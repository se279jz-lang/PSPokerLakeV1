# List all LocalDB instances
$instances = & SqlLocalDB info | Where-Object { $_ -ne "" }

if ($instances.Count -eq 0) {
    Write-Host "No LocalDB instances found."
    return
}

# Present instances for selection
Write-Host "Available LocalDB Instances:"
for ($i = 0; $i -lt $instances.Count; $i++) {
    Write-Host "$($i + 1): $($instances[$i])"
}
https://copilot.microsoft.com/shares/pages/qFJtsZUd2rCLimyddkvSL
# Prompt user to select an instance
$selection = Read-Host "Enter the number of the instance to delete"
$index = [int]$selection - 1

if ($index -ge 0 -and $index -lt $instances.Count) {
    $selectedInstance = $instances[$index]
    Write-Host "You selected: $selectedInstance"
    
    # Confirm deletion
    $confirm = Read-Host "Type 'DELETE' to confirm deletion of $selectedInstance"
    if ($confirm -eq "DELETE") {
        # Stop and delete the instance
        SqlLocalDB stop $selectedInstance -ErrorAction SilentlyContinue
        SqlLocalDB delete $selectedInstance
        Write-Host "Instance '$selectedInstance' has been deleted."
    } else {
        Write-Host "Deletion cancelled. Instance '$selectedInstance' remains intact."
    }
} else {
    Write-Host "Invalid selection. No instance deleted."
}
