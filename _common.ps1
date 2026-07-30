# _common.ps1 - Funções compartilhadas para os scripts de ambiente

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
    }
    catch {
        Write-Fail "Docker Compose V2 nao encontrado. Atualize o Docker Desktop."
        exit 1
    }
}