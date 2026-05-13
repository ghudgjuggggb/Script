local ShinroHub = {
    Version = "2.0.0",
    StartTime = tick(),
    SelectedRemote = nil,
    SelectedQuest = nil,
    AutoFire = false,
    FireDelay = 0.1,
    LoopFire = false,
    CopyMode = "full",
    FilterType = "All",
    SearchQuery = "",
    Favorites = {},
    History = {},
    MaxHistory = 50,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

local function GetExecutor()
    if identifyexecutor then
        return identifyexecutor()
    elseif getexecutorname then
        return getexecutorname()
    elseif KRNL_LOADED then
        return "Krnl"
    elseif syn then
        return "Synapse X"
    elseif fluxus then
        return "Fluxus"
    elseif Delta then
        return "Delta"
    elseif Codex then
        return "Codex"
    elseif Oxygen then
        return "Oxygen U"
    elseif gethui then
        return "Electron"
    elseif hookfunction and not syn then
        return "Custom"
    end
    return "Unknown"
end

local EXECUTOR = GetExecutor()

local function toStringSafe(obj)
    local t = typeof(obj)
    if t == "string" then
        return string.format("%q", obj)
    elseif t == "number" or t == "boolean" then
        return tostring(obj)
    elseif t == "nil" then
        return "nil"
    elseif t == "Vector3" then
        return string.format("Vector3.new(%.3f, %.3f, %.3f)", obj.X, obj.Y, obj.Z)
    elseif t == "CFrame" then
        local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = obj:GetComponents()
        return string.format("CFrame.new(%.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f, %.3f)", x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
    elseif t == "Color3" then
        return string.format("Color3.fromRGB(%d, %d, %d)", math.floor(obj.R * 255), math.floor(obj.G * 255), math.floor(obj.B * 255))
    elseif t == "Instance" then
        return obj:GetFullName()
    elseif t == "table" then
        local parts = {}
        for k, v in pairs(obj) do
            table.insert(parts, string.format("[%s] = %s", toStringSafe(k), toStringSafe(v)))
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    elseif t == "function" then
        return "function() end"
    else
        return string.format("%s(%s)", t, tostring(obj))
    end
end

local function GenerateRemoteCode(remote, args)
    local remotePath = remote:GetFullName()
    local code = ""

    if ShinroHub.CopyMode == "full" then
        code = string.format([[
local args = %s
game:GetService("ReplicatedStorage"):WaitForChild("%s"):WaitForChild("%s"):%s(unpack(args))
]], toStringSafe(args), remote.Parent.Name, remote.Name, remote:IsA("RemoteEvent") and "FireServer" or "InvokeServer")
    elseif ShinroHub.CopyMode == "compact" then
        code = string.format("game.%s:%s(%s)", remotePath, remote:IsA("RemoteEvent") and "FireServer" or "InvokeServer", toStringSafe(args))
    elseif ShinroHub.CopyMode == "args_only" then
        code = toStringSafe(args)
    elseif ShinroHub.CopyMode == "path_only" then
        code = string.format("game.%s", remotePath)
    end

    return code
end

local function CopyToClipboard(text)
    if setclipboard then
        setclipboard(text)
        return true
    elseif toclipboard then
        toclipboard(text)
        return true
    elseif syn and syn.write_clipboard then
        syn.write_clipboard(text)
        return true
    elseif clipboard and clipboard.set then
        clipboard.set(text)
        return true
    end
    return false
end

local function GetAllRemotes()
    local remotes = {}

    local function Scan(parent, path)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("BindableEvent") or child:IsA("BindableFunction") then
                local info = {
                    Object = child,
                    Name = child.Name,
                    Class = child.ClassName,
                    Path = child:GetFullName(),
                    Parent = child.Parent and child.Parent.Name or "nil",
                    Type = child:IsA("RemoteEvent") and "Event" or child:IsA("RemoteFunction") and "Function" or "Bindable",
                }
                table.insert(remotes, info)
            end
        end
    end

    Scan(ReplicatedStorage, "ReplicatedStorage")
    Scan(Workspace, "Workspace")

    if LP:FindFirstChild("PlayerGui") then
        Scan(LP.PlayerGui, "PlayerGui")
    end

    table.sort(remotes, function(a, b)
        return a.Path < b.Path
    end)

    return remotes
end

local function GetAllQuests()
    local quests = {}

    local function ScanForQuests(parent)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("ModuleScript") or child:IsA("Folder") then
                local name = child.Name:lower()
                if name:find("quest") or name:find("mission") or name:find("task") or name:find("objective") then
                    table.insert(quests, {
                        Object = child,
                        Name = child.Name,
                        Path = child:GetFullName(),
                        Type = "Module/Folder"
                    })
                end
            end

            if child:IsA("StringValue") or child:IsA("IntValue") or child:IsA("BoolValue") then
                local name = child.Name:lower()
                if name:find("quest") or name:find("mission") or name:find("task") then
                    table.insert(quests, {
                        Object = child,
                        Name = child.Name,
                        Path = child:GetFullName(),
                        Type = "Value",
                        Value = child.Value
                    })
                end
            end
        end
    end

    ScanForQuests(ReplicatedStorage)
    ScanForQuests(Workspace)
    ScanForQuests(LP)

    table.sort(quests, function(a, b)
        return a.Path < b.Path
    end)

    return quests
end

local function GetQuestRemotes()
    local questRemotes = {}
    local allRemotes = GetAllRemotes()

    for _, remote in ipairs(allRemotes) do
        local name = remote.Name:lower()
        if name:find("quest") or name:find("mission") or name:find("task") or name:find("objective") or name:find("give") or name:find("accept") or name:find("complete") then
            table.insert(questRemotes, remote)
        end
    end

    return questRemotes
end

local function FireRemote(remote, args)
    args = args or {}
    local success, result

    if remote.Object:IsA("RemoteEvent") then
        success, result = pcall(function()
            remote.Object:FireServer(unpack(args))
        end)
    elseif remote.Object:IsA("RemoteFunction") then
        success, result = pcall(function()
            return remote.Object:InvokeServer(unpack(args))
        end)
    end

    return success, result
end

local function AddToHistory(remote, args)
    table.insert(ShinroHub.History, 1, {
        Remote = remote,
        Args = args,
        Time = os.time(),
    })

    while #ShinroHub.History > ShinroHub.MaxHistory do
        table.remove(ShinroHub.History)
    end
end

local function CreateRayfieldUI()
    local ok, Rayfield = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)

    if not ok or not Rayfield then
        warn("[ShinroHub] Rayfield failed, using fallback UI")
        return CreateFallbackUI()
    end

    local Window = Rayfield:CreateWindow({
        Name = "Shinro Hub v" .. ShinroHub.Version,
        LoadingTitle = "Shinro Hub",
        LoadingSubtitle = "Remote Explorer | " .. EXECUTOR,
        Theme = "Default",
        ConfigurationSaving = { Enabled = true, FileName = "ShinroHub_Explorer" },
        KeySystem = false,
    })

    local InfoTab = Window:CreateTab("Info", 4483362458)
    InfoTab:CreateSection("Executor Info")
    InfoTab:CreateParagraph({
        Title = "Executor: " .. EXECUTOR,
        Content = "Copy Method: " .. (setclipboard and "setclipboard" or toclipboard and "toclipboard" or syn and "syn.write_clipboard" or "Not Available")
    })
    InfoTab:CreateParagraph({
        Title = "Features",
        Content = "Auto-scan all remotes | Quest detection | One-click copy | Auto-fire | History tracking"
    })

    local RemoteTab = Window:CreateTab("All Remotes", 4483362458)

    RemoteTab:CreateSection("Search & Filter")

    local RemoteSearch = RemoteTab:CreateInput({
        Name = "Search Remotes",
        PlaceholderText = "Type remote name...",
        RemoveTextAfterFocusLost = false,
        Callback = function(text)
            ShinroHub.SearchQuery = text:lower()
        end,
    })

    local RemoteFilter = RemoteTab:CreateDropdown({
        Name = "Filter Type",
        Options = {"All", "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction"},
        CurrentOption = {"All"},
        Flag = "RemoteFilter",
        Callback = function(selected)
            ShinroHub.FilterType = selected[1]
        end,
    })

    RemoteTab:CreateSection("Copy Settings")

    local CopyModeDropdown = RemoteTab:CreateDropdown({
        Name = "Copy Mode",
        Options = {"full", "compact", "args_only", "path_only"},
        CurrentOption = {"full"},
        Flag = "CopyMode",
        Callback = function(selected)
            ShinroHub.CopyMode = selected[1]
        end,
    })

    RemoteTab:CreateSection("Remote List")

    local allRemotes = GetAllRemotes()
    local remoteButtons = {}

    for i, remote in ipairs(allRemotes) do
        if i > 100 then break end

        local btn = RemoteTab:CreateButton({
            Name = string.format("[%s] %s (%s)", remote.Type, remote.Name, remote.Parent),
            Callback = function()
                ShinroHub.SelectedRemote = remote
                local code = GenerateRemoteCode(remote, {})
                local copied = CopyToClipboard(code)

                Rayfield:Notify({
                    Title = "Remote Copied!",
                    Content = remote.Name .. " | Mode: " .. ShinroHub.CopyMode,
                    Duration = 3,
                })

                AddToHistory(remote, {})
            end,
        })
        table.insert(remoteButtons, btn)
    end

    RemoteTab:CreateSection("Auto Fire")

    local AutoFireToggle = RemoteTab:CreateToggle({
        Name = "Auto Fire Selected",
        CurrentValue = false,
        Flag = "AutoFire",
        Callback = function(value)
            ShinroHub.AutoFire = value
            if value and ShinroHub.SelectedRemote then
                task.spawn(function()
                    while ShinroHub.AutoFire and ShinroHub.SelectedRemote do
                        FireRemote(ShinroHub.SelectedRemote, {})
                        task.wait(ShinroHub.FireDelay)
                    end
                end)
            end
        end,
    })

    local FireDelaySlider = RemoteTab:CreateSlider({
        Name = "Fire Delay (s)",
        Range = {0.01, 5},
        Increment = 0.01,
        Suffix = "s",
        CurrentValue = 0.1,
        Flag = "FireDelay",
        Callback = function(value)
            ShinroHub.FireDelay = value
        end,
    })

    local QuestTab = Window:CreateTab("Quests", 4483362458)

    QuestTab:CreateSection("Quest Remotes")

    local questRemotes = GetQuestRemotes()

    for i, remote in ipairs(questRemotes) do
        if i > 50 then break end

        QuestTab:CreateButton({
            Name = string.format("[%s] %s", remote.Type, remote.Name),
            Callback = function()
                local sampleArgs = {"giveQuest", "Sample Quest Lvl 1"}
                local code = GenerateRemoteCode(remote, sampleArgs)
                CopyToClipboard(code)

                Rayfield:Notify({
                    Title = "Quest Remote Copied!",
                    Content = remote.Name,
                    Duration = 3,
                })
            end,
        })
    end

    QuestTab:CreateSection("Quest Objects")

    local allQuests = GetAllQuests()

    for i, quest in ipairs(allQuests) do
        if i > 50 then break end

        QuestTab:CreateButton({
            Name = string.format("[%s] %s", quest.Type, quest.Name),
            Callback = function()
                local path = quest.Path
                local code = string.format("local quest = game.%s\nprint(quest)", path)
                CopyToClipboard(code)

                Rayfield:Notify({
                    Title = "Quest Path Copied!",
                    Content = quest.Name,
                    Duration = 3,
                })
            end,
        })
    end

    QuestTab:CreateSection("Custom Quest Fire")

    local QuestRemoteInput = QuestTab:CreateInput({
        Name = "Quest Remote Name",
        PlaceholderText = "e.g. Quests",
        RemoveTextAfterFocusLost = false,
        Callback = function(text) end,
    })

    local QuestNameInput = QuestTab:CreateInput({
        Name = "Quest Name",
        PlaceholderText = "e.g. Boar Boss Quest Lvl 250",
        RemoveTextAfterFocusLost = false,
        Callback = function(text) end,
    })

    local QuestLevelInput = QuestTab:CreateInput({
        Name = "Quest Level (optional)",
        PlaceholderText = "e.g. 250",
        RemoveTextAfterFocusLost = false,
        Callback = function(text) end,
    })

    QuestTab:CreateButton({
        Name = "Generate & Copy Quest Code",
        Callback = function()
            local remoteName = QuestRemoteInput.CurrentValue or "Quests"
            local questName = QuestNameInput.CurrentValue or "Sample Quest"
            local questLevel = QuestLevelInput.CurrentValue or ""

            local fullQuestName = questName
            if questLevel ~= "" then
                fullQuestName = questName .. " Lvl " .. questLevel
            end

            local code = string.format([[
local args = {
    "giveQuest",
    %q
}
game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild(%q):FireServer(unpack(args))
]], fullQuestName, remoteName)

            CopyToClipboard(code)

            Rayfield:Notify({
                Title = "Quest Code Generated!",
                Content = "Copied to clipboard",
                Duration = 3,
            })
        end,
    })

    local FireTab = Window:CreateTab("Fire Remote", 4483362458)

    FireTab:CreateSection("Manual Fire")

    local RemotePathInput = FireTab:CreateInput({
        Name = "Remote Path (e.g. Events.Quests)",
        PlaceholderText = "Events.Quests",
        RemoveTextAfterFocusLost = false,
        Callback = function(text) end,
    })

    local ArgsInput = FireTab:CreateInput({
        Name = "Arguments (JSON format)",
        PlaceholderText = '["giveQuest", "Boar Boss Quest Lvl 250"]',
        RemoveTextAfterFocusLost = false,
        Callback = function(text) end,
    })

    FireTab:CreateButton({
        Name = "Fire Remote",
        Callback = function()
            local path = RemotePathInput.CurrentValue or ""
            local argsStr = ArgsInput.CurrentValue or "[]"

            local success, args = pcall(function()
                return HttpService:JSONDecode(argsStr)
            end)

            if not success then
                args = {}
            end

            local parts = string.split(path, ".")
            local current = ReplicatedStorage

            for _, part in ipairs(parts) do
                if part ~= "" then
                    current = current:FindFirstChild(part)
                    if not current then
                        Rayfield:Notify({
                            Title = "Error",
                            Content = "Remote not found: " .. path,
                            Duration = 3,
                        })
                        return
                    end
                end
            end

            if current:IsA("RemoteEvent") then
                current:FireServer(unpack(args))
                Rayfield:Notify({
                    Title = "Fired!",
                    Content = path .. " | Args: " .. #args,
                    Duration = 2,
                })
            elseif current:IsA("RemoteFunction") then
                local result = current:InvokeServer(unpack(args))
                Rayfield:Notify({
                    Title = "Invoked!",
                    Content = "Result: " .. tostring(result):sub(1, 50),
                    Duration = 2,
                })
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Not a remote: " .. current.ClassName,
                    Duration = 3,
                })
            end
        end,
    })

    FireTab:CreateSection("Quick Templates")

    local templates = {
        {Name = "Quest Template", Code = 'local args = {\n    "giveQuest",\n    "Quest Name Lvl 1"\n}\ngame:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Quests"):FireServer(unpack(args))'},
        {Name = "Give Item", Code = 'local args = {\n    "GiveItem",\n    "ItemName",\n    1\n}\ngame:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Inventory"):FireServer(unpack(args))'},
        {Name = "Teleport", Code = 'local args = {\n    "Teleport",\n    Vector3.new(0, 100, 0)\n}\ngame:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Teleport"):FireServer(unpack(args))'},
        {Name = "Damage", Code = 'local args = {\n    "Damage",\n    100,\n    "EnemyName"\n}\ngame:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Combat"):FireServer(unpack(args))'},
    }

    for _, template in ipairs(templates) do
        FireTab:CreateButton({
            Name = "Copy: " .. template.Name,
            Callback = function()
                CopyToClipboard(template.Code)
                Rayfield:Notify({
                    Title = "Template Copied!",
                    Content = template.Name,
                    Duration = 2,
                })
            end,
        })
    end

    local HistoryTab = Window:CreateTab("History", 4483362458)

    HistoryTab:CreateSection("Recent Fires")

    local function RefreshHistory()
        for _, child in ipairs(HistoryTab:GetChildren()) do
            if child:IsA("UIListLayout") then continue end
            child:Destroy()
        end

        for i, entry in ipairs(ShinroHub.History) do
            if i > 20 then break end

            HistoryTab:CreateButton({
                Name = string.format("[%s] %s", os.date("%H:%M:%S", entry.Time), entry.Remote.Name),
                Callback = function()
                    local code = GenerateRemoteCode(entry.Remote, entry.Args)
                    CopyToClipboard(code)
                    Rayfield:Notify({
                        Title = "History Entry Copied!",
                        Content = entry.Remote.Name,
                        Duration = 2,
                    })
                end,
            })
        end
    end

    HistoryTab:CreateButton({
        Name = "Refresh History",
        Callback = function()
            RefreshHistory()
        end,
    })

    local ScannerTab = Window:CreateTab("Scanner", 4483362458)

    ScannerTab:CreateSection("Remote Scanner")

    ScannerTab:CreateButton({
        Name = "Rescan All Remotes",
        Callback = function()
            local remotes = GetAllRemotes()
            Rayfield:Notify({
                Title = "Scan Complete!",
                Content = "Found " .. #remotes .. " remotes",
                Duration = 3,
            })
        end,
    })

    ScannerTab:CreateButton({
        Name = "Export All Remotes to File",
        Callback = function()
            local remotes = GetAllRemotes()
            local output = "-- Shinro Hub Remote Dump\n-- Game: " .. game.PlaceId .. "\n-- Time: " .. os.date() .. "\n\n"

            for _, remote in ipairs(remotes) do
                output = output .. string.format("-- [%s] %s\n-- Path: game.%s\n\n", remote.Type, remote.Name, remote.Path)
            end

            CopyToClipboard(output)
            Rayfield:Notify({
                Title = "Exported!",
                Content = #remotes .. " remotes copied",
                Duration = 3,
            })
        end,
    })

    ScannerTab:CreateSection("Remote Spy")

    local SpyToggle = ScannerTab:CreateToggle({
        Name = "Enable Remote Spy",
        CurrentValue = false,
        Flag = "RemoteSpy",
        Callback = function(value)
            if value then
                local mt = getrawmetatable(game)
                setreadonly(mt, false)
                local oldNamecall = mt.__namecall

                mt.__namecall = newcclosure(function(self, ...)
                    local method = getnamecallmethod()
                    local args = {...}

                    if method == "FireServer" or method == "InvokeServer" then
                        if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                            local info = {
                                Remote = self.Name,
                                Path = self:GetFullName(),
                                Method = method,
                                Args = args,
                                Time = os.time(),
                            }

                            Rayfield:Notify({
                                Title = "Remote Fired!",
                                Content = self.Name .. " | Args: " .. #args,
                                Duration = 2,
                            })
                        end
                    end

                    return oldNamecall(self, ...)
                end)

                setreadonly(mt, true)

                Rayfield:Notify({
                    Title = "Remote Spy Active!",
                    Content = "Monitoring all remote calls...",
                    Duration = 3,
                })
            end
        end,
    })

    local SettingsTab = Window:CreateTab("Settings", 4483362458)

    SettingsTab:CreateSection("Configuration")

    SettingsTab:CreateSlider({
        Name = "Max History Entries",
        Range = {10, 200},
        Increment = 10,
        CurrentValue = 50,
        Flag = "MaxHistory",
        Callback = function(value)
            ShinroHub.MaxHistory = value
        end,
    })

    SettingsTab:CreateButton({
        Name = "Clear History",
        Callback = function()
            ShinroHub.History = {}
            Rayfield:Notify({
                Title = "History Cleared!",
                Content = "All entries removed",
                Duration = 2,
            })
        end,
    })

    SettingsTab:CreateButton({
        Name = "Destroy UI",
        Callback = function()
            Rayfield:Destroy()
        end,
    })

    Rayfield:Notify({
        Title = "Shinro Hub Loaded!",
        Content = "v" .. ShinroHub.Version .. " | " .. EXECUTOR .. " | " .. #allRemotes .. " remotes found",
        Duration = 5,
    })

    return Window
