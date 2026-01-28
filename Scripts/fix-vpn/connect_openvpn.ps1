$logDir = "C:\ProgramData\WorkspaceONE\logs"
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force
}

$log = "C:\ProgramData\WorkspaceONE\logs\ConnectOpenVPN-$(Get-Date -Format yyyyMMdd-HHmmss).log"
function Log($m){ "$((Get-Date).ToString('u'))  $m" | Tee-Object -FilePath $log -Append | Out-Host }

Log "==== Launching OpenVPN Connect GUI ===="

try {
    $openvpnPath = "${env:ProgramFiles}\OpenVPN Connect\OpenVPNConnect.exe"
    if (-not (Test-Path $openvpnPath)) {
        $openvpnPath = "${env:ProgramFiles(x86)}\OpenVPN Connect\OpenVPNConnect.exe"
    }

    if (Test-Path $openvpnPath) {
        Log "Starting OpenVPN Connect GUI..."
        Start-Process -FilePath $openvpnPath -WindowStyle Normal
        Log "Please connect to your VPN profile manually."
        
        Start-Sleep -Seconds 5
        Add-Type -AssemblyName PresentationFramework
        [System.Windows.MessageBox]::Show(
            "OpenVPN settings have been reset. Please try connecting to the VPN now.",
            "Freestyle Workflow Notification",
            'OK',
            'Information'
        )

        exit 0
    } else {
        Log "OpenVPN Connect executable not found."
        exit 1
    }
} catch {
    Log "Error launching OpenVPN Connect: $($_.Exception.Message)"
    exit 1
}