# HTTP Cheat Sheet

## Status Codes

### Success (2xx)

| Code | Meaning    | When to Use                      |
| ---- | ---------- | -------------------------------- |
| 200  | OK         | Request succeeded, body has data |
| 201  | Created    | Resource created (POST)          |
| 204  | No Content | Success, no body (DELETE, PUT)   |

### Redirection (3xx)

| Code | Meaning           | When to Use              |
| ---- | ----------------- | ------------------------ |
| 301  | Moved Permanently | URL changed forever      |
| 302  | Found             | Temporary redirect       |
| 304  | Not Modified      | Client cache still valid |

### Client Errors (4xx)

| Code | Meaning              | When to Use                      |
| ---- | -------------------- | -------------------------------- |
| 400  | Bad Request          | Malformed syntax, invalid data   |
| 401  | Unauthorized         | Missing or invalid credentials   |
| 403  | Forbidden            | Valid credentials, no permission |
| 404  | Not Found            | Resource doesn't exist           |
| 409  | Conflict             | State conflict (duplicate, etc.) |
| 422  | Unprocessable Entity | Valid syntax, semantic errors    |
| 429  | Too Many Requests    | Rate limited                     |

### Server Errors (5xx)

| Code | Meaning               | When to Use               |
| ---- | --------------------- | ------------------------- |
| 500  | Internal Server Error | Unexpected server failure |
| 502  | Bad Gateway           | Upstream server failed    |
| 503  | Service Unavailable   | Server overloaded/down    |
| 504  | Gateway Timeout       | Upstream server timeout   |

## curl Basics

```bash
# GET request
curl https://api.example.com/users

# With headers
curl -H "Authorization: Bearer TOKEN" https://api.example.com/users

# POST JSON
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name": "alice"}' \
  https://api.example.com/users

# POST form data
curl -X POST \
  -d "name=alice&email=alice@example.com" \
  https://api.example.com/users

# Upload file
curl -X POST \
  -F "file=@document.pdf" \
  https://api.example.com/upload
```

## curl Options

| Flag          | Purpose                              |
| ------------- | ------------------------------------ |
| `-X METHOD`   | HTTP method (GET, POST, PUT, DELETE) |
| `-H "K: V"`   | Add header                           |
| `-d "data"`   | Request body                         |
| `-F "k=v"`    | Form field (multipart)               |
| `-o file`     | Write output to file                 |
| `-O`          | Save with remote filename            |
| `-L`          | Follow redirects                     |
| `-i`          | Include response headers             |
| `-I`          | HEAD request (headers only)          |
| `-v`          | Verbose (debug)                      |
| `-s`          | Silent (no progress)                 |
| `-k`          | Skip TLS verification                |
| `-u user:pwd` | Basic auth                           |

## curl + jq Patterns

```bash
# Pretty print JSON response
curl -s https://api.example.com/users | jq

# Extract field
curl -s https://api.example.com/users | jq '.[0].name'

# Filter and format
curl -s https://api.example.com/users | jq '.[] | {name, email}'

# Check status code
curl -s -o /dev/null -w "%{http_code}" https://api.example.com/health
```

## Common Headers

### Request Headers

| Header            | Purpose                 | Example                         |
| ----------------- | ----------------------- | ------------------------------- |
| Authorization     | Credentials             | `Bearer eyJhbGc...`             |
| Content-Type      | Body format             | `application/json`              |
| Accept            | Desired response format | `application/json`              |
| User-Agent        | Client identifier       | `MyApp/1.0`                     |
| Cache-Control     | Caching directives      | `no-cache`                      |
| If-None-Match     | Conditional (ETag)      | `"abc123"`                      |
| If-Modified-Since | Conditional (date)      | `Wed, 21 Oct 2024 07:28:00 GMT` |

### Response Headers

| Header         | Purpose                       | Example                           |
| -------------- | ----------------------------- | --------------------------------- |
| Content-Type   | Body format                   | `application/json; charset=utf-8` |
| Cache-Control  | Caching instructions          | `max-age=3600`                    |
| ETag           | Resource version              | `"abc123"`                        |
| Location       | Redirect target / created URL | `/users/42`                       |
| X-RateLimit-\* | Rate limit info               | `X-RateLimit-Remaining: 99`       |

## REST Conventions

| Action         | Method | Path             | Success Code |
| -------------- | ------ | ---------------- | ------------ |
| List all       | GET    | `/resources`     | 200          |
| Get one        | GET    | `/resources/:id` | 200          |
| Create         | POST   | `/resources`     | 201          |
| Full update    | PUT    | `/resources/:id` | 200          |
| Partial update | PATCH  | `/resources/:id` | 200          |
| Delete         | DELETE | `/resources/:id` | 204          |

### Query Parameters

```text
GET /users?page=2&limit=20           # Pagination
GET /users?sort=name&order=desc      # Sorting
GET /users?filter[role]=admin        # Filtering
GET /users?fields=id,name,email      # Sparse fields
GET /users?include=posts,comments    # Related resources
```

## Authentication Patterns

### Bearer Token

```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
  https://api.example.com/users
```

### Basic Auth

```bash
# With -u flag
curl -u username:password https://api.example.com/users

# Manual header
curl -H "Authorization: Basic $(echo -n user:pass | base64)" \
  https://api.example.com/users
```

### API Key

```bash
# In header
curl -H "X-API-Key: abc123" https://api.example.com/users

# In query string (less secure)
curl "https://api.example.com/users?api_key=abc123"
```

## Debugging

```bash
# See full request/response
curl -v https://api.example.com/users

# Time breakdown
curl -w "\nDNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n" \
  -o /dev/null -s https://api.example.com/users

# Test endpoint availability
curl -s -o /dev/null -w "%{http_code}" https://api.example.com/health
```

## See Also

- [Cryptography](cryptography.md) — TLS, certificates, and HMAC authentication
- [jq](jq.md) — Process JSON responses
- [Unix](unix.md) — Pipe curl output to other tools
