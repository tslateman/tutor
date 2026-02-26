---
title: "AI Adoption"
description:
  Principles for introducing AI coding tools without mandates, preserving code
  ownership and human judgment.
---

Principles for introducing AI coding tools to an engineering team without
mandating them, leaving anyone behind, or undermining code ownership.

## Availability Without Mandate

AI tools lower the cost of generating code. That does not mean every engineer
must use them. Offer access, document how to get started, and stop there. Code
how you want.

No workflow, review process, or sprint metric should reward AI-generated code
over hand-written code. The goal is good software, not AI usage.

### What Availability Looks Like

| Action                            | Not this                                      |
| --------------------------------- | --------------------------------------------- |
| Publish setup docs in the wiki    | Require completion of an AI onboarding course |
| Fund licenses for anyone who asks | Gate access behind manager approval           |
| Share tips in a Slack channel     | Add "AI skills" to the promotion rubric       |
| Let people opt out silently       | Track who uses AI and who does not            |

The distinction matters: access removes barriers; mandates create pressure.
Pressure distorts workflows — engineers optimize for the metric instead of the
outcome.

## What Stays Human

AI tools change how fast you can generate code. They do not change what you own.

| Responsibility          | Why It Stays Human                                                                             | Example                                                                 |
| ----------------------- | ---------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Architecture trade-offs | Org history, team capacity, and roadmap context are not in any context window                  | Choosing a message queue means weighing ops burden against team skill   |
| Mentorship in review    | PR threads are where juniors learn; the war story behind that odd regex is yours to tell       | Explaining why you chose eventual consistency over strong consistency   |
| The merge decision      | "The AI wrote it" is not a defense when it pages you at 2 a.m. — merge code you can evaluate   | A generated migration that silently drops a column default              |
| Incident response       | Triage requires system history, customer context, and judgment under pressure                  | Deciding to revert vs. forward-fix at 3 a.m. during a payment outage    |
| Architecture review     | Trade-offs between teams, timelines, and organizational constraints live outside the codebase  | Choosing boring technology when the team has six months of runway       |
| Hiring decisions        | Technical interviews assess communication, collaboration, and growth — not just correct output | Evaluating whether a candidate reasons through ambiguity                |
| Ethical judgment        | "Should we build this?" requires values, not optimization                                      | Declining to ship a feature that exploits user psychology for retention |
| Values                  | "Should we build this at all?" is a question no model can answer for your team                 | Deciding whether to collect location data you technically could use     |

## Getting Started

Start at the level that matches your curiosity. There is no expected
progression.

| Level | Mode        | What it means                                              | Concrete examples                                                   |
| ----- | ----------- | ---------------------------------------------------------- | ------------------------------------------------------------------- |
| 0     | Completions | Accept, reject, or ignore inline suggestions as you type   | Copilot in VS Code, Supermaven, Codeium — tab-complete while typing |
| 1     | Drafting    | Ask for a first draft; read it before you use it           | ChatGPT for a regex, Claude for a shell script, inline chat in IDE  |
| 2     | Delegation  | Hand off a bounded, well-specified task; verify the output | Claude Code for a refactor, Cursor agent mode, Codex for test gen   |

**Level 0 is a legitimate long-term choice.** Some engineers find completions
useful and never want more. That is fine. Adoption levels are not a maturity
model.

### What Makes Each Level Effective

- **Level 0:** Treat suggestions as spell-check, not autopilot. Reject more than
  you accept. The value is speed on patterns you already know.
- **Level 1:** Read the draft as if a junior wrote it. Check error handling,
  edge cases, and naming. The first draft saves time; the review is where
  quality lives.
- **Level 2:** Write the spec before delegating. A vague prompt produces vague
  code. Specify inputs, outputs, error behavior, and constraints. Verify the
  result against the spec, not against your intuition.

## Codeowners

