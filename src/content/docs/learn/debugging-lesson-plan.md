---
title: "Debugging Lesson Plan"
description:
  Eight lessons from scientific method to system-call tracing, covering
  bisection, isolation, debuggers, profilers, and production diagnosis.
---

A progressive curriculum to find and fix bugs systematically.

<!-- prettier-ignore -->
:::note[Prerequisites]
Comfortable with [Python](../how/python.md) and
[Unix CLI](../how/unix.md). Review
[Debugging Principles](../why/debugging.md) and the
[Debugging Tools Cheat Sheet](../how/debugging.md) for reference.
:::

## Lesson 1: The Scientific Method for Bugs

**Goal:** Replace guessing with a repeatable process: observe, hypothesize,
predict, test.

### Concepts

Most developers debug by staring at code and making random changes. The
scientific method provides structure: observe the actual behavior, form a
hypothesis about the cause, predict what should happen if the hypothesis holds,
then test that prediction. Each failed prediction eliminates a possibility.

### Exercises

1. **Observe the symptom**

   Save this program as `bug1.py`:

   ```python
   def average(numbers):
       total = 0
       for n in numbers:
           total += n
       return total / len(numbers)

   scores = [85, 92, 78, 95, 88]
   print(f"Average: {average(scores)}")
   print(f"Empty average: {average([])}")
   ```

   ```bash
   python3 bug1.py
   ```

   Write down the exact error message before changing anything.

2. **Form a hypothesis**

   The error is `ZeroDivisionError: division by zero`. Hypothesis:
   `len(numbers)` is zero when the list is empty. Predict: if we add a guard for
   empty lists, the error disappears.

3. **Test the prediction**

   ```python
   def average(numbers):
       if not numbers:
           return 0.0
       total = 0
       for n in numbers:
           total += n
       return total / len(numbers)
   ```

   Run again. The prediction holds — the hypothesis was correct.

4. **Practice with a harder bug**

   Save as `bug2.py`:

   ```python
   def find_duplicates(items):
       seen = set()
       duplicates = set()
       for item in items:
           if item in seen:
               duplicates.add(item)
           seen.add(item)
       return duplicates

   data = [1, 2, 3, 2, 4, 3, 5]
   result = find_duplicates(data)
   print(f"Duplicates: {sorted(result)}")  # Expect: [2, 3]

   # But this returns wrong results:
   def find_duplicates_buggy(items):
       seen = []
       duplicates = []
       for item in items:
           if item in seen:
               duplicates.append(item)
       seen.append(item)        # Bug: indentation puts this outside the loop
       return duplicates

   data2 = [1, 2, 3, 2, 4, 3, 5]
   result2 = find_duplicates_buggy(data2)
   print(f"Buggy duplicates: {result2}")  # What does this print?
   ```

   Apply the method: observe output, hypothesize, predict, test. The bug is a
   single indentation error — `seen.append(item)` sits outside the loop.

### Checkpoint

Debug `bug2.py` without reading ahead. Write your hypothesis before making any
code change. Confirm the fix matches your prediction.

---

## Lesson 2: Print Debugging Done Right

**Goal:** Use strategic logging instead of scattershot print statements.

### Concepts

Print debugging works when applied deliberately. Log at function boundaries
(entry/exit), before conditionals, and inside loops. Include variable names and
context in every print statement. Remove prints when done, or better — use the
`logging` module so you can toggle verbosity without editing code.

### Exercises

