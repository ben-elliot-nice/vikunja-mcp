# Docker Deployment Examples

This directory contains example scripts for deploying the Vikunja MCP server with Docker using direct `docker run` commands (as opposed to docker-compose).

## Scripts

### 1. `docker-run-with-auth.sh` - Production Deployment

**Use case**: Production deployments with API key authentication

**Features**:
- ✅ API key authentication required
- ✅ All requests must include `X-API-Key` header
- ✅ Secure for public/exposed deployments
- ✅ Tests both success and failure cases

**Usage**:
```bash
export VIKUNJA_URL="https://your-vikunja-instance.com/api/v1"
export VIKUNJA_API_TOKEN="your-api-token"
export MCP_PROXY_API_KEY="your-secure-api-key"

./docker-run-with-auth.sh
```

**What it does**:
1. Builds the Docker image
2. Starts container with API key authentication
3. Tests connection WITH correct API key (should succeed)
4. Tests connection WITHOUT API key (should fail with 401)
5. Shows container logs and usage instructions

### 2. `docker-run-no-auth.sh` - Development Deployment

**Use case**: Development/testing without authentication

**Features**:
- ⚠️  No authentication (open access)
- ✅ Simpler configuration
- ✅ Quick startup for local development
- ⚠️  **NOT suitable for production or public networks**

**Usage**:
```bash
export VIKUNJA_URL="https://your-vikunja-instance.com/api/v1"
export VIKUNJA_API_TOKEN="your-api-token"

./docker-run-no-auth.sh
```

**What it does**:
1. Builds the Docker image
2. Starts container WITHOUT authentication
3. Tests connection without API key (should succeed)
4. Shows container logs and usage instructions

## Quick Start

### Production (With Authentication)

```bash
cd examples
./docker-run-with-auth.sh
```

### Development (No Authentication)

```bash
cd examples
./docker-run-no-auth.sh
```

## Manual Docker Commands

### With API Key Authentication

```bash
docker run -d \
  --name vikunja-mcp \
  --network host \
  -e VIKUNJA_URL=https://your-vikunja-instance.com/api/v1 \
  -e VIKUNJA_API_TOKEN=your-api-token \
  -e MCP_PROXY_API_KEY=your-secure-api-key \
  vikunja-mcp \
  bash -c 'args="mcp-proxy --pass-environment --port 8080 --host 0.0.0.0 --stateless"; [ -n "$MCP_PROXY_API_KEY" ] && args="$args --apiKey $MCP_PROXY_API_KEY"; exec $args -- node dist/index.js'
```

### Without Authentication

```bash
docker run -d \
  --name vikunja-mcp \
  --network host \
  -e VIKUNJA_URL=https://your-vikunja-instance.com/api/v1 \
  -e VIKUNJA_API_TOKEN=your-api-token \
  vikunja-mcp \
  mcp-proxy --pass-environment --port 8080 --host 0.0.0.0 --stateless -- node dist/index.js
```

## Testing the Deployment

### Test WITH Authentication

```bash
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "X-API-Key: your-secure-api-key" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

### Test WITHOUT Authentication (should fail if auth enabled)

```bash
curl -X POST http://localhost:8080/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

Expected response:
- **With auth enabled**: `401 Unauthorized`
- **Without auth**: Success with tools list

## Cleanup

Stop and remove the container:

```bash
docker stop vikunja-mcp && docker rm vikunja-mcp
```

Or if using the script names:

```bash
# For auth-enabled container
docker stop vikunja-mcp-server && docker rm vikunja-mcp-server

# For dev container
docker stop vikunja-mcp-dev && docker rm vikunja-mcp-dev
```

## Port Mapping vs Host Network

The examples use `--network host` for simplicity. Alternatively, you can use port mapping:

```bash
docker run -d \
  --name vikunja-mcp \
  -p 8080:8080 \
  -e VIKUNJA_URL=https://your-vikunja-instance.com/api/v1 \
  -e VIKUNJA_API_TOKEN=your-api-token \
  -e MCP_PROXY_API_KEY=your-secure-api-key \
  vikunja-mcp \
  bash -c 'args="mcp-proxy --pass-environment --port 8080 --host 0.0.0.0 --stateless"; [ -n "$MCP_PROXY_API_KEY" ] && args="$args --apiKey $MCP_PROXY_API_KEY"; exec $args -- node dist/index.js'
```

**Note**: When using port mapping instead of host network, the container listens on `0.0.0.0:8080` but is accessible from the host at `localhost:8080`.
