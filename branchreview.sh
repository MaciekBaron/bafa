#!/bin/bash
set -euo pipefail

MODEL_NAME="${1:-kimi-k2}"
TMPFILE="$(mktemp -t branchreview.XXXXXX)"
cleanup() { rm -f "$TMPFILE"; }
trap cleanup EXIT INT TERM

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not a git repository." >&2
  exit 1
fi

# Capture diff between main and current HEAD
git diff main...HEAD >"$TMPFILE"

# Run review
llm -m "$MODEL_NAME" -s "Review this git diff. Analyze the changes and look for potential bugs, style violations, and suggest improvements. Only analyze provided code, do not guess what other code exists. Provide concise, straight to the point feedback. Keep praise to minimum. Ignore very minor issues. Only provide code related feedback, not infrastructural or logistical. Remember to mention which file needs updating. Do not provide feedback if you do not have enough context, do not guess. Ignore final new line issues and only provide coding feedback. Do not comment on code changes that made things less flexible. Only provide feedback if necessary. Preface the feedback by saying that things that contradict the original task or requirements should be ignored. In your code suggestions, remember that our python code should have a max line length of 120 as dictated by ruff." <"$TMPFILE"
