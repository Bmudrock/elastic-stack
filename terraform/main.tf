resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/ansible_inventory.tpl", {
    elasticsearch_instance_id = aws_instance.elastic["elasticsearch"].id
    elasticsearch_private_ip  = aws_instance.elastic["elasticsearch"].private_ip

    kibana_instance_id = aws_instance.elastic["kibana"].id
    kibana_private_ip  = aws_instance.elastic["kibana"].private_ip

    apm_instance_id = aws_instance.elastic["apm"].id
    apm_private_ip  = aws_instance.elastic["apm"].private_ip

    aws_region  = var.aws_region
    domain_name = var.domain_name
  })

  filename        = "${path.module}/../ansible/inventory/hosts.yml"
  file_permission = "0640"
}
