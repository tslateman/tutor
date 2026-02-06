# SQL Cheat Sheet

General SQL syntax (portable across databases). See `postgres-cheatsheet.md` for
PostgreSQL-specific features.

## Basic Queries

### SELECT

```sql
-- All columns
SELECT * FROM users;

-- Specific columns
SELECT name, email FROM users;

-- With alias
SELECT name AS username, email AS contact FROM users;

-- Distinct values
SELECT DISTINCT city FROM users;

-- Calculated columns
SELECT name, price * quantity AS total FROM orders;

-- Limit results
SELECT * FROM users LIMIT 10;
SELECT * FROM users LIMIT 10 OFFSET 20;  -- Skip first 20
```

### WHERE (Filtering)

```sql
-- Comparison operators
SELECT * FROM users WHERE age = 25;
SELECT * FROM users WHERE age <> 25;      -- Not equal
SELECT * FROM users WHERE age != 25;      -- Not equal (alternate)
SELECT * FROM users WHERE age > 18;
SELECT * FROM users WHERE age >= 18;
SELECT * FROM users WHERE age < 65;
SELECT * FROM users WHERE age <= 65;

-- Multiple conditions
SELECT * FROM users WHERE age > 18 AND active = true;
SELECT * FROM users WHERE role = 'admin' OR role = 'moderator';
SELECT * FROM users WHERE NOT deleted;

-- Range
SELECT * FROM users WHERE age BETWEEN 18 AND 65;

-- List membership
SELECT * FROM users WHERE country IN ('US', 'UK', 'CA');
SELECT * FROM users WHERE country NOT IN ('US', 'UK');

-- NULL handling
SELECT * FROM users WHERE phone IS NULL;
SELECT * FROM users WHERE phone IS NOT NULL;

-- Pattern matching
SELECT * FROM users WHERE name LIKE 'A%';      -- Starts with A
SELECT * FROM users WHERE name LIKE '%son';    -- Ends with son
SELECT * FROM users WHERE name LIKE '%ali%';   -- Contains ali
SELECT * FROM users WHERE name LIKE '_ohn';    -- John, Bohn, etc.
SELECT * FROM users WHERE email LIKE '%@gmail.com';
```

### ORDER BY

```sql
SELECT * FROM users ORDER BY name;              -- Ascending (default)
SELECT * FROM users ORDER BY created_at DESC;   -- Descending
SELECT * FROM users ORDER BY country, name;     -- Multiple columns
SELECT * FROM users ORDER BY country DESC, name ASC;
SELECT * FROM users ORDER BY 2;                 -- By column position
```

## Aggregation

### Aggregate Functions

```sql
SELECT COUNT(*) FROM users;                     -- Count all rows
SELECT COUNT(phone) FROM users;                 -- Count non-null
SELECT COUNT(DISTINCT country) FROM users;      -- Count unique
SELECT SUM(amount) FROM orders;
SELECT AVG(amount) FROM orders;
SELECT MIN(price) FROM products;
SELECT MAX(price) FROM products;
```

### GROUP BY

```sql
-- Count users per country
SELECT country, COUNT(*) AS user_count
FROM users
GROUP BY country;

-- Multiple aggregations
SELECT
    category,
    COUNT(*) AS product_count,
    AVG(price) AS avg_price,
    SUM(stock) AS total_stock
FROM products
GROUP BY category;

-- Group by multiple columns
SELECT country, city, COUNT(*)
FROM users
GROUP BY country, city;
```

### HAVING (Filter Groups)

```sql
-- Countries with more than 100 users
SELECT country, COUNT(*) AS user_count
FROM users
GROUP BY country
HAVING COUNT(*) > 100;

-- Categories with average price over $50
SELECT category, AVG(price) AS avg_price
FROM products
GROUP BY category
HAVING AVG(price) > 50;
```

## Joins

### INNER JOIN

```sql
-- Only matching rows from both tables
SELECT users.name, orders.total
FROM users
INNER JOIN orders ON users.id = orders.user_id;

-- With aliases
SELECT u.name, o.total
FROM users u
JOIN orders o ON u.id = o.user_id;
```

