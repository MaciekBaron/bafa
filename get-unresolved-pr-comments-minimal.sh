#!/bin/bash

# Minimal script to get only unresolved PR comments (optimized for Claude input)
# Usage: get-unresolved-pr-comments-minimal.sh [PR_NUMBER] [REPO]

set -e

# Function to get repository from git remote
get_repo_from_git() {
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$remote_url" ]; then
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
        echo "Error: Could not detect repository" >&2
        exit 1
    fi
fi

# Get PR number
if [ -n "$1" ]; then
    PR_NUMBER="$1"
else
    PR_NUMBER=$(get_current_pr)
    if [ -z "$PR_NUMBER" ]; then
        echo "Error: Could not detect current PR" >&2
        exit 1
    fi
fi

# Get unresolved threads from GraphQL API
repo_owner=$(echo "$REPO" | cut -d'/' -f1)
repo_name=$(echo "$REPO" | cut -d'/' -f2)

unresolved_data=$(gh api graphql -f query='
{
  repository(owner: "'"$repo_owner"'", name: "'"$repo_name"'") {
    pullRequest(number: '"$PR_NUMBER"') {
      reviewThreads(first: 50) {
        nodes {
          isResolved
          comments(first: 20) {
            nodes {
              databaseId
              body
              path
              originalLine
              createdAt
              author {
                login
              }
              url
            }
          }
        }
      }
    }
  }
}' | jq -r '
.data.repository.pullRequest.reviewThreads.nodes[] | 
select(.isResolved == false) | 
"File: \(.comments.nodes[0].path):\(.comments.nodes[0].originalLine // "no line")
Thread URL: \(.comments.nodes[0].url)

" + (
  .comments.nodes | 
  sort_by(.createdAt) | 
  map("@\(.author.login) (\(.createdAt | sub("T.*"; ""))): \(.body)") | 
  join("\n\n")
) + "\n---"
')

# Get general PR comments
general_comments=$(gh api "/repos/$REPO/issues/$PR_NUMBER/comments" | jq -r '.[] |
"Author: @\(.user.login)
Comment: \(.body)
URL: \(.html_url)
---"
')

# Count unresolved items
unresolved_count=0
general_count=0

if [ -n "$unresolved_data" ]; then
    unresolved_count=$(echo "$unresolved_data" | grep -c "^File:" 2>/dev/null || echo "0")
fi

if [ -n "$general_comments" ]; then
    general_count=$(echo "$general_comments" | grep -c "^Author:" 2>/dev/null || echo "0")
fi

total=$((unresolved_count + general_count))

# Output results only if there are unresolved items
if [ "$total" -eq 0 ]; then
    echo "No unresolved comments."
else
    if [ -n "$unresolved_data" ]; then
        echo "Unresolved Review Comments:"
        echo "$unresolved_data"
    fi

    if [ -n "$general_comments" ]; then
        echo "General PR Comments:"
        echo "$general_comments"
    fi
    
    echo "Total unresolved: $unresolved_count review + $general_count general = $total comments"
fi