# Unix Filesystem Cheat Sheet

Filesystem fundamentals, permissions, atomic operations, locking, and change
detection for Unix systems.

## Filesystem Hierarchy Standard (FHS)

Standard directory layout for Unix-like systems.

### Essential Directories

| Directory    | Purpose                         | Examples                        |
| ------------ | ------------------------------- | ------------------------------- |
| `/`          | Root filesystem                 | Must boot and recover from here |
| `/bin`       | Essential user binaries         | `ls`, `cp`, `cat`               |
| `/sbin`      | Essential system binaries       | `init`, `mount`, `fsck`         |
| `/etc`       | Host-specific configuration     | `passwd`, `fstab`, `hosts`      |
| `/var`       | Variable data (survives reboot) | `/var/log`, `/var/tmp`          |
| `/tmp`       | Temporary (cleared on reboot)   | Session data                    |
| `/home`      | User home directories           | `/home/alice`                   |
| `/root`      | Root user's home                |                                 |
| `/usr`       | Secondary hierarchy (shareable) | Distro-installed software       |
| `/usr/local` | Locally installed software      | Admin-installed programs        |
| `/opt`       | Add-on application packages     | Third-party software            |
| `/srv`       | Data for services               | Web server files                |
| `/run`       | Runtime variable data           | PID files, sockets              |

### Virtual Filesystems

| Mount   | Type     | Purpose                          |
| ------- | -------- | -------------------------------- |
| `/dev`  | devtmpfs | Device nodes (udev managed)      |
| `/proc` | procfs   | Process and kernel info          |
| `/sys`  | sysfs    | Device and driver info           |
| `/tmp`  | tmpfs    | RAM-backed temporary storage     |
| `/run`  | tmpfs    | Runtime data (cleared on reboot) |

### /proc — Process Information

```bash
/proc/PID/cmdline   # Command line arguments
/proc/PID/cwd       # Symlink to current working directory
/proc/PID/exe       # Symlink to executable
/proc/PID/fd/       # Open file descriptors
/proc/PID/maps      # Memory mappings
/proc/PID/status    # Human-readable status
/proc/PID/environ   # Environment variables

/proc/cpuinfo       # CPU information
/proc/meminfo       # Memory statistics
/proc/mounts        # Mounted filesystems
```

### /sys — Kernel Device Model

```bash
/sys/block/         # Block devices
/sys/class/         # Device classes (net, tty, etc.)
/sys/devices/       # Device hierarchy
/sys/fs/            # Filesystem information
```

### /dev — Device Files

| Device         | Purpose                      |
| -------------- | ---------------------------- |
| `/dev/null`    | Discards writes, reads EOF   |
| `/dev/zero`    | Reads return zeros           |
| `/dev/random`  | Blocking random generator    |
| `/dev/urandom` | Non-blocking random          |
| `/dev/stdin`   | Symlink to `/proc/self/fd/0` |
| `/dev/stdout`  | Symlink to `/proc/self/fd/1` |
| `/dev/stderr`  | Symlink to `/proc/self/fd/2` |
| `/dev/tty`     | Controlling terminal         |

## Inodes and Links

### Inode Contents

An inode stores file metadata—everything except the filename:

| Field        | Description                      | Accessed via      |
| ------------ | -------------------------------- | ----------------- |
| Device ID    | Filesystem hosting the inode     | `stat.st_dev`     |
| Inode number | Unique ID within filesystem      | `stat.st_ino`     |
| File type    | Regular, directory, symlink, etc | `stat.st_mode`    |
| Permissions  | rwx bits for user/group/other    | `stat.st_mode`    |
| Link count   | Number of hard links             | `stat.st_nlink`   |
| Owner/Group  | UID and GID                      | `stat.st_uid/gid` |
| File size    | Bytes (regular files/symlinks)   | `stat.st_size`    |
| Timestamps   | atime, mtime, ctime              | `stat.st_*time`   |

