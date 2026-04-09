# 🚀 INICIAR O SISTEMA DE DOCUMENTOS HSS

## **MODO RÁPIDO - INICIAR COM UM COMANDO**

### **Pré-requisitos**
- ✅ Docker instalado e rodando
- ✅ Node.js v18+ instalado
- ✅ Flutter v3.16+ instalado
- ✅ Git instalado

---

## **🔥 Iniciar Tudo (Backend + Frontend + Banco)**

Execute o script `start.sh`:

```bash
cd C:\\Cliente\\HSS\\ColaboradoresHSS
bash start.sh
```

Este script fará **TUDO AUTOMATICAMENTE**:
1. Sobe o banco de dados (PostgreSQL) via Docker
2. Instala dependências do backend
3. Instala dependências do frontend
4. Inicia o backend (porta 3000)
5. Inicia o frontend (porta 8080)

---

## **⏱️ Tempo estimado: 2-3 minutos (primeira vez)**

---

## **📊 O que acontece durante a inicialização**

| Passo | Ação | Tempo estimado |
|---|---|---|
| 1 | Docker Compose iniciar | 30s |
| 2 | npm install backend | 45s |
| 3 | flutter pub get | 30s |
| 4 | Iniciar backend | 5s |
| 5 | Iniciar frontend | 10s |

---

## **📋 Checklist de Funcionamento**

Após o script finalizar, verifique se tudo está rodando:

### **Backend**
```bash
curl http://localhost:3000/health
```
**Esperado:** `{"status":"OK"}`

### **Frontend**
Abra no navegador: http://localhost:8080

**Esperado:** Página de login visível

### **Banco de Dados**
```bash
docker exec -t bd psql -U postgres -c "\l"
```
**Esperado:** Banco `hss_colaboradores` existe

---

## **🔑 Login de Teste (Primeiro Acesso)**
- **Email:** `rh@empresa.com`
- **Senha:** `123456`

---

## **🐛 Se encontrar problemas**

| Problema | Solução |
|---|---|
| "Porta 3000 ocupada" | Edite `.env` e mude `PORT=3001` |
| "Porta 8080 ocupada" | Edite `flutter.log` e procure erro |
| "Banco não conecta" | Rode `docker-compose restart` |
| "Dependências faltando" | Rode `npm install` novamente |

---

## **📚 Documentação Adicional**
- **Testes Manuais:** `TESTE_FLUXO_COMPLETO.md`
- **Queries SQL:** `VERIFICAR_BANCO.sql`
- **Testes Automatizados:** `__tests__/`

---

**Pronto para produção!** 🎉

Quer que eu **execute o `start.sh` agora** e mostre o output em tempo real?