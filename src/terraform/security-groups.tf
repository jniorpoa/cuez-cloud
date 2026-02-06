################################################################################
# Cuez Cloud - Security Groups
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
  ]
}

################################################################################
# Security Group - vMix Server
################################################################################
resource "aws_security_group" "vmix" {
  name        = "prod-sg-vmix"
  description = "Security group for vMix server"
  vpc_id      = aws_vpc.main.id

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

# Intra-VPC (all traffic within VPC)
resource "aws_vpc_security_group_ingress_rule" "vmix_intra_vpc" {
  security_group_id = aws_security_group.vmix.id
  description       = "All traffic within VPC"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}

# Egress (all outbound)
resource "aws_vpc_security_group_egress_rule" "vmix_egress" {
  security_group_id = aws_security_group.vmix.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

################################################################################
# Security Group - Cuez Server
################################################################################
resource "aws_security_group" "cuez" {
  name        = "prod-sg-cuez"
  description = "Security group for Cuez server"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "prod-sg-cuez"
  }
}

# RDP (3389/TCP) - Allowlist
resource "aws_vpc_security_group_ingress_rule" "cuez_rdp" {
  for_each = toset(local.allowed_cidrs)

  security_group_id = aws_security_group.cuez.id
  description       = "RDP access from allowlist"
  from_port         = 3389
  to_port           = 3389
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# HTTP (80/TCP) - Allowlist
resource "aws_vpc_security_group_ingress_rule" "cuez_http" {
  for_each = toset(local.allowed_cidrs)

  security_group_id = aws_security_group.cuez.id
  description       = "HTTP access from allowlist"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# HTTPS (443/TCP) - Allowlist
resource "aws_vpc_security_group_ingress_rule" "cuez_https" {
  for_each = toset(local.allowed_cidrs)

  security_group_id = aws_security_group.cuez.id
  description       = "HTTPS access from allowlist"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

# Intra-VPC (all traffic within VPC)
resource "aws_vpc_security_group_ingress_rule" "cuez_intra_vpc" {
  security_group_id = aws_security_group.cuez.id
  description       = "All traffic within VPC"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = var.vpc_cidr
}

# Egress (all outbound)
resource "aws_vpc_security_group_egress_rule" "cuez_egress" {
  security_group_id = aws_security_group.cuez.id
  description       = "All outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
