param (
    [string]$FolderPath = "C:\\path\\to\\your\\xmlfiles",
    [string]$SqlConnectionString = "Data Source=(localdb)\\ProjectModels;Initial Catalog=BetfairPhhDataLake;Integrated Security=True;",
    [string]$TableName = "Lake_CashTables_Compliance"
)

function Get-Sha256Hash([string]$Content) {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $hash = $sha256.ComputeHash($bytes)
    return -join ($hash | ForEach-Object { $_.ToString("x2") })
}

$files = Get-ChildItem -Path $FolderPath -Filter *.xml
$connection = New-Object System.Data.SqlClient.SqlConnection $SqlConnectionString
$connection.Open()

foreach ($file in $files) {
    $rawContent = Get-Content $file.FullName -Raw
    $xmlContent = $rawContent -replace '<\?xml.*encoding=.*\?>', ''
    try {
        [xml]$null = $xmlContent
    } catch {
        Write-Warning "Invalid XML: $($file.Name). Skipping."
        continue
    }
    $fileName = $file.Name
    $fileSize = $file.Length
    $sha256 = Get-Sha256Hash $rawContent
    $creationTime = $file.CreationTimeUtc
    $lastWriteTime = $file.LastWriteTimeUtc

    $checkCmd = $connection.CreateCommand()
    $checkCmd.CommandText = "SELECT COUNT(*) FROM dbo.$TableName WHERE Sha256Hash = @Sha256Hash"
    $checkCmd.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Sha256Hash", $sha256)))
    $exists = $checkCmd.ExecuteScalar()
    if ($exists -gt 0) {
        Write-Host "Skipping already uploaded file: $fileName"
        continue
    }

    $query = @"
INSERT INTO dbo.$TableName (FileName, XmlContent, UploadTime, FileSize, Sha256Hash, OriginalCreationTime, OriginalLastWriteTime)
VALUES (@FileName, @XmlContent, SYSUTCDATETIME(), @FileSize, @Sha256Hash, @OriginalCreationTime, @OriginalLastWriteTime)
"@

    $command = $connection.CreateCommand()
    $command.CommandText = $query

    $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@FileName", $fileName)))
    $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@XmlContent", $xmlContent)))
    $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@FileSize", $fileSize)))
    $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@Sha256Hash", $sha256)))
    $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@OriginalCreationTime", $creationTime)))
    $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@OriginalLastWriteTime", $lastWriteTime)))

    $command.ExecuteNonQuery()
    Write-Host "Uploaded $fileName"
}
$connection.Close()
