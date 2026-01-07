import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import sqlite3
import threading
import time
from datetime import datetime
from emoji_config import *

class GoalyGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Goaly - Pomodoro Timer with Task Management")
        self.root.geometry("600x500")
        self.root.configure(bg='#f0f0f0')
        
        # Timer variables
        self.is_running = False
        self.timer_thread = None
        self.work_minutes = 25
        self.break_minutes = 5
        
        # Database
        self.db_name = 'tasks.db'
        self.init_db()
        
        self.setup_ui()
        
    def init_db(self):
        conn = sqlite3.connect(self.db_name)
        c = conn.cursor()
        c.execute('''CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0
        )''')
        conn.commit()
        conn.close()
    
    def setup_ui(self):
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        main_frame.rowconfigure(2, weight=1)
        
        # Title
        title_label = ttk.Label(main_frame, text=f"{EMOJI_GOAL} Goaly Pomodoro Timer", 
                               font=('Arial', 16, 'bold'))
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 10))
        
        # Current task display
        self.task_frame = ttk.LabelFrame(main_frame, text="Current Task", padding="10")
        self.task_frame.grid(row=1, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 10))
        
        self.current_task_label = ttk.Label(self.task_frame, text="No task selected", 
                                           font=('Arial', 12))
        self.current_task_label.grid(row=0, column=0, sticky=(tk.W, tk.E))
        
        # Timer display
        self.timer_frame = ttk.LabelFrame(main_frame, text="Timer", padding="10")
        self.timer_frame.grid(row=2, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        
        self.timer_label = ttk.Label(self.timer_frame, text="Ready to start", 
                                    font=('Arial', 14, 'bold'))
        self.timer_label.grid(row=0, column=0, pady=(0, 10))
        
        # Progress bar
        self.progress_var = tk.DoubleVar()
        self.progress_bar = ttk.Progressbar(self.timer_frame, variable=self.progress_var, 
                                           maximum=100, length=400)
        self.progress_bar.grid(row=1, column=0, pady=(0, 10))
        
        # Timer output
        self.output_frame = ttk.LabelFrame(main_frame, text="Timer Output", padding="5")
        self.output_frame.grid(row=3, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 10))
        
        self.output_text = scrolledtext.ScrolledText(self.output_frame, height=8, width=70)
        self.output_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Control buttons
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=4, column=0, columnspan=3, pady=(10, 0))
        
        self.start_button = ttk.Button(button_frame, text="Start Timer", command=self.start_timer)
        self.start_button.grid(row=0, column=0, padx=(0, 10))
        
        self.stop_button = ttk.Button(button_frame, text="Stop Timer", command=self.stop_timer, state='disabled')
        self.stop_button.grid(row=0, column=1, padx=(0, 10))
        
        self.add_task_button = ttk.Button(button_frame, text="Add Task", command=self.add_task_dialog)
        self.add_task_button.grid(row=0, column=2, padx=(0, 10))
        
        self.list_tasks_button = ttk.Button(button_frame, text="List Tasks", command=self.list_tasks)
        self.list_tasks_button.grid(row=0, column=3)
        
        # Configure grid weights for output frame
        self.output_frame.columnconfigure(0, weight=1)
        self.output_frame.rowconfigure(0, weight=1)
        
    def log_message(self, message):
        timestamp = datetime.now().strftime("%H:%M:%S")
        self.output_text.insert(tk.END, f"[{timestamp}] {message}\n")
        self.output_text.see(tk.END)
        self.root.update_idletasks()
    
    def get_random_task(self):
        conn = sqlite3.connect(self.db_name)
        c = conn.cursor()
        c.execute('SELECT id, description FROM tasks WHERE completed = 0 ORDER BY RANDOM() LIMIT 1')
        task = c.fetchone()
        conn.close()
        return task
    
    def update_task_display(self, task):
        if task:
            task_id, task_desc = task
            self.current_task_label.config(text=f"[{task_id}] {task_desc}")
        else:
            self.current_task_label.config(text="No tasks available - add some tasks!")
    
    def start_timer(self):
        if self.is_running:
            return
            
        self.is_running = True
        self.start_button.config(state='disabled')
        self.stop_button.config(state='normal')
        
        self.timer_thread = threading.Thread(target=self.timer_loop, daemon=True)
        self.timer_thread.start()
    
    def stop_timer(self):
        self.is_running = False
        self.start_button.config(state='normal')
        self.stop_button.config(state='disabled')
        self.timer_label.config(text="Timer stopped")
        self.progress_var.set(0)
        self.log_message(f"{EMOJI_STOP} Timer stopped by user")
    
    def timer_loop(self):
        while self.is_running:
            # Get a random task
            task = self.get_random_task()
            self.root.after(0, self.update_task_display, task)
            
            if task:
                task_id, task_desc = task
                self.log_message(f"{EMOJI_GOAL} Selected task: [{task_id}] {task_desc}")
            else:
                self.log_message(f"{EMOJI_GOAL} No tasks available - time to add some!")
            
            # Work session
            if not self.is_running:
                break
                
            self.root.after(0, lambda: self.timer_label.config(text=f"{EMOJI_TIMER} Work Session ({self.work_minutes} minutes)"))
            self.log_message(f"{EMOJI_TIMER} Starting work session ({self.work_minutes} minutes)")
            
            for minute in range(self.work_minutes):
                if not self.is_running:
                    break
                    
                progress = (minute / self.work_minutes) * 100
                self.root.after(0, self.progress_var.set, progress)
                
                if task:
                    message = f"Work on: {task_desc}. Minute: {minute + 1} out of {self.work_minutes}"
                else:
                    message = f"Work! Minute {minute + 1} out of {self.work_minutes})"
                
                self.log_message(message)
                time.sleep(60)
            
            if not self.is_running:
                break
                
            self.log_message(f"{EMOJI_SUCCESS} Work session complete!")
            
            # Break session
            self.root.after(0, lambda: self.timer_label.config(text=f"{EMOJI_BREAK} Break Session ({self.break_minutes} minutes)"))
            self.log_message(f"{EMOJI_BREAK} Starting break session ({self.break_minutes} minutes)")
            
            for minute in range(self.break_minutes):
                if not self.is_running:
                    break
                    
                progress = (minute / self.break_minutes) * 100
                self.root.after(0, self.progress_var.set, progress)
                
                message = f"Play! ({minute + 1}/{self.break_minutes})"
                self.log_message(message)
                time.sleep(60)
            
            if not self.is_running:
                break
                
            self.log_message(f"{EMOJI_CELEBRATE} Break complete! Ready for next round?")
            self.root.after(0, self.progress_var.set, 0)
    
    def add_task_dialog(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("Add New Task")
        dialog.geometry("400x165")
        dialog.transient(self.root)
        dialog.grab_set()
        
        ttk.Label(dialog, text="Task description:").pack(pady=(20, 5))
        
        task_entry = ttk.Entry(dialog, width=50)
        task_entry.pack(pady=(0, 20))
        task_entry.focus()
        
        def add_task():
            description = task_entry.get().strip()
            if description:
                conn = sqlite3.connect(self.db_name)
                c = conn.cursor()
                c.execute('INSERT INTO tasks (description) VALUES (?)', (description,))
                conn.commit()
                conn.close()
                self.log_message(f"{EMOJI_SUCCESS} Task added: {description}")
                dialog.destroy()
        
        def cancel():
            dialog.destroy()
        
        button_frame = ttk.Frame(dialog)
        button_frame.pack(pady=20)
        
        ttk.Button(button_frame, text="Add", command=add_task).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(button_frame, text="Cancel", command=cancel).pack(side=tk.LEFT)
        
        # Bind Enter key to add task
        dialog.bind('<Return>', lambda e: add_task())
    
    def list_tasks(self):
        # Create task management window
        task_window = tk.Toplevel(self.root)
        task_window.title("Task Manager")
        task_window.geometry("500x450")
        task_window.transient(self.root)
        task_window.grab_set()
        
        # Main frame
        main_frame = ttk.Frame(task_window, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Title
        title_label = ttk.Label(main_frame, text=f"{EMOJI_TASKS} Task Manager", font=('Arial', 14, 'bold'))
        title_label.pack(pady=(0, 10))
        
        # Task list frame
        list_frame = ttk.LabelFrame(main_frame, text="Tasks", padding="10")
        list_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        # Create treeview for tasks
        columns = ('ID', 'Description', 'Status')
        tree = ttk.Treeview(list_frame, columns=columns, show='headings', height=15)
        
        # Configure columns
        tree.heading('ID', text='ID')
        tree.heading('Description', text='Description')
        tree.heading('Status', text='Status')
        tree.column('ID', width=50)
        tree.column('Description', width=300)
        tree.column('Status', width=100)
        
        # Scrollbar
        scrollbar = ttk.Scrollbar(list_frame, orient=tk.VERTICAL, command=tree.yview)
        tree.configure(yscrollcommand=scrollbar.set)
        
        tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Button frame
        button_frame = ttk.Frame(main_frame)
        button_frame.pack(fill=tk.X, pady=(10, 0))
        
        def refresh_tasks():
            # Clear existing items
            for item in tree.get_children():
                tree.delete(item)
            
            # Load tasks from database
            conn = sqlite3.connect(self.db_name)
            c = conn.cursor()
            c.execute('SELECT id, description, completed FROM tasks ORDER BY id')
            tasks = c.fetchall()
            conn.close()
            
            # Configure tags once
            tree.tag_configure('completed', foreground='gray')
            
            # Add tasks to treeview
            for tid, desc, comp in tasks:
                status = "Completed" if comp else "Incomplete"
                item = tree.insert('', tk.END, values=(tid, desc, status))
                
                # Apply gray color for completed tasks
                if comp:
                    tree.item(item, tags=('completed',))
        
        def mark_complete():
            selected_item = tree.selection()
            if not selected_item:
                return
            
            item = tree.item(selected_item[0])
            task_id = item['values'][0]
            status = item['values'][2]
            
            if status == "Completed":
                return  # Already completed
            
            conn = sqlite3.connect(self.db_name)
            c = conn.cursor()
            c.execute('UPDATE tasks SET completed = 1 WHERE id = ?', (task_id,))
            conn.commit()
            conn.close()
            
            self.log_message(f"{EMOJI_SUCCESS} Task {task_id} marked as completed")
            refresh_tasks()
        
        def delete_task():
            selected_item = tree.selection()
            if not selected_item:
                return
            
            item = tree.item(selected_item[0])
            task_id = item['values'][0]
            task_desc = item['values'][1]
            
            # Confirm deletion
            confirm = tk.messagebox.askyesno("Confirm Delete", 
                                           f"Are you sure you want to delete task {task_id}: '{task_desc}'?")
            if not confirm:
                return
            
            conn = sqlite3.connect(self.db_name)
            c = conn.cursor()
            c.execute('DELETE FROM tasks WHERE id = ?', (task_id,))
            conn.commit()
            conn.close()
            
            self.log_message(f"{EMOJI_DELETE} Task {task_id} deleted")
            refresh_tasks()
        
        def add_new_task():
            # Create add task dialog
            add_dialog = tk.Toplevel(task_window)
            add_dialog.title("Add New Task")
            add_dialog.geometry("400x165")
            add_dialog.transient(task_window)
            add_dialog.grab_set()
            
            ttk.Label(add_dialog, text="Task description:").pack(pady=(20, 5))
            
            task_entry = ttk.Entry(add_dialog, width=50)
            task_entry.pack(pady=(0, 20))
            task_entry.focus()
            
            def add_task():
                description = task_entry.get().strip()
                if description:
                    conn = sqlite3.connect(self.db_name)
                    c = conn.cursor()
                    c.execute('INSERT INTO tasks (description) VALUES (?)', (description,))
                    conn.commit()
                    conn.close()
                    self.log_message(f"{EMOJI_SUCCESS} Task added: {description}")
                    add_dialog.destroy()
                    refresh_tasks()
            
            def cancel():
                add_dialog.destroy()
            
            button_frame = ttk.Frame(add_dialog)
            button_frame.pack(pady=20)
            
            ttk.Button(button_frame, text="Add", command=add_task).pack(side=tk.LEFT, padx=(0, 10))
            ttk.Button(button_frame, text="Cancel", command=cancel).pack(side=tk.LEFT)
            
            add_dialog.bind('<Return>', lambda e: add_task())
        
        # Buttons
        ttk.Button(button_frame, text="Mark Complete", command=mark_complete).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(button_frame, text="Delete Task", command=delete_task).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(button_frame, text="Add Task", command=add_new_task).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(button_frame, text="Refresh", command=refresh_tasks).pack(side=tk.LEFT, padx=(0, 10))
        ttk.Button(button_frame, text="Close", command=task_window.destroy).pack(side=tk.RIGHT)
        
        # Load initial tasks
        refresh_tasks()

def main():
    root = tk.Tk()
    app = GoalyGUI(root)
    root.mainloop()

if __name__ == '__main__':
    main() 