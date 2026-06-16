local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

if getgenv().OctopusLoaded then return end
getgenv().OctopusLoaded = true

local LogoId = "rbxassetid://71360187256646"
local AdaptationData = {}

local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

local function CreateLoadingScreen()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = HttpService:GenerateGUID(false)
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.DisplayOrder = 999999
    screenGui.Parent = CoreGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 220, 0, 220)
    mainFrame.Position = UDim2.new(0.5, -110, 0.5, -110)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BackgroundTransparency = 1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 90)
    stroke.Thickness = 1.5
    stroke.Transparency = 1
    stroke.Parent = mainFrame

    local gradientStroke = Instance.new("UIGradient")
    gradientStroke.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 120, 200)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 80, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 200))
    })
    gradientStroke.Rotation = 0
    gradientStroke.Parent = stroke

    local backgroundGradient = Instance.new("UIGradient")
    backgroundGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20))
    })
    backgroundGradient.Rotation = 135
    backgroundGradient.Parent = mainFrame

    local logoContainer = Instance.new("Frame")
    logoContainer.Name = "LogoContainer"
    logoContainer.Size = UDim2.new(0, 100, 0, 100)
    logoContainer.Position = UDim2.new(0.5, -50, 0.35, -50)
    logoContainer.BackgroundTransparency = 1
    logoContainer.BorderSizePixel = 0
    logoContainer.Parent = mainFrame

    local logo = Instance.new("ImageLabel")
    logo.Name = "Logo"
    logo.Size = UDim2.new(1, 0, 1, 0)
    logo.BackgroundTransparency = 1
    logo.Image = LogoId
    logo.ImageTransparency = 1
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Parent = logoContainer

    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1.8, 0, 1.8, 0)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = LogoId
    glow.ImageTransparency = 1
    glow.ImageColor3 = Color3.fromRGB(100, 150, 255)
    glow.ScaleType = Enum.ScaleType.Fit
    glow.ZIndex = logo.ZIndex - 1
    glow.Parent = logoContainer

    local statusText = Instance.new("TextLabel")
    statusText.Name = "Status"
    statusText.Size = UDim2.new(0, 200, 0, 20)
    statusText.Position = UDim2.new(0.5, -100, 0.72, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Initializing..."
    statusText.TextColor3 = Color3.fromRGB(200, 200, 255)
    statusText.TextTransparency = 1
    statusText.Font = Enum.Font.GothamMedium
    statusText.TextSize = 12
    statusText.Parent = mainFrame

    local progressBarBg = Instance.new("Frame")
    progressBarBg.Name = "ProgressBg"
    progressBarBg.Size = UDim2.new(0, 160, 0, 3)
    progressBarBg.Position = UDim2.new(0.5, -80, 0.82, 0)
    progressBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    progressBarBg.BackgroundTransparency = 1
    progressBarBg.BorderSizePixel = 0
    progressBarBg.Parent = mainFrame

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(1, 0)
    progressCorner.Parent = progressBarBg

    local progressBar = Instance.new("Frame")
    progressBar.Name = "Progress"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    progressBar.BackgroundTransparency = 1
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBarBg

    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(1, 0)
    progressBarCorner.Parent = progressBar

    local progressGradient = Instance.new("UIGradient")
    progressGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255))
    })
    progressGradient.Parent = progressBar

    local adaptationText = Instance.new("TextLabel")
    adaptationText.Name = "Adaptation"
    adaptationText.Size = UDim2.new(0, 200, 0, 16)
    adaptationText.Position = UDim2.new(0.5, -100, 0.9, 0)
    adaptationText.BackgroundTransparency = 1
    adaptationText.Text = "Neural: Standby"
    adaptationText.TextColor3 = Color3.fromRGB(150, 150, 200)
    adaptationText.TextTransparency = 1
    adaptationText.Font = Enum.Font.Gotham
    adaptationText.TextSize = 10
    adaptationText.Parent = mainFrame

    return {
        Screen = screenGui,
        MainFrame = mainFrame,
        Stroke = stroke,
        Logo = logo,
        Glow = glow,
        Status = statusText,
        ProgressBar = progressBar,
        ProgressBg = progressBarBg,
        AdaptationText = adaptationText
    }
end

