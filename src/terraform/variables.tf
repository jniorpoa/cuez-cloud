################################################################################
# Cuez Cloud - Variables
################################################################################

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
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

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.15.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.15.0.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnet"
  type        = string
  default     = "sa-east-1a"
}

# EC2 Configuration
variable "vmix_instance_type" {
  description = "Instance type for vMix server (g4dn.2xlarge = 8 vCPU, 32GB, NVIDIA T4)"
  type        = string
  default     = "g4dn.2xlarge"
}

variable "enable_nvidia_driver" {
  description = "Enable NVIDIA GRID driver installation via user_data on vMix instance"
  type        = bool
  default     = true
}

variable "cuez_instance_type" {
  description = "Instance type for Cuez server"
  type        = string
  default     = "t3.large"
}

variable "ebs_volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 500
}

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

variable "admin_ip" {
  description = "Admin personal IP"
  type        = string
  default     = "138.97.240.187/32"
}

variable "admin_ip_2" {
  description = "Admin secondary IP"
  type        = string
  default     = "162.120.186.85/32"
}

# Custom AMI
variable "vmix_ami_id" {
  description = "Custom AMI ID for vMix server (Windows 11). Leave empty to use Windows Server 2022 fallback."
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
