# Data Models Lesson Plan

How you model data shapes everything downstream -- queries, APIs, UIs,
performance, team boundaries.

## Lesson 1: Entities and Relationships

**Goal:** Identify the nouns in a system and how they relate to each other.

### Concepts

Every system has entities (things you track) and relationships (how they
connect). List the nouns: users, orders, products. Then determine cardinality --
1:1, 1:N, or M:N. Drawing these out before writing code prevents expensive
rework.

### Exercises

1. **Identify entities in a bookstore**

   ```text
   Entities: Book, Author, Customer, Order, Review

   Relationships:
     Author  --< Book        (1:N)
     Customer --< Order      (1:N)
     Order >--< Book         (M:N)
     Customer --< Review     (1:N)
     Book --< Review         (1:N)
   ```

2. **Draw an ER diagram**

   ```mermaid
   erDiagram
     AUTHOR ||--o{ BOOK : writes
     CUSTOMER ||--o{ ORDER : places
     ORDER }o--o{ BOOK : contains
     CUSTOMER ||--o{ REVIEW : writes
     BOOK ||--o{ REVIEW : "is reviewed in"
   ```

3. **Spot the cardinality errors**

   "Each employee has exactly one department, each department has exactly one
   employee." Explain why 1:1 is wrong here. Rewrite as 1:N. Identify a real
   case where 1:1 makes sense (e.g., user and user_profile).

### Checkpoint

Model a different domain (gym membership, restaurant). List 5+ entities with
cardinalities. Identify one M:N and explain how to resolve it with a join table.

---

## Lesson 2: Relational Modeling

**Goal:** Normalize data into tables that avoid redundancy and anomalies.

### Concepts

Normalization reduces duplication. 1NF: every cell holds one value. 2NF: non-key
columns depend on the entire primary key. 3NF: no column depends on another
non-key column. Over-normalizing creates excessive joins. Denormalize
deliberately when read performance matters more than write consistency.

### Exercises

1. **Fix a 1NF violation**

   ```sql
   -- Bad: multiple phones in one column
   CREATE TABLE contacts (id INTEGER PRIMARY KEY, name TEXT, phones TEXT);

   -- Fixed: separate table
   CREATE TABLE contacts (id INTEGER PRIMARY KEY, name TEXT);
   CREATE TABLE phones (
     id INTEGER PRIMARY KEY,
     contact_id INTEGER REFERENCES contacts(id),
     phone TEXT NOT NULL
   );
   ```

2. **Normalize to 3NF**

   ```sql
   -- Bad: city depends on zip, not on student_id
   CREATE TABLE students (
     student_id INTEGER PRIMARY KEY, name TEXT,
     zip TEXT, city TEXT, state TEXT
   );

   -- Fixed: extract zip_codes
   CREATE TABLE zip_codes (zip TEXT PRIMARY KEY, city TEXT NOT NULL, state TEXT NOT NULL);
   CREATE TABLE students (
     student_id INTEGER PRIMARY KEY, name TEXT,
     zip TEXT REFERENCES zip_codes(zip)
   );
   ```

3. **Resolve an M:N relationship**

   ```sql
   CREATE TABLE students (id INTEGER PRIMARY KEY, name TEXT);
   CREATE TABLE courses (id INTEGER PRIMARY KEY, title TEXT);
   CREATE TABLE enrollments (
     student_id INTEGER REFERENCES students(id),
     course_id INTEGER REFERENCES courses(id),
     enrolled_at TEXT DEFAULT (datetime('now')),
     PRIMARY KEY (student_id, course_id)
   );

   INSERT INTO students VALUES (1, 'Alice'), (2, 'Bob');
   INSERT INTO courses VALUES (1, 'Databases'), (2, 'Algorithms');
   INSERT INTO enrollments (student_id, course_id) VALUES (1, 1), (1, 2), (2, 1);

   SELECT s.name, c.title FROM enrollments e
   JOIN students s ON e.student_id = s.id
   JOIN courses c ON e.course_id = c.id;
   ```

### Checkpoint

Take a flat CSV with repeated customer info in every row. Normalize it into 3NF
with 3+ tables in SQLite.

---

## Lesson 3: Schema Design in Practice

**Goal:** Design a real schema with constraints, indexes, and migrations.

### Concepts

Good schemas encode business rules: NOT NULL prevents missing data, UNIQUE
prevents duplicates, CHECK enforces ranges, FOREIGN KEY enforces relationships.
Indexes support your access patterns -- add them for columns you filter and join
on.

### Exercises

