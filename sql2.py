import sqlite3
import pandas as pd

conn = sqlite3.connect("retail.db")

def sql(query, params=()):
    return pd.read_sql_query(query, conn, params=params)

print("SQLite version:", sqlite3.sqlite_version)

# Get all table names
tables = sql(
    "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
)["name"]

# print(tables)

# Display table name, row count, and column names
df = pd.DataFrame({
    "table": tables,
    "rows": [
        conn.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0]
        for t in tables
    ],
    "columns": [
        ",".join(
            row[1] for row in conn.execute(f'PRAGMA table_info("{t}")')
        )
        for t in tables
    ],
})

# print(df)

# customers = sql("SELECT * FROM customers limit 5")
# print(customers.to_string(index=False))

# customers = sql("SELECT * FROM orders limit 5")
# print(customers.to_string(index=False))

innerjoin = sql("""
    SELECT
        o.order_id,
        o.order_date,
        o.status,
        c.name AS customer,
        c.country
    FROM orders AS o
    INNER JOIN customers AS c
        ON c.customer_id = o.customer_id
    ORDER BY o.order_id
    LIMIT 10
""")

print(innerjoin.to_string(index=False))
conn.close()
