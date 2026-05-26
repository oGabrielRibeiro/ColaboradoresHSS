[CmdletBinding()]
param(
  [ValidateSet("dev", "prod")]
  [string]$Mode = "dev",
  [switch]$WithFrontend,
  [int]$FrontendPort = 3001,
  [switch]$NoBuild
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
  Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
  Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-WarnMsg([string]$Message) {
  Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail([string]$Message) {
  Write-Host "[ERRO] $Message" -ForegroundColor Red
}

function Assert-Command([string]$CommandName, [string]$InstallHint) {
  if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
    Write-Fail "$CommandName nao encontrado. $InstallHint"
    exit 1
  }
}

function Get-ComposeCmd {
  try {
    docker compose version | Out-Null
    return @("docker", "compose")
  } catch {
    Write-Fail "Docker Compose V2 nao encontrado. Atualize o Docker Desktop."
    exit 1
  }
}

function Ensure-EnvFile {
  if (-not (Test-Path ".env")) {
    if (-not (Test-Path ".env.example")) {
      Write-Fail "Nao foi encontrado .env nem .env.example."
      exit 1
    }
    Copy-Item ".env.example" ".env"
    Write-WarnMsg ".env criado a partir de .env.example. Revise credenciais antes de continuar."
  }
}

function Validate-EnvContent {
  $requiredVars = @(
    "DB_USER", "DB_PASS", "DB_NAME", "JWT_SECRET",
    "RH_DEFAULT_EMAIL", "RH_DEFAULT_PASSWORD"
  )

  $content = Get-Content ".env" -ErrorAction Stop
  $envMap = @{}
  foreach ($line in $content) {
    if ($line -match "^\s*#") { continue }
    if (-not ($line -match "=")) { continue }
    $parts = $line.Split("=", 2)
    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    if ($key) { $envMap[$key] = $value }
  }

  $missing = @()
  foreach ($key in $requiredVars) {
    if (-not $envMap.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($envMap[$key])) {
      $missing += $key
    }
  }

  if ($missing.Count -gt 0) {
    Write-Fail "Variaveis obrigatorias ausentes no .env: $($missing -join ', ')"
    exit 1
  }

  if ($envMap["RH_DEFAULT_PASSWORD"] -eq "123456") {
    Write-WarnMsg "RH_DEFAULT_PASSWORD esta fraca (123456). Troque para uso fora de testes."
  }

  if ($envMap.ContainsKey("CORS_ORIGIN") -and [string]::IsNullOrWhiteSpace($envMap["CORS_ORIGIN"])) {
    Write-WarnMsg "CORS_ORIGIN vazio: a API pode aceitar qualquer origem."
  }
}

function Ensure-UploadsFolder {
  if (-not (Test-Path "uploads")) {
    New-Item -ItemType Directory -Path "uploads" | Out-Null
    Write-Ok "Pasta uploads criada."
  }
}

function Check-PortUsage([int[]]$Ports) {
  foreach ($port in $Ports) {
    $tcp = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($tcp) {
      $pids = ($tcp | Select-Object -ExpandProperty OwningProcess -Unique)
      $procNames = @()
      foreach ($pid in $pids) {
        try {
          $procNames += (Get-Process -Id $pid -ErrorAction Stop).ProcessName
        } catch {
          $procNames += "PID:$pid"
        }
      }
      Write-WarnMsg "Porta $port ja em uso por: $($procNames -join ', ')"
    }
  }
}

function Wait-ApiHealth([int]$SecondsTimeout = 90) {
  $deadline = (Get-Date).AddSeconds($SecondsTimeout)
  $url = "http://localhost:3000/health"

  while ((Get-Date) -lt $deadline) {
    try {
      $response = Invoke-RestMethod -Method Get -Uri $url -TimeoutSec 5
      if ($response.status -eq "ok") {
        Write-Ok "API saudavel em $url"
        return
      }
    } catch {
      Start-Sleep -Seconds 2
    }
  }

  Write-Fail "API nao respondeu healthcheck em ate $SecondsTimeout segundos."
  exit 1
}

function Start-Frontend([int]$Port) {
  Assert-Command "flutter" "Instale o Flutter SDK e adicione ao PATH."
  Write-Step "Iniciando frontend Flutter Web na porta $Port..."
  $frontendPath = Join-Path (Get-Location) "frontend"

  Start-Process -FilePath "powershell" `
    -ArgumentList @(
      "-NoExit",
      "-Command",
      "cd `"$frontendPath`"; flutter pub get; flutter run -d chrome --web-port $Port"
    ) | Out-Null

  Write-Ok "Frontend iniciado em nova janela do PowerShell."
}

Write-Step "Validando pre-requisitos..."
Assert-Command "docker" "Instale o Docker Desktop."
$composeCmd = Get-ComposeCmd

try {
  docker info | Out-Null
  Write-Ok "Docker Engine ativo."
} catch {
  Write-Fail "Docker nao esta ativo. Abra o Docker Desktop e tente novamente."
  exit 1
}

Write-Step "Validando arquivos locais..."
Ensure-EnvFile
Validate-EnvContent
Ensure-UploadsFolder

Write-Step "Verificando portas locais..."
Check-PortUsage -Ports @(3000, 5432, $FrontendPort)

$composeFile = if ($Mode -eq "prod") { "docker-compose.prod.yml" } else { "docker-compose.yml" }
if (-not (Test-Path $composeFile)) {
  Write-Fail "Arquivo $composeFile nao encontrado."
  exit 1
}

Write-Step "Subindo containers ($Mode)..."
$upArgs = @("-f", $composeFile, "up", "-d")
if (-not $NoBuild) {
  $upArgs += "--build"
}

& $composeCmd[0] $composeCmd[1] @upArgs
if ($LASTEXITCODE -ne 0) {
  Write-Fail "Falha ao subir containers."
  exit 1
}
Write-Ok "Containers iniciados."

Write-Step "Aguardando healthcheck da API..."
Wait-ApiHealth -SecondsTimeout 120

if ($WithFrontend) {
  Start-Frontend -Port $FrontendPort
}

Write-Host ""
Write-Ok "Ambiente pronto."
Write-Host "API:       http://localhost:3000" -ForegroundColor White
Write-Host "Health:    http://localhost:3000/health" -ForegroundColor White
if ($WithFrontend) {
  Write-Host "Frontend:  http://localhost:$FrontendPort" -ForegroundColor White
} else {
  Write-Host "Frontend:  execute manualmente em ./frontend com flutter run -d chrome --web-port $FrontendPort" -ForegroundColor White
}
Write-Host ""
