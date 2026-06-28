resource "aws_instance" "this" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  iam_instance_profile        = aws_iam_instance_profile.this.name
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = var.key_name
  ebs_optimized               = true
  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, { Name = "elastic-${local.ns}" })

  lifecycle {
    precondition {
      condition     = !var.enable_apm || var.enable_fleet
      error_message = "enable_apm requires enable_fleet (APM Server enrolls through Fleet)."
    }
  }
}

# Dedicated data volume so Elasticsearch data survives instance replacement.
resource "aws_ebs_volume" "data" {
  availability_zone = data.aws_subnet.this.availability_zone
  size              = var.data_ebs_size_gb
  type              = "gp3"
  iops              = var.data_ebs_iops
  throughput        = var.data_ebs_throughput
  encrypted         = true

  tags = merge(var.tags, { Name = "elastic-${local.ns}-data" })
}

resource "aws_volume_attachment" "data" {
  # Requested device name; on Nitro instances the kernel exposes it as an NVMe
  # device, so Ansible resolves the real path by EBS volume ID (by-id symlink).
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.data.id
  instance_id  = aws_instance.this.id
  force_detach = false
}