1. **Design a task tracker schema**

   ```sql
   CREATE TABLE users (
     id INTEGER PRIMARY KEY, email TEXT NOT NULL UNIQUE,
     name TEXT NOT NULL, created_at TEXT NOT NULL DEFAULT (datetime('now'))
   );
   CREATE TABLE projects (
     id INTEGER PRIMARY KEY, name TEXT NOT NULL,
     owner_id INTEGER NOT NULL REFERENCES users(id)
   );
   CREATE TABLE tasks (
     id INTEGER PRIMARY KEY,
     project_id INTEGER NOT NULL REFERENCES projects(id),
     title TEXT NOT NULL,
     status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo','in_progress','done')),
     assignee_id INTEGER REFERENCES users(id),
     due_date TEXT,
     created_at TEXT NOT NULL DEFAULT (datetime('now'))
   );
   CREATE INDEX idx_tasks_project ON tasks(project_id);
   CREATE INDEX idx_tasks_assignee ON tasks(assignee_id);
   ```

2. **Write a migration**

   ```sql
   -- 002_add_task_priority.sql
   ALTER TABLE tasks ADD COLUMN priority TEXT
     DEFAULT 'medium' CHECK (priority IN ('low','medium','high','urgent'));
   UPDATE tasks SET priority = 'medium' WHERE priority IS NULL;
   ```

3. **Query and verify indexes**

   ```sql
   SELECT t.title, t.status, t.due_date, p.name AS project
   FROM tasks t JOIN projects p ON t.project_id = p.id
   WHERE t.assignee_id = 1 AND t.status != 'done'
   ORDER BY t.due_date;

   EXPLAIN QUERY PLAN
   SELECT * FROM tasks WHERE assignee_id = 1 AND status = 'todo';
   ```

### Checkpoint

Load the schema into SQLite with sample data. Run EXPLAIN QUERY PLAN on three
queries. Add a `labels` feature using a junction table.

---

## Lesson 4: Document Models

**Goal:** Understand when to model data as documents instead of tables.

### Concepts

Document models store nested structures -- JSON, YAML, TOML. They excel when
data is self-contained, schema varies across records, or you read entire objects
at once. Embedding duplicates data but avoids joins. Referencing normalizes but
requires multiple lookups.

### Exercises

1. **Model and query a blog post**

   ```json
   {
     "id": "post-001",
     "title": "Data Modeling Basics",
     "author": { "id": "user-42", "name": "Alice" },
     "tags": ["databases", "design"],
     "comments": [
       {
         "user": "Bob",
         "text": "Great post!",
         "created_at": "2025-01-15T10:30:00Z"
       }
     ]
   }
   ```

   ```bash
   jq '.tags[]' post.json              # Extract tags
   jq '.comments[].user' post.json     # Comment authors
   jq '.comments | length' post.json   # Count comments
   ```

2. **Compare embedding vs referencing**

   Embedded order (all data inline) vs referenced order (just IDs). Write three
   advantages and three disadvantages of each approach.

3. **Query a collection with jq**

   Create `tasks.json` with 5 task objects (varying status, priority, assignee):

   ```bash
   jq '[.[] | select(.priority == "high")]' tasks.json
   jq 'group_by(.status) | map({status: .[0].status, count: length})' tasks.json
   jq '[.[] | select(.assignee == "Alice")] | sort_by(.due_date)' tasks.json
   ```

### Checkpoint

Model the Lesson 3 task tracker as JSON documents. Replicate the SQL queries in
jq. Note which become easier and which become harder.

---

## Lesson 5: Graph Models

**Goal:** Model data where relationships are the primary concern.

### Concepts

Graphs store nodes (entities) and edges (relationships). Unlike relational joins
that get expensive at depth, graphs traverse relationships efficiently. Use them
when the key question is "how is X connected to Y?" -- social networks,
knowledge bases, dependency trees.

### Exercises

1. **Build a social graph as JSON**

   ```json
   {
     "nodes": [
       { "id": "alice", "role": "engineer" },
       { "id": "bob", "role": "designer" },
       { "id": "carol", "role": "engineer" }
     ],
     "edges": [
       { "from": "alice", "to": "bob", "type": "follows" },
       { "from": "alice", "to": "carol", "type": "follows" },
       { "from": "carol", "to": "alice", "type": "follows" }
     ]
   }
   ```

   ```bash
   # Who does Alice follow?
   jq '[.edges[] | select(.from == "alice") | .to]' graph.json
   # Who follows Carol?
   jq '[.edges[] | select(.to == "carol") | .from]' graph.json
   ```

2. **Model a dependency graph**

   Create nodes for `app, api, auth, db, cache, logger` with directed edges.
   Find all direct dependencies of `api` with jq. Note why recursive traversal
   is hard in jq but natural in a graph database.

