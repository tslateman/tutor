# PostgreSQL Cheat Sheet

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

| Command         | Description                 |
| --------------- | --------------------------- |
| `\l`            | List databases              |
| `\c dbname`     | Connect to database         |
| `\dt`           | List tables                 |
| `\dt+`          | List tables with size       |
| `\d tablename`  | Describe table              |
| `\d+ tablename` | Describe table with details |
| `\di`           | List indexes                |
| `\dv`           | List views                  |
| `\df`           | List functions              |
| `\dn`           | List schemas                |
| `\du`           | List users/roles            |
| `\x`            | Toggle expanded display     |
| `\timing`       | Toggle query timing         |
| `\e`            | Edit in $EDITOR             |
| `\i file.sql`   | Execute file                |
| `\o file`       | Output to file              |
| `\copy`         | Copy data                   |
| `\q`            | Quit                        |

## Database Operations

```sql
-- Create database
CREATE DATABASE mydb;
CREATE DATABASE mydb OWNER myuser;

-- Drop database
DROP DATABASE mydb;
DROP DATABASE IF EXISTS mydb;

-- Rename database
ALTER DATABASE oldname RENAME TO newname;
```

## Table Operations

```sql
-- Create table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100),
    age INTEGER CHECK (age >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create table with foreign key
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    total DECIMAL(10, 2) NOT NULL
);

-- Alter table
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
ALTER TABLE users DROP COLUMN phone;
ALTER TABLE users ALTER COLUMN name TYPE TEXT;
ALTER TABLE users ALTER COLUMN email SET NOT NULL;
ALTER TABLE users ALTER COLUMN name SET DEFAULT 'Anonymous';
ALTER TABLE users RENAME COLUMN name TO full_name;
ALTER TABLE users RENAME TO customers;

-- Drop table
DROP TABLE users;
DROP TABLE IF EXISTS users CASCADE;

-- Truncate (faster than DELETE)
TRUNCATE TABLE users;
TRUNCATE TABLE users RESTART IDENTITY CASCADE;
```

## Data Types

```sql
-- Numeric
INTEGER, BIGINT, SMALLINT
DECIMAL(precision, scale), NUMERIC
REAL, DOUBLE PRECISION
SERIAL, BIGSERIAL                -- Auto-increment

-- Character
VARCHAR(n), CHAR(n), TEXT

-- Date/Time
DATE, TIME, TIMESTAMP, TIMESTAMPTZ
INTERVAL

-- Boolean
BOOLEAN

-- JSON
JSON, JSONB                      -- JSONB is binary, faster queries

-- Arrays
INTEGER[], TEXT[]

-- UUID
UUID

-- Network
INET, CIDR, MACADDR
```

## CRUD Operations

```sql
-- Insert
INSERT INTO users (email, name) VALUES ('a@b.com', 'Alice');
INSERT INTO users (email, name) VALUES
    ('b@c.com', 'Bob'),
    ('c@d.com', 'Charlie');
INSERT INTO users (email, name) VALUES ('d@e.com', 'Dave')
    RETURNING id, email;

-- Select
SELECT * FROM users;
SELECT id, name FROM users WHERE age > 18;
SELECT DISTINCT city FROM users;
SELECT * FROM users ORDER BY created_at DESC LIMIT 10 OFFSET 20;

-- Update
UPDATE users SET name = 'Alice Smith' WHERE id = 1;
UPDATE users SET age = age + 1 WHERE birthday = CURRENT_DATE
    RETURNING *;

-- Delete
DELETE FROM users WHERE id = 1;
DELETE FROM users WHERE created_at < NOW() - INTERVAL '1 year';

-- Upsert
INSERT INTO users (email, name) VALUES ('a@b.com', 'Alice')
    ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO users (email, name) VALUES ('a@b.com', 'Alice')
    ON CONFLICT (email) DO NOTHING;
```

## Filtering & Operators

