terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # The module's tls_private_key keeps the TLS key in state — use an encrypted
  # remote backend. Provide bucket/key/region/kms_key_id via -backend-config.
  backend "s3" {
    encrypt = true
  }
}

# Central account: holds the Private CA and the Route53 hosted zone.
# The CI runner authenticates here directly.
provider "aws" {
  alias  = "central"
  region = var.aws_region
}

# Contract account: where the Elastic Stack instance is deployed.
provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn = var.contract_account_role_arn
  }

  default_tags {
    tags = var.tags
  }
}

module "elastic" {
  source = "git::https://gitlab.example.com/blueprints/terraform-modules/elastic-stack.git//terraform-module?ref=v0.1.0"
  # For local development against this repo, use a relative path instead:
  # source = "../../../terraform-module"

  providers = {
    aws         = aws
    aws.central = aws.central
  }

  name                   = var.name
  vpc_id                 = var.vpc_id
  subnet_id              = var.subnet_id
  internal_cidr          = var.internal_cidr
  management_cidr        = var.management_cidr
  domain_name            = var.domain_name
  private_ca_arn         = var.private_ca_arn
  central_hosted_zone_id = var.central_hosted_zone_id
  key_name               = var.key_name

  enable_fleet = var.enable_fleet
  enable_apm   = var.enable_apm

  inventory_output_path = "${path.module}/../ansible/inventory/hosts.yml"

  tags = var.tags
}
