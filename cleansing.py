from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *

spark = SparkSession.builder.appName("DataCleansing").getOrCreate()

# Sample messy data
data = [
    (1, "  John Doe  ", "john.doe@email.com", "25", "2023-01-15", 50000.0, "New York"),
    (2, "Jane Smith", "jane@email.com", "30", "15/02/2023", None, "new york"),
    (3, "  John Doe  ", "john.doe@email.com", "25", "2023-01-15", 50000.0, "New York"),  # duplicate
    (4, "Bob Johnson", None, "abc", "2023-03-20", 45000.5, "Chicago"),
    (5, "Alice Brown", "alice@email.com", "28", None, 60000.0, "  Los Angeles  "),
    (6, "Charlie", "charlie@email.com", "35", "2023-04-01", -1000.0, "Houston"),  # negative salary
    (7, None, "test@email.com", "40", "2023-05-10", 55000.0, "Phoenix"),
    (8, "David Wilson", "david@email.com", "22", "2023-06-15", 48000.0, None),
]

columns = ["id", "name", "email", "age", "join_date", "salary", "city"]

df = spark.createDataFrame(data, columns)
df.show(truncate=False)
