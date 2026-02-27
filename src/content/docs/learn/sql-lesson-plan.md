---
title: "SQL Lesson Plan"
description:
  Eight lessons from SELECT to window functions, covering joins, aggregation,
  CTEs, query planning, and optimization.
---

A progressive curriculum to master SQL through hands-on query writing.

<!-- prettier-ignore -->
:::note[Prerequisites]
Comfortable with a terminal and a running database.
Install [PostgreSQL](../how/postgres.md) or use SQLite.
Basic familiarity with [data modeling](data-models-lesson-plan.md) helps but is not required.
:::

## Sample Schema

Every exercise uses this e-commerce database. Create it once and build on it
throughout all eight lessons.

```sql
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    country VARCHAR(50) DEFAULT 'US',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    stock INT NOT NULL DEFAULT 0
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(id),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(id),
    product_id INT NOT NULL REFERENCES products(id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL
);

-- Seed data
INSERT INTO customers (name, email, country) VALUES
    ('Alice', 'alice@example.com', 'US'),
    ('Bob', 'bob@example.com', 'UK'),
    ('Charlie', 'charlie@example.com', 'US'),
    ('Diana', 'diana@example.com', 'CA'),
    ('Eve', 'eve@example.com', 'UK');

INSERT INTO products (name, category, price, stock) VALUES
    ('Laptop', 'Electronics', 999.99, 50),
    ('Keyboard', 'Electronics', 79.99, 200),
    ('Notebook', 'Office', 4.99, 500),
    ('Desk Lamp', 'Office', 34.99, 150),
    ('Headphones', 'Electronics', 149.99, 100),
    ('Pen Set', 'Office', 12.99, 300),
    ('Monitor', 'Electronics', 449.99, 75),
    ('Chair', 'Furniture', 299.99, 40);

INSERT INTO orders (customer_id, status, created_at) VALUES
    (1, 'completed', '2024-01-15'),
    (1, 'completed', '2024-02-20'),
    (2, 'completed', '2024-01-22'),
    (3, 'pending', '2024-03-01'),
    (4, 'completed', '2024-02-10'),
    (2, 'cancelled', '2024-03-05'),
    (5, 'completed', '2024-01-30'),
    (1, 'pending', '2024-03-10');

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 999.99),
    (1, 2, 2, 79.99),
    (2, 3, 10, 4.99),
    (2, 5, 1, 149.99),
    (3, 1, 1, 999.99),
    (3, 4, 3, 34.99),
    (4, 7, 2, 449.99),
    (5, 8, 1, 299.99),
    (5, 6, 5, 12.99),
    (6, 2, 1, 79.99),
    (7, 5, 2, 149.99),
    (7, 3, 20, 4.99),
    (8, 1, 1, 999.99);
```

---

## Lesson 1: First Queries

**Goal:** Retrieve and shape data with SELECT, WHERE, ORDER BY, and LIMIT.

### Concepts

SQL reads declaratively: describe _what_ you want, not _how_ to get it. Every
query starts with SELECT. WHERE filters rows. ORDER BY sorts. LIMIT caps output.

### Exercises

1. **Select all customers**

   ```sql
   SELECT * FROM customers;
   SELECT name, email FROM customers;  -- specific columns
   ```

2. **Filter with WHERE**

   ```sql
   -- Customers in the US
   SELECT name, country FROM customers WHERE country = 'US';

   -- Orders placed after February 2024
   SELECT * FROM orders WHERE created_at >= '2024-02-01';

   -- Pending orders
   SELECT * FROM orders WHERE status = 'pending';
   ```

3. **Sort results**

   ```sql
   -- Products cheapest first
   SELECT name, price FROM products ORDER BY price;

   -- Products most expensive first
   SELECT name, price FROM products ORDER BY price DESC;

   -- Multi-column sort: category ascending, then price descending
   SELECT name, category, price FROM products
   ORDER BY category, price DESC;
   ```

