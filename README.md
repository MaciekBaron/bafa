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
./get-pr-comments.sh 260 ONSdigital/dis-wagtail
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
./get-unresolved-pr-comments.sh 260 ONSdigital/dis-wagtail
./get-unresolved-pr-comments-minimal.sh 260 ONSdigital/dis-wagtail
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
./get-pr-comments-json.sh 260 ONSdigital/dis-wagtail
```

**Output**: Structured JSON with all comments, perfect for scripting

**Example JSON structure**:
```json
{
  "repository": "ONSdigital/dis-wagtail",
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

### Integration

Add to your shell's PATH for global access:
```bash
# Add to ~/.bashrc, ~/.zshrc, etc.
export PATH="$HOME/Development/util_scripts:$PATH"
```

Then use from any Git repository:
```bash
cd /path/to/any/github/repo
get-unresolved-pr-comments.sh
```
