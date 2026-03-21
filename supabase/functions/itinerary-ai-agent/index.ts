// Advanced Supabase Edge Function using OpenAI Agents SDK with MCP
// Note: This requires the @openai/agents package which may need npm bundling
// For simpler deployment, use the basic itinerary-ai function instead

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Environment variables
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const SUPABASE_MCP_URL = Deno.env.get("SUPABASE_MCP_URL") || "https://mcp.supabase.com/mcp?project_ref=jaazuuohrdnaggovntit";
const SUPABASE_MCP_AUTH = Deno.env.get("SUPABASE_MCP_AUTH");

interface RequestBody {
  message: string;
  trip: {
    city: string;
    country: string;
    start_date?: string;
    end_date?: string;
    date_display: string;
  };
  saved_locations?: Array<{
    name: string;
    category?: string;
  }>;
  user_id?: string;
}

// Agent instructions for the itinerary builder
const AGENT_INSTRUCTIONS = `You are an AI travel assistant for Voyagr that helps users plan trip itineraries.

Your capabilities:
1. Access the user's trip data from Supabase via MCP connection
2. Retrieve saved locations the user has bookmarked
3. Create personalized day-by-day itineraries
4. Suggest restaurants, attractions, and activities

When building an itinerary:
- Consider the user's saved locations as must-visit places
- Balance activities throughout the day (morning, afternoon, evening)
- Include practical details like estimated times and distances
- Suggest meal breaks at appropriate times
- Consider the destination's culture and customs

Be conversational and ask clarifying questions about:
- Trip pace (relaxed vs packed)
- Budget preferences
- Interest categories (culture, food, nightlife, nature, etc.)
- Mobility considerations

Format itineraries clearly:
**Day 1 - [Theme]**
🌅 Morning (9:00 AM)
- Activity 1
- Activity 2

☀️ Afternoon (1:00 PM)
- Lunch at [Restaurant]
- Activity 3

🌙 Evening (6:00 PM)
- Dinner recommendation
- Evening activity`;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body: RequestBody = await req.json();
    const { message, trip, saved_locations, user_id } = body;

    if (!message || !trip) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build context for the agent
    const tripContext = `
Trip Details:
- Destination: ${trip.city}, ${trip.country}
- Dates: ${trip.date_display}
${trip.start_date ? `- Start: ${trip.start_date}` : ''}
${trip.end_date ? `- End: ${trip.end_date}` : ''}

${saved_locations && saved_locations.length > 0
  ? `Saved Locations:\n${saved_locations.map(l => `- ${l.name} (${l.category || 'General'})`).join('\n')}`
  : 'No saved locations yet.'}
`;

    // For now, use direct OpenAI API call
    // When @openai/agents supports Deno, we can use the full agent setup
    const systemMessage = `${AGENT_INSTRUCTIONS}\n\nCurrent Trip Context:\n${tripContext}`;

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: systemMessage },
          { role: "user", content: message }
        ],
        temperature: 0.7,
        max_tokens: 1500,
      }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI API error: ${response.status}`);
    }

    const data = await response.json();
    const aiResponse = data.choices[0]?.message?.content || "Unable to generate response.";

    return new Response(
      JSON.stringify({ output_text: aiResponse }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
