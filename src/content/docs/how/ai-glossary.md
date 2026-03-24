---
title: "AI/ML Glossary for Engineers"
description:
  Terms, definitions, and myths that software engineers encounter when building
  with AI — from tokens to RAG to quantization.
---

A working glossary of AI/ML terms aimed at software engineers, not ML
researchers. Each entry explains what the term means, what people get wrong, and
how it shows up in practice.

## Quick Reference

| Term           | One-Line Definition                                          |
| -------------- | ------------------------------------------------------------ |
| Model          | A function learned from data that maps inputs to outputs     |
| Inference      | Running a trained model on new input to get a prediction     |
| Token          | The atomic unit a language model reads and writes            |
| Context window | Maximum number of tokens a model can see in one request      |
| Temperature    | Controls randomness in output generation                     |
| Embedding      | A fixed-size numeric vector representing meaning             |
| RAG            | Retrieval-augmented generation — look up, then answer        |
| Fine-tuning    | Further training a model on your data                        |
| Hallucination  | Model generates plausible but false content                  |
| Prompt         | The text you send to a model as input                        |
| Agent          | A model that calls tools in a loop to accomplish a goal      |
| MCP            | Model Context Protocol — standard interface for tool servers |
| Quantization   | Reducing model precision to shrink size and speed inference  |
| Grounding      | Tying model output to verifiable sources                     |

## Core Concepts

### Model

A mathematical function with learned parameters that maps inputs to outputs. A
"70B model" has 70 billion parameters. Larger models generally perform better
but cost more to run.

**What people get wrong:** A model is not a database of memorized facts. It
learns statistical patterns during training. It cannot "look up" a specific
document it was trained on.

```text
Input: "Translate to French: Hello"
Model: f(input, parameters) → output
Output: "Bonjour"
```

### Inference

Running a trained model on new input. Every API call to Claude, GPT, or Gemini
is an inference request. The model's parameters stay fixed — no learning
happens.

**What people get wrong:** Inference does not update the model. Sending
corrections in a conversation does not retrain anything — the model just sees
your correction as additional context in the current prompt.

### Training

The process of adjusting a model's parameters using data. Pre-training runs on
massive datasets (books, code, web pages) and costs millions of dollars.
Engineers rarely do pre-training; they use pre-trained models via API.

### Fine-tuning

Further training a pre-trained model on a smaller, domain-specific dataset.
Changes the model's weights to specialize its behavior.

**What people get wrong:** Fine-tuning is not the first tool to reach for. It
requires curated datasets, costs money, and can degrade general capabilities.
RAG or well-crafted prompts solve most customization needs without touching
weights.

| Approach     | When to Use                                  | Cost     |
| ------------ | -------------------------------------------- | -------- |
| Prompting    | Behavior change, format control, constraints | Free     |
| RAG          | Custom knowledge, current data               | Moderate |
| Fine-tuning  | Tone, style, specialized domain language     | High     |
| Pre-training | Building a foundation model from scratch     | Extreme  |

### Parameters and Weights

Parameters are the numbers inside a model that determine its behavior. Weights
are the most common type of parameter — the multipliers applied to inputs at
each layer. In casual usage, "parameters" and "weights" are interchangeable.

```text
Model sizes (approximate):
  7B parameters  →  ~4 GB quantized  → runs on laptop
  70B parameters → ~40 GB quantized  → needs a beefy GPU
 405B parameters → ~200 GB quantized → needs a cluster
```

## Language Models

### Token

The atomic unit a language model reads and writes. Not a word — a subword piece
determined by the model's tokenizer. English averages roughly 1 token per 0.75
words (4 characters).

**What people get wrong:** "1 token = 1 word" is a common but inaccurate
shorthand. The word "unhappiness" might be 3 tokens (`un`, `happi`, `ness`).
Code tokenizes especially poorly — a single line of Python can be 20+ tokens.

