# Test Network Connectivity
# Tests basic internet connectivity to verify network fixes

$logDir = "C:\ProgramData\WorkspaceONE\logs"
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force
}

$log = "C:\ProgramData\WorkspaceONE\logs\TestConnectivity-$(Get-Date -Format yyyyMMdd-HHmmss).log"
function Log($m){ "$((Get-Date).ToString('u'))  $m" | Tee-Object -FilePath $log -Append | Out-Host }

Log "==== Testing Network Connectivity ===="

# Test targets
$testTargets = @(
    @{Name="Cloudflare DNS"; IP="1.1.1.1"},
    @{Name="Google DNS"; IP="8.8.8.8"},
    @{Name="OpenDNS"; IP="208.67.222.222"},
    @{Name="Intranet"; IP="192.168.4.8"}
)

$successfulTests = 0
$totalTests = $testTargets.Count

foreach ($target in $testTargets) {
    try {
        Log "Testing connectivity to $($target.Name) ($($target.IP))..."
        $result = Test-Connection -ComputerName $target.IP -Count 1 -Quiet -ErrorAction SilentlyContinue
        
        if ($result) {
            Log "$($target.Name) - SUCCESS"
            $successfulTests++
        } else {
            Log "$($target.Name) - FAILED"
        }
    } catch {
        Log "$($target.Name) - ERROR: $($_.Exception.Message)"
    }
}

# Test DNS resolution
try {
    Log "Testing DNS resolution..."
    $dnsTest = Resolve-DnsName -Name "google.com" -ErrorAction SilentlyContinue
    if ($dnsTest) {
        Log "DNS Resolution - SUCCESS"
        $successfulTests++
        $totalTests++
    } else {
        Log "DNS Resolution - FAILED"
        $totalTests++
    }
} catch {
    Log "DNS Resolution - ERROR: $($_.Exception.Message)"
    $totalTests++
}

Log "==== Connectivity Test Results ===="
Log "Successful tests: $successfulTests / $totalTests"

if ($successfulTests -gt 0) {
    if ($successfulTests -eq $totalTests) {
        Log "All connectivity tests passed - Network appears to be working properly"
        exit 0
    } else {
        Log "Partial connectivity - Some tests passed but network may still have issues"
        exit 2
    }
} else {
    Log "All connectivity tests failed - Network connectivity issues persist"
    exit 1
}
