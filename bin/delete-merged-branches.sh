#!/bin/bash

# delete-merged-branches.sh
# This script deletes all Git branches merged into origin/master.
# It can delete both local and remote branches.
# Enhancements:
#   - Implements a --dry-run option to simulate deletions.
#   - Adds logging functionality to record deleted branches.
#   - Uses a top-level variable for protected branches.

# Exit immediately if a command exits with a non-zero status.
set -e

# ---------------------------
# Configuration Variables
# ---------------------------

# List of protected branches (whitelisted)
WHITELISTED_PROTECTED_BRANCHES="master|main|develop|release|hotfix"

# Log file path
LOG_FILE="deleted-branches.log"

# ---------------------------
# Helper Functions
# ---------------------------

# Function to display usage information
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -l, --local         Delete local branches merged into origin/master"
    echo "  -r, --remote        Delete remote branches merged into origin/master"
    echo "  -a, --all           Delete both local and remote branches merged into origin/master"
    echo "  -d, --dry-run       Simulate deletions without performing them"
    echo "  -h, --help          Display this help message"
    echo ""
    echo "If no options are provided, the script will prompt for actions."
}

# Function to check if current directory is a Git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: This script must be run inside a Git repository."
        exit 1
    fi
}

# Function to fetch latest updates from remote
fetch_updates() {
    echo "Fetching latest updates from remote..."
    git fetch origin --prune
}

# Function to list local branches merged into origin/master
list_merged_local_branches() {
    echo "Listing local branches merged into origin/master..."
    git branch --merged origin/master | grep -vE "^\*|${WHITELISTED_PROTECTED_BRANCHES}" | sed 's/^[ *]*//'
}

# Function to list remote branches merged into origin/master
list_merged_remote_branches() {
    echo "Listing remote branches merged into origin/master..."
    git branch -r --merged origin/master | grep -vE "origin/(${WHITELISTED_PROTECTED_BRANCHES})" | sed 's/^origin\///'
}

# Function to log deleted branches
log_deletion() {
    local branch_type="$1"
    local branch_name="$2"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] Deleted $branch_type branch: $branch_name" >> "$LOG_FILE"
}

# Function to delete local branches
delete_local_branches() {
    local branches=("$@")
    if [ ${#branches[@]} -eq 0 ]; then
        echo "No local branches to delete."
        return
    fi

    echo "The following local branches have been merged into origin/master and will be deleted:"
    for branch in "${branches[@]}"; do
        echo "  - $branch"
    done

    if [ "$DRY_RUN" = true ]; then
        echo "Dry-Run Mode: No local branches will be deleted."
        return
    fi

    read -p "Are you sure you want to delete these local branches? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for branch in "${branches[@]}"; do
            git branch -d "$branch" && echo "Deleted local branch '$branch'"
            log_deletion "local" "$branch"
        done
    else
        echo "Skipping deletion of local branches."
    fi
}

# Function to delete remote branches
delete_remote_branches() {
    local branches=("$@")
    if [ ${#branches[@]} -eq 0 ]; then
        echo "No remote branches to delete."
        return
    fi

    echo "The following remote branches have been merged into origin/master and will be deleted:"
    for branch in "${branches[@]}"; do
        echo "  - $branch"
    done

    if [ "$DRY_RUN" = true ]; then
        echo "Dry-Run Mode: No remote branches will be deleted."
        return
    fi

    read -p "Are you sure you want to delete these remote branches? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for branch in "${branches[@]}"; do
            git push origin --delete "$branch" && echo "Deleted remote branch 'origin/$branch'"
            log_deletion "remote" "$branch"
        done
    else
        echo "Skipping deletion of remote branches."
    fi
}

# Function to populate an array from command output
populate_array() {
    local array_name="$1"
    local cmd="$2"
    eval "$cmd" | while IFS= read -r line; do
        eval "$array_name+=(\"\$line\")"
    done
}

# ---------------------------
# Main Script Execution
# ---------------------------

# Initialize variables
DELETE_LOCAL=false
DELETE_REMOTE=false
DRY_RUN=false

# Parse command-line arguments
if [ $# -gt 0 ]; then
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -l|--local)
                DELETE_LOCAL=true
                shift
                ;;
            -r|--remote)
                DELETE_REMOTE=true
                shift
                ;;
            -a|--all)
                DELETE_LOCAL=true
                DELETE_REMOTE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
fi

# Check if Git repository
check_git_repo

# Fetch latest updates
fetch_updates

# If no deletion options provided, prompt the user
if [ "$DELETE_LOCAL" = false ] && [ "$DELETE_REMOTE" = false ]; then
    echo "No deletion option provided. Would you like to delete local branches? [y/N]: "
    read answer_local
    if [[ "$answer_local" =~ ^[Yy]$ ]]; then
        DELETE_LOCAL=true
    fi

    echo "Would you like to delete remote branches? [y/N]: "
    read answer_remote
    if [[ "$answer_remote" =~ ^[Yy]$ ]]; then
        DELETE_REMOTE=true
    fi
fi

# Get list of branches to delete
if [ "$DELETE_LOCAL" = true ]; then
    # compatible with bash verion 4.4+
    #mapfile -t local_branches < <(list_merged_local_branches)

    # Initialize an empty array
    local_branches=()
    # Populate the array
    populate_array "local_branches" "list_merged_local_branches"
fi

if [ "$DELETE_REMOTE" = true ]; then
    # compatible with bash verion 4.4+
    #mapfile -t remote_branches < <(list_merged_remote_branches)

    # Initialize an empty array
    remote_branches=()
    # Populate the array
    populate_array "remote_branches" "list_merged_remote_branches"
fi

# Delete branches based on user choice and dry-run flag
# TODO: uncomment the actual delete calls and remove the echo placeholders below
if [ "$DELETE_LOCAL" = true ]; then
    echo "call delete_local_branches"
    #delete_local_branches "${local_branches[@]}"
fi

if [ "$DELETE_REMOTE" = true ]; then
    echo "call delete_remote_branches"
    #delete_remote_branches "${remote_branches[@]}"
fi

echo "Branch cleanup completed."

# If dry-run, indicate no deletions were performed
if [ "$DRY_RUN" = true ]; then
    echo "Dry-Run Mode: No branches were actually deleted. Review the listed branches above."
fi

