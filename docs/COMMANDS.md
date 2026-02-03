# Commands Reference

Comandos úteis para gerenciamento da infraestrutura Cuez Cloud.

## Terraform

### Inicialização e Deploy

```bash
# Inicializar Terraform (primeira vez ou após mudança de providers)
cd src/terraform
terraform init

# Validar sintaxe dos arquivos
terraform validate

# Formatar arquivos (fix style)
terraform fmt

# Preview das mudanças
terraform plan

# Aplicar mudanças
terraform apply

# Aplicar sem confirmação interativa
terraform apply -auto-approve

# Destruir infraestrutura (CUIDADO!)
terraform destroy
```

### Estado e Outputs

```bash
# Listar recursos no state
terraform state list

# Ver estado de um recurso específico
terraform state show aws_instance.vmix

# Ver todos os outputs
terraform output

# Ver output específico
terraform output vmix_public_ip
terraform output cuez_public_ip

# Output em formato JSON
terraform output -json
```

### Troubleshooting

```bash
# Refresh state (sincronizar com AWS)
terraform refresh

# Importar recurso existente
terraform import aws_instance.vmix i-1234567890abcdef0

# Remover recurso do state (sem destruir)
terraform state rm aws_instance.vmix

# Unlock state (se travado)
terraform force-unlock <LOCK_ID>
```

## AWS CLI

### EC2

```bash
# Listar instâncias
aws ec2 describe-instances --region sa-east-1 \
  --filters "Name=tag:Project,Values=cuez-cloud" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Start/Stop instâncias
aws ec2 start-instances --instance-ids i-xxx --region sa-east-1
aws ec2 stop-instances --instance-ids i-xxx --region sa-east-1

# Reboot instância
aws ec2 reboot-instances --instance-ids i-xxx --region sa-east-1

# Get Windows password
aws ec2 get-password-data --instance-id i-xxx --priv-launch-key ~/key.pem --region sa-east-1
```

### VPC e Security Groups

```bash
# Listar VPCs
aws ec2 describe-vpcs --region sa-east-1 \
  --filters "Name=tag:Project,Values=cuez-cloud" \
  --query 'Vpcs[].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Listar Security Groups
aws ec2 describe-security-groups --region sa-east-1 \
  --filters "Name=tag:Project,Values=cuez-cloud" \
  --query 'SecurityGroups[].[GroupId,GroupName]' \
  --output table

# Ver regras de um SG
aws ec2 describe-security-groups --group-ids sg-xxx --region sa-east-1
```

### Custos

```bash
# Custo do mês atual (requer ce:GetCostAndUsage permission)
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "BlendedCost" \
  --filter '{"Tags":{"Key":"Project","Values":["cuez-cloud"]}}'
```

## RDP (Remote Desktop)

### Windows/macOS

```bash
# Conectar via mstsc (Windows)
mstsc /v:<PUBLIC_IP>

# macOS - Microsoft Remote Desktop
open "rdp://full%20address=s:<PUBLIC_IP>"
```

### Linux

```bash
# Remmina
remmina -c rdp://<PUBLIC_IP>

# xfreerdp
xfreerdp /v:<PUBLIC_IP> /u:Administrator /p:<PASSWORD> /cert:ignore
```

## Curl - Health Checks

### HTTP Checks

```bash
# Check vMix HTTP (porta 80)
curl -I http://<VMIX_IP>/

# Check Cuez HTTP
curl -I http://<CUEZ_IP>/

# Check Cuez HTTPS
curl -Ik https://<CUEZ_IP>/

# Com timeout
curl -I --connect-timeout 5 http://<IP>/
```

### SRT Check (vMix)

```bash
# Testar conectividade UDP 514 (requer netcat)
nc -zuv <VMIX_IP> 514

# Usando nmap
nmap -sU -p 514 <VMIX_IP>
```

## Validação

### Terraform

```bash
# Verificar formatação
terraform fmt -check -recursive

# Validar configuração
terraform validate

# Security scan com tfsec
tfsec src/terraform/

# Lint com tflint
tflint src/terraform/
```

### Conectividade

```bash
# Ping (se ICMP estiver habilitado)
ping -c 3 <IP>

# Traceroute
traceroute <IP>

# Check porta RDP
nc -zv <IP> 3389

# Check porta HTTP
nc -zv <IP> 80

# Check múltiplas portas
nmap -p 80,443,3389 <IP>
```

### Windows (PowerShell)

```powershell
# Test connection
Test-NetConnection -ComputerName <IP> -Port 3389

# Check all ports
@(80, 443, 3389) | ForEach-Object {
    Test-NetConnection -ComputerName <IP> -Port $_ -WarningAction SilentlyContinue |
    Select-Object ComputerName, RemotePort, TcpTestSucceeded
}
```

## Git

```bash
# Status
git status

# Add e commit
git add .
git commit -m "feat: description"

# Push
git push origin main

# Tags
git tag -a v0.1.0 -m "Initial release"
git push origin v0.1.0
```