### Hard Links vs Symbolic Links

| Aspect            | Hard Link                     | Symbolic Link      |
| ----------------- | ----------------------------- | ------------------ |
| Points to         | Same inode                    | Pathname string    |
| Cross filesystem  | No                            | Yes                |
| Link to directory | No (prevents loops)           | Yes                |
| Target deleted    | Data remains (link count > 0) | Dangling link      |
| Storage overhead  | None                          | Stores target path |

```bash
# Hard link: both names share same inode
ln file hardlink
stat file hardlink    # Same inode number

# Symbolic link: stores path to target
ln -s file symlink
readlink symlink      # Returns "file"

# Find all hard links to a file
find / -inum $(stat -c %i file) 2>/dev/null

# Find broken symlinks
find /path -xtype l

# Resolve symlink chain
readlink -f symlink   # Final target
namei -l symlink      # Full chain with permissions
```

### File Types

| Type      | Mode | Description        |
| --------- | ---- | ------------------ |
| Regular   | `-`  | Ordinary file      |
| Directory | `d`  | Contains entries   |
| Symlink   | `l`  | Points to path     |
| Block     | `b`  | Block device       |
| Character | `c`  | Character device   |
| FIFO      | `p`  | Named pipe         |
| Socket    | `s`  | Unix domain socket |

## File Descriptors

Integer handles for open files, pipes, sockets, devices.

### Standard File Descriptors

| FD  | Name   | Default         | Shell     |
| --- | ------ | --------------- | --------- |
| 0   | stdin  | Terminal input  | `< file`  |
| 1   | stdout | Terminal output | `> file`  |
| 2   | stderr | Terminal error  | `2> file` |

### FD Table Structure

```text
Process FD Table → Open File Table → Inode Table
     [0] ──────────→ [offset, flags] ──→ [file metadata]
     [1] ──────────→ [offset, flags] ──→ [file metadata]
     [2] ──────────→ [offset, flags] ──→ [file metadata]
```

### Inspecting File Descriptors

```bash
# List FDs for a process
ls -la /proc/PID/fd/

# Using lsof
lsof -p PID

# Count open FDs
ls /proc/PID/fd | wc -l

# Check FD limits
ulimit -n                     # Soft limit
cat /proc/sys/fs/file-max     # System-wide limit
```

## Permissions

### Permission Triads

Three sets control access for user (owner), group, and other (everyone else):

| Permission | Files           | Directories                   |
| ---------- | --------------- | ----------------------------- |
| `r` (4)    | Read contents   | List contents                 |
| `w` (2)    | Modify contents | Create/delete/rename files    |
| `x` (1)    | Execute file    | Access directory (cd into it) |

### Octal Notation

| Octal | Permissions | Common use                  |
| ----- | ----------- | --------------------------- |
| `755` | rwxr-xr-x   | Directories, executables    |
| `644` | rw-r--r--   | Regular files               |
| `600` | rw-------   | Private files (credentials) |
| `700` | rwx------   | Private directories         |

### Special Permissions

| Bit    | Octal | On Files               | On Directories                    |
| ------ | ----- | ---------------------- | --------------------------------- |
| setuid | 4xxx  | Execute as file owner  | No effect                         |
| setgid | 2xxx  | Execute as group owner | New files inherit directory group |
| sticky | 1xxx  | No modern effect       | Only owner can delete files       |

```bash
# Find setuid/setgid files
find / -perm /6000 -type f 2>/dev/null

# Remove setuid bit
chmod u-s /path/to/binary

# Set sticky bit on shared directory
chmod +t /shared
```

### ACLs (Access Control Lists)

When basic permissions aren't enough:

```bash
# View ACLs
getfacl file.txt

# Set ACL for specific user
setfacl -m u:alice:rw file.txt

# Set ACL for specific group
setfacl -m g:developers:rx directory/

# Default ACL (inherited by new files)
setfacl -d -m g:developers:rwx directory/

# Remove all ACLs
setfacl -b file.txt
```

