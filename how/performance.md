# Performance Profiling Cheat Sheet

Commands and tools for measuring, profiling, and optimizing performance.

## Python Profiling

### cProfile

```bash
# Profile a script
python -m cProfile script.py

# Sort by cumulative time
python -m cProfile -s cumulative script.py

# Sort by total time spent in each function
python -m cProfile -s tottime script.py

# Save profile data for analysis
python -m cProfile -o profile.prof script.py

# Visualize with snakeviz (install: pip install snakeviz)
snakeviz profile.prof
```

```python
# Profile a specific section
import cProfile
import pstats

profiler = cProfile.Profile()
profiler.enable()
do_work()
profiler.disable()

stats = pstats.Stats(profiler)
stats.sort_stats("cumulative")
stats.print_stats(20)  # Top 20 functions
```

### line_profiler

Profile line-by-line within a function.

```python
# Decorate the function you want to profile
@profile
def process_data(items):
    result = []
    for item in items:
        transformed = expensive_transform(item)
        result.append(transformed)
    return result
```

```bash
# Run with kernprof (install: pip install line_profiler)
kernprof -l -v script.py

# -l  line-by-line mode
# -v  print results immediately
```

Output shows time per line, hits, and percentage -- tells you exactly which line
is slow.

### memory_profiler

```python
from memory_profiler import profile

@profile
def load_data():
    data = [x ** 2 for x in range(10_000_000)]
    filtered = [x for x in data if x % 2 == 0]
    return filtered
```

```bash
# Install
pip install memory_profiler

# Run and see line-by-line memory usage
python -m memory_profiler script.py

# Track memory over time
mprof run script.py
mprof plot                    # Opens matplotlib graph
mprof clean                   # Remove data files
```

### py-spy

Sampling profiler -- attaches without modifying code or restarting.

```bash
# Install
pip install py-spy

# Live top-like view of a running process
py-spy top --pid 12345

# Record a flame graph
py-spy record -o profile.svg -- python script.py

# Attach to running process and record
py-spy record -o profile.svg --pid 12345

# Include subprocesses
py-spy record --subprocesses -o profile.svg -- python script.py

# Record in speedscope format (interactive viewer)
py-spy record -f speedscope -o profile.json -- python script.py

# Sample at higher frequency (default 100 Hz)
py-spy record --rate 250 -o profile.svg -- python script.py
```

### timeit

```bash
# Command line
python -m timeit "sum(range(1000))"
python -m timeit -n 10000 -r 5 "'-'.join(str(i) for i in range(100))"
# -n  number of executions per run
# -r  number of runs (best of r is reported)

# Setup code
python -m timeit -s "import json; d={'a':1}" "json.dumps(d)"
```

```python
import timeit

# Time a statement
elapsed = timeit.timeit("sum(range(1000))", number=10000)

# Time with setup
elapsed = timeit.timeit(
    "json.dumps(d)",
    setup="import json; d={'a': 1, 'b': [1,2,3]}",
    number=100000,
)

# In IPython / Jupyter
# %timeit sum(range(1000))
# %%timeit  (cell magic for multi-line)
```

## Database Profiling (PostgreSQL)

### EXPLAIN ANALYZE

```sql
-- Show actual execution plan with timing
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'alice@example.com';

-- Include buffer/IO statistics
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM users WHERE email = 'alice@example.com';

-- JSON format for programmatic analysis
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT * FROM orders WHERE user_id = 42;

-- Verbose mode shows column output details
EXPLAIN (ANALYZE, VERBOSE) SELECT * FROM users JOIN orders ON users.id = orders.user_id;
```

### Reading Query Plans

| Node type       | Meaning                                         |
| --------------- | ----------------------------------------------- |
| Seq Scan        | Full table scan -- may need an index            |
| Index Scan      | Uses index to find rows, then fetches from heap |
| Index Only Scan | Satisfied entirely from index (best case)       |
| Bitmap Scan     | Index builds bitmap, then fetches in bulk       |
| Nested Loop     | Join via loop -- fast for small outer set       |
| Hash Join       | Builds hash of one table -- good for equality   |
| Merge Join      | Presorted merge -- good for large sorted sets   |
| Sort            | In-memory or on-disk sort                       |
| Materialize     | Caches subquery results                         |

### Key Metrics

```text
Seq Scan on users  (cost=0.00..431.00 rows=1 width=72) (actual time=3.214..3.216 rows=1 loops=1)
                    ^^^^                                        ^^^^^         ^^^^        ^^^^^
                    estimated cost                              first row     actual rows iterations
  Buffers: shared hit=217 read=14
                   ^^^         ^^
                   cache hits  disk reads
Planning Time: 0.085 ms
Execution Time: 3.271 ms
```

