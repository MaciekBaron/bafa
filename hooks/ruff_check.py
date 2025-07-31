#!/usr/bin/env python3
"""Ruff check hook handler for Claude Code.
Runs ruff checks and fixes on Python files when they are written or edited.
"""

import json
import os
import subprocess
import sys


def run_command(cmd: str) -> tuple[int, str, str]:
    """Run a command and return exit code, stdout, stderr."""
    try:
        result = subprocess.run(  # noqa: S602
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            cwd=os.getcwd(),
            check=False,
        )
        return result.returncode, result.stdout, result.stderr
    except Exception as e:
        return 1, "", str(e)


def main():
    """Main hook execution."""
    # Read JSON input from stdin
    try:
        hook_input = json.loads(sys.stdin.read())
        file_path = hook_input.get("tool_input", {}).get("file_path", "")
    except (json.JSONDecodeError, KeyError):
        # If JSON parsing fails, exit gracefully
        sys.exit(0)

    # Only process Python files
    if not file_path.endswith(".py"):
        sys.exit(0)

    ignore_rules = [
        "F401",  # Unused import
        "F841",  # Unused local variable
        "ARG001",  # Unused function argument
        "ARG002",  # Unused method argument
        "T201",  # `print` found
        "ERA001",  # Commented-out code
        "S101",  # `assert` used
    ]

    # Join the list into a single, comma-separated string for the command
    ignore_string = ",".join(ignore_rules)

    # Run ruff with fix and capture output
    cmd = f"poetry run ruff check --fix --ignore {ignore_string} --output-format json '{file_path}'"
    exit_code, stdout, stderr = run_command(cmd)

    # If ruff found violations
    if exit_code == 1:
        # Parse JSON output to check for unfixable issues
        try:
            ruff_output = json.loads(stdout) if stdout else []
            unfixable_issues = [
                f"Line {issue['location']['row']}: {issue['message']} ({issue['code']})"
                for issue in ruff_output
                if issue.get("fix") is None
            ]

            if unfixable_issues:
                print(
                    "Ruff found unfixable issues that require manual intervention:",
                    file=sys.stderr,
                )
                for issue in unfixable_issues:
                    print(issue, file=sys.stderr)
                print("", file=sys.stderr)
                print(
                    "Please fix these issues manually before proceeding.",
                    file=sys.stderr,
                )
                sys.exit(2)  # Blocking error - feeds stderr back to Claude
        except json.JSONDecodeError:
            # If we can't parse the JSON output, just proceed
            pass

    sys.exit(0)


if __name__ == "__main__":
    main()
