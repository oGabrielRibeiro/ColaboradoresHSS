# Colaboradores-HSS

Sistema de gestão de documentos para RH, com foco em colaboradores e empresas prestadoras de serviço.

## Tecnologias

- **Frontend**: Flutter (Web e iOS)
- **Backend**: Node.js + Express
- **Banco de Dados**: PostgreSQL
- **Container**: Docker / Docker Compose

## Como rodar localmente

1. Clone o repositório
2. Crie um arquivo `.env` baseado no `.env.example`
3. Execute `docker-compose up -d`
4. Acesse a API em `http://localhost:3000`
5. O banco de dados estará disponível na porta 5432

## Estrutura

- `backend/`: código do servidor Node.js
- `database/`: scripts SQL iniciais
- `uploads/`: pasta para arquivos enviados (criada automaticamente)

## Próximos passos

- Desenvolvimento do frontend Flutter
- Implementação de CRUD completo
- Sistema de notificações