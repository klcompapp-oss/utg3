-- Roblox webhook test script
-- Paste into an executor or run in a script (Studio needs HTTP enabled)

local HttpService = game:GetService('HttpService')

-- Replace with your ngrok or public webhook catcher URL (include path)
local url = "https://your-ngrok-id.ngrok.io/test"

local payload = {
    time = os.time(),
    source = "roblox-test",
    note = "testing multiple request patterns"
}
local body = HttpService:JSONEncode(payload)
local headers = {
    ["Content-Type"] = "application/json",
    ["x-webhook-token"] = "locakwebxenoawp" -- optional test token
}

local function try_syn_request()
    if type(syn) == "table" and type(syn.request) == "function" then
        local ok, resp = pcall(function()
            return syn.request({
                Url = url,
                Method = "POST",
                Headers = headers,
                Body = body,
            })
        end)
        return ok, resp
    end
    return false, "syn.request not available"
end

local function try_http_request_var()
    -- some environments expose `request` or `http_request`
    local req = request or http_request
    if type(req) == "function" then
        local ok, resp = pcall(function()
            -- many executors accept a table similar to syn.request
            return req({
                Url = url,
                Method = "POST",
                Headers = headers,
                Body = body,
            })
        end)
        return ok, resp
    end
    return false, "request/http_request not available"
end

local function try_HttpService_RequestAsync()
    if type(HttpService.RequestAsync) == "function" then
        local ok, resp = pcall(function()
            return HttpService:RequestAsync({
                Url = url,
                Method = "POST",
                Headers = headers,
                Body = body,
            })
        end)
        return ok, resp
    end
    return false, "HttpService:RequestAsync not available"
end

local attempts = {
    { name = "syn.request", fn = try_syn_request },
    { name = "request/http_request", fn = try_http_request_var },
    { name = "HttpService:RequestAsync", fn = try_HttpService_RequestAsync },
}

for _, attempt in ipairs(attempts) do
    local ok, resp = attempt.fn()
    print("--- Attempt:", attempt.name)
    if ok then
        -- resp may be a table or string depending on executor
        if type(resp) == "table" then
            print("Status:", resp.StatusCode or resp.status or "(no status)")
            print("Body:", resp.Body or resp.body or "(no body)")
        else
            print("Response:", resp)
        end
    else
        print("Failed:", resp)
    end
end

print("Done testing webhook request patterns")
