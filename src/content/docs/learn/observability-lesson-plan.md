---
title: "Observability Lesson Plan"
description:
  Eight lessons from structured logs to burn-rate alerting, covering Prometheus,
  Grafana, OpenTelemetry tracing, SLOs, and incident debugging.
---

Build the instrumentation, then use it the way an on-call engineer does -- eight
lessons from a single JSON log line to a paged burn-rate alert and the incident
report that follows.

<!-- prettier-ignore -->
:::note[Prerequisites]
The [System Design Lesson Plan](system-design-lesson-plan.md) (Lesson 7
introduces these ideas), basic [Docker](../how/docker.md), and
[jq](../how/jq.md). Exercises run on macOS with Python 3 and Docker Desktop.
:::

## Lesson 1: Structured Logging

**Goal:** Emit logs as queryable data, follow one request across services with a
correlation ID, and answer incident questions with jq.

### Concepts

A log line exists to be queried during an incident, and `grep` over prose does
not scale to that moment. Structured logging means one JSON object per line with
consistent keys: `timestamp`, `level`, `message`, a `request_id` stamped on
every line a request touches, and measurements with units in the key name
(`duration_ms`). The correlation ID is the load-bearing field -- generated at
the edge, passed to every downstream call, it turns three services' logs into
one story. Levels are a retention and cost policy, not decoration: `debug` off
in production, `info` for state changes, `error` for things a human may need to
act on.

### Exercises

1. **Generate two services' worth of structured logs**

   ```python
   # loggen.py -- gateway + backend logs with an injected incident
   import json, random, uuid

   random.seed(42)
   gateway, backend = [], []

   for minute in range(60):  # one hour, starting 14:00
       ts = f"2026-01-15T14:{minute:02d}"
       for _ in range(random.randint(40, 60)):
           rid = uuid.uuid4().hex[:8]
           path = random.choice(
               ["/api/orders", "/api/users", "/api/search", "/health"])
           # incident: backend degrades for /api/orders, minutes 20-30
           incident = 20 <= minute < 30 and path == "/api/orders"
           backend_ms = random.expovariate(1 / 40)
           if incident and random.random() < 0.6:
               backend_ms = random.uniform(2000, 5000)
           failed = backend_ms > 1900   # gateway timeout at ~2s
           backend.append({
               "timestamp": f"{ts}:{random.randint(0,59):02d}",
               "level": "error" if failed else "info",
               "service": "backend", "request_id": rid, "path": path,
               "duration_ms": round(backend_ms, 1),
               "message": "timeout waiting on db" if failed else "ok",
           })
           gateway.append({
               "timestamp": f"{ts}:{random.randint(0,59):02d}",
               "level": "error" if failed else "info",
               "service": "gateway", "request_id": rid, "path": path,
               "status": 502 if failed else 200,
               "duration_ms": round(min(backend_ms, 2000) + 3, 1),
           })

   for name, lines in [("gateway", gateway), ("backend", backend)]:
       with open(f"/tmp/{name}.log", "w") as f:
           for line in lines:
               f.write(json.dumps(line) + "\n")
   print(f"wrote {len(gateway)} gateway + {len(backend)} backend lines")
   ```

   ```bash
   python3 loggen.py
   head -2 /tmp/gateway.log | jq .
   ```

2. **Answer the first responder questions**

   ```bash
   # Which endpoint is failing?
   jq -r 'select(.status == 502) | .path' /tmp/gateway.log \
     | sort | uniq -c | sort -rn

   # When did it start and stop? (errors per minute)
   jq -r 'select(.status == 502) | .timestamp[0:16]' /tmp/gateway.log \
     | sort | uniq -c

   # How bad is it? Error ratio for /api/orders during the window
   jq -s '[.[] | select(.path == "/api/orders"
            and (.timestamp >= "2026-01-15T14:20")
            and (.timestamp <  "2026-01-15T14:30"))]
          | (map(select(.status == 502)) | length) / length * 100
          | round' /tmp/gateway.log
   ```

3. **Cross the service boundary with the correlation ID**

   ```bash
   # Take one failed request at the gateway...
   RID=$(jq -r 'select(.status == 502) | .request_id' /tmp/gateway.log \
     | head -1)

   # ...and read its story in the backend
   jq --arg rid "$RID" 'select(.request_id == $rid)' \
     /tmp/gateway.log /tmp/backend.log

   # Confirm every gateway 502 is a backend timeout, not a gateway bug
   jq -r 'select(.status == 502) | .request_id' /tmp/gateway.log \
     | sort > /tmp/gw_failed
   jq -r 'select(.message == "timeout waiting on db") | .request_id' \
     /tmp/backend.log | sort > /tmp/be_failed
   comm -3 /tmp/gw_failed /tmp/be_failed | wc -l   # 0 = perfect overlap
   ```

