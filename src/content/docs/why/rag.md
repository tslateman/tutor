---
title: "Retrieval-Augmented Generation"
description:
  "Mental models for RAG pipelines — chunking, embedding, retrieval, and the
  decision frameworks that separate production systems from demos."
---

Ground language models in external knowledge instead of relying on parametric
memory alone. RAG exists because models hallucinate, training data goes stale,
and context windows — however large — remain finite.

## Why RAG Exists

Three forces push toward retrieval:

| Force                 | Problem Without RAG                                | RAG's Answer                             |
| --------------------- | -------------------------------------------------- | ---------------------------------------- |
| Knowledge freshness   | Training data has a cutoff date                    | Retrieve current documents at query time |
| Grounding             | Models confabulate plausible-sounding falsehoods   | Anchor generation in source text         |
| Context window limits | Large corpora exceed even million-token windows    | Select only the relevant slices          |
| Domain specificity    | General models lack proprietary or niche knowledge | Inject domain documents on demand        |

RAG does not eliminate hallucination. It reduces the surface area by giving the
model evidence to cite rather than memory to fabricate from.

## The Pipeline

Every RAG system follows the same skeleton, however elaborate the
implementation:

```text
Ingest → Chunk → Embed → Store → Retrieve → Augment → Generate
```

| Stage        | Input              | Output           | Key Decision                       |
| ------------ | ------------------ | ---------------- | ---------------------------------- |
| **Ingest**   | Raw documents      | Clean text       | Parsing fidelity (PDF, HTML, code) |
| **Chunk**    | Clean text         | Sized passages   | Strategy and granularity           |
| **Embed**    | Text passages      | Dense vectors    | Model choice, dimensions           |
| **Store**    | Vectors + metadata | Searchable index | Database topology                  |
| **Retrieve** | User query         | Candidate chunks | Search method, top-k, reranking    |
| **Augment**  | Query + chunks     | Assembled prompt | Context packing, ordering          |
| **Generate** | Augmented prompt   | Final answer     | Citation, faithfulness guardrails  |

Failure at any stage propagates forward. 80% of RAG failures trace to ingestion
and chunking, not the model.

## Chunking Strategies

Chunking determines what the retriever can find. A chunk too large buries the
signal in noise. A chunk too small strips the context that makes the signal
interpretable.

| Strategy               | How It Works                                                  | Strengths                       | Weaknesses                                       |
| ---------------------- | ------------------------------------------------------------- | ------------------------------- | ------------------------------------------------ |
| Fixed-size             | Split every N tokens with optional overlap                    | Simple, predictable, fast       | Cuts mid-sentence, ignores structure             |
| Recursive character    | Split on paragraphs → sentences → words → characters          | Respects natural boundaries     | Still structure-unaware for complex docs         |
| Semantic               | Group sentences by embedding similarity                       | Captures topic shifts           | Expensive; needs minimum-size floor              |
| Document-aware         | Use headings, sections, or markup as split points             | Preserves authorial structure   | Requires parser per format                       |
| Contextual (Anthropic) | Prepend document-level context to each chunk before embedding | 35–67% fewer retrieval failures | Adds 50–100 tokens per chunk; preprocessing cost |

### Practical Defaults

- **Recursive character splitting** is the safest starting point.
- **256–512 tokens** per chunk with **10–20% overlap** covers most corpora.
- **Overlap provides no measurable benefit** with sparse retrieval
  (SPLADE/BM25); test before defaulting to 20%.
- **Contextual chunking** — prepending a short summary of the surrounding
  document — reduced retrieval failures by 49% in Anthropic's benchmarks (67%
  with reranking). The preprocessing cost is roughly $1 per million document
  tokens.

The chunking configuration influences retrieval quality as much as the embedding
model. Tune chunks before swapping models.

## Embedding Models

An embedding model compresses text into a dense vector where geometric proximity
approximates semantic similarity. The vector captures _meaning_, not keywords.

### What Matters

