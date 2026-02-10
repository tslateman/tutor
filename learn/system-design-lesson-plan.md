# System Design Lesson Plan

How to think about building systems that handle real traffic -- from one server
to many, and all the tradeoffs along the way.

## Lesson 1: Single-Server Foundations

**Goal:** Understand what one machine can handle and learn to measure its limits
before reaching for distributed solutions.

### Concepts

Every system starts on one server. Before you distribute anything, know what one
box can do -- CPU cores, memory, disk I/O, network bandwidth, and file
descriptor limits. Back-of-envelope estimation is the most important system
design skill: if you need 100 requests/sec and one server handles 1,000, you
don't need a load balancer yet. Measure first, scale second.

### Exercises

1. **Check your machine's limits**

   ```bash
   # File descriptor limit (max open connections)
   ulimit -n

   # CPU cores available
   sysctl -n hw.ncpu

   # Total memory
   sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 " GB"}'

   # Current resource usage
   top -l 1 -n 0 | head -10
   ```

2. **Build a minimal HTTP server and load test it**

   ```python
   # server.py
   from http.server import HTTPServer, BaseHTTPRequestHandler
   import json, time

   class Handler(BaseHTTPRequestHandler):
       def do_GET(self):
           # Simulate a small computation
           data = {"status": "ok", "timestamp": time.time()}
           body = json.dumps(data).encode()
           self.send_response(200)
           self.send_header("Content-Type", "application/json")
           self.send_header("Content-Length", str(len(body)))
           self.end_headers()
           self.wfile.write(body)

       def log_message(self, format, *args):
           pass  # Suppress per-request logging

   if __name__ == "__main__":
       server = HTTPServer(("127.0.0.1", 8080), Handler)
       print("Serving on http://127.0.0.1:8080")
       server.serve_forever()
   ```

   ```bash
   python3 server.py &

   # Load test with ab (Apache Bench, pre-installed on macOS)
   ab -n 1000 -c 10 http://127.0.0.1:8080/
   # Note: Requests per second, Time per request, Failed requests

   kill %1
   ```

3. **Back-of-envelope estimation**

   ```text
   Scenario: Photo sharing app, 10M users, 10% daily active

   Daily active users:       1,000,000
   Uploads per user per day: 2
   Total uploads per day:    2,000,000
   Uploads per second:       2,000,000 / 86,400 ≈ 23/sec

   Average photo size:       2 MB
   Daily storage:            2,000,000 × 2 MB = 4 TB/day
   Annual storage:           4 TB × 365 ≈ 1.5 PB

   Read:write ratio:         10:1 (people view more than they post)
   Reads per second:         230/sec

   Question: Can one server handle 23 writes/sec and 230 reads/sec?
   With SSDs at ~10,000 IOPS -- yes, if each operation is one I/O.
   ```

4. **Compare threaded vs single-process capacity**

   ```python
   # threaded_server.py
   from http.server import HTTPServer, BaseHTTPRequestHandler
   from socketserver import ThreadingMixIn
   import json, time

   class Handler(BaseHTTPRequestHandler):
       def do_GET(self):
           time.sleep(0.01)  # Simulate 10ms of work
           data = {"status": "ok"}
           body = json.dumps(data).encode()
           self.send_response(200)
           self.send_header("Content-Type", "application/json")
           self.send_header("Content-Length", str(len(body)))
           self.end_headers()
           self.wfile.write(body)

       def log_message(self, format, *args):
           pass

   class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
       pass

   if __name__ == "__main__":
       server = ThreadedHTTPServer(("127.0.0.1", 8080), Handler)
       print("Threaded server on http://127.0.0.1:8080")
       server.serve_forever()
   ```

   ```bash
   # Test the threaded version
   python3 threaded_server.py &
   ab -n 1000 -c 50 http://127.0.0.1:8080/
   # Compare Requests/sec with the single-threaded version
   kill %1
   ```

### Checkpoint

Run the single-threaded and threaded servers. Load test each with `ab` at
concurrency levels of 1, 10, 50, and 100. Record the requests/sec and mean
latency for each. Explain the inflection point where the single-threaded server
falls behind.

---

## Lesson 2: Caching

**Goal:** Understand why caching works, implement it at the application layer
with Redis, and reason about invalidation strategies.

### Concepts

Caching exploits locality of reference -- a small fraction of data serves a
large fraction of requests (the Pareto distribution). Caches exist at every
level: CPU L1/L2/L3, application memory, Redis or Memcached, CDN edge servers.
The two hardest problems in computer science are cache invalidation and naming
things. Common strategies include TTL (expire after N seconds), write-through
(update cache on every write), and write-behind (batch writes asynchronously).
Choose based on how stale your reads can tolerate being.

### Exercises

1. **Install Redis and explore it**

   ```bash
   brew install redis
   brew services start redis

   # Basic operations
   redis-cli SET greeting "hello world"
   redis-cli GET greeting

   # Set a key with TTL (expires in 10 seconds)
   redis-cli SET temp_key "gone soon" EX 10
   redis-cli TTL temp_key
   sleep 11
   redis-cli GET temp_key  # Returns (nil)
   ```

2. **Build a Python app with and without caching**

   ```python
   # cache_demo.py
   import time, json, redis, hashlib

   r = redis.Redis(host="localhost", port=6379, decode_responses=True)

   def expensive_query(user_id):
       """Simulate a slow database query."""
       time.sleep(0.1)  # 100ms "database" call
       return {"user_id": user_id, "name": f"User {user_id}", "score": user_id * 42}

   def get_user_no_cache(user_id):
       return expensive_query(user_id)

   def get_user_with_cache(user_id, ttl=30):
       cache_key = f"user:{user_id}"
       cached = r.get(cache_key)
       if cached:
           return json.loads(cached)
       result = expensive_query(user_id)
       r.setex(cache_key, ttl, json.dumps(result))
       return result

   # Benchmark: 100 lookups for 10 users (high repeat rate)
   user_ids = [i % 10 for i in range(100)]

   start = time.time()
   for uid in user_ids:
       get_user_no_cache(uid)
   no_cache_time = time.time() - start

   start = time.time()
   for uid in user_ids:
       get_user_with_cache(uid)
   cache_time = time.time() - start

   print(f"Without cache: {no_cache_time:.2f}s")
   print(f"With cache:    {cache_time:.2f}s")
   print(f"Speedup:       {no_cache_time / cache_time:.1f}x")
   ```

   ```bash
   pip3 install redis
   python3 cache_demo.py
   ```

