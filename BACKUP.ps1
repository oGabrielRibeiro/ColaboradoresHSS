[CmdletBinding()]
param(
  [ValidateSet("dev", "prod")]
  [string]$Mode = "dev",
  [string]$OutputDir = "backups"
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

function Get-EnvMap {
  if (-not (Test-Path ".env")) {
    Write-Fail ".env nao encontrado."
    exit 1
  }

  $map = @{}
  foreach ($line in Get-Content ".env") {
    if ($line -match "^\s*#") { continue }
    if (-not ($line -match "=")) { continue }
    $parts = $line.Split("=", 2)
    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    if ($key) { $map[$key] = $value }
  }
  return $map
}

$envMap = Get-EnvMap
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

if (-not (Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$fileName = "${dbName}_${Mode}_${timestamp}.sql"
$outputPath = Join-Path $OutputDir $fileName

Write-Step "Gerando backup do banco..."
$dump = docker exec $containerName pg_dump -U $dbUser -d $dbName --clean --if-exists
if ($LASTEXITCODE -ne 0) {
  Write-Fail "Falha no pg_dump."
  exit 1
}

[System.IO.File]::WriteAllText((Resolve-Path $outputPath), $dump)
Write-Ok "Backup criado em: $outputPath"
