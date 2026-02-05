# Shell Scripting Cheat Sheet

## Script Setup

```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined var, pipe failure
```

| Flag          | Effect                              |
| ------------- | ----------------------------------- |
| `-e`          | Exit immediately on command failure |
| `-u`          | Error on undefined variables        |
| `-o pipefail` | Pipe fails if any command fails     |
| `-x`          | Print commands as executed (debug)  |

## Variables

```bash
# Assignment (no spaces around =)
name="alice"
count=42

# Usage
echo "Hello, $name"
echo "Count: ${count}"

# Default values
${var:-default}    # Use default if unset/empty
${var:=default}    # Set and use default if unset/empty
${var:+alt}        # Use alt if var IS set
${var:?error msg}  # Exit with error if unset/empty
```

## String Operations

```bash
str="hello world"

${#str}            # Length: 11
${str:0:5}         # Substring: "hello"
${str:6}           # From position: "world"
${str/world/there} # Replace first: "hello there"
${str//o/O}        # Replace all: "hellO wOrld"
${str#hello }      # Remove prefix: "world"
${str%world}       # Remove suffix: "hello "
${str^^}           # Uppercase: "HELLO WORLD"
${str,,}           # Lowercase: "hello world"
```

## Arrays

```bash
# Declare
fruits=("apple" "banana" "cherry")

# Access
echo "${fruits[0]}"      # First element
echo "${fruits[@]}"      # All elements
echo "${#fruits[@]}"     # Length
echo "${!fruits[@]}"     # All indices

# Modify
fruits+=("date")         # Append
fruits[1]="blueberry"    # Replace
unset fruits[2]          # Remove

# Iterate
for fruit in "${fruits[@]}"; do
  echo "$fruit"
done
```

## Conditionals

### If Statements

```bash
if [[ condition ]]; then
  # commands
elif [[ condition ]]; then
  # commands
else
  # commands
fi
```

### Test Operators

**Strings:**

| Operator       | Meaning             |
| -------------- | ------------------- |
| `-z "$s"`      | String is empty     |
| `-n "$s"`      | String not empty    |
| `"$a" = "$b"`  | Strings equal       |
| `"$a" != "$b"` | Strings differ      |
| `"$a" < "$b"`  | Alphabetically less |

**Numbers:**

| Operator    | Meaning          |
| ----------- | ---------------- |
| `$a -eq $b` | Equal            |
| `$a -ne $b` | Not equal        |
| `$a -lt $b` | Less than        |
| `$a -le $b` | Less or equal    |
| `$a -gt $b` | Greater than     |
| `$a -ge $b` | Greater or equal |

**Files:**

| Operator    | Meaning          |
| ----------- | ---------------- |
| `-e file`   | Exists           |
| `-f file`   | Regular file     |
| `-d file`   | Directory        |
| `-r file`   | Readable         |
| `-w file`   | Writable         |
| `-x file`   | Executable       |
| `-s file`   | Size > 0         |
| `f1 -nt f2` | f1 newer than f2 |

**Logic:**

```bash
[[ cond1 && cond2 ]]   # AND
[[ cond1 || cond2 ]]   # OR
[[ ! condition ]]      # NOT
```

### Case Statements

```bash
case "$input" in
  start|begin)
    echo "Starting..."
    ;;
  stop|end)
    echo "Stopping..."
    ;;
  *)
    echo "Unknown command"
    ;;
esac
```

## Loops

### For Loop

```bash
# Over list
for item in apple banana cherry; do
  echo "$item"
done

# Over array
for item in "${array[@]}"; do
  echo "$item"
done

# C-style
for ((i=0; i<10; i++)); do
  echo "$i"
done

# Over files
for file in *.txt; do
  echo "$file"
done

# Over command output
for user in $(cut -d: -f1 /etc/passwd); do
  echo "$user"
done
```

### While Loop

```bash
# Counter
count=0
while [[ $count -lt 5 ]]; do
  echo "$count"
  ((count++))
done

# Read lines from file
while IFS= read -r line; do
  echo "$line"
done < input.txt

# Read lines from command
while IFS= read -r line; do
  echo "$line"
done < <(some_command)
```

### Loop Control

```bash
break      # Exit loop
continue   # Skip to next iteration
```

## Functions

```bash
# Definition
greet() {
  local name="$1"        # Local variable
  local greeting="${2:-Hello}"  # With default
  echo "$greeting, $name!"
  return 0               # Exit status
}

# Usage
greet "Alice"            # "Hello, Alice!"
greet "Bob" "Hi"         # "Hi, Bob!"
result=$(greet "Carol")  # Capture output
```

### Special Variables in Functions

| Variable | Meaning                   |
| -------- | ------------------------- |
| `$0`     | Script name               |
| `$1-$9`  | Positional arguments      |
| `$@`     | All arguments (as array)  |
| `$*`     | All arguments (as string) |
| `$#`     | Number of arguments       |
| `$?`     | Last command exit status  |
| `$$`     | Current script PID        |

## Input/Output

### Read Input

```bash
# Basic
read -r name
echo "Hello, $name"

# With prompt
read -rp "Enter name: " name

# Silent (passwords)
read -rsp "Password: " pass

# With timeout
read -rt 5 -p "Quick! " answer
```

### Here Documents

```bash
cat <<EOF
Line 1
Line 2 with $variable expansion
EOF

cat <<'EOF'
Line with $literal dollar signs
EOF
```

### Redirection

```bash
cmd > file       # Stdout to file (overwrite)
cmd >> file      # Stdout to file (append)
cmd 2> file      # Stderr to file
cmd &> file      # Both stdout and stderr
cmd 2>&1         # Stderr to stdout
cmd < file       # File to stdin
cmd <<< "string" # String to stdin
```

## Error Handling

```bash
# Check exit status
if ! command; then
  echo "Command failed"
  exit 1
fi

# Trap errors
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Cleanup on exit
cleanup() {
  rm -f "$tmpfile"
}
trap cleanup EXIT

# Custom error function
die() {
  echo "Error: $*" >&2
  exit 1
}

[[ -f "$file" ]] || die "File not found: $file"
```

## Common Patterns

### Argument Parsing

```bash
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose)
      verbose=true
      shift
      ;;
    -f|--file)
      file="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done
```

### Check Dependencies

```bash
require() {
  command -v "$1" >/dev/null 2>&1 || die "$1 required but not found"
}

require curl
require jq
```

### Temporary Files

```bash
tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

echo "data" > "$tmpfile"
```

### Progress Indicator

```bash
spinner() {
  local pid=$1
  local chars="/-\|"
  while kill -0 "$pid" 2>/dev/null; do
    for ((i=0; i<${#chars}; i++)); do
      printf "\r%s" "${chars:$i:1}"
      sleep 0.1
    done
  done
  printf "\r"
}

long_command &
spinner $!
```

## See Also

- [Unix](unix.md) — Individual commands
- [Regex](regex.md) — Pattern matching in scripts
