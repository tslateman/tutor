# Agentic Workflows Lesson Plan

Orchestration patterns, failure modes, and engineering discipline for managing
AI agents that do real work.

## Lesson 1: The Agent as Worker

**Goal:** Distinguish agents from functions and identify when agent delegation
beats scripting.

### Concepts

An agent is a stochastic, stateful worker bounded by a finite context window.
Unlike a function, calling an agent twice with the same input may produce
different results. Agents maintain internal reasoning state that evolves as they
work, and they degrade as their context fills -- they do not simply fail. Think
of an agent less like a subprocess and more like a contractor: you give
instructions, they interpret and execute, and the quality depends on how well
you scoped the work.

The k8s parallel starts here. A container has resource limits (CPU, memory); an
agent has context limits (tokens, attention). A container runs a deterministic
image; an agent runs a probabilistic model. This distinction shapes every design
decision that follows.

### Exercises

1. **Compare agent vs script on the same task**

   ```bash
   # Script approach: deterministic, fast, brittle
   git log --oneline --since="1 week" | wc -l

   # Agent approach: flexible, slower, interpretive
   claude -p "How many commits landed this week? Summarize the themes."
   ```

   Run both. Note what the agent adds and what it costs.

2. **Observe stochastic output**

   ```bash
   # Run the same prompt three times, capture outputs
   for i in 1 2 3; do
     claude -p "List the 3 most important files in this repo" > /tmp/run-$i.txt
   done
   diff /tmp/run-1.txt /tmp/run-2.txt
   ```

   The outputs will vary. This is not a bug -- it is the fundamental property
   you must design around.

3. **Probe context boundaries**

   ```bash
   # Give an agent a task that exceeds what fits in context
   claude -p "Read every file in this repository and produce a \
     complete dependency graph with line-level resolution."
   ```

   Watch how the agent approximates, summarizes, or silently drops information.
   Context is a resource limit, not a suggestion.

### Checkpoint

Explain in one paragraph why "retry until it works" is a different strategy for
agents than for HTTP requests. Write it down.

---

## Lesson 2: Task Decomposition

**Goal:** Break work into agent-sized units that are independent,
context-fitting, and verifiable.

### Concepts

Good task decomposition determines whether agents succeed or flail. Each task
must fit within a single context window with room for reasoning. Tasks should be
independently verifiable -- you need to know if the output is correct without
understanding the agent's internal chain of thought. The best agent tasks have
clear inputs, concrete outputs, and objective success criteria.

This mirrors pod design in k8s: one concern per container, clear interfaces,
independent scaling. A monolithic task is like a monolithic container -- it
works until it does not, and then everything fails together.

### Exercises

1. **Decompose a refactoring task**

   ```markdown
   # Bad: monolithic task

   "Refactor the authentication system to use JWT"

   # Good: decomposed tasks

   1. "List all files that import or reference the current auth module"
   2. "Write a JWT token utility with sign/verify/refresh -- no integration"
   3. "Update the login endpoint to issue JWTs instead of session cookies"
   4. "Update the middleware to validate JWTs"
   5. "Write tests for the JWT utility"
   ```

   Write decompositions for a task in your own codebase.

2. **Test context fit**

   ```bash
   # Estimate whether a task fits in context
   # Rule of thumb: task description + relevant source + output < 60% of window
   wc -c $(git ls-files '*.ts' | head -20) | tail -1
   # If the source alone exceeds ~80K tokens, the task is too broad
   ```

3. **Define verification criteria before delegating**

   ```markdown
   # For each subtask, write the check FIRST

   Task: "Write a JWT utility module" Verify:

   - [ ] File exists at src/auth/jwt.ts
   - [ ] Exports sign(), verify(), refresh()
   - [ ] Tests pass: `npm test -- jwt`
   - [ ] No external dependencies beyond jsonwebtoken
   ```

4. **Identify coupling between tasks**

   ```bash
   # Use git to find files that change together (coupling signal)
   git log --oneline --name-only --since="3 months" | \
     awk '/^[a-f0-9]/{commit=$0; next} NF{print commit, $0}' | \
     sort -k2 | head -30
   ```

   Tasks touching coupled files should run sequentially, not in parallel.