4. **Compute latency percentiles from logs**

   ```bash
   # p50 / p95 / p99 for the backend, healthy vs incident window
   for window in "14:00 14:20" "14:20 14:30"; do
     set -- $window
     jq -s --arg a "2026-01-15T$1" --arg b "2026-01-15T$2" '
       [.[] | select(.path == "/api/orders"
              and .timestamp >= $a and .timestamp < $b)
            | .duration_ms] | sort
       | {window: $a, n: length,
          p50: .[length*0.50 | floor],
          p95: .[length*0.95 | floor],
          p99: .[length*0.99 | floor]}' /tmp/backend.log
   done
   ```

### Checkpoint

Using only jq against the two log files, produce the incident summary: the
failing endpoint, start and end minute, error ratio during the window, p95
before vs during, and one request ID whose gateway and backend lines tell the
whole story. Time yourself -- this is the fluency the rest of the plan builds
on.

---

## Lesson 2: Metrics and Instrumentation

**Goal:** Instrument a service with counters, gauges, and histograms, read the
Prometheus exposition format, and understand what histogram buckets actually
store.

### Concepts

Logs record events; metrics record aggregates cheap enough to keep forever and
query in milliseconds. Three types cover nearly everything. A counter only
increases -- `rate()` later extracts its slope, so resets on restart are
harmless. A gauge is a value that moves both ways: queue depth, in-flight
requests, temperature. A histogram counts observations into cumulative buckets
(`le="0.1"` holds everything at or under 100ms), trading exact values for fixed
cost -- percentiles come from interpolating between bucket boundaries, which is
why bucket layout should straddle your SLO threshold. The RED method names the
three service metrics that matter: Rate, Errors, Duration. USE covers resources:
Utilization, Saturation, Errors.

### Exercises

1. **Instrument a simulated service**

   ```python
   # app_metrics.py
   import os, random, time
   from prometheus_client import (Counter, Gauge, Histogram,
                                  start_http_server)

   REQUESTS = Counter("http_requests_total", "Total requests",
                      ["method", "path", "status"])
   IN_FLIGHT = Gauge("http_requests_in_flight", "Active requests")
   LATENCY = Histogram(
       "http_request_duration_seconds", "Latency", ["path"],
       buckets=[0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5])

   ERROR_RATE = float(os.environ.get("APP_ERROR_RATE", "0.02"))
   SLOWDOWN = float(os.environ.get("APP_SLOWDOWN", "1.0"))

   start_http_server(8000)
   print(f"serving /metrics on :8000 "
         f"(error_rate={ERROR_RATE}, slowdown={SLOWDOWN})")

   while True:
       path = random.choice(["/api/orders", "/api/users", "/api/search"])
       IN_FLIGHT.inc()
       with LATENCY.labels(path=path).time():
           time.sleep(random.expovariate(1 / 0.04) * SLOWDOWN)
       status = "500" if random.random() < ERROR_RATE else "200"
       REQUESTS.labels("GET", path, status).inc()
       IN_FLIGHT.dec()
   ```

   ```bash
   pip3 install prometheus-client
   python3 app_metrics.py &
   sleep 5
   curl -s localhost:8000/metrics | grep http_requests_total
   ```

2. **Read the exposition format**

   ```bash
   curl -s localhost:8000/metrics | grep -A3 '# TYPE http_request_duration'
   # Buckets are CUMULATIVE: le="0.1" includes le="0.05".
   # _sum / _count gives the mean; buckets give percentiles.

   # Watch a counter only ever climb
   for i in 1 2 3; do
     curl -s localhost:8000/metrics \
       | awk '/^http_requests_total.*200/ {s += $2} END {print s}'
     sleep 2
   done
   ```

3. **Compute a percentile from buckets by hand**

   ```python
   # quantile_by_hand.py -- what histogram_quantile() actually does
   import urllib.request, re

   text = urllib.request.urlopen(
       "http://localhost:8000/metrics").read().decode()
   buckets = {}
   for le, path, value in re.findall(
           r'http_request_duration_seconds_bucket{le="([^"]+)",'
           r'path="([^"]+)"} (\S+)', text):
       if path == "/api/orders":
           buckets[float("inf") if le == "+Inf" else float(le)] = \
               float(value)

   bounds = sorted(buckets)
   total = buckets[bounds[-1]]
   target = total * 0.95
   prev_bound, prev_count = 0.0, 0.0
   for bound in bounds:
       if buckets[bound] >= target:
           # linear interpolation inside the winning bucket
           fraction = (target - prev_count) / (buckets[bound] - prev_count)
           p95 = prev_bound + fraction * (bound - prev_bound)
           print(f"p95 ~= {p95*1000:.1f}ms "
                 f"(bucket {prev_bound}-{bound}s, n={total:.0f})")
           break
       prev_bound, prev_count = bound, buckets[bound]
   ```

   ```bash
   python3 quantile_by_hand.py
   # The answer is an estimate bounded by bucket edges -- percentile
   # accuracy IS bucket layout.
   ```

