---
title: "Authentication"
description:
  "Sessions, tokens, OAuth2, JWT, SSO, API keys, and multi-factor authentication
  patterns"
---

<!-- prettier-ignore -->
:::tip[Lesson Plan]
Looking to learn security step by step? See the
[Security Lesson Plan](../learn/security-lesson-plan.md).
:::

## Quick Reference

| Mechanism      | State     | Best For             | Trade-off                       |
| -------------- | --------- | -------------------- | ------------------------------- |
| Session cookie | Server    | Traditional web apps | Scalability vs simplicity       |
| JWT            | Client    | APIs, microservices  | Revocation vs statelessness     |
| API key        | Server    | Service-to-service   | Simplicity vs granularity       |
| OAuth2         | Delegated | Third-party access   | Complexity vs security          |
| SSO (OIDC)     | Federated | Enterprise apps      | Setup cost vs unified UX        |
| Passkeys       | Device    | Password replacement | Adoption vs phishing resistance |

## Sessions and Cookies

### How Sessions Work

```text
1. User submits credentials (POST /login)
2. Server validates, creates session in store (Redis, DB)
3. Server sets Set-Cookie: session_id=abc123; HttpOnly; Secure; SameSite=Lax
4. Browser sends cookie on every subsequent request
5. Server looks up session_id in store → retrieves user context
6. On logout, server deletes session from store
```

### Cookie Security Attributes

| Attribute         | Purpose                 | When to Set                  |
| ----------------- | ----------------------- | ---------------------------- |
| `HttpOnly`        | Block JavaScript access | Always for session cookies   |
| `Secure`          | HTTPS transport only    | Always in production         |
| `SameSite=Lax`    | Block cross-origin POST | Default for most cookies     |
| `SameSite=Strict` | Block all cross-site    | Auth-sensitive cookies       |
| `Domain`          | Scope to domain         | Sharing across subdomains    |
| `Max-Age`         | Lifetime in seconds     | Set reasonable limits        |
| `Path`            | Scope to URL path       | When isolating cookie access |

### Session Storage Options

| Store               | Latency | Horizontal Scale | Session Sharing |
| ------------------- | ------- | ---------------- | --------------- |
| In-memory (default) | Fastest | None             | No              |
| Redis               | ~1ms    | Yes              | Yes             |
| Database            | ~10ms   | Limited          | Yes             |
| Signed cookie       | N/A     | Infinite         | Yes (stateless) |

Redis is the standard choice for multi-server deployments. Signed cookies work
for small payloads but leak data if not encrypted.

## JSON Web Tokens (JWT)

### Anatomy

```text
Header.Payload.Signature
  │       │        │
  │       │        └─ HMAC-SHA256(base64(header) + "." + base64(payload), secret)
  │       │
  │       └─ {"sub":"user123","iss":"auth.example.com","exp":1735689600,"aud":"api"}
  │
  └─ {"alg":"RS256","typ":"JWT"}
```

All three parts are Base64URL-encoded. The signature covers header + payload --
tamper with either and verification fails.

### Signing Algorithms

| Algorithm | Type       | Key            | Use Case               |
| --------- | ---------- | -------------- | ---------------------- |
| HS256     | Symmetric  | Shared secret  | Single service         |
| RS256     | Asymmetric | RSA key pair   | Multiple consumers     |
| ES256     | Asymmetric | ECDSA key pair | Modern, compact tokens |
| EdDSA     | Asymmetric | Ed25519 pair   | Fastest verification   |

Use asymmetric algorithms when multiple services verify tokens -- publish the
public key at a JWKS endpoint, keep the private key on the auth server.

### Validation Checklist

Every service that accepts a JWT must verify:

1. **Signature** — using the correct public key or shared secret
2. **`exp`** — token has not expired
3. **`iss`** — issuer matches your auth server
4. **`aud`** — audience includes your service
5. **`nbf`** — not-before time has passed (if present)
6. **`alg`** — matches expected algorithm (reject `none`)

### Access + Refresh Token Pattern

