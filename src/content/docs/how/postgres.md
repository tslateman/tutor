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

### Navigation

| Command         | Description                 |
| --------------- | --------------------------- |
| `\l`            | List databases              |
| `\c dbname`     | Connect to database         |
| `\dt`           | List tables                 |
| `\dt+`          | List tables with sizes      |
| `\d tablename`  | Describe table              |
| `\d+ tablename` | Describe table with storage |
| `\dn`           | List schemas                |
| `\di`           | List indexes                |
| `\dv`           | List views                  |
| `\df`           | List functions              |
| `\du`           | List roles                  |
| `\dp`           | List table privileges       |
| `\ds`           | List sequences              |
| `\dT`           | List data types             |

### Execution and Output

| Command             | Description                     |
| ------------------- | ------------------------------- |
| `\x`                | Toggle expanded display         |
| `\timing`           | Toggle query timing             |
| `\e`                | Edit query in `$EDITOR`         |
| `\i file.sql`       | Execute file                    |
| `\o file.txt`       | Send output to file             |
| `\copy`             | Client-side COPY (no superuser) |
| `\! cmd`            | Execute shell command           |
| `\set VAR value`    | Set psql variable               |
| `\echo text`        | Print text                      |
| `\pset format html` | Change output format            |
| `\q`                | Quit                            |

### Information

| Command     | Description             |
| ----------- | ----------------------- |
| `\?`        | Help on psql commands   |
| `\h`        | Help on SQL commands    |
| `\h ALTER`  | Help on ALTER statement |
| `\conninfo` | Current connection info |
| `\encoding` | Show client encoding    |

## Indexes

```sql
-- B-tree (default, most common)
CREATE INDEX idx_users_email ON users (email);

-- Unique index
CREATE UNIQUE INDEX idx_users_email ON users (email);

-- Composite index (column order matters)
CREATE INDEX idx_orders_user_date ON orders (user_id, created_at);

-- Partial index (only index rows matching WHERE)
CREATE INDEX idx_active_users ON users (email) WHERE active = true;

-- Expression index
CREATE INDEX idx_users_lower_email ON users (lower(email));

-- GIN index (arrays, JSONB, full-text)
CREATE INDEX idx_tags ON posts USING GIN (tags);
CREATE INDEX idx_data ON events USING GIN (metadata jsonb_path_ops);

-- GiST index (geometric, range, full-text)
CREATE INDEX idx_location ON places USING GIST (coordinates);

-- BRIN index (large tables with natural ordering)
CREATE INDEX idx_created ON events USING BRIN (created_at);

-- Concurrent creation (no table lock)
CREATE INDEX CONCURRENTLY idx_name ON table (column);

-- Drop
DROP INDEX idx_name;
DROP INDEX CONCURRENTLY idx_name;

-- Rebuild
REINDEX INDEX idx_name;
REINDEX TABLE tablename;
```

### Index Analysis

```sql
-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan;

-- Find unused indexes (zero scans)
SELECT indexrelid::regclass AS index, relid::regclass AS table,
       idx_scan, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- Check if query uses an index
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'a@b.com';
```

## Window Functions

```sql
-- Row number
SELECT name, department,
       ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
FROM employees;

-- Rank (ties get same rank, gaps after)
SELECT name, salary,
       RANK() OVER (ORDER BY salary DESC) AS rank
FROM employees;

-- Dense rank (no gaps)
SELECT name, salary,
       DENSE_RANK() OVER (ORDER BY salary DESC) AS rank
FROM employees;

-- Running total
SELECT date, amount,
       SUM(amount) OVER (ORDER BY date) AS running_total
FROM transactions;

-- Moving average
SELECT date, amount,
       AVG(amount) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg
FROM daily_sales;

-- Lead and lag (look ahead/behind)
SELECT date, amount,
       LAG(amount) OVER (ORDER BY date) AS prev_amount,
       LEAD(amount) OVER (ORDER BY date) AS next_amount
FROM transactions;

-- First/last in partition
SELECT department, name, salary,
       FIRST_VALUE(name) OVER (PARTITION BY department ORDER BY salary DESC) AS top_earner,
       LAST_VALUE(name) OVER (PARTITION BY department ORDER BY salary DESC
         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS lowest_earner
FROM employees;

-- Ntile (divide into buckets)
SELECT name, salary,
       NTILE(4) OVER (ORDER BY salary) AS quartile
FROM employees;
```

## JSON and JSONB

