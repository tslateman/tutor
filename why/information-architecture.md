# Information Architecture

How to structure shared information so people find what they need without
asking.

## What It Is

Information architecture is the structural design of shared information
environments. It sits at the intersection of three concerns: **context**
(business goals, constraints, culture), **content** (document types, volume,
ownership), and **users** (tasks, seeking behavior, vocabulary). Neglect any one
and the structure fails. A codebase organized by team ownership ignores how
developers seek information. Documentation organized by user preference ignores
content governance. IA answers the question that every project eventually asks:
"Where does this go?"

## The Four Systems

Every information space has four structural systems. Evaluate each when
designing or reviewing.

### Organization

How content is grouped and classified.

| Scheme Type   | Examples                             | Strength              | Weakness                    |
| ------------- | ------------------------------------ | --------------------- | --------------------------- |
| **Exact**     | Alphabetical, chronological, by type | Unambiguous, sortable | Useless for exploration     |
| **Ambiguous** | By topic, by task, by audience       | Supports browsing     | Requires judgment to design |

**Exact schemes** work for known-item lookup: API references sorted
alphabetically, changelogs sorted by date, error code indexes.

**Ambiguous schemes** work for exploration: a `docs/` directory grouped by
topic, a tutorial section organized by task, an ops runbook divided by audience.

**Rule:** One primary scheme per directory level. Mixing schemes at the same
level ("is `auth.md` here because of its topic or its audience?") forces every
reader to guess.

### Taxonomy Construction

Taxonomy is the engine inside organization — the act of building the grouping
scheme itself. A directory structure is a taxonomy — and so is a lesson plan.

1. **List everything** — dump every concept, file, or doc artifact
2. **Group by affinity** — what belongs together? Name the groups
3. **Test mutual exclusivity** — can any item live in two groups? Tighten until
   each has one home
4. **Check depth** — more than three levels signals over-splitting
5. **Card sort test** — give an outsider the items on cards. Where do they put
   each one? Disagreement reveals ambiguous categories

**When taxonomy fails:** items are hard to place, file names don't predict
content, and newcomers ask "where does this go?" repeatedly. The fix is always
the same — revisit the grouping scheme, not the individual placements.

See [Knowledge Design](knowledge-design.md) for taxonomy as a pedagogical skill.

### Labeling

What things are called. Labels are the first thing a reader scans.

- **Describe the content, not the container** -- `authentication.md` not
  `section-3.md`
- **Match user vocabulary** -- if developers grep for "retry", don't label it
  "resilience-patterns"
- **Consistent granularity** -- don't mix concepts (`architecture.md`) and tasks
  (`how-to-deploy.md`) at the same directory level
- **Scope narrows with depth** -- top-level labels are broad categories,
  leaf-level labels are specific nouns

```text
Bad:   docs/misc/  docs/stuff/  docs/other/
Good:  docs/guides/  docs/reference/  docs/decisions/
```

### Navigation

How people move through the space.

| Type             | Function                        | Codebase example                         |
| ---------------- | ------------------------------- | ---------------------------------------- |
| **Global**       | Orients the reader at any point | README with table of contents            |
| **Local**        | Moves within a section          | "See Also" links, prev/next in tutorials |
| **Contextual**   | Inline links from content       | Hyperlinks within ADRs to related ADRs   |
| **Supplemental** | Cross-cuts the hierarchy        | Tag indexes, generated API docs, search  |

**Depth rule:** Three clicks (or three directory levels) to any content. If
deeper, the hierarchy needs flattening or the content needs promoting.

### Search

How people find things without browsing.

In a codebase, "search" means grep, `Cmd+P`, and file-tree scanning:

- **File names are search terms** -- `signal-contract.md` is findable;
  `doc-7.md` is not
- **Headings are grep targets** -- a search for "authentication" should land on
  a heading, not buried mid-paragraph
- **Synonyms need bridges** -- if the concept has multiple names,
  cross-reference them (aliases in frontmatter, redirect files, "See Also")
- **Consistent metadata** -- frontmatter tags, directory-level READMEs, and
  naming conventions enable programmatic discovery

## Diataxis Framework

When the content is documentation, classify each page into exactly one mode.

