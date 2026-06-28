resource "aws_security_group" "this" {
  name        = "elastic-${local.ns}"
  description = "Elastic Stack all-in-one node (${local.ns})"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "elastic-${local.ns}" })
}

# Service ports (conditional on enabled components) from the trusted CIDR.
resource "aws_vpc_security_group_ingress_rule" "services" {
  for_each = toset([for p in local.ingress_ports : tostring(p)])

  security_group_id = aws_security_group.this.id
  cidr_ipv4         = var.internal_cidr
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  ip_protocol       = "tcp"
  description       = "Elastic service port ${each.value}"
}

# SSH from the management range so the CI runner can run Ansible.
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = var.management_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Ansible SSH"
}

# Outbound HTTPS for the Elastic/Ubuntu package repositories and AWS APIs.
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Package repositories and AWS endpoints"
}
