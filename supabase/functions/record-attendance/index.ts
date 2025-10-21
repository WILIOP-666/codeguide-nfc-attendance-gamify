import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AttendanceRequest {
  nfc_uid?: string
  card_type?: string
  student_id?: string
  class_id?: string
  admin_id: string
  check_in_method: 'nfc' | 'manual'
  notes?: string
}

interface AttendanceResponse {
  success: boolean
  attendance_id?: string
  points_earned?: number
  new_streak?: number
  error?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
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

    // Get the current user (admin)
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser()

    if (authError || !user) {
      return new Response<AttendanceResponse>(
        { success: false, error: 'Unauthorized' } as AttendanceResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      )
    }

    // Verify admin role
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (profileError || profile?.role !== 'admin') {
      return new Response<AttendanceResponse>(
        { success: false, error: 'Forbidden: Admin access required' } as AttendanceResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 403,
        }
      )
    }

    const body: AttendanceRequest = await req.json()

    // Validate request
    if (!body.admin_id || !body.check_in_method) {
      return new Response<AttendanceResponse>(
        { success: false, error: 'Missing required fields' } as AttendanceResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      )
    }

    let studentId: string

    // Find student by NFC card or student ID
    if (body.check_in_method === 'nfc' && body.nfc_uid) {
      const { data: nfcCard, error: nfcError } = await supabaseClient
        .from('nfc_cards')
        .select('user_id')
        .eq('uid', body.nfc_uid)
        .eq('is_active', true)
        .single()

      if (nfcError || !nfcCard) {
        return new Response<AttendanceResponse>(
          { success: false, error: 'NFC card not found or inactive' } as AttendanceResponse,
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 404,
          }
        )
      }

      studentId = nfcCard.user_id
    } else if (body.check_in_method === 'manual' && body.student_id) {
      studentId = body.student_id
    } else {
      return new Response<AttendanceResponse>(
        { success: false, error: 'Invalid request parameters' } as AttendanceResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      )
    }

    // Verify student exists and has student role
    const { data: student, error: studentError } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', studentId)
      .eq('role', 'student')
      .single()

    if (studentError || !student) {
      return new Response<AttendanceResponse>(
        { success: false, error: 'Student not found' } as AttendanceResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 404,
        }
      )
    }

    // Check if student already checked in today
    const today = new Date()
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate())
    const endOfDay = new Date(startOfDay.getTime() + 24 * 60 * 60 * 1000)

    const { data: existingAttendance, error: existingError } = await supabaseClient
      .from('attendance')
      .select('*')
      .eq('user_id', studentId)
      .gte('check_in_time', startOfDay.toISOString())
      .lt('check_in_time', endOfDay.toISOString())
      .maybeSingle()

    if (existingAttendance) {
      return new Response<AttendanceResponse>(
        { success: false, error: 'Student already checked in today' } as AttendanceResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 409,
        }
      )
    }

    // Get class information if class_id is provided
    let pointsEarned = 10 // Default points
    let className = 'General Check-in'

    if (body.class_id) {
      const { data: classData, error: classError } = await supabaseClient
        .from('classes')
        .select('course_name, points')
        .eq('id', body.class_id)
        .single()

      if (!classError && classData) {
        className = classData.course_name
        pointsEarned = classData.points || 10
      }
    }

    // Calculate streak
    const newStreak = await calculateAttendanceStreak(supabaseClient, studentId)

    // Check for streak bonus
    if (newStreak > 0 && newStreak % 7 === 0) {
      pointsEarned += 5 // Weekly streak bonus
    }

    // Create attendance record
    const { data: attendance, error: attendanceError } = await supabaseClient
      .from('attendance')
      .insert({
        user_id: studentId,
        class_id: body.class_id,
        admin_id: body.admin_id,
        check_in_time: new Date().toISOString(),
        points_earned: pointsEarned,
        check_in_method: body.check_in_method,
        nfc_card_id: body.nfc_uid,
        notes: body.notes,
        was_late: false, // TODO: Implement late detection logic
      })
      .select()
      .single()

    if (attendanceError || !attendance) {
      return new Response<AttendanceResponse>(
        { success: false, error: 'Failed to record attendance' } as AttendanceResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 500,
        }
      )
    }

    // Update student's total points and streak
    const { error: updateError } = await supabaseClient
      .from('profiles')
      .update({
        total_points: student.total_points + pointsEarned,
        attendance_streak: newStreak,
        updated_at: new Date().toISOString(),
      })
      .eq('id', studentId)

    if (updateError) {
      console.error('Failed to update student points:', updateError)
    }

    // Create points transaction record
    const { error: transactionError } = await supabaseClient
      .from('points_transactions')
      .insert({
        user_id: studentId,
        transaction_type: 'attendance',
        points: pointsEarned,
        reference_id: attendance.id,
        description: `Attendance for ${className}`,
        created_at: new Date().toISOString(),
      })

    if (transactionError) {
      console.error('Failed to create points transaction:', transactionError)
    }

    // Check for achievements
    await checkAchievements(supabaseClient, studentId, student.total_points + pointsEarned, newStreak)

    // Update NFC card usage if NFC check-in
    if (body.check_in_method === 'nfc' && body.nfc_uid) {
      await supabaseClient
        .from('nfc_cards')
        .update({
          usage_count: await supabaseClient.rpc('increment', { x: 1 }),
          last_used: new Date().toISOString(),
        })
        .eq('uid', body.nfc_uid)
    }

    const response: AttendanceResponse = {
      success: true,
      attendance_id: attendance.id,
      points_earned: pointsEarned,
      new_streak: newStreak,
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('Error in record-attendance function:', error)
    return new Response<AttendanceResponse>(
      { success: false, error: 'Internal server error' } as AttendanceResponse,
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})

