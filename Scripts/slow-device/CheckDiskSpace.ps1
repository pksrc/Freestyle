<#
    .SYNOPSIS
        Reports free space on the system drive (C:) as a percentage.

    .DESCRIPTION
        This script queries the `C:` drive and outputs the amount of free space
        as a percentage of total disk capacity.  When used as a Workspace ONE sensor, 
        the returned integer value can be evaluated in a Freestyle Orchestrator
        workflow to determine whether disk-cleanup actions should run.

    .NOTES
        Author: Omnissa Demo Assistant
        Date: 2025-08-24
        Compatible with: Workspace ONE UEM Sensors

    .OUTPUTS
        Integer representing free space percentage (0-100)
#>

# Retrieve the C: drive information.  If the drive does not exist (for
# example, running on a non-Windows platform), the script returns 0.
$drive = Get-PSDrive -Name 'C' -ErrorAction SilentlyContinue
if ($null -ne $drive) {
    # Calculate free space as a percentage of total capacity, rounded to nearest integer.
    $freePercent = [Math]::Round(($drive.Free / ($drive.Free + $drive.Used)) * 100, 0)
    # Return the integer value directly for Workspace ONE UEM sensor compatibility
    [int]$freePercent
} else {
    # Return 0 if drive not found
    0
}
