def logging_decorator(func):
    def wrapper():
        print("Start Logging...")
        func()
        print("End Logging...")
    return wrapper

@logging_decorator
def add():
    print("Start Logging")
    print(10+2)


@logging_decorator
def subtract():
    print("Start Logging")
    print(10-2)

add()
subtract()