### LEFT JOIN (LEFT OUTER JOIN)

```sql
-- All users, with orders if they exist
SELECT u.name, o.total
FROM users u
LEFT JOIN orders o ON u.id = o.user_id;

-- Find users without orders
SELECT u.name
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE o.id IS NULL;
```

### RIGHT JOIN (RIGHT OUTER JOIN)

```sql
-- All orders, with user info if exists
SELECT u.name, o.total
FROM users u
RIGHT JOIN orders o ON u.id = o.user_id;
```

### FULL OUTER JOIN

```sql
-- All rows from both tables
SELECT u.name, o.total
FROM users u
FULL OUTER JOIN orders o ON u.id = o.user_id;
```

### CROSS JOIN

```sql
-- Cartesian product (all combinations)
SELECT colors.name, sizes.name
FROM colors
CROSS JOIN sizes;
```

### Self Join

```sql
-- Employees with their managers
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

### Multiple Joins

```sql
SELECT
    o.id AS order_id,
    u.name AS customer,
    p.name AS product
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id;
```

## Subqueries

### In WHERE Clause

```sql
-- Users who have placed orders
SELECT * FROM users
WHERE id IN (SELECT DISTINCT user_id FROM orders);

-- Products more expensive than average
SELECT * FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- Orders from users in US
SELECT * FROM orders
WHERE user_id IN (
    SELECT id FROM users WHERE country = 'US'
);
```

### In FROM Clause (Derived Table)

```sql
SELECT category, avg_price
FROM (
    SELECT category, AVG(price) AS avg_price
    FROM products
    GROUP BY category
) AS category_prices
WHERE avg_price > 50;
```

### Correlated Subqueries

```sql
-- Users with above-average spending in their country
SELECT * FROM users u
WHERE (
    SELECT SUM(amount) FROM orders
    WHERE user_id = u.id
) > (
    SELECT AVG(total_spent) FROM (
        SELECT SUM(amount) AS total_spent
        FROM orders o
        JOIN users u2 ON o.user_id = u2.id
        WHERE u2.country = u.country
        GROUP BY user_id
    ) AS country_avg
);

-- Simpler: employees earning more than dept average
SELECT * FROM employees e
WHERE salary > (
    SELECT AVG(salary) FROM employees
    WHERE department_id = e.department_id
);
```

### EXISTS

```sql
-- Users who have at least one order
SELECT * FROM users u
WHERE EXISTS (
    SELECT 1 FROM orders WHERE user_id = u.id
);

-- Users with no orders
SELECT * FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM orders WHERE user_id = u.id
);
```

## Set Operations

```sql
-- Combine results (remove duplicates)
SELECT name FROM customers
UNION
SELECT name FROM suppliers;

-- Combine results (keep duplicates)
SELECT name FROM customers
UNION ALL
SELECT name FROM suppliers;

-- Common to both
SELECT name FROM customers
INTERSECT
SELECT name FROM suppliers;

-- In first but not second
SELECT name FROM customers
EXCEPT
SELECT name FROM suppliers;
```

## CASE Expressions

```sql
-- Simple CASE
SELECT name,
    CASE status
        WHEN 'A' THEN 'Active'
        WHEN 'I' THEN 'Inactive'
        WHEN 'P' THEN 'Pending'
        ELSE 'Unknown'
    END AS status_label
FROM users;

-- Searched CASE
SELECT name, price,
    CASE
        WHEN price < 10 THEN 'Budget'
        WHEN price < 50 THEN 'Standard'
        WHEN price < 100 THEN 'Premium'
        ELSE 'Luxury'
    END AS tier
FROM products;

-- In aggregation
SELECT
    COUNT(CASE WHEN status = 'active' THEN 1 END) AS active_count,
    COUNT(CASE WHEN status = 'inactive' THEN 1 END) AS inactive_count
FROM users;
```

## Common Table Expressions (CTEs)

```sql
-- Basic CTE
WITH active_users AS (
    SELECT * FROM users WHERE active = true
)
SELECT * FROM active_users WHERE created_at > '2024-01-01';

