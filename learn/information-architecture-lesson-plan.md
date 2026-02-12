# Information Architecture Lesson Plan

How to organize project documentation so people find what they need -- the four
systems of IA applied to repos, docs directories, and README files.

Reference: Rosenfeld, Morville & Arango, _Information Architecture_ (4th ed.)
and the [Diataxis framework](https://diataxis.fr/).

## Lesson 1: What Is Information Architecture

**Goal:** Learn the four systems that govern findability in a codebase.

### Concepts

"I can't find anything in these docs" is an IA problem, not a writing problem.
Every information space has four structural systems:

| System       | Governs                           | Repo example                     |
| ------------ | --------------------------------- | -------------------------------- |
| Organization | How content is grouped            | docs/ split by topic vs audience |
| Labeling     | What things are called            | "Setup" vs "Installation"        |
| Navigation   | How people move through the space | README links, table of contents  |
| Search       | How people find without browsing  | File names, headings, grep terms |

IA sits at the intersection of **context** (project goals), **content** (what
exists), and **users** (who needs what). Neglect any one and the architecture
fails.

### Exercises

1. **Inventory a project** -- Pick a repo you use. List every doc artifact
   (README, CONTRIBUTING, docs/ files, wiki). Note which system each serves and
   whether a new contributor would find it.

2. **Identify the four systems** -- Open any `docs/` directory. What groups the
   files? Can you predict content from names? Do files link to each other?

3. **Spot the failure** -- Find a repo where you struggled to locate something.
   Which system failed: organization, labeling, navigation, or search?

4. **Map user journeys** -- Write three questions a new contributor would ask.
   Trace each from README to answer. Count the steps.

### Checkpoint

Score a project you maintain on each of the four systems (1-5). Identify the
weakest system.

---

## Lesson 2: Organization Systems

**Goal:** Choose grouping schemes and build hierarchies that scale.

### Concepts

**Exact schemes** are unambiguous: alphabetical, chronological, geographic.
**Ambiguous schemes** require judgment: by topic, by task, by audience. Exact
schemes serve lookup; ambiguous schemes serve browsing.

The rule: one primary scheme per level. Mixing topic folders with audience
folders with file-type folders at the same level confuses navigation.

Hierarchy design: prefer broader over deeper. Mutually exclusive categories
reduce "where does this go?" friction. Consistent granularity at each level.

### Exercises

1. **Diagnose a mixed scheme** -- Find a flat `docs/` with 10+ files. Classify
   each file's implicit scheme. If the answer is "a mix," that's the bug.

2. **Redesign with one scheme** -- Reorganize the same directory by task, then
   by audience. Which fits better?

3. **Build a two-level hierarchy** -- Design 3-5 top-level categories with 3-7
   files each. Every file should have one obvious parent.

4. **Test mutual exclusivity** -- Pick three docs. Could any live in two
   categories? Tighten the scheme until each has one home.

5. **Build a taxonomy from scratch** -- Take 20 programming concepts (e.g.,
   variable, function, closure, class, interface, trait, generic, enum, struct,
   module, package, import, scope, lifetime, ownership, reference, pointer,
   iterator, stream, future). Sort them into a teachable hierarchy with
   prerequisite edges. Draw the tree. Compare your grouping with a peer's.

### Checkpoint

Reorganize a real `docs/` directory into a two-level hierarchy. Write the tree
and explain your scheme choice.

---

## Lesson 3: Labeling

**Goal:** Name files, directories, and headings so readers predict content
without opening them.

### Concepts

Labels are what users scan. Five principles:

- **Describe content, not container.** "Authentication" not "Section 3."
- **Narrow scope.** "Resources" is too broad to help anyone navigate.
- **Match user vocabulary.** If they search "login," don't label it
  "authentication."
- **Consistent granularity.** Don't mix concepts and tasks at the same level.
- **Controlled vocabulary.** One term per concept, everywhere. "Installation" in
  the doc, "setup" in the README, "bootstrapping" in CI = three labels for one
  thing.

### Exercises

1. **Audit file names** -- For each file in a `docs/` directory, answer: can I
   predict the content from the name? Flag `notes.md`, `misc.md`, `docs.md`.

2. **Rename for findability** -- Rewrite `doc-7.md`, `notes.md`, `misc.md` as
   2-4 word kebab-case names that match grep targets.

3. **Fix heading labels** -- Rewrite "Overview", "Details", "More Information",
   and "Notes" to describe actual content.

4. **Build a controlled vocabulary** -- List five key concepts in a project. For
   each, find every synonym in docs, code, and commits. Pick one canonical term.

5. **Semantic labeling progression** -- Take a project glossary of 10+ terms.
   Reorder the definitions so each term is introduced only after its
   prerequisites. Flag terms that reference concepts not yet defined — those are
   dependency violations. Rewrite the glossary in dependency order.

### Checkpoint

Rename every file in a real `docs/` directory so `ls docs/` reads like a table
of contents.

---

## Lesson 4: Navigation

**Goal:** Design navigation that answers "where am I?" and "where can I go?" at
every level.

### Concepts

Three kinds of embedded navigation:

- **Global** -- always visible, orients the reader. In a repo: the README.
- **Local** -- within a section: prev/next, sibling links, "See Also."
- **Contextual** -- inline links to related content.

The depth rule: any content reachable in three clicks from the entry point. If
deeper, flatten or promote. Progressive disclosure: show immediate choices,
reveal detail on demand.

### Exercises

1. **Trace navigation paths** -- Follow every link from a README through to leaf
   docs. Draw the tree. Note dead ends and orphans.

2. **Find orphan pages** -- Check whether every file in `docs/` has at least one
   inbound link. Fix orphans by linking from their natural parent.

3. **Add "See Also" blocks** -- Pick three related docs. Add cross-links at the
   bottom of each.

4. **Flatten a deep hierarchy** -- Find a docs structure 3+ levels deep.
   Restructure to two levels by merging or promoting content.

### Checkpoint

Map every navigation path in a project. Fix orphans, dead ends, and anything
deeper than three levels.

---

## Lesson 5: Search and Findability

**Goal:** Make docs findable through naming, headings, metadata, and
cross-references.

### Concepts

In software projects, "search" means `grep`, `git grep`, GitHub search, or
scanning a tree listing.

- **File names are search terms.** `authentication.md` is findable; `doc-7.md`
  is not.
- **Headings are search results.** A grep for "rate limiting" should land on a
  heading, not buried in paragraph four.
- **Synonyms need bridges.** Cross-reference "auth" / "login" / "sign-in."
- **Metadata enables filtering.** Frontmatter (title, tags, audience) supports
  programmatic discovery.

### Exercises

1. **Grep test** -- Write five questions a user would ask. Grep for the obvious
   keyword. Does each search land on the right file and heading?

2. **Blind name audit** -- Run `ls docs/`. Write a summary of each file from its
   name alone. Open each. Mismatches are findability failures.

3. **Add frontmatter** -- Add `title`, `audience`, and `tags` to five docs.
   Verify `grep -rl "audience: developer" docs/` works as expected.

4. **Synonym cross-reference** -- Find three concepts with multiple names. Add
   "Also known as" lines and redirect notes.

### Checkpoint

For ten common user questions, grep the docs. Record hit or miss. Fix misses by
renaming, rewriting headings, or adding cross-references.

---

## Lesson 6: The Diataxis Framework

**Goal:** Classify docs by mode and stop mixing tutorials with references.

### Concepts

| Mode        | Orientation   | Purpose                  | Form           |
| ----------- | ------------- | ------------------------ | -------------- |
| Tutorial    | Learning      | Teach through doing      | Lesson         |
| How-to      | Task          | Solve a specific problem | Recipe         |
| Explanation | Understanding | Clarify concepts         | Discussion     |
| Reference   | Information   | Describe the machinery   | Austere, exact |

Each page serves one mode. Mixing tutorial prose into a reference degrades both.
When a page feels unfocused, it conflates two modes.

### Exercises

1. **Classify existing docs** -- For each file in a project, assign a Diataxis
   mode. If a file spans two, note the split point.

2. **Diagnose a bloated README** -- Tag each section of a 200+ line README by
   mode. Propose extraction: tutorial -> `docs/tutorial.md`, how-to ->
   `docs/setup.md`, explanation -> `docs/architecture.md`, reference ->
   `docs/reference.md`. README becomes a signpost.

3. **Write four versions** -- Pick one feature. Write it as a tutorial, how-to,
   explanation, and reference. Notice how voice and assumed knowledge differ.

4. **Audit for mode mixing** -- Read a doc paragraph by paragraph. Tag each with
   its mode. If the mode changes more than twice, the doc needs splitting.

### Checkpoint

Classify every doc in a project by mode. Split at least one mixed doc into two
files.

---

## Lesson 7: Content Modeling and Auditing

**Goal:** Model content types, audit for gaps, and design for growth.

### Concepts

Before designing structure, model the content:

- **Types** -- tutorials, ADRs, runbooks, API references, changelogs
- **Attributes** -- author, date, status, audience, related components
- **Relationships** -- a tutorial references an API doc; an ADR supersedes
  another ADR

Audit checklist: **gaps** (unanswered questions), **duplicates** (which copy is
current?), **orphans** (no path leads here), **staleness** (describes old
version).

### Exercises

1. **Model content types** -- List every type in a project, its attributes, and
   relationships in a table.

2. **Content audit** -- Inventory every doc: path, Diataxis mode, last update
   (`git log`), inbound link count, accuracy. Flag orphans and stale docs.

3. **Gap analysis** -- Write ten questions a new contributor would ask. Check
   whether docs answer each. Unanswered = gap.

4. **Design for growth** -- Design a structure for 8 docs that handles 30
   without reorganization. Show where three future docs would land.

5. **Decompose an expert skill** -- Pick a skill you're good at (debugging, code
   review, Git rebasing). Perform a self-CTA: solve a problem slowly, narrate
   every decision and check. Write the steps as a lesson sequence with
   prerequisites. Ask a less experienced peer to follow it — where they get
   stuck reveals steps you skipped.

