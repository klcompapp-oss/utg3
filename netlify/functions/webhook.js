// Simple Netlify Function to forward requests to a Discord webhook.
// It expects an environment variable named `validingawpxeno` (or legacy
// `mahesaweda77`) containing the Discord webhook URL, and `WEBHOOK_TOKEN`
// containing the secret token.

exports.handler = async function (event, context) {
  const DISCORD_WEBHOOK = process.env.validingawpxeno || process.env.mahesaweda77
  const TOKEN = process.env.WEBHOOK_TOKEN

  const headerToken = (event.headers['x-webhook-token'] || event.headers['X-Webhook-Token'] || '').toString()
  if (!TOKEN || headerToken !== TOKEN) {
    return {
      statusCode: 401,
      body: 'Unauthorized: invalid token'
    }
  }

  if (!DISCORD_WEBHOOK) {
    return {
      statusCode: 500,
      body: 'Server misconfiguration: missing DISCORD_WEBHOOK env var'
    }
  }

  try {
    // Forward the body directly to Discord. We trust the client to send
    // a JSON payload formatted for Discord (content / embeds).
    const res = await fetch(DISCORD_WEBHOOK, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: event.body
    })

    const text = await res.text()
    return {
      statusCode: res.status,
      body: text
    }
  } catch (err) {
    return {
      statusCode: 502,
      body: 'Forwarding error: ' + String(err)
    }
  }
}