async function calculateAttendanceStreak(
  supabaseClient: any,
  studentId: string
): Promise<number> {
  try {
    const { data: attendanceHistory } = await supabaseClient
      .from('attendance')
      .select('check_in_time')
      .eq('user_id', studentId)
      .order('check_in_time', ascending: false)
      .limit(30) // Check last 30 days

    if (!attendanceHistory || attendanceHistory.length === 0) {
      return 0
    }

    let streak = 1 // Count today
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    for (let i = 1; i < attendanceHistory.length; i++) {
      const checkInDate = new Date(attendanceHistory[i].check_in_time)
      checkInDate.setHours(0, 0, 0, 0)

      const expectedDate = new Date(today)
      expectedDate.setDate(today.getDate() - i)
      expectedDate.setHours(0, 0, 0, 0)

      if (checkInDate.getTime() === expectedDate.getTime()) {
        streak++
      } else {
        break // Streak broken
      }
    }

    return streak
  } catch (error) {
    console.error('Error calculating streak:', error)
    return 0
  }
}

async function checkAchievements(
  supabaseClient: any,
  studentId: string,
  totalPoints: number,
  streak: number
): Promise<void> {
  try {
    const achievements: Array<{ type: string; threshold: number; name: string; description: string }> = [
      { type: 'points', threshold: 100, name: 'Century Club', description: 'Earned 100 total points' },
      { type: 'points', threshold: 500, name: 'Point Master', description: 'Earned 500 total points' },
      { type: 'points', threshold: 1000, name: 'Point Legend', description: 'Earned 1000 total points' },
      { type: 'streak', threshold: 7, name: 'Week Warrior', description: '7-day attendance streak' },
      { type: 'streak', threshold: 30, name: 'Monthly Champion', description: '30-day attendance streak' },
      { type: 'streak', threshold: 100, name: 'Century Streak', description: '100-day attendance streak' },
    ]

    for (const achievement of achievements) {
      const threshold = achievement.type === 'points' ? totalPoints : streak

      if (threshold >= achievement.threshold) {
        // Check if student already has this achievement
        const { data: existingAchievement } = await supabaseClient
          .from('user_achievements')
          .select('*')
          .eq('user_id', studentId)
          .eq('achievement_id', `${achievement.type}_${achievement.threshold}`)
          .maybeSingle()

        if (!existingAchievement) {
          // Award new achievement
          await supabaseClient
            .from('user_achievements')
            .insert({
              user_id: studentId,
              achievement_id: `${achievement.type}_${achievement.threshold}`,
              name: achievement.name,
              description: achievement.description,
              earned_at: new Date().toISOString(),
            })

          // Create notification
          await supabaseClient
            .from('notifications')
            .insert({
              user_id: studentId,
              title: 'Achievement Unlocked!',
              message: `You've earned the "${achievement.name}" achievement!`,
              type: 'achievement',
              created_at: new Date().toISOString(),
            })
        }
      }
    }
  } catch (error) {
    console.error('Error checking achievements:', error)
  }
}