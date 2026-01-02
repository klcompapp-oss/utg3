local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window =
    Rayfield:CreateWindow(
    {
        Name = "Keyless UTG",
        Icon = "circle-user-round",
        LoadingTitle = "Its Loading",
        LoadingSubtitle = "Please Wait",
        Theme = "Default",
        DisableRayfieldPrompts = true,
        DisableBuildWarnings = true,
        ConfigurationSaving = {
            Enabled = true,
            FolderName = Xcz,
            FileName = "Lolultra"
        },
        Discord = {
            Enabled = false,
            Invite = "-",
            RememberJoins = false
        },
        KeySystem = false,
        KeySettings = {
            Title = "Untitled",
            Subtitle = "Keey gg",
            Note = "Nnoo methd",
            FileName = "Thiskeey",
            SaveKey = false,
            GrabKeyFromSite = false,
            Key = {"dude hell nah"}
        }
    }
)

-------------------- taging --------------------
local Tab = Window:CreateTab("MAIN", 4483362458)
local Section = Tab:CreateSection("Taging")
------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer
local tagEventPath =
    ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("game") and
    ReplicatedStorage.Events.game:FindFirstChild("tags") and
    ReplicatedStorage.Events.game.tags:FindFirstChild("TagPlayer")

-- Helper to safely call RemoteFunction / RemoteEvent
local function safeRemoteCall(remoteObj, ...)
    local varargs = {...}
    if not remoteObj then
        return false, "remote-not-found"
    end
    -- prefer RemoteFunction (returns value)
    if remoteObj.IsA and remoteObj:IsA("RemoteFunction") then
        local ok, res = pcall(function() return remoteObj:InvokeServer(unpack(varargs)) end)
        return ok, res
    end
    -- fallback to RemoteEvent (fire-and-forget)
    if remoteObj.IsA and remoteObj:IsA("RemoteEvent") then
        local ok, res = pcall(function() remoteObj:FireServer(unpack(varargs)) end)
        return ok, res
    end
    -- Some environments expose functions directly
    if typeof(remoteObj) == "function" then
        local ok, res = pcall(function() return remoteObj(unpack(varargs)) end)
        return ok, res
    end
    return false, "unsupported-remote-type"
end
local lastTagTime = {}
local tagAuraRange = UserInputService.TouchEnabled and 7 or 8
local tagEnabled = false
local filterDead = false
local teamCheck = false
local legitTag = true
local roleFilterEnabled = false
local stopDuringVoting = false
local lastGlobalTagTime = 0
local uiClosed = false
local lastMoveTime = tick()
local movementThreshold = 40
local isGameFocused = true

local povCircleEnabled = false
local showPOVCircle = false
local povCircleRadius = 1
local povCircleThickness = 1.5
local povCircleColor = Color3.fromRGB(255, 50, 50)
local povCircleTransparency = 1
local rainbowColorEnabled = false
local rainbowColorSpeed = 0.7

local roleTagRules = {
    Crown = {"Neutral", "Frozen"},
    SoloCrown = {"Neutral", "Frozen"},
    Frozen = {"Freezer", "Chiller", "Infected", "Slasher", "Juggernaut", "Tagger"},
    RedFrozen = {"Freezer", "Chiller", "Infected", "Slasher", "Juggernaut", "Tagger"},
    BlueFrozen = {"Freezer", "Chiller", "Infected", "Slasher", "Juggernaut", "Tagger"},
    Runner = {"Crown", "SoloCrown", "Frozen", "Neutral", "OnFire", "King"},
    Tagger = {"Neutral", "Frozen", "Runner", "Neutral"},
    Dead = {"Crown", "SoloCrown", "Headless"},
    Infect = {"Runner", "Juggernauts", "Neutral"},
    Infected = {"Runner", "Juggernauts", "Frozen", "Neutral"},
    Freezer = {"Frozen", "Runner", "Neutral"},
    Hunter = {"Juggernaut", "Neutral", "Survivor"},
    PatientZero = {"Juggernaut", "Neutral", "Runner"},
    Chiller = {"Neutral", "Runner", "Runners", "runner", "Frozen"},
    Juggernaut = {"Runner", "Infected", "Neutral", "Frozen", "Hunter", "Survivor"},
    Slasher = {"Juggernauts", "Runner", "Neutral", "Frozen", "Survivor"},
    DisguisedTagger = {"Runner", "Neutral"},
    Knight = {"Runner", "Peasent", "Peasant"},
    Medic = {"Sick", "Peasent", "Infect", "Infected"},
    Headless = {"Neutral", "Witch"},
    Peasant = {"Knight", "Crown", "SoloCrown", "Headless", "Witches", "Witch", "Hallows2024_Witch"},
    Hallows2024_Witch = {"Peasent"},
    Alone = {"Alone", "Neutral", "Runner"},
    hallows2024_frozen = {"Survivor", "Captured"},
    hallows2024_saint = {"Survivor", "Captured"},
    BabyZombie = {"Runner"},
    BruteZombie = {"Runner"},
    Captured = {"hallows2024_saint", "Saint"},
    CloakedZombie = {"Runner"},
    HiddenSlasher = {"Survivor"},
    Witch = {"Peasant"},
    Survivor = {"Slasher", "Captured", "Witches", "Witch"},
    DiaguisedTagger = {"Runner"},
    DyingTagger = {"Runner"},
    Hotpotato = {"Runner"},
    Peasant = {"Crown", "SoloCrown"},
    Peasant = {"Crown", "SoloCrown"},
    Sick = {"Runner", "Medic"},
    SprinterZombie = {"Runner"},
    Toxic = {"Runner"},
    Arsonist = {"Runner", "OnFire", "Neutral"},
    BlueTeam = {"YellowTeam", "RedTeam", "OrangeTeam", "GreenTeam", "PurpleTeam", "Neutral"},
    YellowTeam = {"BlueTeam", "RedTeam", "PurpleTeam", "OrangeTeam", "GreenTeam", "Neutral"},
    RedTeam = {"BlueTeam", "YellowTeam", "PurpleTeam", "OrangeTeam", "GreenTeam", "Neutral"},
    OrangeTeam = {"BlueTeam", "YellowTeam", "PurpleTeam", "RedTeam", "GreenTeam", "Neutral"},
    GreenTeam = {"OrangeTeam", "RedTeam", "YellowTeam", "BlueTeam", "PurpleTeam", "Neutral"},
    BlueCaptain = {"RedCaptain", "OrangeCaptain", "GreenCaptain", "YellowCaptain", "Neutral"},
    RedCaptain = {"OrangeCaptain", "GreenCaptain", "YellowCaptain", "BlueCaptain", "Neutral"},
    OrangeCaptain = {"GreenCaptain", "YellowCaptain", "BlueCaptain", "RedCaptain", "Neutral"},
    YellowCaptain = {"BlueCaptain", "RedCaptain", "GreenCaptain", "OrangeCaptain", "Neutral"},
    Neutral = {"Runner"},
    Ashen = {"Runner"},
    AshyBomb = {"Runner"},
    Baron = {"Monarch"},
    Monarch = {"Baron"}
}
local Paragraph = Tab:CreateParagraph({Title = "warning", Content = "Please use it at your own discretion."})
local ToggleTag = Tab:CreateToggle({
    Name = "Silent Tag",
    CurrentValue = false,
    Flag = "AutoTag",
    Callback = function(Value)
        if uiClosed then
            return
        end
        tagEnabled = Value
    end
})

local KeybindToggleTag =
    Tab:CreateKeybind(
    {
        Name = "Manual Silent Tag (Key)",
        CurrentKeybind = "T",
        HoldToInteract = false,
        Flag = "KeybindToggleTag",
        Callback = function()
            if uiClosed then
                return
            end
            tagEnabled = not tagEnabled
            pcall(
                function()
                    ToggleTag:Set(tagEnabled)
                end
            )
        end
    }
)

local ToggleFilterDead =
    Tab:CreateToggle(
    {
        Name = "Ignore Dead",
        CurrentValue = false,
        Flag = "FilterDead",
        Callback = function(Value)
            filterDead = Value
        end
    }
)

local ToggleTeamCheck =
    Tab:CreateToggle(
    {
        Name = "Team Check",
        CurrentValue = false,
        Flag = "TeamCheck",
        Callback = function(Value)
            teamCheck = Value
        end
    }
)

local ToggleLegitTag =
    Tab:CreateToggle(
    {
        Name = "Legit Tag (lagging)",
        CurrentValue = false,
        Flag = "LegitTag",
        Callback = function(Value)
            legitTag = Value
        end
    }
)

local ToggleRoleFilter =
    Tab:CreateToggle(
    {
        Name = "Useless Role Filter",
        CurrentValue = false,
        Flag = "RoleFilter",
        Callback = function(Value)
            roleFilterEnabled = Value
        end
    }
)

local ToggleStopVoting =
    Tab:CreateToggle(
    {
        Name = "Stop During Voting",
        CurrentValue = false,
        Flag = "StopDuringVoting",
        Callback = function(Value)
            stopDuringVoting = Value
        end
    }
)
local SliderTagRange =
    Tab:CreateSlider(
    {
        Name = "Tag Distance",
        Range = {1, 20},
        Increment = 1,
        Suffix = " studs",
        CurrentValue = tagAuraRange,
        Flag = "TagRangeSlider",
        Callback = function(Value)
            tagAuraRange = Value
        end
    }
)
local unlimitedtag =
    Tab:CreateButton(
    {
        Name = "Unlimited tag (can't turn off)",
        Callback = function()
            local success, result =
                pcall(
                function()
                    return loadstring(
                        game:HttpGet("https://raw.githubusercontent.com/nAlwspa/Into/refs/heads/main/tager")
                    )()
                end
            )

            if not success then
                warn("[ERROR] Failed to load")
            end
        end
    }
)
local circleBorder, centerDot

