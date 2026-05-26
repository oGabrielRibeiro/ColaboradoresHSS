# 🧪 TESTE DO FLUXO COMPLETO - Ambiente Local

## 📋 Checklist de Teste Manual

### **Pré-requisitos**
1. Backend rodando: `docker-compose up -d`
2. Frontend rodando: `flutter run -d chrome --web-hostname 0.0.0.0 --web-port 8080`
3. Banco conectado e migration aplicada
4. Usuário logado (pode usar os dados de teste: `rh@empresa.com` / `123456`)

---

## **🎯 Cenários de Teste**

### **1. Criar Empresa ✅ (Testa CRUD Empresas)**

**Passos:**
1. Dashboard → Menu "Empresas"
2. Clique em "➕" (FAB)
3. Digite: `Empresa Teste`
4. Clique em "Criar"

**Resultado Esperado:**
- Empresa aparece na lista
- API retorna status 201
- No banco: `SELECT * FROM empresas WHERE nome = 'Empresa Teste';` → deve retornar 1 linha

---

### **2. Criar Colaborador ✅ (Testa CRUD Colaboradores)**

**Passos:**
1. Dashboard → Menu "Colaboradores"
2. Clique em "➕ Novo Colaborador" (Testes)
3. Preencha:
   - Nome: `João Teste`
   - CPF: `123.456.789-00`
   - Cargo: `Analista`
4. Clique em "Salvar"

**Resultado Esperado:**
- Colaborador aparece na lista
- API retorna status 201
- No banco: `SELECT * FROM colaboradores WHERE nome = 'João Teste';` → deve retornar 1 linha

---

### **3. Criar Vínculo ✅ (Testa Relação Empresa-Colaborador)**

**Passos:**
1. No detalhes do colaborador, clique em "Gerenciar Vínculos"
2. Selecione "Empresa Teste"
3. Clique em "Vincular"

**Resultado Esperado:**
- Vínculo criado com sucesso
- ListView de vínculos mostra "Empresa Teste"
- No banco: `SELECT * FROM vinculos WHERE colaborador_id = X AND empresa_id = Y;` → deve retornar 1 linha

---

### **4. Criar Documento Pessoal ✅ (Testa Documentos Pessoais)**

**Passos:**
1. Detalhes do Colaborador → Botão "➕ Upload File"
2. Preencher:
   - Tipo: "RG" (tipo pessoal)
   - Data de validade: **amanhã**
   - Arquivo: RG.pdf
3. Clique em "CRIAR DOCUMENTO"

**Resultado Esperado:**
- Documento criado com sucesso
- Documento aparece na lista
- No banco: `SELECT * FROM documentos WHERE tipo_documento_id = TIPO_PESSOAL AND empresa_id IS NULL;`

---

### **5. Criar Documento Empresarial ✅ (Testa Documentos Empresariais + Vínculo)**

**Passos:**
1. Detalhes do Colaborador → Botão "➕ Upload File"
2. Preencher:
   - Tipo: "Contrato de Trabalho" (tipo empresa)
   - Empresa: "Empresa Teste" (dropdown deve aparecer)
   - Data de validade: 01/01/2025
   - Arquivo: contrato.pdf
3. Clique em "CRIAR DOCUMENTO"

**Resultado Esperado:**
- Documento criado com sucesso
- No banco: `SELECT * FROM documentos WHERE empresa_id IS NOT NULL;`
- Empresa_id **DEVE** estar preenchido

---

### **6. Substituir Documento ✅ (Testa Versionamento)**

**Passos:**
1. Na lista de documentos, clique em "Substituir (v1)" em um documento existente
2. Selecionar nova data (ex: 01/02/2025)
3. Selecionar novo arquivo (ex: contrato_novo.pdf)
4. Clique em "Substituir"

**Resultado Esperado:**
- Novo documento criado com **versão 2**
- Documento antigo marcado como `ativo = false`
- No banco: `SELECT * FROM documentos WHERE ativo = true` → mostra apenas versão 2

**SQL para verificar:**
```sql
SELECT d.id, d.versao, d.ativo, d.substituido_por_id, e.nome AS tipo
FROM documentos d
LEFT JOIN tipos_documento e ON e.id = d.tipo_documento_id
WHERE d.colaborador_id = SEU_COLABORADOR_ID
ORDER BY d.versao DESC;
```

---

### **7. Visualizar Documento ✅ (Testa Download)**

**Passos:**
1. Clique em "Abrir anexo" em qualquer documento

**Resultado Esperado:**
- Arquivo abre em nova aba/download

---

### **8. Verificar Consistência no Banco ✅**

Execute as queries do arquivo `VERIFICAR_BANCO.sql`:

```sql
-- 1. Nenhum documento pessoal com empresa_id
SELECT * FROM documentos WHERE tipo_documento_id IN (SELECT id FROM tipos_documento WHERE tipo = 'pessoal') AND empresa_id IS NOT NULL;
-- Resultado deve ser: 0 linhas

-- 2. Nenhum documento empresarial sem empresa_id
SELECT * FROM documentos WHERE tipo_documento_id IN (SELECT id FROM tipos_documento WHERE tipo = 'empresa') AND empresa_id IS NULL;
-- Resultado deve ser: 0 linhas

-- 3. Contagem por categoria
SELECT td.tipo, COUNT(*) FROM documentos d JOIN tipos_documento td ON td.id = d.tipo_documento_id WHERE d.deleted_at IS NULL GROUP BY td.tipo;
-- Deve mostrar contagem correta de pessoais e empresariais
```

---

## **✅ RESUMO DO FLUXO**

Se todos os passos acima funcionaram, o **fluxo completo está funcional** para uso básico local:

1. ✅ Empresas → criar/listar
2. ✅ Colaboradores → criar/listar/vincular
3. ✅ Documentos → criar (pessoal/empresarial) → substituir → visualizar
4. ✅ Segurança → rotas protegidas por JWT
5. ✅ Consistência → dados no banco corretos

**QUALQUER BUG ENCONTRADO**: Execute queries de `VERIFICAR_BANCO.sql` e salve resultados.

---

## **📊 Teste de Performance (Opcional)**

Para garantir que funciona com "poucas pessoas" (ex: 5 usuários simultâneos):

```bash
# Teste de carga simples (use curl ou artillery)
for i in {1..5}; do \n  curl -X POST http://localhost:3000/documentos \
    -H "Authorization: Bearer SEU_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{\"colaborador_id\":1,\"tipo_documento_id\":1,\"data_validade\":\"2024-12-31\",\"arquivo_nome\":\"teste.pdf\",\"arquivo_path\":\"/uploads/teste.pdf\"}' &\ndone
```

**Resultado**: Todas requisições devem retornar 201 e aparecer no banco.

---

## **🐛 Se encontrar problemas**

1. **Auth falha**: Verifique `jwtSecret` no backend/.env
2. **Documento não cria**: Verifique console do backend para erros
3. **Empresa não aparece**: Verifique se `getEmpresas` retorna dados
4. **Substituir não funciona**: Debug função `_substituirDocumento`

---

## **✅ Pronto para Uso**

Se todos os testes passaram, o sistema está **funcional para uso local por poucas pessoas**.

Próximos passos (melhorias *não críticas*):
- [ ] Adicionar máscaras (CNPJ, CPF)
- [ ] Adicionar validação de emails
- [ ] Implementar delete lógico
- [ ] Adicionar logs estruturados
- [ ] Criar testes automatizados

---

**Quer que eu execute algum desses testes agora ou gere prints dos resultados?**