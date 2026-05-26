const pool = require("../config/db");
const { sanitizeText, parseOptionalInt, handleApiError, badRequest } = require("../utils/helpers");

const getTiposDocumento = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM tipos_documento ORDER BY tipo, nome",
    );
    res.json(result.rows);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar tipos de documento");
  }
};

const createTipoDocumento = async (req, res) => {
  const nome = sanitizeText(req.body.nome);
  const descricao = sanitizeText(req.body.descricao);
  const tipo = sanitizeText(req.body.tipo);

  if (!nome || !tipo) {
    return handleApiError(res, badRequest("Nome e tipo sao obrigatorios"));
  }

  if (tipo !== "pessoal" && tipo !== "empresa") {
    return handleApiError(
      res,
      badRequest("Tipo deve ser 'pessoal' ou 'empresa'"),
    );
  }

  try {
    const result = await pool.query(
      `INSERT INTO tipos_documento (nome, descricao, tipo)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [nome, descricao, tipo],
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === "23505") {
      return res.status(409).json({ error: "Ja existe um tipo com esse nome" });
    }
    handleApiError(res, err, "Erro ao criar tipo de documento");
  }
};

const updateTipoDocumento = async (req, res) => {
  const id = parseOptionalInt(req.params.id);
  const nome = sanitizeText(req.body.nome);
  const descricao = sanitizeText(req.body.descricao);
  const tipo = sanitizeText(req.body.tipo);

  if (!id) {
    return handleApiError(res, badRequest("ID invalido"));
  }

  if (!nome || !tipo) {
    return handleApiError(res, badRequest("Nome e tipo sao obrigatorios"));
  }

  if (tipo !== "pessoal" && tipo !== "empresa") {
    return handleApiError(
      res,
      badRequest("Tipo deve ser 'pessoal' ou 'empresa'"),
    );
  }

  try {
    const result = await pool.query(
      `UPDATE tipos_documento
       SET nome = $1, descricao = $2, tipo = $3
       WHERE id = $4
       RETURNING *`,
      [nome, descricao, tipo, id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Tipo de documento nao encontrado" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    if (err.code === "23505") {
      return res.status(409).json({ error: "Ja existe um tipo com esse nome" });
    }
    handleApiError(res, err, "Erro ao atualizar tipo de documento");
  }
};

const deleteTipoDocumento = async (req, res) => {
  const id = parseOptionalInt(req.params.id);

  if (!id) {
    return handleApiError(res, badRequest("ID invalido"));
  }

  try {
    const emUso = await pool.query(
      `SELECT COUNT(*)::int AS total
       FROM documentos
       WHERE tipo_documento_id = $1 AND deleted_at IS NULL`,
      [id],
    );

    if (emUso.rows[0].total > 0) {
      return res.status(409).json({
        error:
          "Nao e possivel excluir tipo de documento em uso por documentos cadastrados.",
      });
    }

    const result = await pool.query(
      "DELETE FROM tipos_documento WHERE id = $1 RETURNING id",
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Tipo de documento nao encontrado" });
    }

    res.json({ message: "Tipo de documento removido com sucesso" });
  } catch (err) {
    handleApiError(res, err, "Erro ao remover tipo de documento");
  }
};

module.exports = {
  getTiposDocumento,
  createTipoDocumento,
  updateTipoDocumento,
  deleteTipoDocumento,
};
