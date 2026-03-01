---
title: "Signal Cheat Sheet"
description:
  Filtering signal from noise under real constraints — prioritization, context
  management, and communication as execution skills.
---

You have systems. You still drown. The missing layer is judgment about what
deserves attention.

## The Core Problem

Engineers don't lack tools or techniques. They lack filters. Every channel,
notification, meeting, and request competes for the same finite resource:
attention. Without deliberate filtering, noise wins by default — it's louder,
more urgent, and more frequent than signal.

| Resource           | Replenishable? | Implication                           |
| ------------------ | -------------- | ------------------------------------- |
| **Time**           | No             | Every yes is a no to something else   |
| **Attention**      | Partially      | Degrades with switching; recovers     |
| **Working memory** | No (per task)  | ~4 items; overflow causes errors      |
| **Energy**         | Daily          | Decision quality declines through day |

The three disciplines below form a pipeline: prioritization decides _what
matters_, context management decides _what's relevant now_, and communication
moves others toward the thing that matters.

## Prioritization

Deciding what matters. Not a system — a muscle.

### The Fundamental Test

> "If this is the only thing I accomplish today, will I be satisfied?"

Most days have one thing that actually matters. Find it before opening Slack.

### Signal vs Noise in Work

| Signal                              | Noise                             |
| ----------------------------------- | --------------------------------- |
| Unblocks others                     | Feels urgent but nobody's waiting |
| Compounds — prevents future work    | Linear — consumed once            |
| Moves a goal forward                | Maintains an illusion of progress |
| Has a deadline tied to real impact  | Has a deadline tied to a calendar |
| You're uniquely positioned to do it | Anyone could do it                |

### Triage Heuristics

| Heuristic              | Application                                                     |
| ---------------------- | --------------------------------------------------------------- |
| **One-way vs two-way** | Spend time on irreversible decisions; move fast on reversible   |
| **Cost of delay**      | What breaks if this waits a day? A week? Nothing? Then it waits |
| **Leverage**           | Will this make 10 other things easier?                          |
| **Energy matching**    | Hard problems when sharp; admin when drained                    |
| **Default no**         | New requests are noise until proven signal                      |

### Saying No

The skill that makes every other skill work. Three forms:

1. **Direct no.** "I can't take this on — here's who might."
2. **Conditional no.** "I can do this if X drops. Which matters more?"
3. **Deferred no.** "Not this sprint. Add it to the backlog and we'll
   re-evaluate."

Saying yes to everything is saying nothing matters.

### Failure Modes

| Anti-Pattern           | What Happens                                        | Fix                                            |
| ---------------------- | --------------------------------------------------- | ---------------------------------------------- |
| **Urgency addiction**  | React to every ping; strategic work never starts    | Block deep work first; batch reactive work     |
| **Priority inflation** | Everything is P0; nothing is                        | Force-rank: if everything is critical, re-rank |
| **Busy as identity**   | Confuse activity with progress                      | Track outcomes, not hours                      |
| **Consensus seeking**  | Wait for alignment that never comes                 | Decide, communicate, adjust                    |
| **Perfectionism**      | Polish what's done instead of starting what matters | Ship at 80%; iterate with feedback             |

## Context

What's relevant right now. Human working memory holds ~4 items. Every context
switch flushes the cache.

### The Cost of Switching

Research consistently shows 15-25 minutes to regain deep focus after an
interruption. Three interruptions per hour means zero deep work happens. The
damage compounds: partial context leads to shallow decisions, which create bugs,
which create more interruptions.

### Protecting Context

| Technique               | How                                                          |
| ----------------------- | ------------------------------------------------------------ |
| **Single-threading**    | One hard problem at a time; serialize, don't parallelize     |
| **Context blocks**      | Calendar blocks for deep work; defend them like meetings     |
| **Batch interruptions** | Check messages at intervals, not continuously                |
| **Externalize state**   | Write down where you are before switching; reload is cheaper |
| **Reduce WIP**          | Fewer things in flight = less to hold in memory              |

### When to Context-Switch (Deliberately)

Not all switching is waste. Switch when:

- You're blocked and waiting on someone else
- Diminishing returns — you've been stuck for 30+ minutes
- New information genuinely changes the priority
- A teammate needs 5 minutes now or will be blocked for hours

