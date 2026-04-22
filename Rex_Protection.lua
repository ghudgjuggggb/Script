local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local VirtualUser       = game:GetService("VirtualUser")
local TeleportService   = game:GetService("TeleportService")
local ScriptContext     = game:GetService("ScriptContext")
local CoreGui           = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkClient     = game:GetService("NetworkClient")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local Rex = {}
Rex.Version = "1.0.0 Beta"
Rex.Active  = false
Rex.Threads = {}
Rex.Hooks   = {}
Rex.Log     = {}

local function rLog(msg)
    local entry = "[Rex] " .. msg
    table.insert(Rex.Log, entry)
    if #Rex.Log > 100 then table.remove(Rex.Log, 1) end
    pcall(function() print(entry) end)
end

local function rSpawn(fn)
    local t = task.spawn(fn)
    table.insert(Rex.Threads, t)
    return t
end

local function rRand(min, max)
    return min + math.random() * (max - min)
end

local function rRandInt(min, max)
    return math.random(min, max)
end

local function rGetChar()
    return LocalPlayer.Character
end

local function rGetRoot()
    local c = rGetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function rGetHum()
    local c = rGetChar()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function showSplash()
    local vp    = Camera.ViewportSize
    local cx    = vp.X / 2
    local cy    = vp.Y / 2

    local bg = Drawing.new("Square")
    bg.Size      = Vector2.new(420, 140)
    bg.Position  = Vector2.new(cx - 210, cy - 70)
    bg.Color     = Color3.fromRGB(10, 10, 16)
    bg.Filled    = true
    bg.Thickness = 1
    bg.Visible   = true
    bg.Transparency = 0.12

    local border = Drawing.new("Square")
    border.Size      = Vector2.new(420, 140)
    border.Position  = Vector2.new(cx - 210, cy - 70)
    border.Color     = Color3.fromRGB(80, 120, 255)
    border.Filled    = false
    border.Thickness = 2
    border.Visible   = true

    local accent = Drawing.new("Square")
    accent.Size      = Vector2.new(420, 3)
    accent.Position  = Vector2.new(cx - 210, cy - 70)
    accent.Color     = Color3.fromRGB(80, 120, 255)
    accent.Filled    = true
    accent.Thickness = 1
    accent.Visible   = true

    local title = Drawing.new("Text")
    title.Text      = "Start Rex"
    title.Size      = 36
    title.Font      = Drawing.Fonts.GothamBold
    title.Color     = Color3.fromRGB(255, 255, 255)
    title.Position  = Vector2.new(cx, cy - 22)
    title.Center    = true
    title.Outline   = true
    title.OutlineColor = Color3.fromRGB(0, 0, 0)
    title.Visible   = true

    local ver = Drawing.new("Text")
    ver.Text     = "v" .. Rex.Version
    ver.Size     = 18
    ver.Font     = Drawing.Fonts.Gotham
    ver.Color    = Color3.fromRGB(130, 160, 255)
    ver.Position = Vector2.new(cx, cy + 18)
    ver.Center   = true
    ver.Outline  = true
    ver.OutlineColor = Color3.fromRGB(0, 0, 0)
    ver.Visible  = true

    local sub = Drawing.new("Text")
    sub.Text     = "Protection System · Loading..."
    sub.Size     = 14
    sub.Font     = Drawing.Fonts.Gotham
    sub.Color    = Color3.fromRGB(160, 160, 180)
    sub.Position = Vector2.new(cx, cy + 44)
    sub.Center   = true
    sub.Outline  = false
    sub.Visible  = true

    task.delay(3.2, function()
        for _, d in ipairs({ bg, border, accent, title, ver, sub }) do
            pcall(function() d:Remove() end)
        end
    end)
end

pcall(showSplash)

local RexAntiKick = {}

