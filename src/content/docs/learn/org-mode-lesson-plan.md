---
title: "Org-mode Lesson Plan"
description:
  Eight lessons from first contact to building a personal knowledge system with
  org-mode and org-roam.
---

A progressive curriculum to master org-mode as a complementary tool alongside
your editor.

<!-- prettier-ignore -->
:::note[Prerequisites]
Comfort with a text editor (Vim, VS Code, etc.). You will use Emacs for
org-mode, but your editor skills transfer. Basic Unix CLI knowledge helps.
:::

## Lesson 1: What Is Org-mode?

**Goal:** Understand what org-mode is, why it exists, and whether it fits your
workflow.

### Concepts

Org-mode is a plain-text knowledge management system built into Emacs. It's not
a replacement for your editor—it's a _complementary tool_ for:

- **Outlining and note-taking:** Hierarchical headings that fold/unfold
- **Task management:** TODOs with deadlines, scheduling, effort tracking
- **Tables and data:** Structured data with spreadsheet-like formulas
- **Executable code:** Run code blocks, see results inline
- **Publishing:** Export to HTML, PDF, LaTeX, Markdown in one command
- **Personal wiki:** Link notes together with bidirectional connections
  (org-roam)

### Why Org-mode?

Plain-text files that work with `git`, `grep`, standard tools. Not locked into a
vendor or app. Human-readable even without Emacs. But its power comes from Emacs
integration—you never leave your editor.

### Use Cases

- **Researcher:** Write papers with embedded code, auto-generated results
- **Developer:** Project plans, meeting notes, executable documentation
- **Writer:** Blog posts that export to HTML, with built-in revision history
- **Knowledge worker:** Personal wiki with linked ideas and full-text search
- **Project planner:** Timelines, deadlines, effort estimates in one file

### Exercises

1. **Install Doom Emacs** (the preconfigured distribution with org-mode ready)

   ```bash
   git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
   ~/.config/emacs/bin/doom install
   ```

2. **Create your first org file**

   ```bash
   emacs ~/scratch.org
   ```

3. **Write simple outline**

   ```org
   * First project
   ** Task 1
   ** Task 2

   * Second project
   ** Another task
   ```

   Press `Tab` on a heading to fold/unfold. Use arrow keys to navigate.

4. **Evaluate org-mode for yourself**

   Ask: "What would I use org-mode for?" (Note-taking? TODOs? Publishing?)

### Checkpoint

You have Emacs running with org-mode enabled. You can create headings, fold
sections, and navigate. You have a tentative use case in mind.

---

## Lesson 2: Syntax and Basic Structure

**Goal:** Master org-mode's plain-text syntax—the foundation of everything.

### Concepts

Org-mode syntax is simple:

- `*` = heading (more asterisks = deeper level)
- `-` `+` `*` = lists (bullet or checkbox)
- `|` = tables (aligns on `Tab`)
- `:PROPERTIES:` = metadata blocks
- Links with `[[...]]`
- Code blocks with `#+begin_src`

All human-readable, searchable with `grep`.

### Exercises

1. **Create a structured file**

   ```org
   * Project: My App
     :PROPERTIES:
     :CREATED:  <2026-03-07 Fri>
     :STATUS:   Active
     :END:

   ** Features

   *** Authentication
       - [ ] Design schema
       - [ ] Write tests
       - [x] JWT implementation

   *** Payment Integration
       - [ ] Stripe setup
       - [ ] Webhook handling

   ** Notes
       Some notes about the project.

       Related: [[Project: Backend API]]
   ```

2. **Practice headings and lists**

   Create a file with:
   - 3 top-level headings (use `*`)
   - 2-3 subheadings under each (use `**`)
   - Mixed bullet points and checkboxes under one section

3. **Create a simple table**

   ```org
   | Name   | Age | City      |
   |--------|-----|-----------|
   | Alice  |  30 | NYC       |
   | Bob    |  25 | San Diego |
   ```

   Position cursor on the `|` and press `Tab` to auto-align.

