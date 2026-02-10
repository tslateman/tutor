# API Design Cheat Sheet

Design decisions and tradeoffs for building APIs that survive contact with real
clients, real networks, and real scale.

## REST vs GraphQL vs gRPC

### When to Use What

| Criteria        | REST                            | GraphQL                         | gRPC                                 |
| --------------- | ------------------------------- | ------------------------------- | ------------------------------------ |
| **Best for**    | Public APIs, CRUD services      | Client-driven data fetching     | Internal microservices               |
| **Strengths**   | Simple, cacheable, tooling      | Flexible queries, no over-fetch | Binary, typed, streaming             |
| **Weaknesses**  | Over-fetching, many round trips | Caching hard, query complexity  | Browser support poor, steep learning |
| **Transport**   | HTTP/1.1+                       | HTTP/1.1+                       | HTTP/2                               |
| **Schema**      | OpenAPI (optional)              | SDL (required)                  | Protobuf (required)                  |
| **Caching**     | HTTP caching works natively     | Requires application-level      | No HTTP caching                      |
| **Error model** | HTTP status codes               | 200 with errors array           | Status codes + details               |

### Decision Tree

```text
Is the client a browser or mobile app with varied data needs?
├── Yes → Do clients need to compose queries across many entities?
│         ├── Yes → GraphQL
│         └── No  → REST
└── No  → Is this service-to-service on a fast network?
          ├── Yes → Do you need streaming or high throughput?
          │         ├── Yes → gRPC
          │         └── No  → REST or gRPC (team preference)
          └── No  → REST (widest compatibility)
```

**Heuristic:** REST is the safe default. Choose GraphQL when you have many
client types with different data needs. Choose gRPC when you control both ends
and need speed.

## URL and Resource Design

### Nouns, Not Verbs

Resources are things. The HTTP method is the verb.

```text
GET    /users          # list users
POST   /users          # create user
GET    /users/42       # get one user
PUT    /users/42       # replace user
PATCH  /users/42       # partial update
DELETE /users/42       # delete user
```

**Wrong:** `/getUser`, `/createUser`, `/deleteUser/42`

### Nesting vs Flat

Nest only one level deep to express direct ownership:

```text
GET /users/42/orders        # orders belonging to user 42
GET /orders/99              # order by its own ID (not /users/42/orders/99)
```

**Heuristic:** If the child resource has its own identity, give it a top-level
endpoint. Deep nesting (`/a/1/b/2/c/3`) couples clients to your data model and
makes URLs brittle.

### Path Parameters vs Query Parameters

| Use            | Path parameter                | Query parameter               |
| -------------- | ----------------------------- | ----------------------------- |
| **Identity**   | `/users/42`                   | Never — identity goes in path |
| **Filtering**  | No                            | `/users?role=admin`           |
| **Sorting**    | No                            | `/users?sort=-created_at`     |
| **Pagination** | No                            | `/users?page=2&limit=20`      |
| **Required**   | Usually (identifies resource) | Usually optional              |

## Pagination Strategies

| Strategy         | How It Works            | Strengths                      | Weaknesses                                 |
| ---------------- | ----------------------- | ------------------------------ | ------------------------------------------ |
| **Offset/Limit** | `?offset=40&limit=20`   | Simple, random page access     | Slow at large offsets, unstable on inserts |
| **Cursor**       | `?cursor=eyJpZCI6NDJ9`  | Stable across inserts, fast    | Opaque, no random page access              |
| **Keyset**       | `?after_id=42&limit=20` | Fast (index scan), transparent | Requires sortable column, no random access |

**Offset** works until it does not. At 1M rows, `OFFSET 999980` scans and
discards nearly a million rows.

**Cursor-based** pagination encodes the position opaquely (often base64). The
server decodes it to a keyset query internally. Clients cannot jump to page N
but can always get the next page efficiently.

**Keyset** is the transparent version of cursor. Clients send the last seen
value: `WHERE id > 42 ORDER BY id LIMIT 20`. Fast at any depth because the
database uses the index directly.

