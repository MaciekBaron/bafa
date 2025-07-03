#!/bin/bash

# Script to retrieve comments from a GitHub PR
# Usage: get-pr-comments.sh [PR_NUMBER] [REPO]
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
    # Try to get PR number from current branch
    current_branch=$(git branch --show-current 2>/dev/null || echo "")
    if [ -n "$current_branch" ]; then
        pr_number=$(gh pr list --head "$current_branch" --json number --jq '.[0].number' 2>/dev/null || echo "")
        if [ -n "$pr_number" ]; then
            echo "$pr_number"
            return
        fi
    fi
    
    # Fallback: try to extract from gh pr view output
    pr_number=$(gh pr view --json number --jq '.number' 2>/dev/null || echo "")
    echo "$pr_number"
}

# Get repository
if [ -n "$2" ]; then
    REPO="$2"
else
    REPO=$(get_repo_from_git)
    if [ -z "$REPO" ]; then
        echo "Error: Could not detect repository. Please provide as second argument."
        echo "Usage: $0 [PR_NUMBER] [OWNER/REPO]"
        exit 1
    fi
fi

# Get PR number
if [ -n "$1" ]; then
    PR_NUMBER="$1"
else
    PR_NUMBER=$(get_current_pr)
    if [ -z "$PR_NUMBER" ]; then
        echo "Error: Could not detect current PR. Please provide PR number as argument."
        echo "Usage: $0 [PR_NUMBER] [OWNER/REPO]"
        echo "Repository: $REPO"
        exit 1
    fi
fi

echo "📋 Fetching comments for PR #$PR_NUMBER in $REPO..."
echo ""

# Fetch PR review comments (code comments)
echo "=== Review Comments ==="
gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/$REPO/pulls/$PR_NUMBER/comments" \
  --jq '.[] | select(.in_reply_to_id == null) | {
    id: .id,
    author: .user.login,
    file: .path,
    line: .line,
    body: .body,
    created: .created_at,
    outdated: .outdated,
    url: .html_url
  }' | jq -s 'sort_by(.created)'

echo ""
echo "=== Issue Comments (General PR Comments) ==="
# Fetch general PR comments (issue comments)
gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/$REPO/issues/$PR_NUMBER/comments" \
  --jq '.[] | {
    id: .id,
    author: .user.login,
    body: .body,
    created: .created_at,
    url: .html_url
  }' | jq -s 'sort_by(.created)'

echo ""
echo "=== Summary ==="
# Count comments (handle null outdated values)
review_comments=$(gh api "/repos/$REPO/pulls/$PR_NUMBER/comments" --jq '[.[] | select(.in_reply_to_id == null and (.outdated == false or .outdated == null))] | length')
issue_comments=$(gh api "/repos/$REPO/issues/$PR_NUMBER/comments" --jq 'length')

echo "Review comments (not outdated): $review_comments"
echo "General PR comments: $issue_comments"
echo "Total: $((review_comments + issue_comments))"