-- Multiple CTEs
WITH
    recent_orders AS (
        SELECT * FROM orders
        WHERE created_at > CURRENT_DATE - INTERVAL '30' DAY
    ),
    high_value AS (
        SELECT * FROM recent_orders WHERE total > 100
    )
SELECT user_id, COUNT(*), SUM(total)
FROM high_value
GROUP BY user_id;

-- Recursive CTE (hierarchical data)
WITH RECURSIVE subordinates AS (
    -- Base case
    SELECT id, name, manager_id, 0 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case
    SELECT e.id, e.name, e.manager_id, s.level + 1
    FROM employees e
    JOIN subordinates s ON e.manager_id = s.id
)
SELECT * FROM subordinates ORDER BY level, name;
```

## Window Functions

```sql
-- Row number
SELECT name, department,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS rank
FROM employees;

-- Row number within partition
SELECT name, department,
    ROW_NUMBER() OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) AS dept_rank
FROM employees;

-- Rank (with gaps for ties)
SELECT name, score,
    RANK() OVER (ORDER BY score DESC) AS rank
FROM players;

-- Dense rank (no gaps)
SELECT name, score,
    DENSE_RANK() OVER (ORDER BY score DESC) AS rank
FROM players;

-- Running total
SELECT date, amount,
    SUM(amount) OVER (ORDER BY date) AS running_total
FROM transactions;

-- Running total within partition
SELECT date, category, amount,
    SUM(amount) OVER (
        PARTITION BY category
        ORDER BY date
    ) AS category_running_total
FROM transactions;

-- Moving average
SELECT date, amount,
    AVG(amount) OVER (
        ORDER BY date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7day
FROM transactions;

-- Previous/next row values
SELECT date, amount,
    LAG(amount, 1) OVER (ORDER BY date) AS prev_amount,
    LEAD(amount, 1) OVER (ORDER BY date) AS next_amount
FROM transactions;

-- First/last in partition
SELECT name, department, salary,
    FIRST_VALUE(name) OVER (
        PARTITION BY department
        ORDER BY salary DESC
    ) AS highest_paid
FROM employees;

-- Percentile
SELECT name, salary,
    NTILE(4) OVER (ORDER BY salary) AS quartile
FROM employees;
```

## Data Modification

### INSERT

```sql
-- Single row
INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com');

-- Multiple rows
INSERT INTO users (name, email) VALUES
    ('Bob', 'bob@example.com'),
    ('Charlie', 'charlie@example.com');

-- Insert from select
INSERT INTO archive_users (name, email)
SELECT name, email FROM users WHERE deleted = true;

-- Insert with default values
INSERT INTO users (name) VALUES ('Dave');  -- Other columns get defaults
```

### UPDATE

```sql
-- Update single row
UPDATE users SET name = 'Alice Smith' WHERE id = 1;

-- Update multiple columns
UPDATE users
SET name = 'Alice Smith', email = 'alice.smith@example.com'
WHERE id = 1;

-- Update based on calculation
UPDATE products SET price = price * 1.1;  -- 10% increase

-- Update with subquery
UPDATE orders
SET status = 'cancelled'
WHERE user_id IN (SELECT id FROM users WHERE deleted = true);

-- Update with join (syntax varies by database)
UPDATE orders o
SET o.status = 'vip'
FROM users u
WHERE o.user_id = u.id AND u.tier = 'premium';
```

### DELETE

```sql
-- Delete specific rows
DELETE FROM users WHERE id = 1;

-- Delete with condition
DELETE FROM sessions WHERE expires_at < CURRENT_TIMESTAMP;

-- Delete with subquery
DELETE FROM orders
WHERE user_id IN (SELECT id FROM users WHERE deleted = true);

-- Delete all rows (use TRUNCATE for better performance)
DELETE FROM temp_data;
TRUNCATE TABLE temp_data;  -- Faster, resets auto-increment
```

## Table Operations

### CREATE TABLE

```sql
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,  -- MySQL
    -- id SERIAL PRIMARY KEY,           -- PostgreSQL
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    age INT CHECK (age >= 0),
    country VARCHAR(50) DEFAULT 'US',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- With foreign key
CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    total DECIMAL(10, 2),
    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
```

### ALTER TABLE

```sql
-- Add column
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Drop column
ALTER TABLE users DROP COLUMN phone;

-- Modify column
ALTER TABLE users MODIFY COLUMN name VARCHAR(200);  -- MySQL
ALTER TABLE users ALTER COLUMN name TYPE VARCHAR(200);  -- PostgreSQL

-- Rename column
ALTER TABLE users RENAME COLUMN name TO full_name;

-- Add constraint
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);

