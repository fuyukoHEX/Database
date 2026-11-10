-- ===========================================================================
--  Materialized Views in Practice -- live lecture script
--  Database Systems
--
--  Usage:   createdb mvdemo
--           psql -d mvdemo -f mv_demos.sql          (runs everything)
--  or open this file and run it block by block in psql.
--
--  DEMOS 5 AND 6 NEED TWO SESSIONS. Open a second psql window on the same
--  database and keep this one line ready in it:
--
--        \timing on
--        SELECT count(*) FROM mv_city_month;
--
--  Run the REFRESH in session A, then immediately run that SELECT in
--  session B and read the time it reports.
-- ===========================================================================

\pset pager off
-- Demos 6a, 8, and 10 deliberately raise errors, so do not stop on them.
\set ON_ERROR_STOP off

-- ---------------------------------------------------------------------------
-- SETUP  (~35 seconds)
-- ---------------------------------------------------------------------------
\echo '>>> SETUP: 200k customers, 3M orders'

DROP MATERIALIZED VIEW IF EXISTS mv_city_month, mv_customer_totals, mv_pending_orders;
DROP VIEW IF EXISTS v_city_month;
DROP TABLE IF EXISTS rollup_city_month, orders, customers;

CREATE TABLE customers (
    customer_id int PRIMARY KEY, full_name text NOT NULL, email text NOT NULL,
    city text NOT NULL, signup_date date NOT NULL);

INSERT INTO customers (customer_id, full_name, email, city, signup_date)
SELECT g, 'Customer ' || g,
       'user' || g || '@' || (ARRAY['mail.kz','gmail.com','kbtu.kz','yandex.ru'])[1 + g % 4],
       (ARRAY['Almaty','Astana','Shymkent','Aktobe','Karaganda','Atyrau'])[1 + g % 6],
       DATE '2020-01-01' + (g % 2000)
FROM generate_series(1, 200000) g;

CREATE TABLE orders (
    order_id bigint PRIMARY KEY, customer_id int NOT NULL REFERENCES customers,
    order_date date NOT NULL, status text NOT NULL,
    amount numeric(10,2) NOT NULL, note text);

SELECT setseed(0.42);          -- same data every time you run the lecture

INSERT INTO orders (order_id, customer_id, order_date, status, amount, note)
SELECT g, 1 + (random()*199999)::int,
       DATE '2023-01-01' + (random()*1000)::int,
       CASE WHEN random() < 0.85 THEN 'shipped'
            WHEN random() < 0.67 THEN 'pending' ELSE 'cancelled' END,
       round((10 + random()*9990)::numeric, 2), 'order note ' || g
FROM generate_series(1, 3000000) g;

CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE INDEX idx_orders_date     ON orders (order_date);
VACUUM ANALYZE customers;
VACUUM ANALYZE orders;


-- ---------------------------------------------------------------------------
-- DEMO 1 -- The problem: an expensive dashboard query
-- ---------------------------------------------------------------------------
\echo ''
\echo '>>> DEMO 1: revenue per city per month -- how slow, and why'

SELECT c.city, date_trunc('month', o.order_date)::date AS month,
       count(*) AS orders, round(sum(o.amount),2) AS revenue,
       round(avg(o.amount),2) AS avg_check
  FROM orders o JOIN customers c USING (customer_id)
 WHERE o.status = 'shipped'
 GROUP BY 1,2 ORDER BY 1,2 LIMIT 5;

EXPLAIN (ANALYZE, BUFFERS)
SELECT c.city, date_trunc('month', o.order_date)::date AS month,
       count(*) AS orders, round(sum(o.amount),2) AS revenue,
       round(avg(o.amount),2) AS avg_check
  FROM orders o JOIN customers c USING (customer_id)
 WHERE o.status = 'shipped'
 GROUP BY 1,2;

-- Talking points: ~2.6 s to produce 198 rows from 2,549,389 scanned.
-- Stable answer + expensive to compute + read repeatedly = the case for a
-- materialized view. Write those three conditions on the board.


