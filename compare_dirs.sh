#!/bin/bash

# Usage: ./compare_dirs.sh <branch1> <branch2> <dir_path>
# Example: ./compare_dirs.sh main feature-branch src

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <branch1> <branch2> <dir_path>"
    exit 1
fi

BRANCH1=$1
BRANCH2=$2
DIR_PATH=$3

TMP_DIR1=$(mktemp -d)
TMP_DIR2=$(mktemp -d)

# Ensure we're in a Git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: Not inside a Git repository"
    exit 1
fi

# Fetch branch contents without switching branches
git worktree add "$TMP_DIR1" "$BRANCH1" > /dev/null 2>&1
git worktree add "$TMP_DIR2" "$BRANCH2" > /dev/null 2>&1

# Check if the directory exists in both branches
if [ ! -d "$TMP_DIR1/$DIR_PATH" ]; then
    echo "Error: $DIR_PATH does not exist in $BRANCH1"
    exit 1
fi
if [ ! -d "$TMP_DIR2/$DIR_PATH" ]; then
    echo "Error: $DIR_PATH does not exist in $BRANCH2"
    exit 1
fi

# Compare directories
echo "Comparing $DIR_PATH between $BRANCH1 and $BRANCH2..."
diff -qr "$TMP_DIR1/$DIR_PATH" "$TMP_DIR2/$DIR_PATH"

# Detailed differences
diff -u -r "$TMP_DIR1/$DIR_PATH" "$TMP_DIR2/$DIR_PATH"

# Clean up temporary worktrees
git worktree remove "$TMP_DIR1" --force
git worktree remove "$TMP_DIR2" --force