# Cryptography Lesson Plan

Practical cryptography for engineers -- what to use, when, and why, without the
math PhD.

## Lesson 1: Hashing

**Goal:** Understand hash functions, their properties, and practical uses.

### Concepts

A hash function maps arbitrary data to a fixed-size digest. Good hash functions
are deterministic (same input, same output), one-way (can't reverse the digest),
and collision-resistant (hard to find two inputs with the same digest). Use
hashes for integrity verification, password storage, and content addressing --
never for encryption.

### Exercises

1. **Hash a file and a string**

   ```bash
   echo -n "hello" | shasum -a 256
   # a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e

   echo -n "hello!" | shasum -a 256
   # Completely different -- one character changes everything (avalanche effect)

   shasum -a 256 /etc/hosts    # Hash a file for integrity
   ```

2. **Compare hash algorithms**

   ```bash
   echo -n "test" | md5           # 098f6bcd4621d373cade4e832627b4f6 (128-bit, broken)
   echo -n "test" | shasum -a 1   # a94a8fe5ccb19ba61c4c0873d391e987982fbbd3 (160-bit, weak)
   echo -n "test" | shasum -a 256 # 9f86d081884c7d659a2feaa0c55ad015... (256-bit, use this)
   ```

   MD5 and SHA-1 have known collision attacks. SHA-256 is the current minimum.

3. **Hash passwords properly**

   ```python
   # bad_password.py -- NEVER do this
   import hashlib
   plain_hash = hashlib.sha256(b"password123").hexdigest()
   print(f"Unsalted: {plain_hash}")  # Same for every user with this password

   # good_password.py -- use bcrypt or argon2
   import hashlib, os
   salt = os.urandom(16)
   key = hashlib.pbkdf2_hmac("sha256", b"password123", salt, 100_000)
   print(f"Salt: {salt.hex()}")
   print(f"Key:  {key.hex()}")
   # Different every time because of the random salt
   ```

4. **Verify file integrity**

   ```bash
   # Create a file and its checksum
   echo "important data" > payload.txt
   shasum -a 256 payload.txt > payload.sha256

   # Later, verify nothing changed
   shasum -a 256 -c payload.sha256
   # payload.txt: OK

   # Tamper and re-verify
   echo "modified" >> payload.txt
   shasum -a 256 -c payload.sha256
   # payload.txt: FAILED
   ```

### Checkpoint

Hash three different files. Modify one byte in one file and re-hash. Verify the
digest changes completely. Explain why SHA-256 is preferred over MD5.

---

## Lesson 2: Symmetric Encryption

**Goal:** Encrypt and decrypt data with a shared secret key.

### Concepts

Symmetric encryption uses the same key to encrypt and decrypt. AES is the
standard -- fast, well-studied, hardware-accelerated. The mode of operation
matters: ECB is broken (patterns leak through), CBC requires an IV and is
vulnerable to padding oracles if misused, GCM provides both encryption and
authentication (use this by default). The key must stay secret -- if an attacker
gets the key, everything encrypted with it is compromised.

### Exercises

1. **Encrypt with AES-256-CBC**

   ```bash
   # Encrypt
   echo "secret message" | openssl enc -aes-256-cbc -pbkdf2 -out secret.enc

   # Decrypt
   openssl enc -aes-256-cbc -pbkdf2 -d -in secret.enc
   # Enter the same password -- outputs "secret message"

   # Inspect the encrypted file
   xxd secret.enc | head -5
   # Looks like random bytes -- good
   ```

2. **See why ECB mode is broken**

   ```python
   # ecb_demo.py
   from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
   import os

   key = os.urandom(32)

   # ECB: same plaintext block -> same ciphertext block
   cipher = Cipher(algorithms.AES(key), modes.ECB())
   enc = cipher.encryptor()
   block = b"AAAAAAAAAAAAAAAA"  # 16 bytes = 1 AES block
   c1 = enc.update(block)
   c2 = enc.update(block)
   print(f"ECB same input:  {c1.hex()} == {c2.hex()}?  {c1 == c2}")
   # True -- patterns leak through
   ```

   This is why the ECB penguin exists: encrypt a bitmap with ECB and the image
   is still recognizable.

3. **Encrypt with AES-256-GCM (authenticated)**

   ```python
   # gcm_demo.py
   from cryptography.hazmat.primitives.ciphers.aead import AESGCM
   import os

   key = AESGCM.generate_key(bit_length=256)
   gcm = AESGCM(key)
   nonce = os.urandom(12)

   # Encrypt with associated data (authenticated but not encrypted)
   ciphertext = gcm.encrypt(nonce, b"secret payload", b"metadata")

   # Decrypt
   plaintext = gcm.decrypt(nonce, ciphertext, b"metadata")
   print(plaintext.decode())  # "secret payload"

   # Tamper with ciphertext -- decryption fails
   try:
       gcm.decrypt(nonce, ciphertext[:-1] + bytes([0]), b"metadata")
   except Exception as e:
       print(f"Tamper detected: {e}")
   ```

   GCM detects both data tampering and metadata tampering.

4. **Generate and manage keys**

   ```bash
   # Generate a random 256-bit key
   openssl rand -hex 32

   # Generate a key and save it
   openssl rand 32 > aes.key

   # Encrypt a file with that key
   openssl enc -aes-256-cbc -pbkdf2 -in payload.txt -out payload.enc -kfile aes.key

   # Decrypt
   openssl enc -aes-256-cbc -pbkdf2 -d -in payload.enc -out payload.dec -kfile aes.key
   diff payload.txt payload.dec  # No difference
   ```

### Checkpoint

Encrypt a file with AES-256-GCM using Python. Tamper with one byte of the
ciphertext and show that decryption fails. Explain why GCM is preferred over
CBC.

---

## Lesson 3: Asymmetric Encryption

**Goal:** Use key pairs for encryption and digital signatures.

### Concepts

Asymmetric cryptography uses two keys: a public key anyone can have, and a
private key only you hold. Encrypt with the public key, decrypt with the
private. Sign with the private key, verify with the public. RSA is the classic
algorithm; Ed25519 (for signatures) and X25519 (for key exchange) are modern
elliptic-curve alternatives -- smaller keys, faster operations, fewer footguns.

### Exercises

1. **Generate an RSA key pair**

   ```bash
   # Generate private key (4096-bit)
   openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out rsa.key

   # Extract public key
   openssl pkey -in rsa.key -pubout -out rsa.pub

   # Inspect the public key
   openssl pkey -pubin -in rsa.pub -text -noout
   ```

2. **Encrypt and decrypt with RSA**

   ```bash
   # Encrypt a small message with the public key
   echo -n "secret" | openssl pkeyutl -encrypt -pubin -inkey rsa.pub -out msg.enc

   # Decrypt with the private key
   openssl pkeyutl -decrypt -inkey rsa.key -in msg.enc
   # Outputs: secret
   ```

   RSA can only encrypt data smaller than the key size. In practice, encrypt a
   symmetric key with RSA, then encrypt the data with that key (hybrid
   encryption).

3. **Generate Ed25519 keys**

   ```bash
   # Ed25519 -- modern, fast, small keys
   openssl genpkey -algorithm ED25519 -out ed25519.key
   openssl pkey -in ed25519.key -pubout -out ed25519.pub

   # Compare key sizes
   wc -c rsa.key ed25519.key
   # RSA: ~3200 bytes, Ed25519: ~119 bytes
   ```

4. **Sign and verify a file**

   ```bash
   # Create a document
   echo "I agree to the terms" > contract.txt

   # Sign with private key
   openssl pkeyutl -sign -inkey ed25519.key -in contract.txt -out contract.sig

   # Verify with public key
   openssl pkeyutl -verify -pubin -inkey ed25519.pub \
     -in contract.txt -sigfile contract.sig
   # Signature Verified Successfully

   # Tamper and re-verify
   echo "I disagree" > contract.txt
   openssl pkeyutl -verify -pubin -inkey ed25519.pub \
     -in contract.txt -sigfile contract.sig
   # Signature Verification Failure
   ```

### Checkpoint

Generate an Ed25519 key pair. Sign a file, verify it, tamper with the file, and
show verification fails. Explain the difference between encrypting and signing.

---

## Lesson 4: Certificates and Trust

**Goal:** Understand X.509 certificates, certificate chains, and how trust is
established.

### Concepts

A certificate binds a public key to an identity (domain name, organization).
Certificate Authorities (CAs) sign certificates to vouch for the binding. Your
OS and browser ship with a set of trusted root CAs. Trust flows down the chain:
root CA signs intermediate CA, intermediate signs your server certificate.
Self-signed certificates skip this chain -- useful for development, not for
production.

### Exercises

1. **Inspect a real certificate**

   ```bash
   # Fetch and display a certificate
   echo | openssl s_client -connect github.com:443 2>/dev/null | \
     openssl x509 -text -noout | head -30

   # Key fields: Issuer, Subject, Validity, Public Key Algorithm
   ```

2. **View the certificate chain**

   ```bash
   echo | openssl s_client -connect github.com:443 -showcerts 2>/dev/null | \
     grep -E "s:|i:"
   # s: = subject (who this cert belongs to)
   # i: = issuer (who signed it)
   # Follow the chain: server -> intermediate -> root
   ```

3. **Create a self-signed certificate**

   ```bash
   # Generate key + cert in one step
   openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
     -keyout selfsigned.key -out selfsigned.crt -days 365 -nodes \
     -subj "/CN=localhost"

   # Inspect it
   openssl x509 -in selfsigned.crt -text -noout | grep -E "Issuer|Subject|Not"
   # Issuer and Subject are the same -- self-signed
   ```

4. **Build a mini CA**

   ```bash
   # Create a CA key and certificate
   openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
     -keyout ca.key -out ca.crt -days 3650 -nodes -subj "/CN=My CA"

   # Create a server key and certificate signing request (CSR)
   openssl req -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
     -keyout server.key -out server.csr -nodes -subj "/CN=myapp.local"

   # Sign the server cert with our CA
   openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
     -CAcreateserial -out server.crt -days 365

   # Verify the chain
   openssl verify -CAfile ca.crt server.crt
   # server.crt: OK
   ```

### Checkpoint

Inspect the certificate chain for three different websites. Identify the root
CA, the intermediate, and the server certificate. Create your own CA and sign a
certificate.

---

## Lesson 5: TLS in Practice

**Goal:** Understand the TLS handshake and how to inspect encrypted connections.

### Concepts

TLS (Transport Layer Security) secures HTTP, SMTP, and most network protocols.
The handshake negotiates a cipher suite (key exchange + bulk cipher +
MAC/authentication), authenticates the server via its certificate, and
establishes session keys. TLS 1.3 simplified this to one round trip. The
certificate proves identity; the session key provides confidentiality and
integrity.

### Exercises

1. **Inspect a TLS handshake**

   ```bash
   # Full handshake details
   openssl s_client -connect github.com:443 </dev/null 2>/dev/null | \
     grep -E "Protocol|Cipher|Verify"
   # Protocol: TLSv1.3
   # Cipher: TLS_AES_128_GCM_SHA256
   # Verify return code: 0 (ok)
   ```

2. **Compare TLS versions**

   ```bash
   # Try TLS 1.2
   openssl s_client -connect github.com:443 -tls1_2 </dev/null 2>/dev/null | \
     grep -E "Protocol|Cipher"

   # Try TLS 1.3
   openssl s_client -connect github.com:443 -tls1_3 </dev/null 2>/dev/null | \
     grep -E "Protocol|Cipher"

   # TLS 1.3 cipher suites are shorter -- fewer choices, all good ones
   ```

3. **Test cipher suites with curl**

   ```bash
   # Default (modern cipher suite)
   curl -sI https://github.com | head -5

   # Verbose to see TLS negotiation
   curl -vI https://github.com 2>&1 | grep -E "TLS|SSL|subject|issuer"
   ```

4. **Test certificate pinning manually**

   ```bash
   # Get the certificate fingerprint
   echo | openssl s_client -connect github.com:443 2>/dev/null | \
     openssl x509 -fingerprint -sha256 -noout

   # Save it
   EXPECTED="$(echo | openssl s_client -connect github.com:443 2>/dev/null | \
     openssl x509 -fingerprint -sha256 -noout)"

   # Later, compare
   ACTUAL="$(echo | openssl s_client -connect github.com:443 2>/dev/null | \
     openssl x509 -fingerprint -sha256 -noout)"

   [ "$EXPECTED" = "$ACTUAL" ] && echo "Pin matches" || echo "PIN CHANGED"
   ```

### Checkpoint

Inspect TLS connections to five websites. Record protocol version, cipher suite,
and certificate issuer. Identify which use TLS 1.3 vs 1.2.

---

## Lesson 6: Key Management

**Goal:** Store, rotate, and distribute keys without leaking them.

### Concepts

The hardest part of cryptography is key management -- not the math. Keys in
source code get stolen. Keys without rotation become liabilities. Keys without
backup get lost. Use environment variables or secret managers (not config files
in git). Rotate keys on schedule and on compromise. Derive per-use keys from a
master key when possible.

### Exercises

1. **Find leaked secrets**

   ```bash
   # Scan a repo for accidental secrets
   git log --all -p | grep -iE "(api_key|secret|password|token)\s*=" | head -10

   # Better: use a dedicated tool
   # brew install gitleaks
   gitleaks detect --source . --verbose
   ```

2. **Use environment variables for secrets**

   ```python
   # config.py
   import os

   # Bad -- hardcoded
   # API_KEY = "sk-abc123"

   # Good -- from environment
   API_KEY = os.environ["API_KEY"]  # Fails loud if missing

   # Acceptable -- with default for non-secret config only
   LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO")
   ```

3. **Derive keys from a master key**

   ```python
   # key_derivation.py
   from cryptography.hazmat.primitives.kdf.hkdf import HKDF
   from cryptography.hazmat.primitives import hashes
   import os

   master_key = os.urandom(32)

   def derive_key(master: bytes, purpose: str) -> bytes:
       return HKDF(
           algorithm=hashes.SHA256(),
           length=32,
           salt=None,
           info=purpose.encode(),
       ).derive(master)

   enc_key = derive_key(master_key, "encryption")
   sig_key = derive_key(master_key, "signing")
   print(f"Encryption key: {enc_key.hex()[:32]}...")
   print(f"Signing key:    {sig_key.hex()[:32]}...")
   # Different keys from the same master, deterministic per purpose
   ```

4. **Rotate an encryption key**

   ```text
   Key rotation strategy:
   1. Generate new key (key-v2)
   2. Start encrypting new data with key-v2
   3. On read, try key-v2 first, fall back to key-v1
   4. Re-encrypt old data with key-v2 (background migration)
   5. After migration, retire key-v1

   Metadata format:
   {"key_version": 2, "ciphertext": "...", "nonce": "..."}
   ```

### Checkpoint

Write a script that encrypts data with a versioned key scheme. Simulate a key
rotation by re-encrypting data with a new key. Show that old data is still
readable during the transition.

---

## Lesson 7: Common Mistakes

**Goal:** Recognize and avoid the cryptographic mistakes that cause real
breaches.

### Concepts

Most cryptographic failures aren't mathematical breaks -- they're misuse.
Rolling your own crypto, reusing nonces, using ECB mode, comparing MACs with
`==` (timing attack), seeding randomness badly, and encrypting without
authenticating. The fix is almost always: use a high-level library (libsodium,
Python's `cryptography` with Fernet) and don't make low-level choices yourself.

### Exercises

1. **Timing attack on string comparison**

   ```python
   # timing_demo.py
   import time

   secret = "correct-token-value"

   def insecure_compare(a: str, b: str) -> bool:
       """Vulnerable: short-circuits on first mismatch."""
       if len(a) != len(b):
           return False
       for x, y in zip(a, b):
           if x != y:
               return False
       return True

   import hmac
   def secure_compare(a: str, b: str) -> bool:
       """Safe: constant-time comparison."""
       return hmac.compare_digest(a.encode(), b.encode())
   ```

   In practice, `hmac.compare_digest` is always correct. Never compare secrets
   with `==`.

2. **Nonce reuse breaks GCM**

   ```python
   # nonce_reuse.py
   from cryptography.hazmat.primitives.ciphers.aead import AESGCM
   import os

   key = AESGCM.generate_key(bit_length=256)
   gcm = AESGCM(key)
   nonce = os.urandom(12)

   c1 = gcm.encrypt(nonce, b"message one", None)
   c2 = gcm.encrypt(nonce, b"message two", None)  # SAME NONCE -- catastrophic

   # XOR of ciphertexts reveals XOR of plaintexts
   xor = bytes(a ^ b for a, b in zip(c1, c2))
   print(f"XOR leak: {xor[:11]}")  # Related to plaintext difference
   # Never reuse a nonce with the same key
   ```

3. **Use Fernet for safe defaults**

   ```python
   # fernet_demo.py -- high-level, hard to misuse
   from cryptography.fernet import Fernet

   key = Fernet.generate_key()
   f = Fernet(key)

   token = f.encrypt(b"sensitive data")
   print(f"Token: {token[:40]}...")

   plaintext = f.decrypt(token)
   print(f"Decrypted: {plaintext.decode()}")

   # Fernet handles: AES-128-CBC + HMAC-SHA256 + IV generation + timestamp
   # You can't accidentally reuse a nonce or forget authentication
   ```

4. **Spot the vulnerability**

   ```text
   Review each scenario and identify the flaw:

   A: encrypt(password, AES-ECB) stored in database
      Flaw: ECB leaks patterns, no salt, identical passwords produce
      identical ciphertext

   B: token = SHA256(user_id + timestamp)
      Flaw: No secret -- anyone who knows the scheme can forge tokens

   C: nonce = counter++ (starting from 0 on every restart)
      Flaw: Nonce reuse after restart -- counter resets, old nonces repeat

   D: ciphertext = AES-CBC(data, key, iv) with no HMAC
      Flaw: No authentication -- attacker can modify ciphertext
      (padding oracle attack)
   ```

### Checkpoint

Write a program that demonstrates one cryptographic mistake and its fix. Explain
why the high-level fix (Fernet, libsodium) prevents the mistake.

---

## Lesson 8: Choosing the Right Tool

**Goal:** Pick the right cryptographic primitive for the problem.

### Concepts

Don't start from algorithms -- start from the problem. Need to verify data
hasn't changed? Hash it. Need to prove who sent a message? Sign it. Need to hide
data in transit? TLS. Need to hide data at rest? Encrypt with AES-GCM. Need to
store passwords? Use bcrypt or argon2. Need to generate tokens? Use
`secrets.token_urlsafe`. The best cryptographic code is the code you didn't
write -- use well-tested libraries and protocols.

### Exercises

1. **Match problems to primitives**

   ```text
   Problem                              Primitive
   ──────────────────────────────────   ─────────────────────────
   Verify a download isn't corrupted    SHA-256 hash
   Store user passwords                 bcrypt / argon2
   Encrypt a file for a specific person Hybrid: RSA/ECDH + AES-GCM
   Prove a document hasn't been altered Digital signature (Ed25519)
   Secure an API connection             TLS 1.3
   Generate a session token             secrets.token_urlsafe(32)
   Encrypt database fields at rest      AES-256-GCM (or Fernet)
   Authenticate an API request          HMAC-SHA256
   ```

2. **Generate secure random tokens**

   ```python
   # tokens.py
   import secrets

   # API key (URL-safe base64)
   api_key = secrets.token_urlsafe(32)
   print(f"API key: {api_key}")

   # Session token (hex)
   session = secrets.token_hex(32)
   print(f"Session: {session}")

   # NEVER use random.random() for security -- it's predictable
   import random
   print(f"Insecure: {random.random()}")  # Predictable PRNG -- not for crypto
   ```

3. **Build an HMAC-authenticated API request**

   ```python
   # hmac_auth.py
   import hmac, hashlib, time, json

   SECRET = b"shared-api-secret"

   def sign_request(method: str, path: str, body: str) -> str:
       timestamp = str(int(time.time()))
       message = f"{method}\n{path}\n{timestamp}\n{body}"
       signature = hmac.new(SECRET, message.encode(), hashlib.sha256).hexdigest()
       return f"{timestamp}:{signature}"

   def verify_request(method: str, path: str, body: str, header: str) -> bool:
       timestamp, signature = header.split(":")
       if abs(time.time() - int(timestamp)) > 300:
           return False  # Reject requests older than 5 minutes
       message = f"{method}\n{path}\n{timestamp}\n{body}"
       expected = hmac.new(SECRET, message.encode(), hashlib.sha256).hexdigest()
       return hmac.compare_digest(signature, expected)

   auth = sign_request("POST", "/api/data", '{"key": "value"}')
   print(f"Auth header: {auth}")
   print(f"Valid: {verify_request('POST', '/api/data', '{\"key\": \"value\"}', auth)}")
   ```

4. **Decision checklist**

   ```text
   Before writing crypto code, answer:

   1. Can I avoid crypto entirely? (Use TLS, let the framework handle it)
   2. Can I use a high-level library? (Fernet, libsodium, JWT library)
   3. Am I rolling my own? If yes, stop and reconsider.
   4. Am I using authenticated encryption? (GCM, not bare CBC)
   5. Where do my keys come from? Where are they stored?
   6. What happens when I need to rotate keys?
   7. Am I using secrets.token_* for random values?
   ```

### Checkpoint

Given a scenario (e.g., "build a password reset flow"), identify every
cryptographic primitive needed and justify each choice.

---

## Practice Projects

### Project 1: Encrypted File Vault

Build a CLI tool that encrypts and decrypts files with AES-256-GCM. Support
password-based key derivation (PBKDF2), file integrity verification, and key
rotation. Store metadata (key version, nonce, salt) alongside the ciphertext.

### Project 2: TLS Certificate Monitor

Write a script that checks TLS certificates for a list of domains. Report:
expiration date, days remaining, issuer, protocol version, cipher suite. Alert
when certificates expire within 30 days.

### Project 3: HMAC-Authenticated API

Build a simple HTTP API (Flask or FastAPI) that requires HMAC-signed requests.
The client signs each request with a shared secret; the server verifies the
signature and rejects replays using a timestamp window.

---

## Quick Reference

| Primitive         | Use For                | Don't Use For        | Modern Choice          |
| ----------------- | ---------------------- | -------------------- | ---------------------- |
| SHA-256           | Integrity, fingerprint | Passwords, secrets   | SHA-256 or SHA-3       |
| bcrypt / argon2   | Password storage       | General hashing      | argon2id               |
| AES-256-GCM       | Encrypt + authenticate | Long-term storage    | AES-256-GCM or XChaCha |
| RSA (4096-bit)    | Key exchange, signing  | Bulk encryption      | Ed25519 / X25519       |
| Ed25519           | Digital signatures     | Encryption           | Ed25519                |
| HMAC-SHA256       | Message authentication | Encryption           | HMAC-SHA256            |
| TLS 1.3           | Transport security     | Data at rest         | TLS 1.3                |
| Fernet            | Simple encrypt/decrypt | Large files, streams | Fernet                 |
| `secrets.token_*` | Random tokens, keys    | Anything predictable | `secrets` module       |

## See Also

- [HTTP Cheatsheet](../how/http.md) -- TLS in the context of web requests
- [Security Scanning](../how/security-scanning.md) -- Finding vulnerabilities in
  dependencies
- [Shell Cheatsheet](../how/shell.md) -- openssl CLI patterns