```sql
-- Comparison
WHERE age = 25
WHERE age <> 25              -- Not equal
WHERE age > 18 AND age < 65
WHERE age BETWEEN 18 AND 65
WHERE name IS NULL
WHERE name IS NOT NULL

-- Pattern matching
WHERE name LIKE 'A%'         -- Starts with A
WHERE name LIKE '%son'       -- Ends with son
WHERE name LIKE '%ali%'      -- Contains ali
WHERE name ILIKE '%ALI%'     -- Case insensitive
WHERE name ~ '^[A-Z]'        -- Regex

-- Lists
WHERE id IN (1, 2, 3)
WHERE id NOT IN (SELECT user_id FROM banned)
WHERE EXISTS (SELECT 1 FROM orders WHERE orders.user_id = users.id)

-- Arrays
WHERE tags @> ARRAY['urgent']        -- Contains
WHERE tags && ARRAY['a', 'b']        -- Overlaps
WHERE 'value' = ANY(tags)

-- JSON/JSONB
WHERE data->>'name' = 'Alice'        -- Text extraction
WHERE data->'address'->>'city' = 'NYC'
WHERE data @> '{"active": true}'     -- Contains
WHERE data ? 'key'                   -- Key exists
WHERE data ?| ARRAY['a', 'b']        -- Any key exists
WHERE data ?& ARRAY['a', 'b']        -- All keys exist
```

## Joins

```sql
-- Inner join
SELECT u.name, o.total
FROM users u
INNER JOIN orders o ON u.id = o.user_id;

-- Left join (all from left, matching from right)
SELECT u.name, o.total
FROM users u
LEFT JOIN orders o ON u.id = o.user_id;

-- Right join
SELECT u.name, o.total
FROM users u
RIGHT JOIN orders o ON u.id = o.user_id;

-- Full outer join
SELECT u.name, o.total
FROM users u
FULL OUTER JOIN orders o ON u.id = o.user_id;

-- Cross join (cartesian product)
SELECT * FROM sizes CROSS JOIN colors;

-- Self join
SELECT e.name, m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

## Aggregation

```sql
-- Basic aggregates
SELECT COUNT(*) FROM users;
SELECT COUNT(DISTINCT city) FROM users;
SELECT SUM(total), AVG(total), MIN(total), MAX(total) FROM orders;

-- Group by
SELECT city, COUNT(*) as user_count
FROM users
GROUP BY city
ORDER BY user_count DESC;

-- Having (filter after grouping)
SELECT user_id, SUM(total) as total_spent
FROM orders
GROUP BY user_id
HAVING SUM(total) > 1000;

-- String aggregation
SELECT user_id, STRING_AGG(product_name, ', ')
FROM order_items
GROUP BY user_id;

-- Array aggregation
SELECT user_id, ARRAY_AGG(product_id)
FROM order_items
GROUP BY user_id;
```

## Window Functions

```sql
-- Row number
SELECT name, department,
       ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) as rank
FROM employees;

-- Rank (ties get same rank, gaps after)
SELECT name, RANK() OVER (ORDER BY score DESC) FROM players;

-- Dense rank (no gaps)
SELECT name, DENSE_RANK() OVER (ORDER BY score DESC) FROM players;

-- Running total
SELECT date, amount,
       SUM(amount) OVER (ORDER BY date) as running_total
FROM transactions;

-- Moving average
SELECT date, amount,
       AVG(amount) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
FROM transactions;

-- Lead/Lag
SELECT date, amount,
       LAG(amount) OVER (ORDER BY date) as prev_amount,
       LEAD(amount) OVER (ORDER BY date) as next_amount
FROM transactions;

-- First/Last value
SELECT name, department,
       FIRST_VALUE(name) OVER (PARTITION BY department ORDER BY salary DESC)
FROM employees;
```

## CTEs (Common Table Expressions)

```sql
-- Basic CTE
WITH active_users AS (
    SELECT * FROM users WHERE active = true
)
SELECT * FROM active_users WHERE created_at > '2024-01-01';

