const pool = require("../config/db");
const {
  parseOptionalInt,
  handleApiError,
  badRequest,
} = require("../utils/helpers");

const getVinculos = async (req, res) => {
  const colaboradorId = parseOptionalInt(req.query.colaborador_id);
  const params = [];
  let whereClause = "";

  if (colaboradorId) {
    params.push(colaboradorId);
    whereClause =
      "WHERE v.colaborador_id = $1 AND v.ativo = true AND v.deleted_at IS NULL AND e.deleted_at IS NULL";
  } else {
    whereClause =
      "WHERE v.ativo = true AND v.deleted_at IS NULL AND e.deleted_at IS NULL";
  }

  try {
    const result = await pool.query(
      `SELECT
           v.*,
           e.nome AS empresa_nome,
           e.cnpj AS empresa_cnpj
         FROM vinculos v
         INNER JOIN empresas e ON e.id = v.empresa_id
         ${whereClause}
         ORDER BY e.nome`,
      params,
    );
    res.json(result.rows);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar vinculos");
  }
};

const createVinculo = async (req, res) => {
  const colaboradorId = parseOptionalInt(req.body.colaborador_id);
  const empresaId = parseOptionalInt(req.body.empresa_id);

  if (!colaboradorId || !empresaId) {
    return handleApiError(
      res,
      badRequest("Colaborador e empresa sao obrigatorios"),
    );
  }

  try {
    const existente = await pool.query(
      `SELECT id
         FROM vinculos
         WHERE colaborador_id = $1
           AND empresa_id = $2
           AND ativo = true
           AND deleted_at IS NULL`,
      [colaboradorId, empresaId],
    );

    if (existente.rows.length > 0) {
      return res
        .status(409)
        .json({ error: "Este colaborador ja esta vinculado a empresa" });
    }

    const result = await pool.query(
      "INSERT INTO vinculos (colaborador_id, empresa_id) VALUES ($1, $2) RETURNING *",
      [colaboradorId, empresaId],
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    handleApiError(res, err, "Erro ao criar vinculo");
  }
};

const deleteVinculo = async (req, res) => {
  const id = parseOptionalInt(req.params.id);

  if (!id) {
    return handleApiError(res, badRequest("Vinculo invalido"));
  }

  try {
    const dependencias = await pool.query(
      `SELECT COUNT(*) FROM documentos WHERE vinculo_id = $1 AND ativo = true AND deleted_at IS NULL`,
      [id],
    );

    if (dependencias.rows[0].count > 0) {
      return res.status(409).json({
        error:
          "Nao e possivel excluir o vinculo porque existem documentos ativos associados",
      });
    }

    const result = await pool.query(
      "UPDATE vinculos SET deleted_at = NOW() WHERE id = $1 AND deleted_at IS NULL RETURNING id",
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Vinculo nao encontrado" });
    }

    res.json({ message: "Vinculo removido com sucesso" });
  } catch (err) {
    handleApiError(res, err, "Erro ao remover vinculo");
  }
};

const getVinculoById = async (req, res) => {
  const id = parseOptionalInt(req.params.id);

  if (!id) {
    return handleApiError(res, badRequest("Vinculo invalido"));
  }

  try {
    const result = await pool.query(
      `SELECT
         v.*,
         e.nome AS empresa_nome,
         e.cnpj AS empresa_cnpj,
         c.nome AS colaborador_nome,
         c.email AS colaborador_email
       FROM vinculos v
       INNER JOIN empresas e ON e.id = v.empresa_id
       INNER JOIN colaboradores c ON c.id = v.colaborador_id
       WHERE v.id = $1 AND v.deleted_at IS NULL`,
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Vinculo nao encontrado" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar vinculo");
  }
};

module.exports = {
  getVinculos,
  createVinculo,
  deleteVinculo,
  getVinculoById,
};
