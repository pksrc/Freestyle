# Enable and Restart TAP/OpenVPN Network Adapters
# Requires Administrator privileges

$logDir = "C:\ProgramData\WorkspaceONE\logs"
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force
}

$log = "C:\ProgramData\WorkspaceONE\logs\FixTAPAdapters-$(Get-Date -Format yyyyMMdd-HHmmss).log"
function Log($m){ "$((Get-Date).ToString('u'))  $m" | Tee-Object -FilePath $log -Append | Out-Host }

Log "==== Fixing TAP/OpenVPN Network Adapters ===="

# Find TAP adapters
$tapAdapters = Get-NetAdapter | Where-Object {$_.InterfaceDescription -match "TAP|OpenVPN"}

if ($tapAdapters) {
    Log "Found $($tapAdapters.Count) TAP/OpenVPN adapter(s)"
    
    foreach ($adapter in $tapAdapters) {
        try {
            Log "Processing adapter: $($adapter.Name) ($($adapter.InterfaceDescription))"
            Log "Current status: $($adapter.Status)"
            
            # Enable the adapter
            Log "Enabling adapter $($adapter.Name)..."
            Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
            
            # Wait a moment for the enable to take effect
            Start-Sleep -Seconds 2
            
            # Restart the adapter
            Log "Restarting adapter $($adapter.Name)..."
            Restart-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
            
            # Verify adapter status
            Start-Sleep -Seconds 3
            $updatedAdapter = Get-NetAdapter -Name $adapter.Name -ErrorAction SilentlyContinue
            if ($updatedAdapter) {
                Log "Adapter $($adapter.Name) status: $($updatedAdapter.Status)"
            }
            
        } catch { 
            Log "Failed to fix adapter $($adapter.Name): $($_.Exception.Message)" 
        }
    }
    
    Log "==== TAP Adapter Fix Complete ===="
    Log "Processed $($tapAdapters.Count) TAP/OpenVPN adapter(s)"
    exit 0
    
} else {
    Log "==== No TAP/OpenVPN Adapters Found ===="
    Log "No TAP or OpenVPN adapters detected on this system"
    exit 1
}
