---
title: "Reasoning Lesson Plan"
description:
  Eight lessons from spotting logical fallacies to recognizing cognitive biases
  and building systemic debiasing habits.
---

Recognizing flawed reasoning in others is easy. Catching it in yourself is the
real skill. This plan builds from external detection to internal awareness to
systemic change.

<!-- prettier-ignore -->
:::note[Prerequisites]
No technical prerequisites. Willingness to examine your
own thinking.
:::

## Lesson 1: Logical Fallacies — Spotting Broken Arguments

**Goal:** Identify common reasoning errors in technical arguments.

### Concepts

Logical fallacies are errors in argument structure that make reasoning
unreliable, regardless of whether the conclusion happens to be true. They divide
into two broad families: _formal_ fallacies (broken logical structure —
detectable from form alone) and _informal_ fallacies (flawed premises or
irrelevant connections — detectable only by examining content).

The informal fallacies that matter most in engineering fall into four
categories: relevance (premises don't connect to the conclusion), presumption
(the argument assumes what it's trying to prove), weak induction (insufficient
evidence), and ambiguity (terms shift meaning mid-argument).

Knowing the name matters less than recognizing the pattern. When someone says
"We should use microservices because Google does," the problem isn't that they
committed an _appeal to authority_ — the problem is that Google's context
differs from yours, and the argument doesn't establish that the approach fits
your constraints.

### Exercises

1. **Code review comment analysis**

   Read these anonymized code review exchanges. Identify the fallacy in each and
   explain why the reasoning is unreliable.

   ```text
   a) "This code is terrible — typical junior developer work."
      → What fallacy? Why is it unreliable?

   b) "The tech lead always structures it this way, so we should too."
      → What fallacy? Why is it unreliable?

   c) "Either we refactor the entire module or leave it as-is."
      → What fallacy? Why is it unreliable?

   d) "We tried caching once two years ago and it caused bugs,
       so caching is always more trouble than it's worth."
      → What fallacy? Why is it unreliable?

   e) "Your argument for REST has a fallacy in it,
       so GraphQL is clearly the better choice."
      → What fallacy? Why is it unreliable?
   ```

2. **Tech blog critique**

   Find a blog post arguing for a specific technology choice (framework,
   database, language). Read it critically and identify:
   - At least 2 fallacies or weak reasoning patterns
   - Where the argument would need evidence but relies on assertion instead
   - What a stronger version of the same argument would look like

3. **Fallacy field log**

   Over the next 3 days, log fallacies you encounter in meetings, Slack threads,
   PRs, or articles. Record: the context, the fallacy, and what stronger
   reasoning would look like. Aim for 5 entries.

### Checkpoint

- Can you name 5 fallacy categories and give a technical example of each?
- Can you spot the difference between a weak argument and a wrong conclusion?

---

## Lesson 2: Cognitive Biases — The Mental Operating System

**Goal:** Understand how systematic mental shortcuts distort judgment.

### Concepts

Cognitive biases are different from fallacies. Fallacies are errors in
_arguments_ — you can spot them by examining the reasoning. Biases are errors in
_perception_ — your brain distorts input before reasoning begins. You can
construct a logically valid argument and still reach a wrong conclusion because
the premises were filtered through biased perception.

Kahneman's dual-process model explains why: System 1 (fast, automatic,
pattern-matching) handles most thinking. System 2 (slow, deliberate, logical)
engages only when cued. Biases are System 1 shortcuts — heuristics that work
most of the time but fail systematically in predictable situations.

The key insight: biases exist because they're useful. Anchoring helps you
estimate quickly. Confirmation bias protects cognitive load by filtering noise.
Availability helps you react to recent threats. The problem isn't that these
heuristics exist — it's that they fire in contexts where they mislead.

### Exercises

1. **Bias matching**

   Match each bias to the engineering scenario it best explains.

   ```text
   Biases:
   A. Confirmation bias     D. Anchoring
   B. Planning fallacy      E. Availability heuristic
   C. Sunk cost fallacy     F. Dunning-Kruger effect

   Scenarios:
   1. "This task will take 2 days" — it takes 8.
   2. "Must be a database bug" — you check only DB logs.
   3. "We've invested 6 months in this framework, we can't switch now."
   4. First estimate of "3 sprints" sticks through all re-planning.
   5. After last week's outage, the team over-invests in that exact
      failure mode while ignoring more common risks.
   6. Junior finishes one React tutorial and claims production readiness.
   ```

