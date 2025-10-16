# Derive identity
$RootFolderName = Split-Path -Path $PSScriptRoot -Leaf
$historyDir = Join-Path $PSScriptRoot "HISTORY"
$configFile = Join-Path $PSScriptRoot "config.xml"

$instanceName = "${RootFolderName}DB"
$databaseName = "${RootFolderName}Lake"
$server="(localdb)\${instanceName}"
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

# Add historytable nodes directly
$subfolders = Get-ChildItem -Path $historyDir -Directory
foreach ($folder in $subfolders) {
    $ht = $xml.CreateElement("historytable")
    $ht.SetAttribute("name", $folder.Name)
    $root.AppendChild($ht) | Out-Null
}

# Save and echo
$xml.Save($configFile)
Write-Host "✅ Config saved to '$configFile'"
Write-Host "📁 History tables:" ($subfolders.Name -join ", ")