**Heuristic:** Use offset for admin UIs with small datasets. Use cursor or
keyset for anything user-facing or large.

## Error Format Standards

### Problem Details (RFC 9457)

A standard format so every error looks the same:

```json
{
  "type": "https://api.example.com/errors/insufficient-funds",
  "title": "Insufficient Funds",
  "status": 422,
  "detail": "Account 12345 has $10.00; transfer requires $50.00.",
  "instance": "/transfers/abc-123"
}
```

| Field      | Purpose                              | Required |
| ---------- | ------------------------------------ | -------- |
| `type`     | URI identifying the error class      | Yes      |
| `title`    | Human-readable summary               | Yes      |
| `status`   | HTTP status code (redundant, useful) | No       |
| `detail`   | Specific explanation for this case   | No       |
| `instance` | URI for this specific occurrence     | No       |

### Error Codes

| Approach          | Pros                          | Cons                  |
| ----------------- | ----------------------------- | --------------------- |
| **String enums**  | Self-documenting, greppable   | Longer payloads       |
| **Numeric codes** | Compact, familiar (SQL, HTTP) | Requires lookup table |

**Heuristic:** String enums (`INSUFFICIENT_FUNDS`) for public APIs — clients
should not need a lookup table. Numeric codes only when bandwidth matters or
convention demands it.

## Versioning Approaches

| Strategy            | Example                               | Strengths              | Weaknesses                        |
| ------------------- | ------------------------------------- | ---------------------- | --------------------------------- |
| **URL path**        | `/v1/users`                           | Obvious, easy to route | Proliferates base URLs            |
| **Query parameter** | `/users?version=1`                    | Keeps URL clean        | Easy to forget, caching confusion |
| **Header**          | `Accept: application/vnd.api.v1+json` | Cleanest URL           | Hidden, harder to test in browser |

**Heuristic:** URL versioning for public APIs — visibility and simplicity win.
Header versioning for internal APIs where teams control clients. Query
parameters are the worst of both worlds.

**The deeper truth:** Versioning is failure management. The best strategy is to
evolve the schema without breaking changes and version only when you must.

## Rate Limiting Design

### Algorithms

| Algorithm          | How It Works                                   | Best For                       |
| ------------------ | ---------------------------------------------- | ------------------------------ |
| **Token bucket**   | Bucket fills at steady rate, requests drain it | Allowing bursts within a rate  |
| **Sliding window** | Count requests in a moving time window         | Strict, even distribution      |
| **Fixed window**   | Count resets at interval boundaries            | Simple, but allows edge bursts |

### Response Headers

```text
X-RateLimit-Limit: 100        # max requests per window
X-RateLimit-Remaining: 42     # requests left in current window
X-RateLimit-Reset: 1625097600 # UTC epoch when window resets
Retry-After: 30               # seconds to wait (on 429 response)
```

### Granularity

| Level            | Key                   | Use Case                     |
| ---------------- | --------------------- | ---------------------------- |
| **Per-user**     | API key or auth token | Default for most APIs        |
| **Per-endpoint** | User + endpoint       | Protect expensive operations |
| **Global**       | None                  | Emergency circuit breaker    |
| **Tiered**       | Subscription plan     | Free vs paid differentiation |

## Idempotency

### Why It Matters

Networks fail. Clients retry. Without idempotency, retries create duplicates —
double charges, duplicate orders, repeated notifications.

### HTTP Method Idempotency

| Method   | Idempotent | Safe | Notes                                     |
| -------- | ---------- | ---- | ----------------------------------------- |
| `GET`    | Yes        | Yes  | Read-only by definition                   |
| `HEAD`   | Yes        | Yes  | Like GET but no body                      |
| `PUT`    | Yes        | No   | Full replacement — same input, same state |
| `DELETE` | Yes        | No   | Deleting twice yields same result         |
| `POST`   | **No**     | No   | Each call may create a new resource       |
| `PATCH`  | **No**     | No   | Depends on patch semantics                |

### Idempotency Keys