### Checkpoint

Take a real feature request and decompose it into 4-6 agent tasks. Each task
should have: input files, output files, and a verification command.

---

## Lesson 3: Orchestration Patterns

**Goal:** Choose the right coordination pattern for multi-agent work.

### Concepts

Four patterns cover most orchestration needs. Fan-out/fan-in distributes
independent tasks to parallel agents and collects results. Pipeline chains
agents sequentially where each consumes the previous output. Hierarchy uses a
coordinator agent that delegates to specialist workers. Peer review sends output
from one agent to another for validation. The right pattern depends on task
dependencies and failure tolerance.

In k8s terms: fan-out is a Job with parallelism; pipeline is an init container
chain; hierarchy is an operator managing custom resources; peer review is a
readiness probe run by a different process.

### Exercises

1. **Fan-out with git worktrees**

   ```bash
   # Create isolated worktrees for parallel agents
   git worktree add /tmp/agent-1 -b agent/task-1
   git worktree add /tmp/agent-2 -b agent/task-2
   git worktree add /tmp/agent-3 -b agent/task-3

   # Launch agents in parallel, each in its own worktree
   cd /tmp/agent-1 && claude -p "Add input validation to user endpoints" &
   cd /tmp/agent-2 && claude -p "Add rate limiting middleware" &
   cd /tmp/agent-3 && claude -p "Add request logging middleware" &
   wait

   # Fan-in: review and merge results
   for i in 1 2 3; do
     echo "=== Agent $i ===" && git -C /tmp/agent-$i diff main
   done
   ```

2. **Pipeline pattern**

   ```bash
   # Agent 1: analyze → Agent 2: implement → Agent 3: test
   claude -p "Analyze src/api/ and list functions missing error handling" \
     > /tmp/analysis.md

   claude -p "$(cat /tmp/analysis.md)
   Add error handling to each function listed above." \

   claude -p "Review the changes in this repo. Run the tests. \
     Report which new error handlers work and which have issues."
   ```

3. **Hierarchy via Task tool**

   ```markdown
   # In a CLAUDE.md or direct prompt, instruct the coordinator:

   You are a coordinator. For each item in the task list:

   1. Use the Task tool to delegate implementation to a subagent
   2. Verify each result before proceeding
   3. If a subagent fails, retry with a more specific prompt
   4. Report final status of all tasks
   ```

4. **Peer review pattern**

   ```bash
   # Agent 1 writes code
   claude -p "Implement a rate limiter using token bucket algorithm" \
     > /tmp/implementation.md

   # Agent 2 reviews it
   claude -p "Review this implementation for correctness, edge cases, \
     and security issues:
   $(cat /tmp/implementation.md)" > /tmp/review.md
   ```

### Checkpoint

Implement fan-out across 3 worktrees for a real task. Merge the results and note
which conflicts arise.

---

## Lesson 4: Context Management

**Goal:** Treat context windows as resource budgets and learn to allocate them
effectively.

### Concepts

Context is the scarcest resource in agent systems. Every token of context
consumed by background information is a token unavailable for reasoning.
CLAUDE.md acts as configuration injection -- it shapes agent behavior without
consuming per-task context on repeated instructions. Include the minimum viable
context: the specific files needed, the constraints that matter, and the output
format expected. Exclude project history, unrelated code, and verbose
instructions that restate what the model already knows.

The k8s analogy: context is memory. You set resource requests and limits.
Overprovision context and you waste capacity; underprovision and the agent OOMs
-- not with a crash, but with degraded reasoning. There is no swap space.

### Exercises

1. **Audit your CLAUDE.md for signal density**

   ```bash
   # Count tokens roughly (1 token ~ 4 chars)
   wc -c CLAUDE.md | awk '{printf "~%d tokens\n", $1/4}'

   # Ask: does every line change agent behavior?
   # Remove anything that is "nice to know" but not actionable
   ```

2. **Compare context-heavy vs context-light prompts**

   ```bash
   # Heavy: paste entire file
   claude -p "$(cat src/server.ts)
   Add graceful shutdown handling to this server."

   # Light: reference by path, let the agent read what it needs
   claude -p "Add graceful shutdown handling to src/server.ts. \
     The server uses Express and listens on the port from env.PORT."
   ```

   Measure which produces better results and why.