4. **Add properties to a heading**

   ```org
   * Task: Review PR
     :PROPERTIES:
     :EFFORT:   2h
     :PRIORITY: High
     :END:

     Description goes here.
   ```

### Checkpoint

You can navigate a multi-level outline, use checkboxes, create tables, and add
properties to headings. When you run `grep` on the file, the plain-text format
is readable.

---

## Lesson 3: Task Management with Deadlines

**Goal:** Use org-mode for task tracking with dates, deadlines, and state
transitions.

### Concepts

Any heading can become a task with a state keyword:

- `TODO` — open task
- `DONE` — completed task
- `IN-PROGRESS` — currently working on
- Custom states: define your own

Dates and deadlines:

- `SCHEDULED: <2026-03-10 Mon>` — when to start
- `DEADLINE: <2026-03-15 Sat>` — when it's due

Timestamps are in `<YYYY-MM-DD DayOfWeek>` format. Org can parse these, generate
calendars, and show agendas.

### Exercises

1. **Create a project with task headings**

   ```org
   * PROJECT: Q1 Goals

   ** TODO Write spec
      DEADLINE: <2026-03-08 Sat>
      High priority.

   ** TODO Implement feature
      SCHEDULED: <2026-03-10 Mon>
      DEADLINE: <2026-03-20 Fri>

   ** IN-PROGRESS Code review
      Started: [2026-03-07 Fri 09:00]

   ** DONE Design meeting
      CLOSED: [2026-03-06 Thu 14:30]
   ```

2. **Toggle task states**

   Place cursor on a heading with a task keyword (like `TODO`) and press
   `C-c C-t` (or `t` if using Evil mode). It cycles through states: `TODO` →
   `IN-PROGRESS` → `DONE`.

3. **Set deadlines**

   ```bash
   C-c C-d    # Set deadline
   # Emacs shows a calendar; pick a date
   ```

4. **View the agenda**

   ```bash
   C-c a a    # Show agenda for current week
   ```

   This shows all TODOs across all org files, sorted by deadline.

5. **Create a recurring task**

   ```org
   * TODO Weekly review
     SCHEDULED: <2026-03-07 Fri +1w>
     Repeats every week.
   ```

### Checkpoint

You have a file with mixed task states and deadlines. Running `C-c a a` shows
your agenda. You can toggle states with a keystroke.

---

## Lesson 4: Tables and Spreadsheet Formulas

**Goal:** Use org-mode tables with formulas for structured data.

### Concepts

Org tables are plain text but support formulas:

```org
| Product | Q1 Sales | Q2 Sales | Total   |
|---------|----------|----------|---------|
| A       |       10 |       15 |      25 |
| B       |       20 |       25 |      45 |
| C       |       30 |       35 |      65 |
|---------+----------+----------+---------|
| Total   |       60 |       75 | 135     |
#+TBLFM: @4$4=vsum(@2..@3$4)
```

Formulas use `@row$col` notation. Press `C-c C-c` on the formula line to
recalculate.

### Exercises

1. **Create a budget table**

   ```org
   | Item       | Budgeted | Actual | Variance |
   |------------|----------|--------|----------|
   | Rent       |     1500 |   1500 |        0 |
   | Groceries  |      400 |    450 |      -50 |
   | Transport  |      300 |    250 |       50 |
   |------------|----------|--------|----------|
   | Total      |     2200 |   2200 |        0 |
   #+TBLFM: @4$2=vsum(@2..@3$2) :: @4$3=vsum(@2..@3$3) :: @4$4=@4$3-@4$2
   ```

2. **Recalculate formulas**

   Edit a value (e.g., change Groceries actual to 500) and press `C-c C-c` on
   the formula line. The totals update automatically.

3. **Use column references**

   ```org
   | Name  | Score1 | Score2 | Average |
   |-------|--------|--------|---------|
   | Alice |     85 |     90 |    87.5 |
   | Bob   |     75 |     80 |    77.5 |
   #+TBLFM: $4=($2+$3)/2
   ```

   Position on any row's formula and press `C-c C-c`.

