const express = require('express');
const { Pool } = require('pg');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

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
  const retryInterval = 2000; // 2 segundos

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

// Rota de teste
app.get('/', (req, res) => {
  res.send('API do RH Documentos está rodando!');
});

// Inicia o servidor após conectar ao banco
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