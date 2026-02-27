---
title: "Regex Lesson Plan"
description:
  Eight lessons from literal matching to lookahead and real-world extraction,
  with exercises in grep, Python, and JavaScript.
---

A progressive curriculum to master regular expressions through hands-on
practice.

## Lesson 1: Literals and Metacharacters

**Goal:** Distinguish literal characters from metacharacters and build simple
patterns.

### Concepts

A regex is a pattern that matches text. Most characters match themselves
(literals). A handful of metacharacters carry special meaning:

```text
.  ^  $  *  +  ?  {  }  [  ]  (  )  |  \
```

Everything else is literal. To match a metacharacter literally, escape it with
`\`.

### Exercises

1. **Match literal text**

   ```bash
   echo "The cat sat on the mat" | grep -o 'cat'
   echo "Price: $9.99" | grep -o '\$9\.99'
   ```

   The first matches the literal word. The second escapes `$` and `.` to avoid
   treating them as metacharacters.

2. **Use the dot metacharacter**

   ```bash
   echo -e "cat\ncar\ncab\ncap" | grep 'ca.'
   # Matches all four — dot matches any single character
   ```

3. **Anchor to position**

   ```bash
   echo -e "cat\nconcat\ncatalog" | grep '^cat'
   # Only "cat" and "catalog" — ^ anchors to line start

   echo -e "cat\nconcat\ncatalog" | grep 'cat$'
   # Only "cat" and "concat" — $ anchors to line end
   ```

4. **Escape metacharacters**

   ```bash
   echo "file.txt and file_txt" | grep -o 'file\.txt'
   # Only matches "file.txt", not "file_txt"
   ```

### Checkpoint

Write a pattern that matches "3.14" but not "3X14". Explain why `3.14` without
escaping would match both.

---

## Lesson 2: Character Classes

**Goal:** Match sets of characters using classes and shorthand notation.

### Concepts

Character classes match one character from a defined set.

| Syntax   | Meaning                         |
| -------- | ------------------------------- |
| `[abc]`  | a, b, or c                      |
| `[^abc]` | Any character except a, b, c    |
| `[a-z]`  | Lowercase letter range          |
| `[0-9]`  | Digit range                     |
| `\d`     | Digit (shorthand for `[0-9]`)   |
| `\w`     | Word character (`[a-zA-Z0-9_]`) |
| `\s`     | Whitespace (space, tab, etc.)   |

Uppercase versions (`\D`, `\W`, `\S`) negate the match.

### Exercises

1. **Match specific characters**

   ```bash
   echo -e "gray\ngrey\ngray" | grep 'gr[ae]y'
   # Matches both "gray" and "grey"
   ```

2. **Use ranges**

   ```bash
   echo -e "A1\nB2\nZ9\na1\n!!" | grep '^[A-Z][0-9]$'
   # Matches uppercase letter followed by digit
   ```

3. **Negate a class**

   ```bash
   echo -e "cat\nc4t\nc!t" | grep 'c[^a-z]t'
   # Matches "c4t" and "c!t" — not lowercase letter
   ```

4. **Shorthand classes**

   ```python
   import re

   text = "Order #1234 on 2024-01-15"
   digits = re.findall(r'\d+', text)
   print(digits)  # ['1234', '2024', '01', '15']

   words = re.findall(r'\w+', text)
   print(words)   # ['Order', '1234', 'on', '2024', '01', '15']
   ```

### Checkpoint

Write a pattern that matches a hex color code: `#` followed by exactly 6 hex
characters (0-9, a-f, A-F). Test against `#ff5733`, `#FFFFFF`, and `#xyz`.

---

## Lesson 3: Quantifiers

**Goal:** Control how many times a pattern repeats.

### Concepts

Quantifiers follow a character or group and specify repetition:

