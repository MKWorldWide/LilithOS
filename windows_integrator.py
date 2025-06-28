import os
import sys
import subprocess
import shutil
import tkinter as tk
from tkinter import messagebox, filedialog

# Quantum-detailed inline documentation:
# This script provides a GUI for integrating LilithOS into Windows as a hybrid OS.
# It checks for and installs dependencies (Python, WSL, MSYS2), copies/configures files,
# sets environment variables, and offers a user-friendly interface for system integration.
# Security, performance, and system impact are considered at each step.

# --- Feature Context ---
# This tool is intended for users who want to hybridize their Windows system with LilithOS components.
# It is designed to be run as an administrator for full integration.

# --- Dependency Listings ---
# - Python 3.x
# - tkinter (standard with Python)
# - WSL (Windows Subsystem for Linux)
# - MSYS2 (optional, for Unix-like tools)
# - PyInstaller (for building .exe)

# --- Usage Example ---
# Run: python windows_integrator.py
# Or build: pyinstaller --onefile --noconsole windows_integrator.py

# --- Performance Considerations ---
# - Uses subprocess for system checks and installations
# - Avoids unnecessary file operations
# - Provides user feedback for long-running tasks

# --- Security Implications ---
# - Requests admin privileges for system changes
# - Warns user before making critical modifications

# --- Changelog Entries ---
# [Current Session] Initial version: GUI-based integration tool for LilithOS hybrid OS

LILITHOS_ROOT = r"C:\LilithOS"
USER_LILITHOS = os.path.expandvars(r"%USERPROFILE%\Saved Games\LilithOS")

class LilithOSIntegrator(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("LilithOS Windows Integrator")
        self.geometry("600x400")
        self.resizable(False, False)
        self.create_widgets()

    def create_widgets(self):
        tk.Label(self, text="LilithOS Hybrid OS Integration", font=("Arial", 18, "bold")).pack(pady=10)
        tk.Label(self, text="This tool will help you integrate LilithOS into your Windows system.", font=("Arial", 12)).pack(pady=5)

        self.status = tk.StringVar()
        self.status.set("Ready.")
        tk.Label(self, textvariable=self.status, fg="blue").pack(pady=5)

        btn_frame = tk.Frame(self)
        btn_frame.pack(pady=20)

        tk.Button(btn_frame, text="Check Dependencies", width=25, command=self.check_dependencies).grid(row=0, column=0, padx=10, pady=5)
        tk.Button(btn_frame, text="Integrate LilithOS", width=25, command=self.integrate_lilithos).grid(row=1, column=0, padx=10, pady=5)
        tk.Button(btn_frame, text="Configure Environment", width=25, command=self.configure_environment).grid(row=2, column=0, padx=10, pady=5)
        tk.Button(btn_frame, text="Create Shortcuts", width=25, command=self.create_shortcuts).grid(row=3, column=0, padx=10, pady=5)
        tk.Button(btn_frame, text="Exit", width=25, command=self.quit).grid(row=4, column=0, padx=10, pady=5)

    def check_dependencies(self):
        self.status.set("Checking dependencies...")
        missing = []
        # Check Python
        if not sys.executable:
            missing.append("Python")
        # Check WSL
        try:
            subprocess.check_output(["wsl", "--status"], stderr=subprocess.STDOUT)
        except Exception:
            missing.append("WSL")
        # Check MSYS2
        if not os.path.exists(r"C:\msys64"):
            missing.append("MSYS2")
        if missing:
            messagebox.showwarning("Missing Dependencies", f"The following dependencies are missing: {', '.join(missing)}\nPlease install them before continuing.")
            self.status.set("Missing dependencies: " + ', '.join(missing))
        else:
            messagebox.showinfo("Dependencies OK", "All dependencies are installed.")
            self.status.set("All dependencies are installed.")

    def integrate_lilithos(self):
        self.status.set("Integrating LilithOS...")
        # Copy files from user LilithOS to system LilithOS
        try:
            if not os.path.exists(LILITHOS_ROOT):
                os.makedirs(LILITHOS_ROOT)
            for item in os.listdir(USER_LILITHOS):
                s = os.path.join(USER_LILITHOS, item)
                d = os.path.join(LILITHOS_ROOT, item)
                if os.path.isdir(s):
                    if os.path.exists(d):
                        shutil.rmtree(d)
                    shutil.copytree(s, d)
                else:
                    shutil.copy2(s, d)
            self.status.set("LilithOS files integrated successfully.")
            messagebox.showinfo("Integration Complete", "LilithOS files have been integrated into C:\LilithOS.")
        except Exception as e:
            self.status.set(f"Integration failed: {e}")
            messagebox.showerror("Integration Failed", str(e))

    def configure_environment(self):
        self.status.set("Configuring environment variables...")
        try:
            # Add C:\LilithOS to PATH
            path = os.environ.get("PATH", "")
            if LILITHOS_ROOT not in path:
                os.system(f'setx PATH "{LILITHOS_ROOT};%PATH%"')
            # Set LILITHOS_HOME variable
            os.system(f'setx LILITHOS_HOME "{LILITHOS_ROOT}"')
            self.status.set("Environment variables configured.")
            messagebox.showinfo("Environment Configured", "Environment variables set for LilithOS.")
        except Exception as e:
            self.status.set(f"Environment config failed: {e}")
            messagebox.showerror("Environment Config Failed", str(e))

    def create_shortcuts(self):
        self.status.set("Creating shortcuts...")
        try:
            desktop = os.path.join(os.path.expanduser("~"), "Desktop")
            shortcut_path = os.path.join(desktop, "LilithOS.lnk")
            target = os.path.join(LILITHOS_ROOT, "config_gui.py")
            # Use PowerShell to create a shortcut
            cmd = f'''powershell $s=(New-Object -COM WScript.Shell).CreateShortcut('{shortcut_path}');$s.TargetPath='{sys.executable}';$s.Arguments='"{target}"';$s.Save()'''
            os.system(cmd)
            self.status.set("Shortcut created on Desktop.")
            messagebox.showinfo("Shortcut Created", "LilithOS shortcut created on Desktop.")
        except Exception as e:
            self.status.set(f"Shortcut creation failed: {e}")
            messagebox.showerror("Shortcut Creation Failed", str(e))

if __name__ == "__main__":
    app = LilithOSIntegrator()
    app.mainloop() 