# Railway Deployment Guide

This guide explains how to deploy the Vikunja MCP server to [Railway](https://railway.app/).

## Quick Start

### 1. Create New Project on Railway

1. Go to [railway.app](https://railway.app/)
2. Click "New Project" → "Deploy from GitHub repo"
3. Select your forked `vikunja-mcp` repository
4. Railway will detect it's a Docker project automatically

### 2. Configure Environment Variables

In Railway dashboard, add these environment variables:

**Required:**
```
VIKUNJA_URL=https://your-vikunja-instance.com/api/v1
VIKUNJA_API_TOKEN=your-api-token
```

**Optional (Recommended for Production):**
```
MCP_PROXY_API_KEY=your-secure-api-key-here
DEBUG=false
LOG_LEVEL=info
```

### 3. Deploy Settings

**Dockerfile:** `Dockerfile` (root of repo)

**Start Command** (if you want to override Dockerfile CMD):

```bash
# With conditional API key authentication
/bin/sh -c 'args="mcp-proxy --pass-environment --port $PORT --host 0.0.0.0 --stateless"; [ -n "$MCP_PROXY_API_KEY" ] && args="$args --apiKey $MCP_PROXY_API_KEY"; exec $args -- node dist/index.js'
```

**OR** simpler version without API key auth:

```bash
/bin/sh -c 'exec mcp-proxy --pass-environment --port $PORT --host 0.0.0.0 --stateless -- node dist/index.js'
```

**Note:** The Dockerfile already includes a flexible CMD that uses `${PORT:-8080}`, so you may not need to specify a custom start command at all!

### 4. Deployment

Railway will automatically:
- Build the Docker image
- Start the container
- Assign a public URL
- Set the `PORT` environment variable

### 5. Access Your MCP Server

Once deployed, Railway will provide a URL like:
```
https://your-project.up.railway.app
```

Your MCP endpoints will be:
- **Stream endpoint**: `https://your-project.up.railway.app/mcp`
- **SSE endpoint**: `https://your-project.up.railway.app/sse`

## Testing the Deployment

### Without Authentication (if MCP_PROXY_API_KEY not set):

```bash
curl -X POST https://your-project.up.railway.app/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
```

### With Authentication (if MCP_PROXY_API_KEY is set):

```bash
curl -X POST https://your-project.up.railway.app/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "X-API-Key: your-secure-api-key-here" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

## Railway-Specific Considerations

### PORT Environment Variable

Railway dynamically assigns a port and sets the `PORT` environment variable. The Dockerfile CMD uses:
```bash
--port ${PORT:-8080}
```

This means:
- On Railway: Uses the assigned `$PORT`
- Locally: Defaults to `8080` if `PORT` not set

### Health Checks

Railway automatically detects HTTP services. You can add a health check in Railway settings:

**Path:** `/mcp`
**Method:** `POST`
**Body:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": {"name": "healthcheck", "version": "1.0"}
  }
}
```

**Headers:**
```
Content-Type: application/json
Accept: application/json, text/event-stream
X-API-Key: your-api-key  # If using auth
```

### Public vs Private Deployment

**Public Deployment (No API Key):**
- Set `MCP_PROXY_API_KEY` to empty or don't set it
- Anyone with the URL can access your MCP server
- ⚠️  Only use this for public instances or testing

**Private Deployment (With API Key):**
- Set `MCP_PROXY_API_KEY` to a secure random string
- All requests must include `X-API-Key` header
- ✅ Recommended for production

### Automatic Deployments

Railway can automatically redeploy when you push to your GitHub repository:

1. Go to your project settings
2. Enable "Automatic Deployments"
3. Select the branch to watch (e.g., `main`)
4. Every push to that branch triggers a new deployment

## Troubleshooting

### Container Won't Start

**Check logs in Railway dashboard:**
- Click on your service
- Go to "Logs" tab
- Look for error messages

**Common issues:**
- Missing `VIKUNJA_URL` or `VIKUNJA_API_TOKEN`
- Invalid Vikunja URL (must include `/api/v1` suffix)
- Network connectivity to Vikunja instance

### 401 Unauthorized Errors

**Cause:** API key authentication is enabled but you're not providing the key

**Solutions:**
1. Add `X-API-Key: your-key` header to requests
2. OR remove `MCP_PROXY_API_KEY` environment variable to disable auth

### Connection Refused

**Cause:** Container hasn't fully started yet

**Solution:** Wait 30-60 seconds after deployment before testing

### Port Already in Use

**Cause:** Using hardcoded port instead of `$PORT`

**Solution:** Ensure start command uses `$PORT` environment variable

## Example Railway Configuration

### railway.json (Optional)

You can add a `railway.json` file to your repo root:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "deploy": {
    "healthcheckPath": "/mcp",
    "healthcheckProtocol": "HTTP",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

## Cost Considerations

- Railway offers a free tier ($5/month credit)
- MCP server is lightweight, should fit within free tier
- Consider:
  - Number of requests (rate limiting helps)
  - Memory usage (container ~200-500MB)
  - Network traffic (MCP protocol is efficient)

## Production Checklist

Before going to production:

- [ ] Set strong `MCP_PROXY_API_KEY`
- [ ] Enable `DEBUG=false` and `LOG_LEVEL=info` or `warn`
- [ ] Configure rate limiting (already enabled by default)
- [ ] Test with Railway's public URL
- [ ] Set up monitoring/alerting in Railway dashboard
- [ ] Configure automatic deployments
- [ ] Add health checks
- [ ] Document the public URL and API key for your team

## Alternative Deployment Methods

If Railway doesn't work for you, consider:

- [Docker Compose](../README.md#option-3-docker-deployment) - VPS or local server
- [Direct Docker](../examples/README.md) - Any Docker host
- Other platforms: Fly.io, Render, DigitalOcean App Platform
