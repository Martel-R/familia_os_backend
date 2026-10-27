-- ====================================================================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS (DDL) COM SCHEMA DEDICADO
-- Banco: PostgreSQL (Supabase Remoto)
-- Schema: familialm
-- Padrão de Nomenclatura: pt-BR
-- ====================================================================================

-- 1. Criação do Schema Dedicado
CREATE SCHEMA IF NOT EXISTS familialm;

-- Garantir que a extensão uuid-ossp esteja disponível
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Conceder permissões para que os papéis padrões do Supabase possam acessar o novo schema
GRANT USAGE ON SCHEMA familialm TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA familialm GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA familialm GRANT ALL ON ROUTINES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA familialm GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- ====================================================================================
-- 0. USUÁRIOS E PERFIS
-- (Link direto com o Supabase Auth)
-- ====================================================================================
DO $$ BEGIN
    CREATE TYPE familialm.tipo_perfil AS ENUM ('pai_admin', 'filho_membro', 'cuidador');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS familialm.usuarios (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nome VARCHAR(255) NOT NULL,
    perfil familialm.tipo_perfil NOT NULL,
    saldo_moedas INT DEFAULT 0,
    avatar_url TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ====================================================================================
-- 1. FINANÇAS FAMILIARES
-- ====================================================================================
DO $$ BEGIN
    CREATE TYPE familialm.tipo_transacao AS ENUM ('receita', 'despesa_fixa', 'despesa_variavel', 'assinatura');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE familialm.status_pagamento AS ENUM ('pendente', 'pago', 'atrasado');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS familialm.categorias_financeiras (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome VARCHAR(100) NOT NULL,
    icone VARCHAR(50),
    cor VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS familialm.transacoes_financeiras (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES familialm.usuarios(id),
    categoria_id UUID REFERENCES familialm.categorias_financeiras(id),
    tipo familialm.tipo_transacao NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    data_vencimento DATE NOT NULL,
    data_pagamento DATE,
    status familialm.status_pagamento DEFAULT 'pendente',
    observacoes TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS familialm.cofrinhos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome VARCHAR(255) NOT NULL,
    meta_valor DECIMAL(10,2) NOT NULL,
    saldo_atual DECIMAL(10,2) DEFAULT 0.00,
    data_limite DATE,
    icone VARCHAR(50)
);

-- ====================================================================================
-- 2. PLANEJAMENTO DE EVENTOS & COTAÇÕES
-- ====================================================================================
CREATE TABLE IF NOT EXISTS familialm.eventos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome VARCHAR(255) NOT NULL,
    data_evento TIMESTAMP WITH TIME ZONE NOT NULL,
    descricao TEXT,
    orcamento_estimado DECIMAL(10,2),
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

DO $$ BEGIN
    CREATE TYPE familialm.status_rsvp AS ENUM ('pendente', 'confirmado', 'recusado');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS familialm.convidados (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    evento_id UUID REFERENCES familialm.eventos(id) ON DELETE CASCADE,
    nome VARCHAR(255) NOT NULL,
    telefone VARCHAR(20),
    status familialm.status_rsvp DEFAULT 'pendente',
    restricoes_alimentares TEXT
);

DO $$ BEGIN
    CREATE TYPE familialm.status_cotacao AS ENUM ('em_analise', 'aprovada', 'rejeitada');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS familialm.cotacoes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    evento_id UUID REFERENCES familialm.eventos(id) ON DELETE CASCADE,
    item_ou_servico VARCHAR(255) NOT NULL,
    fornecedor VARCHAR(255) NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    status familialm.status_cotacao DEFAULT 'em_analise',
    link_anexo TEXT,
    observacoes TEXT
);

-- ====================================================================================
-- 3. COFRE DE SENHAS
-- ====================================================================================
DO $$ BEGIN
    CREATE TYPE familialm.nivel_cofre AS ENUM ('master', 'compartilhado');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS familialm.cofre_credenciais (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo VARCHAR(255) NOT NULL,
    nivel familialm.nivel_cofre NOT NULL,
    login_usuario VARCHAR(255),
    senha_criptografada TEXT NOT NULL,
    url_acesso TEXT,
    notas_seguras TEXT,
    criado_por UUID REFERENCES familialm.usuarios(id)
);

-- ====================================================================================
-- 4. ROTINAS E GAMIFICAÇÃO
-- ====================================================================================
DO $$ BEGIN
    CREATE TYPE familialm.recorrencia_tarefa AS ENUM ('unica', 'diaria', 'semanal', 'mensal');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS familialm.tarefas_rotinas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo VARCHAR(255) NOT NULL,
    responsavel_id UUID REFERENCES familialm.usuarios(id),
    recorrencia familialm.recorrencia_tarefa NOT NULL,
    moedas_recompensa INT DEFAULT 0,
    data_limite TIMESTAMP WITH TIME ZONE,
    esta_concluida BOOLEAN DEFAULT FALSE,
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS familialm.loja_privilegios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo VARCHAR(255) NOT NULL,
    custo_moedas INT NOT NULL,
    icone VARCHAR(50),
    estoque_disponivel INT
);

