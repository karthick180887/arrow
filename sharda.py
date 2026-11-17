import sqlite3

# Use the same connection you already have
conn = sqlite3.connect("C:/Users/labadmin/Downloads/retail(1).db")

# List all tables in the database
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = cursor.fetchall()
print("Tables in this database:", tables)
