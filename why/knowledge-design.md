# Knowledge Design

How to structure knowledge for transfer, not storage. The difference between
knowing something and teaching it is architecture — choosing what comes first,
what connects to what, and when to name things.

## The Five Skills

| Skill                     | Core Question                                         |
| ------------------------- | ----------------------------------------------------- |
| Taxonomy & Classification | "What groups exist and how do they relate?"           |
| Cognitive Task Analysis   | "What does the expert do that the learner can't see?" |
| Mental Modeling           | "What does the learner currently believe?"            |
| Semantic Labeling         | "When does this concept earn a name?"                 |
| Visual Communication      | "How do I make the structure visible?"                |

These five skills turn subject-matter expertise into learnable sequences. Each
addresses a different failure mode in knowledge transfer.

## Taxonomy & Classification

Grouping concepts, identifying parent/child relationships, and sequencing
prerequisites.

### Taxonomy Patterns

| Pattern          | Structure                 | Best For                           | Example                          |
| ---------------- | ------------------------- | ---------------------------------- | -------------------------------- |
| **Hierarchical** | Tree — parent/child       | Domains with clear containment     | Animal kingdom, file systems     |
| **Faceted**      | Multiple independent axes | Domains with cross-cutting traits  | Recipes (cuisine × diet × time)  |
| **Sequential**   | Ordered chain             | Domains with prerequisite ordering | Math curriculum, language levels |

### Building a Taxonomy

1. **List everything** — dump every concept, skill, and fact
2. **Group by affinity** — what belongs together? Name the groups
3. **Identify prerequisites** — which concepts require others first?
4. **Draw the tree** — if you can't draw it, you don't understand the subject
5. **Test with outsiders** — does someone unfamiliar agree with the groupings?

### Failure Modes

- **False peers** — concepts at the same level that differ in complexity
  ("variables" and "closures" side by side)
- **Missing parents** — leaf concepts with no containing category
- **Circular prerequisites** — A requires B requires A (usually means both need
  a shared foundation)
- **Overly deep trees** — more than four levels signals over-splitting

**Heuristic:** If you can't draw the tree, you don't understand the subject yet.

## Cognitive Task Analysis

Decomposing expert intuition into learnable steps. Experts chunk so aggressively
that they skip steps unconsciously — the "curse of knowledge."

### The Problem

An expert debugging a production outage "just knows" where to look. They've
internalized hundreds of pattern matches that a novice hasn't built yet. CTA
makes those invisible steps visible.

### Process

1. **Observe** — watch an expert perform the task, noting every action
2. **Elicit** — interview: "What were you thinking when you did X?" "What would
   you check if that didn't work?"
3. **Decompose** — break each step into sub-steps until a novice could follow
4. **Sequence** — order by prerequisite, not by habit

### Output

A **lesson progression** — the order in which concepts should be taught so each
builds on the last.

```text
Expert sees:     "The service is OOMing"
CTA decomposes:  1. Check pod status (kubectl get pods)
                 2. Read restart count (is it cycling?)
                 3. Check memory limits (resource.requests vs actual)
                 4. Read logs for allocation patterns
                 5. Profile heap if needed
                 → Each step is teachable; the expert skipped 1-4
```

### Self-CTA

When you are the expert, decompose your own intuition:

- Solve a problem slowly, narrating each decision
- Ask: "What did I check that I didn't consciously notice?"
- Write the steps down before they re-chunk into intuition

**Heuristic:** If your lesson plan has fewer steps than a novice would need,
you've skipped the CTA.

## Mental Modeling

The learner already has a mental model — it's just wrong, incomplete, or shaped
by a different domain. Teaching starts with seeing their current map and
building a bridge to the target map.

### Model Failures

| Failure Type           | Description                                      | Example                                                |
| ---------------------- | ------------------------------------------------ | ------------------------------------------------------ |
| **Missing concept**    | No node exists for this idea                     | Learner has no concept of "ownership" (Rust)           |
| **Wrong relationship** | Nodes exist but edges are wrong                  | "HTTP is TCP" instead of "HTTP uses TCP"               |
| **Overgeneralization** | One model stretched to cover unrelated territory | "Everything is an object" applied to Go                |
| **False analogy**      | Prior domain maps poorly to new one              | "Git branches are copies" (from SVN mental model)      |
| **Invisible layer**    | An abstraction hides a critical mechanism        | "The network is reliable" (from local-only experience) |

### Bridging Techniques

- **Anchored analogy** — connect to what they know, then show where the analogy
  breaks ("Channels are like pipes, except they block when full")
- **Progressive refinement** — start with the simplified model, add complexity
  as they're ready ("First, think of memory as a big array. Later, we'll add the
  stack and heap distinction")
