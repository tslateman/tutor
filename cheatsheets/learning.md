# Learning

Evidence-based techniques for retaining knowledge. Research over intuition.

## Quick Reference

| Technique         | Impact | Core Idea                                |
| ----------------- | ------ | ---------------------------------------- |
| Active Recall     | High   | Test yourself instead of re-reading      |
| Spaced Repetition | High   | Review at expanding intervals            |
| Interleaving      | Medium | Mix related topics, don't block          |
| Elaboration       | Medium | Ask why, connect to existing knowledge   |
| Generation        | Medium | Produce answers, don't just consume them |
| Feynman Technique | High   | Explain simply to expose gaps            |
| Dual Coding       | Medium | Combine words and visuals                |
| Chunking          | Medium | Group into meaningful units              |

## Active Recall

Retrieve information from memory instead of passively reviewing.

**Practice**:

- Close the book, write what you remember
- Flashcards: see question, produce answer from memory
- Practice tests beat re-reading notes
- Explain concepts without looking at source

**Why it works**: Retrieval strengthens memory traces. Each successful recall
creates new access paths. Even failed attempts improve later retention.

**Research**: Repeated retrieval produces 400% improvement vs. studying once.
(Karpicke & Roediger)

## Spaced Repetition

Review material at increasing intervals: 1 day, 3 days, 1 week, 2 weeks, 1
month.

**Practice**:

- Use SRS software to automate scheduling
- Without software: review next day, then 3d, 7d, 14d, 30d
- Let yourself almost forget before reviewing
- Harder to recall = stronger memory formed

**Why it works**: Each retrieval at the edge of forgetting strengthens the
memory. Massed practice (cramming) produces short-term gains, long-term losses.

**The forgetting curve**: Without review, we lose ~40% in days, ~90% within a
month. Spaced review flattens this curve.

**Tools**: Anki, RemNote, Mochi, Obsidian + Spaced Repetition plugin

## Interleaving

Mix related topics (ABCABC) instead of blocking (AAABBBCCC).

**Practice**:

- Alternate between problem types during practice
- Switch subjects within study sessions
- Create mixed practice sets for review
- Don't do 20 of the same problem in a row

**Why it works**: Forces discrimination between similar concepts. Blocking lets
you pattern-match without true understanding.

**The catch**: Interleaving feels harder and less productive. This is a feature.
The difficulty improves long-term retention.

**When to block**: Start with blocked practice for brand-new material.
Interleave once you have the basics.

**Research**: 30-40% improvement on delayed tests vs. blocking.

## Elaboration

Ask "why" and "how" questions to connect new material to existing knowledge.

**Practice**:

- After learning a fact: "Why is this true?"
- "How does this relate to what I already know?"
- Generate your own examples
- Explain the steps in a procedure, not just the steps

**Why it works**: Creates semantic links to prior knowledge. More connections =
more retrieval paths = better recall.

**Limitation**: Requires background knowledge to elaborate from. Works best when
you have prior knowledge to connect to.

## Generation Effect

Producing information beats passively receiving it.

**Practice**:

- Fill-in-the-blank exercises (cloze deletion)
- Predict the answer before revealing it
- Create your own practice questions
- Write code before looking at the solution

**Why it works**: Generation activates deeper encoding—semantic elaboration,
distinctive processing, effortful retrieval.

**Counterintuitive**: Wrong answers, when corrected, can strengthen memory more
than reading the right answer directly. Struggle is productive.

## Feynman Technique

Explain concepts simply to expose gaps in understanding.

**Steps**:

1. **Choose** a concept you want to understand
2. **Explain** it in plain language, as if teaching a child
3. **Identify gaps** where you stumble, get vague, or resort to jargon
4. **Simplify** and return to source material for weak spots
5. **Repeat** until the explanation flows

**Why it works**: Combines active recall, generation, and self-explanation.
Reveals illusions of competence—you can't hide behind jargon.

**Use for**: Complex topics, interview prep, testing whether you actually
understand something or just recognize it.

## Dual Coding

Combine verbal and visual representations.

**Practice**:

- Sketch diagrams while reading
- Add images to flashcards
- Create mind maps from memory
- Draw system architectures, don't just describe them

**Why it works**: Verbal and visual memory are separate channels. Encoding in
both creates two independent retrieval paths.

**Caution**: Poorly designed visuals increase cognitive load. Simple >
elaborate. The visual should clarify, not decorate.

## Chunking

Group information into meaningful units to work within memory limits.

**Practice**:

- Phone numbers: 973-820-5846 not 9738205846
- Acronyms: ACID for database transactions
- Patterns: See `git rebase -i` as one concept, not four tokens
- Build chunks from smaller chunks (hierarchy)

**Why it works**: Working memory holds ~4-7 items. A chunk counts as one item
regardless of internal complexity. Experts chunk more aggressively.

**In practice**: When learning a new domain, consciously look for patterns that
can become single units. Name them.

## Supporting Factors

### Sleep

Sleep consolidates memory, particularly slow-wave sleep.

- Post-learning sleep stabilizes and enhances memories
- Sleep before learning prepares encoding capacity
- Naps help; all-nighters actively hurt retention
- Fatigue sabotages retention

### Deliberate Practice

Not just repetition—structured practice targeting weaknesses.

- Focus on skills slightly beyond current ability
- Get immediate feedback
- High concentration, not autopilot
- Quality matters more than hours logged

The "10,000 hour rule" oversimplifies. Deliberate practice explains ~26% of
performance variance—significant but not everything.

### Metacognition

Thinking about your thinking.

- **Plan**: What do I know? What's my approach?
- **Monitor**: Is this working? Am I actually learning or just busy?
- **Evaluate**: What did I miss? What should I adjust?

The ability to accurately assess your own understanding is a skill. Develop it.

## What Doesn't Work

| Technique              | Problem                                                                    |
| ---------------------- | -------------------------------------------------------------------------- |
| Re-reading             | Feels productive, builds familiarity not recall                            |
| Highlighting           | Passive; no retrieval or elaboration                                       |
| Learning styles (VAK)  | No evidence that matching "style" helps; everyone benefits from multimodal |
| Cramming               | Works for tomorrow's test, gone next week                                  |
| Blocked practice only  | Feels smoother, transfers worse                                            |
| Passive video watching | Understanding is not retention                                             |

The techniques that feel easiest often work worst. Fluent reading creates an
illusion of learning. Test yourself to know what you actually know.

## Building a System

Minimum viable learning workflow:

1. **Capture**: Take notes in your own words (generation, not transcription)
2. **Process**: Convert notes to questions or flashcards (forces active framing)
3. **Review**: Follow a spaced repetition schedule
4. **Test**: Practice problems, teach-backs, self-quizzes
5. **Sleep**: Non-negotiable

The system matters less than consistency. Pick tools you'll actually use.

## Tools

> Landscape shifts fast. See
> [awesome-fsrs](https://github.com/open-spaced-repetition/awesome-fsrs) and
> [awesome-knowledge-management](https://github.com/brettkromkamp/awesome-knowledge-management)
> for current options.

| Purpose            | Examples                                   |
| ------------------ | ------------------------------------------ |
| Spaced repetition  | Anki, RemNote, Mochi                       |
| Connected notes    | Obsidian, Logseq, Roam                     |
| Flashcard creation | Anki (with cloze), Mochi, RemNote          |
| Coding practice    | Exercism, LeetCode, project-based learning |
| Reading retention  | Readwise (syncs highlights to SRS)         |

## Sources

- Dunlosky et al. (2013). "Improving Students' Learning With Effective Learning
  Techniques." Psychological Science in the Public Interest.
- Karpicke & Roediger (2008). "The Critical Importance of Retrieval for
  Learning."
- Bjork & Bjork. "Desirable Difficulties" research, UCLA Learning and Forgetting
  Lab.
- Ebbinghaus (1885). "Memory: A Contribution to Experimental Psychology."
  (Forgetting curve)
- Roediger & Butler (2011). "The Critical Role of Retrieval Practice in
  Long-Term Retention."