1. **Find the bug with strategic prints**

   Save as `cart.py`:

   ```python
   def apply_discount(price, discount_percent):
       return price * discount_percent / 100

   def calculate_total(items):
       total = 0
       for name, price, qty in items:
           subtotal = price * qty
           total += subtotal
       return total

   cart = [
       ("Widget", 25.00, 3),
       ("Gadget", 15.50, 2),
   ]

   total = calculate_total(cart)
   discount = apply_discount(total, 10)
   final = total - discount
   print(f"Total: ${final:.2f}")  # Expect: $96.30 (10% off $107.00 = $96.30)
   ```

   ```bash
   python3 cart.py
   # Output: Total: $96.30 — looks correct.
   ```

   Now change the discount to 100%:

   ```python
   discount = apply_discount(total, 100)
   ```

   The result should be $0.00, but it returns the full price. Add prints at each
   step to find where `apply_discount` goes wrong:

   ```python
   def apply_discount(price, discount_percent):
       result = price * discount_percent / 100
       print(f"DEBUG apply_discount: price={price}, "
             f"discount={discount_percent}%, result={result}")
       return result
   ```

   The function returns `price * 100 / 100 = price`. The math is correct — the
   bug is in how the result is used. `total - discount` when discount equals the
   total gives zero. The function is fine; trace the caller.

2. **Graduate to the logging module**

   ```python
   import logging

   logging.basicConfig(
       level=logging.DEBUG,
       format="%(asctime)s %(levelname)s %(message)s"
   )
   logger = logging.getLogger(__name__)

   def apply_discount(price, discount_percent):
       result = price * discount_percent / 100
       logger.debug("apply_discount: price=%.2f discount=%d%% result=%.2f",
                     price, discount_percent, result)
       return result
   ```

   ```bash
   # See debug output:
   python3 cart.py

   # Silence debug output without editing code:
   LOG_LEVEL=WARNING python3 -c "
   import logging, os
   logging.basicConfig(level=getattr(logging, os.environ.get('LOG_LEVEL', 'DEBUG')))
   logging.getLogger().debug('This is hidden')
   logging.getLogger().warning('This is visible')
   "
   ```

3. **Log at strategic points**

   Save as `search.py`:

   ```python
   import logging
   logging.basicConfig(level=logging.DEBUG, format="%(levelname)s %(message)s")
   logger = logging.getLogger(__name__)

   def binary_search(arr, target):
       left, right = 0, len(arr)
       logger.debug("Searching for %d in array of length %d", target, len(arr))
       while left < right:
           mid = (left + right) // 2
           logger.debug("  left=%d mid=%d right=%d arr[mid]=%d",
                         left, mid, right, arr[mid])
           if arr[mid] == target:
               return mid
           elif arr[mid] < target:
               left = mid
           else:
               right = mid
       return -1

   data = list(range(0, 100, 5))
   print(binary_search(data, 35))  # Should find it
   print(binary_search(data, 37))  # Not in array — watch for infinite loop
   ```

   The second call loops forever. The logs reveal `left` never advances past
   `mid`. Fix: `left = mid + 1`.

### Checkpoint

Fix the infinite loop in `search.py` using only the log output to diagnose the
problem. Confirm `binary_search(data, 37)` returns `-1`.

---

## Lesson 3: Binary Search for Bugs

**Goal:** Use bisection to narrow a bug's location in code, data, or history.

### Concepts

Binary search cuts the problem space in half with each test. It applies in three
dimensions: in code (comment out halves), in time (git bisect), and in data
(split input). A bug somewhere in 1,000 lines takes at most 10 bisection steps
to locate.

### Exercises

1. **Bisect in code**

   Save as `pipeline.py`:

   ```python
   def step_1(data):
       return [x.strip() for x in data]

   def step_2(data):
       return [x.lower() for x in data]

   def step_3(data):
       return [x for x in data if x]  # Remove empty strings

   def step_4(data):
       return sorted(data)

   def step_5(data):
       return list(set(data))  # Remove duplicates — but destroys order

   def step_6(data):
       return [x.replace("-", " ") for x in data]

   raw = ["  Apple ", "banana", " Cherry", "apple", "", "  banana ", "date-fruit"]
   result = step_6(step_5(step_4(step_3(step_2(step_1(raw))))))
   print(result)
   # Expected: unique, sorted, cleaned, lowercase, hyphens replaced with spaces
   # Bug: step_5 destroys the sort order from step_4
   ```

   Bisect the pipeline. Print intermediate results after step 3, then after
   step 5. The output after step 4 is sorted; after step 5 it is not. The bug is
   in step 5 — `set()` discards order. Fix by moving `step_5` before `step_4`,
   or use `dict.fromkeys(data)` to deduplicate while preserving order.

