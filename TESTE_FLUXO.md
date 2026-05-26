# 📋 Guião de Testes - Fluxo completo de Documentos

## 🎯 **Objetivo**
Testar manualmente todo o fluxo de criação e gestão de documentos após as correções implementadas.

## 📱 **Pré-requisitos**
1. Backend rodando: `docker-compose up -d`
2. Frontend rodando: `flutter run` (web ou iOS)
3. Banco PostgreSQL acessível
4. Usuário logado no sistema

---

## 🧪 **Cenários de Teste**

### **Teste 1: Documento Pessoal (SUCESSO ESPERADO)**

**Passos:**
1. Navegue até Dashboard → Colaboradores
2. Selecione um colaborador (ex: João Silva)
3. Clique no botão ➕ (Upload) no topo da tela
4. Selecione tipo: "RG" (ou outro **pessoal**)
5. **Verifique**: Campo "Empresa" **NÃO** aparece
6. Selecione data de validade: **amanhã**
7. Clique em "Selecionar arquivo" e escolha: `documento_teste.pdf` (ou JPG/PNG)
8. Clique em **CRIAR DOCUMENTO**

**Resultado esperado:**
✅ Documento criado com sucesso
✅ No banco: `empresa_id = null`
✅ Documento aparece na lista do colaborador

**SQL de verificação:**
```sql
SELECT d.id, d.tipo_documento_id, d.empresa_id, d.arquivo_nome, d.versao
FROM documentos d
WHERE d.colaborador_id = 1 -- ID do colaborador testado
ORDER BY d.created_at DESC
LIMIT 1;
```
**Resultado deve ter `empresa_id = null`**

---

### **Teste 2: Documento Empresarial sem Vínculo (ERRO ESPERADO)**

**Passos:**
1. Navegue até Dashboard → Colaboradores
2. Selecione colaborador **SEM vínculos** cadastrados
3. Clique ➕ para adicionar documento
4. Selecione tipo: "Contrato de Trabalho" (empresarial)
5. **Verifique**: Campo "Empresa" aparece como **dropdown vazio**
6. Tente selecionar arquivo e data qualquer
7. Clique criar

**Resultado esperado:**
❌ Backend retorna erro HTTP 400
❌ Mensagem: "Documentos empresariais requerem empresa vinculada"
**Documento NÃO é salvo no banco**

---

### **Teste 3: Documento Empresarial com Vínculo (SUCESSO)**

**Pré-requisito:** Colaborador deve estar vinculado a pelo menos uma empresa

**Passos:**
1. No backend, crie vínculo manualmente se preciso:
```sql
INSERT INTO vinculos (colaborador_id, empresa_id, ativo, created_at)
VALUES (1, 1, true, NOW());
```
2. No Flutter: Dashboard → Colaboradores → Selecione colaborador vinculado
3. Clique ➕ para adicionar documento
4. Selecione tipo: "Contrato de Trabalho" (empresarial)
5. **Verifique**: Campo "Empresa" aparece com dropdown das empresas vinculadas
6. Selecione uma empresa do dropdown
7. Selecione data: futura
8. Selecione arquivo: `contrato.pdf`
9. Clique em **CRIAR DOCUMENTO**

**Resultado esperado:**
✅ Criação bem-sucedida
✅ No banco: `empresa_id = [ID da empresa selecionada]`
✅ Documento aparece na tela de detalhes do colaborador
✅ Documento aparece na tela de detalhes da empresa

**SQL de verificação:**
```sql
SELECT d.id, d.tipo_documento_id, d.empresa_id, d.arquivo_nome, d.versao, e.nome as empresa_nome
FROM documentos d
LEFT JOIN empresas e ON e.id = d.empresa_id
WHERE d.colaborador_id = 1
ORDER BY d.created_at DESC
LIMIT 1;
```
**Resultado deve ter `empresa_id` igual ao ID selecionado**

---

### **Teste 4: Validações de Arquivo**

**a) Tamanho excedido (ERRO)**
1. Crie arquivo > 10MB: `dd if=/dev/zero of=teste_grande.pdf bs=1M count=11` (Linux/Mac)
2. Tente fazer upload
3. **Resultado**: Erro imediato no frontend - "Arquivo excede o tamanho máximo de 10 MB"

**b) Tipo inválido (ERRO)**
1. Crie arquivo .exe ou .zip
2. Tente fazer upload
3. **Resultado**: Erro - "Tipo de arquivo não permitido"

