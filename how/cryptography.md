# Cryptography Cheat Sheet

Commands for hashing, encryption, certificates, and TLS inspection.

## Hashing

```bash
# SHA-256 hash of a string
echo -n "hello" | shasum -a 256

# SHA-256 hash of a file
shasum -a 256 myfile.txt

# Verify a checksum file
shasum -a 256 -c checksums.sha256

# MD5 (legacy, don't use for security)
md5 myfile.txt              # macOS
md5sum myfile.txt            # Linux

# Generate a hash with openssl
openssl dgst -sha256 myfile.txt
```

## Random Data

```bash
# Random hex string (32 bytes = 256 bits)
openssl rand -hex 32

# Random base64 string
openssl rand -base64 32

# Random bytes to file
openssl rand 32 > key.bin
```

```python
import secrets, os

secrets.token_hex(32)        # Hex string (64 chars)
secrets.token_urlsafe(32)    # URL-safe base64
os.urandom(32)               # Raw bytes
```

## Symmetric Encryption (AES)

```bash
# Encrypt a file (AES-256-CBC, password-based)
openssl enc -aes-256-cbc -pbkdf2 -in plain.txt -out encrypted.enc

# Decrypt
openssl enc -aes-256-cbc -pbkdf2 -d -in encrypted.enc -out plain.txt

# Encrypt with a key file
openssl enc -aes-256-cbc -pbkdf2 -in plain.txt -out encrypted.enc -kfile key.bin

# Inspect encrypted file
xxd encrypted.enc | head -5
```

### Python (Fernet -- Safe Defaults)

```python
from cryptography.fernet import Fernet

key = Fernet.generate_key()       # Save this
f = Fernet(key)
token = f.encrypt(b"secret")      # Encrypt
f.decrypt(token)                  # Decrypt
```

### Python (AES-GCM -- Authenticated)

```python
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os

key = AESGCM.generate_key(bit_length=256)
gcm = AESGCM(key)
nonce = os.urandom(12)            # Never reuse with same key
ct = gcm.encrypt(nonce, b"data", b"metadata")
pt = gcm.decrypt(nonce, ct, b"metadata")
```

## Key Pairs

### RSA

```bash
# Generate private key (4096-bit)
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out rsa.key

# Extract public key
openssl pkey -in rsa.key -pubout -out rsa.pub

# Inspect key details
openssl pkey -in rsa.key -text -noout
```

### Ed25519 (Modern, Preferred)

```bash
# Generate private key
openssl genpkey -algorithm ED25519 -out ed25519.key

# Extract public key
openssl pkey -in ed25519.key -pubout -out ed25519.pub
```

### SSH Keys

```bash
# Generate Ed25519 SSH key
ssh-keygen -t ed25519 -C "you@example.com"

# Generate RSA SSH key (if Ed25519 not supported)
ssh-keygen -t rsa -b 4096 -C "you@example.com"

# View public key fingerprint
ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

## Signing and Verification

```bash
# Sign a file
openssl pkeyutl -sign -inkey ed25519.key -in document.txt -out document.sig

# Verify a signature
openssl pkeyutl -verify -pubin -inkey ed25519.pub \
  -in document.txt -sigfile document.sig

# Sign with RSA + SHA-256 (for larger files)
openssl dgst -sha256 -sign rsa.key -out file.sig file.txt

# Verify RSA signature
openssl dgst -sha256 -verify rsa.pub -signature file.sig file.txt
```

## Certificates

### Inspect

```bash
# View a certificate file
openssl x509 -in cert.pem -text -noout

# View remote server certificate
echo | openssl s_client -connect example.com:443 2>/dev/null | \
  openssl x509 -text -noout

# Check expiration date
openssl x509 -in cert.pem -noout -dates

# View certificate chain
echo | openssl s_client -connect example.com:443 -showcerts 2>/dev/null | \
  grep -E "s:|i:"

# Get certificate fingerprint
openssl x509 -in cert.pem -fingerprint -sha256 -noout
```

### Create

```bash
# Self-signed certificate (EC key, 1 year)
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
  -keyout server.key -out server.crt -days 365 -nodes \
  -subj "/CN=localhost"

# Create a CSR (Certificate Signing Request)
openssl req -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
  -keyout server.key -out server.csr -nodes -subj "/CN=myapp.local"