local function createPOVCircle()
    if circleBorder then
        circleBorder:Remove()
    end
    if centerDot then
        centerDot:Remove()
    end

    if not (povCircleEnabled and showPOVCircle) then
        return
    end

    circleBorder = Drawing.new("Circle")
    circleBorder.Visible = true
    circleBorder.Thickness = povCircleThickness
    circleBorder.Color = povCircleColor
    circleBorder.Transparency = povCircleTransparency
    circleBorder.Filled = false
    circleBorder.NumSides = 64

    centerDot = Drawing.new("Circle")
    centerDot.Visible = true
    centerDot.Filled = true
    centerDot.Color = Color3.new(1, 1, 1)
    centerDot.Transparency = 0.5
    centerDot.Radius = 2
end

local function getCirclePosition()
    local camera = workspace.CurrentCamera
    if not camera then
        return nil
    end

    local viewportSize = camera.ViewportSize
    
    local UserInputService = game:GetService("UserInputService")
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    
    if isMobile then
        return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    else
        return UserInputService:GetMouseLocation()
    end
end

local function updatePOVCircle()
    if not (povCircleEnabled and showPOVCircle) then
        if circleBorder then
            circleBorder.Visible = false
        end
        if centerDot then
            centerDot.Visible = false
        end
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return
    end

    if not circleBorder or not centerDot then
        createPOVCircle()
    end

    if not circleBorder or not centerDot then
        return
    end

    local center = getCirclePosition()
    if not center then
        return
    end

    local viewportSize = camera.ViewportSize
    local radius = math.min(viewportSize.X, viewportSize.Y) / 2 * povCircleRadius

    if rainbowColorEnabled then
        local hue = (tick() * rainbowColorSpeed) % 1
        circleBorder.Color = Color3.fromHSV(hue, 1, 1)
    end

    circleBorder.Position = center
    circleBorder.Radius = radius
    circleBorder.Visible = true

    centerDot.Position = center
    centerDot.Visible = true
end

local function isPlayerInCenter(player)
    if not player or not player.Character then
        return false
    end

    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end

    local localChar = localPlayer.Character
    if not localChar then
        return false
    end

    local localHRP = localChar:FindFirstChild("HumanoidRootPart")
    if not localHRP then
        return false
    end

    local distance = (localHRP.Position - rootPart.Position).Magnitude
    if distance > tagAuraRange then
        return false
    end

    local camera = workspace.CurrentCamera
    local screenPoint, onScreen = camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen then
        return false
    end

    local center = getCirclePosition()
    if not center then
        return false
    end

    local playerPos = Vector2.new(screenPoint.X, screenPoint.Y)
    local distanceFromCenter = (playerPos - center).Magnitude

    local viewportSize = camera.ViewportSize
    local safeZoneRadius = math.min(viewportSize.X, viewportSize.Y) / 2 * povCircleRadius
    return distanceFromCenter <= safeZoneRadius
end

local function shouldStopTagging()
    if not stopDuringVoting then
        return false
    end

    local values = ReplicatedStorage:FindFirstChild("Values")
    if not values then
        return false
    end

    local gameModeValue = values:FindFirstChild("Gamemode")
    local timeValue = values:FindFirstChild("Time")

    if gameModeValue and (gameModeValue.Value == "Voting" or gameModeValue.Value == "Intermission") then
        return true
    end

    if timeValue and (timeValue.Value == 0 or timeValue.Value == 0.88) then
        return true
    end

    return false
end

local function canTag(player)
    local values = ReplicatedStorage:FindFirstChild("Values")
    local gameModeValue = values and values:FindFirstChild("Gamemode")

    if gameModeValue and gameModeValue.Value == "MutantInfected" then
        return true
    end

    if not roleFilterEnabled then
        return true
    end

    local localRole = localPlayer:FindFirstChild("PlayerRole")
    local targetRole = player:FindFirstChild("PlayerRole")

    if not localRole or not targetRole then
        return false
    end

    local allowedRoles = roleTagRules[localRole.Value]
    if not allowedRoles then
        return true
    end

    return table.find(allowedRoles, targetRole.Value) ~= nil
end

local function isValidTarget(player)
    if not player or player == localPlayer then
        return false
    end

    if player:GetAttribute("NoTagBack") then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChild("Humanoid")
    local targetHRP = character:FindFirstChild("HumanoidRootPart")
    local playerRole = player:FindFirstChild("PlayerRole")

    if filterDead and playerRole and playerRole:IsA("StringValue") and playerRole.Value == "Dead" then
        return false
    end

    if teamCheck then
        local localRole = localPlayer:FindFirstChild("PlayerRole")

        if localRole and localRole:IsA("StringValue") and (localRole.Value == "Alone" or localRole.Value == "FFATagger") then
        elseif localRole and playerRole and localRole.Value == playerRole.Value then
            return false
        end
    end

    return humanoid and humanoid.Health > 0 and targetHRP and canTag(player)
end
local function getLowestHealthTarget()
    local lowestHealth = math.huge
    local targetPlayer = nil

    for _, player in ipairs(game.Players:GetPlayers()) do
        if isValidTarget(player) then
            local character = player.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            local targetHRP = character and character:FindFirstChild("HumanoidRootPart")
            local localHRP = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")

            if humanoid and targetHRP and localHRP then
                local distance = (localHRP.Position - targetHRP.Position).Magnitude

                if distance <= tagAuraRange and humanoid.Health < lowestHealth then
                    lowestHealth = humanoid.Health
                    targetPlayer = player
                end
            end
        end
    end

    if targetPlayer then
    end

    return targetPlayer
end
local function checkMovement()
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if humanoid and humanoid.MoveDirection.Magnitude > 0.05 then
        lastMoveTime = tick()
    end
end

RunService.Heartbeat:Connect(checkMovement)

-- ==========================================================
-- ==========================================================
UserInputService.WindowFocused:Connect(function()
    isGameFocused = true
end)

UserInputService.WindowFocusReleased:Connect(function()
    isGameFocused = false
end)


-- ==========================================================
-- ==========================================================
local noCooldownEnabled = false

local ToggleNoCooldown = Tab:CreateToggle({
   Name = "No Cooldown Tag",
   CurrentValue = false,
   Flag = "NoCooldownTag",
   Callback = function(Value)
        noCooldownEnabled = Value
        
        if Value then
        else
        end
   end,
})

-- ========== SIMPLIFIED TAG FUNCTION ==========
local function tagPlayer(player)
    local currentTime = tick()

    if not isGameFocused then
        return
    end

    if currentTime - lastMoveTime > movementThreshold then
        return
    end
    
    if not tagEnabled or not isValidTarget(player) or shouldStopTagging() then
        return
    end

    if povCircleEnabled and not isPlayerInCenter(player) then
        return
    end

    if player:GetAttribute("NoTagBack") then
        return
    end

    -- ========== NO COOLDOWN SYSTEM ==========
    if not noCooldownEnabled then
        if lastTagTime[player] and currentTime - lastTagTime[player] < 1 then
            return
        end
        if lastGlobalTag and currentTime - lastGlobalTag < 0.3 then
            return
        end
    end
    -- Jika noCooldownEnabled = true, skip semua cooldown checks

    local localCharacter = localPlayer.Character
    local targetCharacter = player.Character
    if not localCharacter or not targetCharacter then
        return
    end

    local localHRP = localCharacter:FindFirstChild("HumanoidRootPart")
    local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
    if not localHRP or not targetHRP or not targetHumanoid then
        return
    end

    local distance = (localHRP.Position - targetHRP.Position).Magnitude
    if distance > tagAuraRange then
        return
    end

    -- Optimal offset (tanpa multi-ray check)
    local offset = Vector3.new(
        math.random(-5, 5) / 10,
        0,
        math.random(-5, 5) / 10 
    )

    local args = {
        [1] = targetHumanoid,
        [2] = targetHRP.Position + offset
    }

    local success, response = safeRemoteCall(tagEventPath, unpack(args))
    
    if success then
        -- ========== CONDITIONAL COOLDOWN UPDATE ==========
        if not noCooldownEnabled then
            lastTagTime[player] = currentTime
            lastGlobalTag = currentTime
        end
        -- Jika noCooldownEnabled = true, tidak update cooldown timers = NO COOLDOWN

        if legitTag then
            local humanoid = localCharacter:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local animator = humanoid:FindFirstChildOfClass("Animator")
                if not animator then
                    animator = Instance.new("Animator")
                    animator.Parent = humanoid
                end
                local animFolder = ReplicatedStorage:FindFirstChild("Animations") and ReplicatedStorage.Animations:FindFirstChild("Base")
                if animFolder then
                    local tagAnim = animFolder:FindFirstChild("Tag1") or animFolder:FindFirstChild("Tag2")
                    if tagAnim then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            if track.Animation == tagAnim then
                                track:Stop()
                            end
                        end

                        local animation = animator:LoadAnimation(tagAnim)
                        animation:Play()
                    end
                end
            end
        end
    end
end

