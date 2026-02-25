---
title: "Reasoning Cheat Sheet"
---

Your brain is a heuristic engine optimized for survival, not correctness.

## The Dual Process Model

Daniel Kahneman's framework for how humans think.

| System 1                         | System 2                          |
| -------------------------------- | --------------------------------- |
| Fast, automatic, effortless      | Slow, deliberate, effortful       |
| Pattern-matching, intuitive      | Logical, analytical               |
| Always running                   | Lazy — engages only when prompted |
| Prone to systematic errors       | Can catch errors (if activated)   |
| "This feels like a database bug" | "Let me profile before assuming"  |

Most reasoning errors come from System 1 answering a question that System 2
should handle. Experience makes this worse — experts develop stronger System 1
patterns, which fail silently when context shifts.

**The test:** When you feel confident about a decision, ask: "Am I
pattern-matching or actually reasoning through this?"

## Logical Fallacies

Errors in the structure of an argument. Fallacies make reasoning unreliable
regardless of whether the conclusion happens to be true.

### Relevance Fallacies

Premises that don't connect to the conclusion.

| Fallacy                 | Definition                                 | Technical Example                                                         | Antidote                                                    |
| ----------------------- | ------------------------------------------ | ------------------------------------------------------------------------- | ----------------------------------------------------------- |
| **Ad hominem**          | Attack the person, not the argument        | "This junior's review comments aren't worth considering"                  | Evaluate arguments on merit, regardless of source           |
| **Appeal to authority** | Accept claims because an authority says so | "We should use microservices because Google does"                         | Verify with evidence; context matters more than credentials |
| **Strawman**            | Misrepresent a position, then attack that  | "You want NoSQL? You don't care about data consistency at all?"           | Restate the actual position before responding               |
| **Red herring**         | Introduce irrelevant information           | During a security review: "We should really refactor this module first"   | Keep discussions scoped; track tangents separately          |
| **Tu quoque**           | Deflect by pointing out the critic's flaws | "You can't criticize my tech debt when your module has hardcoded secrets" | Both issues can be valid simultaneously                     |

### Presumption Fallacies

Arguments that assume what they're trying to prove.

| Fallacy                  | Definition                                   | Technical Example                                                         | Antidote                                      |
| ------------------------ | -------------------------------------------- | ------------------------------------------------------------------------- | --------------------------------------------- |
| **False dilemma**        | Present only two options when more exist     | "We either rewrite everything or accept permanent tech debt"              | Ask "What else?" to expand the solution space |
| **Sunk cost**            | Continue investing because of past costs     | "We've spent 6 months on this custom auth — we can't switch to OAuth now" | "If starting today, what would we choose?"    |
| **Slippery slope**       | Small step must lead to extreme consequences | "If we allow one day remote, nobody will ever come to the office"         | Require evidence for each step in the chain   |
| **Begging the question** | Assume the conclusion in the premise         | "This architecture is scalable because it's designed to handle growth"    | Ensure premises are independently verifiable  |
| **Nirvana fallacy**      | Reject solutions that aren't perfect         | "This cache doesn't solve 100% of performance issues, so skip it"         | Compare to realistic alternatives, not ideals |

### Weak Induction Fallacies

Insufficient evidence for the conclusion.

| Fallacy                       | Definition                                 | Technical Example                                                       | Antidote                                              |
| ----------------------------- | ------------------------------------------ | ----------------------------------------------------------------------- | ----------------------------------------------------- |
| **Hasty generalization**      | Broad conclusion from small sample         | "Tested on Chrome and Safari — works everywhere"                        | Distinguish exploratory from confirmatory testing     |
| **Post hoc ergo propter hoc** | Sequence implies causation                 | "We deployed yesterday, traffic dropped today — the feature caused it"  | Correlation is not causation; control for confounders |
| **Anecdotal evidence**        | Personal experience over systematic data   | "I shipped without tests once and it was fine, so testing is overrated" | Prioritize data over single cases                     |
| **Texas sharpshooter**        | Cherry-pick data that supports your theory | Reporting sprint velocity only from successful sprints                  | Pre-define success criteria before collecting data    |
| **Survivorship bias**         | Focus on winners, ignore the failures      | "Startups use MongoDB, so it must be the right choice"                  | Actively seek and study failure cases                 |

