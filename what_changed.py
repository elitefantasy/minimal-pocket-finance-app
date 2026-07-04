#! python
"""
What Changed
------------

A lightweight change tracker for any project.

Features
--------
• Detects Added / Modified / Deleted / Renamed files
• Copies only changed files into whatchangedfolder/
• Preserves folder structure
• Stores previous state in .whatchanged_state.json
• Generates changes.txt
• Generates prompt_for_chatgpt.txt

No external libraries required.
"""

# ============================================================
# APPLICATION INFO
# ============================================================

APP_NAME = "What Changed"

APP_VERSION = "1.0.0"

PROJECT_NAME = "Finance Manager"

import os
import sys
import json
import hashlib
import shutil
import argparse
from pathlib import Path
from datetime import datetime
import zipfile

# ============================================================
# CONFIGURATION
# ============================================================

OUTPUT_FOLDER_NAME = "whatchangedfolder"
EXPORT_FOLDER_NAME = "chatgpt_export"
STATE_FOLDER_NAME = "state"
STATE_FILE_NAME = ".whatchanged_state.json"
INFO_FILE_NAME = ".whatchanged_info.json"
BACKUP_STATE_FILE_NAME = ".whatchanged_state_backup.json"

CHANGES_REPORT_FILE = "changes.txt"
CHANGES_JSON_FILE = "changes.json"
PROMPT_FILE = "prompt_for_chatgpt.txt"

IGNORE_FOLDERS = {
    ".git",
    ".idea",
    ".vscode",
    "__pycache__",
    ".dart_tool",
    "build",
    "dist",
    ".gradle",
    ".next",
    ".vs",
    OUTPUT_FOLDER_NAME,
}

IGNORE_FILES = {
    ".DS_Store",
    "Thumbs.db",
    Path(__file__).name,
}

IGNORE_EXTENSIONS = {
    ".apk",
    ".aab",
    ".ipa",
    ".pyc",
    ".log",
    ".tmp",
    ".cache",
    ".sqlite",
    ".sqlite3",
}

PRESERVE_FOLDER_STRUCTURE = False

FORCE_INCLUDE_FILES = set()
FORCE_INCLUDE_FOLDERS = set()
ONLY_EXTENSIONS = set()

INTERACTIVE_MODE = True
CREATE_ZIP_DEFAULT = False
SHOW_IGNORED = False

ALWAYS_COPY_FILES = {
    "pubspec.yaml",
    "README.md",
}

ALWAYS_COPY_FOLDERS = set()

ROOT = Path(__file__).resolve().parent
OUTPUT_PATH = ROOT / OUTPUT_FOLDER_NAME
EXPORT_PATH = OUTPUT_PATH / EXPORT_FOLDER_NAME
STATE_PATH_FOLDER = OUTPUT_PATH / STATE_FOLDER_NAME
STATE_PATH = STATE_PATH_FOLDER / STATE_FILE_NAME
INFO_PATH = STATE_PATH_FOLDER / INFO_FILE_NAME
BACKUP_STATE_PATH = STATE_PATH_FOLDER / BACKUP_STATE_FILE_NAME

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            chunk = f.read(1024 * 1024)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()

def should_ignore(relative_path: Path):
    rel = str(relative_path).replace("\\", "/")
    if rel in FORCE_INCLUDE_FILES:
        return False
    for folder in FORCE_INCLUDE_FOLDERS:
        if rel.startswith(folder):
            return False
    if relative_path.name in IGNORE_FILES:
        return True
    if relative_path.suffix.lower() in IGNORE_EXTENSIONS:
        return True
    if ONLY_EXTENSIONS:
        if relative_path.suffix.lower() not in ONLY_EXTENSIONS:
            return True
    for part in relative_path.parts:
        if part in IGNORE_FOLDERS:
            return True
    return False

def scan_project():
    files = {}
    for root, dirs, filenames in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in IGNORE_FOLDERS]
        for file in filenames:
            full = Path(root) / file
            rel = full.relative_to(ROOT)
            if should_ignore(rel):
                continue
            try:
                stat = full.stat()
                files[str(rel).replace("\\", "/")] = {
                    "hash": sha256(full),
                    "size": stat.st_size,
                    "mtime": stat.st_mtime,
                }
            except Exception:
                pass
    return files

def load_state():
    if not STATE_PATH.exists():
        return {}
    with open(STATE_PATH, "r", encoding="utf8") as f:
        return json.load(f)

def save_state(state):
    if STATE_PATH.exists():
        try:
            shutil.copy2(STATE_PATH, BACKUP_STATE_PATH)
        except Exception:
            pass
    with open(STATE_PATH, "w", encoding="utf8") as f:
        json.dump(state, f, indent=4)