-- ========== MODIFIED HEARTBEAT LOOP ==========
RunService.Heartbeat:Connect(
    function()
        local now = tick()
        
        -- ========== FASTER TAG INTERVAL WHEN NO COOLDOWN ==========
        local tagInterval = noCooldownEnabled and 0.05 or 0.5
        
        if tagEnabled and now - lastGlobalTagTime > tagInterval and not shouldStopTagging() then
            local target

            if roleFilterEnabled or filterDead or teamCheck then
                target = getLowestHealthTarget()
            else
                target = getNearestPlayer()
            end

            if target then
                tagPlayer(target)
                lastGlobalTagTime = now
            end
        end

        updatePOVCircle()
    end
)
local function getNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = math.huge

    local localCharacter = localPlayer.Character
    local localHRP = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not localHRP then
        return nil
    end

    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")

            if targetHRP and humanoid and humanoid.Health > 0 then
                local distance = (localHRP.Position - targetHRP.Position).Magnitude
                if distance < shortestDistance and distance <= tagAuraRange then
                    shortestDistance = distance
                    nearestPlayer = player
                end
            end
        end
    end

    return nearestPlayer
end

RunService.Heartbeat:Connect(
    function()
        local now = tick()
        if tagEnabled and now - lastGlobalTagTime > 0.5 and not shouldStopTagging() then
            local target

            if roleFilterEnabled or filterDead or teamCheck then
                target = getLowestHealthTarget()
            else
                target = getNearestPlayer()
            end

            if target then
                tagPlayer(target)
                lastGlobalTagTime = now
            end
        end

        updatePOVCircle()
    end
)
local Section = Tab:CreateSection("Pov")
local TogglePOVCircleEnabled =
    Tab:CreateToggle(
    {
        Name = "Enable POV Circle Tagging",
        CurrentValue = false,
        Flag = "POVCircleEnabled",
        Callback = function(Value)
            povCircleEnabled = Value
            updatePOVCircle()
        end
    }
)
local ToggleShowPOVCircle =
    Tab:CreateToggle(
    {
        Name = "Show POV Circle",
        CurrentValue = false,
        Flag = "ShowPOVCircle",
        Callback = function(Value)
            showPOVCircle = Value
            updatePOVCircle()
        end
    }
)
local SliderPOVCircleSize =
    Tab:CreateSlider(
    {
        Name = "Circle Size",
        Range = {0.2, 2},
        Increment = 0.05,
        Suffix = "",
        CurrentValue = povCircleRadius,
        Flag = "POVCircleSize",
        Callback = function(Value)
            povCircleRadius = Value
            updatePOVCircle()
        end
    }
)
local Section = Tab:CreateSection("Color pov")
local ToggleRainbowColor =
    Tab:CreateToggle(
    {
        Name = "Rainbow Color Effect",
        CurrentValue = false,
        Flag = "RainbowColor",
        Callback = function(Value)
            rainbowColorEnabled = Value
        end
    }
)
createPOVCircle()
RunService.Heartbeat:Connect(
    function()
        updatePOVCircle()

        if not tagEnabled or shouldStopTagging() then
            return
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                tagPlayer(player)
            end
        end
    end
)
game:GetService("Players").PlayerRemoving:Connect(
    function(player)
        if player == localPlayer then
            if circleBorder then
                circleBorder:Remove()
            end
            if centerDot then
                centerDot:Remove()
            end
        end
    end
)
-------------------- Hitbox --------------------
local Success, Players = pcall(function() return game:GetService("Players") end)
local Success2, RunService = pcall(function() return game:GetService("RunService") end)

if not Players or not RunService then
    warn("ERROR: Could not find Players or RunService service. Script terminated.")
    return
end

local localPlayer = Players.LocalPlayer

-- ==========================================================
-- ==========================================================
local hitboxEnabled = false
local hitboxSize = 4

-- ==========================================================
-- ==========================================================

local function getLocalPlayerRole()
    if not localPlayer then return nil end 
    local roleValue = localPlayer:FindFirstChild("PlayerRole")
    if roleValue and roleValue:IsA("StringValue") then
        return roleValue.Value
    end
    return nil
end

local function getPlayerRole(player)
    if not player then return nil end
    local roleValue = player:FindFirstChild("PlayerRole")
    if roleValue and roleValue:IsA("StringValue") then
        return roleValue.Value
    end
    return nil
end

local function isValidTarget(targetPlayer, localRole)
    if targetPlayer == localPlayer then return false end

    local targetRole = getPlayerRole(targetPlayer)
    if targetRole == "Dead" then return false end
    if localRole and targetRole and localRole == targetRole then return false end

    local targetCharacter = targetPlayer.Character
    if not targetCharacter then return false end

    local targetHRP = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return false end
    
    local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then return false end

    return true
end


-- ==========================================================
-- ==========================================================
local function updateHitboxes()
    if not hitboxEnabled then
        return
    end
    
    local localRole = getLocalPlayerRole()
    
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        
        local hrp = character and character:FindFirstChild("HumanoidRootPart")

        if player and player:IsA("Player") and hrp then
            
            local hitboxPart = hrp:FindFirstChild("HitboxExpanderPart")
            
            if isValidTarget(player, localRole) then
                
                if not hitboxPart then
                    hitboxPart = Instance.new("Part")
                    hitboxPart.Name = "HitboxExpanderPart"
                    
                    -- Atur properti agar tidak mengganggu gameplay atau deteksi anti-cheat
                    hitboxPart.Transparency = 1
                    hitboxPart.CanCollide = false
                    hitboxPart.Anchored = false
                    hitboxPart.Massless = true
                    
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = hrp
                    weld.Part1 = hitboxPart
                    weld.Parent = hitboxPart
                    
                    hitboxPart.Parent = character
                end
                
                hitboxPart.Size = Vector3.new(
                    hitboxSize,
                    hrp.Size.Y * 2.5,
                    hitboxSize
                )
                
                hrp:SetAttribute("ClientHitboxExpanded", true)
            else
                if hrp:GetAttribute("ClientHitboxExpanded") and hitboxPart then
                    hitboxPart:Destroy()
                    hrp:SetAttribute("ClientHitboxExpanded", nil) 
                end
            end
        end
    end
end

local function resetAllHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:GetAttribute("ClientHitboxExpanded") then
                local hitboxPart = hrp:FindFirstChild("HitboxExpanderPart")
                if hitboxPart then
                    hitboxPart:Destroy()
                end
                hrp:SetAttribute("ClientHitboxExpanded", nil)
            end
        end
    end
end

local heartbeatConnection = RunService.RenderStepped:Connect(updateHitboxes)
heartbeatConnection:Disconnect()

-- ==========================================================
-- ==========================================================
script.Destroying:Connect(function()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    resetAllHitboxes()
end)
------------------------------

-------------------- Esp --------------------
local Tab = Window:CreateTab("Esp", 4483362458)
local Section = Tab:CreateSection("Esp (Lag)")
------------------------------------------------------------
local CoreGui = game:GetService("CoreGui")

local espConfig = {
    enabled = false,
    showName = false,
    showRole = true,
    teamCheck = false,
    ignoreDead = false,
    size = 20,
    updateInterval = 0.05,
    showNeutralOnly = false,
    showCrownOnly = false,
    showRunnerOnly = false
}
local tracerConfig = {
    enabled = false,
    teamCheck = false,
    ignoreDead = false,
    thickness = 1,
    transparency = 0.7,
    showNeutralOnly = false,
    showCrownOnly = false,
    showRunnerOnly = false
}
local colorConfig = {
    useCustomColor = false,
    rainbowMode = false,
    rainbowSpeed = 1,
    customColors = {
        Default = Color3.fromRGB(255, 255, 255)
    }
}
local roleColors = {
    Runner = Color3.fromRGB(0, 0, 255),
    Crown = Color3.fromRGB(255, 215, 0),
    SoloCrown = Color3.fromRGB(255, 215, 0),
    Neutral = Color3.fromRGB(128, 128, 128),
    Chiller = Color3.fromRGB(0, 255, 255),
    Frozen = Color3.fromRGB(173, 216, 230),
    Freezer = Color3.fromRGB(0, 0, 0),
    Dead = Color3.fromRGB(255, 255, 255),
    Infected = Color3.fromRGB(0, 255, 0),
    infect = Color3.fromRGB(0, 255, 0),
    Infect = Color3.fromRGB(0, 255, 0),
    Sick = Color3.fromRGB(144, 238, 144),
    PatientZero = Color3.fromRGB(128, 0, 128),
    Medic = Color3.fromRGB(0, 100, 0),
    Bomb = Color3.fromRGB(255, 165, 0),
    HotBomb = Color3.fromRGB(255, 165, 0),
    bomb = Color3.fromRGB(255, 165, 0),
    Tagger = Color3.fromRGB(255, 0, 0),
    Slasher = Color3.fromRGB(139, 0, 0),
    Juggernaut = Color3.fromRGB(75, 0, 130),
    Hunter = Color3.fromRGB(0, 128, 0),
    Survivor = Color3.fromRGB(255, 255, 0),
    Alone = Color3.fromRGB(255, 0, 0),
    FFATagger = Color3.fromRGB(255, 0, 0),
    RunnerTagger = Color3.fromRGB(255, 0, 0),
    InfectedRunner = Color3.fromRGB(255, 0, 0)
}
local espFolder = Instance.new("Folder")
espFolder.Name = "ESPFolder_" .. math.random(10000, 99999)
espFolder.Parent = localPlayer:WaitForChild("PlayerGui")
local espObjects = {}
local tracerObjects = {}
local connections = {}
local updateQueue = {}
local updatePending = false
local lastUpdateTime = 0
local function getRainbowColor(hue)
    local r = math.sin(hue * math.pi * 2) * 0.5 + 0.5
    local g = math.sin((hue + 1 / 3) * math.pi * 2) * 0.5 + 0.5
    local b = math.sin((hue + 2 / 3) * math.pi * 2) * 0.5 + 0.5
    return Color3.new(r, g, b)
