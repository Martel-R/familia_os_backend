-- ==========================================
-- Módulo Saúde: Medicamentos
-- ==========================================
CREATE TABLE IF NOT EXISTS familialm.saude_medicamentos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES familialm.usuarios(id) ON DELETE CASCADE,
    nome_remedio VARCHAR(255) NOT NULL,
    dosagem VARCHAR(100) NOT NULL,
    horario VARCHAR(50) NOT NULL, -- Ex: "08:00 e 20:00"
    foi_tomado_hoje BOOLEAN DEFAULT FALSE,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==========================================
-- Módulo Inventário: Histórico de Manutenções
-- ==========================================
CREATE TABLE IF NOT EXISTS familialm.historico_manutencoes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_id UUID REFERENCES familialm.inventario_itens(id) ON DELETE CASCADE,
    prestador_id UUID REFERENCES familialm.agenda_contatos(id) ON DELETE SET NULL,
    descricao TEXT NOT NULL,
    data_servico DATE NOT NULL,
    custo DECIMAL(10,2),
    data_proxima_manutencao DATE,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==========================================
-- Módulo Mural de Conquistas e Fotos
-- ==========================================
CREATE TABLE IF NOT EXISTS familialm.mural_conquistas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    usuario_id UUID REFERENCES familialm.usuarios(id) ON DELETE SET NULL,
    data_conquista DATE NOT NULL,
    caminho_foto TEXT,
    total_reacoes INT DEFAULT 0,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS familialm.mural_fotos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo VARCHAR(255) NOT NULL,
    autor_id UUID REFERENCES familialm.usuarios(id) ON DELETE CASCADE,
    eh_privado BOOLEAN DEFAULT FALSE,
    caminho_imagem TEXT NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==========================================
-- Módulo Compras Inteligentes
-- ==========================================
CREATE TABLE IF NOT EXISTS familialm.compras_recibos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fornecedor VARCHAR(255),
    data_compra DATE,
    valor_total DECIMAL(10,2) DEFAULT 0.0,
    caminho_imagem_recibo TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS familialm.compras_itens_extraidos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recibo_id UUID REFERENCES familialm.compras_recibos(id) ON DELETE CASCADE,
    nome_produto VARCHAR(255) NOT NULL,
    quantidade DECIMAL(10,3) DEFAULT 1.0,
    valor_unitario DECIMAL(10,2) NOT NULL,
    categoria_sugerida VARCHAR(100),
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==========================================
-- Módulo Cofre (Ajuste para WiFi)
-- ==========================================
-- O Wi-Fi familiar pode ser um registro específico em cofre_credenciais,
-- ou podemos criar uma tabela de configurações. Como a paridade indica
-- um modal para a rede Wi-Fi, vamos criar uma tabela leve de configs.
CREATE TABLE IF NOT EXISTS familialm.configuracoes_casa (
    id VARCHAR(50) PRIMARY KEY, -- ex: 'WIFI_PRINCIPAL'
    valor JSONB NOT NULL,
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

GRANT ALL ON ALL TABLES IN SCHEMA familialm TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA familialm TO anon, authenticated, service_role;
NOTIFY pgrst, 'reload schema';
