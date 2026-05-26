-- Seed para criar/atualizar usuário administrador padrão
-- Executar: psql -U postgres -h localhost -d hss_colaboradores -f seeds/001-usuario-padrao.sql

INSERT INTO usuarios (email, senha, nome, nivel_acesso, ativo, created_at)
VALUES (
  'hss@hsslinea.com.br',
  crypt('hsslinea@2026', gen_salt('bf')),
  'Administrador',
  'admin',
  true,
  NOW()
)
ON CONFLICT (email) DO UPDATE SET
  senha = crypt('hsslinea@2026', gen_salt('bf')),
  nome = 'Administrador',
  ativo = true,
  updated_at = NOW();

-- Mensagem de confirmação
DO $$
BEGIN
  RAISE NOTICE '✅ Usuário padrão atualizado com sucesso:';
  RAISE NOTICE 'Email: hss@hsslinea.com.br';
  RAISE NOTICE 'Senha: hsslinea@2026';
END$$;
