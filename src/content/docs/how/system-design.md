---
title: "System Design"
description:
  "Load balancing, caching, consistency models, capacity estimation, and
  distributed patterns"
---

<!-- prettier-ignore -->
:::tip[Lesson Plan]
Looking to learn this topic step by step? See the
[System Design Lesson Plan](../learn/system-design-lesson-plan.md).
:::

## Quick Reference

| Concept            | When to Use                            | Key Trade-off                               |
| ------------------ | -------------------------------------- | ------------------------------------------- |
| Load balancing     | Multiple servers handle same workload  | Complexity vs throughput                    |
| Caching            | Read-heavy, tolerates some staleness   | Freshness vs latency                        |
| Data partitioning  | Single DB can't hold all data          | Query flexibility vs horizontal scale       |
| Replication        | Need fault tolerance or read scale     | Consistency vs availability                 |
| Message queues     | Decouple producers from consumers      | Latency vs reliability                      |
| CDN                | Static assets, geographically spread   | Cache invalidation vs load reduction        |
| Circuit breaker    | Calling unreliable downstream services | Fail-fast vs retry cost                     |
| CQRS               | Read and write patterns differ greatly | Operational complexity vs query performance |
| Consistent hashing | Distributing data across dynamic nodes | Rebalancing cost vs even distribution       |
| Rate limiting      | Protect services from overload         | User experience vs system stability         |

## Load Balancing

### Algorithms

| Algorithm            | How It Works                        | Best For                         |
| -------------------- | ----------------------------------- | -------------------------------- |
| Round-robin          | Rotate through servers sequentially | Homogeneous servers, stateless   |
| Weighted round-robin | Rotate with proportional allocation | Servers with different capacity  |
| Least connections    | Send to server with fewest active   | Variable request duration        |
| IP hash              | Hash client IP to pick server       | Session affinity without cookies |
| Consistent hashing   | Hash key to ring of virtual nodes   | Caches, stateful partitioning    |
| Random               | Pick a server at random             | Simple, surprisingly effective   |

### L4 vs L7

| Layer | Operates On     | Sees               | Examples          | Use Case                          |
| ----- | --------------- | ------------------ | ----------------- | --------------------------------- |
| L4    | TCP/UDP packets | IP, port           | HAProxy, NLB      | Raw throughput, TLS passthrough   |
| L7    | HTTP requests   | URL, headers, body | nginx, ALB, Envoy | Content routing, header injection |

### nginx Load Balancer Config

```text
upstream backend {
    least_conn;                    # Algorithm selection
    server 10.0.0.1:8080 weight=3;
    server 10.0.0.2:8080 weight=1;
    server 10.0.0.3:8080 backup;   # Only when others are down
}

server {
    listen 80;
    location / {
        proxy_pass http://backend;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Health Checks

| Type    | Mechanism                  | Detects                  |
| ------- | -------------------------- | ------------------------ |
| Passive | Monitor response codes     | Crashed servers          |
| Active  | Periodic probe to endpoint | Unhealthy but responding |
| Deep    | Check dependencies (DB)    | Cascading failures       |

### Rate Limiting Algorithms

| Algorithm      | How It Works                                     | Pros                          | Cons                       |
| -------------- | ------------------------------------------------ | ----------------------------- | -------------------------- |
| Token bucket   | Tokens added at fixed rate, consumed per request | Allows bursts, smooth average | Requires atomic operations |
| Leaky bucket   | Requests queue and drain at fixed rate           | Strict output rate            | Drops bursts               |
| Fixed window   | Count requests per time window                   | Simple to implement           | Boundary spike problem     |
| Sliding window | Rolling count over last N seconds                | Accurate, no boundary spikes  | Higher memory cost         |

## Caching

### Strategies

| Strategy      | Write Path                       | Read Path                  | Staleness Risk | Use Case                    |
| ------------- | -------------------------------- | -------------------------- | -------------- | --------------------------- |
| Cache-aside   | App writes to DB only            | Check cache, miss reads DB | Moderate       | General purpose, read-heavy |
| Write-through | App writes to cache and DB       | Always read from cache     | None           | Strong consistency needed   |
| Write-behind  | App writes to cache, async to DB | Always read from cache     | Low            | Write-heavy, can lose data  |
| Read-through  | Cache fetches from DB on miss    | Always read from cache     | Moderate       | Simplify application code   |

### Eviction Policies

| Policy | Evicts                | Best For                   |
| ------ | --------------------- | -------------------------- |
| LRU    | Least recently used   | General workloads          |
| LFU    | Least frequently used | Stable hot-set             |
| FIFO   | Oldest entry          | Time-series, streaming     |
| TTL    | Expired entries       | Data with known shelf life |
| Random | Random entry          | Uniform access patterns    |

### Invalidation Approaches

| Approach           | Mechanism                          | Consistency | Complexity |
| ------------------ | ---------------------------------- | ----------- | ---------- |
| TTL expiry         | Set expiration on write            | Eventual    | Low        |
| Event-driven purge | Publish invalidation on write      | Near-real   | Medium     |
| Version key        | Bump version to bypass stale cache | Strong      | Medium     |
| Write-through      | Update cache on every write        | Strong      | Low        |

### Cache Hierarchy

```text
Client -> CDN Edge -> Application Cache (Redis) -> Database
         ~5ms          ~1ms                         ~10-50ms
