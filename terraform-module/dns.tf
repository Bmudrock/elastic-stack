# A records for every enabled service, all pointing at the single instance.
# Created in the central account's hosted zone; contract VPCs resolve these
# via Route53 forwarding to the central account.
resource "aws_route53_record" "services" {
  provider = aws.central
  for_each = local.fqdns

  zone_id = var.central_hosted_zone_id
  name    = each.key
  type    = "A"
  ttl     = 300
  records = [aws_instance.this.private_ip]
}
