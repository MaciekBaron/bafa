#!/bin/bash

# Script to retrieve only unresolved comments from a GitHub PR
# Usage: get-unresolved-pr-comments.sh [PR_NUMBER] [REPO]
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
            echo "${BASH_REMATCH[1]%.git}"
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

echo "🔍 Fetching unresolved comments for PR #$PR_NUMBER in $REPO..."
echo ""

# Get review thread resolution status from GraphQL API
repo_owner=$(echo "$REPO" | cut -d'/' -f1)
repo_name=$(echo "$REPO" | cut -d'/' -f2)

thread_resolution=$(gh api graphql -f query='
{
  repository(owner: "'"$repo_owner"'", name: "'"$repo_name"'") {
    pullRequest(number: '"$PR_NUMBER"') {
      reviewThreads(first: 50) {
        nodes {
          id
          isResolved
          comments(first: 1) {
            nodes {
              databaseId
            }
          }
        }
      }
    }
  }
}' | jq '{
  resolved_threads: [.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == true) | .comments.nodes[0].databaseId],
  unresolved_threads: [.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | .comments.nodes[0].databaseId]
}')

# Fetch all review comments for display
all_review_comments=$(gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/$REPO/pulls/$PR_NUMBER/comments")

# Get top-level comments (not replies) that are not outdated
top_level_comments=$(echo "$all_review_comments" | jq '[.[] | select(.in_reply_to_id == null and (.outdated != true))]')

echo "📝 Review Comments (Code Comments):"
echo "==================================="

if [ "$(echo "$top_level_comments" | jq 'length')" -eq 0 ]; then
    echo "✅ No review comments found!"
else
    echo "$top_level_comments" | jq -r --argjson resolution "$thread_resolution" '.[] | 
    "📍 File: \(.path):\(.line // .start_line)
👤 Author: \(.user.login)
🕒 Created: \(.created_at | sub("T"; " ") | sub("Z"; "") | .[0:16])
" + (
    if (.id as $id | $resolution.resolved_threads | contains([$id])) then "✅ Status: Resolved"
    elif (.id as $id | $resolution.unresolved_threads | contains([$id])) then "❌ Status: Unresolved"
    else "❓ Status: Unknown (no thread info)" 
    end
) + "
💬 Comment:
\(.body)
🔗 URL: \(.html_url)
" + ("─" * 50)'
fi

echo ""
echo "💬 General PR Comments:"
echo "======================="

# Fetch all general PR comments - these don't have a "resolved" state
general_comments=$(gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/$REPO/issues/$PR_NUMBER/comments")

if [ "$(echo "$general_comments" | jq 'length')" -eq 0 ]; then
    echo "✅ No general PR comments found!"
else
    echo "$general_comments" | jq -r '.[] | 
    "👤 Author: \(.user.login)
🕒 Created: \(.created_at | sub("T"; " ") | sub("Z"; "") | .[0:16])
💬 Comment:
\(.body)
🔗 URL: \(.html_url)
" + ("─" * 50)'
fi

echo ""
echo "📊 Summary:"
echo "==========="

# Count comments by actual resolution status
review_count=$(echo "$top_level_comments" | jq 'length')
general_count=$(echo "$general_comments" | jq 'length')
resolved_count=$(echo "$top_level_comments" | jq --argjson resolution "$thread_resolution" '[.[] | select(.id as $id | $resolution.resolved_threads | contains([$id]))] | length')
unresolved_count=$(echo "$top_level_comments" | jq --argjson resolution "$thread_resolution" '[.[] | select(.id as $id | $resolution.unresolved_threads | contains([$id]))] | length')
total_unresolved=$((unresolved_count + general_count))

echo "🔍 Review comments (total): $review_count"
echo "  └── ✅ Resolved: $resolved_count"
echo "  └── ❌ Unresolved: $unresolved_count"
echo "💬 General PR comments: $general_count"
echo "📋 Total comments: $((review_count + general_count))"

if [ "$total_unresolved" -eq 0 ]; then
    echo ""
    echo "🎉 All review comments are resolved! No general comments."
else
    echo ""
    echo "⚠️  $total_unresolved item(s) need attention ($unresolved_count unresolved review comments + $general_count general comments)."
fi