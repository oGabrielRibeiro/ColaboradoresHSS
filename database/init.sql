CREATE TABLE IF NOT EXISTS empresas (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    cnpj VARCHAR(20),
    contato VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS colaboradores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    email VARCHAR(100),
    telefone VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS usuarios_rh (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    email VARCHAR(160) NOT NULL UNIQUE,
    senha_hash VARCHAR(255) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vinculos (
    id SERIAL PRIMARY KEY,
    colaborador_id INTEGER REFERENCES colaboradores(id) ON DELETE CASCADE,
    empresa_id INTEGER REFERENCES empresas(id) ON DELETE CASCADE,
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(colaborador_id, empresa_id)
);

CREATE INDEX IF NOT EXISTS idx_vinculos_colaborador_id ON vinculos(colaborador_id);
CREATE INDEX IF NOT EXISTS idx_vinculos_empresa_id ON vinculos(empresa_id);

CREATE TABLE IF NOT EXISTS tipos_documento (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT,
    tipo VARCHAR(20) DEFAULT 'empresa'
);

CREATE TABLE IF NOT EXISTS documentos (
    id SERIAL PRIMARY KEY,
    colaborador_id INTEGER REFERENCES colaboradores(id) ON DELETE CASCADE,
    empresa_id INTEGER REFERENCES empresas(id) ON DELETE CASCADE,
    tipo_documento_id INTEGER REFERENCES tipos_documento(id),
    data_validade DATE NOT NULL,
    arquivo_nome VARCHAR(255),
    arquivo_path VARCHAR(500),
    observacoes TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    versao INTEGER DEFAULT 1,
    substituido_por_id INTEGER REFERENCES documentos(id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documentos_colaborador_id ON documentos(colaborador_id);
CREATE INDEX IF NOT EXISTS idx_documentos_empresa_id ON documentos(empresa_id);
CREATE INDEX IF NOT EXISTS idx_documentos_tipo_documento_id ON documentos(tipo_documento_id);

CREATE TABLE IF NOT EXISTS notificacoes_enviadas (
    id SERIAL PRIMARY KEY,
    documento_id INTEGER REFERENCES documentos(id),
    tipo_alerta VARCHAR(20),
    enviado_em TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notificacoes_documento_id ON notificacoes_enviadas(documento_id);

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
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);

INSERT INTO tipos_documento (nome, tipo) VALUES 
('RG', 'pessoal'),
('CPF', 'pessoal'),
('CNH', 'pessoal'),
('Carteira de Trabalho', 'pessoal'),
('ASO', 'empresa'),
('APR', 'empresa'),
('Integração', 'empresa'),
('Treinamento', 'empresa')
ON CONFLICT (nome) DO NOTHING;