-- ---------------------------------------------------------------------------
-- DEMO 2 -- A regular view is not a cache
-- ---------------------------------------------------------------------------
\echo ''
\echo '>>> DEMO 2: CREATE VIEW stores no rows at all'

CREATE VIEW v_city_month AS
SELECT c.city, date_trunc('month', o.order_date)::date AS month,
       count(*) AS orders, round(sum(o.amount),2) AS revenue,
       round(avg(o.amount),2) AS avg_check
  FROM orders o JOIN customers c USING (customer_id)
 WHERE o.status = 'shipped'
 GROUP BY 1,2;

EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM v_city_month;

\echo '--- even asking for one city does not save the aggregate work ---'
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM v_city_month WHERE city = 'Almaty';

-- Talking points: identical plan, node for node. A view is macro expansion.
-- Views are still useful -- naming, business rules, column access -- just not
-- as a performance tool.


-- ---------------------------------------------------------------------------
-- DEMO 3 -- The materialized view
-- ---------------------------------------------------------------------------
\echo ''
\echo '>>> DEMO 3: same text, one extra keyword'

\timing on
CREATE MATERIALIZED VIEW mv_city_month AS
SELECT c.city, date_trunc('month', o.order_date)::date AS month,
       count(*) AS orders, round(sum(o.amount),2) AS revenue,
       round(avg(o.amount),2) AS avg_check
  FROM orders o JOIN customers c USING (customer_id)
 WHERE o.status = 'shipped'
 GROUP BY 1,2;
\timing off

EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM mv_city_month;

SELECT 'orders' AS object, pg_size_pretty(pg_total_relation_size('orders')) AS size
UNION ALL SELECT 'customers', pg_size_pretty(pg_total_relation_size('customers'))
UNION ALL SELECT 'mv_city_month', pg_size_pretty(pg_total_relation_size('mv_city_month'));

-- Talking points: 2.6 s -> 0.05 ms, 350 MB -> 24 kB. The plan says
-- "Seq Scan on mv_city_month": it is a real table holding the result.
-- Creating it cost one run of the original query -- you MOVED the work.


-- ---------------------------------------------------------------------------
-- DEMO 4 -- The price: staleness
-- ---------------------------------------------------------------------------
\echo ''
\echo '>>> DEMO 4: 50,000 new orders in a month the matview already covers'

INSERT INTO orders (order_id, customer_id, order_date, status, amount, note)
SELECT 3000000 + g,
       (SELECT min(customer_id) FROM customers WHERE city='Almaty') + ((g % 100) * 6),
       DATE '2024-06-01' + (g % 30), 'shipped', 1000.00, 'backfill'
FROM generate_series(1, 50000) g;

SELECT 'view' AS src, orders, revenue FROM v_city_month
 WHERE city='Almaty' AND month=DATE '2024-06-01'
UNION ALL
SELECT 'matview', orders, revenue FROM mv_city_month
 WHERE city='Almaty' AND month=DATE '2024-06-01';

-- Talking points: the view moved, the matview did not. PostgreSQL has NO
-- automatic refresh. Every matview comes with a question you must answer
-- out loud: how stale is this allowed to be?


-- ---------------------------------------------------------------------------
-- DEMO 5 -- REFRESH, and the lock nobody mentions        *** TWO SESSIONS ***
-- ---------------------------------------------------------------------------
\echo ''
\echo '>>> DEMO 5: plain REFRESH -- run the SELECT in session B NOW'

\timing on
REFRESH MATERIALIZED VIEW mv_city_month;
\timing off

-- In session B, while the above runs:
--      \timing on
--      SELECT count(*) FROM mv_city_month;
-- Expect session B to report roughly the refresh duration: it was BLOCKED,
-- not slow. A plain REFRESH takes an ACCESS EXCLUSIVE lock.
-- Measured in the handout: refresh 2,339 ms, reader blocked 1,928 ms.


-- ---------------------------------------------------------------------------
-- DEMO 6 -- REFRESH ... CONCURRENTLY                     *** TWO SESSIONS ***
-- ---------------------------------------------------------------------------
\echo ''
\echo '>>> DEMO 6a: CONCURRENTLY without a unique index -- expect an ERROR'

