# Regex Cheat Sheet

## Basic Patterns

| Pattern | Matches                               |
| ------- | ------------------------------------- |
| `.`     | Any single character (except newline) |
| `\d`    | Digit (0-9)                           |
| `\D`    | Non-digit                             |
| `\w`    | Word character (a-z, A-Z, 0-9, \_)    |
| `\W`    | Non-word character                    |
| `\s`    | Whitespace (space, tab, newline)      |
| `\S`    | Non-whitespace                        |
| `\n`    | Newline                               |
| `\t`    | Tab                                   |
| `\r`    | Carriage return                       |

## Anchors

| Pattern | Matches                                 |
| ------- | --------------------------------------- |
| `^`     | Start of string (or line with `m` flag) |
| `$`     | End of string (or line with `m` flag)   |
| `\b`    | Word boundary                           |
| `\B`    | Not a word boundary                     |
| `\A`    | Start of string (absolute)              |
| `\Z`    | End of string (absolute)                |

## Quantifiers

| Pattern | Matches                     |
| ------- | --------------------------- |
| `*`     | 0 or more                   |
| `+`     | 1 or more                   |
| `?`     | 0 or 1 (optional)           |
| `{3}`   | Exactly 3                   |
| `{3,}`  | 3 or more                   |
| `{3,5}` | Between 3 and 5             |
| `*?`    | 0 or more (lazy/non-greedy) |
| `+?`    | 1 or more (lazy/non-greedy) |
| `??`    | 0 or 1 (lazy/non-greedy)    |

### Greedy vs Lazy

```text
String: <div>hello</div>

Greedy:  <.*>   matches "<div>hello</div>"
Lazy:    <.*?>  matches "<div>"
```

## Character Classes

| Pattern        | Matches                         |
| -------------- | ------------------------------- |
| `[abc]`        | a, b, or c                      |
| `[^abc]`       | Not a, b, or c                  |
| `[a-z]`        | Lowercase letter                |
| `[A-Z]`        | Uppercase letter                |
| `[0-9]`        | Digit (same as \d)              |
| `[a-zA-Z]`     | Any letter                      |
| `[a-zA-Z0-9_]` | Word character (same as \w)     |
| `[\s\S]`       | Any character including newline |

**Inside character classes:**

- Most special characters are literal (no escaping needed)
- Escape: `]`, `\`, `^` (at start), `-` (in middle)

## Groups & Capturing

| Pattern        | Description                      |
| -------------- | -------------------------------- |
| `(abc)`        | Capturing group                  |
| `(?:abc)`      | Non-capturing group              |
| `(?<name>abc)` | Named capturing group            |
| `\1`, `\2`     | Backreference to group 1, 2      |
| `(?P=name)`    | Backreference by name (Python)   |
| `\k<name>`     | Backreference by name (JS, .NET) |

### Examples

```regex
# Capture area code from phone number
\((\d{3})\) \d{3}-\d{4}
Input: (415) 555-1234
Group 1: 415

# Named group
(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})

# Backreference - match repeated words
\b(\w+)\s+\1\b
Matches: "the the", "is is"
```

## Alternation

| Pattern        | Matches                   |
| -------------- | ------------------------- |
| `a\|b`         | a or b                    |
| `(cat\|dog)`   | cat or dog (captured)     |
| `(?:cat\|dog)` | cat or dog (not captured) |

## Lookahead & Lookbehind

| Pattern    | Name                | Description         |
| ---------- | ------------------- | ------------------- |
| `(?=abc)`  | Positive lookahead  | Followed by abc     |
| `(?!abc)`  | Negative lookahead  | Not followed by abc |
| `(?<=abc)` | Positive lookbehind | Preceded by abc     |
| `(?<!abc)` | Negative lookbehind | Not preceded by abc |

### Examples

```regex
# Password: at least one digit, one uppercase, one lowercase
^(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}$

# Match "foo" not followed by "bar"
foo(?!bar)
Matches: "foobaz", "foo "
Skips: "foobar"

# Match number preceded by $
(?<=\$)\d+
Input: "Price: $100"
Matches: "100"

