locals {
  sg_definitions = {
    elasticsearch = {
      description = "Elasticsearch HTTP API"
      ports       = [9200]
    }
    kibana = {
      description = "Kibana web UI and Fleet Server enrollment"
      ports       = [5601, 8220]
    }
    apm = {
      description = "APM Server intake"
      ports       = [8200]
    }
  }
}

resource "aws_security_group" "elastic" {
  for_each = local.sg_definitions

  name        = "elastic-${each.key}"
  description = each.value.description
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "elastic" {
  for_each = {
    for pair in flatten([
      for role, cfg in local.sg_definitions : [
        for port in cfg.ports : {
          key  = "${role}-${port}"
          role = role
          port = port
        }
      ]
    ]) : pair.key => pair
  }

  security_group_id = aws_security_group.elastic[each.value.role].id
  cidr_ipv4         = var.internal_cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "elastic_https" {
  for_each = local.sg_definitions

  security_group_id = aws_security_group.elastic[each.key].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "SSM endpoints and Elastic APT repository"
}
