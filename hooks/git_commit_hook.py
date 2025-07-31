#!/usr/bin/env python3
"""Git commit hook handler for Claude Code.
Runs pre-commit and mypy checks when git commit is detected.
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
        command = hook_input.get("tool_input", {}).get("command", "")
    except (json.JSONDecodeError, KeyError):
        # Fallback to command line argument if JSON parsing fails
        command = sys.argv[1] if len(sys.argv) > 1 else ""

    if "git commit" not in command:
        sys.exit(0)

    # Run pre-commit
    exit_code, stdout, stderr = run_command("pre-commit")

    if exit_code != 0:
        print(f"Pre-commit failed with exit code {exit_code}", file=sys.stderr)
        if stderr:
            print(stderr, file=sys.stderr)
        if stdout:
            print(stdout, file=sys.stderr)
        sys.exit(2)  # Blocking error

    # Stage any files that pre-commit may have fixed
    run_command("git add -u")

    # Run mypy
    mypy_exit, mypy_out, mypy_err = run_command("make mypy")

    if mypy_exit != 0:
        print(f"MyPy failed with exit code {mypy_exit}", file=sys.stderr)
        if mypy_err:
            print(mypy_err, file=sys.stderr)
        if mypy_out:
            print(mypy_out, file=sys.stderr)
        sys.exit(2)  # Blocking error

    sys.exit(0)


if __name__ == "__main__":
    main()