# Match word not preceded by @
(?<!@)\bword\b
```

## Flags/Modifiers

| Flag | Name             | Description                       |
| ---- | ---------------- | --------------------------------- |
| `i`  | Case insensitive | `A` matches `a`                   |
| `g`  | Global           | Find all matches                  |
| `m`  | Multiline        | `^`/`$` match line start/end      |
| `s`  | Dotall           | `.` matches newline               |
| `x`  | Extended         | Ignore whitespace, allow comments |
| `u`  | Unicode          | Full Unicode support              |

### Inline flags

```regex
(?i)case insensitive
(?i:just this part) rest is case sensitive
(?-i)turn off case insensitive
```

## Common Patterns

### Email (simplified)

```regex
[\w.-]+@[\w.-]+\.\w{2,}
```

### URL

```regex
https?://[^\s/$.?#].[^\s]*
```

### IPv4 Address

```regex
\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b
```

### Date (YYYY-MM-DD)

```regex
\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])
```

### Phone (US)

```regex
(?:\+1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}
```

### HTML Tag

```regex
<([a-z]+)[^>]*>.*?</\1>
```

### UUID

```regex
[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
```

### Slug

```regex
^[a-z0-9]+(?:-[a-z0-9]+)*$
```

### Quoted String (with escapes)

```regex
"(?:[^"\\]|\\.)*"
```

### Comments (C-style)

```regex
//.*|/\*[\s\S]*?\*/
```

## Language-Specific Notes

### JavaScript

```javascript
const re = /pattern/flags;
const re = new RegExp('pattern', 'flags');

str.match(re)       // Array of matches or null
str.test(re)        // Boolean
str.replace(re, 'new')
str.split(re)
re.exec(str)        // Detailed match info

// Named groups (ES2018+)
const match = /(?<year>\d{4})/.exec('2024');
match.groups.year   // "2024"
```

### Python

```python
import re

re.search(pattern, string)    # First match
re.match(pattern, string)     # Match at start only
re.findall(pattern, string)   # All matches as list
re.finditer(pattern, string)  # Iterator of match objects
re.sub(pattern, repl, string) # Replace
re.split(pattern, string)     # Split

# Compile for reuse
regex = re.compile(r'pattern', re.IGNORECASE)
regex.search(string)

# Named groups
match = re.search(r'(?P<year>\d{4})', '2024')
match.group('year')  # "2024"
```

### grep/ripgrep

```bash
grep -E 'pattern' file         # Extended regex
grep -P 'pattern' file         # Perl regex (GNU grep)
grep -o 'pattern' file         # Only matching part
grep -i 'pattern' file         # Case insensitive
grep -v 'pattern' file         # Invert match

rg 'pattern' file              # Rust regex (fast)
rg -i 'pattern'                # Case insensitive
rg -o 'pattern'                # Only matching part
rg --pcre2 'pattern'           # Perl-compatible regex
```

### sed

```bash
sed 's/pattern/replacement/'        # First match
sed 's/pattern/replacement/g'       # All matches
sed -E 's/pattern/replacement/'     # Extended regex
sed 's/\(group\)/\1/'               # Backreference (BRE)
sed -E 's/(group)/\1/'              # Backreference (ERE)
```

## Tips & Gotchas

1. **Escape special characters** in literals:
   `\. \* \+ \? \[ \] \( \) \{ \} \| \\ \^ \$`

2. **Use raw strings** in Python: `r'\d+'` not `'\\d+'`

3. **Anchors matter**: `\d+` matches digits anywhere; `^\d+$` matches only if
   entire string is digits

4. **Greedy by default**: `.*` eats as much as possible; use `.*?` for lazy

5. **Character class shortcuts**: `[0-9]` = `\d`, `[a-zA-Z0-9_]` = `\w`,
   `[ \t\n\r]` = `\s`

6. **Test incrementally**: Build complex patterns piece by piece

7. **Use non-capturing groups** `(?:...)` when you don't need the match

8. **Catastrophic backtracking**: Avoid nested quantifiers like `(a+)+` on long
   strings

## See Also

- [Shell](shell.md) — grep, sed, awk patterns that use regex
- [CLI Pipelines](cli-pipelines.md) — Text processing with pipes
- [Python](python.md) — `re` module usage
- [jq](jq.md) — JSON filtering with regex tests
