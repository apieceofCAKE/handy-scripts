# A tiny script to decode Base64 data

param (
    [Parameter(Mandatory=$true)] [string] $base64String
)

Write-Host "Starting script...`n"

try {
    [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64String))
} catch {
    throw "Script failed. The error was: $_"
}

Read-Host -Prompt "`nPress ENTER to finish"