### Checkpoint

You have a working table with formulas. You can edit cells and recalculate.
Formulas persist when you save and reload the file.

---

## Lesson 5: Code Blocks and Inline Execution

**Goal:** Embed executable code in org documents and see results inline.

### Concepts

Mark code blocks with `#+begin_src LANGUAGE` and `#+end_src`. When you execute a
block with `C-c C-c`, org inserts the results below in `#+RESULTS:`.

Org supports 40+ languages: Python, JavaScript, Bash, R, Clojure, Rust, and
more. Results can be values, tables, or rendered output.

### Exercises

1. **Create a Python block**

   ```org
   ** Data Processing

   #+name: data
   #+begin_src python
   numbers = [1, 2, 3, 4, 5]
   total = sum(numbers)
   average = total / len(numbers)
   print(f"Total: {total}, Average: {average}")
   return numbers
   #+end_src

   #+RESULTS: data
   | 1 | 2 | 3 | 4 | 5 |
   ```

   Position cursor inside the block and press `C-c C-c`. Emacs executes the code
   and inserts results below.

2. **Execute a Bash block**

   ```org
   #+begin_src bash
   echo "Current date: $(date)"
   ls -la ~
   #+end_src
   ```

3. **Reference table data in code**

   ```org
   #+name: sales_data
   | Product | Q1 | Q2 |
   |---------|----|----|
   | A       | 10 | 15 |
   | B       | 20 | 25 |

   #+begin_src python :var data=sales_data
   import pandas as pd
   df = pd.DataFrame(data[1:], columns=data[0])
   return df['Q1'].sum()
   #+end_src

   #+RESULTS:
   : 30
   ```

4. **Tangle (extract) code to a file**

   ```org
   * Python Script
   :PROPERTIES:
   :TANGLE: script.py
   :END:

   #+begin_src python
   def hello():
       print("Hello from org-mode!")

   if __name__ == "__main__":
       hello()
   #+end_src
   ```

   Run `C-c C-v C-t` to extract all tangled code blocks. Creates `script.py`.

### Checkpoint

You have a file with code blocks in 2+ languages. You can execute them and see
results inline. Results update when you edit and re-execute.

---

## Lesson 6: Links and Navigation

**Goal:** Connect notes with links and build a personal information network.

### Concepts

Links in org-mode use `[[target]]` syntax:

- `[[note-title]]` — link to another heading
- `[[file.org::heading]]` — link to a file and specific heading
- `[[https://example.com]]` — external link
- `[[id:uuid]]` — permanent link by ID

Org automatically creates backlink buffers: when you visit a note, you see all
other notes that reference it.

### Exercises

1. **Create linked notes**

   ```org
   * Project: Personal Knowledge System
     Link to: [[Project: Org-roam Setup]]

   * Project: Org-roam Setup
     Link to: [[Project: Personal Knowledge System]]
     Related: [[Tool: Emacs]]

   * Tool: Emacs
     Used in: [[Project: Org-roam Setup]]
   ```

2. **Navigate links**

   Place cursor on a link and press `C-c C-o` to follow it. Press `C-c C-&` (or
   `C-c &`) to go back.

3. **Create permanent IDs**

   ```org
   * Idea: Systems Thinking
     :PROPERTIES:
     :ID: 2026-03-07-systems-thinking
     :CREATED: <2026-03-07 Fri>
     :END:

     Reference this idea anywhere with: [[id:2026-03-07-systems-thinking]]
   ```

4. **Search and link**

   ```bash
   C-c C-l    # Insert link (autocomplete suggests existing headings)
   ```

### Checkpoint

You have a file with 3+ cross-linked headings. You can navigate between them
using `C-c C-o` and return with `C-c C-&`. Links are human-readable even in
plain text.

---

## Lesson 7: Org-roam—Bidirectional Linking and Daily Notes

