# Security Lesson Plan

Application security beyond cryptography -- threat modeling, authentication,
authorization, and the defenses that keep real systems from getting owned.

## Lesson 1: Threat Modeling

**Goal:** Systematically identify what can go wrong before writing a single line
of defense code.

### Concepts

Threat modeling is the practice of mapping out your system, identifying what
attackers want, and figuring out how they might get it. The STRIDE framework
categorizes threats as Spoofing, Tampering, Repudiation, Information Disclosure,
Denial of Service, and Elevation of Privilege. You draw a data flow diagram
(DFD) with trust boundaries -- every time data crosses a boundary, that crossing
is an attack surface.

### Exercises

1. **Draw a data flow diagram**

   ```text
   A typical web app has these components and trust boundaries:

   [Browser] --HTTPS--> [Load Balancer] --> [App Server] --> [Database]
                              |                   |
                         Trust Boundary 1    Trust Boundary 2
                        (Internet / DMZ)    (App / Data tier)

   Identify:
   - External entities (users, third-party APIs)
   - Processes (app server, auth service, worker)
   - Data stores (database, cache, file storage)
   - Data flows (arrows between components)
   - Trust boundaries (where privilege levels change)
   ```

2. **Apply STRIDE to each component**

   ```text
   For each element in your DFD, ask:

   Component: App Server
   ┌──────────────────────┬──────────────────────────────────────┐
   │ Threat               │ Example                              │
   ├──────────────────────┼──────────────────────────────────────┤
   │ Spoofing             │ Attacker forges a session cookie     │
   │ Tampering            │ Attacker modifies request body       │
   │ Repudiation          │ User denies placing an order         │
   │ Info Disclosure      │ Stack trace leaks DB credentials     │
   │ Denial of Service    │ Attacker sends 10M requests/sec      │
   │ Elevation of Priv    │ Normal user accesses admin endpoint  │
   └──────────────────────┴──────────────────────────────────────┘

   Repeat for: Database, Load Balancer, Browser
   ```

3. **Enumerate attack surfaces**

   ```bash
   # List every endpoint in a Flask app to map your attack surface
   pip install flask
   python -c "
   from flask import Flask
   app = Flask(__name__)

   @app.route('/login', methods=['POST'])
   def login(): pass

   @app.route('/api/users/<int:user_id>')
   def get_user(user_id): pass

   @app.route('/admin/delete-user', methods=['POST'])
   def delete_user(): pass

   for rule in app.url_map.iter_rules():
       print(f'{rule.methods - {\"OPTIONS\", \"HEAD\"}}  {rule.rule}')
   "
   # Each endpoint is an attack surface -- what input does it accept?
   # Who should be allowed to call it?
   ```

4. **Prioritize threats with risk rating**

   ```text
   Use a simple risk matrix (Likelihood x Impact):

   Threat                          Likelihood  Impact  Priority
   ─────────────────────────────  ──────────  ──────  ────────
   SQL injection in search          High       High    Critical
   CSRF on profile update           Medium     Medium  Medium
   DDoS on public API               High       Medium  High
   Admin panel brute force          Medium     High    High
   XSS in comment field             High       High    Critical

   Fix Critical first. Accept Low/Low risks with monitoring.
   ```

### Checkpoint

Draw a DFD for an app you work on (or a familiar one like a blog platform).
Apply STRIDE to every trust boundary crossing. Produce a ranked list of the top
five threats and propose a mitigation for each.

---

## Lesson 2: Authentication

**Goal:** Build secure login flows that resist credential theft, replay attacks,
and session hijacking.

### Concepts

Authentication proves identity -- are you who you claim to be? Passwords alone
are weak; they must be hashed with slow, salted algorithms like bcrypt or
argon2id. Sessions use server-side state with an opaque token in a cookie. JWTs
move state to the client but require careful signature verification and short
expiration times. Multi-factor authentication (MFA) adds a second factor --
something you have (TOTP) or something you are (biometrics).

### Exercises

1. **Hash passwords with bcrypt**

   ```python
   # password_hashing.py
   # pip install bcrypt flask
   import bcrypt

   def hash_password(password: str) -> str:
       """Hash a password with a random salt. Cost factor 12 ~ 250ms."""
       return bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12)).decode()

   def verify_password(password: str, hashed: str) -> bool:
       return bcrypt.checkpw(password.encode(), hashed.encode())

   stored = hash_password("hunter2")
   print(f"Stored hash: {stored}")
   print(f"Correct password:  {verify_password('hunter2', stored)}")   # True
   print(f"Wrong password:    {verify_password('hunter3', stored)}")   # False
   print(f"Hash again:        {hash_password('hunter2')}")             # Different!
   # Each hash includes its own salt -- no two are alike
   ```

