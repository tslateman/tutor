---
title: "Observability"
description:
  Why instrumentation is a design requirement -- unknown-unknowns, SLOs and
  error budgets, symptom-based alerting, and the cardinality economy.
---

Can you explain any state your system gets into, from the outside, without
shipping new code? That question, not any particular tool, is observability.

<!-- prettier-ignore -->
:::tip[Lesson Plan]
Looking to learn this topic step by step? See the
[Observability Lesson Plan](../learn/observability-lesson-plan.md).
:::

## Monitoring Answers Known Questions

| Practice      | Question shape                       | Fails when                    |
| ------------- | ------------------------------------ | ----------------------------- |
| Monitoring    | "Is CPU above 80%?" (known-unknowns) | The failure is one you never  |
|               |                                      | predicted                     |
| Observability | "Why are checkouts from iOS slow     | Telemetry lacks the detail to |
|               | since 14:00?" (unknown-unknowns)     | slice by what matters         |

Monitoring is a list of questions you wrote in advance. Every dashboard is a
fossil of a past incident. Observability is the property that lets you ask new
questions of a running system -- the incident you have not had yet is the one
that matters, and by definition no dashboard exists for it.

## Pillars Are Data Types, Not Outcomes

Logs, metrics, and traces are storage formats, not goals. The outcome is the
ability to move between them without losing the thread: an alert fires on a
metric, you pivot to traces filtered by the same time window and endpoint, then
to the logs of the one slow span, all connected by shared identifiers (request
ID, trace ID). Instrumentation that cannot be correlated is three silos, not
three pillars. The strongest telemetry is wide and high-cardinality -- events
that carry many attributes (customer, version, region, feature flag), because
the attribute you will need to group by next incident is one you cannot predict
today. Metrics deliberately discard that cardinality for cheap math, which is
why they alert well and explain poorly.

## SLOs Turn Reliability Into a Budget

Measure what users experience (request success, latency at the percentile users
feel), not what machines report (CPU, memory). An SLI is that measurement; an
SLO is the target; the error budget is the gap between the target and perfection
-- and the budget is the point. A 99.9% SLO grants ~43 minutes of failure per
month. Spend it deliberately: ship faster, run risky migrations, skip a
redundancy tier. When the budget is gone, the argument about whether to pause
features is already settled, because the policy was agreed before anyone was
defensive about their launch. Error budgets convert "be more careful" (a mood)
into a number both engineering and product can negotiate with.

Alerting on the budget's burn rate, not on raw error counts, follows from this:
a burn rate of 14.4x means the month's budget disappears in two days, which is
worth a page; a slow 1x burn is a ticket. Static thresholds page you for blips
and sleep through slow bleeds; burn rates scale the urgency to the actual
damage.

## Page on Symptoms, Not Causes

Users experience symptoms: errors, latency, wrongness. Causes (a full disk, a
dead replica, a stuck queue) matter only when they produce symptoms, and a
well-built system absorbs most of them silently. Paging on causes produces alert
fatigue; fatigued humans ack pages without reading them, and then the one page
that mattered dies in the noise. The discipline:

- Every page means a human must act now; if the response is "watch it", it
  should have been a ticket.
- Every page links a runbook; "investigate" is not a runbook.
- Cause-level signals stay on dashboards, where they answer "why" after a
  symptom fires.
- Review pages monthly: anything acked-and-ignored twice gets demoted or
  deleted.

## The Cardinality Economy

Telemetry has a cost model, and cardinality is its currency. A metric's series
count is the product of its label cardinalities, so labels multiply: adding
`customer_id` to a request counter does not add one label, it multiplies every
existing combination by your customer count. Metrics buy cheap, fast aggregation
by staying low-cardinality; traces and logs carry the high-cardinality detail at
higher per-event cost, which sampling then controls. Route each question to the
signal that can afford it: "how many" and "how fast" to metrics, "which ones
exactly" to traces and logs. Most observability bill shocks are a `user_id`
label someone added to a counter.

## Instrumentation Is a Design Requirement

Observability added after an incident answers last incident's questions.
Designed in, it shapes the system: request IDs propagate because the
architecture demands it, spans wrap the operations someone will one day need to
see, and every new feature ships with its SLI attached. This matters more as
code generation accelerates -- AI-written services ship faster than teams
hand-instrument them, so telemetry has to be ambient: auto-instrumentation at
the platform layer, structured logging as the default library, dashboards and
burn-rate alerts generated from the service template. If instrumenting is a
manual step, the fastest-moving code will be the least observable, which is
exactly backwards from what debugging it will require.

## Heuristics

| Situation                            | Reach for                              |
| ------------------------------------ | -------------------------------------- |
| Defining "reliable" for a service    | One SLI per user journey, then the SLO |
| Alert keeps firing, nobody acts      | Delete it or demote it to a dashboard  |
| Debugging a novel failure            | Wide events, group by everything       |
| Metrics bill doubled                 | Audit label cardinality first          |
| "Add a dashboard" as incident action | Ask what question it answers, and when |
| New service template                 | Telemetry on by default, opt out only  |

## See Also

- [Observability Cheat Sheet](../how/observability.md) -- The commands: PromQL,
  OpenTelemetry, burn-rate rules
- [Observability Lesson Plan](../learn/observability-lesson-plan.md) -- Hands-on
  path from logs to SLOs
- [Resilience](resilience.md) -- The failure modes this telemetry exists to
  catch
- [Debugging](debugging.md) -- The scientific method the data feeds
- [Signal](signal.md) -- Filtering noise is the same skill in human channels
- [AI Adoption](ai-adoption.md) -- Why defaults beat mandates for tooling