The key: switch by choice, not by notification.

### Failure Modes

| Anti-Pattern             | What Happens                                      | Fix                                          |
| ------------------------ | ------------------------------------------------- | -------------------------------------------- |
| **Open-door fallacy**    | Availability signals importance; it doesn't       | Async by default; synchronous by exception   |
| **Notification slavery** | Every ding gets immediate attention               | Disable non-critical notifications           |
| **WIP hoarding**         | 8 things "in progress," none moving               | Limit WIP to 2-3; finish before starting     |
| **Context as identity**  | "I need to know everything" — no, you don't       | Trust others; accept partial information     |
| **No breadcrumbs**       | Switch contexts without noting where you left off | 30-second note before switching saves 20 min |

## Communication

How you move others toward what matters. Every message either adds signal or
adds noise. There is no neutral.

### The Compression Principle

Respect for someone's attention is measured by how much you compress before
sending. An unedited brain dump says: my time matters more than yours.

| Low Compression (Noise)                | High Compression (Signal)                      |
| -------------------------------------- | ---------------------------------------------- |
| Wall of text with buried question      | Question first, context below                  |
| "Thoughts?"                            | "Option A or B? Here's the tradeoff."          |
| FYI with no action or relevance stated | One sentence: what changed and who should care |
| Meeting with no agenda                 | Async doc with decision needed by Friday       |

### Async-First Heuristics

| Principle              | Application                                                         |
| ---------------------- | ------------------------------------------------------------------- |
| **Write it down**      | If it's not written, it didn't happen and can't be referenced       |
| **Front-load the ask** | Lead with what you need; put context after                          |
| **State the deadline** | "Need input by Thursday" beats "when you get a chance"              |
| **Choose the channel** | Urgent → DM or call. Important → doc or ticket. FYI → nowhere       |
| **Close the loop**     | "Resolved — went with option B because X." Don't leave threads open |

### Giving and Receiving Feedback

**Giving:** Be specific, timely, and directed at the work. "This function does
too much" beats "the code needs work." Propose an alternative when possible.

**Receiving:** Separate the signal from the delivery. A poorly worded critique
can still contain the most important thing you hear today.

### Failure Modes

| Anti-Pattern             | What Happens                                     | Fix                                                |
| ------------------------ | ------------------------------------------------ | -------------------------------------------------- |
| **Broadcast everything** | Cc the world; nobody reads it                    | Narrow the audience to who needs to act            |
| **Vague escalation**     | "This is broken" with no detail                  | State: what, impact, what you tried, what you need |
| **Meeting as default**   | Synchronous discussion for asynchronous problems | Default to async; meet only when it adds value     |
| **Silence as agreement** | No response interpreted as approval              | Explicit ack: "Looks good" or "Need more time"     |
| **Over-communication**   | Status updates nobody asked for                  | Push only when something changed or is blocked     |

## The Pipeline

The three disciplines reinforce each other:

```text
Prioritization → "This is the one thing that matters today"
    Context    → "I will protect 3 hours to work on it"
    Comms      → "Here's what I need from you by Thursday"
```

When one breaks, the others fail. Without prioritization, you protect context
for the wrong thing. Without context protection, the right priority gets
fragmented. Without clear comms, others can't align with your priorities — so
they interrupt with theirs.

### Daily Practice

1. **Morning:** Identify the one thing. Write it down.
2. **Before deep work:** Close everything else. Note where you left off on other
   threads.
3. **When interrupted:** Ask: "Is this more important than what I'm doing?" If
   not, defer.
4. **When communicating:** Compress. Front-load the ask. State the deadline.
5. **End of day:** Did the one thing move? If not, diagnose which discipline
   broke.

---

_"People think focus means saying yes to the thing you've got to focus on. But
that's not what it means at all. It means saying no to the hundred other good
things."_ — Steve Jobs

## See Also

- [Thinking](thinking.md) — Mental models, Eisenhower matrix, compound vs linear
  value
- [Complexity](complexity.md) — The complexity budget; cognitive load as a
  symptom
- [Reasoning](reasoning.md) — Biases that corrupt prioritization (availability
  heuristic, loss aversion, sunk cost)
- [Information Architecture](information-architecture.md) — Structural design
  for findability
- [Orchestration](orchestration.md) — Context routing in agent systems; the
  human parallels apply