| Dimension         | Why It Matters                                               |
| ----------------- | ------------------------------------------------------------ |
| Model quality     | Determines how well meaning maps to geometry                 |
| Vector dimensions | Higher = more expressive, but more storage and slower search |
| Max input tokens  | Caps chunk size; 8K is common, some models handle 32K        |
| Domain fit        | General-purpose models underperform on specialized corpora   |

### Distance Metrics

| Metric         | Formula Intuition                         | When to Use                              |
| -------------- | ----------------------------------------- | ---------------------------------------- |
| Cosine         | Angle between vectors (ignores magnitude) | Default; works for normalized embeddings |
| Dot product    | Cosine × magnitudes                       | When magnitude encodes importance        |
| Euclidean (L2) | Straight-line distance                    | Rarely better than cosine for text       |

Cosine similarity is the default for a reason: most embedding models normalize
their output, making magnitude irrelevant.

## Vector Store Decision Framework

Choose the store that matches your operational constraints, not the one with the
most features.

| Criterion            | pgvector                         | Qdrant                     | Pinecone                       | Chroma                        |
| -------------------- | -------------------------------- | -------------------------- | ------------------------------ | ----------------------------- |
| **Best for**         | Already on Postgres              | Complex metadata filtering | Turnkey managed scale          | Prototyping and learning      |
| **Deployment**       | Extension on existing DB         | Self-hosted or cloud       | Fully managed                  | Embedded or client-server     |
| **Scale ceiling**    | ~5M vectors before tuning needed | Billions (Rust, HNSW)      | Billions (serverless)          | ~5M before migration pressure |
| **Filtering**        | SQL WHERE clauses                | Rich payload filters       | Metadata filters               | Basic metadata                |
| **Operational cost** | Zero new infrastructure          | Moderate (another service) | Pay-per-query                  | Minimal                       |
| **Tradeoff**         | Performance at scale             | Infra to manage            | Vendor lock-in, cost at volume | Not production-grade at scale |

### Decision Heuristic

1. **Already run Postgres?** Start with pgvector. Same transactions, same
   tooling, no sync pipeline.
2. **Need complex filters + scale?** Qdrant or Milvus. Purpose-built for the
   workload.
3. **Want zero ops?** Pinecone. Pay more, manage less.
4. **Building a prototype?** Chroma. Embedded, no config, swap later.

The self-hosted break-even against managed serverless sits around 80–100 million
queries per month. Below that threshold, managed services save engineering time.

## Retrieval Strategies

The retriever determines what evidence the model sees. A mediocre generator with
excellent retrieval outperforms an excellent generator with mediocre retrieval.

| Strategy                         | Mechanism                                 | Strengths                                   | Weaknesses                       |
| -------------------------------- | ----------------------------------------- | ------------------------------------------- | -------------------------------- |
| Similarity search                | Nearest neighbors in embedding space      | Simple, semantic matching                   | Misses exact keywords            |
| BM25 (lexical)                   | Term frequency–inverse document frequency | Exact match, acronyms, proper nouns         | No semantic understanding        |
| Hybrid (dense + sparse)          | Combine similarity + BM25 via rank fusion | Best of both; 49% fewer failures            | Two indexes to maintain          |
| Reranking                        | Cross-encoder scores query–chunk pairs    | 18–42% precision boost over retrieval alone | Adds latency; runs on top-N only |
| MMR (Maximal Marginal Relevance) | Penalize redundancy in retrieved set      | Diverse results                             | Tuning lambda is fiddly          |

### The Hybrid + Rerank Pattern

The strongest general-purpose configuration:

```text
1. Retrieve top-150 from dense index  (semantic recall)
2. Retrieve top-150 from BM25 index   (lexical recall)
3. Fuse and deduplicate               (rank fusion)
4. Rerank to top-20 with cross-encoder (precision)
5. Pack top-k into prompt             (context assembly)
```

Anthropic's benchmarks showed this pipeline reduces retrieval failures by 67%
compared to naive embedding search alone.

## Context Assembly

Retrieved chunks are raw material. How you pack them into the prompt determines
whether the model uses them well.

