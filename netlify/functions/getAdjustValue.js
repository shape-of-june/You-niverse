// netlify/functions/chatWithGPT.js

// Import the OpenAI library (for v4.x and later)
const OpenAI = require('openai');
// If using ES Modules (e.g., with .mjs extension or "type": "module" in package.json):
// import OpenAI from 'openai';

exports.handler = async (event, context) => {
  // Handle CORS preflight requests
  console.log('landed getAdjustValue.js function');
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200, // or 204
      headers: {
        'Access-Control-Allow-Origin': '*', // Or specific origin
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization', // Add any other headers your client sends
      },
      body: '',
    };
  }
  // Only allow POST requests
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      body: JSON.stringify({ error: 'Method Not Allowed!!!!!' }),
      headers: { 'Allow': 'POST' },
    };
  }

  // 1. Get OpenAI API Key from Netlify environment variables
  const apiKey = process.env.CHATGPT_API_KEY;

  if (!apiKey) {
    console.error('OpenAI API key is not set in environment variables.');
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Server configuration error: API key missing.' }),
    };
  }

  // Initialize the OpenAI client with the API key
  const openai = new OpenAI({ apiKey });

  // 2. Get the user's prompt from the request body
  let userPrompt;
  try {
    const body = JSON.parse(event.body);
    userPrompt = body.prompt;
    if (!userPrompt || typeof userPrompt !== 'string' || userPrompt.trim() === '') {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Missing or invalid "prompt" in request body. It must be a non-empty string.' }),
      };
    }
  } catch (error) {
    console.error('Error parsing request body:', error);
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Invalid JSON in request body.' }),
    };
  }

  try {
    // 3. Make the API Call to OpenAI
    console.log(`Sending prompt to OpenAI: "${userPrompt}"`);
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini", // Or your preferred model, e.g., "gpt-4"
      messages: [
        { role: "system", content: "You are a helpful assistant." }, // Optional: Define the AI's behavior
        { role: "user", content: userPrompt }
      ],
      // Optional parameters:
      // max_tokens: 150, // Adjust as needed
      // temperature: 0.7, // Adjust for creativity vs. determinism
    });

    // 4. Process the Response
    const chatGptResponse = completion.choices[0]?.message?.content?.trim();

    if (!chatGptResponse) {
      console.error('No valid response content from OpenAI:', JSON.stringify(completion, null, 2));
      return {
        statusCode: 500,
        body: JSON.stringify({ error: 'Failed to get a valid response from the AI service.' }),
      };
    }

    // 5. Return the Response to the Frontend
    return {
      statusCode: 200,
      body: JSON.stringify({ reply: chatGptResponse }),
      headers: { 'Content-Type': 'application/json' },
    };

  } catch (error) {
    console.error('Error calling OpenAI API:', error);
    let errorMessage = 'An error occurred while communicating with the AI service.';
    let errorDetails = null;

    if (error.response) { // Axios-like error structure (OpenAI SDK might have this)
      console.error('OpenAI API Error Status:', error.response.status);
      console.error('OpenAI API Error Data:', error.response.data);
      errorMessage = `AI service error: ${error.response.status}`;
      errorDetails = error.response.data?.error?.message || 'No additional details from AI service.';
    } else if (error.message) { // Generic error
        errorMessage = error.message;
    }

    // For OpenAI SDK v4, errors are typically instances of OpenAI.APIError
    if (error instanceof OpenAI.APIError) {
        console.error('OpenAI APIError Status:', error.status); // e.g. 400
        console.error('OpenAI APIError Message:', error.message); // e.g. Your request was rejected as a result of our safety system.
        console.error('OpenAI APIError Code:', error.code); // e.g. content_policy_violation
        console.error('OpenAI APIError Type:', error.type); // e.g. invalid_request_error
        errorMessage = error.message || `AI service error: ${error.status}`;
        errorDetails = `Type: ${error.type}, Code: ${error.code}`;
    }


    return {
      statusCode: (error instanceof OpenAI.APIError ? error.status : null) || 500,
      body: JSON.stringify({ error: errorMessage, details: errorDetails }),
    };
  }
};