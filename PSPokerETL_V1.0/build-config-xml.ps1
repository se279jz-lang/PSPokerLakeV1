# Derive identity
$RootFolderName = Split-Path -Path $PSScriptRoot -Leaf
$historyDir = Join-Path $PSScriptRoot "HISTORY"
$configFile = Join-Path $PSScriptRoot "config0.xml"

$instanceName = "${RootFolderName}DB"
$databaseName = "${RootFolderName}Lake"
$connectionString = "Server=(localdb)\$instanceName;Database=$databaseName;Integrated Security=True;"

# Create XML document
$xml = New-Object System.Xml.XmlDocument
$declaration = $xml.CreateXmlDeclaration("1.0", "UTF-8", $null)
$xml.AppendChild($declaration) | Out-Null

$root = $xml.CreateElement("config")
$xml.AppendChild($root) | Out-Null

# Add core elements
@{
    RootFolderName     = $RootFolderName
    InstanceName       = $instanceName
    DatabaseName       = $databaseName
    HistoryDirectory   = $historyDir
    ConnectionString   = $connectionString
    RestoreDirectory   = "Restore"
}.GetEnumerator() | ForEach-Object {
    $elem = $xml.CreateElement($_.Key)
    $elem.InnerText = $_.Value
    $root.AppendChild($elem) | Out-Null
}

# Add HistoryTables
$historyTables = $xml.CreateElement("HistoryTables")
$subfolders = Get-ChildItem -Path $historyDir -Directory
foreach ($folder in $subfolders) {
    $table = $xml.CreateElement("HistoryTable")
    $table.SetAttribute("name", $folder.Name)
    # $table.InnerText = $folder.Name
    $historyTables.AppendChild($table) | Out-Null
}
$root.AppendChild($historyTables) | Out-Null

# Save and echo
$xml.Save($configFile)
Write-Host "✅ Config saved to '$configFile'"
Write-Host "--- Initializing Project $RootFolderName ---" -ForegroundColor Green
Write-Host " instanceName: $instanceName" -ForegroundColor Green
Write-Host " databaseName: $databaseName" -ForegroundColor Green
Write-Host " connectionString: $connectionString" -ForegroundColor Green
Write-Host " historyDir: $historyDir" -ForegroundColor Green
Write-Host " configFile: $configFile" -ForegroundColor Green
Write-Host " subfolders: $($subfolders.Name -join ', ')" -ForegroundColor Green
Write-Host "--- Project initialization complete! ---" -ForegroundColor Green