-- Drop constraint
ALTER TABLE users DROP CONSTRAINT unique_email;

-- Rename table
ALTER TABLE users RENAME TO customers;
```

### DROP TABLE

```sql
DROP TABLE users;
DROP TABLE IF EXISTS users;
DROP TABLE users CASCADE;  -- Also drop dependent objects
```

## Indexes

```sql
-- Create index
CREATE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_users_email ON users(email);

-- Composite index
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at);

-- Drop index
DROP INDEX idx_users_email;
DROP INDEX idx_users_email ON users;  -- MySQL syntax
```

## Views

```sql
-- Create view
CREATE VIEW active_users AS
SELECT id, name, email
FROM users
WHERE active = true;

-- Use view like a table
SELECT * FROM active_users WHERE name LIKE 'A%';

-- Replace view
CREATE OR REPLACE VIEW active_users AS
SELECT id, name, email, created_at
FROM users
WHERE active = true;

-- Drop view
DROP VIEW active_users;
DROP VIEW IF EXISTS active_users;
```

## Transactions

```sql
-- Basic transaction
BEGIN TRANSACTION;  -- or just BEGIN, or START TRANSACTION
    UPDATE accounts SET balance = balance - 100 WHERE id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

-- Rollback on error
BEGIN;
    DELETE FROM users WHERE active = false;
    -- Something went wrong
ROLLBACK;

-- Savepoints
BEGIN;
    INSERT INTO users (name) VALUES ('Alice');
    SAVEPOINT sp1;
    INSERT INTO users (name) VALUES ('Bob');
    ROLLBACK TO sp1;  -- Only Bob's insert is rolled back
COMMIT;
```

## Useful Patterns

### Pagination

```sql
-- Offset-based (simple but slow for large offsets)
SELECT * FROM users ORDER BY id LIMIT 20 OFFSET 40;

-- Keyset pagination (faster for large datasets)
SELECT * FROM users
WHERE id > 1000
ORDER BY id
LIMIT 20;
```

### Upsert (Insert or Update)

```sql
-- MySQL
INSERT INTO users (email, name) VALUES ('a@b.com', 'Alice')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- PostgreSQL
INSERT INTO users (email, name) VALUES ('a@b.com', 'Alice')
ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name;

-- SQLite
INSERT OR REPLACE INTO users (email, name) VALUES ('a@b.com', 'Alice');
```

### Find Duplicates

```sql
SELECT email, COUNT(*) AS count
FROM users
GROUP BY email
HAVING COUNT(*) > 1;
```

### Get Nth Highest Value

```sql
-- 3rd highest salary
SELECT DISTINCT salary
FROM employees
ORDER BY salary DESC
LIMIT 1 OFFSET 2;

-- Using window function
SELECT * FROM (
    SELECT *, DENSE_RANK() OVER (ORDER BY salary DESC) AS rank
    FROM employees
) ranked
WHERE rank = 3;
```

### Running Difference

```sql
SELECT date, amount,
    amount - LAG(amount) OVER (ORDER BY date) AS daily_change
FROM sales;
```

### Pivot (Cross-Tab)

```sql
-- Manual pivot
SELECT
    product_id,
    SUM(CASE WHEN month = 'Jan' THEN sales END) AS jan,
    SUM(CASE WHEN month = 'Feb' THEN sales END) AS feb,
    SUM(CASE WHEN month = 'Mar' THEN sales END) AS mar
FROM monthly_sales
GROUP BY product_id;
```

## See Also

- [PostgreSQL](postgres.md) — PostgreSQL-specific features (JSONB, arrays, GIN
  indexes)
