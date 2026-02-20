# Agent Memory

Mental models for how AI agents persist and retrieve knowledge across sessions.

## The Core Problem

Agent sessions are ephemeral. Context windows reset. Every session starts from
zero unless memory is explicitly designed.

The naive solutions fail at different scales:

| Approach                  | Failure Mode                                      |
| ------------------------- | ------------------------------------------------- |
| Full conversation history | Token budget explosion                            |
| Manual notes              | Curation effort doesn't scale                     |
| Vector-dump everything    | Noise drowns signal                               |
| Single timestamp          | Can't distinguish "when learned" from "when true" |

## Three Architectures

### Knowledge Graph

Entities and relationships stored as nodes and edges. Retrieval follows
connections.

**Tradeoff:** Rich relational queries, high infrastructure cost (graph database
required).

The key insight is **bi-temporal tracking** — storing two independent timestamps
per fact:

- **valid_time** — when the event occurred in the world
- **transaction_time** — when the system learned about it

This separation answers questions naive systems cannot: "What did the system
believe last Tuesday about events from January?" Single-timestamp systems
conflate these axes.

When a fact changes ("user switched from Python to Rust"), the old edge is
**invalidated** — marked, not deleted. History preserves what the system once
believed.

**Retrieval:** Hybrid — vector similarity + keyword (BM25) + graph traversal. No
single method suffices. The combination outperforms each individually, with
graph distance reranking results by relational proximity.

_Example: [Graphiti](https://github.com/getzep/graphiti)_

### Vector Memory

Atomic facts stored as embeddings. Retrieval by semantic similarity.

**Tradeoff:** Simple API, lossy recall for relational knowledge.

The useful abstraction is a **multi-scope hierarchy**:

| Scope   | Contains                           | Lifecycle                 |
| ------- | ---------------------------------- | ------------------------- |
| User    | Permanent identity facts           | Persists indefinitely     |
| Session | Conversation context               | Expires with session      |
| Agent   | Behavioral state for a named agent | Resets on identity change |

Each scope has different lifecycle rules. The extraction step — converting raw
conversation into discrete, storable facts — is where most complexity hides.

_Example: [Mem0](https://github.com/mem0ai/mem0)_

### Cognitive Layers

Three layers mirroring human memory formation:

| Layer | Human Analog | Agent Component          | Storage             |
| ----- | ------------ | ------------------------ | ------------------- |
| 1     | Episodic     | Raw session logs         | Unstructured search |
| 2     | Working      | Structured diary entries | JSONL               |
| 3     | Procedural   | Playbook rules           | YAML                |

Knowledge flows upward: raw experience → structured reflection → internalized
pattern. This mirrors how expertise actually develops.

Procedural knowledge (Layer 3) carries the most value per token — compressed
wisdom, not raw data. But it requires the lower layers as evidence. Skip the
progression and you get untethered heuristics.

_Example: [CASS](https://github.com/Dicklesworthstone/cass_memory_system)_

## Key Patterns

### Confidence Decay

Rules are not permanent. Effective score uses time-decayed feedback:

```text
decayed_helpful = Σ(2^(-days / 90) per helpful event)
decayed_harmful = Σ(2^(-days / 90) per harmful event) × 4
effective_score = decayed_helpful - decayed_harmful
```

Two insights:

1. **Half-life** (90 days) — outdated knowledge fades automatically
2. **4× harmful multiplier** — loss aversion encoded as math. One bad outcome
   outweighs four good ones

Self-cleaning. No manual pruning.

### Anti-Pattern Inversion

Failed rules don't get deleted — they get inverted into explicit warnings:

```text
"Always cache auth tokens"  →  "PITFALL: Don't always cache auth tokens"
"Use X for Y"               →  "PITFALL: Avoid using X for Y"
```

Failed knowledge is often more valuable than positive rules. Knowing what _not_
to do prevents repeat mistakes. Deletion destroys institutional memory.

### Progressive Disclosure Retrieval

Don't flood the context window. Load memory in stages:

1. **Compact search results** with IDs (~50–100 tokens)
2. **Chronological context** around relevant results
3. **Full details** only for selected items (~500–1,000 tokens)

~10× token savings over naive retrieval. The agent decides what to expand.

### Deterministic Guards

LLMs should not manage their own rules.

The pattern: LLMs **propose** knowledge. Deterministic logic **curates** it. An
LLM curating a playbook that influences its own future behavior is a feedback
loop with no ground truth anchor.

```text
LLM generates → deterministic logic validates → evidence corroborates → rule accepted
```

Separate the generator from the gatekeeper.

### Shared State Artifacts

A JSON file can survive what a context window cannot.

The pattern: one agent writes a structured artifact (`feature_list.json`,
`decisions.yaml`). Subsequent agents — possibly in fresh sessions — read it at
startup. Git commits mark progress boundaries.

This decouples "what needs doing" from "current context." The artifact is
inspectable, diffable, and crash-safe.

### Inline Feedback

Embed feedback in the artifact being produced:

```text
// [memory: helpful rule-8f3a2c] — this pattern caught the edge case
// [memory: harmful rule-x7k9p1] — this broke on concurrent access
```

Feedback at the point of production, not in a separate UI. Auditable in version
control. Parseable by later processing stages.

## The Curation Tradeoff

| Dimension   | Manual Capture            | Automatic Capture       |
| ----------- | ------------------------- | ----------------------- |
| Signal      | High (human judgment)     | Mixed (needs filtering) |
| Coverage    | Gaps (forgets to capture) | Comprehensive           |
| Effort      | Ongoing cost              | Setup cost only         |
| Noise       | Low                       | Requires decay/scoring  |
| Scalability | Doesn't                   | Does                    |

Neither wins universally. The best systems use automatic capture with
deterministic curation — comprehensive input, filtered output.

## Theoretical Foundations

Google's
[Titans](https://research.google/blog/titans-miras-helping-ai-have-long-term-memory/)
architecture offers a model-level analog to the agent patterns above. Its core
idea: use **surprise** (gradient magnitude) as the retention signal — store what
contradicts existing knowledge, skip what confirms it. This inverts time-based
decay: relevance drives retention, not recency.

The companion MIRAS framework decomposes any sequence memory system into four
design axes: memory architecture, attentional bias, retention gate, and memory
algorithm. The three architectures in this guide map onto those axes, suggesting
a more general taxonomy exists beneath the practical tools.

No agent-layer system has adopted surprise-based gating yet. When one does,
expect it to outperform pure time-decay on long-lived knowledge bases where old
facts remain relevant.

## Heuristics

1. **Track two timestamps** — "when learned" and "when true" answer different
   questions
2. **Let knowledge decay** — half-life prevents stale rules from accumulating
3. **Invert failures** — convert bad rules into warnings, don't delete them
4. **Stage retrieval** — load summaries first, expand on demand
5. **Separate generation from curation** — LLMs propose, deterministic logic
   decides
6. **Store evidence** — rules without provenance can't be validated or
   challenged
7. **Design for the token budget** — memory is only useful if it fits in the
   window

## See Also

- [Orchestration](orchestration.md) — Context routing and agent coordination
- [Learning](learning.md) — How humans form and retain knowledge
- [Thinking](thinking.md) — Mental models and systems thinking
- [Agent Orchestration Cheat Sheet](../how/agent-orchestration.md) — Practical
  patterns for multi-agent work