4. **Blow up cardinality on purpose**

   ```python
   # cardinality.py
   from prometheus_client import Counter, generate_latest
   import uuid

   BAD = Counter("lookups_total", "Lookups", ["user_id"])
   for _ in range(5000):
       BAD.labels(user_id=uuid.uuid4().hex[:12]).inc()

   payload = generate_latest()
   print(f"exposition size: {len(payload)/1024:.0f} KB")
   print(f"series created:  {payload.count(b'lookups_total{')}")
   print("every scrape ships all of this, every 5 seconds, forever")
   ```

   ```bash
   python3 cardinality.py
   # 5,000 users made 5,000 series from ONE metric. Route "which
   # user" questions to logs and traces; keep labels bounded.
   ```

### Checkpoint

State which metric type you would use for: queue depth, bytes served, p99
checkout latency, and current WebSocket connections -- then explain why `rate()`
on a gauge is meaningless and what bucket layout you would choose for a 250ms
latency SLO. Verify the bucket answer against your hand-computed percentile.

---

## Lesson 3: Prometheus and PromQL

**Goal:** Run Prometheus against your instrumented service and answer the RED
questions in PromQL.

### Concepts

Prometheus pulls: it scrapes every target's `/metrics` on an interval, stores
samples locally, and evaluates PromQL over the result. Pull means the monitor
notices a dead target (`up == 0`) instead of silently receiving nothing.
PromQL's core move is turning counters into rates over a window (`rate(x[5m])`),
then aggregating with `sum by (label)`. Percentiles come from
`histogram_quantile()` over bucket rates, and the `le` label must survive your
aggregation or the math dies. Recording rules precompute expensive expressions
on a schedule -- dashboards and alerts then read the cheap result. The window
length is a tradeoff: short windows react fast and jitter; long windows smooth
and lag.

### Exercises

1. **Scrape your app**

   ```bash
   cat > /tmp/prometheus.yml <<'EOF'
   global:
     scrape_interval: 5s
   scrape_configs:
     - job_name: app
       static_configs:
         - targets: ["host.docker.internal:8000"]
   EOF

   docker run -d --name prom -p 9090:9090 \
     -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
     prom/prometheus
   open http://localhost:9090/targets    # state should be UP
   ```

2. **Ask the RED questions**

   ```text
   Run each in the Prometheus graph UI (localhost:9090/graph):

   # Rate: requests per second, by path
   sum by (path) (rate(http_requests_total[1m]))

   # Errors: ratio of 5xx
   sum(rate(http_requests_total{status="500"}[1m]))
     / sum(rate(http_requests_total[1m]))

   # Duration: p50 and p99 for /api/orders
   histogram_quantile(0.99, sum by (le) (
     rate(http_request_duration_seconds_bucket{path="/api/orders"}[1m])))

   # Saturation proxy: requests in flight
   http_requests_in_flight
   ```

3. **Change reality, watch the queries follow**

   ```bash
   # Restart the app degraded: 20% errors, 3x slower
   kill %1
   APP_ERROR_RATE=0.2 APP_SLOWDOWN=3 python3 app_metrics.py &

   # Re-run the error ratio and p99 queries over the next 2 minutes.
   # Note the lag: a 1m rate window takes ~1 minute to fully reflect
   # the new world. Try [15s] and [5m] windows and compare shapes.
   ```

4. **Precompute with recording rules**

   ```bash
   cat > /tmp/rules.yml <<'EOF'
   groups:
     - name: service
       interval: 15s
       rules:
         - record: service:error_ratio:rate1m
           expr: |
             sum(rate(http_requests_total{status="500"}[1m]))
               / sum(rate(http_requests_total[1m]))
         - record: path:p99_seconds:rate5m
           expr: |
             histogram_quantile(0.99, sum by (path, le) (
               rate(http_request_duration_seconds_bucket[5m])))
   EOF

   cat >> /tmp/prometheus.yml <<'EOF'
   rule_files:
     - /etc/prometheus/rules.yml
   EOF

   docker rm -f prom
   docker run -d --name prom -p 9090:9090 \
     -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
     -v /tmp/rules.yml:/etc/prometheus/rules.yml \
     prom/prometheus

   # Query the recorded series by name:
   #   service:error_ratio:rate1m
   ```

