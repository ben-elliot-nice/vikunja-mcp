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
RUN printf '#!/bin/sh\n\
exec 2>&1\n\
set -x\n\
echo "=== Railway Network Debug START ===" >&2\n\
echo "VIKUNJA_URL=$VIKUNJA_URL" >&2\n\
echo "" >&2\n\
echo "Testing DNS resolution..." >&2\n\
echo "Trying: vikunja.railway.internal" >&2\n\
nslookup vikunja.railway.internal 2>&1 || echo "NSLOOKUP FAILED" >&2\n\
echo "" >&2\n\
echo "Testing: vik.railway.internal" >&2\n\
nslookup vik.railway.internal 2>&1 || echo "NSLOOKUP FAILED" >&2\n\
echo "" >&2\n\
echo "Testing curl to configured VIKUNJA_URL..." >&2\n\
curl -v -s "$VIKUNJA_URL/projects" 2>&1 | head -20 || echo "CURL TO VIKUNJA_URL FAILED" >&2\n\
echo "" >&2\n\
echo "Testing internal service discovery..." >&2\n\
if host vikunja.railway.internal 2>&1 >/dev/null; then\n\
    echo "✓ DNS: vikunja.railway.internal resolves" >&2\n\
    curl -v -s http://vikunja.railway.internal/api/v1 2>&1 | head -20\n\
else\n\
    echo "✗ DNS: vikunja.railway.internal does not resolve" >&2\n\
fi\n\
echo "" >&2\n\
echo "Environment:" >&2\n\
env | grep -E "VIKUNJA|PORT|RAILWAY|NODE" | sort >&2\n\
echo "=== Railway Network Debug END ===" >&2\n' > /usr/local/bin/debug-network.sh && chmod +x /usr/local/bin/debug-network.sh

# Expose the proxy port (Railway will set PORT env var)
EXPOSE 8080

# Start mcp-proxy wrapping the stdio server
# Note: Use PORT environment variable for dynamic port assignment (Railway, etc.)
CMD ["sh", "-c", "echo '===== DEBUG SCRIPT START =====' 2>&1; sh /usr/local/bin/debug-network.sh 2>&1; echo '===== DEBUG SCRIPT END =====' 2>&1; echo '===== Starting MCP Server =====' 2>&1; args=\"mcp-proxy --pass-environment --port ${PORT:-8080} --host 0.0.0.0 --stateless\"; if [ -n \"$MCP_PROXY_API_KEY\" ]; then args=\"$args --apiKey $MCP_PROXY_API_KEY\"; fi; exec $args -- node dist/index.js"]