```

Common latency targets: CDN hit < 10ms, Redis < 2ms, DB read < 50ms.

## Consistency Models

| Model                 | Guarantee                                  | Latency | Example System        |
| --------------------- | ------------------------------------------ | ------- | --------------------- |
| Strong (linearizable) | Reads see the latest write                 | High    | Spanner, ZooKeeper    |
| Sequential            | All see same order, not necessarily latest | Medium  | Distributed locks     |
| Causal                | Causally related writes ordered            | Medium  | MongoDB (sessions)    |
| Eventual              | All replicas converge given time           | Low     | DynamoDB, Cassandra   |
| Read-your-writes      | Client sees its own writes                 | Low     | Session-affine caches |

### CAP Theorem

Pick two of three during a network partition:

| Choice | Sacrifice      | Behavior During Partition             | Systems                      |
| ------ | -------------- | ------------------------------------- | ---------------------------- |
| CP     | Availability   | Reject writes to maintain consistency | ZooKeeper, etcd, HBase       |
| AP     | Consistency    | Accept writes, reconcile later        | Cassandra, DynamoDB, CouchDB |
| CA     | (No partition) | Only possible on a single node        | Single-node PostgreSQL       |

In practice, partitions happen. The real question: when a partition occurs, do
you favor consistency or availability?

### PACELC Extension

Beyond CAP -- when there is **no** partition, trade latency vs consistency:

| Scenario | Trade-off                                 | Example                           |
| -------- | ----------------------------------------- | --------------------------------- |
| PA/EL    | Available + Low latency                   | DynamoDB (eventual by default)    |
| PC/EC    | Consistent always                         | Spanner (synchronous replication) |
| PA/EC    | Available in failure, consistent normally | MongoDB (default config)          |

### Replication Topologies

| Topology      | Write Path         | Read Path          | Consistency                | Failover           |
| ------------- | ------------------ | ------------------ | -------------------------- | ------------------ |
| Single leader | One primary        | Primary + replicas | Strong possible            | Promote replica    |
| Multi-leader  | Multiple primaries | Any node           | Conflict resolution needed | Automatic          |
| Leaderless    | Any node (quorum)  | Any node (quorum)  | Tunable (R+W>N)            | No failover needed |

Quorum formula: with N replicas, set W (write) + R (read) > N to guarantee
overlap. Common config: N=3, W=2, R=2.

### Consensus Algorithms

Consensus solves the problem: how do N nodes agree on a value when some nodes
may fail?

| Algorithm | Model              | Leader   | Use Case                         |
| --------- | ------------------ | -------- | -------------------------------- |
| Raft      | Crash-tolerant     | Elected  | etcd, Consul, CockroachDB        |
| Paxos     | Crash-tolerant     | Proposer | Chubby, Spanner (Multi-Paxos)    |
| ZAB       | Crash-tolerant     | Elected  | ZooKeeper                        |
| PBFT      | Byzantine-tolerant | Rotating | Blockchain, high-trust consensus |

All crash-tolerant algorithms require a majority quorum: tolerate F failures
with 2F+1 nodes. A 3-node cluster tolerates 1 failure; 5 nodes tolerate 2.

#### Raft Overview

Raft is the most widely-taught consensus algorithm. Three roles: leader,
follower, candidate.

```text
Election:
  1. Follower times out (no heartbeat from leader)
  2. Becomes candidate, increments term, votes for self
  3. Requests votes from peers
  4. Wins with majority → becomes leader
  5. Leader sends heartbeats to prevent new elections

Log replication:
  1. Client sends command to leader
  2. Leader appends to its log, sends AppendEntries to followers
  3. Followers append and acknowledge
  4. Leader commits once majority acknowledges
  5. Leader notifies followers of committed entries
