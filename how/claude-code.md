# Claude Code Extensibility Cheat Sheet

Agents, commands, hooks, plugins, MCP servers, memory, and configuration.

## Extensibility Model

Six extension points, each solving a different problem.

| Component | What It Does                  | Location                | Trigger            |
| --------- | ----------------------------- | ----------------------- | ------------------ |
| Agent     | Autonomous worker with tools  | `.claude/agents/*.md`   | Auto or Task tool  |
| Skill     | Loaded prompt (slash command) | `.claude/commands/*.md` | User types `/name` |
| Command   | Alias for skill (legacy term) | `.claude/commands/*.md` | User types `/name` |
| Hook      | Shell script on event         | `.claude/settings.json` | System event fires |
| Plugin    | Bundled agents+skills+hooks   | `.claude/plugins/`      | Install + auto     |
| MCP       | External tool server          | `.mcp.json`             | Tool call          |

### Scoping

Every component exists at two scopes:

| Scope    | Path prefix  | Shared via git | Use for                   |
| -------- | ------------ | -------------- | ------------------------- |
| Project  | `./.claude/` | Yes            | Repo-specific conventions |
| Personal | `~/.claude/` | No             | Cross-project workflows   |

Skills in `~/.claude/commands/` appear in every project. Skills in
`./.claude/commands/` appear only in that repo.

## Agents

Custom autonomous workers with restricted tool access.

### File Structure

```yaml
# .claude/agents/research-analyst.md
---
name: research-analyst
description: "Deep research combining web sources and repo content"
tools:
  - Read
  - Glob
  - Grep
  - WebSearch
  - WebFetch
---
You are a research analyst for a reference repository. Search the web and
existing guides, then produce structured findings. Do not create or modify
files.
```

### Frontmatter Fields

| Field         | Required | Purpose                                            |
| ------------- | -------- | -------------------------------------------------- |
| `name`        | Yes      | Display name, used for `subagent_type` in Task     |
| `description` | Yes      | Drives automatic agent selection — make it precise |
| `tools`       | No       | Restrict available tools (default: all)            |

### Built-in Agent Types

Available as `subagent_type` values in the Task tool:

| Type              | Tools                     | Use For                       |
| ----------------- | ------------------------- | ----------------------------- |
| `general-purpose` | All                       | Multi-step implementation     |
| `Explore`         | Read-only (no Edit/Write) | Codebase search and analysis  |
| `Plan`            | Read-only (no Edit/Write) | Architecture design           |
| `Bash`            | Bash only                 | Command execution             |
| `test-runner`     | Read, Glob, Bash          | Detect language and run tests |
| `code-simplifier` | All                       | Refine code for clarity       |

Custom agents in `.claude/agents/` appear alongside built-in types.

### Agent Selection

Claude selects agents by matching the task description against each agent's
`description` field. Write descriptions that state **when** to use the agent,
not just what it does.

```yaml
# Weak — doesn't say when to trigger
description: "Analyzes code"

# Strong — states the trigger condition
description: "Deep research combining web sources and existing repo content. Use when investigating a topic before writing new guides."
```

## Skills and Commands

Prompt templates invoked via `/name` from the CLI.

### File Structure

```yaml
# .claude/commands/deep-research.md
---
description: Thorough parallel research with session persistence
allowed-tools: [Task, Read, Glob, Grep, Write, WebSearch, WebFetch, Bash]
---

Research a topic using parallel agents with session management.

## Input

The user's message contains the topic to investigate.

## Step 1: Decompose

Identify 3-7 independent research stages...
```

### Frontmatter Fields

| Field           | Required | Purpose                                |
| --------------- | -------- | -------------------------------------- |
| `description`   | Yes      | Shown in `/` autocomplete menu         |
| `allowed-tools` | No       | Restrict which tools the skill can use |

### Dynamic Arguments

Skills receive the user's message after the `/command` as `$ARGUMENTS`:

```text
User types:  /deep-research agent memory systems
Skill sees:  "agent memory systems" as the input
```

Reference files with `@path/to/file` in the prompt body — Claude resolves these
at invocation time.

### Skill vs Agent Decision

| Choose... | When...                                          |
| --------- | ------------------------------------------------ |
| Skill     | User triggers it explicitly with `/name`         |
| Agent     | Claude should auto-select based on task context  |
| Both      | Wrap an agent invocation inside a skill template |

## Hooks

Shell commands that fire on system events.