### umask

Masks permission bits when creating new files:

| umask | Files (from 666) | Dirs (from 777) |
| ----- | ---------------- | --------------- |
| 022   | 644 (rw-r--r--)  | 755 (rwxr-xr-x) |
| 027   | 640 (rw-r-----)  | 750 (rwxr-x---) |
| 077   | 600 (rw-------)  | 700 (rwx------) |

```bash
umask           # View current
umask 027       # Set restrictive default
```

### Permission Commands

```bash
# Set exact permissions
chmod 750 file

# Add execute for owner
chmod u+x file

# Remove write for group/other
chmod go-w file

# Recursive: read all, execute dirs only
chmod -R a+rX dir/

# Change ownership
chown user:group file
chown -R user dir/

# Show permissions along path
namei -l /path/to/file

# Show octal permissions
stat -c '%a %U:%G %n' *
```

## Security Pitfalls

### World-Writable Files

```bash
# Find world-writable files
find / -perm -002 -type f 2>/dev/null

# Find world-writable directories without sticky bit
find / -perm -002 -type d ! -perm -1000 2>/dev/null
```

### Insecure Temporary Files

```bash
# BAD: Predictable, race condition
tmpfile="/tmp/myapp.$$"
echo "data" > "$tmpfile"

# GOOD: Atomic creation with random suffix
tmpfile=$(mktemp /tmp/myapp.XXXXXX)
echo "data" > "$tmpfile"
```

```python
# BAD
import tempfile
name = tempfile.mktemp()  # Race condition
f = open(name, 'w')

# GOOD
fd, name = tempfile.mkstemp()  # Atomic
os.write(fd, b'data')
```

### Symlink Attacks

Attacker creates symlink pointing to sensitive file in predictable location.

**Mitigations:**

- Use `O_NOFOLLOW` flag with `open()`
- Create temp files in protected directories
- Enable kernel protections: `sysctl fs.protected_symlinks=1`

### Security Audit Commands

```bash
# Find setuid root files
find / -user root -perm -4000 2>/dev/null

# Find world-readable credentials
find /etc -name "*.conf" -perm -004 2>/dev/null | xargs grep -l password

# Check path permissions
namei -l /path/to/sensitive/file
```

## Atomic Operations

### What's Atomic

| Operation                 | Atomic? | Notes                                       |
| ------------------------- | ------- | ------------------------------------------- |
| `rename()` same fs        | Yes     | Atomically replaces destination             |
| `rename()` cross-fs       | No      | Fails with `EXDEV`                          |
| `link()` hard link        | Yes     | Creates link atomically                     |
| `symlink()`               | Yes     | Creates symlink atomically                  |
| `open(O_CREAT \| O_EXCL)` | Yes     | Atomic create-if-not-exists                 |
| `write()` small           | ~Yes    | Atomic up to `PIPE_BUF` (512-4096 bytes)    |
| `write()` large           | No      | May interleave with concurrent writes       |
| `mkdir()`                 | Yes     | Creates directory atomically                |
| `unlink()`                | Yes     | Removes link atomically                     |
| `O_APPEND` writes         | Yes     | Seek-and-write is atomic                    |
| Metadata + data write     | No      | Use `fsync()` for durability, not atomicity |

### Safe File Write Pattern

Never write directly to the target file. Write to temp, then rename:

```bash
# Shell: atomic config update
tmp=$(mktemp /etc/config.XXXXXX)
echo "new content" > "$tmp"
chmod 644 "$tmp"
mv "$tmp" /etc/config       # Atomic replacement
```

```python
# Python: atomic file write
import os
import tempfile

def atomic_write(path, content):
    dir_name = os.path.dirname(path)
    fd, tmp_path = tempfile.mkstemp(dir=dir_name)
    try:
        os.write(fd, content.encode())
        os.fsync(fd)  # Flush to disk
        os.close(fd)
        os.rename(tmp_path, path)  # Atomic
    except:
        os.close(fd)
        os.unlink(tmp_path)
        raise
```

