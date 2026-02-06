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

# Expose the proxy port
EXPOSE 8080

# Start mcp-proxy wrapping the stdio server
CMD ["mcp-proxy", "--port", "8080", "--", "node", "dist/index.js"]
