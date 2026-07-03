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

# ---------------------------------------------
# OUTPUT FOLDER CONFIGURATION
# ---------------------------------------------
#
# Folder structure after every export:
#
# whatchangedfolder/
#
# ├── state/
# │   ├── .whatchanged_state.json
# │   ├── .whatchanged_info.json
# │   └── .whatchanged_state_backup.json (future)
# │
# └── chatgpt_export/
#     ├── changes.txt
#     ├── changes.json
#     ├── prompt_for_chatgpt.txt
#     ├── lib/
#     ├── assets/
#     └── ...
#
# This keeps exported files separate from the internal
# database used by the script.
# If you ever want to rename a folder (for example,
# "chatgpt_export" to simply "export"), you only need to
# change it here.
#
# Avoid typing folder names as strings elsewhere in the code.
# Main folder created by this application.
OUTPUT_FOLDER_NAME = "whatchangedfolder"

# Folder containing files that will be uploaded to ChatGPT.
EXPORT_FOLDER_NAME = "chatgpt_export"

# Folder containing internal databases and metadata.
STATE_FOLDER_NAME = "state"

# Database filename.
STATE_FILE_NAME = ".whatchanged_state.json"

# Export information filename.
INFO_FILE_NAME = ".whatchanged_info.json"

# Backup database (future feature).
BACKUP_STATE_FILE_NAME = ".whatchanged_state_backup.json"

# ============================================================
# REPORT FILE NAMES
# ============================================================

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

# ============================================================
# EXPORT OPTIONS
# ============================================================
#
# True  -> Keep the original project folder structure.
#
# Example:
# chatgpt_export/
#     lib/
#         main.dart
#
# False -> Copy every file directly into the export folder.
#
# Example:
# chatgpt_export/
#     main.dart
#     dashboard_screen.dart
#     pubspec.yaml
#
# WARNING:
# If multiple files have the same filename but are located in
# different folders, only one can exist in a flat export.
# The script will warn you when this happens.
PRESERVE_FOLDER_STRUCTURE = False
# ============================================================



# Optional

FORCE_INCLUDE_FILES = {
    # "pubspec.yaml",
}

FORCE_INCLUDE_FOLDERS = {
    # "assets"
}

# Empty means copy every extension.
ONLY_EXTENSIONS = set()

# ============================================================
# EXTRA CONFIG
# ============================================================

PROJECT_NAME = "Finance Manager"

INTERACTIVE_MODE = True

CREATE_ZIP_DEFAULT = False

SHOW_IGNORED = False

ALWAYS_COPY_FILES = {
    "pubspec.yaml",
    "README.md",
}

ALWAYS_COPY_FOLDERS = {
    # "assets",
}

# ============================================================

ROOT = Path(__file__).resolve().parent
# ------------------------------------------------------------
# Folder that stores internal databases.
# ------------------------------------------------------------
# ============================================================
# BUILD APPLICATION PATHS
# ============================================================
#
# Convert the folder names above into actual filesystem paths.
#
# Example:
#
# ROOT
#   │
#   └── whatchangedfolder
#          │
#          ├── state
#          └── chatgpt_export
#
# ============================================================

# Main application folder.
OUTPUT_PATH = ROOT / OUTPUT_FOLDER_NAME

# Folder containing exported files.
EXPORT_PATH = OUTPUT_PATH / EXPORT_FOLDER_NAME

# Folder containing internal databases.
STATE_PATH_FOLDER = OUTPUT_PATH / STATE_FOLDER_NAME

# File tracking database.
STATE_PATH = STATE_PATH_FOLDER / STATE_FILE_NAME

# Metadata file.
INFO_PATH = STATE_PATH_FOLDER / INFO_FILE_NAME

# Reserved for future undo support.
BACKUP_STATE_PATH = (
    STATE_PATH_FOLDER / BACKUP_STATE_FILE_NAME
)


# ============================================================

def sha256(path):
    h = hashlib.sha256()

    with open(path, "rb") as f:
        while True:
            chunk = f.read(1024 * 1024)
            if not chunk:
                break
            h.update(chunk)

    return h.hexdigest()