3. **Observe cache hit rate**

   ```python
   # cache_stats.py
   import redis, json, random, time

   r = redis.Redis(host="localhost", port=6379, decode_responses=True)
   r.flushdb()  # Start clean

   hits, misses = 0, 0

   def cached_lookup(key):
       global hits, misses
       cached = r.get(key)
       if cached:
           hits += 1
           return json.loads(cached)
       misses += 1
       # Simulate DB lookup
       result = {"key": key, "value": random.randint(1, 100)}
       r.setex(key, 60, json.dumps(result))
       return result

   # Zipf-like distribution: some keys accessed far more than others
   popular_keys = [f"item:{i}" for i in range(5)]
   rare_keys = [f"item:{i}" for i in range(5, 100)]

   for _ in range(1000):
       if random.random() < 0.8:  # 80% of requests hit popular items
           key = random.choice(popular_keys)
       else:
           key = random.choice(rare_keys)
       cached_lookup(key)

   total = hits + misses
   print(f"Hits: {hits}, Misses: {misses}")
   print(f"Hit rate: {hits/total*100:.1f}%")
   ```

   ```bash
   python3 cache_stats.py
   # Expect ~90%+ hit rate due to the skewed access pattern
   ```

4. **Implement cache invalidation**

   ```python
   # invalidation.py
   import redis, json

   r = redis.Redis(host="localhost", port=6379, decode_responses=True)

   def write_through(user_id, data):
       """Update DB and cache atomically."""
       # write to "database" (simulated)
       print(f"DB write: user:{user_id} -> {data}")
       # update cache immediately
       r.setex(f"user:{user_id}", 300, json.dumps(data))

   def invalidate_on_write(user_id, data):
       """Update DB, delete from cache. Next read repopulates."""
       print(f"DB write: user:{user_id} -> {data}")
       r.delete(f"user:{user_id}")

   # Write-through: cache always has fresh data
   write_through(1, {"name": "Alice", "score": 100})
   print("Cache after write-through:", r.get("user:1"))

   # Invalidation: cache is empty until next read
   invalidate_on_write(2, {"name": "Bob", "score": 200})
   print("Cache after invalidation:", r.get("user:2"))  # None
   ```

   ```bash
   python3 invalidation.py
   ```

### Checkpoint

Run `redis-cli MONITOR` in one terminal while running `cache_demo.py` in
another. Watch the SET and GET commands flow through Redis. Then change the TTL
to 2 seconds, re-run the benchmark, and explain how the hit rate and performance
change.

---

## Lesson 3: Load Balancing and Reverse Proxies

**Goal:** Distribute traffic across multiple server instances and understand the
algorithms that decide where each request goes.

### Concepts

A load balancer sits between clients and servers, forwarding each request to one
of several backends. Round-robin distributes evenly. Least-connections sends to
the server with the fewest active requests. Consistent hashing maps requests to
servers based on a key, preserving affinity when servers join or leave. Reverse
proxies also handle TLS termination, compression, and static file serving.
Health checks remove failing backends from the pool automatically.

### Exercises

1. **Run multiple Python workers**

   ```python
   # worker.py
   import sys, json, time
   from http.server import HTTPServer, BaseHTTPRequestHandler

   PORT = int(sys.argv[1])
   WORKER_ID = sys.argv[1]

   class Handler(BaseHTTPRequestHandler):
       def do_GET(self):
           data = {"worker": WORKER_ID, "time": time.time()}
           body = json.dumps(data).encode()
           self.send_response(200)
           self.send_header("Content-Type", "application/json")
           self.send_header("Content-Length", str(len(body)))
           self.end_headers()
           self.wfile.write(body)
       def log_message(self, format, *args):
           pass

   HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
   ```

   ```bash
   python3 worker.py 8081 &
   python3 worker.py 8082 &
   python3 worker.py 8083 &

   # Verify each responds
   curl -s http://127.0.0.1:8081 | python3 -m json.tool
   curl -s http://127.0.0.1:8082 | python3 -m json.tool
   curl -s http://127.0.0.1:8083 | python3 -m json.tool
   ```

2. **Set up nginx as a load balancer**

   ```bash
   brew install nginx
   ```

   ```text
   # Save as /tmp/lb-nginx.conf
   events { worker_connections 128; }
   http {
       upstream backend {
           server 127.0.0.1:8081;
           server 127.0.0.1:8082;
           server 127.0.0.1:8083;
       }
       server {
           listen 8080;
           location / {
               proxy_pass http://backend;
               proxy_set_header X-Real-IP $remote_addr;
           }
           location /health {
               return 200 'ok';
               add_header Content-Type text/plain;
           }
       }
   }
   ```

   ```bash
   nginx -c /tmp/lb-nginx.conf

   # Hit the load balancer repeatedly -- observe round-robin
   for i in $(seq 1 9); do
     curl -s http://127.0.0.1:8080 | python3 -c "import sys,json; print(json.load(sys.stdin)['worker'])"
   done
   # Output: 8081, 8082, 8083, 8081, 8082, 8083, ...

   nginx -s stop
   ```

3. **Implement consistent hashing in Python**

   ```python
   # consistent_hash.py
   import hashlib

   class ConsistentHashRing:
       def __init__(self, nodes, replicas=100):
           self.ring = {}
           self.sorted_keys = []
           for node in nodes:
               for i in range(replicas):
                   key = self._hash(f"{node}:{i}")
                   self.ring[key] = node
                   self.sorted_keys.append(key)
           self.sorted_keys.sort()

       def _hash(self, key):
           return int(hashlib.md5(key.encode()).hexdigest(), 16)

       def get_node(self, key):
           h = self._hash(key)
           for ring_key in self.sorted_keys:
               if h <= ring_key:
                   return self.ring[ring_key]
           return self.ring[self.sorted_keys[0]]

   ring = ConsistentHashRing(["server-1", "server-2", "server-3"])

   # Same key always maps to the same server
   for key in ["user:100", "user:200", "user:300", "user:100"]:
       print(f"{key} -> {ring.get_node(key)}")

   # Remove a server -- only some keys move
   ring2 = ConsistentHashRing(["server-1", "server-3"])
   moved = 0
   for i in range(1000):
       key = f"item:{i}"
       if ring.get_node(key) != ring2.get_node(key):
           moved += 1
   print(f"\nRemoved server-2: {moved}/1000 keys moved ({moved/10:.1f}%)")
   ```

   ```bash
   python3 consistent_hash.py
   # Expect ~33% of keys to move (only keys assigned to server-2)
   ```

