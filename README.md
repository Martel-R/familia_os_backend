# 🗄️ Familia OS - Backend (Supabase)

Backend como serviço (BaaS) para o ecossistema **Familia OS**, contendo as definições de schema, migrations e configurações do Supabase.

## 📁 Estrutura
- `schema_remoto.sql`: Script DDL completo com o schema dedicado `familialm`, tipos (enums), tabelas e permissões de acesso (`GRANT`).
- `supabase/`: Configuração do Supabase CLI e migrações versionadas.

## 🚀 Como Aplicar no Servidor Remoto
1. Acesse o Dashboard do seu Supabase.
2. Navegue até o **SQL Editor**.
3. Execute o conteúdo de `schema_remoto.sql`.
