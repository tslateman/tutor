---
title: "Unix Filesystem Cheat Sheet"
description:
  FHS layout, inodes, permissions, links, file descriptors, and security
  pitfalls for Unix systems.
---

Filesystem core concepts: directory layout, inode metadata, permissions, links,
file descriptors, and common security pitfalls.

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

## See Also

- [Filesystem (Advanced)](filesystem-advanced.md) - Atomic operations, locking,
  inotify/FSEvents, performance
- [Unix](unix.md) - General shell commands
- [Shell](shell.md) - Scripting patterns
- [Performance](performance.md) - Profiling and optimization
