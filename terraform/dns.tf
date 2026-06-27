locals {
  dns_records = {
    elasticsearch = aws_instance.elastic["elasticsearch"].private_ip
    kibana        = aws_instance.elastic["kibana"].private_ip
    fleet         = aws_instance.elastic["kibana"].private_ip
    apm           = aws_instance.elastic["apm"].private_ip
  }
}

resource "aws_route53_record" "elastic" {
  for_each = local.dns_records

  zone_id = var.private_hosted_zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [each.value]
}
