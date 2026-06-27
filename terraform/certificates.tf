locals {
  cert_definitions = {
    elasticsearch = {
      cn   = "elasticsearch.${var.domain_name}"
      sans = ["elasticsearch.${var.domain_name}"]
    }
    kibana = {
      cn   = "kibana.${var.domain_name}"
      sans = ["kibana.${var.domain_name}", "fleet.${var.domain_name}"]
    }
    apm = {
      cn   = "apm.${var.domain_name}"
      sans = ["apm.${var.domain_name}"]
    }
  }
}

resource "tls_private_key" "elastic" {
  for_each  = local.cert_definitions
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "elastic" {
  for_each        = local.cert_definitions
  private_key_pem = tls_private_key.elastic[each.key].private_key_pem

  subject {
    common_name = each.value.cn
  }

  dns_names = each.value.sans
}

resource "aws_acmpca_certificate" "elastic" {
  for_each = local.cert_definitions

  certificate_authority_arn   = var.private_ca_arn
  certificate_signing_request = tls_cert_request.elastic[each.key].cert_request_pem
  signing_algorithm           = "SHA256WITHRSA"

  template_arn = "arn:aws:acm-pca:::template/EndEntityCertificate/V1"

  validity {
    type  = "DAYS"
    value = 825
  }
}

# Private keys stored as SecureString — state backend must use SSE-KMS
resource "aws_ssm_parameter" "tls_key" {
  for_each = local.cert_definitions

  name        = "/elastic/${each.key}/tls/key"
  type        = "SecureString"
  value       = tls_private_key.elastic[each.key].private_key_pem
  description = "TLS private key for elastic-${each.key}"
}

resource "aws_ssm_parameter" "tls_cert" {
  for_each = local.cert_definitions

  name        = "/elastic/${each.key}/tls/cert"
  type        = "String"
  value       = aws_acmpca_certificate.elastic[each.key].certificate
  description = "TLS certificate for elastic-${each.key}"
}

# CA chain is shared across all nodes — stored once
resource "aws_ssm_parameter" "tls_ca_chain" {
  name        = "/elastic/common/tls/ca_chain"
  type        = "String"
  value       = data.aws_acmpca_certificate_authority.this.certificate_chain
  description = "Private CA certificate chain for Elastic Stack TLS verification"
}