end
local function getRoleColor(roleValue)
    if colorConfig.rainbowMode then
        return getRainbowColor((tick() * colorConfig.rainbowSpeed) % 1)
    end
    if colorConfig.useCustomColor then
        return colorConfig.customColors[roleValue] or colorConfig.customColors["Default"]
    end
    return roleColors[roleValue] or Color3.fromRGB(255, 255, 255)
end
local function shouldShowESP(player)
    if player == localPlayer then
        return false
    end
    if not player.Character then
        return false
    end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end

    local roleValue = player:FindFirstChild("PlayerRole") and player.PlayerRole.Value
    local localRoleValue = localPlayer:FindFirstChild("PlayerRole") and localPlayer.PlayerRole.Value

    local isDead =
        humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead or
        roleValue == "Dead"

    if espConfig.ignoreDead and isDead then
        return false
    end

    if localRoleValue == "Crown" or localRoleValue == "SoloCrown" then
        if roleValue ~= "Neutral" then
            return false
        end
    end

    if espConfig.showNeutralOnly and roleValue ~= "Neutral" then
        return false
    end
    if espConfig.showCrownOnly and not (roleValue == "Crown" or roleValue == "SoloCrown") then
        return false
    end
    if espConfig.showRunnerOnly and roleValue ~= "Runner" then
        return false
    end

    if espConfig.teamCheck then
        if roleValue and localRoleValue and roleValue == localRoleValue then
            return false
        end
    end

    return true
end
local function cleanUpPlayerESP(player)
    if espObjects[player] then
        if espObjects[player].gui then
            espObjects[player].gui:Destroy()
        end
        espObjects[player] = nil
    end
end

local function cleanUpTracer(player)
    if tracerObjects[player] then
        for _, tracer in pairs(tracerObjects[player]) do
            if tracer then
                tracer:Remove()
            end
        end
        tracerObjects[player] = nil
    end
end
local function cleanupDeadPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local isDead = false
            if player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    isDead = humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead
                end
            end

            local playerRole = player:FindFirstChild("PlayerRole")
            if playerRole and playerRole.Value == "Dead" then
                isDead = true
            end

            if isDead then
                cleanUpPlayerESP(player)
                cleanUpTracer(player)
            end
        end
    end
end
local function shouldShowTracer(player)
    if player == localPlayer then
        return false
    end
    if not player.Character then
        return false
    end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end

    local roleValue = player:FindFirstChild("PlayerRole") and player.PlayerRole.Value
    local localRoleValue = localPlayer:FindFirstChild("PlayerRole") and localPlayer.PlayerRole.Value

    local isDead =
        humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead or
        roleValue == "Dead"

    if tracerConfig.ignoreDead and isDead then
        return false
    end

    if localRoleValue == "Crown" or localRoleValue == "SoloCrown" then
        if roleValue ~= "Neutral" then
            return false
        end
    end

    if tracerConfig.teamCheck then
        if roleValue and localRoleValue and roleValue == localRoleValue then
            return false
        end
    end

    return true
end
local function updateESPDisplay(player)
    if not espConfig.enabled or not espObjects[player] then
        return
    end

    local character = player.Character
    if not character then
        return
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    local playerRole = player:FindFirstChild("PlayerRole")
    local roleValue = playerRole and playerRole.Value or nil

    local displayText = ""
    if espConfig.showName then
        displayText = player.Name
    end
    if espConfig.showRole and roleValue then
        displayText = displayText ~= "" and (displayText .. "\n" .. roleValue) or roleValue
    end

    if espObjects[player] and espObjects[player].label then
        espObjects[player].label.Text = displayText
        espObjects[player].label.TextColor3 = getRoleColor(roleValue)
        espObjects[player].gui.Size = UDim2.new(espConfig.size, 0, espConfig.size / 4, 0)
        espObjects[player].gui.Adornee = hrp
    end
end
local function queueUpdate(player)
    updateQueue[player] = true

    if not updatePending then
        updatePending = true
        task.spawn(
            function()
                local timeToWait = lastUpdateTime + espConfig.updateInterval - tick()
                if timeToWait > 0 then
                    task.wait(timeToWait)
                end

                local playersToUpdate = {}
                for queuedPlayer in pairs(updateQueue) do
                    if queuedPlayer and queuedPlayer.Parent then
                        table.insert(playersToUpdate, queuedPlayer)
                    end
                    updateQueue[queuedPlayer] = nil
                end

                for _, playerToUpdate in ipairs(playersToUpdate) do
                    if espObjects[playerToUpdate] then
                        updateESPDisplay(playerToUpdate)
                    end
                end

                lastUpdateTime = tick()
                updatePending = false
            end
        )
    end
end

local function createESP(player)
    if not espConfig.enabled or player == localPlayer then
        return
    end
    cleanUpPlayerESP(player)
    local character = player.Character
    if not character then
        return
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(espConfig.size, 0, espConfig.size / 4, 0)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = hrp
    billboard.Parent = espFolder

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSans
    textLabel.Parent = billboard

    espObjects[player] = {
        gui = billboard,
        label = textLabel,
        connections = {}
    }

    local function onRoleChanged()
        queueUpdate(player)
    end

    local function onCharacterAdded(player, newCharacter)
        local humanoid = newCharacter:WaitForChild("Humanoid")
        local rootPart = newCharacter:WaitForChild("HumanoidRootPart")

        if not espObjects[player] then
            espObjects[player] = {connections = {}}
        end

        if espObjects[player].humanoidDiedConn then
            espObjects[player].humanoidDiedConn:Disconnect()
            espObjects[player].humanoidDiedConn = nil
        end

        if espConfig.ignoreDead or tracerConfig.ignoreDead then
            espObjects[player].humanoidDiedConn =
                humanoid.Died:Connect(
                function()
                    if espConfig.enabled then
                        updateESPDisplay(player)
                    end
                    if tracerConfig.enabled then
                        cleanUpTracer(player)
                    end
                end
            )
        end

        if espConfig.enabled then
            updateESPDisplay(player)
        end
        if tracerConfig.enabled then
            createTracer(player)
        end
    end
    local function setupPlayer(player)
        if not espObjects[player] then
            espObjects[player] = {connections = {}}
        end

        local role = player:FindFirstChild("PlayerRole")
        if role then
            local roleConn =
                role.Changed:Connect(
                function()
                    onRoleChanged(player)
                end
            )
            table.insert(espObjects[player].connections, roleConn)
        end

        local charConn =
            player.CharacterAdded:Connect(
            function(character)
                onCharacterAdded(player, character)
            end
        )
        table.insert(espObjects[player].connections, charConn)

        if player.Character then
            onCharacterAdded(player, player.Character)
        end

        updateESPDisplay(player)
    end
end
local function createTracer(player)
    if not tracerConfig.enabled or player == localPlayer then
        return
    end
    cleanUpTracer(player)
    local character = player.Character
    if not character then
        return
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Thickness = tracerConfig.thickness
    tracer.Transparency = tracerConfig.transparency

    if not tracerObjects[player] then
        tracerObjects[player] = {}
    end
    table.insert(tracerObjects[player], tracer)
end

local function updateTracers()
    if not tracerConfig.enabled then
        return
    end

    local localChar = localPlayer.Character
    if not localChar then
        return
    end

    local localHrp = localChar:FindFirstChild("HumanoidRootPart")
    if not localHrp then
        return
    end

    if tracerConfig.ignoreDead then
        for player, _ in pairs(tracerObjects) do
            if player and player.Parent then
                local remove = false
                local role = player:FindFirstChild("PlayerRole")
                if role and role.Value == "Dead" then
                    remove = true
                elseif player.Character then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and (humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead) then
                        remove = true
                    end
                end
                if remove then
                    cleanUpTracer(player)
                end
            else
                cleanUpTracer(player)
            end
        end
    end

    for player, tracers in pairs(tracerObjects) do
        if player and player.Parent and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local shouldShow = true

                if tracerConfig.ignoreDead then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health <= 0 then
                        shouldShow = false
                    end
                    local role = player:FindFirstChild("PlayerRole")
                    if role and role.Value == "Dead" then
                        shouldShow = false
                    end
                end

                if shouldShow and tracerConfig.teamCheck then
                    local role = player:FindFirstChild("PlayerRole")
                    local localRole = localPlayer:FindFirstChild("PlayerRole")
                    if role and localRole and role.Value == localRole.Value then
                        shouldShow = false
                    end
                end

                for _, tracer in ipairs(tracers) do
                    if tracer then
                        local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                        if onScreen and shouldShow then
                            local viewSize = workspace.CurrentCamera.ViewportSize
                            tracer.From = Vector2.new(viewSize.X / 2, viewSize.Y)
                            tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                            tracer.Color = getRoleColor(player:FindFirstChild("PlayerRole") and player.PlayerRole.Value)
                            tracer.Thickness = tracerConfig.thickness
                            tracer.Transparency = tracerConfig.transparency
                            tracer.Visible = true
                        else
                            tracer.Visible = false
                        end
                    end
                end
            end
        else
            cleanUpTracer(player)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and not tracerObjects[player] then
            if shouldShowTracer(player) then
                createTracer(player)
            end
        end
    end
end