### Checkpoint

With the app running degraded, produce the four RED answers (rate by path, error
ratio, p99, in-flight) as PromQL plus the observed value, and explain what the
`[1m]` window did to how quickly each answer reflected the degradation you
injected.

---

## Lesson 4: Dashboards That Answer Questions

**Goal:** Build a RED dashboard for the service and a USE view of the host,
where every panel is titled with the question it answers.

### Concepts

A dashboard is a pre-computed investigation, and the failure mode is the vanity
wall: forty panels, none of which anyone can act on. Discipline comes from the
two methods. For each service, three RED panels: request rate, error ratio,
duration percentiles -- the user's experience. For each resource, three USE
panels: utilization, saturation, errors -- the machine's experience. Title
panels with the question ("Are users seeing errors?"), not the metric name, so
3am-you knows why the panel exists. Template variables (`$path`, `$instance`)
make one dashboard serve every instance. If a panel never changed a decision,
delete it; every panel is a maintenance liability that must earn its place.

### Exercises

1. **Run Grafana and connect Prometheus**

   ```bash
   docker run -d --name grafana -p 3000:3000 grafana/grafana
   open http://localhost:3000     # login admin / admin

   # Connections -> Data sources -> Add data source -> Prometheus
   # URL: http://host.docker.internal:9090  -> Save & test
   ```

2. **Build the RED dashboard**

   ```text
   New dashboard -> three panels, one per question:

   "How much traffic?"        sum by (path) (rate(http_requests_total[1m]))
   "Are users seeing errors?" service:error_ratio:rate1m
                              (unit: percent 0-1, threshold at 0.001)
   "How slow is it?"          path:p99_seconds:rate5m
                              (unit: seconds; add p50 as second query)

   Add a $path variable: Dashboard settings -> Variables ->
   label_values(http_requests_total, path), then filter panel
   queries with {path=~"$path"}.
   ```

3. **Add the USE view of your host**

   ```bash
   brew install node_exporter
   brew services start node_exporter
   curl -s localhost:9100/metrics | head -5

   cat >> /tmp/prometheus.yml <<'EOF'
     - job_name: host
       static_configs:
         - targets: ["host.docker.internal:9100"]
   EOF
   docker restart prom
   ```

   ```text
   Three more panels:

   "CPU utilization"   1 - avg(rate(node_cpu_seconds_total{mode="idle"}[1m]))
   "CPU saturation"    node_load1 / count(node_cpu_seconds_total{mode="idle"})
   "Disk almost full?" node_filesystem_avail_bytes{mountpoint="/"}
                         / node_filesystem_size_bytes{mountpoint="/"}
   ```

4. **Audit a dashboard like a reviewer**

   ```text
   For each panel on your board, answer in one line:
   1. What question does it answer?
   2. Who looks at it, and when?
   3. What decision changes based on it?

   Any panel with a blank line 3 gets deleted or demoted to an
   "investigation" folder. Re-title survivors as questions. This
   audit, run quarterly, is what keeps dashboards trustworthy.
   ```

### Checkpoint

Demonstrate the degraded-app scenario from Lesson 3 on your dashboard: which
panel moves first, which confirms user impact, and which rules out host
saturation as the cause. Every panel involved must be titled as a question.

---

## Lesson 5: Distributed Tracing

**Goal:** Trace one request across two services with OpenTelemetry, find where
the latency lives in Jaeger, and understand context propagation.

### Concepts

Metrics say the p99 is bad; traces say which of the six downstream calls made it
bad. A trace is a tree of spans -- each span one timed operation, carrying
attributes -- sharing a trace ID that travels between services in the
`traceparent` HTTP header. Propagation is the fragile part: any hop that drops
the header (a proxy, a queue, a hand-rolled HTTP client) splits the story into
orphans. OpenTelemetry is the vendor-neutral standard: auto-instrumentation
wraps the libraries you already use, manual spans mark the operations only you
know matter, and attributes carry the high-cardinality detail (customer, cart
size, feature flag) that metrics cannot afford. Sampling keeps the bill sane --
head sampling decides at the root cheaply; tail sampling keeps the interesting
traces at the cost of buffering.

### Exercises

