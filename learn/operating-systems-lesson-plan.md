# Operating Systems Lesson Plan

A progressive curriculum to understand how your OS works by observing it
directly.

## Lesson 1: Processes

**Goal:** Understand what a process is, how processes are created, and how to
observe them.

### Concepts

A process is a running program -- it has a PID, memory space, file descriptors,
and a state. The kernel creates processes using fork (clone the parent) and exec
(replace with a new program). Every process has a parent; PID 1 is the root.
Processes transition through states: running, sleeping, stopped, zombie.

### Exercises

1. **Observe running processes**

   ```bash
   ps aux | head -20           # Snapshot of all processes
   ps -eo pid,ppid,state,comm  # Show parent PIDs and state
   ps -p $$                    # Your current shell process
   echo $$                     # Your shell's PID
   ```

2. **Watch processes in real time**

   ```bash
   top -l 1 -n 10             # macOS: one snapshot, top 10
   # Or on Linux:
   top -b -n 1 | head -20
   ```

   Press `q` to quit interactive top. Note the columns: PID, CPU%, MEM%, STATE,
   COMMAND.

3. **Explore the process tree**

   ```bash
   pstree -p $$ 2>/dev/null || ps -eo pid,ppid,comm | head -30
   # See parent-child relationships
   # On macOS, install pstree: brew install pstree
   ```

4. **Create processes with fork/exec**

   ```python
   # fork_demo.py
   import os

   pid = os.fork()
   if pid == 0:
       print(f"Child: PID={os.getpid()}, Parent={os.getppid()}")
   else:
       print(f"Parent: PID={os.getpid()}, Child={pid}")
       os.waitpid(pid, 0)
   ```

   ```bash
   python3 fork_demo.py
   ```

### Checkpoint

Run `ps -eo pid,ppid,state,comm` and identify your shell, its parent, and at
least one zombie or sleeping process.

---

## Lesson 2: Memory

**Goal:** Understand virtual memory, address spaces, and how to observe memory
usage.

### Concepts

Each process gets its own virtual address space -- it sees a flat range of
addresses regardless of physical RAM layout. The kernel maps virtual pages to
physical frames using page tables. When a process accesses a page not in RAM, a
page fault loads it from disk. Swap extends physical memory to disk at the cost
of speed. Resident set size (RSS) shows how much physical RAM a process actually
uses.

### Exercises

1. **Observe system memory**

   ```bash
   # macOS
   vm_stat                     # Page-level memory stats
   sysctl hw.memsize           # Total physical RAM

   # Linux
   # free -h                   # Human-readable summary
   # cat /proc/meminfo         # Detailed breakdown
   ```

2. **Watch per-process memory**

   ```bash
   ps -eo pid,rss,vsz,comm --sort=-rss 2>/dev/null | head -15
   # rss = resident set (physical), vsz = virtual size
   # macOS alternative:
   ps -eo pid,rss,vsz,comm | sort -k2 -rn | head -15
   ```

3. **Allocate memory and observe**

   ```python
   # mem_demo.py
   import os, time

   print(f"PID: {os.getpid()}")
   input("Press Enter to allocate 100MB...")

   data = bytearray(100 * 1024 * 1024)  # 100 MB
   print("Allocated. Check RSS with: ps -o pid,rss -p " + str(os.getpid()))
   input("Press Enter to exit...")
   ```

   ```bash
   python3 mem_demo.py
   # In another terminal, watch the RSS grow:
   ps -o pid,rss,vsz -p <PID>
   ```

4. **Observe page faults**

   ```bash
   # macOS -- use /usr/bin/time (not shell builtin)
   /usr/bin/time -l python3 -c "x = bytearray(50_000_000)" 2>&1 | grep fault

   # Linux
   # /usr/bin/time -v python3 -c "x = bytearray(50_000_000)" 2>&1 | grep fault
   ```

### Checkpoint

Run the memory allocation script. Confirm RSS increases by roughly 100MB using
`ps`.