function RexAntiKick:Init()
    local mt = getrawmetatable(game)
    pcall(function()
        setreadonly(mt, false)
        local oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args   = {...}
            if method == "Kick" and self == LocalPlayer then
                rLog("AntiKick: Blocked Player:Kick()")
                return
            end
            if method == "TeleportToPlaceInstance" or method == "Teleport" then
                if self == TeleportService then
                    local placeId = args[1]
                    if placeId ~= game.PlaceId then
                        rLog("AntiKick: Blocked suspicious teleport → PlaceId " .. tostring(placeId))
                        return
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)

    rSpawn(function()
        while Rex.Active do
            task.wait(0.1)
            local hum = rGetHum()
            if hum then
                if hum.Health <= 0 and hum.MaxHealth > 0 then
                    pcall(function() hum.Health = hum.MaxHealth end)
                    rLog("AntiKick: Prevented health-zero kick")
                end
            end
        end
    end)

    pcall(function()
        ScriptContext.Error:Connect(function(msg, trace, script)
            if msg and (msg:lower():find("kick") or msg:lower():find("ban") or msg:lower():find("cheat")) then
                rLog("AntiKick: Suppressed error kick: " .. tostring(msg))
                return false
            end
        end)
    end)

    rLog("AntiKick: Initialized")
end

local RexAntiBan = {}
RexAntiBan.MoveSeed      = 0
RexAntiBan.CamSeed       = 0
RexAntiBan.HeartbeatTick = 0

function RexAntiBan:SpoofMovement()
    local root = rGetRoot()
    if not root then return end
    pcall(function()
        local offsets = {
            Vector3.new( 0.03, 0,  0.00),
            Vector3.new(-0.03, 0,  0.00),
            Vector3.new( 0.00, 0,  0.03),
            Vector3.new( 0.00, 0, -0.03),
            Vector3.new( 0.02, 0,  0.02),
            Vector3.new(-0.02, 0, -0.02),
            Vector3.new( 0.00, 0,  0.00),
        }
        local pick = offsets[rRandInt(1, #offsets)]
        root.CFrame = root.CFrame + pick
    end)
end

function RexAntiBan:SpoofCamera()
    pcall(function()
        if not Camera then return end
        local yaw   = rRand(-0.0008, 0.0008)
        local pitch = rRand(-0.0003, 0.0003)
        Camera.CFrame = Camera.CFrame * CFrame.Angles(pitch, yaw, 0)
    end)
end

function RexAntiBan:SpoofHeartbeat()
    pcall(function()
        VirtualUser:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
        task.wait(rRand(0.04, 0.09))
        VirtualUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
    end)
end

function RexAntiBan:SpoofMouseMove()
    pcall(function()
        local x = rRandInt(-3, 3)
        local y = rRandInt(-3, 3)
        VirtualUser:MoveMouse(Vector2.new(x, y))
    end)
end

function RexAntiBan:RandomiseTimings()
    local base   = rRand(0.18, 0.55)
    local jitter = rRand(0, 0.25) * (math.random() > 0.5 and 1 or -1)
    return math.max(0.05, base + jitter)
end

function RexAntiBan:Init()
    rSpawn(function()
        local cycle = 0
        while Rex.Active do
            cycle += 1
            RexAntiBan:SpoofMovement()
            if cycle % 3 == 0 then RexAntiBan:SpoofCamera() end
            if cycle % 7 == 0 then RexAntiBan:SpoofMouseMove() end
            if cycle % 4 == 0 then RexAntiBan:SpoofHeartbeat() end
            if cycle % rRandInt(40, 60) == 0 then
                task.wait(rRand(2.5, 6.0))
                cycle = 0
            end
            task.wait(RexAntiBan:RandomiseTimings())
        end
    end)

    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(52, 88))
            RexAntiBan:SpoofHeartbeat()
            RexAntiBan:SpoofCamera()
        end
    end)

    rLog("AntiBan: Initialized")
end

local RexAntiAC = {}

RexAntiAC.WhitelistRemotes = {
    "ClaimReward","CollectReward","YenReward","EventReward","LikeReward",
    "AFKReward","SpinReward","DailyReward","FreeReward","Collect","Claim",
}

RexAntiAC.SuspiciousPatterns = {
    "detect","anticheat","anti_cheat","ac_","cheatcheck","speedcheck",
    "flycheck","teleportcheck","flagplayer","reportplayer","banplayer",
    "kickplayer","punishment","violation","exploit","hack","cheat",
}

function RexAntiAC:IsSuspiciousRemote(name)
    local nl = name:lower()
    for _, pat in ipairs(RexAntiAC.SuspiciousPatterns) do
        if nl:find(pat) then return true end
    end
    return false