4. **Observe graceful degradation**

   ```bash
   # Start workers and nginx (from exercises 1 and 2)
   python3 worker.py 8081 &
   python3 worker.py 8082 &
   python3 worker.py 8083 &
   nginx -c /tmp/lb-nginx.conf

   # Kill one worker
   kill %2  # kills port 8082

   # nginx detects the failure and routes to remaining workers
   for i in $(seq 1 6); do
     curl -s http://127.0.0.1:8080 | python3 -c "import sys,json; print(json.load(sys.stdin)['worker'])"
   done
   # Output: only 8081 and 8083

   # Clean up
   nginx -s stop
   kill %1 %3 2>/dev/null
   ```

### Checkpoint

Set up three Python workers behind nginx. Use `ab -n 1000 -c 20` to load test
through the balancer. Kill one worker mid-test and observe how nginx handles it.
Check the nginx error log to see the health check failure.

---

## Lesson 4: Databases at Scale

**Goal:** Understand how databases handle growing read/write loads through
indexing, replication, and partitioning.

### Concepts

The first scaling lever is indexing -- a B-tree index turns an O(n) table scan
into an O(log n) lookup. The second is read replicas -- direct writes to a
primary, reads to copies. The third is sharding -- split data across multiple
databases by a partition key (user_id, region). Vertical partitioning separates
columns; horizontal partitioning separates rows. Connection pooling prevents
thousands of clients from each holding a database connection open.

### Exercises

1. **Measure the impact of indexes**

   ```bash
   sqlite3 /tmp/scale_test.db <<'SQL'
   -- Create a table with 100k rows
   CREATE TABLE orders (
     id INTEGER PRIMARY KEY,
     user_id INTEGER NOT NULL,
     product TEXT NOT NULL,
     amount REAL NOT NULL,
     created_at TEXT NOT NULL
   );

   -- Insert 100k rows
   WITH RECURSIVE seq(i) AS (
     VALUES(1) UNION ALL SELECT i+1 FROM seq WHERE i < 100000
   )
   INSERT INTO orders (user_id, product, amount, created_at)
   SELECT
     abs(random()) % 1000,
     'product-' || (abs(random()) % 50),
     (abs(random()) % 10000) / 100.0,
     datetime('2024-01-01', '+' || (abs(random()) % 365) || ' days')
   FROM seq;

   -- Query WITHOUT index
   .timer on
   SELECT count(*), sum(amount) FROM orders WHERE user_id = 42;

   -- Add index
   CREATE INDEX idx_orders_user ON orders(user_id);

   -- Query WITH index
   SELECT count(*), sum(amount) FROM orders WHERE user_id = 42;

   -- Compare query plans
   .timer off
   EXPLAIN QUERY PLAN SELECT * FROM orders WHERE user_id = 42;
   EXPLAIN QUERY PLAN SELECT * FROM orders WHERE product = 'product-7';
   SQL
   ```

2. **Analyze query plans**

   ```bash
   sqlite3 /tmp/scale_test.db <<'SQL'
   -- Full table scan (no index on product)
   EXPLAIN QUERY PLAN
   SELECT * FROM orders WHERE product = 'product-7' AND amount > 50;

   -- Covering index (all columns in the index)
   CREATE INDEX idx_orders_user_amount ON orders(user_id, amount);
   EXPLAIN QUERY PLAN
   SELECT sum(amount) FROM orders WHERE user_id = 42;

   -- Composite index order matters
   EXPLAIN QUERY PLAN
   SELECT * FROM orders WHERE user_id = 42 AND amount > 50;

   -- This won't use the composite index efficiently
   EXPLAIN QUERY PLAN
   SELECT * FROM orders WHERE amount > 50;
   SQL
   ```

3. **Simulate horizontal partitioning (sharding)**

   ```python
   # sharding.py
   import sqlite3, time, random

   def create_shard(shard_id):
       db = sqlite3.connect(f"/tmp/shard_{shard_id}.db")
       db.execute("""
           CREATE TABLE IF NOT EXISTS users (
               id INTEGER PRIMARY KEY,
               name TEXT NOT NULL,
               email TEXT NOT NULL
           )
       """)
       db.commit()
       return db

   def get_shard(user_id, num_shards):
       return user_id % num_shards

   # Create 3 shards
   shards = {i: create_shard(i) for i in range(3)}

   # Insert 10,000 users across shards
   for uid in range(10000):
       shard_id = get_shard(uid, 3)
       shards[shard_id].execute(
           "INSERT OR REPLACE INTO users VALUES (?, ?, ?)",
           (uid, f"User {uid}", f"user{uid}@example.com")
       )
   for db in shards.values():
       db.commit()

   # Count per shard
   for shard_id, db in shards.items():
       count = db.execute("SELECT count(*) FROM users").fetchone()[0]
       print(f"Shard {shard_id}: {count} users")

   # Lookup: route to correct shard
   lookup_id = 4242
   shard_id = get_shard(lookup_id, 3)
   row = shards[shard_id].execute(
       "SELECT * FROM users WHERE id = ?", (lookup_id,)
   ).fetchone()
   print(f"\nUser {lookup_id} found on shard {shard_id}: {row}")

   # Cross-shard query (expensive -- must query all shards)
   start = time.time()
   total = sum(
       db.execute("SELECT count(*) FROM users").fetchone()[0]
       for db in shards.values()
   )
   print(f"Cross-shard count: {total} ({time.time()-start:.4f}s)")

   for db in shards.values():
       db.close()
   ```

   ```bash
   python3 sharding.py
   ```

