# Databricks notebook source
# 1. ABSTRACTION
class BankAccount():

    def __init__(self, name, account_number, balance):
        self.name = name
        self.account_number = account_number

        # 2. ENCAPSULATION
        self.__balance = balance
        self.__transactions = []

    def get_balance(self):
        return self.__balance

    def get_transactions(self):
        return self.__transactions.copy()

    def deposit(self, amount):
        if amount <= 0:
            print("Invalid deposit amount")
            return

        self.__balance += amount
        self.__transactions.append(
            f"Deposited: Rs.{amount}"
        )
        print(f"Deposited Rs.{amount}")

    def _deduct_balance(self, amount):
        self.__balance -= amount
        self.__transactions.append(
            f"Withdrawn: Rs.{amount}"
        )

    @abstractmethod
    def withdraw(self, amount):
        pass

    def show_details(self):
        print("Customer:", self.name)
        print("Account:", self.account_number)
        print("Balance: Rs.", self.__balance)


# 3. INHERITANCE
class SavingsAccount(BankAccount):

    # 4. METHOD OVERRIDING
    def withdraw(self, amount):
        if amount <= 0:
            print("Invalid withdrawal amount")

        elif self.get_balance() - amount < 1000:
            print("Savings: Minimum Rs.1000 required")

        else:
            self._deduct_balance(amount)
            print(f"Savings: Withdrawn Rs.{amount}")


class CurrentAccount(BankAccount):

    # METHOD OVERRIDING
    def withdraw(self, amount):
        if amount <= 0:
            print("Invalid withdrawal amount")

        elif amount > self.get_balance():
            print("Current: Insufficient balance")

        else:
            self._deduct_balance(amount)
            print(f"Current: Withdrawn Rs.{amount}")


# 5. CLASS AND OBJECT
savings = SavingsAccount("Karthick", 101, 10000)
current = CurrentAccount("Selvam", 102, 20000)


print("=== SAVINGS ACCOUNT ===")
savings.show_details()
savings.deposit(5000)
savings.withdraw(3000)
print("Final Balance:", savings.get_balance())


print("\n=== CURRENT ACCOUNT ===")
current.show_details()
current.deposit(10000)
current.withdraw(25000)
print("Final Balance:", current.get_balance())


# 6. POLYMORPHISM
print("\n=== POLYMORPHISM ===")

accounts = [savings, current]

for account in accounts:
    account.withdraw(500)
    print("Balance:", account.get_balance())


# TRANSACTION HISTORY
print("\n=== TRANSACTION HISTORY ===")

for transaction in savings.get_transactions():
    print(transaction)


# COMMAND ----------

