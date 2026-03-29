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
- **`instagram-import-conta-publica-terceiro.json`** - Importação de conta pública de terceiros
- **`instagram-import-structured-parser.json`** - Importação com parser estruturado avançado
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
- **Instagram OAuth2 API**: nova credencial para Graph API (substituir `COLOCAR_ID_CREDENTIAL`)

### 4. Criar Tabela no PostgreSQL
```bash
psql -U seu_usuario -d seu_banco -f sql-instagram-posts-schema.sql
```

### 5. Importar Workflows
1. No n8n: **Import from file**
2. Selecionar os arquivos JSON
3. Ativar os workflows
4. **IMPORTANTE**: Substituir `COLOCAR_ID_CREDENTIAL` pelo ID real da credencial Instagram

## 🔧 Configuração dos Workflows

### Workflow 1: Minha Conta
- **Agendamento**: A cada 4 horas
- **Fonte**: Seus próprios posts
- **Limite**: 25 posts por execução

### Workflow 2: Hashtag #arteriafestas
- **Agendamento**: A cada 6 horas
- **Fonte**: Posts com hashtag `#arteriafestas`
- **Limite**: 25 posts por execução

### Workflow 3: Conta Pública de Terceiros
- **Agendamento**: A cada 6 horas
- **Fonte**: Posts de conta pública específica
- **Limite**: 25 posts por execução
- **Configuração**: Alterar `NOME_DE_USUARIO_ALVO` no node Instagram
- **Parâmetros**: `resource: "IG User"`, `operation: "Get Media"`

### Workflow 4: Structured Parser (Avançado)
- **Agendamento**: A cada 6 horas
- **Fonte**: Seus próprios posts com parsing avançado
- **Limite**: 25 posts por execução
- **Recursos**: Code node para estruturar dados
- **Dados Enriquecidos**: Métricas, metadados, timestamp de captura
- **Parâmetros**: `resource: "IG User"`, `operation: "Get Media"` + Code node

## �️ Configuração Técnica dos Nodes Instagram

### Parâmetros Corrigidos
Todos os workflows foram atualizados com os parâmetros corretos do nó `@mookielianhd/n8n-nodes-instagram`:

```json
{
  "resource": "IG User",           // Antes: "user"
  "operation": "Get Media",       // Antes: "listMedia"
  "node": "me" ou "username",   // Antes: "userId"
  "limit": 25
}
```

### Para Hashtags
```json
{
  "resource": "IG Hashtag",        // Antes: "hashtag"
  "operation": "Get Media",       // Antes: "search"
  "hashtag": "arteriafestas",
  "limit": 25
}
```

### Credenciais
- **Tipo**: `instagramOAuth2Api`
- **Placeholder**: `COLOCAR_ID_CREDENTIAL` (substituir pelo ID real)
- **Scopes necessários**: `instagram_basic`, `pages_show_list`, `instagram_content_publish`, `pages_read_engagement`

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
  conta_origem VARCHAR(100),              -- @username da conta
  nome_perfil TEXT,                       -- Nome completo do perfil
  embedding VECTOR(768),                  -- Embedding Gemini
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
)
```

## 🔄 Estrutura de Dados do Structured Parser

O workflow `instagram-import-structured-parser.json` utiliza um Code node para enriquecer os dados:

```json
{
  "post_id": "id_do_post",
  "url_post": "permalink",
  "url_imagem": "media_url",
  "legenda": "caption",
  "tipo_conteudo": "media_type",
  "data_publicacao": "timestamp",
  "conta_origem": "@username",
  "nome_perfil": "Nome completo",
  "metricas": {
    "likes": 150,
    "comentarios": 23
  },
  "midia": {
    "tipo": "IMAGE",
    "url": "media_url",
    "thumbnail": "thumbnail_url"
  },
  "metadata": {
    "timestamp_captura": "2025-03-28T23:40:00Z",
    "fonte": "instagram_graph_api",
    "versao_parser": "1.0"
  }
}
```

### Vantagens do Parser Estruturado
- ✅ **Dados consistentes**: Formato padronizado para todos os posts
- ✅ **Métricas incluídas**: Likes e comentários capturados
- ✅ **Metadados ricos**: Informações de processamento e versão
- ✅ **Facilidade de análise**: Estrutura otimizada para consultas
- ✅ **Rastreabilidade**: Timestamp de captura e fonte

## 🧠 Uso no Assistente Virtual

O workflow `WhatsApp Chat IA - Arteria Festas.json` já está configurado para usar a base vetorial através do node **Instagram Vector Store**.

### Exemplo de consulta RAG:
```sql
SELECT post_id, legenda, url_post, conta_origem,
       (embedding <=> $1) AS distance
FROM instagram_posts 
WHERE embedding IS NOT NULL
ORDER BY embedding <=> $1 
LIMIT 5;
```

### Busca por conta específica:
```sql
SELECT post_id, legenda, url_post, data_publicacao
FROM instagram_posts 
WHERE conta_origem = '@usuario_especifico'
ORDER BY data_publicacao DESC
LIMIT 10;
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
- **Múltiplas contas** para monitoramento concorrente
- **Análise de engajamento** com métricas da API
- **Parser avançado** com processamento de linguagem natural
- **Alertas** para posts com alto engajamento

---

## ✅ Checklist de Implementação

- [ ] Instalar community node do Instagram
- [ ] Configurar credenciais Instagram API
- [ ] Executar script SQL da tabela (com novos campos)
- [ ] Importar workflows (4 workflows)
- [ ] Configurar `NOME_DE_USUARIO_ALVO` no workflow de terceiros
- [ ] Substituir `COLOCAR_ID_CREDENTIAL` pelo ID real da credencial Instagram
- [ ] Testar execução manual
- [ ] Ativar agendamentos
- [ ] Verificar integração com assistente existente

**Status**: Pronto para produção 🎉