| Quantifier | Meaning           |
| ---------- | ----------------- |
| `*`        | 0 or more         |
| `+`        | 1 or more         |
| `?`        | 0 or 1 (optional) |
| `{3}`      | Exactly 3         |
| `{2,4}`    | Between 2 and 4   |
| `{3,}`     | 3 or more         |

Quantifiers are **greedy** by default — they match as much as possible. Add `?`
after any quantifier to make it **lazy** (match as little as possible).

### Exercises

1. **Match optional and required elements**

   ```bash
   echo -e "color\ncolour" | grep 'colou\?r'
   # Matches both — u is optional

   echo -e "ac\nabc\nabbc\nabbbc" | grep -E 'ab+c'
   # Matches "abc", "abbc", "abbbc" — b required at least once
   ```

2. **Exact and range counts**

   ```bash
   echo -e "12\n123\n1234\n12345" | grep -E '^\d{3,4}$'
   # Matches "123" and "1234" only
   ```

3. **Greedy vs lazy**

   ```python
   import re

   html = '<b>bold</b> and <i>italic</i>'

   greedy = re.findall(r'<.*>', html)
   print(greedy)   # ['<b>bold</b> and <i>italic</i>']

   lazy = re.findall(r'<.*?>', html)
   print(lazy)     # ['<b>', '</b>', '<i>', '</i>']
   ```

4. **Validate a phone number format**

   ```bash
   echo -e "555-1234\n55-1234\n5555-1234" | grep -E '^\d{3}-\d{4}$'
   # Only "555-1234" matches
   ```

### Checkpoint

Write a pattern that matches IP addresses in the format `N.N.N.N` where each N
is 1-3 digits. Test with `192.168.1.1`, `10.0.0.1`, and `999.999.999.999` (all
should match structurally; validation of range 0-255 comes later).

---

## Lesson 4: Groups and Alternation

**Goal:** Capture submatches and express alternatives.

### Concepts

Parentheses serve two purposes: grouping (apply quantifiers to sequences) and
capturing (extract submatches).

| Syntax       | Purpose                  |
| ------------ | ------------------------ |
| `(abc)`      | Capturing group          |
| `(?:abc)`    | Non-capturing group      |
| `(?P<n>abc)` | Named group (Python)     |
| `(?<n>abc)`  | Named group (JS, .NET)   |
| `\1`         | Backreference to group 1 |
| `cat\|dog`   | Alternation (cat or dog) |

### Exercises

1. **Capture groups**

   ```python
   import re

   date = "2024-03-15"
   m = re.match(r'(\d{4})-(\d{2})-(\d{2})', date)
   print(m.group(1))  # '2024'
   print(m.group(2))  # '03'
   print(m.group(3))  # '15'
   ```

2. **Named groups**

   ```python
   m = re.match(r'(?P<year>\d{4})-(?P<month>\d{2})-(?P<day>\d{2})', date)
   print(m.group('year'))   # '2024'
   print(m.group('month'))  # '03'
   ```

3. **Alternation**

   ```bash
   echo -e "cat\ndog\nbird\nfish" | grep -E '^(cat|dog)$'
   # Matches "cat" and "dog"
   ```

4. **Backreferences — find repeated words**

   ```bash
   echo "the the quick brown fox fox" | grep -oE '\b(\w+)\s+\1\b'
   # Matches "the the" and "fox fox"
   ```

5. **Non-capturing groups for efficiency**

   ```python
   import re

   # Capturing — stores unnecessary data
   re.findall(r'(https?)://(\S+)', 'Visit https://example.com')
   # [('https', 'example.com')]

   # Non-capturing on protocol, capture only URL
   re.findall(r'(?:https?)://(\S+)', 'Visit https://example.com')
   # ['example.com']
   ```

### Checkpoint

Write a regex that matches dates in both `YYYY-MM-DD` and `MM/DD/YYYY` formats
using alternation. Capture year, month, and day as named groups in each branch.

---

## Lesson 5: Anchors and Boundaries

