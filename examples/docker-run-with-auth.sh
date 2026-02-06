#!/bin/bash
# Example: Running Vikunja MCP server with Docker and API Key Authentication
# This script demonstrates how to run the server directly with docker run command

set -e

# Configuration
VIKUNJA_URL="${VIKUNJA_URL:-https://your-vikunja-instance.com/api/v1}"
VIKUNJA_API_TOKEN="${VIKUNJA_API_TOKEN:-your-api-token}"
API_KEY="${MCP_PROXY_API_KEY:-my-secure-api-key}"
CONTAINER_NAME="vikunja-mcp-server"
IMAGE_NAME="vikunja-mcp"

echo "🐳 Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "🚀 Starting container with API key authentication..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --network host \
  -e VIKUNJA_URL="$VIKUNJA_URL" \
  -e VIKUNJA_API_TOKEN="$VIKUNJA_API_TOKEN" \
  -e MCP_PROXY_API_KEY="$API_KEY" \
  "$IMAGE_NAME" \
  bash -c 'args="mcp-proxy --pass-environment --port 8080 --host 0.0.0.0 --stateless"; [ -n "$MCP_PROXY_API_KEY" ] && args="$args --apiKey $MCP_PROXY_API_KEY"; exec $args -- node dist/index.js'

echo "⏳ Waiting for server to start..."
sleep 3

echo "🧪 Testing WITH correct API key..."
RESPONSE=$(curl -s -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "X-API-Key: $API_KEY" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}')

TOOL_COUNT=$(echo "$RESPONSE" | grep '^data:' | sed 's/^data: //' | jq '.result.tools | length')
echo "✅ Success! Found $TOOL_COUNT tools with correct API key"

echo ""
echo "🧪 Testing WITHOUT API key (should fail)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}')

if [ "$HTTP_CODE" = "401" ]; then
  echo "✅ Success! Correctly rejected without API key (HTTP $HTTP_CODE)"
else
  echo "❌ Unexpected response code: $HTTP_CODE (expected 401)"
fi

echo ""
echo "📝 Container logs:"
docker logs "$CONTAINER_NAME" 2>&1 | tail -5

echo ""
echo "✅ Deployment successful!"
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
echo "    -H \"X-API-Key: $API_KEY\" \\"
echo "    -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}'"
