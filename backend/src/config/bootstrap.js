const bcrypt = require("bcryptjs");
const pool = require("../config/db");
const isProduction = process.env.NODE_ENV === "production";

async function ensureAuthBootstrap() {
  console.log("[Bootstrap] Iniciando a verificação de usuário RH padrão.");

  try {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS usuarios_rh (
          id SERIAL PRIMARY KEY,
          nome VARCHAR(120) NOT NULL,
          email VARCHAR(160) NOT NULL UNIQUE,
          senha_hash VARCHAR(255) NOT NULL,
          ativo BOOLEAN DEFAULT TRUE,
          created_at TIMESTAMP DEFAULT NOW()
        )
      `);
    console.log("[Bootstrap] Tabela 'usuarios_rh' garantida.");

    const existing = await pool.query("SELECT id, email FROM usuarios_rh");
    console.log(
      `[Bootstrap] Verificação de usuários existentes encontrou ${existing.rows.length} registro(s).`,
    );

    if (existing.rows.length === 0) {
      console.log(
        "[Bootstrap] Nenhum usuário RH encontrado. Criando usuário padrão.",
      );
      const defaultName = process.env.RH_DEFAULT_NOME || "RH Principal";
      const defaultEmail = process.env.RH_DEFAULT_EMAIL || "rh@empresa.com";
      const providedPassword = process.env.RH_DEFAULT_PASSWORD;

      if (
        isProduction &&
        (!providedPassword || providedPassword === "123456")
      ) {
        throw new Error(
          "RH_DEFAULT_PASSWORD deve ser definido com valor forte em producao.",
        );
      }
      const defaultPassword = providedPassword || "123456";
      const senhaHash = await bcrypt.hash(defaultPassword, 10);

      const insertResult = await pool.query(
        `INSERT INTO usuarios_rh (nome, email, senha_hash, ativo)
           VALUES ($1, $2, $3, true) RETURNING id`,
        [defaultName, defaultEmail, senhaHash],
      );

      if (insertResult.rowCount > 0) {
        console.log(
          `[Bootstrap] Sucesso! Usuário RH inicial criado com ID: ${insertResult.rows[0].id} e email: ${defaultEmail}`,
        );
      } else {
        console.error(
          "[Bootstrap] ERRO: A inserção do usuário padrão falhou, mas não gerou exceção.",
        );
      }
    } else {
      console.log(
        `[Bootstrap] Usuário(s) já existe(m). O primeiro usuário encontrado é: ${existing.rows[0].email}. Nenhum usuário novo foi criado.`,
      );
    }
  } catch (error) {
    console.error(
      "[Bootstrap] ERRO CRÍTICO durante o processo de bootstrap de autenticação:",
      error,
    );
    // Lançar o erro para que o processo de inicialização do servidor pare
    throw error;
  }
}

async function waitForDatabase() {
  const maxRetries = 10;
  const retryInterval = 2000;

  for (let attempt = 1; attempt <= maxRetries; attempt += 1) {
    try {
      const client = await pool.connect();
      console.log("Conectado ao banco de dados com sucesso!");
      client.release();
      return true;
    } catch (err) {
      console.log(
        `Tentativa ${attempt} de ${maxRetries}: banco de dados nao esta pronto. Aguardando ${retryInterval / 1000}s...`,
      );

      if (attempt === maxRetries) {
        throw new Error(
          "Nao foi possivel conectar ao banco de dados apos varias tentativas.",
        );
      }

      await new Promise((resolve) => setTimeout(resolve, retryInterval));
    }
  }

  return false;
}

async function ensureSchemaUpdates() {
  try {
    await pool.query(
      `ALTER TABLE empresas ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP DEFAULT NULL`,
    );
    await pool.query(
      `ALTER TABLE colaboradores ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP DEFAULT NULL`,
    );
    await pool.query(
      `ALTER TABLE vinculos ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP DEFAULT NULL`,
    );
    await pool.query(
      `ALTER TABLE documentos ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP DEFAULT NULL`,
    );

    // Opcional: indexar a coluna deleted_at para acelerar as consultas
    await pool.query(
      `CREATE INDEX IF NOT EXISTS idx_empresas_deleted_at ON empresas(deleted_at)`,
    );
    await pool.query(
      `CREATE INDEX IF NOT EXISTS idx_colab_deleted_at ON colaboradores(deleted_at)`,
    );

    await pool.query(`
      CREATE TABLE IF NOT EXISTS audit_logs (
        id SERIAL PRIMARY KEY,
        user_id INTEGER,
        user_email VARCHAR(160),
        user_nome VARCHAR(120),
        action VARCHAR(60) NOT NULL,
        entity_type VARCHAR(60) NOT NULL,
        entity_id VARCHAR(80),
        metadata JSONB,
        ip_address VARCHAR(64),
        user_agent VARCHAR(255),
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);

    await pool.query(
      `CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC)`,
    );
    await pool.query(
      `CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id)`,
    );
    await pool.query(
      `CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action)`,
    );
  } catch (err) {
    console.error("Erro ao aplicar atualizacoes de schema (Soft Delete):", err);
  }
}

module.exports = {
  ensureAuthBootstrap,
  waitForDatabase,
  ensureSchemaUpdates,
};
