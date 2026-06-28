output "instance_id" {
  description = "EC2 instance ID of the all-in-one node"
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP of the instance"
  value       = aws_instance.this.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.this.id
}

output "iam_role_arn" {
  description = "Instance IAM role ARN"
  value       = aws_iam_role.this.arn
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
  description = "Fleet Server HTTPS endpoint (null when Fleet is disabled)"
  value       = var.enable_fleet ? "https://fleet.${var.domain_name}:8220" : null
}

output "apm_server_url" {
  description = "APM Server HTTPS endpoint (null when APM is disabled)"
  value       = var.enable_apm ? "https://apm.${var.domain_name}:8200" : null
}

output "ssm_prefix" {
  description = "SSM Parameter Store namespace for this deployment"
  value       = local.ssm_root
}

output "elastic_password_ssm_name" {
  description = "SSM parameter name holding the elastic superuser password"
  value       = "${local.ssm_root}/credentials/elastic_password"
}

output "kibana_system_password_ssm_name" {
  description = "SSM parameter name holding the kibana_system password"
  value       = "${local.ssm_root}/credentials/kibana_system_password"
}

output "inventory_path" {
  description = "Path to the generated Ansible inventory file"
  value       = local_file.ansible_inventory.filename
}
