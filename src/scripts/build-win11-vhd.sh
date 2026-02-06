#!/usr/bin/env bash
################################################################################
# build-win11-vhd.sh
#
# Builds a Windows 11 VHD on a Linux EC2 instance (c5.metal with KVM),
# uploads it to S3, and imports it as an AMI via aws ec2 import-image.
#
# Usage:
#   ./build-win11-vhd.sh [--bucket BUCKET] [--region REGION] [--disk-size SIZE_GB]
#
# Prerequisites:
#   - Run on an EC2 c5.metal instance (KVM support required)
#   - AWS CLI configured with appropriate permissions
#   - Sufficient disk space (~100GB recommended)
################################################################################

set -euo pipefail

################################################################################
# Configuration
################################################################################
BUCKET="${BUCKET:-cuez-cloud-vmimport}"
REGION="${REGION:-sa-east-1}"
DISK_SIZE="${DISK_SIZE:-64}"
WORK_DIR="${WORK_DIR:-/opt/win11-build}"
VHD_FILE="${WORK_DIR}/win11.vhd"
ISO_FILE="${WORK_DIR}/win11.iso"
VIRTIO_ISO="${WORK_DIR}/virtio-win.iso"
AUTOUNATTEND_DIR="${WORK_DIR}/autounattend"
AUTOUNATTEND_ISO="${WORK_DIR}/autounattend.iso"
S3_KEY="vhd/win11-$(date +%Y%m%d-%H%M%S).vhd"

# Windows 11 Enterprise Evaluation ISO URL (from Microsoft Evaluation Center)
# Update this URL if it changes — check https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise
WIN11_ISO_URL="${WIN11_ISO_URL:-}"

# VirtIO drivers for AWS/KVM
VIRTIO_ISO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"

################################################################################
# Parse arguments
################################################################################
while [[ $# -gt 0 ]]; do
  case $1 in
    --bucket)  BUCKET="$2";    shift 2 ;;
    --region)  REGION="$2";    shift 2 ;;
    --disk-size) DISK_SIZE="$2"; shift 2 ;;
    --iso-url) WIN11_ISO_URL="$2"; shift 2 ;;
    --help)
      echo "Usage: $0 [--bucket BUCKET] [--region REGION] [--disk-size SIZE_GB] [--iso-url URL]"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

################################################################################
# Helper functions
################################################################################
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

die() {
  log "ERROR: $*" >&2
  exit 1
}

check_kvm() {
  if [[ ! -e /dev/kvm ]]; then
    die "KVM not available. This script must run on a bare-metal instance (e.g., c5.metal)."
  fi
  log "KVM is available"
}

################################################################################
# Step 1: Install dependencies
################################################################################
install_dependencies() {
  log "Installing QEMU and dependencies..."

  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq qemu-system-x86 qemu-utils genisoimage curl wget
  elif command -v yum &>/dev/null; then
    sudo yum install -y qemu-kvm qemu-img genisoimage curl wget
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y qemu-kvm qemu-img genisoimage curl wget
  else
    die "Unsupported package manager. Install QEMU manually."
  fi

  log "Dependencies installed"
}

################################################################################
# Step 2: Download ISOs
################################################################################
download_isos() {
  mkdir -p "${WORK_DIR}"

  # Windows 11 ISO
  if [[ -f "${ISO_FILE}" ]]; then
    log "Windows 11 ISO already exists, skipping download"
  else
    if [[ -z "${WIN11_ISO_URL}" ]]; then
      die "Windows 11 ISO URL not set. Download manually from https://www.microsoft.com/en-us/evalcenter/evaluate-windows-11-enterprise and set WIN11_ISO_URL or use --iso-url."
    fi
    log "Downloading Windows 11 ISO..."
    wget -O "${ISO_FILE}" "${WIN11_ISO_URL}"
    log "Windows 11 ISO downloaded"
  fi

  # VirtIO drivers
  if [[ -f "${VIRTIO_ISO}" ]]; then
    log "VirtIO ISO already exists, skipping download"
  else
    log "Downloading VirtIO drivers ISO..."
    wget -O "${VIRTIO_ISO}" "${VIRTIO_ISO_URL}"
    log "VirtIO ISO downloaded"
  fi
}

