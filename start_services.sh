#!/bin/bash

# Exit on error
set -e

# Function to start the umbrella service with IEx
echo "Starting Greenhouse Tycoon umbrella application..."
echo "=========================================================="

# Define the path to the umbrella app
UMBRELLA_APP_PATH="system"

# Start the umbrella application
start_service_iex() {
  echo "Waiting for the umbrella to start..."
  sleep 5
  echo "Starting umbrella application at $UMBRELLA_APP_PATH"
  echo "Web interface will be available at: http://localhost:4000"
  echo "Press Ctrl+C to stop the service"
  echo "=========================================================="

  # Check if umbrella directory exists
  if [ ! -d "$UMBRELLA_APP_PATH" ]; then
    echo "Error: Umbrella directory $UMBRELLA_APP_PATH does not exist"
    exit 1
  fi

  # Get dependencies and start umbrella app
  (cd "$UMBRELLA_APP_PATH" && mix deps.get && mix phx.server)
}

# Function to handle cleanup on exit
cleanup() {
  echo "Stopping the service..."
  pkill -f "iex -S mix"
  pkill -f "mix phx.server"
}

# Trap cleanup function on exit
trap cleanup EXIT

start_service_iex

