output "instance_id" {
  value = module.elastic.instance_id
}

output "private_ip" {
  value = module.elastic.private_ip
}

output "elasticsearch_url" {
  value = module.elastic.elasticsearch_url
}

output "kibana_url" {
  value = module.elastic.kibana_url
}

output "fleet_server_url" {
  value = module.elastic.fleet_server_url
}

output "apm_server_url" {
  value = module.elastic.apm_server_url
}

output "elastic_password_ssm_name" {
  value = module.elastic.elastic_password_ssm_name
}

output "inventory_path" {
  value = module.elastic.inventory_path
}