# ============================================================

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


# ============================================================

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


# ============================================================

def load_state():

    if not STATE_PATH.exists():
        return {}

    with open(STATE_PATH, "r", encoding="utf8") as f:
        return json.load(f)


def save_state(state):

    with open(STATE_PATH, "w", encoding="utf8") as f:
        json.dump(state, f, indent=4)

# ============================================================
# EXPORT INFORMATION
# ============================================================

def save_export_info():
    """
    Save information about the most recent successful export.

    This file is separate from the state database because it
    stores metadata rather than tracked files.
    """

    info = {

        "project": PROJECT_NAME,

        "version": APP_VERSION,

        "last_export": datetime.now().strftime(
            "%Y-%m-%d %H:%M:%S"
        )
    }

    with open(INFO_PATH, "w", encoding="utf8") as f:

        json.dump(
            info,
            f,
            indent=4
        )

def load_export_info():
    """
    Read information about the last successful export.

    Returns None if this is the first time the script
    has been executed.
    """

    if not INFO_PATH.exists():
        return None

    with open(INFO_PATH, "r", encoding="utf8") as f:

        return json.load(f)


# ============================================================
# CREATE OUTPUT FOLDERS
# ============================================================

def ensure_output():
    """
    Create all folders required by the application.

    Safe to call multiple times because mkdir() will not
    recreate folders that already exist.
    """

    OUTPUT_PATH.mkdir(exist_ok=True)

    EXPORT_PATH.mkdir(exist_ok=True)

    STATE_PATH_FOLDER.mkdir(exist_ok=True)


# ============================================================
# CLEAN EXPORT FOLDER
# ============================================================

def clean_output():
    """
    Remove ONLY the exported files.

    The state database is preserved so the script still knows
    what changed between exports.
    """

    if EXPORT_PATH.exists():

        shutil.rmtree(EXPORT_PATH)

    EXPORT_PATH.mkdir(parents=True, exist_ok=True)


# ============================================================
# GENERATE EXPORT FILE NAME
# ============================================================
#
# When PRESERVE_FOLDER_STRUCTURE is False, multiple files can
# have the same filename.
#
# Example:
#
# lib/screens/home.dart
# lib/widgets/home.dart
#
# become
#
# home.dart
# widgets_home.dart
#
# If a collision still exists, keep adding parent folder names.
# ============================================================

def generate_flat_filename(relative_file: Path):

    # Original filename.
    filename = relative_file.name

    # First choice.
    candidate = filename

    # Folder names from deepest to root.
    #
    # Example:
    # lib/screens/home.dart
    #
    # becomes
    #
    # ["screens", "lib"]
    parents = list(relative_file.parents[:-1])

    # Remove the project root ('.')
    parents.reverse()

    # Build unique filename.
    #
    # screens_home.dart
    # lib_screens_home.dart
    #
    for parent in reversed(parents):

        if str(parent) == ".":
            continue

        if not (EXPORT_PATH / candidate).exists():
            return candidate

        candidate = f"{parent.name}_{candidate}"

    # Last safety check.
    counter = 1

    stem = Path(candidate).stem
    suffix = Path(candidate).suffix

    while (EXPORT_PATH / candidate).exists():

        candidate = f"{stem}_{counter}{suffix}"

        counter += 1

    return candidate
# ============================================================

def copy_file(relative_file):
    relative_file = Path(relative_file)

    src = ROOT / relative_file
    # Copy into the ChatGPT export folder while preserving
    # the original project structure.
    
    # ------------------------------------------------------------
    # Decide how exported files should be organized.
    # ------------------------------------------------------------

    if PRESERVE_FOLDER_STRUCTURE:

        dst = EXPORT_PATH / relative_file

    else:

        unique_name = generate_flat_filename(relative_file)

        dst = EXPORT_PATH / unique_name 

    dst.parent.mkdir(parents=True, exist_ok=True)

    shutil.copy2(src, dst)

# ============================================================
# CHANGE DETECTION
# ============================================================

