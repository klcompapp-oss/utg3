-- fixed_block_hook.lua
-- Safe hook to intercept executor HTTP request functions and block Discord webhooks with content/embeds.
-- Usage: paste into executor (e.g., Synapse) or run in Studio (when allowed).
-- This script avoids common pitfalls: normalizes request signatures, protects original calls with pcall,
-- and returns a sensible mock response on failure to avoid crashing callers.

local HttpService = game:GetService("HttpService")
local QID = (type(getgenv) == 'function' and getgenv().HOOK_QID) or math.random(1, 1e9)
if type(getgenv) == 'function' then getgenv().HOOK_QID = QID end

local function normalizeRequestArg(req)
    if type(req) == 'string' then
        return { Url = req, Method = 'GET', Headers = {}, Body = nil }
    end
    if type(req) == 'table' then
        return {
            Url = req.Url or req.url,
            Method = req.Method or req.method or 'GET',
            Headers = req.Headers or req.headers or {},
            Body = req.Body or req.body,
        }
    end
    return { Url = tostring(req), Method = 'GET', Headers = {}, Body = nil }
end

local function tryDecodeJson(body)
    if not body then return false end
    local ok, res = pcall(function() return HttpService:JSONDecode(body) end)
    if ok then return res end
    return false
end

local function isDiscordUrl(url)
    if not url then return false end
    local low = string.lower(tostring(url))
    return string.find(low, 'discord.com/api/webhooks', 1, true) or string.find(low, 'discordapp.com/api/webhooks', 1, true)
end

local function mockBlockedResponse()
    -- different executors expect different shapes; provide a forgiving table plus common fields
    return {
        Success = false,
        StatusCode = 403,
        Body = 'Blocked by hook',
    }
end

local function safeInvoke(orig, ...)
    -- call original with pcall and return its values when possible
    local packed = table.pack(pcall(orig, ...))
    if packed[1] then
        -- pcall success: return all results except first
        return table.unpack(packed, 2, packed.n)
    end

    -- pcall failed: inspect error
    local err = packed[2]
    warn('[hook] original request errored:', err)
    if type(err) == 'string' and string.find(err, 'cannot resume dead coroutine', 1, true) then
        -- don't try to resume; return mock response to avoid propagating runtime crash
        return mockBlockedResponse()
    end

    -- fallback: return mock response
    return mockBlockedResponse()
end

-- find candidate request function (return table-with-container and key and function ref)
local function findRequestCandidate()
    -- syn.request
    if type(syn) == 'table' and type(syn.request) == 'function' then
        return syn, 'request', syn.request
    end
    -- global http_request
    if type(http_request) == 'function' then
        return _G, 'http_request', http_request
    end
    -- global request
    if type(request) == 'function' then
        return _G, 'request', request
    end
    -- http.request table
    if type(http) == 'table' and type(http.request) == 'function' then
        return http, 'request', http.request
    end
    -- try to check for http_request in rawget on _G
    if rawget(_G, 'HttpPost') and type(rawget(_G, 'HttpPost')) == 'function' then
        return _G, 'HttpPost', rawget(_G, 'HttpPost')
    end
    return nil
end

local candidate = findRequestCandidate()
if not candidate then
    warn('[hook] No known request function found to hook. The environment may block overrides.')
    return
end

local container, key, origFn = candidate[1], candidate[2], candidate[3]

-- Install hook safely using hookfunction if available
if type(hookfunction) ~= 'function' then
    warn('[hook] hookfunction not available in this environment. Cannot install safe hook.')
    return
end

local old = hookfunction(origFn, newcclosure(function(...)
    -- quick bypass when QID changed externally
    if type(getgenv) == 'function' and getgenv().HOOK_QID ~= QID then
        return safeInvoke(old, ...)
    end

    local args = table.pack(...)
    local first = args[1]
    local req = normalizeRequestArg(first)

    -- Only inspect Discord webhook URLs
    if isDiscordUrl(req.Url) then
        local json = tryDecodeJson(req.Body)
        if json and (json.content or json.embeds) then
            -- Block: Log warn and return mock blocked response
            warn('[hook] Blocked webhook request. URL:', req.Url)
            warn('[hook] Body snippet:', (type(req.Body) == 'string' and string.sub(req.Body, 1, 400)) or '(non-string)')
            return mockBlockedResponse()
        end
    end

    -- Otherwise, forward to original safely
    return safeInvoke(old, ...)
end))

print('[hook] Installed safe block hook on', key)

-- expose for debugging
if type(getgenv) == 'function' then
    getgenv().HOOK_OLD_REQUEST = old
end
