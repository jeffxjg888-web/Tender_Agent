import { createClient } from 'npm:@supabase/supabase-js@2.58.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const { data: existingUsers } = await supabase
      .from('users')
      .select('email')
      .eq('email', 'admin@example.com')
      .maybeSingle()

    if (existingUsers) {
      return new Response(
        JSON.stringify({ message: 'Admin account already exists', exists: true }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      )
    }

    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: 'admin@example.com',
      password: 'admin123456',
      email_confirm: true,
      user_metadata: {
        full_name: 'Admin',
        role: 'admin'
      }
    })

    if (authError) throw authError

    if (authData.user) {
      const { error: insertError } = await supabase
        .from('users')
        .insert({
          id: authData.user.id,
          email: 'admin@example.com',
          full_name: 'Admin',
          role: 'admin'
        })

      if (insertError) throw insertError

      return new Response(
        JSON.stringify({ 
          message: 'Admin account created successfully',
          created: true,
          email: 'admin@example.com'
        }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      )
    }

    throw new Error('Failed to create admin user')
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    )
  }
})