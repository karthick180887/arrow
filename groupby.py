sql("""
SELECT c.name, c.country, COUNT(*) AS orders, MIN(o.order_date) AS first_order, MAX(o.order_date) AS last_order
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
WHERE o.status <> 'cancelled'
GROUP BY c.customer_id, c.name, c.country
HAVING COUNT(*) >= 25
ORDER BY orders DESC
""")
##########################################################################################Conditional Aggregations ##
sql("""
SELECT channel,
       COUNT(*)                                                 AS orders,
       SUM(CASE WHEN status = 'returned' THEN 1 ELSE 0 END)     AS returned,
       COUNT(*) FILTER (WHERE status = 'cancelled')             AS cancelled,
       ROUND(100 * AVG(CASE WHEN status = 'returned' THEN 1.0 ELSE 0 END), 1) AS return_rate_pct
FROM orders
GROUP BY channel
ORDER BY orders DESC
""")
