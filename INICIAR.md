# 🚀 INICIAR O SISTEMA DE DOCUMENTOS HSS (Windows)

## **MODO RÁPIDO - INICIAR COM UM COMANDO (Windows)**

### **Pré-requisitos** - ✅ Docker instalado e rodando - ✅ Node.js v18+ instalado - ✅ Flutter v3.16+ instalado - ✅ Git instalado

---

## **🔥 Iniciar Tudo (Backend + Frontend + Banco)**

Execute o script `start.bat` (para Windows):

```powershell cd C:\Cliente\HSS\ColaboradoresHSS start.bat ``` **Este script fará TUDO AUTOMATICAMENTE:** 1. Sobe o banco de dados (PostgreSQL) via Docker 2. Instala dependências do backend (npm) 3. Instala dependências do frontend (flutter) 4. Cria arquivo `.env` (se não existir) 5. ✅ Inicia **backend** em background (porta 3000) 6. ✅ Inicia **frontend** em background (porta 8080) 7. ✅ Abre automaticamente o navegador na página de login

---

## **⏱️ Tempo estimado: 2-3 minutos (primeira vez)**

---

## **📊 O que acontece durante a inicialização**

| Passo | Ação | Tempo estimado | |---|---|---| | 1 | Docker Compose iniciar | 30s | | 2 | npm install backend | 45s | | 3 | flutter pub get | 30s | | 4 | Iniciar backend | 5s | | 5 | Iniciar frontend | 10s |

---

## **📋 Checklist de Funcionamento**

Após o script finalizar, verifique se tudo está rodando:

### **Backend** ```powershell curl -s http://localhost:3000/health
# Esperado: {"status":"OK"} ```

### **Frontend**
Abra no navegador: http://localhost:8080

**Esperado:** Página de login visível

### **Banco de Dados**
```powershell docker exec -t bd psql -U postgres -c "\l"
# Esperado: Banco `hss_colaboradores` existe
```

---

## **🔑 Login Padrão (Atualizado)**
- **Email:** `hss@hsslinea.com.br`
- **Senha:** `hsslinea@2026`

---

## **🐛 Problemas Comuns**

| Problema | Solução | |---|---| | **"Porta 3000 ocupada"** | Edite `.env` e mude `PORT=3001` | | **"Porta 8080 ocupada"** | Feche aplicativos usando a porta (ex: Skype) | | **"Banco não conecta"** | Rode `docker-compose restart` | | **"Dependências faltando"** | Rode `npm install` ou `flutter pub get` novamente | | **"Flutter não inicia"** | Rode `flutter clean` e depois `flutter pub get` | | **"Login falha"** | Verifique seed no banco: `SELECT email FROM usuarios WHERE email='hss@hsslinea.com.br';` |

---

## **🎬 Como Rodar Passo a Passo (Sem Script)**

Se preferir controlar cada etapa:

### **1. Banco de Dados**
```powershell cd backend docker-compose up -d
```

### **2. Backend**
```powershell cd backend npm install (apenas primeira vez) npm run dev
```

### **3. Frontend**
```powershell cd frontend flutter pub get (apenas primeira vez) flutter run -d chrome --web-hostname 0.0.0.0 --web-port 8080
```

---

## **📚 Documentação Adicional** - **Testes Manuais:** `TESTE_FLUXO_COMPLETO.md` - **Queries SQL:** `VERIFICAR_BANCO.sql` - **Testes Automatizados:** `__tests__/` - **Seeds de Dados:** `backend/seeds/`

---

## **✅ Pronto para Produção Local!**

Se tudo está rodando, o sistema está **funcional para uso local por poucas pessoas**.

**Próximos passos:** 1. Siga `TESTE_FLUXO_COMPLETO.md` para validar 2. Crie empresas e colaboradores 3. Teste criação de documentos 4. Valide rotas via Postman/API

---

**Dúvidas?** Execute `start.bat` e verifique os logs:
- `backend/server.log`
- `frontend/flutter.log`