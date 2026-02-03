# CLAUDE.md - Cuez Cloud Project

## Project Context

Este projeto gerencia a infraestrutura AWS para servidores de broadcast vMix e Cuez. A infraestrutura está localizada na região sa-east-1 (São Paulo) e utiliza Terraform para provisionamento.

## Architecture Overview

- **VPC**: 10.0.0.0/16 com subnet pública 10.0.1.0/24
- **EC2 vMix**: t3.xlarge, 500GB gp3, Windows Server 2022
- **EC2 Cuez**: t3.large, 500GB gp3, Windows Server 2022
- **Security**: Allowlist por provedor (ALGAR, MUNDIVOX, EMBRATEL, SAMM)

## Key Files

```
src/terraform/
├── main.tf              # Provider AWS, data sources
├── variables.tf         # Todas variáveis com defaults
├── vpc.tf               # VPC, Subnet, IGW, Routes
├── security-groups.tf   # sg-vmix, sg-cuez com allowlist
├── ec2.tf               # EC2 instances
└── outputs.tf           # IPs, IDs, connection strings

src/scripts/
├── setup-vmix.ps1       # Setup vMix server
└── setup-cuez.ps1       # Setup Cuez server (inclui IIS)
```

## Common Tasks

### Deploy Infrastructure
```bash
cd src/terraform
terraform init
terraform plan
terraform apply
```

### Connect via RDP
```bash
# Get IPs
terraform output vmix_public_ip
terraform output cuez_public_ip

# Connect
mstsc /v:<IP>
```

### Run Setup Scripts
```powershell
# On vMix server (as Admin)
.\setup-vmix.ps1 -SkipReboot

# On Cuez server (as Admin)
.\setup-cuez.ps1 -SkipReboot
```

## Security Notes

- Nunca commitar terraform.tfvars (contém dados sensíveis)
- IPs de allowlist são variáveis, não hardcoded
- Egress é aberto (0.0.0.0/0) para atualizações
- Intra-VPC é aberto para comunicação entre servidores

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