```python
# Approximate token counts (varies by model)
"Hello"           # 1 token
"authentication"  # 3 tokens
"123456"          # 2-3 tokens
"こんにちは"       # 3-5 tokens (non-English costs more)
```

### Context Window

The maximum number of tokens a model can process in a single request — including
both the input (prompt) and the output (completion). A 200K context window means
the model can see roughly 150,000 words at once.

**What people get wrong:** A large context window does not mean the model pays
equal attention to everything in it. Performance degrades on information buried
in the middle of very long contexts ("lost in the middle" effect). Place
critical information at the beginning or end of the prompt.

### Temperature

A parameter (0.0–2.0, typically) that controls how random the model's output is.
Low temperature (0.0–0.3) makes output deterministic and focused. High
temperature (0.7–1.0) makes output more creative and varied.

| Temperature | Use Case                           | Character  |
| ----------- | ---------------------------------- | ---------- |
| 0.0         | Code generation, structured output | Repeatable |
| 0.3–0.5     | Technical writing, summaries       | Focused    |
| 0.7–1.0     | Creative writing, brainstorming    | Varied     |

**What people get wrong:** Temperature 0 does not guarantee identical outputs
across requests. Implementation details (batching, floating-point order) can
produce slight variations even at temperature 0.

### Top-p (Nucleus Sampling)

Limits token selection to the smallest set whose cumulative probability exceeds
`p`. With `top_p=0.9`, the model considers only the top 90% of probability mass,
ignoring unlikely tokens.

**Practical rule:** Adjust either temperature or top_p, not both. Most APIs
default top_p to 1.0 (no filtering) and let temperature do the work.

### Max Tokens

The maximum number of tokens the model will generate in its response. This is a
hard cap — the model stops generating once it hits this limit, even
mid-sentence.

**What people get wrong:** Max tokens applies to the output only. It does not
limit the input. Setting `max_tokens=100` with a 10,000-token prompt is valid.

### Stop Sequences

Strings that cause the model to stop generating. Useful for structured output
where you know the delimiter.

```python
# Stop at the first newline — useful for single-line extraction
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    max_tokens=100,
    stop_sequences=["\n"],
    messages=[{"role": "user", "content": "Extract the email: ..."}]
)
```

## Prompting

### System Prompt

A special message that sets the model's behavior for the entire conversation.
Appears before user messages and establishes role, constraints, and output
format.

```python
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    system="You are a code reviewer. Point out bugs and security issues only. "
           "Do not suggest style changes.",
    messages=[{"role": "user", "content": code}]
)
```

### Few-Shot Prompting

Providing examples of desired input-output pairs inside the prompt. The model
infers the pattern and applies it to new input.

```text
Classify the sentiment:

"The deploy was smooth" → positive
"Tests are failing again" → negative
"We shipped the feature" → positive
"The API keeps timing out" →
```

**What people get wrong:** More examples are not always better. Two or three
well-chosen examples often outperform ten mediocre ones. Pick examples that
cover edge cases, not just the happy path.

### Chain-of-Thought (CoT)

Asking the model to show its reasoning step by step before giving a final
answer. Improves accuracy on math, logic, and multi-step problems.

```text
# Without CoT
"What is 17 * 24?" → often wrong

# With CoT
"What is 17 * 24? Think step by step."
→ "17 * 24 = 17 * 20 + 17 * 4 = 340 + 68 = 408" → correct
```

### Structured Output

Constraining the model to output valid JSON, XML, or another format. Achieved
through system prompts, function calling, or schema constraints.

```python
response = client.messages.create(
    model="claude-sonnet-4-20250514",
    system="Respond only with valid JSON matching this schema: "
           '{"name": string, "severity": "low"|"medium"|"high"}',
    messages=[{"role": "user", "content": "Classify this bug report: ..."}]
)
```

### Function Calling (Tool Use)

