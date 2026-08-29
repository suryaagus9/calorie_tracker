import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const query = url.searchParams.get('query')

    if (!query) throw new Error('Parameter pencarian kosong.')

    // Mengambil kunci rahasia dari sistem Supabase
    const FATSECRET_CLIENT_ID = Deno.env.get('FATSECRET_CLIENT_ID') ?? ''
    const FATSECRET_CLIENT_SECRET = Deno.env.get('FATSECRET_CLIENT_SECRET') ?? ''

    // Meminta token ke FatSecret
    const credentials = btoa(`${FATSECRET_CLIENT_ID}:${FATSECRET_CLIENT_SECRET}`)
    const tokenResponse = await fetch('https://oauth.fatsecret.com/connect/token', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${credentials}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials&scope=basic'
    })

    const tokenData = await tokenResponse.json()
    if (!tokenData.access_token) {
          throw new Error(`Gagal token: ${JSON.stringify(tokenData)}`)
        }
    // Meminta data makanan
    const searchUrl = `https://platform.fatsecret.com/rest/foods/search/v1?search_expression=${encodeURIComponent(query)}&format=json&max_results=15`
    const searchResponse = await fetch(searchUrl, {
      method: 'GET',
      headers: { 'Authorization': `Bearer ${tokenData.access_token}` }
    })

    const searchData = await searchResponse.json()

    return new Response(JSON.stringify(searchData), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})