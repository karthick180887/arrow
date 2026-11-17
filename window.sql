-- =============================================================================
-- SQL Window Functions — Simple to Advanced
-- Arrow Generative AI programme · beginner SQL
--
-- Database : shop.db
-- Open shop.db in DB Browser for SQLite (or any SQLite client), then run this
-- script statement by statement. If you run the whole file at once, many
-- clients will show only the last result set.
--
-- A window function looks at other rows and writes a result on the SAME row.
-- The table does not shrink. That is the difference from GROUP BY.
--
--   FUNCTION(...) OVER (
--       PARTITION BY group_columns     -- optional: restart for each group
--       ORDER BY sort_columns          -- optional: order inside the group
--       ROWS BETWEEN ... AND ...       -- optional: which neighbours to include
--   )
--
-- Default frame: with ORDER BY, SQLite uses
--   RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- Without ORDER BY, the frame is the whole partition.
--
-- Filter status = 'completed' only when measuring sales, spend or revenue.
-- Revenue formula: quantity * unit_price * (1 - discount)
-- Recency "as of" date used below: 2025-06-30 (the last order date in the file).
--
-- Try-it solutions are included after each level, commented out with '--'.
-- Uncomment a block (remove the leading '-- ') when you want to run it.
-- =============================================================================


-- =============================================================================
-- Window functions vs GROUP BY (tiny 6-row example, not the shop data)
-- Goal: See that GROUP BY collapses rows, while a window function keeps them.
-- Analogy: GROUP BY packs items into two bags. A window function leaves every
-- item on the counter and writes the bag total on a sticky note next to it.
-- =============================================================================
WITH sales(person, region, amount) AS (
    VALUES
        ('Asha', 'East', 10),
        ('Ben',  'East', 20),
        ('Cara', 'East', 30),
        ('Dev',  'West', 40),
        ('Eva',  'West', 10),
        ('Fay',  'West', 20)
)
SELECT
    region,
    SUM(amount) AS region_total
FROM sales
GROUP BY region
ORDER BY region;

WITH sales(person, region, amount) AS (
    VALUES
        ('Asha', 'East', 10),
        ('Ben',  'East', 20),
        ('Cara', 'East', 30),
        ('Dev',  'West', 40),
        ('Eva',  'West', 10),
        ('Fay',  'West', 20)
)
SELECT
    person,
    region,
    amount,
    SUM(amount) OVER (PARTITION BY region) AS region_total
FROM sales
ORDER BY region, person;

-- =============================================================================
-- Level 1: Grand total and percent of total — SUM() OVER ()
-- =============================================================================
-- Goal: Write the shop-wide total on every category row, then compute each category's share.
-- Analogy: Like adding a 'Grand Total' cell in Excel and then a '% of total' column, without hiding the category rows.
WITH category_sales AS (
    SELECT
        p.category,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
    FROM order_items AS oi
    JOIN orders AS o
        ON o.order_id = oi.order_id
    JOIN products AS p
        ON p.product_id = oi.product_id
    WHERE o.status = 'completed'          -- kept sales only
    GROUP BY p.category
)
SELECT
    category,
    revenue,
    -- same grand total written on every row (empty OVER)
    SUM(revenue) OVER () AS grand_total,
    -- this row's share of the shop, as a percent
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS pct_of_total
FROM category_sales
ORDER BY revenue DESC;

-- Try it: Do the same for completed revenue by country. Show country, revenue, grand_total and pct_of_total, highest revenue first.
-- Solution (commented out — uncomment to run):
-- WITH country_sales AS (
--     SELECT
--         c.country,
--         ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
--     FROM customers AS c
--     JOIN orders AS o
--         ON o.customer_id = c.customer_id
--     JOIN order_items AS oi
--         ON oi.order_id = o.order_id
--     WHERE o.status = 'completed'
--     GROUP BY c.country
-- )
-- SELECT
--     country,
--     revenue,
--     SUM(revenue) OVER () AS grand_total,
--     ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS pct_of_total
-- FROM country_sales
-- ORDER BY revenue DESC;

-- =============================================================================
-- Level 2: PARTITION BY — department total and average next to each person
-- =============================================================================
-- Goal: Show each staff member's salary next to their department average and department total.
-- Analogy: A class average written on every student's report card, instead of one average on the board.
SELECT
    department,
    name,
    role,
    salary,
    -- restarts the average each time the department changes
    ROUND(AVG(salary) OVER (PARTITION BY department), 2) AS dept_avg,
    SUM(salary) OVER (PARTITION BY department) AS dept_total,
    salary - ROUND(AVG(salary) OVER (PARTITION BY department), 2) AS vs_dept_avg
FROM staff
ORDER BY department, salary DESC, name;

-- Try it: Add a label: 'Above average', 'Below average' or 'Exactly average', using the department average from the window.
-- Solution (commented out — uncomment to run):
-- SELECT
--     department,
--     name,
--     salary,
--     ROUND(AVG(salary) OVER (PARTITION BY department), 2) AS dept_avg,
--     salary - ROUND(AVG(salary) OVER (PARTITION BY department), 2) AS vs_dept_avg,
--     CASE
--         WHEN salary > AVG(salary) OVER (PARTITION BY department) THEN 'Above average'
--         WHEN salary < AVG(salary) OVER (PARTITION BY department) THEN 'Below average'
--         ELSE 'Exactly average'
--     END AS vs_average
-- FROM staff
-- ORDER BY department, salary DESC, name;

