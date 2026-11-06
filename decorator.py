def logging_decorator(func):
    def wrapper():
        print("Start Logging...")
        func()
        print("End Logging...")
    return wrapper

def add():
    print("Start Logging")
    print(10+2)

def subtract():
    print("Start Logging")
    print(10-2)


log = logging_decorator(add)
log()

sub_log = logging_decorator(subtract)
sub_log()
