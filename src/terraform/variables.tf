################################################################################
# Cuez Cloud - Variables
# Multi-Region: sa-east-1 (São Paulo) + us-east-1 (Virginia)
################################################################################

# AWS Configuration
variable "aws_region" {
  description = "AWS region for primary resources (São Paulo)"
  type        = string
  default     = "sa-east-1"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "cuez-cloud"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "production"
}

# VPC Configuration — São Paulo (sa-east-1)
variable "vpc_cidr" {
  description = "CIDR block for São Paulo VPC"
  type        = string
  default     = "10.15.11.0/24"
}

variable "subnet_cidr" {
  description = "CIDR block for São Paulo public subnet"
  type        = string
  default     = "10.15.11.0/24"
}

variable "availability_zone" {
  description = "Availability zone for São Paulo subnet"
  type        = string
  default     = "sa-east-1a"
}

# VPC Configuration — Virginia (us-east-1)
variable "virginia_vpc_cidr" {
  description = "CIDR block for Virginia VPC"
  type        = string
  default     = "10.15.1.0/24"
}

variable "virginia_subnet_cidr" {
  description = "CIDR block for Virginia public subnet"
  type        = string
  default     = "10.15.1.0/24"
}

variable "virginia_az" {
  description = "Availability zone for Virginia subnet"
  type        = string
  default     = "us-east-1a"
}

# EC2 Configuration — vMix (São Paulo)
variable "vmix_instance_type" {
  description = "Instance type for vMix server (g4dn.2xlarge = 8 vCPU, 32GB, NVIDIA T4)"
  type        = string
  default     = "g4dn.2xlarge"
}

variable "vmix_ebs_volume_size" {
  description = "EBS volume size in GB for vMix server"
  type        = number
  default     = 500
}

variable "enable_nvidia_driver" {
  description = "Enable NVIDIA GRID driver installation via user_data on vMix instance"
  type        = bool
  default     = true
}

# EC2 Configuration — Gateway (Virginia)
variable "gateway_instance_type" {
  description = "Instance type for Gateway server"
  type        = string
  default     = "t3.large"
}

variable "gateway_ebs_volume_size" {
  description = "EBS volume size in GB for Gateway server"
  type        = number
  default     = 100
}

# EC2 Configuration — Automator (Virginia)
variable "automator_instance_type" {
  description = "Instance type for Automator server"
  type        = string
  default     = "t3.large"
}

variable "automator_ebs_volume_size" {
  description = "EBS volume size in GB for Automator server"
  type        = number
  default     = 100
}

# EC2 Configuration — VPN (São Paulo)
variable "vpn_instance_type" {
  description = "Instance type for VPN server (Pritunl)"
  type        = string
  default     = "t3.micro"
}

variable "vpn_ebs_volume_size" {
  description = "EBS volume size in GB for VPN server"
  type        = number
  default     = 30
}

# Common EC2 Configuration
variable "ebs_volume_type" {
  description = "EBS volume type"
  type        = string
  default     = "gp3"
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair for SSH/RDP access"
  type        = string
}

# Allowlist IPs - Provedores
variable "algar_cidr" {
  description = "ALGAR IP range"
  type        = string
  default     = "189.112.178.128/28"
}

variable "mundivox_cidr_1" {
  description = "MUNDIVOX IP range 1"
  type        = string
  default     = "187.16.97.64/27"
}

variable "mundivox_cidr_2" {
  description = "MUNDIVOX IP range 2"
  type        = string
  default     = "187.102.180.144/28"
}

variable "embratel_cidr" {
  description = "EMBRATEL IP range"
  type        = string
  default     = "200.166.233.192/28"
}

variable "samm_cidr" {
  description = "SAMM IP range"
  type        = string
  default     = "201.87.158.160/28"
}


variable "ufinet_cidr" {
  description = "UFINET RJ IP range"
  type        = string
  default     = "189.84.231.16/28"
}

variable "jml747_ip" {
  description = "JML747 IP"
  type        = string
  default     = "201.54.232.170/32"
}

# Tags
variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