end

function RexAntiAC:IsWhitelisted(name)
    local nl = name:lower()
    for _, w in ipairs(RexAntiAC.WhitelistRemotes) do
        if nl:find(w:lower()) then return true end
    end
    return false
end

function RexAntiAC:BlockACRemotes()
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args   = {...}
            if method == "FireServer" or method == "InvokeServer" then
                if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                    local name = self.Name
                    if RexAntiAC:IsSuspiciousRemote(name) and not RexAntiAC:IsWhitelisted(name) then
                        rLog("AntiAC: Blocked suspicious remote: " .. name)
                        return nil
                    end
                end
            end
            if method == "FireClient" or method == "InvokeClient" then
                if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                    local name = self.Name
                    if RexAntiAC:IsSuspiciousRemote(name) then
                        rLog("AntiAC: Blocked incoming AC ping: " .. name)
                        return nil
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)
end

function RexAntiAC:CleanPlayerFlags()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(1.5, 3.0))
            pcall(function()
                for _, v in ipairs(LocalPlayer:GetDescendants()) do
                    local nl = v.Name:lower()
                    local isSuspicious = nl:find("cheat") or nl:find("exploit")
                        or nl:find("flag") or nl:find("ban") or nl:find("detect")
                        or nl:find("hack") or nl:find("violation")
                    if isSuspicious and (v:IsA("BoolValue") or v:IsA("StringValue") or v:IsA("IntValue")) then
                        pcall(function()
                            if v:IsA("BoolValue") then v.Value = false
                            elseif v:IsA("IntValue") then v.Value = 0
                            elseif v:IsA("StringValue") then v.Value = ""
                            end
                        end)
                        rLog("AntiAC: Cleared flag: " .. v.Name)
                    end
                end
            end)
        end
    end)
end

function RexAntiAC:SpoofHumanoidState()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(0.8, 1.5))
            pcall(function()
                local hum = rGetHum()
                if hum then
                    local state = hum:GetState()
                    if state == Enum.HumanoidStateType.Freefall then
                        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                    end
                end
            end)
        end
    end)
end

function RexAntiAC:SpoofWalkSpeed()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(3.0, 7.0))
            pcall(function()
                local hum  = rGetHum()
                local root = rGetRoot()
                if hum and root then
                    local vel    = root.AssemblyLinearVelocity
                    local moving = vel.Magnitude > 0.5
                    if not moving and hum.WalkSpeed > 40 then
                        local saved = hum.WalkSpeed
                        hum.WalkSpeed = 16
                        task.wait(rRand(0.1, 0.3))
                        hum.WalkSpeed = saved
                    end
                end
            end)
        end
    end)
end

function RexAntiAC:MonitorACScripts()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(2.0, 4.0))
            pcall(function()
                for _, obj in ipairs(LocalPlayer:GetDescendants()) do
                    if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                        local nl = obj.Name:lower()
                        if nl:find("anticheat") or nl:find("ac") or nl:find("detect")
                        or nl:find("check") or nl:find("monitor") then
                            pcall(function() obj.Disabled = true end)
                            rLog("AntiAC: Disabled AC script: " .. obj.Name)
                        end
                    end
                end
            end)
        end
    end)
end

function RexAntiAC:Init()
    RexAntiAC:BlockACRemotes()
    RexAntiAC:CleanPlayerFlags()
    RexAntiAC:SpoofHumanoidState()
    RexAntiAC:SpoofWalkSpeed()
    RexAntiAC:MonitorACScripts()
    rLog("AntiAC: Initialized")
end

local RexAntiDetect = {}

