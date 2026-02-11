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
│  ┌───────────┐ ┌─────────────┐ │                │  ┌───────────────┐              │
│  │ Gateway   │ │ Automator   │ │                │  │ vMix          │              │
│  │ t3.large  │ │ t3.large    │ │ ── controla ──►│  │ g4dn.2xlarge  │              │
│  │ W2025     │ │ W2025       │ │                │  │ W2025+NVIDIA  │              │
│  └───────────┘ └─────────────┘ │                │  └───────────────┘              │
└─────────────────────────────────┘                └─────────────────────────────────┘
```

### Instances
- **vMix** (SP): g4dn.2xlarge (8 vCPU, 32GB, NVIDIA T4), 500GB gp3, Windows Server 2025
- **Gateway** (Virginia): t3.large, 100GB gp3, Windows Server 2025 — máquina mãe da Cuez, controla o vMix
- **Automator** (Virginia): t3.large, 100GB gp3, Windows Server 2025 — conversa com o Gateway
- **Security**: Allowlist por provedor (ALGAR, MUNDIVOX, EMBRATEL, SAMM), cross-VPC via peering

## Key Files

```
src/terraform/
├── main.tf              # Dual provider (SP + Virginia), AMI Windows 2025
├── variables.tf         # Variáveis com defaults para ambas regiões
├── vpc.tf               # Dual VPC, Subnets, IGW, Routes, VPC Peering
├── security-groups.tf   # sg-vmix (SP), sg-gateway (VA), sg-automator (VA)
├── ec2.tf               # 3 EC2 instances (vMix, Gateway, Automator)
└── outputs.tf           # IPs, IDs, connection strings para 3 máquinas

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
# Get IPs
terraform output vmix_public_ip       # vMix (SP)
terraform output gateway_public_ip    # Gateway (Virginia)
terraform output automator_public_ip  # Automator (Virginia)

# Connect
mstsc /v:<IP>
```

### Run Setup Scripts
```powershell
# On vMix server (as Admin)
.\setup-vmix.ps1 -SkipReboot

# On Gateway server (as Admin)
.\setup-cuez.ps1 -SkipReboot
```

## Security Notes

- Nunca commitar terraform.tfvars (contém dados sensíveis)
- IPs de allowlist são variáveis, não hardcoded
- Egress é aberto (0.0.0.0/0) para atualizações
- Intra-VPC é aberto para comunicação entre servidores na mesma região
- Cross-region via VPC Peering (10.15.1.0/24 ↔ 10.15.11.0/24)
- Sem regras 0.0.0.0/0 no ingress (exceto egress)

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
