---
title: "Resilience"
description:
  "Failure modes, chaos engineering, circuit breakers, and the mental models
  that make distributed systems survive real-world conditions"
---

<!-- prettier-ignore -->
:::tip[Lesson Plan]
Looking to learn system design step by step? See the
[System Design Lesson Plan](../learn/system-design-lesson-plan.md).
:::

## Quick Reference

| Principle               | One-liner                                               |
| ----------------------- | ------------------------------------------------------- |
| Everything fails        | Design for failure, not against it                      |
| Blast radius            | Limit how far a failure can spread                      |
| Steady-state hypothesis | Define "normal" before breaking things                  |
| Graceful degradation    | Serve partial results over complete failure             |
| Fail-fast               | Detect failure early, propagate it immediately          |
| Defense in depth        | No single mechanism prevents all failures               |
| Recovery > prevention   | Mean time to recovery matters more than time to failure |

## Why Systems Fail

Systems fail not because individual components are fragile, but because failures
_compose_. A slow database query triggers a thread pool exhaustion that causes a
health check timeout that triggers a cascading restart.

### Failure Taxonomy

| Type               | Description                                        | Example                                |
| ------------------ | -------------------------------------------------- | -------------------------------------- |
| Crash failure      | Process dies                                       | OOM kill, unhandled exception          |
| Omission failure   | Component fails to send or receive                 | Dropped packets, full queue            |
| Timing failure     | Response arrives outside expected window           | GC pause, cold cache after deploy      |
| Byzantine failure  | Component behaves arbitrarily (including lying)    | Corrupted memory, compromised node     |
| Gray failure       | Degraded but still passing health checks           | Slow disk, partial network partition   |
| Cascading failure  | One failure triggers failures in dependent systems | DB slow → thread exhaustion → timeout  |
| Correlated failure | Single cause affects multiple components           | AZ outage, shared dependency, bad push |

Gray failures are the most dangerous -- the system appears healthy to monitoring
while users experience degraded service.

### Cascading Failure Anatomy

```text
DB slow (50ms → 2s)
  → App thread pool fills (waiting for DB)
    → Requests queue at load balancer
      → Health checks timeout
        → LB removes "unhealthy" servers
          → Remaining servers receive ALL traffic
            → They overload too
              → Total outage
```

Breaking the cascade: timeout each stage, shed load early, maintain
backpressure.

## Resilience Patterns

### Pattern Comparison

| Pattern         | Protects Against     | Mechanism                             | Trade-off                       |
| --------------- | -------------------- | ------------------------------------- | ------------------------------- |
| Circuit breaker | Cascading failure    | Stop calling failed dependency        | Fail-fast vs missed recovery    |
| Bulkhead        | Resource exhaustion  | Isolate resource pools per service    | Utilization vs isolation        |
| Timeout         | Unbounded waits      | Fail after deadline                   | Responsiveness vs false failure |
| Retry + backoff | Transient failures   | Retry with exponential delay + jitter | Recovery vs thundering herd     |
| Retry budget    | Retry storms         | Cap total retries across all callers  | Recovery vs amplification       |
| Rate limiting   | Overload             | Reject requests beyond threshold      | Stability vs user experience    |
| Load shedding   | Overload at capacity | Drop low-priority work first          | Availability vs completeness    |
| Fallback        | Dependency failure   | Return cached/default response        | Freshness vs availability       |
| Idempotency     | Duplicate requests   | Same input → same effect              | Storage vs correctness          |

### Timeouts: Choosing Values

```text
                    Read timeout = p99 of dependency + buffer
                    Connect timeout = much shorter (100-500ms)
                    Total timeout = end-user patience minus upstream hops

Rule of thumb:
  - Internal service call: 1-5s
  - Database query: 5-30s
  - External API: 5-10s
  - User-facing request: 200ms-2s total budget
```

Set timeouts at every network boundary. A missing timeout is an unbounded wait
that will surface during the worst possible moment.

### Retry Strategies

| Strategy             | Formula                           | Use Case                   |
| -------------------- | --------------------------------- | -------------------------- |
| Fixed delay          | Wait N seconds between retries    | Simple, predictable        |
| Exponential backoff  | Wait 2^attempt seconds            | Standard for most services |
| Exponential + jitter | 2^attempt \* random(0.5, 1.5)     | Prevents thundering herd   |
| Retry budget         | Max N% of requests can be retries | Prevents retry storms      |

Never retry non-idempotent operations without an idempotency key. Never retry
4xx errors (client bug, not transient). Always set a maximum retry count.

## Chaos Engineering

Chaos engineering is the discipline of experimenting on a system to build
confidence in its ability to withstand turbulent conditions in production.

### The Process

```text
1. Define steady state — what does "working" look like?
   (Error rate < 0.1%, p99 < 200ms, orders processing)

2. Hypothesize — "If we kill one Redis node, the system
   continues serving from the replica within 5 seconds"

3. Inject failure — kill the node, inject latency, drop packets

4. Observe — did the system maintain steady state?

5. Learn — if not, fix and re-test. If yes, increase blast radius.
```

