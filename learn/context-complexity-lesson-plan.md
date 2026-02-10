# Managing Context and Complexity Lesson Plan

A progressive curriculum for treating context as a finite resource and
complexity as its overflow.

## Lesson 1: Context as Resource

**Goal:** Recognize that working memory is limited and learn techniques to stay
within its bounds.

### Concepts

Your brain holds roughly 7 plus or minus 2 items in working memory at once
(Miller, 1956). Chunking groups details into single units -- "HTTP status codes"
instead of "200, 301, 404, 500." When the number of items you must track exceeds
your capacity, you lose track, make mistakes, and slow down. Context is not
free. Every variable name, open file, and unresolved decision occupies a slot.
Effective engineers manage context the way systems manage memory: deliberately.

### Exercises

1. **Measure your working memory**

   Read this list once, then cover it and write down what you remember:

   ```text
   port 8080, retry 3, timeout 30s, TLS on, gzip off,
   max-conns 100, log-level debug, region us-east-1
   ```

   How many did you recall? Now chunk them:

   ```text
   Network:  port 8080, max-conns 100, region us-east-1
   Policy:   retry 3, timeout 30s
   Features: TLS on, gzip off, log-level debug
   ```

   Cover and recall again. Notice the difference.

2. **Audit a context-heavy task**

   Open a recent pull request you reviewed. List every piece of context you had
   to hold simultaneously (file names, variable meanings, business rules, test
   expectations). Count the items. Were there more than seven?

3. **Practice context offloading**

   Pick a problem you are working on. Write down the three things you keep
   forgetting or re-deriving. Put them in a scratch file or sticky note. Observe
   whether your thinking speeds up.

4. **Simulate context loss**

   Open a codebase you haven't touched in a month. Set a five-minute timer.
   Write down every question you have. These questions represent context that
   evaporated. How could the code or its docs have preserved that context for
   you?

### Checkpoint

Explain to a colleague (or a rubber duck) why "just remember it" is not a
strategy. Use the number 7 plus or minus 2 in your explanation.

---

## Lesson 2: Code-Level Context

**Goal:** Write code that minimizes what a reader must hold in mind.

### Concepts

John Ousterhout defines complexity as "anything related to the structure of a
system that makes it hard to understand and modify." At the code level, you
control cognitive load through naming, locality, and module depth. A good name
eliminates a lookup. Keeping related logic close reduces the number of files a
reader must open. Deep modules -- simple interfaces hiding complex
implementations -- let callers forget the details inside.

### Exercises

1. **Name audit**

   Review this function and rename for clarity:

   ```python
   def proc(d, t, f=False):
       if f:
           return d[:t]
       return d[t:]
   ```

   Rewrite:

   ```python
   def split_data(data, threshold, keep_before=False):
       if keep_before:
           return data[:threshold]
       return data[threshold:]
   ```

   Find three similarly opaque names in your own codebase and fix them.

2. **Measure locality**

   Pick a function in your project. Count how many other files you must open to
   understand what it does. If the count exceeds three, refactor to bring
   dependencies closer or extract a self-contained module.

3. **Deep vs shallow modules**

   Compare these two interfaces:

   ```go
   // Shallow: caller must manage details
   file, err := os.OpenFile(name, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0644)

   // Deep: simple interface, complexity hidden
   file, err := config.Save(name)
   ```

   Find a shallow interface in your codebase. Wrap it in a deeper module that
   hides at least two decisions from callers.

4. **Eliminate a "what does this do?" comment**

   Find a comment that explains what code does (not why). Refactor the code so
   the comment becomes unnecessary -- rename variables, extract a function, or
   restructure the logic.

### Checkpoint

Pick a 50-line function. Refactor it so a new team member can read it without
asking you any questions.

---

## Lesson 3: Architectural Context

**Goal:** Design system boundaries that limit how much any one person or team
must know.

### Concepts

Information hiding is the oldest trick in software architecture. A well-drawn
boundary means the team behind it can change internals without notifying
consumers. Contracts -- APIs, schemas, protocols -- are the only thing that
crosses the boundary. Microservices succeed not because they are small, but
because they reduce per-team context. When they fail, it is usually because the
boundaries were drawn wrong and teams still need cross-service knowledge to ship
features.

### Exercises

1. **Map context boundaries**

   Draw a box diagram of a system you work on. For each box, list what its
   developers must know about other boxes. If a box requires knowledge of more
   than two other boxes' internals, the boundary is leaky.

