import sqlite3
import sys
import time
import threading
import signal
from emoji_config import *

DB_NAME = 'tasks.db'
WORK_MINUTES = 25
BREAK_MINUTES = 5

def init_db():
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0
    )''')
    conn.commit()
    conn.close()

def add_task(description):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('INSERT INTO tasks (description) VALUES (?)', (description,))
    conn.commit()
    conn.close()
    print(f'Task added: {description}')

def list_tasks():
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('SELECT id, description, completed FROM tasks WHERE completed = 0')
    tasks = c.fetchall()
    conn.close()
    
    if not tasks:
        print("No incomplete tasks found.")
        return
    
    print("\nIncomplete tasks:")
    for tid, desc, comp in tasks:
        print(f'[{tid}] {desc}')

def complete_task(task_id):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('UPDATE tasks SET completed = 1 WHERE id = ?', (task_id,))
    if c.rowcount > 0:
        conn.commit()
        print(f'Task {task_id} marked as completed.')
    else:
        print(f'Task {task_id} not found.')
    conn.close()

def get_random_task():
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('SELECT id, description FROM tasks WHERE completed = 0 ORDER BY RANDOM() LIMIT 1')
    task = c.fetchone()
    conn.close()
    return task

def start_timer():
    print("\n=== Goaly Pomodoro Timer ===")
    print("Press Ctrl+C to stop the timer\n")
    
    try:
        while True:
            # Get a random incomplete task
            task = get_random_task()
            if task:
                task_id, task_desc = task
                print(f"{EMOJI_GOAL} Current task: [{task_id}] {task_desc}")
            else:
                print(f"{EMOJI_GOAL} No tasks available - time to add some!")
            
            # Work session
            print(f"\n{EMOJI_TIMER} Work session ({WORK_MINUTES} minutes)")
            for minute in range(WORK_MINUTES):
                if task:
                    print(f"Work on: {task_desc} ({minute + 1}/{WORK_MINUTES})")
                else:
                    print(f"Work! ({minute + 1}/{WORK_MINUTES})")
                time.sleep(60)
            
            print(f"\n{EMOJI_SUCCESS} Work session complete!")
            
            # Break session
            print(f"\n{EMOJI_BREAK} Break session ({BREAK_MINUTES} minutes)")
            for minute in range(BREAK_MINUTES):
                print(f"Play! ({minute + 1}/{BREAK_MINUTES})")
                time.sleep(60)
            
            print(f"\n{EMOJI_CELEBRATE} Break complete! Ready for next round?\n")
            
    except KeyboardInterrupt:
        print(f"\n\n{EMOJI_STOP}  Timer stopped. Good work!")

def show_help():
    print("""
Goaly - Pomodoro Timer with Task Management

Usage: python goaly.py [command] [arguments]

Commands:
  add "task description"    Add a new task
  list                     Show all incomplete tasks
  complete TASK_ID         Mark a task as completed
  start                    Start the pomodoro timer
  help                     Show this help message

Examples:
  python goaly.py add "Write documentation"
  python goaly.py list
  python goaly.py complete 1
  python goaly.py start
""")

def main():
    init_db()
    
    if len(sys.argv) < 2:
        show_help()
        return
    
    command = sys.argv[1].lower()
    
    if command == 'add' and len(sys.argv) >= 3:
        add_task(' '.join(sys.argv[2:]))
    elif command == 'list':
        list_tasks()
    elif command == 'complete' and len(sys.argv) == 3:
        complete_task(sys.argv[2])
    elif command == 'start':
        start_timer()
    elif command == 'help':
        show_help()
    else:
        print("Invalid command. Use 'python goaly.py help' for usage information.")

if __name__ == '__main__':
    main() 