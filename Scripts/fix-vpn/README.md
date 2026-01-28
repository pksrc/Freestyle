# VPN Fix Scripts

This directory contains modular PowerShell scripts for diagnosing and fixing VPN connectivity issues. Each script performs a specific atomic operation that can be run independently or as part of the master orchestration script.

## Individual Scripts

### 1. `restart_vpn_services.ps1`
**Purpose**: Restart OpenVPN-related Windows services
- Finds and restarts: `agent_ovpnconnect`, `OpenVPNServiceInteractive`, `OpenVPNService`
- Sets services to Automatic startup
- Verifies service status after restart
- **Exit Codes**: 0 = Success, 1 = No services restarted

### 2. `fix_tap_adapters.ps1`
**Purpose**: Enable and restart TAP/OpenVPN network adapters
- Finds all TAP and OpenVPN network adapters
- Enables disabled adapters
- Restarts adapters to refresh their state
- **Exit Codes**: 0 = Success, 1 = No adapters found

### 3. `reset_network_stack.ps1`
**Purpose**: Reset core network components
- Flushes DNS cache (`ipconfig /flushdns`)
- Resets Winsock catalog (`netsh winsock reset`)
- Resets TCP/IP stack (`netsh int ip reset`)
- **Exit Codes**: 0 = All resets successful, 1 = Some resets failed

### 4. `test_connectivity.ps1`
**Purpose**: Verify internet connectivity and DNS resolution
- Tests connectivity to multiple DNS servers (Cloudflare, Google, OpenDNS)
- Tests DNS resolution capability
- **Exit Codes**: 0 = All tests passed, 1 = All tests failed, 2 = Partial success

### 5. `fix_vpn_master.ps1`
**Purpose**: Master orchestration script that runs all fixes in sequence
- Executes all individual scripts in logical order
- Handles critical vs non-critical failures
- Provides comprehensive logging and final status
- **Exit Codes**: 0 = Complete success, 1 = Failed, 2 = Partial success

## Usage

### Run Individual Scripts
```powershell
# Restart just the VPN services
.\restart_vpn_services.ps1

# Fix only the TAP adapters
.\fix_tap_adapters.ps1

# Reset network stack only
.\reset_network_stack.ps1

# Test connectivity only
.\test_connectivity.ps1
```

### Run Complete Fix Sequence
```powershell
# Run all fixes in proper order
.\fix_vpn_master.ps1
```

## Requirements
- **Administrator privileges** required for all scripts
- PowerShell execution policy must allow script execution
- Windows system with potential OpenVPN installation

## Logging
All scripts create detailed logs in: `C:\ProgramData\WorkspaceONE\logs\`

Log files are named with timestamp: `ScriptName-YYYYMMDD-HHMMSS.log`

## Exit Codes
- **0**: Success - operation completed successfully
- **1**: Failure - operation failed or no action taken
- **2**: Partial Success - some operations succeeded (test_connectivity and master only)

## Notes
- Scripts are designed to be safe - they won't break existing working configurations
- Each script can be run independently for targeted troubleshooting
- The master script provides the most comprehensive fix approach
- Some network resets may require a system reboot to take full effect
