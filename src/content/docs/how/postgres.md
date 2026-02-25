---
title: "PostgreSQL Cheat Sheet"
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