2. **Build a session-based login flow**

   ```python
   # session_auth.py
   # pip install flask
   from flask import Flask, session, request, jsonify
   import secrets, bcrypt

   app = Flask(__name__)
   app.secret_key = secrets.token_hex(32)

   # Simulated user database
   USERS = {
       "alice": bcrypt.hashpw(b"correcthorsebattery", bcrypt.gensalt()).decode()
   }

   @app.route("/login", methods=["POST"])
   def login():
       username = request.json.get("username", "")
       password = request.json.get("password", "")
       stored = USERS.get(username)
       if stored and bcrypt.checkpw(password.encode(), stored.encode()):
           session["user"] = username
           return jsonify({"status": "ok"})
       return jsonify({"error": "invalid credentials"}), 401

   @app.route("/me")
   def me():
       user = session.get("user")
       if not user:
           return jsonify({"error": "not authenticated"}), 401
       return jsonify({"user": user})

   @app.route("/logout", methods=["POST"])
   def logout():
       session.clear()
       return jsonify({"status": "logged out"})

   if __name__ == "__main__":
       app.run(debug=True)
   ```

   ```bash
   # Test it
   curl -s -c cookies.txt -X POST http://localhost:5000/login \
     -H "Content-Type: application/json" \
     -d '{"username":"alice","password":"correcthorsebattery"}'

   curl -s -b cookies.txt http://localhost:5000/me
   # {"user": "alice"}
   ```

3. **Issue and verify a JWT**

   ```python
   # jwt_auth.py
   # pip install PyJWT
   import jwt, time

   SECRET = "use-a-real-secret-in-production"

   def create_token(user_id: str, minutes: int = 15) -> str:
       payload = {
           "sub": user_id,
           "iat": int(time.time()),
           "exp": int(time.time()) + minutes * 60,
       }
       return jwt.encode(payload, SECRET, algorithm="HS256")

   def verify_token(token: str) -> dict:
       return jwt.decode(token, SECRET, algorithms=["HS256"])

   token = create_token("alice")
   print(f"Token: {token[:50]}...")
   print(f"Decoded: {verify_token(token)}")

   # Tamper with the token -- verification fails
   try:
       verify_token(token + "x")
   except jwt.InvalidSignatureError as e:
       print(f"Tampered token rejected: {e}")
   ```

4. **Add TOTP multi-factor authentication**

   ```python
   # totp_demo.py
   # pip install pyotp qrcode
   import pyotp

   # Server generates a secret for the user during MFA enrollment
   secret = pyotp.random_base32()
   print(f"Secret (store server-side): {secret}")

   # Generate a provisioning URI for the authenticator app
   uri = pyotp.totp.TOTP(secret).provisioning_uri(
       name="alice@example.com", issuer_name="MyApp"
   )
   print(f"QR code URI: {uri}")

   # Verify a TOTP code submitted by the user
   totp = pyotp.TOTP(secret)
   current_code = totp.now()
   print(f"Current code: {current_code}")
   print(f"Valid: {totp.verify(current_code)}")       # True
   print(f"Wrong code: {totp.verify('000000')}")      # False
   ```

### Checkpoint

Run the session-based Flask app. Log in, access a protected route, and log out.
Then swap the session store for JWTs. Explain when you would choose sessions
over JWTs and why MFA matters even with strong passwords.

---

## Lesson 3: Authorization

**Goal:** Control what authenticated users can do, applying the principle of
least privilege.

### Concepts

Authorization determines access -- you proved who you are, but are you allowed
to do this? Role-Based Access Control (RBAC) assigns permissions to roles and
roles to users. Attribute-Based Access Control (ABAC) evaluates policies against
user attributes, resource attributes, and context. The principle of least
privilege says grant the minimum access needed and nothing more. The most common
authorization bugs are Insecure Direct Object References (IDOR) and client-side
enforcement.

### Exercises

1. **Implement RBAC with a decorator**

   ```python
   # rbac.py
   from functools import wraps
   from flask import Flask, session, jsonify

   app = Flask(__name__)
   app.secret_key = "dev-secret"

   # Role -> permissions mapping
   ROLES = {
       "admin": {"read", "write", "delete", "manage_users"},
       "editor": {"read", "write"},
       "viewer": {"read"},
   }

   # User -> role mapping (normally from a database)
   USER_ROLES = {
       "alice": "admin",
       "bob": "editor",
       "carol": "viewer",
   }

   def require_permission(permission: str):
       def decorator(f):
           @wraps(f)
           def wrapper(*args, **kwargs):
               user = session.get("user")
               if not user:
                   return jsonify({"error": "not authenticated"}), 401
               role = USER_ROLES.get(user, "viewer")
               if permission not in ROLES.get(role, set()):
                   return jsonify({"error": "forbidden"}), 403
               return f(*args, **kwargs)
           return wrapper
       return decorator

   @app.route("/articles")
   @require_permission("read")
   def list_articles():
       return jsonify({"articles": ["article1", "article2"]})

   @app.route("/articles", methods=["POST"])
   @require_permission("write")
   def create_article():
       return jsonify({"status": "created"})

   @app.route("/admin/users")
   @require_permission("manage_users")
   def manage_users():
       return jsonify({"users": ["alice", "bob", "carol"]})
   ```