The model selects a function from a provided list, generates the arguments, and
returns a structured call for your code to execute. The model never executes the
function — your code does.

```text
User: "What's the weather in Austin?"

Model decides to call:
  function: get_weather
  arguments: {"location": "Austin, TX"}

Your code runs get_weather("Austin, TX") → {"temp": 95, "condition": "sunny"}

Model uses the result to answer:
  "It's 95°F and sunny in Austin."
```

**What people get wrong:** The model does not execute code. It outputs a JSON
object describing which function to call and with what arguments. Your
application parses the output and runs the function.

## Retrieval & Memory

### Embedding

A fixed-length numeric vector (e.g., 1,536 floats) that represents the semantic
meaning of text. Similar meanings produce vectors that are close together in
vector space.

```python
from openai import OpenAI
client = OpenAI()

# Two semantically similar sentences produce close vectors
emb1 = client.embeddings.create(input="How do I reset my password?", model="text-embedding-3-small")
emb2 = client.embeddings.create(input="I forgot my login credentials", model="text-embedding-3-small")
# cosine_similarity(emb1, emb2) ≈ 0.89 (high similarity)
```

**What people get wrong:** Embeddings capture semantic similarity, not keyword
overlap. "Dog" and "canine" produce close embeddings. "Bank" (finance) and
"bank" (river) produce distant ones — but only in good embedding models.

### Vector Database

A database optimized for storing and querying embeddings via similarity search.
Instead of exact matches (SQL `WHERE`), you search by "nearest neighbors" in
vector space.

| Database | Type                  | Notes                        |
| -------- | --------------------- | ---------------------------- |
| pgvector | Postgres extension    | Add vectors to existing data |
| Pinecone | Managed cloud         | Serverless, pay-per-query    |
| ChromaDB | Embedded (in-process) | Good for prototypes          |
| Qdrant   | Self-hosted or cloud  | Rich filtering support       |
| Weaviate | Self-hosted or cloud  | Hybrid keyword + vector      |

### RAG (Retrieval-Augmented Generation)

A pattern: retrieve relevant documents from a knowledge base, then include them
in the prompt so the model can answer from real data rather than memorized
training data.

```text
User question: "What is our refund policy?"

Step 1 — Retrieve: Search vector DB for "refund policy" → top 3 documents
Step 2 — Augment: Insert documents into the prompt as context
Step 3 — Generate: Model answers using the retrieved context
```

**What people get wrong:** RAG does not eliminate hallucination — it reduces it.
The model can still misinterpret, selectively ignore, or incorrectly synthesize
retrieved documents. Always verify critical answers.

### Semantic Search

Searching by meaning rather than keywords. Uses embeddings to find documents
that are conceptually similar to a query, even when they share no words.

```text
Query: "how to handle app crashes"
Keyword search finds: documents containing "app" and "crashes"
Semantic search also finds: "error recovery strategies", "exception handling"
```

### Chunking

Splitting documents into smaller pieces before embedding them. Chunk size
affects retrieval quality — too large and you dilute relevance; too small and
you lose context.

| Strategy   | Chunk Size     | Best For                         |
| ---------- | -------------- | -------------------------------- |
| Fixed-size | 500–1000 chars | Simple, predictable              |
| Sentence   | 1–3 sentences  | Preserves grammatical boundaries |
| Paragraph  | ~200–500 words | Natural topic boundaries         |
| Recursive  | Varies         | Structured docs (Markdown, HTML) |

## Agents

### Tool Use

A model's ability to call external functions (APIs, databases, file systems) to
take actions or retrieve information. The model decides which tool to call and
generates the arguments; your runtime executes the call.

### Agent Loop

The cycle an agent follows: observe (read context) → think (decide next action)
→ act (call a tool) → observe (read result) → repeat until done.

```text
Goal: "Find and fix the failing test"

Loop iteration 1: read test output → identify assertion error
Loop iteration 2: read source file → spot the bug
Loop iteration 3: edit file → fix the bug
Loop iteration 4: run tests → all pass → done
```