3. **Build a task-specific context package**

   ```bash
   # Instead of "read everything", prepare a focused context file
   {
     echo "# Task Context"
     echo "## Relevant interfaces"
     sed -n '/^export interface/,/^}/p' src/types.ts
     echo "## Current implementation"
     cat src/auth/session.ts
     echo "## Test expectations"
     grep -A5 'describe.*session' test/auth.test.ts
   } > /tmp/task-context.md

   claude -p "$(cat /tmp/task-context.md)
   Migrate session auth to JWT. Preserve all existing test expectations."
   ```

4. **Use CLAUDE.md as persistent configuration**

   ```markdown
   # Project-level CLAUDE.md -- injected into every agent session

   # Keep this under 500 tokens

   ## Constraints

   - TypeScript strict mode, no `any`
   - Tests required for all public functions
   - Use existing error types from src/errors.ts

   ## Patterns

   - Repository pattern for data access
   - Result<T, E> for fallible operations (no thrown exceptions)
   ```

### Checkpoint

Reduce your CLAUDE.md to under 500 tokens while preserving all behavioral
constraints. Verify agents still follow the rules.

---

## Lesson 5: Multi-Agent Coordination

**Goal:** Manage shared state and prevent conflicts when multiple agents work
simultaneously.

### Concepts

Parallel agents create coordination problems identical to concurrent
programming: race conditions on shared files, conflicting assumptions about
system state, and merge conflicts when work recombines. Git worktrees provide
process isolation -- each agent works on an independent copy. Message passing
between agents happens through files, not shared memory. The coordinator must
detect and resolve conflicts during the fan-in phase, not hope they do not
occur.

Where the k8s analogy holds: worktrees are like separate pods with their own
filesystem. Where it breaks: pods share a network namespace; agents share a
codebase and must eventually merge into a single coherent state.

### Exercises

1. **Set up isolated agent workspaces**

   ```bash
   # Create a coordination directory
   mkdir -p /tmp/agents/{workspace,results,messages}

   # One worktree per agent
   git worktree add /tmp/agents/workspace/agent-a -b work/agent-a
   git worktree add /tmp/agents/workspace/agent-b -b work/agent-b

   # Shared message board (file-based message passing)
   echo '{"status": "ready", "agents": ["a", "b"]}' \
     > /tmp/agents/messages/coordinator.json
   ```

2. **Detect conflicts before they happen**

   ```bash
   # Before launching parallel agents, check for file overlap
   TASK_A_FILES="src/auth/login.ts src/auth/middleware.ts"
   TASK_B_FILES="src/auth/middleware.ts src/api/routes.ts"

   # Find overlap
   comm -12 \
     <(echo "$TASK_A_FILES" | tr ' ' '\n' | sort) \
     <(echo "$TASK_B_FILES" | tr ' ' '\n' | sort)

   # If overlap exists, serialize those tasks or split the file
   ```

3. **Implement a merge protocol**

   ```bash
   # After agents complete, merge systematically
   git switch main

   # Merge first agent (should be clean)
   git merge work/agent-a --no-edit

   # Merge second agent (may conflict)
   git merge work/agent-b --no-edit || {
     echo "Conflict detected. Files:"
     git diff --name-only --diff-filter=U
     # Option: delegate conflict resolution to another agent
     claude -p "Resolve the merge conflicts in these files. \
       Preserve the intent of both changes."
   }
   ```

4. **Use tmux for agent monitoring**

   ```bash
   # Create a monitoring session
   tmux new-session -d -s agents -n coordinator

   # Split into panes, one per agent
   tmux split-window -h -t agents:coordinator
   tmux split-window -v -t agents:coordinator.1

   # Watch agent output in each pane
   tmux send-keys -t agents:coordinator.0 \
     "tail -f /tmp/agents/results/agent-a.log" C-m
   tmux send-keys -t agents:coordinator.1 \
     "tail -f /tmp/agents/results/agent-b.log" C-m

   tmux attach -t agents
   ```

### Checkpoint

Run two agents in parallel on tasks that touch one overlapping file. Resolve the
merge conflict and verify the combined result is correct.

