# Path to your Betfair Poker tournament history folder
$tournamentPath = "C:\Users\cnua\AppData\Local\Betfair Poker\data\cnuapkr\History\Data\Tournaments"

# Get the latest .xml file
$latestFile = Get-ChildItem -Path $tournamentPath -Filter *.xml |
              Sort-Object LastWriteTime -Descending |
              Select-Object -First 1

# Parse and validate based on table number
if ($latestFile) {
    [xml]$xmlContent = Get-Content $latestFile.FullName
    $tableName = $xmlContent.session.general.tablename.tostring().trim()

    # Extract numeric identifier from table name
    if ($tableName -match '\d{6,}') {
        $tableNumber = $matches[0]
        Write-Host "Table number detected: $tableNumber"
        Start-Process $latestFile.FullName
    } else {
        Write-Host "No valid table number found in tablename."
    }
} else {
    Write-Host "No XML files found in the tournaments folder."
}