2. **Demonstrate an IDOR vulnerability**

   ```python
   # idor_vulnerable.py
   from flask import Flask, jsonify, session

   app = Flask(__name__)
   app.secret_key = "dev-secret"

   INVOICES = {
       1: {"owner": "alice", "amount": 500},
       2: {"owner": "bob", "amount": 1200},
   }

   # VULNERABLE: no ownership check
   @app.route("/api/invoices/<int:invoice_id>")
   def get_invoice_bad(invoice_id):
       invoice = INVOICES.get(invoice_id)
       if not invoice:
           return jsonify({"error": "not found"}), 404
       return jsonify(invoice)  # Bob can see Alice's invoice!

   # FIXED: verify ownership
   @app.route("/api/invoices-safe/<int:invoice_id>")
   def get_invoice_safe(invoice_id):
       user = session.get("user")
       if not user:
           return jsonify({"error": "not authenticated"}), 401
       invoice = INVOICES.get(invoice_id)
       if not invoice:
           return jsonify({"error": "not found"}), 404
       if invoice["owner"] != user:
           return jsonify({"error": "forbidden"}), 403
       return jsonify(invoice)
   ```

3. **Implement attribute-based checks**

   ```python
   # abac.py
   from dataclasses import dataclass
   from datetime import datetime

   @dataclass
   class User:
       name: str
       role: str
       department: str

   @dataclass
   class Document:
       title: str
       classification: str   # public, internal, confidential
       department: str

   def can_access(user: User, document: Document) -> bool:
       """ABAC policy: check multiple attributes, not just role."""
       if document.classification == "public":
           return True
       if document.classification == "internal":
           return user.department == document.department
       if document.classification == "confidential":
           return (user.role == "admin"
                   and user.department == document.department)
       return False

   alice = User("alice", "admin", "engineering")
   bob = User("bob", "viewer", "engineering")
   carol = User("carol", "admin", "marketing")

   doc = Document("Architecture Plan", "confidential", "engineering")

   print(f"Alice: {can_access(alice, doc)}")  # True  -- admin + same dept
   print(f"Bob:   {can_access(bob, doc)}")    # False -- not admin
   print(f"Carol: {can_access(carol, doc)}")  # False -- wrong department
   ```

4. **Spot authorization mistakes**

   ```text
   Review each scenario and identify the flaw:

   A: Frontend hides the "Delete" button for non-admins, but the API
      endpoint /api/delete has no server-side role check.
      Flaw: Client-side authorization -- anyone with curl can delete.

   B: GET /api/users/42/settings -- user ID comes from the URL,
      not the session.
      Flaw: IDOR -- change 42 to 43 and see someone else's settings.

   C: JWT contains {"role": "admin"} and the server trusts it
      without checking a database.
      Flaw: Users can mint their own JWTs if the secret leaks,
      or the role in the token may be stale after revocation.

   D: API checks permission on GET /resource but not on
      PUT /resource or DELETE /resource.
      Flaw: Inconsistent enforcement -- only read is protected.
   ```

### Checkpoint

Build a Flask app with three roles (admin, editor, viewer). Prove that an editor
cannot access admin routes. Demonstrate an IDOR vulnerability and then fix it by
adding an ownership check.

---

## Lesson 4: Input Validation

**Goal:** Defend against injection attacks by validating, sanitizing, and
parameterizing all user input.

### Concepts

Never trust user input -- it crosses a trust boundary. SQL injection lets
attackers rewrite queries. Cross-site scripting (XSS) lets attackers run
JavaScript in other users' browsers. Command injection lets attackers execute
shell commands on your server. The defenses are parameterized queries (not
string concatenation), output encoding/escaping, and Content Security Policy
headers. Validation rejects bad input; sanitization cleans it; parameterization
prevents it from being interpreted as code.

### Exercises

