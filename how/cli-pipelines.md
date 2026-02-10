# CLI Pipelines: Keeping Data in the Stream

How to work with command output without reaching for the mouse. The core idea:
output is input to the next command, not text to be read and retyped.

## Pipes

The fundamental building block. `|` sends stdout of one command to stdin of the
next.

```bash
# Count Go files
find . -name "*.go" | wc -l

# Find the 5 largest files
du -sh * | sort -rh | head -5

# Unique sorted IPs from a log
awk '{print $1}' access.log | sort -u

# Chain as many as you need
cat /etc/passwd | cut -d: -f1 | sort | head -20
```

### Pipe to clipboard

Skip the select-and-copy step entirely.

```bash
# macOS
echo "something useful" | pbcopy
pbpaste                              # retrieve it

# Linux (X11)
echo "something useful" | xclip -selection clipboard
xclip -selection clipboard -o

# Linux (Wayland)
echo "something useful" | wl-copy
wl-paste
```

## Command Substitution

Capture output inline with `$()`. The shell runs the inner command first and
substitutes the result.

```bash
# Open all files containing TODO
nvim $(rg -l "TODO")

# cd into a found directory
cd $(fd -t d "components" | head -1)

# Use a timestamp in a filename
tar czf "backup-$(date +%Y%m%d).tar.gz" ./src

# Assign to a variable
current_branch=$(git branch --show-current)
echo "On branch: $current_branch"
```

### Nesting

```bash
# Count lines in the most recently modified file
wc -l $(ls -t *.log | head -1)
```

## History Expansion

Reuse pieces of previous commands without retyping.

| Expansion | Meaning                             |
| --------- | ----------------------------------- |
| `!!`      | Last command, entire line           |
| `!$`      | Last argument of previous command   |
| `!^`      | First argument of previous command  |
| `!*`      | All arguments of previous command   |
| `!:2`     | Second argument of previous command |
| `$_`      | Last argument (works in scripts)    |
| `!-2`     | Command two entries back            |

```bash
# Rerun with sudo
apt install nginx
sudo !!                              # becomes: sudo apt install nginx

# Reuse the path you just typed
ls /var/log/nginx/error.log
less !$                              # becomes: less /var/log/nginx/error.log
vim !$                               # open the same file

# Reuse all arguments
cp file1.txt file2.txt /backup/
ls !*                                # becomes: ls file1.txt file2.txt /backup/
```

### Quick substitution

```bash
# Fix a typo in the last command
git stats
^stats^status^                       # reruns as: git status
```

## xargs

Convert stdin lines into arguments for another command.

```bash
# Delete all .tmp files
fd '\.tmp$' | xargs rm

# Open matching files in your editor
rg -l "deprecated" | xargs nvim

# Run in parallel (-P)
fd '\.png$' | xargs -P 4 optipng

# Handle filenames with spaces (-0 with -print0 or fd -0)
fd -0 '\.log$' | xargs -0 rm

# Limit arguments per invocation (-n)
echo "a b c d" | xargs -n 2 echo    # "a b" then "c d"

# Substitute placement (-I)
cat urls.txt | xargs -I {} curl -O {}
```

## Process Substitution

`<()` creates a temporary file-like object from command output. Use when a
command expects a filename, not stdin.

```bash
# Diff two commands without temp files
diff <(curl -s https://api.example.com/v1) <(curl -s https://api.example.com/v2)

# Diff sorted outputs
diff <(sort file1.txt) <(sort file2.txt)

# Compare directory listings
diff <(ls dir1/) <(ls dir2/)

# Source output of a command
source <(kubectl completion bash)
```

## Fuzzy Selection with fzf

[fzf](https://github.com/junegunn/fzf) turns any list into an interactive
picker. No mouse needed — type to filter, arrow keys to select.

```bash
# Pick a file to edit
nvim $(fzf)

# Pick a branch to checkout
git checkout $(git branch --all | fzf)

# Pick a process to kill
kill $(ps aux | fzf | awk '{print $2}')

# Pick a docker container to exec into
docker exec -it $(docker ps --format '{{.Names}}' | fzf) bash

# Pick from command history
$(history | fzf | sed 's/^ *[0-9]* *//')
```

### fzf with preview

```bash
# File picker with preview
nvim $(fzf --preview 'bat --color=always {}')

# Git log picker with diff preview
git show $(git log --oneline | fzf --preview 'git show {1}' | awk '{print $1}')
```

### fzf key bindings (defaults after install)

| Binding  | Action                               |
| -------- | ------------------------------------ |
| `Ctrl+T` | Paste selected file path into prompt |
| `Ctrl+R` | Search command history               |
| `Alt+C`  | cd into selected directory           |

## Here Documents and Here Strings

Feed multi-line or single-line input without temp files.

```bash
# Here document (multi-line input)
cat <<EOF
line one
line two
EOF

# Here string (single-line input)
grep "error" <<< "$log_output"

# Useful for commands that read stdin
bc <<< "2 ^ 10"                      # 1024
```

## Tee

Send output to both a file and the next command in the pipeline.

```bash
# Save and display
curl -s https://api.example.com | tee response.json | jq '.status'

# Save intermediate pipeline results
ps aux | tee processes.txt | grep nginx

# Append instead of overwrite
echo "log entry" | tee -a debug.log
```

## Variable Capture Patterns

```bash
# Capture exit code
some_command
status=$?

# Capture output and check status
if output=$(git pull 2>&1); then
    echo "Success: $output"
else
    echo "Failed: $output"
fi

# Read line by line from a command
while IFS= read -r line; do
    echo "Processing: $line"
done < <(find . -name "*.md")
```

## Combining Patterns

Real workflows chain these together.

```bash
# Find the function that changed most across git history
git log --oneline --all --follow -p -- '*.py' \
  | grep "^+.*def " \
  | sed 's/^+//' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10

# Deploy: build, tag, push — stopping on any failure
version=$(git describe --tags) \
  && docker build -t "app:$version" . \
  && docker push "app:$version" \
  && echo "Deployed $version"

# Interactive git stash apply
git stash apply $(git stash list | fzf | cut -d: -f1)

# Find large files not tracked by git
comm -23 \
  <(find . -type f -size +1M | sort) \
  <(git ls-files | sort) \
  | head -20
```

## Quick Reference

| Goal                           | Pattern                    |
| ------------------------------ | -------------------------- |
| Use output as arguments        | `cmd $(other_cmd)`         |
| Use output as stdin            | `cmd1 \| cmd2`             |
| Use output as a file           | `cmd <(other_cmd)`         |
| Save output and pass it along  | `cmd1 \| tee file \| cmd2` |
| Send output to clipboard       | `cmd \| pbcopy`            |
| Pick from output interactively | `cmd \| fzf`               |
| Reuse last argument            | `!$` or `$_`               |
| Rerun last command             | `!!`                       |
| Convert stdin to arguments     | `cmd1 \| xargs cmd2`       |
| Fix typo in last command       | `^old^new^`                |

## See Also

- [Shell Scripting](shell.md) — Variables, functions, control flow
- [Unix CLI](unix.md) — Core commands for file ops and text processing
- [jq](jq.md) — JSON processing in pipelines
