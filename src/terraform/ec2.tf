################################################################################
# Cuez Cloud - EC2 Instances
################################################################################

################################################################################
# Locals - NVIDIA GRID Driver user_data
################################################################################
locals {
  nvidia_driver_script = <<-USERDATA
    <powershell>
    # NVIDIA GRID Driver Installation for g4dn instances
    # Downloads from AWS official S3 bucket (free for EC2 GPU instances)
    $logDir = "C:\vmix\logs"
    $logFile = "$logDir\nvidia-setup.log"

    New-Item -ItemType Directory -Force -Path $logDir | Out-Null

    function Write-Log($msg) {
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$ts - $msg" | Out-File -Append -FilePath $logFile
    }

    Write-Log "Starting NVIDIA GRID driver installation"

    try {
        # Download NVIDIA GRID driver from AWS S3
        $installerDir = "C:\vmix\drivers"
        New-Item -ItemType Directory -Force -Path $installerDir | Out-Null

        $bucket = "ec2-windows-nvidia-drivers"
        $prefix = "latest"
        $localPath = "$installerDir\NVIDIA-GRID-driver.exe"

        Write-Log "Downloading NVIDIA GRID driver from s3://$bucket/$prefix"

        # Use AWS CLI (pre-installed on Windows AMIs) to download
        $s3Key = (aws s3 ls "s3://$bucket/$prefix/" --no-sign-request | Where-Object { $_ -match "\.exe$" } | Sort-Object | Select-Object -Last 1) -replace '.*\s+', ''

        if ($s3Key) {
            aws s3 cp "s3://$bucket/$prefix/$s3Key" $localPath --no-sign-request 2>&1 | Out-File -Append -FilePath $logFile
            Write-Log "Downloaded: $s3Key"

            # Silent install
            Write-Log "Running silent install..."
            Start-Process -FilePath $localPath -ArgumentList "/s /noreboot" -Wait -NoNewWindow 2>&1 | Out-File -Append -FilePath $logFile
            Write-Log "NVIDIA driver installation completed"
        } else {
            Write-Log "ERROR: Could not find NVIDIA driver in S3 bucket"
        }
    } catch {
        Write-Log "ERROR: $($_.Exception.Message)"
    }

    Write-Log "user_data script finished"
    </powershell>
  USERDATA

  nvidia_driver_userdata = var.enable_nvidia_driver ? local.nvidia_driver_script : null
}

################################################################################
# EC2 Instance - vMix Server
################################################################################
resource "aws_instance" "vmix" {
  ami                    = var.vmix_ami_id != "" ? var.vmix_ami_id : data.aws_ami.windows_2022.id
  instance_type          = var.vmix_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.vmix.id]
  user_data              = local.nvidia_driver_userdata

  root_block_device {
    volume_size           = var.ebs_volume_size
    volume_type           = var.ebs_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "prod-vmix"
    Role = "vMix-Server"
  }

  volume_tags = {
    Name = "prod-vmix-volume"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

################################################################################
# EC2 Instance - Cuez Server
################################################################################
resource "aws_instance" "cuez" {
  ami                    = data.aws_ami.windows_2022.id
  instance_type          = var.cuez_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.cuez.id]

  root_block_device {
    volume_size           = var.ebs_volume_size
    volume_type           = var.ebs_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "prod-cuez"
    Role = "Cuez-Server"
  }

  volume_tags = {
    Name = "prod-cuez-volume"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

################################################################################
# Elastic IPs (opcional - uncomment se necessário IP fixo)
################################################################################
# resource "aws_eip" "vmix" {
#   instance = aws_instance.vmix.id
#   domain   = "vpc"
#
#   tags = {
#     Name = "prod-vmix-eip"
#   }
# }

# resource "aws_eip" "cuez" {
#   instance = aws_instance.cuez.id
#   domain   = "vpc"
#
#   tags = {
#     Name = "prod-cuez-eip"
#   }
# }