2. **Git bisect**

   Create a repo with a deliberate regression:

   ```bash
   mkdir bisect-lab && cd bisect-lab && git init
   echo 'def greet(): return "hello"' > app.py
   git add app.py && git commit -m "Initial: greet works"

   for i in $(seq 2 10); do
     echo "# comment $i" >> app.py
     git commit -am "Commit $i: add comment"
   done

   # Introduce the bug at commit 6-ish
   sed -i '' 's/return "hello"/return "helo"/' app.py  # Typo
   git commit -am "Commit with typo"

   for i in $(seq 12 15); do
     echo "# comment $i" >> app.py
     git commit -am "Commit $i: more work"
   done
   ```

   Now bisect:

   ```bash
   git bisect start
   git bisect bad                    # HEAD is broken
   git bisect good HEAD~14           # First commit was good
   # At each step, test:
   python3 -c "exec(open('app.py').read()); assert greet() == 'hello'"
   # Mark good or bad, repeat until git identifies the culprit
   git bisect reset
   ```

3. **Automated git bisect**

   ```bash
   git bisect start HEAD HEAD~14
   git bisect run python3 -c "exec(open('app.py').read()); assert greet() == 'hello'"
   # Git runs the test automatically and reports the first bad commit
   git bisect reset
   ```

### Checkpoint

Run the automated bisect. Confirm git identifies the exact commit that
introduced the typo.

---

## Lesson 4: Interactive Debuggers

**Goal:** Use pdb to set breakpoints, step through code, and inspect state.

### Concepts

An interactive debugger lets you pause execution, examine variables, step
through code line by line, and evaluate expressions — all without modifying
source files. Python's built-in `pdb` provides these capabilities.
`breakpoint()` (Python 3.7+) drops into the debugger at any point.

### Exercises

1. **Set a breakpoint and explore**

   Save as `inventory.py`:

   ```python
   def restock(inventory, item, quantity):
       if item in inventory:
           inventory[item] += quantity
       else:
           inventory[item] = quantity
       return inventory

   def process_orders(inventory, orders):
       for item, qty in orders:
           if inventory.get(item, 0) >= qty:
               inventory[item] -= qty
           else:
               print(f"Insufficient stock for {item}")
       return inventory

   stock = {"widgets": 100, "gadgets": 50}
   orders = [("widgets", 30), ("gadgets", 60), ("widgets", 80)]

   breakpoint()  # Pause here
   result = process_orders(stock, orders)
   print(result)
   ```

   ```bash
   python3 inventory.py
   ```

   At the `(Pdb)` prompt, practice these commands:

   ```text
   (Pdb) p stock                    # Print variable
   (Pdb) p orders                   # Print orders list
   (Pdb) n                          # Step to next line
   (Pdb) s                          # Step into process_orders
   (Pdb) l                          # List source around current line
   (Pdb) p inventory                # Inspect parameter inside function
   (Pdb) n                          # Step through the loop
   (Pdb) p item, qty                # Check loop variables
   (Pdb) c                          # Continue to end
   ```

2. **Conditional breakpoints**

   Save as `scorer.py`:

   ```python
   def score_entries(entries):
       results = []
       for entry in entries:
           name = entry["name"]
           raw = entry["score"]
           # Bug: crashes when score is a string
           normalized = raw / 100.0
           results.append({"name": name, "normalized": normalized})
       return results

   data = [
       {"name": "Alice", "score": 95},
       {"name": "Bob", "score": 88},
       {"name": "Carol", "score": "seventy"},  # Bad data
       {"name": "Dave", "score": 72},
   ]

   print(score_entries(data))
   ```

   ```bash
   python3 -m pdb scorer.py
   ```

   ```text
   (Pdb) b 7, not isinstance(raw, (int, float))
   (Pdb) c
   # Stops only when raw is not a number
   (Pdb) p entry
   (Pdb) p raw, type(raw)
   ```

   The conditional breakpoint fires on Carol's entry, where `raw` is a string.