def detect_changes(old_state, new_state):
    """
    Compare previous scan with current scan.

    Returns:
        added
        modified
        deleted
        moved
    """

    added = []
    modified = []
    deleted = []
    moved = []

    old_paths = set(old_state.keys())
    new_paths = set(new_state.keys())

    # Simple comparisons
    added = sorted(new_paths - old_paths)
    deleted = sorted(old_paths - new_paths)

    for path in sorted(old_paths & new_paths):
        if old_state[path]["hash"] != new_state[path]["hash"]:
            modified.append(path)

    # --------------------------------------------------------
    # Rename / Move detection
    #
    # If a deleted file has the same SHA256 hash as an added
    # file, assume it was renamed or moved.
    # --------------------------------------------------------

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

    return (
        sorted(added),
        sorted(modified),
        sorted(deleted),
        sorted(moved),
    )


# ============================================================
# REPORT GENERATION
# ============================================================

def write_changes_file(added, modified, deleted, moved):

    report = EXPORT_PATH / CHANGES_REPORT_FILE

    with open(report, "w", encoding="utf8") as f:

        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        f.write("What Changed Report\n")
        f.write("===================\n\n")
        f.write(f"Generated: {now}\n\n")

        f.write(f"Added ({len(added)})\n")
        f.write("-" * 40 + "\n")

        if added:
            for item in added:
                f.write(item + "\n")
        else:
            f.write("None\n")

        f.write("\n")

        f.write(f"Modified ({len(modified)})\n")
        f.write("-" * 40 + "\n")

        if modified:
            for item in modified:
                f.write(item + "\n")
        else:
            f.write("None\n")

        f.write("\n")

        f.write(f"Deleted ({len(deleted)})\n")
        f.write("-" * 40 + "\n")

        if deleted:
            for item in deleted:
                f.write(item + "\n")
        else:
            f.write("None\n")

        f.write("\n")

        f.write(f"Moved / Renamed ({len(moved)})\n")
        f.write("-" * 40 + "\n")

        if moved:
            for old, new in moved:
                f.write(f"{old}\n")
                f.write(f" -> {new}\n\n")
        else:
            f.write("None\n")


# ============================================================
# CHATGPT PROMPT
# ============================================================

def write_prompt_file(added, modified, deleted, moved):

    prompt = EXPORT_PATH / PROMPT_FILE

    with open(prompt, "w", encoding="utf8") as f:

        f.write("Project Update\n")
        f.write("=========================\n\n")

        f.write(
            "Please update my project using ONLY the files "
            "contained in this folder.\n\n"
        )

        if added:
            f.write("Added Files\n")
            f.write("-----------------\n")
            for x in added:
                f.write(f"- {x}\n")
            f.write("\n")

        if modified:
            f.write("Modified Files\n")
            f.write("-----------------\n")
            for x in modified:
                f.write(f"- {x}\n")
            f.write("\n")

        if deleted:
            f.write("Deleted Files\n")
            f.write("-----------------\n")
            for x in deleted:
                f.write(f"- {x}\n")
            f.write("\n")

        if moved:
            f.write("Moved / Renamed\n")
            f.write("-----------------\n")
            for old, new in moved:
                f.write(f"- {old} -> {new}\n")
            f.write("\n")

        f.write(
            "Assume every other file in the project remains unchanged.\n"
        )


# ============================================================
# COPY CHANGED FILES
# ============================================================
#
# Copies all newly added and modified files.
#
# copied_files:
#     A set containing every file copied during this export.
#     It prevents the same file from being copied twice.
# ============================================================

def copy_changed_files(
    added,
    modified,
    copied_files,
):
    copied = 0

    # Process both added and modified files.
    for file in added + modified:

        # Skip files that have already been copied.
        if file in copied_files:
            continue

        try:

            copy_file(file)

            copied_files.add(file)

            copied += 1

        except Exception as e:

            print(f"Failed to copy '{file}'")
            print(e)

    return copied

# ============================================================
# CONSOLE HELPERS
# ============================================================

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
    if USE_COLOR:
        return color + text + Color.RESET
    return text


# ============================================================

