getgenv().Config = {
    CameraLock = {
        Toggled = false,
        Smoothness = 0.1,
        DefaultPrediction = 0.15,
        AutoPrediction = true,
        TargetPart = "HumanoidRootPart"
    },
    Settings = {
        Keybind = Enum.KeyCode.Q
    },
    PredictionTable = {
        [30] = 0.12, [40] = 0.125, [50] = 0.13, [60] = 0.135, [70] = 0.14,
        [80] = 0.145, [90] = 0.15, [100] = 0.155, [110] = 0.16, [120] = 0.165,
        [130] = 0.17, [140] = 0.175
    }
}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local CurrentTarget = nil

--// Notification Function
local function Notify(title, text)
     StarterGui:SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = 2;
    })
end

--// UI Setup
local screenGui = Instance.new("ScreenGui", game.CoreGui)
local button = Instance.new("TextButton", screenGui)
local ui = Instance.new("UICorner", button)

button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0, 10, 0, 10)
button.Font = Enum.Font.GothamBlack
button.TextScaled = true
button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
button.Active = true
button.Draggable = true

ui.CornerRadius = UDim.new(0, 5)

--// Logic for Toggling (Shared between Keybind and Button)
local function ToggleLock()
    getgenv().Config.CameraLock.Toggled = not getgenv().Config.CameraLock.Toggled
    
    if getgenv().Config.CameraLock.Toggled then
        local target = getClosestPlayer()
        if target then
            Notify("Targeting", target.DisplayName)
        else
            Notify("ProjectBanana", "No target found nearby")
        end
    else
        if CurrentTarget then
            Notify("Untargeting", CurrentTarget.Name .. " (Bozo)")
        end
    end
end

--// Button Click Connection
button.MouseButton1Click:Connect(function()
    ToggleLock()
end)

-- Rainbow Logic
local hue = 0
RunService.RenderStepped:Connect(function(dt)
    hue = (hue + dt * 0.2) % 1
    button.TextColor3 = Color3.fromHSV(hue, 0.8, 0.8)
    button.Text = "ProjectBanana | " .. (getgenv().Config.CameraLock.Toggled and "ON" or "OFF")
end)

function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    for _, player in pairs(Players:GetPlayers()) do
        local targetPart = getgenv().Config.CameraLock.TargetPart
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(targetPart) then
            local targetPos = player.Character[targetPart].Position
            local distance = (myPos - targetPos).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                closestPlayer = player
            end
        end
    end
    return closestPlayer
end

local function getAutoPrediction()
    local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    local closestPing = 30
    local minDiff = math.huge
    for p, val in pairs(getgenv().Config.PredictionTable) do
        local diff = math.abs(ping - p)
        if diff < minDiff then
            minDiff = diff
            closestPing = p
        end
    end
    return getgenv().Config.PredictionTable[closestPing]
end

--// Main Camera Logic
RunService.RenderStepped:Connect(function()
    if not getgenv().Config.CameraLock.Toggled then 
        CurrentTarget = nil 
        return 
    end

    local target = getClosestPlayer()
    local targetPartName = getgenv().Config.CameraLock.TargetPart
    
    if target and target.Character and target.Character:FindFirstChild(targetPartName) then
        CurrentTarget = target 
        local part = target.Character[targetPartName]
        local predValue = getAutoPrediction()
        
        local predictedPosition = part.Position + (part.Velocity * predValue)
        local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, getgenv().Config.CameraLock.Smoothness)
    end
end)

--// Keybind Connection
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end 
    if input.KeyCode == getgenv().Config.Settings.Keybind then
        ToggleLock()
    end
end)

Notify("ProjectBanana", "Initialized")