3. **Post-mortem debugging**

   ```bash
   python3 -m pdb -c continue scorer.py
   # Crashes on TypeError, then drops into pdb at the crash site
   ```

   ```text
   (Pdb) p raw              # See the bad value
   (Pdb) w                  # Full stack trace
   (Pdb) u                  # Move up to calling frame
   (Pdb) p entries[2]       # Inspect the bad entry
   ```

4. **Use display for watching values**

   ```bash
   python3 -m pdb inventory.py
   ```

   ```text
   (Pdb) b process_orders
   (Pdb) c
   (Pdb) display inventory    # Watch inventory after each step
   (Pdb) n                    # Step — see inventory update automatically
   (Pdb) n
   (Pdb) undisplay inventory
   ```

### Checkpoint

Debug `scorer.py` using post-mortem mode. Identify the bad entry without adding
any print statements. Fix the function to skip non-numeric scores.

---

## Lesson 5: Isolation Techniques

**Goal:** Reduce a complex bug to its minimal reproduction.

### Concepts

A bug in a 10,000-line program is hard to fix. The same bug in 10 lines is
obvious. Isolation means stripping away everything that does not contribute to
the failure: remove unrelated code, replace complex inputs with simple ones,
eliminate external dependencies. Change one variable at a time to identify which
factor causes the failure.

### Exercises

1. **Minimal reproduction**

   Save as `processor.py`:

   ```python
   import json
   import os
   from datetime import datetime

   CONFIG = {"max_retries": 3, "timeout": 30, "debug": False}

   def load_data(path):
       with open(path) as f:
           return json.load(f)

   def validate(record):
       required = ["id", "name", "timestamp"]
       for field in required:
           if field not in record:
               raise ValueError(f"Missing field: {field}")
       return True

   def transform(record):
       record["name"] = record["name"].strip().title()
       record["timestamp"] = datetime.fromisoformat(record["timestamp"])
       record["processed"] = True
       return record

   def process_batch(records):
       results = []
       for r in records:
           validate(r)
           results.append(transform(r))
       return results

   # This crashes:
   data = [
       {"id": 1, "name": "alice", "timestamp": "2024-01-15T10:30:00"},
       {"id": 2, "name": "bob",   "timestamp": "2024-13-01T08:00:00"},
       {"id": 3, "name": "carol", "timestamp": "2024-02-28T14:45:00"},
   ]
   process_batch(data)
   ```

   The bug hides in batch processing. Isolate it:

   ```python
   # Step 1: Which record fails?
   for i, r in enumerate(data):
       try:
           transform(r)
       except Exception as e:
           print(f"Record {i} fails: {e}")

   # Step 2: Minimal reproduction (one line)
   from datetime import datetime
   datetime.fromisoformat("2024-13-01T08:00:00")  # month 13 — invalid
   ```

   The 40-line program reduces to one line: an invalid date string.

2. **Remove variables one at a time**

   Save as `server_sim.py`:

   ```python
   import time
   import random

   def fetch_data(source):
       time.sleep(random.uniform(0.1, 0.5))  # Simulate network
       if source == "db":
           return {"status": "ok", "items": [1, 2, 3]}
       elif source == "cache":
           return {"status": "ok", "items": [1, 2, 3]}
       elif source == "api":
           return {"status": "ok", "Items": [1, 2, 3]}  # Capital I
       return None

   def get_items(source):
       response = fetch_data(source)
       return response["items"]  # KeyError when source is "api"

   # Works:
   print(get_items("db"))
   print(get_items("cache"))
   # Fails:
   print(get_items("api"))
   ```

   The `time.sleep` and `random` are noise — they are not related to the bug.
   The three sources look identical but differ in key casing. Isolation reveals
   the `"Items"` vs `"items"` mismatch.

3. **Environment isolation**

   ```bash
   # Reproduce a bug in a clean environment
   python3 -m venv /tmp/debug-env
   source /tmp/debug-env/bin/activate
   # Install only what the script needs
   # Run the script — does it still fail?
   # If not, the bug is in your environment (wrong package version, config)
   deactivate
   ```

### Checkpoint

Reduce `processor.py` from a batch-processing system to a single line that
reproduces the error. Identify and fix the invalid data.

