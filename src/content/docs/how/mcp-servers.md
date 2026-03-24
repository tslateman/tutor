---
title: "MCP Servers Cheat Sheet"
description:
  Building Model Context Protocol servers — tools, resources, prompts,
  transports, and deployment in TypeScript and Python.
---

## Quick Reference

| I want to...                   | Use                                             |
| ------------------------------ | ----------------------------------------------- |
| Create a server (TS)           | `new McpServer({ name, version })`              |
| Create a server (Python)       | `FastMCP("name")`                               |
| Expose a callable function     | Tool (`tools/list`, `tools/call`)               |
| Expose read-only data          | Resource (`resources/read`)                     |
| Expose an interaction template | Prompt (`prompts/get`)                          |
| Connect locally                | stdio transport                                 |
| Connect remotely               | Streamable HTTP transport                       |
| Test interactively             | `npx @modelcontextprotocol/inspector`           |
| Configure in Claude Code       | `.mcp.json` at project or `~/.claude/.mcp.json` |

## Protocol Overview

MCP follows a client-server architecture over JSON-RPC 2.0. A **host** (Claude
Code, Claude Desktop, VS Code) creates one **client** per **server**. Each
client maintains a dedicated connection to its server.

```text
Host (AI Application)
├── Client 1 ──── Server A (local, stdio)
├── Client 2 ──── Server B (local, stdio)
└── Client 3 ──── Server C (remote, HTTP)
```

### Lifecycle

1. Client sends `initialize` with its capabilities and protocol version
2. Server responds with its capabilities (tools, resources, prompts)
3. Client sends `notifications/initialized`
4. Normal operation: list/call/read exchanges
5. Client closes connection or terminates subprocess

### Capability Negotiation

```json
{
  "capabilities": {
    "tools": { "listChanged": true },
    "resources": { "subscribe": true, "listChanged": true },
    "prompts": { "listChanged": true }
  }
}
```

Declare only the primitives your server supports. `listChanged` enables dynamic
notifications when available items change.

## Server Primitives

Three building blocks define what a server exposes.

| Primitive    | Purpose                       | Control Model | Discovery        | Execution        |
| ------------ | ----------------------------- | ------------- | ---------------- | ---------------- |
| **Tool**     | Executable function           | Model-driven  | `tools/list`     | `tools/call`     |
| **Resource** | Read-only data                | App-driven    | `resources/list` | `resources/read` |
| **Prompt**   | Reusable interaction template | User-driven   | `prompts/list`   | `prompts/get`    |

## Tools

Tools let the LLM perform actions — query a database, call an API, modify a
file.

### Tool Definition (JSON Schema)

```json
{
  "name": "search_issues",
  "description": "Search project issues by keyword and status",
  "inputSchema": {
    "type": "object",
    "properties": {
      "query": {
        "type": "string",
        "description": "Search keyword"
      },
      "status": {
        "type": "string",
        "enum": ["open", "closed", "all"],
        "description": "Filter by issue status"
      }
    },
    "required": ["query"]
  }
}
```

### Tool Result

Results return a `content` array supporting multiple types.

| Content Type    | Field      | Use                       |
| --------------- | ---------- | ------------------------- |
| `text`          | `text`     | Plain text responses      |
| `image`         | `data`     | Base64-encoded image      |
| `audio`         | `data`     | Base64-encoded audio      |
| `resource_link` | `uri`      | Link to a server resource |
| `resource`      | `resource` | Embedded resource content |

Set `isError: true` in the result to signal a tool execution failure without
raising a protocol-level error.

```json
{
  "content": [
    { "type": "text", "text": "Rate limit exceeded. Retry after 60s." }
  ],
  "isError": true
}
```

## Resources

Resources expose data the application reads for context — file contents,
database schemas, API responses.

### Resource Definition

```json
{
  "uri": "db://schema/users",
  "name": "users-table-schema",
  "description": "Column definitions for the users table",
  "mimeType": "application/json"
}
```

### Resource Templates

Parameterized URIs using RFC 6570 templates.

```json
{
  "uriTemplate": "db://tables/{table}/schema",
  "name": "table-schema",
  "description": "Schema for any database table",
  "mimeType": "application/json"
}
```

### Common URI Schemes

