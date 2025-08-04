#!/bin/bash
set -e

MODEL_NAME="${1:-kimi-k2}"
trap 'rm branchreview.tmp' EXIT

git diff main...HEAD > branchreview.tmp
cat branchreview.tmp | llm -m $MODEL_NAME -s "Review this git diff. Analyze the changes and look for potential bugs, style violations, and suggest improvements. Only analyze provided code, do not guess what other code exists. Provide concise, straight to the point feedback. Keep praise to minimum. Ignore very minor issues. Only provide code related feedback, not infrastructural or logistical. Remember to mention which file needs updating. Do not provide feedback if you do not have enough context, do not guess. Ignore final new line issues and only provide coding feedback. Do not comment on code changes that made things less flexible. Only provide feedback if necessary. Preface the feedback by saying that things that contradict the original task or requirements should be ignored. In your code suggestions, remember that our python code should have a max line length of 120 as dictated by ruff."