### Assembly Principles

| Principle                         | Rationale                                              |
| --------------------------------- | ------------------------------------------------------ |
| Order by relevance                | Models attend more to the beginning and end of context |
| Include source metadata           | Enables citation; "According to [doc, section]..."     |
| Stay under 8K tokens              | Shorter, precise context outperforms 50K token dumps   |
| Separate context from instruction | Clear delimiter between retrieved text and task        |

### Prompt Structure

```text
You are answering questions using the provided context.
Only use information from the context. If the context does
not contain the answer, say so.

## Context
{retrieved_chunks_with_source_metadata}

## Question
{user_query}
```

The instruction to say "I don't know" when context lacks the answer is a
faithfulness guardrail. Without it, the model fills gaps from parametric memory
— exactly what RAG was supposed to prevent.

## Evaluation

RAG evaluation splits into two independent axes: did you retrieve the right
evidence, and did you generate a faithful answer from it?

### Retrieval Metrics

| Metric      | Measures                                     | Target |
| ----------- | -------------------------------------------- | ------ |
| Recall@k    | Fraction of relevant docs found in top-k     | > 0.8  |
| Precision@k | Fraction of top-k that are actually relevant | > 0.7  |
| MRR         | Reciprocal rank of first relevant result     | > 0.7  |
| nDCG@k      | Ranking quality weighted by position         | > 0.7  |

Precision below 70% signals a chunking or embedding problem. Fix retrieval
before tuning generation.

### Generation Metrics

| Metric        | Measures                                      | How to Assess           |
| ------------- | --------------------------------------------- | ----------------------- |
| Faithfulness  | Answer grounded in retrieved context          | LLM-as-judge or human   |
| Relevance     | Answer addresses the actual question          | LLM-as-judge or human   |
| Completeness  | All relevant information from context is used | Human evaluation        |
| Hallucination | Claims not supported by any retrieved chunk   | Automated + spot checks |

### Production Monitoring Thresholds

| Signal               | Alert When                       |
| -------------------- | -------------------------------- |
| Faithfulness score   | Drops > 15% from baseline        |
| Retrieval latency    | p99 exceeds 500ms                |
| End-to-end latency   | Simple RAG > 2s, agentic > 8s    |
| Empty retrieval rate | > 5% of queries return no chunks |
| Error rate spike     | > 25% increase over window       |

## When NOT to Use RAG

RAG adds infrastructure, latency, and failure modes. Use it only when the
alternatives are worse.

| Situation                               | Better Alternative                           |
| --------------------------------------- | -------------------------------------------- |
| Corpus fits in context (< 200K tokens)  | Prompt stuffing with caching                 |
| Data is structured (tables, schemas)    | Text-to-SQL or direct API query              |
| Answers require full-document reasoning | Long-context model with complete document    |
| Knowledge is static and small           | Fine-tune or few-shot examples               |
| Exact lookup, not semantic search       | Traditional database query or keyword search |
| Real-time transactional data            | Direct database access, not a stale index    |

The question is not "can RAG solve this?" but "is RAG the simplest architecture
that solves this?" If a SQL query or a cached prompt answers the question, RAG
is accidental complexity.

## Production Concerns

| Concern       | Problem                                           | Mitigation                                                   |
| ------------- | ------------------------------------------------- | ------------------------------------------------------------ |
| Staleness     | Index lags behind source documents                | Incremental ingestion pipeline; track document hashes        |
| Consistency   | Different chunks from different document versions | Version metadata on chunks; atomic re-index per doc          |
| Cost          | Embedding + storage + retrieval + generation      | Cache frequent queries; batch embeddings; rerank fewer       |
| Latency       | Retrieval adds 100–500ms before generation        | Pre-compute embeddings; use ANN with HNSW; cache hot queries |
| Security      | Retrieved chunks may contain sensitive data       | Chunk-level access control; filter by user permissions       |
| Observability | Black-box retrieval hides failure modes           | Log retrieved chunk IDs per query; track retrieval scores    |

