// Simple OpenAI integration without external dependencies for now
// We'll use fetch to call OpenAI API directly

exports.handler = async (event, context) => {
  // Handle CORS
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  };

  // Handle preflight requests
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: '',
    };
  }

  try {
    // Only allow POST requests
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        headers,
        body: JSON.stringify({ error: 'Method not allowed' }),
      };
    }

    // Parse request body
    const { message, context: userContext = '', maxTokens = 2000, temperature = 0.7 } = JSON.parse(event.body || '{}');
    
    // Input validation
    if (!message || typeof message !== 'string' || message.trim().length === 0) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ 
          error: 'Message is required and must be a non-empty string' 
        }),
      };
    }

    if (message.length > 4000) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ 
          error: 'Message too long. Maximum 4000 characters.' 
        }),
      };
    }

    // System prompt for weight loss and wellness coaching
    const systemPrompt = `You are a supportive weight loss and wellness coach. 
Your role is to:
        - Provide encouraging feedback or advice
        - Help users understand their eating patterns and behaviors
        - Suggest healthy alternatives and practical strategies or encourage reflection and forward thinking
        - Be empathetic, non-judgmental, and supportive
        - Focus on sustainable lifestyle changes rather than quick fixes
        
        Context about the user's journey: ${userContext || 'New user starting their health journey'}
        
        Respond as a caring coach who understands the challenges of weight loss and provides practical, encouraging guidance. Keep responses under 200 words and end with a supportive question or next step where appropriate.`;

    // Call OpenAI API directly using fetch
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
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
      })
    });

    if (!openaiResponse.ok) {
      const errorData = await openaiResponse.text();
      throw new Error(`OpenAI API error: ${openaiResponse.status} - ${errorData}`);
    }

    const completion = await openaiResponse.json();
    const response = completion.choices[0].message.content;
    const usage = completion.usage;
    
    // Log usage for monitoring
    console.log(`API call completed - Tokens used: ${usage.total_tokens}, Model: gpt-4o-mini`);

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ 
        response, 
        usage: {
          promptTokens: usage.prompt_tokens,
          completionTokens: usage.completion_tokens,
          totalTokens: usage.total_tokens
        },
        model: 'gpt-4o-mini',
        timestamp: new Date().toISOString()
      }),
    };

  } catch (error) {
    console.error('OpenAI API Error:', error);
    
    // Handle specific OpenAI errors
    if (error.status === 429) {
      return {
        statusCode: 429,
        headers,
        body: JSON.stringify({ 
          error: 'Rate limit exceeded. Please try again later.',
          retryAfter: error.headers?.['retry-after'] || 60
        }),
      };
    }
    
    if (error.status === 401) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({ 
          error: 'Authentication failed. Please contact support.' 
        }),
      };
    }
    
    if (error.status === 400) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ 
          error: 'Invalid request. Please check your input and try again.' 
        }),
      };
    }
    
    // Generic error response
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Internal server error. Please try again later.',
        message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
      }),
    };
  }
};
