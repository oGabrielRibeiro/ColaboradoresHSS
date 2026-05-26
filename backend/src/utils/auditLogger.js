const pool = require("../config/db");

async function logAudit({
  req,
  action,
  entityType,
  entityId = null,
  metadata = null,
}) {
  try {
    const authUser = req?.authUser || {};
    const userId = authUser.sub ? Number.parseInt(authUser.sub, 10) : null;
    const userEmail = authUser.email || null;
    const userNome = authUser.nome || null;
    const ipAddress =
      req?.headers["x-forwarded-for"]?.toString().split(",")[0]?.trim() ||
      req?.socket?.remoteAddress ||
      null;
    const userAgent = req?.headers["user-agent"] || null;

    await pool.query(
      `INSERT INTO audit_logs
       (user_id, user_email, user_nome, action, entity_type, entity_id, metadata, ip_address, user_agent)
       VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8, $9)`,
      [
        Number.isNaN(userId) ? null : userId,
        userEmail,
        userNome,
        action,
        entityType,
        entityId == null ? null : String(entityId),
        metadata ? JSON.stringify(metadata) : null,
        ipAddress,
        userAgent,
      ],
    );
  } catch (error) {
    console.error("[AUDIT] Falha ao gravar log de auditoria:", error.message);
  }
}

module.exports = { logAudit };