local function startUpdateLoop()
    local heartbeatConnection
    local lastUpdate = 0

    local function updateAll()
        local now = tick()
        if now - lastUpdate < espConfig.updateInterval then
            return
        end
        lastUpdate = now

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                if espConfig.enabled and shouldShowESP(player) then
                    if not espObjects[player] then
                        createESP(player)
                    else
                        updateESPDisplay(player)
                    end
                else
                    cleanUpPlayerESP(player)
                end

                if tracerConfig.enabled and shouldShowTracer(player) then
                    if not tracerObjects[player] then
                        createTracer(player)
                    end
                else
                    cleanUpTracer(player)
                end
            end
        end

        updateTracers()
    end

    heartbeatConnection = RunService.Heartbeat:Connect(updateAll)

    return function()
        heartbeatConnection:Disconnect()
    end
end
local function updatePlayerESP(player)
    if espConfig.enabled then
        if shouldShowESP(player) then
            if not espObjects[player] then
                createESP(player)
            else
                updateESPDisplay(player)
            end
        else
            cleanUpPlayerESP(player)
        end
    else
        cleanUpPlayerESP(player)
    end

    if tracerConfig.enabled then
        if shouldShowTracer(player) then
            if not tracerObjects[player] then
                createTracer(player)
            end
        else
            cleanUpTracer(player)
        end
    else
        cleanUpTracer(player)
    end
end
local function onCharacterAdded(player, newCharacter)
    local humanoid = newCharacter:WaitForChild("Humanoid")
    local rootPart = newCharacter:WaitForChild("HumanoidRootPart")

    if not espObjects[player] then
        espObjects[player] = {}
    end

    if espObjects[player].humanoidDiedConn then
        espObjects[player].humanoidDiedConn:Disconnect()
        espObjects[player].humanoidDiedConn = nil
    end

    if espConfig.ignoreDead or tracerConfig.ignoreDead then
        espObjects[player].humanoidDiedConn =
            humanoid.Died:Connect(
            function()
                if espConfig.enabled then
                    updateESPDisplay(player)
                end
                if tracerConfig.enabled then
                    cleanUpTracer(player)
                end
            end
        )
    end

    if espConfig.enabled then
        updateESPDisplay(player, rootPart)
    end
    if tracerConfig.enabled then
        createTracer(player, rootPart)
    end
end
local function setupPlayerEvents()
    table.insert(
        connections,
        Players.PlayerAdded:Connect(
            function(player)
                local charConn
                charConn =
                    player.CharacterAdded:Connect(
                    function(character)
                        local humanoid = character:WaitForChild("Humanoid", 5)
                        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
                        if humanoid and rootPart then
                            onCharacterAdded(player, character)
                        end
                    end
                )
                table.insert(connections, charConn)

                local role = player:FindFirstChild("PlayerRole")
                if role then
                    local roleConn =
                        role.Changed:Connect(
                        function()
                            if espConfig.enabled or tracerConfig.enabled then
                                updatePlayerESP(player)
                            end
                        end
                    )
                    table.insert(connections, roleConn)
                end

                if player.Character then
                    onCharacterAdded(player, player.Character)
                end
            end
        )
    )

    table.insert(
        connections,
        Players.PlayerRemoving:Connect(
            function(player)
                cleanUpPlayerESP(player)
                cleanUpTracer(player)
            end
        )
    )
end

local function clearAllESP()
    for player in pairs(espObjects) do
        cleanUpPlayerESP(player)
    end
    for player in pairs(tracerObjects) do
        cleanUpTracer(player)
    end
    espObjects = {}
    tracerObjects = {}
end
local stopUpdateLoop
local function initializeESP()
    if stopUpdateLoop then
        stopUpdateLoop()
    end
    clearAllESP()

    setupPlayerEvents()

    if espConfig.enabled or tracerConfig.enabled then
        stopUpdateLoop = startUpdateLoop()
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            updatePlayerESP(player)
        end
    end
end
local function forceFullUpdate()
    for _, player in ipairs(Players:GetPlayers()) do
        updatePlayerESP(player)
    end
end
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        updatePlayerESP(player)
    end
end
table.insert(
    connections,
    Players.PlayerAdded:Connect(
        function(player)
            player.CharacterAdded:Connect(
                function()
                    updatePlayerESP(player)
                end
            )
            updatePlayerESP(player)
        end
    )
)
table.insert(
    connections,
    Players.PlayerRemoving:Connect(
        function(player)
            cleanUpPlayerESP(player)
            cleanUpTracer(player)
        end
    )
)

local localRole = localPlayer:FindFirstChild("PlayerRole")
if localRole then
    table.insert(
        connections,
        localRole.Changed:Connect(
            function()
                if espConfig.teamCheck or tracerConfig.teamCheck then
                    forceFullUpdate()
                end
            end
        )
    )
end
table.insert(
    connections,
    RunService.RenderStepped:Connect(
        function()
            updateTracers()
        end
    )
)

local function fullCleanup()
    if stopUpdateLoop then
        stopUpdateLoop()
        stopUpdateLoop = nil
    end
    for player, espData in pairs(espObjects) do
        if espData then
            if espData.gui then
                pcall(
                    function()
                        espData.gui:Destroy()
                    end
                )
            end
            if espData.connections then
                for _, conn in pairs(espData.connections) do
                    pcall(
                        function()
                            conn:Disconnect()
                        end
                    )
                end
            end
        end
    end
    espObjects = {}
    for player, tracers in pairs(tracerObjects) do
        if tracers then
            for _, tracer in ipairs(tracers) do
                pcall(
                    function()
                        if tracer then
                            tracer.Visible = false
                            tracer:Remove()
                        end
                    end
                )
            end
        end
    end
    tracerObjects = {}
    if espFolder then
        pcall(
            function()
                espFolder:Destroy()
            end
        )
    end
end

local teleportConnection
teleportConnection =
    localPlayer.OnTeleport:Connect(
    function(state)
        if state == Enum.TeleportState.Started then
            for _, conn in ipairs(connections) do
                pcall(
                    function()
                        conn:Disconnect()
                    end
                )
            end
            fullCleanup()
            teleportConnection:Disconnect()
        end
    end
)
table.insert(connections, teleportConnection)

local playerRemovingConnection
playerRemovingConnection =
    Players.PlayerRemoving:Connect(
    function(player)
        if player == localPlayer then
            fullCleanup()
            playerRemovingConnection:Disconnect()
        end
    end
)
table.insert(connections, playerRemovingConnection)
local ToggleEsp =
    Tab:CreateToggle(
    {
        Name = "ESP Toggle",
        CurrentValue = espConfig.enabled,
        Flag = "ToggleEsp",
        Callback = function(Value)
            espConfig.enabled = Value
            initializeESP()
        end
    }
)

local KeybindToggleEsp =
    Tab:CreateKeybind(
    {
        Name = "TOGGLE ESP (Key)",
        CurrentKeybind = "Y",
        HoldToInteract = false,
        Flag = "KeybindToggleEsp",
        Callback = function()
            if uiClosed then
                return
            end
            espConfig.enabled = not espConfig.enabled

            pcall(
                function()
                    ToggleEsp:Set(espConfig.enabled)
                end
            )

            initializeESP()
        end
    }
)
Tab:CreateToggle(
    {
        Name = "Show Role",
        CurrentValue = espConfig.showRole,
        Flag = "ESPRole",
        Callback = function(Value)
            espConfig.showRole = Value
            forceFullUpdate()
        end
    }
)

Tab:CreateToggle(
    {
        Name = "Show Name",
        CurrentValue = espConfig.showName,
        Flag = "ESPName",
        Callback = function(Value)
            espConfig.showName = Value
            forceFullUpdate()
        end
    }
)

Tab:CreateToggle(
    {
        Name = "Ignore Dead",
        CurrentValue = espConfig.ignoreDead,
        Flag = "IgnoreDead",
        Callback = function(Value)
            espConfig.ignoreDead = Value
            if Value then
                cleanupDeadPlayers()
            else
                forceFullUpdate()
            end
        end
    }
)

Tab:CreateToggle(
    {
        Name = "Team Check",
        CurrentValue = espConfig.teamCheck,
        Flag = "TeamCheck",
        Callback = function(Value)
            espConfig.teamCheck = Value
            forceFullUpdate()
        end
    }
)
local Section = Tab:CreateSection("Line esp(Lag)")
local ToggleLine =
    Tab:CreateToggle(
    {
        Name = "Line ESP",
        CurrentValue = tracerConfig.enabled,
        Flag = "ToggleLineESP",
        Callback = function(Value)
            tracerConfig.enabled = Value
            if Value then
                initializeESP() -- ⬅️ paksa re-inisialisasi biar tracer loop hidup
            else
                for player, tracers in pairs(tracerObjects) do
                    cleanUpTracer(player)
                end
            end
        end
    }
)

Tab:CreateToggle(
    {
        Name = "Line Team Check",
        CurrentValue = tracerConfig.teamCheck,
        Flag = "TracerTeamCheck",
        Callback = function(Value)
            tracerConfig.teamCheck = Value
            forceFullUpdate()
        end
    }
)