-- Multiple CTEs
WITH
    recent_orders AS (
        SELECT * FROM orders WHERE created_at > NOW() - INTERVAL '30 days'
    ),
    high_value AS (
        SELECT * FROM recent_orders WHERE total > 100
    )
SELECT user_id, COUNT(*) FROM high_value GROUP BY user_id;

-- Recursive CTE
WITH RECURSIVE subordinates AS (
    SELECT id, name, manager_id FROM employees WHERE id = 1
    UNION ALL
    SELECT e.id, e.name, e.manager_id
    FROM employees e
    INNER JOIN subordinates s ON e.manager_id = s.id
)
SELECT * FROM subordinates;
```

## Indexes

```sql
-- Create index
CREATE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_name ON users(name) WHERE active = true;  -- Partial

-- Composite index
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at DESC);

-- Expression index
CREATE INDEX idx_users_lower_email ON users(LOWER(email));

-- GIN index (for JSONB, arrays, full-text)
CREATE INDEX idx_users_data ON users USING GIN(data);
CREATE INDEX idx_posts_search ON posts USING GIN(to_tsvector('english', content));

-- Drop index
DROP INDEX idx_users_email;

-- Reindex
REINDEX INDEX idx_users_email;
REINDEX TABLE users;
```

## Transactions

```sql
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

-- Rollback
BEGIN;
    DELETE FROM users;
ROLLBACK;

-- Savepoints
BEGIN;
    INSERT INTO users (name) VALUES ('Alice');
    SAVEPOINT my_savepoint;
    INSERT INTO users (name) VALUES ('Bob');
    ROLLBACK TO my_savepoint;  -- Only Bob's insert is rolled back
COMMIT;
```

## Views

```sql
-- Create view
CREATE VIEW active_orders AS
SELECT o.*, u.name as user_name
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE o.status = 'active';

-- Materialized view (cached)
CREATE MATERIALIZED VIEW monthly_stats AS
SELECT DATE_TRUNC('month', created_at) as month, COUNT(*), SUM(total)
FROM orders
GROUP BY 1;

-- Refresh materialized view
REFRESH MATERIALIZED VIEW monthly_stats;
REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_stats;  -- Non-blocking

-- Drop view
DROP VIEW active_orders;
DROP MATERIALIZED VIEW monthly_stats;
```

## Users & Permissions

```sql
-- Create user
CREATE USER myuser WITH PASSWORD 'secret';
CREATE ROLE myuser WITH LOGIN PASSWORD 'secret';

-- Grant permissions
GRANT SELECT ON users TO myuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO myuser;
GRANT USAGE ON SCHEMA myschema TO myuser;

-- Revoke permissions
REVOKE DELETE ON users FROM myuser;

-- Change password
ALTER USER myuser WITH PASSWORD 'newpassword';

-- Drop user
DROP USER myuser;
```

## Useful Queries

```sql
-- Table sizes
SELECT relname, pg_size_pretty(pg_total_relation_size(relid))
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- Database size
SELECT pg_size_pretty(pg_database_size('dbname'));

-- Active connections
SELECT * FROM pg_stat_activity WHERE state = 'active';

-- Kill connection
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid = 12345;

-- Lock info
SELECT * FROM pg_locks WHERE NOT granted;

-- Index usage
SELECT relname, idx_scan, seq_scan
FROM pg_stat_user_tables
ORDER BY seq_scan DESC;

-- Slow queries (requires pg_stat_statements)
SELECT query, calls, mean_time, total_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Explain query
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'a@b.com';

-- Running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;
```

## Backup & Restore

```bash
# Dump database
pg_dump dbname > backup.sql
pg_dump -Fc dbname > backup.dump    # Custom format (compressed)
pg_dump -t tablename dbname > table.sql

# Restore
psql dbname < backup.sql
pg_restore -d dbname backup.dump

# Dump all databases
pg_dumpall > all_databases.sql
```

## See Also

- [SQL](sql.md) — General SQL syntax portable across databases