################################################################################
# Step 3: Generate autounattend.xml
################################################################################
generate_autounattend() {
  log "Generating autounattend.xml..."

  mkdir -p "${AUTOUNATTEND_DIR}"

  cat > "${AUTOUNATTEND_DIR}/autounattend.xml" << 'XMLEOF'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">

  <!-- Bypass TPM / SecureBoot / RAM checks -->
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral"
               versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">

      <UserData>
        <ProductKey>
          <!-- Windows 11 Enterprise Evaluation (no key needed) -->
          <Key></Key>
          <WillShowUI>OnError</WillShowUI>
        </ProductKey>
        <AcceptEula>true</AcceptEula>
      </UserData>

      <DiskConfiguration>
        <Disk wcm:action="add">
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
          <CreatePartitions>
            <CreatePartition wcm:action="add">
              <Order>1</Order>
              <Type>EFI</Type>
              <Size>260</Size>
            </CreatePartition>
            <CreatePartition wcm:action="add">
              <Order>2</Order>
              <Type>MSR</Type>
              <Size>128</Size>
            </CreatePartition>
            <CreatePartition wcm:action="add">
              <Order>3</Order>
              <Type>Primary</Type>
              <Extend>true</Extend>
            </CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add">
              <Order>1</Order>
              <PartitionID>1</PartitionID>
              <Format>FAT32</Format>
              <Label>System</Label>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
              <Order>2</Order>
              <PartitionID>2</PartitionID>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
              <Order>3</Order>
              <PartitionID>3</PartitionID>
              <Format>NTFS</Format>
              <Label>Windows</Label>
            </ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>

      <ImageInstall>
        <OSImage>
          <InstallTo>
            <DiskID>0</DiskID>
            <PartitionID>3</PartitionID>
          </InstallTo>
        </OSImage>
      </ImageInstall>

      <RunSynchronous>
        <RunSynchronousCommand wcm:action="add">
          <Order>1</Order>
          <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1 /f</Path>
          <Description>Bypass TPM Check</Description>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
          <Order>2</Order>
          <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f</Path>
          <Description>Bypass SecureBoot Check</Description>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
          <Order>3</Order>
          <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1 /f</Path>
          <Description>Bypass RAM Check</Description>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
          <Order>4</Order>
          <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassStorageCheck /t REG_DWORD /d 1 /f</Path>
          <Description>Bypass Storage Check</Description>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
          <Order>5</Order>
          <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassCPUCheck /t REG_DWORD /d 1 /f</Path>
          <Description>Bypass CPU Check</Description>
        </RunSynchronousCommand>
      </RunSynchronous>

    </component>

    <!-- Load VirtIO drivers during install -->
    <component name="Microsoft-Windows-PnpCustomizationsWinPE" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral"
               versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <DriverPaths>
        <PathAndCredentials wcm:action="add" wcm:keyValue="1">
          <Path>E:\vioscsi\w11\amd64</Path>
        </PathAndCredentials>
        <PathAndCredentials wcm:action="add" wcm:keyValue="2">
          <Path>E:\viostor\w11\amd64</Path>
        </PathAndCredentials>
        <PathAndCredentials wcm:action="add" wcm:keyValue="3">
          <Path>E:\NetKVM\w11\amd64</Path>
        </PathAndCredentials>
      </DriverPaths>
    </component>
  </settings>

  <!-- OOBE settings -->
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral"
               versionScope="nonSxS">
      <InputLocale>en-US</InputLocale>
      <SystemLocale>en-US</SystemLocale>
      <UILanguage>en-US</UILanguage>
      <UserLocale>en-US</UserLocale>
    </component>

    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral"
               versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <ProtectYourPC>3</ProtectYourPC>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>

      <UserAccounts>
        <AdministratorPassword>
          <Value>Cuez2024!</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Password>
              <Value>Cuez2024!</Value>
              <PlainText>true</PlainText>
            </Password>
            <DisplayName>Admin</DisplayName>
            <Group>Administrators</Group>
            <Name>Admin</Name>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>

      <AutoLogon>
        <Enabled>true</Enabled>
        <Username>Admin</Username>
        <Password>
          <Value>Cuez2024!</Value>
          <PlainText>true</PlainText>
        </Password>
        <LogonCount>3</LogonCount>
      </AutoLogon>

      <RegisteredOrganization>CazeTV</RegisteredOrganization>
      <RegisteredOwner>Admin</RegisteredOwner>
      <TimeZone>E. South America Standard Time</TimeZone>
    </component>
  </settings>

  <!-- Enable RDP and install VirtIO drivers post-install -->
  <settings pass="specialize">
    <component name="Microsoft-Windows-TerminalServices-LocalSessionManager" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral"
               versionScope="nonSxS">
      <fDenyTSConnections>false</fDenyTSConnections>
    </component>

    <component name="Networking-MPSSVC-Svc" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral"
               versionScope="nonSxS">
      <FirewallGroups>
        <FirewallGroup wcm:action="add">
          <Active>true</Active>
          <Group>Remote Desktop</Group>
          <Profile>all</Profile>
        </FirewallGroup>
      </FirewallGroups>
    </component>

    <component name="Microsoft-Windows-PnpCustomizationsNonWinPE" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral"
               versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <DriverPaths>
        <PathAndCredentials wcm:action="add" wcm:keyValue="1">
          <Path>E:\vioscsi\w11\amd64</Path>
        </PathAndCredentials>
        <PathAndCredentials wcm:action="add" wcm:keyValue="2">
          <Path>E:\viostor\w11\amd64</Path>
        </PathAndCredentials>
        <PathAndCredentials wcm:action="add" wcm:keyValue="3">
          <Path>E:\NetKVM\w11\amd64</Path>
        </PathAndCredentials>
        <PathAndCredentials wcm:action="add" wcm:keyValue="4">
          <Path>E:\Balloon\w11\amd64</Path>
        </PathAndCredentials>
        <PathAndCredentials wcm:action="add" wcm:keyValue="5">
          <Path>E:\pvpanic\w11\amd64</Path>
        </PathAndCredentials>
        <PathAndCredentials wcm:action="add" wcm:keyValue="6">
          <Path>E:\qxldod\w11\amd64</Path>
        </PathAndCredentials>
      </DriverPaths>
    </component>

    <!-- Enable EC2Launch / Sysprep compatibility -->
    <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral"
               versionScope="nonSxS">
      <RunSynchronous>
        <RunSynchronousCommand wcm:action="add">
          <Order>1</Order>
          <Path>cmd /c powershell -Command "Set-ExecutionPolicy RemoteSigned -Force"</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add">
          <Order>2</Order>
          <Path>cmd /c powershell -Command "Enable-PSRemoting -Force -SkipNetworkProfileCheck"</Path>
        </RunSynchronousCommand>
      </RunSynchronous>
    </component>
  </settings>

</unattend>
XMLEOF

  # Create the autounattend ISO (to attach to QEMU)
  genisoimage -o "${AUTOUNATTEND_ISO}" \
    -J -r -iso-level 4 \
    "${AUTOUNATTEND_DIR}/"

  log "autounattend.xml and ISO generated"
}