---

## Lesson 6: Failure Modes

**Goal:** Detect, classify, and recover from agent failures -- especially the
silent ones.

### Concepts

Agents fail in two fundamentally different ways. Crash failures are obvious: the
process exits, the API returns an error, the tool call is malformed. Semantic
failures are invisible: the agent produces plausible output that is subtly
wrong, incomplete, or misaligned with intent. Semantic failure is the harder
problem because it passes all syntactic checks. Degradation is a third mode --
the agent does not fail but gradually loses coherence as context fills up, like
a process leaking memory until it thrashes.

Crash failures map to k8s liveness probes. Semantic failures need readiness
probes -- tests that verify the agent can still do meaningful work, not just
respond. There is no automatic restart that fixes a semantic failure; you need
fresh context.

### Exercises

1. **Build a semantic verification layer**

   ```bash
   # Agent writes code, then a separate check validates it
   claude -p "Add input validation to src/api/users.ts"

   # Semantic checks (not just "does it compile")
   npx tsc --noEmit                          # Type check
   npm test                                   # Existing tests pass
   claude -p "Review src/api/users.ts. Does every public endpoint \
     validate all input parameters? List any gaps."  # Semantic review
   ```

2. **Detect context degradation**

   ```bash
   # Ask the agent to summarize what it has done -- if the summary
   # is wrong or incomplete, context is degraded
   claude -p "List every file you have modified in this session \
     and summarize each change in one sentence."

   # Compare against actual changes
   git diff --name-only
   # Divergence between agent's summary and reality = degradation
   ```

3. **Implement retry with context reset**

   ```bash
   # Bad retry: same context, same result
   # Good retry: fresh session, refined prompt, explicit prior output

   # First attempt captures output
   claude -p "Write a connection pool for PostgreSQL" > /tmp/attempt-1.ts

   # If attempt 1 has issues, retry with feedback in a new session
   claude -p "Here is a previous attempt at a PostgreSQL connection pool:
   $(cat /tmp/attempt-1.ts)

   Problems found:
   - Does not handle connection timeout
   - Missing max pool size enforcement

   Write a corrected version that fixes these specific issues."
   ```

4. **Know when to intervene**

   ```markdown
   # Decision tree for agent failure response:

   #

   # Agent produced output?

   # No -> crash failure -> retry (up to 2x) -> intervene manually

   # Yes -> check semantic correctness

   # Correct?

   # Yes -> accept

   # No -> classify the error

   # Wrong approach -> rewrite prompt, fresh session

   # Right approach, wrong details -> provide corrections, retry

   # Incoherent -> context degraded -> fresh session, smaller task
   ```

### Checkpoint

Intentionally give an agent a task too large for its context. Document the
degradation signals you observe. Retry with a decomposed version and compare
results.

---

## Lesson 7: Memory and Continuity

**Goal:** Maintain knowledge across sessions, handoffs, and context compaction.

### Concepts

Agent sessions are ephemeral. When a session ends, everything the agent learned
disappears unless explicitly persisted. Continuity across sessions requires
deliberate externalization: CLAUDE.md files, structured handoff documents, and
project memory files. Knowledge graphs and persistent memory systems extend this
further, but the foundation is simple -- write down what the next session needs
to know. Patterns that survive compaction are concrete and specific: file paths,
function signatures, architectural decisions with rationale. Patterns that do
not survive: vague summaries, implicit assumptions, reasoning chains without
conclusions.

### Exercises

1. **Write a session handoff document**

   ```markdown
   # Session Handoff -- 2025-01-15

   ## Completed

   - Migrated auth from sessions to JWT (src/auth/jwt.ts)
   - Updated 4 of 7 API endpoints

   ## Remaining

   - Endpoints not yet migrated: /admin/_, /webhook/_, /health
   - Each needs: replace req.session with JWT validation

   ## Decisions Made

   - Refresh tokens stored in httpOnly cookies (not localStorage)
   - Token expiry: 15min access, 7d refresh
   - Rationale: balances security vs UX for this app's threat model

   ## Gotchas

   - src/middleware/cors.ts must allow credentials for cookie flow
   - Tests in test/auth/ use a mock JWT -- see test/helpers/jwt.ts
   ```