3. **Store a graph in SQL**

   ```sql
   CREATE TABLE nodes (id TEXT PRIMARY KEY, label TEXT, properties TEXT);
   CREATE TABLE edges (
     id INTEGER PRIMARY KEY,
     from_node TEXT REFERENCES nodes(id),
     to_node TEXT REFERENCES nodes(id),
     type TEXT NOT NULL
   );

   -- Friends of friends (2-hop traversal)
   SELECT DISTINCT e2.to_node AS friend_of_friend
   FROM edges e1 JOIN edges e2 ON e1.to_node = e2.from_node
   WHERE e1.from_node = 'alice' AND e1.type = 'follows'
     AND e2.type = 'follows' AND e2.to_node != 'alice';
   ```

### Checkpoint

Build a knowledge graph for a topic you know (10+ nodes, 15+ edges). Write a
query finding all nodes within 2 hops of a starting node.

---

## Lesson 6: Time and State

**Goal:** Model data that changes over time without losing history.

### Concepts

Most databases store current state only -- UPDATE destroys the previous value.
Event sourcing stores every change as an immutable event; current state derives
from replaying events. Append-only logs (JSONL, Kafka) capture what happened and
when, enabling audit trails and point-in-time queries.

### Exercises

1. **Build an append-only event log**

   Create `events.jsonl` with one JSON event per line:

   ```jsonl
   {"ts":"2025-01-01T09:00:00Z","type":"task.created","task_id":"t-1","title":"Write docs"}
   {"ts":"2025-01-01T10:30:00Z","type":"task.assigned","task_id":"t-1","assignee":"alice"}
   {"ts":"2025-01-01T14:00:00Z","type":"task.status_changed","task_id":"t-1","to":"in_progress"}
   {"ts":"2025-01-02T11:00:00Z","type":"task.status_changed","task_id":"t-1","to":"done"}
   ```

   ```bash
   # Current status (last status_changed event)
   jq -s '[.[] | select(.type == "task.status_changed")] | last | .to' events.jsonl
   # Full timeline
   jq -s 'sort_by(.ts) | .[] | "\(.ts) \(.type)"' events.jsonl
   ```

2. **Temporal table in SQL**

   ```sql
   CREATE TABLE task_history (
     id INTEGER PRIMARY KEY, task_id TEXT NOT NULL,
     field TEXT NOT NULL, old_value TEXT, new_value TEXT NOT NULL,
     changed_at TEXT NOT NULL DEFAULT (datetime('now')),
     changed_by TEXT NOT NULL
   );

   -- Status at a specific time
   SELECT new_value FROM task_history
   WHERE task_id = 't-1' AND field = 'status'
     AND changed_at <= '2025-01-01T12:00:00Z'
   ORDER BY changed_at DESC LIMIT 1;
   ```

3. **Compare mutable vs immutable**

   ```sql
   -- Mutable: current balance only
   CREATE TABLE accounts (id TEXT PRIMARY KEY, balance REAL NOT NULL DEFAULT 0);

   -- Immutable: transaction log
   CREATE TABLE transactions (
     id INTEGER PRIMARY KEY, account_id TEXT NOT NULL,
     amount REAL NOT NULL, created_at TEXT NOT NULL DEFAULT (datetime('now'))
   );
   -- Current balance: SELECT SUM(amount) FROM transactions WHERE account_id = 'acct-1';
   -- Balance at date: add AND created_at <= '2025-06-01'
   ```

   Write when you would choose each approach and why.

### Checkpoint

Build an event log for a shopping cart (add, remove, change quantity). Replay it
with jq to compute the final state. Add a point-in-time query.

---

## Lesson 7: API Data Contracts

**Goal:** Design API schemas that evolve without breaking consumers.

### Concepts

Internal schemas optimize for storage; API schemas optimize for consumers.
Adding fields is safe. Removing or renaming fields breaks clients. Version your
APIs or use additive-only changes. JSON Schema and OpenAPI formalize contracts
so both sides know what to expect.

### Exercises

1. **Design a REST resource schema**

   ```json
   {
     "type": "object",
     "required": ["id", "title", "status", "project_id"],
     "properties": {
       "id": { "type": "string" },
       "title": { "type": "string" },
       "status": { "type": "string", "enum": ["todo", "in_progress", "done"] },
       "assignee": { "type": "object", "properties": { "id": {}, "name": {} } }
     }
   }
   ```

   Note: `assignee` is embedded (not just an ID) -- optimize for the consumer,
   not the database.

