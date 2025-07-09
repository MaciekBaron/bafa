#!/bin/bash

# git-claude-worktree.sh
# Automates the creation of a Git worktree and symlinks CLAUDE*.md files from the
# main worktree to the new one.

# Function to display usage instructions
usage() {
    echo "Usage: $0 <new_worktree_path> [<commit-ish_or_branch>]"
    echo ""
    echo "  <new_worktree_path>: The path where the new Git worktree will be created."
    echo "                       This path can be relative or absolute."
    echo "  <commit-ish_or_branch>: Optional. The commit, branch, or tag to base the"
    echo "                          new worktree on. If omitted, Git's default behavior applies."
    echo ""
    echo "Example:"
    echo "  $0 ../feature-x-worktree feature/my-new-feature"
    echo "  $0 /tmp/hotfix-worktree hotfix/urgent-bug"
    exit 1
}

# --- Pre-checks ---

# Check if Git is installed and available in the PATH
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed or not found in your system's PATH."
    exit 1
fi

# Check if the script is being run from within a Git repository
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "Error: You must run this script from within an existing Git repository's worktree."
    exit 1
fi

# Check for 'realpath' command (common on Linux, installable on macOS via Homebrew coreutils)
if ! command -v realpath &> /dev/null; then
    echo "Error: 'realpath' command not found. Please install coreutils (e.g., 'brew install coreutils' on macOS)."
    exit 1
fi

# --- Argument Parsing ---

NEW_WORKTREE_PATH="$1"
shift # Remove the first argument, remaining arguments are for 'git worktree add'

# Ensure the new worktree path is provided
if [ -z "$NEW_WORKTREE_PATH" ]; then
    echo "Error: Missing <new_worktree_path> argument."
    usage
fi

# Get the absolute root path of the current (main) Git worktree
MAIN_WORKTREE_ROOT=$(git rev-parse --show-toplevel)
echo "Source (main) worktree root: $MAIN_WORKTREE_ROOT"

# --- Create New Git Worktree ---

# Construct the 'git worktree add' command with all provided arguments
GIT_WORKTREE_ADD_CMD="git worktree add \"$NEW_WORKTREE_PATH\""
if [ "$#" -gt 0 ]; then
    # Append any additional arguments (like branch name or commit-ish)
    GIT_WORKTREE_ADD_CMD+=" \"$@\""
fi

echo "Attempting to create new worktree:"
echo "  Command: $GIT_WORKTREE_ADD_CMD"

# Execute the git worktree add command
# 'eval' is used here to correctly handle cases where arguments might contain spaces or special characters
# within quotes, ensuring they are passed to git worktree add as single arguments.
eval "$GIT_WORKTREE_ADD_CMD"

# Check the exit status of the previous command
if [ $? -ne 0 ]; then
    echo "Error: 'git worktree add' failed. Please check the output above."
    exit 1
fi

# Get the absolute path of the newly created worktree
# This is crucial because NEW_WORKTREE_PATH might have been relative.
NEW_WORKTREE_ABS_PATH=$(realpath "$NEW_WORKTREE_PATH")
echo "New worktree created at: $NEW_WORKTREE_ABS_PATH"

# --- Symlink CLAUDE*.md files ---

echo "Searching for CLAUDE*.md files in '$MAIN_WORKTREE_ROOT' to symlink..."

# Find all CLAUDE*.md files directly in the root of the main worktree
# -maxdepth 1 ensures only files in the root are found, not subdirectories.
# This assumes your CLAUDE*.md files are in the main worktree's top-level directory.
CLAUDE_FILES=$(find "$MAIN_WORKTREE_ROOT" -maxdepth 1 -name "CLAUDE*.md")

if [ -z "$CLAUDE_FILES" ]; then
    echo "No CLAUDE*.md files found in the source worktree. No symlinks will be created."
else
    echo "Found CLAUDE*.md files. Creating symlinks in the new worktree:"
    # Loop through each found file and create a symlink
    for SOURCE_FILE_PATH in $CLAUDE_FILES; do
        FILE_NAME=$(basename "$SOURCE_FILE_PATH") # Get just the filename (e.g., CLAUDE.md)

        # Calculate the relative path from the *new worktree* to the *original file*
        # This makes the symlink portable if the entire repository is moved.
        RELATIVE_SYMLINK_TARGET=$(realpath --relative-to="$NEW_WORKTREE_ABS_PATH" "$SOURCE_FILE_PATH")

        DESTINATION_SYMLINK_PATH="$NEW_WORKTREE_ABS_PATH/$FILE_NAME"

        # Check if a file or symlink with the same name already exists in the destination
        if [ -e "$DESTINATION_SYMLINK_PATH" ]; then
            echo "  Warning: '$DESTINATION_SYMLINK_PATH' already exists. Skipping symlink for '$FILE_NAME'."
            continue
        fi

        echo "  Creating symlink: '$FILE_NAME' -> '$RELATIVE_SYMLINK_TARGET'"
        # Use -s for symbolic link
        ln -s "$RELATIVE_SYMLINK_TARGET" "$DESTINATION_SYMLINK_PATH"

        if [ $? -ne 0 ]; then
            echo "  Error: Failed to create symlink for '$FILE_NAME'. You may need to create it manually."
        fi
    done
fi

echo ""
echo "Automation complete!"
echo "--------------------"
echo "Important: Ensure 'CLAUDE*.md' (or similar patterns) are correctly listed in your project's .gitignore file."
echo "You can now navigate into your new worktree: 'cd $NEW_WORKTREE_PATH'"
