# Agent Orchestration Cheat Sheet

Coordinate multiple AI coding agents for parallel and complex work.

## Core Concepts

### Task Decomposition

Break work into appropriately-sized chunks:

```text
Too large:  "Build the authentication system"
Too small:  "Add import statement for bcrypt"
Right size: "Implement password hashing with bcrypt, including
             hash generation and verification functions"
```

Decomposition criteria:

- **Independence** — Can this run without waiting for other tasks?
- **Context fit** — Does the agent have enough info to complete it?
- **Verifiability** — Can you tell if it succeeded?

### Context Boundaries

Each agent has limited context. Decide what to include:

| Include                      | Exclude                          |
| ---------------------------- | -------------------------------- |
| Relevant file paths          | Unrelated code                   |
| API contracts / interfaces   | Full implementation details      |
| Constraints and requirements | Historical discussions           |
| Expected output format       | Alternative approaches not taken |

## Orchestration Patterns

### Fan-Out / Fan-In

Parallel independent work, then merge.

```text
                    ┌─► Agent A (feature 1) ─┐
Orchestrator ───────┼─► Agent B (feature 2) ─┼───► Merge
                    └─► Agent C (feature 3) ─┘
```

Use when: Features don't share files, tests are independent.

### Pipeline

Sequential handoff between specialists.

```text
Research ──► Plan ──► Implement ──► Review ──► Test
```

Use when: Each stage needs output from the previous.

### Hierarchy

Lead agent decomposes, spawns workers.

```text
Lead Agent
    ├── analyzes task
    ├── creates subtasks
    └── spawns specialists
            ├── Agent A (backend)
            ├── Agent B (frontend)
            └── Agent C (tests)
```

Use when: Scope unclear upfront, needs dynamic decomposition.

### Peer Review

One writes, another critiques.

```text
Implementer ──► code ──► Reviewer ──► feedback ──► Implementer
```

Use when: Quality matters, catching blind spots.

## Claude Code Native Orchestration

### Task Tool (Subagents)

Spawn focused subagents from main conversation:

```markdown
Use Task tool with:

- subagent_type: "Explore" for codebase research
- subagent_type: "Plan" for architecture design
- subagent_type: "general-purpose" for multi-step work
- subagent_type: "Bash" for command execution
```

Subagent prompt tips:

- State the goal explicitly
- Specify output format
- Include relevant file paths
- Set clear boundaries ("only modify src/auth/")

### Parallel Subagents

Launch multiple in one message for concurrent execution:

```markdown
"Research the authentication patterns in this codebase" → Task: Explore agent

"Find all API endpoints that need auth" → Task: Explore agent (parallel)

"Check how tests mock authentication" → Task: Explore agent (parallel)
```

### CLAUDE.md for Shared Context

All agents inherit project instructions:

```markdown
# CLAUDE.md

## Architecture

- API routes in src/routes/
- Business logic in src/services/
- All endpoints require JWT auth except /health

## Conventions

- Use zod for validation
- Errors return { error: string, code: number }
- Tests use vitest with in-memory SQLite
```

## External Orchestration

### Agent of Empires

Terminal session manager for multiple AI agents.

```bash
# Install
cargo install agent-of-empires

# Launch TUI dashboard
aoe

# Create new session
aoe new --agent claude-code --branch feature/auth

# List sessions
aoe list

# Attach to session
aoe attach <session-name>

# View session status
aoe status
```

Within tmux session:

```bash
Ctrl+b d     # Detach (session keeps running)
Ctrl+b [     # Scroll mode
Ctrl+b c     # New window
Ctrl+b n/p   # Next/prev window
```

### Git Worktrees for Isolation

Each agent works on separate branch without conflicts:

```bash
# Create worktree for agent
git worktree add ../project-feature-auth feature/auth
git worktree add ../project-feature-api feature/api

# List worktrees
git worktree list

# Agent A works in ../project-feature-auth
# Agent B works in ../project-feature-api
# No merge conflicts during parallel work

# When done, merge and clean up
git checkout main
git merge feature/auth
git merge feature/api
git worktree remove ../project-feature-auth
git worktree remove ../project-feature-api
```

### tmux Direct Usage

Manage agent sessions manually:

