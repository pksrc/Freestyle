# VPN Status Enumeration Script
# This script defines VPN connection states and provides functions to check status of popular VPN clients

# Define VPN Status Enumeration
enum VpnStatus {
    Unknown = 0
    Disconnected = 1
    Connecting = 2
    Connected = 3
    Disconnecting = 4
    Reconnecting = 5
    Error = 6
    Disabled = 7
    AuthenticationRequired = 8
    Suspended = 9
}

# Function to get GlobalProtect VPN status
function Get-GlobalProtectStatus {
    [OutputType([VpnStatus])]
    param()
    
    try {
        # Check if GlobalProtect service is running
        $gpService = Get-Service -Name "PanGPS" -ErrorAction SilentlyContinue
        if (-not $gpService) {
            return [VpnStatus]::Unknown
        }
        
        if ($gpService.Status -ne "Running") {
            return [VpnStatus]::Disabled
        }
        
        # Check GlobalProtect process and registry for connection status
        $gpProcess = Get-Process -Name "PanGPA" -ErrorAction SilentlyContinue
        if (-not $gpProcess) {
            return [VpnStatus]::Disconnected
        }
        
        # Check registry for connection status (GlobalProtect stores status here)
        $regPath = "HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect"
        if (Test-Path $regPath) {
            $connectionStatus = Get-ItemProperty -Path $regPath -Name "PanConnectionStatus" -ErrorAction SilentlyContinue
            if ($connectionStatus) {
                switch ($connectionStatus.PanConnectionStatus) {
                    "Connected" { return [VpnStatus]::Connected }
                    "Connecting" { return [VpnStatus]::Connecting }
                    "Disconnected" { return [VpnStatus]::Disconnected }
                    "Disconnecting" { return [VpnStatus]::Disconnecting }
                    default { return [VpnStatus]::Unknown }
                }
            }
        }
        
        # Fallback: Check network adapters for GlobalProtect interface
        $gpAdapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*PANGP*" -or $_.Name -like "*GlobalProtect*" }
        if ($gpAdapter -and $gpAdapter.Status -eq "Up") {
            return [VpnStatus]::Connected
        }
        
        return [VpnStatus]::Disconnected
    }
    catch {
        Write-Warning "Error checking GlobalProtect status: $($_.Exception.Message)"
        return [VpnStatus]::Error
    }
}

# Function to get Cisco AnyConnect VPN status
function Get-CiscoAnyConnectStatus {
    [OutputType([VpnStatus])]
    param()
    
    try {
        # Check if Cisco AnyConnect service is running
        $ciscoService = Get-Service -Name "vpnagent" -ErrorAction SilentlyContinue
        if (-not $ciscoService -or $ciscoService.Status -ne "Running") {
            return [VpnStatus]::Disabled
        }
        
        # Check for AnyConnect process
        $ciscoProcess = Get-Process -Name "vpnui" -ErrorAction SilentlyContinue
        if (-not $ciscoProcess) {
            return [VpnStatus]::Disconnected
        }
        
        # Check network adapters for Cisco VPN interface
        $ciscoAdapter = Get-NetAdapter | Where-Object { 
            $_.InterfaceDescription -like "*Cisco AnyConnect*" -or 
            $_.InterfaceDescription -like "*VPN*" -and $_.InterfaceDescription -like "*Cisco*"
        }
        
        if ($ciscoAdapter -and $ciscoAdapter.Status -eq "Up") {
            return [VpnStatus]::Connected
        }
        
        return [VpnStatus]::Disconnected
    }
    catch {
        Write-Warning "Error checking Cisco AnyConnect status: $($_.Exception.Message)"
        return [VpnStatus]::Error
    }
}

