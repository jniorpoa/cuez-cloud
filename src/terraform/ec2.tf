################################################################################
# Cuez Cloud - EC2 Instances (Multi-Region)
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
# EC2 Instance - vMix Server (São Paulo)
################################################################################
resource "aws_instance" "vmix" {
  ami                    = data.aws_ami.windows_2025.id
  instance_type          = var.vmix_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.saopaulo_public.id
  vpc_security_group_ids = [aws_security_group.vmix.id]
  user_data              = local.nvidia_driver_userdata

  root_block_device {
    volume_size           = var.vmix_ebs_volume_size
    volume_type           = var.ebs_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name   = "prod-vmix"
    Role   = "vMix-Server"
    Region = "sa-east-1"
  }

  volume_tags = {
    Name = "prod-vmix-volume"
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

################################################################################
# EC2 Instance - VPN Server / Pritunl (São Paulo)
################################################################################
locals {
  pritunl_user_data = <<-USERDATA
    #!/bin/bash
    set -euo pipefail
    exec > /var/log/pritunl-setup.log 2>&1

    echo "=== Pritunl VPN Setup - $(date) ==="

    # Wait for cloud-init network
    echo "Waiting for network..."
    until ping -c1 archive.ubuntu.com &>/dev/null; do sleep 2; done

    export DEBIAN_FRONTEND=noninteractive

    # System update
    echo "Updating system packages..."
    apt-get update -y
    apt-get upgrade -y

    # Install prerequisites
    apt-get install -y gnupg curl

    # MongoDB 8.0 repository (7.0 não tem repo pra Noble)
    echo "Adding MongoDB 8.0 repository..."
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
      gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
    echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | \
      tee /etc/apt/sources.list.d/mongodb-org-8.0.list

    # Pritunl repository
    echo "Adding Pritunl repository..."
    curl -fsSL https://raw.githubusercontent.com/pritunl/pgp/master/pritunl_repo_pub.asc | \
      gpg --dearmor -o /usr/share/keyrings/pritunl.gpg
    echo "deb [signed-by=/usr/share/keyrings/pritunl.gpg] https://repo.pritunl.com/stable/apt noble main" | \
      tee /etc/apt/sources.list.d/pritunl.list

    # Install MongoDB + Pritunl
    echo "Installing MongoDB and Pritunl..."
    apt-get update -y
    apt-get install -y mongodb-org pritunl

    # Enable and start services
    echo "Starting services..."
    systemctl enable mongod pritunl
    systemctl start mongod
    sleep 5
    systemctl start pritunl

    echo "=== Pritunl setup completed - $(date) ==="
    echo "Run 'sudo pritunl setup-key' to get the initial setup key"
  USERDATA
}

resource "aws_instance" "vpn" {
  ami                    = data.aws_ami.ubuntu_2404.id
  instance_type          = var.vpn_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.saopaulo_public.id
  vpc_security_group_ids = [aws_security_group.vpn.id]
  user_data              = local.pritunl_user_data

  root_block_device {
    volume_size           = var.vpn_ebs_volume_size
    volume_type           = var.ebs_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name   = "prod-vpn"
    Role   = "VPN-Server"
    Region = "sa-east-1"
  }

  volume_tags = {
    Name = "prod-vpn-volume"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# Elastic IP for VPN — IP fixo para profiles OpenVPN
resource "aws_eip" "vpn" {
  instance = aws_instance.vpn.id
  domain   = "vpc"

  tags = {
    Name = "prod-eip-vpn"
  }
}

################################################################################
# EC2 Instance - Gateway Server (Virginia)
################################################################################
resource "aws_instance" "gateway" {
  provider               = aws.virginia
  ami                    = data.aws_ami.windows_2025_virginia.id
  instance_type          = var.gateway_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.virginia_public.id
  vpc_security_group_ids = [aws_security_group.gateway.id]

  root_block_device {
    volume_size           = var.gateway_ebs_volume_size
    volume_type           = var.ebs_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name   = "prod-gateway"
    Role   = "Gateway-Server"
    Region = "us-east-1"
  }

  volume_tags = {
    Name = "prod-gateway-volume"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

################################################################################
# EC2 Instance - Automator Server (Virginia)
################################################################################
resource "aws_instance" "automator" {
  provider               = aws.virginia
  ami                    = data.aws_ami.windows_2025_virginia.id
  instance_type          = var.automator_instance_type
  key_name               = var.key_pair_name
  subnet_id              = aws_subnet.virginia_public.id
  vpc_security_group_ids = [aws_security_group.automator.id]

  root_block_device {
    volume_size           = var.automator_ebs_volume_size
    volume_type           = var.ebs_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name   = "prod-automator"
    Role   = "Automator-Server"
    Region = "us-east-1"
  }

  volume_tags = {
    Name = "prod-automator-volume"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}
