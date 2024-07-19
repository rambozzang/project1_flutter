// import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
// import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// serve(async (req) => {
//   const authHeader = req.headers.get('Authorization')!
//   const supabase = createClient(
//     Deno.env.get('SUPABASE_URL') ?? '',
//     Deno.env.get('SUPABASE_ANON_KEY') ?? '',
//     { global: { headers: { Authorization: authHeader } } }
//   )
  
//   // Get the current user
//   const {
//     data: { user },
//   } = await supabase.auth.getUser()

//   if (!user) {
//     return new Response(JSON.stringify({ error: "Not authenticated" }), {
//       headers: { "Content-Type": "application/json" },
//       status: 401
//     })
//   }

//   // Delete the user
//   const { data, error } = await supabase.rpc('delete_user', {
//     user_id: user.id
//   })

//   if (error) {
//     return new Response(JSON.stringify({ error: error.message }), {
//       headers: { "Content-Type": "application/json" },
//       status: 400
//     })
//   }

//   return new Response(JSON.stringify({ message: "User deleted successfully" }), {
//     headers: { "Content-Type": "application/json" }
//   })
// })