1. **SQL injection: attack and defend**

   ```python
   # sqli_demo.py
   # pip install flask
   import sqlite3
   from flask import Flask, request, jsonify

   app = Flask(__name__)

   def init_db():
       db = sqlite3.connect(":memory:")
       db.execute("CREATE TABLE users (id INTEGER, name TEXT, role TEXT)")
       db.execute("INSERT INTO users VALUES (1, 'alice', 'admin')")
       db.execute("INSERT INTO users VALUES (2, 'bob', 'user')")
       db.commit()
       return db

   DB = init_db()

   # VULNERABLE: string concatenation
   @app.route("/search-bad")
   def search_bad():
       name = request.args.get("name", "")
       query = f"SELECT * FROM users WHERE name = '{name}'"
       print(f"Query: {query}")
       rows = DB.execute(query).fetchall()
       return jsonify(rows)

   # SAFE: parameterized query
   @app.route("/search-safe")
   def search_safe():
       name = request.args.get("name", "")
       rows = DB.execute(
           "SELECT * FROM users WHERE name = ?", (name,)
       ).fetchall()
       return jsonify(rows)

   if __name__ == "__main__":
       app.run(debug=True)
   ```

   ```bash
   # Normal request
   curl "http://localhost:5000/search-bad?name=alice"

   # SQL injection -- dump all users
   curl "http://localhost:5000/search-bad?name=' OR '1'='1"

   # Same injection against the safe endpoint -- returns empty
   curl "http://localhost:5000/search-safe?name=' OR '1'='1"
   ```

2. **XSS: attack and defend**

   ```python
   # xss_demo.py
   from flask import Flask, request
   from markupsafe import escape

   app = Flask(__name__)

   # VULNERABLE: renders user input as raw HTML
   @app.route("/greet-bad")
   def greet_bad():
       name = request.args.get("name", "World")
       return f"<h1>Hello, {name}!</h1>"

   # SAFE: escape HTML entities
   @app.route("/greet-safe")
   def greet_safe():
       name = request.args.get("name", "World")
       return f"<h1>Hello, {escape(name)}!</h1>"

   if __name__ == "__main__":
       app.run(debug=True)
   ```

   ```bash
   # Normal
   curl "http://localhost:5000/greet-bad?name=Alice"

   # XSS payload -- executes JavaScript in a browser
   curl "http://localhost:5000/greet-bad?name=<script>alert('xss')</script>"

   # Safe endpoint escapes the angle brackets
   curl "http://localhost:5000/greet-safe?name=<script>alert('xss')</script>"
   # Output: <h1>Hello, &lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;!</h1>
   ```

3. **Command injection: attack and defend**

   ```python
   # cmdi_demo.py
   import subprocess
   from flask import Flask, request, jsonify

   app = Flask(__name__)

   # VULNERABLE: user input passed to shell
   @app.route("/ping-bad")
   def ping_bad():
       host = request.args.get("host", "localhost")
       output = subprocess.run(
           f"ping -c 1 {host}", shell=True, capture_output=True, text=True
       )
       return jsonify({"output": output.stdout})

   # SAFE: use a list (no shell interpolation) + validate input
   @app.route("/ping-safe")
   def ping_safe():
       import re
       host = request.args.get("host", "localhost")
       if not re.match(r'^[a-zA-Z0-9.\-]+$', host):
           return jsonify({"error": "invalid hostname"}), 400
       output = subprocess.run(
           ["ping", "-c", "1", host], capture_output=True, text=True
       )
       return jsonify({"output": output.stdout})

   if __name__ == "__main__":
       app.run(debug=True)
   ```

   ```bash
   # Command injection -- runs arbitrary commands
   curl "http://localhost:5000/ping-bad?host=localhost;cat /etc/passwd"

   # Safe endpoint rejects it
   curl "http://localhost:5000/ping-safe?host=localhost;cat /etc/passwd"
   # {"error": "invalid hostname"}
   ```

4. **Add Content Security Policy headers**

   ```python
   # csp_demo.py
   from flask import Flask, make_response

   app = Flask(__name__)

   @app.after_request
   def add_security_headers(response):
       # Block inline scripts and only allow same-origin resources
       response.headers["Content-Security-Policy"] = (
           "default-src 'self'; "
           "script-src 'self'; "
           "style-src 'self'; "
           "img-src 'self' data:; "
           "frame-ancestors 'none'"
       )
       response.headers["X-Content-Type-Options"] = "nosniff"
       return response

   @app.route("/")
   def index():
       # Even if XSS payload is injected, CSP blocks script execution
       return "<h1>Protected Page</h1><script>alert('blocked by CSP')</script>"

   if __name__ == "__main__":
       app.run(debug=True)
   ```

### Checkpoint

Run the SQL injection demo. Confirm you can extract all rows with the vulnerable
endpoint and that the parameterized endpoint blocks the same payload. Do the
same for the XSS and command injection demos. Explain why parameterized queries
are better than escaping user input.

---

## Lesson 5: OWASP Top 10

**Goal:** Recognize the ten most critical web application security risks and
know the standard defenses for each.

### Concepts

The OWASP Top 10 is a consensus list of the most dangerous web application
vulnerabilities, updated periodically. The 2021 list reshuffled priorities:
broken access control moved to number one, cryptographic failures to number two,
and injection dropped to number three. Understanding the Top 10 gives you a
shared vocabulary with security teams and a checklist for code reviews. Focus on
access control, injection, misconfiguration, and SSRF -- these cause the
majority of real breaches.

