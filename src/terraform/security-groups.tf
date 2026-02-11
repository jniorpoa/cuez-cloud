################################################################################
# Cuez Cloud - Security Groups (Multi-Region)
################################################################################

# Lista de CIDRs permitidos (Allowlist)
locals {
  allowed_cidrs = [
    var.algar_cidr,      # ALGAR
    var.mundivox_cidr_1, # MUNDIVOX 1
    var.mundivox_cidr_2, # MUNDIVOX 2
    var.embratel_cidr,   # EMBRATEL
    var.samm_cidr,       # SAMM
    var.admin_ip,        # Admin
    var.admin_ip_2,      # Admin 2
    var.admin_ip_3,      # Admin 3
  ]
}

################################################################################
# Security Group - vMix Server (São Paulo)
################################################################################
resource "aws_security_group" "vmix" {
  name        = "prod-sg-vmix"
  description = "Security group for vMix server (Sao Paulo)"
  vpc_id      = aws_vpc.saopaulo.id

  tags = {
    Name = "prod-sg-vmix"
  }
}

# RDP (3389/TCP) - Allowlist
resource "aws_vpc_security_group_ingress_rule" "vmix_rdp" {
  for_each = toset(local.allowed_cidrs)

  security_group_id = aws_security_group.vmix.id
  description       = "RDP access from allowlist"
  from_port         = 3389
  to_port           = 3389
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# SRT (514/UDP) - Allowlist
resource "aws_vpc_security_group_ingress_rule" "vmix_srt" {
  for_each = toset(local.allowed_cidrs)

  security_group_id = aws_security_group.vmix.id
  description       = "SRT streaming from allowlist"
  from_port         = 514
  to_port           = 514
  ip_protocol       = "udp"
  cidr_ipv4         = each.value
}

# HTTP (80/TCP) - Allowlist
resource "aws_vpc_security_group_ingress_rule" "vmix_http" {
  for_each = toset(local.allowed_cidrs)

  security_group_id = aws_security_group.vmix.id
  description       = "HTTP access from allowlist"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# Intra-VPC (all traffic within SP VPC)
resource "aws_vpc_security_group_ingress_rule" "vmix_intra_vpc" {
  security_group_id = aws_security_group.vmix.id
  description       = "All traffic within SP VPC"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}

# From Virginia VPC (Gateway control)
resource "aws_vpc_security_group_ingress_rule" "vmix_from_virginia" {
  security_group_id = aws_security_group.vmix.id
  description       = "All traffic from Virginia VPC (Gateway control)"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = var.virginia_vpc_cidr
}

# Egress (all outbound)
resource "aws_vpc_security_group_egress_rule" "vmix_egress" {
  security_group_id = aws_security_group.vmix.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

################################################################################
# Security Group - Gateway Server (Virginia)
################################################################################
resource "aws_security_group" "gateway" {
  provider    = aws.virginia
  name        = "prod-sg-gateway"
  description = "Security group for Gateway server (Virginia)"
  vpc_id      = aws_vpc.virginia.id

  tags = {
    Name = "prod-sg-gateway"
  }
}

# RDP (3389/TCP) - Allowlist
resource "aws_vpc_security_group_ingress_rule" "gateway_rdp" {
  for_each = toset(local.allowed_cidrs)
  provider = aws.virginia

  security_group_id = aws_security_group.gateway.id
  description       = "RDP access from allowlist"
  from_port         = 3389
  to_port           = 3389
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# HTTP (80/TCP) - Allowlist
resource "aws_vpc_security_group_ingress_rule" "gateway_http" {
  for_each = toset(local.allowed_cidrs)
  provider = aws.virginia

  security_group_id = aws_security_group.gateway.id
  description       = "HTTP access from allowlist"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# HTTPS (443/TCP) - Allowlist
resource "aws_vpc_security_group_ingress_rule" "gateway_https" {
  for_each = toset(local.allowed_cidrs)
  provider = aws.virginia

  security_group_id = aws_security_group.gateway.id
  description       = "HTTPS access from allowlist"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# Intra-VPC (all traffic within Virginia VPC)
resource "aws_vpc_security_group_ingress_rule" "gateway_intra_vpc" {
  provider          = aws.virginia
  security_group_id = aws_security_group.gateway.id
  description       = "All traffic within Virginia VPC"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = var.virginia_vpc_cidr
}

# From SP VPC (vMix responses)
resource "aws_vpc_security_group_ingress_rule" "gateway_from_sp" {
  provider          = aws.virginia
  security_group_id = aws_security_group.gateway.id
  description       = "All traffic from SP VPC (vMix)"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}

# Egress (all outbound)
resource "aws_vpc_security_group_egress_rule" "gateway_egress" {
  provider          = aws.virginia
  security_group_id = aws_security_group.gateway.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

################################################################################
# Security Group - Automator Server (Virginia)
################################################################################
resource "aws_security_group" "automator" {
  provider    = aws.virginia
  name        = "prod-sg-automator"
  description = "Security group for Automator server (Virginia)"
  vpc_id      = aws_vpc.virginia.id

  tags = {
    Name = "prod-sg-automator"
  }
}

# RDP (3389/TCP) - Allowlist
resource "aws_vpc_security_group_ingress_rule" "automator_rdp" {
  for_each = toset(local.allowed_cidrs)
  provider = aws.virginia

  security_group_id = aws_security_group.automator.id
  description       = "RDP access from allowlist"
  from_port         = 3389
  to_port           = 3389
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# Intra-VPC (all traffic within Virginia VPC)
resource "aws_vpc_security_group_ingress_rule" "automator_intra_vpc" {
  provider          = aws.virginia
  security_group_id = aws_security_group.automator.id
  description       = "All traffic within Virginia VPC"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = var.virginia_vpc_cidr
}

# Egress (all outbound)
resource "aws_vpc_security_group_egress_rule" "automator_egress" {
  provider          = aws.virginia
  security_group_id = aws_security_group.automator.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
