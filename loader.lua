local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local fruitValues = {
    ["Dragon"] = 6000, ["Leopard"] = 5800, ["Kitsune"] = 5500, ["Spirit"] = 5000,
    ["Dough"] = 4500, ["Blizzard"] = 4200, ["Venom"] = 4000, ["Shadow"] = 3800,
    ["Portal"] = 3600, ["Buddha"] = 3400, ["Rumble"] = 3200, ["Phoenix"] = 3000,
    ["Magma"] = 2800, ["Light"] = 2600, ["Flame"] = 2400, ["Love"] = 2200,
    ["Barrier"] = 2000, ["Dark"] = 1800, ["Diamond"] = 1600, ["Rubber"] = 1400,
    ["Ghost"] = 1200, ["Ice"] = 1000, ["Sand"] = 800, ["Smoke"] = 600,
    ["Bomb"] = 400, ["Spike"] = 200, ["Yeti"] = 7600, ["Gas"] = 3900, ["Gravity"] = 5500
}

local fruitList = {}
for fruitName, _ in pairs(fruitValues) do
    table.insert(fruitList, fruitName)
end
table.sort(fruitList)

local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
ScreenGui.Name = "TradeHelper"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 500)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BackgroundTransparency = 0.2
MainFrame.Visible = false

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", MainFrame).Thickness = 2

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Меню"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24

local function createButton(text, posX)
    local button = Instance.new("TextButton", MainFrame)
    button.Size = UDim2.new(0, 90, 0, 30)
    button.Position = UDim2.new(0, posX, 0, 45)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    return button
end

local TradeButton = createButton("Трейд", 10)
local FarmButton = createButton("Фарм", 105)
local StockButton = createButton("Сток", 200)

local function createTab()
    local tab = Instance.new("ScrollingFrame", MainFrame)
    tab.Size = UDim2.new(1, -20, 1, -90)
    tab.Position = UDim2.new(0, 10, 0, 80)
    tab.BackgroundTransparency = 1
    tab.ScrollBarThickness = 4
    tab.Visible = false
    return tab
end

local TradeTab = createTab()
local UIListLayout = Instance.new("UIListLayout", TradeTab)
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

for _, fruitName in ipairs(fruitList) do
    local FruitButton = Instance.new("TextButton", TradeTab)
    FruitButton.Size = UDim2.new(1, 0, 0, 35)
    FruitButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    FruitButton.Text = fruitName .. " (" .. fruitValues[fruitName] .. ")"
    FruitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    FruitButton.Font = Enum.Font.Gotham
    FruitButton.TextSize = 16
    Instance.new("UICorner", FruitButton).CornerRadius = UDim.new(0, 8)

    FruitButton.MouseButton1Click:Connect(function()
        print("Вы выбрали фрукт: " .. fruitName)
    end)
end

local FarmTab = createTab()
local StockTab = createTab()

local AutoFarm = false
local AutoFarmButton = Instance.new("TextButton", FarmTab)
AutoFarmButton.Size = UDim2.new(0, 220, 0, 50)
AutoFarmButton.Position = UDim2.new(0.5, -110, 0, 10)
AutoFarmButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AutoFarmButton.Text = "АвтоФарм: Выкл"
AutoFarmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoFarmButton.Font = Enum.Font.GothamBold
AutoFarmButton.TextSize = 20

AutoFarmButton.MouseButton1Click:Connect(function()
    AutoFarm = not AutoFarm
    AutoFarmButton.Text = AutoFarm and "АвтоФарм: Вкл" or "АвтоФарм: Выкл"
    if AutoFarm then
        task.spawn(function()
            while AutoFarm do
                for _, v in pairs(workspace:GetChildren()) do
                    if v:IsA("Tool") and fruitValues[v.Name] then
                        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        local handle = v:FindFirstChild("Handle") or v:FindFirstChildOfClass("Part")
                        if root and handle then
                            root.CFrame = handle.CFrame
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end
end)

local AutoQuest = false
local AutoQuestButton = Instance.new("TextButton", FarmTab)
AutoQuestButton.Size = UDim2.new(0, 220, 0, 50)
AutoQuestButton.Position = UDim2.new(0.5, -110, 0, 80)
AutoQuestButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AutoQuestButton.Text = "АвтоКвест: Выкл"
AutoQuestButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoQuestButton.Font = Enum.Font.GothamBold
AutoQuestButton.TextSize = 20

AutoQuestButton.MouseButton1Click:Connect(function()
    AutoQuest = not AutoQuest
    AutoQuestButton.Text = AutoQuest and "АвтоКвест: Вкл" or "АвтоКвест: Выкл"
    if AutoQuest then
        task.spawn(function()
            while AutoQuest do
                pcall(function()
                    local quest = workspace:FindFirstChild("Quests")
                    if quest then
                        for _, q in pairs(quest:GetChildren()) do
                            if q:IsA("Model") then
                                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                                if root then
                                    root.CFrame = q.PrimaryPart.CFrame
                                    wait(1)
                                    fireclickdetector(q:FindFirstChildOfClass("ClickDetector"))
                                end
                            end
                        end
                    end
                end)
                task.wait(5)
            end
        end)
    end
end)

-- НОВОЕ: Авто сундуки
local AutoChest = false
local AutoChestButton = Instance.new("TextButton", FarmTab)
AutoChestButton.Size = UDim2.new(0, 220, 0, 50)
AutoChestButton.Position = UDim2.new(0.5, -110, 0, 150)
AutoChestButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AutoChestButton.Text = "АвтоСундуки: Выкл"
AutoChestButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoChestButton.Font = Enum.Font.GothamBold
AutoChestButton.TextSize = 20

local function TweenToPosition(position)
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local root = character.HumanoidRootPart
        local tweenInfo = TweenInfo.new(
            (root.Position - position).Magnitude / 100,
            Enum.EasingStyle.Linear
        )
        local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(position)})
        tween:Play()
        tween.Completed:Wait()
    end
end

AutoChestButton.MouseButton1Click:Connect(function()
    AutoChest = not AutoChest
    AutoChestButton.Text = AutoChest and "АвтоСундуки: Вкл" or "АвтоСундуки: Выкл"
    if AutoChest then
        task.spawn(function()
            while AutoChest do
                for _, chest in pairs(workspace:GetDescendants()) do
                    if chest:IsA("Model") and chest.Name:lower():find("chest") and chest:FindFirstChild("TouchInterest") then
                        local touchPart = chest:FindFirstChildWhichIsA("BasePart")
                        if touchPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            TweenToPosition(touchPart.Position + Vector3.new(0, 3, 0))
                            task.wait(0.5)
                        end
                    end
                end
                task.wait(2)
            end
        end)
    end
end)

-- Продолжение твоего кода (сток, флай и т.д.)
-- ...