AI tools lower the cost of opening PRs. That cost transfers to reviewers —
especially codeowners with high surface area.

Before opening a large AI-assisted PR against a system you do not own:

- Ask whether codeowners have a preferred approach or prior art
- Review the diff yourself first and cut what is not needed — do not hand
  reviewers 800 lines of generated code to triage
- Do not mistake model confidence for correctness

Codeowners have standing to ask for rewrites. That is the deal.

## Review Dynamics

AI changes the economics of code review. Generation becomes cheap; review stays
expensive. This imbalance creates predictable failure modes.

### The Asymmetry

```text
Before AI:  Write 100 lines/hr → Review 100 lines/hr  → balanced
After AI:   Write 500 lines/hr → Review 100 lines/hr  → bottleneck at review
```

Review throughput does not scale with generation throughput. Every unreviewed
line is latent risk.

### Review Heuristics for Generated Code

| Heuristic                          | Rationale                                                        |
| ---------------------------------- | ---------------------------------------------------------------- |
| Smaller PRs, even if AI can go big | Review quality degrades past ~400 lines                          |
| Read the diff, not the prompt      | The prompt describes intent; the diff describes reality          |
| Check error paths first            | Models optimize for the happy path; errors get generic handling  |
| Verify names match domain language | Generated identifiers drift from team conventions                |
| Run the code, not just read it     | Plausible-looking code passes visual review but fails at runtime |

## The Validation Problem

DORA 2025 measured AI adoption across thousands of engineering organizations and
found a two-directional result: AI correlates positively with throughput _and_
negatively with stability. Teams using AI ship faster and break more things —
simultaneously.

This is not a simple good/bad finding. It reveals where the bottleneck moved.
Before AI, the constraint was generation speed: how fast can we write code?
After AI, the constraint is validation speed: how fast can we verify code?

### Why Both Directions at Once

AI accelerates the easy part of software development (producing code) without
accelerating the hard part (confirming it works in production). The result
depends on the validation floor:

| Foundation                            | AI outcome                                    |
| ------------------------------------- | --------------------------------------------- |
| Strong CI, observability, clear specs | Speed converts to delivery                    |
| Weak CI, sparse tests                 | Speed converts to more deployments that break |
| No staging, manual QA                 | Speed converts to debt and incident load      |

### The Amplifier Model

AI does not make teams better or worse. It amplifies existing process quality.

```text
Team with strong validation:
  More code → caught by CI → stable delivery → throughput win

Team with weak validation:
  More code → bypasses gaps → unstable delivery → DORA stability hit
```

The practical implication: invest in the validation floor _before_ expanding
generation capacity. A team that adds AI tooling before fixing flaky tests and
missing observability will ship its existing problems faster.

### What the Validation Floor Requires

| Layer         | Minimum bar                                           |
| ------------- | ----------------------------------------------------- |
| Tests         | CI runs on every PR; failures block merge             |
| Type checking | Compiler or type checker catches shape errors early   |
| Observability | Errors, latency, and saturation visible in dashboards |
| Staging       | Changes deploy to a non-production environment first  |
| Rollback      | Any deploy can revert within minutes                  |
| Ownership     | Every service has a named on-call rotation            |

## Heuristics

Rules of thumb for when AI helps and when it hinders.

### Use AI When

| Situation                           | Why it works                                                   |
| ----------------------------------- | -------------------------------------------------------------- |
| Boilerplate with known patterns     | Models excel at repeating well-documented structures           |
| First draft of tests                | Generates coverage scaffolding; you refine assertions          |
| Language or API you rarely use      | Faster than reading docs for a one-off task                    |
| Regex, jq filters, shell one-liners | Syntax-dense tools where the model recalls patterns you forgot |
| Explaining unfamiliar code          | Summarizes intent faster than reading a 500-line file cold     |
| Migrating between formats           | CSV-to-JSON, YAML restructuring, config format changes         |

### Stay Manual When

