# Technical Writing Lesson Plan

A progressive curriculum based on Google's Technical Writing courses.

Reference: [Technical Writing 101](https://lisafc.github.io/tw101-reading/)

## Lesson 1: Words

**Goal:** Choose precise terminology and eliminate ambiguity.

### Concepts

Good technical writing uses words consistently and precisely:

- Define new terms before using them
- Use terms consistently (don't switch between synonyms)
- Expand acronyms on first use
- Resolve ambiguous pronouns

### Exercises

1. **Define before use**

   Rewrite to define the term:

   > The microservice handles authentication.

   Better:

   > A microservice is a small, independent service that performs one function.
   > The authentication microservice validates user credentials.

2. **Fix inconsistent terminology**

   Find the problem:

   > The function returns the result. The method outputs the value. This
   > procedure yields the answer.

   Pick one term and stick with it.

3. **Expand acronyms**

   First use:

   > The Content Delivery Network (CDN) caches static assets. Subsequent
   > requests hit the CDN instead of your origin server.

4. **Resolve pronouns**

   Ambiguous:

   > Python stores variables in memory. It allocates space automatically.

   What does "it" refer to? Python? Memory? Rewrite:

   > Python stores variables in memory. The interpreter allocates space
   > automatically.

### Checkpoint

Review a paragraph you've written. Circle every pronoun. Can each one be
replaced with its referent without confusion?

---

## Lesson 2: Active Voice

**Goal:** Write direct sentences where the actor performs the action.

### Concepts

| Voice   | Structure             | Example                              |
| ------- | --------------------- | ------------------------------------ |
| Active  | Actor → verb → target | The server logs the request.         |
| Passive | Target → verb → actor | The request is logged by the server. |

Active voice is clearer, shorter, and specifies who does what.

### Exercises

1. **Identify voice**

   Which is passive?
   - a) "The configuration file specifies the port."
   - b) "The port is specified in the configuration file."
   - c) "You specify the port in the configuration file."

2. **Convert passive to active**

   > The tests are run by the CI system after each commit.

   Rewrite:

   > The CI system runs tests after each commit.

3. **Find the hidden actor**

   Passive sentences often hide who does the action:

   > The database should be backed up regularly.

   By whom? Make it explicit:

   > The operations team backs up the database daily.