# Sign a CSR with your CA
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out server.crt -days 365

# Verify certificate against CA
openssl verify -CAfile ca.crt server.crt
```

## TLS Inspection

```bash
# Test TLS connection
openssl s_client -connect example.com:443 </dev/null 2>/dev/null | \
  grep -E "Protocol|Cipher|Verify"

# Force TLS version
openssl s_client -connect example.com:443 -tls1_3 </dev/null
openssl s_client -connect example.com:443 -tls1_2 </dev/null

# View TLS details with curl
curl -vI https://example.com 2>&1 | grep -E "TLS|SSL|subject|issuer"

# Check certificate expiration with curl
curl -vI https://example.com 2>&1 | grep "expire"

# Test with specific SNI (Server Name Indication)
openssl s_client -connect cdn.example.com:443 -servername example.com
```

## Password Hashing

```python
# PBKDF2 (stdlib)
import hashlib, os

salt = os.urandom(16)
key = hashlib.pbkdf2_hmac("sha256", b"password", salt, 100_000)

# bcrypt (pip install bcrypt)
import bcrypt

hashed = bcrypt.hashpw(b"password", bcrypt.gensalt())
bcrypt.checkpw(b"password", hashed)  # True
```

## HMAC

```bash
# HMAC-SHA256 of a string
echo -n "message" | openssl dgst -sha256 -hmac "secret-key"

# HMAC-SHA256 of a file
openssl dgst -sha256 -hmac "secret-key" myfile.txt
```

```python
import hmac, hashlib

sig = hmac.new(b"secret", b"message", hashlib.sha256).hexdigest()

# Constant-time comparison (always use for secrets)
hmac.compare_digest(sig, expected_sig)
```

## Base64

```bash
# Encode
echo -n "hello" | base64
openssl base64 -in file.bin -out file.b64

# Decode
echo "aGVsbG8=" | base64 -d
openssl base64 -d -in file.b64 -out file.bin
```

## Quick Reference

| Task                  | Command                                                         |
| --------------------- | --------------------------------------------------------------- |
| Hash a file           | `shasum -a 256 file`                                            |
| Generate random key   | `openssl rand -hex 32`                                          |
| Generate secure token | `python3 -c "import secrets; print(secrets.token_urlsafe(32))"` |
| Encrypt a file        | `openssl enc -aes-256-cbc -pbkdf2 -in f -out f.enc`             |
| Generate Ed25519 key  | `openssl genpkey -algorithm ED25519 -out key.pem`               |
| Generate SSH key      | `ssh-keygen -t ed25519`                                         |
| Sign a file           | `openssl pkeyutl -sign -inkey key -in f -out f.sig`             |
| Inspect remote cert   | `openssl s_client -connect host:443`                            |
| Check cert expiration | `openssl x509 -in cert.pem -noout -dates`                       |
| Self-signed cert      | `openssl req -x509 -newkey ec ... -subj "/CN=localhost"`        |
| Test TLS version      | `openssl s_client -connect host:443 -tls1_3`                    |
| HMAC a message        | `echo -n msg \| openssl dgst -sha256 -hmac key`                 |

## Algorithm Choices

| Purpose              | Use                | Avoid               |
| -------------------- | ------------------ | ------------------- |
| File integrity       | SHA-256            | MD5, SHA-1          |
| Password storage     | argon2id, bcrypt   | SHA-256, plain text |
| Symmetric encryption | AES-256-GCM        | AES-ECB, DES        |
| Signatures           | Ed25519            | RSA-1024, DSA       |
| Key exchange         | X25519, ECDH P-256 | RSA-2048            |
| TLS                  | TLS 1.3            | TLS 1.0, TLS 1.1    |
| Random tokens        | `secrets` module   | `random` module     |
| Message auth         | HMAC-SHA256        | Raw hash            |

## See Also

- [Cryptography Lesson Plan](../learn/cryptography-lesson-plan.md) --
  Progressive lessons from hashing to key management
- [HTTP Cheatsheet](http.md) -- TLS in the context of web requests
- [Security Scanning](security-scanning.md) -- Detecting leaked secrets and
  vulnerable dependencies
- [Shell Cheatsheet](shell.md) -- Scripting patterns for automation
