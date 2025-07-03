#!/bin/bash

# Git Bisect Auto - Automatically find the breaking commit
# Usage: git-bisect-auto.sh <good_commit> <test_command>
# Example: git-bisect-auto.sh HEAD~10 "npm test"

set -e

# Check if we have the required arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <good_commit> <test_command>"
    echo "Example: $0 HEAD~10 'npm test'"
    echo "Example: $0 abc123 'make test'"
    exit 1
fi

GOOD_COMMIT="$1"
TEST_COMMAND="$2"

# Ensure we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Check if the good commit exists
if ! git rev-parse --verify "$GOOD_COMMIT" > /dev/null 2>&1; then
    echo "Error: Commit '$GOOD_COMMIT' does not exist"
    exit 1
fi

echo "Starting git bisect..."
echo "Good commit: $GOOD_COMMIT"
echo "Test command: $TEST_COMMAND"
echo

# Start bisect
git bisect start

# Mark current commit as bad (assuming we're running this because current state is broken)
git bisect bad

# Mark the known good commit
git bisect good "$GOOD_COMMIT"

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