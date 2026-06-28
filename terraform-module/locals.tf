locals {
  # Effective namespace for resource names and SSM parameter paths.
  ns       = var.name
  ssm_root = "${var.ssm_prefix}/${var.name}"

  ami_id = coalesce(var.ami_id, try(data.aws_ami.ubuntu[0].id, null))

  # Service FQDN -> enabled. Elasticsearch and Kibana are always on;
  # Fleet and APM are opt-in. Drives DNS records and TLS SANs.
  fqdns = merge(
    {
      "elasticsearch.${var.domain_name}" = true
      "kibana.${var.domain_name}"        = true
    },
    var.enable_fleet ? { "fleet.${var.domain_name}" = true } : {},
    var.enable_apm ? { "apm.${var.domain_name}" = true } : {},
  )

  # Cert covers every enabled service name plus localhost (all components talk
  # to each other over the loopback on the all-in-one host).
  cert_sans = concat(keys(local.fqdns), ["localhost"])

  # Service ports opened to internal_cidr, conditional on enabled components.
  ingress_ports = concat(
    [9200, 5601],
    var.enable_fleet ? [8220] : [],
    var.enable_apm ? [8200] : [],
  )
}
