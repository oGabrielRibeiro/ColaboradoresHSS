const fs = require("fs");
const path = require("path");
const pool = require("../config/db");
const {
  sanitizeText,
  parseOptionalInt,
  isValidFutureOrTodayDate,
  handleApiError,
  badRequest,
} = require("../utils/helpers");

const ensureEmpresaVinculada = async (colaboradorId, empresaId) => {
  const vinculo = await pool.query(
    `SELECT id
     FROM vinculos
     WHERE colaborador_id = $1
       AND empresa_id = $2
       AND ativo = true
       AND deleted_at IS NULL`, // Added deleted_at check for consistency
    [colaboradorId, empresaId],
  );

  if (vinculo.rows.length === 0) {
    const error = new Error(
      "O colaborador precisa estar vinculado a empresa para receber documento empresarial",
    );
    error.statusCode = 400;
    throw error;
  }
};

const getDocumentos = async (req, res) => {
  const page = parseOptionalInt(req.query.page) || 1;
  const limit = parseOptionalInt(req.query.limit) || 15;
  const offset = (page - 1) * limit;

  const filters = [];
  const params = [];

  const colaboradorId = parseOptionalInt(req.query.colaborador_id);
  const empresaId = parseOptionalInt(req.query.empresa_id);
  const status = sanitizeText(req.query.status);
  const somenteAtivos = req.query.ativo !== "false";

  // Always filter by deleted_at for main entities
  filters.push("d.deleted_at IS NULL");
  filters.push("c.deleted_at IS NULL");
  filters.push("(e.deleted_at IS NULL OR d.empresa_id IS NULL)"); // Correctly handle documents with no company

  if (colaboradorId) {
    params.push(colaboradorId);
    filters.push(`d.colaborador_id = $${params.length}`);
  }

  if (req.query.empresa_id !== undefined) {
    if (empresaId === null) {
      filters.push("d.empresa_id IS NULL");
    } else {
      params.push(empresaId);
      filters.push(`d.empresa_id = $${params.length}`);
    }
  }

  if (somenteAtivos) {
    filters.push("d.ativo = true");
  }

  if (status === "vencido") {
    // Use else if to avoid overlapping conditions
    filters.push("d.data_validade < CURRENT_DATE");
  } else if (status === "a_vencer") {
    filters.push(
      "d.data_validade BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'",
    );
  } else if (status === "ok") {
    filters.push("d.data_validade > CURRENT_DATE + INTERVAL '30 days'");
  }

  const whereClause =
    filters.length > 0 ? `WHERE ${filters.join(" AND ")}` : "";

  // Common FROM and JOIN clauses for both data and count queries
  const fromJoinClause = `
    FROM documentos d
    INNER JOIN colaboradores c ON c.id = d.colaborador_id
    LEFT JOIN tipos_documento td ON td.id = d.tipo_documento_id
    LEFT JOIN empresas e ON e.id = d.empresa_id
  `;

  try {
    const dataQuery = `
        SELECT
          d.*,
          c.nome AS colaborador_nome,
          td.nome AS tipo_documento_nome,
          td.tipo AS tipo_documento_categoria,
          e.nome AS empresa_nome
        ${fromJoinClause}
        ${whereClause}
        ORDER BY d.data_validade ASC, d.created_at DESC
        LIMIT $${params.length + 1} OFFSET $${params.length + 2}
      `;

    const countQuery = `
        SELECT COUNT(*) 
        ${fromJoinClause}
        ${whereClause}
      `;

    const dataPromise = pool.query(dataQuery, [...params, limit, offset]);
    const countPromise = pool.query(countQuery, params);

    const [dataResult, countResult] = await Promise.all([
      dataPromise,
      countPromise,
    ]);
    res.set("X-Total-Count", countResult.rows[0].count);

    res.json(dataResult.rows);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar documentos");
  }
};