- **Misconception-first teaching** — surface the wrong model explicitly, then
  correct it ("You might think git pull fetches changes. It actually does two
  things...")
- **Contrast pairs** — show two similar things side by side to highlight the
  difference ("mutex vs channel — both synchronize, different tradeoffs")

**Heuristic:** If the learner nods but can't solve the problem, they have the
words but not the model.

## Semantic Labeling

Choosing precise but accessible terminology — and introducing it at the right
moment. Jargon is a power tool: essential for experts, dangerous for beginners.

### The "Name It When You Need It" Principle

Introduce a term only when the learner has a concept that needs a name:

```text
Bad:   "Today we'll learn about monads, functors, and applicatives."
       (Three names for concepts the learner can't anchor)

Good:  "You've been chaining these operations with .then(). That pattern
       has a name: it's a monad. Now you can search for it."
       (Name arrives when the concept has a home)
```

### Vocabulary Progression

| Phase            | Vocabulary Level                        | Example                              |
| ---------------- | --------------------------------------- | ------------------------------------ |
| **Introduction** | Plain language, no jargon               | "A box that holds a value"           |
| **Familiarity**  | Introduce the term alongside plain form | "This box — called an Option — ..."  |
| **Fluency**      | Use the term, define it in glossary     | "Option<T> wraps a nullable value"   |
| **Expertise**    | Assume the term, use in compound forms  | "Option::map chains transformations" |

### Failure Modes

- **Premature jargon** — terms before concepts (learner memorizes without
  understanding)
- **Jargon avoidance** — refusing to name things (learner can't search, can't
  communicate with peers)
- **Inconsistent naming** — same concept called different things in different
  lessons
- **Overloaded terms** — same word meaning different things in different
  contexts without flagging the ambiguity

**Heuristic:** If the learner can use the jargon but not explain it in plain
language, the label arrived before the concept.

## Visual Communication

Translating abstract hierarchies into spatial relationships. A diagram
communicates structure that prose cannot — but only if the spatial choices carry
meaning.

### Spatial Rules

| Visual Property  | Meaning                  | Example                           |
| ---------------- | ------------------------ | --------------------------------- |
| **Proximity**    | Relatedness              | Grouped boxes = same category     |
| **Lines/arrows** | Dependency or flow       | A → B means A feeds B             |
| **Containment**  | Scope or ownership       | Box inside box = part of whole    |
| **Position (Y)** | Hierarchy or time        | Top = abstract, bottom = concrete |
| **Position (X)** | Sequence or alternatives | Left-to-right = temporal flow     |
| **Size**         | Importance or volume     | Larger = more significant         |

### Diagram Types

| Type              | Best For                      | Structure              |
| ----------------- | ----------------------------- | ---------------------- |
| **Concept map**   | Showing how ideas relate      | Nodes + labeled edges  |
| **Flowchart**     | Decision logic, process steps | Boxes + branching      |
| **Sequence**      | Interactions over time        | Vertical timelines     |
| **Hierarchy**     | Classification, org structure | Tree                   |
| **State machine** | Lifecycle, transitions        | States + events        |
| **ER diagram**    | Data relationships            | Entities + connections |

### Rules of Thumb

- **7±2 nodes** per diagram — more and it needs splitting
- **One idea per diagram** — if the title needs "and", make two diagrams
- **Label everything** — unlabeled arrows are ambiguous
- **Direction = flow** — left-to-right for time, top-to-bottom for hierarchy
- **Don't decorate** — every visual element should encode information

See [Diagramming](../how/diagramming.md) for syntax and tool reference.

## Failure Modes

| Failure                     | Symptom                                     | Root Cause                         |
| --------------------------- | ------------------------------------------- | ---------------------------------- |
| **Premature jargon**        | Learner memorizes terms, can't apply them   | Labels before concepts             |
| **Flat curriculum**         | Everything taught at same depth and pace    | Missing taxonomy, no prerequisites |
| **Missing prerequisites**   | Learner stuck mid-lesson on assumed concept | Incomplete CTA                     |
| **Expert blind spots**      | "It's obvious" — but only to the expert     | No self-CTA performed              |
| **Wrong mental model**      | Learner confident but incorrect             | Didn't surface existing model      |
| **Wall of text**            | Concepts described but never visualized     | No visual communication            |
| **Taxonomy by familiarity** | Grouped by what expert learned first        | Expert bias, not logical structure |

## See Also

- [Information Architecture](information-architecture.md) — Structural IA for
  documents and codebases
- [Learning](learning.md) — Retention science (spaced repetition, active recall)
- [Thinking](thinking.md) — Mental models for reasoning and judgment
