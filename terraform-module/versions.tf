terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # The default `aws` provider deploys into the contract account.
      # The `aws.central` alias targets the central account that holds the
      # Private CA and the Route53 hosted zone for the domain.
      configuration_aliases = [aws.central]
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}