def print_header():
    # ------------------------------------------------------------
    # Make sure all required folders exist before doing anything.
    # ------------------------------------------------------------
    ensure_output()

    print("=" * 60)
    print(f"{APP_NAME} v{APP_VERSION}")
    print(f"Project : {PROJECT_NAME}")
    print("=" * 60)

    info = load_export_info()

    if info:

        print(
            f"Last successful export : "
            f"{info['last_export']}"
        )

    else:

        print("Last successful export : Never")

    print()


# ============================================================

def print_summary(added, modified, deleted, moved, copied):

    print()

    print(c(f"Added     : {len(added)}", Color.GREEN))
    print(c(f"Modified  : {len(modified)}", Color.YELLOW))
    print(c(f"Deleted   : {len(deleted)}", Color.RED))
    print(c(f"Moved     : {len(moved)}", Color.CYAN))

    print()

    print(f"Copied    : {copied}")

    print(f"Export Folder    : {EXPORT_FOLDER_NAME}")

    print()


# ============================================================
# DRY RUN SUMMARY
# ============================================================
#
# Displays what WOULD happen if the user performed an export.
#
# No files are copied.
# No reports are generated.
# The baseline database is NOT updated.
# ============================================================

def print_dry_run_summary(
    added,
    modified,
    deleted,
    moved,
):

    print()
    print("=" * 60)
    print("DRY RUN COMPLETE")
    print("=" * 60)

    print()
    print("Nothing has been copied.")
    print("Baseline has NOT been updated.")
    print()

    print("Export Summary")
    print("-" * 30)

    print(f"Added      : {len(added)}")
    print(f"Modified   : {len(modified)}")
    print(f"Deleted    : {len(deleted)}")
    print(f"Moved      : {len(moved)}")

    total = len(added) + len(modified)

    print("-" * 30)
    print(f"Files that would be copied : {total}")

    # Always-copy files
    if ALWAYS_COPY_FILES:

        print()
        print("Always copied files:")

        for file in sorted(ALWAYS_COPY_FILES):

            print(f"  • {file}")

    print()

def print_stats(state):

    total_size = 0

    for data in state.values():
        total_size += data["size"]

    print()

    print("Project Statistics")
    print("------------------")
    print(f"Tracked files : {len(state)}")
    print(f"Total size    : {round(total_size/1024/1024,2)} MB")
    print()


# ============================================================
# COPY ENTIRE PROJECT
# ============================================================

def copy_everything(current_state):

    clean_output()

    copied = 0

    for file in sorted(current_state.keys()):

        try:
            copy_file(file)
            copied += 1
        except Exception:
            pass

    write_changes_file([], list(current_state.keys()), [], [])
    write_prompt_file([], list(current_state.keys()), [], [])

    print(f"Copied {copied} files.")

    return copied


# ============================================================
# COMMAND LINE
# ============================================================

def parse_args():

    parser = argparse.ArgumentParser(
        description="Track project changes."
    )

    parser.add_argument(
        "--dry",
        action="store_true",
        help="Show changes only. Do not copy files."
    )

    parser.add_argument(
        "--reset",
        action="store_true",
        help="Create a new baseline."
    )

    parser.add_argument(
        "--clean",
        action="store_true",
        help="Delete whatchangedfolder contents."
    )

    parser.add_argument(
        "--full",
        action="store_true",
        help="Copy every tracked file."
    )

    parser.add_argument(
        "--stats",
        action="store_true",
        help="Show project statistics."
    )
    
    parser.add_argument(
        "--zip",
        action="store_true",
        help="Create a ZIP after exporting."
    )

    parser.add_argument(
        "--yes",
        action="store_true",
        help="Skip interactive confirmation."
    )

    parser.add_argument(
        "--note",
        action="store_true",
        help="Add a project note to prompt_for_chatgpt.txt."
    )

    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show detailed file lists."
    )

    return parser.parse_args()

# ============================================================
# COPY ALWAYS INCLUDED FILES
# ============================================================
#
# Copies files that should always accompany an export.
#
# Examples:
#     README.md
#     pubspec.yaml
#
# copied_files prevents duplicate copies.
# ============================================================

