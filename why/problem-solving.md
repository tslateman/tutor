# Problem Solving Cheat Sheet

Structured approaches to breaking down hard problems.

## Polya's Method

George Polya's four-phase framework from _How to Solve It_ (1945).

### 1. Understand the Problem

- What is the unknown? What are the data? What is the condition?
- Can you restate the problem in your own words?
- Draw a diagram. Introduce notation.
- Separate the parts of the condition.

**Test:** Can you explain the problem to someone else?

### 2. Devise a Plan

- Have you seen this problem before? Or a similar one?
- Do you know a related problem with a known solution?
- Can you solve a simpler version first?
- Can you solve part of the problem?

**Test:** Can you articulate your approach before starting?

### 3. Execute the Plan

- Carry out your plan step by step.
- Check each step as you go.
- Can you prove each step is correct?

**Test:** At each step, can you explain why it's right?

### 4. Review

- Can you check the result?
- Can you derive the result differently?
- Can you use the result or method for another problem?
- What did you learn?

**Test:** Would you solve it the same way next time?

### When to Use

General-purpose framework. Works for any problem. Especially useful when you're
stuck at the start and don't know how to begin.

## Divide and Conquer

Break the problem into smaller, independent subproblems.

```text
Original problem
    ├── Subproblem A → Solve → Solution A
    ├── Subproblem B → Solve → Solution B
    └── Subproblem C → Solve → Solution C
                       ↓
              Combine solutions
```

### Requirements

- Subproblems should be independent (or nearly so)
- Solutions should be combinable
- Subproblems should be easier than the original

### Examples

| Domain      | Break Into                              |
| ----------- | --------------------------------------- |
| Sorting     | Sort halves, merge results              |
| Parsing     | Lex, parse, validate, transform         |
| Large tasks | Identify phases, complete one at a time |
| Debugging   | Isolate components, test independently  |
| Learning    | Break skill into subskills, master each |

### When to Use

- Problem is too large to hold in your head
- Clear boundaries exist between parts
- You can solve subproblems independently
- You can parallelize work

### Pitfall

Watch for hidden dependencies between subproblems. If solving A changes the
requirements for B, you don't have independent subproblems.

## Working Backwards

Start from the goal and trace back to the start.

```text
Goal state
    ↑ What step produces this?
Intermediate state
    ↑ What step produces this?
...
    ↑
Start state
```

### Examples

| Domain          | Application                                        |
| --------------- | -------------------------------------------------- |
| Math proofs     | Assume conclusion, find what implies it            |
| Test-driven dev | Write the test first, then the code                |
| Debugging       | Start from error, trace back to cause              |
| Planning        | Set deadline, work backward to identify milestones |
| API design      | Write the ideal call site, then implement          |

### When to Use

- Goal is clearer than the path
- Many possible starting points but one destination
- Forward progress feels aimless
- You need to set milestones or deadlines

### Pitfall

Don't confuse "what would give me the answer" with "what's actually true."
Working backwards generates candidates; verify forward.

## Analogical Reasoning

Find a similar problem you've already solved.

### The Process

1. **Identify** — What are the structural elements of this problem?
2. **Search** — What similar problems have I seen?
3. **Map** — Which elements correspond?
4. **Transfer** — Apply the old solution to the new context
5. **Verify** — Does the analogy actually hold?

### Example Mappings

| New Problem             | Similar Problem            | What Transfers           |
| ----------------------- | -------------------------- | ------------------------ |
| Rate limiting API calls | Traffic light intersection | Queue theory, throttling |
| User permissions        | Physical key systems       | Hierarchies, inheritance |
| Database transactions   | Bank transfers             | ACID properties          |
| Load balancing          | Checkout lanes at a store  | Queue distribution       |

### When to Use

- Problem feels familiar but context is different
- You have deep experience in adjacent domains
- Standard solutions exist for similar problems
- You want to leverage existing patterns

### Pitfall