1. **Run two services under auto-instrumentation**

   ```python
   # backend.py
   import random, time
   from flask import Flask

   app = Flask(__name__)

   @app.get("/inventory")
   def inventory():
       time.sleep(random.expovariate(1 / 0.02))
       if random.random() < 0.15:
           time.sleep(0.5)          # the slow dependency path
       return {"in_stock": True}

   app.run(port=5001)
   ```

   ```python
   # gateway.py
   import requests
   from flask import Flask

   app = Flask(__name__)

   @app.get("/checkout")
   def checkout():
       r = requests.get("http://localhost:5001/inventory")
       return {"ok": r.json()["in_stock"]}

   app.run(port=5000)
   ```

   ```bash
   pip3 install flask requests \
     opentelemetry-distro opentelemetry-exporter-otlp
   opentelemetry-bootstrap -a install

   docker run -d --name jaeger \
     -p 16686:16686 -p 4317:4317 -p 4318:4318 \
     jaegertracing/all-in-one

   OTEL_SERVICE_NAME=backend \
     OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 \
     opentelemetry-instrument python3 backend.py &
   OTEL_SERVICE_NAME=gateway \
     OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 \
     opentelemetry-instrument python3 gateway.py &

   for i in $(seq 1 60); do curl -s localhost:5000/checkout >/dev/null; done
   open http://localhost:16686
   ```

2. **Find the latency**

   ```text
   In Jaeger: service "gateway" -> Find Traces. Sort by duration.

   1. Open a ~40ms trace and a ~540ms trace side by side.
   2. Both show gateway -> backend. In the slow one, which span
      holds the extra 500ms?
   3. Note what the gateway span alone could never tell you: the
      slowness is INSIDE backend's handler, not the network hop.
   ```

3. **Add a manual span with searchable attributes**

   ```python
   # In backend.py, wrap the slow path:
   from opentelemetry import trace
   tracer = trace.get_tracer("backend")

   @app.get("/inventory")
   def inventory():
       time.sleep(random.expovariate(1 / 0.02))
       if random.random() < 0.15:
           with tracer.start_as_current_span("warehouse_fallback") as span:
               span.set_attribute("warehouse.region", "us-east-1")
               span.set_attribute("cache.hit", False)
               time.sleep(0.5)
       return {"in_stock": True}
   ```

   ```bash
   # Restart backend, send traffic, then search in Jaeger:
   #   Tags: cache.hit=false
   # Every slow trace is now findable by WHY it was slow.
   ```

4. **Watch propagation work, then break it**

   ```python
   # peek.py -- see the header that carries the trace
   from flask import Flask, request

   app = Flask(__name__)

   @app.get("/peek")
   def peek():
       return {"traceparent": request.headers.get("traceparent", "MISSING")}

   app.run(port=5002)
   ```

   ```bash
   OTEL_SERVICE_NAME=peek \
     OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 \
     opentelemetry-instrument python3 peek.py &

   # Instrumented caller propagates:
   python3 -c "
   import requests
   print(requests.get('http://localhost:5002/peek').json())" | cat
   # Run that same snippet under opentelemetry-instrument and compare:
   # bare python has no traceparent; instrumented python injects one.
   # Format: 00-<trace_id 32hex>-<span_id 16hex>-<flags>
   ```

### Checkpoint

From Jaeger alone: report what fraction of gateway request time the backend
consumes in the healthy case, name the span responsible for slow requests and
the attribute that identifies its cause, and explain what the trace tree would
look like if a proxy between the services dropped `traceparent`.

---

## Lesson 6: SLOs and Error Budgets

**Goal:** Define SLIs from user journeys, set an SLO, and compute how fast an
incident spends the error budget.

### Concepts

An SLI measures what a user experiences: the fraction of requests that succeeded
fast enough. An SLO is the target you commit to (99.9% over 30 days), chosen by
asking how much failure users tolerate before they notice and leave -- not by
asking what the system currently achieves. Everything above the target is error
budget, and the budget is a spending account: deploys, migrations, and
experiments all draw from it, and an empty account pauses risk-taking by
pre-agreed policy rather than by argument. Burn rate makes budgets operational:
burn 1x and the budget lasts exactly the window; burn 14.4x and a 30-day budget
dies in 50 hours. Fast burns page a human; slow burns file a ticket. The SLO
document -- SLI definition, target, window, and exhaustion policy -- is the
deliverable that makes all of this real.

### Exercises

