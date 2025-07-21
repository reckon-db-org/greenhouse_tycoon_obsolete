#!/bin/zsh

# This script refreshes the dependencies for the Greenhouse Tycoon ecosystem.

echo "Refreshing dependencies for Greenhouse Tycoon apps and umbrella..."

# Define the path to the umbrella app
UMBRELLA_PATH="system"

echo "Processing $UMBRELLA_PATH..."
# Change to the umbrella directory
cd "$UMBRELLA_PATH" || exit

# Get the dependencies
mix deps.get

# Compile the dependencies
mix deps.compile

# Return to the root directory
cd - || exit

echo "Dependencies have been refreshed for all apps."
