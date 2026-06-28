resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    name            = local.ns
    private_ip      = aws_instance.this.private_ip
    ssh_user        = var.ssh_user
    aws_region      = data.aws_region.current.name
    domain_name     = var.domain_name
    ssm_prefix      = local.ssm_root
    elastic_version = var.elastic_version
    heap_size       = var.elasticsearch_heap_size
    enable_fleet    = var.enable_fleet
    enable_apm      = var.enable_apm
    data_volume_id  = aws_ebs_volume.data.id

    elasticsearch_fqdn = "elasticsearch.${var.domain_name}"
    kibana_fqdn        = "kibana.${var.domain_name}"
    fleet_fqdn         = "fleet.${var.domain_name}"
    apm_fqdn           = "apm.${var.domain_name}"
  })

  filename        = var.inventory_output_path
  file_permission = "0640"
}
