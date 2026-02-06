# jq Cheat Sheet

`jq` is a lightweight command-line JSON processor.

## Basic Usage

```bash
# Pretty print
cat file.json | jq '.'
jq '.' file.json

# Compact output (no pretty print)
jq -c '.' file.json

# Raw output (no quotes on strings)
jq -r '.name' file.json

# Read from string
echo '{"name":"alice"}' | jq '.name'
```

## Flags

| Flag                 | Description                             |
| -------------------- | --------------------------------------- |
| `-r`                 | Raw output (no quotes)                  |
| `-c`                 | Compact output (one line)               |
| `-s`                 | Slurp: read all inputs into array       |
| `-n`                 | Null input (don't read stdin)           |
| `-e`                 | Exit with error if output is false/null |
| `-S`                 | Sort object keys                        |
| `--arg name val`     | Pass string variable                    |
| `--argjson name val` | Pass JSON variable                      |

## Navigation

### Object Access

```bash
# Sample: {"name": "alice", "age": 30, "address": {"city": "NYC"}}

jq '.name'              # "alice"
jq '.address.city'      # "NYC"
jq '.missing'           # null
jq '.missing // "default"'  # "default"

# Optional access (no error if null)
jq '.foo?.bar?'         # null (instead of error)

# Bracket notation
jq '.["name"]'          # "alice"
jq '.["key-with-dash"]' # Works with special chars
```

### Array Access

```bash
# Sample: [10, 20, 30, 40, 50]

jq '.[0]'               # 10
jq '.[-1]'              # 50 (last element)
jq '.[1:3]'             # [20, 30]
jq '.[:2]'              # [10, 20]
jq '.[-2:]'             # [40, 50]
jq '.[2:]'              # [30, 40, 50]
```

### Iteration

```bash
# Sample: [{"name": "a"}, {"name": "b"}]

jq '.[]'                # Iterate: {"name":"a"} then {"name":"b"}
jq '.[].name'           # Iterate: "a" then "b"
jq '.[] | .name'        # Same as above

# Sample: {"a": 1, "b": 2}
jq '.[]'                # Iterate values: 1 then 2
jq 'keys'               # ["a", "b"]
jq 'keys[]'             # "a" then "b"
```

## Operators

### Pipe

```bash
jq '.users | .[] | .name'
jq '.users[].name'      # Equivalent shorthand
```

### Comma (Multiple Outputs)

```bash
jq '.name, .age'        # Output both
jq '{name, age}'        # Build object with both
```

### Parentheses (Grouping)

```bash
jq '(.a + .b) * 2'
```

## Constructing Values

### Objects

```bash
# Build new object
jq '{name: .user, count: .total}'
jq '{name, age}'        # Shorthand: {name: .name, age: .age}
jq '{(.key): .value}'   # Dynamic key

# Add/update fields
jq '. + {newfield: "value"}'
jq '.name = "bob"'
jq '.users[0].name = "bob"'

# Remove fields
jq 'del(.unwanted)'
jq 'del(.users[0])'
```

### Arrays

```bash
# Build array
jq '[.items[].name]'    # Collect into array
jq '[., .]'             # Duplicate input

# Add to array
jq '. + ["new"]'
jq '. += ["new"]'

# Concatenate arrays
jq '.arr1 + .arr2'
```

## Filtering

### Select

```bash
# Filter array elements
jq '.[] | select(.age > 21)'
jq '.[] | select(.active == true)'
jq '.[] | select(.name | contains("ali"))'
jq '.[] | select(.tags | index("admin"))'

# Multiple conditions
jq '.[] | select(.age > 21 and .active)'
jq '.[] | select(.role == "admin" or .role == "mod")'

# Negation
jq '.[] | select(.deleted | not)'
```

### Map

```bash
# Transform each element
jq 'map(.name)'                    # [{"name":"a"},...] → ["a",...]
jq 'map(. * 2)'                    # [1,2,3] → [2,4,6]
jq 'map(select(.active))'          # Filter with map
jq 'map({name, email})'            # Project fields

# map_values for objects
jq 'map_values(. + 1)'             # {"a":1,"b":2} → {"a":2,"b":3}
```

### Group & Sort

```bash
jq 'group_by(.category)'           # Group into sub-arrays
jq 'sort_by(.date)'                # Sort array of objects
jq 'sort_by(.date) | reverse'      # Sort descending
jq 'sort'                          # Sort array of primitives
jq 'unique'                        # Remove duplicates
jq 'unique_by(.id)'                # Unique by field
```

## String Operations

```bash
jq '.name | length'                # String length
jq '.name | ascii_downcase'        # Lowercase
jq '.name | ascii_upcase'          # Uppercase
jq '.name | ltrimstr("Mr. ")'      # Remove prefix
jq '.name | rtrimstr(" Jr.")'      # Remove suffix
jq '.name | split(" ")'            # Split to array
jq '.parts | join("-")'            # Join array
jq '"\(.first) \(.last)"'          # String interpolation
jq '.name | startswith("A")'       # Boolean check
jq '.name | endswith("son")'       # Boolean check
jq '.name | contains("ali")'       # Boolean check
jq '.name | test("^[A-Z]")'        # Regex match
jq '.name | capture("(?<first>\\w+)")'  # Regex capture
jq '.name | sub("old"; "new")'     # Replace first
jq '.name | gsub("old"; "new")'    # Replace all
```

## Numeric Operations

```bash
jq '.price * 1.1'                  # Arithmetic
jq '.values | add'                 # Sum array
jq '.values | add / length'        # Average
jq '.values | min'                 # Minimum
jq '.values | max'                 # Maximum
jq '.value | floor'                # Round down
jq '.value | ceil'                 # Round up
jq '.value | round'                # Round nearest
jq 'range(5)'                      # 0,1,2,3,4
jq '[range(5)]'                    # [0,1,2,3,4]
```

## Array Operations

```bash
jq 'length'                        # Array/string/object length
jq 'first'                         # First element (.[0])
jq 'last'                          # Last element (.[-1])
jq 'nth(2)'                        # Third element (.[2])
jq 'flatten'                       # Flatten nested arrays
jq 'flatten(1)'                    # Flatten one level
jq 'reverse'                       # Reverse array
jq 'indices("x")'                  # Find all indices of value
jq 'inside([1,2,3])'               # Check if subset
jq 'contains([1,2])'               # Check if contains
jq '. - ["a","b"]'                 # Remove elements
jq 'limit(3; .[])'                 # First 3 elements
jq '[limit(3; .[])]'               # As array
jq 'first(.[]; . > 5)'             # First matching
```

## Conditionals

```bash
# if-then-else
jq 'if .age >= 18 then "adult" else "minor" end'

# Alternative operator (default value)
jq '.name // "unknown"'
jq '.items[0] // empty'            # No output if null

# Error handling
jq 'try .foo.bar catch "error"'
jq '.items[]? | .name'             # Suppress errors
```

## Reduce & Recursion

```bash
# Reduce (fold)
jq 'reduce .[] as $x (0; . + $x)'  # Sum

# Recursive descent
jq '.. | numbers'                  # All numbers at any depth
jq '.. | strings'                  # All strings at any depth
jq '.. | .name? // empty'          # All "name" values

# Walk (transform recursively)
jq 'walk(if type == "string" then ascii_upcase else . end)'
```

## Variables

```bash
# Define variable
jq '.user as $u | .posts[] | {title, author: $u}'

# From command line
jq --arg name "alice" '.users[] | select(.name == $name)'
jq --argjson id 123 '.users[] | select(.id == $id)'

# Multiple variables
jq --arg a "x" --arg b "y" '{first: $a, second: $b}'
```

## Multiple Inputs

```bash
# Slurp into array
jq -s '.' file1.json file2.json   # Combine into array
jq -s 'add' file1.json file2.json # Merge objects

# Process each file
jq '.name' file1.json file2.json  # Output from each

# Input from array
jq '.[]' <<< '[1,2,3]'            # Stream items
```

## Practical Examples

### Extract nested values

```bash
jq '.data.users[].profile.email'
```

### Filter and project

```bash
jq '[.users[] | select(.active) | {name, email}]'
```

### Count items

```bash
jq '[.items[] | select(.status == "done")] | length'
```

### Group and count

```bash
jq 'group_by(.category) | map({category: .[0].category, count: length})'
```

### Flatten nested structure

```bash
jq '[.departments[].employees[].name]'
```

### Merge objects

```bash
jq -s '.[0] * .[1]' defaults.json config.json
```

### Convert CSV-like to JSON

```bash
jq -R -s 'split("\n") | map(split(",")) | map({name: .[0], value: .[1]})'
```

### Update deeply nested value

```bash
jq '.config.database.host = "newhost"'
```

### Add field to all array elements

```bash
jq '.users[] |= . + {processed: true}'
```

### Remove null values

```bash
jq 'del(..|nulls)'
jq 'with_entries(select(.value != null))'
```

### Convert object to array of key-value pairs

```bash
jq 'to_entries'                   # [{key, value}, ...]
jq 'to_entries | map("\(.key)=\(.value)") | .[]'
```

### Construct object from arrays

```bash
jq -n '{names: $ARGS.positional}' --args alice bob charlie
```

### Pretty print with sorted keys

```bash
jq -S '.'
```

### Get unique values from nested arrays

```bash
jq '[.items[].tags[]] | unique'
```

### Sum values by group

```bash
jq 'group_by(.category) | map({category: .[0].category, total: map(.amount) | add})'
```

## See Also

- [Shell](shell.md) — Scripting patterns for pipelines and data processing
