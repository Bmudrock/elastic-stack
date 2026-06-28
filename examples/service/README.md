# Example service consumer

Reference for a `/<contract>/services/elastic-stack` project that deploys the
Elastic Stack into a contract AWS account using the two blueprint artifacts.

```
terraform/   calls the elastic-stack Terraform module + writes the inventory
ansible/     pulls the mycompany.elastic_stack collection + runs site.yml
```

## Deploy (two phases)

Run from a CI runner that has: Terraform, Ansible, AWS credentials for the
central account (able to assume `contract_account_role_arn`), the SSH private
key for `key_name`, and network reachability into the contract private subnet.

```bash
# 1. Provision infrastructure (also writes ../ansible/inventory/hosts.yml)
cd terraform
cp terraform.tfvars.example terraform.tfvars   # fill in real values
terraform init -backend-config=backend.hcl     # encrypted S3 backend
terraform apply

# 2. Configure the stack
cd ../ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook mycompany.elastic_stack.site -i inventory/hosts.yml --private-key ~/.ssh/elastic-stack
```

The Ansible run is idempotent and doubles as the day-2 tool (re-run after a cert
rotation or version bump).

## Retrieve the elastic password

```bash
aws ssm get-parameter \
  --name "$(terraform -chdir=terraform output -raw elastic_password_ssm_name)" \
  --with-decryption --query 'Parameter.Value' --output text
```
