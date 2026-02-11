################################################################################
# Cuez Cloud - Outputs (Multi-Region)
################################################################################

# VPC Outputs — São Paulo
output "vpc_sp_id" {
  description = "ID of the São Paulo VPC"
  value       = aws_vpc.saopaulo.id
}

output "vpc_sp_cidr" {
  description = "CIDR block of the São Paulo VPC"
  value       = aws_vpc.saopaulo.cidr_block
}

output "subnet_sp_id" {
  description = "ID of the São Paulo public subnet"
  value       = aws_subnet.saopaulo_public.id
}

# VPC Outputs — Virginia
output "vpc_va_id" {
  description = "ID of the Virginia VPC"
  value       = aws_vpc.virginia.id
}

output "vpc_va_cidr" {
  description = "CIDR block of the Virginia VPC"
  value       = aws_vpc.virginia.cidr_block
}

output "subnet_va_id" {
  description = "ID of the Virginia public subnet"
  value       = aws_subnet.virginia_public.id
}

# VPC Peering
output "vpc_peering_id" {
  description = "ID of the VPC peering connection (SP ↔ Virginia)"
  value       = aws_vpc_peering_connection.sp_to_virginia.id
}

# Security Group Outputs
output "sg_vmix_id" {
  description = "ID of the vMix security group (SP)"
  value       = aws_security_group.vmix.id
}

output "sg_gateway_id" {
  description = "ID of the Gateway security group (Virginia)"
  value       = aws_security_group.gateway.id
}

output "sg_automator_id" {
  description = "ID of the Automator security group (Virginia)"
  value       = aws_security_group.automator.id
}

# EC2 vMix Outputs (São Paulo)
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

# EC2 Gateway Outputs (Virginia)
output "gateway_instance_id" {
  description = "Instance ID of Gateway server"
  value       = aws_instance.gateway.id
}

output "gateway_private_ip" {
  description = "Private IP of Gateway server"
  value       = aws_instance.gateway.private_ip
}

output "gateway_public_ip" {
  description = "Public IP of Gateway server"
  value       = aws_instance.gateway.public_ip
}

output "gateway_public_dns" {
  description = "Public DNS of Gateway server"
  value       = aws_instance.gateway.public_dns
}

# EC2 Automator Outputs (Virginia)
output "automator_instance_id" {
  description = "Instance ID of Automator server"
  value       = aws_instance.automator.id
}

output "automator_private_ip" {
  description = "Private IP of Automator server"
  value       = aws_instance.automator.private_ip
}

output "automator_public_ip" {
  description = "Public IP of Automator server"
  value       = aws_instance.automator.public_ip
}

output "automator_public_dns" {
  description = "Public DNS of Automator server"
  value       = aws_instance.automator.public_dns
}

# Connection Info
output "rdp_connection_vmix" {
  description = "RDP connection string for vMix (SP)"
  value       = "mstsc /v:${aws_instance.vmix.public_ip}"
}

output "rdp_connection_gateway" {
  description = "RDP connection string for Gateway (Virginia)"
  value       = "mstsc /v:${aws_instance.gateway.public_ip}"
}

output "rdp_connection_automator" {
  description = "RDP connection string for Automator (Virginia)"
  value       = "mstsc /v:${aws_instance.automator.public_ip}"
}

# AMI Info
output "windows_2025_sp_ami_id" {
  description = "Windows Server 2025 AMI ID (São Paulo)"
  value       = data.aws_ami.windows_2025.id
}

output "windows_2025_sp_ami_name" {
  description = "Windows Server 2025 AMI name (São Paulo)"
  value       = data.aws_ami.windows_2025.name
}

output "windows_2025_va_ami_id" {
  description = "Windows Server 2025 AMI ID (Virginia)"
  value       = data.aws_ami.windows_2025_virginia.id
}

output "windows_2025_va_ami_name" {
  description = "Windows Server 2025 AMI name (Virginia)"
  value       = data.aws_ami.windows_2025_virginia.name
}