2. **Build project memory into CLAUDE.md**

   ```markdown
   # Append architectural decisions to CLAUDE.md

   # These persist across every future session

   ## Architecture Decisions

   - Auth: JWT with httpOnly refresh cookies (decided 2025-01-15)
   - DB: Repository pattern, no raw SQL outside src/db/
   - Errors: Result<T, E> pattern, never throw in business logic
   - API: REST, versioned at /api/v1/, OpenAPI spec in docs/
   ```

3. **Test compaction resilience**

   ```bash
   # Write two versions of the same information
   # Version A: vague (will not survive compaction)
   echo "We decided to go with the better auth approach" > /tmp/vague.md

   # Version B: concrete (will survive compaction)
   echo "Auth uses JWT. Access tokens expire in 15min. \
   Refresh tokens in httpOnly cookies expire in 7d. \
   See src/auth/jwt.ts." > /tmp/concrete.md

   # Start a new session with each and ask the agent to act on it
   claude -p "$(cat /tmp/concrete.md)
   What token expiry should the /admin endpoints use?"
   ```

4. **Create a knowledge persistence structure**

   ```bash
   # Project memory directory
   mkdir -p .claude/memory

   # Structured knowledge files
   cat > .claude/memory/architecture.md << 'EOF'
   # Architecture

   ## Service Boundaries
   - API server: src/api/ (Express, port 3000)
   - Worker: src/worker/ (Bull queue processor)
   - DB: PostgreSQL 15, migrations in src/db/migrations/

   ## Integration Points
   - API -> Worker: Redis queue (Bull)
   - API -> DB: connection pool (src/db/pool.ts, max 20)
   - External: Stripe webhooks at /webhook/stripe
   EOF
   ```

### Checkpoint

End a session mid-task. Write a handoff document. Start a new session with only
that document. Verify the new session can continue the work without re-reading
the entire codebase.

---

## Lesson 8: Operating at Scale

**Goal:** Monitor, scale, and maintain agent systems that run continuously.

### Concepts

Scaling agent work means decomposing into more tasks, not running more agents on
the same task. Replication does not help when the bottleneck is context, not
compute. Monitoring agents requires health checks that go beyond "is it running"
to "is it producing correct output." The context routing problem is deciding
which information each agent needs -- too little and it fails, too much and it
degrades. At scale, this becomes the primary engineering challenge.

The k8s parallel is strongest here: horizontal scaling through decomposition
(microservices, not bigger VMs), health checks that verify semantic correctness
(readiness probes, not just liveness), and scheduling that matches tasks to
available context capacity (resource requests and limits). Where it breaks: you
cannot simply restart a degraded agent and expect it to resume -- you must
reconstruct its context from external state.

### Exercises

1. **Build an agent health check**

   ```bash
   #!/bin/bash
   # agent-health.sh -- verify an agent session is still coherent

   WORKSPACE=$1

   # Liveness: is the process running?
   pgrep -f "claude.*$WORKSPACE" > /dev/null || {
     echo "DEAD: agent process not found"; exit 1
   }

   # Readiness: can it still reason about its task?
   cd "$WORKSPACE"
   ACTUAL_FILES=$(git diff --name-only main | sort)
   # Compare against expected task scope
   # Drift from expected files = possible degradation
   ```

2. **Implement a task queue**

   ```bash
   # Simple file-based task queue for agent orchestration
   QUEUE_DIR=/tmp/agent-queue
   mkdir -p "$QUEUE_DIR"/{pending,active,done,failed}

   # Enqueue tasks
   for task in "Add tests for auth" "Add tests for api" "Add tests for db"; do
     echo "$task" > "$QUEUE_DIR/pending/$(date +%s)-$RANDOM.task"
   done

   # Worker loop (one per agent)
   while task=$(ls "$QUEUE_DIR/pending/" | head -1) && [ -n "$task" ]; do
     mv "$QUEUE_DIR/pending/$task" "$QUEUE_DIR/active/$task"
     PROMPT=$(cat "$QUEUE_DIR/active/$task")

     if claude -p "$PROMPT"; then
       mv "$QUEUE_DIR/active/$task" "$QUEUE_DIR/done/$task"
     else
       mv "$QUEUE_DIR/active/$task" "$QUEUE_DIR/failed/$task"
     fi
   done
   ```

