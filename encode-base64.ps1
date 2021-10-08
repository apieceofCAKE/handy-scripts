# A tiny script to encode data to Base64

param (
    [Parameter(Mandatory=$true)] [string] $Input
)

Write-Host "Starting script...`n"

try {
    $Bytes = [System.Text.Encoding]::ASCII.GetBytes($Input)
    $EncodedText =[Convert]::ToBase64String($Bytes)
    Write-Host $EncodedText
} catch {
    throw "Script failed. The error was: $_"
}

Read-Host -Prompt "`nPress ENTER to finish"