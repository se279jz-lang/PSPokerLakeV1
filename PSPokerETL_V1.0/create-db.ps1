# File: create-db.ps1
param(
  [string]$Instance = "(localdb)\MSSQLLocalDB",
  [string]$Database = "PokerHistory"
)

sqlcmd -S $Instance -Q "IF DB_ID('$Database') IS NULL CREATE DATABASE [$Database];"