const createDocumento = async (req, res) => {
  const colaboradorId = parseOptionalInt(req.body.colaborador_id);
  const empresaId = parseOptionalInt(req.body.empresa_id);
  const tipoDocumentoId = parseOptionalInt(req.body.tipo_documento_id);
  const dataValidade = sanitizeText(req.body.data_validade);
  const arquivoNome = sanitizeText(req.body.arquivo_nome);
  const arquivoPath = sanitizeText(req.body.arquivo_path); // e.g., /uploads/filename.ext
  const observacoes = sanitizeText(req.body.observacoes);

  if (
    !colaboradorId ||
    !tipoDocumentoId ||
    !dataValidade ||
    !arquivoNome ||
    !arquivoPath // Frontend sends the path it received from the upload endpoint
  ) {
    return handleApiError(
      res,
      badRequest("Dados obrigatorios do documento nao foram informados"),
    );
  }

  if (!isValidFutureOrTodayDate(dataValidade)) {
    return handleApiError(
      res,
      badRequest("A data de validade deve ser hoje ou uma data futura"),
    );
  }

  try {
    const tipo = await pool.query(
      "SELECT * FROM tipos_documento WHERE id = $1",
      [tipoDocumentoId],
    );

    if (tipo.rows.length === 0) {
      return res
        .status(404)
        .json({ error: "Tipo de documento nao encontrado" });
    }

    const categoria = tipo.rows[0].tipo;

    if (categoria === "empresa") {
      if (!empresaId) {
        return handleApiError(
          res,
          badRequest("Documentos empresariais exigem empresa vinculada"),
        );
      }

      await ensureEmpresaVinculada(colaboradorId, empresaId);
    }

    if (categoria === "pessoal" && empresaId) {
      return handleApiError(
        res,
        badRequest("Documentos pessoais nao devem ser vinculados a empresa"),
      );
    }

    const existente = await pool.query(
      `SELECT id
         FROM documentos
         WHERE d.colaborador_id = $1
           AND tipo_documento_id = $2
           AND (
             (empresa_id = $3)
             OR ($3 IS NULL AND empresa_id IS NULL)
           )
           AND ativo = true
           AND deleted_at IS NULL`,
      [colaboradorId, tipoDocumentoId, empresaId],
    );

    if (existente.rows.length > 0) {
      return res.status(409).json({
        error:
          "Ja existe um documento ativo desse tipo para este colaborador. Use a substituicao para criar nova versao.",
      });
    }

    const arquivoFilename = arquivoPath ? path.basename(arquivoPath) : null;

    const result = await pool.query(
      `INSERT INTO documentos
         (colaborador_id, empresa_id, tipo_documento_id, data_validade, arquivo_nome, arquivo_path, observacoes, ativo, versao)
         VALUES ($1, $2, $3, $4, $5, $6, $7, true, 1)
         RETURNING *`,
      [
        colaboradorId,
        empresaId,
        tipoDocumentoId,
        dataValidade,
        arquivoNome,
        arquivoFilename,
        observacoes,
      ],
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    handleApiError(res, err, "Erro ao criar documento");
  }
};

const getDocumentoHistorico = async (req, res) => {
  const id = parseOptionalInt(req.params.id);

  if (!id) {
    return handleApiError(res, badRequest("Documento invalido"));
  }

  try {
    const documento = await pool.query(
      "SELECT * FROM documentos WHERE id = $1",
      [id],
    );

    if (documento.rows.length === 0) {
      return res.status(404).json({ error: "Documento nao encontrado" });
    }

    const doc = documento.rows[0];

    const historico = await pool.query(
      `SELECT
           d.*,
           c.nome AS colaborador_nome,
           td.nome AS tipo_documento_nome,
           td.tipo AS tipo_documento_categoria,
           e.nome AS empresa_nome
         FROM documentos d
         INNER JOIN colaboradores c ON c.id = d.colaborador_id
         LEFT JOIN tipos_documento td ON td.id = d.tipo_documento_id
         LEFT JOIN empresas e ON e.id = d.empresa_id
         WHERE d.colaborador_id = $1
           AND d.tipo_documento_id = $2
           AND (
             (d.empresa_id = $3)
             OR ($3 IS NULL AND d.empresa_id IS NULL)
           )
           AND d.deleted_at IS NULL
           AND c.deleted_at IS NULL
         ORDER BY d.versao DESC, d.created_at DESC`,
      [doc.colaborador_id, doc.tipo_documento_id, doc.empresa_id],
    );

    res.json(historico.rows);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar historico do documento");
  }
};

const substituirDocumento = async (req, res) => {
  const id = parseOptionalInt(req.params.id);
  const dataValidade = sanitizeText(req.body.data_validade);
  const observacoes = sanitizeText(req.body.observacoes);
  const { file: arquivo } = req;

  if (!id) {
    return handleApiError(res, badRequest("Documento original inválido"));
  }

  if (!dataValidade || !arquivo) {
    return handleApiError(
      res,
      badRequest("Nova data de validade e novo arquivo são obrigatórios"),
    );
  }

  if (!isValidFutureOrTodayDate(dataValidade)) {
    return handleApiError(
      res,
      badRequest("A data de validade deve ser hoje ou uma data futura"),
    );
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const documentoOriginalResult = await client.query(
      "SELECT * FROM documentos WHERE id = $1 AND deleted_at IS NULL FOR UPDATE",
      [id],
    );

    if (documentoOriginalResult.rows.length === 0) {
      throw badRequest("Documento original não encontrado");
    }

    const original = documentoOriginalResult.rows[0];
    if (!original.ativo) {
      throw badRequest(
        "Não é possível substituir um documento que já está inativo.",
      );
    }

    const novoDocumentoResult = await client.query(
      `INSERT INTO documentos
         (colaborador_id, empresa_id, tipo_documento_id, data_validade, arquivo_nome, arquivo_path, observacoes, ativo, versao)
         VALUES ($1, $2, $3, $4, $5, $6, $7, true, $8)
         RETURNING *`,
      [
        original.colaborador_id,
        original.empresa_id,
        original.tipo_documento_id,
        dataValidade,
        arquivo.originalname,
        arquivo.filename,
        observacoes,
        original.versao + 1,
      ],
    );

    const novoDocumento = novoDocumentoResult.rows[0];

    await client.query(
      `UPDATE documentos SET ativo = false, substituido_por_id = $1 WHERE id = $2`,
      [novoDocumento.id, original.id],
    );

    await client.query("COMMIT");
    res.status(201).json(novoDocumento);
  } catch (err) {
    await client.query("ROLLBACK");
    if (arquivo && fs.existsSync(arquivo.path)) {
      fs.unlinkSync(arquivo.path);
    }
    handleApiError(res, err, "Erro ao substituir documento");
  } finally {
    client.release();
  }
};

const getDocumentoById = async (req, res) => {
  const id = parseOptionalInt(req.params.id);

  if (!id) {
    return handleApiError(res, badRequest("Documento invalido"));
  }

  try {
    const result = await pool.query(
      `SELECT
         d.*,
         c.nome AS colaborador_nome,
         td.nome AS tipo_documento_nome,
         td.tipo AS tipo_documento_categoria,
         e.nome AS empresa_nome
       FROM documentos d
       INNER JOIN colaboradores c ON c.id = d.colaborador_id
       LEFT JOIN tipos_documento td ON td.id = d.tipo_documento_id
       LEFT JOIN empresas e ON e.id = d.empresa_id
       WHERE d.id = $1 AND d.deleted_at IS NULL`,
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Documento nao encontrado" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar documento");
  }
};

const updateDocumento = async (req, res) => {
  const id = parseOptionalInt(req.params.id);
  const dataValidade = sanitizeText(req.body.data_validade);
  const observacoes = sanitizeText(req.body.observacoes);
  const ativo = req.body.ativo; // boolean

  if (!id) {
    return handleApiError(res, badRequest("Documento invalido"));
  }

  if (!dataValidade) {
    return handleApiError(res, badRequest("Data de validade e obrigatoria"));
  }

  if (!isValidFutureOrTodayDate(dataValidade)) {
    return handleApiError(
      res,
      badRequest("A data de validade deve ser hoje ou uma data futura"),
    );
  }

  try {
    const result = await pool.query(
      `UPDATE documentos
       SET data_validade = $1, observacoes = $2, ativo = $3
       WHERE id = $4 AND deleted_at IS NULL
       RETURNING *`,
      [dataValidade, observacoes, ativo, id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Documento nao encontrado" });
    }

    res.json(result.rows[0]);
  } catch (err) {
    handleApiError(res, err, "Erro ao atualizar documento");
  }
};

const deleteDocumento = async (req, res) => {
  const id = parseOptionalInt(req.params.id);

  if (!id) {
    return handleApiError(res, badRequest("Documento invalido"));
  }

  try {
    const result = await pool.query(
      "UPDATE documentos SET deleted_at = NOW() WHERE id = $1 AND deleted_at IS NULL RETURNING id",
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Documento nao encontrado" });
    }

    res.json({ message: "Documento removido com sucesso" });
  } catch (err) {
    handleApiError(res, err, "Erro ao excluir documento");
  }
};

module.exports = {
  getDocumentos,
  createDocumento,
  getDocumentoHistorico,
  substituirDocumento,
  getDocumentoById,
  updateDocumento,
  deleteDocumento,
  ensureEmpresaVinculada, // Export ensureEmpresaVinculada as it's used by createDocumento
};
