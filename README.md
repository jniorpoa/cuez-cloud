# Cuez Cloud

Infraestrutura AWS para servidores vMix e Cuez na região sa-east-1 (São Paulo).

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS sa-east-1                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    VPC 10.0.0.0/16                         │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │              Subnet 10.0.1.0/24                      │  │  │
│  │  │                                                       │  │  │
│  │  │   ┌─────────────┐         ┌─────────────┐           │  │  │
│  │  │   │   vMix      │         │    Cuez     │           │  │  │
│  │  │   │  t3.xlarge  │◄───────►│  t3.large   │           │  │  │
│  │  │   │  500GB gp3  │         │  500GB gp3  │           │  │  │
│  │  │   └─────────────┘         └─────────────┘           │  │  │
│  │  │         │                       │                    │  │  │
│  │  └─────────┼───────────────────────┼────────────────────┘  │  │
│  │            │                       │                        │  │
│  │  ┌─────────▼───────┐     ┌─────────▼───────┐              │  │
│  │  │   sg-vmix       │     │   sg-cuez       │              │  │
│  │  │ RDP:3389        │     │ RDP:3389        │              │  │
│  │  │ SRT:514/UDP     │     │ HTTP:80         │              │  │
│  │  │ HTTP:80         │     │ HTTPS:443       │              │  │
│  │  └─────────────────┘     └─────────────────┘              │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                   │
│                    ┌─────────▼─────────┐                        │
│                    │  Internet Gateway  │                        │
│                    └─────────┬─────────┘                        │
└──────────────────────────────┼──────────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │    Allowlist IPs    │
                    │  ALGAR | MUNDIVOX   │
                    │ EMBRATEL | SAMM     │
                    └─────────────────────┘
```

## Requisitos

- Terraform >= 1.0.0
- AWS CLI configurado
- Key pair criado na AWS

## Quick Start

```bash
# Clone o repositório
git clone https://github.com/jniorpoa/cuez-cloud.git
cd cuez-cloud/src/terraform

# Configure variáveis
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars com seus valores

# Deploy
terraform init
terraform plan
terraform apply
```

## Estrutura do Projeto

```
cuez-cloud/
├── src/
│   ├── terraform/          # Infraestrutura como código
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── vpc.tf
│   │   ├── security-groups.tf
│   │   ├── ec2.tf
│   │   └── outputs.tf
│   └── scripts/            # Scripts de configuração
│       ├── setup-vmix.ps1
│       └── setup-cuez.ps1
├── docs/                   # Documentação
│   ├── CHANGELOG.md
│   ├── COMMANDS.md
│   └── sessions/
├── assets/                 # Diagramas e recursos
│   └── architecture.md
├── README.md
└── CLAUDE.md
```

## Security Groups

| Server | Porta | Protocolo | Descrição |
|--------|-------|-----------|-----------|
| vMix   | 3389  | TCP       | RDP       |
| vMix   | 514   | UDP       | SRT       |
| vMix   | 80    | TCP       | HTTP      |
| Cuez   | 3389  | TCP       | RDP       |
| Cuez   | 80    | TCP       | HTTP      |
| Cuez   | 443   | TCP       | HTTPS     |

## Allowlist IPs

- **ALGAR**: 189.112.178.129/28
- **MUNDIVOX**: 187.16.97.66/27, 187.102.180.146/28
- **EMBRATEL**: 200.166.233.194/28
- **SAMM**: 201.87.158.162/28
- **Intra-VPC**: 10.0.0.0/16

## Post-Deploy

Após o deploy, conecte via RDP e execute os scripts de setup:

```powershell
# vMix Server
.\setup-vmix.ps1

# Cuez Server
.\setup-cuez.ps1
```

## Documentação Adicional

- [CHANGELOG](docs/CHANGELOG.md) - Histórico de mudanças
- [COMMANDS](docs/COMMANDS.md) - Comandos úteis
- [Architecture](assets/architecture.md) - Diagrama detalhado

## License

MIT