3. **Monitor parallel agents with tmux**

   ```bash
   # Dashboard session for monitoring agent fleet
   tmux new-session -d -s dashboard -n overview

   # Top pane: agent status summary
   tmux send-keys -t dashboard:overview \
     "watch -n5 'ls /tmp/agent-queue/*/  | head -20'" C-m

   # Split for individual agent logs
   tmux split-window -v -t dashboard:overview
   tmux send-keys -t dashboard:overview.1 \
     "tail -f /tmp/agents/results/*.log" C-m

   # Separate window for git status across worktrees
   tmux new-window -t dashboard -n git
   tmux send-keys -t dashboard:git \
     "watch -n10 'for wt in /tmp/agents/workspace/agent-*; do \
       echo \"=== \$wt ===\"; git -C \$wt diff --stat main; done'" C-m

   tmux attach -t dashboard
   ```

4. **Solve a context routing problem**

   ```bash
   # Given a task, determine the minimum context an agent needs
   # This is the scheduling problem for agent systems

   TASK="Fix the N+1 query in the user list endpoint"

   # Step 1: identify relevant files (static analysis)
   grep -rl "user.*list\|listUsers\|getUsers" src/ > /tmp/relevant.txt

   # Step 2: include dependency chain (one level deep)
   while read -r file; do
     grep -oP "from ['\"]\./(.*?)['\"]" "$file" | \
       sed "s|from ['\"]./||;s|['\"]||g" >> /tmp/relevant.txt
   done < /tmp/relevant.txt

   sort -u /tmp/relevant.txt > /tmp/context-manifest.txt

   # Step 3: estimate context budget
   xargs wc -c < /tmp/context-manifest.txt | tail -1 | \
     awk '{printf "Context needed: ~%d tokens\n", $1/4}'
   ```

### Checkpoint

Set up a 3-agent fleet processing a queue of 6 tasks. Monitor progress via tmux.
Identify which tasks succeed, which fail, and why. Write a post-mortem for any
failures.

---

## Practice Projects

### Project 1: Codebase Migration

Pick a real migration (JS to TS, REST to GraphQL, or similar). Decompose it into
8-12 agent tasks. Execute them across worktrees with fan-out/fan-in. Track
success rates and failure modes. Write a retrospective.

### Project 2: Agent CI Pipeline

Build a pipeline where Agent A writes a feature, Agent B writes tests for it,
and Agent C reviews both. Automate the pipeline with a shell script. Run it 5
times on different features and measure how often the pipeline produces correct,
tested code without human intervention.

### Project 3: Self-Healing Agent System

Design and build a coordinator that monitors worker agents, detects degradation
(via semantic health checks), terminates degraded workers, and relaunches them
with fresh context plus a handoff document. Run a sustained workload for 30
minutes and measure how many tasks complete correctly.

---

## Quick Reference

| Concept           | Pattern                         | Anti-Pattern                      |
| ----------------- | ------------------------------- | --------------------------------- |
| Task sizing       | Fits in 60% of context window   | "Read everything and fix it"      |
| Parallelism       | Git worktrees, isolated state   | Multiple agents in same directory |
| Verification      | Separate agent reviews output   | Trust first output                |
| Context           | Minimal, specific, actionable   | Dump entire codebase              |
| Failure detection | Semantic checks, diff audits    | "It compiled so it works"         |
| Retry strategy    | Fresh session, refined prompt   | Same prompt, same context         |
| Memory            | Concrete facts in files         | Vague summaries in chat history   |
| Scaling           | More tasks, not more agents     | Replicate agents on same task     |
| Coordination      | File-based message passing      | Shared mutable state              |
| Health checks     | Readiness (semantic) + liveness | Process alive = healthy           |

## See Also

- [Agent Orchestration](../how/agent-orchestration.md) -- Patterns, delegation,
  worktrees, monitoring
- [Complexity](../why/complexity.md) -- Essential vs accidental complexity in
  agent systems
- [Problem Solving](../why/problem-solving.md) -- Systematic debugging for
  non-deterministic systems
