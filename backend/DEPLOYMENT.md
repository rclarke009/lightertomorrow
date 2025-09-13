# Deployment Guide for Coacher OpenAI Proxy

## Quick Deploy to Vercel (Recommended)

### 1. Prerequisites
- [Vercel account](https://vercel.com) (free tier available)
- [GitHub account](https://github.com)
- OpenAI API key

### 2. Deploy Steps

1. **Fork or upload the backend code to GitHub**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/yourusername/coacher-openai-proxy
   git push -u origin main
   ```

2. **Connect to Vercel**
   - Go to [vercel.com](https://vercel.com)
   - Click "New Project"
   - Import your GitHub repository
   - Select the backend folder as root directory

3. **Set Environment Variables**
   In Vercel dashboard, go to Settings > Environment Variables:
   ```
   OPENAI_API_KEY=sk-proj-your-actual-api-key-here
   NODE_ENV=production
   ALLOWED_ORIGINS=https://your-app-domain.com
   RATE_LIMIT_WINDOW_MS=900000
   RATE_LIMIT_MAX_REQUESTS=100
   ```

4. **Deploy**
   - Click "Deploy"
   - Wait for deployment to complete
   - Copy the deployment URL (e.g., `https://coacher-openai-proxy.vercel.app`)

### 3. Update iOS App
Update the backend URL in your iOS app:
```swift
// In BackendLLMManager.swift
init(backendURL: String = "https://your-deployment-url.vercel.app") {
    // ...
}
```

## Alternative Deployments

### Railway
1. Connect GitHub repository
2. Set environment variables
3. Deploy automatically

### Heroku
1. Create new app
2. Connect GitHub
3. Set config vars
4. Deploy

### DigitalOcean App Platform
1. Create new app
2. Connect GitHub
3. Set environment variables
4. Deploy

## Testing Your Deployment

### 1. Health Check
```bash
curl https://your-deployment-url.vercel.app/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "version": "1.0.0"
}
```

### 2. Chat API Test
```bash
curl -X POST https://your-deployment-url.vercel.app/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "How can I start eating healthier?"}'
```

Expected response:
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

## Security Checklist

- ✅ API key stored in environment variables only
- ✅ CORS configured for your app domain
- ✅ Rate limiting enabled
- ✅ HTTPS enabled (automatic on Vercel)
- ✅ Input validation implemented
- ✅ Error handling without sensitive data exposure

## Monitoring

### 1. Vercel Analytics
- View request logs in Vercel dashboard
- Monitor response times and errors
- Set up alerts for failures

### 2. OpenAI Dashboard
- Monitor token usage and costs
- Set billing alerts
- Track API performance

### 3. Custom Monitoring
Add to your backend for custom metrics:
```javascript
// Log important events
console.log(`API call - User: ${req.ip}, Tokens: ${usage.total_tokens}`);
```

## Cost Management

### 1. Set OpenAI Limits
- Go to OpenAI dashboard
- Set monthly spending limit
- Enable billing alerts

### 2. Monitor Usage
- Check Vercel logs for token usage
- Track costs in OpenAI dashboard
- Consider caching frequent responses

### 3. Optimize
- Use gpt-3.5-turbo for simple queries
- Implement response caching
- Add request deduplication

## Troubleshooting

### Common Issues

1. **CORS Errors**
   - Check ALLOWED_ORIGINS environment variable
   - Ensure your app domain is included

2. **Rate Limit Errors**
   - Check rate limit settings
   - Consider increasing limits for production

3. **API Key Errors**
   - Verify OPENAI_API_KEY is set correctly
   - Check key has sufficient credits

4. **Deployment Failures**
   - Check Vercel build logs
   - Ensure all dependencies are in package.json
   - Verify Node.js version compatibility

### Debug Mode
Set `NODE_ENV=development` to see detailed error messages in responses.

## Production Checklist

- [ ] Environment variables configured
- [ ] CORS origins set correctly
- [ ] Rate limiting configured
- [ ] Health check endpoint working
- [ ] Chat API responding correctly
- [ ] iOS app updated with new URL
- [ ] Monitoring set up
- [ ] Cost limits configured
- [ ] Error handling tested
- [ ] Security review completed