Tab:CreateToggle(
    {
        Name = "Line Ignore Dead",
        CurrentValue = tracerConfig.ignoreDead,
        Callback = function(Value)
            tracerConfig.ignoreDead = Value

            if Value then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= localPlayer then
                        local shouldClean = false

                        if player.Character then
                            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                            if humanoid then
                                shouldClean = humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead
                            end
                        end

                        local playerRole = player:FindFirstChild("PlayerRole")
                        if playerRole and playerRole.Value == "Dead" then
                            shouldClean = true
                        end

                        if shouldClean then
                            cleanUpTracer(player)
                        end
                    end
                end
            else
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= localPlayer and shouldShowTracer(player) then
                        createTracer(player)
                    end
                end
            end
        end
    }
)
Tab:CreateToggle(
    {
        Name = "Custom Colors",
        CurrentValue = colorConfig.useCustomColor,
        Flag = "UseCustomColors",
        Callback = function(Value)
            colorConfig.useCustomColor = Value
            forceFullUpdate()
        end
    }
)
Tab:CreateToggle(
    {
        Name = "raimbow Mode",
        CurrentValue = colorConfig.rainbowMode,
        Flag = "RainbowMode",
        Callback = function(Value)
            colorConfig.rainbowMode = Value
            forceFullUpdate()
        end
    }
)
Tab:CreateColorPicker(
    {
        Name = "costom Color set",
        Color = Color3.fromRGB(255, 255, 255),
        Flag = "DefaultTracerColor",
        Callback = function(Value)
            colorConfig.customColors["Default"] = Value
            if colorConfig.useCustomColor then
                forceFullUpdate()
            end
        end
    }
)
-------------------- player --------------------
local Tab = Window:CreateTab("localPlayer", 4483362458)
local Section = Tab:CreateSection("localPlayer")
------------------------------------------------------------
local Label =
    Tab:CreateLabel("--Infjump, noclip and speed boost risk LOL--", 4483362458, Color3.fromRGB(255, 255, 255), true)
local infJumpEnabled = false
local noclipEnabled = false
local infJump
local lastMovementTime = 0
local movementThreshold = 30
local movementCheck

local function onMovement()
    lastMovementTime = tick()
    
    if infJumpEnabled and not infJump then
        infJump =
            UserInputService.JumpRequest:Connect(
            function()
                if localPlayer.Character and localPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
                    localPlayer.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(
                        Enum.HumanoidStateType.Jumping
                    )
                end
            end
        )
    end
end

local function startMovementDetection()
    if movementCheck then
        movementCheck:Disconnect()
    end
    
    movementCheck = RunService.Heartbeat:Connect(function()
        local character = localPlayer.Character
        if character and character:FindFirstChildWhichIsA("Humanoid") then
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            local moveDirection = humanoid.MoveDirection
            
            if moveDirection.Magnitude > 0 then
                onMovement()
            else
                if infJumpEnabled and infJump and (tick() - lastMovementTime) > movementThreshold then
                    infJump:Disconnect()
                    infJump = nil
                end
            end
        end
    end)
end

local ToggleInfJump =
    Tab:CreateToggle(
    {
        Name = "Infinite Jump",
        CurrentValue = false,
        Flag = "InfJump",
        Callback = function(Value)
            infJumpEnabled = Value
            
            if Value then
                lastMovementTime = tick()
                startMovementDetection()
                
                -- Langsung aktifkan infJump saat pertama di-toggle
                if not infJump then
                    infJump =
                        UserInputService.JumpRequest:Connect(
                        function()
                            if localPlayer.Character and localPlayer.Character:FindFirstChildWhichIsA("Humanoid") then
                                localPlayer.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(
                                    Enum.HumanoidStateType.Jumping
                                )
                            end
                        end
                    )
                end
            else
                if infJump then
                    infJump:Disconnect()
                    infJump = nil
                end
                if movementCheck then
                    movementCheck:Disconnect()
                    movementCheck = nil
                end
            end
        end
    }
)

local function setNoclipState(state)
    noclipEnabled = state
    pcall(function()
        ToggleNoclip:Set(state)
    end)
end

local ToggleNoclip =
    Tab:CreateToggle(
    {
        Name = "Noclip",
        CurrentValue = false,
        Flag = "Noclip",
        Callback = function(Value)
            if uiClosed then
                return
            end
            noclipEnabled = Value
        end
    }
)

local KeybindToggleNoclip =
    Tab:CreateKeybind(
    {
        Name = "TOGGLE NOCLIP (Key)",
        CurrentKeybind = "N",
        HoldToInteract = false,
        Flag = "KeybindToggleNoclip",
        Callback = function()
            if uiClosed then
                return
            end
            noclipEnabled = not noclipEnabled
            pcall(function()
                ToggleNoclip:Set(noclipEnabled)
            end)
        end
    }
)

RunService.Stepped:Connect(
    function()
        local character = localPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if noclipEnabled then
                        part.CanCollide = false
                    else
                        if part.Name == "Torso" then
                            part.CanCollide = true
                        end
                    end
                end
            end
        end
    end
)

local player = Players.LocalPlayer
local disableContactDamage = false
local ToggleContactDamage =
    Tab:CreateToggle(
    {
        Name = "Disable lava damage",
        CurrentValue = false,
        Flag = "DisableContactDamage",
        Callback = function(Value)
            disableContactDamage = Value
        end
    }
)
player.CharacterAdded:Connect(
    function(char)
        local hrp = char:WaitForChild("HumanoidRootPart")

        hrp.Touched:Connect(
            function(part)
                if disableContactDamage and part:GetAttribute("ContactDamage") then
                    part:SetAttribute("ContactDamage", 0)
                end
            end
        )
    end
)
local Section = Tab:CreateSection("Speed")
local tpWalkEnabled = false
local walktpSpeed = 1

local function setTPWalkState(state)
    tpwalking = state

    pcall(function()
        TPWalkToggle:Set(state)
    end)

    if state then
        task.spawn(function()
            local chr = LocalPlayer.Character
            local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")

            while tpwalking and chr and hum and hum.Parent do
                local delta = RunService.Heartbeat:Wait()

                if hum.MoveDirection.Magnitude > 0 then
                    chr:TranslateBy(hum.MoveDirection * walktpSpeed * delta)
                end

                chr = LocalPlayer.Character
                hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
            end
        end)
    end
end

local TPWalkToggle = Tab:CreateToggle({
    Name = "Speed Boost",
    CurrentValue = false,
    Flag = "TPWalkToggle",
    Callback = function(Value)
        if uiClosed then return end

        tpWalkEnabled = Value

        if tpWalkEnabled and walktpSpeed > 32 then
            setTPWalkState(true)
        else
            setTPWalkState(false)
        end
    end
})

local KeybindTPWalk = Tab:CreateKeybind({
    Name = "TOGGLE SPEED BOOST (Key)",
    CurrentKeybind = "H",
    HoldToInteract = false,
    Flag = "KeybindTPWalk",
    Callback = function()
        if uiClosed then return end

        tpWalkEnabled = not tpWalkEnabled

        pcall(function()
            TPWalkToggle:Set(tpWalkEnabled)
        end)

        if tpWalkEnabled and walktpSpeed > 20 then
            setTPWalkState(true)
        else
            setTPWalkState(false)
        end
    end
})

local SpeedAmount = Tab:CreateSlider({
    Name = "Speed Boost amount",
    Range = {1, 40},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 1,
    Flag = "TPWalkSpeedSlider",
    Callback = function(Value)
        walktpSpeed = Value

        -- **Jika speed turun ke <= 20, maka otomatis matikan TPWalk**
        if walktpSpeed <= 20 and tpwalking then
            setTPWalkState(false)
        end

        if walktpSpeed > 20 and tpWalkEnabled then
            setTPWalkState(true)
        end
    end
})


local Section = Tab:CreateSection("Fling")



local walkflinging = false

local function getRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function startWalkFling()
    if walkflinging then
        return
    end
    walkflinging = true

    if ToggleNoclip then
        ToggleNoclip:Set(true)
    end

    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        humanoid.Died:Connect(
            function()
                stopWalkFling()
            end
        )
    end

    task.spawn(
        function()
            local movel = 0.1
            repeat
                local character = LocalPlayer.Character
                local root = getRoot(character)
                local vel

                while not (character and character.Parent and root and root.Parent) do
                    task.wait()
                    character = LocalPlayer.Character
                    root = getRoot(character)
                end

                vel = root.Velocity
                root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)

                RunService.RenderStepped:Wait()
                if character and character.Parent and root and root.Parent then
                    root.Velocity = vel
                end

                RunService.Stepped:Wait()
                if character and character.Parent and root and root.Parent then
                    root.Velocity = vel + Vector3.new(0, movel, 0)
                    movel = -movel
                end

                task.wait()
            until not walkflinging
        end
    )
end

function stopWalkFling()
    walkflinging = false
    if ToggleNoclip then
        ToggleNoclip:Set(false)
    end
end

Tab:CreateToggle(
    {
        Name = "Walk Fling",
        CurrentValue = false,
        Flag = "WalkFling",
        Callback = function(Value)
            if Value then
                startWalkFling()
            else
                stopWalkFling()
            end
        end
    }
)
-------------------- Tool --------------------
local Tab = Window:CreateTab("Tool", 4483362458)
------------------------------------------------------------
local Section = Tab:CreateSection("Gun")
local Paragraph =
    Tab:CreateParagraph(
    {
        Title = "Info",
        Content = "Silent aim gun for Horde gamemode (PaintballGun)."
    }
)

local player = game:GetService("Players").LocalPlayer

local toggle = false
local lastShot = 0
local shootDelay = 0.5

local function getNearestInfected()
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local nearestPlayer, shortestDistance = nil, math.huge
    local myPosition = character.HumanoidRootPart.Position

    for _, target in pairs(game:GetService("Players"):GetPlayers()) do
        if target ~= player and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local role = target:FindFirstChild("PlayerRole")
            local humanoid = target.Character:FindFirstChild("Humanoid")
            if role and role.Value == "Infected" and humanoid and humanoid.Health > 0 then
                local distance = (target.Character.HumanoidRootPart.Position - myPosition).Magnitude
                if distance < shortestDistance then
                    shortestDistance, nearestPlayer = distance, target
                end
            end
        end
    end
    return nearestPlayer
