# Load config
[xml]$config = Get-Content "$PSScriptRoot\config.xml"
$instance = $config.config.InstanceName
$database = $config.config.DatabaseName
write-host "$PSScriptRoot\config.xml"
# Connect to master DB to create the new one
$connectionString = $config.config.ConnectionString
$createSql = "CREATE DATABASE [$database]"

$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
$command = $connection.CreateCommand()
$command.CommandText = $createSql

$connection.Open()
$command.ExecuteNonQuery()
$connection.Close()

Write-Host "Database '$database' created in instance '$instance'."
