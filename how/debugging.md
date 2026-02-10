# Debugging Tools Cheat Sheet

Commands, flags, and workflows for debugging, profiling, and performance
analysis.

## Python Debugging

### pdb / breakpoint()

```python
# Drop into debugger at this line (Python 3.7+)
breakpoint()

# Older equivalent
import pdb; pdb.set_trace()

# Post-mortem: debug after an unhandled exception
import pdb; pdb.pm()
```

```bash
# Run script under pdb from the start
python -m pdb script.py

# Post-mortem on crash (drops into pdb on exception)
python -m pdb -c continue script.py
```

### pdb Commands

| Command        | Short  | Effect                                  |
| -------------- | ------ | --------------------------------------- |
| `next`         | `n`    | Execute next line (step over)           |
| `step`         | `s`    | Step into function call                 |
| `continue`     | `c`    | Continue until next breakpoint          |
| `return`       | `r`    | Continue until current function returns |
| `break N`      | `b N`  | Set breakpoint at line N                |
| `break fn`     | `b fn` | Set breakpoint at function              |
| `tbreak N`     |        | Temporary breakpoint (fires once)       |
| `clear N`      | `cl N` | Clear breakpoint number N               |
| `list`         | `l`    | Show source around current line         |
| `longlist`     | `ll`   | Show full source of current function    |
| `print expr`   | `p`    | Evaluate and print expression           |
| `pp expr`      |        | Pretty-print expression                 |
| `display expr` |        | Watch expression (print on change)      |
| `undisplay`    |        | Remove watched expression               |
| `where`        | `w`    | Print stack trace                       |
| `up`           | `u`    | Move up one stack frame                 |
| `down`         | `d`    | Move down one stack frame               |
| `quit`         | `q`    | Exit debugger                           |

### Conditional Breakpoints

```text
(Pdb) b 42, x > 100        # Break at line 42 only when x > 100
(Pdb) b utils.py:10, len(items) == 0
```

### ipdb and pudb

```bash
# ipdb — pdb with IPython features (tab completion, syntax highlighting)
pip install ipdb
python -m ipdb script.py
```

```python
# Use ipdb as the default breakpoint handler
import os
os.environ["PYTHONBREAKPOINT"] = "ipdb.set_trace"
breakpoint()  # Now opens ipdb
```

```bash
# pudb — full TUI debugger with variable inspector
pip install pudb
python -m pudb script.py
```

## System-Level Debugging

### strace (Linux)

```bash
# Trace all system calls
strace ./program

# Trace specific syscall categories
strace -e trace=network ./program
strace -e trace=file ./program
strace -e trace=open,read,write ./program

# Attach to running process
strace -p 1234

# Count syscalls and show summary
strace -c ./program

# Write output to file (stderr is normal output)
strace -o trace.log ./program

# Timestamp each syscall
strace -t ./program          # Wall clock
strace -T ./program          # Time spent in each call
```

### dtruss (macOS)

```bash
# macOS equivalent of strace (requires SIP adjustments)
sudo dtruss ./program

# Trace running process
sudo dtruss -p 1234

# Trace specific syscalls
sudo dtruss -f -t open ./program
```

### DTrace One-Liners (macOS)

```bash
# Count syscalls by process name
sudo dtrace -n 'syscall:::entry { @[execname] = count(); }'

# Trace file opens by a specific process
sudo dtrace -n 'syscall::open*:entry /execname == "python3"/ {
  printf("%s", copyinstr(arg0));
}'

# Profile user-space stacks at 99 Hz
sudo dtrace -n 'profile-99 /pid == 1234/ {
  @[ustack()] = count();
}'
```

### lldb (macOS Default)

```bash
# Launch program under debugger
lldb ./program
lldb -- ./program --flag arg

# Attach to running process
lldb -p 1234
lldb -n process_name
```