**Goal:** Control where in the text a pattern must match.

### Concepts

Anchors match positions, not characters. They consume no input.

| Anchor | Position                                 |
| ------ | ---------------------------------------- |
| `^`    | Start of string (or line with `m` flag)  |
| `$`    | End of string (or line with `m` flag)    |
| `\b`   | Word boundary                            |
| `\B`   | Not a word boundary                      |
| `\A`   | Start of string (ignores multiline flag) |
| `\Z`   | End of string (ignores multiline flag)   |

A word boundary `\b` sits between a `\w` character and a `\W` character (or
string edge).

### Exercises

1. **Word boundaries prevent partial matches**

   ```bash
   echo "cat concatenate category" | grep -oE '\bcat\b'
   # Only matches "cat", not "cat" inside other words

   echo "cat concatenate category" | grep -oE '\bcat'
   # Matches "cat" at word start: "cat", "concatenate", "category"
   ```

2. **Validate entire strings**

   ```python
   import re

   # Without anchors — matches substrings
   bool(re.search(r'\d{3}', '12345'))  # True (finds "123")

   # With anchors — matches whole string only
   bool(re.search(r'^\d{3}$', '12345'))  # False
   bool(re.search(r'^\d{3}$', '123'))    # True
   ```

3. **Multiline mode**

   ```python
   import re

   log = """ERROR: disk full
   INFO: backup started
   ERROR: connection timeout"""

   # Without multiline — ^ matches only string start
   re.findall(r'^ERROR.*', log)
   # ['ERROR: disk full']

   # With multiline — ^ matches each line start
   re.findall(r'^ERROR.*', log, re.MULTILINE)
   # ['ERROR: disk full', 'ERROR: connection timeout']
   ```

4. **Non-word boundaries**

   ```bash
   echo -e "subclass\nsub class\nclass" | grep -E '\Bclass'
   # Matches "class" inside "subclass" — not at word boundary
   ```

### Checkpoint

Write a pattern that finds lines starting with `#` (comments) in a multiline
string. Then write one that finds `TODO` only as a standalone word, not inside
`MYTODO` or `TODOLIST`.

---

## Lesson 6: Lookahead and Lookbehind

**Goal:** Assert conditions without consuming characters.

### Concepts

Lookarounds check what comes before or after a position without including it in
the match.

| Syntax     | Name                | Asserts             |
| ---------- | ------------------- | ------------------- |
| `(?=abc)`  | Positive lookahead  | Followed by abc     |
| `(?!abc)`  | Negative lookahead  | Not followed by abc |
| `(?<=abc)` | Positive lookbehind | Preceded by abc     |
| `(?<!abc)` | Negative lookbehind | Not preceded by abc |

Lookarounds are zero-width — they assert a condition but don't advance the match
position.

### Exercises

1. **Positive lookahead — match word before punctuation**

   ```python
   import re

   text = "Hello, world! How are you?"
   re.findall(r'\w+(?=[!?])', text)
   # ['world', 'you'] — words followed by ! or ?
   ```

2. **Negative lookahead — exclude patterns**

   ```python
   text = "foo foobar foobaz football"
   re.findall(r'foo(?!bar)', text)
   # ['foo', 'foo', 'foo'] — "foo" not followed by "bar"
   ```

3. **Positive lookbehind — match after prefix**

   ```python
   text = "Price: $100 and €200"
   re.findall(r'(?<=\$)\d+', text)
   # ['100'] — digits preceded by $
   ```

4. **Password validation with multiple lookaheads**

   ```python
   import re

   def validate_password(pw):
       pattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%]).{8,}$'
       return bool(re.match(pattern, pw))

   validate_password("Abc1!xyz")    # False (7 chars)
   validate_password("Abcd1!xy")    # True
   validate_password("abcd1!xy")    # False (no uppercase)
   ```