4. **Limit output**

   ```sql
   -- Top 3 most expensive products
   SELECT name, price FROM products ORDER BY price DESC LIMIT 3;

   -- Page 2 (items 4-6)
   SELECT name, price FROM products ORDER BY price DESC LIMIT 3 OFFSET 3;
   ```

5. **Use aliases and expressions**

   ```sql
   SELECT
       name AS product_name,
       price,
       stock,
       price * stock AS inventory_value
   FROM products
   ORDER BY inventory_value DESC;
   ```

### Checkpoint

Write a query that returns the 5 most expensive products with columns
`product_name`, `category`, and `price`. Verify the output matches your
expectations.

---

## Lesson 2: Filtering and Sorting

**Goal:** Master comparison operators, pattern matching, and NULL handling.

### Concepts

WHERE supports more than equality. BETWEEN tests ranges. IN tests set
membership. LIKE matches patterns. IS NULL tests for missing data -- never use
`= NULL`, which always returns false because NULL represents unknown.

### Exercises

1. **Range and set operators**

   ```sql
   -- Products between $10 and $100
   SELECT name, price FROM products WHERE price BETWEEN 10 AND 100;

   -- Customers in US or UK
   SELECT name, country FROM customers WHERE country IN ('US', 'UK');

   -- Products NOT in Office category
   SELECT name, category FROM products WHERE category NOT IN ('Office');
   ```

2. **Pattern matching with LIKE**

   ```sql
   -- Names starting with 'A'
   SELECT name FROM customers WHERE name LIKE 'A%';

   -- Products containing 'board' (case-insensitive with ILIKE in PostgreSQL)
   SELECT name FROM products WHERE name ILIKE '%board%';

   -- Single character wildcard: names with exactly 3 characters
   SELECT name FROM customers WHERE name LIKE '___';
   ```

3. **NULL handling**

   ```sql
   -- Simulate NULL data
   UPDATE customers SET country = NULL WHERE name = 'Eve';

   -- Find NULLs (= NULL does NOT work)
   SELECT name FROM customers WHERE country IS NULL;
   SELECT name FROM customers WHERE country IS NOT NULL;

   -- COALESCE replaces NULL with a default
   SELECT name, COALESCE(country, 'Unknown') AS country FROM customers;
   ```

4. **Combine conditions**

   ```sql
   -- Electronics under $100
   SELECT name, category, price FROM products
   WHERE category = 'Electronics' AND price < 100;

   -- Completed or pending orders from January
   SELECT * FROM orders
   WHERE status IN ('completed', 'pending')
     AND created_at >= '2024-01-01'
     AND created_at < '2024-02-01';
   ```

5. **DISTINCT and counting**

   ```sql
   -- Unique countries
   SELECT DISTINCT country FROM customers;

   -- Unique categories with product count
   SELECT DISTINCT category FROM products ORDER BY category;
   ```

### Checkpoint

Write a query that finds all electronics products priced between $50 and $500,
sorted by price ascending. Use COALESCE in a separate query to handle a NULL
country field.

---

## Lesson 3: Joins

**Goal:** Combine rows from multiple tables using INNER, LEFT, RIGHT, and FULL
joins.

### Concepts

Joins connect tables on a shared column. INNER JOIN returns only matching rows.
LEFT JOIN returns all rows from the left table plus matches from the right
(NULLs where no match exists). Think of it visually:

```text
INNER JOIN:    LEFT JOIN:     FULL OUTER JOIN:

  ┌───┬───┐    ┌───┬───┐     ┌───┬───┐
  │ A │ B │    │ A │ B │     │ A │ B │
  ├───┼───┤    ├───┼───┤     ├───┼───┤
  │ 1 │ 1 │    │ 1 │ 1 │     │ 1 │ 1 │
  │ 2 │ 2 │    │ 2 │ 2 │     │ 2 │ 2 │
  └───┴───┘    │ 3 │   │     │ 3 │   │
               └───┴───┘     │   │ 4 │
                              └───┴───┘
  Only matches  All from A    All from both
```