### Checkpoint

Run a full content audit: inventory, classify, check staleness, find orphans,
identify gaps. Produce a one-page report.

---

## Lesson 8: Capstone -- Audit and Restructure

**Goal:** Apply Lessons 1-7 to audit and restructure a real project's docs
end-to-end.

### Concepts

Inventory, evaluate the four systems, classify by mode, model content types,
find gaps, then propose a new structure. If you cannot explain why a file lives
where it does, move it.

### Exercises

1. **Choose a project** -- Pick one with a README and 5+ doc files. The messier,
   the better.

2. **Four-systems evaluation** -- Score each system 1-5 with evidence:
   organization (consistent scheme?), labeling (predictable names?), navigation
   (three-click reach? orphans?), search (grep-friendly?).

3. **Propose a new structure** -- Write the complete file tree. Annotate each
   level's scheme, each file's Diataxis mode, and required navigation links.

4. **Implement** -- Execute on a branch. Update all links. Verify every doc has
   an inbound link and nothing is deeper than two levels from root.

### Checkpoint

Submit before-and-after trees, the four-systems scorecard, and a summary of
every structural decision.

---

## Practice Projects

### Project 1: README Triage

Extract a 300+ line README into a docs structure. The README shrinks to under 80
lines (description, quick start, links). Each section becomes its own file.

### Project 2: Docs Directory Redesign

Find a flat `docs/` (15+ files). Write an IA review, propose a two-level
hierarchy, restructure on a branch, and open a PR.

### Project 3: Content Model and Gap Analysis

Build a content model for a project you maintain. Audit for staleness, orphans,
and gaps. Write the three most critical missing docs.

---

## Quick Reference

| Principle     | Technique                                                        |
| ------------- | ---------------------------------------------------------------- |
| Organization  | One scheme per level; mutual exclusivity; balance breadth/depth  |
| Labeling      | Describe content not container; match user vocabulary; be narrow |
| Navigation    | Three-click reach; no orphans; global + local + contextual links |
| Search        | Grep-friendly names; headings match queries; synonym bridges     |
| Diataxis      | One mode per page; split mixed docs; README as signpost          |
| Content model | Types, attributes, relationships; audit before designing         |
| Auditing      | Gaps, orphans, staleness, duplication; score each system 1-5     |

## See Also

- [Technical Writing](technical-writing-lesson-plan.md) -- Clear writing makes
  content findable
- [System Design](system-design-lesson-plan.md) -- IA is structural design for
  information
