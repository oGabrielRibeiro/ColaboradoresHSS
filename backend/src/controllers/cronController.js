const cron = require("node-cron");
const pool = require("../config/db");

const notifyDaysAhead = Number.parseInt(
  process.env.NOTIFY_DAYS_AHEAD || "30",
  10,
);
const notifyCronSchedule = process.env.CRON_NOTIFY_SCHEDULE || "0 8 * * *";
const notifyRunOnStart = process.env.NOTIFY_RUN_ON_START !== "false";

async function registrarNotificacoesPorTipo(
  tipoAlerta,
  whereClause,
  params = [],
) {
  const query = `
    INSERT INTO notificacoes_enviadas (documento_id, tipo_alerta)
    SELECT d.id, $1::VARCHAR(20)
    FROM documentos d
    WHERE d.ativo = true
      AND d.deleted_at IS NULL
      AND ${whereClause}
      AND NOT EXISTS (
        SELECT 1
        FROM notificacoes_enviadas n
        WHERE n.documento_id = d.id
          AND n.tipo_alerta = $1
          AND DATE(n.enviado_em) = CURRENT_DATE
      )
    RETURNING id
  `;

  const result = await pool.query(query, [tipoAlerta, ...params]);
  return result.rows.length;
}

async function executarJobNotificacoesVencimento() {
  try {
    const inseridosVencidos = await registrarNotificacoesPorTipo(
      "vencido",
      "d.data_validade < CURRENT_DATE",
    );

    const inseridosAVencer = await registrarNotificacoesPorTipo(
      "a_vencer",
      "d.data_validade BETWEEN CURRENT_DATE AND CURRENT_DATE + ($2::int * INTERVAL '1 day')",
      [notifyDaysAhead],
    );

    const totalInseridos = inseridosVencidos + inseridosAVencer;
    console.log(
      `[CRON] Notificacoes processadas: ${totalInseridos} (vencidos=${inseridosVencidos}, a_vencer=${inseridosAVencer})`,
    );
  } catch (err) {
    console.error("[CRON] Erro ao processar notificacoes:", err);
  }
}

function iniciarJobNotificacoesVencimento() {
  if (!cron.validate(notifyCronSchedule)) {
    console.warn(
      `[CRON] Expressao invalida em CRON_NOTIFY_SCHEDULE: "${notifyCronSchedule}". Job nao iniciado.`,
    );
    return;
  }

  cron.schedule(notifyCronSchedule, () => {
    executarJobNotificacoesVencimento();
  });

  console.log(
    `[CRON] Job de notificacoes configurado para "${notifyCronSchedule}" (janela=${notifyDaysAhead} dias)`,
  );

  if (notifyRunOnStart) {
    executarJobNotificacoesVencimento();
  }
}

module.exports = {
  iniciarJobNotificacoesVencimento,
  executarJobNotificacoesVencimento,
};
