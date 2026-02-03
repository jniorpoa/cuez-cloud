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
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnet"
  type        = string
  default     = "sa-east-1a"
}

# EC2 Configuration
variable "vmix_instance_type" {
  description = "Instance type for vMix server"
  type        = string
  default     = "t3.xlarge"
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
  default     = "189.112.178.129/28"
}

variable "mundivox_cidr_1" {
  description = "MUNDIVOX IP range 1"
  type        = string
  default     = "187.16.97.66/27"
}

variable "mundivox_cidr_2" {
  description = "MUNDIVOX IP range 2"
  type        = string
  default     = "187.102.180.146/28"
}

variable "embratel_cidr" {
  description = "EMBRATEL IP range"
  type        = string
  default     = "200.166.233.194/28"
}

variable "samm_cidr" {
  description = "SAMM IP range"
  type        = string
  default     = "201.87.158.162/28"
}

# Tags
variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