```

#### When You Need Consensus

| Problem                         | Consensus needed? | Why                                |
| ------------------------------- | ----------------- | ---------------------------------- |
| Leader election                 | Yes               | Exactly one leader at a time       |
| Distributed lock                | Yes               | Mutual exclusion across nodes      |
| Configuration management        | Yes               | All nodes see same config          |
| Sequence number generation      | Yes               | Globally unique, ordered IDs       |
| Shopping cart (last-write-wins) | No                | Eventual consistency is acceptable |
| Metrics aggregation             | No                | Approximate counts are fine        |
| DNS caching                     | No                | TTL-based staleness is tolerable   |

Consensus is expensive (network round trips on every write). Avoid it when
eventual consistency or conflict-free replicated data types (CRDTs) suffice.

### Database Selection Guide

| Workload                 | Good Fit                     | Why                                  |
| ------------------------ | ---------------------------- | ------------------------------------ |
| OLTP, relational data    | PostgreSQL, MySQL            | ACID, joins, mature tooling          |
| High write throughput    | Cassandra, ScyllaDB          | LSM-tree, horizontal writes          |
| Document/flexible schema | MongoDB, CouchDB             | Schema-per-document, easy iteration  |
| Key-value, sub-ms reads  | Redis, DynamoDB              | In-memory or SSD-optimized           |
| Graph relationships      | Neo4j, Amazon Neptune        | Traversal queries, no join explosion |
| Time-series              | TimescaleDB, InfluxDB        | Compression, time-windowed queries   |
| Full-text search         | Elasticsearch, Meilisearch   | Inverted index, ranking              |
| NewSQL (OLTP + scale)    | CockroachDB, TiDB, Spanner   | ACID + horizontal sharding           |
| Analytical (OLAP)        | ClickHouse, DuckDB, BigQuery | Columnar storage, aggregate queries  |

#### ACID vs BASE

| Property     | ACID (Relational/NewSQL)        | BASE (NoSQL)                       |
| ------------ | ------------------------------- | ---------------------------------- |
| Consistency  | Strong (every read sees latest) | Eventual (replicas converge)       |
| Availability | May block during partition      | Prioritizes availability           |
| Transactions | Multi-row, multi-table          | Single-document or none            |
| Scale model  | Vertical or sharded (NewSQL)    | Horizontal by default              |
| Best for     | Financial, inventory, booking   | Social feeds, IoT, high-write logs |

NewSQL (CockroachDB, TiDB, Spanner) bridges the gap: ACID transactions with
automatic horizontal sharding. The trade-off is higher write latency from
distributed consensus on every commit.

#### Time-Series Databases

Time-series workloads differ from OLTP: writes are append-only, reads scan time
ranges, and old data compresses or ages out.

| Feature            | TimescaleDB               | InfluxDB                   |
| ------------------ | ------------------------- | -------------------------- |
| Built on           | PostgreSQL extension      | Custom storage engine      |
| Query language     | SQL                       | InfluxQL / Flux            |
| Compression        | Columnar, 90%+ on older   | Run-length, delta, Gorilla |
| Retention policies | Continuous aggregates     | Built-in retention rules   |
| Best for           | Teams already on Postgres | Metrics/IoT pipelines      |

Key concepts: downsampling (roll 1-second data into 1-minute averages),
retention policies (auto-delete data older than N days), and continuous
aggregates (pre-compute summaries as data arrives).

## Data Partitioning

### Horizontal vs Vertical

| Type       | Splits By        | Example                            | Trade-off                   |
| ---------- | ---------------- | ---------------------------------- | --------------------------- |
| Horizontal | Rows (sharding)  | Users 1-1M on shard A, 1M+ on B    | Cross-shard queries costly  |
| Vertical   | Columns/features | User profile on DB1, orders on DB2 | Joins require network calls |

### Partition Strategies

| Strategy        | How It Works                       | Pros                          | Cons                            |
| --------------- | ---------------------------------- | ----------------------------- | ------------------------------- |
| Range           | Split by key range (A-M, N-Z)      | Range queries stay local      | Hotspots if distribution skewed |
| Hash            | Hash key mod N partitions          | Even distribution             | Range queries span all shards   |
| Consistent hash | Hash to ring, virtual nodes        | Minimal rebalancing on resize | Complex implementation          |
| Directory       | Lookup table maps key to partition | Flexible placement            | Directory becomes bottleneck    |

### Rebalancing

| Trigger          | Strategy                               | Risk                               |
| ---------------- | -------------------------------------- | ---------------------------------- |
| Add node         | Move proportional slices from existing | Increased network during migration |
| Remove node      | Distribute orphaned data to remaining  | Temporary hotspots                 |
| Hotspot detected | Split hot partition, redistribute      | Application-level awareness needed |

## Capacity Estimation

### Reference Latencies

| Operation                         | Time      |
| --------------------------------- | --------- |
| L1 cache reference                | 1 ns      |
| L2 cache reference                | 4 ns      |
| Main memory reference             | 100 ns    |
| SSD random read                   | 16 us     |
| HDD random read                   | 4 ms      |
| Network round trip (same DC)      | 500 us    |
| Network round trip (cross-region) | 50-150 ms |
| Mutex lock/unlock                 | 100 ns    |

### Throughput Reference Points

| Resource              | Throughput        |
| --------------------- | ----------------- |
| SSD sequential read   | 500 MB/s - 3 GB/s |
| HDD sequential read   | 100-200 MB/s      |
| 1 Gbps network        | ~125 MB/s         |
| 10 Gbps network       | ~1.25 GB/s        |
| Postgres simple query | 10,000-50,000 QPS |
| Redis GET             | 100,000+ QPS      |
| nginx static file     | 50,000+ req/s     |

### Storage Estimation Template

```text
Users:            10M total, 1M DAU
Writes per user:  5/day
Write throughput:  5M / 86,400 ≈ 58 writes/sec
Read:write ratio: 10:1 → 580 reads/sec