### Configuration

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": "~/scripts/validate-bash.sh"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "command": "prettier --write $CLAUDE_FILE_PATH"
      }
    ],
    "PreCompact": [
      {
        "matcher": "",
        "command": "~/scripts/save-context.sh"
      }
    ]
  }
}
```

### Hook Events

| Event              | Fires When                 | Common Use                     |
| ------------------ | -------------------------- | ------------------------------ |
| `PreToolUse`       | Before a tool executes     | Block dangerous commands       |
| `PostToolUse`      | After a tool executes      | Auto-format, lint, log         |
| `Stop`             | Agent completes its turn   | Notification, cleanup          |
| `SubagentStop`     | Subagent completes         | Collect results                |
| `PreCompact`       | Before context compression | Save state before memory loss  |
| `SessionStart`     | New session begins         | Load context, set env          |
| `SessionEnd`       | Session closes             | Persist state                  |
| `UserPromptSubmit` | User sends a message       | Inject context, validate input |
| `Notification`     | System notification fires  | External alerts                |

### Hook Response

Hooks communicate back via stdout JSON:

```json
{
  "decision": "block",
  "reason": "Command contains rm -rf"
}
```

| Decision   | Effect                         |
| ---------- | ------------------------------ |
| `allow`    | Proceed (default if no output) |
| `block`    | Prevent the tool call          |
| (any text) | Injected as context for Claude |

### Environment Variables in Hooks

| Variable              | Available In      | Contains                   |
| --------------------- | ----------------- | -------------------------- |
| `$CLAUDE_FILE_PATH`   | Write, Edit hooks | Path of the file modified  |
| `$CLAUDE_TOOL_INPUT`  | PreToolUse        | JSON of tool parameters    |
| `$CLAUDE_TOOL_OUTPUT` | PostToolUse       | JSON of tool result        |
| `$CLAUDE_SESSION_ID`  | All               | Current session identifier |

## Plugins

Bundled packages of agents, skills, hooks, and MCP servers.

### Structure

```text
my-plugin/
├── plugin.json          # Manifest
├── agents/
│   └── reviewer.md
├── commands/
│   └── review.md
├── skills/
│   └── analyze.md
└── hooks/
    └── pre-commit.sh
```

### Manifest

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Code review automation",
  "components": {
    "agents": ["agents/reviewer.md"],
    "commands": ["commands/review.md"],
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Bash",
          "command": "${CLAUDE_PLUGIN_ROOT}/hooks/pre-commit.sh"
        }
      ]
    }
  }
}
```

Use `${CLAUDE_PLUGIN_ROOT}` for paths relative to the plugin directory.

### Installation

```bash
# From local path
claude plugin add ./my-plugin

# From npm
claude plugin add @scope/my-plugin

# From marketplace template
claude plugin add claude-code-templates/review-plugin
```

## MCP Servers

External tool providers via Model Context Protocol.

### Configuration

```json
{
  "mcpServers": {
    "linear": {
      "type": "sse",
      "url": "https://mcp.linear.app/sse",
      "env": { "LINEAR_API_KEY": "..." }
    },
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path"]
    }
  }
}
```

### File Locations

| File                  | Scope    | Git | Use For                 |
| --------------------- | -------- | --- | ----------------------- |
| `.mcp.json`           | Project  | Yes | Team-shared MCP servers |
| `~/.claude/.mcp.json` | Personal | No  | Personal tool servers   |

### Server Types

| Type    | Transport | Use For                             |
| ------- | --------- | ----------------------------------- |
| `stdio` | stdin/out | Local CLI tools (filesystem, git)   |
| `sse`   | HTTP SSE  | Remote APIs (Linear, Notion, Slack) |

## Settings and Permissions

### Settings Hierarchy

Higher entries override lower:

```text
1. Managed policy      (organization-enforced)
2. CLI arguments        (--flag for this session)
3. Local settings      (.claude/settings.local.json)
4. Project settings    (.claude/settings.json)
5. User settings       (~/.claude/settings.json)
```

### Permission Modes

| Mode                | Behavior                                    |
| ------------------- | ------------------------------------------- |
| `default`           | Ask for each tool use                       |
| `acceptEdits`       | Auto-allow file edits, ask for Bash         |
| `plan`              | Require plan approval before implementation |
| `delegate`          | Team lead approves teammate plans           |
| `dontAsk`           | Auto-allow everything                       |
| `bypassPermissions` | Skip all permission checks                  |

### Allow/Deny Rules

```json
{
  "permissions": {
    "allow": ["Bash(npm test)", "Bash(make *)", "Edit", "Write"],
    "deny": ["Bash(rm -rf *)", "Bash(git push --force*)"]
  }
}
```

Patterns support glob syntax. `deny` takes precedence over `allow`.

## Memory System

### CLAUDE.md Hierarchy

```text
~/.claude/CLAUDE.md                  # Personal defaults (all projects)
./CLAUDE.md                          # Project root (committed)
./CLAUDE.local.md                    # Project personal (gitignored)
./src/CLAUDE.md                      # Subdirectory (loaded on demand)
./src/auth/CLAUDE.md                 # Deeper nesting works too
```

Subdirectory CLAUDE.md files load only when Claude reads files in that
directory. Use them for module-specific conventions.

### Auto Memory