| Scheme     | Use                                         |
| ---------- | ------------------------------------------- |
| `file://`  | Filesystem-like resources                   |
| `https://` | Web resources clients can fetch directly    |
| `git://`   | Version control integration                 |
| Custom     | Domain-specific (`db://`, `slack://`, etc.) |

## Prompts

Prompts define parameterized templates that generate structured messages.

### Prompt Definition

```json
{
  "name": "code_review",
  "description": "Review code for quality and suggest improvements",
  "arguments": [
    { "name": "code", "description": "The code to review", "required": true },
    {
      "name": "language",
      "description": "Programming language",
      "required": false
    }
  ]
}
```

### Prompt Result

`prompts/get` returns an array of messages with roles.

```json
{
  "messages": [
    {
      "role": "user",
      "content": {
        "type": "text",
        "text": "Review this Python code for clarity and correctness:\n\ndef add(a, b):\n    return a + b"
      }
    }
  ]
}
```

## Building a Server in TypeScript

### Setup

```bash
npm install @modelcontextprotocol/sdk zod
npm install -D @types/node typescript
```

### Server with Tools

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({
  name: "my-server",
  version: "1.0.0",
});

// Register a tool — Zod schemas define inputSchema automatically
server.registerTool(
  "search_issues",
  {
    description: "Search project issues by keyword",
    inputSchema: {
      query: z.string().describe("Search keyword"),
      status: z
        .enum(["open", "closed", "all"])
        .default("open")
        .describe("Filter by status"),
    },
  },
  async ({ query, status }) => {
    const results = await searchIssues(query, status);
    return {
      content: [{ type: "text", text: JSON.stringify(results, null, 2) }],
    };
  },
);
```

### Server with Resources

```typescript
server.registerResource(
  "schema",
  "db://schema/users",
  { description: "Users table schema", mimeType: "application/json" },
  async () => ({
    contents: [
      {
        uri: "db://schema/users",
        mimeType: "application/json",
        text: JSON.stringify(getUsersSchema()),
      },
    ],
  }),
);
```

### Server with Prompts

```typescript
server.registerPrompt(
  "code_review",
  {
    description: "Review code for quality issues",
    arguments: [
      { name: "code", description: "Code to review", required: true },
    ],
  },
  async ({ code }) => ({
    messages: [
      {
        role: "user",
        content: {
          type: "text",
          text: `Review this code for clarity, correctness, and style:\n\n${code}`,
        },
      },
    ],
  }),
);
```

### Start with stdio Transport

```typescript
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("MCP server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
```

**Logging rule for stdio:** Never use `console.log()` — it writes to stdout and
corrupts JSON-RPC messages. Use `console.error()` for all diagnostic output.

## Building a Server in Python

### Setup

```bash
uv add "mcp[cli]"
# or
pip install "mcp[cli]"
```

### Server with Tools

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("my-server")


@mcp.tool()
async def search_issues(query: str, status: str = "open") -> str:
    """Search project issues by keyword.

    Args:
        query: Search keyword
        status: Filter by status (open, closed, all)
    """
    results = await do_search(query, status)
    return json.dumps(results, indent=2)
```

FastMCP reads type hints and docstrings to generate `inputSchema` automatically.
No manual JSON Schema needed.

### Server with Resources

```python
@mcp.resource("db://schema/{table}")
def get_table_schema(table: str) -> str:
    """Return the schema for a database table."""
    schema = load_schema(table)
    return json.dumps(schema)
```

### Server with Prompts

```python
@mcp.prompt()
def code_review(code: str, language: str = "python") -> str:
    """Review code for quality issues."""
    return f"Review this {language} code for clarity and correctness:\n\n{code}"
```

### Context Object

Inject `Context` for logging, progress, and sampling.

```python
from mcp.server.fastmcp import Context


@mcp.tool()
async def long_analysis(repo: str, ctx: Context) -> str:
    """Analyze a repository for security issues."""
    await ctx.info(f"Starting analysis of {repo}")
    await ctx.report_progress(progress=0, total=100)

    results = await analyze(repo)

    await ctx.report_progress(progress=100, total=100)
    return results
```

### Structured Output with Pydantic

```python
from pydantic import BaseModel


class AnalysisResult(BaseModel):
    score: float
    issues: list[str]
    passed: bool


@mcp.tool()
def analyze_code(code: str) -> AnalysisResult:
    """Run static analysis on code."""
    return AnalysisResult(score=8.5, issues=["unused import"], passed=True)
```

### Start with stdio Transport

```python
if __name__ == "__main__":
    mcp.run(transport="stdio")
```

**Logging rule for stdio:** Never use `print()` — it writes to stdout. Use
`print(..., file=sys.stderr)` or the `logging` module.

## Transport Layers

### stdio

The client spawns the server as a subprocess. Messages flow over stdin/stdout as
newline-delimited JSON-RPC.

| Attribute | Detail                                  |
| --------- | --------------------------------------- |
| Launch    | Client spawns server process            |
| Latency   | Minimal (no network)                    |
| Auth      | Inherits OS-level process permissions   |
| Scaling   | One client per server process           |
| Best for  | Local tools, CLI integrations, dev/test |

### Streamable HTTP

The server runs as an HTTP service. Client sends POST requests; server may
respond with JSON or open an SSE stream.

| Attribute | Detail                                          |
| --------- | ----------------------------------------------- |
| Launch    | Server runs independently                       |
| Latency   | Network round-trip                              |
| Auth      | Bearer tokens, API keys, OAuth                  |
| Scaling   | Multiple clients per server                     |
| Best for  | Remote APIs, shared services, production deploy |

```python
# Python: Streamable HTTP
mcp.run(transport="streamable-http")
```

```python
# Python: Mount on existing ASGI app
from starlette.applications import Starlette
from starlette.routing import Mount

app = Starlette(routes=[Mount("/mcp", app=mcp.streamable_http_app())])
```

### Transport Decision Guide

| Scenario                            | Transport       |
| ----------------------------------- | --------------- |
| Local filesystem or database access | stdio           |
| Running inside Docker on same host  | stdio           |
| Shared team service behind auth     | Streamable HTTP |
| Public API integration              | Streamable HTTP |
| Development and testing             | stdio           |

## Testing

### MCP Inspector

Interactive browser-based tool for exercising all server capabilities.

```bash
# Test a local TypeScript server
npx @modelcontextprotocol/inspector node build/index.js

# Test a local Python server
npx @modelcontextprotocol/inspector uv --directory ./myserver run server.py

# Test an npm package
npx @modelcontextprotocol/inspector npx @modelcontextprotocol/server-filesystem /tmp

# Test a PyPI package
npx @modelcontextprotocol/inspector uvx mcp-server-git --repository ~/code/repo
```

The Inspector provides tabs for tools, resources, prompts, and a notification
pane for logs.

### Unit Testing Handlers

Test tool logic independently of the transport layer.

```python
import pytest

from server import search_issues


@pytest.mark.asyncio
async def test_search_issues():
    result = await search_issues("authentication", status="open")
    parsed = json.loads(result)
    assert len(parsed) > 0
    assert all(issue["status"] == "open" for issue in parsed)
```

```typescript
import { describe, it, expect } from "vitest";
import { searchIssues } from "./handlers.js";

describe("search_issues", () => {
  it("filters by status", async () => {
    const result = await searchIssues("auth", "open");
    expect(result.length).toBeGreaterThan(0);
    result.forEach((issue) => expect(issue.status).toBe("open"));
  });
});
```

### Testing Workflow

1. Unit test each handler function in isolation
2. Use the Inspector to verify protocol compliance
3. Integration test with a real client (Claude Code, Claude Desktop)

## Client Configuration

### Claude Code / Claude Desktop

```json
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "node",
      "args": ["./build/index.js"]
    },
    "remote-api": {
      "type": "sse",
      "url": "https://mcp.example.com/sse",
      "env": { "API_KEY": "..." }
    }
  }
}
```

| File                  | Scope    | Git | Purpose               |
| --------------------- | -------- | --- | --------------------- |
| `.mcp.json`           | Project  | Yes | Team-shared servers   |
| `~/.claude/.mcp.json` | Personal | No  | Personal tool servers |

### Environment Variables

Pass secrets through `env` — never hard-code them in server source.

```json
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
    }
  }
}
```

## Error Handling

### Two Error Levels

| Level                | Mechanism                 | When                                     |
| -------------------- | ------------------------- | ---------------------------------------- |
| Protocol error       | JSON-RPC `error` response | Unknown tool, invalid params, server bug |
| Tool execution error | `isError: true` in result | API failure, bad input, business logic   |

### Standard JSON-RPC Error Codes

| Code     | Meaning            |
| -------- | ------------------ |
| `-32600` | Invalid request    |
| `-32601` | Method not found   |
| `-32602` | Invalid params     |
| `-32603` | Internal error     |
| `-32002` | Resource not found |

### Validation Pattern (TypeScript)

```typescript
server.registerTool(
  "create_issue",
  {
    description: "Create a new issue",
    inputSchema: {
      title: z.string().min(1).max(200).describe("Issue title"),
      priority: z.enum(["low", "medium", "high"]).describe("Priority level"),
      labels: z.array(z.string()).max(10).optional().describe("Labels"),
    },
  },
  async ({ title, priority, labels }) => {
    try {
      const issue = await createIssue({ title, priority, labels });
      return {
        content: [{ type: "text", text: `Created issue #${issue.id}` }],
      };
    } catch (err) {
      return {
        content: [{ type: "text", text: `Failed: ${err.message}` }],
        isError: true,
      };
    }
  },
);
```

## Security

### Input Validation

- Validate every tool input — use Zod (TS) or Pydantic (Python) for schema
  enforcement
- Sanitize string inputs before passing to shell commands, SQL, or file paths
- Reject unexpected fields; never pass raw input to `eval()` or template engines

### Capability Scoping

- Declare only the primitives your server needs
- Scope tools narrowly — one action per tool, not a god-tool that does
  everything
- Use `annotations.audience` to control which content reaches the user vs. the
  model

### Secrets Management

- Pass secrets via environment variables, never in source code
- Use `env` in `.mcp.json` for injection at launch time
- For Streamable HTTP, use OAuth or bearer tokens — never embed keys in URLs

### Stdio Isolation

- Stdio servers inherit the host process's permissions — scope filesystem access
- Validate all file paths against an allow-list
- Run containerized servers for untrusted workloads

## Deployment Patterns

| Pattern           | Transport       | Use Case                                |
| ----------------- | --------------- | --------------------------------------- |
| Local process     | stdio           | Dev tools, personal utilities           |
| Docker container  | stdio           | Isolated local tools, reproducible envs |
| HTTP service      | Streamable HTTP | Shared team servers, cloud deployment   |
| Sidecar container | stdio           | K8s pods, co-located with app           |

### Docker with stdio

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY build/ ./build/
USER node
ENTRYPOINT ["node", "build/index.js"]
```

