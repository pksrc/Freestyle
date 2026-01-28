# Reset Network Stack (DNS, Winsock, IP)
# Requires Administrator privileges

$logDir = "C:\ProgramData\WorkspaceONE\logs"
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force
}

$log = "C:\ProgramData\WorkspaceONE\logs\ResetNetworkStack-$(Get-Date -Format yyyyMMdd-HHmmss).log"
function Log($m){ "$((Get-Date).ToString('u'))  $m" | Tee-Object -FilePath $log -Append | Out-Host }

Log "==== Resetting Network Stack ===="

$errors = 0

# Flush DNS Cache
try {
    Log "Flushing DNS cache..."
    $result = ipconfig /flushdns 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log "DNS cache flushed successfully"
    } else {
        Log "DNS flush returned exit code: $LASTEXITCODE"
        Log "Output: $result"
    }
} catch { 
    Log "DNS flush failed: $($_.Exception.Message)"
    $errors++
}

# Reset Winsock
try {
    Log "Resetting Winsock catalog..."
    $result = netsh winsock reset 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log "Winsock reset successfully"
    } else {
        Log "Winsock reset returned exit code: $LASTEXITCODE"
        Log "Output: $result"
    }
} catch { 
    Log "Winsock reset failed: $($_.Exception.Message)"
    $errors++
}

# Reset TCP/IP Stack
try {
    Log "Resetting TCP/IP stack..."
    $result = netsh int ip reset 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log "TCP/IP stack reset successfully"
    } else {
        Log "TCP/IP reset returned exit code: $LASTEXITCODE"
        Log "Output: $result"
    }
} catch { 
    Log "TCP/IP reset failed: $($_.Exception.Message)"
    $errors++
}

Log "==== Network Stack Reset Complete ===="

if ($errors -eq 0) {
    Log "All network resets completed successfully"
    Log "Note: Some changes may require a system reboot to take full effect"
    exit 0
} else {
    Log "Network reset completed with $errors error(s)"
    exit 1
}
