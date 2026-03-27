# TODO - App RH Documentos

Este arquivo foi reorganizado para servir como plano real de entrega, com foco em:

- estabilizar o fluxo principal
- reduzir bugs e retrabalho
- deixar o projeto mais confiavel para uso real
- preparar a base para producao

## Estado atual do projeto

### Ja existe hoje

- Backend Node.js com PostgreSQL
- Docker Compose para backend + banco
- Upload de arquivos com `multer`
- Substituicao de documentos com versionamento
- Listagem de colaboradores
- Dashboard com resumo
- Tela de detalhes do colaborador
- Tela de vinculos com empresas
- Cadastro basico de empresas via backend
- Tipos de documento no banco

### O que isso significa na pratica

- O projeto ja tem um MVP tecnico funcional
- O maior risco hoje nao e falta de feature, e sim inconsistencia entre fluxos
- Antes de crescer o sistema, precisamos fechar o fluxo principal sem bugs

---

## Prioridade 0 - Estabilizar o fluxo principal

Objetivo: garantir que o sistema funcione de ponta a ponta sem comportamento confuso.

### Bugs criticos para corrigir primeiro

- [ ] Corrigir o bug em que documento empresarial esta sendo salvo como documento pessoal
- [ ] Garantir que `empresa_id` chegue corretamente do frontend ao backend em todo fluxo de criacao
- [ ] Garantir que o documento empresarial apareca na empresa correta na tela de detalhes
- [ ] Validar se a substituicao de documento preserva corretamente `empresa_id`, `tipo_documento_id` e versao
- [ ] Corrigir qualquer inconsistenca entre lista exibida e dados realmente salvos no banco

### Ajustes obrigatorios no fluxo do colaborador

- [ ] Exibir empresas vinculadas de forma confiavel e sem chamadas repetidas desnecessarias
- [ ] Permitir adicionar e remover vinculos sem depender de atualizacao manual da tela
- [ ] Bloquear criacao de documento empresarial se o colaborador nao estiver vinculado a empresa
- [ ] Recarregar dados corretamente apos criar, substituir ou remover registros
- [ ] Revisar mensagens de erro para o usuario entender o que aconteceu

### Validacoes minimas obrigatorias

- [ ] Nao permitir data de validade no passado
- [ ] Validar campos obrigatorios no frontend antes de enviar
- [ ] Validar campos obrigatorios no backend antes de gravar no banco
- [ ] Validar tipos de arquivo aceitos no upload
- [ ] Definir limite de tamanho para arquivo enviado

### Entrega esperada desta fase

- [ ] Cadastrar empresa
- [ ] Vincular colaborador a empresa
- [ ] Anexar documento pessoal
- [ ] Anexar documento empresarial
- [ ] Substituir documento existente
- [ ] Ver tudo refletido corretamente no dashboard e nas listas

---

## Prioridade 1 - Completar o minimo operacional

Objetivo: sair de MVP tecnico para sistema utilizavel no dia a dia.

### Empresas

- [ ] Criar tela de listagem de empresas
- [ ] Criar tela de cadastro de empresa
- [ ] Criar edicao de empresa
- [ ] Criar exclusao de empresa com confirmacao
- [ ] Adicionar busca por nome ou CNPJ
- [ ] Impedir exclusao de empresa com dependencias sem tratamento claro

### Colaboradores

- [ ] Revisar cadastro de colaborador
- [ ] Adicionar edicao de colaborador
- [ ] Adicionar exclusao com confirmacao
- [ ] Permitir busca e filtros na lista

### Documentos

- [ ] Exibir nome do tipo de documento em vez do ID
- [ ] Exibir status visual claro: vencido, a vencer, em dia
- [ ] Permitir visualizar arquivo anexado
- [ ] Melhorar a apresentacao de documentos por empresa
- [ ] Mostrar historico de versoes do documento
- [ ] Exibir data de upload e versao atual

### Dashboard

