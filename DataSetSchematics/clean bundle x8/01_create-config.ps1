param(
    [Parameter(Position=0, HelpMessage = "Path to the history folder. If omitted, uses the default 'Data' folder next to this script.")]
    [string]$HistoryDir = $null,

    [Parameter(Position=1, HelpMessage = "Path to the output config.xml. If omitted, writes 'config.xml' next to this script.")]
    [string]$ConfigFile = $null
)

# 01_create-config.ps1
# Scan HISTORY subfolders and write a config.xml for the pipeline
# Usage: run from the scripts folder; it will write config.xml next to this script
# You can optionally pass a history directory: .\01_create-config.ps1 -HistoryDir "C:\path\to\history"

$RootFolderName = Split-Path -Path $PSScriptRoot -Leaf

# Determine history directory (default: Data next to the script)
if (-not $HistoryDir) {
    $historyDir = Join-Path $PSScriptRoot "Data"
} else {
    # If user provided a relative path, make it relative to the script folder
    if (-not [System.IO.Path]::IsPathRooted($HistoryDir)) {
        $historyDir = Join-Path $PSScriptRoot $HistoryDir
    } else {
        $historyDir = $HistoryDir
    }
}

# Determine config file path (default: config.xml next to the script)
if (-not $ConfigFile) {
    $configFile = Join-Path $PSScriptRoot "config.xml"
} else {
    if (-not [System.IO.Path]::IsPathRooted($ConfigFile)) {
        $configFile = Join-Path $PSScriptRoot $ConfigFile
    } else {
        $configFile = $ConfigFile
    }
}

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
} else {
    Write-Host "!! History directory not found: '$historyDir'" -ForegroundColor Yellow
}

$xml.Save($configFile)
Write-Host "? Config saved to '$configFile'"
Write-Host "? Using history directory: '$historyDir'"
if ($subfolders) { Write-Host "?? History tables:" ($subfolders.Name -join ", ") }
else { Write-Host "?? No HISTORY subfolders found to populate historytable entries." }