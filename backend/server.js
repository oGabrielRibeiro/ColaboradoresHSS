const express = require('express');
const { Pool } = require('pg');
const dotenv = require('dotenv');
const cors = require('cors');

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(cors());

// Configuração do pool de conexão
const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  port: 5432,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
});

// Função para aguardar o banco de dados ficar pronto
async function waitForDatabase() {
  const maxRetries = 10;
  const retryInterval = 2000;

  for (let i = 1; i <= maxRetries; i++) {
    try {
      const client = await pool.connect();
      console.log('Conectado ao banco de dados com sucesso!');
      client.release();
      return true;
    } catch (err) {
      console.log(`Tentativa ${i} de ${maxRetries}: banco de dados não está pronto. Aguardando ${retryInterval/1000}s...`);
      if (i === maxRetries) {
        throw new Error('Não foi possível conectar ao banco de dados após várias tentativas.');
      }
      await new Promise(resolve => setTimeout(resolve, retryInterval));
    }
  }
}

// ==================== ROTAS ====================

// Rota de teste
app.get('/', (req, res) => {
  res.send('API do RH Documentos está rodando!');
});

// --- Empresas ---
app.get('/empresas', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM empresas ORDER BY nome');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar empresas' });
  }
});

app.post('/empresas', async (req, res) => {
  const { nome, cnpj, contato } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO empresas (nome, cnpj, contato) VALUES ($1, $2, $3) RETURNING *',
      [nome, cnpj, contato]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao criar empresa' });
  }
});

// --- Colaboradores ---
app.get('/colaboradores', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM colaboradores ORDER BY nome');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar colaboradores' });
  }
});

app.post('/colaboradores', async (req, res) => {
  const { nome, email, telefone } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO colaboradores (nome, email, telefone) VALUES ($1, $2, $3) RETURNING *',
      [nome, email, telefone]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao criar colaborador' });
  }
});

// --- Tipos de Documento ---
app.get('/tipos-documento', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM tipos_documento ORDER BY nome');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar tipos de documento' });
  }
});

// --- Documentos ---
app.get('/documentos', async (req, res) => {
  const { colaborador_id } = req.query;
  try {
    let query = 'SELECT * FROM documentos';
    const params = [];
    if (colaborador_id) {
      query += ' WHERE colaborador_id = $1';
      params.push(colaborador_id);
    }
    query += ' ORDER BY data_validade';
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar documentos' });
  }
});

app.post('/documentos', async (req, res) => {
  const { colaborador_id, empresa_id, tipo_documento_id, data_validade, arquivo_nome, arquivo_path, observacoes } = req.body;
  try {
    // Inserir novo documento
    const result = await pool.query(
      `INSERT INTO documentos 
       (colaborador_id, empresa_id, tipo_documento_id, data_validade, arquivo_nome, arquivo_path, observacoes) 
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [colaborador_id, empresa_id || null, tipo_documento_id, data_validade, arquivo_nome, arquivo_path, observacoes]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao criar documento' });
  }
});

// --- Vínculos (colaborador x empresa) ---
app.get('/vinculos', async (req, res) => {
  const { colaborador_id } = req.query;
  try {
    let query = 'SELECT * FROM vinculos';
    const params = [];
    if (colaborador_id) {
      query += ' WHERE colaborador_id = $1';
      params.push(colaborador_id);
    }
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar vínculos' });
  }
});

app.post('/vinculos', async (req, res) => {
  const { colaborador_id, empresa_id } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO vinculos (colaborador_id, empresa_id) VALUES ($1, $2) RETURNING *',
      [colaborador_id, empresa_id]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao criar vínculo' });
  }
});

// Rota para resumo do dashboard
app.get('/dashboard/resumo', async (req, res) => {
  try {
    // Total de colaboradores
    const colaboradores = await pool.query('SELECT COUNT(*) FROM colaboradores');
    const totalColaboradores = parseInt(colaboradores.rows[0].count);

    // Total de empresas
    const empresas = await pool.query('SELECT COUNT(*) FROM empresas');
    const totalEmpresas = parseInt(empresas.rows[0].count);

    // Documentos vencidos (data_validade < hoje)
    const vencidos = await pool.query(
      "SELECT COUNT(*) FROM documentos WHERE data_validade < CURRENT_DATE AND ativo = true"
    );
    const documentosVencidos = parseInt(vencidos.rows[0].count);

    // Documentos a vencer nos próximos 30 dias
    const aVencer = await pool.query(
      "SELECT COUNT(*) FROM documentos WHERE data_validade BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days' AND ativo = true"
    );
    const documentosAVencer = parseInt(aVencer.rows[0].count);

    // Documentos OK (válidos por mais de 30 dias)
    const ok = await pool.query(
      "SELECT COUNT(*) FROM documentos WHERE data_validade > CURRENT_DATE + INTERVAL '30 days' AND ativo = true"
    );
    const documentosOK = parseInt(ok.rows[0].count);

    res.json({
      totalColaboradores,
      totalEmpresas,
      documentosVencidos,
      documentosAVencer,
      documentosOK,
    });
  } catch (err) {
    console.error('Erro no dashboard:', err);
    res.status(500).json({ error: 'Erro ao carregar resumo' });
  }
});

// ==================== INICIALIZAÇÃO ====================
async function startServer() {
  try {
    await waitForDatabase();
    app.listen(port, () => {
      console.log(`Servidor rodando na porta ${port}`);
    });
  } catch (err) {
    console.error('Erro fatal:', err.message);
    process.exit(1);
  }
}

startServer();