################################################################################
# Step 4: Create VHD and install Windows
################################################################################
create_vhd_and_install() {
  log "Creating ${DISK_SIZE}GB VHD disk..."
  qemu-img create -f vpc "${VHD_FILE}" "${DISK_SIZE}G"
  log "VHD created: ${VHD_FILE}"

  log "Starting Windows 11 installation via QEMU + KVM..."
  log "This will take 15-30 minutes. The VM will auto-shutdown when installation completes."

  # Phase 1: Boot from ISO and start installation
  qemu-system-x86_64 \
    -enable-kvm \
    -machine q35 \
    -cpu host \
    -smp 4 \
    -m 8192 \
    -drive file="${VHD_FILE}",format=vpc,if=virtio \
    -drive file="${ISO_FILE}",media=cdrom,index=0 \
    -drive file="${VIRTIO_ISO}",media=cdrom,index=1 \
    -drive file="${AUTOUNATTEND_ISO}",media=cdrom,index=2 \
    -boot d \
    -vga std \
    -display none \
    -serial stdio \
    -net nic,model=virtio \
    -net user \
    -no-reboot

  log "Phase 1 complete (first reboot). Starting Phase 2..."

  # Phase 2: Boot from disk to complete OOBE
  qemu-system-x86_64 \
    -enable-kvm \
    -machine q35 \
    -cpu host \
    -smp 4 \
    -m 8192 \
    -drive file="${VHD_FILE}",format=vpc,if=virtio \
    -drive file="${VIRTIO_ISO}",media=cdrom,index=1 \
    -boot c \
    -vga std \
    -display none \
    -serial stdio \
    -net nic,model=virtio \
    -net user \
    -no-reboot

  log "Windows 11 installation completed"
}

