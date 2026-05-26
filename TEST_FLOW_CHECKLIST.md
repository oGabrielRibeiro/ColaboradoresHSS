# Checklist de Teste de Fluxo

## Preparacao

- [ ] `docker-compose up -d --build` executado com sucesso
- [ ] API responde `GET /health`
- [ ] Frontend abre sem erro no navegador

## Autenticacao

- [ ] Login com credenciais validas funciona
- [ ] Login com credenciais invalidas retorna erro amigavel
- [ ] Logout encerra sessao e redireciona para login

## Cadastros Basicos

- [ ] Criar empresa
- [ ] Editar empresa
- [ ] Excluir empresa sem dependencia
- [ ] Criar colaborador
- [ ] Editar colaborador
- [ ] Excluir colaborador sem dependencia

## Vinculos

- [ ] Vincular colaborador a empresa
- [ ] Remover vinculo
- [ ] Impedir vinculo duplicado

## Documentos

- [ ] Upload de documento pessoal
- [ ] Upload de documento empresarial com vinculo
- [ ] Bloqueio de documento empresarial sem vinculo
- [ ] Substituir documento (nova versao)
- [ ] Abrir anexo via link assinado
- [ ] Visualizar historico do documento

## Dashboard e Relatorios

- [ ] Dashboard carrega indicadores corretamente
- [ ] `GET /relatorios/documentos-vencidos-por-empresa` retorna dados
- [ ] `GET /relatorios/documentos-a-vencer-periodo` retorna dados

## Auditoria

- [ ] Criar empresa gera registro em `/audit-logs`
- [ ] Editar colaborador gera registro em `/audit-logs`
- [ ] Excluir documento gera registro em `/audit-logs`
