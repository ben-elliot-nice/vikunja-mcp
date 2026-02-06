FROM node:20-slim

# Install curl for network debugging
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Install all dependencies (including dev dependencies for building)
WORKDIR /app
COPY package*.json ./
RUN npm ci --ignore-scripts

# Install mcp-proxy globally (pinned version for consistency)
RUN npm install -g mcp-proxy@6.4.0

# Copy MCP server code
COPY . .

# Build the TypeScript project
RUN npx tsc

# Add debug script for testing connectivity
RUN printf '#!/bin/sh\n\
echo "NETWORK_DEBUG: VIKUNJA_URL=$VIKUNJA_URL"\n\
echo "NETWORK_DEBUG: Testing HTTP to configured URL"\n\
curl -v -s "$VIKUNJA_URL/projects" 2>&1 | head -10 || echo "NETWORK_DEBUG: HTTP to VIKUNJA_URL failed"\n\
echo "NETWORK_DEBUG: Testing Railway service: vikunja.railway.internal"\n\
curl -v -s "http://vikunja.railway.internal/api/v1/projects" 2>&1 | head -10 || echo "NETWORK_DEBUG: HTTP to vikunja.railway.internal failed"\n\
echo "NETWORK_DEBUG: Testing Railway service: vik.railway.internal"\n\
curl -v -s "http://vik.railway.internal/api/v1/projects" 2>&1 | head -10 || echo "NETWORK_DEBUG: HTTP to vik.railway.internal failed"\n\
echo "NETWORK_DEBUG: Complete"\n\
' > /usr/local/bin/debug-network.sh && chmod +x /usr/local/bin/debug-network.sh

# Expose the proxy port (Railway will set PORT env var)
EXPOSE 8080

# Start mcp-proxy wrapping the stdio server
# Note: Use PORT environment variable for dynamic port assignment (Railway, etc.)
CMD ["sh", "-c", "sh /usr/local/bin/debug-network.sh || true; args=\"mcp-proxy --pass-environment --port ${PORT:-8080} --host 0.0.0.0 --stateless\"; if [ -n \"$MCP_PROXY_API_KEY\" ]; then args=\"$args --apiKey $MCP_PROXY_API_KEY\"; fi; exec $args -- node dist/index.js"]
