#!/usr/bin/env sh
# ================================================================================
# File: env.sh
# Description: Replaces environment variables in asset files.
# Usage: Run this script in your terminal, ensuring APP_PREFIX and ASSET_DIRS are set.
# ================================================================================

# Set the exit flag to exit immediately if any command fails
set -e

# Check if APP_PREFIX is set
: "${APP_PREFIX:?APP_PREFIX must be set (e.g. APP_PREFIX='APP_PREFIX_')}"

# Check if ASSET_DIRS is set
: "${ASSET_DIRS:?Must set ASSET_DIRS to one or more paths (space-delimited)}"

# Iterate through each directory in ASSET_DIRS
for dir in $ASSET_DIRS; do
  # Check if the directory exists
  if [ ! -d "$dir" ]; then
    # If not, display a warning message and skip to the next iteration
    echo "Warning: directory '$dir' not found, skipping."
    continue
  fi

  # Display the current directory being scanned
  echo "Scanning directory: $dir"
  
  # Iterate through each environment variable that starts with APP_PREFIX
  env | grep "^${APP_PREFIX}" | while IFS='=' read -r key value; do
    # Display the variable being replaced
    echo "  • Replacing ${key} → ${value}"

    # Use find and sed to replace the variable in all files within the directory
    find "$dir" -type f \
      -exec sed -i "s|${key}|${value}|g" {} +
  done
done