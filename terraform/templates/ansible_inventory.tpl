---
all:
  vars:
    aws_region: ${aws_region}
    domain_name: ${domain_name}

  children:
    elasticsearch:
      hosts:
        ${elasticsearch_instance_id}:
          ansible_connection: community.aws.aws_ssm
          ansible_aws_ssm_region: ${aws_region}
          private_ip: ${elasticsearch_private_ip}
          fqdn: elasticsearch.${domain_name}
          ssm_role_name: elasticsearch

    kibana:
      hosts:
        ${kibana_instance_id}:
          ansible_connection: community.aws.aws_ssm
          ansible_aws_ssm_region: ${aws_region}
          private_ip: ${kibana_private_ip}
          fqdn: kibana.${domain_name}
          ssm_role_name: kibana

    apm_server:
      hosts:
        ${apm_instance_id}:
          ansible_connection: community.aws.aws_ssm
          ansible_aws_ssm_region: ${aws_region}
          private_ip: ${apm_private_ip}
          fqdn: apm.${domain_name}
          ssm_role_name: apm
