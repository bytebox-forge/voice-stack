# Voice Stack Connection Test Script
# Run this in PowerShell on your Docker host

Write-Host "=== Voice Stack Connection Test ===" -ForegroundColor Green
Write-Host ""

# Test 1: Check if ports are bound locally
Write-Host "1. Checking port bindings..." -ForegroundColor Yellow
$ports = @("8008", "8080")
foreach ($port in $ports) {
    $binding = netstat -an | Select-String ":$port " | Select-String "0.0.0.0" | Select-Object -First 1
    if ($binding) {
        Write-Host "   Port $port is bound: $($binding.Line.Trim())" -ForegroundColor Green
    } else {
        Write-Host "   Port $port is NOT bound!" -ForegroundColor Red
    }
}

Write-Host ""

# Test 2: Test local HTTP connectivity
Write-Host "2. Testing local HTTP connectivity..." -ForegroundColor Yellow

# Test Synapse
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8008" -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    Write-Host "   Synapse (8008): WORKING - Status $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   Synapse (8008): FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test Element
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    Write-Host "   Element (8080): WORKING - Status $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   Element (8080): FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Check Docker containers (if Docker CLI is available)
Write-Host "3. Checking Docker containers..." -ForegroundColor Yellow
try {
    $containers = docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" 2>$null
    if ($containers) {
        Write-Host "   Docker containers:" -ForegroundColor Green
        $containers | ForEach-Object { Write-Host "   $_" }
    } else {
        Write-Host "   Docker CLI not available or no containers running" -ForegroundColor Red
    }
} catch {
    Write-Host "   Docker CLI not available" -ForegroundColor Red
}

Write-Host ""

# Test 4: Network interface check
Write-Host "4. Checking network interfaces..." -ForegroundColor Yellow
$interfaces = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -match "^192\.168\." -or $_.IPAddress -match "^10\." -or $_.IPAddress -match "^172\." }
foreach ($interface in $interfaces) {
    Write-Host "   Interface: $($interface.IPAddress)" -ForegroundColor Cyan
}

Write-Host ""

# Test 5: Windows Firewall check
Write-Host "5. Checking Windows Firewall..." -ForegroundColor Yellow
try {
    $firewallEnabled = Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $true }
    if ($firewallEnabled) {
        Write-Host "   Windows Firewall is ENABLED" -ForegroundColor Yellow
        Write-Host "   You may need to add firewall rules for ports 8008 and 8080" -ForegroundColor Yellow
    } else {
        Write-Host "   Windows Firewall is DISABLED" -ForegroundColor Green
    }
} catch {
    Write-Host "   Could not check Windows Firewall status" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps based on results:" -ForegroundColor Yellow
Write-Host "- If ports are NOT bound: Check container status in Portainer" -ForegroundColor White
Write-Host "- If local HTTP tests FAIL: Check container logs in Portainer" -ForegroundColor White
Write-Host "- If local works but external fails: Check Windows Firewall" -ForegroundColor White
Write-Host "- If everything fails: Redeploy the stack" -ForegroundColor White
