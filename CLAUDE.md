# CLAUDE.md - Cuez Cloud Project

## Project Context

Este projeto gerencia a infraestrutura AWS multi-region para servidores de broadcast vMix, Gateway (Cuez) e Automator. Utiliza Terraform para provisionamento em duas regiões: sa-east-1 (São Paulo) e us-east-1 (Virginia), conectadas via VPC Peering.

## Architecture Overview

### Multi-Region Layout
```
┌─────────────────────────────────┐  VPC Peering  ┌─────────────────────────────────┐
│  us-east-1 (Virginia)           │◄──────────────►│  sa-east-1 (São Paulo)          │
│  VPC: 10.15.1.0/24             │                │  VPC: 10.15.11.0/24             │
│                                 │                │                                 │
│  ┌───────────┐ ┌─────────────┐ │                │  ┌───────────────┐ ┌──────────┐│
│  │ Gateway   │ │ Automator   │ │                │  │ vMix          │ │ Pritunl  ││
│  │ t3.large  │ │ t3.large    │ │ ── controla ──►│  │ g4dn.2xlarge  │ │ t3.micro ││
│  │ W2025     │ │ W2025       │ │                │  │ W2025+NVIDIA  │ │ Ubuntu   ││
│  └───────────┘ └─────────────┘ │                │  └───────────────┘ └──────────┘│
└─────────────────────────────────┘                └─────────────────────────────────┘
```

### Instances
- **vMix** (SP): g4dn.2xlarge (8 vCPU, 32GB, NVIDIA T4), 500GB gp3, Windows Server 2025 — EIP: 54.94.57.229
- **Gateway** (Virginia): t3.large, 100GB gp3, Windows Server 2025 — máquina mãe da Cuez — EIP: 13.223.20.168
- **Automator** (Virginia): t3.large, 100GB gp3, Windows Server 2025 — conversa com o Gateway — EIP: 3.232.241.70
- **VPN/Pritunl** (SP): t3.micro, 30GB gp3, Ubuntu 24.04 — VPN para acesso admin por IP privado — EIP: 54.20.7.43
- **Security**: Allowlist por provedor (ALGAR, MUNDIVOX, EMBRATEL, SAMM, UFINET), cross-VPC via peering, VPN Pritunl

## Key Files

```
src/terraform/
├── main.tf              # Dual provider (SP + Virginia), AMI Windows 2025 + Ubuntu 24.04
├── variables.tf         # Variáveis com defaults para ambas regiões
├── vpc.tf               # Dual VPC, Subnets, IGW, Routes, VPC Peering
├── security-groups.tf   # sg-vmix (SP), sg-vpn (SP), sg-gateway (VA), sg-automator (VA)
├── ec2.tf               # 4 EC2 instances + 4 Elastic IPs
└── outputs.tf           # IPs, IDs, connection strings para 4 máquinas

src/scripts/
├── setup-vmix.ps1       # Setup vMix server
└── setup-cuez.ps1       # Setup Cuez server (inclui IIS)
```

## Common Tasks

### Deploy Infrastructure
```bash
cd src/terraform
terraform init          # Registra providers de ambas regiões
terraform plan
terraform apply
```

### Connect via RDP
```bash
mstsc /v:54.94.57.229    # vMix (SP)
mstsc /v:13.223.20.168   # Gateway (Virginia)
mstsc /v:3.232.241.70    # Automator (Virginia)
# User: livemode / L1veM0de@2026!
```

### Connect via VPN
```bash
# Pritunl web UI
https://54.20.7.43

# SSH
ssh -i cuez-cloud-key.pem ubuntu@54.20.7.43

# Após conectar VPN, acessar por IP privado:
mstsc /v:10.15.11.19    # vMix
mstsc /v:10.15.1.105    # Gateway
mstsc /v:10.15.1.192    # Automator
```

### Run Setup Scripts
```powershell
# On vMix server (as Admin)
.\setup-vmix.ps1 -SkipReboot

# On Gateway server (as Admin)
.\setup-cuez.ps1 -SkipReboot
```