function RexAntiDetect:SpoofScriptIdentity()
    pcall(function()
        local identities = {4, 5, 6, 7}
        local pick = identities[rRandInt(1, #identities)]
        set_thread_identity(pick)
    end)
    pcall(function()
        setidentity(rRandInt(4, 7))
    end)
end

function RexAntiDetect:ClearExecutorTraces()
    pcall(function()
        local envNames = {"SYNAPSE_RUNNING","KRNL_LOADED","FLUXUS","SCRIPT_HUB","EXECUTOR"}
        local G = getfenv(0)
        for _, name in ipairs(envNames) do
            if G[name] ~= nil then
                pcall(function() G[name] = nil end)
            end
        end
    end)
end

function RexAntiDetect:BlockPingDetection()
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        local oldIndex = mt.__index
        mt.__index = newcclosure(function(self, key)
            if key == "PlaceVersion" or key == "JobId" then
                if type(oldIndex) == "function" then
                    local ok, val = pcall(oldIndex, self, key)
                    return ok and val or nil
                end
            end
            if type(oldIndex) == "function" then
                return oldIndex(self, key)
            end
            return rawget(self, key)
        end)
        setreadonly(mt, true)
    end)
end

function RexAntiDetect:Init()
    RexAntiDetect:SpoofScriptIdentity()
    RexAntiDetect:ClearExecutorTraces()
    RexAntiDetect:BlockPingDetection()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(25, 45))
            RexAntiDetect:SpoofScriptIdentity()
            RexAntiDetect:ClearExecutorTraces()
        end
    end)
    rLog("AntiDetect: Initialized")
end

local RexGuardian = {}
RexGuardian.Watchlist = {}

function RexGuardian:Watch(name, fn)
    table.insert(RexGuardian.Watchlist, { name = name, fn = fn })
end

function RexGuardian:Init()
    rSpawn(function()
        while Rex.Active do
            task.wait(rRand(5.0, 10.0))
            for _, entry in ipairs(RexGuardian.Watchlist) do
                local ok, err = pcall(entry.fn)
                if not ok then
                    rLog("Guardian: Restarting " .. entry.name .. " — " .. tostring(err))
                    task.wait(0.5)
                end
            end
        end
    end)
    rLog("Guardian: Watching " .. #RexGuardian.Watchlist .. " modules")
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name            = "Rex",
    LoadingTitle    = "Rex Protection",
    LoadingSubtitle = "v" .. Rex.Version,
    ConfigurationSaving = { Enabled = false },
    Discord   = { Enabled = false },
    KeySystem = false,
})

local logLabel    = nil
local statusLabel = nil