Claude maintains a persistent memory directory per project:

```text
~/.claude/projects/{project-path-slug}/memory/MEMORY.md
```

- First 200 lines of `MEMORY.md` load into every system prompt
- Create topic files (`patterns.md`, `debugging.md`) for detailed notes
- Link topic files from `MEMORY.md` to keep the index concise

### Rules

Scoped instructions with path-based targeting:

```yaml
# .claude/rules/tests.md
---
path: "**/*.test.ts"
---
Use vitest. Mock external services. Assert both success and failure cases.
```

Rules activate only when Claude works on files matching the `path` glob.

### @-imports

Reference files inline in CLAUDE.md:

```markdown
## Architecture

@src/ARCHITECTURE.md

## API Conventions

@docs/api-style-guide.md
```

Referenced files load their content into Claude's context at session start.

## Context Management

### Window Size

Default context: 200K tokens. Extended context aliases provide 1M tokens:

```bash
# Use extended context model
claude --model claude-sonnet-4-5-20250929
```

### Compaction

When context fills, Claude compresses earlier messages. Control this with:

- **PreCompact hook** — save state before compression happens
- **Structured handoff** — write summaries to files before compaction
- **Keep CLAUDE.md lean** — it reloads after every compaction

### Strategies to Stay Under Budget

| Strategy               | How                                               |
| ---------------------- | ------------------------------------------------- |
| Subagents              | Offload research to Task agents (separate window) |
| Progressive disclosure | Start with summaries, drill into files on demand  |
| File-based state       | Write findings to disk, read back when needed     |
| Lean context files     | Keep CLAUDE.md under 300 lines                    |

## Model Selection

### Effort Levels

Control reasoning depth without switching models:

```bash
# Quick completion (less thinking)
claude --effort low

# Default balance
claude --effort medium

# Deep reasoning
claude --effort high
```

### Model Routing for Agents

Match model to task complexity when spawning subagents:

| Task Complexity   | Model    | Use For                                   |
| ----------------- | -------- | ----------------------------------------- |
| Data gathering    | `haiku`  | File enumeration, listings, simple lookup |
| Standard analysis | `sonnet` | Code analysis, documentation, patterns    |
| Complex reasoning | `opus`   | Architecture, cross-cutting concerns      |

```markdown
<!-- In Task tool call -->

model: "haiku" subagent_type: "general-purpose" prompt: "List all files matching
\*.test.ts and count assertions per file"
```

## Agent Teams

Coordinate multiple agents working on shared tasks.

### Team Lifecycle

```text
1. TeamCreate         → creates team + shared task list
2. TaskCreate (×N)    → populate work items
3. Task (×N)          → spawn teammates with team_name
4. TaskUpdate         → assign work via owner field
5. SendMessage        → coordinate between teammates
6. TaskUpdate         → mark tasks completed
7. shutdown_request   → gracefully stop teammates
8. TeamDelete         → clean up team files
```

### Task Assignment

```text
Team lead creates tasks → assigns owner → teammate claims and works →
marks complete → checks TaskList for next item
```

Teammates prefer tasks in ID order (lowest first). Tasks support `blockedBy`
dependencies to enforce ordering.

### Communication

| Method        | Use For                                |
| ------------- | -------------------------------------- |
| `SendMessage` | Direct message to one teammate         |
| `broadcast`   | Critical announcements (use sparingly) |
| `TaskList`    | Check shared progress                  |
| `TaskUpdate`  | Signal completion or blockers          |

Messages deliver automatically — no polling needed. Teammates go idle between
turns; sending a message wakes them.

## Quick Reference

| I want to...              | Use                                        |
| ------------------------- | ------------------------------------------ |
| Add a custom worker       | `.claude/agents/name.md`                   |
| Create a slash command    | `.claude/commands/name.md`                 |
| Auto-format on file write | PostToolUse hook                           |
| Block dangerous commands  | PreToolUse hook with `"decision": "block"` |
| Add external tools        | `.mcp.json` with server config             |
| Share project conventions | `./CLAUDE.md` (committed)                  |
| Keep personal preferences | `~/.claude/CLAUDE.md`                      |
| Persist learnings         | Auto memory `MEMORY.md`                    |
| Scope rules to file types | `.claude/rules/name.md` with `path` glob   |
| Run parallel research     | Task tool with multiple agents             |
| Coordinate a team         | TeamCreate + TaskCreate + Task             |

## See Also

- [AI CLI Patterns](ai-cli.md) — Prompting, verification, workflow modes
- [Agent Orchestration](agent-orchestration.md) — Multi-agent coordination
  patterns, worktrees, delegation prompts
- [Orchestration Mental Model](../why/orchestration.md) — K8s-to-agents
  parallels, context routing, failure modes
- [Agent Memory](../why/agent-memory.md) — Temporal tracking, cognitive layers,
  decay, retrieval patterns