def undo_last_action():
    if not BACKUP_STATE_PATH.exists():
        print(c("\n[!] No undo history found. Cannot revert.", Color.RED))
        return False
    try:
        if STATE_PATH.exists():
            os.remove(STATE_PATH)
        shutil.copy2(BACKUP_STATE_PATH, STATE_PATH)
        os.remove(BACKUP_STATE_PATH)
        clean_output()
        print(c("\n[✓] Success: Last action has been undone!", Color.GREEN))
        print("The database state was reverted and exported files were cleared.")
        return True
    except Exception as e:
        print(c(f"\n[!] Failed to complete undo operation: {e}", Color.RED))
        return False

def save_export_info():
    info = {
        "project": PROJECT_NAME,
        "version": APP_VERSION,
        "last_export": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    with open(INFO_PATH, "w", encoding="utf8") as f:
        json.dump(info, f, indent=4)

def load_export_info():
    if not INFO_PATH.exists():
        return None
    with open(INFO_PATH, "r", encoding="utf8") as f:
        return json.load(f)

def ensure_output():
    OUTPUT_PATH.mkdir(exist_ok=True)
    EXPORT_PATH.mkdir(exist_ok=True)
    STATE_PATH_FOLDER.mkdir(exist_ok=True)

def clean_output():
    if EXPORT_PATH.exists():
        shutil.rmtree(EXPORT_PATH)
    EXPORT_PATH.mkdir(parents=True, exist_ok=True)

def generate_flat_filename(relative_file: Path):
    filename = relative_file.name
    candidate = filename
    parents = list(relative_file.parents[:-1])
    parents.reverse()
    for parent in reversed(parents):
        if str(parent) == ".":
            continue
        if not (EXPORT_PATH / candidate).exists():
            return candidate
        candidate = f"{parent.name}_{candidate}"
    counter = 1
    stem = Path(candidate).stem
    suffix = Path(candidate).suffix
    while (EXPORT_PATH / candidate).exists():
        candidate = f"{stem}_{counter}{suffix}"
        counter += 1
    return candidate

def copy_file(relative_file):
    relative_file = Path(relative_file)
    src = ROOT / relative_file
    if PRESERVE_FOLDER_STRUCTURE:
        dst = EXPORT_PATH / relative_file
    else:
        unique_name = generate_flat_filename(relative_file)
        dst = EXPORT_PATH / unique_name 
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)

def detect_changes(old_state, new_state):
    added = []
    modified = []
    deleted = []
    moved = []
    old_paths = set(old_state.keys())
    new_paths = set(new_state.keys())
    added = sorted(new_paths - old_paths)
    deleted = sorted(old_paths - new_paths)
    for path in sorted(old_paths & new_paths):
        if old_state[path]["hash"] != new_state[path]["hash"]:
            modified.append(path)
    remaining_added = []
    remaining_deleted = deleted.copy()
    for add in added:
        add_hash = new_state[add]["hash"]
        found = False
        for old in deleted:
            if old not in remaining_deleted:
                continue
            if old_state[old]["hash"] == add_hash:
                moved.append((old, add))
                remaining_deleted.remove(old)
                found = True
                break
        if not found:
            remaining_added.append(add)
    added = remaining_added
    deleted = remaining_deleted
    return sorted(added), sorted(modified), sorted(deleted), sorted(moved)

def write_changes_file(added, modified, deleted, moved):
    report = EXPORT_PATH / CHANGES_REPORT_FILE
    with open(report, "w", encoding="utf8") as f:
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        f.write("What Changed Report\n===================\n\n")
        f.write(f"Generated: {now}\n\n")
        f.write(f"Added ({len(added)})\n" + "-" * 40 + "\n")
        if added:
            for item in added: f.write(item + "\n")
        else: f.write("None\n")
        f.write(f"\nModified ({len(modified)})\n" + "-" * 40 + "\n")
        if modified:
            for item in modified: f.write(item + "\n")
        else: f.write("None\n")
        f.write(f"\nDeleted ({len(deleted)})\n" + "-" * 40 + "\n")
        if deleted:
            for item in deleted: f.write(item + "\n")
        else: f.write("None\n")
        f.write(f"\nMoved / Renamed ({len(moved)})\n" + "-" * 40 + "\n")
        if moved:
            for old, new in moved: f.write(f"{old}\n -> {new}\n\n")
        else: f.write("None\n")

