#!/bin/bash
# Meta Index Protocol - All-in-One Development Script
# Starts Anvil, deploys contracts, and runs the frontend

set -e

echo "🚀 Meta Index Protocol - All-in-One Development"
echo "================================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Cleanup function
cleanup() {
  echo ""
  echo "${YELLOW}🛑 Shutting down...${NC}"
  if [ ! -z "$ANVIL_PID" ]; then
    echo "Stopping Anvil (PID: $ANVIL_PID)..."
    kill $ANVIL_PID 2>/dev/null || true
  fi
  if [ ! -z "$FRONTEND_PID" ]; then
    echo "Stopping Frontend (PID: $FRONTEND_PID)..."
    kill $FRONTEND_PID 2>/dev/null || true
  fi
  exit 0
}

# Set up trap to cleanup on exit
trap cleanup SIGINT SIGTERM EXIT

# Check if Anvil is already running
if nc -z localhost 8545 2>/dev/null; then
  echo "${YELLOW}⚠️  Anvil is already running on port 8545${NC}"
  echo "Please stop it first or use dev-setup.sh instead"
  exit 1
fi

# Start Anvil in background
echo ""
echo "${BLUE}⚙️  Starting Anvil...${NC}"
anvil > /tmp/anvil.log 2>&1 &
ANVIL_PID=$!
echo "Anvil started (PID: $ANVIL_PID)"

# Wait for Anvil to be ready
echo "Waiting for Anvil to be ready..."
for i in {1..10}; do
  if nc -z localhost 8545 2>/dev/null; then
    echo "${GREEN}✅ Anvil is ready${NC}"
    break
  fi
  if [ $i -eq 10 ]; then
    echo "❌ Anvil failed to start"
    exit 1
  fi
  sleep 1
done

# Run the dev-setup script
echo ""
echo "${BLUE}🔧 Running development setup...${NC}"
bash "$SCRIPT_DIR/dev-setup.sh"

# Start the frontend
echo ""
echo "${BLUE}🌐 Starting frontend...${NC}"
cd "$PROJECT_ROOT/frontend"
npm run dev:anvil > /tmp/frontend.log 2>&1 &
FRONTEND_PID=$!
echo "Frontend started (PID: $FRONTEND_PID)"

# Wait for frontend to be ready
echo "Waiting for frontend to be ready..."
for i in {1..20}; do
  if nc -z localhost 5173 2>/dev/null; then
    echo "${GREEN}✅ Frontend is ready${NC}"
    break
  fi
  if [ $i -eq 20 ]; then
    echo "${YELLOW}⚠️  Frontend may still be starting...${NC}"
  fi
  sleep 1
done

echo ""
echo "${GREEN}================================================"
echo "✨ Everything is running! ✨"
echo "================================================${NC}"
echo ""
echo "📱 Frontend: http://localhost:5173"
echo "⛓️  Anvil RPC: http://localhost:8545"
echo ""
echo "📋 Logs:"
echo "  Anvil: tail -f /tmp/anvil.log"
echo "  Frontend: tail -f /tmp/frontend.log"
echo ""
echo "🔑 MetaMask Setup:"
echo "  Network: Anvil Local"
echo "  RPC URL: http://127.0.0.1:8545"
echo "  Chain ID: 31337"
echo "  Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
echo ""
echo "${YELLOW}Press Ctrl+C to stop all services${NC}"
echo ""

# Keep script running and wait for user interrupt
wait