---

## Lesson 3: File Systems

**Goal:** Understand inodes, file descriptors, and the "everything is a file"
abstraction.

### Concepts

Files on disk are represented by inodes -- data structures storing metadata
(size, permissions, block pointers) but not the name. Directory entries map
names to inode numbers. When a process opens a file, the kernel returns a file
descriptor (a small integer). File descriptors 0, 1, 2 are stdin, stdout,
stderr. The "everything is a file" philosophy means devices, pipes, and sockets
all use the same read/write interface.

### Exercises

1. **Examine inodes**

   ```bash
   ls -i /etc/hosts             # Show inode number
   stat /etc/hosts              # Full inode metadata
   # Create a hard link -- same inode, different name
   echo "hello" > /tmp/original.txt
   ln /tmp/original.txt /tmp/hardlink.txt
   ls -i /tmp/original.txt /tmp/hardlink.txt  # Same inode
   stat /tmp/original.txt       # Note the link count
   ```

2. **Explore file descriptors**

   ```bash
   # See open file descriptors for your shell
   ls -la /dev/fd/
   # macOS: lsof on your shell
   lsof -p $$
   ```

3. **Watch file descriptors in action**

   ```python
   # fd_demo.py
   import os

   f = open("/tmp/fd_test.txt", "w")
   print(f"File descriptor: {f.fileno()}")
   print(f"PID: {os.getpid()}")
   input("Check lsof -p <PID> in another terminal. Press Enter to close...")
   f.close()
   ```

   ```bash
   python3 fd_demo.py
   # In another terminal:
   lsof -p <PID> | grep fd_test
   ```

4. **See "everything is a file"**

   ```bash
   file /dev/null               # Character special device
   file /dev/stdin              # Link to fd/0
   echo "hello" > /dev/null     # Write to the void
   cat < /dev/urandom | head -c 16 | xxd  # Read random bytes
   ```

### Checkpoint

Create a file, find its inode with `ls -i`, open it in Python, and confirm the
file descriptor appears in `lsof`.

---

## Lesson 4: I/O

**Goal:** Understand blocking vs non-blocking I/O, buffering, and I/O
multiplexing.

### Concepts

By default, read and write calls block -- the process sleeps until the operation
completes. Non-blocking I/O returns immediately if data is not ready. Buffering
(in libc or the kernel) batches small writes into larger ones for efficiency.
I/O multiplexing (select, poll, epoll/kqueue) lets a single thread monitor many
file descriptors at once, which is how event-driven servers (nginx, Node.js)
handle thousands of connections.

### Exercises

1. **Observe blocking I/O**

   ```python
   # blocking_io.py
   import os, time

   print(f"PID: {os.getpid()}")
   print("Blocking on stdin... (type something)")
   data = input()
   print(f"Got: {data}")
   ```

   ```bash
   python3 blocking_io.py &
   ps -o pid,state,comm -p $!  # Process is sleeping (S)
   fg                           # Bring back and type input
   ```

2. **See buffering effects**

   ```bash
   # Unbuffered vs buffered output
   python3 -c "
   import sys, time
   for i in range(5):
       sys.stdout.write(f'{i} ')
       time.sleep(0.5)
   print()
   "
   # Output appears all at once (buffered to non-terminal)
   # Pipe to cat to see buffering:
   python3 -c "
   import sys, time
   for i in range(5):
       sys.stdout.write(f'{i} ')
       sys.stdout.flush()    # Force unbuffered
       time.sleep(0.5)
   print()
   "
   ```

3. **I/O multiplexing with select**

   ```python
   # select_demo.py
   import select, sys

   print("Type lines (Ctrl-D to quit). Timeout after 3s of silence.")
   while True:
       ready, _, _ = select.select([sys.stdin], [], [], 3.0)
       if ready:
           line = sys.stdin.readline()
           if not line:
               break
           print(f"  Got: {line.strip()}")
       else:
           print("  (no input for 3 seconds)")
   ```

   ```bash
   python3 select_demo.py
   ```

