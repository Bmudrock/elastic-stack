output "elasticsearch_instance_id" {
  description = "Instance ID of the Elasticsearch node"
  value       = aws_instance.elastic["elasticsearch"].id
}

output "kibana_instance_id" {
  description = "Instance ID of the Kibana + Fleet Server node"
  value       = aws_instance.elastic["kibana"].id
}

output "apm_instance_id" {
  description = "Instance ID of the APM Server node"
  value       = aws_instance.elastic["apm"].id
}

output "elasticsearch_private_ip" {
  description = "Private IP of the Elasticsearch node"
  value       = aws_instance.elastic["elasticsearch"].private_ip
}

output "kibana_private_ip" {
  description = "Private IP of the Kibana + Fleet Server node"
  value       = aws_instance.elastic["kibana"].private_ip
}

output "apm_private_ip" {
  description = "Private IP of the APM Server node"
  value       = aws_instance.elastic["apm"].private_ip
}

output "elasticsearch_url" {
  description = "Elasticsearch HTTPS endpoint"
  value       = "https://elasticsearch.${var.domain_name}:9200"
}

output "kibana_url" {
  description = "Kibana HTTPS endpoint"
  value       = "https://kibana.${var.domain_name}:5601"
}

output "fleet_server_url" {
  description = "Fleet Server HTTPS endpoint"
  value       = "https://fleet.${var.domain_name}:8220"
}

output "apm_server_url" {
  description = "APM Server HTTPS endpoint"
  value       = "https://apm.${var.domain_name}:8200"
}

output "ansible_inventory_path" {
  description = "Path to the generated Ansible inventory file"
  value       = local_file.ansible_inventory.filename
}
