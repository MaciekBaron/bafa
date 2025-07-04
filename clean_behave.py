#!/usr/bin/env python3
import sys


def clean_behave_output():
    """
    Reads behave test output from stdin and prints a cleaner, more concise
    version to stdout, optimized for reducing token usage for coding agents.

    Uses a two-pass approach to accurately identify and filter out irrelevant
    feature lines and include only active test results and the final summary.
    """
    all_lines = [line.strip() for line in sys.stdin]
    output_lines_to_print = []

    current_feature_name = ""
    # This flag indicates if the *current buffered feature* has had any scenario or failed step.
    # It determines if the buffered feature name should eventually be printed.
    has_active_content_in_feature = False

    in_failed_step_error_block = False

    summary_start_index = -1  # Index where the final summary section begins

    # --- First Pass: Find the start of the summary section ---
    # This pass identifies the line that marks the beginning of the final report.
    # It looks for any of the common summary lines to ensure the entire block is captured.
    for i, line in enumerate(all_lines):
        if (
            line.startswith("Failing scenarios:")
            or "features passed" in line
            or "scenario passed" in line
            or "steps passed" in line
            or line.startswith("Took ")
        ):  # Explicitly include "Took" as a summary marker
            summary_start_index = i
            break

    # If no explicit summary marker is found (highly unlikely for behave),
    # treat all lines as content up to the end.
    if summary_start_index == -1:
        summary_start_index = len(all_lines)

    # --- Second Pass: Process lines up to the summary start ---
    # This loop handles individual feature, scenario, and step outputs,
    # buffering feature names and printing them only when active content is found.
    for i in range(summary_start_index):
        line = all_lines[i]

        # Skip database creation/destruction messages
        if line.startswith("Creating test database") or line.startswith(
            "Destroying test database"
        ):
            continue

        # Handle lines that are part of a failed step's error block
        if in_failed_step_error_block:
            output_lines_to_print.append(line)
            # An empty line often signifies the end of an error block's details
            if not line:
                in_failed_step_error_block = False
            continue

        # Process Feature lines
        if line.startswith("Feature:"):
            # If there was a previous feature being buffered and it had active content,
            # print its name now before starting to buffer the new feature.
            if current_feature_name and has_active_content_in_feature:
                output_lines_to_print.append(current_feature_name)

            current_feature_name = line  # Buffer the new feature line
            has_active_content_in_feature = (
                False  # Reset active content flag for the new feature
            )
            in_failed_step_error_block = (
                False  # Ensure error block state is reset for a new feature
            )
            continue

        # Process Scenario lines
        if line.startswith("Scenario:"):
            # If the current feature being buffered hasn't yet been marked as having active content,
            # it means this is the first scenario (or failed step) for this feature.
            # In this case, print its buffered header.
            if current_feature_name and not has_active_content_in_feature:
                output_lines_to_print.append(current_feature_name)
            has_active_content_in_feature = (
                True  # Mark current feature as having active content
            )

            # Extract only the scenario title (before "...") for conciseness
            scenario_title = line.split("...")[0].strip()
            output_lines_to_print.append(f"  {scenario_title}")
            continue

        # Handle failed step lines
        if "... failed" in line:
            # Similar to scenarios, if this is the first active content for the current feature,
            # print its buffered header.
            if current_feature_name and not has_active_content_in_feature:
                output_lines_to_print.append(current_feature_name)
            has_active_content_in_feature = (
                True  # Mark current feature as having active content
            )

            output_lines_to_print.append(line)
            in_failed_step_error_block = (
                True  # Activate error block capture for subsequent lines
            )
            continue

        # Explicitly skip "Background:" lines
        if line.startswith("Background:"):
            continue

        # All other lines (e.g., individual "... passed" step lines, empty lines not
        # part of an error block) are implicitly skipped by not matching any of the
        # above conditions for appending.

    # After processing all lines up to the summary start,
    # perform a final check for the very last buffered feature.
    # If it had active content and was the last thing processed before the summary,
    # ensure its header is printed.
    if current_feature_name and has_active_content_in_feature:
        output_lines_to_print.append(current_feature_name)

    # --- Append all lines from the summary section onwards ---
    # This ensures the final summary (including "Took" line) is always included.
    for i in range(summary_start_index, len(all_lines)):
        line = all_lines[i]
        # Even within the summary, ensure database messages are skipped if they somehow appear.
        if not (
            line.startswith("Creating test database")
            or line.startswith("Destroying test database")
        ):
            output_lines_to_print.append(line)

    # Print all collected lines to stdout
    for cleaned_line in output_lines_to_print:
        if not cleaned_line.startswith("Took "):
            print(cleaned_line)


if __name__ == "__main__":
    clean_behave_output()
