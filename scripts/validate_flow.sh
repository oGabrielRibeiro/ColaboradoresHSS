#!/usr/bin/env bash
set -euo pipefail

API_BASE_URL="${API_BASE_URL:-http://localhost:3000}"
EMAIL="${RH_EMAIL:-rh@empresa.com}"
PASSWORD="${RH_PASSWORD:-123456}"

echo "[1/6] Health check..."
curl -fsS "${API_BASE_URL}/health" >/dev/null
echo "  OK"

echo "[2/6] Login..."
LOGIN_RESPONSE="$(curl -fsS -X POST "${API_BASE_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${EMAIL}\",\"senha\":\"${PASSWORD}\"}")"
TOKEN="$(echo "${LOGIN_RESPONSE}" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')"

if [[ -z "${TOKEN}" ]]; then
  echo "Falha ao extrair token do login."
  exit 1
fi
echo "  OK"

AUTH_HEADER="Authorization: Bearer ${TOKEN}"

echo "[3/6] Sessao /auth/me..."
curl -fsS "${API_BASE_URL}/auth/me" -H "${AUTH_HEADER}" >/dev/null
echo "  OK"

echo "[4/6] Dashboard..."
curl -fsS "${API_BASE_URL}/dashboard/resumo" -H "${AUTH_HEADER}" >/dev/null
echo "  OK"

echo "[5/6] Relatorio vencidos por empresa..."
curl -fsS "${API_BASE_URL}/relatorios/documentos-vencidos-por-empresa" \
  -H "${AUTH_HEADER}" >/dev/null
echo "  OK"

echo "[6/6] Relatorio a vencer por periodo..."
curl -fsS "${API_BASE_URL}/relatorios/documentos-a-vencer-periodo?dias=30" \
  -H "${AUTH_HEADER}" >/dev/null
echo "  OK"

echo "Validacao basica concluida com sucesso."