**Goal:** Build a networked knowledge system with org-roam (Roam Research in
plain text).

### Concepts

Org-roam automatically indexes your org files and creates:

- **Bidirectional links:** When you link to a note, the backlinks appear in that
  note automatically
- **Daily notes:** Timestamped notes created one per day, linked to permanent
  notes
- **Graph visualization:** See how your notes connect (requires Graphviz)
- **Full-text search:** Find notes across your vault

Unlike hierarchical note-taking, org-roam embraces networked thinking: ideas
flow in multiple directions.

### Exercises

1. **Enable org-roam in Doom Emacs**

   Edit `~/.doom.d/init.el`:

   ```elisp
   :lang
   (org +roam2)    ;; Add this line
   ```

   Run `~/.config/emacs/bin/doom sync`.

2. **Create your first org-roam note**

   ```bash
   M-x org-roam-node-find
   # Type a new note title, press Enter
   ```

   Org-roam creates `~/org/roam/YYYY-MM-DD-title.org` with a unique ID.

3. **Create daily notes**

   ```bash
   M-x org-roam-dailies-capture-today
   # Or in Doom: C-c n d (with Evil mode)
   ```

   Creates `~/org/roam/daily/2026-03-07.org`. Use this for daily thoughts,
   capture, and fleeting ideas.

4. **Link to other notes**

   In any note, type `[[` and start typing. Org-roam autocompletes existing
   notes. Press Enter to create a new note and link it.

5. **Explore backlinks**

   Visit a note. At the bottom, you see a "Backlinks" buffer showing all notes
   that reference this one. Click to jump to them.

6. **View the graph**

   ```bash
   M-x org-roam-graph
   ```

   Opens a browser showing your notes as a visual graph. Lines show connections.

### Checkpoint

You have 5+ org-roam notes with cross-links. You can navigate between them using
autocomplete. Backlinks appear automatically. The graph visualization shows at
least 3 connected notes.

---

## Lesson 8: Building a Personal Knowledge System

**Goal:** Integrate org-mode and org-roam into your daily workflow using Evil
mode and Doom Emacs.

### Concepts

A personal knowledge system (PKS) combines:

- **Daily capture:** Fleeting ideas in daily notes
- **Processing:** Weekly review moves fleeting ideas to permanent notes
- **Organization:** Links group related ideas into emergent structures
- **Retrieval:** Full-text search and graph navigation find knowledge when you
  need it
- **Publishing:** Export insights to blog, documents, or share with teams

The Zettelkasten method formalized this: each note is atomic (one idea),
timestamped, with backlinks to related ideas. Org-roam makes this practical.

### Exercises

1. **Set up Evil mode keybindings for org-roam**

   In `~/.doom.d/config.el`:

   ```elisp
   (use-package! org-roam
     :config
     (setq org-roam-directory (file-truename "~/org/roam"))
     (org-roam-db-autosync-mode))

   ;; Evil keybindings for org-roam (if not auto-configured)
   (map! :leader
         (:prefix ("n" . "notes")
          :desc "Find note" "f" #'org-roam-node-find
          :desc "Today" "d" #'org-roam-dailies-capture-today
          :desc "Insert link" "i" #'org-roam-node-insert
          :desc "Graph" "g" #'org-roam-graph))
   ```

2. **Create a weekly review template**

   `~/org/roam/templates/weekly-review.org`:

   ```org
   * Review: Week of <2026-03-07>
   :PROPERTIES:
   :CREATED: <2026-03-07 Fri>
   :END:

   ** What went well?
      -

   ** What was hard?
      -

   ** Key learnings
      - [[idea]]
      - [[another-idea]]

   ** Next week priorities
      - [ ] Priority 1
      - [ ] Priority 2
   ```

3. **Implement a capture workflow**

   Add to `~/.doom.d/config.el`:

   ```elisp
   (setq org-roam-capture-templates
         '(("d" "default" plain
            "%?"
            :if-new (org-roam-node-create-with-capture)
            :unnarrowed t)
           ("w" "work" plain
            "* Context\n%?\n\n* Related\n"
            :if-new (org-roam-node-create-with-capture)
            :unnarrowed t)))
   ```