## Advanced Patterns

### HyDE (Hypothetical Document Embeddings)

The query "What are the tax implications of stock options?" shares little
lexical or embedding overlap with the document that answers it. HyDE bridges
this gap:

```text
1. Ask the LLM to generate a hypothetical answer (no retrieval)
2. Embed the hypothetical answer (not the original query)
3. Use that embedding to retrieve real documents
```

The hypothetical answer, even if factually wrong, occupies the same embedding
neighborhood as real answers. This shifts the search from query-space to
answer-space, where documents actually live.

**When it helps:** Vague queries, exploratory questions, domain gaps between
user language and document language.

**When it hurts:** Adds an LLM call before retrieval. Skip it when queries
already match document vocabulary.

### Query Decomposition

Complex questions often require evidence from multiple chunks that no single
retrieval can surface:

```text
"How does our auth system compare to the OWASP recommendations?"

Decomposed:
  1. "What is our current auth system architecture?"
  2. "What are the OWASP authentication recommendations?"
  3. "Where do they diverge?"
```

Retrieve for each sub-query independently, then synthesize. The cost is multiple
retrieval passes; the gain is evidence that a single query would miss.

### Agentic RAG

The retriever becomes a tool the agent decides when and how to call:

```text
Agent loop:
  1. Analyze query → decide if retrieval is needed
  2. Formulate retrieval query (may differ from user query)
  3. Evaluate retrieved chunks → decide if sufficient
  4. If insufficient → reformulate query or try different source
  5. Generate answer from accumulated evidence
```

Agentic RAG trades latency for recall. The agent can retry, decompose, and
cross-reference — capabilities that a single-pass pipeline lacks. The cost is
unpredictable latency and harder evaluation.

## Anti-Patterns

| Anti-Pattern                                     | Why It Fails                                       | Fix                                               |
| ------------------------------------------------ | -------------------------------------------------- | ------------------------------------------------- |
| Chunk and pray                                   | No evaluation; assumes retrieval works             | Measure recall@k and precision@k before shipping  |
| Dump 50K tokens of context                       | Drowns signal; models attend poorly to mid-context | Cap at 8K; rerank aggressively                    |
| Embed everything, filter nothing                 | Noise outranks signal                              | Metadata filters, access controls, reranking      |
| Skip reranking                                   | ANN search optimizes speed, not precision          | Cross-encoder reranking on top-N                  |
| One chunk size for all document types            | PDFs, code, and chat logs have different structure | Document-aware chunking per source type           |
| No staleness detection                           | Index answers from last month's docs               | Hash-based change detection; incremental re-index |
| RAG when context window suffices                 | Added complexity for no retrieval benefit          | Measure corpus size first; use prompt caching     |
| Evaluate generation without evaluating retrieval | Tuning the generator when the retriever is broken  | Evaluate each stage independently                 |

## Heuristics

1. **Fix retrieval before generation** — a perfect model cannot compensate for
   missing evidence
2. **Start with hybrid search** — dense + sparse retrieval outperforms either
   alone
3. **Rerank the top-N** — approximate nearest neighbor optimizes for speed, not
   precision
4. **Measure before you tune** — precision@k and recall@k diagnose which stage
   is failing
5. **Keep assembled context short** — 8K tokens of precise evidence beats 50K of
   marginally relevant text
6. **Chunk configuration matters as much as model choice** — tune chunk size and
   overlap before swapping embedding models
7. **Version your index** — document hashes and metadata prevent stale answers
8. **Ask whether RAG is necessary** — if the corpus fits in context, skip the
   pipeline

## See Also

- [Agent Memory](agent-memory.md) — Memory architectures where RAG serves as one
  retrieval layer
- [Orchestration](orchestration.md) — RAG as a step in agent workflows, context
  routing challenges
- [System Design](../how/system-design.md) — Where vector stores and retrieval
  pipelines fit in system architecture
- [Complexity](complexity.md) — RAG adds accidental complexity; when the simpler
  approach wins