```json
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "docker",
      "args": ["run", "-i", "--rm", "my-mcp-server:latest"]
    }
  }
}
```

The `-i` flag keeps stdin open for JSON-RPC communication. Skip `-t` — TTY mode
corrupts the binary stream.

### Docker with Streamable HTTP

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
USER nobody
EXPOSE 8000
CMD ["python", "server.py"]
```

```python
# server.py
mcp = FastMCP("my-server")
# ... register tools, resources, prompts ...

if __name__ == "__main__":
    mcp.run(transport="streamable-http", host="0.0.0.0", port=8000)
```

## Anti-patterns

| Anti-pattern                      | Fix                                                      |
| --------------------------------- | -------------------------------------------------------- |
| God-tool with 15+ parameters      | Split into focused tools with 2-5 params each            |
| Missing or vague descriptions     | Write descriptions the LLM uses to decide when to call   |
| No error messages in tool results | Return `isError: true` with a human-readable explanation |
| `console.log()` in stdio servers  | Use `console.error()` — stdout is the JSON-RPC channel   |
| Secrets hard-coded in source      | Inject via `env` in `.mcp.json` or environment variables |
| Returning raw stack traces        | Catch errors, return sanitized messages                  |
| No input validation               | Use Zod (TS) or Pydantic (Python) on every tool          |
| Exposing all data as tools        | Use resources for read-only data, tools for actions      |
| Blocking sync calls in Python     | Use `async def` handlers with `httpx` or `aiohttp`       |
| No pagination on large lists      | Implement cursor-based pagination for `*/list` methods   |

## See Also

- [Claude Code Extensibility](claude-code.md) — Using MCP servers from the
  client side, configuration, and `.mcp.json` setup
- [AI CLI Patterns](ai-cli.md) — Claude Code CLI workflows and prompting
  patterns
- [TypeScript](typescript.md) — TypeScript language reference for SDK
  development
- [Docker](docker.md) — Containerizing MCP servers for isolated deployment
