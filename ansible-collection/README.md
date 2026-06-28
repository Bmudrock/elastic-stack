# mycompany.elastic_stack

Ansible collection that installs and configures an **all-in-one Elastic Stack
node** (Elasticsearch + Kibana, with optional Fleet Server and APM Server) on a
stock Ubuntu 24.04 host, over SSH.

It is the configuration half of the Elastic Stack blueprint; the
[`elastic-stack` Terraform module](../terraform-module) provisions the EC2
instance and writes the inventory this collection consumes.

## Roles

| Role | Purpose |
|------|---------|
| `common` | Elastic APT repo (pinned to `elastic_version`), prerequisites, TLS material fetched from SSM |
| `elasticsearch` | Install + configure single-node Elasticsearch; mount the data volume; bootstrap credentials into SSM (once) |
| `kibana` | Install + configure Kibana (talks to Elasticsearch over localhost) |
| `fleet_server` | Bootstrap Fleet Server on the local Elastic Agent (opt-in) |
| `apm_server` | Add the APM integration to the local agent's policy (opt-in; requires Fleet) |

## Playbook

`mycompany.elastic_stack.site` applies the roles in order, gating Fleet and APM
on the `enable_fleet` / `enable_apm` inventory vars.

## Key variables (supplied by the Terraform-generated inventory)

`deployment_name`, `aws_region`, `domain_name`, `elastic_ssm_prefix`,
`elastic_version`, `elasticsearch_heap_size`, `enable_fleet`, `enable_apm`,
`data_volume_id`, and the per-service FQDNs (`kibana_fqdn`, `fleet_fqdn`,
`apm_fqdn`).

## Usage

```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook mycompany.elastic_stack.site -i inventory/hosts.yml --private-key <key>
```

Re-running is idempotent: stack passwords are generated only on the first run and
read back from SSM thereafter, so consumers are never disrupted.
