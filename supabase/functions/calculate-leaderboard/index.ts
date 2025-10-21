import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

interface LeaderboardRequest {
  filter?: 'all' | 'program' | 'batch'
  program?: string
  batch?: number
  limit?: number
}

interface LeaderboardResponse {
  success: boolean
  leaderboard?: Array<{
    rank: number
    user_id: string
    full_name: string
    student_id: string
    program: string
    batch: number
    total_points: number
    current_level: number
    attendance_streak: number
    profile_image_url?: string
  }>
  error?: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get the current user
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser()

    if (authError || !user) {
      return new Response<LeaderboardResponse>(
        { success: false, error: 'Unauthorized' } as LeaderboardResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      )
    }

    const body: LeaderboardRequest = await req.json()
    const { filter = 'all', program, batch, limit = 50 } = body

    // Build query
    let query = supabaseClient
      .from('profiles')
      .select('id, full_name, student_id, program, batch, total_points, current_level, attendance_streak, avatar_url')
      .eq('role', 'student')
      .order('total_points', ascending: false)
      .limit(limit)

    // Apply filters
    if (filter === 'program' && program) {
      query = query.eq('program', program)
    } else if (filter === 'batch' && batch) {
      query = query.eq('batch', batch)
    }

    const { data: students, error: studentsError } = await query

    if (studentsError || !students) {
      return new Response<LeaderboardResponse>(
        { success: false, error: 'Failed to fetch leaderboard data' } as LeaderboardResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 500,
        }
      )
    }

    // Add rank and format response
    const leaderboard = students.map((student, index) => ({
      rank: index + 1,
      user_id: student.id,
      full_name: student.full_name,
      student_id: student.student_id,
      program: student.program,
      batch: student.batch,
      total_points: student.total_points,
      current_level: student.current_level,
      attendance_streak: student.attendance_streak,
      profile_image_url: student.avatar_url,
    }))

    // Cache the leaderboard result for 5 minutes
    await supabaseClient
      .from('system_settings')
      .upsert({
        key: `leaderboard_cache_${filter}_${program || ''}_${batch || ''}`,
        value: JSON.stringify(leaderboard),
        description: `Cached leaderboard for ${filter} filter`,
        data_type: 'json',
        is_public: true,
        updated_at: new Date().toISOString(),
      })

    const response: LeaderboardResponse = {
      success: true,
      leaderboard,
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('Error in calculate-leaderboard function:', error)
    return new Response<LeaderboardResponse>(
      { success: false, error: 'Internal server error' } as LeaderboardResponse,
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})