### Exercises

1. **INNER JOIN: orders with customer names**

   ```sql
   SELECT o.id AS order_id, c.name, o.status, o.created_at
   FROM orders o
   JOIN customers c ON o.customer_id = c.id;
   ```

2. **LEFT JOIN: all customers, even those without orders**

   ```sql
   SELECT c.name, o.id AS order_id, o.status
   FROM customers c
   LEFT JOIN orders o ON c.id = o.customer_id;
   ```

3. **Find customers who never ordered**

   ```sql
   SELECT c.name, c.email
   FROM customers c
   LEFT JOIN orders o ON c.id = o.customer_id
   WHERE o.id IS NULL;
   ```

4. **Multi-table join: order details**

   ```sql
   -- Full order breakdown: customer, order, product, line total
   SELECT
       c.name AS customer,
       o.id AS order_id,
       p.name AS product,
       oi.quantity,
       oi.unit_price,
       oi.quantity * oi.unit_price AS line_total
   FROM orders o
   JOIN customers c ON o.customer_id = c.id
   JOIN order_items oi ON o.id = oi.order_id
   JOIN products p ON oi.product_id = p.id
   ORDER BY o.id, p.name;
   ```

5. **Self join: compare products in the same category**

   ```sql
   -- Pairs of products in the same category
   SELECT
       a.name AS product_a,
       b.name AS product_b,
       a.category,
       ABS(a.price - b.price) AS price_diff
   FROM products a
   JOIN products b ON a.category = b.category AND a.id < b.id
   ORDER BY a.category, price_diff;
   ```

### Checkpoint

Write a query that lists every order with the customer name, each product
ordered, quantity, and line total. Verify that customers without orders do not
appear (INNER JOIN) or do appear with NULLs (LEFT JOIN).

---

## Lesson 4: Aggregation

**Goal:** Summarize data with GROUP BY, HAVING, and aggregate functions.

### Concepts

Aggregate functions collapse rows: COUNT, SUM, AVG, MIN, MAX. GROUP BY splits
rows into buckets before aggregating. HAVING filters groups (WHERE filters rows
before grouping; HAVING filters after).

