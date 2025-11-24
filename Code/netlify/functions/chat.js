// Simple OpenAI integration without external dependencies for now
// We'll use fetch to call OpenAI API directly

// Crisis detection keywords and phrases
// Based on IS PATH WARM? framework, Columbia Suicide Severity Rating Scale,
// and official suicide prevention resources
// Split into high-risk (always trigger) and moderate-risk (require context)

// HIGH-RISK: Always trigger crisis response immediately
const highRiskKeywords = [
  // ===== IS PATH WARM? - IDEATION (I) =====
  // Direct suicidal statements
  'kill myself', 'end my life', 'suicide', 'not want to live', 'better off dead',
  'want to die', 'don\'t want to exist', 'take my life', 'end it all',
  'no reason to live', 'life isn\'t worth', 'life is not worth',
  'committing suicide', 'die by suicide', 'complete suicide',
  
  // Conditional/modal suicidal ideation (could, might, should, would, want to)
  'could kill myself', 'might kill myself', 'should kill myself', 'would kill myself',
  'want to kill myself', 'thinking of killing', 'thinking about killing',
  'could end my life', 'might end my life', 'should end my life', 'would end my life',
  'want to end my life', 'could take my life', 'might take my life',
  'thinking of ending', 'thinking about ending', 'thoughts of ending',
  'could die', 'want to die', 'wish i was dead', 'wish i were dead',
  'want to be dead', 'should just die', 'would be better dead',
  'might as well die', 'wouldn\'t mind dying', 'don\'t care if i die',
  
  // Suicidal ideation phrases
  'thinking about suicide', 'suicidal thoughts', 'suicidal ideation',
  'thoughts of suicide', 'having suicidal thoughts', 'suicidal thinking',
  'feel suicidal', 'feeling suicidal', 'become suicidal',
  'contemplating suicide', 'considering suicide',
  
  // ===== IS PATH WARM? - PURPOSELESSNESS (P) =====
  'no reason to live', 'no reason for living', 'no purpose',
  'no point', 'no point in living', 'see no point', 'what\'s the point',
  'pointless', 'everything is pointless', 'nothing matters',
  'life has no meaning', 'no meaning in life', 'meaningless',
  'nothing to live for', 'no reason to continue', 'no reason to stay',
  
  // ===== IS PATH WARM? - TRAPPED (T) =====
  'trapped', 'feel trapped', 'feeling trapped', 'can\'t escape',
  'no way out', 'there\'s no way out', 'stuck', 'no escape',
  'nowhere to turn', 'no options', 'no choice', 'no alternatives',
  
  // ===== IS PATH WARM? - HOPELESSNESS (H) =====
  'hopeless', 'no hope', 'all hope is gone', 'lost all hope',
  'desperate', 'desperation', 'no future', 'no tomorrow',
  'things will never get better', 'it will never change',
  'always be like this', 'can\'t be fixed', 'unfixable',
  'give up', 'giving up', 'ready to give up', 'about to give up',
  
  // ===== ABSOLUTIST LANGUAGE =====
  'always this way', 'never get better', 'never going to change',
  'nothing works', 'nothing helps', 'everything is wrong',
  'everything is bad', 'absolutely hopeless', 'completely useless',
  
  // ===== SELF-HARM =====
  'hurt myself', 'self harm', 'self-harm', 'cut myself', 'cutting',
  'harm myself', 'hurting myself', 'self injury', 'self-injury',
  'could hurt myself', 'might hurt myself', 'want to hurt myself',
  'thinking of hurting', 'thinking about hurting', 'hurting myself',
  'burn myself', 'hit myself', 'punish myself',
  
  // ===== PLANNING & METHOD =====
  'have a plan', 'made a plan', 'have a method', 'know how i\'ll',
  'planning to hurt', 'planning to kill', 'plan to end it',
  'going to hurt myself', 'going to kill myself', 'going to end it',
  'going to do it', 'ready to do it', 'prepared to die',
  'got everything ready', 'all planned out',
  
  // ===== IMMINENT DANGER (specific phrases) =====
  'final goodbye', 'see you never', 'wont see me again',
  'this is the last', 'my last message', 'last time',
  'doing it now', 'about to do it', 'by the time you read this',
  
  // ===== CRISIS LANGUAGE =====
  'can\'t go on', 'can\'t continue', 'can\'t take it anymore',
  'can\'t handle this', 'can\'t deal with this', 'too much',
  'enough', 'had enough', 'i\'ve had enough',
  'tired of living', 'tired of life', 'sick of living',
  'done with life', 'finished with life',
  
  // ===== WITHDRAWAL & ISOLATION =====
  'no one cares', 'nobody cares', 'no one would miss me',
  'better without me', 'they\'d be better off', 'everyone would be better',
  'no one understands', 'all alone', 'completely alone',
  'no friends', 'lost everyone', 'everyone left',
  
  // ===== PAIN & SUFFERING =====
  'too much pain', 'can\'t bear the pain', 'pain too much',
  'suffering', 'too much suffering', 'end the suffering',
  'make it stop', 'need it to stop', 'want it to end',
  'final peace', 'eternal peace', 'no more pain', 'end all pain',
  
  // ===== ADDITIONAL VARIATIONS =====
  'off myself', 'do myself in', 'end myself',
  'check out', 'checking out', 'opt out',
  'cease to exist', 'stop existing', 'not exist',
  'not be here', 'won\'t be here', 'be gone',
  'make myself disappear', 'vanish', 'just disappear'
];