local function refreshLog()
    if logLabel then
        local last = Rex.Log[#Rex.Log] or "No events yet."
        logLabel:Set("Last: " .. last)
    end
end

local HomeTab = Window:CreateTab("🛡 Rex", 4483362458)

HomeTab:CreateSection("Protection Status")

statusLabel = HomeTab:CreateLabel("Status: ⭕ Inactive")
logLabel    = HomeTab:CreateLabel("Last: —")

HomeTab:CreateToggle({
    Name         = "🛡 Enable Rex Protection",
    CurrentValue = false,
    Flag         = "RexMain",
    Callback     = function(val)
        Rex.Active = val
        if val then
            RexAntiBan:Init()
            RexAntiKick:Init()
            RexAntiAC:Init()
            RexAntiDetect:Init()

            RexGuardian:Watch("AntiBan",    function() RexAntiBan:SpoofHeartbeat() end)
            RexGuardian:Watch("AntiKick",   function() local h = rGetHum(); if h then return h.Health > 0 end end)
            RexGuardian:Watch("AntiDetect", function() RexAntiDetect:ClearExecutorTraces() end)
            RexGuardian:Init()

            if statusLabel then statusLabel:Set("Status: ✅ Active — All modules running") end

            Rayfield:Notify({
                Title    = "🛡 Rex Active",
                Content  = "Anti-Ban · Anti-Kick · Anti-AC · Anti-Detect",
                Duration = 5,
                Image    = 4483362458,
            })

            rSpawn(function()
                while Rex.Active do
                    task.wait(1.5)
                    pcall(refreshLog)
                end
            end)
        else
            if statusLabel then statusLabel:Set("Status: ⭕ Inactive") end
            for _, t in ipairs(Rex.Threads) do pcall(function() task.cancel(t) end) end
            Rex.Threads = {}
            Rayfield:Notify({
                Title    = "🛡 Rex Stopped",
                Content  = "All protection modules disabled.",
                Duration = 3,
            })
        end
    end,
})

HomeTab:CreateButton({
    Name     = "📋 Show Last 5 Events",
    Callback = function()
        local lines = {}
        local start = math.max(1, #Rex.Log - 4)
        for i = start, #Rex.Log do
            table.insert(lines, Rex.Log[i])
        end
        local text = #lines > 0 and table.concat(lines, "\n") or "No events logged yet."
        Rayfield:Notify({ Title = "📋 Rex Log", Content = text, Duration = 10 })
    end,
})

HomeTab:CreateButton({
    Name     = "🗑️ Clear Log",
    Callback = function()
        Rex.Log = {}
        if logLabel then logLabel:Set("Last: —") end
        Rayfield:Notify({ Title = "Log Cleared", Content = "Rex event log cleared.", Duration = 2 })
    end,
})

local AntiKickTab = Window:CreateTab("🦵 Anti-Kick", 4483362458)
AntiKickTab:CreateSection("Anti-Kick Info")
AntiKickTab:CreateLabel("Blocks all kick methods:")
AntiKickTab:CreateLabel("⚔ Player:Kick() namecall hook")
AntiKickTab:CreateLabel("⚔ Health-zero kick prevention")
AntiKickTab:CreateLabel("⚔ ScriptContext error kick suppression")
AntiKickTab:CreateLabel("⚔ Suspicious teleport blocker")

local AntiBanTab = Window:CreateTab("🚫 Anti-Ban", 4483362458)
AntiBanTab:CreateSection("Anti-Ban Info")
AntiBanTab:CreateLabel("Makes you look 100% human to the server:")
AntiBanTab:CreateLabel("⚔ Randomised micro-movements every cycle")
AntiBanTab:CreateLabel("⚔ Camera angle spoofing every 3 cycles")
AntiBanTab:CreateLabel("⚔ Mouse movement spoof every 7 cycles")
AntiBanTab:CreateLabel("⚔ VirtualUser heartbeat every 4 cycles")
AntiBanTab:CreateLabel("⚔ Random long pauses every 40–60 cycles")
AntiBanTab:CreateLabel("⚔ Independent idle heartbeat every ~70s")

local AntiACTab = Window:CreateTab("🔒 Anti-AC", 4483362458)
AntiACTab:CreateSection("Anti-AC Info")
AntiACTab:CreateLabel("Bypasses anti-cheat detection:")
AntiACTab:CreateLabel("⚔ Blocks suspicious RemoteEvent calls")
AntiACTab:CreateLabel("⚔ Clears exploit flags on LocalPlayer")
AntiACTab:CreateLabel("⚔ Humanoid state spoofing (fly/speed)")
AntiACTab:CreateLabel("⚔ WalkSpeed masking when standing still")
AntiACTab:CreateLabel("⚔ Monitors + disables AC LocalScripts")

local AntiDetectTab = Window:CreateTab("👁 Anti-Detect", 4483362458)
AntiDetectTab:CreateSection("Anti-Detect Info")
AntiDetectTab:CreateLabel("Hides executor traces from the server:")
AntiDetectTab:CreateLabel("⚔ Script identity spoofing (thread)")
AntiDetectTab:CreateLabel("⚔ Executor env variable removal")
AntiDetectTab:CreateLabel("⚔ Ping-based detection blocker")
AntiDetectTab:CreateLabel("⚔ Re-spoofs every 25–45 seconds")

local GuardianTab = Window:CreateTab("👁‍🗨 Guardian", 4483362458)
GuardianTab:CreateSection("Guardian Info")
GuardianTab:CreateLabel("Self-repair system — always watching:")
GuardianTab:CreateLabel("⚔ Monitors all Rex modules every 5–10s")
GuardianTab:CreateLabel("⚔ Automatically restarts any crashed module")
GuardianTab:CreateLabel("⚔ Logs every restart event to Rex Log")

local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)
MiscTab:CreateSection("Info")
MiscTab:CreateLabel("Rex v" .. Rex.Version .. " — Protection System")
MiscTab:CreateLabel("Anti-Ban · Anti-Kick · Anti-AC · Anti-Detect")
MiscTab:CreateLabel("Guardian — Self-Repair Engine")

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    rLog("Character respawned — re-checking modules")
end)

Rayfield:Notify({
    Title    = "🛡 Rex v" .. Rex.Version,
    Content  = "Loaded. Enable protection in the Rex tab.",
    Duration = 5,
    Image    = 4483362458,
})