```bash
# Create named session
tmux new-session -d -s agent-auth
tmux new-session -d -s agent-api

# Send command to session
tmux send-keys -t agent-auth 'claude' Enter
tmux send-keys -t agent-auth 'Implement JWT auth in src/auth/' Enter

# View session
tmux attach -t agent-auth

# List sessions
tmux list-sessions

# Kill session
tmux kill-session -t agent-auth
```

## Delegation Prompts

### Clear Task Prompt

```markdown
## Task

Implement rate limiting middleware for the Express API.

## Context

- API routes are in src/routes/
- Existing middleware pattern in src/middleware/auth.ts
- Use redis client from src/lib/redis.ts

## Requirements

- 100 requests per minute per IP
- Return 429 with retry-after header
- Bypass for /health endpoint

## Output

- Create src/middleware/rateLimit.ts
- Add middleware to src/app.ts
- Write tests in src/middleware/rateLimit.test.ts
```

### Research Prompt

```markdown
## Goal

Understand how error handling works in this codebase.

## Questions to Answer

1. Where are errors caught and transformed?
2. What error format do API responses use?
3. How are errors logged?
4. Are there custom error classes?

## Output Format

Bullet points with file:line references.
```

### Review Prompt

```markdown
## Task

Review the changes in src/auth/ for security issues.

## Focus Areas

- Input validation
- Authentication bypass risks
- Secrets handling
- SQL/NoSQL injection

## Output Format

List issues with severity (critical/high/medium/low), file location, and
suggested fix.
```

## Monitoring and Intervention

### Health Checks

Signs an agent is stuck:

- No file changes for extended period
- Repeating same action
- Error loops without progress
- Asking questions it should know

### When to Intervene

| Situation                    | Action                         |
| ---------------------------- | ------------------------------ |
| Wrong direction              | Stop early, redirect           |
| Missing context              | Provide file contents, clarify |
| Stuck on error               | Debug together, unblock        |
| Scope creep                  | Remind of boundaries           |
| Conflicting with other agent | Coordinate, define ownership   |

### Graceful Handoff

When passing work between agents:

```markdown
## Handoff: Auth Implementation → Review

### Completed

- JWT generation in src/auth/jwt.ts
- Login endpoint in src/routes/auth.ts
- Tests passing (12/12)

### Ready for Review

Files changed:

- src/auth/jwt.ts (new)
- src/routes/auth.ts (modified)
- src/middleware/requireAuth.ts (new)

### Open Questions

- Should refresh tokens be stored in Redis or DB?
- Token expiry: 15min proposed, confirm?
```

## Failure Handling

### Retry Strategy

```text
Attempt 1: Original prompt
Attempt 2: Add more context, simplify scope
Attempt 3: Break into smaller pieces
Attempt 4: Human intervention
```

### Preventing Cascading Failures

- Validate outputs before passing to next stage
- Use feature flags for incomplete work
- Keep main branch stable, merge only verified work
- Set timeouts for long-running agents

## Anti-Patterns

| Anti-Pattern             | Better Approach                          |
| ------------------------ | ---------------------------------------- |
| Vague delegation         | Explicit goals, files, output format     |
| Too many parallel agents | Start with 2-3, scale based on results   |
| No verification          | Review outputs before merging            |
| Shared mutable files     | Isolate via worktrees or clear ownership |
| Fire and forget          | Monitor progress, intervene early        |
| Over-orchestrating       | Some tasks don't need coordination       |

## Quick Reference

| Task                      | Approach                            |
| ------------------------- | ----------------------------------- |
| Independent features      | Fan-out with worktrees              |
| Sequential stages         | Pipeline with handoff prompts       |
| Unknown scope             | Hierarchy with lead agent           |
| Quality-critical          | Peer review pattern                 |
| Quick research            | Claude Code Task with Explore agent |
| Long-running work         | External tool (AoE, tmux)           |
| Shared codebase knowledge | CLAUDE.md with conventions          |

## See Also

- [Orchestration Mental Model](../why/orchestration.md) — K8s-to-agents
  parallels, context routing, failure modes
- [Agentic Workflows Lesson Plan](../learn/agentic-workflows-lesson-plan.md) —
  Progressive lessons on building agent systems

## Resources

- [Agent of Empires](https://github.com/njbrake/agent-of-empires)
- [Claude-Flow](https://github.com/ruvnet/claude-flow)
- [Microsoft AI Agent Patterns](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns)
- [OpenAI Multi-Agent Docs](https://openai.github.io/openai-agents-python/multi_agent/)
