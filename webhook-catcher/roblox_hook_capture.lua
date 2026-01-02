-- roblox_hook_capture.lua
-- Paste this into your executor (or run in Studio if allowed) to capture outgoing webhook requests
-- Set `CATCHER_URL` to your local catcher (ngrok) URL, e.g. https://abc123.ngrok.io/capture

local HttpService = game:GetService("HttpService")
local CATCHER_URL = "https://your-ngrok-id.ngrok.io/capture" -- <- set this
local SELF_TAG = "roblox-hook-capture" -- used to avoid forwarding loops

local function normalizeRequest(req)
    if type(req) == "string" then
        return { Url = req }
    elseif type(req) == "table" then
        -- accept Url or url, Method/Method lowercase, Headers or headers, Body or body
        local url = req.Url or req.url
        local method = req.Method or req.method or req.Method or "GET"
        local headers = req.Headers or req.headers or {}
        local body = req.Body or req.body
        return { Url = url, Method = method, Headers = headers, Body = body }
    else
        return { Url = tostring(req) }
    end
end

local function buildCapturePayload(sourceName, reqTable)
    return {
        timestamp = os.time(),
        source = sourceName,
        url = reqTable.Url,
        method = reqTable.Method,
        headers = reqTable.Headers,
        body = reqTable.Body,
    }
end

local function safe_pcall(fn, ...)
    local ok, res = pcall(fn, ...)
    return ok, res
end

local function forwardToCatcher(orig_fn, sourceName, reqTable)
    -- avoid forwarding if request targets the catcher itself
    if not reqTable or not reqTable.Url then return end
    if string.find(reqTable.Url, CATCHER_URL, 1, true) then return end

    local payload = buildCapturePayload(sourceName, reqTable)
    local ok, _ = pcall(function()
        -- use the original function to forward so we don't depend on overridden HttpService
        orig_fn({
            Url = CATCHER_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", ["X-Forwarded-By"] = SELF_TAG },
            Body = HttpService:JSONEncode(payload),
        })
    end)
    if not ok then
        -- best-effort: try HttpService directly if available (and not overridden)
        pcall(function()
            HttpService:RequestAsync({
                Url = CATCHER_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json", ["X-Forwarded-By"] = SELF_TAG },
                Body = HttpService:JSONEncode(payload),
            })
        end)
    end
end

local function wrapFunction(container, fnName, isMethod)
    local ok, orig = pcall(function()
        if isMethod then
            return container[fnName]
        else
            return container[fnName]
        end
    end)
    if not ok or type(orig) ~= "function" then
        return false, nil
    end

    local function wrapper(...)
        local args = {...}
        local reqArg = args[1]
        local norm = normalizeRequest(reqArg)
        print("[hook] Intercepted", fnName, norm.Url or "(no-url)")

        -- forward a copy asynchronously using the original function saved as `orig`
        spawn(function()
            pcall(function() forwardToCatcher(orig, fnName, norm) end)
        end)

        -- call original and return its results
        return orig(...)
    end

    -- attempt to set wrapper in place
    local success, err = pcall(function() container[fnName] = wrapper end)
    if not success then
        -- some environments prevent direct assignment; try debug.setreadonly trick if available
        if type(debug) == "table" and type(debug.setmetatable) == "function" then
            -- fall back only to inform user
            return false, "readonly"
        end
        return false, err
    end

    return true, orig
end

local installed = {}

-- Save originals where found so forwarding uses them (to avoid recursion)
local originals = {}

-- Try syn.request
if type(syn) == "table" and type(syn.request) == "function" then
    originals.syn_request = syn.request
    syn.request = function(req)
        local norm = normalizeRequest(req)
        print("[hook] syn.request ->", norm.Url or "(no-url)")
        spawn(function() pcall(function() forwardToCatcher(originals.syn_request, "syn.request", norm) end) end)
        return originals.syn_request(req)
    end
    installed[#installed+1] = "syn.request"
end

-- Try global request / http_request
if type(request) == "function" then
    originals.request = request
    request = function(req)
        local norm = normalizeRequest(req)
        print("[hook] request ->", norm.Url or "(no-url)")
        spawn(function() pcall(function() forwardToCatcher(originals.request, "request", norm) end) end)
        return originals.request(req)
    end
    installed[#installed+1] = "request"
end

if type(http_request) == "function" then
    originals.http_request = http_request
    http_request = function(req)
        local norm = normalizeRequest(req)
        print("[hook] http_request ->", norm.Url or "(no-url)")
        spawn(function() pcall(function() forwardToCatcher(originals.http_request, "http_request", norm) end) end)
        return originals.http_request(req)
    end
    installed[#installed+1] = "http_request"
end

-- Try http.request table
if type(http) == "table" and type(http.request) == "function" then
    originals.http_request_table = http.request
    http.request = function(req)
        local norm = normalizeRequest(req)
        print("[hook] http.request ->", norm.Url or "(no-url)")
        spawn(function() pcall(function() forwardToCatcher(originals.http_request_table, "http.request", norm) end) end)
        return originals.http_request_table(req)
    end
    installed[#installed+1] = "http.request"
end

-- Try HttpService:RequestAsync (method)
if type(HttpService.RequestAsync) == "function" then
    originals.HttpService_RequestAsync = HttpService.RequestAsync
    local orig = originals.HttpService_RequestAsync
    HttpService.RequestAsync = function(self, opts)
        local norm = normalizeRequest(opts)
        print("[hook] HttpService:RequestAsync ->", norm.Url or "(no-url)")
        spawn(function() pcall(function() forwardToCatcher(orig, "HttpService.RequestAsync", norm) end) end)
        return orig(self, opts)
    end
    installed[#installed+1] = "HttpService.RequestAsync"
end

print("[hook] Installed hooks:")
for _, name in ipairs(installed) do
    print(" - ", name)
end
if #installed == 0 then
    print("[hook] No known request functions were found to hook. Some executors restrict overrides.")
end

-- End of script