REFRESH MATERIALIZED VIEW CONCURRENTLY mv_city_month;

\echo '>>> DEMO 6b: give it a unique index and try again'

CREATE UNIQUE INDEX mv_city_month_pk ON mv_city_month (city, month);

\timing on
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_city_month;
\timing off

-- Run the session B SELECT again while this one runs: it should return in
-- about a millisecond. Measured in the handout: refresh 2,738 ms (17% slower
-- than plain), reader 1.17 ms instead of 1,928 ms.
--
-- Two conditions for CONCURRENTLY: a UNIQUE index with no WHERE clause, and
-- the view must already be populated. It also leaves dead rows, so vacuum.

SELECT 'view' AS src, orders, revenue FROM v_city_month
 WHERE city='Almaty' AND month=DATE '2024-06-01'
UNION ALL
SELECT 'matview', orders, revenue FROM mv_city_month
 WHERE city='Almaty' AND month=DATE '2024-06-01';


-- ---------------------------------------------------------------------------
-- DEMO 7 -- A materialized view is a table: index it
-- ---------------------------------------------------------------------------
\echo ''
\echo '>>> DEMO 7: a bigger matview, 200,000 rows'

\timing on
CREATE MATERIALIZED VIEW mv_customer_totals AS
SELECT c.customer_id, c.full_name, c.city,
       count(*) AS orders, round(sum(o.amount),2) AS lifetime_value,
       max(o.order_date) AS last_order
  FROM customers c JOIN orders o USING (customer_id)
 GROUP BY 1,2,3;
\timing off

SELECT count(*) AS rows,
       pg_size_pretty(pg_total_relation_size('mv_customer_totals')) AS size
FROM mv_customer_totals;

\echo '--- BEFORE: no index on the matview ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM mv_customer_totals WHERE customer_id = 142857;

CREATE UNIQUE INDEX mv_cust_totals_pk  ON mv_customer_totals (customer_id);
CREATE INDEX        mv_cust_totals_ltv ON mv_customer_totals (lifetime_value DESC);

\echo '--- AFTER ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM mv_customer_totals WHERE customer_id = 142857;

\echo '--- top spenders ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT full_name, city, lifetime_value FROM mv_customer_totals
 ORDER BY lifetime_value DESC LIMIT 10;

-- Talking points: nothing here is matview-specific -- that IS the point.
-- The unique index does double duty: fast lookups AND it enables
-- REFRESH ... CONCURRENTLY. Create it as a habit.


-- ---------------------------------------------------------------------------
-- DEMO 8 -- WITH NO DATA
-- ---------------------------------------------------------------------------
\echo ''
\echo '>>> DEMO 8: create the shape now, pay for the data later'

\timing on
CREATE MATERIALIZED VIEW mv_pending_orders AS
SELECT c.city, count(*) AS pending, round(sum(o.amount),2) AS amount
  FROM orders o JOIN customers c USING (customer_id)
 WHERE o.status = 'pending' GROUP BY 1
WITH NO DATA;
\timing off

SELECT matviewname, ispopulated FROM pg_matviews ORDER BY 1;

\echo '--- querying an unpopulated matview -- expect an ERROR ---'
SELECT * FROM mv_pending_orders;

\timing on
REFRESH MATERIALIZED VIEW mv_pending_orders;
\timing off

SELECT matviewname, ispopulated FROM pg_matviews WHERE matviewname = 'mv_pending_orders';

-- Talking points: an empty matview ERRORS, it does not return zero rows.
-- pg_matviews.ispopulated is what a deployment smoke test should check.


-- ---------------------------------------------------------------------------
-- DEMO 9 -- When a plain rollup table beats a materialized view
-- ---------------------------------------------------------------------------
\echo ''
\echo '>>> DEMO 9: full refresh vs updating only the month that changed'

CREATE TABLE rollup_city_month (
    city text NOT NULL, month date NOT NULL,
    orders bigint NOT NULL, revenue numeric(14,2) NOT NULL,
    PRIMARY KEY (city, month));

