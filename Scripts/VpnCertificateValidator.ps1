# VPN Certificate Validation Script
# This script checks the validity of certificates used by popular VPN clients
# Returns boolean values indicating certificate validity

# Function to validate GlobalProtect certificates
function Test-GlobalProtectCertificates {
    [OutputType([bool])]
    param()
    
    try {
        $isValid = $true
        
        # Check user certificates in Personal store
        $userCerts = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object {
            $_.Subject -like "*GlobalProtect*" -or 
            $_.Subject -like "*Palo Alto*" -or
            $_.FriendlyName -like "*GlobalProtect*"
        }
        
        foreach ($cert in $userCerts) {
            if ($cert.NotAfter -lt (Get-Date)) {
                Write-Verbose "GlobalProtect user certificate expired: $($cert.Subject)"
                $isValid = $false
            }
            if ($cert.NotBefore -gt (Get-Date)) {
                Write-Verbose "GlobalProtect user certificate not yet valid: $($cert.Subject)"
                $isValid = $false
            }
        }
        
        # Check machine certificates in Local Machine store
        $machineCerts = Get-ChildItem -Path "Cert:\LocalMachine\My" -ErrorAction SilentlyContinue | Where-Object {
            $_.Subject -like "*GlobalProtect*" -or 
            $_.Subject -like "*Palo Alto*" -or
            $_.FriendlyName -like "*GlobalProtect*"
        }
        
        foreach ($cert in $machineCerts) {
            if ($cert.NotAfter -lt (Get-Date)) {
                Write-Verbose "GlobalProtect machine certificate expired: $($cert.Subject)"
                $isValid = $false
            }
            if ($cert.NotBefore -gt (Get-Date)) {
                Write-Verbose "GlobalProtect machine certificate not yet valid: $($cert.Subject)"
                $isValid = $false
            }
        }
        
        # If no certificates found, check if GlobalProtect is installed
        $gpService = Get-Service -Name "PanGPS" -ErrorAction SilentlyContinue
        if ($gpService -and ($userCerts.Count -eq 0 -and $machineCerts.Count -eq 0)) {
            Write-Verbose "GlobalProtect installed but no certificates found"
            return $false
        }
        
        return $isValid
    }
    catch {
        Write-Warning "Error validating GlobalProtect certificates: $($_.Exception.Message)"
        return $false
    }
}

# Function to validate Cisco AnyConnect certificates
function Test-CiscoAnyConnectCertificates {
    [OutputType([bool])]
    param()
    
    try {
        $isValid = $true
        
        # Check user certificates
        $userCerts = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object {
            $_.Subject -like "*Cisco*" -or 
            $_.Subject -like "*AnyConnect*" -or
            $_.FriendlyName -like "*Cisco*" -or
            $_.FriendlyName -like "*AnyConnect*"
        }
        
        foreach ($cert in $userCerts) {
            if ($cert.NotAfter -lt (Get-Date)) {
                Write-Verbose "Cisco AnyConnect user certificate expired: $($cert.Subject)"
                $isValid = $false
            }
            if ($cert.NotBefore -gt (Get-Date)) {
                Write-Verbose "Cisco AnyConnect user certificate not yet valid: $($cert.Subject)"
                $isValid = $false
            }
        }
        
        # Check machine certificates
        $machineCerts = Get-ChildItem -Path "Cert:\LocalMachine\My" -ErrorAction SilentlyContinue | Where-Object {
            $_.Subject -like "*Cisco*" -or 
            $_.Subject -like "*AnyConnect*" -or
            $_.FriendlyName -like "*Cisco*" -or
            $_.FriendlyName -like "*AnyConnect*"
        }
        
        foreach ($cert in $machineCerts) {
            if ($cert.NotAfter -lt (Get-Date)) {
                Write-Verbose "Cisco AnyConnect machine certificate expired: $($cert.Subject)"
                $isValid = $false
            }
            if ($cert.NotBefore -gt (Get-Date)) {
                Write-Verbose "Cisco AnyConnect machine certificate not yet valid: $($cert.Subject)"
                $isValid = $false
            }
        }
        
        # Check if AnyConnect is installed
        $ciscoService = Get-Service -Name "vpnagent" -ErrorAction SilentlyContinue
        if ($ciscoService -and ($userCerts.Count -eq 0 -and $machineCerts.Count -eq 0)) {
            Write-Verbose "Cisco AnyConnect installed but no certificates found"
            return $false
        }
        
        return $isValid
    }
    catch {
        Write-Warning "Error validating Cisco AnyConnect certificates: $($_.Exception.Message)"
        return $false
    }
}

