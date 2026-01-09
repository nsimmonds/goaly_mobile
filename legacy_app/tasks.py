import sqlite3
import sys

DB_NAME = 'tasks.db'

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
    c.execute('SELECT id, description, completed FROM tasks')
    tasks = c.fetchall()
    conn.close()
    for tid, desc, comp in tasks:
        status = '✓' if comp else ' '
        print(f'[{status}] {tid}: {desc}')

def complete_task(task_id):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute('UPDATE tasks SET completed = 1 WHERE id = ?', (task_id,))
    conn.commit()
    conn.close()
    print(f'Task {task_id} marked as completed.')

def main():
    init_db()
    if len(sys.argv) < 2:
        print('Usage: python tasks.py [add "task desc" | list | complete TASK_ID]')
        return
    cmd = sys.argv[1]
    if cmd == 'add' and len(sys.argv) >= 3:
        add_task(' '.join(sys.argv[2:]))
    elif cmd == 'list':
        list_tasks()
    elif cmd == 'complete' and len(sys.argv) == 3:
        complete_task(sys.argv[2])
    else:
        print('Invalid command or arguments.')

if __name__ == '__main__':
    main()