4. **Denormalization tradeoff**

   ```bash
   sqlite3 /tmp/scale_test.db <<'SQL'
   -- Normalized: requires a JOIN
   CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
   CREATE TABLE user_orders AS
     SELECT o.id, o.user_id, o.product, o.amount, o.created_at
     FROM orders o;

   INSERT INTO users (id, name)
   SELECT DISTINCT user_id, 'User ' || user_id FROM orders;

   .timer on
   -- Normalized query (JOIN)
   SELECT u.name, count(*), sum(o.amount)
   FROM user_orders o JOIN users u ON o.user_id = u.id
   GROUP BY u.name ORDER BY sum(o.amount) DESC LIMIT 5;

   -- Denormalized: add user_name to orders
   ALTER TABLE user_orders ADD COLUMN user_name TEXT;
   UPDATE user_orders SET user_name = (
     SELECT name FROM users WHERE users.id = user_orders.user_id
   );

   -- Denormalized query (no JOIN)
   SELECT user_name, count(*), sum(amount)
   FROM user_orders
   GROUP BY user_name ORDER BY sum(amount) DESC LIMIT 5;
   .timer off
   SQL
   ```

### Checkpoint

Create a SQLite database with 100k rows. Write three queries: one that benefits
from an index, one that requires a composite index, and one that does a full
table scan. Run `EXPLAIN QUERY PLAN` on each and explain why the optimizer chose
each strategy.

---

## Lesson 5: Asynchronous Processing

**Goal:** Decouple producers from consumers using queues, and understand when
async processing beats synchronous request-response.

### Concepts

Synchronous processing blocks the caller until work completes. When the work is
slow (sending email, resizing images, generating reports), the caller waits
unnecessarily. Message queues let producers enqueue work and move on; consumers
process it independently. This decoupling absorbs traffic spikes, enables
retries, and lets you scale consumers independently. Dead letter queues capture
messages that repeatedly fail, preventing poison messages from blocking the
pipeline.

### Exercises

1. **Build a task queue with Redis lists**

   ```python
   # producer.py
   import redis, json, time

   r = redis.Redis(host="localhost", port=6379, decode_responses=True)

   tasks = [
       {"type": "send_email", "to": "alice@example.com", "subject": "Welcome"},
       {"type": "resize_image", "path": "/uploads/photo.jpg", "size": "800x600"},
       {"type": "generate_report", "user_id": 42, "format": "pdf"},
       {"type": "send_email", "to": "bob@example.com", "subject": "Invoice"},
       {"type": "resize_image", "path": "/uploads/avatar.png", "size": "200x200"},
   ]

   for task in tasks:
       task["queued_at"] = time.time()
       r.lpush("task_queue", json.dumps(task))
       print(f"Enqueued: {task['type']}")

   print(f"\nQueue length: {r.llen('task_queue')}")
   ```

   ```python
   # consumer.py
   import redis, json, time, random

   r = redis.Redis(host="localhost", port=6379, decode_responses=True)

   def process_task(task):
       """Simulate processing with random delays and failures."""
       delay = random.uniform(0.1, 0.5)
       time.sleep(delay)
       if random.random() < 0.1:  # 10% failure rate
           raise Exception(f"Failed to process {task['type']}")
       return f"Completed {task['type']} in {delay:.2f}s"

   print("Consumer waiting for tasks...")
   while True:
       # BRPOP blocks until a task is available (timeout 5s)
       result = r.brpop("task_queue", timeout=5)
       if result is None:
           print("No more tasks. Exiting.")
           break

       _, raw = result
       task = json.loads(raw)
       latency = time.time() - task["queued_at"]
       print(f"Processing: {task['type']} (waited {latency:.2f}s)")

       try:
           msg = process_task(task)
           print(f"  -> {msg}")
       except Exception as e:
           print(f"  -> ERROR: {e}")
           # Move to dead letter queue
           r.lpush("dead_letter_queue", raw)
           print(f"  -> Moved to dead letter queue")

   dlq_len = r.llen("dead_letter_queue")
   if dlq_len:
       print(f"\nDead letter queue: {dlq_len} failed tasks")
   ```

   ```bash
   pip3 install redis
   python3 producer.py
   python3 consumer.py
   ```

2. **Run multiple consumers in parallel**

   ```bash
   # Enqueue 20 tasks
   python3 -c "
   import redis, json, time
   r = redis.Redis(host='localhost', port=6379, decode_responses=True)
   for i in range(20):
       task = {'type': f'task_{i}', 'queued_at': time.time()}
       r.lpush('task_queue', json.dumps(task))
   print(f'Enqueued 20 tasks. Queue length: {r.llen(\"task_queue\")}')
   "

   # Run 3 consumers in parallel
   python3 consumer.py &
   python3 consumer.py &
   python3 consumer.py &
   wait
   # Each consumer picks up different tasks -- no duplicates
   ```

3. **Compare sync vs async throughput**

   ```python
   # sync_vs_async.py
   import time, threading, queue

   def slow_operation(item):
       time.sleep(0.1)  # Simulate I/O
       return item * 2

   items = list(range(50))

   # Synchronous
   start = time.time()
   sync_results = [slow_operation(i) for i in items]
   sync_time = time.time() - start

   # Async with worker pool
   q = queue.Queue()
   results = []
   lock = threading.Lock()

   def worker():
       while True:
           try:
               item = q.get(timeout=1)
               result = slow_operation(item)
               with lock:
                   results.append(result)
               q.task_done()
           except queue.Empty:
               break

   start = time.time()
   for item in items:
       q.put(item)
   workers = [threading.Thread(target=worker) for _ in range(10)]
   for w in workers:
       w.start()
   q.join()
   async_time = time.time() - start

   print(f"Synchronous:  {sync_time:.2f}s ({len(sync_results)} results)")
   print(f"10 workers:   {async_time:.2f}s ({len(results)} results)")
   print(f"Speedup:      {sync_time / async_time:.1f}x")
   ```

   ```bash
   python3 sync_vs_async.py
   ```

4. **Implement retry with backoff**

   ```python
   # retry.py
   import time, random

   def unreliable_operation():
       if random.random() < 0.7:
           raise Exception("Transient failure")
       return "success"

   def retry_with_backoff(fn, max_retries=5, base_delay=0.1):
       for attempt in range(max_retries):
           try:
               result = fn()
               print(f"  Attempt {attempt + 1}: succeeded")
               return result
           except Exception as e:
               delay = base_delay * (2 ** attempt) + random.uniform(0, 0.1)
               print(f"  Attempt {attempt + 1}: {e} (retry in {delay:.2f}s)")
               time.sleep(delay)
       raise Exception(f"Failed after {max_retries} attempts")

   print("Retry with exponential backoff:")
   try:
       result = retry_with_backoff(unreliable_operation)
       print(f"Final result: {result}")
   except Exception as e:
       print(f"Gave up: {e}")
   ```

   ```bash
   python3 retry.py
   ```