### Ambiguity Fallacies

Arguments that exploit unclear meaning.

| Fallacy          | Definition                                       | Technical Example                                                  | Antidote                                 |
| ---------------- | ------------------------------------------------ | ------------------------------------------------------------------ | ---------------------------------------- |
| **Equivocation** | Same term, different meanings within an argument | Using "testing" to mean unit tests here and QA there               | Define terms explicitly at the start     |
| **Composition**  | What's true for parts must be true for whole     | "Each team member is skilled, so the team will be high-performing" | Test assumptions about wholes separately |
| **Division**     | What's true for whole must be true for parts     | "Our company is innovative, so every employee must be innovative"  | Evaluate parts independently             |

### Meta-Fallacies

| Fallacy                   | Definition                                          | Technical Example                                                | Antidote                                         |
| ------------------------- | --------------------------------------------------- | ---------------------------------------------------------------- | ------------------------------------------------ |
| **Argument from fallacy** | Dismiss a conclusion because the argument is flawed | "Your caching argument has a flaw, so caching is wrong"          | A bad argument doesn't make the conclusion false |
| **Moving goalposts**      | Change acceptance criteria after they're met        | "The feature works, but now it also needs to handle edge case X" | Define criteria in writing before starting       |
| **Cargo cult**            | Copy patterns without understanding why they work   | Implementing microservices because successful companies use them | Understand the problem before copying solutions  |
| **Appeal to novelty**     | New must be better                                  | Adopting the latest framework without evaluating fit             | Assess tools against specific needs              |

## Cognitive Biases

Systematic deviations in judgment. Unlike fallacies (errors in arguments),
biases are errors in perception — your brain distorts input before reasoning
even begins.

### Decision-Making Biases

| Bias                       | Definition                                            | Engineering Example                                                               | Debiasing Technique                                   |
| -------------------------- | ----------------------------------------------------- | --------------------------------------------------------------------------------- | ----------------------------------------------------- |
| **Confirmation bias**      | Seek evidence that confirms; dismiss what contradicts | Debugging: "Must be the database" — check only DB logs                            | Seek disconfirming evidence first                     |
| **Anchoring**              | First number dominates subsequent estimates           | "2 weeks" becomes the baseline no matter what you learn later                     | Delay estimates until requirements are explored       |
| **Availability heuristic** | Overweight recent or vivid events                     | Over-prioritizing edge cases from last week's outage                              | Check metrics, not memory                             |
| **Framing effect**         | Decision changes based on how options are presented   | "Saves 20 hours/week" accepted; "Risks 4 hours downtime" rejected — same project  | Present as both gains and losses                      |
| **Loss aversion**          | Losses hurt twice as much as equivalent gains         | Feature work over refactoring — features feel like gains, debt prevention doesn't | Reframe: "invest $400K now vs face $2M rewrite later" |

### Estimation Biases

