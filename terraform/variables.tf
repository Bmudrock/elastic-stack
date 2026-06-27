# ── Required: no defaults ─────────────────────────────────────────────────────
# Supply all of these in terraform.tfvars (never commit that file).

variable "vpc_id" {
  type        = string
  description = "ID of the existing VPC"
}

variable "subnet_id" {
  type        = string
  description = "ID of the private subnet for EC2 instances"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
}

variable "private_hosted_zone_id" {
  type        = string
  description = "ID of the existing private Route53 hosted zone"
}

variable "domain_name" {
  type        = string
  description = "Private domain name used for DNS records and TLS SANs (e.g. internal.corp)"
}

variable "private_ca_arn" {
  type        = string
  description = "ARN of the AWS Private Certificate Authority used to sign TLS certificates"
}

variable "internal_cidr" {
  type        = string
  description = "Trusted CIDR block for all security group inbound rules (workstations and Fargate containers)"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for EC2 instances — Ubuntu 26.04 LTS (region-specific; swap to 24.04 if APT support is missing)"
}

# ── Optional: operational defaults ────────────────────────────────────────────

variable "elasticsearch_instance_type" {
  type        = string
  description = "EC2 instance type for Elasticsearch (sized for 74 medium Fargate agents, single node, 32 GB heap)"
  default     = "r6i.2xlarge"
}

variable "kibana_instance_type" {
  type        = string
  description = "EC2 instance type for Kibana + Fleet Server"
  default     = "m6i.xlarge"
}

variable "apm_instance_type" {
  type        = string
  description = "EC2 instance type for APM Server"
  default     = "m6i.large"
}

variable "elasticsearch_ebs_size_gb" {
  type        = number
  description = "Size in GB of the Elasticsearch data EBS volume (7-day retention for 74 medium agents)"
  default     = 1000
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for break-glass SSH access. SSM Session Manager is the primary access method."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources"
  default     = {}
}
