sql("""
SELECT c.name, c.country, COUNT(*) AS orders, MIN(o.order_date) AS first_order, MAX(o.order_date) AS last_order
FROM orders AS o
JOIN customers AS c ON c.customer_id = o.customer_id
WHERE o.status <> 'cancelled'
GROUP BY c.customer_id, c.name, c.country
HAVING COUNT(*) >= 25
ORDER BY orders DESC
""")