---

## Lesson 6: System-Level Debugging

**Goal:** Trace system calls to see what a program asks the operating system to
do.

### Concepts

When a program opens files, reads sockets, or allocates memory, it makes system
calls. `strace` (Linux) and `dtruss` (macOS) intercept these calls and show
exactly what the OS sees. This reveals problems invisible to application-level
debugging: missing files, permission errors, DNS failures, and slow I/O.

### Exercises

1. **Trace file operations**

   Save as `reader.py`:

   ```python
   def read_config():
       with open("/tmp/myapp/config.json") as f:
           return f.read()

   try:
       print(read_config())
   except FileNotFoundError as e:
       print(f"Error: {e}")
   ```

   Trace the system calls:

   ```bash
   # Linux:
   strace -e trace=openat python3 reader.py 2>&1 | grep config

   # macOS:
   sudo dtruss -f python3 reader.py 2>&1 | grep config
   ```

   The trace shows the exact `openat` call and the `ENOENT` (file not found)
   error. You see the precise path the program attempted to open.

2. **Trace a DNS lookup**

   ```bash
   # Linux:
   strace -e trace=network python3 -c "
   import urllib.request
   urllib.request.urlopen('http://example.com')
   " 2>&1 | head -30

   # macOS:
   sudo dtruss python3 -c "
   import urllib.request
   urllib.request.urlopen('http://example.com')
   " 2>&1 | grep -E "connect|socket" | head -20
   ```

   Observe the socket creation, DNS resolution, and TCP connect calls.

3. **Count system calls**

   ```bash
   # Linux: summary of syscall frequency and time
   strace -c python3 -c "
   import json
   data = json.dumps({'key': 'value'} )
   parsed = json.loads(data)
   "
   ```

   The summary shows which calls dominate. File I/O–heavy programs spend time in
   `read`/`write`; network programs spend time in `connect`/`recvfrom`.

4. **Trace file descriptor leaks**

   Save as `leak.py`:

   ```python
   import os

   handles = []
   for i in range(20):
       f = open(f"/tmp/leak_test_{i}.txt", "w")
       f.write(f"file {i}")
       handles.append(f)
       # Bug: never closes files

   # Check open file descriptors
   pid = os.getpid()
   print(f"PID: {pid}")
   print(f"Open handles: {len(handles)}")
   ```

   ```bash
   python3 leak.py
   # Check open FDs (Linux):
   # ls -la /proc/<PID>/fd
   # macOS:
   lsof -p $(python3 -c "import os; print(os.getpid())") 2>/dev/null | head -20
   ```

   Fix with context managers: `with open(...) as f:`.

### Checkpoint

Trace `reader.py` with strace or dtruss. Identify the exact system call that
fails and the errno it returns.

---

## Lesson 7: Performance Debugging

**Goal:** Find bottlenecks using profilers, flame graphs, and benchmarks.

### Concepts

Performance bugs do not produce errors — the program runs, but slowly. Profilers
measure where time is spent. Flame graphs visualize call stacks so hot paths
stand out. Never optimize without measuring first: intuition about performance
is unreliable.

### Exercises

1. **Profile with cProfile**

   Save as `slow.py`:

   ```python
   import time

   def fetch_users():
       time.sleep(0.3)
       return [{"id": i, "name": f"User {i}"} for i in range(100)]

   def fetch_orders():
       time.sleep(0.5)
       return [{"user_id": i % 100, "amount": i * 1.5} for i in range(1000)]

   def match_orders(users, orders):
       result = []
       for order in orders:
           for user in users:  # O(n*m) — nested loop
               if user["id"] == order["user_id"]:
                   result.append({**order, "name": user["name"]})
                   break
       return result

   def main():
       users = fetch_users()
       orders = fetch_orders()
       matched = match_orders(users, orders)
       print(f"Matched {len(matched)} orders")

   main()
   ```

   ```bash
   python3 -m cProfile -s cumtime slow.py 2>&1 | head -25
   ```

   Read the output: `match_orders` dominates because of the O(n\*m) nested loop.
   The `time.sleep` calls also show up clearly.

