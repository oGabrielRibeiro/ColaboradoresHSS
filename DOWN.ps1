[CmdletBinding()]
param(
  [ValidateSet("dev", "prod")]
  [string]$Mode = "dev",
  [switch]$RemoveVolumes
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

function Get-ComposeCmd {
  try {
    docker compose version | Out-Null
    return @("docker", "compose")
  } catch {
    Write-Fail "Docker Compose V2 nao encontrado."
    exit 1
  }
}

$composeCmd = Get-ComposeCmd
$composeFile = if ($Mode -eq "prod") { "docker-compose.prod.yml" } else { "docker-compose.yml" }

if (-not (Test-Path $composeFile)) {
  Write-Fail "Arquivo $composeFile nao encontrado."
  exit 1
}

Write-Step "Parando ambiente ($Mode)..."
$args = @("-f", $composeFile, "down")
if ($RemoveVolumes) {
  $args += "-v"
}

& $composeCmd[0] $composeCmd[1] @args
if ($LASTEXITCODE -ne 0) {
  Write-Fail "Falha ao parar containers."
  exit 1
}

Write-Ok "Ambiente finalizado."
