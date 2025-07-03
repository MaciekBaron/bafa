#!/bin/bash

# Script to retrieve comments from a GitHub PR in JSON format
# Usage: get-pr-comments-json.sh [PR_NUMBER] [REPO]
# If no PR number is provided, it will try to detect the current PR
# If no repo is provided, it will try to detect from git remote

set -e

# Function to get repository from git remote
get_repo_from_git() {
    # Try to get repo from origin remote
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$remote_url" ]; then
        # Extract owner/repo from various URL formats
        if [[ "$remote_url" =~ github\.com[:/]([^/]+/[^/]+)(\.git)?$ ]]; then
            echo "${BASH_REMATCH[1]}" | sed 's/\.git$//'
        fi
    fi
}

# Function to get current PR number
get_current_pr() {
    current_branch=$(git branch --show-current 2>/dev/null || echo "")
    if [ -n "$current_branch" ]; then
        pr_number=$(gh pr list --head "$current_branch" --json number --jq '.[0].number' 2>/dev/null || echo "")
        if [ -n "$pr_number" ]; then
            echo "$pr_number"
            return
        fi
    fi
    
    pr_number=$(gh pr view --json number --jq '.number' 2>/dev/null || echo "")
    echo "$pr_number"
}

# Get repository
if [ -n "$2" ]; then
    REPO="$2"
else
    REPO=$(get_repo_from_git)
    if [ -z "$REPO" ]; then
        echo '{"error": "Could not detect repository. Please provide as second argument.", "usage": "get-pr-comments-json.sh [PR_NUMBER] [OWNER/REPO]"}' >&2
        exit 1
    fi
fi

# Get PR number
if [ -n "$1" ]; then
    PR_NUMBER="$1"
else
    PR_NUMBER=$(get_current_pr)
    if [ -z "$PR_NUMBER" ]; then
        echo '{"error": "Could not detect current PR. Please provide PR number as argument.", "usage": "get-pr-comments-json.sh [PR_NUMBER] [OWNER/REPO]", "repository": "'"$REPO"'"}' >&2
        exit 1
    fi
fi

# Fetch review comments and general comments in parallel
review_comments=$(gh api "/repos/$REPO/pulls/$PR_NUMBER/comments" --jq '[.[] | select(.in_reply_to_id == null and (.outdated == false or .outdated == null)) | {type: "review", id: .id, author: .user.login, file: .path, line: .line, body: .body, created: .created_at, url: .html_url}]')

general_comments=$(gh api "/repos/$REPO/issues/$PR_NUMBER/comments" --jq '[.[] | {type: "general", id: .id, author: .user.login, body: .body, created: .created_at, url: .html_url}]')

# Combine and sort by creation date
echo "$review_comments $general_comments" | jq -s '{
  repository: "'"$REPO"'",
  pr_number: '"$PR_NUMBER"',
  total_comments: (.[0] + .[1]) | length,
  review_comments: .[0] | length,
  general_comments: .[1] | length,
  comments: (.[0] + .[1]) | sort_by(.created)
}'