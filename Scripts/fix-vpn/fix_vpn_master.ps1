# Master VPN Fix Script - Orchestrates all individual fixes
# Requires Administrator privileges

$logDir = "C:\ProgramData\WorkspaceONE\logs"
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force
}

$log = "C:\ProgramData\WorkspaceONE\logs\MasterVPNFix-$(Get-Date -Format yyyyMMdd-HHmmss).log"
function Log($m){ "$((Get-Date).ToString('u'))  $m" | Tee-Object -FilePath $log -Append | Out-Host }

Log "==== Master VPN Fix Starting ===="

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define the individual fix scripts in order
$fixScripts = @(
    @{Name="Restart VPN Services"; Script="restart_vpn_services.ps1"; Critical=$false},
    @{Name="Fix TAP Adapters"; Script="fix_tap_adapters.ps1"; Critical=$false},
    @{Name="Reset Network Stack"; Script="reset_network_stack.ps1"; Critical=$true}
)

$successfulFixes = 0
$totalFixes = $fixScripts.Count

foreach ($fix in $fixScripts) {
    $scriptPath = Join-Path $scriptDir $fix.Script
    
    if (Test-Path $scriptPath) {
        try {
            Log "Running: $($fix.Name)..."
            $result = & PowerShell.exe -ExecutionPolicy Bypass -File $scriptPath
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                Log "$($fix.Name) - SUCCESS"
                $successfulFixes++
            } elseif ($exitCode -eq 2) {
                Log "$($fix.Name) - PARTIAL SUCCESS"
                $successfulFixes++
            } else {
                Log "$($fix.Name) - FAILED (Exit Code: $exitCode)"
                if ($fix.Critical) {
                    Log "Critical fix failed - stopping execution"
                    break
                }
            }
        } catch {
            Log "$($fix.Name) - ERROR: $($_.Exception.Message)"
            if ($fix.Critical) {
                Log "Critical fix error - stopping execution"
                break
            }
        }
    } else {
        Log "Script not found: $scriptPath"
        if ($fix.Critical) {
            Log "Critical script missing - stopping execution"
            break
        }
    }
    
    # Small delay between fixes
    Start-Sleep -Seconds 2
}

Log "==== Running Final Connectivity Test ===="

# Run connectivity test
$testScript = Join-Path $scriptDir "test_connectivity.ps1"
if (Test-Path $testScript) {
    try {
        Start-Sleep -Seconds 3  # Give network stack time to settle
        $result = & PowerShell.exe -ExecutionPolicy Bypass -File $testScript
        $testExitCode = $LASTEXITCODE
        
        if ($testExitCode -eq 0) {
            Log "Final connectivity test - PASSED"
        } elseif ($testExitCode -eq 2) {
            Log "Final connectivity test - PARTIAL"
        } else {
            Log "Final connectivity test - FAILED"
        }
    } catch {
        Log "Connectivity test error: $($_.Exception.Message)"
        $testExitCode = 1
    }
} else {
    Log "Connectivity test script not found"
    $testExitCode = 1
}

Log "==== Master VPN Fix Complete ===="
Log "Successful fixes: $successfulFixes / $totalFixes"

# Determine overall exit code
if ($successfulFixes -eq $totalFixes -and $testExitCode -eq 0) {
    Log "All fixes completed successfully and connectivity verified"
    exit 0
} elseif ($successfulFixes -gt 0 -or $testExitCode -eq 2) {
    Log "Some fixes applied - VPN may be partially working"
    exit 2
} else {
    Log "VPN fix failed - connectivity issues persist"
    exit 1
}
