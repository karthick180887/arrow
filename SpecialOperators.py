# Databricks notebook source
class Book:
    def __init__(self, title, author, year):
        self.title = title
        self.author = author
        self.year = year

    def __str__(self):
        return f"{self.title} by {self.author} ({self.year})"
    
    def __len__(self):
        return len(self.title) + len(self.author) + len(str(self.year))
    
    def __del__(self):
        print(f"Book '{self.title}' by {self.author} ({self.year}) has been deleted.")

# COMMAND ----------

book = Book("The Great Gatsby", "F. Scott Fitzgerald", 1925)
print(book)
print(len(book))
del book

# COMMAND ----------

