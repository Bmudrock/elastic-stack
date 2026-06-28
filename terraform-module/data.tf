data "aws_region" "current" {}

data "aws_subnet" "this" {
  id = var.subnet_id
}

# Latest Canonical Ubuntu 24.04 LTS (noble), used unless var.ami_id is set.
data "aws_ami" "ubuntu" {
  count = var.ami_id == null ? 1 : 0

  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Private CA lives in the central account.
data "aws_acmpca_certificate_authority" "this" {
  provider = aws.central
  arn      = var.private_ca_arn
}