| Mode            | Orientation   | Purpose                  | Form              | Example                       |
| --------------- | ------------- | ------------------------ | ----------------- | ----------------------------- |
| **Tutorial**    | Learning      | Teach through doing      | Lesson with steps | "Build your first plugin"     |
| **How-to**      | Task          | Solve a specific problem | Recipe            | "How to configure TLS"        |
| **Explanation** | Understanding | Clarify why and how      | Discussion        | "Why we chose event sourcing" |
| **Reference**   | Information   | Describe the machinery   | Austere, exact    | "CLI flag reference"          |

**Each page serves one mode.** A reference page that drifts into tutorial prose
degrades both. When a page feels unfocused, it likely conflates two modes --
split it.

```text
docs/
  learn/          # tutorials (learning-oriented)
  guides/         # how-tos (task-oriented)
  explanation/    # concepts (understanding-oriented)
  reference/      # API, CLI, config (information-oriented)
```

## Information-Seeking Behaviors

Users approach information four different ways. Good IA supports all of them.

| Behavior        | Question                                   | IA support needed                    |
| --------------- | ------------------------------------------ | ------------------------------------ |
| **Known-item**  | "Where is the config reference?"           | Search, consistent naming, indexes   |
| **Exploratory** | "What's available for monitoring?"         | Clear hierarchy, descriptive labels  |
| **Exhaustive**  | "Show me everything about authentication." | Indexes, cross-references, tag pages |
| **Re-finding**  | "I read this last week. Where was it?"     | Stable paths, consistent locations   |

**Heuristic:** If your IA only supports known-item seeking (search works, but
browsing fails), newcomers and explorers are lost. If it only supports browsing
(nice hierarchy, but file names are opaque), experienced users who know what
they want pay a navigation tax every time.

## Failure Modes

| Anti-Pattern             | Symptom                                     | Fix                                                              |
| ------------------------ | ------------------------------------------- | ---------------------------------------------------------------- |
| **Growing README**       | README exceeds 200 lines, accumulates all   | Extract into `docs/` by Diataxis mode; README becomes signpost   |
| **Flat docs directory**  | 20+ files at one level, no grouping         | Group by topic or audience; add directory-level READMEs          |
| **Deep nest**            | 4+ directory levels for docs                | Flatten by merging related pages or promoting important content  |
| **Orphan pages**         | Content exists but nothing links to it      | Add to table of contents, "See Also", or navigation index        |
| **Team-structured docs** | Organized by who wrote it, not who reads it | Reorganize by task or topic; users think in tasks, not org chart |
| **Jargon labels**        | `sre-runbook-v2-final.md`                   | Name for the reader: `incident-response.md`                      |
| **Duplicate homes**      | Same info in README, wiki, and docs/        | Single source of truth; others link to it                        |
| **Missing cross-refs**   | Related pages don't link to each other      | Add "See Also" sections; contextual inline links                 |

## Evaluating IA Quality

Seven questions to audit any information space.

1. **Can a newcomer find what they need without asking someone?** If not,
   navigation and labeling have failed.
2. **Can you predict what's inside from the label alone?** If not, labels are
   too vague or too clever.
3. **Is there one obvious place for any given content?** If not, categories
   overlap.
4. **Can you reach any page in three steps?** If not, the hierarchy is too deep.
5. **Are there orphan pages with no inbound link?** If so, they're invisible.
6. **Do similar items live together?** If scattered, the grouping scheme
   drifted.
7. **Does the structure match how users think?** Organized by team, or by task?
   Users think in tasks.

## Placement Decision Tree

When new content arrives and you don't know where it goes:

```text
Does similar content already exist?
├── Yes → Extend it. Don't duplicate.
└── No  → What question does this answer?
          ├── "How do I...?"        → guides/ (how-to)
          ├── "What is...?"         → explanation/
          ├── "Teach me..."         → learn/ (tutorial)
          ├── "What are the exact?" → reference/
          └── Unsure → Who needs it?
                       ├── Identify the audience's natural path
                       └── Can you name the parent directory in one word?
                           ├── Yes → Place it there
                           └── No  → The taxonomy needs work first
```

**Quick placement heuristic:** If you can't decide between two locations, the
organization scheme has a gap. Fix the scheme, then place the content.

## See Also

- [Knowledge Design](knowledge-design.md) -- Structuring knowledge for transfer
  (taxonomy, CTA, mental modeling)
- [Complexity](complexity.md) -- IA is complexity management for information
- [Thinking](thinking.md) -- Information-seeking maps to structured reasoning
- [Problem Solving](problem-solving.md) -- Placement decisions are design
  decisions