2. **Generate a flame graph with py-spy**

   ```bash
   pip install py-spy

   # Record a flame graph
   py-spy record -o flame.svg -- python3 slow.py
   # Open flame.svg in a browser — look for wide bars
   ```

   The flame graph shows `match_orders` as the widest bar. Fix the O(n\*m) loop
   with a dictionary lookup:

   ```python
   def match_orders_fast(users, orders):
       user_map = {u["id"]: u["name"] for u in users}
       return [{**o, "name": user_map[o["user_id"]]} for o in orders]
   ```

3. **Benchmark with hyperfine**

   Save the slow and fast versions as separate files, then compare:

   ```bash
   hyperfine 'python3 slow.py' 'python3 fast.py'
   ```

   Hyperfine runs each command multiple times and reports mean, min, max, and
   standard deviation.

4. **Line-level profiling**

   ```bash
   pip install line_profiler
   ```

   Add `@profile` to `match_orders` in `slow.py`:

   ```python
   @profile
   def match_orders(users, orders):
       # ... same as before
   ```

   ```bash
   kernprof -l -v slow.py
   ```

   The output shows time per line. The inner loop line dominates.

### Checkpoint

Profile `slow.py`, identify the bottleneck, and implement the dictionary-based
fix. Verify with cProfile that `match_orders_fast` is faster.

---

## Lesson 8: Production Debugging

**Goal:** Diagnose bugs in running systems using logs, metrics, and post-mortem
analysis.

### Concepts

Production debugging differs from local debugging: you cannot attach a debugger
or add print statements to a live server. Instead, you rely on structured logs,
metrics, distributed traces, and core dumps. The goal shifts from "find the
line" to "narrow the blast radius" — which service, which endpoint, which time
window, which user.

### Exercises

1. **Structured logging for production**

   Save as `webapp.py`:

   ```python
   import json
   import logging
   import time
   import uuid

   class JSONFormatter(logging.Formatter):
       def format(self, record):
           entry = {
               "time": self.formatTime(record),
               "level": record.levelname,
               "message": record.getMessage(),
               "logger": record.name,
           }
           for key in ("request_id", "user_id", "duration_ms", "status"):
               if hasattr(record, key):
                   entry[key] = getattr(record, key)
           return json.dumps(entry)

   handler = logging.StreamHandler()
   handler.setFormatter(JSONFormatter())
   logger = logging.getLogger("webapp")
   logger.addHandler(handler)
   logger.setLevel(logging.DEBUG)

   def handle_request(user_id, action):
       request_id = str(uuid.uuid4())[:8]
       start = time.time()
       logger.info("Request started", extra={
           "request_id": request_id, "user_id": user_id
       })
       try:
           if action == "crash":
               raise RuntimeError("Simulated failure")
           time.sleep(0.1)  # Simulate work
           duration = (time.time() - start) * 1000
           logger.info("Request completed", extra={
               "request_id": request_id, "duration_ms": round(duration),
               "status": 200
           })
       except Exception as e:
           duration = (time.time() - start) * 1000
           logger.error("Request failed: %s", e, extra={
               "request_id": request_id, "duration_ms": round(duration),
               "status": 500
           })

   handle_request(42, "read")
   handle_request(99, "crash")
   handle_request(42, "write")
   ```

   ```bash
   python3 webapp.py 2>&1 | python3 -m json.tool --no-ensure-ascii
   ```

   Notice how `request_id` ties related log entries together. In production, you
   filter by request ID to reconstruct a single request's journey.

2. **Parse logs to find patterns**

   Save sample logs to a file:

   ```bash
   python3 webapp.py 2> app.log
   ```

   Query the JSON logs:

   ```bash
   # Find all errors
   cat app.log | python3 -c "
   import sys, json
   for line in sys.stdin:
       entry = json.loads(line)
       if entry['level'] == 'ERROR':
           print(json.dumps(entry, indent=2))
   "

   # If jq is installed (preferred):
   cat app.log | jq 'select(.level == "ERROR")'

   # Count requests by status
   cat app.log | jq -r 'select(.status) | .status' | sort | uniq -c
   ```