1. **Derive SLIs from user journeys**

   ```text
   For the checkout service (gateway + backend from Lesson 5):

   Journey: "user completes checkout"
   SLI 1 (availability): non-5xx responses / all responses
   SLI 2 (latency): responses under 500ms / all responses

   Write the PromQL for each:
   sum(rate(http_requests_total{status!~"5.."}[5m]))
     / sum(rate(http_requests_total[5m]))

   sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m]))
     / sum(rate(http_request_duration_seconds_count[5m]))

   Note the trick: a histogram bucket IS a latency SLI numerator.
   Pick bucket boundaries at your SLO threshold or this stops
   working.
   ```

2. **Compute budget spend from a month of traffic**

   ```python
   # budget.py
   import random

   random.seed(9)
   SLO = 0.999
   DAILY_REQUESTS = 2_000_000

   days = []
   for day in range(1, 31):
       error_ratio = random.uniform(0.0001, 0.0006)  # good days
       if day == 12:
           error_ratio = 0.019    # a bad deploy, rolled back in 1h
       days.append((day, error_ratio))

   total = DAILY_REQUESTS * 30
   budget = total * (1 - SLO)
   spent = 0
   for day, ratio in days:
       spent += DAILY_REQUESTS * ratio
       flag = "  <-- incident" if ratio > 0.01 else ""
       if day in (1, 11, 12, 13, 30):
           print(f"day {day:2d}: error_ratio={ratio:.4f}  "
                 f"budget used {spent/budget:5.1%}{flag}")

   print(f"\nSLO {SLO:.1%}: budget={budget:,.0f} failed requests")
   print(f"month ended at {spent/budget:.1%} of budget")
   print("one bad hour consumed more than every good day combined")
   ```

   ```bash
   python3 budget.py
   ```

3. **Work the burn-rate math**

   ```text
   SLO 99.9% (0.1% budget), 30-day window. For each incident,
   compute burn rate = observed_error_ratio / 0.001 and
   time-to-empty = 30 days / burn_rate:

   a) 0.5% of requests failing    -> 5x    -> budget gone in 6 days
   b) 1.44% failing               -> 14.4x -> gone in 50 hours
   c) 100% failing (full outage)  -> 1000x -> gone in 43 minutes
   d) 0.08% failing               -> 0.8x  -> never (within SLO)

   Which deserve a page? (b) and (c) burn fast enough that waiting
   for a human on a ticket queue loses the month; (a) is a ticket
   with a deadline; (d) is normal operation, alerting on it is
   noise.
   ```

4. **Write the SLO document**

   ```text
   # SLO: checkout availability
   SLI:     non-5xx gateway responses / all gateway responses,
            measured at the load balancer
   Target:  99.9% over a rolling 30 days
   Excludes: requests failed by client disconnect; planned
            maintenance announced 72h ahead
   Budget policy:
     > 50% remaining:  normal release cadence
     < 50% remaining:  deploys need a second reviewer
     exhausted:        feature freeze, reliability work only,
                       until 7-day burn rate < 1
   Owner: checkout team; reviewed quarterly
   ```

### Checkpoint

Produce the SLO doc for the latency SLI (not availability) of your Lesson 5
service: PromQL definition, a defensible target based on measured p95/p99, and
the budget policy. Then compute the burn rate your Lesson 3 degraded mode (20%
errors) would cause and how long the monthly budget would survive it.

---

## Lesson 7: Alerting Without the 3am Regret

**Goal:** Encode burn-rate alerts in Prometheus, fire one on purpose, and
classify every alert as page, ticket, or dashboard-only.

### Concepts

An alert is a claim that a human must change what they are doing. Pages
interrupt sleep for symptoms burning the error budget fast; tickets queue work
for slow burns; everything else belongs on a dashboard for the humans already
investigating. Multiwindow burn-rate alerts encode this: a long window (1h)
proves the damage is real, a short window (5m) proves it is still happening --
both must exceed the threshold, so a recovered blip cannot page you an hour
later. Cause-based alerts (disk 80%, replica down) page for states users never
felt; symptom-based alerts page for user pain and let the dashboard explain the
cause. Every page carries a runbook link, and a runbook is imperative sentences
with commands, not "investigate the service".

### Exercises

