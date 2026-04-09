#!/bin/bash

# =============================================================================
# START.SH - Script de inicialização automática do Sistema de Documentos HSS
# Autor: Sistema
# Descrição: Sobe backend, frontend e banco com um único comando
# =============================================================================

set -e  # Sai em caso de erro

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função de log
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERRO:${NC} $1"
    exit 1
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] AVISO:${NC} $1"
}

log_info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"
}

# =============================================================================
# 1. VERIFICAÇÃO DE PRÉ-REQUISITOS
# =============================================================================
log_info "Verificando pré-requisitos..."

# Verifica Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker não está instalado ou não está no PATH"
fi

if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose não está instalado ou não está no PATH"
fi

# Verifica Node.js
if ! command -v node &> /dev/null; then
    log_error "Node.js não está instalado"
fi

if ! command -v npm &> /dev/null; then
    log_error "npm não está instalado"
fi

# Verifica Flutter
if ! command -v flutter &> /dev/null; then
    log_error "Flutter não está instalado"
fi

log_info "✅ Todos os pré-requisitos verificados"

# =============================================================================
# 2. INICIALIZAÇÃO DO DOCKER
# =============================================================================
log_info "Iniciando Docker Compose..."

cd backend

# Verifica se containers já estão rodando
if docker-compose ps | grep -q "Up"; then
    log_warn "Containers já estão rodando!"
else
    docker-compose up -d
    log_info "✅ Docker Compose iniciado"
fi

# Aguarda o banco estar pronto
log_info "Aguardando banco de dados..."
sleep 5

# Testa conexão com o banco
if docker exec bd pg_isready -U postgres; then
    log_info "✅ Banco de dados pronto"
else
    log_warn "Banco pode não estar 100% pronto, mas continuando..."
fi

cd ..

# =============================================================================
# 3. INSTALAR DEPENDÊNCIAS DO BACKEND
# =============================================================================
log_info "Instalando dependências do backend..."

cd backend

if [ -d "node_modules" ]; then
    log_warn "node_modules já existe, pulando install"
else
    npm install
    log_info "✅ Dependências do backend instaladas"
fi

cd ..

# =============================================================================
# 4. INSTALAR DEPENDÊNCIAS DO FRONTEND
# =============================================================================
log_info "Instalando dependências do frontend..."

cd frontend

if [ -d ".pub-cache" ]; then
    log_warn "Dependências já instaladas, pulando"
else
    flutter pub get
    log_info "✅ Dependências do frontend instaladas"
fi

cd ..

# =============================================================================
# 5. INICIALIZAR BACKEND (em background)
# =============================================================================
log_info "Iniciando backend..."

cd backend

# Cria arquivo de ambiente padrão se não existir
if [ ! -f ".env" ]; then
    cat > .env << EOF
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=hss_colaboradores
JWT_SECRET=mysecretkey123
EOF
    log_warn "Arquivo .env criado com valores padrão!"
fi

# Inicia o servidor em background
nohup npm run dev > server.log 2>&1 &
BACKEND_PID=$!
log_info "✅ Backend iniciado (PID: $BACKEND_PID)"

# Aguarda backend iniciar
log_info "Aguardando backend responder..."
sleep 3

# Testa se backend está respondendo
if curl -s http://localhost:3000/health > /dev/null; then
    log_info "✅ Backend respondendo"
else
    log_warn "Backend pode não estar 100% pronto, mas continuando..."
fi

cd ..

# =============================================================================
# 6. INICIALIZAR FRONTEND (em background)
# =============================================================================
log_info "Iniciando frontend..."

cd frontend

# Inicia Flutter em background
nohup flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 > flutter.log 2>&1 &
FRONTEND_PID=$!
log_info "✅ Frontend iniciado (PID: $FRONTEND_PID)"

cd ..

# =============================================================================
# 7. VERIFICAÇÃO FINAL
# =============================================================================
log_info "Verificando se tudo está funcionando..."
sleep 5

# Verifica backend
if curl -s http://localhost:3000/health | grep -q "OK"; then
    log_info "✅ Backend: http://localhost:3000"
else
    log_error "Backend não respondeu corretamente"
fi

# Verifica frontend
if curl -s http://localhost:8080 | grep -q "login"; then
    log_info "✅ Frontend: http://localhost:8080"
else
    log_warn "Frontend pode não estar totalmente carregado"
fi

# =============================================================================
# 8. INFORMAÇÕES DE ACESSO
# =============================================================================
echo ""
log_info "═══════════════════════════════════════"
log_info "   🚀 APP INICIADO COM SUCESSO!"
log_info "═══════════════════════════════════════"
echo ""
echo -e "${GREEN}Backend:${NC} http://localhost:3000"
echo -e "${GREEN}Frontend:${NC} http://localhost:8080"
echo ""
echo -e "${YELLOW}Login de teste:${NC}"
echo "  Email: rh@empresa.com"
echo "  Senha: 123456"
echo ""
echo -e "${BLUE}Logs:${NC}"
echo "  Backend: backend/server.log"
echo "  Frontend: frontend/flutter.log"
echo ""
echo -e "${YELLOW}Dica:${NC} Para parar tudo, execute: kill $BACKEND_PID $FRONTEND_PID"
echo ""

# =============================================================================
# 9. OPCIONAL: ABRIR NAVEGADORES
# =============================================================================
if command -v xdg-open &> /dev/null; then
    xdg-open http://localhost:8080 &
fi

log_info "✅ Sistema totalmente inicializado!"
exit 0