```text
Client                   Auth Server               Resource Server
  │                          │                          │
  │── POST /token ──────────>│                          │
  │   (credentials)          │                          │
  │<── access_token (15min) ─│                          │
  │    refresh_token (7d)    │                          │
  │                          │                          │
  │── GET /api ──────────────┼─────────────────────────>│
  │   Authorization: Bearer  │                          │
  │<── 200 ──────────────────┼──────────────────────────│
  │                          │                          │
  │  ... access token expires ...                       │
  │                          │                          │
  │── POST /token ──────────>│                          │
  │   (refresh_token)        │                          │
  │<── new access_token ─────│                          │
  │    new refresh_token     │  (rotate on each use)    │
```

Short-lived access tokens limit exposure. Refresh tokens enable revocation
without checking a deny list on every request.

## OAuth2

### Grant Types

| Grant                     | Flow                     | Use Case           | Notes                              |
| ------------------------- | ------------------------ | ------------------ | ---------------------------------- |
| Authorization Code        | Browser redirect         | Web apps + backend | Standard choice                    |
| Authorization Code + PKCE | Redirect + code verifier | SPAs, mobile, CLIs | Required for public clients        |
| Client Credentials        | Direct token request     | Service-to-service | No user context                    |
| Device Code               | Out-of-band user auth    | CLIs, smart TVs    | User authenticates on other device |
| Implicit                  | _(Deprecated)_           | —                  | Use Authorization Code + PKCE      |
| Resource Owner Password   | _(Deprecated)_           | —                  | Exposes credentials to client      |

### Authorization Code Flow

```text
User        Client App         Auth Server          Resource Server
 │              │                    │                     │
 │─ click ─────>│                    │                     │
 │              │── redirect ───────>│                     │
 │              │   /authorize?      │                     │
 │              │   response_type=   │                     │
 │              │   code&            │                     │
 │              │   client_id=X&     │                     │
 │              │   redirect_uri=Y&  │                     │
 │              │   scope=read&      │                     │
 │              │   state=random123  │                     │
 │              │                    │                     │
 │<──── login form ─────────────────│                     │
 │──── credentials ─────────────────>│                     │
 │              │                    │                     │
 │<──── redirect to Y?code=ABC ─────│                     │
 │──────────────>│                   │                     │
 │              │── POST /token ────>│                     │
 │              │   code=ABC&        │                     │
 │              │   client_secret=Z  │                     │
 │              │<── access_token ───│                     │
 │              │                    │                     │
 │              │── GET /api ────────┼────────────────────>│
 │              │   Bearer token     │                     │
 │              │<── data ───────────┼─────────────────────│
```

### PKCE Extension

PKCE (Proof Key for Code Exchange) prevents authorization code interception for
public clients (SPAs, mobile apps) that cannot keep a `client_secret`.

```text
1. Client generates random code_verifier (43-128 chars)
2. Client computes code_challenge = BASE64URL(SHA256(code_verifier))
3. Client sends code_challenge in /authorize request
4. Auth server stores code_challenge with the authorization code
5. Client sends code_verifier in /token request
6. Auth server hashes code_verifier, compares with stored challenge
```

If an attacker intercepts the authorization code, they lack the `code_verifier`
and cannot exchange it for a token.

### OAuth2 Scopes

Scopes limit what a token can do. Define them by resource and action:

```text
read:users      # Read user profiles
write:orders    # Create/update orders
admin:billing   # Full billing access
```

Request the minimum scopes needed. Users see the scope list on the consent
screen.

## API Keys

| Concern   | Best Practice                                                  |
| --------- | -------------------------------------------------------------- |
| Placement | Header (`Authorization: Bearer` or `X-API-Key`) — never in URL |
| Storage   | Hash server-side; show full key only once at creation          |
| Rotation  | Support multiple active keys; deprecate old ones               |
| Scoping   | Limit by endpoint, IP allowlist, rate tier                     |
| Prefix    | Add a recognizable prefix (`sk_live_`, `pk_test_`)             |
| Logging   | Log key prefix/ID, never the full key                          |

