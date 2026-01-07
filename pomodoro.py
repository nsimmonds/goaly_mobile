import time

WORK_MINUTES = 25
BREAK_MINUTES = 5

while True:
    for minute in range(WORK_MINUTES):
        print(f"Work! ({minute + 1}/{WORK_MINUTES})")
        time.sleep(60)
    for minute in range(BREAK_MINUTES):
        print(f"Play! ({minute + 1}/{BREAK_MINUTES})")
        time.sleep(60) 