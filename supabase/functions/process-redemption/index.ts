import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

interface RedemptionRequest {
  user_id: string
  merchandise_id: string
}

interface RedemptionResponse {
  success: boolean
  order_id?: string
  new_balance?: number
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
      return new Response<RedemptionResponse>(
        { success: false, error: 'Unauthorized' } as RedemptionResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      )
    }

    const body: RedemptionRequest = await req.json()

    if (!body.user_id || !body.merchandise_id) {
      return new Response<RedemptionResponse>(
        { success: false, error: 'Missing required fields' } as RedemptionResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      )
    }

    // Verify user can only redeem for themselves
    if (user.id !== body.user_id) {
      return new Response<RedemptionResponse>(
        { success: false, error: 'Forbidden: Can only redeem for your own account' } as RedemptionResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 403,
        }
      )
    }

    // Get user profile
    const { data: userProfile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('total_points, full_name')
      .eq('id', body.user_id)
      .single()

    if (profileError || !userProfile) {
      return new Response<RedemptionResponse>(
        { success: false, error: 'User not found' } as RedemptionResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 404,
        }
      )
    }

    // Get merchandise details
    const { data: merchandise, error: merchandiseError } = await supabaseClient
      .from('merchandise')
      .select('name, points_cost, category, stock_quantity')
      .eq('id', body.merchandise_id)
      .eq('is_active', true)
      .single()

    if (merchandiseError || !merchandise) {
      return new Response<RedemptionResponse>(
        { success: false, error: 'Merchandise not found or inactive' } as RedemptionResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 404,
        }
      )
    }

    // Check if user has enough points
    if (userProfile.total_points < merchandise.points_cost) {
      return new Response<RedemptionResponse>(
        { success: false, error: 'Insufficient points' } as RedemptionResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      )
    }

    // Check stock availability for physical items
    if (merchandise.category === 'physical' && merchandise.stock_quantity !== null) {
      if (merchandise.stock_quantity <= 0) {
        return new Response<RedemptionResponse>(
          { success: false, error: 'Item out of stock' } as RedemptionResponse,
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
          }
        )
      }
    }

    // Check monthly redemption limit
    const now = new Date()
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1)
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1)

    const { data: monthlyOrders, error: ordersError } = await supabaseClient
      .from('merchandise_orders')
      .select('id')
      .eq('user_id', body.user_id)
      .gte('ordered_at', startOfMonth.toISOString())
      .lt('ordered_at', endOfMonth.toISOString())
      .neq('status', 'cancelled')

    if (!ordersError && monthlyOrders && monthlyOrders.length >= 10) {
      return new Response<RedemptionResponse>(
        { success: false, error: 'Monthly redemption limit reached (10 items per month)' } as RedemptionResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      )
    }

    // Begin transaction
    try {
      // Create merchandise order
      const { data: order, error: orderError } = await supabaseClient
        .from('merchandise_orders')
        .insert({
          user_id: body.user_id,
          merchandise_id: body.merchandise_id,
          points_cost: merchandise.points_cost,
          status: 'pending',
          ordered_at: new Date().toISOString(),
        })
        .select()
        .single()

      if (orderError || !order) {
        throw new Error('Failed to create order')
      }

      // Deduct points from user
      const { error: updateError } = await supabaseClient
        .from('profiles')
        .update({
          total_points: userProfile.total_points - merchandise.points_cost,
          updated_at: new Date().toISOString(),
        })
        .eq('id', body.user_id)

      if (updateError) {
        throw new Error('Failed to update user points')
      }

      // Create points transaction record
      const { error: transactionError } = await supabaseClient
        .from('points_transactions')
        .insert({
          user_id: body.user_id,
          transaction_type: 'redemption',
          points: -merchandise.points_cost,
          description: `Redeemed: ${merchandise.name}`,
          reference_id: order.id,
          created_at: new Date().toISOString(),
        })

      if (transactionError) {
        console.error('Failed to create points transaction:', transactionError)
      }

      // Update stock if physical item
      if (merchandise.category === 'physical' && merchandise.stock_quantity !== null) {
        await supabaseClient
          .from('merchandise')
          .update({
            stock_quantity: merchandise.stock_quantity - 1,
            updated_at: new Date().toISOString(),
          })
          .eq('id', body.merchandise_id)
      }

      // Create notification
      await supabaseClient
        .from('notifications')
        .insert({
          user_id: body.user_id,
          title: 'Order Placed!',
          message: `Your order for "${merchandise.name}" has been placed and is pending approval.`,
          type: 'order',
          created_at: new Date().toISOString(),
        })

      const response: RedemptionResponse = {
        success: true,
        order_id: order.id,
        new_balance: userProfile.total_points - merchandise.points_cost,
      }

      return new Response(JSON.stringify(response), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })

    } catch (error) {
      console.error('Transaction failed:', error)
      return new Response<RedemptionResponse>(
        { success: false, error: 'Transaction failed. Please try again.' } as RedemptionResponse,
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 500,
        }
      )
    }

  } catch (error) {
    console.error('Error in process-redemption function:', error)
    return new Response<RedemptionResponse>(
      { success: false, error: 'Internal server error' } as RedemptionResponse,
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})