- **actual time**: first row..last row in milliseconds
- **rows**: actual rows returned (compare to estimated `rows`)
- **loops**: how many times this node executed
- **Buffers shared hit**: pages found in cache
- **Buffers shared read**: pages read from disk

### pg_stat_statements

```sql
-- Enable (add to postgresql.conf or ALTER SYSTEM)
-- shared_preload_libraries = 'pg_stat_statements'
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Top queries by total time
SELECT query, calls, total_exec_time, mean_exec_time, rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Top queries by mean time (slowest on average)
SELECT query, calls, mean_exec_time, stddev_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Reset stats
SELECT pg_stat_statements_reset();
```

### Common Slow Patterns

| Pattern             | Symptom                                 | Fix                                            |
| ------------------- | --------------------------------------- | ---------------------------------------------- |
| Missing index       | Seq Scan on large table                 | `CREATE INDEX` on filter/join columns          |
| N+1 queries         | Thousands of identical simple queries   | Use JOIN or batch fetch                        |
| Large sort on disk  | Sort Method: external merge             | Add index matching ORDER BY, increase work_mem |
| Bloated table       | Seq Scan reads far more pages than rows | `VACUUM FULL` or pg_repack                     |
| Correlated subquery | Nested Loop with high loops count       | Rewrite as JOIN or lateral                     |
| Missing statistics  | Row estimates wildly wrong              | `ANALYZE tablename`                            |

## System Profiling

### time

```bash
# Bash builtin -- wall/user/sys
time python script.py

# /usr/bin/time with memory and detail (macOS)
/usr/bin/time -l python script.py
#   real/user/sys + max RSS, page faults, context switches

# /usr/bin/time with memory and detail (Linux)
/usr/bin/time -v python script.py
```

| Metric           | Meaning                                   |
| ---------------- | ----------------------------------------- |
| real (wall)      | Elapsed clock time                        |
| user             | CPU time in user space                    |
| sys              | CPU time in kernel space                  |
| user + sys       | Total CPU time (> real means parallelism) |
| real >> user+sys | Process is I/O bound or waiting on locks  |
| max RSS          | Peak memory usage                         |

### Process Monitoring

```bash
# top -- built-in, press 'o' to sort by cpu/mem/pid
top

# htop -- interactive, tree view, filter by user/process
htop
htop -p 12345                   # Monitor specific PID

# macOS Activity Monitor from CLI
open -a "Activity Monitor"

# ps snapshots
ps aux --sort=-%mem | head -20  # Top memory consumers (Linux)
ps aux -m | head -20            # Top memory consumers (macOS)
ps aux -r | head -20            # Top CPU consumers (macOS)
```

### macOS Instruments

```bash
# List available templates
instruments -s templates

# Time Profiler -- CPU sampling
xcrun xctrace record --template "Time Profiler" --launch -- ./myprogram

# Allocations -- memory tracking
xcrun xctrace record --template "Allocations" --launch -- ./myprogram

# Attach to running process
xcrun xctrace record --template "Time Profiler" --attach 12345

# Open result in Instruments.app
open recording.trace
```

### perf (Linux)

```bash
# Count hardware events (cycles, instructions, cache misses)
perf stat ./myprogram

# Record samples for analysis
perf record -g ./myprogram      # -g captures call graphs
perf report                     # Interactive TUI

# Record at specific frequency
perf record -F 99 -g ./myprogram

# Record a running process
perf record -g -p 12345 -- sleep 30

# Flame graph pipeline
perf record -F 99 -g ./myprogram
perf script | stackcollapse-perf.pl | flamegraph.pl > perf.svg
```

### System-Level Bottleneck Identification

```bash
# vmstat -- CPU, memory, swap, I/O overview (Linux)
vmstat 1 10                     # 1-second interval, 10 samples

# iostat -- disk I/O statistics
iostat -x 1 5                   # Extended stats, 1-sec interval (Linux)
iostat -d 1 5                   # Disk stats (macOS)

# macOS equivalents
vm_stat                         # Memory page statistics
fs_usage -w -f filesys          # Real-time filesystem activity (needs sudo)

# Network
nettop                          # macOS -- live network usage per process
iftop                           # Linux -- live bandwidth per connection
ss -s                           # Linux -- socket statistics summary
```

## Benchmarking

### hyperfine

```bash
# Install
brew install hyperfine           # macOS
cargo install hyperfine          # From source

# Basic comparison
hyperfine 'fd . /tmp' 'find /tmp'

# With warmup runs (prime caches)
hyperfine --warmup 3 'command_a' 'command_b'

# Parameter scan
hyperfine --parameter-scan threads 1 8 'myprogram --threads {threads}'

# Export results as markdown table
hyperfine --export-markdown bench.md 'command_a' 'command_b'

# Export as JSON for further analysis
hyperfine --export-json bench.json 'command_a' 'command_b'

# Set minimum number of runs
hyperfine --min-runs 20 'mycommand'

# Preparation command (runs before each timing run)
hyperfine --prepare 'sync; echo 3 | sudo tee /proc/sys/vm/drop_caches' 'cat largefile'
```