def copy_always_files(copied_files):
    copied = 0

    # --------------------------------------------------------
    # Copy individual files.
    # --------------------------------------------------------

    for file in sorted(ALWAYS_COPY_FILES):

        src = ROOT / file

        if not src.exists():

            print(f"Warning: '{file}' does not exist.")

            continue

        # Already copied by copy_changed_files().
        if file in copied_files:
            continue

        copy_file(file)

        copied_files.add(file)

        copied += 1

    # --------------------------------------------------------
    # Copy entire folders.
    # --------------------------------------------------------

    for folder in sorted(ALWAYS_COPY_FOLDERS):

        folder_path = ROOT / folder

        if not folder_path.exists():

            print(f"Warning: Folder '{folder}' does not exist.")

            continue

        for file in folder_path.rglob("*"):

            if not file.is_file():
                continue

            rel = str(file.relative_to(ROOT)).replace("\\", "/")

            if rel in copied_files:
                continue

            copy_file(rel)

            copied_files.add(rel)

            copied += 1

    return copied

# ============================================================
# INTERACTIVE MENU
# ============================================================
#
# This menu is shown after changes have been detected.
# It lets the user decide what to do before any files
# are copied or the baseline is updated.
#
# Returns:
#     "1" -> Export changed files
#     "2" -> Dry run
#     "3" -> Export entire project
#     "4" -> Reset baseline
#     "5" -> Show detailed list
#     "6" -> Quit
#
# ============================================================

def interactive_menu():

    print()
    print("=" * 60)
    print(f"{PROJECT_NAME} - What Changed")
    print("=" * 60)

    print()
    print("Choose an action")
    print("----------------")
    print("1. Export changed files")
    print("2. Dry run")
    print("3. Export entire project")
    print("4. Reset baseline")
    print("5. Show detailed file list")
    print("6. Quit")

    while True:

        choice = input("\nEnter choice (1-6): ").strip()

        if choice in ("1", "2", "3", "4", "5", "6"):
            return choice

        print("Invalid choice. Please enter a number between 1 and 6.")

def create_zip():

    zip_name = ROOT / (
        "whatchanged_" +
        datetime.now().strftime("%Y-%m-%d_%H-%M-%S") +
        ".zip"
    )

    with zipfile.ZipFile(zip_name, "w", zipfile.ZIP_DEFLATED) as z:

        for file in OUTPUT_PATH.rglob("*"):

            if file.is_file():

                z.write(
                    file,
                    file.relative_to(ROOT)
                )

    print(f"ZIP created: {zip_name.name}")

# ============================================================
# MAIN PROGRAM
# ============================================================

