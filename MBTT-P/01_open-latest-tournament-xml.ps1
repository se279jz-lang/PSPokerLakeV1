param (
    [string]$TableNumber
)

$TableNumber = 1141793836

$tournamentPath = "C:\Users\cnua\AppData\Local\Betfair Poker\data\cnuapkr\History\Data\Tournaments"

$latestFile = Get-ChildItem -Path $tournamentPath -Filter *.xml |
              Sort-Object LastWriteTime -Descending |
              Select-Object -First 1

if ($latestFile) {
    [xml]$xmlContent = Get-Content $latestFile.FullName

    $sessionCode = $xmlContent.session.'sessioncode'
    $tableName = $xmlContent.session.general.tablename.tostring().trim()
    $tableNumberN = 0
    # Extract numeric identifier from table name
    if ($tableName -match '\d{6,}') {
        $tableNumberN = $matches[0]
        # Write-Host "Table number detected: $tableNumberN"
     }
    Write-Host "=== FAI TERMINAL REPORT ==="
    Write-Host "INPUT: TableNumber → $TableNumber"
    Write-Host "PARSED: TableNumberN → $TableNumberN"
    Write-Host "EXTRACTED: TableName → $tableName"
    Write-Host "EXTRACTED: SessionCode → $sessionCode"
    Write-Host "FILENAME: $($latestFile.BaseName)"
    Write-Host "----------------------------"

    $tableMatch = $tableName -like "*$TableNumber*"
    $fileMatch = $latestFile.BaseName -eq $sessionCode

    Write-Host "VALIDATION: TableName contains TableNumber → $tableMatch"
    Write-Host "VALIDATION: Filename matches SessionCode → $fileMatch"

    if ($tableMatch -and $fileMatch) {
        Write-Host "STATUS: ✅ CONCURRENCY VALIDATED — LAUNCHING FILE"
        Start-Process $latestFile.FullName
    } else {
        Write-Host "STATUS: ❌ VALIDATION FAILED — FILE NOT LAUNCHED"
    }

    Write-Host "============================"
} else {
    Write-Host "STATUS: ❌ NO XML FILES FOUND"
}
