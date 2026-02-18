# Orchestration Cheat Sheet

Coordinating autonomous workers -- containers or agents -- is the same problem
at different levels of determinism.

## What Transfers from K8s

Orchestration experience builds instincts that apply directly to agent systems.

| K8s Concept           | Agent Equivalent         | Why It Transfers                                  |
| --------------------- | ------------------------ | ------------------------------------------------- |
| Declarative state     | Intent-driven prompts    | Describe the outcome, not the procedure           |
| Orchestration != exec | Delegation != doing      | The scheduler doesn't run your code               |
| Service discovery     | Registry / capability ad | Workers find each other through a central catalog |
| Resource limits       | Context window budgets   | Finite capacity requires explicit allocation      |
| ConfigMaps / Secrets  | CLAUDE.md / context      | Configuration travels alongside the workload      |
| Liveness probes       | Output validation        | Verify workers are producing useful results       |
| Eventual consistency  | Async coordination       | Not everything settles immediately                |
| Rolling updates       | Progressive rollout      | Change gradually, watch for regressions           |
| Labels and selectors  | Metadata and routing     | Route work by properties, not names               |
| Namespaces            | Session / project scope  | Isolation prevents cross-contamination            |

**The core transfer:** Think in desired state, not step sequences.

## What Misleads

K8s instincts that break when applied to agents without adjustment.

| K8s Assumption             | Agent Reality                          | The Gap                                         |
| -------------------------- | -------------------------------------- | ----------------------------------------------- |
| Deterministic execution    | Stochastic output                      | Same input rarely yields identical results      |
| Clean failure (exit codes) | Semantic failure (confident nonsense)  | The worker says "done" but the answer is wrong  |
| Horizontal scaling         | Context doesn't shard                  | You can't split a reasoning task across 10 pods |
| Strong contracts (schemas) | Fuzzy interfaces (natural language)    | Input/output validation is probabilistic        |
| Stateless workers          | Context-dependent reasoning            | Agent output depends on what it has seen        |
| Fast restart               | Expensive cold start (context rebuild) | Losing state costs minutes, not seconds         |
| Observable metrics         | Hard-to-measure quality                | Latency and throughput miss the point           |
| Idempotent operations      | Non-repeatable reasoning               | Re-running a prompt gives different output      |

**The core trap:** Expecting mechanical reliability from cognitive workers.

## The Unsolved Problem: Context Routing

K8s solved resource scheduling -- bin-packing CPU and memory across nodes.
Nobody has solved context scheduling for agents.

```text
K8s scheduler:  "This pod needs 2 CPU and 4GB. Node 3 has room."
                 Solved. Measurable. Provably optimal.

Agent scheduler: "This task needs the auth codebase context, the API
                  design doc, and awareness of last week's decisions."
                  Unsolved. Unmeasurable. Currently manual.
```

### Why It's Hard

| Resource Scheduling (Solved) | Context Scheduling (Unsolved)        |
| ---------------------------- | ------------------------------------ |
| CPU/memory are fungible      | Context is semantic, non-fungible    |
| Usage is measurable          | Relevance is subjective              |
| Capacity is fixed per node   | Window size is fixed, density varies |
| Bin-packing is well-studied  | No algorithm for "what matters"      |
| Overcommit = OOM kill        | Overcommit = degraded reasoning      |

### Current Workarounds

- **Manual curation** -- CLAUDE.md files, explicit context injection
- **Convention over discovery** -- standard file locations, naming patterns
- **Progressive disclosure** -- start small, load more on demand
- **Handoff protocols** -- structured summaries for session transfer

None of these scale. The team that solves automatic context routing wins the
orchestration layer.

## Failure Detection

K8s health checks assume binary state: healthy or not. Agent failures are
gradient.

| Failure Type    | K8s Detection     | Agent Detection              |
| --------------- | ----------------- | ---------------------------- |
| Crash           | Process exit code | Exception / timeout          |
| Hang            | Liveness probe    | Token stream stops           |
| Wrong answer    | N/A               | Output validation (hard)     |
| Subtle drift    | N/A               | Semantic comparison (harder) |
| Confident error | N/A               | Currently undetectable       |

**The gap:** K8s never has to ask "is this output _correct_?" It only asks "is
the process alive?" Agent orchestration must answer both.

## Patterns from Production Systems

