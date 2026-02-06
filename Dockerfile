FROM node:20-slim

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
RUN cat > /usr/local/bin/debug-network.sh << 'EOF'
#!/bin/sh
echo "NETWORK_DEBUG: VIKUNJA_URL=$VIKUNJA_URL"
echo "NETWORK_DEBUG: Testing DNS for vikunja.railway.internal"
nslookup vikunja.railway.internal 2>&1 || echo "NETWORK_DEBUG: DNS lookup failed"
echo "NETWORK_DEBUG: Testing DNS for vik.railway.internal"
nslookup vik.railway.internal 2>&1 || echo "NETWORK_DEBUG: DNS lookup failed"
echo "NETWORK_DEBUG: Testing HTTP to VIKUNJA_URL"
curl -v -s "$VIKUNJA_URL/projects" 2>&1 | head -5 || echo "NETWORK_DEBUG: HTTP request failed"
echo "NETWORK_DEBUG: Environment vars"
env | grep -E "VIKUNJA|PORT|RAILWAY" | sort || echo "NETWORK_DEBUG: No env vars found"
echo "NETWORK_DEBUG: Complete"
EOF
chmod +x /usr/local/bin/debug-network.sh

# Expose the proxy port (Railway will set PORT env var)
EXPOSE 8080

# Start mcp-proxy wrapping the stdio server
# Note: Use PORT environment variable for dynamic port assignment (Railway, etc.)
CMD ["sh", "-c", "sh /usr/local/bin/debug-network.sh || true; args=\"mcp-proxy --pass-environment --port ${PORT:-8080} --host 0.0.0.0 --stateless\"; if [ -n \"$MCP_PROXY_API_KEY\" ]; then args=\"$args --apiKey $MCP_PROXY_API_KEY\"; fi; exec $args -- node dist/index.js"]