-- =============================================================================
-- Level 3: ROW_NUMBER — a bib number inside each group
-- =============================================================================
-- Goal: Number the staff in each department from highest salary to lowest.
-- Analogy: Lining people up in each room and handing out bibs 1, 2, 3... Even if two people have the same salary, the numbers never tie (we also sort by name so the order is stable).
SELECT
    department,
    name,
    salary,
    -- bib numbers inside each department; name is a tie-breaker so the order is stable
    ROW_NUMBER() OVER (
        PARTITION BY department
        ORDER BY salary DESC, name
    ) AS row_in_dept
FROM staff
ORDER BY department, row_in_dept;

-- Try it: Number every product inside its category by unit_price, most expensive first. Show category, product_name, unit_price and price_rank.
-- Solution (commented out — uncomment to run):
-- SELECT
--     category,
--     product_name,
--     unit_price,
--     ROW_NUMBER() OVER (
--         PARTITION BY category
--         ORDER BY unit_price DESC, product_name
--     ) AS price_rank
-- FROM products
-- ORDER BY category, price_rank;

-- =============================================================================
-- Level 4: ROW_NUMBER vs RANK vs DENSE_RANK (ties in Sales salaries)
-- =============================================================================
-- Goal: Put the three ranking functions side by side on the Sales team, where several people share a salary.
-- Analogy: Olympics: two people tie for 4th. RANK gives the next person 6 (it skips 5). DENSE_RANK gives the next person 5 (no gap). ROW_NUMBER never ties — it still hands out 4, 5, 6.
SELECT
    name,
    salary,
    -- always 1, 2, 3... even when salaries match
    ROW_NUMBER() OVER (ORDER BY salary DESC, name) AS row_num,
    -- Olympic style: two people share 4th, the next number is 6 (5 is skipped)
    RANK() OVER (ORDER BY salary DESC) AS rnk,
    -- no gaps: two people share 4th, the next number is 5
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rnk
FROM staff
WHERE department = 'Sales'
ORDER BY salary DESC, name;

-- Try it: Run the same three functions for the Operations team (three people share 58,000, two share 52,000).
-- Solution (commented out — uncomment to run):
-- SELECT
--     name,
--     salary,
--     ROW_NUMBER() OVER (ORDER BY salary DESC, name) AS row_num,
--     RANK() OVER (ORDER BY salary DESC) AS rnk,
--     DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rnk
-- FROM staff
-- WHERE department = 'Operations'
-- ORDER BY salary DESC, name;

-- =============================================================================
-- Level 5: Top-N per group — a CTE plus ROW_NUMBER
-- =============================================================================
-- Goal: Keep only the two highest-revenue products in each category (completed sales).
-- Analogy: You cannot use a window result in WHERE in the same query, so you wrap it in a CTE (rough-work box) and then filter rn <= 2. Like short-listing the top 2 students in each class after writing their ranks.
WITH product_sales AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
    FROM products AS p
    JOIN order_items AS oi
        ON oi.product_id = p.product_id
    JOIN orders AS o
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY p.category, p.product_id, p.product_name
),
ranked AS (
    SELECT
        category,
        product_id,
        product_name,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY revenue DESC, product_name
        ) AS rn
    FROM product_sales
)
SELECT
    category,
    product_name,
    revenue,
    rn AS top_in_category
FROM ranked
WHERE rn <= 2                 -- keep only the top 2 in each category
ORDER BY category, rn;

-- Try it: List the top 2 earners in each staff department. Management has only one person, so that department returns one row.
-- Solution (commented out — uncomment to run):
-- WITH ranked AS (
--     SELECT
--         department,
--         name,
--         role,
--         salary,
--         ROW_NUMBER() OVER (
--             PARTITION BY department
--             ORDER BY salary DESC, name
--         ) AS rn
--     FROM staff
-- )
-- SELECT
--     department,
--     name,
--     role,
--     salary,
--     rn AS top_in_dept
-- FROM ranked
-- WHERE rn <= 2
-- ORDER BY department, rn;

-- =============================================================================
-- Level 6: NTILE — spend quartiles of customers
-- =============================================================================
-- Goal: Split customers who have completed spend into four piles that are as even as possible. Quartile 1 is the lowest spenders, quartile 4 the highest.
-- Analogy: Dealing a deck of cards into four hands. With 199 customers, the piles will be 50, 50, 50 and 49.
WITH customer_spend AS (
    SELECT
        c.customer_id,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS total_spend
    FROM customers AS c
    JOIN orders AS o
        ON o.customer_id = c.customer_id
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY c.customer_id
),
banded AS (
    SELECT
        customer_id,
        total_spend,
        NTILE(4) OVER (ORDER BY total_spend, customer_id) AS spend_quartile
    FROM customer_spend
)
SELECT
    spend_quartile,
    COUNT(*) AS customers,
    ROUND(MIN(total_spend), 2) AS min_spend,
    ROUND(MAX(total_spend), 2) AS max_spend,
    ROUND(AVG(total_spend), 2) AS avg_spend
FROM banded
GROUP BY spend_quartile
ORDER BY spend_quartile;

-- The same 199 customers, each with a quartile (scan the first rows: these are the lowest spenders).
WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.name,
        c.country,
        c.segment,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS total_spend
    FROM customers AS c
    JOIN orders AS o
        ON o.customer_id = c.customer_id
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY c.customer_id, c.name, c.country, c.segment
)
SELECT
    customer_id,
    name,
    country,
    segment,
    total_spend,
    -- 1 = lowest spenders, 4 = highest spenders (four piles, as even as possible)
    NTILE(4) OVER (ORDER BY total_spend, customer_id) AS spend_quartile