end

local function CreateFallbackUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ShinroHub_Fallback"
    ScreenGui.Parent = game.CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = ScreenGui
    MainFrame.Size = UDim2.new(0, 400, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MainFrame.BorderSizePixel = 0

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Parent = MainFrame
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Title.Text = "Shinro Hub v" .. ShinroHub.Version .. " | " .. EXECUTOR
    Title.TextColor3 = Color3.fromRGB(0, 170, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Parent = MainFrame
    Scroll.Size = UDim2.new(1, -20, 1, -60)
    Scroll.Position = UDim2.new(0, 10, 0, 50)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 4

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = Scroll
    Layout.Padding = UDim.new(0, 5)

    local remotes = GetAllRemotes()

    for i, remote in ipairs(remotes) do
        if i > 50 then break end

        local btn = Instance.new("TextButton")
        btn.Parent = Scroll
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        btn.Text = string.format("[%s] %s", remote.Type, remote.Name)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            local code = GenerateRemoteCode(remote, {})
            CopyToClipboard(code)

            game.StarterGui:SetCore("SendNotification", {
                Title = "Copied!",
                Text = remote.Name,
                Duration = 2,
            })
        end)
    end

    return ScreenGui
end

local success, result = pcall(CreateRayfieldUI)
if not success then
    warn("[ShinroHub] Error: " .. tostring(result))
    CreateFallbackUI()
end
