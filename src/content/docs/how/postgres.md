---
title: "PostgreSQL Cheat Sheet"
description:
  psql commands, connection strings, indexes, window functions, JSON operators,
  and admin queries.
---

## Connection

```bash
# Connect
psql -h localhost -U username -d database
psql "postgresql://user:pass@host:5432/dbname"

# Common flags
psql -c "SQL"           # Execute single command
psql -f file.sql        # Execute file
psql -l                 # List databases
```

## psql Commands

| Command | Description    |
| ------- | -------------- |
| `\l`    | List databases |

| `

## See Also

- [SQL](sql.md) — Portable SQL syntax: joins, CTEs, window functions
- [Performance](performance.md) — Profiling and benchmarking, including database
  queries
- [Docker](docker.md) — Running PostgreSQL in containers
- [Kubernetes](k8s.md) — Deploying PostgreSQL on k8s
- [Data Models Lesson Plan](../learn/data-models-lesson-plan.md) — ER diagrams
  to model selection
