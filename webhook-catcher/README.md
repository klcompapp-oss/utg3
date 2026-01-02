Webhook Catcher
================

Simple Express server to capture and log incoming webhook requests for testing.

Files
- server.js — Express server that logs method, full URL, headers, query, and body to console and `requests.log`.

Setup & Run
1. Install Node.js (>=16).
2. From this folder:

```bash
npm init -y
npm install express
node server.js
```

3. Server listens on port 8080 by default. Change port with `PORT` env var.

Expose to the internet (optional)
- Use ngrok to expose the local port so external services can reach your machine:

```bash
ngrok http 8080
```

- Copy the public HTTPS URL shown by ngrok and use it as your webhook URL (e.g. `https://abc123.ngrok.io/webhook`).

Examples
- curl example:

```bash
curl -X POST https://<your-ngrok>.ngrok.io/test -H "Content-Type: application/json" -d '{"msg":"hello"}'
```

- Roblox (Luau) example using `HttpService:RequestAsync` (use in executor/Studio with HTTP enabled):

```lua
local HttpService = game:GetService('HttpService')

local url = 'https://<your-ngrok>.ngrok.io/test'
local body = HttpService:JSONEncode({ msg = 'from roblox' })
local ok, resp = pcall(function()
    return HttpService:RequestAsync({
        Url = url,
        Method = 'POST',
        Headers = { ['Content-Type'] = 'application/json' },
        Body = body,
    })
end)

print(ok, resp and resp.StatusCode, resp and resp.Body)
```

Notes
- All incoming requests are appended to `requests.log` for later inspection.
- The server returns a JSON response echoing what it received.