-- ====================================================================================
-- 5. INVENTÁRIO, MANUTENÇÕES E CONTATOS
-- ====================================================================================
CREATE TABLE IF NOT EXISTS familialm.agenda_contatos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome VARCHAR(255) NOT NULL,
    especialidade VARCHAR(100),
    telefone VARCHAR(20) NOT NULL,
    eh_emergencia BOOLEAN DEFAULT FALSE,
    observacoes TEXT
);

CREATE TABLE IF NOT EXISTS familialm.inventario_itens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome VARCHAR(255) NOT NULL,
    localizacao VARCHAR(255) NOT NULL,
    quantidade INT DEFAULT 1,
    data_compra DATE,
    data_fim_garantia DATE,
    caminho_nota_fiscal TEXT,
    caminho_manual TEXT
);

CREATE TABLE IF NOT EXISTS familialm.historico_manutencoes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_id UUID REFERENCES familialm.inventario_itens(id) ON DELETE SET NULL,
    prestador_id UUID REFERENCES familialm.agenda_contatos(id) ON DELETE SET NULL,
    descricao TEXT NOT NULL,
    data_servico DATE NOT NULL,
    custo DECIMAL(10,2),
    data_proxima_manutencao DATE
);

-- ====================================================================================
-- 6. SAÚDE INTEGRAL
-- ====================================================================================
CREATE TABLE IF NOT EXISTS familialm.saude_checkins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES familialm.usuarios(id) ON DELETE CASCADE,
    nivel_humor INT CHECK (nivel_humor BETWEEN 1 AND 5),
    notas_diario TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS familialm.saude_fichas_medicas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES familialm.usuarios(id) ON DELETE CASCADE,
    tipo_sanguineo VARCHAR(5),
    alergias TEXT,
    medicamentos_uso_continuo TEXT,
    numero_plano_saude VARCHAR(50)
);

-- ====================================================================================
-- 7. COMPRAS INTELIGENTES (OCR / IA)
-- ====================================================================================
CREATE TABLE IF NOT EXISTS familialm.compras_recibos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fornecedor VARCHAR(255),
    data_compra DATE,
    valor_total DECIMAL(10,2),
    caminho_imagem_recibo TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS familialm.compras_itens_extraidos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recibo_id UUID REFERENCES familialm.compras_recibos(id) ON DELETE CASCADE,
    nome_produto VARCHAR(255) NOT NULL,
    quantidade DECIMAL(10,3) DEFAULT 1.000,
    valor_unitario DECIMAL(10,2) NOT NULL,
    categoria_sugerida VARCHAR(100)
);

-- ====================================================================================
-- 8. MURAL DE CONQUISTAS E ÁLBUM
-- ====================================================================================
CREATE TABLE IF NOT EXISTS familialm.mural_conquistas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    usuario_id UUID REFERENCES familialm.usuarios(id) ON DELETE SET NULL,
    data_conquista DATE NOT NULL,
    caminho_foto TEXT
);

-- Garantir concessões nas tabelas recém criadas
GRANT ALL ON ALL TABLES IN SCHEMA familialm TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA familialm TO anon, authenticated, service_role;

-- ====================================================================================
-- 9. BUCKETS DE STORAGE (Prefixados para isolamento)
-- ====================================================================================
INSERT INTO storage.buckets (id, name, public) VALUES
    ('familia-os-recibos', 'familia-os-recibos', false),
    ('familia-os-documentos', 'familia-os-documentos', false),
    ('familia-os-fotos', 'familia-os-fotos', true)
ON CONFLICT (id) DO NOTHING;

DO $$ 
BEGIN
    CREATE POLICY "Familia OS: Acesso aos buckets do projeto"
    ON storage.objects
    FOR ALL
    TO anon, authenticated
    USING (bucket_id IN ('familia-os-recibos', 'familia-os-documentos', 'familia-os-fotos'))
    WITH CHECK (bucket_id IN ('familia-os-recibos', 'familia-os-documentos', 'familia-os-fotos'));
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

