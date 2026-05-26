const pool = require("../config/db");
const {
  parseOptionalInt,
  handleApiError,
  badRequest,
} = require("../utils/helpers");
const { logAudit } = require("../utils/auditLogger");

const getVinculos = async (req, res) => {
  const colaboradorId = parseOptionalInt(req.query.colaborador_id);
  const empresaId = parseOptionalInt(req.query.empresa_id);

  const filters = [];
  const params = [];

  // Filtra apenas por vínculos ativos e não deletados
  filters.push("v.ativo = true");
  filters.push("v.deleted_at IS NULL");
  filters.push("c.deleted_at IS NULL");
  filters.push("e.deleted_at IS NULL");

  if (colaboradorId) {
    params.push(colaboradorId);
    filters.push(`v.colaborador_id = $${params.length}`);
  }

  if (empresaId) {
    params.push(empresaId);
    filters.push(`v.empresa_id = $${params.length}`);
  }

  const whereClause =
    filters.length > 0 ? `WHERE ${filters.join(" AND ")}` : "";

  try {
    const query = `
      SELECT
        v.id,
        v.colaborador_id,
        c.nome as colaborador_nome,
        v.empresa_id,
        e.nome as empresa_nome,
        e.cnpj as empresa_cnpj,
        v.ativo,
        v.created_at
      FROM vinculos v
      INNER JOIN colaboradores c ON c.id = v.colaborador_id
      INNER JOIN empresas e ON e.id = v.empresa_id
      ${whereClause}
      ORDER BY e.nome ASC
    `;

    const result = await pool.query(query, params);
    // Retorna uma lista direta, sem paginação,
    // pois a quantidade de vínculos por colaborador/empresa é geralmente pequena.
    res.json(result.rows);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar vínculos");
  }
};

const createVinculo = async (req, res) => {
  const colaboradorId = parseOptionalInt(req.body.colaborador_id);
  const empresaId = parseOptionalInt(req.body.empresa_id);

  if (!colaboradorId || !empresaId) {
    return handleApiError(
      res,
      badRequest("Colaborador e empresa são obrigatórios"),
    );
  }

  try {
    // Verifica se o vínculo já existe e está ativo
    const existente = await pool.query(
      `SELECT id FROM vinculos
       WHERE colaborador_id = $1 AND empresa_id = $2 AND ativo = true AND deleted_at IS NULL`,
      [colaboradorId, empresaId],
    );

    if (existente.rows.length > 0) {
      return res
        .status(409)
        .json({ error: "Este vínculo já existe e está ativo." });
    }

    const result = await pool.query(
      `INSERT INTO vinculos (colaborador_id, empresa_id, ativo)
       VALUES ($1, $2, true) RETURNING *`,
      [colaboradorId, empresaId],
    );

    await logAudit({
      req,
      action: "vinculo.create",
      entityType: "vinculo",
      entityId: result.rows[0].id,
      metadata: { colaboradorId, empresaId },
    });
    res.status(201).json(result.rows[0]);
  } catch (err) {
    handleApiError(res, err, "Erro ao criar vínculo");
  }
};

const deleteVinculo = async (req, res) => {
  const id = parseOptionalInt(req.params.id);

  if (!id) {
    return handleApiError(res, badRequest("ID do vínculo é inválido"));
  }

  try {
    const vinculoResult = await pool.query(
      `SELECT colaborador_id, empresa_id
       FROM vinculos
       WHERE id = $1 AND deleted_at IS NULL`,
      [id],
    );

    if (vinculoResult.rows.length === 0) {
      return res.status(404).json({ error: "Vínculo não encontrado" });
    }

    const vinculo = vinculoResult.rows[0];
    const documentosAtivos = await pool.query(
      `SELECT COUNT(*)::int AS total
       FROM documentos
       WHERE colaborador_id = $1
         AND empresa_id = $2
         AND ativo = true
         AND deleted_at IS NULL`,
      [vinculo.colaborador_id, vinculo.empresa_id],
    );

    if (documentosAtivos.rows[0].total > 0) {
      return res.status(409).json({
        error:
          "Nao e possivel remover o vinculo porque existem documentos empresariais ativos associados.",
      });
    }

    const result = await pool.query(
      `UPDATE vinculos SET ativo = false, deleted_at = NOW()
       WHERE id = $1 AND deleted_at IS NULL RETURNING id`,
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Vínculo não encontrado" });
    }

    await logAudit({
      req,
      action: "vinculo.delete",
      entityType: "vinculo",
      entityId: id,
      metadata: { softDelete: true },
    });
    res.json({ message: "Vínculo removido com sucesso" });
  } catch (err) {
    handleApiError(res, err, "Erro ao remover vínculo");
  }
};

module.exports = {
  getVinculos,
  createVinculo,
  deleteVinculo,
};
