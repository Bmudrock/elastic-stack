# Operations

## Prerequisites

### Local tooling

| Tool | Minimum version | Purpose |
|---|---|---|
| Terraform | 1.5 | Infrastructure provisioning |
| Ansible | 2.15 | VM configuration |
| AWS CLI v2 | 2.x | SSM, Parameter Store access |
| session-manager-plugin | latest | Required by Ansible SSM connection |
| Python 3 | 3.9+ | Required by Ansible |

### AWS permissions (deploying identity)

The IAM user or role running Terraform and Ansible needs at minimum:

- `ec2:*` (instances, volumes, security groups)
- `iam:*` (roles, policies, instance profiles)
- `route53:ChangeResourceRecordSets`, `route53:ListHostedZones`
- `acm-pca:IssueCertificate`, `acm-pca:GetCertificate`, `acm-pca:DescribeCertificateAuthority`
- `ssm:PutParameter`, `ssm:GetParameter`, `ssm:StartSession`

## Deployment

### 1. Configure variables

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars — fill in all required values
```

### 2. Provision infrastructure

```bash
cd terraform
terraform init
terraform plan    # review before applying
terraform apply
```

This creates all AWS resources and writes `ansible/inventory/hosts.yml`.

### 3. Install Ansible collections

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

### 4. Verify SSM connectivity

```bash
ansible all -i inventory/hosts.yml -m ansible.builtin.ping
```

All three hosts should return `pong`. If they do not, check:
- IAM instance profile is attached and includes `AmazonSSMManagedInstanceCore`
- SSM agent is running on the instance (check via EC2 console → Systems Manager)
- Outbound 443 is allowed from the instance SG (it is — see `elastic_https` egress rule)

### 5. Run Ansible

```bash
# Full stack
ansible-playbook -i inventory/hosts.yml playbooks/site.yml

# Individual service (e.g. to re-run only Elasticsearch config)
ansible-playbook -i inventory/hosts.yml playbooks/elasticsearch.yml
```

### 6. Verify the deployment

```bash
# From a host within var.internal_cidr:

# Elasticsearch cluster health
curl -k -u elastic:<password> https://elasticsearch.<domain>:9200/_cluster/health

# Kibana status
curl -k https://kibana.<domain>:5601/api/status

# Fleet Server status
curl -k https://fleet.<domain>:8220/api/status

# APM Server (via Elastic Agent) — check in Kibana Fleet UI
```

Retrieve the `elastic` password from SSM:
```bash
aws ssm get-parameter \
  --name /elastic/credentials/elastic_password \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text
```

## Day-2 Operations

### Connecting to a VM

SSM Session Manager is the only supported access method:

```bash
aws ssm start-session --target <instance-id> --region <region>
```

Instance IDs are in `terraform output` or `ansible/inventory/hosts.yml`.

### Rotating credentials

Re-running the Elasticsearch playbook resets `elastic` and `kibana_system` passwords and updates SSM. After rotating, re-run the Kibana playbook to sync the new `kibana_system` password into the Kibana keystore:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/elasticsearch.yml
ansible-playbook -i inventory/hosts.yml playbooks/kibana.yml
```

### Renewing TLS certificates

See [certificate-renewal.md](certificate-renewal.md) for the full process, including the distinction between routine renewal (taint certificate only) and key rotation (taint key and certificate), service restart impact, and expiry monitoring options.

### Scaling Elasticsearch storage

If 7-day retention is no longer sufficient, increase the EBS volume size:

1. Update `elasticsearch_ebs_size_gb` in `terraform.tfvars`
2. `terraform apply` — this modifies the EBS volume in place (no downtime for gp3 modifications)
3. SSH (via SSM) to the Elasticsearch VM and grow the filesystem:

```bash
sudo xfs_growfs /var/lib/elasticsearch
```

### Updating Elastic Stack version

The Elastic APT repository tracks the latest 8.x release automatically. To upgrade:

```bash
ansible-playbook -i inventory/hosts.yml playbooks/site.yml \
  -t upgrade \
  --extra-vars "elastic_upgrade=true"
```

Add an `upgrade` tag and `apt` upgrade task to each role's `tasks/main.yml` when implementing this. Upgrade order must follow the standard Elastic guidance: Elasticsearch first, then Kibana, then agents.

### Replacing a failed instance

If an EC2 instance is terminated or fails:

1. `terraform apply` — Terraform will detect the missing instance and create a new one
2. Re-run the relevant Ansible playbook — the new instance will have no data; the EBS volume persists and will be re-attached by Terraform

Note: EBS volumes are not destroyed when instances are replaced, provided `prevent_destroy = true` or that the volume resource is not tainted. Add a lifecycle rule to `aws_ebs_volume.elastic_data` resources if this protection is required.

## Constraints and Limits

| Constraint | Value | Impact |
|---|---|---|
| Elasticsearch nodes | 1 | No HA; full outage during node failure |
| Data retention | 7 days | ILM deletes older indices automatically |
| Agent count | 74 (37 per scenario) | Sizing basis; above ~200 agents consider a dedicated Fleet Server VM |
| TLS cert validity | 825 days | Calendar reminder needed; no auto-renewal |
| Subnet | Single AZ | AZ outage takes down the full stack |
| Public IPs | None | Access requires SSM or being inside `internal_cidr` |
| Elasticsearch heap | 32 GB hard limit | JVM compressed-oops boundary; cannot be increased without changing instance type |