def main():

    args = parse_args()

    print_header()

    # --------------------------------------------------------

    if args.clean:

        clean_output()

        print("Output folder cleaned.")
        return

    # --------------------------------------------------------

    current_state = scan_project()

    # --------------------------------------------------------

    if args.stats:

        print_stats(current_state)
        return

    # --------------------------------------------------------

    if args.reset:

        save_state(current_state)

        clean_output()

        print("Baseline has been recreated.")
        print(f"Tracked files : {len(current_state)}")
        return
    
   

    # --------------------------------------------------------

    if args.full:

        copy_everything(current_state)

        save_state(current_state)

        return

    # --------------------------------------------------------

    previous_state = load_state()

    # --------------------------------------------------------
    # First run
    # --------------------------------------------------------

    if not previous_state:

        save_state(current_state)

        clean_output()

        print()
        print("No previous database found.")
        print("Current project has been saved as the baseline.")
        print()
        print(
            "Run the script again after making changes "
            "to detect modified files."
        )

        return

    # --------------------------------------------------------

    added, modified, deleted, moved = detect_changes(
        previous_state,
        current_state,
    )

    # --------------------------------------------------------

    if (
        not added
        and not modified
        and not deleted
        and not moved
    ):

        print()
        print("No changes detected.")

        save_state(current_state)

        return

    # --------------------------------------------------------

    print()

    if added:
        print(f"Added ({len(added)})")
        for f in added:
            print("  +", f)
        print()

    if modified:
        print(f"Modified ({len(modified)})")
        for f in modified:
            print("  *", f)
        print()

    if deleted:
        print(f"Deleted ({len(deleted)})")
        for f in deleted:
            print("  -", f)
        print()

    if moved:
        print(f"Moved ({len(moved)})")
        for old, new in moved:
            print(f"  > {old}")
            print(f"    -> {new}")
        print()

    # ------------------------------------------------------------
    # Command-line dry run.
    #
    # Show what would happen without copying files or updating
    # the baseline.
    # ------------------------------------------------------------
    if args.dry:

        print_dry_run_summary(
            added,
            modified,
            deleted,
            moved,
        )

        return

    # ------------------------------------------------------------
    # Interactive menu handling
    #
    # We already know what changed.
    # Now ask the user what they want to do BEFORE
    # we copy files or update the baseline.
    #
    # If the user didn't use the --yes option, ask what to do.
    # ------------------------------------------------------------

    if INTERACTIVE_MODE and not args.yes:

        while True:

            choice = interactive_menu()

            # ----------------------------------------------------
            # Export changed files
            # ----------------------------------------------------
            if choice == "1":
                break

            # ------------------------------------------------------------
            # Interactive dry run.
            # ------------------------------------------------------------
            elif choice == "2":

                print_dry_run_summary(
                    added,
                    modified,
                    deleted,
                    moved,
                )

                return

            # ----------------------------------------------------
            # Export entire project
            # ----------------------------------------------------
            elif choice == "3":

                copy_everything(current_state)

                save_state(current_state)

                return

            # ----------------------------------------------------
            # Reset baseline
            # ----------------------------------------------------
            elif choice == "4":

                save_state(current_state)

                print("\nBaseline has been reset.")

                return

            # ----------------------------------------------------
            # Show detailed file list
            #
            # After showing the list, the menu appears again.
            # ----------------------------------------------------
            elif choice == "5":

                print("\nAdded")
                print("-" * 30)

                if added:
                    for f in added:
                        print(f"+ {f}")
                else:
                    print("None")

                print("\nModified")
                print("-" * 30)

                if modified:
                    for f in modified:
                        print(f"* {f}")
                else:
                    print("None")

                print("\nDeleted")
                print("-" * 30)

                if deleted:
                    for f in deleted:
                        print(f"- {f}")
                else:
                    print("None")

                print("\nMoved")
                print("-" * 30)

                if moved:
                    for old, new in moved:
                        print(f"{old}")
                        print(f" -> {new}")
                else:
                    print("None")

                # Show the menu again.
                continue

            # ----------------------------------------------------
            # Quit without exporting
            # ----------------------------------------------------
            elif choice == "6":

                print("\nOperation cancelled.")

                return

    # ------------------------------------------------------------
    # User chose to export changes.
    # ------------------------------------------------------------

    # ------------------------------------------------------------
    # Keep track of every file copied during this export.
    #
    # This ensures the same file is never copied twice,
    # even if it appears in multiple categories.
    # ------------------------------------------------------------
    copied_files = set()

    clean_output()

    # Copy newly added and modified files.
    copied = copy_changed_files(
        added,
        modified,
        copied_files,
    )

    # Copy files that should always be included.
    copied += copy_always_files(
        copied_files,
    )
    # ------------------------------------------------------------
    
    # Generate report files.
    write_changes_file(
        added,
        modified,
        deleted,
        moved,
    )

    write_prompt_file(
        added,
        modified,
        deleted,
        moved,
    )

    # Optional ZIP creation.
    if args.zip or CREATE_ZIP_DEFAULT:
        create_zip()

    # ------------------------------------------------------------
    # The export completed successfully.
    #
    # Only now should we update the baseline and
    # record the export timestamp.
    # ------------------------------------------------------------
    save_state(current_state)
    save_export_info()

    print_summary(
        added,
        modified,
        deleted,
        moved,
        copied,
    )

# ============================================================
# PROGRAM ENTRY POINT
# ============================================================

if __name__ == "__main__":
    main()