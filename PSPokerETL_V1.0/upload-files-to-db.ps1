param(
    [string]$ConfigPath = "$PSScriptRoot\config.xml",
    [string]$HistoryRoot = $null,
    [string]$Instance = $null,
    [string]$Database = $null,
    [string]$Since = $null
)

# Load config (or use provided ConfigPath)
[xml]$config = Get-Content $ConfigPath

# Determine connection string: prefer explicit instance/database if provided
if ($Instance -and $Database) {
    $SqlConnectionString = "Server=$Instance;Database=$Database;Integrated Security=True;"
} else {
    $SqlConnectionString = $config.config.ConnectionString.ToString().Trim()
}

# Determine history directory: prefer explicit override
if ($HistoryRoot) {
    $HistoryDirectory = $HistoryRoot
} else {
    $HistoryDirectory = $config.config.HistoryDirectory.ToString().Trim()
}

$historyTables = $config.config.historytable

function Get-Sha256Hash([string]$Content) {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $hash = $sha256.ComputeHash($bytes)
    return -join ($hash | ForEach-Object { $_.ToString("x2") })
}

$connection = New-Object System.Data.SqlClient.SqlConnection $SqlConnectionString
$connection.Open()
Write-Host "🔗 Connected to SQL Server" -ForegroundColor Green

foreach ($table in $historyTables) {
    $subfolder = $table.name.Trim()
    $folderPath = Join-Path $HistoryDirectory $subfolder
    $files = Get-ChildItem -Path $folderPath -Filter *.xml -ErrorAction SilentlyContinue

    if (-not $files) {
        Write-Warning "⚠️ No XML files found in '$folderPath'"
        continue
    }

    Write-Host "📁 Uploading from '$folderPath' to 'Lake_$subfolder'" -ForegroundColor Cyan

    foreach ($file in $files) {
        $rawXml = Get-Content $file.FullName -Raw
        $xmlContent = $rawXml -replace '^<\?xml.*?\?>\s*', ''

        try {
            [xml]$null = $xmlContent
        } catch {
            Write-Warning "❌ Invalid XML: $($file.Name). Skipping."
            continue
        }

        $fileName = $file.Name
        $fileSize = $file.Length
        $sha256 = Get-Sha256Hash $xmlContent
        $creationTime = $file.CreationTimeUtc
        $lastWriteTime = $file.LastWriteTimeUtc

        $checkCmd = $connection.CreateCommand()
        $checkCmd.CommandText = "SELECT COUNT(*) FROM dbo.Lake_$subfolder WHERE Sha256Hash = @Sha256Hash"
        $checkCmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Sha256Hash", $sha256))) | Out-Null
        $exists = $checkCmd.ExecuteScalar()

        if ($exists -gt 0) {
            Write-Host "⏩ Skipped duplicate: $fileName" -ForegroundColor Yellow
            continue
        }

        $insertCmd = $connection.CreateCommand()
        $insertCmd.CommandText = @"
INSERT INTO dbo.Lake_$subfolder (FileName, XmlContent, UploadTime, FileSize, Sha256Hash, OriginalCreationTime, OriginalLastWriteTime)
VALUES (@FileName, @XmlContent, SYSUTCDATETIME(), @FileSize, @Sha256Hash, @OriginalCreationTime, @OriginalLastWriteTime)
"@
    $insertCmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@FileName", $fileName)))
    $insertCmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@XmlContent", $xmlContent)))
    $insertCmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@FileSize", $fileSize)))
    $insertCmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Sha256Hash", $sha256)))
    $insertCmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@OriginalCreationTime", $creationTime)))
    $insertCmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@OriginalLastWriteTime", $lastWriteTime)))

        try {
            $insertCmd.ExecuteNonQuery()
            Write-Host "✅ Uploaded: $fileName" -ForegroundColor Green
        } catch {
            Write-Warning "❌ Failed to upload '$fileName': $($_.Exception.Message)"
        }
    }
}

$connection.Close()
Write-Host "🏁 Upload complete. Connection closed." -ForegroundColor Cyan
