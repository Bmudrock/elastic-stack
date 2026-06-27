locals {
  instances = {
    elasticsearch = {
      instance_type = var.elasticsearch_instance_type
      data_disk_gb  = var.elasticsearch_ebs_size_gb
      data_iops     = 6000
      data_tp_mbps  = 250
    }
    kibana = {
      instance_type = var.kibana_instance_type
      data_disk_gb  = 100
      data_iops     = 3000
      data_tp_mbps  = 125
    }
    apm = {
      instance_type = var.apm_instance_type
      data_disk_gb  = 100
      data_iops     = 3000
      data_tp_mbps  = 125
    }
  }
}

resource "aws_instance" "elastic" {
  for_each = local.instances

  ami                         = var.ami_id
  instance_type               = each.value.instance_type
  subnet_id                   = var.subnet_id
  iam_instance_profile        = aws_iam_instance_profile.elastic_node[each.key].name
  vpc_security_group_ids      = [aws_security_group.elastic[each.key].id]
  ebs_optimized               = true
  key_name                    = var.key_name
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    hostname = "elastic-${each.key}"
  }))

  tags = { Name = "elastic-${each.key}" }

  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "aws_ebs_volume" "elastic_data" {
  for_each = local.instances

  availability_zone = data.aws_subnet.this.availability_zone
  size              = each.value.data_disk_gb
  type              = "gp3"
  iops              = each.value.data_iops
  throughput        = each.value.data_tp_mbps
  encrypted         = true

  tags = { Name = "elastic-${each.key}-data" }
}

resource "aws_volume_attachment" "elastic_data" {
  for_each = local.instances

  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.elastic_data[each.key].id
  instance_id  = aws_instance.elastic[each.key].id
  force_detach = false
}
