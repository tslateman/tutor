---
title: "Specification"
description:
  The discipline of defining what software must do before building it — from
  decision tables to TLA+, from Design by Contract to agent constraints.
---

The bottleneck shifted from execution to specification.

AI writes code fast. The constraint is no longer "can we build it?" but "can we
define what to build?" Specification — the act of stating precisely what a
system must do — is the skill that compounds in an era of automated execution.

> "If you're thinking without writing, you only think you're thinking." — Leslie
> Lamport

## The Specification-Execution Spectrum

Every specification sits on a spectrum from informal to formal. Match the level
to the risk.

| Level              | Form                           | Precision   | Tooling                     | When to use                                |
| ------------------ | ------------------------------ | ----------- | --------------------------- | ------------------------------------------ |
| **Informal**       | User stories, prose            | Low         | Jira, docs                  | Early exploration, business alignment      |
| **Structured**     | BDD/Gherkin, decision tables   | Medium-low  | Cucumber, spreadsheets      | Acceptance criteria, stakeholder comms     |
| **Schema**         | OpenAPI, JSON Schema, Protobuf | Medium      | Validators, code generators | API boundaries, service contracts          |
| **Type system**    | TypeScript strict, Rust types  | Medium-high | Compiler                    | Structural invariants, data shapes         |
| **Contracts**      | DbC (pre/post/invariant)       | High        | `deal`, `contracts` crate   | Interface guarantees, runtime enforcement  |
| **Property-based** | Hypothesis, QuickCheck         | High        | Test frameworks             | Behavioral invariants, edge case discovery |
| **Formal model**   | TLA+, Alloy                    | Very high   | Model checkers              | Concurrency, distributed systems           |

Most teams live at the schema and type system levels. The leverage is at the
ends: structured specifications catch ambiguity early; formal models catch
concurrency bugs that testing misses entirely.

## Decision Tables

The simplest formal method. Write all combinations of conditions and their
outcomes in a grid. Missing rows reveal missing specifications.

```text
| Premium? | Cart > $100? | Holiday? | Discount |
|----------|-------------|----------|----------|
| Y        | Y           | Y        | 25%      |
| Y        | Y           | N        | 15%      |
| Y        | N           | Y        | 10%      |
| Y        | N           | N        | 5%       |
| N        | Y           | Y        | 10%      |
| N        | Y           | N        | 0%       |
| N        | N           | Y        | 5%       |
| N        | N           | N        | 0%       |
```

Eight rows for three booleans. No ambiguity. No "it depends." The table _is_ the
specification — hand it to any implementation and get the same result.

## Design by Contract

Bertrand Meyer's framework: every function is a contract between supplier and
client.

| Element           | Who guarantees it | Meaning                             |
| ----------------- | ----------------- | ----------------------------------- |
| **Precondition**  | Client (caller)   | "I promise the input looks like..." |
| **Postcondition** | Supplier (callee) | "I promise the output will..."      |
| **Invariant**     | Both              | "This property always holds"        |

```python
# Python with the `deal` library
import deal

@deal.pre(lambda amount: amount > 0, message="amount must be positive")
@deal.post(lambda result: result >= 0, message="balance cannot go negative")
def withdraw(balance: float, amount: float) -> float:
    return balance - amount
```

The contract documents _and_ enforces the specification. When `deal` integrates
with Hypothesis, it generates tests automatically from contract decorators —
contracts become executable specifications.

**The key insight:** Contracts separate what from how. The precondition says
"give me positive numbers." The postcondition says "I'll return a non-negative
balance." The implementation is free to change as long as the contract holds.

## Property-Based Testing

Example-based tests prove specific cases. Property-based tests prove invariants
across thousands of generated inputs.

```text
Example-based:  sort([3,1,2]) == [1,2,3]          ← one case
Property-based: for any list L, len(sort(L)) == len(L)     ← all cases
                for any list L, sort(L) is non-decreasing
                for any list L, elements(sort(L)) == elements(L)
```

Properties define what a function must do without specifying how. The test
framework generates inputs — including edge cases humans overlook: empty lists,
single elements, duplicates, very large inputs.

| Tool                   | Language           | Key feature                         |
| ---------------------- | ------------------ | ----------------------------------- |
| **Hypothesis**         | Python             | Shrinks failing cases to minimal    |
| **QuickCheck**         | Haskell (original) | Ported to most languages            |
| `icontract-hypothesis` | Python             | Generates tests from DbC decorators |