Make non-idempotent operations safe by requiring a client-generated key:

```text
POST /payments
Idempotency-Key: a1b2c3d4-e5f6-7890-abcd-ef1234567890

{...payment body...}
```

The server stores the key with the response. On retry, it returns the stored
response instead of re-executing. Keys should expire (24-48 hours is common).

## Authentication Patterns

| Pattern       | Complexity | Security   | Best For                            |
| ------------- | ---------- | ---------- | ----------------------------------- |
| **API keys**  | Low        | Low-medium | Server-to-server, internal tools    |
| **OAuth 2.0** | High       | High       | Third-party access, user delegation |
| **JWT**       | Medium     | Medium     | Stateless auth, microservices       |

**API keys** are simple but blunt — they identify the application, not the user.
Rotate them regularly. Never embed them in client-side code.

**OAuth 2.0** solves delegation ("let this app read my data") with scoped tokens
and refresh flows. Complex to implement, but the right choice when third parties
need access.

**JWT** encodes claims into the token itself. The server verifies the signature
without a database lookup. Tradeoff: you cannot revoke a JWT before expiry
without maintaining a blacklist, which defeats the statelessness.

**Heuristic:** API keys for internal/server calls. OAuth for third-party
integrations. JWT for stateless microservice auth with short expiry times.

## Schema Evolution

### Compatibility Directions

| Change Type            | Backward Compatible | Forward Compatible |
| ---------------------- | ------------------- | ------------------ |
| Add optional field     | Yes                 | Yes                |
| Add required field     | **No**              | Yes                |
| Remove field           | Yes                 | **No**             |
| Rename field           | **No**              | **No**             |
| Change field type      | **No**              | **No**             |
| Widen enum (add value) | Yes                 | **No**             |
| Narrow enum (remove)   | **No**              | Yes                |

**Backward compatible** means old clients work with the new API. **Forward
compatible** means new clients work with the old API.

### Rules of Thumb

1. **Additive changes are safe.** Add fields, add endpoints, add enum values.
2. **Removal and rename break clients.** Deprecate first, remove later.
3. **Robustness principle:** Be liberal in what you accept, conservative in what
   you send. Accept unknown fields silently; never add unexpected fields to
   responses without versioning.
4. **Deprecation window:** Announce the change, give clients a migration period
   (weeks to months depending on audience), then remove.

## Anti-Patterns

| Anti-Pattern                      | Why It Fails                                       | Better Approach                                |
| --------------------------------- | -------------------------------------------------- | ---------------------------------------------- |
| Verbs in URLs                     | Duplicates HTTP methods, inconsistent naming       | Use HTTP methods; resources are nouns          |
| Nested URLs 3+ levels deep        | Couples clients to data model, fragile paths       | Flatten; give child resources own endpoints    |
| 200 OK with error body            | Breaks HTTP semantics, tools can't detect failures | Use proper status codes                        |
| Exposing database IDs as integers | Sequential IDs leak count, enable enumeration      | Use UUIDs or opaque identifiers                |
| Version in every URL from day one | Premature complexity, multiple code paths          | Design for evolution; version only when forced |
| God endpoint (one RPC does all)   | Untyped blob, impossible to document or cache      | Separate endpoints per operation               |
| Inconsistent naming               | `user_name` here, `userName` there                 | Pick one convention, enforce it everywhere     |
| No pagination on list endpoints   | Works in dev, OOMs in production                   | Always paginate; default limit with max cap    |
| Breaking changes without warning  | Clients fail silently or loudly with no recourse   | Deprecation headers, changelogs, sunset dates  |
| Auth tokens in query strings      | Logged in server logs, browser history, referer    | Use Authorization header                       |

## See Also

- [HTTP](../how/http.md) — curl, headers, status codes, REST conventions
- [Data Models Lesson Plan](../learn/data-models-lesson-plan.md) — Schema
  evolution, contracts
- [System Design Lesson Plan](../learn/system-design-lesson-plan.md) —
  Distributed architecture
- [Testing](../how/testing.md) — API testing patterns
