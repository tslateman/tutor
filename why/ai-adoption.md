# AI Adoption

Principles for introducing AI coding tools to an engineering team without
mandating them, leaving anyone behind, or undermining code ownership.

## Availability Without Mandate

AI tools lower the cost of generating code. That does not mean every engineer
must use them. Offer access, document how to get started, and stop there. Code
how you want.

No workflow, review process, or sprint metric should reward AI-generated code
over hand-written code. The goal is good software, not AI usage.

## What Stays Human

AI tools change how fast you can generate code. They do not change what you own.

| Responsibility          | Why It Stays Human                                                                           |
| ----------------------- | -------------------------------------------------------------------------------------------- |
| Architecture trade-offs | Org history, team capacity, and roadmap context are not in any context window                |
| Mentorship in review    | PR threads are where juniors learn; the war story behind that odd regex is yours to tell     |
| The merge decision      | "The AI wrote it" is not a defense when it pages you at 2 a.m. — merge code you can evaluate |
| Values                  | "Should we build this at all?" is a question no model can answer for your team               |

## Getting Started

Start at the level that matches your curiosity. There is no expected
progression.

| Level | Mode        | What it means                                              |
| ----- | ----------- | ---------------------------------------------------------- |
| 0     | Completions | Accept, reject, or ignore inline suggestions as you type   |
| 1     | Drafting    | Ask for a first draft; read it before you use it           |
| 2     | Delegation  | Hand off a bounded, well-specified task; verify the output |

## Codeowners

AI tools lower the cost of opening PRs. That cost transfers to reviewers —
especially codeowners with high surface area.

Before opening a large AI-assisted PR against a system you do not own:

- Ask whether codeowners have a preferred approach or prior art
- Review the diff yourself first and cut what is not needed — do not hand
  reviewers 800 lines of generated code to triage
- Do not mistake model confidence for correctness

Codeowners have standing to ask for rewrites. That is the deal.

## The Validation Problem

DORA 2025 measured two things simultaneously: AI adoption correlates positively
with throughput and negatively with stability. More AI means faster delivery
**and** less stable systems — unless the validation floor is solid.

The bottleneck shifted from "how fast can we write code" to "how fast can we
validate code." AI amplifies your existing process:

| Foundation                            | AI outcome                        |
| ------------------------------------- | --------------------------------- |
| Strong CI, observability, clear specs | Speed converts to delivery        |
| Weak process, unclear ownership       | Speed converts to debt and rework |

Invest in the floor before expanding generation capacity.

## Traps

| Trap                     | What actually happens                                                                |
| ------------------------ | ------------------------------------------------------------------------------------ |
| Mandatory AI usage       | Developers who code well without AI are implicitly penalized                         |
| Skipping review          | "The AI wrote it" is not a review; it is a deferral of judgment                      |
| Ignoring codeowners      | Faster PR generation with the same review bandwidth creates a review backlog         |
| Measuring AI usage       | Optimizes for the metric, not the outcome                                            |
| Assuming faster = better | METR RCT: experienced devs took 19% longer with AI but believed they were 20% faster |

## See Also

- [AI CLI](../how/ai-cli.md) — Claude Code usage, context files, prompting
- [Agent Orchestration](../how/agent-orchestration.md) — Multi-agent patterns
  and failure modes
- [Complexity](./complexity.md) — Essential vs accidental complexity; applies
  directly to AI-generated code
- [Agentic Workflows](../learn/agentic-workflows-lesson-plan.md) — Lesson plan
  for working with AI agents in engineering
