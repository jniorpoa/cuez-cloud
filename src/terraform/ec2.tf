################################################################################
# Cuez Cloud - EC2 Instances
################################################################################

################################################################################
# EC2 Instance - vMix Server
################################################################################
resource "aws_instance" "vmix" {
  ami                    = data.aws_ami.windows_11.id
  instance_type          = var.vmix_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.vmix.id]

  root_block_device {
    volume_size           = var.ebs_volume_size
    volume_type           = var.ebs_volume_type
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.tags, {
      Name = "${var.project_name}-vmix-root"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-vmix"
    Role = "vMix-Server"
  })

  volume_tags = merge(var.tags, {
    Name = "${var.project_name}-vmix-volume"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

################################################################################
# EC2 Instance - Cuez Server
################################################################################
resource "aws_instance" "cuez" {
  ami                    = data.aws_ami.windows_11.id
  instance_type          = var.cuez_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.cuez.id]

  root_block_device {
    volume_size           = var.ebs_volume_size
    volume_type           = var.ebs_volume_type
    encrypted             = true
    delete_on_termination = true

    tags = merge(var.tags, {
      Name = "${var.project_name}-cuez-root"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-cuez"
    Role = "Cuez-Server"
  })

  volume_tags = merge(var.tags, {
    Name = "${var.project_name}-cuez-volume"
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

################################################################################
# Elastic IPs (opcional - uncomment se necessário IP fixo)
################################################################################
# resource "aws_eip" "vmix" {
#   instance = aws_instance.vmix.id
#   domain   = "vpc"
#
#   tags = merge(var.tags, {
#     Name = "${var.project_name}-vmix-eip"
#   })
# }

# resource "aws_eip" "cuez" {
#   instance = aws_instance.cuez.id
#   domain   = "vpc"
#
#   tags = merge(var.tags, {
#     Name = "${var.project_name}-cuez-eip"
#   })
# }