### Checkpoint

Run the producer to enqueue 20 tasks, then start three consumers simultaneously.
Watch them divide the work. Check the dead letter queue for failed tasks.
Explain why BRPOP prevents two consumers from processing the same task.

---

## Lesson 6: Consistency and Availability

**Goal:** Understand the CAP theorem through concrete examples and reason about
when eventual consistency is acceptable.

### Concepts

The CAP theorem states that a distributed system can guarantee at most two of
three properties: Consistency (every read sees the latest write), Availability
(every request gets a response), and Partition tolerance (the system works
despite network failures). Since network partitions are inevitable, the real
choice is between consistency and availability during a partition. Strong
consistency means all nodes agree before responding; eventual consistency means
nodes converge over time, allowing temporary disagreement.

### Exercises

1. **Simulate two nodes with a network partition**

   ```python
   # cap_sim.py
   import time, threading

   class Node:
       def __init__(self, name):
           self.name = name
           self.data = {}
           self.peers = []
           self.partitioned = False

       def write(self, key, value):
           self.data[key] = {"value": value, "ts": time.time()}
           print(f"  [{self.name}] WRITE {key}={value}")
           self._replicate(key)

       def read(self, key):
           entry = self.data.get(key, {"value": None})
           print(f"  [{self.name}] READ  {key}={entry['value']}")
           return entry["value"]

       def _replicate(self, key):
           for peer in self.peers:
               if not self.partitioned and not peer.partitioned:
                   peer.data[key] = self.data[key].copy()
                   print(f"  [{self.name}] -> replicated {key} to {peer.name}")
               else:
                   print(f"  [{self.name}] -> PARTITION: cannot reach {peer.name}")

   # Setup: two nodes that replicate to each other
   node_a = Node("A")
   node_b = Node("B")
   node_a.peers = [node_b]
   node_b.peers = [node_a]

   print("=== Normal operation (consistent) ===")
   node_a.write("balance", 100)
   node_b.read("balance")

   print("\n=== Network partition ===")
   node_a.partitioned = True
   node_b.partitioned = True

   node_a.write("balance", 80)   # A sees 80
   node_b.write("balance", 120)  # B sees 120
   print(f"\n  Conflict! A={node_a.read('balance')}, B={node_b.read('balance')}")

   print("\n=== Partition heals ===")
   node_a.partitioned = False
   node_b.partitioned = False
   # Last-write-wins resolution
   if node_a.data["balance"]["ts"] > node_b.data["balance"]["ts"]:
       node_b.data["balance"] = node_a.data["balance"].copy()
       winner = "A"
   else:
       node_a.data["balance"] = node_b.data["balance"].copy()
       winner = "B"
   print(f"  Resolved with last-write-wins: {winner}'s value")
   print(f"  A={node_a.read('balance')}, B={node_b.read('balance')}")
   ```

   ```bash
   python3 cap_sim.py
   ```

2. **Demonstrate eventual consistency with Redis pub/sub**

   ```python
   # eventual.py
   import redis, json, time, threading

   r = redis.Redis(host="localhost", port=6379, decode_responses=True)

   local_cache = {}

   def subscriber():
       """Background thread that listens for updates."""
       pubsub = r.pubsub()
       pubsub.subscribe("updates")
       for message in pubsub.listen():
           if message["type"] == "message":
               update = json.loads(message["data"])
               local_cache[update["key"]] = update["value"]
               print(f"  [subscriber] synced: {update['key']}={update['value']}")

   # Start subscriber in background
   t = threading.Thread(target=subscriber, daemon=True)
   t.start()
   time.sleep(0.5)  # Let subscriber connect

   # Write to "primary"
   r.set("counter", 1)
   r.publish("updates", json.dumps({"key": "counter", "value": 1}))
   print("Published counter=1")

   time.sleep(0.1)
   print(f"Local cache: {local_cache}")

   r.set("counter", 2)
   r.publish("updates", json.dumps({"key": "counter", "value": 2}))
   print("Published counter=2")

   time.sleep(0.1)
   print(f"Local cache: {local_cache}")

   # Simulate replication lag
   print("\nSimulating lag: write happens but subscriber is slow...")
   r.set("counter", 3)
   print(f"  Primary: counter=3")
   print(f"  Local cache: counter={local_cache.get('counter')} (stale!)")
   r.publish("updates", json.dumps({"key": "counter", "value": 3}))
   time.sleep(0.2)
   print(f"  Local cache: counter={local_cache.get('counter')} (eventually consistent)")
   ```

   ```bash
   python3 eventual.py
   ```

3. **When consistency matters vs when it doesn't**

   ```text
   Eventual consistency is FINE for:
   - Social media likes/counts (off by one is harmless)
   - Shopping cart contents (user sees their own writes)
   - Search index updates (slight delay is acceptable)
   - Analytics dashboards (minutes-old data is fine)
   - User profile caches (stale name for a few seconds is OK)

   Strong consistency is REQUIRED for:
   - Bank account balances (double-spend is catastrophic)
   - Inventory decrements (overselling is expensive)
   - Distributed locks (two holders = data corruption)
   - Unique constraint enforcement (duplicate usernames)
   - Leader election (two leaders = split brain)

   Ask: "What is the cost of a stale read?"
   If the answer is "minor annoyance" -> eventual consistency
   If the answer is "data loss or money" -> strong consistency
   ```

4. **Implement a conflict resolution strategy**

   ```python
   # conflict.py
   import time

   class VersionedValue:
       def __init__(self, value, version=0, timestamp=None):
           self.value = value
           self.version = version
           self.timestamp = timestamp or time.time()

   def last_write_wins(a, b):
       winner = a if a.timestamp > b.timestamp else b
       print(f"  LWW: picked '{winner.value}' (newer timestamp)")
       return winner

   def highest_version_wins(a, b):
       winner = a if a.version > b.version else b
       print(f"  Version: picked '{winner.value}' (version {winner.version})")
       return winner

   def merge_sets(a_set, b_set):
       merged = a_set | b_set
       print(f"  Merge: {a_set} + {b_set} = {merged}")
       return merged

   # Scenario: two nodes edit a username concurrently
   print("=== Last-write-wins ===")
   v1 = VersionedValue("alice_old", version=1, timestamp=100)
   v2 = VersionedValue("alice_new", version=1, timestamp=101)
   last_write_wins(v1, v2)

   print("\n=== Version vector ===")
   v1 = VersionedValue("draft", version=3)
   v2 = VersionedValue("published", version=5)
   highest_version_wins(v1, v2)

   print("\n=== Set merge (CRDTs) ===")
   cart_a = {"apple", "banana"}
   cart_b = {"banana", "cherry"}
   merge_sets(cart_a, cart_b)
   ```

   ```bash
   python3 conflict.py
   ```

