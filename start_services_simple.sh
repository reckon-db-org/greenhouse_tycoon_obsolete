#!/bin/bash

# Exit on error
set -e

# Function to handle cleanup on exit
cleanup() {
  echo "Stopping the service..."
  pkill -f "mix run --no-halt"
  pkill -f "mix phx.server"
}

# Trap cleanup function on exit
trap cleanup EXIT

# Path to the umbrella app
UMBRELLA_APP_PATH="system"

echo "Starting Greenhouse Tycoon umbrella application (simple mode)..."
echo "=========================================================="

# Function to show service status dashboard
show_service_status() {
  echo "Service Status Dashboard"
  echo "========================="
  echo "| Service            | Status | PID     | CPU% | MEM% |"
  echo "|-------------------|--------|---------|------|------|"
  
  # Check greenhouse_tycoon service
  if pgrep -f "greenhouse_tycoon" | xargs -I {} ps -p {} -o args --no-headers 2>/dev/null | grep -q "mix run --no-halt"; then
    pid=$(pgrep -f "greenhouse_tycoon" | head -1)
    cpu_mem=$(ps -p $pid -o %cpu,%mem --no-headers 2>/dev/null || echo "N/A N/A")
    cpu=$(echo $cpu_mem | awk '{print $1}')
    mem=$(echo $cpu_mem | awk '{print $2}')
    printf "| %-17s | %-6s | %-7s | %-4s | %-4s |\n" "greenhouse_tycoon" "RUNNING" "$pid" "$cpu" "$mem"
  else
    printf "| %-17s | %-6s | %-7s | %-4s | %-4s |\n" "greenhouse_tycoon" "STOPPED" "N/A" "N/A" "N/A"
  fi
  
  echo "|-------------------|--------|---------|------|------|"
  echo "Total processes: $(pgrep -f "mix run --no-halt" | wc -l)"
  echo
}

# Start the umbrella application
start_service() {
  local service_path="$1"
  local service_name="$(basename "$service_path")"
  echo "Starting service: $service_name at $service_path"
  
  # Check if directory exists
  if [ ! -d "$service_path" ]; then
    echo "Error: Directory $service_path does not exist"
    return 1
  fi
  
  # Get dependencies and start service
  (cd "$service_path" && mix deps.get && echo "Starting $service_name..." && mix run --no-halt &)
}

# Start the umbrella service
start_service "$UMBRELLA_APP_PATH"

echo "Waiting for service to start..."
sleep 5

# Initial service status check
show_service_status

echo "Greenhouse Tycoon umbrella application started successfully!"
echo "Press Ctrl+C to stop the service"
echo "=========================================================="

# Keep the script running and show periodic status
while true; do
  echo "\n$(date): Service running...\n"
  show_service_status
  sleep 10
done