# Function to validate OpenVPN certificates
function Test-OpenVpnCertificates {
    [OutputType([bool])]
    param()
    
    try {
        $isValid = $true
        
        # Check for OpenVPN configuration files that might contain certificate paths
        $openvpnPaths = @(
            "$env:ProgramFiles\OpenVPN\config",
            "$env:ProgramFiles(x86)\OpenVPN\config",
            "$env:USERPROFILE\OpenVPN\config"
        )
        
        foreach ($path in $openvpnPaths) {
            if (Test-Path $path) {
                $configFiles = Get-ChildItem -Path $path -Filter "*.ovpn" -ErrorAction SilentlyContinue
                
                foreach ($config in $configFiles) {
                    $content = Get-Content $config.FullName -ErrorAction SilentlyContinue
                    
                    # Look for certificate file references
                    $certLines = $content | Where-Object { $_ -match "^cert\s+" -or $_ -match "^ca\s+" }
                    
                    foreach ($certLine in $certLines) {
                        $certPath = ($certLine -split "\s+")[1]
                        if ($certPath -and (Test-Path (Join-Path $path $certPath))) {
                            try {
                                $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                                $cert.Import((Join-Path $path $certPath))
                                
                                if ($cert.NotAfter -lt (Get-Date)) {
                                    Write-Verbose "OpenVPN certificate expired: $($cert.Subject)"
                                    $isValid = $false
                                }
                                if ($cert.NotBefore -gt (Get-Date)) {
                                    Write-Verbose "OpenVPN certificate not yet valid: $($cert.Subject)"
                                    $isValid = $false
                                }
                            }
                            catch {
                                Write-Verbose "Could not validate OpenVPN certificate: $certPath"
                                $isValid = $false
                            }
                        }
                    }
                }
            }
        }
        
        # Also check certificate stores for OpenVPN certificates
        $userCerts = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object {
            $_.Subject -like "*OpenVPN*" -or 
            $_.FriendlyName -like "*OpenVPN*"
        }
        
        foreach ($cert in $userCerts) {
            if ($cert.NotAfter -lt (Get-Date)) {
                Write-Verbose "OpenVPN user certificate expired: $($cert.Subject)"
                $isValid = $false
            }
            if ($cert.NotBefore -gt (Get-Date)) {
                Write-Verbose "OpenVPN user certificate not yet valid: $($cert.Subject)"
                $isValid = $false
            }
        }
        
        return $isValid
    }
    catch {
        Write-Warning "Error validating OpenVPN certificates: $($_.Exception.Message)"
        return $false
    }
}

# Function to validate Windows built-in VPN certificates
function Test-WindowsVpnCertificates {
    [OutputType([bool])]
    param()
    
    try {
        $isValid = $true
        
        # Get VPN connections
        $vpnConnections = Get-VpnConnection -ErrorAction SilentlyContinue
        
        foreach ($vpn in $vpnConnections) {
            if ($vpn.AuthenticationMethod -eq "Certificate" -or $vpn.AuthenticationMethod -eq "EAP") {
                # Check if certificate is specified and valid
                if ($vpn.CertificateThumbprint) {
                    $cert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object { $_.Thumbprint -eq $vpn.CertificateThumbprint }
                    if (-not $cert) {
                        $cert = Get-ChildItem -Path "Cert:\LocalMachine\My" -ErrorAction SilentlyContinue | Where-Object { $_.Thumbprint -eq $vpn.CertificateThumbprint }
                    }
                    
                    if ($cert) {
                        if ($cert.NotAfter -lt (Get-Date)) {
                            Write-Verbose "Windows VPN certificate expired for connection '$($vpn.Name)': $($cert.Subject)"
                            $isValid = $false
                        }
                        if ($cert.NotBefore -gt (Get-Date)) {
                            Write-Verbose "Windows VPN certificate not yet valid for connection '$($vpn.Name)': $($cert.Subject)"
                            $isValid = $false
                        }
                    }
                    else {
                        Write-Verbose "Certificate not found for Windows VPN connection '$($vpn.Name)'"
                        $isValid = $false
                    }
                }
            }
        }
        
        return $isValid
    }
    catch {
        Write-Warning "Error validating Windows VPN certificates: $($_.Exception.Message)"
        return $false
    }
}

# Function to validate FortiClient certificates
function Test-FortiClientCertificates {
    [OutputType([bool])]
    param()
    
    try {
        $isValid = $true
        
        # Check user certificates
        $userCerts = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object {
            $_.Subject -like "*Fortinet*" -or 
            $_.Subject -like "*FortiClient*" -or
            $_.FriendlyName -like "*Fortinet*" -or
            $_.FriendlyName -like "*FortiClient*"
        }
        
        foreach ($cert in $userCerts) {
            if ($cert.NotAfter -lt (Get-Date)) {
                Write-Verbose "FortiClient user certificate expired: $($cert.Subject)"
                $isValid = $false
            }
            if ($cert.NotBefore -gt (Get-Date)) {
                Write-Verbose "FortiClient user certificate not yet valid: $($cert.Subject)"
                $isValid = $false
            }
        }
        
        # Check machine certificates
        $machineCerts = Get-ChildItem -Path "Cert:\LocalMachine\My" -ErrorAction SilentlyContinue | Where-Object {
            $_.Subject -like "*Fortinet*" -or 
            $_.Subject -like "*FortiClient*" -or
            $_.FriendlyName -like "*Fortinet*" -or
            $_.FriendlyName -like "*FortiClient*"
        }
        
        foreach ($cert in $machineCerts) {
            if ($cert.NotAfter -lt (Get-Date)) {
                Write-Verbose "FortiClient machine certificate expired: $($cert.Subject)"
                $isValid = $false
            }
            if ($cert.NotBefore -gt (Get-Date)) {
                Write-Verbose "FortiClient machine certificate not yet valid: $($cert.Subject)"
                $isValid = $false
            }
        }
        
        return $isValid
    }
    catch {
        Write-Warning "Error validating FortiClient certificates: $($_.Exception.Message)"
        return $false
    }
}

