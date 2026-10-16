import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { base64Image, prompt } = await req.json()
    
    const keysString = Deno.env.get('GEMINI_API_KEYS') || "";
    const keys = keysString.split(',').map(key => key.trim()).filter(key => key.length > 0);

    if (keys.length === 0) {
      throw new Error("Konfigurasi API Keys tidak ditemukan di server.");
    }

    const parts: any[] = [{ text: prompt }];

    if (base64Image) {
      parts.push({
        inline_data: {
          mime_type: "image/jpeg",
          data: base64Image
        }
      });
    }

    let result = null;
    let success = false;

    for (let i = 0; i < keys.length; i++) {
      const currentKey = keys[i];

      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=${currentKey}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: parts }]
        })
      });

      if (response.ok) {
        result = await response.json();
        success = true;
        break;
      } else if (response.status !== 429) {
        const errText = await response.text();
        console.error("Gemini API Error:", errText);
        throw new Error(errText);
      }
    }

    if (!success) {
      throw new Error("Semua API Key telah mencapai batas kuota (Limit Exceeded).");
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})