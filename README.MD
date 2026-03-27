# Colaboradores-HSS (Release 1.0 de Testes)

Sistema de gestao de documentos para RH com colaboradores, empresas, vinculos e controle de documentos pessoais/empresariais.

## Stack

- Frontend: Flutter (Web e iOS)
- Backend: Node.js + Express
- Banco: PostgreSQL
- Infra local: Docker Compose

## Funcionalidades 1.0

- Login real com JWT (`/auth/login`)
- Sessao persistida no app Flutter
- CRUD de colaboradores
- CRUD de empresas
- Vinculo colaborador x empresa
- Upload de anexos com validacao de tipo/tamanho
- Documento pessoal e empresarial com validacao de regra
- Substituicao com historico de versoes
- Dashboard com indicadores de vencimento

## Como rodar localmente

1. Crie o arquivo `.env` usando o `.env.example`
2. Suba os servicos:
   `docker-compose up -d --build`
3. API backend:
   `http://localhost:3000`
4. Frontend Flutter:
   execute dentro de `frontend/` com `flutter run -d chrome` ou dispositivo iOS

## Usuario inicial

Na primeira subida, o backend cria automaticamente um usuario RH se nao houver nenhum na tabela `usuarios_rh`.

- E-mail padrao: `rh@empresa.com`
- Senha inicial: valor definido em `RH_DEFAULT_PASSWORD`

Esses valores podem ser alterados via variaveis:

- `RH_DEFAULT_NOME`
- `RH_DEFAULT_EMAIL`
- `RH_DEFAULT_PASSWORD`

## Variaveis importantes

- `DB_USER`
- `DB_PASS`
- `DB_NAME`
- `DB_HOST`
- `PORT`
- `JWT_SECRET`
- `JWT_EXPIRES_IN`
- `FILE_LINK_EXPIRES_IN`
- `CORS_ORIGIN`
- `API_RATE_LIMIT_WINDOW_MS`
- `API_RATE_LIMIT_MAX`
- `AUTH_RATE_LIMIT_MAX`
- `CRON_NOTIFY_SCHEDULE`
- `NOTIFY_DAYS_AHEAD`
- `NOTIFY_RUN_ON_START`

## Estrutura principal

- `backend/`: API e regras de negocio
- `frontend/`: app Flutter
- `database/`: bootstrap SQL
- `uploads/`: arquivos enviados
- `RELEASE_1_0_CHECKLIST.md`: validacao final da release
