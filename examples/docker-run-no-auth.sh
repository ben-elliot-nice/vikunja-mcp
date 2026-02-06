#!/bin/bash
# Example: Running Vikunja MCP server with Docker WITHOUT authentication
# This demonstrates the simpler configuration for development/testing

set -e

# Configuration
VIKUNJA_URL="${VIKUNJA_URL:-https://your-vikunja-instance.com/api/v1}"
VIKUNJA_API_TOKEN="${VIKUNJA_API_TOKEN:-your-api-token}"
CONTAINER_NAME="vikunja-mcp-dev"
IMAGE_NAME="vikunja-mcp"

echo "🐳 Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "🚀 Starting container WITHOUT authentication (development mode)..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --network host \
  -e VIKUNJA_URL="$VIKUNJA_URL" \
  -e VIKUNJA_API_TOKEN="$VIKUNJA_API_TOKEN" \
  "$IMAGE_NAME" \
  mcp-proxy --pass-environment --port 8080 --host 0.0.0.0 --stateless -- node dist/index.js

echo "⏳ Waiting for server to start..."
sleep 3

echo "🧪 Testing WITHOUT API key (should work)..."
RESPONSE=$(curl -s -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}')

TOOL_COUNT=$(echo "$RESPONSE" | grep '^data:' | sed 's/^data: //' | jq '.result.tools | length')
echo "✅ Success! Found $TOOL_COUNT tools without authentication"

echo ""
echo "📝 Container logs:"
docker logs "$CONTAINER_NAME" 2>&1 | tail -5

echo ""
echo "✅ Deployment successful!"
echo ""
echo "⚠️  WARNING: This configuration has NO authentication!"
echo "   Only use this for development/testing behind a firewall."
echo ""
echo "To stop the container:"
echo "  docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME"
echo ""
echo "To view logs:"
echo "  docker logs -f $CONTAINER_NAME"
echo ""
echo "To test with curl:"
echo "  curl -X POST http://localhost:8080/mcp \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -H \"Accept: application/json, text/event-stream\" \\"
echo "    -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}'"