```text
Execution order:
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

### Exercises

1. **Basic aggregates**

   ```sql
   SELECT COUNT(*) AS total_orders FROM orders;
   SELECT AVG(price) AS avg_price FROM products;
   SELECT MIN(price) AS cheapest, MAX(price) AS priciest FROM products;
   ```

2. **GROUP BY: orders per customer**

   ```sql
   SELECT
       c.name,
       COUNT(o.id) AS order_count
   FROM customers c
   LEFT JOIN orders o ON c.id = o.customer_id
   GROUP BY c.name
   ORDER BY order_count DESC;
   ```

3. **Revenue per product category**

   ```sql
   SELECT
       p.category,
       SUM(oi.quantity * oi.unit_price) AS revenue,
       SUM(oi.quantity) AS units_sold
   FROM order_items oi
   JOIN products p ON oi.product_id = p.id
   GROUP BY p.category
   ORDER BY revenue DESC;
   ```

4. **HAVING: filter groups**

   ```sql
   -- Customers with more than 1 order
   SELECT c.name, COUNT(o.id) AS order_count
   FROM customers c
   JOIN orders o ON c.id = o.customer_id
   GROUP BY c.name
   HAVING COUNT(o.id) > 1;
   ```

5. **Combine WHERE and HAVING**

   ```sql
   -- Categories with revenue over $200, counting only completed orders
   SELECT
       p.category,
       SUM(oi.quantity * oi.unit_price) AS revenue
   FROM order_items oi
   JOIN products p ON oi.product_id = p.id
   JOIN orders o ON oi.order_id = o.id
   WHERE o.status = 'completed'
   GROUP BY p.category
   HAVING SUM(oi.quantity * oi.unit_price) > 200;
   ```

### Checkpoint

Write a query showing each customer's total spending across all completed
orders. Include only customers who spent more than $100. Verify the totals by
hand against the seed data.

---

## Lesson 5: Subqueries

**Goal:** Nest queries inside other queries for filtering and comparison.

### Concepts

A subquery is a SELECT inside another statement. Scalar subqueries return one
value. IN subqueries return a list. Correlated subqueries reference the outer
query — they run once per outer row, so watch performance. EXISTS tests whether
a subquery returns any rows at all.

### Exercises

1. **Scalar subquery: above-average price**

   ```sql
   SELECT name, price
   FROM products
   WHERE price > (SELECT AVG(price) FROM products);
   ```

2. **IN subquery: customers who ordered**

   ```sql
   SELECT name, email
   FROM customers
   WHERE id IN (SELECT DISTINCT customer_id FROM orders);
   ```

3. **NOT IN: customers who never ordered**

   ```sql
   SELECT name, email
   FROM customers
   WHERE id NOT IN (
       SELECT DISTINCT customer_id FROM orders
   );
   ```

4. **Correlated subquery: each customer's latest order**

   ```sql
   SELECT c.name, o.created_at AS latest_order
   FROM customers c
   JOIN orders o ON c.id = o.customer_id
   WHERE o.created_at = (
       SELECT MAX(o2.created_at)
       FROM orders o2
       WHERE o2.customer_id = c.id
   );
   ```

5. **EXISTS: customers with completed orders**

   ```sql
   -- EXISTS stops scanning after the first match — often faster than IN
   SELECT c.name
   FROM customers c
   WHERE EXISTS (
       SELECT 1 FROM orders o
       WHERE o.customer_id = c.id AND o.status = 'completed'
   );
   ```

6. **Derived table (subquery in FROM)**

   ```sql
   -- Top spending customers
   SELECT customer, total_spent
   FROM (
       SELECT
           c.name AS customer,
           SUM(oi.quantity * oi.unit_price) AS total_spent
       FROM customers c
       JOIN orders o ON c.id = o.customer_id
       JOIN order_items oi ON o.id = oi.order_id
       WHERE o.status = 'completed'
       GROUP BY c.name
   ) AS spending
   WHERE total_spent > 100
   ORDER BY total_spent DESC;
   ```

### Checkpoint

Rewrite exercise 3 using NOT EXISTS instead of NOT IN. Both should return the
same rows. Explain why NOT EXISTS is safer when the subquery might contain
NULLs.

---

## Lesson 6: CTEs and Window Functions

**Goal:** Write readable multi-step queries with CTEs and compute rankings,
running totals, and comparisons with window functions.

### Concepts

A CTE (Common Table Expression) names a subquery with `WITH ... AS`. It improves
readability and allows reuse within the same statement. Window functions compute
a value across a set of rows related to the current row — without collapsing
rows the way GROUP BY does. The `OVER()` clause defines the window.

### Exercises

1. **Basic CTE**

   ```sql
   WITH completed_orders AS (
       SELECT o.id, o.customer_id, o.created_at
       FROM orders o
       WHERE o.status = 'completed'
   )
   SELECT c.name, COUNT(*) AS completed_count
   FROM completed_orders co
   JOIN customers c ON co.customer_id = c.id
   GROUP BY c.name;
   ```

2. **Chained CTEs**

   ```sql
   WITH order_totals AS (
       SELECT
           order_id,
           SUM(quantity * unit_price) AS total
       FROM order_items
       GROUP BY order_id
   ),
   customer_spending AS (
       SELECT
           o.customer_id,
           SUM(ot.total) AS total_spent
       FROM orders o
       JOIN order_totals ot ON o.id = ot.order_id
       WHERE o.status = 'completed'
       GROUP BY o.customer_id
   )
   SELECT c.name, cs.total_spent
   FROM customer_spending cs
   JOIN customers c ON cs.customer_id = c.id
   ORDER BY cs.total_spent DESC;
   ```

3. **ROW_NUMBER: rank products by price within category**

   ```sql
   SELECT
       name,
       category,
       price,
       ROW_NUMBER() OVER (
           PARTITION BY category ORDER BY price DESC
       ) AS rank_in_category
   FROM products;
   ```

4. **RANK and DENSE_RANK**

   ```sql
   -- RANK leaves gaps at ties; DENSE_RANK does not
   SELECT
       name,
       price,
       RANK() OVER (ORDER BY price DESC) AS rank,
       DENSE_RANK() OVER (ORDER BY price DESC) AS dense_rank
   FROM products;
   ```

5. **Running total and LAG/LEAD**

   ```sql
   -- Running order total by date
   WITH daily_orders AS (
       SELECT
           o.created_at::date AS order_date,
           SUM(oi.quantity * oi.unit_price) AS daily_total
       FROM orders o
       JOIN order_items oi ON o.id = oi.order_id
       GROUP BY o.created_at::date
   )
   SELECT
       order_date,
       daily_total,
       SUM(daily_total) OVER (ORDER BY order_date) AS running_total,
       LAG(daily_total) OVER (ORDER BY order_date) AS prev_day,
       daily_total - LAG(daily_total) OVER (ORDER BY order_date) AS day_change
   FROM daily_orders
   ORDER BY order_date;
   ```

6. **Top-N per group**

   ```sql
   -- Most expensive product per category
   WITH ranked AS (
       SELECT
           name,
           category,
           price,
           ROW_NUMBER() OVER (
               PARTITION BY category ORDER BY price DESC
           ) AS rn
       FROM products
   )
   SELECT name, category, price
   FROM ranked
   WHERE rn = 1;
   ```

### Checkpoint

Write a CTE-based query that ranks customers by total spending, then returns
only the top 3. Use ROW_NUMBER with OVER to assign the rank.

---

## Lesson 7: Data Modification

**Goal:** Insert, update, delete, and upsert rows safely using transactions.

### Concepts

SELECT reads; INSERT, UPDATE, DELETE write. Always use WHERE with UPDATE and
DELETE — an unfiltered UPDATE modifies every row. Transactions group statements
into atomic units: either all succeed (COMMIT) or none take effect (ROLLBACK).

### Exercises

1. **INSERT: add a new customer and product**

   ```sql
   INSERT INTO customers (name, email, country)
   VALUES ('Frank', 'frank@example.com', 'DE');

   INSERT INTO products (name, category, price, stock)
   VALUES ('Webcam', 'Electronics', 59.99, 80);
   ```

2. **INSERT from SELECT**

   ```sql
   -- Archive completed orders into a summary table
   CREATE TABLE order_summary (
       customer_name VARCHAR(100),
       order_count INT,
       total_spent DECIMAL(10, 2)
   );

   INSERT INTO order_summary (customer_name, order_count, total_spent)
   SELECT
       c.name,
       COUNT(DISTINCT o.id),
       SUM(oi.quantity * oi.unit_price)
   FROM customers c
   JOIN orders o ON c.id = o.customer_id
   JOIN order_items oi ON o.id = oi.order_id
   WHERE o.status = 'completed'
   GROUP BY c.name;
   ```

3. **UPDATE with conditions**

   ```sql
   -- Mark old pending orders as cancelled
   UPDATE orders
   SET status = 'cancelled'
   WHERE status = 'pending' AND created_at < '2024-03-01';

   -- 10% price increase for Office products
   UPDATE products
   SET price = ROUND(price * 1.10, 2)
   WHERE category = 'Office';
   ```

4. **DELETE safely**

   ```sql
   -- Preview before deleting
   SELECT * FROM orders WHERE status = 'cancelled';

   -- Then delete
   DELETE FROM order_items
   WHERE order_id IN (SELECT id FROM orders WHERE status = 'cancelled');

   DELETE FROM orders WHERE status = 'cancelled';
   ```

5. **Transactions**

   ```sql
   -- Transfer stock between products atomically
   BEGIN;
       UPDATE products SET stock = stock - 10 WHERE name = 'Keyboard';
       UPDATE products SET stock = stock + 10 WHERE name = 'Webcam';

       -- Verify before committing
       SELECT name, stock FROM products WHERE name IN ('Keyboard', 'Webcam');
   COMMIT;

   -- Rollback example
   BEGIN;
       DELETE FROM customers WHERE name = 'Frank';
       -- Oops, wrong customer
   ROLLBACK;
   ```

6. **UPSERT (PostgreSQL)**

   ```sql
   -- Insert or update on conflict
   INSERT INTO products (name, category, price, stock)
   VALUES ('Keyboard', 'Electronics', 89.99, 200)
   ON CONFLICT (name) DO UPDATE
   SET price = EXCLUDED.price, stock = EXCLUDED.stock;
   ```

   <!-- prettier-ignore -->
   :::note
   UPSERT syntax varies by database. PostgreSQL uses `ON CONFLICT ... DO UPDATE`.
   MySQL uses `ON DUPLICATE KEY UPDATE`. See
   [SQL Cheat Sheet](../how/sql.md#upsert-insert-or-update) for portable options.
   :::

### Checkpoint

Write a transaction that inserts a new order with two order items. If either
insert fails, roll back the entire transaction. Verify the order exists after
COMMIT.

---

## Lesson 8: Query Planning and Optimization

**Goal:** Read execution plans, create indexes, and avoid common anti-patterns.

### Concepts

The query planner decides how to execute your SQL. EXPLAIN shows the plan;
EXPLAIN ANALYZE runs the query and shows actual timings. Sequential scans read
every row. Index scans jump directly to matching rows. The planner chooses based
on table statistics, available indexes, and estimated costs.

### Exercises

1. **Read an execution plan**

   ```sql
   EXPLAIN SELECT * FROM customers WHERE country = 'US';

   -- With actual timing
   EXPLAIN ANALYZE SELECT * FROM customers WHERE country = 'US';
   ```

   ```text
   Key things to look for:
   - Seq Scan vs Index Scan
   - Estimated rows vs actual rows
   - Cost (startup..total)
   - Sort method (quicksort, external merge)
   ```

2. **Create and test an index**

   ```sql
   -- Without index (Seq Scan)
   EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 1;

   -- Add index
   CREATE INDEX idx_orders_customer ON orders(customer_id);

   -- With index (Index Scan)
   EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 1;
   ```

3. **Composite indexes**

   ```sql
   -- Query filters on two columns
   EXPLAIN ANALYZE
   SELECT * FROM order_items WHERE order_id = 1 AND product_id = 2;

   -- Composite index matches the query
   CREATE INDEX idx_oi_order_product ON order_items(order_id, product_id);

   EXPLAIN ANALYZE
   SELECT * FROM order_items WHERE order_id = 1 AND product_id = 2;
   ```

4. **Spot common anti-patterns**

   ```sql
   -- Anti-pattern: function on indexed column defeats the index
   -- BAD: Seq Scan
   SELECT * FROM customers WHERE UPPER(email) = 'ALICE@EXAMPLE.COM';

   -- FIX: expression index or query-side normalization
   CREATE INDEX idx_customers_lower_email ON customers(LOWER(email));
   SELECT * FROM customers WHERE LOWER(email) = 'alice@example.com';

   -- Anti-pattern: SELECT * when you need two columns
   -- BAD: reads all columns from disk
   SELECT * FROM products WHERE category = 'Electronics';

   -- BETTER: select only needed columns
   SELECT name, price FROM products WHERE category = 'Electronics';

   -- Anti-pattern: N+1 queries in application code
   -- BAD (pseudocode):
   --   for each customer:
   --     SELECT * FROM orders WHERE customer_id = ?
   --
   -- FIX: single JOIN
   SELECT c.name, o.id FROM customers c JOIN orders o ON c.id = o.customer_id;
   ```

5. **Partial indexes and covering indexes**

   ```sql
   -- Partial index: only index rows you query
   CREATE INDEX idx_orders_pending ON orders(created_at)
   WHERE status = 'pending';

   EXPLAIN ANALYZE
   SELECT * FROM orders WHERE status = 'pending' ORDER BY created_at;

   -- Covering index: includes all needed columns (Index Only Scan)
   CREATE INDEX idx_products_cat_price ON products(category, price)
   INCLUDE (name);

   EXPLAIN ANALYZE
   SELECT name, price FROM products WHERE category = 'Electronics';
   ```

6. **Analyze join performance**

   ```sql
   EXPLAIN ANALYZE
   SELECT c.name, SUM(oi.quantity * oi.unit_price) AS total
   FROM customers c
   JOIN orders o ON c.id = o.customer_id
   JOIN order_items oi ON o.id = oi.order_id
   GROUP BY c.name
   ORDER BY total DESC;
   ```

   ```text
   Look for:
   - Hash Join vs Nested Loop vs Merge Join
   - Hash Join: best for large unindexed tables
   - Nested Loop: best when one side is small or indexed
   - Merge Join: best when both sides are pre-sorted
   ```

### Checkpoint

Add an index that speeds up a slow query. Run EXPLAIN ANALYZE before and after
to measure the improvement. Identify which scan type changed (Seq Scan → Index
Scan).

---

## Practice Projects

### Project 1: Sales Dashboard Queries

Write a set of queries that power a dashboard: total revenue by month, top 5
products by units sold, customer retention (customers who ordered in consecutive
months), and average order value over time. Use CTEs and window functions.

### Project 2: Data Cleanup Pipeline

Import a messy CSV into a staging table. Write queries to find duplicates, fix
inconsistent casing, fill NULL values with defaults, and merge cleaned data into
production tables — all inside a transaction.

### Project 3: Query Optimization Audit

Take 5 slow queries (real or invented), run EXPLAIN ANALYZE on each, add
appropriate indexes, and document the before/after plans. Identify which
anti-patterns caused the slowdown.

---

## Command Reference

| Stage        | Must Know                                                  |
| ------------ | ---------------------------------------------------------- |
| Reading      | `SELECT` `WHERE` `ORDER BY` `LIMIT` `DISTINCT`             |
| Filtering    | `LIKE` `IN` `BETWEEN` `IS NULL` `COALESCE`                 |
| Joining      | `JOIN` `LEFT JOIN` `RIGHT JOIN` `FULL OUTER JOIN`          |
| Aggregating  | `GROUP BY` `HAVING` `COUNT` `SUM` `AVG` `MIN` `MAX`        |
| Subqueries   | `IN (SELECT)` `EXISTS` `NOT EXISTS` scalar subquery        |
| Advanced     | `WITH` (CTE) `ROW_NUMBER` `RANK` `LAG` `LEAD` `SUM() OVER` |
| Writing      | `INSERT` `UPDATE` `DELETE` `BEGIN` `COMMIT` `ROLLBACK`     |
| Optimization | `EXPLAIN ANALYZE` `CREATE INDEX` `VACUUM` `ANALYZE`        |

## See Also

- [SQL Cheat Sheet](../how/sql.md) — Portable SQL syntax reference
- [PostgreSQL Cheat Sheet](../how/postgres.md) — psql commands, JSON, admin
  queries
- [Data Models Lesson Plan](data-models-lesson-plan.md) — ER diagrams,
  normalization, schema evolution
