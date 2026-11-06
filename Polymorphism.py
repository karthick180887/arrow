# Databricks notebook source
class dog:
    def __init__(self, name):
        self.name = name
    def speak(self):
        return self.name + ' says woof!'

# COMMAND ----------

class cat:
    def __init__(self, name):
        self.name = name
    def speak(self):
        return self.name + ' says meow!'

# COMMAND ----------

niko = dog('niko')

# COMMAND ----------

felix = cat('felix')

# COMMAND ----------

niko.speak()

# COMMAND ----------

felix.speak()

# COMMAND ----------

for pet in [niko, felix]:
    print(pet.speak())

# COMMAND ----------

def pet_speak(pet):
    print(pet.speak())

# COMMAND ----------

pet_speak(niko)

# COMMAND ----------

pet_speak(felix)

# COMMAND ----------

