-- =====================================================
-- Instagram Posts Schema para RAG com pgvector
-- Compatível com Gemini Embeddings (768 dimensões)
-- =====================================================

-- Extensão necessária para vetores
CREATE EXTENSION IF NOT EXISTS vector;

-- Tabela principal de posts do Instagram
CREATE TABLE IF NOT EXISTS instagram_posts (
  id SERIAL PRIMARY KEY,
  post_id VARCHAR(255) UNIQUE NOT NULL,
  url_post TEXT,
  url_imagem TEXT,
  legenda TEXT,
  tipo_conteudo VARCHAR(50),
  data_publicacao TIMESTAMP,
  embedding VECTOR(768),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE UNIQUE INDEX IF NOT EXISTS ux_instagram_posts_post_id
ON instagram_posts(post_id);

CREATE INDEX IF NOT EXISTS ix_instagram_posts_data_publicacao
ON instagram_posts(data_publicacao DESC);

-- Índice de texto completo para buscas por legenda
CREATE INDEX IF NOT EXISTS ix_instagram_posts_legenda_fts
ON instagram_posts
USING GIN (to_tsvector('portuguese', coalesce(legenda,'')));

-- Índice vetorial para consultas semânticas (RAG)
-- IVFFlat é mais rápido para grandes volumes de dados
CREATE INDEX IF NOT EXISTS ix_instagram_posts_embedding_ivfflat
ON instagram_posts
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Trigger para atualizar timestamp
CREATE OR REPLACE FUNCTION update_instagram_posts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_instagram_posts_updated_at
    BEFORE UPDATE ON instagram_posts
    FOR EACH ROW
    EXECUTE FUNCTION update_instagram_posts_updated_at();

-- =====================================================
-- Exemplos de Consulta para o Assistente Virtual
-- =====================================================

-- Busca semântica (RAG) - encontrar posts mais relevantes
SELECT
  post_id,
  legenda,
  url_post,
  (embedding <=> '[0.0123, -0.8831, 0.4421]') AS distance
FROM instagram_posts
WHERE embedding IS NOT NULL
ORDER BY embedding <=> '[0.0123, -0.8831, 0.4421]'
LIMIT 5;

-- Busca híbrida (texto + vetor)
SELECT
  post_id,
  legenda,
  url_post,
  data_publicacao,
  (embedding <=> '[0.0123, -0.8831, 0.4421]') AS vector_distance,
  ts_rank(to_tsvector('portuguese', coalesce(legenda,'')), plainto_tsquery('portuguese', 'balão')) AS text_rank
FROM instagram_posts
WHERE embedding IS NOT NULL
  AND to_tsvector('portuguese', coalesce(legenda,'')) @@ plainto_tsquery('portuguese', 'balão')
ORDER BY (embedding <=> '[0.0123, -0.8831, 0.4421]') ASC, text_rank DESC
LIMIT 10;

-- Estatísticas da base
SELECT 
  COUNT(*) as total_posts,
  COUNT(embedding) as posts_with_embedding,
  COUNT(*) - COUNT(embedding) as posts_without_embedding,
  MAX(data_publicacao) as latest_post,
  MIN(data_publicacao) as oldest_post
FROM instagram_posts;

-- Posts recentes sem embedding (para reprocessamento)
SELECT post_id, legenda, data_publicacao
FROM instagram_posts 
WHERE embedding IS NULL 
  AND data_publicacao > CURRENT_DATE - INTERVAL '7 days'
ORDER BY data_publicacao DESC;