Object size:      1 KB average
Daily storage:    5M * 1 KB = 5 GB/day
Annual storage:   5 GB * 365 ≈ 1.8 TB/year
With replication: 1.8 TB * 3 = 5.4 TB/year
```

### Powers of Two

| Power | Value | Approx     |
| ----- | ----- | ---------- |
| 10    | 1,024 | 1 Thousand |
| 20    | 1M    | 1 Million  |
| 30    | 1B    | 1 Billion  |
| 40    | 1T    | 1 Trillion |

Useful shortcut: 2^10 = ~10^3. So 2^30 = ~10^9 (1 billion).

### Time Conversions

| Period   | Seconds |
| -------- | ------- |
| 1 minute | 60      |
| 1 hour   | 3,600   |
| 1 day    | 86,400  |
| 1 month  | 2.6M    |
| 1 year   | 31.5M   |

## Message Queues

### Delivery Guarantees

| Guarantee     | Behavior                           | Use Case                 | Systems              |
| ------------- | ---------------------------------- | ------------------------ | -------------------- |
| At-most-once  | Send and forget, may lose messages | Metrics, logging         | UDP, fire-and-forget |
| At-least-once | Retry until ack, may duplicate     | Order processing, events | SQS, RabbitMQ        |
| Exactly-once  | Dedup at consumer or broker level  | Financial transactions   | Kafka (idempotent)   |

### Push vs Pull

| Model | Consumer Behavior           | Pros                   | Cons                        |
| ----- | --------------------------- | ---------------------- | --------------------------- |
| Push  | Broker sends to consumer    | Low latency            | Consumer can be overwhelmed |
| Pull  | Consumer polls for messages | Consumer controls pace | Polling overhead, latency   |

### Queue vs Stream

| Type   | Message Lifetime                 | Consumers                 | Example        |
| ------ | -------------------------------- | ------------------------- | -------------- |
| Queue  | Deleted after consumption        | One consumer per message  | SQS, RabbitMQ  |
| Stream | Retained for configurable period | Multiple consumers replay | Kafka, Kinesis |

## Common Patterns

| Pattern            | Problem It Solves                        | Trade-off                              |
| ------------------ | ---------------------------------------- | -------------------------------------- |
| Circuit breaker    | Cascading failures from failed service   | Fail-fast vs potential false positives |
| Bulkhead           | One component consuming all resources    | Resource isolation vs utilization      |
| Saga               | Distributed transactions across services | Complexity vs data consistency         |
| CQRS               | Read/write models need different schemas | Operational cost vs query performance  |
| Event sourcing     | Audit trail, temporal queries            | Storage cost vs complete history       |
| Sidecar            | Cross-cutting concerns (logging, auth)   | Extra process vs code reuse            |
| Strangler fig      | Incremental migration from monolith      | Dual maintenance vs big-bang risk      |
| Backpressure       | Producer faster than consumer            | Throttled throughput vs data loss      |
| Retry with backoff | Transient failures                       | Recovery time vs thundering herd       |
| Idempotency key    | Duplicate requests cause double writes   | Storage overhead vs data correctness   |

### Circuit Breaker States

```text
        success
  ┌───────────────┐
  v               │
CLOSED ──fail──> OPEN ──timeout──> HALF-OPEN
  ^                                    │
  └──────────success───────────────────┘
                  │
              fail│
                  v
                OPEN
