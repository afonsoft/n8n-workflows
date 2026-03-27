# 📥 Instagram → PostgreSQL → RAG (Gemini) - Arteria Festas

Pipeline completo para ingestão de posts do Instagram com embeddings vetoriais para uso no assistente virtual via RAG.

## 🏗️ Arquitetura

```
Instagram Graph API
   ↓
n8n Workflows
   ↓
PostgreSQL + pgvector
   ↓
Gemini Embeddings (768)
   ↓
Assistente Virtual (RAG)
```

## 📁 Arquivos do Projeto

### Workflows n8n
- **`instagram-import-minha-conta.json`** - Importação posts da sua conta
- **`instagram-import-hashtag-arteriafestas.json`** - Importação por hashtag #arteriafestas
- **`WhatsApp Chat IA - Arteria Festas.json`** - Workflow existente do assistente

### Banco de Dados
- **`sql-instagram-posts-schema.sql`** - Schema completo da tabela `instagram_posts`

## 🚀 Configuração Rápida

### 1. Pré-requisitos
- n8n (self-hosted ou cloud)
- PostgreSQL com extensão `pgvector`
- Instagram Graph API credentials
- Google Gemini API key

### 2. Instalar Community Node
```bash
# No n8n, instalar via UI:
# Community Nodes → @mookielianhd/n8n-nodes-instagram
```

### 3. Configurar Credenciais no n8n
- **PostgreSQL**: mesma credencial usada no workflow existente (`nNWOoSo66DYfDpAF`)
- **Google Gemini**: mesma credencial usada no workflow existente (`eJJhTvSw2avKW11x`)
- **Instagram Access Token**: nova credencial para Graph API

### 4. Criar Tabela no PostgreSQL
```bash
psql -U seu_usuario -d seu_banco -f sql-instagram-posts-schema.sql
```

### 5. Importar Workflows
1. No n8n: **Import from file**
2. Selecionar os arquivos JSON
3. Ativar os workflows

## 🔧 Configuração dos Workflows

### Workflow 1: Minha Conta
- **Agendamento**: A cada 4 horas
- **Fonte**: Seus próprios posts
- **Limite**: 25 posts por execução

### Workflow 2: Hashtag #arteriafestas
- **Agendamento**: A cada 6 horas
- **Fonte**: Posts com hashtag `#arteriafestas`
- **Limite**: 25 posts por execução

## 📊 Estrutura da Tabela

```sql
instagram_posts (
  id SERIAL PRIMARY KEY,
  post_id VARCHAR(255) UNIQUE,           -- ID do Instagram
  url_post TEXT,                          -- Link do post
  url_imagem TEXT,                        -- URL da imagem
  legenda TEXT,                           -- Caption/descrição
  tipo_conteudo VARCHAR(50),              -- IMAGE, CAROUSEL_ALBUM, etc
  data_publicacao TIMESTAMP,              -- Data do post
  embedding VECTOR(768),                  -- Embedding Gemini
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
)
```

## 🧠 Uso no Assistente Virtual

O workflow `WhatsApp Chat IA - Arteria Festas.json` já está configurado para usar a base vetorial através do node **Instagram Vector Store**.

### Exemplo de consulta RAG:
```sql
SELECT post_id, legenda, url_post, 
       (embedding <=> $1) AS distance
FROM instagram_posts 
WHERE embedding IS NOT NULL
ORDER BY embedding <=> $1 
LIMIT 5;
```

## 🔍 Monitoramento

### Verificar status da ingestão:
```sql
SELECT 
  COUNT(*) as total_posts,
  COUNT(embedding) as posts_com_embedding,
  MAX(data_publicacao) as post_mais_recente
FROM instagram_posts;
```

### Posts sem embedding (para reprocessar):
```sql
SELECT post_id, legenda, data_publicacao
FROM instagram_posts 
WHERE embedding IS NULL 
ORDER BY data_publicacao DESC;
```

## ⚡ Performance

- **Índice vetorial**: IVFFlat com 100 lists
- **Busca semântica**: O(log n) com cosine similarity
- **Batch processing**: 5 posts por lote para evitar rate limits

## 🔒 Segurança

- Tokens armazenados como credenciais no n8n
- UPSERT idempotente (sem duplicações)
- Processamento em lotes controlado

## 🚨 Troubleshooting

### Instagram API Rate Limit
- Reduzir `limit` e `batchSize` nos workflows
- Aumentar intervalo de agendamento

### Embeddings não gerados
- Verificar quota da API Gemini
- Conferir credenciais no n8n

### Performance lenta
- Recriar índice vetorial: `REINDEX INDEX ix_instagram_posts_embedding_ivfflat;`
- Aumentar `lists` no índice para mais dados

## 📈 Extensões Futuras

- **OCR de imagens** para extrair texto
- **Extração de preços** e vincular com `produtos_baloes`
- **Webhooks** para ingestão em tempo real
- **Dashboards** de monitoramento

---

## ✅ Checklist de Implementação

- [ ] Instalar community node do Instagram
- [ ] Configurar credenciais Instagram API
- [ ] Executar script SQL da tabela
- [ ] Importar workflows
- [ ] Testar execução manual
- [ ] Ativar agendamentos
- [ ] Verificar integração com assistente existente

**Status**: Pronto para produção 🎉
