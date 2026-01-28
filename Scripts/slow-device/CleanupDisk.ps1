<#
    .SYNOPSIS
        Cleans up disk space and optimizes the system drive on Windows.

    .DESCRIPTION
        Performs several clean‑up tasks to reclaim disk space on a Windows
        computer.  The script must be run with administrative privileges.  It
        performs the following actions:

        * Deletes contents of common temporary directories (`%windir%\Temp`,
          `%TEMP%`, `%TMP%` and `%LOCALAPPDATA%\Temp`).
        * Stops the Windows Update and BITS services, purges the
          SoftwareDistribution\Download cache and restarts the services.
        * Empties the Recycle Bin.
        * Runs DISM component cleanup to remove superseded update files.
        * Defragments the system drive (`C:`) to optimize file layout.

    .NOTES
        Author: Omnissa Demo Assistant
        Date: 2025-08-24
        Compatible with: Workspace ONE UEM

    .IMPORTANT
        This script should be executed under the SYSTEM context or by a user
        with administrative rights.  Running under a normal user account will
        result in insufficient permission errors.
#>

# Configure logging for Workspace ONE UEM compatibility
$LogPath = "$env:ProgramData\Omnissa\Logs"
$LogFile = "$LogPath\CleanupDisk-$(Get-Date -Format 'yyyy-MM-dd').log"

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
    Write-Log "Starting CleanupDisk script execution"
    Assert-Administrator

    Write-Log "Starting disk cleanup operations..."

    # Temporary directories to purge
    $TempPaths = @(
        "$env:windir\Temp",
        "$env:TEMP",
        "$env:TMP",
        "$env:LOCALAPPDATA\Temp"
    )

    foreach ($path in $TempPaths) {
        if (Test-Path $path) {
            Write-Log "Clearing $path..."
            Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Stop Windows Update and BITS services
    $servicesToStop = 'wuauserv','bits'
    foreach ($svc in $servicesToStop) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service -and $service.Status -ne 'Stopped') {
            Write-Log "Stopping service $svc..."
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        }
    }

    # Purge Windows Update download cache
    $wuCache = "$env:windir\SoftwareDistribution\Download"
    if (Test-Path $wuCache) {
        Write-Log "Clearing Windows Update cache at $wuCache..."
        Get-ChildItem -Path $wuCache -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Restart services
    foreach ($svc in $servicesToStop) {
        Write-Log "Starting service $svc..."
        Start-Service -Name $svc -ErrorAction SilentlyContinue
    }

    # Empty Recycle Bin for all drives
    Write-Log "Emptying Recycle Bin..."
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Log "Failed to clear recycle bin: $($_.Exception.Message)" "WARN"
    }

    # Perform component cleanup
    Write-Log "Performing component cleanup..."
    try {
        & dism.exe /Online /Cleanup-Image /StartComponentCleanup /Quiet
    } catch {
        Write-Log "DISM cleanup failed: $($_.Exception.Message)" "WARN"
    }

    # Defragment system drive (optimize)
    Write-Log "Defragmenting C: drive..."
    try {
        & defrag.exe C: /O
    } catch {
        Write-Log "Defrag failed: $($_.Exception.Message)" "WARN"
    }

    # Report new free space
    $drive = Get-PSDrive -Name 'C' -ErrorAction SilentlyContinue
    if ($drive) {
        $freeGB = [Math]::Round($drive.Free / 1GB, 2)
        Write-Log ("Cleanup complete. Free space: {0:N2} GB" -f $freeGB)
    }

    Write-Log "CleanupDisk script completed successfully"

} catch {
    Write-Log "CleanupDisk script failed: $($_.Exception.Message)" "ERROR"
    Write-Error $_
}