4. **Measure I/O throughput**

   ```bash
   # Write 100MB and measure speed
   dd if=/dev/zero of=/tmp/testfile bs=1m count=100 2>&1
   # Read it back
   dd if=/tmp/testfile of=/dev/null bs=1m 2>&1
   rm /tmp/testfile
   ```

### Checkpoint

Run the select demo. Confirm it detects both input and timeouts. Explain why a
web server uses multiplexing instead of one thread per connection.

---

## Lesson 5: Scheduling

**Goal:** Understand how the kernel allocates CPU time and how to observe
scheduling behavior.

### Concepts

The scheduler decides which process runs on which CPU and for how long. Modern
schedulers use preemptive multitasking -- they interrupt running processes to
share the CPU fairly. Priority and "nice" values influence scheduling decisions.
A process with a higher nice value yields more CPU time to others. Real-time
processes get strict priority guarantees.

### Exercises

1. **Observe scheduling with top**

   ```bash
   # Watch CPU distribution in real time
   top -o cpu                  # macOS: sort by CPU
   # top -o %CPU              # Linux alternative
   # Look at: TIME (total CPU used), STATE, PRI/NI columns
   ```

2. **Experiment with nice values**

   ```bash
   # Run a CPU-bound task at normal priority
   nice -n 0 python3 -c "
   import time; start = time.time()
   x = sum(range(50_000_000))
   print(f'Normal: {time.time()-start:.2f}s')
   "

   # Run with low priority (be "nicer" to other processes)
   nice -n 19 python3 -c "
   import time; start = time.time()
   x = sum(range(50_000_000))
   print(f'Nice 19: {time.time()-start:.2f}s')
   "
   ```

3. **Observe context switches**

   ```bash
   # macOS
   /usr/bin/time -l python3 -c "
   import time
   for _ in range(1000): time.sleep(0.001)
   " 2>&1 | grep "voluntary context"

   # Linux
   # /usr/bin/time -v python3 -c "..." 2>&1 | grep context
   ```

4. **Compete for CPU**

   ```bash
   # Start two CPU-bound tasks with different nice values
   nice -n 0  python3 -c "x=sum(range(100_000_000)); print('normal done')" &
   nice -n 19 python3 -c "x=sum(range(100_000_000)); print('nice done')" &
   wait
   # The normal-priority task should finish first
   ```

### Checkpoint

Run two competing tasks with different nice values. Confirm the lower-nice
(higher-priority) task gets more CPU time.

---

## Lesson 6: Concurrency

**Goal:** Understand threads vs processes, race conditions, and synchronization
primitives.

### Concepts

Threads share memory within a process; processes have separate address spaces.
Shared memory makes threads fast to communicate but dangerous -- two threads
writing the same variable cause race conditions. Locks (mutexes) prevent
concurrent access to shared data. Deadlock occurs when two threads each hold a
lock the other needs. Python's GIL serializes CPU-bound threads, so use
multiprocessing for true parallelism in Python.

### Exercises

1. **Threads vs processes**

   ```python
   # threads_vs_procs.py
   import threading, multiprocessing, os

   def show_ids(label):
       print(f"{label}: PID={os.getpid()}, TID={threading.get_ident()}")

   t = threading.Thread(target=show_ids, args=("Thread",))
   t.start(); t.join()

   p = multiprocessing.Process(target=show_ids, args=("Process",))
   p.start(); p.join()

   show_ids("Main")
   # Thread has same PID as Main; Process has a different PID
   ```

   ```bash
   python3 threads_vs_procs.py
   ```

2. **Demonstrate a race condition**

   ```python
   # race.py
   import threading

   counter = 0

   def increment():
       global counter
       for _ in range(1_000_000):
           counter += 1

   threads = [threading.Thread(target=increment) for _ in range(4)]
   for t in threads: t.start()
   for t in threads: t.join()

   print(f"Expected: 4000000, Got: {counter}")
   # Result will be less than 4000000 due to race conditions
   ```

   ```bash
   python3 race.py
   ```