2. **Design a contract**

   Write an OpenAPI spec (or protobuf definition) for a service boundary:

   ```yaml
   paths:
     /users/{id}/preferences:
       get:
         summary: Get user preferences
         responses:
           "200":
             content:
               application/json:
                 schema:
                   type: object
                   properties:
                     theme:
                       type: string
                     locale:
                       type: string
   ```

   Ask yourself: can a consumer use this without reading the service's source
   code? If not, the contract is insufficient.

3. **Identify a leaky abstraction**

   Find a place in your architecture where a consumer must know implementation
   details to use the interface correctly (e.g., "you must call init() before
   query() or it crashes"). Propose a fix that moves that knowledge inside the
   boundary.

4. **Context cost of a change**

   Pick a recent feature. List every team or service that had to coordinate.
   Each coordination point is context cost. Could a different boundary placement
   have reduced it?

### Checkpoint

Explain why "shared database" is an anti-pattern from a context perspective, not
just a coupling perspective.

---

## Lesson 4: Session Context

**Goal:** Manage context windows in AI agent sessions as a concrete example of
finite context.

### Concepts

An AI context window is working memory made literal. A 200k-token window seems
large, but a medium codebase can exhaust it in minutes. CLAUDE.md files function
like Kubernetes ConfigMaps -- they inject persistent context into every session
so the agent does not start from zero. When a session grows long, the system
compacts (summarizes) old messages, which works like cache eviction: recent and
high-value context survives, the rest is lost. Every token you waste on
irrelevant context is a token unavailable for reasoning.

### Exercises

1. **Audit a CLAUDE.md**

   Read a project's CLAUDE.md (or create one). Score each line: does it prevent
   a repeated mistake (high value) or state something obvious (low value)?
   Remove the low-value lines.

   ```markdown
   # Good: prevents repeated mistakes

   - Run `make lint` before committing; CI uses the same rules
   - The payments module uses cents (int), never dollars (float)

   # Bad: obvious or stale

   - This project uses TypeScript
   - Created in 2023
   ```

2. **Measure context burn rate**

   Start a Claude Code session. After 10 interactions, ask the agent to
   summarize what it knows about your project. Compare its summary to your
   CLAUDE.md. What did it retain? What did it lose? The gap reveals your
   session's context efficiency.

3. **Practice context compaction**

   Take a 500-word project description and compress it to 100 words without
   losing actionable information. This is the same skill an LLM's compaction
   step performs.

   ```text
   Before (verbose): "Our application is a web-based platform that
   allows users to create, edit, and manage their personal task lists.
   It uses React on the frontend and Express on the backend, with
   PostgreSQL for data storage..."

   After (compact): "Task management app. React + Express + PostgreSQL.
   CRUD on task lists. Auth via JWT. Deploy to Fly.io. Run `make dev`
   for local setup."
   ```

4. **Design a session handoff file**

   After a productive Claude Code session, write a handoff note (under 200
   words) that a fresh session could use to continue the work. Include: what was
   accomplished, what remains, and any decisions made with their rationale.

### Checkpoint

Start a fresh AI session with only your handoff note as context. Verify it can
continue the work without re-deriving decisions.

---

## Lesson 5: State Management

**Goal:** Understand that where state lives determines how much context you need
to reason about it.

### Concepts

Stateless components are easy to reason about because each request carries its
own context. Stateful components accumulate context over time -- you must know
not just the current input but the history of inputs. Shared mutable state is
the worst case: every reader and writer must understand every other reader and
writer. This is why functional programming, immutable data, and event sourcing
exist -- they reduce the context needed to understand what happened and why.

### Exercises

1. **Classify state locations**

   Label each as stateless, stateful-local, or shared-mutable:

   ```text
   a) A pure function that computes tax from price and rate
   b) A database connection pool tracking active connections
   c) A global configuration object modified at runtime
   d) A REST endpoint that reads from a cache
   e) A WebSocket server tracking connected clients
   ```

   Answers: a) stateless, b) stateful-local, c) shared-mutable, d)
   stateful-local, e) shared-mutable.

2. **Refactor shared state**

   Take this shared-mutable pattern and refactor:

   ```python
   # Shared mutable state -- any function can modify
   app_state = {"retries": 0, "last_error": None}

   def handle_request():
       try:
           process()
       except Exception as e:
           app_state["retries"] += 1
           app_state["last_error"] = str(e)
   ```

   Refactor to pass state explicitly:

   ```python
   from dataclasses import dataclass

   @dataclass(frozen=True)
   class RequestState:
       retries: int = 0
       last_error: str | None = None

   def handle_request(state: RequestState) -> RequestState:
       try:
           process()
           return state
       except Exception as e:
           return RequestState(
               retries=state.retries + 1,
               last_error=str(e),
           )
   ```

