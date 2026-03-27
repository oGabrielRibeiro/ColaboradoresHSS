const pool = require("../config/db");
const { handleApiError } = require("../utils/helpers");

const notifyDaysAhead = Number.parseInt(
  process.env.NOTIFY_DAYS_AHEAD || "30",
  10,
);

const getDashboardResumo = async (req, res) => {
  try {
    const [
      empresasResult,
      colaboradoresResult,
      documentosAtivosResult,
      documentosAVencerResult,
      documentosVencidosResult,
    ] = await Promise.all([
      pool.query("SELECT COUNT(*) FROM empresas WHERE deleted_at IS NULL"),
      pool.query("SELECT COUNT(*) FROM colaboradores WHERE deleted_at IS NULL"),
      pool.query(
        "SELECT COUNT(*) FROM documentos WHERE ativo = true AND deleted_at IS NULL",
      ),
      pool.query(
        `SELECT COUNT(*) FROM documentos
         WHERE data_validade BETWEEN CURRENT_DATE AND CURRENT_DATE + ($1::int * INTERVAL '1 day')
           AND ativo = true
           AND deleted_at IS NULL`,
        [notifyDaysAhead],
      ),
      pool.query(
        "SELECT COUNT(*) FROM documentos WHERE data_validade < CURRENT_DATE AND ativo = true AND deleted_at IS NULL",
      ),
    ]);

    res.json({
      total_empresas: parseInt(empresasResult.rows[0].count, 10),
      total_colaboradores: parseInt(colaboradoresResult.rows[0].count, 10),
      total_documentos_ativos: parseInt(
        documentosAtivosResult.rows[0].count,
        10,
      ),
      documentos_a_vencer: parseInt(documentosAVencerResult.rows[0].count, 10),
      documentos_vencidos: parseInt(documentosVencidosResult.rows[0].count, 10),
      janela_notificacao_dias: notifyDaysAhead,
    });
  } catch (err) {
    handleApiError(res, err, "Erro ao carregar resumo");
  }
};

module.exports = {
  getDashboardResumo,
};
