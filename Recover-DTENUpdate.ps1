<#
.SYNOPSIS
    Automated DTEN Windows Update & Driver Recovery Script.
    Targets: Windows 10 Enterprise LTSC 1809 (Zoom Rooms).
    Resolves: Error 0x80070422 and Camera detection issues.
#>

# --- 1. Elevated Privilege Check ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "CRITICAL: This script must be run as an Administrator."
    exit
}

Write-Host "📡 Starting DTEN Windows Update & Driver Recovery..." -ForegroundColor Cyan

# --- 2. Resolve Service Configuration (Fix 0x80070422) ---
$Services = @("wuauserv", "bits", "cryptSvc")
foreach ($Svc in $Services) {
    Write-Host "⚙️ Configuring service: $Svc"
    Set-Service $Svc -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service $Svc -ErrorAction SilentlyContinue
}

# --- 3. Refresh Software Distribution Cache ---
Write-Host "🧹 Clearing Windows Update Cache..." -ForegroundColor Yellow
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
try {
    if (Test-Path "C:\Windows\SoftwareDistribution") {
        Remove-Item -Recurse -Force "C:\Windows\SoftwareDistribution" -ErrorAction Stop
    }
    Write-Host "✅ Cache cleared successfully." -ForegroundColor Green
} catch {
    Write-Warning "⚠️ Could not clear cache. Some files may be in use."
}
Start-Service wuauserv

# --- 4. Install PowerShell Windows Update Module ---
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "📦 Installing PSWindowsUpdate Module..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue
    Install-Module PSWindowsUpdate -Force -SkipPublisherCheck -Confirm:$false
}

# --- 5. Force Driver Detection & Installation ---
Write-Host "🚀 Forcing driver and update check... DTEN may reboot." -ForegroundColor Green

# Use the module to specifically target drivers and updates
# -AcceptAll and -AutoReboot ensure the DTEN returns to service automatically
Get-WindowsUpdate -Install -AcceptAll -AutoReboot -Verbose