# Release 1.0 - Checklist de Validacao

## 1. Preparacao

- [x] `.env` criado com base no `.env.example`
- [x] `docker-compose up -d --build` executado sem falhas
- [x] Backend respondendo em `GET /health`

## 2. Autenticacao

- [x] Login com usuario valido retorna token
- [x] Login com senha invalida bloqueia acesso
- [x] Sessao persiste apos recarregar o app
- [x] Logout remove sessao e volta para tela de login

## 3. Fluxo principal

- [x] Cadastrar empresa
- [x] Cadastrar colaborador
- [x] Vincular colaborador a empresa
- [x] Upload de documento pessoal
- [x] Upload de documento empresarial (somente com vinculo)
- [x] Substituir documento e validar versao
- [x] Visualizar historico de versoes
- [x] Abrir anexo salvo

## 4. Dashboard

- [x] Cards de colaboradores e empresas corretos
- [x] Card de vencidos reflete dados ativos
- [x] Navegacao para listas de status funcionando

## 5. Regras e validacoes

- [x] Data de validade passada e bloqueada
- [x] Tipo de documento empresarial sem empresa e bloqueado
- [x] Tipo de arquivo invalido e bloqueado no upload
- [x] Erros de API retornam mensagens legiveis

## 6. Qualidade tecnica

- [x] `flutter analyze` sem issues de codigo
- [x] Backend inicia sem erro com `node server.js`
- [x] Sem credenciais sensiveis hardcoded em codigo
