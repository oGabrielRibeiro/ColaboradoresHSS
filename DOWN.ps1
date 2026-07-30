[CmdletBinding()]
param(
  [ValidateSet("dev", "prod")]
  [string]$Mode = "dev",
  [switch]$RemoveVolumes
)

# Importa funções de utilidade compartilhadas
. (Join-Path $PSScriptRoot "_common.ps1")

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
