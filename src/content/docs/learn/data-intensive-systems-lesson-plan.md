---
title: "Data-Intensive Systems Lesson Plan"
description:
  Eight staff-level lessons from storage engines to stream processing, covering
  replication, partitioning, transactions, consensus, and design review.
---

The advanced sequel to the System Design Lesson Plan. Where that plan scales a
web app from one server to many, this one goes inside the data systems
themselves -- how storage engines organize bytes, how replicas diverge, why
"exactly-once" is a marketing term, and how a staff engineer reviews a design
before it ships. The arc follows Kleppmann's
[Designing Data-Intensive Applications](https://dataintensive.net/), with
runnable exercises instead of prose.

<!-- prettier-ignore -->
:::note[Prerequisites]
Completed the [System Design Lesson Plan](system-design-lesson-plan.md), plus
working [SQL](../how/sql.md) and comfort reading Python. Several exercises use
Redis and PostgreSQL (see the [PostgreSQL cheat sheet](../how/postgres.md)).
:::

## Lesson 1: Storage Engines

**Goal:** Understand how LSM-trees and B-trees organize data on disk, and
measure the write, read, and space amplification each design trades away.

### Concepts

Every database is a clever arrangement of two ideas: update-in-place (B-trees)
or append-only (log-structured merge trees). B-trees overwrite pages in place
and rely on a write-ahead log for crash safety; reads are fast and predictable.
LSM-trees buffer writes in a memtable, flush sorted runs (SSTables) to disk, and
merge them in the background through compaction; writes are fast and sequential,
reads may touch several files. Neither wins outright -- the RUM conjecture says
you can optimize any two of read, update, and memory cost, but never all three.
Staff-level storage decisions start by naming which amplification you are
paying: write (bytes written per logical write), read (files touched per
lookup), or space (bytes stored per live byte).

### Exercises

1. **Build an append-only log store**

   ```python
   # kvlog.py
   import json, os, time

   class LogKV:
       def __init__(self, path):
           self.path = path
           self.index = {}  # key -> byte offset of latest record
           self.f = open(path, "a+b")

       def put(self, key, value):
           self.f.seek(0, 2)
           offset = self.f.tell()
           self.f.write(json.dumps({"k": key, "v": value}).encode() + b"\n")
           self.index[key] = offset

       def get(self, key):
           offset = self.index.get(key)
           if offset is None:
               return None
           self.f.seek(offset)
           return json.loads(self.f.readline())["v"]

   if os.path.exists("/tmp/kv.log"):
       os.remove("/tmp/kv.log")
   store = LogKV("/tmp/kv.log")

   start = time.time()
   for i in range(100000):
       store.put(f"user:{i % 10000}", {"n": i})
   store.f.flush()
   elapsed = time.time() - start

   print(f"100k writes in {elapsed:.2f}s ({100000/elapsed:,.0f}/sec)")
   print("read user:42 ->", store.get("user:42"))
   size = os.path.getsize("/tmp/kv.log") / 1e6
   print(f"log size: {size:.1f} MB for 10k live keys")
   print("space amplification: ~10x (nine stale versions per key)")
   ```

   ```bash
   python3 kvlog.py
   # Sequential appends are why LSM writes are fast.
   # The stale versions are why compaction must exist.
   ```

2. **Build a mini LSM-tree with compaction**

   ```python
   # minilsm.py
   import json, os, glob, time

   DATA = "/tmp/minilsm"
   os.makedirs(DATA, exist_ok=True)
   for f in glob.glob(f"{DATA}/sst_*.json"):
       os.remove(f)

   class MiniLSM:
       def __init__(self, memtable_limit=500):
           self.memtable = {}
           self.limit = memtable_limit
           self.sstables = []

       def put(self, key, value):
           self.memtable[key] = value
           if len(self.memtable) >= self.limit:
               self.flush()

       def flush(self):
           path = f"{DATA}/sst_{len(self.sstables):06d}.json"
           with open(path, "w") as f:
               json.dump(dict(sorted(self.memtable.items())), f)
           self.sstables.append(path)
           self.memtable = {}

       def get(self, key):
           if key in self.memtable:
               return self.memtable[key]
           for path in reversed(self.sstables):  # newest first
               with open(path) as f:
                   table = json.load(f)
               if key in table:
                   return table[key]
           return None

       def compact(self):
           merged = {}
           for path in self.sstables:  # oldest first, newer wins
               with open(path) as f:
                   merged.update(json.load(f))
               os.remove(path)
           path = f"{DATA}/sst_compacted.json"
           with open(path, "w") as f:
               json.dump(merged, f)
           self.sstables = [path]

   db = MiniLSM()
   for i in range(5000):
       db.put(f"key:{i % 1000}", i)  # heavy overwrites

   print(f"SSTables before compaction: {len(db.sstables)}")
   start = time.time()
   for i in range(200):
       db.get(f"key:{i}")
   print(f"200 reads across all tables: {time.time()-start:.3f}s")

   db.compact()
   print(f"SSTables after compaction: {len(db.sstables)}")
   start = time.time()
   for i in range(200):
       db.get(f"key:{i}")
   print(f"200 reads after compaction: {time.time()-start:.3f}s")
   ```

   ```bash
   python3 minilsm.py
   # Read amplification drops with compaction; the cost moved
   # to background I/O. Real engines use bloom filters to skip
   # SSTables that cannot contain the key.
   ```

3. **Measure the write-ahead log tradeoff in SQLite**

   ```bash
   python3 - <<'EOF'
   import sqlite3, time, os

   for mode in ["DELETE", "WAL"]:
       path = f"/tmp/journal_{mode}.db"
       for suffix in ["", "-wal", "-shm"]:
           if os.path.exists(path + suffix):
               os.remove(path + suffix)
       db = sqlite3.connect(path, isolation_level=None)
       db.execute(f"PRAGMA journal_mode={mode}")
       db.execute("PRAGMA synchronous=FULL")
       db.execute("CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)")
       start = time.time()
       for i in range(2000):
           db.execute("INSERT INTO t (v) VALUES (?)", (f"value-{i}",))
       print(f"{mode}: 2000 single-row commits in {time.time()-start:.2f}s")
       db.close()
   EOF
   # WAL turns each commit into one sequential append instead of
   # rewriting pages in place -- the B-tree borrowing the LSM trick.
   ```

4. **Choose an engine per workload**

   ```text
   For each workload, pick B-tree or LSM and name the amplification
   you accepted:

   1. Telemetry ingest: 500k writes/sec, reads are rare range scans
      over recent data.
   2. User profile store: 50:1 read:write, point lookups, p99 read
      latency SLO of 5ms.
   3. Message archive: append-heavy, occasional key lookup, storage
      cost dominates the budget.
   4. Financial ledger: moderate writes, every read must see the
      committed value, audits scan by time range.

   Sketch answers:
   1 -> LSM (sequential ingest; pay read amplification you rarely use)
   2 -> B-tree (predictable point reads; pay write amplification)
   3 -> LSM with aggressive compaction and compression (pay CPU)
   4 -> B-tree/WAL engine (pay write cost for read predictability)
   ```

### Checkpoint

Run the log store and mini LSM. Report write throughput, read latency before and
after compaction, and the space amplification you measured. Then explain, in two
sentences each, which engine you would pick for the four workloads in exercise 4
and which amplification each choice pays.

---

## Lesson 2: Replication

**Goal:** Reason about replication lag, read-your-writes guarantees, quorum
overlap, and what a failover actually loses.

### Concepts

Replication looks simple -- copy the data -- until the copies disagree.
Leader-based replication sends a change log to followers; asynchronous followers
lag, so a read after a write can travel back in time. The named guarantees
(read-your-writes, monotonic reads, consistent prefix) are contracts about which
anomalies clients never see, and each costs routing or tracking machinery.
Leaderless systems replace the leader with quorums: with `n` replicas, writes to
`w` and reads from `r` overlap when `w + r > n`, letting the reader find at
least one fresh copy. Failover is where replication designs earn their keep --
promoting a stale follower silently discards every unreplicated write, and split
brain (two leaders) corrupts data faster than downtime ever could.

### Exercises

1. **Observe replication lag**

   ```python
   # lag.py
   import time, threading, queue

   class Follower:
       def __init__(self, name, delay):
           self.name, self.delay = name, delay
           self.data = {}
           self.applied_seq = 0
           self.inbox = queue.Queue()
           threading.Thread(target=self._apply, daemon=True).start()

       def _apply(self):
           while True:
               seq, key, value = self.inbox.get()
               time.sleep(self.delay)  # network + apply lag
               self.data[key] = value
               self.applied_seq = seq

   class Leader:
       def __init__(self, followers):
           self.data, self.log, self.followers = {}, [], followers

       def write(self, key, value):
           seq = len(self.log) + 1
           self.data[key] = value
           self.log.append((seq, key, value))
           for f in self.followers:
               f.inbox.put((seq, key, value))
           return seq

   fast = Follower("fast", delay=0.01)
   slow = Follower("slow", delay=0.5)
   leader = Leader([fast, slow])

   leader.write("bio", "hello world")
   time.sleep(0.05)
   print("fast follower:", fast.data.get("bio"))
   print("slow follower:", slow.data.get("bio"), "<- stale read")
   time.sleep(0.6)
   print("slow follower:", slow.data.get("bio"), "<- converged")
   ```

   ```bash
   python3 lag.py
   # The user who posts a comment and refreshes against the slow
   # follower sees their comment vanish.
   ```

2. **Implement read-your-writes with sequence tokens**

   ```python
   # ryw.py  (requires classes from lag.py)
   import time

   def read_your_writes(client_token, follower, leader, key):
       """Serve from the follower only if it has caught up to the
       client's last write; otherwise fall back to the leader."""
       if follower.applied_seq >= client_token:
           return follower.data.get(key), follower.name
       return leader.data.get(key), "leader (follower behind)"

   # exec(open("lag.py").read()) or paste the classes above first
   token = leader.write("status", "shipped")
   value, source = read_your_writes(token, slow, leader, "status")
   print(f"read '{value}' from {source}")
   time.sleep(0.6)
   value, source = read_your_writes(token, slow, leader, "status")
   print(f"read '{value}' from {source}")
   ```

   ```bash
   python3 ryw.py
   # The token is the client remembering "I wrote seq 2"; routing
   # honors it. This is how session consistency works in practice.
   ```

3. **Verify quorum overlap catches the latest write**

   ```python
   # quorum.py
   import random

   class Replica:
       def __init__(self, name):
           self.name, self.version, self.value = name, 0, None
           self.up = True

   def write(replicas, value, version, w):
       acked = [rep for rep in replicas if rep.up]
       for rep in acked:
           rep.version, rep.value = version, value
       if len(acked) < w:
           raise RuntimeError(f"{len(acked)} acks < w={w}")

   def read(replicas, r):
       alive = [rep for rep in replicas if rep.up]
       sample = random.sample(alive, min(r, len(alive)))
       if len(sample) < r:
           raise RuntimeError(f"{len(sample)} replies < r={r}")
       best = max(sample, key=lambda rep: rep.version)
       return best.value, [rep.name for rep in sample]

   replicas = [Replica("a"), Replica("b"), Replica("c")]
   write(replicas, "v1", 1, w=3)

   replicas[2].up = False          # one replica dies
   write(replicas, "v2", 2, w=2)   # quorum write still succeeds
   replicas[2].up = True           # it comes back, still holding v1

   stale = 0
   for _ in range(1000):
       value, _ = read(replicas, r=2)   # w=2, r=2, n=3: overlap
       if value != "v2":
           stale += 1
   print(f"w=2, r=2: {stale}/1000 stale reads")

   stale = 0
   for _ in range(1000):
       value, _ = read(replicas, r=1)   # w=2 + r=1 = n: no overlap
       if value != "v2":
           stale += 1
   print(f"w=2, r=1: {stale}/1000 stale reads")
   ```

   ```bash
   python3 quorum.py
   # w + r > n guarantees the read set intersects the write set.
   # Drop to r=1 and roughly a third of reads return v1.
   ```

4. **Count what failover loses**

   ```python
   # failover.py
   leader_log = [(seq, f"write-{seq}") for seq in range(1, 11)]
   follower_applied = 7   # async follower is 3 writes behind

   # Leader dies; the follower is promoted.
   lost = [entry for entry in leader_log if entry[0] > follower_applied]
   print(f"promoted follower at seq {follower_applied}")
   print(f"acknowledged writes lost: {len(lost)}")
   for seq, payload in lost:
       print(f"  seq {seq}: {payload} (client saw success)")
   ```

   ```bash
   python3 failover.py
   # These writes were acknowledged to clients. Semi-synchronous
   # replication or waiting for follower catch-up trades latency
   # or availability for closing this window.
   ```

### Checkpoint

For a session store (logout tolerable) and a payment ledger (loss intolerable),
choose `n`, `w`, and `r`, decide sync vs async replication, and state which
anomaly you accepted in each case. Support the session-store answer with stale
read counts from the quorum simulation.

---

## Lesson 3: Partitioning

**Goal:** Pick partition keys that spread load, rebalance without moving the
world, and understand what secondary indexes cost on a partitioned store.

### Concepts

Partitioning (sharding) splits data so each node owns a subset. Hash
partitioning spreads load evenly but destroys range queries; key-range
partitioning keeps ranges scannable but invites hot spots. Skew is the silent
killer -- one celebrity key can pin a whole shard at 100% while the rest idle.
Rebalancing strategy matters as much as the initial split: naive `hash mod N`
moves almost every key when N changes, while consistent hashing with virtual
nodes moves only `1/N` of them. Secondary indexes come in two flavors: local
(each shard indexes its own rows, so queries scatter-gather across all shards)
and global (the index itself is partitioned by the indexed value, so reads hit
one shard but writes fan out). Every partitioned design answers three questions:
what is the key, how does rebalancing work, and who pays for secondary lookups.

### Exercises

1. **Measure how virtual nodes smooth distribution**

   ```python
   # vnodes.py
   import hashlib, statistics

   def ring_assign(nodes, vnodes, keys):
       ring = []
       for node in nodes:
           for i in range(vnodes):
               h = int(hashlib.md5(f"{node}:{i}".encode()).hexdigest(), 16)
               ring.append((h, node))
       ring.sort()
       counts = {node: 0 for node in nodes}
       for key in keys:
           h = int(hashlib.md5(key.encode()).hexdigest(), 16)
           owner = next((node for hv, node in ring if h <= hv), ring[0][1])
           counts[owner] += 1
       return counts

   nodes = ["node-a", "node-b", "node-c"]
   keys = [f"user:{i}" for i in range(30000)]

   for vnodes in [1, 10, 100]:
       counts = ring_assign(nodes, vnodes, keys)
       spread = statistics.pstdev(counts.values())
       print(f"vnodes={vnodes:3d}  {counts}  stddev={spread:,.0f}")
   ```

   ```bash
   python3 vnodes.py
   # One point per node gives lumpy ownership; 100 virtual nodes
   # per physical node approaches an even split.
   ```

2. **Compare rebalancing cost: mod-N vs consistent hashing**

   ```python
   # rebalance.py
   import hashlib

   def hash_int(key):
       return int(hashlib.md5(key.encode()).hexdigest(), 16)

   def mod_assign(key, n):
       return hash_int(key) % n

   def ring(nodes, vnodes=100):
       points = []
       for node in nodes:
           for i in range(vnodes):
               points.append((hash_int(f"{node}:{i}"), node))
       return sorted(points)

   def ring_assign(key, points):
       h = hash_int(key)
       return next((node for hv, node in points if h <= hv), points[0][1])

   keys = [f"item:{i}" for i in range(20000)]

   moved_mod = sum(
       1 for k in keys if mod_assign(k, 3) != mod_assign(k, 4)
   )
   ring3 = ring(["n1", "n2", "n3"])
   ring4 = ring(["n1", "n2", "n3", "n4"])
   moved_ring = sum(
       1 for k in keys if ring_assign(k, ring3) != ring_assign(k, ring4)
   )

   print(f"mod-N:              {moved_mod/len(keys):.0%} of keys moved")
   print(f"consistent hashing: {moved_ring/len(keys):.0%} of keys moved")
   ```

   ```bash
   python3 rebalance.py
   # Expect ~75% vs ~25%. Moving a key means copying data and
   # invalidating caches -- rebalancing IS downtime risk.
   ```

3. **Detect and salt a hot key**

   ```python
   # hotkey.py
   import random
   from collections import Counter

   def shard_of(key, n=4):
       return hash(key) % n

   # Celebrity workload: 40% of traffic hits one key
   requests = [
       "user:celebrity" if random.random() < 0.4
       else f"user:{random.randint(1, 10000)}"
       for _ in range(100000)
   ]

   before = Counter(shard_of(key) for key in requests)
   print("per-shard load, raw:     ", dict(sorted(before.items())))

   def salted(key):
       if key == "user:celebrity":  # split hot key across 8 subkeys
           return f"{key}#{random.randint(0, 7)}"
       return key

   after = Counter(shard_of(salted(key)) for key in requests)
   print("per-shard load, salted:  ", dict(sorted(after.items())))
   print("cost: reads for the hot key must now query all 8 subkeys")
   ```

   ```bash
   python3 hotkey.py
   # Salting trades write skew for read fan-out. Only salt keys
   # that are measurably hot -- it complicates every reader.
   ```

4. **Price local vs global secondary indexes**

   ```python
   # sec_index.py
   NUM_SHARDS = 6

   # 100 queries by city, 100 user writes, under each design:

   # Local index: every shard indexes its own users.
   local_query_rpcs = 100 * NUM_SHARDS   # scatter-gather every query
   local_write_rpcs = 100 * 1            # write stays on one shard

   # Global index: index partitioned by city.
   global_query_rpcs = 100 * 1           # city lives on one shard
   global_write_rpcs = 100 * 2           # row shard + index shard

   print(f"local  index: {local_query_rpcs} query RPCs, "
         f"{local_write_rpcs} write RPCs")
   print(f"global index: {global_query_rpcs} query RPCs, "
         f"{global_write_rpcs} write RPCs (and the index update "
         f"is async -- readers may see lag)")
   ```

   ```bash
   python3 sec_index.py
   # Local indexes tax reads; global indexes tax writes and add
   # eventual consistency. DynamoDB GSIs are the global flavor.
   ```

### Checkpoint

Design partitioning for a multi-tenant SaaS `orders` table where one tenant
generates 30% of all traffic. Name the partition key, the rebalancing scheme,
how you contain the hot tenant, and whether "orders by status" uses a local or
global index. Justify each with the numbers from these exercises.

---

## Lesson 4: Transactions and Isolation

**Goal:** Reproduce real isolation anomalies in PostgreSQL, then pick the
weakest isolation level and the cheapest pattern that keeps your invariants.

### Concepts

Isolation levels are a menu of anomalies you agree to tolerate. Read committed
stops dirty reads but allows lost updates -- two clients read 100, both add 10,
and one increment vanishes. Snapshot isolation (PostgreSQL `REPEATABLE READ`)
gives each transaction a frozen view, which kills lost-update anomalies on the
same row but permits write skew: two transactions read an invariant ("at least
one doctor on call"), each modify different rows, and jointly break it.
`SERIALIZABLE` catches write skew by aborting one transaction, which means your
code must retry. Distributed transactions raise the stakes: two-phase commit
buys atomicity at the price of a blocking coordinator, so most systems prefer
sagas -- a sequence of local transactions with compensating actions for
rollback. The staff move is naming the invariant first, then buying the cheapest
mechanism that protects it.

### Exercises

1. **Reproduce a lost update, then fix it**

   ```bash
   # Setup (PostgreSQL running locally; see the PostgreSQL cheat sheet)
   createdb txdemo
   psql txdemo -c "CREATE TABLE accounts (
     id int PRIMARY KEY, balance int NOT NULL);
   INSERT INTO accounts VALUES (1, 100);"
   ```

   ```sql
   -- Terminal A                      -- Terminal B
   BEGIN;
   SELECT balance FROM accounts
     WHERE id = 1;   -- sees 100
                                      BEGIN;
                                      SELECT balance FROM accounts
                                        WHERE id = 1;   -- sees 100
   UPDATE accounts SET balance = 110
     WHERE id = 1;
   COMMIT;
                                      UPDATE accounts SET balance = 105
                                        WHERE id = 1;
                                      COMMIT;
   -- Final balance: 105. A's +10 is gone: a lost update.

   -- Fix: SELECT ... FOR UPDATE in both sessions. B's select now
   -- blocks until A commits, then reads 110 and writes 115.
   ```

2. **Produce write skew and watch SERIALIZABLE catch it**

   ```bash
   psql txdemo -c "CREATE TABLE oncall (
     doctor text PRIMARY KEY, on_duty boolean NOT NULL);
   INSERT INTO oncall VALUES ('alice', true), ('bob', true);"
   ```

   ```sql
   -- Invariant: at least one doctor stays on duty.
   -- Terminal A                      -- Terminal B
   BEGIN ISOLATION LEVEL
     REPEATABLE READ;
   SELECT count(*) FROM oncall
     WHERE on_duty;  -- sees 2, safe
                                      BEGIN ISOLATION LEVEL
                                        REPEATABLE READ;
                                      SELECT count(*) FROM oncall
                                        WHERE on_duty;  -- sees 2, safe
   UPDATE oncall SET on_duty = false
     WHERE doctor = 'alice';
   COMMIT;
                                      UPDATE oncall SET on_duty = false
                                        WHERE doctor = 'bob';
                                      COMMIT;
   -- Both commit. Zero doctors on duty: write skew.

   -- Re-run with BEGIN ISOLATION LEVEL SERIALIZABLE; the second
   -- COMMIT fails with SQLSTATE 40001 (serialization failure).
   -- Your application must catch 40001 and retry the transaction.
   ```

3. **Implement optimistic concurrency control**

   ```python
   # occ.py
   import sqlite3

   db = sqlite3.connect(":memory:", check_same_thread=False)
   db.execute("CREATE TABLE doc (id INT PRIMARY KEY, body TEXT, version INT)")
   db.execute("INSERT INTO doc VALUES (1, 'draft', 1)")

   def save(doc_id, new_body, expected_version):
       cur = db.execute(
           "UPDATE doc SET body = ?, version = version + 1 "
           "WHERE id = ? AND version = ?",
           (new_body, doc_id, expected_version),
       )
       return cur.rowcount == 1   # 0 rows means someone got there first

   # Two editors loaded version 1
   print("editor 1 saves:", save(1, "editor 1 text", 1))   # True
   print("editor 2 saves:", save(1, "editor 2 text", 1))   # False: conflict

   # Editor 2 reloads and retries against the current version
   body, version = db.execute(
       "SELECT body, version FROM doc WHERE id = 1"
   ).fetchone()
   print(f"editor 2 reloads v{version}, merges, retries:",
         save(1, body + " + editor 2 additions", version))
   ```

   ```bash
   python3 occ.py
   # No locks held while the user edits. The version column turns
   # "last write wins" into "first write wins, second one knows".
   ```

4. **Simulate a saga with compensations**

   ```python
   # saga.py
   import random

   def reserve_inventory(order):
       print("  reserve_inventory: ok")
       return lambda: print("  COMPENSATE: release inventory")

   def charge_payment(order):
       if random.random() < 0.5:
           raise RuntimeError("card declined")
       print("  charge_payment: ok")
       return lambda: print("  COMPENSATE: refund payment")

   def create_shipment(order):
       print("  create_shipment: ok")
       return lambda: print("  COMPENSATE: cancel shipment")

   def run_saga(order, steps):
       compensations = []
       try:
           for step in steps:
               compensations.append(step(order))
           print("saga committed")
       except Exception as e:
           print(f"saga failed at {len(compensations)+1}: {e}")
           for undo in reversed(compensations):
               undo()

   random.seed(7)
   for attempt in range(3):
       print(f"order attempt {attempt + 1}:")
       run_saga({"id": 42},
                [reserve_inventory, charge_payment, create_shipment])
   ```

   ```bash
   python3 saga.py
   # No coordinator, no global lock -- but between steps the system
   # is visibly mid-flight, and compensations must be idempotent.
   ```

### Checkpoint

For an inventory system with the invariant "never sell more units than exist",
state which anomaly each isolation level would let through, then pick the
cheapest safe design: isolation level, locking or OCC, and where a saga is
acceptable. Show the write-skew transcript from exercise 2 as your evidence.

---

## Lesson 5: Clocks, Ordering, and Consensus

**Goal:** Stop trusting wall clocks, order events with logical clocks, and know
exactly what fencing tokens and consensus protocols buy you.

### Concepts

Distributed systems have no "now". NTP-synced clocks drift and jump, so
last-write-wins by timestamp silently drops concurrent writes. Lamport clocks
replace wall time with a counter that respects causality: if A happened-before
B, A's clock is smaller (the reverse does not hold, which is the price of their
simplicity). Leases and locks fail without ordering too -- a client can acquire
a lease, stall in a GC pause past expiry, and wake convinced it still holds the
lock. Fencing tokens fix this: every lease grant carries a monotonically
increasing number, and storage rejects any write bearing an older token.
Consensus (Raft, Paxos) is the industrial-strength version: it gives a cluster a
single agreed sequence of decisions despite crashes, at the cost of majority
round-trips. You rarely implement it -- you rent it from etcd, ZooKeeper, or
your database's replication layer -- but you must know which guarantees are
consensus-backed and which are best-effort.

### Exercises

1. **Order events with Lamport clocks**

   ```python
   # lamport.py
   class Process:
       def __init__(self, name, wall_skew):
           self.name, self.clock, self.skew = name, 0, wall_skew
           self.events = []

       def local_event(self, label, wall_time):
           self.clock += 1
           self.events.append((self.clock, self.name, label,
                               wall_time + self.skew))

       def send(self, label, wall_time):
           self.local_event(label, wall_time)
           return self.clock

       def receive(self, sender_clock, label, wall_time):
           self.clock = max(self.clock, sender_clock) + 1
           self.events.append((self.clock, self.name, label,
                               wall_time + self.skew))

   a = Process("A", wall_skew=0.0)
   b = Process("B", wall_skew=-2.5)   # B's clock runs 2.5s behind

   a.local_event("write x=1", 1.0)
   ts = a.send("send x to B", 2.0)
   b.receive(ts, "apply x=1", 2.1)
   b.local_event("write y=2", 3.0)

   merged = sorted(a.events + b.events)
   print("Lamport order (correct causality):")
   for clock, proc, label, wall in merged:
       print(f"  L{clock} [{proc}] {label} (wall={wall:.1f})")
   print("\nWall-clock order (skew breaks causality):")
   for clock, proc, label, wall in sorted(merged, key=lambda e: e[3]):
       print(f"  wall={wall:.1f} [{proc}] {label}")
   ```

   ```bash
   python3 lamport.py
   # By wall clock, B "applies x=1" before A sends it. Any
   # last-write-wins rule keyed on wall time inherits this bug.
   ```

2. **Break a lease, then fence it**

   ```python
   # fencing.py
   class LockService:
       def __init__(self):
           self.token = 0

       def acquire(self, client):
           self.token += 1
           print(f"lease granted to {client} with token {self.token}")
           return self.token

   class Storage:
       def __init__(self):
           self.max_token = 0

       def write(self, client, token, data):
           if token < self.max_token:
               print(f"  REJECTED {client} (token {token} < "
                     f"{self.max_token})")
               return False
           self.max_token = token
           print(f"  accepted {client} (token {token}): {data}")
           return True

   locks, storage = LockService(), Storage()

   t_a = locks.acquire("client-A")
   print("client-A enters a 30s GC pause; lease expires...")
   t_b = locks.acquire("client-B")      # lease re-granted
   storage.write("client-B", t_b, "B's update")
   print("client-A wakes, still believes it holds the lock:")
   storage.write("client-A", t_a, "A's zombie update")
   ```

   ```bash
   python3 fencing.py
   # Without the token check, A's zombie write lands after B's and
   # corrupts state. TTL-based locks (Redis SETNX + EXPIRE) have
   # exactly this hole unless storage checks fencing tokens.
   ```

3. **Reject a stale leader with epochs**

   ```python
   # epochs.py
   class Node:
       def __init__(self, name):
           self.name = name
           self.current_term = 0

       def append_entries(self, leader, term, entry):
           if term < self.current_term:
               print(f"  {self.name}: REJECT {leader} "
                     f"(term {term} < {self.current_term})")
               return False
           self.current_term = term
           print(f"  {self.name}: accept '{entry}' from {leader} "
                 f"(term {term})")
           return True

   cluster = [Node("n1"), Node("n2"), Node("n3")]

   print("leader-1 elected for term 1:")
   for node in cluster:
       node.append_entries("leader-1", 1, "set x=1")

   print("partition: leader-2 elected for term 2 by majority:")
   for node in cluster[1:]:
       node.append_entries("leader-2", 2, "set x=2")

   print("old leader-1 heals and tries to keep leading:")
   for node in cluster:
       node.append_entries("leader-1", 1, "set x=99")
   ```

   ```bash
   python3 epochs.py
   # Terms are cluster-wide fencing tokens. This is the mechanism
   # that makes Raft failover safe; step through the visualization
   # at https://raft.github.io/ to see elections drive the terms.
   ```

4. **Classify features by required consistency**

   ```text
   Using the map at https://jepsen.io/consistency, assign the
   weakest sufficient level to each feature, and note what breaks
   if you weaken it one more step:

   1. Username uniqueness check at signup
   2. Like counter on a post
   3. "Undo send" within 10 seconds of sending
   4. Shopping cart merge across devices
   5. Config flag that disables a payment provider

   Sketch: (1) linearizable -- else duplicate usernames;
   (2) eventual -- counts converge, nobody audits likes;
   (3) causal/read-your-writes -- sender must see their own send;
   (4) eventual with CRDT merge -- union beats last-write-wins;
   (5) linearizable read after write -- a stale true flag keeps
   charging a dead provider.
   ```

### Checkpoint

Write the incident narrative for a Redis `SETNX`-with-TTL lock protecting a
report generator: the exact interleaving (pause, expiry, second acquirer) that
produces a double-run, shown with the fencing simulation's output. Then state
the two fixes (fencing tokens at storage, or moving the mutual exclusion into a
consensus-backed store) and the cost of each.

---

## Lesson 6: Batch Processing and Derived Data

**Goal:** Treat raw events as immutable input and every table, index, and
dashboard as a derived view you can rebuild from scratch.

### Concepts

Batch processing starts from a liberating constraint: input files are immutable,
output is derived, and any job can rerun without harm. The Unix pipeline is the
original dataflow engine -- sort-based grouping, streaming through bounded
memory -- and MapReduce industrialized the same shape: map (extract keys),
shuffle (group by key via sorting), reduce (aggregate per key). Joins dominate
real batch work; a sort-merge join sorts both sides by the join key and zips
them in one pass, which beats nested loops by orders of magnitude at scale. The
deeper idea is derived data: search indexes, caches, materialized views, and ML
features are all recomputable functions of an event log. When derivation logic
has a bug, you fix it and rebuild -- which only works if jobs are deterministic
and idempotent, so backfills are a design requirement, not an afterthought.

### Exercises

1. **Run a batch job as a Unix pipeline**

   ```bash
   # Generate a 500k-line access log
   python3 - <<'EOF'
   import random
   paths = ["/api/users", "/api/orders", "/health", "/api/search",
            "/api/items", "/login", "/logout", "/api/cart"]
   weights = [30, 20, 25, 10, 5, 4, 3, 3]
   with open("/tmp/access.log", "w") as f:
       for i in range(500000):
           path = random.choices(paths, weights)[0]
           status = random.choices([200, 404, 500], [95, 3, 2])[0]
           f.write(f"10.0.0.{i % 255} {path} {status}\n")
   EOF

   # Top endpoints by traffic: map (cut), shuffle (sort), reduce (uniq)
   time cut -d' ' -f2 /tmp/access.log | sort | uniq -c | sort -rn

   # Error rate per endpoint
   awk '$3 >= 500 {err[$2]++} {total[$2]++}
        END {for (p in total)
          printf "%-14s %.2f%%\n", p, 100*err[p]/total[p]}' /tmp/access.log
   ```

2. **Implement a sort-merge join**

   ```python
   # mergejoin.py
   import random, time

   users = [(uid, f"user-{uid}") for uid in range(20000)]
   events = [(random.randint(0, 19999), f"event-{i}")
             for i in range(200000)]

   # Nested-loop join (the accidental O(n*m))
   lookup_free = random.sample(events, 2000)
   start = time.time()
   joined = [(name, event) for uid, event in lookup_free
             for u_uid, name in users if uid == u_uid]
   nested_time = time.time() - start

   # Sort-merge join: sort both sides, zip in one pass
   start = time.time()
   users_sorted = sorted(users)
   events_sorted = sorted(events)
   result, i = [], 0
   for uid, name in users_sorted:
       while i < len(events_sorted) and events_sorted[i][0] < uid:
           i += 1
       j = i
       while j < len(events_sorted) and events_sorted[j][0] == uid:
           result.append((name, events_sorted[j][1]))
           j += 1
   merge_time = time.time() - start

   print(f"nested loop: {len(joined)} rows from 2k events "
         f"in {nested_time:.2f}s")
   print(f"sort-merge:  {len(result)} rows from 200k events "
         f"in {merge_time:.2f}s")
   ```

   ```bash
   python3 mergejoin.py
   # The merge join processed 100x the data in less time. Sorting
   # is the shuffle phase MapReduce runs between map and reduce.
   ```

3. **Rebuild a derived view and prove determinism**

   ```python
   # derived.py
   import json, hashlib, random

   random.seed(1234)
   with open("/tmp/events.jsonl", "w") as f:      # immutable event log
       for i in range(50000):
           f.write(json.dumps({
               "player": f"p{random.randint(1, 500)}",
               "score": random.randint(1, 100),
           }) + "\n")

   def build_leaderboard(path):
       totals = {}
       with open(path) as f:
           for line in f:
               event = json.loads(line)
               totals[event["player"]] = (
                   totals.get(event["player"], 0) + event["score"]
               )
       top = sorted(totals.items(), key=lambda kv: (-kv[1], kv[0]))[:10]
       return top

   first = build_leaderboard("/tmp/events.jsonl")
   second = build_leaderboard("/tmp/events.jsonl")   # "backfill" rerun

   digest = lambda view: hashlib.sha256(
       json.dumps(view).encode()).hexdigest()[:12]
   print("run 1 digest:", digest(first))
   print("run 2 digest:", digest(second))
   print("identical:", first == second)
   print("top 3:", first[:3])
   ```

   ```bash
   python3 derived.py
   # The leaderboard is disposable; the log is the truth. Any code
   # using random(), now(), or dict order breaks this property.
   ```

4. **Compare incremental update to full rebuild**

   ```python
   # incremental.py  (run derived.py first)
   import json, time

   def full_rebuild(path):
       totals = {}
       with open(path) as f:
           for line in f:
               e = json.loads(line)
               totals[e["player"]] = totals.get(e["player"], 0) + e["score"]
       return totals

   start = time.time()
   totals = full_rebuild("/tmp/events.jsonl")
   full_time = time.time() - start

   # 100 new events arrive; apply them to the existing view
   new_events = [{"player": "p42", "score": 10}] * 100
   start = time.time()
   for e in new_events:
       totals[e["player"]] = totals.get(e["player"], 0) + e["score"]
   incr_time = time.time() - start

   print(f"full rebuild of 50k events: {full_time*1000:.0f}ms")
   print(f"incremental apply of 100:   {incr_time*1000:.2f}ms")
   print("rule: incremental for freshness, full rebuild for repair")
   ```

   ```bash
   python3 incremental.py
   ```

### Checkpoint

A bug in `build_leaderboard` double-counted scores for two weeks. Write the
backfill plan: what you rebuild, from which input, how you verify the fix
(digests before and after), how readers cut over, and why the job being
deterministic and side-effect-free is what makes the plan safe.

---

## Lesson 7: Stream Processing

**Goal:** Use a log as the spine of the system -- consumer groups, replay,
windows over event time, and effective exactly-once from idempotence.

### Concepts

A stream is a log you never finish reading. Kafka-style logs give each partition
a total order and let independent consumer groups keep their own offsets, so the
same events can feed billing, analytics, and search without coordination -- and
replay is just rewinding an offset. Two clocks run through every stream: event
time (when it happened) and processing time (when you saw it); windows computed
on processing time silently lie whenever events arrive late. Delivery guarantees
are the honest conversation: at-most-once drops, at-least-once duplicates, and
"exactly-once" in practice means at-least-once delivery paired with idempotent
or transactional processing. The dual-write bug -- writing the database and
publishing an event as two separate steps -- is the classic streaming data-loss
source; the outbox pattern closes it by making the event part of the database
transaction.

### Exercises

1. **Consumer groups, acks, and crash recovery with Redis Streams**

   ```python
   # streams.py
   import redis

   r = redis.Redis(decode_responses=True)
   r.delete("orders")
   r.xgroup_create("orders", "billing", id="0", mkstream=True)

   for i in range(6):
       r.xadd("orders", {"order_id": str(i), "amount": str(10 + i)})

   # worker-1 claims three messages but crashes after acking one
   batch = r.xreadgroup("billing", "worker-1", {"orders": ">"}, count=3)
   messages = batch[0][1]
   r.xack("orders", "billing", messages[0][0])
   print(f"worker-1 read 3, acked 1, crashed")

   # worker-2 processes the rest of the stream
   batch = r.xreadgroup("billing", "worker-2", {"orders": ">"}, count=10)
   print(f"worker-2 processed {len(batch[0][1])} new messages")

   # The unacked messages are still pending -- nothing was lost
   pending = r.xpending("orders", "billing")
   print(f"pending after crash: {pending['pending']}")

   # worker-2 claims worker-1's abandoned messages and finishes them
   stale = r.xpending_range("orders", "billing", "-", "+", 10,
                            consumername="worker-1")
   ids = [entry["message_id"] for entry in stale]
   claimed = r.xclaim("orders", "billing", "worker-2",
                      min_idle_time=0, message_ids=ids)
   for msg_id, fields in claimed:
       r.xack("orders", "billing", msg_id)
   print(f"worker-2 reclaimed and acked {len(claimed)}")
   print(f"pending now: {r.xpending('orders', 'billing')['pending']}")
   ```

   ```bash
   python3 streams.py
   # Ack-after-processing plus a pending list is at-least-once
   # delivery: the crash cost a redelivery, never a loss.
   ```

2. **Window by event time, not arrival time**

   ```python
   # windows.py
   from collections import defaultdict

   # (event_time_sec, value) -- the 3rd event arrives 25s late
   arrivals = [(2, 10), (8, 20), (31, 99), (12, 30), (18, 40), (27, 50)]
   # arrival order above IS processing order; event 12 and 18 came
   # after the clock passed 30

   WINDOW = 10  # tumbling 10-second windows

   processing_windows = defaultdict(int)
   event_windows = defaultdict(int)

   for arrival_position, (event_time, value) in enumerate(arrivals):
       processing_time = arrival_position * 6   # one event per 6s
       processing_windows[processing_time // WINDOW] += value
       event_windows[event_time // WINDOW] += value

   print("processing-time windows:", dict(processing_windows))
   print("event-time windows:     ", dict(event_windows))
   print("late data moved 70 units into the correct windows;")
   print("a watermark decides how long to wait before closing one")
   ```

   ```bash
   python3 windows.py
   # If the dashboard sums processing-time windows, a flaky mobile
   # network reshapes your business metrics.
   ```

3. **Turn at-least-once into effectively-once with idempotence**

   ```python
   # idempotent.py
   import redis

   r = redis.Redis(decode_responses=True)
   r.delete("revenue", "processed_ids")

   def process(msg_id, amount):
       # SADD returns 0 if the id was already present: a duplicate
       if r.sadd("processed_ids", msg_id) == 0:
           print(f"  {msg_id}: duplicate, skipped")
           return
       r.incrby("revenue", amount)
       print(f"  {msg_id}: applied +{amount}")

   deliveries = [("m1", 100), ("m2", 50), ("m2", 50),  # redelivered
                 ("m3", 25), ("m1", 100)]              # redelivered
   for msg_id, amount in deliveries:
       process(msg_id, amount)

   print("revenue:", r.get("revenue"), "(correct: 175)")
   ```

   ```bash
   python3 idempotent.py
   # The dedupe set and the increment should live in the same store
   # so they commit atomically -- here both sit in Redis.
   ```

4. **Close the dual-write hole with an outbox**

   ```python
   # outbox.py
   import sqlite3, json, redis

   db = sqlite3.connect(":memory:")
   db.execute("CREATE TABLE orders (id INTEGER PRIMARY KEY, item TEXT)")
   db.execute("""CREATE TABLE outbox (
       id INTEGER PRIMARY KEY, payload TEXT, published INT DEFAULT 0)""")
   r = redis.Redis(decode_responses=True)
   r.delete("order-events")

   def create_order_dual_write(item, crash_before_publish):
       db.execute("INSERT INTO orders (item) VALUES (?)", (item,))
       db.commit()
       if crash_before_publish:
           print(f"  {item}: DB committed, crashed before publish "
                 "-- event lost forever")
           return
       r.xadd("order-events", {"item": item})

   def create_order_outbox(item):
       with db:  # one transaction: order row + outbox row
           db.execute("INSERT INTO orders (item) VALUES (?)", (item,))
           db.execute("INSERT INTO outbox (payload) VALUES (?)",
                      (json.dumps({"item": item}),))

   def relay():  # runs forever in production; idempotent
       rows = db.execute(
           "SELECT id, payload FROM outbox WHERE published = 0").fetchall()
       for row_id, payload in rows:
           r.xadd("order-events", json.loads(payload))
           db.execute("UPDATE outbox SET published = 1 WHERE id = ?",
                      (row_id,))
       db.commit()
       return len(rows)

   print("dual write:")
   create_order_dual_write("book", crash_before_publish=True)
   print("outbox:")
   create_order_outbox("lamp")
   print(f"  crash before relay? rows wait in outbox: "
         f"{relay()} published on recovery")
   print("stream length:", r.xlen("order-events"))
   ```

   ```bash
   python3 outbox.py
   # The event becomes durable in the same transaction as the data.
   # The relay may publish twice after a crash, so downstream
   # consumers still need exercise 3's idempotence.
   ```

### Checkpoint

A teammate proposes "Kafka gives us exactly-once, so consumers can be dumb".
Write the two-paragraph correction: what the broker actually guarantees, where
duplicates still appear (producer retries, consumer redelivery, relay crashes),
and the pairing from exercises 3 and 4 that makes processing effectively-once
anyway.

---

## Lesson 8: The Staff-Level Design Review

**Goal:** Run a design through the review a staff engineer gives it -- capacity
math with growth, failure domains, migration and rollback, and the tradeoff memo
that survives the meeting.

### Concepts

Below staff level, design review asks "will it work?". At staff level it asks
four harder questions. What breaks first -- which component hits its ceiling at
2x and 10x growth, and does it degrade or collapse? What is the blast radius --
which failures stay contained inside one partition, tenant, or region, and which
cascade? How does it evolve -- can you change the schema, replay the data, and
migrate live traffic without a big-bang cutover? And what does it cost to
operate -- on-call load, backfill time, the bill. Strong designs earn boring
answers: single-writer where invariants live, derived data everywhere else,
idempotence at every retry boundary, and rollback plans that were rehearsed
rather than asserted. The written artifact matters as much as the architecture;
a tradeoff memo that names the rejected alternatives is what lets the next
engineer change your system safely.

### Exercises

1. **Capacity-model a metrics pipeline**

   ```text
   Requirement: ingest 1M metric points/sec, queryable within 10s,
   13-month retention.

   INGEST
   Point size:          ~60 bytes raw, ~15 bytes compressed (TSDB)
   Ingest bandwidth:    1M x 60B = 60 MB/s raw
   Partitions at 10 MB/s each:  6 minimum -> 24 for burst + growth
   Partition key:       metric_name + tag hash (watch hot metrics)

   STORAGE
   Raw/day:      1M x 86,400 x 15B compressed ≈ 1.3 TB/day
   13 months raw: ~510 TB -> downsampling is mandatory:
     raw (10s) for 14 days:        ~18 TB
     5-min rollups for 13 months:  ~17 TB
   Downsampling is a batch job over the log (Lesson 6).

   QUERY
   Dashboards hit rollups; only incident debugging touches raw.
   Fan-out: a 6-month query over 24 partitions is scatter-gather;
   cap concurrent raw-range queries or they starve ingest.

   FAILURE MATH
   One partition down = 1/24th of metrics delayed, not lost
   (consumers resume from offsets). State the RPO: zero for acked
   points; RTO: consumer lag catch-up rate = 3x ingest -> 30 min
   of downtime replays in ~10 min.
   ```

2. **Run a failure-mode analysis (FMEA-lite)**

   ```text
   For the URL shortener from the System Design Lesson Plan,
   fill one row per component:

   | Component | Failure        | Blast radius      | Detected by | Mitigation        |
   | --------- | -------------- | ----------------- | ----------- | ----------------- |
   | Redis     | eviction storm | DB read spike     | cache hit   | TTL jitter,       |
   |           |                | p99 up 10x        | rate alert  | request coalescing|
   | Postgres  | primary down   | writes fail,      | health      | replica promote,  |
   |           |                | reads OK (cache)  | check       | queue new URLs    |
   | Analytics | consumer lag   | stale dashboards, | lag metric  | none needed:      |
   | queue     |                | zero user impact  |             | document + alert  |
   | Code gen  | hash collision | wrong redirect    | ratio test  | 409 + re-salt     |
   |           |                | (data integrity!) | in CI       | on insert conflict|

   The discipline: every row needs a detection signal that fires
   before users tweet about it, and integrity failures outrank
   availability failures no matter how rare.
   ```

3. **Design a payments ledger (the invariant-first workout)**

   ```text
   Requirements: record transfers between accounts, survive retries,
   support audits, 10k transfers/sec peak.

   INVARIANTS (name these before any technology)
   I1: money is never created or destroyed (debits == credits)
   I2: a transfer applies exactly once despite client retries
   I3: history is immutable -- corrections are new entries

   DESIGN
   - Append-only ledger of double-entry records; the log is the
     source of truth (Lesson 6), balances are a derived view.
   - Idempotency: client-supplied transfer_id, unique constraint;
     retries hit the constraint and return the original result (I2).
   - Single-writer per account partition serializes balance checks
     (Lesson 3 + 4): overdraft check and append commit together.
   - Balances snapshot + replay tail on restart (Lesson 7).
   - Nightly reconciliation job re-derives balances from genesis
     and diffs against the live view (I1 as a batch check).

   REJECTED
   - Mutable balance column + row locks: loses I3, audit needs
     a second system, lock contention at hot accounts.
   - Distributed transaction across account shards: 2PC coordinator
     becomes the availability ceiling; a transfer saga with
     reserved-funds states keeps partitions independent.
   ```

4. **Red-team your own design**

   ```text
   The staff review question list -- ask these of exercise 3:

   SCALE     Which number in the capacity model is least certain?
             What breaks first at 10x? (hot account partitions)
   FAILURE   Kill any one component: what do users see? What is
             the blast radius of a bad deploy of the relay?
   CORRECTNESS Where can duplicates enter? Replay: is every
             consumer idempotent? What detects drift? (the
             reconciliation job -- how fast?)
   EVOLUTION Add a currency field next quarter: which parts
             change? Can you replay 2 years of events through
             new derivation code in bounded time?
   OPERATIONS What pages a human at 3am? Can on-call replay,
             pause, or rewind consumers with a runbook command?
   ROLLBACK  The new balance-derivation code is wrong in prod:
             exact steps back, and how long do they take?
   ```

### Checkpoint

Write a one-page design doc for a social feed (choose fan-out-on-write vs
fan-out-on-read, or a hybrid): capacity model, partition key, consistency choice
per surface, failure table, and one rejected alternative with the reason. Then
answer all six red-team categories from exercise 4 against your own doc, in
writing, before anyone else gets to.

---

## Reading Map

Each lesson pairs with chapters of
[Designing Data-Intensive Applications](https://dataintensive.net/):

| Lesson                        | DDIA Chapters                          |
| ----------------------------- | -------------------------------------- |
| 1. Storage Engines            | Ch 3: Storage and Retrieval            |
| 2. Replication                | Ch 5: Replication                      |
| 3. Partitioning               | Ch 6: Partitioning                     |
| 4. Transactions and Isolation | Ch 7: Transactions                     |
| 5. Clocks and Consensus       | Ch 8-9: Faults, Consistency, Consensus |
| 6. Batch and Derived Data     | Ch 10: Batch Processing                |
| 7. Stream Processing          | Ch 11: Stream Processing               |
| 8. Design Review              | Ch 12: The Future of Data Systems      |

## Practice Projects

### Project 1: Rebuild-Anything Store

Extend the mini LSM with a write-ahead log, tombstones for deletes, and crash
recovery (kill the process mid-write, restart, verify no acknowledged write is
lost). Add a compaction thread and chart write throughput against compaction
backlog.

### Project 2: Replicated KV with Chaos

Combine Lessons 2 and 5: three replicas, quorum reads and writes, Lamport
timestamps for conflict detection, and a chaos mode that randomly partitions,
delays, and restarts nodes. Prove read-your-writes holds for a client while
chaos runs.

### Project 3: End-to-End Event Pipeline

Orders flow through an outbox into a Redis Stream, a consumer group derives
balances and a leaderboard, a batch job rebuilds both views from genesis, and
digests prove the streaming and batch answers agree (the kappa architecture
test).

## Quick Reference

| Topic        | Key Concepts                                                   |
| ------------ | -------------------------------------------------------------- |
| Storage      | LSM vs B-tree, compaction, WAL, write/read/space amplification |
| Replication  | Lag anomalies, read-your-writes, quorums (w + r > n), failover |
| Partitioning | Hash vs range, virtual nodes, hot keys, local vs global index  |
| Transactions | Lost update, write skew, SERIALIZABLE + retry, OCC, sagas      |
| Consensus    | Lamport clocks, fencing tokens, epochs/terms, rent-not-build   |
| Batch        | Immutable input, sort-merge join, derived views, backfills     |
| Streams      | Consumer groups, offsets, event time, idempotence, outbox      |
| Review       | Capacity at 10x, blast radius, evolution, rollback rehearsal   |

## See Also

- [System Design Lesson Plan](system-design-lesson-plan.md) -- The prerequisite:
  scaling from one server to many
- [Data Models Lesson Plan](data-models-lesson-plan.md) -- Choosing the shapes
  these systems store
- [Concurrency Lesson Plan](concurrency-lesson-plan.md) -- The single-machine
  version of these races
- [SQL Lesson Plan](sql-lesson-plan.md) -- The query layer over these engines
- [PostgreSQL Cheatsheet](../how/postgres.md) -- Commands for the isolation
  exercises
- [System Design Cheatsheet](../how/system-design.md) -- Quick reference for the
  building blocks
- [Resilience](../why/resilience.md) -- Failure modes and chaos engineering as a
  mental model