2. **Classify schema changes**

   Given `{"id": "t-1", "title": "Write docs", "status": "todo"}`, classify:
   - Add optional `priority` field -- **SAFE**
   - Rename `title` to `name` -- **BREAKING**
   - Add `"blocked"` to status enum -- **RISKY** (clients may not handle it)
   - Change `id` from string to integer -- **BREAKING**

   For each breaking change, write a migration strategy preserving backwards
   compatibility.

3. **Validate with jq**

   ```bash
   jq '
     if .id == null then error("missing id")
     elif .title == null then error("missing title")
     elif (.status | IN("todo","in_progress","done") | not)
       then error("invalid status")
     else "valid" end
   ' task.json
   ```

### Checkpoint

Design request/response schemas for create-task and list-tasks endpoints. Write
a jq validator for sample payloads.

---

## Lesson 8: Choosing the Right Model

**Goal:** Apply a decision framework to pick the right data model for a problem.

### Concepts

No single model fits all problems. Relational models handle structured data with
complex cross-entity queries. Documents suit self-contained objects with
variable schemas. Graphs shine when relationships drive queries. Event logs
capture temporal state. Real systems combine multiple models -- pick based on
access patterns, not familiarity.

### Exercises

1. **Evaluate tradeoffs for three scenarios**

   ```text
   A: E-commerce catalog -- products with varying attributes (books have ISBN,
      clothing has sizes). Customers browse and search. Orders reference products.

   B: Fraud detection -- tracks relationships between accounts, devices, IPs.
      Key question: "Is this account connected to known-fraud accounts?"

   C: Financial audit -- must record every change. Regulators need state at any
      point in time. No data may be deleted.
   ```

   Choose a primary model for each and justify in one paragraph.

2. **Design a hybrid model**

   ```sql
   -- Relational core
   CREATE TABLE projects (id TEXT PRIMARY KEY, name TEXT NOT NULL);
   CREATE TABLE tasks (
     id TEXT PRIMARY KEY, project_id TEXT REFERENCES projects(id),
     title TEXT NOT NULL, status TEXT NOT NULL,
     metadata TEXT DEFAULT '{}'  -- JSON for flexible fields
   );
   -- Event log for audit
   CREATE TABLE events (
     id INTEGER PRIMARY KEY, entity_type TEXT, entity_id TEXT,
     event_type TEXT NOT NULL, payload TEXT NOT NULL,
     created_at TEXT NOT NULL DEFAULT (datetime('now'))
   );
   ```

   ```sql
   -- Query JSON metadata
   SELECT id, title, json_extract(metadata, '$.sprint') AS sprint
   FROM tasks WHERE json_extract(metadata, '$.story_points') > 2;
   ```

3. **Build a decision checklist**

   ```text
   Access patterns:   Whole objects by ID --> Document
                      Cross-entity JOINs  --> Relational
                      N-hop traversals    --> Graph
                      Replay / audit      --> Event log

   Schema structure:  Fixed, enforced     --> Relational
                      Variable per record --> Document

   Consistency:       Strong, ACID        --> Relational
                      Eventual OK         --> Document / Event log
   ```

### Checkpoint

Pick a real application you use daily. Identify its likely data model(s) and
write a one-page analysis covering entities, access patterns, and consistency
needs.

---

## Practice Projects

### Project 1: Task Tracker (Full Stack Model)

Design a task tracker with users, projects, tasks, labels, comments, and
activity feed. Write the SQL schema, seed it, build 10 queries, and add an event
log for audit.

### Project 2: Recipe Book (Document Model)

Model a recipe collection as JSON documents with ingredients, steps, tags, and
ratings. Store 10 recipes. Write jq queries to search by ingredient, filter by
tag, and find recipes under 30 minutes.

### Project 3: Knowledge Graph

Build a graph of technologies -- languages, frameworks, databases. Model "uses,"
"built-with," and "depends-on" edges. Store in SQLite as nodes and edges. Find
clusters and most-connected nodes.

---

## Quick Reference

| Model    | Best For                         | Watch Out For                  |
| -------- | -------------------------------- | ------------------------------ |
| Relation | Structured data, complex queries | Over-normalization, join costs |
| Document | Variable schema, self-contained  | Data duplication, no joins     |
| Graph    | Relationship-heavy queries       | Simple queries become verbose  |
| Event    | Audit trails, temporal queries   | Replay cost, storage growth    |
| Hybrid   | Real-world systems, mixed needs  | Operational complexity         |

## See Also

- [PostgreSQL Cheatsheet](../how/postgres.md) -- Indexes, window functions,
  admin queries
- [SQL Cheatsheet](../how/sql.md) -- Joins, CTEs, window functions
- [Thinking](../why/thinking.md) -- Mental models and systems thinking