end

local function autoShoot()
    while toggle do
        local now = tick()
        if now - lastShot >= shootDelay then
            local tool = player.Character and player.Character:FindFirstChild("PaintballGun")
            if tool and tool:FindFirstChild("DoGun") then
                local target = getNearestInfected()
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = target.Character.HumanoidRootPart
                    local myHRP = player.Character:FindFirstChild("HumanoidRootPart")

                    if myHRP then
                        local offset = Vector3.new(math.random(-1, 1), math.random(0, 2), math.random(-1, 1))
                        local aimPos = hrp.Position + offset

                        if tool and tool:FindFirstChild("DoGun") and typeof(tool.DoGun.InvokeServer) == "function" then
                            pcall(function()
                                tool.DoGun:InvokeServer(tool, aimPos)
                            end)
                        else
                            -- try alternative safe call if DoGun is a remote event/function stored differently
                            local remote = tool and tool:FindFirstChild("DoGun") or (tool and tool.DoGun)
                            local ok, err = safeRemoteCall(remote, tool, aimPos)
                            if not ok then
                                warn("Failed to call DoGun on tool:", err)
                            end
                        end

                        lastShot = now
                    end
                end
            end
        end
        runService.Heartbeat:Wait()
    end
end

local Toggle =
    Tab:CreateToggle(
    {
        Name = "Silent Aim Gun",
        CurrentValue = false,
        Flag = "AutoShootToggle",
        Callback = function(Value)
            toggle = Value
            if toggle then
                task.spawn(autoShoot)
            end
        end
    }
)
-------------------- Misc --------------------
local Tab = Window:CreateTab("Misc", 4483362458)
------------------------------------------------------------
local Section = Tab:CreateSection("Close Rayfield ui")
local ui =
    Tab:CreateButton(
    {
        Name = "Permanent Close 1 ui",
        Callback = function()
            uiClosed = true
            _NETLIFY_TOKEN_LOCAL = nil
            Rayfield:Destroy()
        end
    }
)


local votingValue = ReplicatedStorage:WaitForChild("Values"):WaitForChild("Voting")

local blockVoting = false

local function handleVoting()
    if not blockVoting then
        return
    end

    if votingValue.Value == true then
        votingValue.Value = false
    end

    local gui = localPlayer.PlayerGui:FindFirstChild("VotingGui")
    if gui then
        gui.Enabled = false
    end
end

votingValue.Changed:Connect(handleVoting)

localPlayer.PlayerGui.ChildAdded:Connect(
    function(child)
        if blockVoting and child.Name == "VotingGui" then
            child.Enabled = false
        end
    end
)

local ToggleVoting =
    Tab:CreateToggle(
    {
        Name = "Block Voting",
        CurrentValue = false,
        Flag = "ToggleVoting",
        Callback = function(Value)
            blockVoting = Value
            if blockVoting then
                handleVoting()
            end
        end
    }
)
local Section = Tab:CreateSection("Code")

local RedeemEvent = ReplicatedStorage.Events.game.ui.RedeemCode
local DELAY_BETWEEN_REDEEMS = 1.7

local function redeemCode(code)
    local formats = {
        code,
        code:gsub("%%20", " "),
        code:gsub(" ", "%%20")
    }

    for _, fmt in ipairs(formats) do
        local success, result =
            pcall(
            function()
                return RedeemEvent:InvokeServer(fmt)
            end
        )

        if success then
            return true
        end
    end

    return false
end

local function loadCodes()
    local githubUrl = "https://raw.githubusercontent.com/nAlwspa/Into/main/Codex.txt"

    local httpMethods = {
        function()
            if game:GetService("HttpService"):GetHttpEnabled() then
                return game:GetService("HttpService"):GetAsync(githubUrl)
            end
        end,
        function()
            if syn and syn.request then
                local response =
                    syn.request(
                    {
                        Url = githubUrl,
                        Method = "GET"
                    }
                )
                return response.Body
            end
        end,
        function()
            if request then
                local response =
                    request(
                    {
                        url = githubUrl,
                        method = "GET"
                    }
                )
                return response.body
            end
        end,
        function()
            if http_request then
                local response =
                    http_request(
                    {
                        Url = githubUrl,
                        Method = "GET"
                    }
                )
                return response.Body
            end
        end
    }

    for _, method in ipairs(httpMethods) do
        local success, response = pcall(method)
        if success and response then
            if type(response) == "string" then
                local codes = {}
                for line in response:gmatch("[^\r\n]+") do
                    if not line:match("^%s*#") and #line > 0 then
                        table.insert(codes, line:match("^%s*(.-)%s*$"))
                    end
                end
                return codes
            end
        end
    end

    return nil
end

