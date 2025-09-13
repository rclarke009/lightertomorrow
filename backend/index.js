require('dotenv').config();
const express = require('express');
const { OpenAI } = require('openai');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const app = express();

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// CORS configuration
const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:8080'];
app.use(cors({
  origin: allowedOrigins,
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // 100 requests per IP
  message: {
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: Math.ceil((parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000) / 1000)
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// Initialize OpenAI
const openai = new OpenAI({ 
  apiKey: process.env.OPENAI_API_KEY 
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Chat endpoint
app.post('/api/chat', async (req, res) => {
  try {
    const { message, context = '', maxTokens = 2000, temperature = 0.7 } = req.body;
    
    // Input validation
    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return res.status(400).json({ 
        error: 'Message is required and must be a non-empty string' 
      });
    }

    if (message.length > 4000) {
      return res.status(400).json({ 
        error: 'Message too long. Maximum 4000 characters.' 
      });
    }

    // System prompt for health and wellness coaching
    const systemPrompt = `You are a compassionate, knowledgeable health and wellness coach powered by OpenAI. Your role is to provide supportive, evidence-based guidance to help users build sustainable healthy habits.

Key principles:
- Be encouraging and non-judgmental
- Provide practical, actionable advice
- Focus on sustainable lifestyle changes
- Acknowledge challenges and setbacks as normal
- Celebrate progress, no matter how small
- Use evidence-based strategies
- Keep responses helpful but not overwhelming
- Respond with empathy, practical advice, and encouragement
- Keep responses detailed but focused

User context: ${context || 'New user starting their health journey'}

Respond with empathy, practical advice, and encouragement. Keep responses detailed but focused.`;

    // Call OpenAI API
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: message.trim() }
      ],
      max_tokens: Math.min(maxTokens, 2000),
      temperature: Math.max(0.1, Math.min(temperature, 2.0)),
      top_p: 1,
      frequency_penalty: 0,
      presence_penalty: 0
    });

    const response = completion.choices[0].message.content;
    const usage = completion.usage;
    
    // Log usage for monitoring (in production, you might want to store this in a database)
    console.log(`API call completed - Tokens used: ${usage.total_tokens}, Model: gpt-4o-mini`);

    res.json({ 
      response, 
      usage: {
        promptTokens: usage.prompt_tokens,
        completionTokens: usage.completion_tokens,
        totalTokens: usage.total_tokens
      },
      model: 'gpt-4o-mini',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('OpenAI API Error:', error);
    
    // Handle specific OpenAI errors
    if (error.status === 429) {
      return res.status(429).json({ 
        error: 'Rate limit exceeded. Please try again later.',
        retryAfter: error.headers?.['retry-after'] || 60
      });
    }
    
    if (error.status === 401) {
      return res.status(500).json({ 
        error: 'Authentication failed. Please contact support.' 
      });
    }
    
    if (error.status === 400) {
      return res.status(400).json({ 
        error: 'Invalid request. Please check your input and try again.' 
      });
    }
    
    // Generic error response
    res.status(500).json({ 
      error: 'Internal server error. Please try again later.',
      message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Endpoint not found',
    availableEndpoints: ['/health', '/api/chat']
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Coacher OpenAI Proxy running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔒 Rate limit: ${process.env.RATE_LIMIT_MAX_REQUESTS || 100} requests per ${Math.ceil((parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000) / 60000)} minutes`);
  console.log(`🌐 CORS origins: ${allowedOrigins.join(', ')}`);
});

module.exports = app;
