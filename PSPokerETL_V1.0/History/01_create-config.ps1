param(
    [string]$ConfigPath = "",
    [string]$HistoryRoot = ""
)

# Determine script and root names
$scriptDir = $PSScriptRoot
$RootFolderName = Split-Path -Path $scriptDir -Leaf

# If a HistoryRoot override wasn't provided, assume the script sits beside the folders with XML files
if ([string]::IsNullOrWhiteSpace($HistoryRoot)) {
    $historyDir = $scriptDir
} else {
    $historyDir = (Resolve-Path -Path $HistoryRoot -ErrorAction Stop).Path
}

# Config file location — default to the script directory unless overridden
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $configFile = Join-Path $scriptDir "config.xml"
} else {
    $configFile = $ConfigPath
}

$instanceName = "${RootFolderName}DB"
$databaseName = "${RootFolderName}Lake"
$server = "(localdb)\${instanceName}"
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

# Add historytable nodes only for subfolders that contain XML files
$subfolders = Get-ChildItem -Path $historyDir -Directory -ErrorAction SilentlyContinue | Where-Object {
    (Get-ChildItem -Path $_.FullName -Filter '*.xml' -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
}

foreach ($folder in $subfolders) {
    $ht = $xml.CreateElement("historytable")
    $ht.SetAttribute("name", $folder.Name)
    $root.AppendChild($ht) | Out-Null
}

# Save and echo
$xml.Save($configFile)
Write-Host "✅ Config saved to '$configFile'"
Write-Host "📁 History tables:" ($subfolders.Name -join ", ")