5. **Format numbers with comma separators**

   ```python
   import re

   num = "1234567890"
   re.sub(r'(?<=\d)(?=(\d{3})+$)', ',', num)
   # '1,234,567,890'
   ```

### Checkpoint

Write a regex that extracts dollar amounts (e.g., `42.99` from `$42.99`) using
lookbehind to match the `$` without including it. Test against a string with
mixed currencies: `$42.99, €30.00, $7.50`.

---

## Lesson 7: Substitution and Practical Extraction

**Goal:** Transform text with regex substitution and extract structured data.

### Concepts

Substitution replaces matched text. Backreferences in the replacement string
refer to captured groups.

| Language   | Syntax                                         |
| ---------- | ---------------------------------------------- |
| Python     | `re.sub(pattern, replacement, string)`         |
| JavaScript | `string.replace(/pattern/g, replacement)`      |
| sed        | `sed 's/pattern/replacement/g'`                |
| grep       | Match only (use sed/awk/perl for substitution) |

### Exercises

1. **Reformat dates**

   ```python
   import re

   text = "Born 2024-03-15, died 2024-12-01"
   re.sub(r'(\d{4})-(\d{2})-(\d{2})', r'\2/\3/\1', text)
   # 'Born 03/15/2024, died 12/01/2024'
   ```

2. **Clean whitespace**

   ```bash
   echo "too   many    spaces" | sed -E 's/ +/ /g'
   # "too many spaces"
   ```

3. **Extract log fields**

   ```python
   import re

   log = '2024-03-15 14:30:22 ERROR [auth] Login failed for user=admin'
   pattern = r'(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}) (\w+) \[(\w+)\] (.+)'
   m = re.match(pattern, log)
   date, time, level, module, message = m.groups()
   # date='2024-03-15', level='ERROR', module='auth'
   ```

4. **Transform camelCase to snake_case**

   ```python
   import re

   def to_snake(name):
       s = re.sub(r'([A-Z])', r'_\1', name)
       return s.lower().lstrip('_')

   to_snake('getUserName')     # 'get_user_name'
   to_snake('HTMLParser')      # 'h_t_m_l_parser' — needs refinement
   ```

   ```python
   # Better version: handle consecutive uppercase
   def to_snake(name):
       s = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1_\2', name)
       s = re.sub(r'([a-z])([A-Z])', r'\1_\2', s)
       return s.lower()

   to_snake('HTMLParser')      # 'html_parser'
   to_snake('getUserName')     # 'get_user_name'
   ```

5. **Extract URLs from markdown**

   ```bash
   grep -oE '\[([^]]+)\]\(([^)]+)\)' README.md
   # Extracts markdown links: [text](url)
   ```

### Checkpoint

Write a substitution that converts US phone numbers from `(555) 123-4567` to
`555.123.4567`. Test with `sed` and `re.sub`.

---

## Lesson 8: Performance, Pitfalls, and Tool Differences

**Goal:** Avoid catastrophic backtracking, understand engine differences, and
choose the right tool.

### Concepts

Regex engines use backtracking to try all possible matches. Certain patterns
cause exponential blowup.

**Catastrophic backtracking** happens when a pattern has nested quantifiers that
create overlapping match paths. The engine explores every combination before
admitting failure.

### Exercises

1. **Observe backtracking**

   ```python
   import re
   import time

   # Safe pattern
   start = time.time()
   re.match(r'\d+', 'a' * 30)
   print(f"Safe: {time.time() - start:.4f}s")

   # Dangerous pattern — nested quantifiers
   start = time.time()
   re.match(r'(a+)+b', 'a' * 25)
   print(f"Dangerous: {time.time() - start:.4f}s")
   # Much slower — exponential backtracking
   ```

2. **Fix catastrophic patterns**

   ```python
   # Bad: overlapping quantifiers
   bad = r'(a+)+b'

   # Good: atomic grouping (Python 3.11+ or use possessive quantifiers)
   good = r'a+b'
   # Remove the unnecessary group — the nested + adds nothing
   ```