**What people get wrong:** Agents are not magic. Each loop iteration costs
tokens and time. A poorly constrained agent can spin for dozens of iterations
burning budget without making progress. Set exit conditions and iteration
limits.

### Orchestration

Coordinating multiple agents or model calls to complete a complex task. Patterns
include sequential pipelines, parallel fan-out, and hierarchical delegation.

```text
Sequential:  plan → research → write → review → publish
Parallel:    [lint, test, typecheck] → merge results → decide
Hierarchical: lead agent delegates subtasks to specialist agents
```

### MCP (Model Context Protocol)

An open standard for connecting AI models to external tools and data sources.
Defines a JSON-RPC protocol so any MCP-compatible client (Claude Code, Cursor)
can discover and call tools from any MCP server.

```text
Client (Claude Code) ←→ MCP Server (your tools)
  ├── list_tools → returns available functions
  ├── call_tool → executes a function, returns result
  └── list_resources → exposes data for context
```

## Safety & Quality

### Hallucination

When a model generates content that sounds plausible but is factually wrong. Not
a bug — it is a fundamental property of how generative models work. They predict
likely next tokens, not truthful ones.

**Common forms:**

| Type             | Example                                       |
| ---------------- | --------------------------------------------- |
| Fabricated facts | Cites a paper that does not exist             |
| Wrong code       | Calls an API method that the library lacks    |
| Confident error  | States an incorrect date with full confidence |
| Invented URLs    | Generates a plausible but nonexistent link    |

### Grounding

Tying model outputs to verifiable sources. RAG is the most common grounding
technique — the model answers from retrieved documents rather than parametric
memory.

**What people get wrong:** Grounding reduces hallucination but does not
eliminate it. A grounded model can still misread, ignore, or misquote its
sources.

### Guardrails

Filters and checks applied before or after model output to enforce safety,
format, or business rules. These run in your application code, not inside the
model.

```text
Pre-generation guardrails:
  - Input validation (reject prompt injection attempts)
  - PII detection (strip sensitive data before sending)

Post-generation guardrails:
  - Output validation (parse JSON, check schema)
  - Content filtering (flag unsafe or off-topic responses)
  - Fact-checking (compare claims against a source of truth)
```

### Red Teaming

Deliberately trying to make a model fail — produce harmful output, leak system
prompts, bypass guardrails, or generate incorrect answers. A form of adversarial
testing.

### Alignment

Training or steering a model to behave according to intended values and
instructions. Techniques include RLHF (reinforcement learning from human
feedback) and constitutional AI (rules the model self-enforces).

**What people get wrong:** Alignment is not a binary state. A model is not
"aligned" or "unaligned" — it sits on a spectrum and can fail in novel
situations. Treat alignment as defense in depth, not a guarantee.

## Infrastructure

### Inference Endpoint

An HTTP API that serves a model for inference. You send a request with your
prompt; it returns the model's output. All major providers (Anthropic, OpenAI,
Google) expose models this way.

