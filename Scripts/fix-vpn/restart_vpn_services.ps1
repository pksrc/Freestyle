# Restart OpenVPN Services
# Requires Administrator privileges

$logDir = "C:\ProgramData\WorkspaceONE\logs"
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force
}

$log = "C:\ProgramData\WorkspaceONE\logs\RestartVPNServices-$(Get-Date -Format yyyyMMdd-HHmmss).log"
function Log($m){ "$((Get-Date).ToString('u'))  $m" | Tee-Object -FilePath $log -Append | Out-Host }

Log "==== Restarting VPN Services ===="

# Restart OpenVPN services if present (don't fail if they refuse stop)
$svcNames = "agent_ovpnconnect","OpenVPNServiceInteractive","OpenVPNService"
$restartedServices = 0

foreach ($svc in $svcNames) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        try {
            Log "Found service $svc (Status: $($s.Status))"
            Log "Setting $svc startup type to Automatic..."
            Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
            
            Log "Restarting service $svc..."
            Restart-Service -Name $svc -Force -ErrorAction SilentlyContinue
            
            # Verify service status after restart
            Start-Sleep -Seconds 2
            $updatedService = Get-Service -Name $svc -ErrorAction SilentlyContinue
            if ($updatedService -and $updatedService.Status -eq "Running") {
                Log "Service $svc restarted successfully"
                $restartedServices++
            } else {
                Log "Service $svc may not have started properly (Status: $($updatedService.Status))"
            }
        } catch { 
            Log "Restart failed for ${svc}: $($_.Exception.Message)" 
        }
    } else {
        Log "Service $svc not found"
    }
}

Log "==== VPN Services Restart Complete ===="
Log "Services restarted: $restartedServices"

if ($restartedServices -gt 0) {
    Log "Successfully restarted $restartedServices VPN service(s)"
    exit 0
} else {
    Log "No VPN services were restarted"
    exit 1
}
