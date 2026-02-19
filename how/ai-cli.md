# AI CLI Cheat Sheet

> Last updated: 2026-02-06

Command-line AI coding assistants: Claude Code, GitHub Copilot CLI, Cursor,
Cline.

## Context Management

### CLAUDE.md Structure

Recommended sections:

1. **Project Overview** — 1-2 sentences: what this is, primary
   language/framework
2. **Architecture** — Key directories, entry points, data flow
3. **Commands** — Build, test, lint, deploy commands
4. **Conventions** — Naming patterns, error handling, testing expectations
5. **Gotchas** — The weird auth module, special headers, files to avoid

### File Locations

| File                  | Scope                           | Git |
| --------------------- | ------------------------------- | --- |
| `~/.claude/CLAUDE.md` | All projects                    | No  |
| `./CLAUDE.md`         | Project root                    | Yes |
| `./CLAUDE.local.md`   | Project (personal)              | No  |
| `./src/CLAUDE.md`     | Subdirectory (loaded on demand) | Yes |
| `.cursorrules`        | Cursor (legacy)                 | Yes |
| `.cursor/rules/*.md`  | Cursor (scoped rules)           | Yes |

### What to Include

**Good — prevents mistakes:**

- "Use pnpm, not npm"
- "All API routes require auth middleware"
- "Never modify migrations after merge"

**Bad — use linters instead:**

- "Use 2-space indentation"
- "Always add semicolons"
- "Sort imports alphabetically"

Keep under 300 lines. Every line should prevent a specific mistake.

## Prompting Patterns

### Plan First, Code Second

```text
# Ask for a plan before implementation
"Before writing code, outline your approach for adding
user authentication. What files will change?"

# Review plan, then approve
"That approach looks good. Proceed with step 1."
```

### Context Packing

```text
# Provide constraints upfront
"Add pagination to the users API. Constraints:
- Use cursor-based pagination (not offset)
- Match existing endpoints in src/api/posts.ts
- Return max 50 items per page
- Include total count in response"

# Include examples of desired output
"Format error responses like this:
{ error: { code: 'INVALID_INPUT', message: '...' } }"
```

### Chunked Implementation

```text
# Break large tasks into steps
"Let's implement the checkout flow in steps:
1. First, create the cart summary component
2. Then add the payment form
3. Finally, wire up the order submission

Start with step 1."

# Verify before continuing
"Step 1 looks good. Proceed to step 2."
```

### Negative Constraints

```text
# Tell the AI what NOT to do
"Add form validation. Do NOT:
- Add new dependencies
- Modify the existing API
- Change the form layout"
```

## Workflow Modes

### Exploratory (Vibe Coding)

Good for prototypes, learning, throwaway code.

```text
# Open-ended generation
"Build a CLI tool that converts markdown to HTML"

# Iterate on results
"Add syntax highlighting for code blocks"
"Make it watch for file changes"
```

### Production (AI-Assisted Engineering)

Good for code that will be maintained.

```text
# Spec-driven development
"Implement the user service according to this spec:
[paste spec or reference file]"

# Test-first
"Write failing tests for the user service first,
then implement to make them pass"

# Incremental changes
"Add email validation to the signup form.
Show me the diff before applying."
```

### Debugging

```text
# Provide full context
"This test is failing:
[paste test output]

The relevant code is in src/auth/token.ts.
What's causing the failure?"

# Ask for hypotheses first
"Before fixing, list 3 possible causes ranked by likelihood"
```

## Verification Checklist

### Always Check

- [ ] **Logic correctness** — AI has 1.75× more logic errors than humans
- [ ] **Edge cases** — Empty inputs, nulls, boundary values
- [ ] **Error handling** — Failures should be graceful, not silent
- [ ] **Security** — 45% of AI code has security flaws (auth, injection, XSS)

### Before Merging

```bash
# Run the full test suite
npm test

# Check types
npm run typecheck

# Run linter
npm run lint

# Manual smoke test
# "Click through the UI yourself"
```

### Red Flags in AI Output

```javascript
// Overly clever solutions
// AI loves unnecessary abstractions

// Inconsistent patterns
// Different approach than existing code

// Missing error handling
try {
  doThing(); // No catch, no finally
}

// Hardcoded values that should be config
const API_URL = "http://localhost:3000"; // Should be env var

// Commented-out code or TODOs
// TODO: implement proper validation
```

## Tool Selection

### When to Use CLI Agents (Claude Code, Copilot CLI)

- Multi-file refactoring
- Running tests and fixing failures iteratively
- Exploring unfamiliar codebases
- Complex tasks requiring tool use (git, npm, etc.)

### When to Use IDE Copilots (Copilot, Cursor)

- Line-by-line completions while typing
- Quick boilerplate generation
- Tab-completing known patterns
- Real-time suggestions

### When to Go Manual

- Security-critical code (auth, crypto, payments)
- Complex business logic requiring domain knowledge
- When you can't explain what the AI wrote
- Debugging AI-generated bugs (irony is real)

## Version Control Discipline

### Commit Granularly

```bash
# Commit after each successful AI edit
git add -p                    # Review changes
git commit -m "Add user validation"

# Use commits as save points
git stash                     # Before risky AI operation
# ... AI makes changes ...
git diff                      # Review what changed
git checkout -- file.ts       # Revert if needed
```

### Isolate Experiments

```bash
# Use branches for AI experiments
git checkout -b ai/experiment-auth

# Or worktrees for parallel exploration
git worktree add ../project-experiment feature
```

## Anti-Patterns

### Blind Trust

```text
# Bad: accept without review
"Generate the authentication system" → merge

# Good: review everything
"Generate the authentication system" → review → test → iterate
```

### Prompt and Pray

```text
# Bad: vague request
"Make it better"

# Good: specific request
"Reduce the function complexity by extracting
the validation logic into a separate function"
```

### Context Starvation

```text
# Bad: no context
"Fix the bug"

# Good: full context
"Fix the null pointer in handleSubmit (src/form.ts:45).
The form data is undefined when the user double-clicks.
Here's the error: [paste error]"
```

### Skipping Tests

```text
# Bad: assume AI code works
"Generate the API endpoint" → deploy

# Good: verify behavior
"Generate the API endpoint" → write tests → verify → deploy
```

## Quick Reference

| Pattern         | Command/Approach                            |
| --------------- | ------------------------------------------- |
| Start session   | Review CLAUDE.md, state current goal        |
| Request plan    | "Outline your approach before coding"       |
| Chunk work      | "Let's do this in steps. Start with X"      |
| Add constraints | "Do NOT modify Y or add dependencies"       |
| Verify output   | Run tests, lint, manual check               |
| Review diff     | "Show me the changes before applying"       |
| Iterate         | "That's close, but change X to Y"           |
| Save progress   | `git commit` after each successful change   |
| Escape hatch    | `git checkout -- file` to revert AI changes |

## See Also

- [Claude Code Extensibility](claude-code.md) — Agents, hooks, plugins, MCP,
  memory, configuration
- [Git](git.md) — Version control for tracking AI changes
- [Shell](shell.md) — Commands AI agents execute
- [Debugging](../why/debugging.md) — Systematic approach to fixing AI bugs
- [Thinking](../why/thinking.md) — Mental models for evaluating AI suggestions
