# One TLS identity for the all-in-one node, shared by Elasticsearch, Kibana,
# Fleet Server, and the Elastic Agent. SANs cover every enabled service name
# plus localhost.
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name = "kibana.${var.domain_name}"
  }

  dns_names = local.cert_sans
}

# Signed by the Private CA in the central account.
resource "aws_acmpca_certificate" "this" {
  provider = aws.central

  certificate_authority_arn   = var.private_ca_arn
  certificate_signing_request = tls_cert_request.this.cert_request_pem
  signing_algorithm           = "SHA256WITHRSA"
  template_arn                = "arn:aws:acm-pca:::template/EndEntityCertificate/V1"

  validity {
    type  = "DAYS"
    value = 825
  }
}

# TLS material is stored in the contract account's SSM so the instance can
# fetch it via its IAM role.
# NOTE: tls_private_key keeps the key in Terraform state — the consuming
# project's state MUST use an encrypted remote backend (SSE-KMS).
resource "aws_ssm_parameter" "tls_key" {
  name        = "${local.ssm_root}/tls/key"
  type        = "SecureString"
  value       = tls_private_key.this.private_key_pem
  description = "TLS private key for elastic-${local.ns}"
  tags        = var.tags
}

resource "aws_ssm_parameter" "tls_cert" {
  name        = "${local.ssm_root}/tls/cert"
  type        = "String"
  value       = aws_acmpca_certificate.this.certificate
  description = "TLS certificate for elastic-${local.ns}"
  tags        = var.tags
}

# CA chain for verification. For a subordinate CA, certificate_chain contains
# the full chain to the root; for a root CA it is empty, so fall back to the
# CA certificate itself.
resource "aws_ssm_parameter" "tls_ca_chain" {
  name        = "${local.ssm_root}/common/tls/ca_chain"
  type        = "String"
  value       = length(trimspace(data.aws_acmpca_certificate_authority.this.certificate_chain)) > 0 ? data.aws_acmpca_certificate_authority.this.certificate_chain : data.aws_acmpca_certificate_authority.this.certificate
  description = "Private CA certificate chain for Elastic Stack TLS verification"
  tags        = var.tags
}