INSERT INTO rollup_city_month
SELECT c.city, date_trunc('month', o.order_date)::date, count(*), round(sum(o.amount),2)
  FROM orders o JOIN customers c USING (customer_id)
 WHERE o.status = 'shipped' GROUP BY 1,2;

\echo '--- 50,000 new orders, all in September 2024 ---'
INSERT INTO orders (order_id, customer_id, order_date, status, amount, note)
SELECT 4000000 + g, 1 + (random()*199999)::int,
       DATE '2024-09-01' + (g % 30), 'shipped', 500.00, 'september batch'
FROM generate_series(1, 50000) g;

\timing on
\echo '--- A: the matview redoes all 33 months ---'
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_city_month;

\echo '--- B: the rollup table redoes one month ---'
INSERT INTO rollup_city_month (city, month, orders, revenue)
SELECT c.city, date_trunc('month', o.order_date)::date, count(*), round(sum(o.amount),2)
  FROM orders o JOIN customers c USING (customer_id)
 WHERE o.status = 'shipped'
   AND o.order_date >= DATE '2024-09-01' AND o.order_date < DATE '2024-10-01'
 GROUP BY 1,2
ON CONFLICT (city, month) DO UPDATE
   SET orders = EXCLUDED.orders, revenue = EXCLUDED.revenue;
\timing off

\echo '--- identical results ---'
SELECT 'matview' AS src, orders, revenue FROM mv_city_month
 WHERE city='Almaty' AND month=DATE '2024-09-01'
UNION ALL
SELECT 'rollup', orders, revenue FROM rollup_city_month
 WHERE city='Almaty' AND month=DATE '2024-09-01';

-- Talking points: ~5.8x faster, and the gap widens with history. The cost is
-- complexity: you own the refresh logic and its bugs. A matview cannot be
-- wrong, only old.
-- Ask: what breaks in B if an OLD order is edited or deleted?


-- ---------------------------------------------------------------------------
-- DEMO 10 -- Restrictions and dependencies
-- ---------------------------------------------------------------------------
\echo ''
\echo '>>> DEMO 10: two things a matview is not'

\echo '--- not writable -- expect an ERROR ---'
UPDATE mv_city_month SET revenue = 0 WHERE city = 'Almaty';

\echo '--- not independent of its base tables -- expect an ERROR ---'
BEGIN;
ALTER TABLE orders DROP COLUMN amount;
ROLLBACK;

\echo '--- who depends on what ---'
SELECT dependent.relname AS matview, source.relname AS depends_on
  FROM pg_depend d
  JOIN pg_rewrite r        ON r.oid = d.objid
  JOIN pg_class dependent  ON dependent.oid = r.ev_class
  JOIN pg_class source     ON source.oid = d.refobjid
 WHERE dependent.relkind = 'm' AND source.relkind = 'r'
 GROUP BY 1,2 ORDER BY 1,2;

-- Talking points: matviews make schema migrations harder -- drop, alter,
-- recreate, in the right order, in the same deployment.


-- ---------------------------------------------------------------------------
-- DEMO 11 -- Inventory and maintenance
-- ---------------------------------------------------------------------------
\echo ''
\echo '>>> DEMO 11: what do we own, and what does it cost?'

SELECT m.matviewname AS name, m.ispopulated AS populated,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS size,
       (SELECT count(*) FROM pg_index i WHERE i.indrelid = c.oid) AS indexes
  FROM pg_matviews m JOIN pg_class c ON c.relname = m.matviewname
 WHERE c.relkind = 'm'
 ORDER BY pg_total_relation_size(c.oid) DESC;

-- Talking points: nothing records WHEN a matview was last refreshed. If
-- staleness matters, log it yourself and show that timestamp on the
-- dashboard. Scheduling lives outside the database: pg_cron, system cron,
-- or your application's job runner.


-- ---------------------------------------------------------------------------
-- CLEANUP
-- ---------------------------------------------------------------------------
-- DROP MATERIALIZED VIEW mv_city_month, mv_customer_totals, mv_pending_orders;
-- DROP VIEW v_city_month;
-- DROP TABLE rollup_city_month, orders, customers;
