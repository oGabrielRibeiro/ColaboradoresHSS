-- ================================================
-- VERIFICAÇÕES CRÍTICAS DO BANCO
-- ================================================

-- 1. VERIFICAR DOCUMENTOS PESSOAIS COM EMPRESA (ERRO)
-- Resultado deve ser: 0 linhas
-- Se retornar linhas, o bug ainda existe
SELECT
 d.id,
 d.arquivo_nome,
 td.nome as tipo_documento,
 td.tipo as categoria,
 d.empresa_id,
 c.nome as colaborador
FROM documentos d
INNER JOIN tipos_documento td ON td.id = d.tipo_documento_id
INNER JOIN colaboradores c ON c.id = d.colaborador_id
WHERE d.deleted_at IS NULL
 AND td.tipo = 'pessoal'
 AND d.empresa_id IS NOT NULL;

-- 2. VERIFICAR DOCUMENTOS EMPRESARIAIS SEM EMPRESA (ERRO)
-- Resultado deve ser: 0 linhas
SELECT
 d.id,
 d.arquivo_nome,
 td.nome as tipo_documento,
 td.tipo as categoria,
 d.empresa_id,
 c.nome as colaborador
FROM documentos d
INNER JOIN tipos_documento td ON td.id = d.tipo_documento_id
INNER JOIN colaboradores c ON c.id = d.colaborador_id
WHERE d.deleted_at IS NULL
 AND td.tipo = 'empresa'
 AND d.empresa_id IS NULL;

-- 3. VERIFICAR TODOS OS DOCUMENTOS COM SEUS TIPOS
-- Mostra todos os documentos e suas categorias
SELECT
 d.id,
 d.versao,
 d.arquivo_nome,
 DATE(d.data_validade) as validade,
 td.nome as tipo,
 td.tipo as categoria,
 d.empresa_id,
 e.nome as empresa_nome,
 c.nome as colaborador,
 d.created_at
FROM documentos d
LEFT JOIN tipos_documento td ON td.id = d.tipo_documento_id
LEFT JOIN empresas e ON e.id = d.empresa_id
INNER JOIN colaboradores c ON c.id = d.colaborador_id
WHERE d.deleted_at IS NULL
ORDER BY d.created_at DESC;

-- 4. VERIFICAR DADOS DE UM COLABORADOR ESPECÍFICO
-- Substitua o ID (1) pelo colaborador que deseja testar
SELECT
 d.id,
 d.versao,
 d.arquivo_nome,
 DATE(d.data_validade) as validade,
 td.nome as tipo,
 td.tipo as categoria,
 d.empresa_id,
 e.nome as empresa_nome,
 d.created_at
FROM documentos d
LEFT JOIN tipos_documento td ON td.id = d.tipo_documento_id
LEFT JOIN empresas e ON e.id = d.empresa_id
WHERE d.colaborador_id = 1 -- ALTERE AQUI
 AND d.deleted_at IS NULL
ORDER BY d.created_at DESC;

-- 5. VERIFICAR TOTAIS POR CATEGORIA
SELECT
 td.tipo as categoria,
 COUNT(*) as total_documentos,
 COUNT(CASE WHEN d.empresa_id IS NULL THEN 1 END) as sem_empresa,
 COUNT(CASE WHEN d.empresa_id IS NOT NULL THEN 1 END) as com_empresa
FROM documentos d
LEFT JOIN tipos_documento td ON td.id = d.tipo_documento_id
WHERE d.deleted_at IS NULL
GROUP BY td.tipo;

-- 6. VERIFICAR DOCUMENTOS MAIS RECENTES (últimos 10)
SELECT
 d.id,
 d.versao,
 d.arquivo_nome,
 DATE(d.data_validade) as validade,
 td.nome as tipo,
 td.tipo as categoria,
 d.empresa_id,
 e.nome as empresa_nome,
 c.nome as colaborador,
 d.created_at
FROM documentos d
LEFT JOIN tipos_documento td ON td.id = d.tipo_documento_id
LEFT JOIN empresas e ON e.id = d.empresa_id
INNER JOIN colaboradores c ON c.id = d.colaborador_id
WHERE d.deleted_at IS NULL
ORDER BY d.created_at DESC
LIMIT 10;

-- 7. VERIFICAR SE SUBSTITUIÇÃO ESTÁ FUNCIONANDO
-- Documentos com versão > 1
SELECT
 d.id,
 d.versao,
 d.arquivo_nome,
 d.tipo_documento_id,
 d.empresa_id,
 d.substituido_por_id,
 COUNT(*) OVER (PARTITION BY d.colaborador_id, d.tipo_documento_id, d.empresa_id) as total_versoes
FROM documentos d
WHERE d.deleted_at IS NULL
 AND d.versao > 1
ORDER BY d.colaborador_id, d.tipo_documento_id, d.versao DESC;

-- ================================================
-- SCRIPTS ÚTEIS DE TESTE
-- ================================================

-- Inserir vínculo para teste (se não existir)
INSERT INTO vinculos (colaborador_id, empresa_id, ativo, created_at)
VALUES (1, 1, true, NOW())
ON CONFLICT DO NOTHING;

-- Verificar tipos de documento disponíveis
SELECT id, nome, tipo FROM tipos_documento ORDER BY nome;

-- Verificar colaboradores
SELECT id, nome FROM colaboradores WHERE deleted_at IS NULL;

-- Verificar empresas
SELECT id, nome FROM empresas WHERE deleted_at IS NULL;

-- Palavra final: Limpar documentos de teste se necessário (executar com cuidado)
-- DELETE FROM documentos WHERE colaborador_id = 1 AND arquivo_nome LIKE 'teste_%';