### Exercises

1. **Broken access control (A01)**

   ```python
   # broken_access.py
   from flask import Flask, request, jsonify

   app = Flask(__name__)

   DOCUMENTS = {
       "doc-001": {"owner": "alice", "content": "Alice's secret plan"},
       "doc-002": {"owner": "bob", "content": "Bob's financial report"},
   }

   # VULNERABLE: no access control
   @app.route("/api/docs/<doc_id>")
   def get_doc(doc_id):
       doc = DOCUMENTS.get(doc_id)
       if not doc:
           return jsonify({"error": "not found"}), 404
       return jsonify(doc)  # Anyone can read any document

   # FIXED: verify the requesting user owns the document
   @app.route("/api/docs-safe/<doc_id>")
   def get_doc_safe(doc_id):
       current_user = request.headers.get("X-User")  # Simplified for demo
       doc = DOCUMENTS.get(doc_id)
       if not doc:
           return jsonify({"error": "not found"}), 404
       if doc["owner"] != current_user:
           return jsonify({"error": "forbidden"}), 403
       return jsonify(doc)
   ```

   ```bash
   # Alice reads Bob's document -- broken access control
   curl http://localhost:5000/api/docs/doc-002

   # Fixed endpoint blocks it
   curl -H "X-User: alice" http://localhost:5000/api/docs-safe/doc-002
   # {"error": "forbidden"}
   ```

2. **Security misconfiguration (A05)**

   ```python
   # misconfig_demo.py
   from flask import Flask, jsonify
   import traceback

   app = Flask(__name__)

   # VULNERABLE: debug mode exposes stack traces and interactive console
   # app.run(debug=True)  <-- NEVER in production

   # VULNERABLE: default credentials, verbose errors
   @app.route("/api/data")
   def get_data():
       try:
           result = 1 / 0
       except Exception:
           # Leaks internals to the client
           return jsonify({"error": traceback.format_exc()}), 500

   # FIXED: generic error message, log details server-side
   @app.route("/api/data-safe")
   def get_data_safe():
       try:
           result = 1 / 0
       except Exception:
           app.logger.exception("Error in /api/data-safe")
           return jsonify({"error": "internal server error"}), 500
   ```

   ```bash
   # Check for common misconfigurations
   curl -sI http://localhost:5000/ | grep -iE "server|x-powered-by"
   # Remove Server and X-Powered-By headers -- they help attackers fingerprint
   ```

3. **Server-Side Request Forgery -- SSRF (A10)**

   ```python
   # ssrf_demo.py
   import requests
   from flask import Flask, request, jsonify
   from urllib.parse import urlparse

   app = Flask(__name__)

   # VULNERABLE: fetches any URL the user provides
   @app.route("/fetch-bad")
   def fetch_bad():
       url = request.args.get("url", "")
       resp = requests.get(url)
       return jsonify({"status": resp.status_code, "length": len(resp.text)})

   # SAFE: validate URL against an allowlist
   ALLOWED_HOSTS = {"api.example.com", "cdn.example.com"}

   @app.route("/fetch-safe")
   def fetch_safe():
       url = request.args.get("url", "")
       parsed = urlparse(url)
       if parsed.hostname not in ALLOWED_HOSTS:
           return jsonify({"error": "host not allowed"}), 403
       if parsed.scheme != "https":
           return jsonify({"error": "https required"}), 400
       resp = requests.get(url)
       return jsonify({"status": resp.status_code, "length": len(resp.text)})
   ```

   ```bash
   # SSRF: attacker reads internal metadata service
   curl "http://localhost:5000/fetch-bad?url=http://169.254.169.254/latest/meta-data/"

   # Safe endpoint blocks non-allowlisted hosts
   curl "http://localhost:5000/fetch-safe?url=http://169.254.169.254/latest/meta-data/"
   # {"error": "host not allowed"}
   ```

4. **OWASP Top 10 quick reference**

   ```text
   # OWASP Top 10 (2021)
   ┌─────┬───────────────────────────────┬──────────────────────────────┐
   │  #  │ Risk                          │ Key Defense                  │
   ├─────┼───────────────────────────────┼──────────────────────────────┤
   │ A01 │ Broken Access Control         │ Server-side authz checks     │
   │ A02 │ Cryptographic Failures        │ TLS, strong hashing, no ECB  │
   │ A03 │ Injection                     │ Parameterized queries        │
   │ A04 │ Insecure Design               │ Threat modeling, abuse cases │
   │ A05 │ Security Misconfiguration     │ Hardened defaults, no debug  │
   │ A06 │ Vulnerable Components         │ Dependency scanning, SBOMs   │
   │ A07 │ Auth Failures                 │ MFA, rate limiting, bcrypt   │
   │ A08 │ Software/Data Integrity       │ Signed updates, CI/CD locks  │
   │ A09 │ Logging/Monitoring Failures   │ Audit logs, alerting         │
   │ A10 │ SSRF                          │ URL allowlists, egress rules │
   └─────┴───────────────────────────────┴──────────────────────────────┘
   ```

