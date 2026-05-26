const pool = require("../config/db");
const {
  parseOptionalInt,
  sanitizeText,
  handleApiError,
  badRequest,
} = require("../utils/helpers");
const { logAudit } = require("../utils/auditLogger");

const getColaboradores = async (req, res) => {
  const page = parseOptionalInt(req.query.page) || 1;
  const limit = parseOptionalInt(req.query.limit) || 15;
  const offset = (page - 1) * limit;
  const search = sanitizeText(req.query.search);

  const filters = ["deleted_at IS NULL"];
  const params = [];

  if (search) {
    params.push(`%${search}%`);
    filters.push(
      `(nome ILIKE $${params.length} OR email ILIKE $${params.length})`,
    );
  }

  const whereClause =
    filters.length > 0 ? `WHERE ${filters.join(" AND ")}` : "";

  try {
    const countQuery = `SELECT COUNT(*) FROM colaboradores ${whereClause}`;
    const dataQuery = `SELECT * FROM colaboradores ${whereClause} ORDER BY nome LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    const dataPromise = pool.query(dataQuery, [...params, limit, offset]);
    const countPromise = pool.query(countQuery, params);

    const [dataResult, countResult] = await Promise.all([
      dataPromise,
      countPromise,
    ]);

    res.set("X-Total-Count", countResult.rows[0].count);
    res.json(dataResult.rows);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar colaboradores");
  }
};

const getColaboradorById = async (req, res) => {
  const id = parseOptionalInt(req.params.id);

  if (!id) {
    return handleApiError(res, badRequest("Colaborador invalido"));
  }

  try {
    const result = await pool.query(
      "SELECT * FROM colaboradores WHERE id = $1 AND deleted_at IS NULL",
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Colaborador nao encontrado" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar colaborador");
  }
};

const getColaboradorVinculos = async (req, res) => {
  const colaboradorId = parseOptionalInt(req.params.id);

  if (!colaboradorId) {
    return handleApiError(res, badRequest("Colaborador invalido"));
  }

  try {
    const result = await pool.query(
      `SELECT
         v.id,
         e.id AS empresa_id,
         e.nome AS empresa_nome,
         e.cnpj AS empresa_cnpj
       FROM vinculos v
       INNER JOIN empresas e ON e.id = v.empresa_id
       WHERE v.colaborador_id = $1
         AND v.ativo = true
         AND v.deleted_at IS NULL
         AND e.deleted_at IS NULL
       ORDER BY e.nome`,
      [colaboradorId],
    );

    res.json(result.rows);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar vinculos do colaborador");
  }
};

const createColaborador = async (req, res) => {
  const nome = sanitizeText(req.body.nome);
  const email = sanitizeText(req.body.email);
  const telefone = sanitizeText(req.body.telefone);

  if (!nome) {
    return handleApiError(res, badRequest("Nome do colaborador e obrigatorio"));
  }

  try {
    const result = await pool.query(
      "INSERT INTO colaboradores (nome, email, telefone) VALUES ($1, $2, $3) RETURNING *",
      [nome, email, telefone],
    );
    await logAudit({
      req,
      action: "colaborador.create",
      entityType: "colaborador",
      entityId: result.rows[0].id,
      metadata: { nome, email, telefone },
    });
    res.status(201).json(result.rows[0]);
  } catch (err) {
    handleApiError(res, err, "Erro ao criar colaborador");
  }
};

const updateColaborador = async (req, res) => {
  const id = parseOptionalInt(req.params.id);
  const nome = sanitizeText(req.body.nome);
  const email = sanitizeText(req.body.email);
  const telefone = sanitizeText(req.body.telefone);

  if (!id) {
    return handleApiError(res, badRequest("Colaborador invalido"));
  }

  if (!nome) {
    return handleApiError(res, badRequest("Nome do colaborador e obrigatorio"));
  }

  try {
    const result = await pool.query(
      `UPDATE colaboradores
       SET nome = $1, email = $2, telefone = $3
       WHERE id = $4 AND deleted_at IS NULL
       RETURNING *`,
      [nome, email, telefone, id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Colaborador nao encontrado" });
    }

    await logAudit({
      req,
      action: "colaborador.update",
      entityType: "colaborador",
      entityId: id,
      metadata: { nome, email, telefone },
    });
    res.json(result.rows[0]);
  } catch (err) {
    handleApiError(res, err, "Erro ao atualizar colaborador");
  }
};

const deleteColaborador = async (req, res) => {
  const id = parseOptionalInt(req.params.id);

  if (!id) {
    return handleApiError(res, badRequest("Colaborador invalido"));
  }

  try {
    // Check for dependencies before soft deleting
    const dependencias = await pool.query(
      `SELECT
         (SELECT COUNT(*) FROM vinculos WHERE colaborador_id = $1 AND deleted_at IS NULL)::int AS vinculos,
         (SELECT COUNT(*) FROM documentos WHERE colaborador_id = $1 AND deleted_at IS NULL)::int AS documentos`,
      [id],
    );

    const { vinculos, documentos } = dependencias.rows[0];
    if (vinculos > 0 || documentos > 0) {
      return res.status(409).json({
        error:
          "Nao e possivel excluir o colaborador porque existem vinculos ou documentos ativos associados",
      });
    }

    const result = await pool.query(
      "UPDATE colaboradores SET deleted_at = NOW() WHERE id = $1 AND deleted_at IS NULL RETURNING id",
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Colaborador nao encontrado" });
    }

    await logAudit({
      req,
      action: "colaborador.delete",
      entityType: "colaborador",
      entityId: id,
      metadata: { softDelete: true },
    });
    res.json({ message: "Colaborador removido com sucesso" });
  } catch (err) {
    handleApiError(res, err, "Erro ao excluir colaborador");
  }
};

module.exports = {
  getColaboradores,
  getColaboradorById,
  getColaboradorVinculos,
  createColaborador,
  updateColaborador,
  deleteColaborador,
};