### NVIDIA GRID Driver (vMix — após nova instância)
```powershell
New-Item -ItemType Directory -Force -Path "C:\vmix\drivers"
$s3Key = (aws s3 ls "s3://ec2-windows-nvidia-drivers/latest/" --no-sign-request | Where-Object { $_ -match "\.exe$" } | Sort-Object | Select-Object -Last 1) -replace '.*\s+', ''
aws s3 cp "s3://ec2-windows-nvidia-drivers/latest/$s3Key" "C:\vmix\drivers\NVIDIA-GRID-driver.exe" --no-sign-request
Start-Process -FilePath "C:\vmix\drivers\NVIDIA-GRID-driver.exe" -ArgumentList "/s /noreboot" -Wait -NoNewWindow
# DirectX
Invoke-WebRequest -Uri "https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe" -OutFile "C:\vmix\drivers\dxwebsetup.exe"
Start-Process -FilePath "C:\vmix\drivers\dxwebsetup.exe" -ArgumentList "/Q" -Wait -NoNewWindow
Restart-Computer -Force
```

### Windows Firewall — Ping + SMB cross-region
```powershell
# Rodar em AMBAS as máquinas (vMix e Automator)
New-NetFirewallRule -DisplayName "ICMP Allow Ping" -Direction Inbound -Protocol ICMPv4 -Action Allow -Profile Any
Enable-NetFirewallRule -DisplayGroup "File and Printer Sharing"

# No vMix — liberar SMB do Automator (Virginia)
New-NetFirewallRule -DisplayName "SMB Inbound (TCP 445)" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow -RemoteAddress 10.15.1.0/24 -Profile Any

# No Automator — liberar SMB do vMix (SP)
New-NetFirewallRule -DisplayName "SMB Inbound (TCP 445)" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow -RemoteAddress 10.15.11.0/24 -Profile Any
```

### SMB Share — Mapear pasta do vMix no Automator
```powershell
# No vMix — compartilhar pasta
New-SmbShare -Name "Cuez_Media" -Path "D:\Cuez_Media" -FullAccess "livemode"

# No Automator (logado como livemode) — mapear drive Z:
net use Z: \\10.15.11.19\Cuez_Media /user:livemode L1veM0de@2026! /persistent:yes
```

## Security Notes

- Nunca commitar terraform.tfvars (contém dados sensíveis)
- IPs de allowlist são variáveis, não hardcoded
- Egress é aberto (0.0.0.0/0) para atualizações
- Intra-VPC é aberto para comunicação entre servidores na mesma região
- Cross-region via VPC Peering (10.15.1.0/24 ↔ 10.15.11.0/24)
- VPN Pritunl para acesso admin (elimina necessidade de IPs variáveis na allowlist)
- Todas as instâncias possuem Elastic IP fixo
- Sem regras 0.0.0.0/0 no ingress (exceto VPN: HTTPS 443 + OpenVPN 1194)

## Conventions

- **Branches**: main (prod), develop, feature/*
- **Commits**: conventional commits (feat, fix, docs, etc)
- **Tags**: vX.Y.Z (semantic versioning)

## Troubleshooting

### Terraform state lock
```bash
terraform force-unlock <LOCK_ID>
```

### Windows Update failing
```powershell
# Run setup without Windows Update
.\setup-vmix.ps1 -SkipWindowsUpdate -SkipReboot
```

### IIS not starting
```powershell
Get-Service W3SVC | Start-Service
Get-WindowsFeature Web-Server
```

### VPC Peering not routing
```bash
# Verify peering is active
terraform output vpc_peering_id
# Check route tables include peering routes in both regions
```

### Ping não funciona entre VPCs
```powershell
# Verificar se Windows Firewall permite ICMP
Get-NetFirewallRule -DisplayName "ICMP Allow Ping"
# Se não existir, criar:
New-NetFirewallRule -DisplayName "ICMP Allow Ping" -Direction Inbound -Protocol ICMPv4 -Action Allow -Profile Any
```

### SMB share não acessível cross-region
```powershell
# Verificar compartilhamento no vMix
net share
# Verificar firewall SMB
Get-NetFirewallRule -DisplayName "SMB Inbound*"
# Testar conectividade
Test-NetConnection -ComputerName 10.15.11.19 -Port 445
```

### Pritunl — setup inicial
```bash
ssh -i cuez-cloud-key.pem ubuntu@54.20.7.43
sudo pritunl setup-key        # chave para web UI
sudo pritunl default-password  # credenciais padrão
# Acessar https://54.20.7.43 e configurar
```

### Pritunl — MongoDB 8.0 (Ubuntu Noble)
```bash
# MongoDB 7.0 NÃO tem repo para Noble 24.04 — usar 8.0
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
```
