# Elastic Stack blueprint

Reusable building blocks for deploying an **all-in-one Elastic Stack EC2
instance** (Elasticsearch + Kibana, with optional Fleet Server and APM Server)
into any AWS account.

The design follows one principle: **each tool does one job, packaged as a
versioned, importable artifact.**

```
terraform-module/    Terraform module — provisions the EC2 instance, EBS, IAM,
                     security group, TLS cert (ACM-PCA), DNS, and writes an
                     Ansible inventory. (No Packer; uses the stock Ubuntu AMI.)

ansible-collection/  Ansible collection (mycompany.elastic_stack) — installs and
                     configures the stack over SSH.

examples/service/    Reference consumer wiring the module + collection together,
                     as it would live in a per-contract service project.

docs/                Design and operational documentation.
```

## How a deployment works

1. **Terraform** provisions one EC2 instance from the latest Canonical Ubuntu
   24.04 AMI (public in every account — no AMI building or sharing), the data
   volume, IAM role, security group, the TLS certificate (signed by the central
   account's Private CA, stored in the contract account's SSM), and Route53
   records. It writes an Ansible inventory to a path you choose.
2. **Ansible** (the collection) installs and configures Elasticsearch, Kibana,
   and the opt-in Fleet/APM components over SSH, using that inventory.

Elasticsearch and Kibana are always on; Fleet Server and APM Server are opt-in
(`enable_fleet`, `enable_apm`). The deploy is two phases — `terraform apply`
then `ansible-playbook` — and the playbook re-runs idempotently as the day-2
tool.

## Quick start

See [`examples/service/README.md`](examples/service/README.md) for the full
two-phase deploy. In short:

```bash
cd examples/service/terraform
terraform init -backend-config=backend.hcl && terraform apply

cd ../ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook mycompany.elastic_stack.site -i inventory/hosts.yml --private-key <key>
```

## Docs

- [Architecture](docs/architecture.md) — components, data flow, all-in-one model
- [Security](docs/security.md) — network isolation, TLS, IAM, credentials, state
- [Terraform](docs/terraform.md) — module inputs/outputs, cross-account providers
- [Ansible](docs/ansible.md) — collection roles, idempotency, day-2 use
- [Operations](docs/operations.md) — deployment steps, runbook
- [Certificate Renewal](docs/certificate-renewal.md) — renewal and expiry