### API Key vs OAuth2 Token

| Dimension   | API Key              | OAuth2 Token          |
| ----------- | -------------------- | --------------------- |
| Represents  | Application identity | User + app identity   |
| Expiry      | Long-lived           | Short-lived           |
| Revocation  | Delete from store    | Deny list or expiry   |
| Scope       | Static per key       | Dynamic per grant     |
| When to use | Server-to-server     | User-delegated access |

## Single Sign-On (SSO)

### SAML 2.0 vs OpenID Connect

|               | SAML 2.0                | OpenID Connect (OIDC)              |
| ------------- | ----------------------- | ---------------------------------- |
| Protocol      | XML-based               | JSON/REST (over OAuth2)            |
| Token format  | XML assertion           | JWT (`id_token`)                   |
| Transport     | Browser POST / redirect | Browser redirect                   |
| Best for      | Enterprise, legacy      | Modern web and mobile              |
| Built on      | Custom spec             | OAuth2                             |
| Discovery     | Metadata XML            | `.well-known/openid-configuration` |
| Identity data | Attributes in assertion | Claims in `id_token`               |

### OIDC Flow (Simplified)

```text
1. App redirects to IdP: /authorize?scope=openid profile email
2. User authenticates at IdP (Google, Okta, Azure AD)
3. IdP redirects back with authorization code
4. App exchanges code for id_token + access_token
5. App reads user identity from id_token claims (sub, email, name)
```

OIDC adds an identity layer on top of OAuth2. The `id_token` tells you _who_ the
user is; the `access_token` lets you call APIs _on their behalf_.

## Multi-Factor Authentication

| Factor                   | Type               | Strength  | UX Friction |
| ------------------------ | ------------------ | --------- | ----------- |
| TOTP (authenticator app) | Something you have | Good      | Low         |
| SMS OTP                  | Something you have | Weak      | Low         |
| WebAuthn / Passkeys      | Something you have | Excellent | Low         |
| Email magic link         | Something you have | Moderate  | Medium      |
| Hardware key (YubiKey)   | Something you have | Excellent | Medium      |

SMS is vulnerable to SIM-swap attacks. Prefer TOTP or WebAuthn. Passkeys
(discoverable WebAuthn credentials) replace passwords entirely -- the browser
prompts for biometrics or a device PIN.

### TOTP Implementation

```text
1. Server generates shared secret (base32-encoded, 160+ bits)
2. User scans QR code into authenticator app
3. At login, app computes: TOTP = HMAC-SHA1(secret, floor(time / 30))
4. Server computes same value, allows ±1 window for clock skew
5. Each code is valid for 30 seconds
```

## Anti-patterns

| Anti-pattern                   | Problem                                | Fix                                            |
| ------------------------------ | -------------------------------------- | ---------------------------------------------- |
| JWT as session replacement     | Cannot revoke without deny list        | Short expiry + refresh tokens + deny list      |
| Secrets in localStorage        | XSS exfiltrates them                   | Use `HttpOnly` cookies                         |
| Rolling your own auth          | Timing attacks, subtle logic bugs      | Use established libraries (Passport, NextAuth) |
| Long-lived tokens              | Extended exposure window               | Short access (15min), rotating refresh (7d)    |
| API keys in URLs               | Logged in server logs, browser history | Send in headers                                |
| No rate limiting on /login     | Brute force                            | Rate limit + lockout + CAPTCHA                 |
| Accepting `alg: none` in JWT   | Attacker strips signature              | Allowlist signing algorithms                   |
| Shared secrets across services | One compromised service leaks all      | Asymmetric keys + JWKS endpoint                |

## See Also

- [Security Lesson Plan](../learn/security-lesson-plan.md) — Progressive
  authentication and authorization exercises
- [Cryptography](cryptography.md) — Hashing, certificates, TLS
- [HTTP](http.md) — Headers, status codes, cookies in curl
- [API Design](../why/api-design.md) — REST conventions, versioning, error
  handling
- [System Design](system-design.md) — Rate limiting, load balancing, session
  affinity
