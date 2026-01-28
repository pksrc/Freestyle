# Workspace ONE UEM VPN Sensors

This repository contains two PowerShell sensors designed for Workspace ONE UEM to monitor VPN status and certificate validity on Windows endpoints.

## Sensors Overview

### 1. VPN Status Sensor (`VpnStatusEnum.ps1`)
- **Purpose**: Detects the connection status of various VPN clients
- **Return Type**: String (VPN status enum value)
- **Supported VPN Clients**: GlobalProtect, Cisco AnyConnect, OpenVPN, Windows VPN, FortiClient

### 2. VPN Certificate Validator Sensor (`VpnCertificateValidator.ps1`)
- **Purpose**: Validates VPN authentication certificates
- **Return Type**: Boolean (true = valid, false = invalid/expired)
- **Certificate Stores**: User and Machine certificate stores

## Workspace ONE UEM Configuration

### Sensor Setup

1. **Navigate to**: UEM Console → Resources → Sensors → Add Sensor
2. **Sensor Type**: PowerShell
3. **Execution Architecture**: Select appropriate (x64 recommended)
4. **Execution Context**: System (for machine certificates access)

### VPN Status Sensor Configuration

```powershell
# Sensor Script: VpnStatusEnum.ps1
# Expected Return: String value from VpnStatus enum
# Sample Values: "Connected", "Disconnected", "Connecting", "Error", etc.
```

**Sensor Settings:**
- **Name**: VPN Connection Status
- **Description**: Monitors VPN connection status across multiple VPN clients
- **Category**: Connectivity
- **Response Data Type**: String
- **Execution Frequency**: Every 15-30 minutes (or as needed)

### VPN Certificate Validator Sensor Configuration

```powershell
# Sensor Script: VpnCertificateValidator.ps1
# Expected Return: Boolean value
# true = All VPN certificates valid
# false = One or more certificates invalid/expired
```

**Sensor Settings:**
- **Name**: VPN Certificate Validity
- **Description**: Validates VPN authentication certificates
- **Category**: Security
- **Response Data Type**: Boolean
- **Execution Frequency**: Daily or weekly

## Exit Codes Reference

### VPN Status Sensor Exit Codes
- **0**: Success - VPN connected, connecting, or reconnecting
- **1**: Failure - VPN disconnected, disabled, or unknown
- **2**: Error - Unable to determine VPN status

### VPN Certificate Validator Exit Codes
- **0**: Success - All certificates valid
- **1**: Failure - One or more certificates invalid/expired
- **2**: Error - Unable to determine certificate status

## Smart Groups and Compliance Rules

### Smart Group Examples

#### VPN Connected Devices
```
Sensor: VPN Connection Status
Operator: Is
Value: Connected
```

#### VPN Certificate Issues
```
Sensor: VPN Certificate Validity
Operator: Is
Value: false
```

#### VPN Disconnected Devices
```
Sensor: VPN Connection Status
Operator: Is one of
Values: Disconnected, Disabled, Unknown
```

### Compliance Policy Examples

#### VPN Connection Compliance
- **Rule**: VPN Connection Status = "Connected"
- **Action on Non-Compliance**: Send notification, trigger remediation workflow

#### Certificate Validity Compliance
- **Rule**: VPN Certificate Validity = true
- **Action on Non-Compliance**: Alert IT team, initiate certificate renewal process

## Automation and Workflows

### Proactive Certificate Management
1. **Trigger**: VPN Certificate Validity = false
2. **Action**: 
   - Send alert to IT team
   - Create service desk ticket
   - Notify end user of pending certificate expiration

### VPN Connection Monitoring
1. **Trigger**: VPN Connection Status = "Disconnected" for > 30 minutes
2. **Action**:
   - Send reminder to user
   - Trigger VPN reconnection script
   - Log event for security audit

## Reporting and Analytics

### Custom Dashboard Widgets

#### VPN Status Distribution
```
Widget Type: Pie Chart
Data Source: VPN Connection Status sensor
Grouping: By status value
```

#### Certificate Health Overview
```
Widget Type: Bar Chart
Data Source: VPN Certificate Validity sensor
Grouping: Valid vs Invalid certificates
```

### Scheduled Reports

#### Weekly VPN Connectivity Report
- **Frequency**: Weekly
- **Recipients**: IT Security Team
- **Content**: VPN connection trends, certificate expiration alerts

#### Monthly Security Compliance Report
- **Frequency**: Monthly
- **Recipients**: CISO, IT Management
- **Content**: Certificate validity status, VPN usage patterns

## Troubleshooting

### Common Issues

1. **Sensor Returns "Error"**
   - Check PowerShell execution policy
   - Verify sensor runs with appropriate permissions
   - Review Windows Event Logs for certificate access issues

2. **False Negatives on Certificate Validation**
   - Ensure sensor runs in System context for machine certificates
   - Verify certificate store permissions
   - Check for custom certificate locations

3. **VPN Status Not Detected**
   - Confirm VPN client is supported
   - Verify service names and processes match VPN client version
   - Check network adapter detection logic

### Log Analysis

Monitor UEM sensor execution logs for:
- PowerShell execution errors
- Certificate access permission issues
- Network adapter enumeration failures
- Service detection problems

## Best Practices

1. **Sensor Frequency**: Balance monitoring needs with system performance
2. **Alert Fatigue**: Configure appropriate thresholds to avoid excessive notifications
3. **Documentation**: Maintain updated VPN client versions and certificate policies
4. **Testing**: Regularly test sensors in lab environment before production deployment
5. **Security**: Use least-privilege principles for sensor execution contexts

## Integration Examples

### ServiceNow Integration
```json
{
  "trigger": "VPN Certificate Validity = false",
  "action": "Create ServiceNow incident",
  "priority": "Medium",
  "assignment_group": "Desktop Support"
}
```

### Slack Notifications
```json
{
  "trigger": "VPN Connection Status = Error",
  "action": "Send Slack notification",
  "channel": "#it-alerts",
  "message": "VPN connection error detected on {{device.name}}"
}
```

## Version History

- **v1.0**: Initial release with basic VPN status detection
- **v1.1**: Added certificate validation functionality
- **v1.2**: Enhanced Workspace ONE UEM sensor compatibility
- **v1.3**: Added support for additional VPN clients

## Support

For issues or enhancements:
1. Review troubleshooting section
2. Check Workspace ONE UEM documentation
3. Test in isolated environment
4. Document findings for future reference