################################################################################
# Step 5: Upload VHD to S3
################################################################################
upload_to_s3() {
  log "Uploading VHD to s3://${BUCKET}/${S3_KEY}..."

  aws s3 cp "${VHD_FILE}" "s3://${BUCKET}/${S3_KEY}" \
    --region "${REGION}" \
    --no-progress

  log "Upload complete: s3://${BUCKET}/${S3_KEY}"
}

################################################################################
# Step 6: Import as AMI
################################################################################
import_ami() {
  log "Starting EC2 import-image..."

  IMPORT_TASK_ID=$(aws ec2 import-image \
    --region "${REGION}" \
    --description "Windows 11 Enterprise for vMix - $(date +%Y%m%d)" \
    --license-type BYOL \
    --disk-containers "[{
      \"Description\": \"Windows 11 Enterprise VHD\",
      \"Format\": \"VHD\",
      \"UserBucket\": {
        \"S3Bucket\": \"${BUCKET}\",
        \"S3Key\": \"${S3_KEY}\"
      }
    }]" \
    --role-name vmimport \
    --output text \
    --query 'ImportTaskId')

  log "Import task started: ${IMPORT_TASK_ID}"
  log "Monitoring progress..."

  while true; do
    STATUS_JSON=$(aws ec2 describe-import-image-tasks \
      --region "${REGION}" \
      --import-task-ids "${IMPORT_TASK_ID}" \
      --output json)

    STATUS=$(echo "${STATUS_JSON}" | python3 -c "
import sys, json
task = json.load(sys.stdin)['ImportImageTasks'][0]
status = task.get('Status', 'unknown')
progress = task.get('Progress', '0')
msg = task.get('StatusMessage', '')
print(f'{status}|{progress}|{msg}')
")

    IFS='|' read -r STATE PROGRESS MESSAGE <<< "${STATUS}"

    case "${STATE}" in
      completed)
        AMI_ID=$(echo "${STATUS_JSON}" | python3 -c "
import sys, json
task = json.load(sys.stdin)['ImportImageTasks'][0]
print(task.get('ImageId', 'unknown'))
")
        log "Import completed! AMI ID: ${AMI_ID}"

        # Tag the AMI
        aws ec2 create-tags \
          --region "${REGION}" \
          --resources "${AMI_ID}" \
          --tags \
            Key=Name,Value="Windows11-vMix-$(date +%Y%m%d)" \
            Key=Project,Value="cuez-cloud" \
            Key=OS,Value="Windows 11 Enterprise" \
            Key=Purpose,Value="vMix Server"

        log "AMI tagged successfully"
        log ""
        log "============================================"
        log "  AMI ready: ${AMI_ID}"
        log "  Use with Terraform:"
        log "    terraform apply -var=\"vmix_ami_id=${AMI_ID}\""
        log "============================================"
        return 0
        ;;
      deleted|error)
        die "Import failed: ${MESSAGE}"
        ;;
      *)
        log "Status: ${STATE} | Progress: ${PROGRESS}% | ${MESSAGE}"
        sleep 30
        ;;
    esac
  done
}

################################################################################
# Main
################################################################################
main() {
  log "=========================================="
  log "  Windows 11 VHD Builder for vMix/EC2"
  log "=========================================="
  log "Bucket: ${BUCKET}"
  log "Region: ${REGION}"
  log "Disk:   ${DISK_SIZE}GB"
  log ""

  check_kvm
  install_dependencies
  download_isos
  generate_autounattend
  create_vhd_and_install
  upload_to_s3
  import_ami

  log "All done!"
}

main "$@"