1. **Encode the burn-rate alerts**

   ```bash
   cat > /tmp/alerts.yml <<'EOF'
   groups:
     - name: slo_burn
       rules:
         - alert: CheckoutFastBurn
           expr: |
             (sum(rate(http_requests_total{status="500"}[1h]))
                / sum(rate(http_requests_total[1h]))) > (14.4 * 0.001)
             and
             (sum(rate(http_requests_total{status="500"}[5m]))
                / sum(rate(http_requests_total[5m]))) > (14.4 * 0.001)
           for: 2m
           labels: { severity: page }
           annotations:
             summary: "Error budget burning 14.4x -- gone in ~50h"
             runbook: "https://runbooks.internal/checkout-fast-burn"
         - alert: CheckoutSlowBurn
           expr: |
             (sum(rate(http_requests_total{status="500"}[6h]))
                / sum(rate(http_requests_total[6h]))) > (3 * 0.001)
           for: 15m
           labels: { severity: ticket }
   EOF

   docker rm -f prom
   docker run -d --name prom -p 9090:9090 \
     -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml \
     -v /tmp/rules.yml:/etc/prometheus/rules.yml \
     -v /tmp/alerts.yml:/etc/prometheus/alerts.yml \
     prom/prometheus
   ```

   Add `/etc/prometheus/alerts.yml` under `rule_files:` in `/tmp/prometheus.yml`
   before restarting.

2. **Fire the page on purpose**

   ```bash
   # Burn hard: 5% errors is a 50x burn against a 99.9% SLO
   kill %1
   APP_ERROR_RATE=0.05 python3 app_metrics.py &

   open http://localhost:9090/alerts
   # Watch CheckoutFastBurn move: inactive -> pending (the `for:`
   # timer) -> firing. Then heal the app (APP_ERROR_RATE=0.001)
   # and watch the short window clear the alert while the long
   # window still remembers the damage.
   ```

3. **Classify a candidate alert list**

   ```text
   Page, ticket, or dashboard-only? Decide before reading the answers.

   1. Error budget burn rate > 14.4x for 5m and 1h
   2. Disk usage > 80% on one app host
   3. p99 latency 2x baseline for 30 minutes
   4. TLS certificate expires in 21 days
   5. One of three replicas down, traffic healthy
   6. Queue depth growing for 2 hours, consumers healthy
   7. Deploy caused error ratio 0.05% -> 0.4% (SLO 99.9%)
   8. Host CPU at 95% for 10 minutes, latency SLI healthy

   Sketch: 1 page. 2 dashboard (page only when full disk becomes a
   symptom -- or better, alert on predicted-full-in-4h as a ticket).
   3 page if it breaks the latency SLO budget, else ticket.
   4 ticket (deadline, not emergency). 5 ticket -- users feel
   nothing; page at two down. 6 ticket with trend attached.
   7 ticket: 4x burn, budget survives days, rollback in hours.
   8 dashboard: no symptom, no action.
   ```

4. **Write the runbook the page links to**

   ```text
   # Runbook: CheckoutFastBurn
   Confirm   dashboard "checkout RED" -- is the error ratio panel
             above 1.44%? Which paths? (filter $path)
   Correlate last deploy: `kubectl rollout history deploy/checkout`
             feature flags changed in the last 2h; upstream status
   Mitigate  bad deploy -> `kubectl rollout undo deploy/checkout`
             flag-related -> disable the flag, then verify burn
             rate < 1 on the 5m window within 10 minutes
   Escalate  burn still > 14.4x after mitigation: page
             #checkout-oncall-secondary and start an incident doc
   ```

### Checkpoint

Show the alert lifecycle from exercise 2 (pending, firing, resolved) and explain
what the `for: 2m` clause and the 5m confirmation window each protect against.
Then defend your classification of items 2, 5, and 7 from exercise 3 in terms of
symptoms, budgets, and required human action.

---

## Lesson 8: Debugging Production

**Goal:** Break the system three ways and diagnose each from telemetry alone,
pivoting between metrics, traces, and logs.

### Concepts

Real incidents test whether the signals connect. The investigation loop is
always the same: the alert names the symptom, dashboards scope it (which paths,
which instances, since when), traces localize it (which operation, which
dependency), and logs explain it (what exactly happened in that span). Each
pivot rides a shared key -- time window, path, request ID, trace ID -- which is
why instrumentation designed together beats three tools bolted on. The reflex to
build is hypothesis-driven: every glance at a dashboard should test a guess, and
a guess the telemetry cannot test marks an instrumentation gap to close in the
postmortem. That closing move -- every incident funds the next one's diagnosis
-- is how observability compounds.

### Exercises

1. **Break it three ways, diagnose each blind**

   ```bash
   # Have a partner (or your shell history) pick ONE, sight unseen:

   # (a) latency: everything slow, nothing failing
   APP_SLOWDOWN=5 python3 app_metrics.py &

   # (b) errors: one path failing hard
   APP_ERROR_RATE=0.3 python3 app_metrics.py &

   # (c) saturation: traffic beyond capacity
   python3 app_metrics.py &
   ab -n 100000 -c 200 http://localhost:8000/metrics >/dev/null &

   # Diagnose from the dashboard only: which RED panel moved first,
   # what does in-flight/CPU say, errors or latency or both?
   # Write your diagnosis BEFORE looking at which command ran.
   ```