### Checkpoint

Pick any three items from the OWASP Top 10. For each, write a vulnerable code
snippet and a fixed version. Explain which layer of defense (validation,
authorization, configuration) addresses each risk.

---

## Lesson 6: Secrets Management

**Goal:** Keep credentials, API keys, and tokens out of source code, logs, and
version history.

### Concepts

Secrets in source code are the most common cause of credential leaks. Once a
secret is committed to git, it lives in history forever -- even after deletion.
Environment variables are the minimum viable approach. Secret managers (AWS
Secrets Manager, HashiCorp Vault, 1Password CLI) are better for teams. Tools
like gitleaks and git-secrets scan for accidental commits. The `.env` file
pattern with `.gitignore` is acceptable for local development but must never
reach production or version control.

### Exercises

1. **Accidentally leak a secret and detect it**

   ```bash
   # Set up a demo repo
   mkdir /tmp/secrets-demo && cd /tmp/secrets-demo
   git init

   # Simulate an accidental commit
   cat > config.py << 'PYEOF'
   DATABASE_URL = "postgres://admin:s3cretP@ss@db.example.com:5432/prod"
   API_KEY = "sk-live-abc123def456ghi789"
   PYEOF

   git add config.py
   git commit -m "Add config"

   # Scan with gitleaks (brew install gitleaks)
   gitleaks detect --source . --verbose
   # Finding: config.py contains hardcoded credentials
   ```

2. **Use .env files safely**

   ```bash
   # Create a .env file (never commit this)
   cat > .env << 'EOF'
   DATABASE_URL=postgres://admin:s3cretP@ss@db.example.com:5432/prod
   API_KEY=sk-live-abc123def456ghi789
   EOF

   # Add .env to .gitignore BEFORE committing
   echo ".env" >> .gitignore
   git add .gitignore
   git commit -m "Add gitignore"
   ```

   ```python
   # app.py -- load secrets from environment
   # pip install python-dotenv
   import os
   from dotenv import load_dotenv

   load_dotenv()  # Reads .env file into environment

   db_url = os.environ["DATABASE_URL"]
   api_key = os.environ["API_KEY"]

   # Verify secrets loaded (print length, never the value)
   print(f"DB URL loaded: {len(db_url)} chars")
   print(f"API key loaded: {len(api_key)} chars")
   ```

3. **Set up pre-commit secret scanning**

   ```bash
   # Install gitleaks as a pre-commit hook
   cd /tmp/secrets-demo

   # Option 1: manual git hook
   cat > .git/hooks/pre-commit << 'HOOK'
   #!/bin/sh
   gitleaks protect --staged --verbose
   if [ $? -ne 0 ]; then
       echo "ERROR: Secrets detected in staged files. Commit blocked."
       exit 1
   fi
   HOOK
   chmod +x .git/hooks/pre-commit

   # Try to commit a secret -- hook blocks it
   echo 'SECRET_KEY = "sk-live-xyz789"' > new_config.py
   git add new_config.py
   git commit -m "Oops"
   # ERROR: Secrets detected in staged files. Commit blocked.
   ```

4. **Remove a leaked secret from git history**

   ```bash
   # If you accidentally committed a secret, removing the file is not enough.
   # The secret lives in git history. Use git-filter-repo:
   # pip install git-filter-repo

   # View the secret in history
   git log --all -p -- config.py | head -20

   # Remove the file from ALL history
   git filter-repo --path config.py --invert-paths --force

   # Verify it is gone
   git log --all -p -- config.py
   # (empty -- file never existed in history)

   # IMPORTANT: after rewriting history, rotate the leaked secret.
   # Anyone who already cloned the repo still has it.
   ```

### Checkpoint

Create a repo, commit a fake API key, detect it with gitleaks, remove it from
history with git-filter-repo, and set up a pre-commit hook that blocks future
leaks. Explain why rotating the secret after removal is mandatory.

---

## Lesson 7: Dependency Security

**Goal:** Assess, audit, and monitor third-party dependencies for known
vulnerabilities and supply chain risks.

### Concepts

Your application inherits the security posture of every dependency it uses.
Supply chain attacks compromise a trusted package to reach downstream users --
event-stream, ua-parser-js, and colors are real examples. Lockfiles pin exact
versions so builds are reproducible. SBOMs (Software Bills of Materials)
inventory every component. Audit tools like `npm audit`, `pip-audit`, and Trivy
scan for known CVEs. Trust but verify: check download counts, maintainer
history, and the OpenSSF Scorecard before adopting a package.

### Exercises

