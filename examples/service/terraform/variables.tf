variable "name" {
  type        = string
  description = "Deployment name (namespaces all resources and SSM paths)."
}

variable "aws_region" {
  type        = string
  description = "AWS region for both the contract and central providers."
}

variable "contract_account_role_arn" {
  type        = string
  description = "IAM role ARN to assume in the contract account where the instance is deployed."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID in the contract account."
}

variable "subnet_id" {
  type        = string
  description = "Private subnet ID in the contract account."
}

variable "internal_cidr" {
  type        = string
  description = "Trusted CIDR allowed to reach the Elastic service ports."
}

variable "management_cidr" {
  type        = string
  description = "CIDR allowed to SSH (the CI runner's egress range)."
}

variable "domain_name" {
  type        = string
  description = "Domain for DNS and TLS (e.g. contract1.mycompany.com)."
}

variable "private_ca_arn" {
  type        = string
  description = "Private CA ARN in the central account."
}

variable "central_hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID in the central account."
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name; the runner holds the private key."
}

variable "enable_fleet" {
  type        = bool
  description = "Enable Fleet Server."
  default     = false
}

variable "enable_apm" {
  type        = bool
  description = "Enable APM Server (requires enable_fleet)."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