### Checkpoint

Run the CAP simulation and modify it so both nodes accept writes during the
partition. Introduce a conflict by writing different values to the same key.
Implement two resolution strategies (last-write-wins and merge) and explain when
each is appropriate.

---

## Lesson 7: Observability

**Goal:** Build the instrumentation that lets you understand what a running
system is doing -- metrics, logs, and traces.

### Concepts

You cannot fix what you cannot see. Observability rests on three pillars:
metrics (counters, gauges, histograms that track system health), logs
(structured events that record what happened), and traces (request flows across
services). Structured logging with JSON and correlation IDs lets you follow a
single request through multiple services. SLIs (Service Level Indicators)
measure what users experience; SLOs (Service Level Objectives) set targets;
error budgets define how much failure is acceptable before you stop shipping
features.

### Exercises

1. **Build structured logging**

   ```python
   # structured_log.py
   import json, time, uuid, sys

   def log(level, message, **kwargs):
       entry = {
           "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
           "level": level,
           "message": message,
           **kwargs,
       }
       print(json.dumps(entry))

   def with_request_id(fn):
       """Decorator that adds a correlation ID to every log."""
       def wrapper(*args, **kwargs):
           kwargs["request_id"] = str(uuid.uuid4())[:8]
           return fn(*args, **kwargs)
       return wrapper

   @with_request_id
   def handle_request(path, request_id=None):
       log("info", "request started", path=path, request_id=request_id)

       start = time.time()
       # Simulate work
       time.sleep(0.05)
       log("info", "database query", table="users", rows=42, request_id=request_id)

       time.sleep(0.02)
       duration_ms = (time.time() - start) * 1000
       log("info", "request completed", path=path,
           duration_ms=round(duration_ms, 1), status=200, request_id=request_id)

   handle_request("/api/users")
   handle_request("/api/orders")
   ```

   ```bash
   python3 structured_log.py | python3 -m json.tool
   # Each log line is valid JSON with a shared request_id
   ```

2. **Build a metrics collector**

   ```python
   # metrics.py
   import time, threading, json
   from collections import defaultdict

   class Metrics:
       def __init__(self):
           self.counters = defaultdict(int)
           self.gauges = {}
           self.histograms = defaultdict(list)
           self._lock = threading.Lock()

       def increment(self, name, amount=1):
           with self._lock:
               self.counters[name] += amount

       def gauge(self, name, value):
           with self._lock:
               self.gauges[name] = value

       def observe(self, name, value):
           with self._lock:
               self.histograms[name].append(value)

       def report(self):
           with self._lock:
               report = {"counters": dict(self.counters), "gauges": dict(self.gauges)}
               for name, values in self.histograms.items():
                   sorted_v = sorted(values)
                   n = len(sorted_v)
                   report[f"histogram_{name}"] = {
                       "count": n,
                       "p50": sorted_v[n // 2] if n else 0,
                       "p95": sorted_v[int(n * 0.95)] if n else 0,
                       "p99": sorted_v[int(n * 0.99)] if n else 0,
                   }
               return report

   m = Metrics()

   # Simulate traffic
   import random
   for _ in range(1000):
       m.increment("http_requests_total")
       latency = random.expovariate(1 / 50)  # Mean 50ms
       m.observe("request_duration_ms", round(latency, 1))
       if random.random() < 0.02:
           m.increment("http_errors_total")

   m.gauge("active_connections", 47)
   m.gauge("queue_depth", 12)

   print(json.dumps(m.report(), indent=2))
   ```

   ```bash
   python3 metrics.py
   ```

3. **Implement request tracing across services**

   ```python
   # tracing.py
   import json, time, uuid

   def trace_span(service, operation, parent_id=None, trace_id=None):
       span_id = str(uuid.uuid4())[:8]
       trace_id = trace_id or str(uuid.uuid4())[:8]
       start = time.time()

       def finish(status="ok", **attrs):
           duration_ms = (time.time() - start) * 1000
           span = {
               "trace_id": trace_id,
               "span_id": span_id,
               "parent_id": parent_id,
               "service": service,
               "operation": operation,
               "duration_ms": round(duration_ms, 1),
               "status": status,
               **attrs,
           }
           print(json.dumps(span))
           return span_id, trace_id

       return span_id, trace_id, finish

   # Simulate a request flowing through three services
   # API Gateway -> User Service -> Database
   sid1, tid, finish1 = trace_span("api-gateway", "GET /api/users/42")
   time.sleep(0.01)

   sid2, _, finish2 = trace_span("user-service", "get_user", parent_id=sid1, trace_id=tid)
   time.sleep(0.005)

   sid3, _, finish3 = trace_span("database", "SELECT * FROM users", parent_id=sid2, trace_id=tid)
   time.sleep(0.02)
   finish3(rows=1)

   finish2(cache_hit=False)
   finish1(status_code=200)
   ```

   ```bash
   python3 tracing.py | python3 -m json.tool
   # All three spans share the same trace_id
   # parent_id links child spans to their parent
   ```

4. **Build a health check endpoint**

   ```python
   # healthcheck.py
   import json, time, sqlite3, redis
   from http.server import HTTPServer, BaseHTTPRequestHandler

   class HealthHandler(BaseHTTPRequestHandler):
       def do_GET(self):
           checks = {}

           # Check Redis
           try:
               r = redis.Redis(host="localhost", port=6379)
               r.ping()
               checks["redis"] = {"status": "healthy", "latency_ms": 0}
           except Exception as e:
               checks["redis"] = {"status": "unhealthy", "error": str(e)}

           # Check SQLite (stand-in for a real database)
           try:
               start = time.time()
               db = sqlite3.connect(":memory:")
               db.execute("SELECT 1")
               db.close()
               checks["database"] = {
                   "status": "healthy",
                   "latency_ms": round((time.time() - start) * 1000, 1),
               }
           except Exception as e:
               checks["database"] = {"status": "unhealthy", "error": str(e)}

           overall = "healthy" if all(
               c["status"] == "healthy" for c in checks.values()
           ) else "unhealthy"

           body = json.dumps({"status": overall, "checks": checks}, indent=2).encode()
           status = 200 if overall == "healthy" else 503
           self.send_response(status)
           self.send_header("Content-Type", "application/json")
           self.end_headers()
           self.wfile.write(body)

       def log_message(self, format, *args):
           pass

   server = HTTPServer(("127.0.0.1", 8080), HealthHandler)
   print("Health check on http://127.0.0.1:8080")
   server.serve_forever()
   ```

   ```bash
   python3 healthcheck.py &
   curl -s http://127.0.0.1:8080 | python3 -m json.tool
   # Returns {"status": "healthy", "checks": {...}}
   kill %1
   ```