## Formal Methods for Working Engineers

TLA+ and Alloy are not academic exercises. AWS uses TLA+ across seven teams.
Engineers become productive in 2–3 weeks. TLA+ found bugs in S3, DynamoDB, and
EBS that testing could not reach.

| Tool      | Creator        | Best for                                         | Entry point              |
| --------- | -------------- | ------------------------------------------------ | ------------------------ |
| **TLA+**  | Leslie Lamport | Concurrency, distributed systems, state machines | PlusCal (sequential DSL) |
| **Alloy** | Daniel Jackson | Data models, structural constraints, small scope | Alloy 6 (adds temporal)  |

### Why testing is insufficient for concurrency

A concurrent system with _n_ threads and _m_ states has _m^n_ possible
interleavings. Tests exercise a handful. A model checker explores all of them.

Hillel Wayne found a concurrency bug in 31 minutes with TLA+ that took 16 hours
to find with unit tests. The bug existed in an interleaving that tests never
hit.

### What TLA+ specifications look like

```text
---- MODULE TransferMoney ----
VARIABLES alice_balance, bob_balance

Init ==
    /\ alice_balance = 100
    /\ bob_balance = 50

Transfer(amount) ==
    /\ alice_balance >= amount
    /\ alice_balance' = alice_balance - amount
    /\ bob_balance' = bob_balance + amount

Invariant ==
    alice_balance + bob_balance = 150
====
```

The model checker verifies the invariant holds across every reachable state. If
it fails, you get a counterexample trace — the exact sequence of steps that
breaks it.

## Agent Constraints as Specification

CLAUDE.md files, agent prompts, and constraint lists are specifications. They
define what an agent must do, what it must not do, and what success looks like.

| Specification element | Traditional software | Agent systems           |
| --------------------- | -------------------- | ----------------------- |
| **Input contract**    | Type signatures      | Context boundaries      |
| **Output contract**   | Return types         | Output format schemas   |
| **Invariants**        | Database constraints | Behavioral constraints  |
| **Resource bounds**   | Memory/CPU limits    | Token budgets, timeouts |
| **Success criteria**  | Assertions           | Evaluation rubrics      |

The gap between traditional and agent specification: traditional contracts are
deterministic (the compiler enforces them), agent contracts are probabilistic
(the agent might violate them). This makes specification _more_ important, not
less — clear constraints reduce the probability of violation.

## Heuristics

### When to increase formality

- Multiple developers interpret the same requirement differently
- Bugs appear in interleavings or edge cases testing misses
- The cost of a production bug exceeds the cost of specification
- You're defining boundaries between autonomous systems (services, agents)

### When informality suffices

- Prototyping where requirements will change tomorrow
- Solo projects where you are both specifier and implementer
- Throwaway scripts with a lifespan of hours

### The specification test

Ask three people to implement the same specification independently. If they
produce meaningfully different implementations, the specification is
insufficient.

## Key Quotes

- "There are two ways of constructing software: One way is to make it so simple
  that there are obviously no deficiencies. The other way is to make it so
  complicated that there are no obvious deficiencies." — C.A.R. Hoare
- "The hardest single part of building a software system is deciding precisely
  what to build." — Fred Brooks
- "Specifications are thinking tools, not proof systems." — Hillel Wayne
- "Prompt engineering is tactical execution; specification is strategic intent."

## Further Reading

- Leslie Lamport — _Specifying Systems_ (2002, free PDF)
- Hillel Wayne — _Practical TLA+_ (2018)
- Daniel Jackson — _The Essence of Software_ (2021)
- Bertrand Meyer — _Object-Oriented Software Construction_ (1997)
- Hillel Wayne — [learntla.com](https://learntla.com) (free tutorial)
- AWS — _How Amazon Web Services Uses Formal Methods_ (CACM 2015)

## See Also

- [Testing](testing.md) — Property-based testing as executable specification
- [Complexity](complexity.md) — Specification defines abstraction boundaries
- [API Design](api-design.md) — Schemas as specification for service boundaries
- [Orchestration](orchestration.md) — Agent contracts and constraint
  specification
- [Thinking](thinking.md) — Specification as a thinking discipline
- [Specification Lesson Plan](../learn/specification-lesson-plan.md) — Eight
  lessons from decision tables to TLA+