- [ ] Corrigir overflow e responsividade em telas pequenas
- [ ] Tornar cards clicaveis com filtros reais
- [ ] Adicionar navegacao para empresas
- [ ] Revisar contadores para garantir consistencia com os dados ativos
- [ ] Melhorar feedback de carregamento e erro

### UX basica

- [ ] Substituir mensagens genericas por mensagens orientadas a acao
- [ ] Padronizar `SnackBar`, dialogs e estados vazios
- [ ] Adicionar estados de loading melhores
- [ ] Revisar textos da interface para ficarem mais claros

---

## Prioridade 2 - Confiabilidade e qualidade

Objetivo: diminuir regressao, facilitar manutencao e dar seguranca para evoluir.

### Backend

- [ ] Criar camada de validacao de entrada
- [ ] Padronizar respostas de erro da API
- [ ] Adicionar logs estruturados para erros e operacoes importantes
- [ ] Evitar repeticao de logica nas rotas
- [ ] Separar melhor rotas, servicos e configuracoes
- [ ] Tratar cenario de upload falhar apos registro no banco ou vice-versa

### Banco de dados

- [ ] Implementar Soft Delete (exclusao logica com coluna `deleted_at`) em vez de deletar registros fisicamente
- [ ] Otimizar consultas com paginacao nas listagens maiores (empresas, colaboradores, documentos)
- [ ] Revisar constraints e regras de integridade
- [ ] Garantir indices para consultas principais
- [ ] Definir estrategia de migracoes
- [ ] Revisar colunas que podem ou nao ser nulas
- [ ] Garantir consistencia entre documentos ativos e versionamento

### Frontend

- [ ] Implementar suporte a paginacao nas telas de listagem (Infinite Scroll ou Botoes de Pagina)
- [ ] Reduzir chamadas repetidas para a API
- [ ] Centralizar tratamento de erros de rede
- [ ] Revisar organizacao de models e servicos para evitar duplicidade
- [ ] Revisar fluxo de estados para evitar tela desatualizada
- [ ] Melhorar responsividade da web

### Testes

- [ ] Criar checklist manual de fluxo principal
- [ ] Testar cadastro, vinculo, upload e substituicao ponta a ponta
- [ ] Testar cenarios de erro: arquivo invalido, data invalida, vinculo ausente
- [ ] Testar responsividade em diferentes larguras
- [ ] Testar no iOS simulador e dispositivo fisico
- [ ] Adicionar testes automatizados nas partes criticas

---

## Prioridade 3 - Seguranca e preparo para producao

Objetivo: deixar o sistema apto para uso real com menos risco.

### Autenticacao e acesso

- [ ] Remover login fixo
- [x] Implementar autenticacao real com JWT ou sessao
- [x] Proteger rotas no frontend
- [x] Proteger rotas no backend
- [x] Armazenar senha com hash seguro
- [ ] Definir perfis de acesso: RH unico ou multiplos usuarios

### Seguranca da aplicacao

- [ ] Validar e sanitizar entradas
- [x] Revisar CORS para producao
- [x] Restringir upload por extensao e MIME type
- [ ] Avaliar antivirus ou varredura basica de arquivos se houver uso externo
- [ ] Esconder configuracoes sensiveis via `.env`
- [x] Revisar exposicao publica da pasta de uploads
- [x] Implementar Rate Limiting na API para evitar abusos
- [ ] Criar logs de auditoria (tabela `audit_logs` para rastrear quem criou/editou/deletou o que)

### Infraestrutura

- [ ] Separar ambiente de desenvolvimento e producao
- [ ] Configurar HTTPS
- [ ] Configurar dominio
- [ ] Publicar em servidor Linux com Docker
- [ ] Criar rotina de backup automatico do banco
- [ ] Criar estrategia de restauracao de backup
- [ ] Adicionar monitoramento e alertas

### Entrega continua

- [ ] Configurar CI para lint e testes
- [ ] Configurar deploy automatizado ou semi-automatizado
- [ ] Definir processo de versionamento e release

---

## Prioridade 4 - UI e UX

