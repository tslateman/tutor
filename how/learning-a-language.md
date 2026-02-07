# Learning a Programming Language

A practical workflow for learning any language, whether first or fifteenth.

## Quick Reference

| Phase        | Duration  | Focus                                  |
| ------------ | --------- | -------------------------------------- |
| Orientation  | Days 1-3  | Tooling, hello world, language tour    |
| Fundamentals | Weeks 1-2 | Syntax, types, control flow, functions |
| Competence   | Weeks 2-4 | Modules, idioms, small projects        |
| Fluency      | Week 4+   | Real projects, contribution, teaching  |

Experienced programmers learning a new language: compress to 1-2 weeks.

## Daily Routine

| Activity        | Time    | Purpose                          |
| --------------- | ------- | -------------------------------- |
| Anki review     | 10 min  | Retain syntax and idioms         |
| Lesson or docs  | 20 min  | Learn new concepts               |
| Coding practice | 30+ min | Apply through exercises/projects |

Consistency beats intensity. 30 minutes daily outperforms weekend marathons.

## Phase 1: Orientation

**Goal:** Run code and understand the ecosystem.

### Day 1: Environment

```bash
# Install the language and tooling
# Run the REPL or hello world
# Verify your editor has language support
```

### Days 2-3: Tour

- Read the official language tour or tutorial
- Note syntax that differs from languages you know
- Identify: How do I run code? Import modules? Print output?

### Capture to Flashcards

Create Anki cards as you learn. Use cloze deletions:

```text
# Card front
In Python, iterate over a list with indices using {{c1::enumerate()}}

# Card back
In Python, iterate over a list with indices using enumerate()
```

Keep cards atomic—one fact per card.

## Phase 2: Fundamentals

**Goal:** Write basic programs without constant reference.

### Core Concepts

Work through these in order:

1. **Syntax** — How code is structured (indentation, semicolons, braces)
2. **Types** — Primitives, collections, type system philosophy
3. **Control flow** — Conditionals, loops, pattern matching
4. **Functions** — Definition, arguments, return values
5. **Error handling** — Exceptions, Result types, or language equivalent

### Learning Pattern

For each concept:

1. **Read** — Official docs or lesson plan section
2. **Write** — Code examples from memory, not copy-paste
3. **Card** — Add syntax patterns to Anki
4. **Exercise** — Solve a small problem using the concept

### Interleave Topics

After the first few days, mix practice:

```text
# Bad: blocked practice
20 string problems, then 20 array problems

# Good: interleaved practice
String → Array → HashMap → String → Array
```

Interleaving feels harder but produces better retention.

## Phase 3: Competence

**Goal:** Build small projects and write idiomatic code.

### Exercism Track

Start the language track on [Exercism](https://exercism.org/tracks):

- Structured exercises with increasing difficulty
- Automated feedback on code style
- Optional mentorship from experienced developers
- Study other solutions after submitting

### Small Projects

Build something real:

| Project Type    | Examples                                      |
| --------------- | --------------------------------------------- |
| CLI tool        | Todo list, file organizer, markdown converter |
| Data processing | CSV parser, log analyzer, API client          |
| Web app         | Simple CRUD, personal dashboard               |

Choose projects that solve a problem you have.

### Read Idiomatic Code

Study well-written code in the language:

- Standard library source
- Popular open-source projects
- Style guides (official or community)

Note patterns that differ from your expectations.

## Phase 4: Fluency

**Goal:** Think in the language, not translate from another.

### Signs of Fluency

- Write code without syntax reference
- Read unfamiliar code and understand intent
- Debug errors without searching every message
- Recognize when code is idiomatic vs. awkward

### Build a Real Project

Choose something with actual users or stakes:

- Contribute to an open-source project
- Build a tool for your job
- Create something you'll maintain for months

Real constraints force deeper learning.

### Teach

The Feynman Technique applied:

- Write a blog post explaining a concept
- Answer questions on forums or Discord
- Create your own cheatsheet or lesson
- Mentor someone earlier in their journey

Teaching reveals gaps you didn't know existed.

## Techniques Applied

From [Learning](../why/learning.md):

| Technique           | Application                                    |
| ------------------- | ---------------------------------------------- |
| Active Recall       | Write code without docs, then check            |
| Spaced Repetition   | Daily Anki review for syntax and idioms        |
| Interleaving        | Mix problem types in practice sessions         |
| Generation          | Write code before looking at solutions         |
| Feynman Technique   | Explain concepts in your own words             |
| Deliberate Practice | Exercism with feedback, projects at skill edge |

## Anti-Patterns

### Tutorial Hell

```text
# Bad: passive consumption
Watch 10 hours of tutorials → feel productive → can't code

# Good: active building
Watch 20 minutes → code for 40 minutes → repeat
```

### Language Hopping

Stick with one language for 3-4 months minimum. Switching before competence
means restarting the frustration phase repeatedly.

### Copy-Paste Learning

Typing code that you copy trains muscle memory, not understanding. Write from
memory, check against reference, correct mistakes.

### Skipping Errors

```text
# Bad: avoid errors
Skip exercises that cause confusion

# Good: embrace errors
Errors reveal gaps—investigate, don't avoid
```

## Tools

### Spaced Repetition

- [Anki](https://apps.ankiweb.net/) — Free, customizable, cross-platform
- Use `font-family: monospace` in card CSS for code
- One concept per card, cloze deletion for syntax

### Practice Platforms

| Platform                                   | Strength                       |
| ------------------------------------------ | ------------------------------ |
| [Exercism](https://exercism.org)           | Mentorship, idiomatic feedback |
| [LeetCode](https://leetcode.com)           | Algorithms, interview prep     |
| [Advent of Code](https://adventofcode.com) | Puzzles, community             |

### Documentation

- Official language docs (authoritative)
- [roadmap.sh](https://roadmap.sh) — Learning paths with context
- Language-specific cheatsheets in this repo

## Learning in Public

Document your journey to accelerate learning:

- **TIL posts** — Short notes on daily discoveries
- **Blog posts** — Longer explanations of concepts
- **Progress threads** — Twitter/Mastodon updates
- **Code sharing** — GitHub repos, gists

Share progress, not perfection. Vulnerability invites feedback and mentorship.

## See Also

- [Learning](../why/learning.md) — Evidence-based retention techniques
- [Problem Solving](../why/problem-solving.md) — Approaching coding challenges
- [Debugging](../why/debugging.md) — Systematic error investigation
- Language lesson plans in [learn/](../learn/) — Structured curricula
