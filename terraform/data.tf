data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_subnet" "this" {
  id = var.subnet_id
}

data "aws_route53_zone" "this" {
  zone_id = var.private_hosted_zone_id
}

data "aws_acmpca_certificate_authority" "this" {
  arn = var.private_ca_arn
}
