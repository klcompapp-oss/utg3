local ReplicatedStorage = game:GetService("ReplicatedStorage")
if ReplicatedStorage:FindFirstChild("shared") then
    local shared = ReplicatedStorage.shared
    if shared:FindFirstChild("cooldowns") then
        shared.cooldowns:Destroy()
        
    end
end
local success, err = pcall(function()
    local Utils = require(game.ReplicatedFirst:FindFirstChild("Utils"))
    if Utils and typeof(Utils.InCooldown) == "function" then
        hookfunction(Utils.InCooldown, function(action)
            return false
        end)
        
    end
end)
if not success then
    
    return
end
