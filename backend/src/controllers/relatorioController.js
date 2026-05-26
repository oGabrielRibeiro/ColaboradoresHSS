const pool = require("../config/db");
const { sanitizeText, handleApiError } = require("../utils/helpers");

const getDocumentosVencidosPorEmpresa = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT
         e.id AS empresa_id,
         e.nome AS empresa_nome,
         COUNT(d.id)::int AS total_documentos_vencidos
       FROM empresas e
       INNER JOIN documentos d ON d.empresa_id = e.id
       WHERE e.deleted_at IS NULL
         AND d.deleted_at IS NULL
         AND d.ativo = true
         AND d.data_validade < CURRENT_DATE
       GROUP BY e.id, e.nome
       ORDER BY total_documentos_vencidos DESC, e.nome ASC`,
    );

    res.json(result.rows);
  } catch (err) {
    handleApiError(res, err, "Erro ao gerar relatorio de vencidos por empresa");
  }
};

const getDocumentosAVencerPorPeriodo = async (req, res) => {
  const dataInicio = sanitizeText(req.query.data_inicio);
  const dataFim = sanitizeText(req.query.data_fim);
  const baseDate = sanitizeText(req.query.base_date) || new Date().toISOString();
  const dias = Number.parseInt(req.query.dias || "30", 10);

  try {
    let query = "";
    let params = [];

    if (dataInicio && dataFim) {
      query = `
        SELECT
          d.id,
          d.colaborador_id,
          c.nome AS colaborador_nome,
          d.empresa_id,
          e.nome AS empresa_nome,
          d.tipo_documento_id,
          td.nome AS tipo_documento_nome,
          d.data_validade,
          d.versao
        FROM documentos d
        INNER JOIN colaboradores c ON c.id = d.colaborador_id
        LEFT JOIN empresas e ON e.id = d.empresa_id
        LEFT JOIN tipos_documento td ON td.id = d.tipo_documento_id
        WHERE d.deleted_at IS NULL
          AND d.ativo = true
          AND c.deleted_at IS NULL
          AND (e.deleted_at IS NULL OR d.empresa_id IS NULL)
          AND d.data_validade BETWEEN $1::date AND $2::date
        ORDER BY d.data_validade ASC, colaborador_nome ASC
      `;
      params = [dataInicio, dataFim];
    } else {
      query = `
        SELECT
          d.id,
          d.colaborador_id,
          c.nome AS colaborador_nome,
          d.empresa_id,
          e.nome AS empresa_nome,
          d.tipo_documento_id,
          td.nome AS tipo_documento_nome,
          d.data_validade,
          d.versao
        FROM documentos d
        INNER JOIN colaboradores c ON c.id = d.colaborador_id
        LEFT JOIN empresas e ON e.id = d.empresa_id
        LEFT JOIN tipos_documento td ON td.id = d.tipo_documento_id
        WHERE d.deleted_at IS NULL
          AND d.ativo = true
          AND c.deleted_at IS NULL
          AND (e.deleted_at IS NULL OR d.empresa_id IS NULL)
          AND d.data_validade BETWEEN DATE($1::timestamp) AND DATE($1::timestamp) + ($2::int * INTERVAL '1 day')
        ORDER BY d.data_validade ASC, colaborador_nome ASC
      `;
      params = [baseDate, Number.isNaN(dias) ? 30 : dias];
    }

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    handleApiError(res, err, "Erro ao gerar relatorio de documentos a vencer");
  }
};

const getIntegridadeDocumentos = async (req, res) => {
  const janelaDias = Number.parseInt(req.query.janela_dias || "30", 10);
  const dias = Number.isNaN(janelaDias) ? 30 : janelaDias;

  try {
    const [visaoListas, visaoDashboard, porEmpresa, porCategoria] =
      await Promise.all([
        pool.query(
          `SELECT
             COUNT(*)::int AS total_documentos_ativos_lista,
             COUNT(*) FILTER (WHERE d.data_validade < CURRENT_DATE)::int AS documentos_vencidos_lista,
             COUNT(*) FILTER (
               WHERE d.data_validade BETWEEN CURRENT_DATE
               AND CURRENT_DATE + ($1::int * INTERVAL '1 day')
             )::int AS documentos_a_vencer_lista
           FROM documentos d
           INNER JOIN colaboradores c ON c.id = d.colaborador_id
           LEFT JOIN empresas e ON e.id = d.empresa_id
           WHERE d.deleted_at IS NULL
             AND d.ativo = true
             AND c.deleted_at IS NULL
             AND (e.deleted_at IS NULL OR d.empresa_id IS NULL)`,
          [dias],
        ),
        pool.query(
          `SELECT
             COUNT(*) FILTER (WHERE d.ativo = true AND d.deleted_at IS NULL)::int AS total_documentos_ativos_dashboard,
             COUNT(*) FILTER (
               WHERE d.ativo = true
                 AND d.deleted_at IS NULL
                 AND d.data_validade < CURRENT_DATE
             )::int AS documentos_vencidos_dashboard,
             COUNT(*) FILTER (
               WHERE d.ativo = true
                 AND d.deleted_at IS NULL
                 AND d.data_validade BETWEEN CURRENT_DATE
                 AND CURRENT_DATE + ($1::int * INTERVAL '1 day')
             )::int AS documentos_a_vencer_dashboard
           FROM documentos d`,
          [dias],
        ),
        pool.query(
          `SELECT
             COALESCE(e.id, 0)::int AS empresa_id,
             COALESCE(e.nome, 'Sem empresa') AS empresa_nome,
             COUNT(*)::int AS total_ativos,
             COUNT(*) FILTER (WHERE d.data_validade < CURRENT_DATE)::int AS vencidos,
             COUNT(*) FILTER (
               WHERE d.data_validade BETWEEN CURRENT_DATE
               AND CURRENT_DATE + ($1::int * INTERVAL '1 day')
             )::int AS a_vencer
           FROM documentos d
           INNER JOIN colaboradores c ON c.id = d.colaborador_id
           LEFT JOIN empresas e ON e.id = d.empresa_id
           WHERE d.deleted_at IS NULL
             AND d.ativo = true
             AND c.deleted_at IS NULL
             AND (e.deleted_at IS NULL OR d.empresa_id IS NULL)
           GROUP BY e.id, e.nome
           ORDER BY total_ativos DESC, empresa_nome ASC`,
          [dias],
        ),
        pool.query(
          `SELECT
             COALESCE(td.tipo, 'desconhecido') AS categoria,
             COUNT(*)::int AS total_ativos
           FROM documentos d
           LEFT JOIN tipos_documento td ON td.id = d.tipo_documento_id
           INNER JOIN colaboradores c ON c.id = d.colaborador_id
           LEFT JOIN empresas e ON e.id = d.empresa_id
           WHERE d.deleted_at IS NULL
             AND d.ativo = true
             AND c.deleted_at IS NULL
             AND (e.deleted_at IS NULL OR d.empresa_id IS NULL)
           GROUP BY td.tipo
           ORDER BY categoria ASC`,
        ),
      ]);

    const listas = visaoListas.rows[0];
    const dashboard = visaoDashboard.rows[0];

    const mismatches = {
      total_ativos:
        listas.total_documentos_ativos_lista !==
        dashboard.total_documentos_ativos_dashboard,
      vencidos:
        listas.documentos_vencidos_lista !==
        dashboard.documentos_vencidos_dashboard,
      a_vencer:
        listas.documentos_a_vencer_lista !==
        dashboard.documentos_a_vencer_dashboard,
    };

    res.json({
      janela_dias: dias,
      resumo_listas: listas,
      resumo_dashboard: dashboard,
      mismatches,
      por_empresa: porEmpresa.rows,
      por_categoria: porCategoria.rows,
    });
  } catch (err) {
    handleApiError(res, err, "Erro ao gerar relatorio de integridade");
  }
};

module.exports = {
  getDocumentosVencidosPorEmpresa,
  getDocumentosAVencerPorPeriodo,
  getIntegridadeDocumentos,
};