### Checkpoint

Run the structured logging example and pipe the output into a file. Use `jq` to
filter for only error-level logs, extract all unique request IDs, and calculate
the average request duration. This is the workflow for investigating production
incidents from log files.

---

## Lesson 8: Putting It Together

**Goal:** Apply every concept from the previous lessons to design complete
systems end-to-end, making tradeoffs explicit at each layer.

### Concepts

System design is the art of making tradeoffs -- every choice forecloses others.
The process follows a repeatable pattern: estimate scale, define the API, choose
a data model, add caching where reads dominate, introduce queues where writes
spike, decide on consistency guarantees, and instrument everything. Walking
through a design end-to-end reveals hidden dependencies and forces you to
justify every component. If you cannot explain why a component exists, remove
it.

### Exercises

1. **Design a URL shortener**

   ```text
   === Requirements ===
   - Shorten long URLs to 7-character codes
   - Redirect short URLs to the original
   - Track click analytics
   - 100M URLs stored, 1000 redirects/sec

   === Back-of-envelope ===
   Storage: 100M × (7 + 200 bytes avg URL) ≈ 20 GB (fits one machine)
   Reads:   1000/sec (heavy read, light write)
   Writes:  ~10/sec (new URLs)
   Ratio:   100:1 read-heavy → cache aggressively

   === Schema ===
   urls(code TEXT PK, original_url TEXT NOT NULL, created_at TEXT)
   clicks(id INTEGER PK, code TEXT FK, clicked_at TEXT, referrer TEXT, ip TEXT)

   === Components ===
   1. API server: POST /shorten, GET /:code (302 redirect)
   2. Redis cache: code -> original_url (TTL 1 hour)
   3. SQLite/Postgres: persistent storage
   4. Analytics queue: log clicks asynchronously
   ```

   ```python
   # url_shortener.py
   import json, time, hashlib, sqlite3, redis
   from http.server import HTTPServer, BaseHTTPRequestHandler

   db = sqlite3.connect("/tmp/shortener.db")
   db.execute("""
       CREATE TABLE IF NOT EXISTS urls (
           code TEXT PRIMARY KEY,
           original_url TEXT NOT NULL,
           created_at TEXT DEFAULT (datetime('now'))
       )
   """)
   db.execute("""
       CREATE TABLE IF NOT EXISTS clicks (
           id INTEGER PRIMARY KEY,
           code TEXT REFERENCES urls(code),
           clicked_at TEXT DEFAULT (datetime('now'))
       )
   """)
   db.commit()

   cache = redis.Redis(host="localhost", port=6379, decode_responses=True)

   def shorten(url):
       code = hashlib.md5(url.encode()).hexdigest()[:7]
       db.execute(
           "INSERT OR IGNORE INTO urls (code, original_url) VALUES (?, ?)",
           (code, url),
       )
       db.commit()
       cache.setex(f"url:{code}", 3600, url)
       return code

   def resolve(code):
       # Check cache first
       cached = cache.get(f"url:{code}")
       if cached:
           return cached
       # Fall back to database
       row = db.execute(
           "SELECT original_url FROM urls WHERE code = ?", (code,)
       ).fetchone()
       if row:
           cache.setex(f"url:{code}", 3600, row[0])
           return row[0]
       return None

   class Handler(BaseHTTPRequestHandler):
       def do_POST(self):
           length = int(self.headers.get("Content-Length", 0))
           body = json.loads(self.rfile.read(length))
           code = shorten(body["url"])
           resp = json.dumps({"short_url": f"http://localhost:8080/{code}"}).encode()
           self.send_response(201)
           self.send_header("Content-Type", "application/json")
           self.end_headers()
           self.wfile.write(resp)

       def do_GET(self):
           code = self.path.strip("/")
           if code == "stats":
               count = db.execute("SELECT count(*) FROM urls").fetchone()[0]
               clicks = db.execute("SELECT count(*) FROM clicks").fetchone()[0]
               resp = json.dumps({"urls": count, "clicks": clicks}).encode()
               self.send_response(200)
               self.send_header("Content-Type", "application/json")
               self.end_headers()
               self.wfile.write(resp)
               return
           url = resolve(code)
           if url:
               db.execute("INSERT INTO clicks (code) VALUES (?)", (code,))
               db.commit()
               self.send_response(302)
               self.send_header("Location", url)
               self.end_headers()
           else:
               self.send_response(404)
               self.end_headers()
               self.wfile.write(b"Not found")

       def log_message(self, format, *args):
           pass

   print("URL shortener on http://127.0.0.1:8080")
   HTTPServer(("127.0.0.1", 8080), Handler).serve_forever()
   ```

   ```bash
   python3 url_shortener.py &

   # Create a short URL
   curl -s -X POST http://127.0.0.1:8080 \
     -H "Content-Type: application/json" \
     -d '{"url": "https://en.wikipedia.org/wiki/Systems_design"}' | python3 -m json.tool

   # Follow the redirect
   curl -v http://127.0.0.1:8080/$(curl -s -X POST http://127.0.0.1:8080 \
     -H "Content-Type: application/json" \
     -d '{"url": "https://example.com"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['short_url'].split('/')[-1])") 2>&1 | grep Location

   # Check stats
   curl -s http://127.0.0.1:8080/stats | python3 -m json.tool

   kill %1
   ```