```go
// Go: atomic file write
func atomicWrite(path string, data []byte, perm os.FileMode) error {
    dir := filepath.Dir(path)
    f, err := os.CreateTemp(dir, ".tmp")
    if err != nil {
        return err
    }
    tmpPath := f.Name()
    defer os.Remove(tmpPath) // Clean up on failure

    if _, err := f.Write(data); err != nil {
        f.Close()
        return err
    }
    if err := f.Sync(); err != nil { // fsync
        f.Close()
        return err
    }
    if err := f.Close(); err != nil {
        return err
    }
    if err := os.Chmod(tmpPath, perm); err != nil {
        return err
    }
    return os.Rename(tmpPath, path) // Atomic
}
```

### renameat2 (Linux 3.15+)

Extended rename with atomicity flags:

| Flag               | Behavior                                  |
| ------------------ | ----------------------------------------- |
| `RENAME_NOREPLACE` | Fail if destination exists (atomic check) |
| `RENAME_EXCHANGE`  | Atomically swap two files                 |

```c
// Atomic swap of two files (Linux only)
#include <linux/fs.h>
renameat2(AT_FDCWD, "file_a", AT_FDCWD, "file_b", RENAME_EXCHANGE);
```

## File Locking

### Advisory vs Mandatory Locks

| Type      | Enforced by | Use case                       |
| --------- | ----------- | ------------------------------ |
| Advisory  | Convention  | Cooperating processes          |
| Mandatory | Kernel      | Rare, disabled on most systems |

Advisory locks only work if all processes agree to check them.

### flock() - Whole File Locks

```c
#include <sys/file.h>

int fd = open("file", O_RDWR);
flock(fd, LOCK_EX);    // Exclusive lock (blocks)
flock(fd, LOCK_SH);    // Shared lock (blocks)
flock(fd, LOCK_EX | LOCK_NB);  // Non-blocking
flock(fd, LOCK_UN);    // Unlock
```

| Flag      | Meaning                           |
| --------- | --------------------------------- |
| `LOCK_SH` | Shared (read) lock                |
| `LOCK_EX` | Exclusive (write) lock            |
| `LOCK_NB` | Non-blocking (return EWOULDBLOCK) |
| `LOCK_UN` | Release lock                      |

**Key behaviors:**

- Locks are on open file descriptions, not file descriptors
- Inherited across `fork()` (both processes share the lock)
- Released when all FDs to that description close
- **Not** released on `exec()` unless `O_CLOEXEC`

### fcntl() - Byte Range Locks (POSIX)

```c
#include <fcntl.h>

struct flock fl = {
    .l_type = F_WRLCK,     // F_RDLCK, F_WRLCK, F_UNLCK
    .l_whence = SEEK_SET,
    .l_start = 0,
    .l_len = 0             // 0 = entire file
};

fcntl(fd, F_SETLK, &fl);   // Non-blocking
fcntl(fd, F_SETLKW, &fl);  // Blocking
fcntl(fd, F_GETLK, &fl);   // Test lock
```

| Lock type | Meaning            |
| --------- | ------------------ |
| `F_RDLCK` | Shared (read) lock |
| `F_WRLCK` | Exclusive (write)  |
| `F_UNLCK` | Release lock       |

**Key behaviors:**

- Locks per process, not per FD (closing any FD releases all locks)
- Works over NFS (unlike flock on older kernels)
- Can lock byte ranges within a file

### Lock File Pattern

For process exclusion (daemons, scripts):

```bash
# Shell: lock file with flock
exec 200>/var/run/myapp.lock
flock -n 200 || { echo "Already running"; exit 1; }
# ... do work ...
```

