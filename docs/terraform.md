# Terraform

## Overview

The `terraform/` directory provisions all AWS infrastructure. Ansible configuration depends on the outputs of this layer — specifically the EC2 instance IDs (for SSM targeting) and the Ansible inventory file that Terraform generates.

## File Structure

| File | Purpose |
|---|---|
| `providers.tf` | AWS, TLS, and local provider versions |
| `variables.tf` | All input variables — see reference table below |
| `data.tf` | Data sources for VPC, subnet, Route53 zone, Private CA |
| `iam.tf` | Per-VM IAM roles, SSM policy, SSM Parameter Store policy |
| `security_groups.tf` | Per-VM security groups with `internal_cidr` source rules |
| `certificates.tf` | TLS key generation, Private CA signing, SSM parameter storage |
| `ec2.tf` | EC2 instances, EBS data volumes, volume attachments |
| `dns.tf` | Route53 A records for all four FQDNs |
| `main.tf` | Generates the Ansible inventory file via `local_file` |
| `outputs.tf` | Instance IDs, private IPs, service URLs |
| `templates/ansible_inventory.tpl` | Inventory template (SSM connection plugin format) |
| `templates/user_data.sh.tpl` | Minimal user data — sets hostname only |
| `terraform.tfvars.example` | Documents required variables; safe to commit |

## Variable Reference

### Required (no defaults — must be in `terraform.tfvars`)

| Variable | Type | Description |
|---|---|---|
| `vpc_id` | string | Existing VPC to deploy into |
| `subnet_id` | string | Private subnet for all EC2 instances |
| `aws_region` | string | AWS region |
| `private_hosted_zone_id` | string | Private Route53 hosted zone ID |
| `domain_name` | string | Private domain for DNS records and TLS SANs |
| `private_ca_arn` | string | ARN of the AWS Private Certificate Authority |
| `internal_cidr` | string | Trusted CIDR for all security group inbound rules |
| `ami_id` | string | Ubuntu 26.04 LTS AMI ID (region-specific) |

### Optional (safe defaults)

| Variable | Default | Description |
|---|---|---|
| `elasticsearch_instance_type` | `r6i.2xlarge` | 8 vCPU, 64 GB — supports 32 GB ES heap |
| `kibana_instance_type` | `m6i.xlarge` | 4 vCPU, 16 GB — Kibana + Fleet at 74 agents |
| `apm_instance_type` | `m6i.large` | 2 vCPU, 8 GB — APM relay is mostly stateless |
| `elasticsearch_ebs_size_gb` | `1000` | 1 TB gp3 for 7-day retention at medium log volume |
| `key_name` | `null` | EC2 key pair for break-glass SSH (SSM is primary) |
| `tags` | `{}` | Additional tags on all resources |

## VM Sizing Rationale

**Elasticsearch — `r6i.2xlarge` (8 vCPU, 64 GB RAM, 1 TB gp3)**

Elasticsearch heap is capped at 32 GB (half of RAM, the JVM compressed-oops boundary). A 32 GB heap comfortably handles indexing from 74 medium Fargate agents. The `r6i` family is memory-optimised, which suits Elasticsearch's working-set caching behaviour.

EBS is provisioned at 1 TB gp3 with 6000 IOPS and 250 MB/s throughput. At medium log/trace volume (estimated ~150 MB/hour across 74 containers), 1 TB provides 7 days of retention with roughly 2× headroom.

**Kibana + Fleet — `m6i.xlarge` (4 vCPU, 16 GB RAM, 100 GB gp3)**

Fleet Server with 74 enrolled agents is a light workload. The `m6i.xlarge` leaves headroom for both Kibana rendering and Fleet's agent heartbeat traffic without a dedicated Fleet VM.

**APM Server — `m6i.large` (2 vCPU, 8 GB RAM, 100 GB gp3)**

APM Server (via Elastic Agent) is stateless: it receives trace/metric payloads and forwards them to Elasticsearch. Two cores and 8 GB are sufficient for the expected APM throughput from 74 medium containers.

## What Terraform Creates

| Resource Type | Count | Notes |
|---|---|---|
| `aws_instance` | 3 | elasticsearch, kibana, apm |
| `aws_ebs_volume` | 3 | 1 TB (ES), 100 GB × 2 (Kibana, APM) |
| `aws_volume_attachment` | 3 | `/dev/xvdf` on each instance |
| `aws_security_group` | 3 | One per VM |
| `aws_vpc_security_group_ingress_rule` | 4 | 9200, 5601, 8220, 8200 |
| `aws_vpc_security_group_egress_rule` | 3 | 443/tcp outbound |
| `aws_iam_role` | 3 | Per-VM least-privilege roles |
| `aws_iam_role_policy_attachment` | 3 | SSM Core managed policy |
| `aws_iam_role_policy` | 3 | SSM Parameter Store read on `/elastic/*` |
| `aws_iam_instance_profile` | 3 | Attached to each instance |
| `tls_private_key` | 3 | RSA 4096 — one per role |
| `aws_acmpca_certificate` | 3 | Signed by Private CA, 825-day validity |
| `aws_ssm_parameter` | 7 | 3 keys, 3 certs, 1 shared CA chain |
| `aws_route53_record` | 4 | elasticsearch, kibana, fleet, apm |
| `local_file` | 1 | `ansible/inventory/hosts.yml` |

## Design Decisions

**Single subnet** — All VMs share one private subnet. Cross-AZ traffic costs and latency are avoided at the cost of AZ-level redundancy, which is acceptable for a single-node Elasticsearch deployment.

**Per-VM security groups** — Each VM has its own SG rather than a shared one. This allows port-level granularity without over-permissioning and makes it possible to tighten or expand individual services independently.

**`aws_vpc_security_group_ingress_rule` instead of inline rules** — Using the standalone rule resources avoids Terraform lifecycle conflicts when modifying rules on existing groups.

**XFS on EBS** — The Elasticsearch data volume is formatted as XFS by the Ansible role. XFS handles Elasticsearch's write-heavy, large-file I/O patterns better than ext4 and is the format recommended by Elastic for production deployments.

**gp3 over gp2** — gp3 allows IOPS and throughput to be provisioned independently of volume size, delivering better price/performance. The Elasticsearch volume is provisioned at 6000 IOPS / 250 MB/s regardless of size.

**`ignore_changes = [user_data]`** — User data only sets the hostname and is consumed once on first boot. Ignoring changes prevents Terraform from replacing instances when the template is re-rendered with unchanged values.

## Outputs

After `terraform apply`, the following outputs are available:

```
elasticsearch_instance_id   — used by Ansible SSM connection
kibana_instance_id
apm_instance_id
elasticsearch_private_ip
kibana_private_ip
apm_private_ip
elasticsearch_url           — https://elasticsearch.<domain>:9200
kibana_url                  — https://kibana.<domain>:5601
fleet_server_url            — https://fleet.<domain>:8220
apm_server_url              — https://apm.<domain>:8200
ansible_inventory_path      — path to the generated hosts.yml
```