```text
(lldb) breakpoint set -f main.c -l 42    # Break at file:line
(lldb) b main                             # Break at function
(lldb) br list                            # List breakpoints
(lldb) run                                # Start execution
(lldb) next                               # Step over
(lldb) step                               # Step into
(lldb) continue                           # Continue
(lldb) bt                                 # Backtrace
(lldb) frame variable                     # Show local variables
(lldb) p expression                       # Evaluate expression
(lldb) memory read 0x1000                 # Examine memory
(lldb) register read                      # Show registers
(lldb) watchpoint set variable x          # Break on write to x
(lldb) quit
```

### gdb (Linux Default)

```text
(gdb) break main.c:42          # Set breakpoint
(gdb) run                       # Start program
(gdb) next / step / continue    # Navigation
(gdb) bt                        # Backtrace
(gdb) info locals               # Show local variables
(gdb) print expr                # Evaluate expression
(gdb) watch variable            # Watchpoint
(gdb) x/16xw 0x1000            # Examine 16 words at address
```

### lldb vs gdb Quick Map

| Task            | lldb                        | gdb           |
| --------------- | --------------------------- | ------------- |
| Set breakpoint  | `b main`                    | `break main`  |
| Run             | `run`                       | `run`         |
| Backtrace       | `bt`                        | `bt`          |
| Print variable  | `p var`                     | `print var`   |
| Local variables | `frame variable`            | `info locals` |
| Examine memory  | `memory read addr`          | `x addr`      |
| Watch variable  | `watchpoint set variable x` | `watch x`     |
| Attach to PID   | `process attach -p 1234`    | `attach 1234` |

## Profiling

### py-spy (Python)

```bash
# Install
pip install py-spy

# Live top-like view of a running process
py-spy top --pid 1234

# Record a flame graph (SVG output)
py-spy record -o flame.svg --pid 1234
py-spy record -o flame.svg -- python script.py

# Record with specific format
py-spy record --format flamegraph -o flame.svg -- python script.py
py-spy record --format speedscope -o profile.json -- python script.py

# Sample rate (default 100 Hz)
py-spy record --rate 250 -o flame.svg --pid 1234

# Include native C extensions
py-spy record --native -o flame.svg --pid 1234

# Profile subprocess too
py-spy record --subprocesses -o flame.svg -- python script.py
```

### cProfile + snakeviz

```bash
# Run profiler and save stats
python -m cProfile -o profile.prof script.py

# Sort by cumulative time (direct output)
python -m cProfile -s cumtime script.py

# Visualize with snakeviz (opens browser)
pip install snakeviz
snakeviz profile.prof
```

```python
# Profile a specific section
import cProfile
import pstats

with cProfile.Profile() as pr:
    expensive_function()

stats = pstats.Stats(pr)
stats.sort_stats("cumulative")
stats.print_stats(20)  # Top 20 functions
```

### line_profiler

```bash
pip install line_profiler
```

```python
# Decorate functions to profile
@profile
def slow_function():
    total = sum(range(1000000))
    return total
```

```bash
# Run with kernprof
kernprof -l -v script.py
# -l  line-by-line profiling
# -v  show results immediately
```

### memory_profiler

```bash
pip install memory_profiler
```

```python
from memory_profiler import profile

@profile
def memory_hungry():
    a = [1] * 1000000
    b = [2] * 2000000
    del b
    return a
```

```bash
# Run and show line-by-line memory usage
python -m memory_profiler script.py

# Track memory over time (generates plot data)
mprof run script.py
mprof plot  # Opens matplotlib graph
```

## Benchmarking

### hyperfine