2. **Run the full pivot on a traced incident**

   ```bash
   # With the Lesson 5 gateway/backend/jaeger stack running:
   for i in $(seq 1 200); do curl -s localhost:5000/checkout >/dev/null; done
   ```

   ```text
   Document each pivot with its artifact:
   1. METRIC   gateway p99 vs p50 -- bimodal? (two populations)
   2. TRACE    Jaeger, sort by duration: slow traces all contain
               which span?
   3. ATTRIBUTE group slow traces by warehouse.region / cache.hit
   4. LOG      the span's time window in backend logs: the exact
               message for one slow request_id
   Conclusion in one sentence, citing all four artifacts.
   ```

3. **Audit your telemetry's cost**

   ```text
   In Prometheus (localhost:9090):

   count({__name__=~".+"})                            # total series
   topk(5, count by (__name__) ({__name__=~".+"}))    # biggest metrics
   count by (path) (http_requests_total)              # a label's spread

   Now price a mistake: your app serves 50k users. Estimate the
   series count if someone adds user_id as a label to
   http_requests_total (methods x paths x statuses x 50k), and
   what that does to every scrape, every query, and the bill.
   Write the one-line code review comment that stops it.
   ```

4. **Ship the instrument-before-launch checklist**

   ```text
   # Telemetry checklist for any new endpoint (copy into your PR
   # template)
   [ ] Request counter + duration histogram with route-template
       labels (no raw IDs)
   [ ] Log line per request: level, request_id, duration_ms, status
   [ ] Spans wrap every network call; attributes carry the
       debugging dimensions (tenant, region, flag)
   [ ] SLI defined; endpoint mapped to an existing SLO or a new one
   [ ] RED panels exist; burn-rate alert covers the SLO
   [ ] Runbook stub linked from the alert
   [ ] Cardinality reviewed: every label value set is bounded
   ```

### Checkpoint

Write the incident report for one scenario from exercise 1: detection (which
signal, how fast), diagnosis (the pivot chain with artifacts), remediation, and
the instrumentation gap you found -- plus the checklist item from exercise 4
that would have caught the gap before launch.

---

## Practice Projects

### Project 1: SLO-Complete URL Shortener

Take the URL shortener from the System Design Lesson Plan and make it observable
end to end: RED metrics with route-template labels, structured logs with request
IDs, an SLO doc for redirect latency, burn-rate alerts, and a dashboard whose
every panel is a question. Then break it and run the Lesson 8 loop.

### Project 2: Trace Context by Hand

Implement `traceparent` propagation without the OpenTelemetry SDK: parse and
generate the header across the two Flask services, record spans as JSON lines,
and render the trace tree in the terminal. Compare your output with the SDK's in
Jaeger to see what the standard adds (sampling flags, span kinds, baggage).

### Project 3: The Sampling Tradeoff

Simulate 1M requests with 0.5% errors, then apply head sampling at 1% and a
tail-sampling policy (keep all errors, keep p99 latencies, keep 1% of the rest).
Compare what each strategy preserves: error visibility, percentile accuracy,
storage cost. Produce the table that justifies a sampling policy to your team.

## Quick Reference

| Topic      | Key Concepts                                                |
| ---------- | ----------------------------------------------------------- |
| Logs       | JSON lines, request_id, jq investigation, levels as policy  |
| Metrics    | Counter/gauge/histogram, buckets, RED/USE, cardinality      |
| PromQL     | rate + sum by, histogram_quantile, recording rules, windows |
| Dashboards | Panels as questions, RED per service, USE per resource      |
| Tracing    | Spans, traceparent, auto vs manual, attributes, sampling    |
| SLOs       | SLI from journeys, budget as policy, burn rate math         |
| Alerting   | Multiwindow burn, page vs ticket, runbooks                  |
| Incidents  | Metric -> trace -> log pivots, close the telemetry gap      |

## See Also

- [Observability Cheat Sheet](../how/observability.md) -- The commands and
  expressions used throughout
- [Observability](../why/observability.md) -- The mental model behind these
  practices
- [System Design Lesson Plan](system-design-lesson-plan.md) -- Lesson 7 plants
  the seeds this plan grows
- [Debugging Lesson Plan](debugging-lesson-plan.md) -- Host-level investigation
  when telemetry points at one machine
- [Docker](../how/docker.md) -- The container commands behind the local stack
- [jq](../how/jq.md) -- Log analysis fluency
- [Resilience](../why/resilience.md) -- The failures worth instrumenting for
