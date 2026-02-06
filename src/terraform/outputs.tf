################################################################################
# Cuez Cloud - Outputs
################################################################################

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Security Group Outputs
output "sg_vmix_id" {
  description = "ID of the vMix security group"
  value       = aws_security_group.vmix.id
}

output "sg_cuez_id" {
  description = "ID of the Cuez security group"
  value       = aws_security_group.cuez.id
}

# EC2 vMix Outputs
output "vmix_instance_id" {
  description = "Instance ID of vMix server"
  value       = aws_instance.vmix.id
}

output "vmix_private_ip" {
  description = "Private IP of vMix server"
  value       = aws_instance.vmix.private_ip
}

output "vmix_public_ip" {
  description = "Public IP of vMix server"
  value       = aws_instance.vmix.public_ip
}

output "vmix_public_dns" {
  description = "Public DNS of vMix server"
  value       = aws_instance.vmix.public_dns
}

# EC2 Cuez Outputs
output "cuez_instance_id" {
  description = "Instance ID of Cuez server"
  value       = aws_instance.cuez.id
}

output "cuez_private_ip" {
  description = "Private IP of Cuez server"
  value       = aws_instance.cuez.private_ip
}

output "cuez_public_ip" {
  description = "Public IP of Cuez server"
  value       = aws_instance.cuez.public_ip
}

output "cuez_public_dns" {
  description = "Public DNS of Cuez server"
  value       = aws_instance.cuez.public_dns
}

# Connection Info
output "rdp_connection_vmix" {
  description = "RDP connection string for vMix"
  value       = "mstsc /v:${aws_instance.vmix.public_ip}"
}

output "rdp_connection_cuez" {
  description = "RDP connection string for Cuez"
  value       = "mstsc /v:${aws_instance.cuez.public_ip}"
}

# AMI Info
output "windows_ami_id" {
  description = "Windows AMI ID used"
  value       = data.aws_ami.windows_2022.id
}

output "windows_ami_name" {
  description = "Windows AMI name"
  value       = data.aws_ami.windows_2022.name
}

# vMix AMI Info
output "vmix_ami_used" {
  description = "AMI ID used for vMix server (custom W11 or fallback W2022)"
  value       = aws_instance.vmix.ami
}

# Instance Type Info
output "vmix_instance_type" {
  description = "Instance type used for vMix server"
  value       = aws_instance.vmix.instance_type
}
