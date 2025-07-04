#!/bin/bash

# Git Bisect Auto - Automatically find the breaking commit
# Usage: git-bisect-auto.sh [<good_commit>] <test_command>
# If <good_commit> is not provided, the current commit (HEAD) is assumed bad
# and its parent (HEAD^) is assumed good.
# Example: git-bisect-auto.sh HEAD~10 "npm test"
# Example (auto-assume good/bad): git-bisect-auto.sh "npm test"

set -e

GOOD_COMMIT=""
TEST_COMMAND=""

# Determine arguments based on count
if [ $# -eq 1 ]; then
    # Only test command provided, assume auto mode
    TEST_COMMAND="$1"
    echo "No good commit provided. Assuming current commit (HEAD) is 'bad' and its parent (HEAD^) is 'good'."
    echo "To explicitly set good/bad commits, use: $0 <good_commit> <test_command>"
elif [ $# -eq 2 ]; then
    # Both good commit and test command provided
    GOOD_COMMIT="$1"
    TEST_COMMAND="$2"
else
    echo "Usage: $0 [<good_commit>] <test_command>"
    echo "Example: $0 HEAD~10 'npm test'"
    echo "Example (auto-assume good/bad): $0 'npm test'"
    exit 1
fi

# Ensure we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Determine actual good and bad commits for bisect
ACTUAL_GOOD_COMMIT=""
ACTUAL_BAD_COMMIT=""

if [ -z "$GOOD_COMMIT" ]; then
    # Auto-assume mode: current commit (HEAD) is bad, its parent (HEAD^) is good.
    ACTUAL_BAD_COMMIT="HEAD" # The commit where the issue is currently observed.
    ACTUAL_GOOD_COMMIT="HEAD^" # Default to the commit just before HEAD.

    # Check if HEAD^ exists. If not (e.g., initial commit), this approach won't work.
    if ! git rev-parse --verify "$ACTUAL_GOOD_COMMIT" > /dev/null 2>&1; then
        echo "Error: Cannot find a default 'good' commit (HEAD^) because it might be the initial commit."
        echo "Please provide a specific good commit (e.g., '$0 <good_commit> <test_command>')."
        exit 1
    fi
else
    # Good commit was provided explicitly
    ACTUAL_GOOD_COMMIT="$GOOD_COMMIT"
    # When a good commit is provided, the current HEAD is assumed bad.
    ACTUAL_BAD_COMMIT="HEAD"
fi

# Check if the good commit exists
if ! git rev-parse --verify "$ACTUAL_GOOD_COMMIT" > /dev/null 2>&1; then
    echo "Error: Commit '$ACTUAL_GOOD_COMMIT' does not exist."
    exit 1
fi

echo "Starting git bisect..."
echo "Assumed good commit: $ACTUAL_GOOD_COMMIT"
echo "Assumed bad commit: $ACTUAL_BAD_COMMIT"
echo "Test command: $TEST_COMMAND"
echo

# Start bisect
git bisect start

# Mark the bad commit
git bisect bad "$ACTUAL_BAD_COMMIT"

# Mark the known good commit
git bisect good "$ACTUAL_GOOD_COMMIT"

# Create a temporary script for the test command
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" << EOF
#!/bin/bash
set -e
$TEST_COMMAND
EOF
chmod +x "$TEMP_SCRIPT"

# Run automatic bisect
echo "Running automatic bisect..."
git bisect run "$TEMP_SCRIPT"

# Clean up
rm -f "$TEMP_SCRIPT"

echo
echo "Bisect complete! The first bad commit has been identified above."
echo "To reset bisect state, run: git bisect reset"
