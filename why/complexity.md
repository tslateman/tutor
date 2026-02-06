# Complexity Cheat Sheet

The central challenge of software engineering.

## The Fundamental Distinction

| Type           | Source                 | Reducible?                  | Example                           |
| -------------- | ---------------------- | --------------------------- | --------------------------------- |
| **Essential**  | Problem domain         | No — only redistributable   | "Users need 30 features"          |
| **Accidental** | Implementation choices | Yes — through better design | Spaghetti code, poor abstractions |

_Essential complexity is the enemy you respect. Accidental complexity is the
enemy you created._

— Fred Brooks, "No Silver Bullet" (1986)

## How Complexity Manifests

### Ousterhout's Three Symptoms

| Symptom                  | Description                         | You notice when...                    |
| ------------------------ | ----------------------------------- | ------------------------------------- |
| **Change amplification** | Simple change touches many places   | "I just wanted to rename this field"  |
| **Cognitive load**       | Must know too much to proceed       | "Let me read 12 files first"          |
| **Unknown unknowns**     | Unclear what to do or if it'll work | "I have no idea what this will break" |

### Two Root Causes

1. **Dependencies** — You can't understand or change code in isolation
2. **Obscurity** — Important information isn't obvious

## Simple vs Easy

| Simple               | Easy                      |
| -------------------- | ------------------------- |
| Not intertwined      | Familiar, at hand         |
| Objective property   | Relative to you           |
| Opposite of complex  | Opposite of hard          |
| Sustainable velocity | Fast start, slowing later |

**The trap:** Choosing easy over simple feels productive but accumulates
complexity.

```text
Week 1:  Easy choice → ship fast
Week 10: Easy choices → slower
Week 50: Easy choices → grinding halt
```

— Rich Hickey, "Simple Made Easy" (2011)

## Techniques for Managing Complexity

### Separation of Concerns

One module, one responsibility. Each piece should do one thing well.

**Test:** Can you describe what this module does without using "and"?

### Abstraction

Hide details, expose essentials. Users of a module shouldn't need to know how it
works.

**Test:** Can you change the implementation without changing callers?

### Modularity

Self-contained pieces with clear boundaries.

**Test:** Can you understand this module without reading others?

### Deep vs Shallow Modules

| Deep Module                | Shallow Module            |
| -------------------------- | ------------------------- |
| Simple interface           | Complex interface         |
| Powerful functionality     | Little functionality      |
| Hides complexity           | Exposes complexity        |
| Worth the abstraction cost | Abstraction adds overhead |

> "The best modules provide powerful functionality with simple interfaces." —
> John Ousterhout

### Coupling and Cohesion

| Metric       | Goal | Meaning                                        |
| ------------ | ---- | ---------------------------------------------- |
| **Coupling** | Low  | Modules don't depend on each other's internals |
| **Cohesion** | High | Related things stay together                   |

**Loose coupling:** Change one module without changing others.

**High cohesion:** Everything in a module serves the same purpose.

## Heuristics

### Sandi Metz's Rules

- Classes: < 100 lines
- Methods: < 5 lines
- Parameters: ≤ 4
- Controllers: instantiate one object

_Rules are for breaking — but know when and why._

### Classic Principles

| Principle | Meaning                                                |
| --------- | ------------------------------------------------------ |
| **KISS**  | Keep It Simple, Stupid                                 |
| **YAGNI** | You Aren't Gonna Need It                               |
| **DRY**   | Don't Repeat Yourself (but don't over-abstract either) |

### Warning Signs

- "Let me explain how this works..."
- "Don't touch that, it's fragile"
- "Only Alice understands that code"
- "We'll clean it up later"
- Deep inheritance hierarchies
- God objects / god functions
- Circular dependencies

## Strategies

### When Adding Features

1. Can I extend without modifying? (Open-Closed)
2. Where does this naturally belong?
3. Am I adding dependencies?
4. Will future-me understand this?

### When Debugging

1. What changed recently?
2. Can I isolate the problem?
3. What are the dependencies?
4. What assumptions am I making?

### When Refactoring

1. What's the smallest useful change?
2. Can I add tests first?
3. Am I solving a real problem or a hypothetical one?
4. Is now the right time? (Boy Scout Rule vs. Yak Shaving)

## The Complexity Budget

Every system has a complexity budget. Spend it on essential complexity.

| Spend on                    | Avoid spending on          |
| --------------------------- | -------------------------- |
| Domain modeling             | Clever abstractions        |
| Error handling that matters | Handling impossible cases  |
| Performance where measured  | Premature optimization     |
| Flexibility where needed    | Flexibility "just in case" |

### Questions to Ask

- Is this complexity essential or accidental?
- Am I solving today's problem or tomorrow's maybe-problem?
- Would a junior engineer understand this?
- What's the cost of simplifying later vs. now?

## The Paradox

Fighting complexity requires effort. That effort can itself introduce
complexity.

**Traps:**

- Over-engineering simple things
- Abstracting too early
- DRY at the cost of clarity
- Frameworks for 100-line scripts

**Resolution:** Bias toward simplicity. The cost of adding flexibility later is
usually less than the cost of maintaining unused flexibility now.

## Key Quotes

- "Controlling complexity is the essence of computer programming." — Brian
  Kernighan
- "Simplicity is prerequisite for reliability." — Edsger Dijkstra
- "There are two ways of constructing software: One way is to make it so simple
  that there are obviously no deficiencies. The other way is to make it so
  complicated that there are no obvious deficiencies." — C.A.R. Hoare
- "The purpose of software engineering is to control complexity, not to create
  it." — Pamela Zave

## Further Reading

- Fred Brooks — _No Silver Bullet_ (1986)
- John Ousterhout — _A Philosophy of Software Design_ (2018)
- Rich Hickey — _Simple Made Easy_ (2011 talk)
- Sandi Metz — _Practical Object-Oriented Design_ (2012)
- Dave Farley — _Modern Software Engineering_ (2021)

## See Also

- [Thinking](thinking.md) — Systems thinking helps manage complexity
