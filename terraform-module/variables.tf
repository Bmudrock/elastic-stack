# ── Required ──────────────────────────────────────────────────────────────────

variable "name" {
  type        = string
  description = "Deployment name. Namespaces all resource names and SSM parameter paths so multiple deployments can coexist in one account."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "name must contain only lowercase letters, digits, and hyphens."
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the existing VPC in the contract account."
}

variable "subnet_id" {
  type        = string
  description = "ID of the private subnet for the EC2 instance."
}

variable "internal_cidr" {
  type        = string
  description = "Trusted CIDR block allowed to reach the Elastic Stack service ports (workstations, Fargate containers, etc.)."
}

variable "management_cidr" {
  type        = string
  description = "CIDR allowed to reach SSH (port 22) for Ansible configuration — typically the CI runner's egress range."
}

variable "domain_name" {
  type        = string
  description = "Domain used for DNS records and TLS SANs (e.g. contract1.mycompany.com). Each deployment must use a distinct domain to avoid record collisions."
}

variable "private_ca_arn" {
  type        = string
  description = "ARN of the AWS Private Certificate Authority (in the central account) used to sign the TLS certificate."
}

variable "central_hosted_zone_id" {
  type        = string
  description = "ID of the Route53 hosted zone (in the central account) for domain_name."
}

variable "inventory_output_path" {
  type        = string
  description = "Filesystem path where the generated Ansible inventory is written (e.g. ../ansible/inventory/hosts.yml)."
}

variable "key_name" {
  type        = string
  description = "Name of an existing EC2 key pair; the CI runner must hold the matching private key to run Ansible over SSH."
}

# ── Optional ──────────────────────────────────────────────────────────────────

variable "ami_id" {
  type        = string
  description = "Override AMI ID. When null, the latest Canonical Ubuntu 24.04 (noble) AMI is looked up automatically."
  default     = null
}

variable "ssh_user" {
  type        = string
  description = "SSH user for Ansible (matches the base AMI's default user)."
  default     = "ubuntu"
}

variable "enable_fleet" {
  type        = bool
  description = "Install and configure Fleet Server. Opt-in."
  default     = false
}

variable "enable_apm" {
  type        = bool
  description = "Install and enroll the APM Server (Elastic Agent). Opt-in; requires enable_fleet."
  default     = false
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the all-in-one node."
  default     = "r6i.2xlarge"
}

variable "elasticsearch_heap_size" {
  type        = string
  description = "Elasticsearch JVM heap size. Sized for a shared all-in-one host (leaves RAM for Kibana, Fleet, APM, and OS page cache)."
  default     = "16g"
}

variable "elastic_version" {
  type        = string
  description = "Elastic Stack version to pin (apt package version, e.g. 8.17.0). Verify the current stable release before deploying."
  default     = "8.17.0"
}

variable "data_ebs_size_gb" {
  type        = number
  description = "Size in GB of the Elasticsearch data EBS volume."
  default     = 1000
}

variable "data_ebs_iops" {
  type        = number
  description = "Provisioned IOPS for the gp3 data volume."
  default     = 6000
}

variable "data_ebs_throughput" {
  type        = number
  description = "Provisioned throughput (MB/s) for the gp3 data volume."
  default     = 250
}

variable "root_volume_size" {
  type        = number
  description = "Size in GB of the encrypted gp3 root volume."
  default     = 50
}

variable "ssm_prefix" {
  type        = string
  description = "Base SSM Parameter Store prefix. The effective namespace is <ssm_prefix>/<name>."
  default     = "/elastic"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources."
  default     = {}
}