3. **Map state flow**

   Pick a feature in your application. Draw where state is created, read,
   modified, and destroyed. Count the number of components that can write. Each
   writer adds context load for everyone who reads.

4. **Eliminate a global**

   Find a global variable or singleton in your codebase. Convert it to an
   explicit parameter passed through the call chain. Notice how the dependency
   becomes visible.

### Checkpoint

Explain to someone why "it works fine with a global" is a statement about the
present, not the future.

---

## Lesson 6: Knowledge Graphs and Registries

**Goal:** Build external memory systems that reduce what individuals must hold
in their heads.

### Concepts

Service registries, dependency graphs, runbooks, and ADRs (Architecture Decision
Records) are external memory. They answer questions that would otherwise require
interrupting a colleague or reading source code. Service discovery replaces "ask
Dave which port the auth service uses" with a lookup. A decision record replaces
"why did we choose Kafka?" with a searchable document. Every question you
externalize into a registry is one fewer item someone must carry in working
memory.

### Exercises

1. **Create an ADR**

   Document a recent technical decision:

   ```markdown
   # ADR-007: Use SQLite for Local Development

   ## Status

   Accepted

   ## Context

   Developers spend 15 minutes per day starting PostgreSQL locally. Test data is
   small (under 10MB). CI uses PostgreSQL for integration tests.

   ## Decision

   Use SQLite for local dev and unit tests. Keep PostgreSQL for CI and
   production.

   ## Consequences

   - Faster local startup
   - Must avoid PostgreSQL-specific SQL in application queries
   - CI catches dialect mismatches before merge
   ```

2. **Build a service map**

   Create a simple service registry as a YAML file:

   ```yaml
   services:
     auth:
       port: 8081
       owner: platform-team
       repo: github.com/org/auth-service
       depends_on: [postgres, redis]
     billing:
       port: 8082
       owner: payments-team
       repo: github.com/org/billing-service
       depends_on: [postgres, auth]
   ```

   Can a new hire find any service's owner and dependencies from this file
   alone?

3. **Audit tribal knowledge**

   List five things about your project that exist only in someone's head. For
   each, choose a home: CLAUDE.md, ADR, runbook, or code comment. Write at least
   two of them down.

4. **Test your external memory**

   Ask a teammate to answer these questions using only written artifacts (no
   asking humans):
   - What port does service X run on?
   - Why did we choose database Y?
   - How do I run the test suite?

   Every question they cannot answer from docs represents fragile context.

### Checkpoint

Verify that a new team member could set up the project and understand its
architecture without asking a single question in Slack.

---

## Lesson 7: Handoffs and Succession

**Goal:** Transfer context between people, sessions, and teams without loss.

### Concepts

Context loss during handoffs is the largest hidden cost in engineering. When
someone leaves a team, goes on vacation, or ends a pairing session, knowledge
walks out the door. The same applies to AI sessions -- each new session starts
from zero unless you prepare. Good handoffs are not brain dumps. They are
curated transfers that distinguish "must know now" from "can learn later." The
best handoff artifact is one the recipient can act on immediately without asking
follow-up questions.

### Exercises

1. **Write a rotation handoff**

   You are going on vacation. Write a handoff document (under 300 words)
   covering:

   ```markdown
   ## Active Work

   - PR #142: Awaiting review from security team. Ping @alice if no response by
     Wednesday.
   - Bug #89: Reproduced locally. Root cause is a race condition in the
     connection pool. Fix is drafted but untested.

   ## Ongoing Responsibilities

   - On-call: @bob is covering. Runbook is in docs/oncall.md.
   - Deploy cadence: Ship Tuesdays. Release checklist in docs/release.md.

   ## Landmines

   - Do not upgrade the `kafka-client` library. Version 3.x has a breaking
     change we have not migrated for. See ADR-012.
   ```

2. **Practice session succession**

   End a Claude Code session by writing a continuation prompt. Start a new
   session with only that prompt. Can the new session pick up where the old one
   left off?

   ```markdown
   ## Session Handoff: Auth Refactor

   ### Completed

   - Extracted JWT validation into middleware (src/middleware/auth.ts)
   - Added unit tests (tests/auth.test.ts) -- all passing

   ### Next Steps

   - Wire middleware into routes in src/routes/index.ts
   - Add integration test for expired token rejection

   ### Key Decisions

   - Chose jose library over jsonwebtoken for Edge runtime compat
   ```

