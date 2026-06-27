# TLS Certificate Renewal

## Overview

Certificates are issued by the AWS Private Certificate Authority during `terraform apply` and are valid for **825 days**. There is no automatic renewal — a manual Terraform + Ansible run is required before expiry.

The renewal lifecycle spans three layers:

1. **Terraform** — re-issues the certificate from the Private CA and updates SSM Parameter Store
2. **SSM Parameter Store** — holds the new certificate at rest; the old value is overwritten
3. **Ansible** — fetches the new certificate from SSM, writes it to disk, and restarts the service

## Routine Renewal vs. Key Rotation

| Scenario | What to taint |
|---|---|
| Routine renewal (cert expiring, no compromise suspected) | `aws_acmpca_certificate` only |
| Key rotation (compromise suspected or key rotation policy) | `tls_private_key` **and** `aws_acmpca_certificate` |

For routine renewal, only the certificate resource needs to be tainted. Terraform resubmits the existing CSR to the Private CA and receives a new certificate with a fresh validity window. The private key and CSR are unchanged.

Tainting `tls_private_key` generates an entirely new RSA key pair, which cascades to a new CSR and new certificate. Only do this when key rotation is explicitly required.

## Renewal Process

### 1. Taint the certificate resources

```bash
cd terraform

terraform taint 'aws_acmpca_certificate.elastic["elasticsearch"]'
terraform taint 'aws_acmpca_certificate.elastic["kibana"]'
terraform taint 'aws_acmpca_certificate.elastic["apm"]'
```

To renew a single service only, taint just that resource.

### 2. Re-apply Terraform

```bash
terraform plan   # confirm only aws_acmpca_certificate and aws_ssm_parameter resources are affected
terraform apply
```

`aws_ssm_parameter.tls_cert` for each role depends on `aws_acmpca_certificate`, so the SSM parameters update automatically in the same apply. No other resources are modified.

### 3. Deploy new certificates via Ansible

```bash
cd ..
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml
```

The `common` role re-fetches all TLS material from SSM on every run. When the certificate file on disk changes, the role-specific handler triggers a service restart. No manual service intervention is required.

To control the restart window per service, run playbooks individually:

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/elasticsearch.yml
# wait and verify health before continuing
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/kibana.yml
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/apm_server.yml
```

### 4. Verify

```bash
# Replace <domain> and <password> with your values

curl -k -u elastic:<password> \
  https://elasticsearch.<domain>:9200/_cluster/health

curl -k https://kibana.<domain>:5601/api/status

curl -k https://fleet.<domain>:8220/api/status
```

Retrieve the elastic password from SSM if needed:

```bash
aws ssm get-parameter \
  --name /elastic/credentials/elastic_password \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text
```

## Service Restart Impact

Each service restarts once when its certificate file changes on disk. With a single-node Elasticsearch cluster there is no rolling restart — the node is briefly unavailable during the restart (~15–30 seconds). Running the playbooks individually (step 3 above) lets you control when each window occurs.

| Service | Restart duration | Notes |
|---|---|---|
| Elasticsearch | ~15–30 s | Stack unavailable; single node, no HA |
| Kibana | ~10–20 s | Fleet Server restarts with it |
| APM Server (Elastic Agent) | ~5–10 s | Agents reconnect automatically after restart |

Enrolled Fargate agents and the APM agent reconnect to Fleet automatically after the Kibana/Fleet Server restart. No re-enrollment is required.

## The Kibana Certificate Covers Fleet

The Kibana certificate includes `fleet.<domain>` as a Subject Alternative Name. A single renewal covers both services. Renewing the Kibana cert and restarting Kibana also rotates the Fleet Server TLS identity.

## Expiry Monitoring

The current design has no built-in certificate expiry alerting. Without a reminder, a missed renewal takes the stack down silently when certificates expire.

Recommended approaches, in increasing order of automation:

**Calendar reminder** — Set a reminder for day 760 (825 days minus 65 days lead time). Low effort, entirely manual.

**AWS Config rule** — `acm-certificate-expiration-check` can be configured to flag certificates expiring within a given number of days. Note this covers ACM-managed certificates; for Private CA direct issuance you may need a custom Config rule or EventBridge scheduled query.

**EventBridge + Lambda** — Schedule a Lambda to call `acm-pca:GetCertificate`, parse the `NotAfter` field, and publish to an SNS topic if expiry is within 90 days. This is the most robust option and can trigger an automated renewal pipeline.

## Limitations of This Design

Certificates are generated and stored as Terraform-managed resources. This has two implications for renewal:

- **Terraform state holds private keys.** The state file contains the `tls_private_key` output in plaintext. The S3 backend must use SSE-KMS with a strict bucket policy. See [security.md](security.md) for full mitigation details.

- **No ACM auto-renewal.** The design uses direct Private CA issuance (`aws_acmpca_certificate`) rather than ACM-managed certificates. This is necessary because ACM-managed private certificates cannot have their private keys exported, and Elastic Stack requires the key on disk. The trade-off is that ACM's managed renewal lifecycle does not apply — renewal is always a deliberate manual operation.