1. **Audit Python dependencies**

   ```bash
   # pip install pip-audit
   # Create a requirements file with a known-vulnerable package
   mkdir /tmp/dep-audit && cd /tmp/dep-audit

   cat > requirements.txt << 'EOF'
   flask==2.2.0
   requests==2.28.0
   urllib3==1.26.5
   EOF

   # Scan for known vulnerabilities
   pip-audit -r requirements.txt
   # Shows CVEs for vulnerable versions

   # Fix: upgrade to patched versions
   pip-audit -r requirements.txt --fix --dry-run
   ```

2. **Audit Node.js dependencies**

   ```bash
   mkdir /tmp/node-audit && cd /tmp/node-audit
   npm init -y

   # Install a package with known vulnerabilities
   npm install express@4.17.1

   # Run audit
   npm audit
   # Shows severity, vulnerability description, and fix path

   # Auto-fix what's possible
   npm audit fix

   # For breaking changes
   npm audit fix --force  # Use with caution
   ```

3. **Scan container images with Trivy**

   ```bash
   # brew install trivy

   # Scan a container image for OS and library vulnerabilities
   trivy image python:3.11-slim
   # Reports CVEs in OS packages and Python libraries

   # Scan your project directory
   trivy fs /tmp/dep-audit
   # Finds vulnerable packages in lockfiles and requirements

   # Generate an SBOM
   trivy sbom --format cyclonedx /tmp/dep-audit > sbom.json
   ```

4. **Evaluate a dependency before adopting it**

   ```bash
   # Check OpenSSF Scorecard (brew install scorecard)
   scorecard --repo=github.com/pallets/flask
   # Reports on: maintained, vulnerabilities, code-review, branch-protection

   # Manual checks:
   # 1. How many maintainers? (bus factor)
   gh api repos/pallets/flask --jq '.open_issues_count, .stargazers_count'

   # 2. How recently updated?
   gh api repos/pallets/flask --jq '.pushed_at'

   # 3. Does it have security policy?
   gh api repos/pallets/flask/contents/SECURITY.md --jq '.name' 2>/dev/null \
     && echo "Has SECURITY.md" || echo "No security policy"
   ```

### Checkpoint

Run `pip-audit` on a project with outdated dependencies. Identify at least one
CVE, read its advisory, and upgrade to a patched version. Run Trivy on a
container image and explain the difference between OS-level and library-level
vulnerabilities.

---

## Lesson 8: Security in Practice

**Goal:** Apply defense-in-depth with security headers, HTTPS, secure defaults,
and a review checklist you can use on every project.

### Concepts

Security is not a feature you add at the end -- it is a property of your
defaults. HTTPS should be the only option, not an upgrade. Security headers tell
browsers to enforce restrictions your code cannot. CSP blocks injected scripts,
HSTS forces HTTPS, X-Frame-Options prevents clickjacking. A security review
checklist catches the gaps that individual defenses miss. Defense-in-depth means
no single control is the only thing standing between an attacker and your data.

### Exercises

1. **Add a full set of security headers**

   ```python
   # secure_headers.py
   from flask import Flask

   app = Flask(__name__)

   @app.after_request
   def add_security_headers(response):
       headers = {
           # Force HTTPS for 1 year, including subdomains
           "Strict-Transport-Security": "max-age=31536000; includeSubDomains",
           # Block XSS even if escaping fails
           "Content-Security-Policy": "default-src 'self'; script-src 'self'",
           # Prevent clickjacking
           "X-Frame-Options": "DENY",
           # Stop MIME-type sniffing
           "X-Content-Type-Options": "nosniff",
           # Control referrer information leakage
           "Referrer-Policy": "strict-origin-when-cross-origin",
           # Restrict browser features
           "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
       }
       for key, value in headers.items():
           response.headers[key] = value
       return response

   @app.route("/")
   def index():
       return "<h1>Secure by default</h1>"

   if __name__ == "__main__":
       app.run()
   ```

   ```bash
   # Verify headers are set
   curl -sI http://localhost:5000/ | grep -iE "strict|content-security|x-frame|x-content|referrer|permissions"
   ```

2. **Audit a site's security headers**

   ```bash
   # Check headers on a production site
   curl -sI https://github.com | grep -iE "strict|content-security|x-frame|x-content"

   # Compare with a site that lacks headers
   curl -sI https://example.com | grep -iE "strict|content-security|x-frame|x-content"

   # Use securityheaders.com for a grade
   # (visit https://securityheaders.com/?q=github.com in a browser)
   ```