3. **Fix with a lock**

   ```python
   # race_fixed.py
   import threading

   counter = 0
   lock = threading.Lock()

   def increment():
       global counter
       for _ in range(1_000_000):
           with lock:
               counter += 1

   threads = [threading.Thread(target=increment) for _ in range(4)]
   for t in threads: t.start()
   for t in threads: t.join()

   print(f"Expected: 4000000, Got: {counter}")
   # Correct, but much slower due to lock contention
   ```

   ```bash
   python3 race_fixed.py
   ```

4. **Observe threads in the OS**

   ```bash
   python3 -c "
   import threading, time, os
   print(f'PID: {os.getpid()}')
   def worker(): time.sleep(30)
   for i in range(4): threading.Thread(target=worker, daemon=True).start()
   time.sleep(30)
   " &

   # View threads (macOS)
   ps -M -p $!
   # Linux: ps -T -p <PID>
   kill $!
   ```

### Checkpoint

Run the race condition demo. Confirm the result is wrong. Apply the lock and
confirm correctness.

---

## Lesson 7: System Calls

**Goal:** Understand the userspace/kernel boundary and trace system calls with
real tools.

### Concepts

System calls are the interface between user programs and the kernel. When your
code calls open(), read(), or write(), the C library translates these into
system calls that trap into kernel mode. On macOS, use `dtruss` (requires SIP
disabled or `sudo`). On Linux, use `strace`. Tracing system calls reveals
exactly what a program asks the kernel to do -- invaluable for debugging file,
network, and permission issues.

### Exercises

1. **Trace a simple command**

   ```bash
   # macOS (requires sudo)
   sudo dtruss -f ls /tmp 2>&1 | head -40

   # Linux
   # strace ls /tmp 2>&1 | head -40
   # Look for: open/openat, read, write, close, stat
   ```

2. **Count system calls by type**

   ```bash
   # macOS
   sudo dtruss ls /tmp 2>&1 | awk '{print $1}' | sort | uniq -c | sort -rn | head

   # Linux
   # strace -c ls /tmp
   # Shows a summary table of syscall counts and time
   ```

3. **Trace a Python script**

   ```python
   # syscall_demo.py
   f = open("/tmp/syscall_test.txt", "w")
   f.write("hello from userspace\n")
   f.close()
   ```

   ```bash
   # macOS
   sudo dtruss python3 syscall_demo.py 2>&1 | grep syscall_test

   # Linux
   # strace -e openat,write,close python3 syscall_demo.py
   # You will see openat(), write(), close() for your file
   ```

4. **Trace network system calls**

   ```bash
   # macOS
   sudo dtruss curl -s https://example.com -o /dev/null 2>&1 | grep -E "socket|connect|send|recv" | head -20

   # Linux
   # strace -e socket,connect,sendto,recvfrom curl -s https://example.com -o /dev/null
   ```

### Checkpoint

Trace `cat /etc/hosts` and identify the open, read, write, and close system
calls in the output.

---

## Lesson 8: Putting It Together

**Goal:** Trace a web request through the full OS stack -- processes, memory,
files, I/O, and syscalls.

### Concepts

When a browser requests a page, dozens of OS mechanisms activate: DNS resolution
(socket syscalls), TCP connection (connect, send, recv), the server forks or
dispatches a thread, reads files from disk (open, read), allocates memory for
the response, and writes it back over the socket. Understanding this full path
turns the OS from an abstraction into a visible machine you can inspect and
debug.

### Exercises