### Failure Injection Techniques

| Technique              | What It Tests                      | Tools                            |
| ---------------------- | ---------------------------------- | -------------------------------- |
| Kill process/container | Crash recovery, restart policies   | `kill -9`, Docker stop           |
| Network latency        | Timeout handling, circuit breakers | `tc netem`, Toxiproxy            |
| Packet loss/corruption | Retry logic, error handling        | `tc netem`, Chaos Mesh           |
| DNS failure            | Fallback resolution, caching       | Block DNS, `/etc/hosts`          |
| Disk full              | Graceful degradation, alerting     | `fallocate`, Litmus              |
| Clock skew             | Lease expiry, token validation     | `faketime`, Chaos Mesh           |
| AZ/region failure      | Multi-AZ failover                  | Disable AZ routing               |
| CPU/memory pressure    | Autoscaling, OOM handling          | `stress-ng`, Chaos Monkey        |
| Dependency slowdown    | Timeout + fallback behavior        | Toxiproxy, Envoy fault injection |

### Blast Radius Control

Start small and expand:

| Level      | Scope             | Example                                   |
| ---------- | ----------------- | ----------------------------------------- |
| 1. Dev     | Local environment | Kill a container in Docker Compose        |
| 2. Staging | Non-production    | Inject latency into staging load balancer |
| 3. Canary  | Small % of prod   | Fail 1% of requests to a single service   |
| 4. Prod    | Full production   | Kill an AZ during business hours          |

Most teams never need level 4. Levels 1-3 catch the majority of resilience gaps.

### Game Days

A game day is a scheduled chaos experiment with the full team:

1. **Announce** — everyone knows it is happening, no surprise outages
2. **Define scope** — which systems, what failures, what is off-limits
3. **Run the experiment** — inject failure, observe dashboards
4. **Respond as in production** — oncall triages, team communicates
5. **Debrief** — what broke, what held, what do we fix

Game days test not just the system but the team's incident response.

## Observability for Resilience

Resilience requires visibility. You cannot recover from what you cannot detect.

### Detection Hierarchy

| Signal           | Detects                           | Latency          |
| ---------------- | --------------------------------- | ---------------- |
| Synthetic probes | Endpoint down, degraded response  | Seconds          |
| Error rate spike | Bug, dependency failure           | 1-5 minutes      |
| Latency shift    | Gray failure, resource pressure   | 1-5 minutes      |
| Saturation alert | Approaching capacity limits       | Minutes          |
| Log anomaly      | Unusual patterns, new error types | Varies           |
| Customer reports | Anything monitoring missed        | Hours (too late) |

Alert on symptoms (error rate, latency), not causes (CPU, disk). Cause-based
alerts generate noise; symptom-based alerts catch problems regardless of root
cause.

### SLO-Based Alerting

Define an error budget from your SLO, then alert when you are burning through it
too fast:

```text
SLO: 99.9% availability (43.8 min/month budget)

Burn rate alert thresholds:
  - 14.4x burn rate over 1h  → page (budget gone in 5 hours)
  - 6x burn rate over 6h     → page (budget gone in 12 hours)
  - 1x burn rate over 3 days → ticket (on track to miss SLO)
```

## Anti-patterns

| Anti-pattern               | Problem                                        | Fix                                            |
| -------------------------- | ---------------------------------------------- | ---------------------------------------------- |
| Retry without backoff      | Amplifies load during failures                 | Exponential backoff with jitter                |
| Retry without budget       | Every caller retries, creating a retry storm   | Cap retries as % of total traffic              |
| No timeout                 | Thread/connection held indefinitely            | Timeout at every network boundary              |
| Health check that lies     | Returns 200 while dependencies are down        | Deep health checks that test critical paths    |
| Chaos without steady state | Breaking things without knowing what "good" is | Define metrics baseline before injecting chaos |
| Testing only in staging    | Staging never matches production topology      | Graduate chaos from staging to canary to prod  |
| Ignoring gray failures     | System "up" but degraded for subset of users   | Synthetic probes, percentile-based alerting    |
| Single point of failure    | One component takes everything down            | Redundancy at every layer, test failover       |
| Manual failover            | Depends on human speed at 3 a.m.               | Automate failover, test it with chaos          |

## See Also

- [System Design](../how/system-design.md) — Circuit breaker states, load
  balancing, caching patterns
- [Debugging](debugging.md) — Scientific method applied to failures
- [Observability](observability.md) -- The telemetry that catches these failure
  modes in production
- [Specification](specification.md) — Defining what "correct" means before
  testing resilience
- [Orchestration](orchestration.md) — Failure modes in multi-agent and
  distributed coordination
- [Testing](testing.md) — Testing pyramid, integration tests that exercise
  failure paths
- [AI Safety](ai-safety.md) — Defense in depth and failure modes applied to
  LLM-powered systems