# Main function to validate all VPN certificates
function Test-VpnCertificates {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [ValidateSet("All", "GlobalProtect", "CiscoAnyConnect", "OpenVPN", "Windows", "FortiClient")]
        [string]$ClientType = "All",
        
        [switch]$Detailed
    )
    
    $results = @{}
    
    switch ($ClientType) {
        "GlobalProtect" {
            $results["GlobalProtect"] = Test-GlobalProtectCertificates
        }
        "CiscoAnyConnect" {
            $results["CiscoAnyConnect"] = Test-CiscoAnyConnectCertificates
        }
        "OpenVPN" {
            $results["OpenVPN"] = Test-OpenVpnCertificates
        }
        "Windows" {
            $results["Windows"] = Test-WindowsVpnCertificates
        }
        "FortiClient" {
            $results["FortiClient"] = Test-FortiClientCertificates
        }
        "All" {
            $results["GlobalProtect"] = Test-GlobalProtectCertificates
            $results["CiscoAnyConnect"] = Test-CiscoAnyConnectCertificates
            $results["OpenVPN"] = Test-OpenVpnCertificates
            $results["Windows"] = Test-WindowsVpnCertificates
            $results["FortiClient"] = Test-FortiClientCertificates
        }
    }
    
    # Calculate overall validity
    $allValid = $true
    foreach ($result in $results.Values) {
        if (-not $result) {
            $allValid = $false
            break
        }
    }
    
    if ($Detailed) {
        return [PSCustomObject]@{
            Timestamp = Get-Date
            AllCertificatesValid = $allValid
            ClientResults = $results
        }
    }
    else {
        return $allValid
    }
}

# Function to display certificate validation results
function Show-VpnCertificateStatus {
    [CmdletBinding()]
    param(
        [ValidateSet("All", "GlobalProtect", "CiscoAnyConnect", "OpenVPN", "Windows", "FortiClient")]
        [string]$ClientType = "All"
    )
    
    $result = Test-VpnCertificates -ClientType $ClientType -Detailed
    
    Write-Host "`nVPN Certificate Validation Report - $($result.Timestamp)" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
    
    foreach ($client in $result.ClientResults.Keys) {
        $isValid = $result.ClientResults[$client]
        $status = if ($isValid) { "VALID" } else { "INVALID/EXPIRED" }
        $color = if ($isValid) { "Green" } else { "Red" }
        
        Write-Host "$($client.PadRight(20)): $status" -ForegroundColor $color
    }
    
    $overallStatus = if ($result.AllCertificatesValid) { "ALL CERTIFICATES VALID" } else { "CERTIFICATE ISSUES DETECTED" }
    $overallColor = if ($result.AllCertificatesValid) { "Green" } else { "Red" }
    
    Write-Host "`nOverall Status: $overallStatus" -ForegroundColor $overallColor
    
    return $result.AllCertificatesValid
}

# Workspace ONE UEM Sensor: VPN Certificate Validation
# Returns: Boolean value indicating certificate validity
# Exit Codes: 0 = Valid certificates, 1 = Invalid/expired certificates, 2 = Error

# Main sensor execution for Workspace ONE UEM
try {
    # Suppress verbose output for clean sensor data
    $VerbosePreference = "SilentlyContinue"
    $WarningPreference = "SilentlyContinue"
    
    # Test all VPN client certificates
    $result = Test-VpnCertificates -ClientType GlobalProtect
    
    # Output result as boolean for Workspace ONE UEM consumption
    Write-Output $result
    
    # Set appropriate exit code for UEM interpretation
    if ($result) {
        exit 0  # Success: All certificates valid
    } else {
        exit 1  # Failure: One or more certificates invalid/expired
    }
}
catch {
    # Error occurred during execution
    Write-Output $false
    exit 2  # Error: Unable to determine certificate status
}

# Export functions for module use (when dot-sourced)
Export-ModuleMember -Function Test-VpnCertificates, Show-VpnCertificateStatus, Test-GlobalProtectCertificates, Test-CiscoAnyConnectCertificates, Test-OpenVpnCertificates, Test-WindowsVpnCertificates, Test-FortiClientCertificates