```python
# Python: lock file
import fcntl
import os
import sys

def acquire_lock(path):
    fd = os.open(path, os.O_CREAT | os.O_RDWR)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return fd
    except BlockingIOError:
        os.close(fd)
        return None

lock_fd = acquire_lock('/var/run/myapp.lock')
if lock_fd is None:
    sys.exit("Already running")
# Lock released when process exits
```

### PID File Pattern

```bash
# Write PID atomically
echo $$ > /var/run/myapp.pid.tmp
mv /var/run/myapp.pid.tmp /var/run/myapp.pid

# Check if process is running
if [ -f /var/run/myapp.pid ]; then
    pid=$(cat /var/run/myapp.pid)
    if kill -0 "$pid" 2>/dev/null; then
        echo "Running as $pid"
    else
        echo "Stale PID file"
    fi
fi
```

### flock vs fcntl Summary

| Feature           | flock          | fcntl            |
| ----------------- | -------------- | ---------------- |
| Granularity       | Whole file     | Byte ranges      |
| NFS support       | Linux 2.6.12+  | Yes              |
| Release on close  | All FDs closed | Any FD closed    |
| Inherited on fork | Yes (shared)   | No (per-process) |
| POSIX standard    | No (BSD)       | Yes              |

## Watching for Changes

### Platform APIs

| Platform | API                   | Notes                                      |
| -------- | --------------------- | ------------------------------------------ |
| Linux    | inotify               | File/directory level, recursive needs work |
| macOS    | FSEvents              | Directory level, coalesced events          |
| BSD      | kqueue                | File descriptor based, very flexible       |
| Windows  | ReadDirectoryChangesW | Directory based                            |

### inotify (Linux)

```c
#include <sys/inotify.h>

int fd = inotify_init1(IN_NONBLOCK);
int wd = inotify_add_watch(fd, "/path",
    IN_CREATE | IN_DELETE | IN_MODIFY | IN_MOVE);

// Read events
char buf[4096];
ssize_t len = read(fd, buf, sizeof(buf));
struct inotify_event *event = (struct inotify_event *)buf;
```

| Event              | Meaning                       |
| ------------------ | ----------------------------- |
| `IN_ACCESS`        | File accessed (read)          |
| `IN_MODIFY`        | File modified                 |
| `IN_ATTRIB`        | Metadata changed              |
| `IN_CLOSE_WRITE`   | Writable file closed          |
| `IN_CLOSE_NOWRITE` | Non-writable file closed      |
| `IN_OPEN`          | File opened                   |
| `IN_MOVED_FROM`    | File moved out of watched dir |
| `IN_MOVED_TO`      | File moved into watched dir   |
| `IN_CREATE`        | File/dir created              |
| `IN_DELETE`        | File/dir deleted              |
| `IN_DELETE_SELF`   | Watched item itself deleted   |
| `IN_MOVE_SELF`     | Watched item itself moved     |

**Limitations:**

- Not recursive (must add watches to subdirectories manually)
- Events can be coalesced or lost under load (`IN_Q_OVERFLOW`)
- Race condition: files may change before you can read them
- Doesn't work on network filesystems (NFS, CIFS)

### kqueue (BSD/macOS)

```c
#include <sys/event.h>

int kq = kqueue();
int fd = open("/path/to/file", O_RDONLY);

struct kevent change;
EV_SET(&change, fd, EVFILT_VNODE,
    EV_ADD | EV_CLEAR,
    NOTE_WRITE | NOTE_DELETE | NOTE_RENAME,
    0, NULL);

kevent(kq, &change, 1, NULL, 0, NULL);

// Wait for events
struct kevent event;
int n = kevent(kq, NULL, 0, &event, 1, NULL);
```

| Filter flag   | Meaning            |
| ------------- | ------------------ |
| `NOTE_DELETE` | File deleted       |
| `NOTE_WRITE`  | File modified      |
| `NOTE_EXTEND` | File extended      |
| `NOTE_ATTRIB` | Attributes changed |
| `NOTE_LINK`   | Link count changed |
| `NOTE_RENAME` | File renamed       |
| `NOTE_REVOKE` | Access revoked     |

