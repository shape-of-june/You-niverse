#!/bin/bash

# Script to build a Flutter web application and copy the output to a specified deployment directory.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Assuming this script is run from the root of your Flutter project.
# The FLUTTER_PROJECT_ROOT will be the current directory where the script is executed.
FLUTTER_PROJECT_ROOT=$(pwd)

# Source directory for built Flutter web files
BUILD_OUTPUT_DIR="$FLUTTER_PROJECT_ROOT/build/web"

# Destination directory for the built web app
# This path is relative to the Flutter project root: one level up, then into 'relationship_app'
# This matches the structure: parent_directory/relationship_app/
DESTINATION_DIR="$FLUTTER_PROJECT_ROOT/../relationship_app"

# --- Script Steps ---

echo "----------------------------------------------------"
echo "Starting Flutter Web App Build and Deploy Process"
echo "Flutter Project Root: $FLUTTER_PROJECT_ROOT"
echo "Build Output Source:  $BUILD_OUTPUT_DIR"
echo "Deployment Destination: $DESTINATION_DIR"
echo "----------------------------------------------------"
echo ""

# Step 1: Build the Flutter web application
echo ">>> Step 1: Building Flutter web application..."
echo "Running: flutter build web --release --base-href /relationship_app/"
flutter build web --release --base-href /relationship_app/
echo "Flutter build complete."
echo ""

# Step 2: Clean the destination directory
echo ">>> Step 2: Cleaning destination directory: $DESTINATION_DIR"
# Remove the destination directory if it exists, then recreate it.
# This ensures a clean state for the new build.
if [ -d "$DESTINATION_DIR" ]; then
  echo "Removing existing destination directory..."
  rm -rf "$DESTINATION_DIR"
  echo "Removed: $DESTINATION_DIR"
fi
echo "Creating destination directory..."
mkdir -p "$DESTINATION_DIR" # -p creates parent directories if they don't exist and doesn't error if it already exists
echo "Created: $DESTINATION_DIR"
echo ""

# Step 3: Copy built files to the destination directory
echo ">>> Step 3: Copying built files from $BUILD_OUTPUT_DIR to $DESTINATION_DIR"
# Check if the build output directory exists and is not empty
if [ -d "$BUILD_OUTPUT_DIR" ] && [ "$(ls -A "$BUILD_OUTPUT_DIR")" ]; then
  echo "Copying contents of $BUILD_OUTPUT_DIR/* to $DESTINATION_DIR/"
  # Using `cp -R source/. destination/` or `cp -R source/* destination/` are common ways to copy contents.
  # Using /* ensures only the contents are copied if BUILD_OUTPUT_DIR is not empty.
  cp -R "$BUILD_OUTPUT_DIR"/* "$DESTINATION_DIR"/
  echo "Files copied successfully."
else
  echo "Error: Build output directory ($BUILD_OUTPUT_DIR) is empty or does not exist."
  echo "Please check the Flutter build step for errors."
  exit 1 # Exit with an error code
fi

echo ""
echo "----------------------------------------------------"
echo "Build and deploy process completed successfully!"
echo "Your Flutter web app should now be in: $DESTINATION_DIR"
echo "----------------------------------------------------"

exit 0