| Bias                 | Definition                                            | Engineering Example                                                  | Debiasing Technique                            |
| -------------------- | ----------------------------------------------------- | -------------------------------------------------------------------- | ---------------------------------------------- |
| **Planning fallacy** | Underestimate time by simulating best-case scenarios  | "2 days" for a task that historically takes 5                        | Reference class forecasting from past actuals  |
| **Optimism bias**    | Believe bad outcomes are less likely for you          | "Our migration will go smoothly" (most don't)                        | Track estimation accuracy; calibrate over time |
| **Dunning-Kruger**   | Low skill overestimates; high skill underestimates    | Junior: "I know React" after one tutorial. Senior: imposter syndrome | Seek objective skill assessments               |
| **Normalcy bias**    | Dismiss warnings because things have been fine so far | Ignoring alerts because "it's probably nothing"                      | Analyze near-misses; treat warnings as data    |

### Social and Team Biases

| Bias                              | Definition                             | Engineering Example                                                 | Debiasing Technique                                 |
| --------------------------------- | -------------------------------------- | ------------------------------------------------------------------- | --------------------------------------------------- |
| **Authority bias**                | Overvalue opinions from hierarchy top  | Junior spots bug in senior's code but approves anyway               | Anonymous review; explicitly value merit over rank  |
| **Bandwagon effect**              | Adopt beliefs because others hold them | "Everyone is moving to Kubernetes, so we should too"                | Evaluate against specific needs, not popularity     |
| **Groupthink**                    | Consensus-seeking suppresses dissent   | No one challenges the tech lead's architecture proposal             | Assign devil's advocate; require documented dissent |
| **Fundamental attribution error** | Blame people, not systems              | "Alice caused the outage" vs "Missing guardrails caused the outage" | Ask "what system failed?" before "who failed?"      |

### Retrospective Biases

| Bias                       | Definition                                     | Engineering Example                                                       | Debiasing Technique                               |
| -------------------------- | ---------------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------- |
| **Hindsight bias**         | "I knew it all along" after the fact           | Post-incident: "We always had concerns" (but no one raised them before)   | Document predictions before outcomes              |
| **Outcome bias**           | Judge decision quality by result, not process  | Criticizing an architecture that failed due to unforeseeable market shift | Evaluate based on what was known at decision time |
| **IKEA effect**            | Overvalue what you built yourself              | Defending your code design against valid criticism                        | Separate creation from evaluation                 |
| **Choice-supportive bias** | Remember past choices as better than they were | Recalling only benefits of a past tech choice, forgetting the pain        | Keep decision records; review them honestly       |

### How Biases Compound

Biases rarely act alone. Common combinations:

| Combination                           | Context      | Effect                                                   |
| ------------------------------------- | ------------ | -------------------------------------------------------- |
| Confirmation bias + anchoring         | Estimation   | Initial estimate sticks; team seeks only confirming data |
| Availability heuristic + recency bias | Debugging    | Over-investigate causes similar to last incident         |
| Authority bias + groupthink           | Architecture | Senior's proposal rubber-stamped without critique        |
| Loss aversion + sunk cost             | Tech debt    | Keep broken approach because change feels like loss      |
| IKEA effect + choice-supportive bias  | Code review  | Resist refactoring code you wrote                        |

## Debiasing Techniques

Knowledge of biases doesn't prevent them — they operate below conscious
awareness. You need **systems**, not just understanding.

### Pre-Mortem (Klein)

Imagine the project has already failed. Work backward to identify why.

1. Individual brainstorm: list 5-10 reasons for failure
2. Round-robin sharing (no debate)
3. Categorize: technical, organizational, external, assumptions
4. Identify early warning signals for top risks

Increases risk identification accuracy by 30%. Kahneman calls it his favorite
debiasing technique.

### Reference Class Forecasting

Base estimates on actual outcomes from similar past work, not the inside view of
the current project.

```text
Last 5 API integrations: 3, 4, 6, 3, 5 weeks
Average: 4.2 weeks
Your estimate for the next one: start at 4.2, adjust for specifics
```

Counteracts planning fallacy and optimism bias.

### Steel-Manning

Present the strongest version of an opposing argument before responding.

**Dennett's protocol:**

1. Re-express the position so clearly the holder says "I wish I'd put it that
   way"
2. List points of agreement
3. Mention what you learned from their position
4. Only then offer rebuttal

Prevents strawman fallacy and builds collaborative truth-seeking.

### Decision Journals

Record decisions with reasoning, predictions (with confidence levels), and
expected outcomes. Review quarterly.

```text
Date:       2026-02-21
Decision:   Use PostgreSQL over MongoDB for user service
Reasoning:  Access patterns are relational joins; ACID needed
Prediction: Read latency <50ms, write throughput >1000 ops/sec (70% confident)
Revisit:    2026-05-21
```

Creates a feedback loop that calibrates judgment over time.

### Checklists (Gawande)

Brief reminders of essential steps that experts might skip. Not procedures —
guardrails.

Get "dumb stuff out of the way so the brain can concentrate on the hard stuff."

### Consider-the-Opposite

Generate 2-3 reasons you might be wrong. Research shows 2 counterarguments is
effective; 10 is counterproductive (the difficulty makes you _more_ confident).

### Blameless Post-Mortems

Focus on **what** happened and **how** systems failed, not **who** made
mistakes. Use "what" questions ("What was your understanding?") instead of "why"
questions ("Why did you deploy without testing?"). Reveals systemic factors:
time pressure, unclear requirements, missing guardrails.

## Team-Level Debiasing

| Technique                | Counters                              | How It Works                                                                            |
| ------------------------ | ------------------------------------- | --------------------------------------------------------------------------------------- |
| **Delphi method**        | Authority bias, groupthink, bandwagon | Anonymous rounds of independent evaluation; converge through iteration                  |
| **Silent voting first**  | Anchoring, authority bias             | Everyone commits a position before discussion                                           |
| **Devil's advocate**     | Groupthink, confirmation bias         | Assign someone to argue against the prevailing view                                     |
| **Cognitive diversity**  | Shared blind spots                    | Assemble diverse thinking styles, not just demographics                                 |
| **Psychological safety** | Self-censorship, authority bias       | People must feel safe to dissent; Google found it was the #1 factor in team performance |

## Heuristics

### Where Fallacies and Biases Strike

| Context           | Common Fallacies                             | Common Biases                                   |
| ----------------- | -------------------------------------------- | ----------------------------------------------- |
| Code review       | Ad hominem, strawman, appeal to authority    | Authority bias, IKEA effect, bikeshedding       |
| Architecture      | False dilemma, cargo cult, appeal to novelty | Groupthink, anchoring, survivorship bias        |
| Estimation        | Nirvana fallacy, false dilemma               | Planning fallacy, anchoring, optimism bias      |
| Debugging         | Post hoc, hasty generalization               | Confirmation bias, availability, recency bias   |
| Incident response | Red herring, tu quoque                       | Fundamental attribution error, hindsight bias   |
| Hiring            | Ad hominem, anecdotal evidence               | Confirmation bias, representativeness heuristic |

### Quick Checks

- **Before deciding:** What evidence would change my mind? (confirmation bias)
- **Before estimating:** What did similar past work actually take? (planning
  fallacy)
- **Before debating:** Can I state the opposing view so its holder would agree?
  (strawman)
- **After an incident:** What system failed, not who failed? (attribution error)
- **When confident:** Am I pattern-matching or reasoning? (System 1 vs 2)

## Key Quotes

- "The first principle is that you must not fool yourself — and you are the
  easiest person to fool." — Richard Feynman
- "It is difficult to get a man to understand something when his salary depends
  on his not understanding it." — Upton Sinclair
- "We don't see things as they are, we see them as we are." — Anais Nin
- "The greatest enemy of knowledge is not ignorance, it is the illusion of
  knowledge." — Daniel Boorstin

## Further Reading

- Daniel Kahneman — _Thinking, Fast and Slow_ (2011)
- Philip Tetlock — _Superforecasting_ (2015)
- Atul Gawande — _The Checklist Manifesto_ (2009)
- Donella Meadows — _Thinking in Systems_ (2008)
- Gary Klein — _Sources of Power_ (1998)
- Buster Benson — "Cognitive Bias Codex" (2016)

## See Also

- [Thinking](thinking.md) — Mental models and systems thinking
- [Problem Solving](problem-solving.md) — Structured approaches; traps section
  covers complexity bias and tunnel vision
- [Complexity](complexity.md) — Essential vs accidental; the paradox of fighting
  complexity with complexity
