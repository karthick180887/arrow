with open("bookings.csv",encoding="utf-8") as file:
    booking_iterator = iter(file)  
    header  = next(booking_iterator)
    while True:
        try:
            booking = next(booking_iterator)
            print(booking)
        except StopIteration:
            break