Objetivo: melhorar experiencia, usabilidade e valor para o usuario.

- [ ] Revisar contraste, acessibilidade e legibilidade
- [x] Revisar contraste, acessibilidade e legibilidade
- [x] Adicionar skeletons em telas de carregamento (Listas e Detalhes)
- [x] Suporte a arrastar e soltar (Drag and Drop) para upload de documentos na Web
- [x] Inserir graficos visuais no Dashboard (ex: grafico de rosca para status dos documentos)
- [ ] Implementar animacoes e microinteracoes ao salvar, excluir ou trocar de tela
- [ ] Melhorar navegacao entre telas
- [x] Adicionar icones por tipo de documento
- [ ] Adicionar tooltips nos pontos confusos
- [ ] Revisar layout mobile e web com mais cuidado
- [x] Criar visualizacao em formato de "Grid" (cards) alem da lista tradicional

## Prioridade 5 - Melhorias de Produto Adicionais

### Alertas e acompanhamento

- [ ] Destacar documentos vencidos na lista
- [ ] Criar filtros por status
- [ ] Criar alertas para proximidade de vencimento
- [ ] Avaliar notificacoes web e iOS
- [ ] Avaliar envio de e-mail como canal principal
- [x] Criar um CRON Job (tarefa agendada no backend) para notificar automaticamente proximidades de vencimento

### Relatorios e operacao

- [ ] Relatorio de documentos vencidos por empresa
- [ ] Relatorio de documentos a vencer por periodo
- [ ] Exportacao simples para PDF ou CSV
- [ ] Permitir download em lote (ZIP) dos documentos de um colaborador
- [ ] Cache de dados do Dashboard (Redis ou Node Cache) para nao sobrecarregar o banco

---

## Roadmap futuro

Itens bons, mas nao bloqueiam entrega inicial:

- [ ] Painel do colaborador
- [ ] QR Code para abrir colaborador rapidamente
- [ ] Modo escuro
- [ ] Permissoes mais avancadas por perfil
- [ ] Integracoes futuras com sistemas internos

---

## Ordem recomendada de execucao

### Sprint 1 - Fechar o basico sem bug

- [ ] Corrigir documento empresarial
- [ ] Revisar vinculos
- [ ] Validar upload e substituicao
- [ ] Melhorar mensagens de erro
- [ ] Testar fluxo ponta a ponta

### Sprint 2 - Operacao minima

- [ ] CRUD de empresas completo
- [ ] Melhorias na tela de colaborador
- [ ] Exibir nome do tipo de documento
- [ ] Corrigir dashboard e responsividade

### Sprint 3 - Robustez

- [ ] Validacao backend
- [ ] Logs
- [ ] Reorganizacao basica do backend
- [ ] Testes automatizados iniciais

### Sprint 4 - Producao

- [ ] Autenticacao real
- [ ] Protecao de rotas
- [ ] Deploy com HTTPS
- [ ] Backup e monitoramento

---

## Checklist de aceite antes de considerar pronto

- [ ] Consigo cadastrar empresa sem erro
- [ ] Consigo cadastrar colaborador sem erro
- [ ] Consigo vincular colaborador a empresa
- [ ] Consigo anexar documento pessoal
- [ ] Consigo anexar documento empresarial
- [ ] Consigo substituir documento mantendo historico
- [ ] Consigo visualizar arquivo anexado
- [ ] O dashboard reflete os dados corretamente
- [ ] O sistema funciona bem em web e iOS
- [ ] Erros aparecem de forma clara para o usuario
- [ ] Nao existem campos obrigatorios sem validacao
- [ ] Existe processo minimo de backup e deploy

---

## Observacoes

- Evitar adicionar features novas antes de fechar os bugs do fluxo principal
- Sempre que uma feature for concluida, validar backend + frontend + banco
- Remover `print` de depuracao antes de producao e substituir por logs apropriados
- Manter `.env` fora do versionamento
- Trabalhar com branches curtas e entregas pequenas