### Python Benchmarking

```bash
# pytest-benchmark (install: pip install pytest-benchmark)
pytest --benchmark-only
pytest --benchmark-compare
pytest --benchmark-save=baseline
```

```python
# pytest-benchmark fixture
def test_sort_performance(benchmark):
    data = list(range(10000, 0, -1))
    result = benchmark(sorted, data)
    assert result == sorted(data)

# With setup
def test_with_setup(benchmark):
    def setup():
        return (list(range(10000)),), {}
    benchmark.pedantic(sorted, setup=setup, rounds=100)
```

### Go Benchmarking

```go
// In _test.go file
func BenchmarkFib(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Fib(20)
    }
}

// Benchmark with allocation tracking
func BenchmarkParse(b *testing.B) {
    b.ReportAllocs()
    for i := 0; i < b.N; i++ {
        Parse(input)
    }
}
```

```bash
# Run benchmarks
go test -bench=.
go test -bench=BenchmarkFib
go test -bench=. -benchmem          # Include allocation stats
go test -bench=. -count=5           # Run 5 times for statistical significance
go test -bench=. -benchtime=5s      # Run for 5 seconds

# Compare results with benchstat
go test -bench=. -count=10 > old.txt
# (make changes)
go test -bench=. -count=10 > new.txt
benchstat old.txt new.txt
```

### Rust Benchmarking

```bash
# Built-in (nightly only)
cargo +nightly bench

# Criterion (stable Rust, statistical rigor)
cargo bench                        # With criterion in Cargo.toml
```

```rust
// Criterion benchmark (benches/my_benchmark.rs)
use criterion::{criterion_group, criterion_main, Criterion};

fn fibonacci(n: u64) -> u64 {
    match n {
        0 | 1 => n,
        _ => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

fn bench_fib(c: &mut Criterion) {
    c.bench_function("fib 20", |b| b.iter(|| fibonacci(20)));
}

criterion_group!(benches, bench_fib);
criterion_main!(benches);
```

## Flame Graphs

### How to Read

```text
          +---------+
          | child_b |      Width = proportion of total time
     +----+---------+----+
     |     parent_fn     |  Y-axis = stack depth (bottom = entry point)
+----+-------------------+----+
|          main               |  X-axis = alphabetical (NOT time order)
+-----------------------------+
```

- **Wide frames** are where time is spent -- the hot path
- **Tall stacks** show deep call chains
- Look for wide frames near the top -- those are leaf functions consuming CPU
- Narrow frames at the bottom are just call chain overhead

### Generating Flame Graphs

```bash
# Python (py-spy)
py-spy record --format flamegraph -o profile.svg -- python script.py

# Linux (perf + Brendan Gregg's tools)
perf record -F 99 -g -- ./myprogram
perf script | stackcollapse-perf.pl | flamegraph.pl > flame.svg

# Go (built-in pprof)
go tool pprof -http=:8080 cpu.prof   # Opens interactive web UI with flame graph

# Node.js
node --prof script.js
node --prof-process isolate-*.log > processed.txt
# Or use 0x: npx 0x script.js
```

### Differential Flame Graphs

Compare before/after to see what changed.

```bash
# Generate two profiles
perf record -F 99 -g -o before.data -- ./program_v1
perf record -F 99 -g -o after.data -- ./program_v2

# Create differential flame graph
perf script -i before.data | stackcollapse-perf.pl > before.folded
perf script -i after.data | stackcollapse-perf.pl > after.folded
difffolded.pl before.folded after.folded | flamegraph.pl > diff.svg
```

Red = regression (more time), blue = improvement (less time).

## Load Testing

### wrk

```bash
# Install
brew install wrk

# Basic load test (10 threads, 200 connections, 30 seconds)
wrk -t10 -c200 -d30s http://localhost:8080/api/users

# With custom headers
wrk -t4 -c100 -d30s -H "Authorization: Bearer TOKEN" http://localhost:8080/api

# With Lua script for POST requests
wrk -t4 -c100 -d30s -s post.lua http://localhost:8080/api
```

```lua
-- post.lua
wrk.method = "POST"
wrk.headers["Content-Type"] = "application/json"
wrk.body = '{"name": "test"}'
```

Reading wrk output: focus on **Req/Sec** (throughput), **Latency** (avg and
stdev), and the **percentile distribution** (p50, p99).

### hey

```bash
# Install
brew install hey

# 200 requests, 50 concurrent
hey -n 200 -c 50 http://localhost:8080/

# 30 seconds of load
hey -z 30s -c 50 http://localhost:8080/

# POST with body
hey -m POST -d '{"key":"value"}' -T "application/json" http://localhost:8080/api
```

