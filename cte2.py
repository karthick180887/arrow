sql("""
WITH order_totals AS (
    SELECT order_id, SUM(quantity * unit_price * (1 - discount)) AS total
    FROM order_items
    GROUP BY order_id
),
customer_spend AS (
    SELECT o.customer_id,
           COUNT(*)     AS orders,
           SUM(t.total) AS spend
    FROM orders AS o
    JOIN order_totals AS t ON t.order_id = o.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY o.customer_id
)
SELECT c.segment,
       COUNT(*)                AS customers,
       ROUND(AVG(s.orders), 1) AS avg_orders,
       ROUND(AVG(s.spend), 2)  AS avg_spend,
       ROUND(SUM(s.spend), 2)  AS total_spend
FROM customer_spend AS s
JOIN customers AS c ON c.customer_id = s.customer_id
GROUP BY c.segment
ORDER BY total_spend DESC
""")
