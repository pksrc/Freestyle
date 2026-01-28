# Requires SYSTEM (Hub runs as SYSTEM by default)

$logDir = "C:\ProgramData\WorkspaceONE\logs"
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force
}

$log = "C:\ProgramData\WorkspaceONE\logs\FixVPN-$(Get-Date -Format yyyyMMdd-HHmmss).log"
function Log($m){ "$((Get-Date).ToString('u'))  $m" | Tee-Object -FilePath $log -Append | Out-Host }

Log "==== Fix my VPN starting ===="

# 2) Restart OpenVPN services if present (don’t fail if they refuse stop)
$svcNames = "agent_ovpnconnect","OpenVPNServiceInteractive","OpenVPNService"
foreach ($svc in $svcNames) {
  $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
  if ($s) {
    try {
      Log "Restarting service $svc ..."
      Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
      Restart-Service -Name $svc -Force -ErrorAction SilentlyContinue
    } catch { Log "Restart failed for ${svc}: $($_.Exception.Message)" }
  }
}

# 3) Heal TAP adapters
$tap = Get-NetAdapter | Where-Object {$_.InterfaceDescription -match "TAP|OpenVPN"}
if ($tap) {
  foreach ($a in $tap) {
    try {
      Log "Enabling & restarting adapter $($a.Name) ..."
      Enable-NetAdapter -Name $a.Name -Confirm:$false -ErrorAction SilentlyContinue
      Restart-NetAdapter -Name $a.Name -Confirm:$false -ErrorAction SilentlyContinue
    } catch { Log "Adapter heal failed for $($a.Name): $($_.Exception.Message)" }
  }
} else {
  Log "No TAP/OpenVPN adapters detected."
}

# 4) Reset name resolution and sockets
try {
  Log "Resetting DNS/Winsock/IP ..."
  ipconfig /flushdns | Out-Null
  netsh winsock reset | Out-Null
  netsh int ip reset | Out-Null
} catch { Log "Network resets experienced errors: $($_.Exception.Message)" }

# 6) Quick verification
Start-Sleep -Seconds 3
$ok = (Test-Connection -ComputerName 1.1.1.1 -Count 1 -Quiet) -or `
      (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet)

if ($ok) { Log "Basic connectivity looks good."; exit 0 }
else     { Log "Connectivity still failing.";   exit 1 }