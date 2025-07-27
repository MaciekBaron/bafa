# BAFA Scripts (By Agents For Agents)

A collection of useful development scripts that work across multiple projects, created by AI agents for AI agents. These scripts are designed to automate common tasks, analyze data, and enhance productivity in software development workflows.

Most of these scripts (and their descriptions in this README) were created using AI agents like Claude, however some were written by humans. The goal is to provide a set of tools that can improve the performance of agents and developers alike, making it easier to manage tasks, analyze data, and streamline workflows.

Scripts are written in Bash and Python.

## Table of Contents

- [GitHub PR Comment Scripts](#github-pr-comment-scripts)
  - [get-pr-comments.sh](#get-pr-commentssh)
  - [get-unresolved-pr-comments.sh](#get-unresolved-pr-commentssh)
  - [get-unresolved-pr-comments-minimal.sh](#get-unresolved-pr-comments-minimalsh)
  - [get-pr-comments-json.sh](#get-pr-comments-jsonsh)
- [Testing Scripts](#testing-scripts)
  - [clean_behave.py](#clean_behavepy)
- [Git Bisect Scripts](#git-bisect-scripts)
  - [git-bisect-auto.sh](#git-bisect-autosh)
  - [git-bisect-auto-finder.sh](#git-bisect-auto-findersh)
- [Git Worktree Scripts](#git-worktree-scripts)
  - [git-claude-worktree.sh](#git-claude-worktreesh)
- [Code Quality Scripts](#code-quality-scripts)
  - [whitespacefix.sh](#whitespacefixsh)
- [System Monitoring Scripts](#system-monitoring-scripts)
  - [idle-check.sh](#idle-checksh)

## GitHub PR Comment Scripts

Scripts to analyze comments and discussions on GitHub Pull Requests using the GitHub CLI (`gh`).

### Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated
- `jq` for JSON processing
- Git repository with GitHub remote

### Scripts

#### `get-pr-comments.sh`
**Purpose**: Get all PR comments with detailed information

**Usage**:
```bash
# Auto-detect current PR and repository
./get-pr-comments.sh

# Specify PR number (auto-detect repository)
./get-pr-comments.sh 260

# Specify both PR number and repository
./get-pr-comments.sh 260 MaciekBaron/bafa
```

**Output**: Detailed view of review comments and general PR comments with metadata

#### `get-unresolved-pr-comments.sh`
**Purpose**: Focus on comments that need attention (human-readable format)

#### `get-unresolved-pr-comments-minimal.sh`
**Purpose**: Minimal output showing only unresolved comments (optimized for Claude/AI input)

**Usage**:
```bash
# Auto-detect current PR and repository
./get-unresolved-pr-comments.sh
./get-unresolved-pr-comments-minimal.sh

# Specify PR number (auto-detect repository)
./get-unresolved-pr-comments.sh 260
./get-unresolved-pr-comments-minimal.sh 260

# Specify both PR number and repository
./get-unresolved-pr-comments.sh 260 MaciekBaron/bafa
./get-unresolved-pr-comments-minimal.sh 260 MaciekBaron/bafa
```

**Features** (`get-unresolved-pr-comments.sh`):
- 🔄 Shows which comments have replies (potentially addressed)
- ❓ Highlights comments without replies (need attention)
- 📊 Provides summary statistics
- 🎯 Focuses on actionable items

**Features** (`get-unresolved-pr-comments-minimal.sh`):
- 🎯 Shows only unresolved comments (no noise)
- 📝 Clean, minimal output perfect for feeding into Claude/AI
- ⚡ Faster execution with fewer API calls
- 🔗 Includes essential info: file, author, comment, URL

#### `get-pr-comments-json.sh`
**Purpose**: Get comments in JSON format for parsing/automation

**Usage**:
```bash
# Auto-detect current PR and repository
./get-pr-comments-json.sh

# Specify PR number (auto-detect repository)
./get-pr-comments-json.sh 260

# Specify both PR number and repository
./get-pr-comments-json.sh 260 MaciekBaron/bafa
```

**Output**: Structured JSON with all comments, perfect for scripting

**Example JSON structure**:
```json
{
  "repository": "MaciekBaron/bafa",
  "pr_number": 260,
  "total_comments": 6,
  "review_comments": 6,
  "general_comments": 0,
  "comments": [
    {
      "type": "review",
      "id": 2174759937,
      "author": "reviewer",
      "file": "path/to/file.py",
      "line": 42,
      "body": "Comment text...",
      "created": "2025-06-30T10:33:17Z",
      "url": "https://github.com/..."
    }
  ]
}
```

### Auto-Detection Features

All scripts automatically detect:

1. **Repository**: Extracts `owner/repo` from git remote origin URL
   - Supports both HTTPS and SSH formats
   - Works with `github.com` URLs

2. **PR Number**: Attempts multiple methods:
   - Current branch name via `gh pr list --head`
   - Active PR via `gh pr view`

### Comment Types

- **Review Comments**: Code-specific comments with file/line context
- **General Comments**: Discussion comments on the PR overall

### Comment Status Analysis

The scripts distinguish between:
- **Comments with replies**: May be addressed/resolved
- **Comments without replies**: Likely need attention
- **Outdated comments**: Automatically filtered out (when code changes)

## Testing Scripts

### `clean_behave.py`
**Purpose**: Clean and filter behave test output for reduced verbosity and better AI agent consumption

**Usage**:
```bash
# Pipe behave output through the cleaner (requires --format=plain -Tk)
behave tests/ --format=plain -Tk 2>&1 | ./clean_behave.py

# Use with any behave command
behave --tags=@smoke --format=plain -Tk 2>&1 | ./clean_behave.py

# If folder with script is in PATH:
behave tests/ --format=plain -Tk 2>&1 | clean_behave.py
```

**Prerequisites**:
- Behave command must be run with `--format=plain -Tk` flags for proper output formatting

**Features**:
- 🎯 Filters out irrelevant test output (database creation/destruction messages)
- 📊 Shows only active test results (scenarios and failed steps)
- 🧹 Provides clean, concise output optimized for AI agents
- ⚡ Reduces token usage by removing verbose passing step details
- 📋 Preserves essential information: feature names, scenario titles, failures, and summary

**What it filters**:
- Database creation/destruction messages
- Individual "... passed" step lines
- Background sections
- Empty lines not part of error blocks
- Verbose feature headers for features with no active content

**What it preserves**:
- Feature names (only when they contain active scenarios or failures)
- Scenario titles (truncated before "...")
- Failed step details and error messages
- Final test summary and statistics

## Git Bisect Scripts

### `git-bisect-auto.sh`
**Purpose**: Automatically find the first breaking commit using git bisect

**Usage**:
```bash
# With explicit good commit
./git-bisect-auto.sh <good_commit> <test_command>

# Auto-assume mode (HEAD is bad, HEAD^ is good)
./git-bisect-auto.sh <test_command>
```

**Examples**:
```bash
# Find when tests started failing (explicit good commit)
./git-bisect-auto.sh HEAD~10 "npm test"

# Auto-assume mode - current commit is bad, parent is good
./git-bisect-auto.sh "npm test"

# Find when build broke
./git-bisect-auto.sh abc123 "make build"

# Find when specific script fails
./git-bisect-auto.sh v1.0.0 "python -m pytest tests/test_feature.py"
```

**Features**:
- 🎯 Automatically marks commits as bad/good based on your input
- 🔄 Runs git bisect automatically using the provided test command
- 🧹 Cleans up temporary files and provides clear output
- ⚡ Stops as soon as the first bad commit is found
- 📋 Shows instructions for resetting bisect state when done
- 🤖 Auto-assume mode: when no good commit is specified, assumes HEAD is bad and HEAD^ is good

**How it works**:
1. Validates inputs and git repository status
2. Determines good/bad commits (explicit or auto-assumed)
3. Starts git bisect with appropriate commits
4. Creates temporary script with your test command
5. Runs `git bisect run` to automatically find the breaking commit
6. Cleans up and shows results

### `git-bisect-auto-finder.sh`
**Purpose**: Automatically find a good commit by jumping backwards in history, then run git bisect

**Usage**:
```bash
# Default jump size (10 commits)
./git-bisect-auto-finder.sh <test_command>

# Custom jump size
./git-bisect-auto-finder.sh <jump_size> <test_command>
```

**Examples**:
```bash
# Find good commit jumping 10 commits at a time
./git-bisect-auto-finder.sh "npm test"

# Find good commit jumping 20 commits at a time
./git-bisect-auto-finder.sh 20 "make build"

# Find good commit for specific test
./git-bisect-auto-finder.sh 5 "python -m pytest tests/test_feature.py"
```

**Features**:
- 🔍 Automatically searches backwards in history to find a good commit
- 🎯 Uses configurable jump size for efficient searching
- 🔄 Automatically runs git bisect once good commit is found
- 🤖 Assumes current HEAD is the bad commit
- 🧹 Handles edge cases like reaching repository beginning
- ⚡ Efficient binary search combined with initial good commit discovery

**How it works**:
1. Assumes current HEAD is the bad commit
2. Jumps backwards in history by specified intervals
3. Tests each commit until a good one is found
4. Automatically starts git bisect with found good commit and current bad commit
5. Runs `git bisect run` to find the exact breaking commit
6. Cleans up and shows results

## Git Worktree Scripts

### `git-claude-worktree.sh`
**Purpose**: Automates the creation of a Git worktree and symlinks CLAUDE*.md files from the main worktree to the new one

**Usage**:
```bash
# Create worktree with specific branch/commit
./git-claude-worktree.sh <new_worktree_path> [<commit-ish_or_branch>]

# Create worktree with Git's default behavior
./git-claude-worktree.sh <new_worktree_path>
```

**Examples**:
```bash
# Create worktree for feature branch
./git-claude-worktree.sh ../feature-x-worktree feature/my-new-feature

# Create worktree for hotfix
./git-claude-worktree.sh /tmp/hotfix-worktree hotfix/urgent-bug

# Create worktree with default Git behavior
./git-claude-worktree.sh ../testing-worktree
```

**Features**:
- 🔧 Automatically creates new Git worktree at specified path
- 📋 Symlinks all CLAUDE*.md files from main worktree to new worktree
- 🔗 Uses relative symlinks for portability
- 🛡️ Validates Git repository and dependencies before execution
- ⚠️ Handles existing files gracefully (skips if already exists)
- 📍 Supports both absolute and relative paths

**Prerequisites**:
- Git repository
- `realpath` command (install with `brew install coreutils` on macOS)

**How it works**:
1. Validates Git repository and required tools
2. Creates new worktree using `git worktree add`
3. Searches for CLAUDE*.md files in main worktree root
4. Creates relative symlinks to these files in the new worktree
5. Provides instructions for next steps

## Code Quality Scripts

### `whitespacefix.sh`
**Purpose**: Cleans up whitespace in text files according to standardized rules - designed for use as a development hook

**Usage**:
```bash
# Fix whitespace in specific files
./whitespacefix.sh file1.txt file2.py

# Fix multiple files at once
./whitespacefix.sh src/*.py tests/*.py

# Common use as a pre-commit hook
./whitespacefix.sh $(git diff --cached --name-only --diff-filter=ACM)
```

**Features**:
- 🧹 Removes trailing whitespace from all lines
- 📋 Removes lines that contain only whitespace
- 📄 Ensures files end with a single newline character
- 🔧 Designed for use as a development hook (Git, Claude Code, etc.)
- ⚡ Processes multiple files efficiently
- 🛡️ Validates file existence and handles errors gracefully
- 🎯 Returns exit code 1 if changes were made (useful for automation)
- 📊 Provides clear feedback: "Whitespace issues have been fixed" or "No changes made"

**Exit Codes**:
- `0`: No whitespace issues found
- `1`: Whitespace issues were detected and fixed

**Hook Integration**:
This script is ideal for development hooks that need to detect and fix whitespace issues. The exit code allows automation systems to determine if files were modified. Can be integrated with Git hooks (`.git/hooks/pre-commit`), Claude Code hooks, or other development workflow automation systems.

**What it fixes**:
- Trailing spaces and tabs at end of lines
- Empty lines containing only whitespace characters
- Missing newline at end of file
- Multiple trailing newlines (reduces to single newline)

## System Monitoring Scripts

### `idle-check.sh`
**Purpose**: Monitors user idle time on macOS and sends push notifications via ntfy.sh when idle threshold is exceeded

**Usage**:
```bash
# Run with default settings (60 second threshold)
./idle-check.sh

# Configure via environment variables
IDLE_THRESHOLD_SECONDS=300 NTFY_CLAUDE_TOPIC=mytopic ./idle-check.sh
```

**Configuration**:
- `IDLE_THRESHOLD_SECONDS`: Idle time threshold in seconds (default: 60)
- `NTFY_CLAUDE_TOPIC`: ntfy.sh topic for notifications (default: "mytopic")

**Features**:
- 🕒 Monitors system idle time using macOS ioreg command
- 📱 Sends push notifications via ntfy.sh service
- ⚙️ Configurable idle time threshold
- 🔧 Environment variable configuration support
- 🛡️ Error handling for idle time retrieval failures
- 📊 Clear status reporting and logging

**Prerequisites**:
- macOS system (uses ioreg command)
- Internet connection for ntfy.sh notifications
- curl command available

**How it works**:
1. Queries macOS HIDIdleTime using ioreg command
2. Converts idle time from nanoseconds to seconds
3. Compares current idle time against configured threshold
4. Sends notification via ntfy.sh if threshold exceeded
5. Provides status feedback for monitoring/logging

**Common Use Cases**:
- CI/CD pipeline monitoring (notify when builds complete during idle periods)
- Development workflow automation (alert when long-running tasks finish)
- System administration monitoring
- Integration with cron jobs for periodic idle checks
