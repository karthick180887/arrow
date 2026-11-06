# Databricks notebook source
class Animal:
    def __init__(self):
        print("Animal Created")
    def whoami(self):
        print("Animal")
    def eat(self):
        print("Eating")
        

# COMMAND ----------

class dog(Animal):
    def __init__(self):
        Animal.__init__(self)
        print("Dog Created")
    def whoami(self):
        print("Dog")
    def bark(self):
        print("Woof!")

# COMMAND ----------

a = Animal()

# COMMAND ----------

d = dog()

# COMMAND ----------

d.bark()

# COMMAND ----------

d.eat()

# COMMAND ----------

d.bark()

# COMMAND ----------

d.whoami()

# COMMAND ----------

