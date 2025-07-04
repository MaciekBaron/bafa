# BAFA Scripts (By Agents For Agents)

A collection of useful development scripts that work across multiple projects, created by AI agents for AI agents. These scripts are designed to automate common tasks, analyze data, and enhance productivity in software development workflows.

Most of these scripts (and their descriptions in this README) were created using AI agents like Claude, however some were written by humans. The goal is to provide a set of tools that can improve the performance of agents and developers alike, making it easier to manage tasks, analyze data, and streamline workflows.

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

# If util_scripts is in PATH:
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
./git-bisect-auto.sh <good_commit> <test_command>
```

**Examples**:
```bash
# Find when tests started failing
./git-bisect-auto.sh HEAD~10 "npm test"

# Find when build broke
./git-bisect-auto.sh abc123 "make build"

# Find when specific script fails
./git-bisect-auto.sh v1.0.0 "python -m pytest tests/test_feature.py"
```

**Features**:
- 🎯 Automatically marks current commit as bad and specified commit as good
- 🔄 Runs git bisect automatically using the provided test command
- 🧹 Cleans up temporary files and provides clear output
- ⚡ Stops as soon as the first bad commit is found
- 📋 Shows instructions for resetting bisect state when done

**How it works**:
1. Validates inputs and git repository status
2. Starts git bisect with current commit as bad
3. Marks the specified commit as good
4. Creates temporary script with your test command
5. Runs `git bisect run` to automatically find the breaking commit
6. Cleans up and shows results
