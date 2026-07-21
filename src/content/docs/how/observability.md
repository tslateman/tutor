---
title: "Observability Cheat Sheet"
description:
  Structured logs with jq, Prometheus metrics and PromQL, OpenTelemetry tracing,
  SLO math, and burn-rate alerting.
---

<!-- prettier-ignore -->
:::tip[Lesson Plan]
Looking to learn this topic step by step? See the
[Observability Lesson Plan](../learn/observability-lesson-plan.md).
:::

## Structured Logs with jq

```bash
# Filter to errors only
jq 'select(.level == "error")' app.log

# Error count by endpoint
jq -r 'select(.status >= 500) | .path' app.log | sort | uniq -c | sort -rn

# Follow one request across services by correlation ID
jq 'select(.request_id == "a1b2c3d4")' app.log gateway.log worker.log

# p95 latency from logs (sort, then index)
jq -s 'map(.duration_ms) | sort | .[(length * 0.95 | floor)]' app.log

# Requests per minute over time
jq -r '.timestamp[0:16]' app.log | uniq -c

# Extract slow requests with context
jq 'select(.duration_ms > 1000) | {path, duration_ms, request_id}' app.log
```

Rules for emitting logs worth querying: one JSON object per line, a `level`, a
`timestamp`, a `request_id` on every line the request touches, and `duration_ms`
on completion lines. Log the units in the key name.

## Instrumenting Metrics (Python)

```python
# app_metrics.py
from prometheus_client import Counter, Gauge, Histogram, start_http_server
import random, time

REQUESTS = Counter(
    "http_requests_total", "Total HTTP requests",
    ["method", "path", "status"],
)
IN_FLIGHT = Gauge("http_requests_in_flight", "Requests currently active")
LATENCY = Histogram(
    "http_request_duration_seconds", "Request latency",
    ["path"],
    buckets=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5],
)

start_http_server(8000)  # exposes http://localhost:8000/metrics
print("metrics on :8000/metrics")

while True:  # simulate traffic
    path = random.choice(["/api/users", "/api/orders", "/health"])
    IN_FLIGHT.inc()
    with LATENCY.labels(path=path).time():
        time.sleep(random.expovariate(1 / 0.05))
    status = "500" if random.random() < 0.02 else "200"
    REQUESTS.labels(method="GET", path=path, status=status).inc()
    IN_FLIGHT.dec()
```

```bash
pip3 install prometheus-client
python3 app_metrics.py &
curl -s localhost:8000/metrics | grep -v '^#' | head -20
```

Metric type decision: monotonically increasing event count -> Counter (`rate()`
extracts the per-second slope). Point-in-time value that goes both ways ->
Gauge. Distribution you will take percentiles from -> Histogram, and pick
buckets around your SLO threshold.

## PromQL Essentials

```text
# Requests per second, by path (rate needs a Counter and a window)
sum by (path) (rate(http_requests_total[5m]))

# Error ratio (the SLI for most services)
sum(rate(http_requests_total{status=~"5.."}[5m]))
  / sum(rate(http_requests_total[5m]))

# p99 latency from a histogram (aggregate le before quantile)
histogram_quantile(0.99,
  sum by (le) (rate(http_request_duration_seconds_bucket[5m])))

# p99 per path
histogram_quantile(0.99,
  sum by (path, le) (rate(http_request_duration_seconds_bucket[5m])))

# Top 5 busiest paths
topk(5, sum by (path) (rate(http_requests_total[5m])))

# How many requests in the last hour (increase = rate x window)
sum(increase(http_requests_total[1h]))

# Saturation: fraction of a limit in use
http_requests_in_flight / 100
```

```yaml
# Recording rule: precompute expensive queries dashboards reuse
groups:
  - name: service_rules
    interval: 30s
    rules:
      - record: path:http_requests:rate5m
        expr: sum by (path) (rate(http_requests_total[5m]))
      - record: service:http_error_ratio:rate5m
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
            / sum(rate(http_requests_total[5m]))
```

## Cardinality Control

```text
# Total series in the instance (watch this number)
count({__name__=~".+"})

# Which metrics have the most series
topk(10, count by (__name__) ({__name__=~".+"}))

# Which label values explode a specific metric
count by (path) (http_requests_total)
```

Series count is the product of label cardinalities: 5 methods x 200 paths x 5
statuses = 5,000 series for one metric. Never use unbounded values (`user_id`,
`request_id`, raw URLs with IDs) as label values -- route templates
(`/api/users/:id`), not concrete paths. High-cardinality questions belong in
traces and logs, not metrics.

## OpenTelemetry Tracing

```bash
# Auto-instrument a Python service (no code changes)
pip3 install opentelemetry-distro opentelemetry-exporter-otlp
opentelemetry-bootstrap -a install   # instruments installed libraries

OTEL_SERVICE_NAME=checkout \
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317 \
OTEL_TRACES_SAMPLER=parentbased_traceidratio \
OTEL_TRACES_SAMPLER_ARG=0.1 \
opentelemetry-instrument python3 app.py
```