2. **System 1 vs System 2 experiment**

   Pick 5 small technical decisions from your upcoming day (naming a variable,
   choosing an approach, estimating a task). For each:
   - First: write your System 1 gut answer (2 seconds, no thinking)
   - Then: spend 5 minutes reasoning through it deliberately (System 2)
   - Compare: where did they agree? Where did they diverge? What changed?

3. **Personal bias inventory**

   Review your last 10 technical decisions (PRs, architecture choices,
   estimates). For each, ask: "Which bias might have influenced this?" Identify
   your top 3 recurring biases. Be specific — not "I'm biased" but "I
   consistently underestimate integration work by 40%."

### Checkpoint

- Can you explain the adaptive purpose of 3 different biases?
- Can you identify 3 situations where each bias leads engineers astray?

---

## Lesson 3: Case Studies — When Reasoning Fails at Scale

**Goal:** Analyze real-world failures through a critical thinking lens.

### Concepts

Abstract knowledge of biases doesn't transfer to real decisions. Analogical
training — learning through concrete cases — outperforms abstract instruction
for debiasing. These cases show how biases compound in organizations, turning
small judgment errors into catastrophic outcomes.

The common thread: no single person was irrational. Each actor made locally
reasonable decisions that became collectively disastrous because of systemic
blind spots, suppressed dissent, and compounding biases.

### Exercises

1. **Knight Capital ($440M in 45 minutes)**

   In August 2012, Knight Capital deployed code that reactivated dormant trading
   logic, executing millions of erroneous trades in 45 minutes. The company lost
   $440 million and never recovered.

   ```text
   Analyze the failure:

   a) Identify 3 cognitive biases that contributed:
      - What role did normalcy bias play?
        (Hint: alerts were dismissed as routine)
      - What role did optimism bias play in deployment practices?
      - What systemic factor enabled a single deployment to be fatal?

   b) Map the failure tree — what independent failures had to align?
      - Deployment process
      - Testing coverage
      - Monitoring and circuit breakers
      - Kill switch availability

   c) What debiasing structures would have caught this?
      - Pre-mortem
      - Deployment checklist
      - Automated safeguards
   ```

2. **Healthcare.gov launch (2013)**

   The federal healthcare marketplace launched to catastrophic failure despite
   repeated internal warnings that the system wasn't ready.

   ```text
   Analyze the organizational biases:

   a) Authority bias: Executives overrode engineers' warnings.
      What questions would have surfaced the real status?

   b) Sunk cost: Launch date was legally mandated. How did this
      create a "launch anyway" bias even when engineers knew it
      would fail?

   c) What decision-making structure would allow engineers to
      escalate warnings past organizational hierarchy?
   ```

3. **Pattern extraction**

   Compare the two cases. What do they share?

   ```text
   Fill in:
   - Both had warnings that were ______
   - Both lacked ______ between those who knew and those who decided
   - Both suffered from ______ bias (believing things would work
     out despite evidence)
   - The systemic fix for both is ______
   ```

### Checkpoint

- Can you identify 3 biases that contributed to each failure?
- Can you propose a systemic intervention (not "be more careful") that would
  have surfaced problems earlier?

---

## Lesson 4: Decision Journals — Tracking Your Own Reasoning

**Goal:** Build the habit of documenting decisions for later review.

### Concepts

Metacognition — thinking about your own thinking — is the bridge between knowing
about biases and catching them in yourself. The problem: memory is unreliable.
Hindsight bias rewrites your recollection of past reasoning. Choice-supportive
bias makes past decisions seem better than they were. Without written records,
you can't learn from your own judgment.

A decision journal creates a feedback loop. You record your reasoning and
predictions at decision time, then compare to actual outcomes later. This
calibrates your confidence over time — you learn where your judgment is reliable
and where it systematically fails.

Decision quality and outcome quality are different things. A good decision can
have a bad outcome (bad luck). A bad decision can have a good outcome (good
luck). Evaluate the process, not the result.

### Exercises