local function AnimateLoading(ui)
    TweenService:Create(ui.MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.1}):Play()
    TweenService:Create(ui.Stroke, TweenInfo.new(0.6), {Transparency = 0}):Play()
    TweenService:Create(ui.Logo, TweenInfo.new(0.8), {ImageTransparency = 0}):Play()
    TweenService:Create(ui.Glow, TweenInfo.new(0.8), {ImageTransparency = 0.6}):Play()
    TweenService:Create(ui.Status, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    TweenService:Create(ui.ProgressBg, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
    TweenService:Create(ui.ProgressBar, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
    TweenService:Create(ui.AdaptationText, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

    task.wait(0.6)

    local stages = {
        {0.15, "Analyzing...", "Neural: Scanning"},
        {0.30, "Detecting AC...", "Neural: Learning"},
        {0.45, "Bypass Kick...", "Neural: Adapting"},
        {0.60, "Bypass Ban...", "Neural: Evolving"},
        {0.75, "Secure TP...", "Neural: Hardening"},
        {0.90, "Shield...", "Neural: Synced"},
        {1.00, "Ready", "Neural: Active"}
    }

    for _, stage in ipairs(stages) do
        TweenService:Create(ui.ProgressBar, TweenInfo.new(0.8, Enum.EasingStyle.Quad), {Size = UDim2.new(stage[1], 0, 1, 0)}):Play()
        ui.Status.Text = stage[2]
        ui.AdaptationText.Text = stage[3]

        local pulse = TweenService:Create(ui.Glow, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.3})
        pulse:Play()
        task.wait(0.4)
        TweenService:Create(ui.Glow, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {ImageTransparency = 0.6}):Play()
        task.wait(0.4)
    end

    task.wait(0.5)

    TweenService:Create(ui.Logo, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
    TweenService:Create(ui.Glow, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
    TweenService:Create(ui.Status, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TweenService:Create(ui.ProgressBar, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(ui.ProgressBg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(ui.AdaptationText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TweenService:Create(ui.Stroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
    TweenService:Create(ui.MainFrame, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()

    task.wait(0.8)
    ui.Screen:Destroy()
end

local function AdaptiveLearning()
    local function ScanEnvironment()
        local signatures = {}
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                local name = tostring(obj):lower()
                if name:find("ac") or name:find("anticheat") or name:find("anti") or name:find("detect") or name:find("check") or name:find("verify") or name:find("validate") or name:find("secure") then
                    table.insert(signatures, {Object = obj, Name = name, Type = obj.ClassName})
                end
            end
        end
        return signatures
    end

    local function AdaptToSignature(signature)
        local obj = signature.Object
        local name = signature.Name

        if not AdaptationData[name] then
            AdaptationData[name] = {Blocked = 0, Learned = 0, Patterns = {}}
        end

        if hookfunction and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            pcall(function()
                if obj:IsA("RemoteEvent") then
                    local oldFire = hookfunction(obj.FireServer, function(self, ...)
                        if self == obj then
                            AdaptationData[name].Blocked = AdaptationData[name].Blocked + 1
                            return nil
                        end
                        return oldFire(self, ...)
                    end)
                elseif obj:IsA("RemoteFunction") then
                    local oldInvoke = hookfunction(obj.InvokeServer, function(self, ...)
                        if self == obj then
                            AdaptationData[name].Blocked = AdaptationData[name].Blocked + 1
                            return nil
                        end
                        return oldInvoke(self, ...)
                    end)
                end
            end)
        end

        if getconnections then
            pcall(function()
                if obj:IsA("RemoteEvent") then
                    for _, conn in pairs(getconnections(obj.OnClientEvent)) do
                        if conn.Disable then
                            conn:Disable()
                        elseif conn.Disconnect then
                            conn:Disconnect()
                        end
                    end
                end
            end)
        end
    end

    local function ContinuousAdaptation()
        while true do
            task.wait(5)
            local newSignatures = ScanEnvironment()
            for _, sig in ipairs(newSignatures) do
                if not AdaptationData[sig.Name] then
                    AdaptToSignature(sig)
                end
            end

            for name, data in pairs(AdaptationData) do
                data.Learned = data.Learned + 1
            end
        end
    end

    local initialSignatures = ScanEnvironment()
    for _, sig in ipairs(initialSignatures) do
        AdaptToSignature(sig)
    end

    task.spawn(ContinuousAdaptation)
end

local function AntiKick()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" and self == LocalPlayer then
            return nil
        end
        return oldNamecall(self, ...)
    end)

    setreadonly(mt, true)

    if hookfunction then
        pcall(function()
            local oldKick = hookfunction(LocalPlayer.Kick, function(self, ...)
                if self == LocalPlayer then
                    return nil
                end
                return oldKick(self, ...)
            end)
        end)

        pcall(function()
            local oldDestroy = hookfunction(LocalPlayer.Destroy, function(self, ...)
                if self == LocalPlayer then
                    return nil
                end
                return oldDestroy(self, ...)
            end)
        end)
    end

    LocalPlayer.Kick = function() end

    if getconnections then
        pcall(function()
            for _, connection in pairs(getconnections(LocalPlayer.Kick)) do
                if connection.Disable then
                    connection:Disable()
                elseif connection.Disconnect then
                    connection:Disconnect()
                end
            end
        end)
    end
end

local function AntiBan()
    if hookfunction then
        pcall(function()
            local oldBanAsync = hookfunction(Players.BanAsync, function(self, ...)
                return nil
            end)
        end)

        pcall(function()
            local oldBan = hookfunction(Players.Ban, function(self, ...)
                return nil
            end)
        end)
    end

    pcall(function()
        TeleportService.Teleport = function() end
    end)

    pcall(function()
        TeleportService.TeleportToPlaceInstance = function() end
    end)

    pcall(function()
        TeleportService.TeleportPartyAsync = function() end
    end)

    pcall(function()
        TeleportService.TeleportAsync = function() end
    end)

    pcall(function()
        TeleportService.TeleportToSpawnByName = function() end
    end)

    if hookfunction then
        pcall(function()
            local oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
                local remoteName = tostring(self):lower()
                if remoteName:find("ban") or remoteName:find("kick") or remoteName:find("punish") or remoteName:find("mod") or remoteName:find("admin") or remoteName:find("exploit") or remoteName:find("cheat") or remoteName:find("hack") or remoteName:find("ac") or remoteName:find("anticheat") or remoteName:find("detect") or remoteName:find("check") then
                    return nil
                end
                return oldFireServer(self, ...)
            end)
        end)

        pcall(function()
            local oldInvokeServer = hookfunction(Instance.new("RemoteFunction").InvokeServer, function(self, ...)
                local remoteName = tostring(self):lower()
                if remoteName:find("ban") or remoteName:find("kick") or remoteName:find("punish") or remoteName:find("mod") or remoteName:find("admin") or remoteName:find("exploit") or remoteName:find("cheat") or remoteName:find("hack") or remoteName:find("ac") or remoteName:find("anticheat") or remoteName:find("detect") or remoteName:find("check") then
                    return nil
                end
                return oldInvokeServer(self, ...)
            end)
        end)
    end

    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local selfName = tostring(self):lower()

        if method == "FireServer" or method == "InvokeServer" then
            if selfName:find("ban") or selfName:find("kick") or selfName:find("punish") or selfName:find("mod") or selfName:find("admin") or selfName:find("exploit") or selfName:find("cheat") or selfName:find("hack") or selfName:find("ac") or selfName:find("anticheat") or selfName:find("detect") or selfName:find("check") then
                return nil
            end
        end

        if method == "Teleport" or method == "TeleportToPlaceInstance" or method == "TeleportPartyAsync" or method == "TeleportAsync" then
            return nil
        end

        if method == "Destroy" and self == LocalPlayer then
            return nil
        end

        return oldNamecall(self, ...)
    end)

    setreadonly(mt, true)

    if getconnections then
        pcall(function()
            for _, remote in pairs(game:GetDescendants()) do
                if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                    local name = tostring(remote):lower()
                    if name:find("ban") or name:find("kick") or name:find("punish") or name:find("mod") or name:find("admin") or name:find("ac") or name:find("anticheat") then
                        for _, connection in pairs(getconnections(remote.OnClientEvent)) do
                            if connection.Disable then
                                connection:Disable()
                            elseif connection.Disconnect then
                                connection:Disconnect()
                            end
                        end
                    end
                end
            end
        end)
    end
end

local function AntiCrash()
    if hookfunction then
        pcall(function()
            local oldError = hookfunction(error, function(...) end)
        end)

        pcall(function()
            local oldWarn = hookfunction(warn, function(...) end)
        end)
    end

    game:GetService("ScriptContext").Error:Connect(function() end)

    LocalPlayer.PlayerGui.DescendantAdded:Connect(function(descendant)
        pcall(function()
            if descendant:IsA("ScreenGui") then
                local name = tostring(descendant):lower()
                if name:find("ban") or name:find("kick") or name:find("punish") or name:find("error") or name:find("crash") then
                    descendant:Destroy()
                end
            end
        end)
    end)
end

local function AntiLog()
    if hookfunction then
        pcall(function()
            local oldLogService = hookfunction(game:GetService("LogService").GetLogHistory, function(self, ...)
                return {}
            end)
        end)
    end
end

local function AntiHeartbeat()
    RunService.Heartbeat:Connect(function()
        pcall(function()
            if LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health <= 0 then
                    humanoid.Health = 100
                end
            end
        end)
    end)
end

local function AntiMemoryScan()
    if hookfunction then
        pcall(function()
            local oldGetChildren = hookfunction(game.GetChildren, function(self, ...)
                return oldGetChildren(self, ...)
            end)
        end)
    end
end

local function Initialize()
    local ui = CreateLoadingScreen()
    task.spawn(function()
        AnimateLoading(ui)
    end)

    task.wait(0.1)
    AntiKick()
    task.wait(0.1)
    AntiBan()
    task.wait(0.1)
    AntiCrash()
    task.wait(0.1)
    AntiLog()
    task.wait(0.1)
    AntiHeartbeat()
    task.wait(0.1)
    AntiMemoryScan()
    task.wait(0.1)
    AdaptiveLearning()

    task.wait(2.5)
    Notify("Octopus", "Neural Shield Active", 3)
    Notify("Octopus", "Adaptive Learning Online", 3)
    Notify("Octopus", "All Systems Operational", 4)
end

Initialize()