| Situation                      | Why AI hinders                                                      |
| ------------------------------ | ------------------------------------------------------------------- |
| Security-sensitive logic       | Models hallucinate safe-looking code that fails edge cases silently |
| Performance-critical hot paths | Generated code optimizes for readability, not throughput            |
| Novel algorithms               | Models recombine training data; genuinely new logic needs thought   |
| Architectural decisions        | Context window holds code, not org politics and team dynamics       |
| Code you cannot read           | If you cannot evaluate the output, you cannot own it                |
| Debugging production incidents | Triage needs system history and real-time signals, not generation   |

### The Ownership Test

Before merging AI-generated code, answer three questions:

1. **Can I explain what this does?** — If not, do not merge it.
2. **Can I debug this at 2 a.m.?** — If not, rewrite until you can.
3. **Would I write a test for this?** — If the answer is "the AI should write
   the test too," you have delegated judgment, not just labor.

## Traps

| Trap                     | What it looks like                                                                     | Counter                                                              |
| ------------------------ | -------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Mandatory AI usage       | Sprint retros track "AI-assisted PRs" as a KPI; devs pad the metric                    | Measure outcomes (cycle time, defect rate), not tool adoption        |
| Skipping review          | Reviewer skims a 400-line generated diff, approves in 2 minutes                        | Treat generated code with _more_ scrutiny — it has no author to ask  |
| Ignoring codeowners      | Dev opens 6 large PRs against services they don't own in one sprint                    | Batch changes; ask codeowners for preferred approach before starting |
| Measuring AI usage       | Dashboard shows "% of code written by AI" as if that number should go up               | Track delivery metrics; AI usage is an input, not an outcome         |
| Assuming faster = better | METR RCT: experienced devs took 19% longer with AI but believed they were 20% faster   | Time actual tasks; subjective speed perception is unreliable         |
| Automation bias          | Engineer accepts a generated answer without checking because "it usually works"        | Require the same review bar for generated and handwritten code       |
| Context window worship   | Team stuffs every doc into the prompt, assumes the model read and understood all of it | Models degrade on long context; provide focused, relevant input only |
| Deskilling               | Junior devs generate code they cannot explain, skipping the learning curve             | Require juniors to write core logic by hand first, then compare      |

### The Speed Illusion

The METR finding deserves emphasis. In a randomized controlled trial on real
open-source tasks, experienced developers using AI completed tasks 19% slower
than without AI — yet self-reported feeling 20% faster. The gap between
perceived and actual speed was nearly 40 percentage points.

This happens because AI changes the _texture_ of work. Generating code feels
productive. Reading, verifying, and debugging generated code feels like
overhead. Engineers undercount the verification time because it does not feel
like "real work." The result: teams believe AI accelerated them when it did not,
and make resourcing decisions based on the illusion.

## Warning Signs

Signals that AI adoption is going wrong:

- "We should require AI tools to hit our velocity targets"
- Incident rate climbs but deployment frequency also climbs
- PR review times increase while PR sizes grow
- Junior engineers ship code they cannot explain in review
- The team debates prompt engineering more than system design
- Codeowners become bottlenecks because PR volume doubled
- Generated tests pass but do not catch real bugs
- "The AI wrote it" appears in incident postmortems

One or two of these in isolation mean little. Three or more together indicate
the validation floor needs investment before generation capacity grows further.

## See Also

- [AI CLI](../how/ai-cli.md) — Claude Code usage, context files, prompting
- [Agent Orchestration](../how/agent-orchestration.md) — Multi-agent patterns
  and failure modes
- [Complexity](./complexity.md) — Essential vs accidental complexity; applies
  directly to AI-generated code
- [Testing](./testing.md) — The validation floor that determines whether AI
  speed converts to delivery or debt
- [Agentic Workflows](../learn/agentic-workflows-lesson-plan.md) — Lesson plan
  for working with AI agents in engineering
