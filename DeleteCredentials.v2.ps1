# Script to selectively delete Windows credentials from Credential Manager and log deletions
# This requires administrative privileges to run properly

# Create a timestamp for the log file
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "CredentialDeletionLog-$timestamp.txt"
$logPath = Join-Path -Path $env:USERPROFILE -ChildPath $logFile

# Display the script header
Write-Host "===== Windows Credential Manager: Selective Deletion =====" -ForegroundColor Cyan
Write-Host "This script will delete selected Windows credentials and create a log file at:" -ForegroundColor Cyan
Write-Host "$logPath" -ForegroundColor Yellow
Write-Host ""

# Get deletion mode from user
Write-Host "Deletion options:" -ForegroundColor Yellow
Write-Host "1. Delete ALL credentials" -ForegroundColor Yellow
Write-Host "2. Delete credentials containing a specific term" -ForegroundColor Yellow
$deleteMode = Read-Host -Prompt "Please select an option (1 or 2)"

$searchTerm = ""
$deleteAll = $true

if ($deleteMode -eq "2") {
    $deleteAll = $false
    $searchTerm = Read-Host -Prompt "Enter the search term for credentials to delete (case-insensitive)"
    Write-Host "Will delete credentials containing: '$searchTerm'" -ForegroundColor Yellow
} else {
    Write-Host "Will delete ALL credentials." -ForegroundColor Red
}

# Confirm deletion
if ($deleteAll) {
    $confirmation = Read-Host -Prompt "Type 'YES' to delete ALL credentials or anything else to cancel"
    if ($confirmation -ne "YES") {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
        exit
    }
} else {
    $confirmation = Read-Host -Prompt "Type 'YES' to delete credentials containing '$searchTerm' or anything else to cancel"
    if ($confirmation -ne "YES") {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
        exit
    }
}

# Start the log file
"# Windows Credential Manager Deletion Log" | Out-File -FilePath $logPath -Force
"# Created: $(Get-Date)" | Out-File -FilePath $logPath -Append
"# Machine: $env:COMPUTERNAME" | Out-File -FilePath $logPath -Append
"# User: $env:USERNAME" | Out-File -FilePath $logPath -Append
"# Deletion mode: $(if ($deleteAll) {"ALL credentials"} else {"Credentials containing '$searchTerm'"})" | Out-File -FilePath $logPath -Append
"" | Out-File -FilePath $logPath -Append

# Get all credentials using cmdkey
Write-Host "`nGetting list of all credentials..." -ForegroundColor Cyan
$credentialOutput = cmdkey /list
$allCredentials = $credentialOutput | Where-Object { $_ -like "*Target:*" }

if ($allCredentials.Count -eq 0) {
    Write-Host "No credentials found in Credential Manager." -ForegroundColor Green
    "No credentials found in Credential Manager." | Out-File -FilePath $logPath -Append
    exit
}

# Filter credentials if needed
$credentials = @()
if ($deleteAll) {
    $credentials = $allCredentials
} else {
    foreach ($cred in $allCredentials) {
        if ($cred -match "(?i)$searchTerm") {
            $credentials += $cred
        }
    }
}

# Check if we found matching credentials
$credentialCount = $credentials.Count
if ($credentialCount -eq 0) {
    Write-Host "No credentials matching '$searchTerm' found." -ForegroundColor Yellow
    "No credentials matching '$searchTerm' found." | Out-File -FilePath $logPath -Append
    exit
}

# Display how many credentials were found
Write-Host "Found $credentialCount credential entries matching criteria." -ForegroundColor Cyan
"Found $credentialCount credential entries matching criteria." | Out-File -FilePath $logPath -Append

# Log the complete credential list before deletion
"" | Out-File -FilePath $logPath -Append
"## Complete Credential List Before Deletion" | Out-File -FilePath $logPath -Append
"" | Out-File -FilePath $logPath -Append

if ($deleteAll) {
    $credentialOutput | Out-File -FilePath $logPath -Append
} else {
    "### All Available Credentials" | Out-File -FilePath $logPath -Append
    $credentialOutput | Out-File -FilePath $logPath -Append
    
    "### Credentials Selected for Deletion (containing '$searchTerm')" | Out-File -FilePath $logPath -Append
    $credentials | Out-File -FilePath $logPath -Append
}

"" | Out-File -FilePath $logPath -Append
"## Deletion Process" | Out-File -FilePath $logPath -Append
"" | Out-File -FilePath $logPath -Append

# Extract target names
$targetNames = @()
foreach ($cred in $credentials) {
    if ($cred -match "Target: (.+)") {
        $targetNames += $matches[1].Trim()
    }
}

# Final confirmation with count
Write-Host "`nReady to delete $($targetNames.Count) credential(s)." -ForegroundColor Yellow
$finalConfirm = Read-Host -Prompt "Type 'DELETE' to proceed or anything else to cancel"
if ($finalConfirm -ne "DELETE") {
    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    "Deletion cancelled by user at final confirmation." | Out-File -FilePath $logPath -Append
    exit
}

# Counter for deleted credentials
$deletedCount = 0

# Delete each credential
foreach ($target in $targetNames) {
    Write-Host "Deleting credential: $target" -ForegroundColor Yellow
    "Attempting to delete: $target" | Out-File -FilePath $logPath -Append
    
    $result = cmdkey /delete:$target
    
    if ($result -like "*successfully*") {
        $deletedCount++
        Write-Host "Successfully deleted: $target" -ForegroundColor Green
        "SUCCESS: Deleted $target" | Out-File -FilePath $logPath -Append
    } else {
        Write-Host "Failed to delete: $target" -ForegroundColor Red
        "FAILED: Could not delete $target" | Out-File -FilePath $logPath -Append
    }
}

# Summary
$summary = @"

## Summary
Mode: $(if ($deleteAll) {"Delete ALL credentials"} else {"Delete credentials containing '$searchTerm'"})
Total credentials matching criteria: $($targetNames.Count)
Successfully deleted: $deletedCount
Failed to delete: $($targetNames.Count - $deletedCount)
Log file saved to: $logPath
"@

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "Mode: $(if ($deleteAll) {"Delete ALL credentials"} else {"Delete credentials containing '$searchTerm'"})"-ForegroundColor White
Write-Host "Total credentials matching criteria: $($targetNames.Count)" -ForegroundColor White
Write-Host "Successfully deleted: $deletedCount" -ForegroundColor Green
Write-Host "Failed to delete: $($targetNames.Count - $deletedCount)" -ForegroundColor Yellow
Write-Host "Log file saved to: $logPath" -ForegroundColor Cyan

$summary | Out-File -FilePath $logPath -Append

Write-Host "`nCredential Manager cleanup completed." -ForegroundColor Cyan