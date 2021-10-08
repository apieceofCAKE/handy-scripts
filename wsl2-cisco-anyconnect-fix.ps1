# This script is used to make WSL2 properly connect to the internet when using AnyConnect VPN
# Reference: https://github.com/microsoft/WSL/issues/5068

# TO-DO: 
#   fix: It doens't work when not started from an admin session

param (
    [Parameter()] $netInterfaceDescription = "Cisco AnyConnect",
    [Parameter()] $netInterfaceMetric = 6000,
    [Parameter()] $testEndpoint = "google.com"
)

function Test-Admin {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
        return $principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )
    } catch {
        throw "Failed to determine if the current user has elevated privileges. The error was: $_"
    }
}

function Test-Conn() {
    return Test-Connection $testEndpoint -Quiet
}

Write-Host "Starting script..."
Write-Host "Checking if Powershell is running with admin privileges..."

if ((Test-Admin) -eq $false)  {
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))    
    } catch {
        throw "Failed to start Powershell as an admin. The error was: $_"
    }
}

Write-Host "Running with admin privileges" -ForegroundColor Green

$ConnectionStatus = $false
$Counter = 0

do {
    Write-Host "Trying to change network settings..."

    Get-NetAdapter | Where-Object {$_.InterfaceDescription -Match $netInterfaceDescription} | Set-NetIPInterface -InterfaceMetric 6000

    $ConnectionStatus = Test-Connection $testEndpoint -Quiet
    $Counter ++

    write-verbose "$(Test-Connection $testEndpoint)"

    if ($ConnectionStatus -eq $true) {
        Write-Host "Ping succeeded!" -ForegroundColor Green
    } else {
        Write-Host "Ping failed on $Counter try!" -ForegroundColor Red
    }

} while (($ConnectionStatus -ne $true) -and ($Counter -lt 10))

if ($Counter -eq 10) {
    Write-Host "Reached maximum number of retries. Check your network settings" -ForegroundColor Yellow
}

Write-Host "Finishing script..."
Read-Host -Prompt "Press ENTER to finish"





