import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { initializeApp, cert } from 'https://esm.sh/firebase-admin@12.0.0/app'
import { getMessaging } from 'https://esm.sh/firebase-admin@12.0.0/messaging'

// ——— Firebase Admin Init ———
// Set these via: supabase secrets set FIREBASE_SERVICE_ACCOUNT_ACCOUNT="..."
const serviceAccount = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')

if (serviceAccount) {
  initializeApp({
    credential: cert(JSON.parse(serviceAccount)),
  })
}

// ——— Supabase Client ———
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

serve(async (req) => {
  try {
    const now = new Date()
    const in1day = new Date(now.getTime() + 24 * 60 * 60 * 1000)
    const in3days = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000)

    // ── 1. 查找 3 天後到期的項目 ──
    const { data: items3day } = await supabase
      .from('items')
      .select('id, title, deadline, user_id, current_units, total_units')
      .eq('status', 'in_progress')
      .lte('deadline', in3days.toISOString())
      .gte('deadline', now.toISOString())

    // ── 2. 查找 1 天後到期的項目 ──
    const { data: items1day } = await supabase
      .from('items')
      .select('id, title, deadline, user_id, current_units, total_units')
      .eq('status', 'in_progress')
      .lte('deadline', in1day.toISOString())
      .gte('deadline', now.toISOString())

    // ── 3. 取得所有 user 的 FCM token ──
    const { data: users } = await supabase
      .from('users')
      .select('id, fcm_token')
      .not('fcm_token', 'is', null)

    if (!users || users.length === 0) {
      return new Response(JSON.stringify({ message: 'No users with FCM token' }),
        { headers: { 'Content-Type': 'application/json' } })
    }

    const userTokenMap = new Map(users.map((u: any) => [u.id, u.fcm_token]))

    // ── 4. Send notifications ──
    const messages: any[] = []

    for (const item of items3day || []) {
      const token = userTokenMap.get(item.user_id)
      if (token) {
        messages.push({
          token,
          notification: {
            title: `${item.title} — 3 天後到期`,
            body: '還有 3 天，加緊腳步！',
          },
          data: { itemId: item.id, type: 'deadline_3day' },
        })
      }
    }

    for (const item of items1day || []) {
      const token = userTokenMap.get(item.user_id)
      if (token) {
        messages.push({
          token,
          notification: {
            title: `${item.title} — 明天到期`,
            body: '明天就是期限了！',
          },
          data: { itemId: item.id, type: 'deadline_1day' },
        })
      }
    }

    // ── 5. Send via FCM ──
    if (serviceAccount && messages.length > 0) {
      const messaging = getMessaging()
      const results = await messaging.sendEach(messages)

      // ── 6. Record sent notifications ──
      const notifications = messages
        .filter((_, i) => results.responses[i].success)
        .map((m: any) => ({
          item_id: m.data.itemId,
          type: m.data.type,
          scheduled_at: now.toISOString(),
          sent_at: now.toISOString(),
        }))

      if (notifications.length > 0) {
        await supabase.from('notifications').insert(notifications)
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        sent: messages.length,
        deadline_3day_count: items3day?.length ?? 0,
        deadline_1day_count: items1day?.length ?? 0,
      }),
      { headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    console.error('notify-deadline error:', error)
    return new Response(JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } })
  }
})
