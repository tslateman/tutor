# Unix CLI Cheat Sheet

Portable commands for Linux, macOS, and other Unix-like systems.

## File Navigation

| Command     | Description                   |
| ----------- | ----------------------------- |
| `pwd`       | Print working directory       |
| `cd -`      | Go to previous directory      |
| `cd ~`      | Go to home directory          |
| `ls -la`    | List all files with details   |
| `ls -lah`   | Human-readable sizes          |
| `ls -lt`    | Sort by modification time     |
| `tree -L 2` | Directory tree, 2 levels deep |

## File Operations

| Command             | Description                     |
| ------------------- | ------------------------------- |
| `cp -r src dest`    | Copy directory recursively      |
| `mv old new`        | Move/rename                     |
| `rm -rf dir`        | Remove directory recursively    |
| `mkdir -p a/b/c`    | Create nested directories       |
| `touch file`        | Create file or update timestamp |
| `ln -s target link` | Create symbolic link            |
| `stat file`         | File details                    |
| `file filename`     | Detect file type                |

## File Viewing

| Command            | Description                |
| ------------------ | -------------------------- |
| `cat file`         | Print entire file          |
| `less file`        | Paginated view (q to quit) |
| `head -n 20 file`  | First 20 lines             |
| `tail -n 20 file`  | Last 20 lines              |
| `tail -f file`     | Follow file (live updates) |
| `wc -l file`       | Line count                 |
| `diff file1 file2` | Compare files              |
| `colordiff`        | Colored diff               |

## Searching

| Command                    | Description                |
| -------------------------- | -------------------------- |
| `find . -name "*.js"`      | Find by name               |
| `find . -type f -mtime -1` | Files modified in last day |
| `find . -size +100M`       | Files larger than 100MB    |
| `grep -r "pattern" .`      | Recursive search           |
| `grep -rn "pattern" .`     | With line numbers          |
| `grep -rl "pattern" .`     | List matching files only   |
| `grep -i "pattern"`        | Case insensitive           |
| `grep -v "pattern"`        | Invert match               |
| `rg "pattern"`             | Ripgrep (faster)           |
| `rg -t js "pattern"`       | Ripgrep, JS files only     |
| `fd "pattern"`             | Faster find alternative    |

## Text Processing

| Command                | Description                |
| ---------------------- | -------------------------- |
| `sort file`            | Sort lines                 |
| `sort -u file`         | Sort unique                |
| `sort -n file`         | Numeric sort               |
| `uniq`                 | Remove adjacent duplicates |
| `uniq -c`              | Count occurrences          |
| `cut -d',' -f1,3`      | Extract columns 1 and 3    |
| `awk '{print $1}'`     | Print first column         |
| `awk -F: '{print $1}'` | Custom delimiter           |
| `sed 's/old/new/g'`    | Replace all occurrences    |
| `tr 'a-z' 'A-Z'`       | Translate characters       |
| `xargs`                | Build commands from stdin  |

### sed In-Place Edit

```bash
# Linux
sed -i 's/old/new/g' file

# macOS (requires empty string for backup)
sed -i '' 's/old/new/g' file
```

## Pipes & Redirection

| Command                    | Description                 |
| -------------------------- | --------------------------- |
| `cmd > file`               | Redirect stdout to file     |
| `cmd >> file`              | Append stdout to file       |
| `cmd 2> file`              | Redirect stderr             |
| `cmd &> file`              | Redirect both               |
| `cmd1 \| cmd2`             | Pipe stdout to next command |
| `cmd1 \| tee file \| cmd2` | Pipe and save copy          |
| `cmd < file`               | Use file as stdin           |
| `cmd <<< "string"`         | Here string                 |

## Process Management

| Command               | Description                |
| --------------------- | -------------------------- |
| `ps aux`              | All processes              |
| `ps aux \| grep name` | Find process               |
| `pgrep -f pattern`    | Get PIDs by pattern        |
| `top`                 | Interactive process viewer |
| `htop`                | Better process viewer      |
| `kill PID`            | Terminate process          |
| `kill -9 PID`         | Force kill                 |
| `pkill -f pattern`    | Kill by pattern            |
| `killall name`        | Kill by name               |
| `jobs`                | List background jobs       |
| `bg`                  | Resume job in background   |
| `fg`                  | Bring job to foreground    |
| `nohup cmd &`         | Run immune to hangups      |
| `cmd &`               | Run in background          |
| `Ctrl+Z`              | Suspend current process    |
| `Ctrl+C`              | Interrupt process          |

