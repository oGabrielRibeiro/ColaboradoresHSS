[CmdletBinding()]
param(
  [ValidateSet("dev", "prod")]
  [string]$Mode = "dev",
  [Parameter(Mandatory = $true)]
  [string]$BackupFile
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
  Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
  Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Fail([string]$Message) {
  Write-Host "[ERRO] $Message" -ForegroundColor Red
}

if (-not (Test-Path $BackupFile)) {
  Write-Fail "Arquivo de backup nao encontrado: $BackupFile"
  exit 1
}

if (-not (Test-Path ".env")) {
  Write-Fail ".env nao encontrado."
  exit 1
}

$envMap = @{}
foreach ($line in Get-Content ".env") {
  if ($line -match "^\s*#") { continue }
  if (-not ($line -match "=")) { continue }
  $parts = $line.Split("=", 2)
  $key = $parts[0].Trim()
  $value = $parts[1].Trim()
  if ($key) { $envMap[$key] = $value }
}

$dbUser = $envMap["DB_USER"]
$dbName = $envMap["DB_NAME"]
if ([string]::IsNullOrWhiteSpace($dbUser) -or [string]::IsNullOrWhiteSpace($dbName)) {
  Write-Fail "DB_USER ou DB_NAME nao definidos no .env."
  exit 1
}

$containerName = if ($Mode -eq "prod") {
  "colaboradores_hss_db_prod"
} else {
  "colaboradores_hss_db"
}

Write-Step "Validando container do banco: $containerName"
$running = docker ps --format "{{.Names}}" | Select-String -SimpleMatch $containerName
if (-not $running) {
  Write-Fail "Container $containerName nao esta em execucao."
  exit 1
}

$confirm = Read-Host "Isso vai sobrescrever dados do banco '$dbName'. Digite RESTORE para continuar"
if ($confirm -ne "RESTORE") {
  Write-Fail "Operacao cancelada."
  exit 1
}

$resolved = (Resolve-Path $BackupFile).Path
Write-Step "Aplicando restore..."
Get-Content -Path $resolved -Raw | docker exec -i $containerName psql -U $dbUser -d $dbName
if ($LASTEXITCODE -ne 0) {
  Write-Fail "Falha ao restaurar backup."
  exit 1
}

Write-Ok "Restore concluido com sucesso."
