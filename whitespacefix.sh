#!/bin/bash

# Whitespace Fixer Script
#
# This script cleans up whitespace in text files according to three rules:
# 1. Removes trailing whitespace from the end of all lines.
# 2. Removes any lines that contain only whitespace (e.g., spaces, tabs).
# 3. Ensures the file ends with a single newline character.
#
# Usage: ./whitespace_fixer.sh <file1> [file2] ...

# Check if at least one file was provided as an argument.
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <file1> [file2] ..."
    exit 1
fi

# Loop through each file provided as a command-line argument.
for file in "$@"; do
    # Check if the file exists and is a regular file.
    if [ ! -f "$file" ]; then
        echo "Warning: File '$file' not found or is not a regular file. Skipping."
        continue
    fi

    echo "Processing '$file'..."

    # 1. Remove trailing whitespace from every line.
    #    The `sed` command with `s/[[:space:]]*$//` finds any sequence of whitespace
    #    characters (`[[:space:]]*`) at the end of a line (`$`) and replaces it
    #    with nothing. The `-i` flag means "in-place" editing of the file.
    sed -i 's/[[:space:]]*$//' "$file"

    # 2. Remove lines that consist only of whitespace.
    #    The `sed` command with `/^[[:space:]]*$/d` looks for lines that start (`^`),
    #    contain only whitespace (`[[:space:]]*`), and end (`$`). The `d` command
    #    deletes these matching lines.
    sed -i '/^[[:space:]]*$/d' "$file"

    # 3. Ensure the file ends with a newline.
    #    `tail -c1 "$file"` gets the very last character of the file.
    #    We check if this last character is not empty and not a newline.
    #    If it's not a newline, we append one. This prevents adding a newline
    #    to an already empty file or a file that correctly ends with one.
    if [ -n "$(tail -c1 "$file")" ]; then
        echo "" >> "$file"
    fi
done

echo "Whitespace fixing complete."