3. **Understand engine differences**

   ```bash
   # BRE (Basic Regular Expressions) — grep default
   echo "abc" | grep '\(abc\)'       # Escaped parens for groups

   # ERE (Extended) — grep -E, egrep
   echo "abc" | grep -E '(abc)'      # Unescaped parens

   # PCRE (Perl-Compatible) — grep -P, Python, JS
   echo "abc" | grep -P '(?:abc)'    # Non-capturing groups
   ```

   | Feature        | BRE                | ERE    | PCRE   |
   | -------------- | ------------------ | ------ | ------ |
   | `+`, `?`, `{}` | `\+`, `\?`, `\{\}` | Native | Native |
   | `()`           | `\(\)`             | Native | Native |
   | Lookaround     | No                 | No     | Yes    |
   | Named groups   | No                 | No     | Yes    |
   | Non-capturing  | No                 | No     | Yes    |
   | Backreferences | Yes                | Varies | Yes    |

4. **Choose the right tool**

   ```bash
   # grep — find lines matching a pattern
   grep -E 'ERROR|WARN' app.log

   # sed — find and replace in streams
   sed -E 's/v([0-9]+)/version \1/g' changelog.md

   # awk — field-based processing with regex
   awk '/ERROR/ {print $1, $2}' app.log

   # ripgrep — fast recursive search
   rg 'TODO|FIXME' --type py
   ```

5. **Debug regex interactively**

   ```python
   import re

   # re.VERBOSE lets you add comments and whitespace
   pattern = re.compile(r'''
       ^                  # Start of string
       (?P<proto>https?)  # Protocol
       ://                # Separator
       (?P<host>[^/]+)    # Hostname
       (?P<path>/\S*)?    # Optional path
       $                  # End of string
   ''', re.VERBOSE)

   m = pattern.match('https://example.com/api/v1')
   print(m.group('host'))  # 'example.com'
   print(m.group('path'))  # '/api/v1'
   ```

### Checkpoint

Explain why `(a|b)*c` is safe but `(a*)*c` is dangerous on input without `c`.
Write a verbose regex with comments that parses an email address into local part
and domain.

---

## Practice Projects

### Project 1: Log Analyzer

Write a script that parses nginx access logs:

```text
192.168.1.1 - - [15/Mar/2024:14:30:22 +0000] "GET /api/users HTTP/1.1" 200 1234
```

Extract: IP, timestamp, method, path, status code, response size. Print a
summary of status code counts.

### Project 2: Markdown Link Checker

Write a script that extracts all markdown links `[text](url)` from a file.
Separate internal links (relative paths) from external links (http/https).
Report broken internal links.

### Project 3: Code Pattern Detector

Write a regex-based linter that finds common issues in Python files:

- `print()` statements (should use logging)
- Bare `except:` clauses (should catch specific exceptions)
- `TODO` and `FIXME` comments (should track in issue tracker)
- Hardcoded IP addresses or port numbers

---

## Pattern Reference

| Stage    | Must Know                                               |
| -------- | ------------------------------------------------------- |
| Beginner | `.` `*` `+` `?` `^` `$` `[]` `\d` `\w` `\s`             |
| Daily    | `()` `\|` `{n,m}` `\b` `\1` named groups, flags         |
| Power    | `(?=)` `(?!)` `(?<=)` `(?<!)` `(?:)` lazy quantifiers   |
| Advanced | `re.VERBOSE` backtracking awareness, engine differences |

## See Also

- [Regex](../how/regex.md) — Quick reference: patterns, character classes,
  language-specific syntax
- [Shell](../how/shell.md) — grep, sed, awk scripting that uses regex
- [CLI Pipelines](../how/cli-pipelines.md) — Text processing pipelines with
  regex tools
- [Python Lesson Plan](python-lesson-plan.md) — Python fundamentals including
  the re module