```sql
-- Access field (returns JSON)
SELECT data->'name' FROM events;

-- Access field (returns text)
SELECT data->>'name' FROM events;

-- Nested access
SELECT data->'address'->>'city' FROM users;

-- Array element
SELECT data->0 FROM events;

-- Path access
SELECT data #> '{address,city}' FROM users;
SELECT data #>> '{address,city}' FROM users;  -- as text

-- Contains
SELECT * FROM events WHERE data @> '{"type": "click"}';

-- Key exists
SELECT * FROM events WHERE data ? 'email';

-- Any key exists
SELECT * FROM events WHERE data ?| array['email', 'phone'];

-- All keys exist
SELECT * FROM events WHERE data ?& array['email', 'phone'];

-- Build JSON
SELECT jsonb_build_object('name', name, 'age', age) FROM users;

-- Aggregate to JSON array
SELECT jsonb_agg(name) FROM users;

-- Aggregate to JSON object
SELECT jsonb_object_agg(id, name) FROM users;

-- Expand JSON object to rows
SELECT * FROM jsonb_each('{"a": 1, "b": 2}');
SELECT * FROM jsonb_each_text('{"a": 1, "b": 2}');

-- Update JSONB field
UPDATE users SET data = jsonb_set(data, '{address,city}', '"NYC"');

-- Remove key
UPDATE users SET data = data - 'temporary_field';
```

## Admin Queries

### Table and Database Size

```sql
-- Database size
SELECT pg_size_pretty(pg_database_size('mydb'));

-- Table sizes (with indexes)
SELECT relname, pg_size_pretty(pg_total_relation_size(oid)) AS total,
       pg_size_pretty(pg_relation_size(oid)) AS table_only,
       pg_size_pretty(pg_indexes_size(oid)) AS indexes
FROM pg_class
WHERE relkind = 'r'
ORDER BY pg_total_relation_size(oid) DESC
LIMIT 20;

-- Schema size
SELECT schemaname,
       pg_size_pretty(SUM(pg_total_relation_size(schemaname || '.' || tablename))) AS size
FROM pg_tables
GROUP BY schemaname
ORDER BY SUM(pg_total_relation_size(schemaname || '.' || tablename)) DESC;
```

### Active Queries and Locks

```sql
-- Running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration,
       query, state
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;

-- Kill a query
SELECT pg_cancel_backend(pid);    -- Graceful
SELECT pg_terminate_backend(pid); -- Force

-- Blocking locks
SELECT blocked.pid AS blocked_pid,
       blocked.query AS blocked_query,
       blocking.pid AS blocking_pid,
       blocking.query AS blocking_query
FROM pg_stat_activity AS blocked
JOIN pg_locks AS blocked_locks ON blocked.pid = blocked_locks.pid
JOIN pg_locks AS blocking_locks ON blocked_locks.locktype = blocking_locks.locktype
  AND blocked_locks.relation = blocking_locks.relation
  AND blocked_locks.pid != blocking_locks.pid
JOIN pg_stat_activity AS blocking ON blocking_locks.pid = blocking.pid
WHERE NOT blocked_locks.granted;
```

### Statistics and Maintenance

```sql
-- Table stats
SELECT relname, n_live_tup, n_dead_tup,
       last_vacuum, last_autovacuum, last_analyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- Cache hit ratio (should be > 99%)
SELECT
  sum(heap_blks_read) AS heap_read,
  sum(heap_blks_hit) AS heap_hit,
  sum(heap_blks_hit) / GREATEST(sum(heap_blks_hit) + sum(heap_blks_read), 1) AS ratio
FROM pg_statio_user_tables;

-- Index hit ratio
SELECT relname,
       idx_blks_hit / GREATEST(idx_blks_hit + idx_blks_read, 1) AS hit_ratio
FROM pg_statio_user_indexes
ORDER BY idx_blks_hit + idx_blks_read DESC;

-- Manual maintenance
VACUUM tablename;            -- Reclaim dead tuples
VACUUM FULL tablename;       -- Reclaim + compact (locks table)
ANALYZE tablename;           -- Update statistics
VACUUM ANALYZE tablename;    -- Both
```

### Roles and Permissions

```sql
-- Create role
CREATE ROLE readonly LOGIN PASSWORD 'pass';

-- Grant
GRANT CONNECT ON DATABASE mydb TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

-- Default privileges (for future tables)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO readonly;

-- Revoke
REVOKE ALL ON DATABASE mydb FROM readonly;

-- Check permissions
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'users';
```

## See Also

- [SQL](sql.md) — Portable SQL syntax: joins, CTEs, window functions
- [Performance](performance.md) — Profiling and benchmarking, including database
  queries
- [Docker](docker.md) — Running PostgreSQL in containers
- [Kubernetes](k8s.md) — Deploying PostgreSQL on k8s
- [Data Models Lesson Plan](../learn/data-models-lesson-plan.md) — ER diagrams
  to model selection