**Advantages over inotify:**

- Unified API for files, sockets, processes, signals, timers
- Works on file descriptor (survives rename)
- Per-event EV_CLEAR for edge-triggered behavior

### FSEvents (macOS)

```c
#include <CoreServices/CoreServices.h>

void callback(ConstFSEventStreamRef stream,
              void *info,
              size_t numEvents,
              void *eventPaths,
              const FSEventStreamEventFlags flags[],
              const FSEventStreamEventId ids[]) {
    char **paths = eventPaths;
    for (size_t i = 0; i < numEvents; i++) {
        printf("Changed: %s\n", paths[i]);
    }
}

CFStringRef path = CFSTR("/path/to/watch");
CFArrayRef paths = CFArrayCreate(NULL, (const void **)&path, 1, NULL);

FSEventStreamRef stream = FSEventStreamCreate(
    NULL, &callback, NULL, paths,
    kFSEventStreamEventIdSinceNow,
    1.0,  // Latency in seconds
    kFSEventStreamCreateFlagFileEvents
);

FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(),
    kCFRunLoopDefaultMode);
FSEventStreamStart(stream);
CFRunLoopRun();
```

| Flag                                 | Meaning                           |
| ------------------------------------ | --------------------------------- |
| `kFSEventStreamCreateFlagFileEvents` | File-level events (not just dirs) |
| `kFSEventStreamCreateFlagNoDefer`    | Don't batch events                |

### Cross-Platform Libraries

| Library  | Language | Platforms             |
| -------- | -------- | --------------------- |
| watchdog | Python   | Linux, macOS, Windows |
| notify   | Rust     | Linux, macOS, Windows |
| fsnotify | Go       | Linux, macOS, Windows |
| chokidar | Node.js  | Linux, macOS, Windows |

```python
# Python watchdog example
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class Handler(FileSystemEventHandler):
    def on_modified(self, event):
        print(f"Modified: {event.src_path}")

observer = Observer()
observer.schedule(Handler(), "/path/to/watch", recursive=True)
observer.start()
```

## Performance Considerations

### Many Small Files vs Few Large Files

| Aspect          | Many small files   | Few large files |
| --------------- | ------------------ | --------------- |
| Metadata ops    | High overhead      | Low overhead    |
| Directory scans | Slow               | Fast            |
| Inode usage     | Can exhaust inodes | Minimal         |
| Fragmentation   | Higher             | Lower (usually) |
| Backup/sync     | Slower             | Faster          |

**Rule of thumb:** If files are < 4KB, consider combining them.

### Directory Traversal Performance

```bash
# Bad: spawns find subprocess for each dir
for d in */; do find "$d" -name "*.log"; done

# Good: single find invocation
find . -name "*.log"

# Best: parallel with fd (if available)
fd -e log
```

**Optimization strategies:**

1. **Avoid stat() calls when possible** - `ls -1` vs `ls -l`
2. **Use openat/fstatat** - reduces path resolution overhead
3. **Read directories in batches** - `getdents64` syscall
4. **Sort by inode** for sequential disk access (HDD only)

### Caching Considerations

| Cache level | Size      | Latency     |
| ----------- | --------- | ----------- |
| Page cache  | RAM-based | ~100ns      |
| Disk cache  | ~64-256MB | ~1ms (SSD)  |
| Cold disk   | -         | ~10ms (SSD) |

```bash
# Drop caches (Linux, requires root)
echo 3 > /proc/sys/vm/drop_caches

# Check cache hit ratio
cat /proc/meminfo | grep -E "Cached|Buffers"

# Force bypass page cache
dd if=/dev/sda of=/dev/null bs=1M iflag=direct
```

### O_DIRECT - Bypass Page Cache