### ab (Apache Bench)

```bash
# 1000 requests, 10 concurrent
ab -n 1000 -c 10 http://localhost:8080/

# POST with file body
ab -n 1000 -c 10 -p payload.json -T "application/json" http://localhost:8080/api

# Keep-alive connections
ab -n 1000 -c 10 -k http://localhost:8080/
```

### k6

```bash
# Install
brew install k6
```

```javascript
// load-test.js
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "30s", target: 20 }, // Ramp up to 20 users
    { duration: "1m", target: 20 }, // Hold at 20
    { duration: "10s", target: 0 }, // Ramp down
  ],
};

export default function () {
  const res = http.get("http://localhost:8080/api/users");
  check(res, {
    "status is 200": (r) => r.status === 200,
    "latency < 500ms": (r) => r.timings.duration < 500,
  });
  sleep(1);
}
```

```bash
k6 run load-test.js
k6 run --vus 50 --duration 60s load-test.js    # Override from CLI
```

## Optimization Heuristics

### First Principles

1. **Profile before optimizing** -- measure, do not guess
2. **Amdahl's law** -- if 5% of runtime is in the hot path, a 10x speedup there
   yields only 1.05x overall
3. **The 80/20 rule** -- find the hot path first; most time is spent in a small
   fraction of code
4. **Premature optimization is the root of all evil** -- but mature optimization
   requires data

### Bottleneck Diagnosis

| Bottleneck type | How to identify                        | Common fix                                    |
| --------------- | -------------------------------------- | --------------------------------------------- |
| CPU-bound       | `user` time >> `real` time, high CPU % | Algorithm change, caching, parallelism        |
| I/O-bound       | `real` >> `user+sys`, low CPU %        | Async I/O, batching, caching, connection pool |
| Memory-bound    | High RSS, swapping, GC pauses          | Reduce allocations, streaming, object pools   |
| Lock contention | High `sys` time, threads waiting       | Reduce critical section, lock-free structures |
| Network-bound   | High latency, low throughput           | Connection reuse, compression, CDN            |
| Query-bound     | Slow SQL, high database wait time      | Index, query rewrite, denormalization         |

### Optimization Checklist

```text
1. Establish a baseline (measure current performance)
2. Set a target (what does "fast enough" mean?)
3. Profile to find the bottleneck
4. Fix the bottleneck (one change at a time)
5. Measure again (did it help? by how much?)
6. Repeat until target is met
```

## Quick Reference

| I need to measure...            | Tool               | Command                                                 |
| ------------------------------- | ------------------ | ------------------------------------------------------- |
| Python function time            | cProfile           | `python -m cProfile -s cumulative script.py`            |
| Python line-by-line time        | line_profiler      | `kernprof -l -v script.py`                              |
| Python memory per line          | memory_profiler    | `python -m memory_profiler script.py`                   |
| Python process (no code change) | py-spy             | `py-spy top --pid PID`                                  |
| Wall/user/sys time              | time               | `time command` or `/usr/bin/time -l command`            |
| SQL query performance           | EXPLAIN ANALYZE    | `EXPLAIN (ANALYZE, BUFFERS) SELECT ...`                 |
| Slowest SQL queries             | pg_stat_statements | `SELECT query, mean_exec_time FROM pg_stat_statements`  |
| CLI command comparison          | hyperfine          | `hyperfine 'cmd_a' 'cmd_b'`                             |
| Go function benchmark           | go test            | `go test -bench=. -benchmem`                            |
| Rust function benchmark         | criterion          | `cargo bench`                                           |
| HTTP endpoint throughput        | wrk                | `wrk -t4 -c100 -d30s URL`                               |
| HTTP endpoint latency           | hey                | `hey -n 1000 -c 50 URL`                                 |
| CPU flame graph (Python)        | py-spy             | `py-spy record -o flame.svg -- python script.py`        |
| CPU flame graph (Linux)         | perf               | `perf record -g ./prog && perf script \| flamegraph.pl` |
| System CPU/memory overview      | htop               | `htop`                                                  |
| Disk I/O bottleneck             | iostat             | `iostat -x 1 5`                                         |
| macOS filesystem activity       | fs_usage           | `sudo fs_usage -w -f filesys`                           |
| Load test with scenarios        | k6                 | `k6 run load-test.js`                                   |

## See Also

- [Debugging Tools](debugging.md) -- pdb, lldb, system call tracing
- [Debugging Principles](../why/debugging.md) -- Scientific method for
  performance issues
- [PostgreSQL](postgres.md) -- Database-specific commands
- [Python](python.md) -- Python-specific patterns
- [Testing](testing.md) -- Benchmark test patterns
