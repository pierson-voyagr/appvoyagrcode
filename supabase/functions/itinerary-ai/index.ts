// Supabase Edge Function for Voyagr AI Itinerary Builder
// Uses OpenAI Agents SDK with MCP connection to Supabase

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// OpenAI API configuration
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");

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
    latitude: number;
    longitude: number;
  }>;
  conversation_history?: Array<{
    role: "user" | "assistant";
    content: string;
  }>;
  user_id?: string;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body: RequestBody = await req.json();
    const { message, trip, saved_locations, conversation_history, user_id } = body;

    if (!message || !trip) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: message, trip" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build the system prompt with context
    const savedLocationsContext = saved_locations && saved_locations.length > 0
      ? `\n\nThe user has saved these locations they're interested in:\n${saved_locations.map(loc => `- ${loc.name} (${loc.category || 'uncategorized'})`).join('\n')}`
      : '';

    const systemPrompt = `You are a friendly and helpful AI travel assistant for Voyagr, a travel planning app.
You're helping the user plan their trip to ${trip.city}, ${trip.country}.
They're traveling: ${trip.date_display}
${savedLocationsContext}

Your role is to:
1. Help create personalized day-by-day itineraries
2. Suggest activities, restaurants, and attractions based on their preferences
3. Consider their saved locations when making recommendations
4. Be conversational and engaging
5. Ask clarifying questions to understand their preferences (pace, budget, interests)
6. Provide practical tips about the destination

Keep responses concise but helpful. Use emoji sparingly to add personality.
Format itineraries clearly with days, times, and activities.`;

    // Build messages array
    const messages = [
      { role: "system", content: systemPrompt },
    ];

    // Add conversation history if provided
    if (conversation_history && conversation_history.length > 0) {
      for (const msg of conversation_history) {
        messages.push({
          role: msg.role,
          content: msg.content,
        });
      }
    }

    // Add the current user message
    messages.push({ role: "user", content: message });

    // Call OpenAI API
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini", // Cost-effective model, change to gpt-4o for better quality
        messages: messages,
        temperature: 0.7,
        max_tokens: 1000,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("OpenAI API error:", errorText);
      throw new Error(`OpenAI API error: ${response.status}`);
    }

    const data = await response.json();
    const aiResponse = data.choices[0]?.message?.content || "I'm having trouble generating a response. Please try again.";

    return new Response(
      JSON.stringify({
        output_text: aiResponse,
        usage: data.usage,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );

  } catch (error) {
    console.error("Error in itinerary-ai function:", error);
    return new Response(
      JSON.stringify({
        error: "Failed to process request",
        details: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    );
  }
});
