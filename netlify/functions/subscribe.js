exports.handler = async (event, context) => {
  // Handle CORS
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  // Handle preflight requests
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: '',
    };
  }

  // Only allow POST requests
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  }

  try {
    // Parse request body
    const { email } = JSON.parse(event.body || '{}');
    
    // Input validation
    if (!email || typeof email !== 'string' || email.trim().length === 0) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ 
          error: 'Email is required and must be a non-empty string' 
        }),
      };
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ 
          error: 'Please provide a valid email address' 
        }),
      };
    }

    // Call MailerLite API
    const mailerliteResponse = await fetch('https://connect.mailerlite.com/api/subscribers', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.MAILERLITE_API_KEY}`,
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        email: email.trim(),
        groups: [process.env.MAILERLITE_GROUP_ID]
      })
    });

    if (!mailerliteResponse.ok) {
      const errorData = await mailerliteResponse.text();
      console.error('MailerLite API error:', errorData);
      
      // Handle specific MailerLite errors
      if (mailerliteResponse.status === 409) {
        return {
          statusCode: 200, // Treat duplicate as success
          headers,
          body: JSON.stringify({ 
            message: 'Email already subscribed',
            success: true 
          }),
        };
      }
      
      throw new Error(`MailerLite API error: ${mailerliteResponse.status}`);
    }

    const result = await mailerliteResponse.json();
    
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ 
        message: 'Successfully subscribed!',
        success: true,
        data: result
      }),
    };

  } catch (error) {
    console.error('Subscription error:', error);
    
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Failed to subscribe. Please try again later.',
        success: false
      }),
    };
  }
};