## Disk & Space

| Command               | Description            |
| --------------------- | ---------------------- |
| `df -h`               | Disk free space        |
| `du -sh *`            | Directory sizes        |
| `du -sh * \| sort -h` | Sorted by size         |
| `ncdu`                | Interactive disk usage |

## Network

| Command                       | Description             |
| ----------------------------- | ----------------------- |
| `curl -I url`                 | Headers only            |
| `curl -o file url`            | Download to file        |
| `curl -X POST -d "data" url`  | POST request            |
| `curl -H "Header: value" url` | Custom header           |
| `wget url`                    | Download file           |
| `ping host`                   | Test connectivity       |
| `traceroute host`             | Trace route             |
| `netstat -an`                 | Network connections     |
| `lsof -i :8080`               | What's on port 8080     |
| `ss -tuln`                    | Listening ports (Linux) |
| `dig domain`                  | DNS lookup              |
| `nslookup domain`             | DNS lookup              |
| `host domain`                 | DNS lookup              |

## Permissions

| Command                 | Description            |
| ----------------------- | ---------------------- |
| `chmod 755 file`        | rwxr-xr-x              |
| `chmod +x file`         | Add execute permission |
| `chmod -R 644 dir`      | Recursive              |
| `chown user:group file` | Change owner           |
| `chown -R user dir`     | Recursive              |

### Permission Numbers

| Number | Permission                 |
| ------ | -------------------------- |
| `7`    | rwx (read, write, execute) |
| `6`    | rw- (read, write)          |
| `5`    | r-x (read, execute)        |
| `4`    | r-- (read only)            |
| `0`    | --- (none)                 |

Common: `755` (dirs), `644` (files), `600` (private), `777` (all access)

## Archive & Compression

| Command                        | Description              |
| ------------------------------ | ------------------------ |
| `tar -czvf archive.tar.gz dir` | Create gzipped tarball   |
| `tar -xzvf archive.tar.gz`     | Extract gzipped tarball  |
| `tar -tf archive.tar`          | List contents            |
| `zip -r archive.zip dir`       | Create zip               |
| `unzip archive.zip`            | Extract zip              |
| `gzip file`                    | Compress (replaces file) |
| `gunzip file.gz`               | Decompress               |

## Environment & Shell

| Command             | Description                   |
| ------------------- | ----------------------------- |
| `env`               | Show environment variables    |
| `echo $VAR`         | Print variable                |
| `export VAR=value`  | Set variable                  |
| `which cmd`         | Path to command               |
| `type cmd`          | Command type/location         |
| `alias ll='ls -la'` | Create alias                  |
| `source ~/.bashrc`  | Reload config                 |
| `history`           | Command history               |
| `!!`                | Repeat last command           |
| `!$`                | Last argument of previous cmd |
| `Ctrl+R`            | Reverse search history        |

## SSH & Remote

| Command                         | Description         |
| ------------------------------- | ------------------- |
| `ssh user@host`                 | Connect             |
| `ssh -i key.pem user@host`      | With key file       |
| `ssh -L 8080:localhost:80 host` | Local port forward  |
| `ssh -R 8080:localhost:80 host` | Remote port forward |
| `scp file user@host:path`       | Copy to remote      |
| `scp user@host:path file`       | Copy from remote    |
| `rsync -avz src dest`           | Sync directories    |
| `rsync -avz --delete src dest`  | Sync with delete    |

## Useful Patterns

```bash
# Find and delete
find . -name "*.tmp" -delete

# Find and execute
find . -name "*.js" -exec wc -l {} +

# Count files by extension
find . -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn

# Watch command output (Linux)
watch -n 2 'command'

# Parallel execution
cat urls.txt | xargs -P 4 -I {} curl {}

# JSON pretty print
cat file.json | python -m json.tool
cat file.json | jq '.'

# Get external IP
curl -s ifconfig.me

# Quick HTTP server
python -m http.server 8000

# Base64 encode/decode
echo "text" | base64
echo "dGV4dAo=" | base64 -d

# Generate random string
openssl rand -hex 16

# Monitor file changes
tail -f log.txt | grep --line-buffered "error"

# Process substitution
diff <(sort file1) <(sort file2)

# Loop over files
for f in *.txt; do echo "$f"; done

# Loop over lines
while read -r line; do echo "$line"; done < file.txt
```
