# 05_upload-files.ps1
# Upload XML files from HISTORY subfolders into Lake_* tables per config.xml
[xml]$config = Get-Content "$PSScriptRoot\config.xml"
$instance = $config.config.InstanceName.ToString().Trim()
$database = $config.config.DatabaseName.ToString().Trim()
$tables   = $config.config.historytable

function Invoke-Sql([string]$Q){ & sqlcmd -S "(localdb)\$instance" -d $database -b -Q $Q }

foreach ($t in $tables) {
  $lake = "Lake_" + $t.name.Trim()
  $folder = Join-Path $PSScriptRoot "HISTORY\$($t.name)"
  Write-Host "=== Uploading from $folder into $lake ==="

  $files = Get-ChildItem -Path $folder -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue
  if (-not $files) { Write-Host "  (no files)"; continue }

  foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $sha = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    $hash = ([System.BitConverter]::ToString($sha)).Replace("-", "").ToLower()
    $xml = [xml](Get-Content -Path $f.FullName -Raw)
    $sessionCode = $null
    try { $sessionCode = $xml.session.sessioncode } catch { }
    if (-not $sessionCode) { $sessionCode = [System.IO.Path]::GetFileNameWithoutExtension($f.Name) }
    $xmlEsc = $xml.OuterXml.Replace("'", "''")

    try {
      Invoke-Sql @"
INSERT INTO dbo.$lake (FileName, XmlContent, UploadTime, FileSize, Sha256Hash, OriginalCreationTime, OriginalLastWriteTime, SessionCode, processed)
VALUES (N'$($f.Name)', CONVERT(XML, N'$xmlEsc'), SYSUTCDATETIME(), $($f.Length), '$hash',
        '$($f.CreationTimeUtc.ToString("o"))', '$($f.LastWriteTimeUtc.ToString("o"))', N'$sessionCode', 0);
"@
      Write-Host "  ? Uploaded $($f.Name)"
    } catch {
      if ($_.Exception.Message -match "UQ_.*_Hash" -or $_.Exception.Message -match "UQ_.*_Session") {
        Write-Host "  ? Skipped duplicate $($f.Name)"
      } else {
        Write-Warning "  ? Error $($f.Name): $($_.Exception.Message)"
      }
    }
  }
}