4. **Build a weekly ritual**

   Every Friday at 4 PM:
   1. `C-c n d` (create daily note)
   2. Review yesterday's daily notes (scan `roam/daily/` directory)
   3. Move important items to permanent notes: `C-c n f` (find or create)
   4. Create weekly review: link to notes from the week
   5. Run `C-c a a` (agenda) to see next week's deadlines

5. **Query your knowledge**

   ```bash
   # Find all notes mentioning "learning"
   M-x org-roam-node-find
   # Type "learning" in search box

   # See graph of related ideas
   M-x org-roam-graph
   ```

6. **Export your thoughts**

   ```bash
   C-c C-e h h    # Export current note to HTML
   # Or publish all: C-c n (org-publish-current-project)
   ```

### Checkpoint

You have:

- A daily capture habit (at least 3 daily notes)
- 5+ permanent notes linked together
- A weekly review process
- Evil keybindings working for org-roam
- Ability to search and navigate your knowledge graph

You are now using org-mode and org-roam as a complementary knowledge system
alongside your primary editor.

---

## Practice Projects

### Project 1: Personal Learning Log

Create a learning vault:

- Daily notes: capture what you learn each day
- Permanent notes: synthesize learnings into reusable ideas
- Links: connect ideas to related concepts
- Weekly review: summarize insights

Track 2 weeks of learning. See patterns emerge.

### Project 2: Project Planning

Set up org-mode for a project:

- Top-level heading: project name
- Subheadings: features, timeline, team
- Table: features with effort estimates and deadlines
- Code blocks: design sketches or executable specs
- Links: reference external docs or related projects

### Project 3: Blog with Org-mode

Write 3 blog posts in org-mode:

- Use headings, lists, code blocks
- Export each to HTML: `C-c C-e h h`
- Verify HTML is readable in browser
- Experiment with `#+TITLE:`, `#+AUTHOR:`, `#+DATE:` metadata

---

## Evil Mode Keybinding Summary

When using Evil mode in Emacs with org-mode:

| Action             | Keybinding               | Notes                   |
| ------------------ | ------------------------ | ----------------------- |
| Navigate           | `j/k` ↑↓, `h/l` ←→       | Standard Vi movement    |
| Fold heading       | `za`                     | Vim-style, toggles fold |
| Unfold recursively | `zR`                     | Open all levels         |
| Promote heading    | `>` (visual mode)        | Decrease level          |
| Demote heading     | `<` (visual mode)        | Increase level          |
| Toggle task state  | `C-c C-t` or `t`         | Cycles through states   |
| Set deadline       | `C-c C-d`                | Calendar picker         |
| Find note          | `C-c n f` (Doom default) | Org-roam                |
| Insert link        | `C-c n i` (Doom default) | Org-roam                |
| Daily note         | `C-c n d` (Doom default) | Create today's note     |

**Note:** Org-mode commands use `C-c` prefix (Emacs convention), not Vi keys.
Once learned, these become automatic.

---

## See Also

- [Org-mode for Beginners](https://orgmodeforbeginners.com/) — Video tutorials
  (3–10 min each)
- [The Org Manual](https://orgmode.org/org.html) — Comprehensive reference
- [Org-roam User Manual](https://www.orgroam.com/manual.html) — Full
  documentation
- [Doom Emacs `:lang org` module](https://docs.doomemacs.org/v21.12/modules/lang/org/)
  — Configuration options
- [Ghostty Lesson Plan](ghostty-lesson-plan.md) — Terminal emulator for running
  Emacs
- [Technical Writing Lesson Plan](technical-writing-lesson-plan.md) — Export
  org-mode documents with clarity
- [Git Lesson Plan](git-lesson-plan.md) — Version control your knowledge vault
  (`~/org/roam/`)