```

- **Closed**: Requests pass through. Track failure count.
- **Open**: Requests fail immediately. Wait for timeout.
- **Half-open**: Allow one test request. Success closes; failure reopens.

### Saga Pattern (Choreography vs Orchestration)

| Style         | Coordination                      | Pros                       | Cons                    |
| ------------- | --------------------------------- | -------------------------- | ----------------------- |
| Choreography  | Services emit events, peers react | Loose coupling, simple     | Hard to trace, debug    |
| Orchestration | Central coordinator directs steps | Clear flow, easy to reason | Single point of failure |

### CQRS

```text
                 ┌─── Write Model ─── Event Store
Command ────────>│
                 └─── Projection ──── Read Model ────> Query
```

Separate the write path (optimized for validation, business rules) from the read
path (optimized for queries, denormalized views).

## Monitoring and Observability

### RED Method (Request-driven services)

| Signal   | Measures                   | Example Metric                  |
| -------- | -------------------------- | ------------------------------- |
| Rate     | Requests per second        | `http_requests_total`           |
| Errors   | Failed requests per second | `http_errors_total`             |
| Duration | Time per request           | `http_request_duration_seconds` |

### USE Method (Resources: CPU, memory, disk, network)

| Signal      | Measures                    | Example Metric                 |
| ----------- | --------------------------- | ------------------------------ |
| Utilization | Percentage of resource used | `cpu_usage_percent`            |
| Saturation  | Queue depth, waiting work   | `disk_io_queue_length`         |
| Errors      | Resource-level error events | `network_receive_errors_total` |

### The Four Golden Signals (Google SRE)

| Signal     | What to Measure         | Alert When                   |
| ---------- | ----------------------- | ---------------------------- |
| Latency    | Time to serve requests  | p99 exceeds SLO              |
| Traffic    | Requests per second     | Sudden drop or spike         |
| Errors     | Rate of failed requests | Error rate exceeds threshold |
| Saturation | How full the service is | Approaching resource limits  |

### SLI / SLO / SLA

| Term | Definition                         | Example                              |
| ---- | ---------------------------------- | ------------------------------------ |
| SLI  | Service Level Indicator (metric)   | 99.2% of requests < 200ms            |
| SLO  | Service Level Objective (target)   | 99.9% of requests < 200ms            |
| SLA  | Service Level Agreement (contract) | Refund if uptime < 99.95% in a month |

### Availability Nines

| Nines   | Uptime    | Downtime/year | Downtime/month |
| ------- | --------- | ------------- | -------------- |
| 99%     | Two nines | 3.65 days     | 7.3 hours      |
| 99.9%   | Three     | 8.76 hours    | 43.8 min       |
| 99.99%  | Four      | 52.6 min      | 4.38 min       |
| 99.999% | Five      | 5.26 min      | 26.3 sec       |

### Distributed Tracing

```text
Client ─── Gateway ─── Service A ─── Service B ─── Database
  │           │            │             │            │
  └───────────┴────────────┴─────────────┴────────────┘
                     Trace ID: abc-123
                     propagated through all hops
```

Each service adds a span with timing, metadata, and parent span ID. Tools:
Jaeger, Zipkin, OpenTelemetry.

## Anti-patterns

| Anti-pattern             | Problem                                      | Fix                                          |
| ------------------------ | -------------------------------------------- | -------------------------------------------- |
| Premature distribution   | Added complexity before measuring need       | Measure, then scale                          |
| Shared mutable state     | Distributed locking kills throughput         | Partition data, use message passing          |
| Distributed monolith     | Microservices with tight coupling            | Define clear contracts, deploy independently |
| No backpressure          | Fast producers crash slow consumers          | Add queues, rate limit upstream              |
| Synchronous chains       | A calls B calls C -- latency compounds       | Use async messaging where possible           |
| Ignoring cold start      | Empty caches cause thundering herd at deploy | Cache warming, gradual traffic shift         |
| Single point of failure  | One component takes down the whole system    | Redundancy at every layer                    |
| Optimistic capacity plan | "We'll scale later" with no headroom         | Plan for 3-5x peak, test at 2x               |

## See Also

- [System Design Lesson Plan](../learn/system-design-lesson-plan.md) — 8
  progressive lessons with hands-on exercises
- [Kubernetes](k8s.md) — Container orchestration, deployments, services
- [Docker](docker.md) — Images, containers, Compose
- [API Design](../why/api-design.md) — REST, GraphQL, gRPC, pagination,
  versioning
- [Authentication](authentication.md) — Sessions, OAuth2, JWT, SSO, API keys
- [Resilience](../why/resilience.md) — Failure modes, chaos engineering, circuit
  breaker mental models
