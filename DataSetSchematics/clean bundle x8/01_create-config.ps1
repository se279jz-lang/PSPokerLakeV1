# 01_create-config.ps1
# Scan HISTORY subfolders and write a config.xml for the pipeline
# Usage: run from the scripts folder; it will write config.xml next to this script

$RootFolderName = Split-Path -Path $PSScriptRoot -Leaf
$historyDir = Join-Path $PSScriptRoot "HISTORY"
$configFile = Join-Path $PSScriptRoot "config.xml"

$instanceName = "${RootFolderName}DB"
$databaseName = "${RootFolderName}Lake"
$connectionString = "Server=(localdb)\$instanceName;Database=$databaseName;Integrated Security=True;"

# Build XML
$xml = New-Object System.Xml.XmlDocument
$declaration = $xml.CreateXmlDeclaration("1.0", "UTF-8", $null)
$xml.AppendChild($declaration) | Out-Null

$root = $xml.CreateElement("config")
$xml.AppendChild($root) | Out-Null

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

# Add historytable nodes for each subfolder in HISTORY
if (Test-Path $historyDir) {
    $subfolders = Get-ChildItem -Path $historyDir -Directory -ErrorAction SilentlyContinue
    foreach ($folder in $subfolders) {
        $ht = $xml.CreateElement("historytable")
        $ht.SetAttribute("name", $folder.Name)
        $root.AppendChild($ht) | Out-Null
    }
}

$xml.Save($configFile)
Write-Host "? Config saved to '$configFile'"
if ($subfolders) { Write-Host "?? History tables:" ($subfolders.Name -join ", ") }
else { Write-Host "?? No HISTORY subfolders found to populate historytable entries." }