Real agent fleets reveal patterns that theory alone misses.

### Clean Context per Step

Each agent in a pipeline starts with a fresh context window, receiving only
explicit inputs from the previous step. This directly counters the drift
problem: an agent at step 7 works with a different implicit model than the agent
at step 1.

The tradeoff: you must explicitly design what context passes between steps. This
forces clarity about what actually matters at each stage.

_Source: [Antfarm](https://github.com/snarktank/antfarm)_

### Doer/Verifier Separation

The developer doesn't mark their own homework. A separate agent verifies
implementation against acceptance criteria.

This catches a class of errors that self-review cannot: rationalization,
satisfied-by-construction failures, and blind spots from having written the
code. Simple to implement. Most systems skip it.

_Source: [Antfarm](https://github.com/snarktank/antfarm)_

### Typed Routing Decisions

Routing decisions — which agent handles a task — should be structured artifacts,
not prose. Pydantic models or equivalent typed schemas prevent the orchestration
layer from becoming the weakest link.

_Source: [AgenticFleet](https://github.com/Qredence/agentic-fleet) (via DSPy
signatures)_

### Execution Mode as Vocabulary

Name your modes: **sequential**, **parallel**, **delegated**, **handoff**,
**discussion**. The vocabulary itself improves reasoning about agent
coordination, regardless of which framework you use.

"Discussion" as a first-class mode — multi-agent deliberation — acknowledges
that some problems need deliberation, not just delegation.

_Source: [AgenticFleet](https://github.com/Qredence/agentic-fleet)_

### Time-Travel Checkpointing

Checkpoint workflow state so you can rewind and replay from any point. Without
it, debugging a failed multi-agent run means replaying from scratch.

Rare in practice. High engineering cost. Invaluable when you need it.

_Source:
[Microsoft Agent Framework](https://github.com/microsoft/agent-framework)_

### Deterministic Nodes in Agent Graphs

Not every step needs an LLM. Mixing deterministic functions with agent calls in
the same orchestration graph — with the same interface — prevents the common
failure of using an LLM where `json.loads()` suffices.

_Source:
[Microsoft Agent Framework](https://github.com/microsoft/agent-framework)_

## Heuristics

### When Designing Agent Systems

1. **State your intent, not your steps** -- declarative beats imperative
2. **Budget context like memory** -- every token has an opportunity cost
3. **Validate outputs, not just completion** -- "done" isn't "correct"
4. **Design for cold start** -- assume every session begins from zero
5. **Make handoffs explicit** -- structured summaries, not "it's in the chat"
6. **Registry before wiring** -- know what exists before connecting it

### When Debugging Agent Systems

1. **Check what the agent saw** -- bad input explains bad output
2. **Reproduce the context, not just the prompt** -- same prompt, different
   window, different result
3. **Look for semantic failure** -- the agent completed successfully and
   produced garbage
4. **Suspect the handoff** -- most failures happen at boundaries

## The Maturity Model

Where are you on the orchestration spectrum?

| Level | K8s Equivalent     | Agent Equivalent            | Indicator                              |
| ----- | ------------------ | --------------------------- | -------------------------------------- |
| 0     | Manual deployment  | Copy-paste prompts          | "I'll just run it myself"              |
| 1     | Shell scripts      | Single agent, manual review | "Claude handles the simple stuff"      |
| 2     | Docker Compose     | Multi-agent, structured     | "Agents coordinate through files"      |
| 3     | K8s with operators | Orchestrated with registry  | "The system routes work automatically" |
| 4     | Service mesh       | Context-aware routing       | Nobody is here yet                     |

Most teams are at level 1-2. Level 3 requires a registry and contracts. Level 4
requires solving context routing.

## Key Insight

You don't need K8s experience to orchestrate agents -- but if you have it,
recognize which instincts transfer and which deceive. The API and data model
matter more than the scheduler. Complexity must be earned by scale, not borrowed
from ambition.

## See Also

- [Agent Memory](agent-memory.md) -- Temporal tracking, cognitive layers, decay
- [Complexity](complexity.md) -- Essential vs accidental in orchestration design
- [Thinking](thinking.md) -- Systems thinking for feedback loops and delays
- [Agentic Workflows Lesson Plan](../learn/agentic-workflows-lesson-plan.md) --
  Progressive lessons on building agent systems