1. **Decision journal setup**

   Create a journal (file, notebook, spreadsheet — whatever you'll actually use)
   with this template:

   ```text
   Date:        ___
   Decision:    What you decided
   Context:     What situation prompted this
   Options:     What alternatives you considered
   Reasoning:   Why you chose this option
   Prediction:  What you expect to happen (be specific)
   Confidence:  How confident are you? (50%? 80%? 95%?)
   Revisit by:  When you'll check the outcome
   ```

   Log at least 1 technical decision per day for the next 2 weeks. Good
   candidates: estimation calls, technology choices, design tradeoffs, debugging
   hypotheses.

2. **Retrospective review**

   After 2 weeks, review your logged decisions:

   ```text
   For each decision, record:
   - Actual outcome: What happened?
   - Accuracy: Was your prediction right?
   - Calibration: Were your confidence levels accurate?
     (Of your "80% confident" predictions, were ~80% correct?)
   - Patterns: Which types of decisions do you judge well?
     Which poorly?
   - Recurring biases: What bias appears most often?
   ```

3. **Custom pre-decision checklist**

   Based on your personal bias inventory (Lesson 2) and journal patterns, create
   a 3-5 item checklist to run before significant decisions.

   ```text
   Example (for someone prone to optimism bias + anchoring):

   Before estimating:
   [ ] What did similar past work actually take?
   [ ] What's the realistic worst case?
   [ ] Am I anchored on someone else's number?
   [ ] Have I accounted for integration, testing, and review time?
   ```

### Checkpoint

- Do you have 10+ logged decisions with predictions?
- Can you identify one recurring bias in your decision-making?
- Is your confidence well-calibrated? (50% predictions right ~half the time?)

---

## Lesson 5: Pre-Mortems — Imagining Failure Before It Happens

**Goal:** Use inversion to surface risks that normal planning misses.

### Concepts

Gary Klein's pre-mortem technique inverts the question. Instead of "What could
go wrong?" (which triggers optimism bias — people downplay risks), assume the
project has already failed and ask "What went wrong?"

This small reframe — prospective hindsight — increases risk identification
accuracy by 30%. It works because failure feels concrete and real, so people
generate richer, more honest explanations. Team members who might feel
"impolitic" raising concerns during normal planning feel safe explaining a
hypothetical failure.

The difference from risk analysis: risk analysis asks "What might happen?"
(speculative, easy to dismiss). Pre-mortem says "It happened. Why?" (concrete,
harder to dismiss).

### Exercises

1. **Solo pre-mortem**

   Pick an upcoming project or significant task.

   ```text
   Imagine it's 3 months from now. The project failed spectacularly.

   Write 10 specific reasons it failed:
   1.
   2.
   3.
   ...
   10.

   Now categorize each:
   - Technical (architecture, scaling, integration)
   - Organizational (communication, resources, priorities)
   - External (dependencies, market, requirements change)
   - Assumptions (things you believed that turned out false)

   For your top 3 risks:
   - What's the early warning signal?
   - What would you do now to reduce the risk?
   ```

2. **Comparative analysis**

   Run both a traditional risk analysis and a pre-mortem on the same project.

   ```text
   Traditional risk analysis:
   "What could go wrong with this project?"
   List risks: ___

   Pre-mortem:
   "The project failed. What went wrong?"
   List causes: ___

   Compare:
   - Which technique surfaced more risks?
   - Which surfaced different kinds of risks?
   - Which felt more honest?
   ```

3. **Group pre-mortem simulation**

   With 2-3 colleagues, run a 20-minute pre-mortem on a shared project:

   ```text
   Format:
   - 5 min: Individual brainstorming (silent)
   - 8 min: Round-robin sharing (no debate, just listing)
   - 5 min: Vote on top 3 risks
   - 2 min: Assign early-warning signal for each

   Rules:
   - No pushback during sharing ("That won't happen" is banned)
   - Quantity over quality in brainstorming phase
   - Categorize after generating, not during
   ```

### Checkpoint

- Can you run a 20-minute pre-mortem solo?
- Did the pre-mortem surface risks you hadn't considered in normal planning?
- Can you articulate why "it failed — why?" works better than "what might go
  wrong?"

---

## Lesson 6: Steel-Manning — Arguing for the Other Side

**Goal:** Practice charitable interpretation and intellectual humility.

### Concepts

The opposite of a strawman is a steel-man: represent the opposing argument in
its strongest possible form, then address _that_ version. This is harder than it
sounds — it requires understanding the other position well enough to improve it.

Daniel Dennett's protocol for constructive criticism:

1. Re-express the other position so clearly they'd say "I wish I'd put it that
   way"
2. List points of agreement
3. Mention what you learned from their position
4. Only then offer your rebuttal

Steel-manning isn't about being nice. It's about being rigorous. If you can only
defeat the weakest version of an argument, you haven't actually addressed it.
The strongest version might reveal tradeoffs you hadn't considered.

In engineering, strawmanning is epidemic: "So you want to use NoSQL? You don't
care about consistency?" Steel-manning transforms the conversation: "The
strongest case for NoSQL here is that our access patterns are key-value lookups,
write throughput matters more than ACID, and eventual consistency is acceptable.
Let's evaluate whether those assumptions hold."

### Exercises

1. **Steel-man a position you disagree with**

   Pick a technical position you think is wrong (examples: "Microservices are
   always better," "TDD is a waste of time," "Rewrites are never worth it").

   ```text
   Position I disagree with: ___

   Steel-man (strongest possible argument for this position):
   - Premise 1: ___
   - Premise 2: ___
   - Premise 3: ___
   - Best evidence: ___
   - Context where this is most compelling: ___

   Test: Would a genuine advocate agree this is a fair
   representation of their view? Show them and find out.
   ```

2. **Debate with switching**

   Find a partner. Pick a contentious tech decision (TypeScript vs JavaScript,
   SQL vs NoSQL, monolith vs microservices).

   ```text
   Round 1 (5 min): Argue for your actual position.
   Round 2 (5 min): Switch — argue for the opposite position.
   Debrief:
   - What was the strongest point for the other side?
   - Did switching change your view?
   - What tradeoff did you discover that you hadn't considered?
   ```

3. **Steel-man code review**

   Before your next code review, write one paragraph explaining the strongest
   rationale for the approach taken. Only then suggest alternatives.

   ```text
   PR: ___
   Steel-man for the author's approach:
   ___

   My suggestions (after steel-manning):
   ___

   Reflection: Did steel-manning change the tone or content
   of your feedback?
   ```

### Checkpoint

- Can you articulate an opposing technical view so well its holder would agree
  with your summary?
- Has steel-manning changed your mind about anything?
- Has the tone of your code reviews shifted?

---

## Lesson 7: Biases in Engineering Practice

**Goal:** Catch domain-specific bias patterns in estimation, code review, and
architecture.

### Concepts

Research shows ~49% of developer actions involve some form of cognitive bias,
and LLM-assisted development increases this to ~56%. The biases aren't
distributed evenly — specific biases cluster around specific engineering
activities:

- **Code review:** Authority bias (rubber-stamping seniors), bikeshedding
  (debating names, ignoring logic), IKEA effect (defending your own code)
- **Estimation:** Planning fallacy (best-case simulation), anchoring (first
  number sticks), optimism bias (especially strong in technical professionals)
- **Architecture:** Bandwagon effect (Kubernetes because everyone else),
  survivorship bias (copying patterns from companies that succeeded), NIH bias
  (rebuilding what libraries already solve)
- **Debugging:** Confirmation bias (testing only your first hypothesis), recency
  bias (assuming the bug resembles the last one), availability heuristic
  (looking where the light is)

The debiasing goal at this level isn't knowledge — it's practice. You need
repeated exposure to catching biases in your actual work, not hypothetical
scenarios.

### Exercises

1. **Code review bias audit**

   Review your last 10 code review comments (given or received).

   ```text
   For each comment, ask:
   - Did I spend more time on style than substance? (bikeshedding)
   - Did I skip complex sections? (complexity aversion)
   - Did I defer to seniority rather than evaluate on merit?
     (authority bias)
   - Did I defend my approach because I wrote it? (IKEA effect)

   Rewrite 3 comments with debiased framing.

   Original: ___
   Debiased: ___
   What changed: ___
   ```

2. **Estimation calibration**

   For 10 upcoming small tasks, record:

   ```text
   Task | Gut estimate | Deliberate estimate | Reference class | Actual
   -----+--------------+---------------------+-----------------+-------
        |              |                     |                 |
        |              |                     |                 |

   After completing all 10:
   - Optimism ratio = average(estimated / actual)
     < 1.0 means you overestimate (rare)
     > 1.0 means you underestimate (common)
   - Which estimation method was most accurate?
   - Practice confidence intervals:
     "70% confident: 2-4 hours. 95% confident: 1-8 hours."
   ```

3. **Architecture decision debiasing**

   Pick a recent technology choice.

   ```text
   Decision: ___
   Check for:
   [ ] Bandwagon — Did I choose this because it's popular?
   [ ] Authority — Did I choose this because a respected person
       recommended it?
   [ ] Survivorship — Am I looking only at success stories?
   [ ] NIH — Am I rebuilding something a library already solves?
   [ ] Confirmation — Did I seek only evidence supporting
       my preference?

   Disconfirming evidence: What evidence would make this
   the wrong choice? Actively look for it.
   ```

### Checkpoint

- What's your optimism ratio? Is it improving?
- Can you identify 3 biases in your last architecture proposal?
- Have your code reviews changed in tone or focus?

---

## Lesson 8: Systemic Debiasing — Building Bias-Resistant Processes

**Goal:** Design organizational processes that reduce bias without relying on
individual awareness.

### Concepts

Individual debiasing has a ceiling. Knowledge of biases doesn't prevent them —
they operate below conscious awareness. The bias blind spot (recognizing bias in
others but not yourself) persists even among experts. People high in bias blind
spot are _more resistant_ to debiasing training.

The solution: shift from individual awareness to structural interventions. Build
processes where biases can't take hold, rather than relying on people to catch
their own errors.

Blameless post-mortems exemplify this. Instead of asking "Why did Alice deploy
without testing?" (which triggers fundamental attribution error), ask "What
circumstances led this deployment to happen without testing?" This surfaces
systemic factors: time pressure, unclear requirements, missing automated
guardrails, inadequate staging environments.

The highest-leverage debiasing interventions are structural:

- **Pre-mortems** before projects (surfaces risks despite optimism bias)
- **Blameless post-mortems** after incidents (counters attribution error)
- **Silent voting before discussion** (prevents anchoring and authority bias)
- **Decision journals** for recurring high-impact decisions (calibrates
  judgment)
- **Automated guardrails** (catches errors regardless of bias)
- **Psychological safety** as foundation (enables all other techniques)

### Exercises

1. **Blameless post-mortem facilitation**

   Use the Knight Capital case (Lesson 3) as a practice incident. Run a mock
   post-mortem following this structure:

   ```text
   Template:
   - Timeline: What happened? (facts, not blame)
   - Impact: What was the effect?
   - Contributing factors: What enabled this failure?
     (plural — never "root cause")
   - What worked: What prevented it from being worse?
   - Action items: What will we change?

   Rules:
   - Use "what" and "how" questions, not "why"
   - "What was the understanding at the time?" NOT
     "Why didn't you check?"
   - Focus on systemic factors: process, tooling, communication
   - No counterfactuals: "You should have..." is banned
   ```

2. **Personal incident post-mortem**

   Pick a bug you introduced or a project that went poorly.

   ```text
   Write a blameless post-mortem on yourself:

   Timeline: What happened?
   Contributing factors (systemic, not personal):
   - Time pressure? ___
   - Unclear requirements? ___
   - Missing tests? ___
   - Inadequate review? ___
   - Wrong assumptions? ___

   What would make this category of error less likely?
   (Not "be more careful" — structural changes only)
   ```

3. **Systemic intervention design**

   Pick one bias your team struggles with. Design a process intervention that
   doesn't rely on individual awareness.

   ```text
   Bias: ___
   Current impact: ___

   Proposed intervention:
   - What process change? ___
   - How does it structurally prevent the bias? ___
   - What's the cost (time, effort, friction)? ___
   - How will you measure if it's working? ___

   Examples:
   - Planning fallacy → Require reference class data in every estimate
   - Anchoring → Silent estimation before discussion (planning poker)
   - Authority bias → Anonymous code review (where tooling supports it)
   - Groupthink → Mandatory devil's advocate role, rotated weekly
   - Confirmation bias → Pre-mortem required for projects > 2 weeks
   ```

### Checkpoint

- Can you facilitate a 30-minute blameless post-mortem?
- Have you designed one systemic intervention for your team?
- Can you explain why structural interventions outperform individual awareness?

---

## Progression Summary

| Lesson | Focus              | Skill Level              | Key Practice                     |
| ------ | ------------------ | ------------------------ | -------------------------------- |
| 1      | Logical fallacies  | External recognition     | Spot errors in others' arguments |
| 2      | Cognitive biases   | Internal awareness       | Understand your mental shortcuts |
| 3      | Case studies       | Analysis                 | Dissect real-world failures      |
| 4      | Decision journals  | Self-monitoring          | Track your own reasoning         |
| 5      | Pre-mortems        | Prospective debiasing    | Surface risks before they strike |
| 6      | Steel-manning      | Collaborative reasoning  | Argue for the other side         |
| 7      | Engineering biases | Domain-specific practice | Catch biases in daily work       |
| 8      | Systemic debiasing | Organizational change    | Build bias-resistant processes   |

**Arc:** External detection → Internal awareness → Applied practice → Systemic
change

## Further Reading

- Daniel Kahneman — _Thinking, Fast and Slow_ (2011)
- Philip Tetlock — _Superforecasting_ (2015)
- Atul Gawande — _The Checklist Manifesto_ (2009)
- Gary Klein — _Sources of Power_ (1998)
- Donella Meadows — _Thinking in Systems_ (2008)

## See Also

- [Reasoning](../why/reasoning.md) — Fallacy and bias reference tables,
  debiasing techniques
- [Thinking](../why/thinking.md) — Mental models and systems thinking
- [Problem Solving](../why/problem-solving.md) — Structured approaches to hard
  problems
- [Complexity](../why/complexity.md) — Essential vs accidental complexity