FROM customer_spend
ORDER BY total_spend, customer_id;

-- Try it: Repeat the quartile split, but only for Corporate customers (those with completed spend). Show customer_id, name, segment, total_spend and spend_quartile, lowest spend first.
-- Solution (commented out — uncomment to run):
-- WITH customer_spend AS (
--     SELECT
--         c.customer_id,
--         c.name,
--         c.segment,
--         ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS total_spend
--     FROM customers AS c
--     JOIN orders AS o
--         ON o.customer_id = c.customer_id
--     JOIN order_items AS oi
--         ON oi.order_id = o.order_id
--     WHERE o.status = 'completed'
--       AND c.segment = 'Corporate'
--     GROUP BY c.customer_id, c.name, c.segment
-- )
-- SELECT
--     customer_id,
--     name,
--     segment,
--     total_spend,
--     NTILE(4) OVER (ORDER BY total_spend, customer_id) AS spend_quartile
-- FROM customer_spend
-- ORDER BY total_spend, customer_id;

-- =============================================================================
-- Level 7: Running total — ORDER BY inside OVER
-- =============================================================================
-- Goal: Build a month-by-month completed-revenue piggy bank from Jan 2024 to Jun 2025.
-- Analogy: A piggy bank: each month you drop in this month's coins and write the new balance on the jar. There is one row per month, so ROWS and RANGE would give the same answer here.
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date) AS year_month,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY strftime('%Y-%m', o.order_date)
)
SELECT
    year_month,
    revenue,
    -- piggy-bank running total: this month plus every month before it
    ROUND(
        SUM(revenue) OVER (
            ORDER BY year_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_revenue
FROM monthly
ORDER BY year_month;

-- Try it: Build a running total of completed order_count by month, not revenue.
-- Solution (commented out — uncomment to run):
-- WITH monthly AS (
--     SELECT
--         strftime('%Y-%m', o.order_date) AS year_month,
--         COUNT(DISTINCT o.order_id) AS order_count
--     FROM orders AS o
--     WHERE o.status = 'completed'
--     GROUP BY strftime('%Y-%m', o.order_date)
-- )
-- SELECT
--     year_month,
--     order_count,
--     SUM(order_count) OVER (
--         ORDER BY year_month
--         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--     ) AS running_orders
-- FROM monthly
-- ORDER BY year_month;

-- =============================================================================
-- Level 8: Running total per partition (per category)
-- =============================================================================
-- Goal: The same piggy bank, but one jar per category. The running total restarts when the category changes. The main query shows Electronics; the short follow-up shows Jan–Feb for every category so you can see the restart.
-- Analogy: Five separate piggy banks, one labelled Books, one Electronics, and so on. When you pick up the Electronics jar you do not add in the Books coins.
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date) AS year_month,
        p.category,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    JOIN products AS p
        ON p.product_id = oi.product_id
    WHERE o.status = 'completed'
    GROUP BY strftime('%Y-%m', o.order_date), p.category
)
SELECT
    category,
    year_month,
    revenue,
    -- the running total restarts at 0 for each category
    ROUND(
        SUM(revenue) OVER (
            PARTITION BY category
            ORDER BY year_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_revenue
FROM monthly
WHERE category = 'Electronics'    -- one category, so the restart is easy to see
ORDER BY year_month;

-- First two months for every category — notice each category's running total starts again.
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date) AS year_month,
        p.category,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    JOIN products AS p
        ON p.product_id = oi.product_id
    WHERE o.status = 'completed'
    GROUP BY strftime('%Y-%m', o.order_date), p.category
)
SELECT
    category,
    year_month,
    revenue,
    ROUND(
        SUM(revenue) OVER (
            PARTITION BY category
            ORDER BY year_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_revenue
FROM monthly
WHERE year_month <= '2024-02'
ORDER BY category, year_month;

-- Try it: Show the monthly running total for Toys only, Jan 2024 to Jun 2025.
-- Solution (commented out — uncomment to run):
-- WITH monthly AS (
--     SELECT
--         strftime('%Y-%m', o.order_date) AS year_month,
--         p.category,
--         ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
--     FROM orders AS o
--     JOIN order_items AS oi
--         ON oi.order_id = o.order_id
--     JOIN products AS p
--         ON p.product_id = oi.product_id
--     WHERE o.status = 'completed'
--     GROUP BY strftime('%Y-%m', o.order_date), p.category
-- )
-- SELECT
--     category,
--     year_month,
--     revenue,
--     ROUND(
--         SUM(revenue) OVER (
--             PARTITION BY category
--             ORDER BY year_month
--             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--         ),
--         2
--     ) AS running_revenue
-- FROM monthly
-- WHERE category = 'Toys'
-- ORDER BY year_month;

-- =============================================================================
-- Level 9: 3-month moving average — ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
-- =============================================================================
-- Goal: Smooth monthly completed revenue with a 3-month moving average (this month plus the two before it).
-- Analogy: Looking at this month and the two behind you, then taking a step forward and looking again. At the start of the series there are not yet 3 months, so the average uses 1 month, then 2, then 3. months_in_avg shows that.
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date) AS year_month,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY strftime('%Y-%m', o.order_date)
)
SELECT
    year_month,
    revenue,
    -- this month plus the two before it (fewer than 3 months at the start)
    ROUND(
        AVG(revenue) OVER (
            ORDER BY year_month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS ma_3m,
    -- how many months actually went into that average (1, 2, then 3)
    COUNT(*) OVER (
        ORDER BY year_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS months_in_avg
FROM monthly
ORDER BY year_month;

-- Try it: Compute the same 3-month moving average for Electronics monthly revenue only.
-- Solution (commented out — uncomment to run):
-- WITH monthly AS (
--     SELECT
--         strftime('%Y-%m', o.order_date) AS year_month,
--         p.category,
--         ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
--     FROM orders AS o
--     JOIN order_items AS oi
--         ON oi.order_id = o.order_id
--     JOIN products AS p
--         ON p.product_id = oi.product_id
--     WHERE o.status = 'completed'
--       AND p.category = 'Electronics'
--     GROUP BY strftime('%Y-%m', o.order_date), p.category
-- )
-- SELECT
--     year_month,
--     revenue,
--     ROUND(
--         AVG(revenue) OVER (
--             ORDER BY year_month
--             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
--         ),
--         2
--     ) AS ma_3m,
--     COUNT(*) OVER (
--         ORDER BY year_month
--         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
--     ) AS months_in_avg
-- FROM monthly
-- ORDER BY year_month;

-- =============================================================================
-- Level 10: ROWS vs RANGE when dates repeat
-- =============================================================================
-- Goal: See how a running total behaves when several rows share the same date. First a 6-row toy table, then the first days of January 2024 in the shop.
-- Analogy: ROWS is 'the people standing in front of me in the queue'. RANGE is 'everyone who arrived on the same day as me'. If two orders share a date, RANGE writes the same running total on both of them.
WITH daily(dt, amount) AS (
    VALUES
        ('2024-01-01', 10),
        ('2024-01-01', 20),   -- same date as the row above
        ('2024-01-02', 30),
        ('2024-01-03', 40),
        ('2024-01-03', 50),
        ('2024-01-03', 60)    -- three rows share 3 January
)
SELECT
    dt,
    amount,
    -- ROWS: add one physical row at a time
    SUM(amount) OVER (
        ORDER BY dt, amount
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_rows,
    -- RANGE: once you land on a date, include EVERY row with that date
    SUM(amount) OVER (
        ORDER BY dt
        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_range
FROM daily
ORDER BY dt, amount;

-- The same idea on real shop orders, 1–6 January 2024 (completed). 1 Jan, 4 Jan and 5 Jan have more than one order.
WITH day_orders AS (
    SELECT
        o.order_id,
        o.order_date,
        o.channel,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
      AND o.order_date BETWEEN '2024-01-01' AND '2024-01-06'
    GROUP BY o.order_id, o.order_date, o.channel
)
SELECT
    order_date,
    order_id,
    channel,
    revenue,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY order_date, order_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_rows,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY order_date
            RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_range
FROM day_orders
ORDER BY order_date, order_id;

-- Try it: Run the same ROWS vs RANGE comparison for completed orders from 2024-01-07 to 2024-01-12. Several days in that week have more than one order, so the two columns will disagree on those days.
-- Solution (commented out — uncomment to run):
-- WITH day_orders AS (
--     SELECT
--         o.order_id,
--         o.order_date,
--         ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
--     FROM orders AS o
--     JOIN order_items AS oi
--         ON oi.order_id = o.order_id
--     WHERE o.status = 'completed'
--       AND o.order_date BETWEEN '2024-01-07' AND '2024-01-12'
--     GROUP BY o.order_id, o.order_date
-- )
-- SELECT
--     order_date,
--     order_id,
--     revenue,
--     ROUND(
--         SUM(revenue) OVER (
--             ORDER BY order_date, order_id
--             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--         ),
--         2
--     ) AS running_rows,
--     ROUND(
--         SUM(revenue) OVER (
--             ORDER BY order_date
--             RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--         ),
--         2
--     ) AS running_range
-- FROM day_orders
-- ORDER BY order_date, order_id;

-- =============================================================================
-- Level 11: LAG and LEAD — month-over-month growth
-- =============================================================================
-- Goal: Compare each month's completed revenue to the previous month and the next month, without a self-join.
-- Analogy: Leaning back to read last month's number (LAG) or leaning forward to peek at next month (LEAD). The first month has no previous value, so prev_month_rev and mom_pct are empty.
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date) AS year_month,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY strftime('%Y-%m', o.order_date)
)
SELECT
    year_month,
    revenue,
    -- peek at the row above (previous month)
    LAG(revenue, 1) OVER (ORDER BY year_month) AS prev_month_rev,
    -- peek at the row below (next month)
    LEAD(revenue, 1) OVER (ORDER BY year_month) AS next_month_rev,
    ROUND(revenue - LAG(revenue, 1) OVER (ORDER BY year_month), 2) AS change_amt,
    ROUND(
        100.0 * (revenue - LAG(revenue, 1) OVER (ORDER BY year_month))
        / LAG(revenue, 1) OVER (ORDER BY year_month),
        2
    ) AS mom_pct
FROM monthly
ORDER BY year_month;

-- Try it: Compute month-over-month growth for completed order_count instead of revenue.
-- Solution (commented out — uncomment to run):
-- WITH monthly AS (
--     SELECT
--         strftime('%Y-%m', o.order_date) AS year_month,
--         COUNT(DISTINCT o.order_id) AS order_count
--     FROM orders AS o
--     WHERE o.status = 'completed'
--     GROUP BY strftime('%Y-%m', o.order_date)
-- )
-- SELECT
--     year_month,
--     order_count,
--     LAG(order_count, 1) OVER (ORDER BY year_month) AS prev_month_orders,
--     ROUND(
--         100.0 * (order_count - LAG(order_count, 1) OVER (ORDER BY year_month))
--         / LAG(order_count, 1) OVER (ORDER BY year_month),
--         2
--     ) AS mom_pct
-- FROM monthly
-- ORDER BY year_month;

-- =============================================================================
-- Level 12: Days between a customer's consecutive orders — LAG
-- =============================================================================
-- Goal: For Ethan Kelly (C0163) and Hugo Menon (C0186), show each completed order and how many days have passed since that customer's previous completed order.
-- Analogy: A stamp in a loyalty card: next to today's visit you write the date of the last visit and count the days in between. The first order has no previous visit, so the gap is empty. PARTITION BY customer_id stops you from subtracting one customer’s date from another’s.
WITH cust_orders AS (
    SELECT
        o.customer_id,
        c.name,
        o.order_id,
        o.order_date,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS order_revenue
    FROM orders AS o
    JOIN customers AS c
        ON c.customer_id = o.customer_id
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
      AND o.customer_id IN ('C0163', 'C0186')   -- Ethan Kelly (5) and Hugo Menon (4)
    GROUP BY o.customer_id, c.name, o.order_id, o.order_date
)
SELECT
    customer_id,
    name,
    order_id,
    order_date,
    order_revenue,
    LAG(order_date) OVER (
        PARTITION BY customer_id
        ORDER BY order_date, order_id
    ) AS prev_order_date,
    CAST(
        julianday(order_date) - julianday(
            LAG(order_date) OVER (
                PARTITION BY customer_id
                ORDER BY order_date, order_id
            )
        ) AS INTEGER
    ) AS days_since_prev
FROM cust_orders
ORDER BY customer_id, order_date, order_id;

-- Try it: Show the same day-gap list for Ryan Jones (C0057, Ireland, 5 completed orders).
-- Solution (commented out — uncomment to run):
-- WITH cust_orders AS (
--     SELECT
--         o.customer_id,
--         c.name,
--         o.order_id,
--         o.order_date
--     FROM orders AS o
--     JOIN customers AS c
--         ON c.customer_id = o.customer_id
--     WHERE o.status = 'completed'
--       AND o.customer_id = 'C0057'              -- Ryan Jones, Ireland, 5 completed orders
--     GROUP BY o.customer_id, c.name, o.order_id, o.order_date
-- )
-- SELECT
--     customer_id,
--     name,
--     order_id,
--     order_date,
--     LAG(order_date) OVER (ORDER BY order_date, order_id) AS prev_order_date,
--     CAST(
--         julianday(order_date) - julianday(
--             LAG(order_date) OVER (ORDER BY order_date, order_id)
--         ) AS INTEGER
--     ) AS days_since_prev
-- FROM cust_orders
-- ORDER BY order_date, order_id;

-- =============================================================================
-- Level 13: FIRST_VALUE, LAST_VALUE (the frame trap) and NTH_VALUE
-- =============================================================================
-- Goal: For the Sales team, name the top earner, the bottom earner and the second-highest earner. See why LAST_VALUE is wrong until you extend the frame.
-- Analogy: A roll call from highest salary to lowest. FIRST_VALUE is the first name on the list. LAST_VALUE *should* be the last name, but the default frame only goes as far as the current person, so it often just repeats the current name. Stretch the frame with ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING. NTH_VALUE has the same trap; we ask for the 2nd name on the list.
SELECT
    department,
    name,
    salary,
    FIRST_VALUE(name) OVER (
        PARTITION BY department
        ORDER BY salary DESC, name
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS top_earner,
    -- TRAP: the default frame ends at the current row, so LAST_VALUE
    -- often just returns the current person, not the last in the department
    LAST_VALUE(name) OVER (
        PARTITION BY department
        ORDER BY salary DESC, name
    ) AS last_value_wrong,
    -- FIX: extend the frame all the way to the end of the department
    LAST_VALUE(name) OVER (
        PARTITION BY department
        ORDER BY salary DESC, name
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS bottom_earner,
    -- NTH_VALUE has the same frame trap; 2 means the second row in the ordered list
    NTH_VALUE(name, 2) OVER (
        PARTITION BY department
        ORDER BY salary DESC, name
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS second_highest
FROM staff
WHERE department = 'Sales'
ORDER BY salary DESC, name;

-- Try it: For Operations, show top_earner, bottom_earner and second_highest, all with the full-partition frame. Three people share 58,000, so the 'second' name depends on the tie-break (we sort by salary, then name).
-- Solution (commented out — uncomment to run):
-- SELECT
--     department,
--     name,
--     salary,
--     FIRST_VALUE(name) OVER (
--         PARTITION BY department
--         ORDER BY salary DESC, name
--         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
--     ) AS top_earner,
--     LAST_VALUE(name) OVER (
--         PARTITION BY department
--         ORDER BY salary DESC, name
--         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
--     ) AS bottom_earner,
--     NTH_VALUE(name, 2) OVER (
--         PARTITION BY department
--         ORDER BY salary DESC, name
--         ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
--     ) AS second_highest
-- FROM staff
-- WHERE department = 'Operations'
-- ORDER BY salary DESC, name;

-- =============================================================================
-- Level 14: PERCENT_RANK and CUME_DIST
-- =============================================================================
-- Goal: Place every staff member on a 0-to-1 scale by salary, and compare the two functions, including ties.
-- Analogy: PERCENT_RANK is 'how far down the list are you?' — 0 for the top, 1 for the bottom, formula (rank - 1) / (n - 1). CUME_DIST is 'what share of the group is at this salary or higher?' (because we ordered DESC) and is never 0. People with the same salary share the same value.
SELECT
    name,
    department,
    salary,
    RANK() OVER (ORDER BY salary DESC) AS rnk,
    -- 0 for the top salary, 1 for the bottom; ties share the same value
    ROUND(PERCENT_RANK() OVER (ORDER BY salary DESC), 4) AS pct_rank,
    -- share of the staff who earn at least as much as this person (never 0; top group > 0)
    ROUND(CUME_DIST() OVER (ORDER BY salary DESC), 4) AS cume_dist
FROM staff
ORDER BY salary DESC, name;

-- Try it: Compute RANK, PERCENT_RANK and CUME_DIST for Ireland customers by completed spend, highest spend first.
-- Solution (commented out — uncomment to run):
-- WITH ireland_spend AS (
--     SELECT
--         c.customer_id,
--         c.name,
--         ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS total_spend
--     FROM customers AS c
--     JOIN orders AS o
--         ON o.customer_id = c.customer_id
--     JOIN order_items AS oi
--         ON oi.order_id = o.order_id
--     WHERE o.status = 'completed'
--       AND c.country = 'Ireland'
--     GROUP BY c.customer_id, c.name
-- )
-- SELECT
--     customer_id,
--     name,
--     total_spend,
--     RANK() OVER (ORDER BY total_spend DESC) AS rnk,
--     ROUND(PERCENT_RANK() OVER (ORDER BY total_spend DESC), 4) AS pct_rank,
--     ROUND(CUME_DIST() OVER (ORDER BY total_spend DESC), 4) AS cume_dist
-- FROM ireland_spend
-- ORDER BY total_spend DESC, name;

-- =============================================================================
-- Level 15: Capstone — customer report plus a named WINDOW clause
-- =============================================================================
-- Goal: Build one customer report: first order, last order, order count, spend rank within the country, share of country spend, usual gap between orders, days since the last order (as of 2025-06-30), and a gap-based churn flag. The WINDOW clause names the two windows so we do not repeat the OVER text. The first query shows Ireland (9 customers, easy to check). The second lists customers flagged At risk.
-- Analogy: A one-page account review. Rank and share use a named window: w_rank is ordered (for RANK), w_share has no ORDER BY (so SUM is the full country total, not a running total). Churn rule: At risk if it has been at least 90 days since the last completed order AND that gap is more than twice the customer's usual gap between orders (or more than twice 45 days if they have only one order). That is why Ethan Kelly (142 days, usual gap 100) stays Active — 142 is not greater than 200 — while a one-order customer whose last order was a year ago is At risk.
WITH order_totals AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS order_revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY o.customer_id, o.order_id, o.order_date
),
gaps AS (
    SELECT
        customer_id,
        order_id,
        CAST(
            julianday(order_date) - julianday(
                LAG(order_date) OVER (
                    PARTITION BY customer_id
                    ORDER BY order_date, order_id
                )
            ) AS INTEGER
        ) AS gap_days
    FROM order_totals
),
usual_gaps AS (
    SELECT
        customer_id,
        ROUND(AVG(gap_days), 1) AS usual_gap_days
    FROM gaps
    WHERE gap_days IS NOT NULL
    GROUP BY customer_id
),
customer_stats AS (
    SELECT
        o.customer_id,
        MIN(o.order_date) AS first_order,
        MAX(o.order_date) AS last_order,
        COUNT(*) AS order_count,
        ROUND(SUM(o.order_revenue), 2) AS total_spend,
        CAST(
            julianday('2025-06-30') - julianday(MAX(o.order_date))
            AS INTEGER
        ) AS days_since_last
    FROM order_totals AS o
    GROUP BY o.customer_id
)
SELECT
    c.customer_id,
    c.name,
    c.country,
    s.first_order,
    s.last_order,
    s.order_count,
    s.total_spend,
    RANK() OVER w_rank AS spend_rank_in_country,
    ROUND(
        100.0 * s.total_spend / SUM(s.total_spend) OVER w_share,
        2
    ) AS pct_of_country_spend,
    g.usual_gap_days,
    s.days_since_last,
    CASE
        WHEN s.days_since_last >= 90
         AND s.days_since_last > 2 * COALESCE(g.usual_gap_days, 45)
        THEN 'At risk'
        ELSE 'Active'
    END AS churn_flag
FROM customers AS c
JOIN customer_stats AS s
    ON s.customer_id = c.customer_id
LEFT JOIN usual_gaps AS g
    ON g.customer_id = c.customer_id
WHERE c.country = 'Ireland'
WINDOW
    w_rank AS (PARTITION BY c.country ORDER BY s.total_spend DESC),
    w_share AS (PARTITION BY c.country)          -- no ORDER BY: full country total
ORDER BY spend_rank_in_country, c.name;

-- Customers flagged At risk, longest time since last order first (60 rows).
WITH order_totals AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS order_revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY o.customer_id, o.order_id, o.order_date
),
gaps AS (
    SELECT
        customer_id,
        order_id,
        CAST(
            julianday(order_date) - julianday(
                LAG(order_date) OVER (
                    PARTITION BY customer_id
                    ORDER BY order_date, order_id
                )
            ) AS INTEGER
        ) AS gap_days
    FROM order_totals
),
usual_gaps AS (
    SELECT
        customer_id,
        ROUND(AVG(gap_days), 1) AS usual_gap_days
    FROM gaps
    WHERE gap_days IS NOT NULL
    GROUP BY customer_id
),
customer_stats AS (
    SELECT
        o.customer_id,
        MIN(o.order_date) AS first_order,
        MAX(o.order_date) AS last_order,
        COUNT(*) AS order_count,
        ROUND(SUM(o.order_revenue), 2) AS total_spend,
        CAST(
            julianday('2025-06-30') - julianday(MAX(o.order_date))
            AS INTEGER
        ) AS days_since_last
    FROM order_totals AS o
    GROUP BY o.customer_id
),
scored AS (
    SELECT
        c.customer_id,
        c.name,
        c.country,
        s.first_order,
        s.last_order,
        s.order_count,
        s.total_spend,
        RANK() OVER w_rank AS spend_rank_in_country,
        ROUND(
            100.0 * s.total_spend / SUM(s.total_spend) OVER w_share,
            2
        ) AS pct_of_country_spend,
        g.usual_gap_days,
        s.days_since_last,
        CASE
            WHEN s.days_since_last >= 90
             AND s.days_since_last > 2 * COALESCE(g.usual_gap_days, 45)
            THEN 'At risk'
            ELSE 'Active'
        END AS churn_flag
    FROM customers AS c
    JOIN customer_stats AS s
        ON s.customer_id = c.customer_id
    LEFT JOIN usual_gaps AS g
        ON g.customer_id = c.customer_id
    WINDOW
        w_rank AS (PARTITION BY c.country ORDER BY s.total_spend DESC),
        w_share AS (PARTITION BY c.country)
)
SELECT
    customer_id,
    name,
    country,
    last_order,
    order_count,
    total_spend,
    spend_rank_in_country,
    usual_gap_days,
    days_since_last,
    churn_flag
FROM scored
WHERE churn_flag = 'At risk'
ORDER BY days_since_last DESC, name;

-- Try it: Run the same report for Spain, including the churn flag, ordered by spend_rank_in_country.
-- Solution (commented out — uncomment to run):
-- WITH order_totals AS (
--     SELECT
--         o.customer_id,
--         o.order_id,
--         o.order_date,
--         SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS order_revenue
--     FROM orders AS o
--     JOIN order_items AS oi
--         ON oi.order_id = o.order_id
--     WHERE o.status = 'completed'
--     GROUP BY o.customer_id, o.order_id, o.order_date
-- ),
-- gaps AS (
--     SELECT
--         customer_id,
--         CAST(
--             julianday(order_date) - julianday(
--                 LAG(order_date) OVER (
--                     PARTITION BY customer_id
--                     ORDER BY order_date, order_id
--                 )
--             ) AS INTEGER
--         ) AS gap_days
--     FROM order_totals
-- ),
-- usual_gaps AS (
--     SELECT
--         customer_id,
--         ROUND(AVG(gap_days), 1) AS usual_gap_days
--     FROM gaps
--     WHERE gap_days IS NOT NULL
--     GROUP BY customer_id
-- ),
-- customer_stats AS (
--     SELECT
--         o.customer_id,
--         MIN(o.order_date) AS first_order,
--         MAX(o.order_date) AS last_order,
--         COUNT(*) AS order_count,
--         ROUND(SUM(o.order_revenue), 2) AS total_spend,
--         CAST(
--             julianday('2025-06-30') - julianday(MAX(o.order_date))
--             AS INTEGER
--         ) AS days_since_last
--     FROM order_totals AS o
--     GROUP BY o.customer_id
-- ),
-- scored AS (
--     SELECT
--         c.customer_id,
--         c.name,
--         c.country,
--         s.first_order,
--         s.last_order,
--         s.order_count,
--         s.total_spend,
--         RANK() OVER w_rank AS spend_rank_in_country,
--         ROUND(
--             100.0 * s.total_spend / SUM(s.total_spend) OVER w_share,
--             2
--         ) AS pct_of_country_spend,
--         g.usual_gap_days,
--         s.days_since_last,
--         CASE
--             WHEN s.days_since_last >= 90
--              AND s.days_since_last > 2 * COALESCE(g.usual_gap_days, 45)
--             THEN 'At risk'
--             ELSE 'Active'
--         END AS churn_flag
--     FROM customers AS c
--     JOIN customer_stats AS s
--         ON s.customer_id = c.customer_id
--     LEFT JOIN usual_gaps AS g
--         ON g.customer_id = c.customer_id
--     WINDOW
--         w_rank AS (PARTITION BY c.country ORDER BY s.total_spend DESC),
--         w_share AS (PARTITION BY c.country)
-- )
-- SELECT
--     customer_id,
--     name,
--     country,
--     first_order,
--     last_order,
--     order_count,
--     total_spend,
--     spend_rank_in_country,
--     pct_of_country_spend,
--     usual_gap_days,
--     days_since_last,
--     churn_flag
-- FROM scored
-- WHERE country = 'Spain'
-- ORDER BY spend_rank_in_country, name;

-- =============================================================================
-- Cheat sheet
-- =============================================================================
-- Anatomy
--   FUNC(...) OVER (
--       PARTITION BY groups
--       ORDER BY sort_cols
--       ROWS BETWEEN frame_start AND frame_end
--   )
--
-- Grand total / percent of total
--   SUM(amount) OVER ()
--   100.0 * amount / SUM(amount) OVER ()
--
-- Total or average of a group, written on each row
--   SUM(salary) OVER (PARTITION BY department)
--   AVG(salary) OVER (PARTITION BY department)
--
-- Ranking (put ROW_NUMBER in a CTE to filter top-N)
--   ROW_NUMBER() OVER (PARTITION BY grp ORDER BY metric DESC, tiebreaker)
--   RANK()       OVER (PARTITION BY grp ORDER BY metric DESC)
--   DENSE_RANK() OVER (PARTITION BY grp ORDER BY metric DESC)
--   NTILE(4)     OVER (ORDER BY metric)     -- 1 = lowest if you sort ASC
--
-- Running total and moving average
--   SUM(v) OVER (ORDER BY dt ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
--   SUM(v) OVER (PARTITION BY grp ORDER BY dt ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
--   AVG(v) OVER (ORDER BY dt ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
--
-- ROWS vs RANGE (duplicate dates)
--   ROWS  = one physical row at a time
--   RANGE = include every row that shares the current ORDER BY value
--   Default frame when ORDER BY is present: RANGE ... CURRENT ROW
--
-- Peek at neighbours
--   LAG(v, 1)  OVER (PARTITION BY customer ORDER BY order_date)
--   LEAD(v, 1) OVER (ORDER BY year_month)
--
-- First / last / nth in a group — use a full frame
--   FIRST_VALUE(name) OVER (PARTITION BY dept ORDER BY salary DESC, name
--       ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
--   LAST_VALUE(name)  OVER ( ... same full frame ... )
--   NTH_VALUE(name, 2) OVER ( ... same full frame ... )
--
-- Position on a 0-to-1 scale
--   PERCENT_RANK() OVER (ORDER BY salary DESC)   -- 0 for the first
--   CUME_DIST()    OVER (ORDER BY salary DESC)   -- never 0
--
-- Named windows (write the definition once)
--   SELECT
--       RANK() OVER w_rank,
--       SUM(spend) OVER w_share
--   FROM ...
--   WINDOW
--       w_rank  AS (PARTITION BY country ORDER BY spend DESC),
--       w_share AS (PARTITION BY country)
--
-- Common mistakes
--   1. You cannot use a window result in WHERE of the same query.
--      Wrap it in a CTE, then filter.
--   2. LAST_VALUE (and NTH_VALUE) need
--      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
--      or they often just return the current row.
--   3. A running total needs ORDER BY (and usually an explicit ROWS frame).
--      SUM(v) OVER () is a grand total, not a running total.
--      SUM(v) OVER (PARTITION BY grp ORDER BY dt) uses RANGE by default,
--      so same-date rows share one running total.


-- =============================================================================
-- Common mistakes (run the good versions; the first two bad snippets error)
-- =============================================================================

-- Mistake 1 — cannot filter on a window result in the same WHERE
-- Bad (do not run, or run it once to read the error):
--   SELECT name, salary, ROW_NUMBER() OVER (ORDER BY salary DESC) AS rn
--   FROM staff
--   WHERE rn = 1;
-- Error: misuse of aliased window function rn
--
-- Also bad: putting the window function itself in WHERE
--   SELECT name, salary FROM staff
--   WHERE ROW_NUMBER() OVER (ORDER BY salary DESC) = 1;
-- Error: misuse of window function ROW_NUMBER()
--
-- Good: wrap in a CTE, then filter.
WITH ranked AS (
    SELECT
        name,
        salary,
        ROW_NUMBER() OVER (ORDER BY salary DESC, name) AS rn
    FROM staff
)
SELECT name, salary, rn
FROM ranked
WHERE rn = 1;

-- Mistake 2 — LAST_VALUE default frame (before / after)
-- Before: default frame ends at the current row, so the "last" value walks
-- down the list with you.
SELECT
    name,
    salary,
    LAST_VALUE(name) OVER (
        ORDER BY salary DESC, name
    ) AS last_value_default
FROM staff
WHERE department = 'Sales'
ORDER BY salary DESC, name;

-- After: extend the frame to the end of the partition.
SELECT
    name,
    salary,
    LAST_VALUE(name) OVER (
        ORDER BY salary DESC, name
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_in_list
FROM staff
WHERE department = 'Sales'
ORDER BY salary DESC, name;

-- Mistake 3 — forgetting ORDER BY on a running total (before / after)
-- Before: every Books month shows the same full total.
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date) AS year_month,
        p.category,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    JOIN products AS p
        ON p.product_id = oi.product_id
    WHERE o.status = 'completed'
      AND p.category = 'Books'
    GROUP BY strftime('%Y-%m', o.order_date), p.category
)
SELECT
    year_month,
    revenue,
    -- forgotten ORDER BY: every row gets the same full total, not a running total
    ROUND(SUM(revenue) OVER (), 2) AS not_a_running_total
FROM monthly
ORDER BY year_month;

-- After: ORDER BY plus a ROWS frame gives a true running total.
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date) AS year_month,
        p.category,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON oi.order_id = o.order_id
    JOIN products AS p
        ON p.product_id = oi.product_id
    WHERE o.status = 'completed'
      AND p.category = 'Books'
    GROUP BY strftime('%Y-%m', o.order_date), p.category
)
SELECT
    year_month,
    revenue,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY year_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_revenue
FROM monthly
ORDER BY year_month;

-- =============================================================================
-- End of script
-- =============================================================================