3. **Enforce HTTPS with redirect**

   ```python
   # https_redirect.py
   from flask import Flask, request, redirect

   app = Flask(__name__)

   @app.before_request
   def enforce_https():
       # In production behind a reverse proxy, check X-Forwarded-Proto
       if request.headers.get("X-Forwarded-Proto", "http") != "https":
           url = request.url.replace("http://", "https://", 1)
           return redirect(url, code=301)

   @app.route("/")
   def index():
       return "<h1>HTTPS only</h1>"
   ```

   ```bash
   # Test locally with the header a reverse proxy would set
   curl -sI -H "X-Forwarded-Proto: http" http://localhost:5000/
   # HTTP/1.1 301 -- redirects to HTTPS

   curl -sI -H "X-Forwarded-Proto: https" http://localhost:5000/
   # HTTP/1.1 200 -- serves the page
   ```

4. **Security review checklist**

   ```text
   Run through this checklist before every deployment:

   Authentication
   [ ] Passwords hashed with bcrypt/argon2 (not SHA-256, not MD5)
   [ ] Sessions expire and can be revoked
   [ ] MFA available for privileged accounts
   [ ] Rate limiting on login endpoints

   Authorization
   [ ] Every endpoint has server-side access control
   [ ] Object-level checks (no IDOR)
   [ ] Principle of least privilege for service accounts

   Input
   [ ] All SQL uses parameterized queries
   [ ] HTML output is escaped or uses a template engine
   [ ] File uploads validated by type and size
   [ ] No shell=True with user input

   Secrets
   [ ] No credentials in source code or logs
   [ ] .env in .gitignore
   [ ] Pre-commit hooks scan for secrets
   [ ] Secrets rotated on schedule

   Dependencies
   [ ] Lock file committed and up to date
   [ ] npm audit / pip-audit clean or exceptions documented
   [ ] Base images scanned with Trivy

   Transport & Headers
   [ ] HTTPS everywhere (HSTS enabled)
   [ ] CSP blocks inline scripts
   [ ] X-Frame-Options: DENY
   [ ] X-Content-Type-Options: nosniff
   [ ] Cookies: Secure, HttpOnly, SameSite=Lax

   Logging
   [ ] Authentication events logged
   [ ] Authorization failures logged
   [ ] No secrets in log output
   [ ] Logs forwarded to a central system
   ```

### Checkpoint

Run the security headers Flask app and verify every header appears in the
response. Audit the headers of three production websites. Apply the security
review checklist to a project you work on and identify at least three items that
need improvement.

---

## Practice Projects

### Project 1: Secure Login System

Build a Flask application with registration, login, logout, and a protected
dashboard. Hash passwords with argon2, use server-side sessions, add CSRF
protection, rate-limit login attempts, and set all security headers. Write tests
that prove: wrong passwords fail, expired sessions are rejected, and rate
limiting kicks in after five failed attempts.

### Project 2: Vulnerability Scanner

Write a Python script that takes a URL and checks for common misconfigurations:
missing security headers, exposed server version, open redirect, mixed content,
and insecure cookies. Output a report with severity ratings and remediation
advice. Test it against intentionally vulnerable apps like OWASP Juice Shop.

### Project 3: Dependency Audit Pipeline

Create a CI pipeline (GitHub Actions) that runs `pip-audit`, `npm audit`, Trivy
image scan, and gitleaks on every pull request. Fail the build on high-severity
findings. Generate an SBOM in CycloneDX format and upload it as a build
artifact. Document the process for triaging and suppressing false positives.

---

## Quick Reference

| Topic             | Key Defense                  | Common Mistake                 | Tool / Standard      |
| ----------------- | ---------------------------- | ------------------------------ | -------------------- |
| Threat Modeling   | STRIDE + data flow diagrams  | Skipping it entirely           | OWASP Threat Dragon  |
| Authentication    | bcrypt/argon2 + MFA          | SHA-256 for passwords          | pyotp, bcrypt        |
| Authorization     | Server-side RBAC/ABAC        | Client-side checks, IDOR       | Flask decorators     |
| SQL Injection     | Parameterized queries        | String concatenation           | SQLAlchemy, psycopg2 |
| XSS               | Output escaping + CSP        | Rendering raw user input       | Jinja2 autoescaping  |
| Command Injection | Avoid shell=True, use lists  | subprocess with shell=True     | subprocess.run       |
| Secrets           | Env vars + secret managers   | Hardcoded credentials in code  | gitleaks, Vault      |
| Dependencies      | Lockfiles + audit + SBOM     | Ignoring npm audit warnings    | pip-audit, Trivy     |
| Security Headers  | HSTS, CSP, X-Frame-Options   | No headers at all              | securityheaders.com  |
| OWASP Top 10      | Checklist-driven code review | Treating security as a feature | OWASP ZAP            |

## See Also

- [Cryptography Lesson Plan](cryptography-lesson-plan.md) -- Crypto primitives
  used in auth
- [Security Scanning Cheatsheet](../how/security-scanning.md) -- Tools for
  dependency scanning
- [HTTP Cheatsheet](../how/http.md) -- Headers and authentication patterns