**c) Tipo válido (SUCESSO)**
1. Faça upload com PDF, JPG, DOCX, XLSX
2. **Resultado**: Aceita arquivo

---

### **Teste 5: Validação de Data**

**a) Data passada (ERRO)**
1. No DatePicker, tente selecionar data **antes de hoje**
2. **Resultado**: DatePicker **bloqueia**, não deixa selecionar

**b) Data hoje (SUCESSO)**
1. Selecione data de **hoje**
2. **Resultado**: Aceita e salva

**c) Data futura (SUCESSO)**
1. Selecione data de **amanhã** ou posterior
2. **Resultado**: Aceita e salva

---

### **Teste 6: Consistência da Lista**

**Passos:**
1. Crie 3 documentos:
   - 1 pessoal (ex: RG)
   - 1 empresarial válido (ex: Contrato)
   - 1 pessoal (ex: CPF)
2. Navegue até: Dashboard → Colaborador → Detalhes
3. Verifique lista de documentos
4. Execute query direta no banco:
```sql
SELECT id, arquivo_nome, tipo_documento_id, empresa_id
FROM documentos
WHERE colaborador_id = 1 AND deleted_at IS NULL
ORDER BY created_at DESC;
```

**Resultado esperado:**
✅ Lista no Flutter **mostra exatamente** os mesmos 3 documentos da query
✅ Documentos pessoais aparecem sem empresa
✅ Documento empresarial aparece com empresa correta
✅ Nenhum documento está "perdido" ou sumido

---

## 🗄️ **Queries de Verificação no Banco**

### **Verificar documentos de um colaborador:**
```sql
SELECT d.id, d.versao, d.arquivo_nome, d.data_validade,
       td.nome as tipo, td.tipo as categoria,
       d.empresa_id, e.nome as empresa_nome,
       d.created_at, d.deleted_at
FROM documentos d
LEFT JOIN tipos_documento td ON td.id = d.tipo_documento_id
LEFT JOIN empresas e ON e.id = d.empresa_id
WHERE d.colaborador_id = 1 -- Altere o ID
  AND d.deleted_at IS NULL
ORDER BY d.created_at DESC;
```

### **Verificar se documentos pessoais têm empresa_id null:**
```sql
SELECT id, arquivo_nome, tipo_documento_id
FROM documentos
WHERE colaborador_id = 1
  AND empresa_id IS NOT NULL
  AND tipo_documento_id IN (SELECT id FROM tipos_documento WHERE tipo = 'pessoal');
```
**Resultado deve ser VAZIO (0 linhas)**

### **Verificar se documentos empresariais têm empresa_id:**
```sql
SELECT id, arquivo_nome, empresa_id
FROM documentos
WHERE colaborador_id = 1
  AND empresa_id IS NULL
  AND tipo_documento_id IN (SELECT id FROM tipos_documento WHERE tipo = 'empresa');
```
**Resultado deve ser VAZIO (0 linhas)**

---

## 📋 **Checklist de Sucesso**

- [ ] Teste 1: Documento pessoal criado com `empresa_id = null`
- [ ] Teste 2: Documento empresarial sem vínculo retorna erro
- [ ] Teste 3: Documento empresarial com vínculo salva `empresa_id` correto
- [ ] Teste 4a: Upload >10MB é bloqueado
- [ ] Teste 4b: Upload .exe/.zip é bloqueado
- [ ] Teste 4c: Upload PDF/JPG/DOCX é aceito
- [ ] Teste 5a: Data passada é bloqueada pelo DatePicker
- [ ] Teste 5b: Data hoje é aceita
- [ ] Teste 5c: Data futura é aceita
- [ ] Teste 6: Lista no app == Query no banco
- [ ] O botão ➕ abre a tela de criação
- [ ] Tela de criação é funcional e salva no banco
- [ ] Documentos aparecem na lista após criação

---

## 🚀 **Próximo Passo**
Se todos os testes passarem, o **fluxo principal está estável** e pronto para próxima fase:
- [ ] Testes automatizados (backend e frontend)
- [ ] Implementar soft delete no lugar de delete físico
- [ ] Adicionar logs estruturados
- [ ] Configurar CI/CD
- [ ] Deploy em ambiente de produção

**Status atual**: ✅ **CORREÇÕES CRÍTICAS CONCLUÍDAS** - Teste manual pendente