```python
# Manual spans where auto-instrumentation cannot see
from opentelemetry import trace

tracer = trace.get_tracer("checkout")

with tracer.start_as_current_span("apply_discounts") as span:
    span.set_attribute("cart.items", len(items))
    span.set_attribute("customer.tier", tier)   # high cardinality is fine here
    total = compute(items)
```

```text
# Context propagation: one header carries the trace across services
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
              |  trace-id (32 hex)                 span-id (16 hex)  flags

Sampling decisions:
  head sampling   cheap, decided at the root (SAMPLER_ARG=0.1 keeps 10%)
  tail sampling   keeps the interesting traces (errors, slow), needs a
                  collector buffering complete traces before deciding
```

## SLO Math

```text
Availability budget per 30-day month:
  99%     7h 12m
  99.5%   3h 36m
  99.9%   43m 12s
  99.95%  21m 36s
  99.99%  4m 19s

SLI (ratio of good events):
  1 - (failed_requests / total_requests)

Error budget remaining after N days of a 30-day window:
  budget = (1 - SLO) x total_requests
  spent  = failed_requests
  burn rate = observed_error_ratio / (1 - SLO)
  burn rate 1.0 = spending exactly the budget over the window
  burn rate 14.4 = the whole month's budget gone in 50 hours
```

## Burn-Rate Alerting

```yaml
# Multiwindow burn-rate alerts for a 99.9% SLO (Google SRE Workbook)
# Both windows must burn: the short window stops stale alerts.
groups:
  - name: slo_alerts
    rules:
      - alert: ErrorBudgetFastBurn # page: 2% of budget in 1 hour
        expr: |
          service:http_error_ratio:rate1h > (14.4 * 0.001)
            and
          service:http_error_ratio:rate5m > (14.4 * 0.001)
        labels: { severity: page }
      - alert: ErrorBudgetSlowBurn # ticket: 10% of budget in 3 days
        expr: |
          service:http_error_ratio:rate3d > (1 * 0.001)
            and
          service:http_error_ratio:rate6h > (1 * 0.001)
        labels: { severity: ticket }
```

```text
Burn rate reference (30-day window, from the SRE Workbook):
  page    14.4x over 1h  (+ 5m confirm)   2% of budget consumed
  page     6x   over 6h  (+ 30m confirm)  5% of budget consumed
  ticket   3x   over 1d  (+ 2h confirm)   10% of budget consumed
  ticket   1x   over 3d  (+ 6h confirm)   10% of budget consumed
```

## Local Stack

```bash
# Prometheus scraping an app on your host (macOS Docker Desktop)
cat > /tmp/prometheus.yml <<'EOF'
scrape_configs:
  - job_name: app
    scrape_interval: 5s
    static_configs:
      - targets: ["host.docker.internal:8000"]
EOF
docker run -d --name prom -p 9090:9090 \
  -v /tmp/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
open http://localhost:9090

# Grafana (default login admin/admin; add Prometheus datasource
# with URL http://host.docker.internal:9090)
docker run -d --name grafana -p 3000:3000 grafana/grafana
open http://localhost:3000

# Jaeger all-in-one (OTLP in, UI out)
docker run -d --name jaeger \
  -p 16686:16686 -p 4317:4317 -p 4318:4318 \
  jaegertracing/all-in-one
open http://localhost:16686

# Teardown
docker rm -f prom grafana jaeger
```

## Method Cheat Sheet

| Method              | Measures                             | Use for               |
| ------------------- | ------------------------------------ | --------------------- |
| RED                 | Rate, Errors, Duration               | Every service         |
| USE                 | Utilization, Saturation, Errors      | Every resource        |
| Four Golden Signals | Latency, traffic, errors, saturation | Whole-system overview |

## Quick Reference

| Task                  | Command / Expression                                           |
| --------------------- | -------------------------------------------------------------- |
| Errors from JSON logs | `jq 'select(.level == "error")' app.log`                       |
| Requests per second   | `sum(rate(http_requests_total[5m]))`                           |
| Error ratio           | `rate(...{status=~"5.."}[5m]) / rate(...[5m])`                 |
| p99 latency           | `histogram_quantile(0.99, sum by (le) (rate(..._bucket[5m])))` |
| Series count          | `count({__name__=~".+"})`                                      |
| Trace a Python app    | `opentelemetry-instrument python3 app.py`                      |
| 99.9% monthly budget  | 43m 12s                                                        |
| Page-worthy burn      | 14.4x over 1h and 5m                                           |

## See Also

- [Observability](../why/observability.md) -- The mental model: SLOs, error
  budgets, alerting philosophy
- [Observability Lesson Plan](../learn/observability-lesson-plan.md) -- Hands-on
  path from logs to burn-rate alerts
- [Performance](performance.md) -- Profiling and load testing the app behind the
  metrics
- [Debugging Tools](debugging.md) -- Host-level tracing when telemetry runs out
- [jq](jq.md) -- The full JSON query toolkit for log analysis
- [Kubernetes](k8s.md) -- Where these signals get scraped in production