2. **Design a rate limiter**

   ```python
   # rate_limiter.py
   import redis, time, json
   from http.server import HTTPServer, BaseHTTPRequestHandler

   r = redis.Redis(host="localhost", port=6379, decode_responses=True)

   def is_rate_limited(client_id, max_requests=10, window_seconds=60):
       """Sliding window rate limiter using Redis sorted sets."""
       key = f"ratelimit:{client_id}"
       now = time.time()
       window_start = now - window_seconds

       pipe = r.pipeline()
       pipe.zremrangebyscore(key, 0, window_start)  # Remove old entries
       pipe.zadd(key, {str(now): now})               # Add current request
       pipe.zcard(key)                                # Count requests in window
       pipe.expire(key, window_seconds)               # Auto-cleanup
       results = pipe.execute()

       request_count = results[2]
       remaining = max(0, max_requests - request_count)
       return request_count > max_requests, request_count, remaining

   class Handler(BaseHTTPRequestHandler):
       def do_GET(self):
           client_id = self.client_address[0]
           limited, count, remaining = is_rate_limited(client_id)

           self.send_header = self._original_send_header
           if limited:
               self.send_response(429)
               self.send_header("Retry-After", "60")
               self.send_header("X-RateLimit-Remaining", str(remaining))
               self.end_headers()
               self.wfile.write(b"Rate limit exceeded")
           else:
               body = json.dumps({"message": "ok", "requests_used": count}).encode()
               self.send_response(200)
               self.send_header("Content-Type", "application/json")
               self.send_header("X-RateLimit-Remaining", str(remaining))
               self.end_headers()
               self.wfile.write(body)

       def log_message(self, format, *args):
           pass

   print("Rate limiter on http://127.0.0.1:8080 (10 req/min)")
   HTTPServer(("127.0.0.1", 8080), Handler).serve_forever()
   ```

   ```bash
   python3 rate_limiter.py &

   # Send 12 requests quickly -- last ones should be 429
   for i in $(seq 1 12); do
     echo "Request $i: $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080)"
   done

   kill %1
   ```

3. **System design decision checklist**

   ```text
   For any system, walk through these questions:

   SCALE
   [ ] How many users? DAU? Peak QPS?
   [ ] Read:write ratio?
   [ ] How much data? Growth rate?
   [ ] Can one server handle it?

   DATA
   [ ] What are the entities and relationships?
   [ ] SQL or NoSQL? Why?
   [ ] What indexes are needed?
   [ ] Sharding key (if needed)?

   CACHING
   [ ] What data is read-heavy and rarely changes?
   [ ] Cache invalidation strategy?
   [ ] What is the acceptable staleness?

   ASYNC
   [ ] Which operations can be deferred?
   [ ] What happens if a queued task fails?
   [ ] Do consumers need exactly-once semantics?

   CONSISTENCY
   [ ] What needs strong consistency?
   [ ] Where is eventual consistency acceptable?
   [ ] What is the cost of a stale or conflicting read?

   OBSERVABILITY
   [ ] What are the SLIs? (latency, error rate, throughput)
   [ ] What SLO targets?
   [ ] How will you detect and diagnose failures?
   ```

4. **Walk through tradeoffs for the URL shortener**

   ```text
   TRADEOFF 1: Code generation
   - Hash (MD5/SHA) vs counter vs random
   - Hash: deterministic, same URL = same code (dedup)
   - Counter: sequential, predictable (security concern)
   - Random: no collisions with DB check, not guessable

   TRADEOFF 2: Cache TTL
   - Long TTL (1 hour): fewer DB reads, stale if URL deleted
   - Short TTL (1 min): fresher data, more DB load
   - No TTL: fastest reads, cache grows unbounded

   TRADEOFF 3: Analytics
   - Sync: every redirect waits for INSERT (adds latency)
   - Async queue: redirect is fast, analytics may lag
   - Batch: buffer clicks in memory, flush periodically

   TRADEOFF 4: Consistency
   - Single DB: strongly consistent, single point of failure
   - Replicas: available under failure, reads may be stale
   - The shortener is read-heavy → replicas make sense
   ```

### Checkpoint

Pick one of these systems: a paste bin, a notification service, or a
leaderboard. Walk through the full design checklist: estimate scale, define the
API, choose a data model, decide on caching and queuing, set consistency
requirements, and define SLIs. Write it up in the same format as the URL
shortener exercise above. Justify every component -- if you cannot explain why
it exists, remove it.

---

## Practice Projects

### Project 1: URL Shortener with Analytics Dashboard

Extend the URL shortener from Lesson 8 with a full analytics pipeline. Track
referrers, geographic data (via IP), and click timestamps. Use Redis for
real-time counters and SQLite for historical data. Build a `/stats/:code`
endpoint that returns click-over-time data as JSON. Add rate limiting to the
create endpoint.

### Project 2: Job Queue System

Build a production-quality job queue with Redis. Support priority levels (high,
normal, low), retry with exponential backoff, dead letter queues, and a
dashboard endpoint showing queue depth, processing rate, and failure rate. Add
multiple worker types that handle different job types.

### Project 3: Mini Load Tester

Write a Python tool that sends concurrent HTTP requests to a target URL and
reports statistics: requests/sec, latency percentiles (p50, p95, p99), error
rate, and throughput in bytes/sec. Support configurable concurrency, duration,
and request count. Output results as both a summary and a JSON report.

---

## Quick Reference

| Topic          | Key Concepts                                                   |
| -------------- | -------------------------------------------------------------- |
| Capacity       | `ulimit`, `ab`, back-of-envelope estimation, one-server limits |
| Caching        | Redis, TTL, write-through, invalidation, hit rate              |
| Load balancing | nginx, round-robin, least-connections, consistent hashing      |
| Databases      | Indexes, EXPLAIN, read replicas, sharding, denormalization     |
| Async          | Redis queues, BRPOP, worker pools, retry, dead letter queues   |
| Consistency    | CAP theorem, strong vs eventual, conflict resolution           |
| Observability  | Structured logs, metrics, traces, correlation IDs, SLIs/SLOs   |
| Design process | Estimate, schema, API, cache, queue, consistency, instrument   |

## See Also

- [Data Models Lesson Plan](data-models-lesson-plan.md) -- How you store data
  shapes everything
- [Networking Lesson Plan](networking-lesson-plan.md) -- The network layer
  underneath
- [Cryptography Lesson Plan](cryptography-lesson-plan.md) -- TLS and auth at
  scale
- [PostgreSQL Cheatsheet](../how/postgres.md) -- Database commands and
  optimization
- [Docker Cheatsheet](../how/docker.md) -- Containerization for multi-service
  setups