4. **When passive is acceptable**

   Use passive when the actor is unknown or irrelevant:

   > The bug was reported in 2019. (Who reported it doesn't matter.)

   Or to emphasize the target:

   > The data is encrypted at rest. (Focus is on the data, not who encrypts.)

### Checkpoint

Scan your last commit message or PR description. Convert any passive sentences
to active.

---

## Lesson 3: Clear Sentences

**Goal:** Use strong verbs and concrete language.

### Concepts

Weak writing uses vague verbs and abstract nouns. Strong writing uses specific
verbs that convey precise meaning.

### Exercises

1. **Replace weak verbs**

   | Weak                       | Strong                       |
   | -------------------------- | ---------------------------- |
   | The error occurs when...   | The parser throws when...    |
   | This is a function that... | This function parses...      |
   | There are many options...  | The API offers five options. |

2. **Eliminate "there is/there are"**

   Weak:

   > There are three ways to configure logging.

   Strong:

   > You can configure logging three ways.

3. **Be specific**

   Vague:

   > The system processes data quickly.

   Specific:

   > The pipeline processes 10,000 records per second.

4. **Add examples**

   Abstract:

   > Escape special characters in the query.

   Concrete:

   > Escape special characters in the query. For example, write `\'` for a
   > literal single quote.

### Checkpoint

Find a sentence you wrote with "is" or "are" as the main verb. Rewrite with a
stronger verb.

---

## Lesson 4: Short Sentences

**Goal:** Write sentences that convey one idea each.

### Concepts

Long sentences overload readers. Each sentence should make one point. If you use
"and" more than once, consider splitting.

### Exercises

1. **Split compound sentences**

   Too long:

   > The server validates the request and checks the user's permissions and
   > queries the database and returns the result.

   Split:

   > The server validates the request. It checks the user's permissions. Then it
   > queries the database and returns the result.

2. **Reduce clause chains**

   Nested:

   > The function, which was written by the previous team and which handles edge
   > cases that occur when users submit empty forms, throws an exception.

   Untangled:

   > This function handles empty form submissions. The previous team wrote it.
   > It throws an exception for edge cases.

3. **Cut filler words**

   | Remove            | Keep           |
   | ----------------- | -------------- |
   | in order to       | to             |
   | at this point     | now            |
   | due to the fact   | because        |
   | a number of       | several / many |
   | in the event that | if             |

4. **Target sentence length**

   Aim for 15-25 words. Vary length for rhythm, but break up anything over 30
   words.

### Checkpoint

Find your longest sentence in recent writing. Split it into 2-3 shorter
sentences.

---

## Lesson 5: Lists and Tables

**Goal:** Structure information for scanning.

### Concepts

Lists and tables let readers find information quickly. Use them when you have:

- Three or more related items
- Steps in a procedure
- Parallel information to compare

### Exercises

1. **Convert prose to list**

   Prose:

   > To deploy, you need to run the build, then run the tests, then push to the
   > registry, then update the manifest.

   List:

   > To deploy:
   >
   > 1. Run the build.
   > 2. Run the tests.
   > 3. Push to the registry.
   > 4. Update the manifest.

2. **Maintain parallel structure**

   Inconsistent:

   > - Configure the database
   > - The cache should be cleared
   > - Restarting the server

   Parallel (imperative verbs):

   > - Configure the database.
   > - Clear the cache.
   > - Restart the server.

3. **Choose list type**

   | Type     | Use when                       |
   | -------- | ------------------------------ |
   | Bulleted | Order doesn't matter           |
   | Numbered | Sequence matters (steps)       |
   | Table    | Comparing items across columns |

4. **Introduce lists**

   Add context before a list:

   > The API accepts three authentication methods:
   >
   > - API key
   > - OAuth token
   > - Basic auth

### Checkpoint

Convert a paragraph with embedded items into a bulleted or numbered list.

---

## Lesson 6: Paragraphs

**Goal:** Structure paragraphs for clarity.

### Concepts

A paragraph is a unit of thought. Start with the main point. Support it. Move
on.

### Exercises

1. **Lead with the point**

   Buried lead:

   > Our team evaluated several options. We considered Redis, Memcached, and a
   > custom solution. After testing, we found Redis best fits our needs. Redis
   > supports our data structures.

   Lead first:

   > We chose Redis for caching. It supports our data structures and
   > outperformed Memcached in our tests. We also considered a custom solution
   > but rejected it for maintenance reasons.

2. **Answer three questions**

   For each paragraph, answer:
   - **What** is this about?
   - **Why** does it matter?
   - **How** does it work?

3. **One topic per paragraph**

   Split if a paragraph covers multiple ideas. Each paragraph should be
   summarizable in one sentence.

4. **Use transitions**

   Connect paragraphs with signals:
   - Continuation: "Additionally," "Furthermore,"
   - Contrast: "However," "In contrast,"
   - Consequence: "Therefore," "As a result,"

### Checkpoint

Read a paragraph you wrote. Can you summarize it in one sentence? If not, split
it.

---

## Lesson 7: Audience

**Goal:** Write for your readers' knowledge level.

### Concepts

The curse of knowledge: experts forget what novices don't know. Define your
audience explicitly.

### Exercises

1. **Define your audience**

   Before writing, answer:
   - What role does the reader have? (Developer? Operator? Manager?)
   - What do they already know?
   - What do they need to accomplish?

2. **Identify assumed knowledge**

   Review this sentence:

   > Use gRPC for service-to-service communication.

   Assumes reader knows:
   - What gRPC is
   - What service-to-service means
   - Why you'd choose it over alternatives

   For beginners, expand. For experts, proceed.

3. **Layer your documentation**

   Structure for mixed audiences:
   - Quick start (beginner)
   - API reference (intermediate)
   - Architecture guide (expert)

4. **Test with a real reader**

   Ask someone from your target audience to read your doc. Note where they get
   confused.

### Checkpoint

Pick a technical term in your writing. Would your target audience know it? Add a
definition or link if not.

---

## Lesson 8: Documents

**Goal:** Structure complete documents effectively.

### Concepts

Documents need structure beyond paragraphs:

- State the purpose upfront
- Organize for your reader's task
- Use headings as signposts

### Exercises

1. **Write a strong opening**

   Weak:

   > This document describes the caching layer.

   Strong:

   > This guide explains how to configure Redis caching for your application.
   > After reading, you'll be able to set up caching, tune performance, and
   > troubleshoot common issues.

2. **Organize by task, not structure**

   Don't:

   > 1. Overview
   > 2. Components
   > 3. Configuration
   > 4. API

   Do:

   > 1. Quick Start
   > 2. Configure Caching
   > 3. Monitor Performance
   > 4. Troubleshoot Errors

3. **Front-load information**

   Put the most important content first. Most readers won't finish.

4. **Use scannable headings**

   Vague:

   > ## Details

   Specific:

   > ## Configure Connection Pooling

### Checkpoint

Outline a document you need to write. Start each heading with a verb or answer a
question the reader has.

---

## Practice Projects

### Project 1: README Rewrite

Take a project README and rewrite it applying these principles:

- Lead with what the project does
- Add a quick start section
- Convert setup steps to a numbered list
- Define jargon

### Project 2: Explain a Concept

Write a 500-word explanation of a technical concept for beginners:

- Define terms before using them
- Use active voice throughout
- Include a concrete example
- End with "next steps"

### Project 3: Procedure Documentation

Document a multi-step procedure:

- Write numbered steps
- Use imperative mood ("Click," not "You should click")
- Add troubleshooting for common errors
- Test with someone unfamiliar with the process

---

## Quick Reference

| Principle          | Technique                                        |
| ------------------ | ------------------------------------------------ |
| Precision          | Define terms; resolve pronouns; be consistent    |
| Clarity            | Use active voice; choose strong verbs            |
| Brevity            | One idea per sentence; cut filler words          |
| Scannability       | Use lists and tables; write descriptive headings |
| Structure          | Lead with the point; organize by task            |
| Audience-awareness | Define audience; explain assumed knowledge       |

## See Also

- [Learning](../why/learning.md) — How to retain what you learn
- [Thinking](../why/thinking.md) — Clear thinking enables clear writing
- [AI CLI](../how/ai-cli.md) — Apply these principles to AI prompts
