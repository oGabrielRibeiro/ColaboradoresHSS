const pool = require("../config/db");
const {
  parseOptionalInt,
  sanitizeText,
  handleApiError,
} = require("../utils/helpers");

const getAuditLogs = async (req, res) => {
  const page = parseOptionalInt(req.query.page) || 1;
  const limit = parseOptionalInt(req.query.limit) || 25;
  const offset = (page - 1) * limit;

  const action = sanitizeText(req.query.action);
  const entityType = sanitizeText(req.query.entity_type);
  const entityId = sanitizeText(req.query.entity_id);
  const userId = parseOptionalInt(req.query.user_id);
  const fromDate = sanitizeText(req.query.from_date);
  const toDate = sanitizeText(req.query.to_date);

  const filters = [];
  const params = [];

  if (action) {
    params.push(action);
    filters.push(`action = $${params.length}`);
  }

  if (entityType) {
    params.push(entityType);
    filters.push(`entity_type = $${params.length}`);
  }

  if (entityId) {
    params.push(entityId);
    filters.push(`entity_id = $${params.length}`);
  }

  if (userId) {
    params.push(userId);
    filters.push(`user_id = $${params.length}`);
  }

  if (fromDate) {
    params.push(fromDate);
    filters.push(`created_at >= $${params.length}::timestamp`);
  }

  if (toDate) {
    params.push(toDate);
    filters.push(`created_at <= $${params.length}::timestamp`);
  }

  const whereClause =
    filters.length > 0 ? `WHERE ${filters.join(" AND ")}` : "";

  try {
    const countQuery = `SELECT COUNT(*) FROM audit_logs ${whereClause}`;
    const dataQuery = `
      SELECT *
      FROM audit_logs
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}
    `;

    const [countResult, dataResult] = await Promise.all([
      pool.query(countQuery, params),
      pool.query(dataQuery, [...params, limit, offset]),
    ]);

    res.set("X-Total-Count", countResult.rows[0].count);
    res.json(dataResult.rows);
  } catch (err) {
    handleApiError(res, err, "Erro ao buscar logs de auditoria");
  }
};

module.exports = {
  getAuditLogs,
};