3. **Post-mortem with core dumps**

   ```python
   # Save as crash.py
   import traceback
   import json
   from datetime import datetime

   def save_crash_report(exc_type, exc_value, exc_tb):
       report = {
           "time": datetime.now().isoformat(),
           "error": str(exc_value),
           "type": exc_type.__name__,
           "traceback": traceback.format_exception(exc_type, exc_value, exc_tb),
       }
       path = "/tmp/crash_report.json"
       with open(path, "w") as f:
           json.dump(report, f, indent=2)
       print(f"Crash report saved to {path}")

   import sys
   sys.excepthook = save_crash_report

   # Trigger a crash
   def process():
       data = {"users": [1, 2, 3]}
       return data["orders"]  # KeyError

   process()
   ```

   ```bash
   python3 crash.py
   cat /tmp/crash_report.json | python3 -m json.tool
   ```

   In production systems, crash reports feed into error tracking services
   (Sentry, Datadog) that aggregate and deduplicate errors.

4. **Simulate a monitoring dashboard**

   ```python
   # Save as monitor.py
   import time
   import random

   metrics = {"requests": 0, "errors": 0, "total_ms": 0}

   def record_request(success, duration_ms):
       metrics["requests"] += 1
       metrics["total_ms"] += duration_ms
       if not success:
           metrics["errors"] += 1

   def report():
       total = metrics["requests"]
       if total == 0:
           return
       error_rate = metrics["errors"] / total * 100
       avg_latency = metrics["total_ms"] / total
       print(f"Requests: {total} | Error rate: {error_rate:.1f}% | "
             f"Avg latency: {avg_latency:.0f}ms")

   # Simulate traffic
   for _ in range(50):
       success = random.random() > 0.1
       latency = random.gauss(100, 30) if success else random.gauss(500, 100)
       record_request(success, max(0, latency))

   report()
   ```

   ```bash
   python3 monitor.py
   ```

   Key production metrics: error rate, latency percentiles (p50, p95, p99), and
   throughput. A spike in any signals a problem worth investigating.

### Checkpoint

Run `webapp.py`, pipe output through jq, and filter for errors. Extract the
request ID from the error entry and find all log lines for that request.

---

## Practice Projects

### Project 1: Bug Jar

Create a directory of 10 Python scripts, each containing a different category of
bug (off-by-one, type error, race condition, missing import, wrong operator,
infinite loop, mutation of shared state, encoding error, silent failure, wrong
default). Practice debugging each using the appropriate technique from lessons
1–5.

### Project 2: Profiling Challenge

Write a deliberately slow data-processing pipeline (CSV parsing, filtering,
aggregation) that takes 10+ seconds. Use cProfile, py-spy, and line_profiler to
identify the three worst bottlenecks. Optimize each and document the
before/after measurements.

### Project 3: Production Simulation

Build a multi-file Python application with structured JSON logging, a crash
reporter, and a metrics collector. Inject three bugs at different layers (data
validation, business logic, I/O). Use only logs and metrics to find each bug
without reading the source code.

---

## Command Reference

| Stage          | Must Know                                               |
| -------------- | ------------------------------------------------------- |
| Print debug    | `print(f"DEBUG: {var=}")` `logging.debug()`             |
| Debugger       | `breakpoint()` `n` `s` `c` `p` `w` `b` `display`        |
| Bisection      | `git bisect start` `git bisect run`                     |
| System tracing | `strace -e trace=file` `dtruss` `lsof`                  |
| Profiling      | `cProfile` `py-spy record` `kernprof` `hyperfine`       |
| Production     | structured logging, JSON formatter, `jq`, crash reports |

## See Also

- [Debugging Principles](../why/debugging.md) — Scientific method, bisection,
  isolation
- [Debugging Tools](../how/debugging.md) — pdb, strace, py-spy command reference
- [Performance Profiling](../how/performance.md) — Benchmarking and flame graphs
- [Problem Solving](../why/problem-solving.md) — Polya's method,
  divide-and-conquer
