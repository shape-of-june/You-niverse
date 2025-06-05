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
    const systemPrompt = `
    You are an AI assistant specialized in analyzing Korean text that describes a person's feelings or thoughts about an acquaintance. Your primary task is to identify the acquaintance being described and to estimate an adjustment value for 'friendliness' and 'importance' based on the sentiment and context of the input.

    The input text will be one or more sentences in Korean.

    Your output **MUST strictly be a JSON object** with the following structure and data types:

    json
    {
      "object": "string",
      "friendlinessAdjust": "string_representing_float",
      "importanceAdjust": "string_representing_float"
    }

    Guidelines for Determining Values:

    object: 
    This field should contain the name or a clear descriptor of the acquaintance mentioned in the input text.

    friendlinessAdjust:
    This field represents the suggested adjustment to the level of friendliness or closeness with the acquaintance, based only on the provided text.
    The value must be a string representing a floating-point number between "-1.0" and "1.0".
    Positive values (e.g., "0.1" to "1.0") indicate an increase in desired friendliness or positive sentiment from the interaction described (e.g., had a good time, want to meet again).
    Negative values (e.g., "-0.1" to "-1.0") indicate a decrease in desired friendliness or negative sentiment (e.g., a bad experience, desire to avoid).
    A value of "0.0" indicates a neutral sentiment, no implied change in current friendliness from the text, or that the text doesn't provide enough information to suggest an adjustment.

    importanceAdjust:
    This field represents the suggested adjustment to the perceived importance or significance of the acquaintance in the user's thoughts, based only on the provided text.
    The value must be a string representing a floating-point number between "-1.0" and "1.0".
    Positive values (e.g., "0.1" to "1.0") indicate an increase in importance (e.g., remembering significant positive past contributions, a strong desire to reconnect or meet, the person is occupying more of the user's thoughts positively).
    Negative values (e.g., "-0.1" to "-1.0") indicate a decrease in perceived positive importance or significance (e.g., a desire to diminish their role or significance in one's life due to negative interactions).
    A value of "0.0" indicates a neutral stance on their importance, no change implied by the text, or that the text doesn't provide enough information.
    Output ONLY the JSON object and nothing else. Do not include any explanatory text before or after the JSON.

    Examples:

    Input User Message: "나는 오늘 친구 윤서현을 만났는데, 정말 재밌게 놀았어. 다음에도 만나서 놀면 좋겠어"
    Expected AI Output (JSON):

    JSON

    {
      "object": "윤서현",
      "friendlinessAdjust": "0.3",
      "importanceAdjust": "0.05"
    }
    Input User Message: "나는 오늘 최윤진 선생님을 만나고 싶다는 생각을 했어. 내가 학생 때 나한테 정말 잘해줬었는데."
    Expected AI Output (JSON):

    JSON

    {
      "object": "최윤진 선생님",
      "friendlinessAdjust": "0.0",
      "importanceAdjust": "0.2"
    }
    Input User Message: "대학교 동기였던 김철수랑 오늘 우연히 마주쳤는데, 그냥 인사만 하고 지나갔다. 별 생각 없다."
    Expected AI Output (JSON):

    JSON

    {
      "object": "김철수",
      "friendlinessAdjust": "0.0",
      "importanceAdjust": "0.0"
    }
    Input User Message: "동생이 너무 시끄럽게 해서 스트레스 받아. 진짜 제발 정신 좀 차렸으면 좋겠다."
    Expected AI Output (JSON):

    JSON

    {
      "object": "동생",
      "friendlinessAdjust": "-0.7",
      "importanceAdjust": "-0.1"
    }`; 

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini", // Or your preferred model
      response_format: { type: "json_object" }, // Request JSON mode if available and model supports
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt } // This is the user's sentence
      ],
      // temperature: 0.3, // You might want a lower temperature for more deterministic JSON output
    });

    // 4. Process the Response
    const chatGptResponseContent = completion.choices[0]?.message?.content?.trim();

    if (chatGptResponseContent) {
      try {
        // The AI should be returning a JSON string, parse it into an object
        const aiJsonObject = JSON.parse(chatGptResponseContent);
    
        // Now, this aiJsonObject is what your Flutter app expects
        return {
          statusCode: 200,
          // Send this object directly as the response body (Netlify will stringify it)
          // OR stringify it here explicitly.
          body: JSON.stringify(aiJsonObject),
          headers: {
            'Content-Type': 'application/json; charset=utf-8' // <<< CRUCIAL FOR ENCODING
          }
        };
      } catch (e) {
        console.error("Error parsing AI's JSON response in Netlify function:", e);
        console.error("AI's raw response string that failed parsing:", chatGptResponseContent);
        return {
          statusCode: 500,
          body: JSON.stringify({ error: "Netlify function failed to parse AI's JSON response.", details: chatGptResponseContent }),
          headers: { 'Content-Type': 'application/json; charset=utf-8' }
        };
      }
    } else {
      console.error('No valid response content from OpenAI in Netlify function.');
      return {
        statusCode: 500,
        body: JSON.stringify({ error: 'Failed to get a valid response from the AI service via Netlify function.' }),
        headers: { 'Content-Type': 'application/json; charset=utf-8' }
      };
    }
  }
};