```bash
# Typical inference endpoint call
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-sonnet-4-20250514",
    "max_tokens": 1024,
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### Model Serving

The infrastructure for hosting and scaling inference endpoints. Includes GPU
allocation, request batching, load balancing, and autoscaling. Tools like vLLM,
TGI (Text Generation Inference), and Triton handle this.

### Quantization

Reducing the numerical precision of model weights to shrink file size and speed
inference. A 16-bit model quantized to 4-bit runs roughly 4x faster with modest
quality loss.

| Precision | Bits per Weight | Quality   | Speed  | Use Case             |
| --------- | --------------- | --------- | ------ | -------------------- |
| FP32      | 32              | Baseline  | Slow   | Research             |
| FP16/BF16 | 16              | ~Baseline | Medium | GPU training/serving |
| INT8      | 8               | Very good | Fast   | Production serving   |
| INT4/Q4   | 4               | Good      | Faster | Local/edge inference |

**What people get wrong:** Quantization is not free compression. Going from
16-bit to 4-bit degrades reasoning on complex tasks. Test your specific workload
before deploying a quantized model in production.

### Distillation

Training a small "student" model to mimic a large "teacher" model. The student
learns from the teacher's outputs rather than raw data, capturing much of the
teacher's capability in a fraction of the size.

```text
Teacher (405B params) → generates labeled data
Student (7B params)   → trains on teacher's outputs
Result: 7B model that performs close to the 405B on targeted tasks
```

### GGUF and ONNX

File formats for distributing models outside their original framework.

| Format      | What It Is                                     | Runs On            |
| ----------- | ---------------------------------------------- | ------------------ |
| GGUF        | Quantized model format for llama.cpp           | CPU, Apple Silicon |
| ONNX        | Open Neural Network Exchange (cross-framework) | Any ONNX runtime   |
| SafeTensors | Hugging Face safe serialization format         | PyTorch, JAX       |

```bash
# Run a GGUF model locally with llama.cpp
./llama-server -m model.Q4_K_M.gguf --port 8080

# Or with Ollama (wraps llama.cpp)
ollama run llama3
```

## Myths Engineers Believe

| Myth                                       | Reality                                                                                                                                                                                       |
| ------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "AI understands my code"                   | Models predict likely next tokens based on patterns. They have no runtime, no debugger, no understanding — just statistical correlation over training data.                                   |
| "A bigger context window fixes everything" | Attention degrades over long contexts. Stuffing 200K tokens into a prompt does not mean the model uses all of it well. Retrieve the right 2K tokens instead.                                  |
| "Temperature 0 = deterministic"            | Implementation details (GPU batching, floating-point non-determinism) can produce different outputs even at temperature 0. Use seed parameters when available.                                |
| "Fine-tuning is the answer"                | Fine-tuning requires curated data, costs money, and can degrade general capabilities. Prompt engineering and RAG solve 90% of customization needs.                                            |
| "RAG eliminates hallucination"             | RAG reduces hallucination by grounding answers in documents. The model can still misinterpret, selectively ignore, or fabricate beyond its sources.                                           |
| "More examples = better few-shot"          | Two precise examples that cover edge cases outperform ten examples that all show the happy path. Quality over quantity.                                                                       |
| "Embeddings capture meaning perfectly"     | Embeddings capture distributional similarity, not meaning. "Not bad" and "good" embed similarly despite carrying different nuance.                                                            |
| "Agents can do anything"                   | Each agent loop iteration costs tokens, time, and money. Poorly scoped agents burn budget spinning in circles. Set exit conditions and iteration caps.                                        |
| "AI-generated code doesn't need review"    | AI code has 1.75x more logic errors and 45% security flaw rate. Review every line as if a confident but careless junior wrote it.                                                             |
| "Open-source models are free"              | The weights are free. The GPUs to run them are not. Serving a 70B model requires hardware that costs $2–5/hour.                                                                               |
| "Tokens are words"                         | Tokens are subword pieces. "unhappiness" is 3 tokens. Code tokenizes poorly. Non-English text costs more tokens per word.                                                                     |
| "The model remembers past conversations"   | Each API call is stateless. The model has no memory between requests. Your application must manage conversation history by resending prior messages.                                          |
| "Prompt injection is solved"               | No reliable defense exists against all prompt injection attacks. Defense in depth — input validation, output filtering, least-privilege tool access — reduces risk but does not eliminate it. |

## See Also

- [AI CLI](ai-cli.md) — Claude Code CLI usage and prompting patterns
- [Claude Code](claude-code.md) — Agents, hooks, MCP, memory, configuration
- [AI Adoption](../why/ai-adoption.md) — When and how to adopt AI tools in a
  team
