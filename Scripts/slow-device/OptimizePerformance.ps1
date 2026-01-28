<#
    .SYNOPSIS
        Performs basic performance optimizations on a Windows device.

    .DESCRIPTION
        This script performs two optional tasks that can improve user experience:

        * Installs available driver updates via Windows Update (using COM
          interfaces).  If no driver updates are available, the script reports
          accordingly.
        * Sets the active power plan to High Performance to avoid throttling.

        The script must be run as administrator.

    .NOTES
        Author: Omnissa Demo Assistant
        Date: 2025-08-24
        Compatible with: Workspace ONE UEM
#>

# Configure logging for Workspace ONE UEM compatibility
$LogPath = "$env:ProgramData\Omnissa\Logs"
$LogFile = "$LogPath\OptimizePerformance-$(Get-Date -Format 'yyyy-MM-dd').log"

# Ensure log directory exists
if (-not (Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
    Write-Host $logEntry  # Also output to console for UEM visibility
}

function Assert-Administrator {
    $isAdmin = ([Security.Principal.WindowsPrincipal]`
                [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
                [Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Log "Script must be run as administrator" "ERROR"
        throw 'This script must be run as an administrator.'
    }
}

try {
    Write-Log "Starting OptimizePerformance script execution"
    Assert-Administrator

    Write-Log "Checking for driver updates via Windows Update..."
    try {
        $updateSession  = New-Object -ComObject 'Microsoft.Update.Session'
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult   = $updateSearcher.Search("Type='Driver' and IsInstalled=0")

        if ($searchResult.Updates.Count -gt 0) {
            Write-Log ("Found {0} driver update(s). Installing..." -f $searchResult.Updates.Count)
            $installer = $updateSession.CreateUpdateInstaller()
            $installer.Updates = $searchResult.Updates
            $result    = $installer.Install()
            Write-Log "Driver update installation completed with result code: $($result.ResultCode)"
        } else {
            Write-Log "No driver updates found."
        }
    } catch {
        Write-Log "Unable to query or install driver updates: $($_.Exception.Message)" "WARN"
    }

    # Attempt to switch to High Performance power plan (or best available for VMs)
    Write-Log "Setting power scheme to optimal performance..."
    try {
        # Get all available power plans
        $powerPlans = powercfg.exe -list
        
        # Try to find High Performance plan first (preferred)
        $planLine = $powerPlans | Where-Object { $_ -match 'High performance' }
        
        # If High Performance not found, try Ultimate Performance (Windows 10/11)
        if (-not $planLine) {
            $planLine = $powerPlans | Where-Object { $_ -match 'Ultimate Performance' }
        }
        
        # If neither found, fall back to Balanced plan (common in VMs)
        if (-not $planLine) {
            Write-Log "High Performance plan not available (common in VMs). Using Balanced plan..."
            $planLine = $powerPlans | Where-Object { $_ -match 'Balanced' }
        }
        
        if ($planLine) {
            # GUID is enclosed in parentheses on the line; extract with regex
            if ($planLine -match '\(([A-Fa-f0-9\-]+)\)') {
                $guid = $matches[1]
                powercfg.exe -setactive $guid | Out-Null
                
                # Determine which plan was actually set
                $planName = if ($planLine -match 'High performance') { "High Performance" }
                           elseif ($planLine -match 'Ultimate Performance') { "Ultimate Performance" }
                           else { "Balanced" }
                           
                Write-Log "Power scheme set to $planName (GUID: $guid)"
                
                # For VMs running Balanced, also optimize some power settings
                if ($planName -eq "Balanced") {
                    Write-Log "Optimizing Balanced plan settings for VM performance..."
                    try {
                        # Set processor minimum state to 100% when plugged in
                        powercfg.exe -setacvalueindex $guid 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100 | Out-Null
                        # Set processor maximum state to 100% when plugged in  
                        powercfg.exe -setacvalueindex $guid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 | Out-Null
                        # Apply the changes
                        powercfg.exe -setactive $guid | Out-Null
                        Write-Log "Applied performance optimizations to Balanced plan"
                    } catch {
                        Write-Log "Could not optimize Balanced plan settings: $($_.Exception.Message)" "WARN"
                    }
                }
            } else {
                Write-Log "Could not parse GUID for power plan." "WARN"
            }
        } else {
            Write-Log "No suitable power plan found on this system." "WARN"
        }
    } catch {
        Write-Log "Failed to change power scheme: $($_.Exception.Message)" "WARN"
    }

    Write-Log "OptimizePerformance script completed successfully"

} catch {
    Write-Log "OptimizePerformance script failed: $($_.Exception.Message)" "ERROR"
    Write-Error $_
}