1. **Run a minimal HTTP server and observe it**

   ```python
   # server.py
   from http.server import HTTPServer, SimpleHTTPRequestHandler
   import os

   os.chdir("/tmp")
   with open("index.html", "w") as f:
       f.write("<h1>Hello OS</h1>")

   print(f"Server PID: {os.getpid()}")
   HTTPServer(("127.0.0.1", 8080), SimpleHTTPRequestHandler).serve_forever()
   ```

   ```bash
   python3 server.py &
   SERVER_PID=$!

   # Observe the process
   ps -o pid,state,comm -p $SERVER_PID

   # See its open file descriptors
   lsof -p $SERVER_PID | head -20

   # Make a request
   curl http://127.0.0.1:8080/index.html

   kill $SERVER_PID
   ```

2. **Trace the server handling a request**

   ```bash
   python3 server.py &
   SERVER_PID=$!

   # macOS: trace syscalls while making a request
   sudo dtruss -p $SERVER_PID 2>/tmp/trace.out &
   sleep 1
   curl http://127.0.0.1:8080/index.html
   sleep 1
   kill $SERVER_PID

   # Examine the trace -- find accept, read, open, write, close
   grep -E "accept|read|write|open|close|send" /tmp/trace.out | head -30
   ```

3. **Observe the full connection lifecycle**

   ```bash
   python3 server.py &
   SERVER_PID=$!

   # Watch network connections
   lsof -i :8080               # See LISTEN state
   curl http://127.0.0.1:8080/index.html &
   lsof -i :8080               # See ESTABLISHED during request

   # Check memory usage
   ps -o pid,rss,vsz -p $SERVER_PID

   kill $SERVER_PID
   ```

4. **Build a mental model end to end**

   ```bash
   # Trace a full curl request to see every OS interaction
   # macOS
   sudo dtruss curl -s http://127.0.0.1:8080/index.html -o /dev/null 2>&1 | \
     grep -E "socket|connect|send|recv|write|read" | head -30

   # Map each syscall to a layer:
   # socket()   -> create network endpoint
   # connect()  -> TCP handshake
   # send()     -> HTTP request
   # recv()     -> HTTP response
   # close()    -> tear down connection
   ```

   Start the server again before running this, then clean up after.

### Checkpoint

Start the HTTP server. Make a request while tracing. Identify at least one
syscall from each category: network (socket/connect), file (open/read), and I/O
(write/send).

---

## Practice Projects

### Project 1: Process Monitor

Write a script that polls `ps` every second and logs when new processes appear
or existing ones exit. Track PIDs, parent PIDs, and lifetimes. Run it for 5
minutes during normal usage and analyze the output.

### Project 2: Memory Pressure Experiment

Write a program that allocates memory in 10MB increments, pausing between each.
Monitor RSS, virtual size, and swap usage as you approach system limits. Record
the point where the OS starts swapping and measure the performance cliff.

### Project 3: Web Server Autopsy

Start a Python HTTP server. Use lsof, ps, and dtruss/strace to produce a
complete annotated log of what happens when a client connects, requests a file,
and disconnects. Document every process, file descriptor, and system call
involved.

---

## Quick Reference

| Topic       | Key Commands                                 |
| ----------- | -------------------------------------------- |
| Processes   | `ps aux`, `top`, `pstree`, `kill`, `wait`    |
| Memory      | `vm_stat`, `vmstat`, `ps -o rss`, `free -h`  |
| Files       | `ls -i`, `stat`, `lsof`, `file`, `/dev/fd`   |
| I/O         | `dd`, `select`, `lsof -i`, `iostat`          |
| Scheduling  | `nice`, `renice`, `top -o cpu`, `taskset`    |
| Concurrency | `ps -M` (threads), `ps -T`, `htop`           |
| Syscalls    | `dtruss` (macOS), `strace` (Linux), `dtrace` |
| Network     | `lsof -i`, `netstat`, `ss`, `tcpdump`        |

## See Also

- [Unix Commands](../how/unix.md) -- Shell tools used throughout these lessons
- [Complexity](../why/complexity.md) -- Why OS abstractions exist and when they
  leak
