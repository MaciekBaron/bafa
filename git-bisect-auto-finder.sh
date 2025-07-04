#!/bin/bash

# Git Bisect Jumper - Automatically find a good commit and then bisect
# Usage: git-bisect-jumper.sh [<jump_size>] <test_command>
# <jump_size>: Optional. Number of commits to jump back at a time (default: 10).
# <test_command>: The command to run to test if a commit is good (exits 0 for good, non-0 for bad).
#
# Example: git-bisect-jumper.sh 20 "npm test"
# Example (default jump size): git-bisect-jumper.sh "make test"

set -e

JUMP_SIZE_DEFAULT=10
JUMP_SIZE=$JUMP_SIZE_DEFAULT
TEST_COMMAND=""

# Parse arguments
if [ $# -eq 1 ]; then
    TEST_COMMAND="$1"
elif [ $# -eq 2 ]; then
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        JUMP_SIZE="$1"
        TEST_COMMAND="$2"
    else
        echo "Error: <jump_size> must be a number."
        echo "Usage: $0 [<jump_size>] <test_command>"
        exit 1
    fi
else
    echo "Usage: $0 [<jump_size>] <test_command>"
    echo "Example: $0 20 'npm test'"
    echo "Example (default jump size): $0 'make test'"
    exit 1
fi

# Ensure we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository."
    exit 1
fi

# Store the initial HEAD commit, which is assumed to be bad
INITIAL_BAD_COMMIT=$(git rev-parse HEAD)
echo "Current HEAD ($INITIAL_BAD_COMMIT) is assumed to be the bad commit."
echo "Searching for a good commit by jumping $JUMP_SIZE commits at a time..."
echo "Test command: $TEST_COMMAND"
echo

FOUND_GOOD_COMMIT=""
CURRENT_OFFSET=0
TEMP_SCRIPT=$(mktemp)

# Create a temporary script for the test command
cat > "$TEMP_SCRIPT" << EOF
#!/bin/bash
set -e
$TEST_COMMAND
EOF
chmod +x "$TEMP_SCRIPT"

# Loop backward in history to find a good commit
while true; do
    CURRENT_OFFSET=$((CURRENT_OFFSET + JUMP_SIZE))
    CANDIDATE_COMMIT_REF="HEAD~${CURRENT_OFFSET}"
    CANDIDATE_COMMIT_HASH=$(git rev-parse --verify "$CANDIDATE_COMMIT_REF" 2>/dev/null)

    if [ -z "$CANDIDATE_COMMIT_HASH" ]; then
        echo "Error: Reached the beginning of the repository history without finding a good commit."
        echo "Please ensure your test command is reliable and that a good commit exists in the history."
        rm -f "$TEMP_SCRIPT"
        exit 1
    fi

    echo "Checking commit: $CANDIDATE_COMMIT_HASH (approx. $CURRENT_OFFSET commits back from HEAD)"

    # Checkout the candidate commit and run the test
    git checkout "$CANDIDATE_COMMIT_HASH" > /dev/null 2>&1
    if "$TEMP_SCRIPT"; then
        echo "Commit $CANDIDATE_COMMIT_HASH is GOOD!"
        FOUND_GOOD_COMMIT="$CANDIDATE_COMMIT_HASH"
        break # Found a good commit, exit the loop
    else
        echo "Commit $CANDIDATE_COMMIT_HASH is BAD. Jumping further back..."
    fi
done

# Return to the initial bad commit before starting bisect
echo "Returning to initial bad commit: $INITIAL_BAD_COMMIT"
git checkout "$INITIAL_BAD_COMMIT" > /dev/null 2>&1

echo
echo "Starting git bisect with:"
echo "  Bad commit: $INITIAL_BAD_COMMIT"
echo "  Good commit: $FOUND_GOOD_COMMIT"
echo "  Test command: $TEST_COMMAND"
echo

# Start bisect
git bisect start

# Mark the known bad commit
git bisect bad "$INITIAL_BAD_COMMIT"

# Mark the known good commit
git bisect good "$FOUND_GOOD_COMMIT"

# Run automatic bisect
echo "Running automatic bisect..."
git bisect run "$TEMP_SCRIPT"

# Clean up
rm -f "$TEMP_SCRIPT"

echo
echo "Bisect complete! The first bad commit has been identified above."
echo "To reset bisect state, run: git bisect reset"