```c
int fd = open("file", O_RDWR | O_DIRECT);
// Buffer must be aligned (typically 512 or 4096 bytes)
void *buf;
posix_memalign(&buf, 4096, 4096);
read(fd, buf, 4096);
```

**When to use O_DIRECT:**

- Application does its own caching (databases)
- Very large files that won't benefit from cache
- Avoiding double-buffering

### Sync and Durability

| Function      | Guarantees                           |
| ------------- | ------------------------------------ |
| `fsync(fd)`   | File data + metadata flushed to disk |
| `fdatasync()` | File data flushed (metadata may lag) |
| `sync()`      | Flush all buffers (system-wide)      |
| `O_SYNC`      | Every write is synchronous           |
| `O_DSYNC`     | Data sync on each write              |

```bash
# Ensure write durability
echo "data" > file
sync  # System-wide, sledgehammer

# Better: fsync specific file
python -c "import os; f=open('file','a'); f.flush(); os.fsync(f.fileno())"
```

## Common Patterns

### Safe Config File Update

```bash
#!/bin/bash
config="/etc/myapp/config"
new_config=$(mktemp "${config}.XXXXXX")

# Write new config
cat > "$new_config" << 'EOF'
key=value
EOF

# Preserve permissions
chmod --reference="$config" "$new_config" 2>/dev/null || chmod 644 "$new_config"

# Atomic replacement
mv "$new_config" "$config"
```

### Concurrent-Safe Counter

```python
import os
import fcntl

def increment_counter(path):
    fd = os.open(path, os.O_RDWR | os.O_CREAT)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        data = os.read(fd, 100) or b'0'
        count = int(data.strip() or 0) + 1
        os.ftruncate(fd, 0)
        os.lseek(fd, 0, os.SEEK_SET)
        os.write(fd, str(count).encode())
        os.fsync(fd)
        return count
    finally:
        fcntl.flock(fd, fcntl.LOCK_UN)
        os.close(fd)
```

### Watching Directory for New Files

```bash
# Using inotifywait (Linux)
inotifywait -m -e create /path/to/dir |
while read dir action file; do
    echo "New file: $file"
done

# Using fswatch (macOS/Linux)
fswatch -0 /path/to/dir | xargs -0 -n1 echo

# Polling fallback (portable)
while true; do
    ls -1 /path/to/dir > /tmp/current
    diff /tmp/previous /tmp/current 2>/dev/null | grep "^>"
    mv /tmp/current /tmp/previous
    sleep 1
done
```

## Quick Reference

### Error Codes

| Error         | Meaning                              |
| ------------- | ------------------------------------ |
| `ENOENT`      | File doesn't exist                   |
| `EEXIST`      | File already exists                  |
| `EACCES`      | Permission denied                    |
| `EBUSY`       | Resource busy (mounted, locked)      |
| `EXDEV`       | Cross-device link (rename across fs) |
| `ENOSPC`      | No space left                        |
| `ENOLCK`      | No locks available                   |
| `EWOULDBLOCK` | Would block (non-blocking op)        |
| `ESTALE`      | Stale NFS file handle                |

### Critical Syscalls

| Syscall     | Purpose                     |
| ----------- | --------------------------- |
| `open()`    | Open/create file            |
| `close()`   | Close descriptor            |
| `read()`    | Read bytes                  |
| `write()`   | Write bytes                 |
| `rename()`  | Atomic rename               |
| `unlink()`  | Remove file                 |
| `link()`    | Create hard link            |
| `symlink()` | Create symbolic link        |
| `stat()`    | Get file metadata           |
| `fstat()`   | Get metadata via FD         |
| `fsync()`   | Flush to disk               |
| `flock()`   | Advisory file lock          |
| `fcntl()`   | File control (locks, flags) |

## See Also

- [Unix](unix.md) - General shell commands
- [Shell](shell.md) - Scripting patterns
- [Performance](performance.md) - Profiling and optimization