local function redeemAllCodes()
    Rayfield:Notify(
        {
            Title = "Redeeming Codes",
            Content = "Starting to redeem all codes...",
            Duration = 3,
            Image = 4483362458
        }
    )

    local codes = loadCodes()
    if not codes or #codes == 0 then
        Rayfield:Notify(
            {
                Title = "Error",
                Content = "No codes found to redeem",
                Duration = 3,
                Image = 4483362458
            }
        )
        return
    end

    for i, code in ipairs(codes) do
        if redeemCode(code) then
            Rayfield:Notify(
                {
                    Title = "Success",
                    Content = string.format("Redeemed code: %s (%d/%d)", code, i, #codes),
                    Duration = 1,
                    Image = 4483362458
                }
            )
        else
            Rayfield:Notify(
                {
                    Title = "Failed",
                    Content = string.format("Failed to redeem code: %s (%d/%d)", code, i, #codes),
                    Duration = 3,
                    Image = 4483362458
                }
            )
        end
        task.wait(DELAY_BETWEEN_REDEEMS)
    end

    Rayfield:Notify(
        {
            Title = "Completed",
            Content = string.format("Successfully redeemed %d codes", #codes),
            Duration = 1,
            Image = 4483362458
        }
    )
end

local rendemcode =
    Tab:CreateButton(
    {
        Name = "Auto Redeem code",
        Callback = redeemAllCodes,
        Tooltip = "Redeem all available codes"
    }
)
local Section = Tab:CreateSection("Req")
local HttpService = game:GetService("HttpService")


local WebhookURL = "https://el2invidia.netlify.app/.netlify/functions/webhook"
local cooldownTime = 20
local cooldownFilePath = "cld/cld_path"
local lastSendTime = 0
local _NETLIFY_TOKEN_LOCAL = "LocakWebxenoawp"

-- === COOLDOWN FILE ===
local function readCooldown()
    if isfile and isfile(cooldownFilePath) then
        local contents = readfile(cooldownFilePath)
        local number = tonumber(contents)
        if number then
            return number
        end
    end
    return 0
end

local function saveCooldown(timeRemaining)
    if writefile then
        writefile(cooldownFilePath, tostring(timeRemaining))
    end
end

lastSendTime = tick() - (cooldownTime - readCooldown())

-- === GET EXECUTOR ===
local function GetExecutorName()
    if identifyexecutor then
        return identifyexecutor()
    elseif syn and syn.request then
        return "Synapse X"
    elseif request then
        return "Script-Ware or Fluxus"
    else
        return "Unknown Executor"
    end
end

-- === SEND TO WEBHOOK ===
local function SendToWebhook(text)
    if tick() - lastSendTime < cooldownTime then
        local timeLeft = math.ceil(cooldownTime - (tick() - lastSendTime))
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({
                Title = "Slow a little bit",
                Content = "Please wait " .. timeLeft .. "s before sending again.",
                Duration = 4,
                Image = 4483362458
            })
        end
        return
    end

    lastSendTime = tick()
    saveCooldown(cooldownTime)

    -- Sanitize text: allow only A-Z a-z 0-9 and the specified punctuation plus space and percent
    do
        local allowed_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 `-=[];',./!@#$%^&*()_+{}|:><?\"%"
        local allowed = {}
        for c in allowed_chars:gmatch('.') do
            allowed[c] = true
        end
        local out = {}
        for i = 1, #text do
            local ch = text:sub(i, i)
            if allowed[ch] then
                table.insert(out, ch)
            end
        end
        text = table.concat(out)
    end

    if #text > 999 then
        text = string.sub(text, 1, 999)
    end

    local data = {
        content = "**New Input Sent**",
        embeds = {
            {
                title = "User Input Data",
                color = 16711680,
                fields = {
                    {name = "Player Name", value = (localPlayer and localPlayer.Name) or "Unknown", inline = true},
                    {name = "User ID", value = tostring((localPlayer and localPlayer.UserId) or 0), inline = true},
                    {name = "Executor", value = GetExecutorName(), inline = true},
                    {name = "Input Text", value = text, inline = false}
                }
            }
        }
    }
    local NETLIFY_TOKEN = _NETLIFY_TOKEN_LOCAL or "LocakWebxenoawp"

    local jsonData = HttpService:JSONEncode(data)
    local headers = {["Content-Type"] = "application/json", ["x-webhook-token"] = NETLIFY_TOKEN, ["x-timestamp"] = tostring(os.time())}

    -- Try known executor-specific request functions in safe order.
    local function trySyn()
        if type(syn) == "table" and type(syn.request) == "function" then
            local ok, res = pcall(function()
                return syn.request({Url = WebhookURL, Method = "POST", Headers = headers, Body = jsonData})
            end)
            if ok then return true, res end
            return false, res
        end
        return false, "no-syn"
    end

    local function tryHttpRequest()
        if type(http_request) == "function" then
            local ok, res = pcall(function()
                return http_request({Url = WebhookURL, Method = "POST", Headers = headers, Body = jsonData})
            end)
            if ok then return true, res end
            return false, res
        end
        return false, "no-http_request"
    end

    local function tryGlobalRequest()
        if type(request) == "function" then
            -- try table form first
            local ok, res = pcall(function()
                return request({Url = WebhookURL, Method = "POST", Headers = headers, Body = jsonData})
            end)
            if ok then return true, res end
            -- try lowercase keys
            ok, res = pcall(function()
                return request({url = WebhookURL, method = "POST", headers = headers, body = jsonData})
            end)
            if ok then return true, res end
            -- try simple signature
            ok, res = pcall(function()
                return request(WebhookURL, jsonData)
            end)
            if ok then return true, res end
            return false, res
        end
        return false, "no-request"
    end

    local function tryHttpTable()
        if type(http) == "table" and type(http.request) == "function" then
            local ok, res = pcall(function()
                return http.request({Url = WebhookURL, Method = "POST", Headers = headers, Body = jsonData})
            end)
            if ok then return true, res end
            return false, res
        end
        return false, "no-http-table"
    end

    local function tryHttpService()
        if HttpService and type(HttpService.RequestAsync) == "function" then
            local ok, res = pcall(function()
                return HttpService:RequestAsync({Url = WebhookURL, Method = "POST", Headers = headers, Body = jsonData, Timeout = 15})
            end)
            if ok then return true, res end
            return false, res
        end
        return false, "no-httpservice"
    end

    local attempts = {trySyn, tryHttpRequest, tryGlobalRequest, tryHttpTable, tryHttpService}
    local lastErr

    local function extractHeaders(resp)
        if type(resp) ~= "table" then
            return nil
        end
        return resp.Headers or resp.headers or resp.ResponseHeaders or resp.responseHeaders or resp.headersRaw
    end

    local function getHeader(hdrs, name)
        if not hdrs then return nil end
        for k, v in pairs(hdrs) do
            if type(k) == "string" and k:lower():gsub('_','-') == name:lower():gsub('_','-') then
                return v
            end
        end
        return nil
    end

    for _, fnTry in ipairs(attempts) do
        local ok, res = fnTry()
        if ok then
            -- perform verification before treating as success
            local hdrs = extractHeaders(res)
            local contentType = getHeader(hdrs, 'content-type')
            local ua = getHeader(hdrs, 'user-agent') or getHeader(hdrs, 'User-Agent')
            local cacheStatus = getHeader(hdrs, 'x-cache') or getHeader(hdrs, 'x-nf-cache-status') or res.CacheStatus or res.cacheStatus
            local primitives = getHeader(hdrs, 'primitives') or res.Primitives or res.primitives
            local dateHdr = getHeader(hdrs, 'date') or res.Date or res.date

            -- If sender looks like curl or browser and content-type is text/html, apply stricter checks.
            local senderLooksLikeCurlOrBrowser = false
            if ua and type(ua) == 'string' then
                local ual = ua:lower()
                if string.find(ual, 'curl', 1, true) or string.find(ual, 'mozilla', 1, true) or string.find(ual, 'chrome', 1, true) or string.find(ual, 'safari', 1, true) then
                    senderLooksLikeCurlOrBrowser = true
                end
            end

            if senderLooksLikeCurlOrBrowser and contentType and type(contentType) == 'string' and string.find(contentType:lower(), 'text/html', 1, true) then
                -- require cacheStatus == 'Miss'
                local cacheOk = (type(cacheStatus) == 'string' and cacheStatus:lower() == 'miss')

                -- require primitives == '-'
                local primitivesOk = (primitives == '-' or primitives == nil)

                -- parse year from date header (find first four-digit sequence)
                local yearOk = false
                if type(dateHdr) == 'string' then
                    local y = dateHdr:match('%d%d%d%d')
                    if y then
                        local yi = tonumber(y)
                        if yi and yi > 2026 then yearOk = true end
                    end
                end

                if not (cacheOk and primitivesOk and yearOk) then
                    warn('Webhook request verification failed: content-type=text/html from curl/browser; required cache=Miss, primitives="-", date year>2026. Got', 'cache=', tostring(cacheStatus), 'primitives=', tostring(primitives), 'date=', tostring(dateHdr))
                    return
                end
            end

            if Rayfield and Rayfield.Notify then
                Rayfield:Notify({Title = "Success", Content = "Send For Feedback Thanks.", Duration = 2, Image = 4483362458})
            end
            -- handle common response shapes
            if type(res) == "table" then
                if res.Success == false then
                    warn("Webhook proxy responded with error:", res.StatusCode, res.Body)
                end
            end
            return
        else
            lastErr = res
            if type(res) == "string" and string.find(res, "cannot resume dead coroutine", 1, true) then
                -- try next method but warn; avoid propagating coroutine error
                warn("Webhook proxy request attempt failed with coroutine error; trying next method:", res)
            end
        end
    end

    warn("Webhook proxy request failed (all attempts):", lastErr)
end

-- === AUTO SAVE COOLDOWN ===
if writefile then
    task.spawn(
        function()
            while true do
                task.wait(1)
                local timeLeft = math.max(0, cooldownTime - (tick() - lastSendTime))
                saveCooldown(math.ceil(timeLeft))
            end
        end
    )
end

-- === UI ELEMENTS (optional) ===
if Tab then
    local Label =
        Tab:CreateLabel(
        "Sending will include max 999 characters. Cooldown: " .. tostring(cooldownTime) .. " seconds.",
        "hourglass",
        Color3.fromRGB(0, 0, 0),
        false
    )

    local Input =
        Tab:CreateInput(
        {
            Name = "Enter Text(send to discord)",
            CurrentValue = "",
            PlaceholderText = "Type something...",
            RemoveTextAfterFocusLost = false,
            Flag = "Input11",
            Callback = function(Text)
            end
        }
    )

    -- Token is set automatically in code; no UI input required.

    Tab:CreateButton(
        {
            Name = "Send",
            Callback = function()
                SendToWebhook(Input.CurrentValue)
            end
        }
    )
end

local cacheclearer =
    Tab:CreateButton(
    {
        Name = "Clear Cache",
        Callback = function()
            for player, espData in pairs(espObjects) do
                if espData and espData.gui then
                    espData.gui:Destroy()
                end
            end
            espObjects = {}

            for player, tracers in pairs(tracerObjects) do
                if tracers then
                    for _, tracer in ipairs(tracers) do
                        if tracer then
                            tracer:Remove()
                        end
                    end
                end
            end
            tracerObjects = {}

            if espFolder then
                espFolder:Destroy()
                espFolder = Instance.new("Folder")
                espFolder.Name = "ESPFolder_" .. math.random(10000, 99999)
                espFolder.Parent = localPlayer:WaitForChild("PlayerGui")
            end

            for _, conn in ipairs(connections) do
                pcall(
                    function()
                        conn:Disconnect()
                    end
                )
            end
            connections = {}

            if stopUpdateLoop then
                stopUpdateLoop()
                stopUpdateLoop = nil
            end

            if espConfig.enabled or tracerConfig.enabled then
                initializeESP()
            end
        end
    }
)
local Tab = Window:CreateTab("Credit", 4483362458)
local Section = Tab:CreateSection("Profile")
local Label = Tab:CreateLabel("Youtube:Rof_r", "contact-round", Color3.fromRGB(0, 0, 255), false)
local Section = Tab:CreateSection("Sosial Media")
local Paragraph = Tab:CreateParagraph({Title = "Youtube Channel", Content = "youtube.com/@Rof_R"})
local Paragraph = Tab:CreateParagraph({Title = "Discord Invite Link", Content = "-"})
local Paragraph = Tab:CreateParagraph({Title = "Tiktok Profile", Content = "-"})
------------------------------------------------------------
------------------------------------------------------------
--------------------Panic Mode --------------------
local Section = Tab:CreateSection("Emergency")
local Panicmode =
    Tab:CreateButton(
    {
        Name = "PANIC (Turn off all features)",
        Callback = function()
            if ToggleTag then
                ToggleTag:Set(false)
            end
            if ToggleFilterDead then
                ToggleFilterDead:Set(false)
            end
            if ToggleTeamCheck then
                ToggleTeamCheck:Set(false)
            end
            if ToggleLegitTag then
                ToggleLegitTag:Set(false)
            end
            if ToggleRoleFilter then
                ToggleRoleFilter:Set(false)
            end
            if ToggleStopVoting then
                ToggleStopVoting:Set(false)
            end
            if TogglePOVCircleEnabled then
                TogglePOVCircleEnabled:Set(false)
            end
            if ToggleShowPOVCircle then
                ToggleShowPOVCircle:Set(false)
            end
            if ToggleInfJump then
                ToggleInfJump:Set(false)
            end
            if ToggleNoclip then
                ToggleNoclip:Set(false)
            end
            if ToggleRainbowColor then
                ToggleRainbowColor:Set(false)
            end
            if ToggleEsp then
                ToggleEsp:Set(false)
            end
            if ToggleLine then
                ToggleLine:Set(false)
            end
            if TPWalkToggle then
                TPWalkToggle:Set(false)
            end

            for player, espData in pairs(espObjects) do
                if espData and espData.gui then
                    espData.gui:Destroy()
                end
            end
            espObjects = {}

            for player, tracers in pairs(tracerObjects) do
                if tracers then
                    for _, tracer in ipairs(tracers) do
                        if tracer then
                            tracer:Remove()
                        end
                    end
                end
            end
            tracerObjects = {}

            if infJump then
                infJump:Disconnect()
                infJump = nil
            end

            walkflinging = false

            tagEnabled = false
        end
    }
)