// MODERATE-RISK: Only trigger if combined with other crisis indicators
// These are common words that need context to avoid false positives
const moderateRiskKeywords = [
  'goodbye',  // Normal in conversation, but concerning with other indicators
  'tonight',  // Only risky if combined with action words
  'today',    // Only risky if combined with action words
  'right now', // Only risky if combined with action words
  'peace',    // Common word, only risky with crisis context
  'release'   // Common word, only risky with crisis context
];

// Check if message contains crisis language
// Two-tier system: high-risk always triggers, moderate-risk requires context
function detectCrisisLanguage(message) {
  const lowerMessage = message.toLowerCase();
  
  // Check high-risk keywords first (always trigger)
  if (highRiskKeywords.some(keyword => lowerMessage.includes(keyword))) {
    return true;
  }
  
  // Check moderate-risk keywords, but only if combined with other crisis indicators
  const hasModerateRiskKeyword = moderateRiskKeywords.some(keyword => lowerMessage.includes(keyword));
  if (hasModerateRiskKeyword) {
    // Check if message also contains any high-risk indicators
    // This provides context awareness to avoid false positives
    const hasHighRiskContext = highRiskKeywords.some(keyword => lowerMessage.includes(keyword));
    
    // Also check for crisis-related context words even if not in high-risk list
    const contextIndicators = [
      'kill', 'die', 'suicide', 'end', 'hurt', 'pain', 'suffering',
      'hopeless', 'desperate', 'trapped', 'give up', 'no way out',
      'alone', 'no one', 'better off', 'no point', 'meaningless'
    ];
    const hasCrisisContext = contextIndicators.some(indicator => lowerMessage.includes(indicator));
    
    // Only trigger if moderate-risk keyword has crisis context
    return hasHighRiskContext || hasCrisisContext;
  }
  
  return false;
}

// Generate crisis response with hotline information
function generateCrisisResponse() {
  return {
    isCrisis: true,
    response: `I'm concerned about what you're sharing. Your life has value, and there are people who want to help you right now.

Please reach out for immediate support:

• 988 Suicide & Crisis Lifeline: Call or text 988 (available 24/7)
• Crisis Text Line: Text HOME to 741741
• In an emergency, call 911

These services are free, confidential, and available 24/7. You don't have to face this alone.`,
    resources: {
      suicideHotline: '988',
      crisisTextLine: 'Text HOME to 741741',
      emergency: '911'
    }
  };
}

// Detect if OpenAI returned a guardrail/refusal response
function detectGuardrailResponse(response) {
  const lowerResponse = response.toLowerCase();
  
  // Common guardrail phrases OpenAI uses
  const guardrailPhrases = [
    "i can't help",
    "i cannot assist",
    "i'm not able to",
    "i cannot provide",
    "i'm not allowed",
    "i can't provide information",
    "i can't help with that",
    "i cannot help with",
    "i'm unable to",
    "i'm sorry, but i cannot",
    "i can't provide that",
    "i cannot provide that information",
    "i cannot and will not",
    "i'm designed not to",
    "i cannot answer that",
    "i can't answer that",
    "i cannot support",
    "i cannot provide advice",
    "i cannot provide recommendations",
    "content policy",
    "safety guidelines",
    "i can't engage",
    "i cannot engage with",
    "i must decline",
    "i have to decline",
    "i cannot generate",
    "i can't generate",
    "not appropriate",
    "not able to comply"
  ];
  
  // Check if response contains any guardrail phrase
  return guardrailPhrases.some(phrase => lowerResponse.includes(phrase));
}

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

    // Check for crisis language BEFORE processing
    if (detectCrisisLanguage(message)) {
      console.log('⚠️ CRISIS DETECTED - Returning emergency resources');
      const crisisResponse = generateCrisisResponse();
      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          ...crisisResponse,
          usage: {
            promptTokens: 0,
            completionTokens: 0,
            totalTokens: 0
          },
          model: 'crisis-detection',
          timestamp: new Date().toISOString()
        })
      };
    }

    // System prompt for health and wellness coaching
    const systemPrompt = `You are a compassionate health and wellness coach. Respond like you're texting a supportive friend - brief, focused, and conversational.

Response Guidelines:
- Keep each response to 2-3 sentences (approximately 80-120 words max)
- Focus on ONE thing per message: either encouragement, OR a question, OR one piece of advice, OR validation
- Rotate naturally between response types across the conversation
- Don't try to cover everything in one message - let advice and insights unfold over the conversation
- Be warm, empathetic, and non-judgmental
- Match the user's energy level and depth

CRITICAL SAFETY PROTOCOL:
- If a user expresses thoughts of suicide, self-harm, or wanting to end their life, you MUST immediately provide crisis resources
- Include: 988 Suicide & Crisis Lifeline (call/text 988), Crisis Text Line (text HOME to 741741), and 911 for emergencies
- Acknowledge their pain with compassion, emphasize their life has value, and direct them to immediate professional help
- Do not minimize their feelings, but always prioritize getting them to professional crisis support

User context: ${userContext || 'New user starting their health journey'}

Remember: You're having a conversation, not giving a comprehensive answer. Less is more.`;

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
    let response = completion.choices[0].message.content;
    const usage = completion.usage;
    
    // Check if response is a guardrail/refusal and replace with standardized message
    if (detectGuardrailResponse(response)) {
      console.log('🛡️ GUARDRAIL DETECTED - Replacing with standardized message');
      response = "I'm sorry, but I can't assist with that.";
    }
    
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