3. **Pair with a handoff constraint**

   Pair-program for 25 minutes (one Pomodoro). At the end, the driver writes a
   three-sentence summary. The navigator continues from that summary alone.
   Evaluate what was lost.

4. **Design a team knowledge bus**

   Propose a lightweight system for your team where decisions and context are
   recorded as they happen -- not after the fact. Examples: a decisions channel
   in Slack with a bot that archives to ADRs, or a post-standup "today I
   learned" log.

### Checkpoint

Have someone read your handoff document and list three actions they would take.
If their list matches your intent, the handoff succeeded.

---

## Lesson 8: Complexity Budgets

**Goal:** Spend complexity deliberately on what matters and eliminate it
everywhere else.

### Concepts

Every system has a complexity budget -- the total cognitive load your team can
sustain. Essential complexity comes from the problem domain: you cannot simplify
it without changing the problem. Accidental complexity comes from your tools,
architecture, and historical choices: you can and should reduce it. The
discipline is knowing which is which. Spending your budget on accidental
complexity leaves less capacity for the essential kind. "Simplify" does not mean
"remove features." It means consolidating, hiding, and automating so that the
essential complexity is the only thing people think about.

### Exercises

1. **Classify complexity sources**

   Label each as essential or accidental:

   ```text
   a) Tax rules vary by jurisdiction         -> essential
   b) Three different logging frameworks      -> accidental
   c) Users need role-based access control    -> essential
   d) Deploy requires 14 manual steps         -> accidental
   e) Financial calculations need precision   -> essential
   f) Config split across env vars, YAML,
      and a database table                    -> accidental
   ```

2. **Calculate a complexity budget**

   List the top 10 things a new developer on your team must learn before they
   can ship their first feature. Separate essential items (domain knowledge,
   core architecture) from accidental items (build quirks, legacy workarounds).
   Set a goal: reduce the accidental list by half within a quarter.

   ```text
   Essential (keep):
   1. Domain model: orders, payments, fulfillment
   2. Event-driven architecture
   3. Multi-tenant data isolation

   Accidental (reduce):
   1. Two build systems (webpack + esbuild)  -> consolidate
   2. Manual database migration process      -> automate
   3. Undocumented env var requirements      -> add to .env.example
   ```

3. **Apply the second-system test**

   Pick a component you suspect is over-engineered. Ask: "If I rebuilt this from
   scratch today knowing what I know, would I build it the same way?" If not,
   write down what you would change. Estimate the cost of changing it now vs.
   carrying the complexity forever.

4. **Simplify one thing this week**

   Choose the smallest accidental complexity item from exercise 2. Eliminate it.
   Document what you did and how much context it removes from the "must know"
   list for new developers.

### Checkpoint

Present your team's complexity budget to a colleague. Can they identify which
items are essential vs. accidental? If they disagree, discuss -- the boundary is
often worth debating.

---

## Practice Projects

### Project 1: Context-Optimized Onboarding

Create an onboarding guide for your project that a new developer can follow
without asking questions. Include a CLAUDE.md, an ADR for the most important
architectural decision, and a service map. Test it by having someone (or a fresh
AI session) follow it end to end.

### Project 2: Session Continuity System

Build a workflow for long-running AI-assisted development. Create templates for
session handoff notes, design a naming convention for storing them, and write a
script that initializes a new session from the most recent handoff. Test across
three sequential sessions working on the same feature.

### Project 3: Complexity Audit

Audit a real codebase (yours or open-source). Produce a report that inventories
essential vs. accidental complexity, measures context load per module (files you
must open to understand it), and proposes three concrete simplifications.
Present the cost-benefit of each proposal.

---

## Quick Reference

| Principle            | Technique                                                    |
| -------------------- | ------------------------------------------------------------ |
| Working memory       | Chunk information; offload to external artifacts             |
| Code-level context   | Name well; keep related logic close; build deep modules      |
| Architectural bounds | Hide information behind contracts; draw boundaries at teams  |
| Session context      | Use CLAUDE.md; compact aggressively; write handoff notes     |
| State management     | Prefer stateless; make state explicit; avoid shared mutables |
| External memory      | ADRs, registries, runbooks -- reduce tribal knowledge        |
| Handoffs             | Curate transfers; distinguish "must know" from "learn later" |
| Complexity budgets   | Classify essential vs. accidental; spend deliberately        |

## See Also

- [Complexity](../why/complexity.md) -- Essential vs. accidental complexity
- [Thinking](../why/thinking.md) -- Mental models and systems thinking
- [Agent Orchestration](../how/agent-orchestration.md) -- Multi-agent context
  management