```bash
# Basic benchmark
hyperfine 'sleep 0.3'

# Compare two commands
hyperfine 'fd . /tmp' 'find /tmp'

# Warmup runs (prime caches)
hyperfine --warmup 3 'command'

# Exact number of runs
hyperfine --runs 50 'command'

# Parameter sweep
hyperfine --parameter-scan threads 1 8 \
  'sort --parallel={threads} data.txt'

# Parameter list
hyperfine --parameter-list lang python3,ruby,node \
  '{lang} fib.py'

# Export results
hyperfine --export-json results.json 'command'
hyperfine --export-markdown results.md 'command'

# Preparation command (run before each timing)
hyperfine --prepare 'sync; echo 3 | sudo tee /proc/sys/vm/drop_caches' \
  'cat largefile'

# Show output of command
hyperfine --show-output 'echo hello'
```

### time

```bash
# Bash builtin (real/user/sys)
time sleep 1

# More detailed: /usr/bin/time
/usr/bin/time -l ./program          # macOS: includes memory stats
/usr/bin/time -v ./program          # Linux: verbose resource usage

# GNU time output format
/usr/bin/time -f "%e real, %U user, %S sys, %M maxRSS(KB)" ./program
```

### Python timeit

```bash
# From command line
python -m timeit 'sum(range(1000))'
python -m timeit -n 10000 -r 5 'sum(range(1000))'
# -n  number of executions per run
# -r  number of runs (best of r is reported)
```

```python
import timeit

# Time a statement
elapsed = timeit.timeit('sum(range(1000))', number=10000)

# Time with setup
elapsed = timeit.timeit(
    'sorted(data)',
    setup='import random; data = random.sample(range(10000), 1000)',
    number=1000
)
```

## Flame Graphs

### How to Read Them

```text
width  = time spent (wider = more time)
depth  = call stack (bottom = entry point, top = leaf function)
color  = arbitrary (usually random or by category)

Look for:
  - Wide bars at top → hot functions (optimize these)
  - Tall narrow towers → deep call stacks (check recursion)
  - Plateaus → single function dominating runtime
```

### Generate with py-spy (Python)

```bash
py-spy record --format flamegraph -o flame.svg -- python script.py
# Open flame.svg in a browser (interactive: click to zoom)
```

### Generate with perf (Linux)

```bash
# Record CPU profile
perf record -g ./program

# Convert to flame graph (Brendan Gregg's scripts)
perf script | stackcollapse-perf.pl | flamegraph.pl > flame.svg
```

### Instruments.app (macOS)

```bash
# Profile from command line using xctrace
xcrun xctrace record --template 'Time Profiler' \
  --launch ./program --output profile.trace

# Open in Instruments GUI
open profile.trace
```

Instruments provides a native flame graph ("Call Tree" view inverted) plus
memory allocations, disk I/O, and energy impact profilers.

## Network Debugging

### tcpdump

```bash
# Capture all traffic on default interface
sudo tcpdump

# Specific interface and port
sudo tcpdump -i en0 port 443

# Filter by host
sudo tcpdump host 192.168.1.1

# Show packet contents in ASCII
sudo tcpdump -A port 80

# Save to file for Wireshark analysis
sudo tcpdump -w capture.pcap

# Read saved capture
tcpdump -r capture.pcap

# Common filters
sudo tcpdump 'tcp port 80 and host example.com'
sudo tcpdump 'udp and port 53'        # DNS only
sudo tcpdump -n 'icmp'                # Ping/ICMP only
```

### curl Verbose Mode

```bash
# Show request/response headers
curl -v https://example.com

# Full trace (hex + ASCII)
curl --trace trace.log https://example.com
curl --trace-ascii trace.log https://example.com

# Show only timing info
curl -o /dev/null -s -w "\
  DNS:        %{time_namelookup}s\n\
  Connect:    %{time_connect}s\n\
  TLS:        %{time_appconnect}s\n\
  TTFB:       %{time_starttransfer}s\n\
  Total:      %{time_total}s\n" \
  https://example.com

# Follow redirects with verbose
curl -vL https://short.url/abc
```

### DNS Debugging

```bash
# nslookup — simple DNS query
nslookup example.com
nslookup -type=MX example.com

# dig — detailed DNS query
dig example.com
dig example.com MX
dig +short example.com          # Just the answer
dig +trace example.com          # Full delegation chain
dig @8.8.8.8 example.com       # Query specific nameserver

# host — concise DNS lookup
host example.com
host -t AAAA example.com       # IPv6 records
```