# Function to get OpenVPN status
function Get-OpenVpnStatus {
    [OutputType([VpnStatus])]
    param()
    
    try {
        # Check for OpenVPN service
        $openvpnService = Get-Service -Name "OpenVPNService*" -ErrorAction SilentlyContinue
        if (-not $openvpnService) {
            # Check for OpenVPN GUI process
            $openvpnProcess = Get-Process -Name "openvpn-gui" -ErrorAction SilentlyContinue
            if (-not $openvpnProcess) {
                return [VpnStatus]::Unknown
            }
        }
        
        # Check network adapters for TAP interface (commonly used by OpenVPN)
        $tapAdapter = Get-NetAdapter | Where-Object { 
            $_.InterfaceDescription -like "*TAP*" -or 
            $_.InterfaceDescription -like "*OpenVPN*"
        }
        
        if ($tapAdapter -and $tapAdapter.Status -eq "Up") {
            return [VpnStatus]::Connected
        }
        
        return [VpnStatus]::Disconnected
    }
    catch {
        Write-Warning "Error checking OpenVPN status: $($_.Exception.Message)"
        return [VpnStatus]::Error
    }
}

# Function to get Windows built-in VPN status
function Get-WindowsVpnStatus {
    [OutputType([VpnStatus])]
    param()
    
    try {
        # Get VPN connections using Get-VpnConnection
        $vpnConnections = Get-VpnConnection -ErrorAction SilentlyContinue
        
        if (-not $vpnConnections) {
            return [VpnStatus]::Unknown
        }
        
        foreach ($vpn in $vpnConnections) {
            switch ($vpn.ConnectionStatus) {
                "Connected" { return [VpnStatus]::Connected }
                "Connecting" { return [VpnStatus]::Connecting }
                "Disconnecting" { return [VpnStatus]::Disconnecting }
                "Disconnected" { continue }
                default { continue }
            }
        }
        
        return [VpnStatus]::Disconnected
    }
    catch {
        Write-Warning "Error checking Windows VPN status: $($_.Exception.Message)"
        return [VpnStatus]::Error
    }
}

# Function to get FortiClient VPN status
function Get-FortiClientStatus {
    [OutputType([VpnStatus])]
    param()
    
    try {
        # Check FortiClient service
        $fortiService = Get-Service -Name "FA_Scheduler" -ErrorAction SilentlyContinue
        if (-not $fortiService -or $fortiService.Status -ne "Running") {
            return [VpnStatus]::Disabled
        }
        
        # Check FortiClient process
        $fortiProcess = Get-Process -Name "FortiClient" -ErrorAction SilentlyContinue
        if (-not $fortiProcess) {
            return [VpnStatus]::Disconnected
        }
        
        # Check network adapters for FortiClient interface
        $fortiAdapter = Get-NetAdapter | Where-Object { 
            $_.InterfaceDescription -like "*Fortinet*" -or 
            $_.InterfaceDescription -like "*FortiSSL*"
        }
        
        if ($fortiAdapter -and $fortiAdapter.Status -eq "Up") {
            return [VpnStatus]::Connected
        }
        
        return [VpnStatus]::Disconnected
    }
    catch {
        Write-Warning "Error checking FortiClient status: $($_.Exception.Message)"
        return [VpnStatus]::Error
    }
}

