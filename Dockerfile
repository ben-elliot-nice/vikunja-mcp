FROM node:20-slim

# Install all dependencies (including dev dependencies for building)
WORKDIR /app
COPY package*.json ./
RUN npm ci --ignore-scripts

# Install mcp-proxy globally
RUN npm install -g mcp-proxy

# Copy MCP server code
COPY . .

# Build the TypeScript project
RUN npx tsc

# Expose the proxy port (Railway will set PORT env var)
EXPOSE 8080

# Start mcp-proxy wrapping the stdio server
# Note: Use PORT environment variable for dynamic port assignment (Railway, etc.)
CMD ["sh", "-c", "args=\"mcp-proxy --pass-environment --port ${PORT:-8080} --host 0.0.0.0 --stateless\"; if [ -n \"$MCP_PROXY_API_KEY\" ]; then args=\"$args --apiKey $MCP_PROXY_API_KEY\"; fi; exec $args -- node dist/index.js"]