## Log-Based Debugging

### Python Structured Logging

```python
import logging
import json

# Basic configuration
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s %(levelname)s %(name)s %(message)s"
)
logger = logging.getLogger(__name__)

# Structured output with extra fields
logger.info("Request processed", extra={
    "user_id": 42,
    "duration_ms": 150,
    "status": 200
})
```

```python
# JSON log formatter for machine parsing
class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_entry = {
            "time": self.formatTime(record),
            "level": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
        }
        if hasattr(record, "user_id"):
            log_entry["user_id"] = record.user_id
        return json.dumps(log_entry)
```

### Parsing Logs with grep and jq

```bash
# Filter log lines
grep "ERROR" app.log
grep -i "timeout" app.log
grep -C 3 "Exception" app.log   # 3 lines context

# Count error types
grep -oP 'ERROR: \K[^:]+' app.log | sort | uniq -c | sort -rn

# Parse JSON logs with jq
cat app.log | jq 'select(.level == "ERROR")'
cat app.log | jq 'select(.duration_ms > 1000) | {time, message}'
cat app.log | jq -r '[.time, .level, .message] | @tsv'

# Group errors by message
cat app.log | jq -r 'select(.level == "ERROR") | .message' \
  | sort | uniq -c | sort -rn
```

### Live Log Tailing

```bash
# Follow log file in real time
tail -f app.log

# Follow and filter
tail -f app.log | grep --line-buffered "ERROR"

# Follow multiple files
tail -f *.log

# Follow with highlighting (grep color)
tail -f app.log | grep --line-buffered --color=always -E "ERROR|WARNING|"
# Empty final alternative matches all lines but colors matches
```

## Quick Reference

| I need to...                      | Tool            | Command                                       |
| --------------------------------- | --------------- | --------------------------------------------- |
| Debug Python interactively        | pdb             | `breakpoint()` in code                        |
| Debug with better UI              | pudb            | `python -m pudb script.py`                    |
| Profile Python CPU usage          | py-spy          | `py-spy top --pid 1234`                       |
| Generate a flame graph            | py-spy          | `py-spy record -o flame.svg -- python app.py` |
| Profile function call counts      | cProfile        | `python -m cProfile -s cumtime script.py`     |
| Profile line-by-line              | line_profiler   | `kernprof -l -v script.py`                    |
| Profile memory usage              | memory_profiler | `python -m memory_profiler script.py`         |
| Benchmark shell commands          | hyperfine       | `hyperfine 'cmd1' 'cmd2'`                     |
| Benchmark Python snippets         | timeit          | `python -m timeit 'expr'`                     |
| Trace system calls (Linux)        | strace          | `strace -e trace=file ./program`              |
| Trace system calls (macOS)        | dtruss          | `sudo dtruss ./program`                       |
| Debug native binary (macOS)       | lldb            | `lldb ./program`                              |
| Debug native binary (Linux)       | gdb             | `gdb ./program`                               |
| Capture network traffic           | tcpdump         | `sudo tcpdump -i en0 port 443`                |
| Debug HTTP requests               | curl            | `curl -v https://example.com`                 |
| Debug DNS resolution              | dig             | `dig +trace example.com`                      |
| Find which commit broke something | git bisect      | `git bisect start && git bisect bad`          |
| Watch logs in real time           | tail            | `tail -f app.log \| grep ERROR`               |
| Parse JSON logs                   | jq              | `jq 'select(.level == "ERROR")' app.log`      |

## See Also

- [Debugging Principles](../why/debugging.md) — Scientific method, bisection,
  isolation
- [Testing](testing.md) — Test-driven debugging
- [Shell](shell.md) — Pipe and filter patterns for log analysis
- [Python](python.md) — Python-specific patterns