def write_prompt_file(added, modified, deleted, moved):
    prompt = EXPORT_PATH / PROMPT_FILE
    with open(prompt, "w", encoding="utf8") as f:
        f.write("Project Update\n=========================\n\n")
        f.write("Please update my project using ONLY the files contained in this folder.\n\n")
        if added:
            f.write("Added Files\n-----------------\n")
            for x in added: f.write(f"- {x}\n")
            f.write("\n")
        if modified:
            f.write("Modified Files\n-----------------\n")
            for x in modified: f.write(f"- {x}\n")
            f.write("\n")
        if deleted:
            f.write("Deleted Files\n-----------------\n")
            for x in deleted: f.write(f"- {x}\n")
            f.write("\n")
        if moved:
            f.write("Moved / Renamed\n-----------------\n")
            for old, new in moved: f.write(f"- {old} -> {new}\n")
            f.write("\n")
        f.write("Assume every other file in the project remains unchanged.\n")

def copy_changed_files(added, modified, copied_files):
    copied = 0
    for file in added + modified:
        if file in copied_files:
            continue
        try:
            copy_file(file)
            copied_files.add(file)
            copied += 1
        except Exception as e:
            print(f"Failed to copy '{file}': {e}")
    return copied

class Color:
    RESET = "\033[0m"
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    CYAN = "\033[96m"
    BOLD = "\033[1m"

def supports_color():
    return sys.stdout.isatty() and os.name != "nt"

USE_COLOR = supports_color()

def c(text, color):
    if USE_COLOR: return color + text + Color.RESET
    return text

def print_header():
    ensure_output()
    print("=" * 60)
    print(f"{APP_NAME} v{APP_VERSION}")
    print(f"Project : {PROJECT_NAME}")
    print("=" * 60)
    info = load_export_info()
    if info: print(f"Last successful export : {info['last_export']}")
    else: print("Last successful export : Never")
    print()

def print_summary(added, modified, deleted, moved, copied):
    print()
    print(c(f"Added     : {len(added)}", Color.GREEN))
    print(c(f"Modified  : {len(modified)}", Color.YELLOW))
    print(c(f"Deleted   : {len(deleted)}", Color.RED))
    print(c(f"Moved     : {len(moved)}", Color.CYAN))
    print(f"\nCopied    : {copied}")
    print(f"Export Folder    : {EXPORT_FOLDER_NAME}\n")

def print_dry_run_summary(added, modified, deleted, moved):
    print()
    print("=" * 60)
    print("DRY RUN COMPLETE")
    print("=" * 60)
    print("\nNothing has been copied.\nBaseline has NOT been updated.\n")
    print("Export Summary\n" + "-" * 30)
    print(f"Added      : {len(added)}")
    print(f"Modified   : {len(modified)}")
    print(f"Deleted    : {len(deleted)}")
    print(f"Moved      : {len(moved)}")
    total = len(added) + len(modified)
    print("-" * 30)
    print(f"Files that would be copied : {total}")
    if ALWAYS_COPY_FILES:
        print("\nAlways copied files:")
        for file in sorted(ALWAYS_COPY_FILES): print(f"  • {file}")
    print()

def print_stats(state):
    total_size = 0
    for data in state.values(): total_size += data["size"]
    print("\nProject Statistics\n------------------")
    print(f"Tracked files : {len(state)}")
    print(f"Total size    : {round(total_size/1024/1024,2)} MB\n")

def parse_args():
    parser = argparse.ArgumentParser(description="Track project changes.")
    parser.add_argument("--dry", action="store_true", help="Show changes only.")
    parser.add_argument("--reset", action="store_true", help="Create a new baseline.")
    parser.add_argument("--clean", action="store_true", help="Delete folder contents.")
    parser.add_argument("--stats", action="store_true", help="Show project statistics.")
    parser.add_argument("--zip", action="store_true", help="Create a ZIP after exporting.")
    parser.add_argument("--yes", action="store_true", help="Skip confirmation.")
    parser.add_argument("--note", action="store_true", help="Add a project note.")
    parser.add_argument("--verbose", action="store_true", help="Show detailed lists.")
    return parser.parse_args()

def copy_always_files(copied_files):
    copied = 0
    for file in sorted(ALWAYS_COPY_FILES):
        src = ROOT / file
        if not src.exists():
            print(f"Warning: '{file}' does not exist.")
            continue
        if file in copied_files:
            continue
        copy_file(file)
        copied_files.add(file)
        copied += 1
    for folder in sorted(ALWAYS_COPY_FOLDERS):
        folder_path = ROOT / folder
        if not folder_path.exists():
            print(f"Warning: Folder '{folder}' does not exist.")
            continue
        for file in folder_path.rglob("*"):
            if not file.is_file(): continue
            rel = str(file.relative_to(ROOT)).replace("\\", "/")
            if rel in copied_files: continue
            copy_file(rel)
            copied_files.add(rel)
            copied += 1
    return copied

