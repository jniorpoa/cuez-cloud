#Requires -RunAsAdministrator
################################################################################
# Cuez Cloud - Cuez Server Setup Script
# Run this script as Administrator on the Cuez EC2 instance
################################################################################

param(
    [switch]$SkipWindowsUpdate,
    [switch]$SkipReboot
)

$ErrorActionPreference = "Stop"
$LogPath = "C:\cuez\logs"
$LogFile = "$LogPath\setup-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').log"

# Create log directory
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

function Install-Chocolatey {
    Write-Log "Checking Chocolatey installation..."

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Log "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        Write-Log "Chocolatey installed successfully"
    } else {
        Write-Log "Chocolatey already installed"
    }
}

function Install-BasePackages {
    Write-Log "Installing base packages via Chocolatey..."

    $packages = @(
        "7zip",
        "git",
        "curl"
    )

    foreach ($package in $packages) {
        Write-Log "Installing $package..."
        choco install $package -y --no-progress
    }

    Write-Log "Base packages installed"
}

function Install-IIS {
    Write-Log "Installing IIS (Internet Information Services)..."

    # Check if IIS is already installed
    $iisFeature = Get-WindowsFeature -Name Web-Server -ErrorAction SilentlyContinue

    if ($iisFeature -and $iisFeature.Installed) {
        Write-Log "IIS already installed"
    } else {
        # Install IIS with common features
        $features = @(
            "Web-Server",
            "Web-Common-Http",
            "Web-Default-Doc",
            "Web-Dir-Browsing",
            "Web-Http-Errors",
            "Web-Static-Content",
            "Web-Http-Logging",
            "Web-Stat-Compression",
            "Web-Filtering",
            "Web-Mgmt-Console",
            "Web-Mgmt-Tools"
        )

        foreach ($feature in $features) {
            Write-Log "Installing feature: $feature"
            Install-WindowsFeature -Name $feature -IncludeManagementTools -ErrorAction SilentlyContinue
        }

        Write-Log "IIS installed successfully"
    }

    # Ensure IIS service is running
    Start-Service W3SVC -ErrorAction SilentlyContinue
    Set-Service W3SVC -StartupType Automatic
    Write-Log "IIS service configured and running"
}

function Update-Windows {
    if ($SkipWindowsUpdate) {
        Write-Log "Skipping Windows Update (flag set)"
        return
    }

    Write-Log "Starting Windows Update..."

    # Install PSWindowsUpdate module if not present
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Log "Installing PSWindowsUpdate module..."
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
    }

    Import-Module PSWindowsUpdate

    Write-Log "Checking for updates..."
    $updates = Get-WindowsUpdate -AcceptAll -IgnoreReboot

    if ($updates.Count -gt 0) {
        Write-Log "Found $($updates.Count) updates. Installing..."
        Install-WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$false
        Write-Log "Windows updates installed"
    } else {
        Write-Log "No updates available"
    }
}

function Set-FirewallRules {
    Write-Log "Configuring Windows Firewall rules..."

    # RDP (should already be enabled, but ensure it)
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue

    # HTTP Port 80
    $httpRule = Get-NetFirewallRule -DisplayName "HTTP Inbound (TCP 80)" -ErrorAction SilentlyContinue
    if (-not $httpRule) {
        New-NetFirewallRule -DisplayName "HTTP Inbound (TCP 80)" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 80 `
            -Action Allow `
            -Profile Any
        Write-Log "HTTP firewall rule created"
    }

    # HTTPS Port 443
    $httpsRule = Get-NetFirewallRule -DisplayName "HTTPS Inbound (TCP 443)" -ErrorAction SilentlyContinue
    if (-not $httpsRule) {
        New-NetFirewallRule -DisplayName "HTTPS Inbound (TCP 443)" `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort 443 `
            -Action Allow `
            -Profile Any
        Write-Log "HTTPS firewall rule created"
    }

    Write-Log "Firewall rules configured"
}

function Initialize-CuezDirectories {
    Write-Log "Creating Cuez directories..."

    $directories = @(
        "C:\cuez",
        "C:\cuez\logs",
        "C:\cuez\web",
        "C:\cuez\data",
        "C:\cuez\backups"
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Log "Created directory: $dir"
        }
    }
}

################################################################################
# Main Execution
################################################################################

Write-Log "=========================================="
Write-Log "Cuez Server Setup Started"
Write-Log "=========================================="

try {
    Initialize-CuezDirectories
    Install-Chocolatey
    Install-BasePackages
    Install-IIS
    Update-Windows
    Set-FirewallRules

    Write-Log "=========================================="
    Write-Log "Cuez Server Setup Completed Successfully"
    Write-Log "=========================================="
    Write-Log "Log file: $LogFile"

    if (-not $SkipReboot) {
        Write-Log "System will reboot in 60 seconds..."
        Write-Log "Run 'shutdown /a' to cancel reboot"
        shutdown /r /t 60 /c "Cuez setup complete - rebooting"
    }

} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Log "Stack Trace: $($_.ScriptStackTrace)"
    throw
}