# Main function to check all VPN clients and return overall status
function Get-VpnStatus {
    [OutputType([PSCustomObject])]
    param(
        [string]$ClientType = "All"
    )
    
    $results = @{}
    
    switch ($ClientType.ToLower()) {
        "globalprotect" {
            $results["GlobalProtect"] = Get-GlobalProtectStatus
        }
        "ciscoanyconnect" {
            $results["CiscoAnyConnect"] = Get-CiscoAnyConnectStatus
        }
        "openvpn" {
            $results["OpenVPN"] = Get-OpenVpnStatus
        }
        "windows" {
            $results["WindowsVPN"] = Get-WindowsVpnStatus
        }
        "forticlient" {
            $results["FortiClient"] = Get-FortiClientStatus
        }
        "all" {
            $results["GlobalProtect"] = Get-GlobalProtectStatus
            $results["CiscoAnyConnect"] = Get-CiscoAnyConnectStatus
            $results["OpenVPN"] = Get-OpenVpnStatus
            $results["WindowsVPN"] = Get-WindowsVpnStatus
            $results["FortiClient"] = Get-FortiClientStatus
        }
        default {
            Write-Error "Invalid client type. Use: GlobalProtect, CiscoAnyConnect, OpenVPN, Windows, FortiClient, or All"
            return
        }
    }
    
    # Create output object
    $output = [PSCustomObject]@{
        Timestamp = Get-Date
        Results = $results
        OverallStatus = [VpnStatus]::Disconnected
    }
    
    # Determine overall status
    $connectedClients = $results.Values | Where-Object { $_ -eq [VpnStatus]::Connected }
    $connectingClients = $results.Values | Where-Object { $_ -eq [VpnStatus]::Connecting -or $_ -eq [VpnStatus]::Reconnecting }
    $errorClients = $results.Values | Where-Object { $_ -eq [VpnStatus]::Error }
    
    if ($connectedClients.Count -gt 0) {
        $output.OverallStatus = [VpnStatus]::Connected
    }
    elseif ($connectingClients.Count -gt 0) {
        $output.OverallStatus = [VpnStatus]::Connecting
    }
    elseif ($errorClients.Count -gt 0) {
        $output.OverallStatus = [VpnStatus]::Error
    }
    else {
        $output.OverallStatus = [VpnStatus]::Disconnected
    }
    
    return $output
}

# Function to display VPN status in a formatted way
function Show-VpnStatus {
    param(
        [string]$ClientType = "All"
    )
    
    $status = Get-VpnStatus -ClientType $ClientType
    
    Write-Host "`nVPN Status Report - $($status.Timestamp)" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    foreach ($client in $status.Results.Keys) {
        $clientStatus = $status.Results[$client]
        $color = switch ($clientStatus) {
            ([VpnStatus]::Connected) { "Green" }
            ([VpnStatus]::Connecting) { "Yellow" }
            ([VpnStatus]::Reconnecting) { "Yellow" }
            ([VpnStatus]::Error) { "Red" }
            ([VpnStatus]::Disconnected) { "Gray" }
            ([VpnStatus]::Disabled) { "DarkGray" }
            default { "White" }
        }
        
        Write-Host "$($client.PadRight(20)): $clientStatus" -ForegroundColor $color
    }
    
    $overallColor = switch ($status.OverallStatus) {
        ([VpnStatus]::Connected) { "Green" }
        ([VpnStatus]::Connecting) { "Yellow" }
        ([VpnStatus]::Error) { "Red" }
        default { "Gray" }
    }
    
    Write-Host "`nOverall Status: $($status.OverallStatus)" -ForegroundColor $overallColor
}

# Workspace ONE UEM Sensor: VPN Status Detection
# Returns: String value representing overall VPN status
# Exit Codes: 0 = Success, 1 = No VPN connection, 2 = Error

# Main sensor execution for Workspace ONE UEM
try {
    # Suppress verbose output for clean sensor data
    $VerbosePreference = "SilentlyContinue"
    $WarningPreference = "SilentlyContinue"
    
    # Get VPN status for all clients
    $status = Get-VpnStatus -ClientType "All"
    
    # Output the overall status as string for Workspace ONE UEM
    Write-Output $status.OverallStatus.ToString()
    
    # Set appropriate exit code based on connection status
    switch ($status.OverallStatus) {
        ([VpnStatus]::Connected) { exit 0 }      # Success: VPN connected
        ([VpnStatus]::Connecting) { exit 0 }     # Success: VPN connecting
        ([VpnStatus]::Reconnecting) { exit 0 }   # Success: VPN reconnecting
        ([VpnStatus]::Error) { exit 2 }          # Error: VPN error state
        default { exit 1 }                       # Failure: VPN not connected
    }
}
catch {
    # Error occurred during execution
    Write-Output "Error"
    exit 2  # Error: Unable to determine VPN status
}

# Export functions for module use (when dot-sourced)
Export-ModuleMember -Function Get-VpnStatus, Show-VpnStatus, Get-GlobalProtectStatus, Get-CiscoAnyConnectStatus, Get-OpenVpnStatus, Get-WindowsVpnStatus, Get-FortiClientStatus
