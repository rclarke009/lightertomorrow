# Coacher OpenAI Proxy Backend

A secure backend proxy for the Coacher app that handles OpenAI API requests without exposing API keys to the client.

## Features

- 🔒 **Secure API Key Storage** - OpenAI API key stored server-side only
- 🚀 **Rate Limiting** - Prevents abuse with configurable limits
- 🌐 **CORS Support** - Configurable cross-origin resource sharing
- 📊 **Usage Monitoring** - Logs token usage for cost tracking
- 🛡️ **Input Validation** - Sanitizes and validates user inputs
- ⚡ **Error Handling** - Comprehensive error responses
- 🏥 **Health Check** - Monitoring endpoint for uptime

## Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Environment Setup
```bash
cp env.example .env
```

Edit `.env` with your configuration:
```env
OPENAI_API_KEY=sk-proj-your-actual-api-key-here
PORT=3000
NODE_ENV=production
ALLOWED_ORIGINS=https://your-app-domain.com
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### 3. Run Locally
```bash
npm start
```

For development with auto-restart:
```bash
npm run dev
```

### 4. Test the API
```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "How can I start eating healthier?", "context": "Beginner with no diet experience"}'
```

## API Endpoints

### Health Check
```
GET /health
```
Returns server status and version information.

### Chat
```
POST /api/chat
```

**Request Body:**
```json
{
  "message": "How can I start eating healthier?",
  "context": "Beginner with no diet experience",
  "maxTokens": 2000,
  "temperature": 0.7
}
```

**Response:**
```json
{
  "response": "Starting to eat healthier is a journey...",
  "usage": {
    "promptTokens": 45,
    "completionTokens": 150,
    "totalTokens": 195
  },
  "model": "gpt-4o-mini",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## Deployment

### Vercel (Recommended)
1. Install Vercel CLI: `npm i -g vercel`
2. Run `vercel` in the backend directory
3. Set environment variables in Vercel dashboard
4. Update your iOS app with the deployed URL

### Heroku
1. Create a new Heroku app
2. Set environment variables: `heroku config:set OPENAI_API_KEY=your-key`
3. Deploy: `git push heroku main`

### Railway
1. Connect your GitHub repository
2. Set environment variables in Railway dashboard
3. Deploy automatically on push

## Security Features

- **API Key Protection** - Never exposed to client
- **Rate Limiting** - Prevents abuse
- **Input Validation** - Sanitizes user inputs
- **CORS Configuration** - Restricts origins
- **Error Handling** - No sensitive data in error responses
- **HTTPS Only** - All production traffic encrypted

## Monitoring

- Check `/health` endpoint for uptime monitoring
- Monitor logs for token usage and errors
- Set up alerts for rate limit violations
- Track costs in OpenAI dashboard

## Cost Management

- Monitor token usage in logs
- Set OpenAI billing alerts
- Consider caching frequent responses
- Use gpt-3.5-turbo for non-critical features

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | Your OpenAI API key | Required |
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Environment | development |
| `ALLOWED_ORIGINS` | CORS origins (comma-separated) | localhost:8080 |
| `RATE_LIMIT_WINDOW_MS` | Rate limit window in ms | 900000 (15 min) |
| `RATE_LIMIT_MAX_REQUESTS` | Max requests per window | 100 |

## Support

For issues or questions:
1. Check the logs for error details
2. Verify environment variables are set correctly
3. Test with the health check endpoint
4. Ensure OpenAI API key is valid and has credits