Surface similarity can mislead. The checkout lane analogy breaks down when
requests have vastly different processing times. Verify that the structural
similarity holds where it matters.

## Constraint Relaxation

Remove constraints to find a solution to an easier problem, then add constraints
back.

### The Process

1. **List** all constraints on the problem
2. **Remove** one or more constraints
3. **Solve** the relaxed problem
4. **Analyze** how the solution violates removed constraints
5. **Modify** the solution to satisfy all constraints

### Example

```text
Original: Sort 1TB of data in 8GB RAM

Constraints:
  - Must fit in 8GB RAM
  - Must handle 1TB data
  - Must produce sorted output

Relax "fit in RAM":
  - If unlimited RAM → simple in-memory sort

Reintroduce constraint:
  - External merge sort: sort chunks that fit, merge results
```

### When to Use

- Too many constraints to consider simultaneously
- You don't know where to start
- You want to understand which constraints make the problem hard
- Looking for a baseline solution to improve

### Pitfall

Some constraints are load-bearing. Relaxing "must not corrupt data" to make
progress leads to solutions you can't actually use.

## Rubber Duck Debugging

Explain the problem out loud to externalize your thinking.

### Why It Works

- Forces you to articulate assumptions
- Slows down thinking to speaking pace
- Reveals gaps in understanding
- Activates different cognitive processes than silent thought

### The Process

1. State what the code (or solution) should do
2. Walk through step by step, explaining each part
3. When you say "and then obviously..." — stop and verify
4. The bug hides where explanation doesn't match reality

### Variations

| Audience         | Best For                            |
| ---------------- | ----------------------------------- |
| Rubber duck      | Low-stakes, immediate               |
| Colleague        | Fresh perspective, catches jargon   |
| Written document | Thorough analysis, future reference |
| Voice memo       | Captures stream of consciousness    |

### When to Use

- You've been staring at the same code for too long
- The solution "should work" but doesn't
- You can't articulate what's failing
- You're about to ask someone for help (explain it first)

See also: [Debugging](debugging.md) for the full scientific method.

## Choosing a Technique

| Situation                    | Try                           |
| ---------------------------- | ----------------------------- |
| Don't know where to start    | Polya's method                |
| Problem too big              | Divide and conquer            |
| Goal clearer than path       | Working backwards             |
| Feels familiar               | Analogical reasoning          |
| Too many constraints         | Constraint relaxation         |
| "It should work but doesn't" | Rubber duck                   |
| Bug in code                  | See [Debugging](debugging.md) |

### Combining Techniques

Techniques compose well:

1. Use **Polya's method** to understand the problem
2. Use **divide and conquer** to break it into subproblems
3. For each subproblem, try **analogical reasoning** first
4. If stuck, **relax constraints** to find a starting point
5. Use **rubber duck** when implementation doesn't match expectation
6. **Work backwards** from failing test to find the cause

## Common Traps

| Trap                       | Description                                     | Antidote                                  |
| -------------------------- | ----------------------------------------------- | ----------------------------------------- |
| **Premature optimization** | Solving for performance before correctness      | Make it work, make it right, make it fast |
| **X-Y problem**            | Asking about your solution, not your problem    | State the original goal                   |
| **Tunnel vision**          | Committing to first approach that comes to mind | Generate three options before choosing    |
| **Analysis paralysis**     | Overthinking instead of experimenting           | Time-box analysis, then try something     |
| **Complexity bias**        | Assuming hard problems need complex solutions   | Try the dumbest thing first               |

## Key Quotes

- "If you can't solve a problem, there is an easier problem you can solve: find
  it." — George Polya
- "The art of debugging is figuring out what you really told your program to do
  rather than what you thought you told it to do." — Andrew Singer
- "Weeks of coding can save you hours of planning." — Unknown
- "Make it work, make it right, make it fast." — Kent Beck

## See Also

- [Debugging](debugging.md) — Problem-solving applied to bugs
- [Thinking](thinking.md) — Mental models for approach selection
- [Complexity](complexity.md) — Understanding what makes problems hard
