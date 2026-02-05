# Thinking Cheat Sheet

Judgment scales; execution is commoditized.

## Mental Models

### Fundamentals

| Model                    | Core Idea                                                         |
| ------------------------ | ----------------------------------------------------------------- |
| **First principles**     | Strip away assumptions; build from bedrock truths                 |
| **Inversion**            | Instead of "how do I succeed?" ask "how would I fail?"            |
| **Second-order effects** | Then what? And then what after that?                              |
| **Opportunity cost**     | Choosing X means not choosing Y                                   |
| **Reversibility**        | Two-way doors (cheap to undo) vs one-way doors (commit carefully) |
| **Leverage**             | Small inputs, large outputs — where's the fulcrum?                |

### Technical

| Model                      | Core Idea                                                                       |
| -------------------------- | ------------------------------------------------------------------------------- |
| **CAP theorem**            | Distributed systems: pick two of consistency, availability, partition tolerance |
| **Amdahl's law**           | Speedup limited by the part you can't parallelize                               |
| **Premature optimization** | Measure first; optimize the bottleneck                                          |
| **Leaky abstractions**     | All abstractions fail; know what's underneath                                   |
| **Worse is better**        | Simple, working beats perfect, unshipped                                        |
| **Gall's law**             | Complex systems that work evolved from simple systems that worked               |

### Decision-Making

| Model                   | Core Idea                                      |
| ----------------------- | ---------------------------------------------- |
| **Regret minimization** | Which choice will 80-year-old you regret less? |
| **Eisenhower matrix**   | Urgent vs important — different axes           |
| **Satisficing**         | "Good enough" beats endless optimization       |
| **Reversible defaults** | When uncertain, choose what's easiest to undo  |

## Systems Thinking

### Core Concepts

**Feedback loops** — Outputs become inputs

- _Reinforcing_: growth spirals (or death spirals)
- _Balancing_: self-correcting toward equilibrium

**Stocks and flows** — Accumulations and rates of change

- Don't confuse the bathtub (stock) with the faucet (flow)

**Delays** — Effects lag behind causes

- Systems overshoot because feedback arrives late

**Emergent behavior** — Whole > sum of parts

- Local optimization ≠ global optimization

### Questions to Ask

- Where are the feedback loops?
- What's the delay between action and effect?
- Who are the stakeholders I'm not seeing?
- What happens if this succeeds beyond expectations?
- What's the system optimizing for? Is that what we want?

### Traps

| Trap                   | Description                                                 |
| ---------------------- | ----------------------------------------------------------- |
| **Local optimization** | Improving your part while harming the whole                 |
| **Metric fixation**    | Goodhart's law: measure becomes target, ceases to be useful |
| **Linear thinking**    | Assuming proportional cause/effect in nonlinear systems     |
| **Ignoring delays**    | Impatience leads to over-correction                         |

## Asking Good Questions

### Before Building

- What problem are we actually solving?
- Who has this problem? How do they cope today?
- What would "done" look like?
- How will we know if it worked?
- What's the simplest thing that could possibly work?

### Before Deciding

- What would have to be true for this to be the right choice?
- What are we optimizing for? What are we sacrificing?
- Is this a one-way or two-way door?
- What do we believe that might be wrong?
- Who disagrees? Why?

### When Stuck

- What do I actually know vs assume?
- What question am I not asking?
- What would I try if I couldn't fail?
- What would a beginner do?
- What would I advise a friend in this situation?

### Debugging Questions

- What changed?
- What did I expect? What happened instead?
- Can I reproduce it?
- What's the smallest case that shows the bug?
- Am I solving the symptom or the cause?

## Minding the Real Goal

### The Goal Stack

```text
Immediate task    → "Deploy the feature"
Project goal      → "Increase user engagement"
Business goal     → "Grow revenue"
Actual goal       → "Build something people want"
Life goal         → "Do meaningful work"
```

Working on the wrong level wastes effort. Zoom out regularly.

### Traps

| Trap                          | Example                                                            |
| ----------------------------- | ------------------------------------------------------------------ |
| **Task fixation**             | Finishing the ticket vs solving the user's problem                 |
| **Vanity metrics**            | Optimizing for lines of code, story points, commits                |
| **Sunk cost**                 | Continuing because you've already invested, not because it's right |
| **Cargo culting**             | Copying practices without understanding why they work              |
| **Resume-driven development** | Choosing tech for your CV, not the problem                         |

### Reframes

- "What would success look like if this feature didn't exist?"
- "If we couldn't build this, how else might we achieve the goal?"
- "What's the user actually trying to accomplish?"
- "Will this matter in a week? A year?"

## Learning with AI

### The New Division of Labor

| AI handles well     | Humans handle better  |
| ------------------- | --------------------- |
| Syntax, boilerplate | Architecture, design  |
| Lookup, recall      | Judgment, taste       |
| First draft         | Final edit            |
| "How to X in Y"     | "Should we X at all?" |
| Speed               | Direction             |

### Skills That Compound

- **Verification** — Can you tell if the output is correct?
- **Decomposition** — Breaking problems into AI-sized chunks
- **Iteration** — Refining output through dialogue
- **Integration** — Combining AI output into coherent systems
- **Knowing when to go deep** — Some things need human understanding

### Effective AI Collaboration

**Do:**

- State context and constraints upfront
- Ask for reasoning, not just answers
- Verify against your mental model
- Iterate — first answer is rarely best
- Use AI to explore options, then decide yourself

**Don't:**

- Trust without verification
- Outsource understanding
- Skip building mental models
- Accept complexity you can't maintain
- Let AI make one-way-door decisions

### The Paradox

You must know enough to verify AI output, but AI reduces the need to memorize.

Resolution: Learn _principles_ deeply, _details_ just-in-time.

## Daily Practice

1. **Before starting**: What's the real goal here?
2. **When stuck**: What question am I not asking?
3. **After finishing**: What would I do differently?
4. **Weekly**: What did I learn? What's still fuzzy?

---

_"The formulation of a problem is often more essential than its solution."_ —
Einstein
