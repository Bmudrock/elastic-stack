# Elastic Stack

Terraform and Ansible to deploy Elasticsearch, Kibana, and APM Server on AWS EC2, sized to observe 74 Fargate containers across two application scenarios.

## Structure

```
terraform/   AWS infrastructure (EC2, EBS, IAM, Route53, Private CA certs)
ansible/     VM configuration (Elastic Stack install, TLS, Fleet, APM)
docs/        Design and operational documentation
```

## Docs

- [Architecture](docs/architecture.md) — component diagram, data flow, constraints
- [Security](docs/security.md) — network isolation, TLS design, IAM, credential storage
- [Terraform](docs/terraform.md) — resource inventory, variable reference, design decisions
- [Ansible](docs/ansible.md) — roles, playbook ordering, idempotency
- [Operations](docs/operations.md) — deployment steps, day-2 runbook
- [Certificate Renewal](docs/certificate-renewal.md) — renewal process and expiry monitoring

## Quick Start

```bash
# 1. Provision infrastructure
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# fill in terraform.tfvars
cd terraform && terraform init && terraform apply

# 2. Configure VMs
cd ../ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```

See [docs/operations.md](docs/operations.md) for prerequisites and full deployment steps.
