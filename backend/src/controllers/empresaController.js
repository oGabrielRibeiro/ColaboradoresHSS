const pool = require("../config/db");
const {
  parseOptionalInt,
  sanitizeText,
  handleApiError,
  badRequest,
} = require("../utils/helpers");

const getEmpresas = async (req, res) => {
  const page = parseOptionalInt(req.query.page) || 1;
  const limit = parseOptionalInt(req.query.limit) || 15;
  const offset = (page - 1) * limit;
  const search = sanitizeText(req.query.search);

  const filters = ["deleted_at IS NULL"];
  const params = [];

  if (search) {
    params.push(`%${search}%`);
    filters.push(
      `(nome ILIKE $${params.length} OR cnpj ILIKE $${params.length})`,
    );
  }

  const whereClause =
    filters.length > 0 ? `WHERE ${filters.join(" AND ")}` : "";

  try {
    const countQuery = `SELECT COUNT(*) FROM empresas ${whereClause}`;
    const dataQuery = `SELECT * FROM empresas ${whereClause} ORDER BY nome LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;

    const dataPromise = pool.query(dataQuery, [...params, limit, offset]);
    const countPromise = pool.query(countQuery, params);

    const [dataResult, countResult] = await Promise.all([
      dataPromise,
      countPromise,
    ]);

    res.set("X-Total-Count", countResult.rows[0].count);
    res.json(dataResult.rows);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar empresas");
  }
};

const createEmpresa = async (req, res) => {
  const nome = sanitizeText(req.body.nome);
  const cnpj = sanitizeText(req.body.cnpj);
  const contato = sanitizeText(req.body.contato);

  if (!nome) {
    return handleApiError(res, badRequest("Nome da empresa e obrigatorio"));
  }

  try {
    const result = await pool.query(
      "INSERT INTO empresas (nome, cnpj, contato) VALUES ($1, $2, $3) RETURNING *",
      [nome, cnpj, contato],
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    handleApiError(res, err, "Erro ao criar empresa");
  }
};

const updateEmpresa = async (req, res) => {
  const id = parseOptionalInt(req.params.id);
  const nome = sanitizeText(req.body.nome);
  const cnpj = sanitizeText(req.body.cnpj);
  const contato = sanitizeText(req.body.contato);

  if (!id) {
    return handleApiError(res, badRequest("Empresa invalida"));
  }

  if (!nome) {
    return handleApiError(res, badRequest("Nome da empresa e obrigatorio"));
  }

  try {
    const result = await pool.query(
      `UPDATE empresas
       SET nome = $1, cnpj = $2, contato = $3
       WHERE id = $4 AND deleted_at IS NULL
       RETURNING *`,
      [nome, cnpj, contato, id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Empresa nao encontrada" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    handleApiError(res, err, "Erro ao atualizar empresa");
  }
};

const deleteEmpresa = async (req, res) => {
  const id = parseOptionalInt(req.params.id);

  if (!id) {
    return handleApiError(res, badRequest("Empresa invalida"));
  }

  try {
    const dependencias = await pool.query(
      `SELECT (SELECT COUNT(*) FROM vinculos WHERE empresa_id = $1 AND deleted_at IS NULL)::int AS vinculos,
              (SELECT COUNT(*) FROM documentos WHERE empresa_id = $1 AND ativo = true AND deleted_at IS NULL)::int AS documentos`,
      [id],
    );

    const { vinculos, documentos } = dependencias.rows[0];
    if (vinculos > 0 || documentos > 0) {
      return res.status(409).json({
        error:
          "Nao e possivel excluir a empresa porque existem vinculos ou documentos ativos associados",
      });
    }

    const result = await pool.query(
      "UPDATE empresas SET deleted_at = NOW() WHERE id = $1 AND deleted_at IS NULL RETURNING id",
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Empresa nao encontrada" });
    }

    res.json({ message: "Empresa removida com sucesso" });
  } catch (err) {
    handleApiError(res, err, "Erro ao excluir empresa");
  }
};

const getEmpresaById = async (req, res) => {
  const id = parseOptionalInt(req.params.id);

  if (!id) {
    return handleApiError(res, badRequest("Empresa invalida"));
  }

  try {
    const result = await pool.query(
      "SELECT * FROM empresas WHERE id = $1 AND deleted_at IS NULL",
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Empresa nao encontrada" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar empresa");
  }
};

module.exports = {
  getEmpresas,
  createEmpresa,
  updateEmpresa,
  deleteEmpresa,
  getEmpresaById,
};