def interactive_menu():
    print("=" * 60)
    print(f"{PROJECT_NAME} - What Changed")
    print("=" * 60)
    print("\nChoose an action\n----------------")
    print("1. Export changed files")
    print("2. Dry run")
    print("3. Undo last action")
    print("4. Reset baseline")
    print("5. Show detailed file list")
    print("6. Quit")
    while True:
        choice = input("\nEnter choice (1-6): ").strip()
        if choice in ("1", "2", "3", "4", "5", "6"):
            return choice
        print("Invalid choice. Please enter a number between 1-6.")

def create_zip():
    zip_name = ROOT / ("whatchanged_" + datetime.now().strftime("%Y-%m-%d_%H-%M-%S") + ".zip")
    with zipfile.ZipFile(zip_name, "w", zipfile.ZIP_DEFLATED) as z:
        for file in OUTPUT_PATH.rglob("*"):
            if file.is_file(): z.write(file, file.relative_to(ROOT))
    print(f"ZIP created: {zip_name.name}")

# ============================================================
# MAIN PROGRAM
# ============================================================

def main():
    args = parse_args()
    print_header()

    if args.clean:
        clean_output()
        print("Output folder cleaned.")
        return
    
    # Core persistent engine loop
    while True: 
        current_state = scan_project()

        if args.stats:
            print_stats(current_state)
            return

        if args.reset:
            save_state(current_state)
            clean_output()
            print("Baseline has been recreated.")
            print(f"Tracked files : {len(current_state)}")
            return

        previous_state = load_state()

        if not previous_state:
            save_state(current_state)
            clean_output()
            print("\nNo previous database found.\nCurrent project saved as the baseline.")
            print("\nRun the script again after making changes to detect modifications.")
            return

        added, modified, deleted, moved = detect_changes(previous_state, current_state)

        # Show state indicators if present
        if added or modified or deleted or moved:
            print()
            if added:
                print(f"Added ({len(added)})")
                for f in added: print("  +", f)
            if modified:
                print(f"Modified ({len(modified)})")
                for f in modified: print("  *", f)
            if deleted:
                print(f"Deleted ({len(deleted)})")
                for f in deleted: print("  -", f)
            if moved:
                print(f"Moved ({len(moved)})")
                for old, new in moved: print(f"  > {old}\n    -> {new}")
            print()

        # Command-line automation overrides
        if args.dry:
            print_dry_run_summary(added, modified, deleted, moved)
            return

        # Interactive Mode Choice Cycle
        if INTERACTIVE_MODE and not args.yes:
            action_chosen = False
            
            while not action_chosen:
                choice = interactive_menu()

                if choice == "1":
                    action_chosen = True  # Breaks loop to perform production copy execution

                elif choice == "2":
                    print_dry_run_summary(added, modified, deleted, moved)
                    # Loop resets back down to present choices cleanly

                elif choice == "3":
                    if undo_last_action():
                        break # Re-evaluates target files instantly using the restored backup dataset
                    else:
                        continue

                elif choice == "4":
                    save_state(current_state)
                    clean_output()
                    print("\n[✓] Baseline has been reset successfully.")
                    break # Breaks directory validation loop to calculate the fresh base reference

                elif choice == "5":
                    print("\nAdded\n" + "-" * 30)
                    if added:
                        for f in added: print(f"+ {f}")
                    else: print("None")
                    print("\nModified\n" + "-" * 30)
                    if modified:
                        for f in modified: print(f"* {f}")
                    else: print("None")
                    print("\nDeleted\n" + "-" * 30)
                    if deleted:
                        for f in deleted: print(f"- {f}")
                    else: print("None")
                    print("\nMoved\n" + "-" * 30)
                    if moved:
                        for old, new in moved: print(f"{old} -> {new}")
                    else: print("None")

                elif choice == "6":
                    print("\nOperation cancelled.")
                    return # Safely breaks process string execution completely

            if choice in ("3", "4"):
                continue # Loops process cycle to run matching directory footprint scan updates

        # Production Execution Sequence (Option 1 Selected)
        copied_files = set()
        clean_output()

        copied = copy_changed_files(added, modified, copied_files)
        copied += copy_always_files(copied_files)
        
        write_changes_file(added, modified, deleted, moved)
        write_prompt_file(added, modified, deleted, moved)

        if args.zip or CREATE_ZIP_DEFAULT:
            create_zip()

        save_state(current_state)
        save_export_info()

        print_summary(added, modified, deleted, moved, copied)

        print("\n--- Restarting File Tracker Scan ---\n")

if __name__ == "__main__":
    main()