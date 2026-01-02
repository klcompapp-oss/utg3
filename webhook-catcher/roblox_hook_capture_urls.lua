-- roblox_hook_capture_urls.lua
-- Lightweight hook: detect and record outgoing webhook URLs only (no forwarding)
-- Usage: paste into an executor or run in Studio (if allowed). Captured entries are stored in
-- getgenv().CAPTURED_WEBHOOK_URLS (preferred) or _G.CAPTURED_WEBHOOK_URLS.

local HttpService = game:GetService('HttpService')

-- storage: prefer getgenv if available (executors), fallback to _G
local env = (type(getgenv) == 'function' and getgenv()) or _G
env.CAPTURED_WEBHOOK_URLS = env.CAPTURED_WEBHOOK_URLS or {}

local function isLikelyWebhook(url)
    if not url then return false end
    local l = string.lower(tostring(url))
    if string.find(l, 'discord.com/api/webhooks', 1, true) then return true end
    if string.find(l, 'discordapp.com/api/webhooks', 1, true) then return true end
    if string.find(l, 'hooks.slack.com', 1, true) then return true end
    if string.find(l, 'webhook.site', 1, true) then return true end
    if string.find(l, '/webhook', 1, true) then return true end
    if string.find(l, 'webhooks', 1, true) then return true end
    if string.find(l, 'webhook', 1, true) then return true end
    return false
end

local function normalizeRequest(req)
    if type(req) == 'string' then return { Url = req } end
    if type(req) == 'table' then
        return {
            Url = req.Url or req.url,
            Method = req.Method or req.method or 'GET',
            Headers = req.Headers or req.headers or {},
            Body = req.Body or req.body,
        }
    end
    return { Url = tostring(req) }
end

local function recordUrl(url, source)
    if not url then return end
    if not isLikelyWebhook(url) then return end
    -- avoid duplicates
    for _, v in ipairs(env.CAPTURED_WEBHOOK_URLS) do
        if v.url == url then return end
    end
    table.insert(env.CAPTURED_WEBHOOK_URLS, { url = url, source = source or 'unknown', ts = os.time() })
    print('[webhook-capture] Captured webhook URL:', url, 'source:', source or 'unknown')
end

-- Helper to wrap function fields safely
local function safeWrap(container, key, sourceName)
    if not container then return false end
    local ok, orig = pcall(function() return container[key] end)
    if not ok or type(orig) ~= 'function' then return false end
    container[key] = function(...)
        local args = {...}
        local norm = normalizeRequest(args[1])
        recordUrl(norm.Url, sourceName)
        return orig(...)
    end
    return true
end

local installed = {}

-- syn.request
if type(syn) == 'table' and type(syn.request) == 'function' then
    local orig = syn.request
    syn.request = function(req)
        local norm = normalizeRequest(req)
        recordUrl(norm.Url, 'syn.request')
        return orig(req)
    end
    table.insert(installed, 'syn.request')
end

-- global request / http_request
if type(request) == 'function' then
    local orig = request
    request = function(req)
        local norm = normalizeRequest(req)
        recordUrl(norm.Url, 'request')
        return orig(req)
    end
    table.insert(installed, 'request')
end

if type(http_request) == 'function' then
    local orig = http_request
    http_request = function(req)
        local norm = normalizeRequest(req)
        recordUrl(norm.Url, 'http_request')
        return orig(req)
    end
    table.insert(installed, 'http_request')
end

-- http.request table
if type(http) == 'table' and type(http.request) == 'function' then
    local orig = http.request
    http.request = function(req)
        local norm = normalizeRequest(req)
        recordUrl(norm.Url, 'http.request')
        return orig(req)
    end
    table.insert(installed, 'http.request')
end

-- HttpService:RequestAsync method
if type(HttpService.RequestAsync) == 'function' then
    local orig = HttpService.RequestAsync
    HttpService.RequestAsync = function(self, opts)
        local norm = normalizeRequest(opts)
        recordUrl(norm.Url, 'HttpService.RequestAsync')
        return orig(self, opts)
    end
    table.insert(installed, 'HttpService.RequestAsync')
end

print('[webhook-capture] URL-only hook installed. Captured list at getgenv().CAPTURED_WEBHOOK_URLS or _G.CAPTURED_WEBHOOK_URLS')
if #installed == 0 then
    print('[webhook-capture] Warning: no known request functions were hooked. Some environments block overrides.')
else
    print('[webhook-capture] Hooks installed:')
    for _, n in ipairs(installed) do print(' -', n) end
end

-- helper to print all captured urls conveniently
env.printCapturedWebhookUrls = function()
    for i, v in ipairs(env.CAPTURED_WEBHOOK_URLS) do
        print(i, v.ts, v.source, v.url)
    end
end

-- end of script
