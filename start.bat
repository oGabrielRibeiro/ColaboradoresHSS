@echo off
setlocal enabledelayedexpansion

REM =============================================================================
REM START.BAT - Script de inicialização automática para Windows
REM Descrição: Sobe backend, frontend e banco com um único comando (para Windows)
REM =============================================================================

echo [INFO] Iniciando sistema de documentos HSS...
echo [INFO] Timestamp: %date% %time%

REM Verifica Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRO] Docker não encontrado. Instale Docker Desktop e tente novamente.
    exit /b 1
)

REM Verifica Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRO] Node.js não encontrado. Instale Node.js v18+.
    exit /b 1
)

REM Verifica Flutter
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRO] Flutter não encontrado. Instale Flutter SDK.
    exit /b 1
)

echo [INFO] ✅ Todos os pré-requisitos verificados

REM Inicia Docker Compose
echo [INFO] Iniciando Docker Compose...
cd backend

docker-compose up -d
if %errorlevel% neq 0 (
    echo [ERRO] Falha ao iniciar Docker Compose
    exit /b 1
)

echo [INFO] Aguardando banco de dados...
timeout /t 5 /nobreak >nul

echo [INFO] ✅ Docker Compose iniciado
cd ..

REM Instala dependências e inicia backend
echo [INFO] Instalando dependências do backend...
cd backend

if exist "node_modules" (
    echo [AVISO] node_modules já existe, pulando npm install
) else (
    npm install
    if %errorlevel% neq 0 (
        echo [ERRO] Falha ao instalar dependências do backend
        exit /b 1
    )
)

echo [INFO] Iniciando backend...
if not exist ".env" (
    echo POSTGRES_HOST=localhost> .env
echo POSTGRES_PORT=5432>> .env
echo POSTGRES_USER=postgres>> .env
echo POSTGRES_PASSWORD=postgres>> .env
echo POSTGRES_DB=hss_colaboradores>> .env
echo JWT_SECRET=mysecretkey123>> .env
    echo [AVISO] Arquivo .env criado com valores padrão
)

REM Inicia backend em background
start npm run dev

echo [INFO] Backend iniciado
cd ..

REM Instala dependências e inicia frontend
echo [INFO] Instalando dependências do frontend...
cd frontend

if exist ".pub-cache" (
    echo [AVISO] Dependências já instaladas, pulando flutter pub get
) else (
    flutter pub get
    if %errorlevel% neq 0 (
        echo [ERRO] Falha ao instalar dependências do frontend
        exit /b 1
    )
)

echo [INFO] Iniciando frontend...
start flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --release

echo [INFO] Frontend iniciado
cd ..

REM Aguardar e verificar
echo [INFO] Aguardando serviços iniciarem...
timeout /t 10 /nobreak >nul

REM Verifica backend
curl -s http://localhost:3000/health >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] ✅ Backend respondendo: http://localhost:3000
) else (
    echo [AVISO] Backend pode não estar totalmente pronto
)

REM Verifica frontend (tenta abrir no navegador)
start http://localhost:8080

echo [INFO] ✅ Frontend iniciado: http://localhost:8080

echo [INFO] ════════════════════════════════════
echo [INFO]    🚀 SISTEMA INICIADO COM SUCESSO!
echo [INFO] ════════════════════════════════════
echo [INFO] Backend: http://localhost:3000
echo [INFO] Frontend: http://localhost:8080
echo [INFO] Login: hss@hsslinea.com.br / hsslinea@2026
echo [INFO] ════════════════════════════════════

exit /b 0
