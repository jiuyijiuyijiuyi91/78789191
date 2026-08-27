local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")

local Window = WindUI:CreateWindow({
    Title = "XJW",
    Icon = "sparkles",
    Author = "英雄时代",
    Folder = "XJW_HeroAge",
    Size = UDim2.fromOffset(400, 520),
    Theme = "Pink",
    HideSearchBar = false,
})

local TimeTag = Window:Tag({
    Title = "00:00",
    Color = Color3.fromRGB(255, 255, 255)
})

local hue = 0
task.spawn(function()
    while true do
        local now = os.date("*t")
        local hours = string.format("%02d", now.hour)
        local minutes = string.format("%02d", now.min)
        hue = (hue + 0.01) % 1
        local rainbowColor = Color3.fromHSV(hue, 1, 1)
        TimeTag:SetTitle(hours .. ":" .. minutes)
        TimeTag:SetColor(rainbowColor)
        task.wait(0.06)
    end
end)

Window:Tag({
    Title = "XJW",
    Color = Color3.fromHex("#7FDBFF")
})

Window:EditOpenButton({
    Title = "XJW",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF6B6B")),
    Draggable = true,
})

-- ==================== 行为伪装反检测（不hook任何东西） ====================
-- 1. 防挂机（最安全）
pcall(function()
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- 2. 模拟鼠标微动（让服务器以为你在操作）
pcall(function()
    task.spawn(function()
        while true do
            if autoAttackEnabled or policeLoopEnabled then
                pcall(function()
                    UIS.MouseBehavior = Enum.MouseBehavior.Default
                end)
            end
            task.wait(math.random(5, 15))
        end
    end)
end)

-- 3. 模拟随机按键（让服务器以为你是真人）
pcall(function()
    local keys = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D}
    task.spawn(function()
        while true do
            if autoAttackEnabled or policeLoopEnabled then
                local key = keys[math.random(#keys)]
                pcall(function()
                    UIS:SetKeyDown(key)
                    task.wait(0.05 + math.random() * 0.1)
                    UIS:SetKeyUp(key)
                end)
            end
            task.wait(math.random(8, 25))
        end
    end)
end)

-- 4. 定期随机小停顿（更像真人）
pcall(function()
    task.spawn(function()
        while true do
            task.wait(math.random(30, 90))
            if autoAttackEnabled then
                pcall(function()
                    task.wait(math.random(1, 3))
                end)
            end
        end
    end)
end)

print("[行为伪装] 已加载（无hook，安全）")

-- ==================== 配置 ====================
local ATTACK_SPEED = 0.28
local ATTACK_RANDOM_DELAY = 0.06
local ATTACK_BURST_COUNT = 2
local ATTACK_BURST_WAIT = 1.2
local autoAttackEnabled = false
local playerEspEnabled = false
local policeEspEnabled = false
local civilianLoopEnabled = false
local policeLoopEnabled = false
local currentPolice = nil
local attackTimer = 0
local burstCounter = 0
local burstTimer = 0

-- ==================== 传送基础函数 ====================
local CITY_SAFEZONE = Vector3.new(-242.419418, 94.108253, 99.990486)

local function teleportTo(position)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if root then
        root.CFrame = CFrame.new(position)
    end
end

local function teleportToPart(part)
    if not part then return end
    teleportTo(part.Position)
end

local function teleportBehind(part)
    if not part then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end
    local enemyCF = part.CFrame
    local behindPos = enemyCF.Position - enemyCF.LookVector * 3
    behindPos = behindPos + Vector3.new(0, 0.5, 0)
    root.CFrame = CFrame.new(behindPos)
end

local function lockCharacterBehind(targetRoot)
    if not targetRoot then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end
    local direction = (targetRoot.Position - root.Position).Unit
    root.CFrame = CFrame.new(root.Position, root.Position + direction)
end

local function teleportCivilian()
    local civilian = Workspace:FindFirstChild("Civilian")
    if not civilian then return false end
    local root = civilian:FindFirstChild("HumanoidRootPart") or civilian:FindFirstChild("Torso") or civilian:FindFirstChild("UpperTorso")
    if root then
        teleportToPart(root)
        return true
    end
    return false
end

local function teleportPolice()
    local police = Workspace:FindFirstChild("Police")
    if not police then return false end
    local root = police:FindFirstChild("HumanoidRootPart") or police:FindFirstChild("Torso") or police:FindFirstChild("UpperTorso")
    if root then
        teleportToPart(root)
        return true
    end
    return false
end

local function GetNearestPolice()
    if currentPolice and currentPolice.Parent then
        local hum = currentPolice:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            return currentPolice
        end
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearest = nil
    local nearestDist = math.huge

    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and child.Name == "Police" then
            local hum = child:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local npcRoot = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso")
                if npcRoot then
                    local dist = (npcRoot.Position - root.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = child
                    end
                end
            end
        end
    end

    currentPolice = nearest
    return nearest
end

local function startPoliceLoop()
    if policeLoopEnabled then return end
    policeLoopEnabled = true
    currentPolice = nil

    task.spawn(function()
        while policeLoopEnabled do
            local target = GetNearestPolice()
            if target then
                local part = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
                if part then
                    teleportBehind(part)
                    lockCharacterBehind(part)
                end
            end
            task.wait(0.02)
        end
    end)
end

local function stopPoliceLoop()
    policeLoopEnabled = false
    currentPolice = nil
end

local function startCivilianLoop()
    if civilianLoopEnabled then return end
    civilianLoopEnabled = true
    task.spawn(function()
        while civilianLoopEnabled do
            local civilian = Workspace:FindFirstChild("Civilian")
            if civilian then
                local root = civilian:FindFirstChild("HumanoidRootPart") or civilian:FindFirstChild("Torso") or civilian:FindFirstChild("UpperTorso")
                if root then teleportToPart(root) end
            end
            task.wait(0.8)
        end
    end)
end

local function stopCivilianLoop()
    civilianLoopEnabled = false
end

local function sendPunch()
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local target = GetNearestPolice()
    if not target then return end

    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end

    local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
    if not targetRoot then return end

    local dist = (targetRoot.Position - root.Position).Magnitude
    if dist > 12 then return end

    if tick() - burstTimer > ATTACK_BURST_WAIT then burstCounter = 0 end
    if burstCounter >= ATTACK_BURST_COUNT then return end

    local randomDelay = math.random() * ATTACK_RANDOM_DELAY
    if tick() - attackTimer < ATTACK_SPEED + randomDelay then return end

    ReplicatedStorage:WaitForChild("Events"):WaitForChild("Punch"):FireServer(0, 0.1, 1)

    attackTimer = tick()
    burstCounter = burstCounter + 1
    if burstCounter >= ATTACK_BURST_COUNT then burstTimer = tick() end
end

local function startAutoAttack()
    if autoAttackEnabled then return end
    autoAttackEnabled = true
    attackTimer = 0
    burstCounter = 0
    burstTimer = 0

    task.spawn(function()
        while autoAttackEnabled do
            pcall(sendPunch)
            task.wait(0.05)
        end
    end)
end

local function stopAutoAttack()
    autoAttackEnabled = false
end

-- ==================== 警察透视 ====================
local policeEspObjects = {}

local function createPoliceEsp(police)
    if policeEspObjects[police] then return end
    local root = police:FindFirstChild("HumanoidRootPart") or police:FindFirstChild("Torso") or police:FindFirstChild("UpperTorso")
    if not root then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(0, 100, 255)
    box.Thickness = 2
    box.Filled = false
    box.Transparency = 0.5

    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(0, 100, 255)
    line.Thickness = 1.5

    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Color = Color3.fromRGB(0, 100, 255)
    nameText.Size = 14
    nameText.Font = Drawing.Fonts.Monospace
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0)
    nameText.Center = true

    policeEspObjects[police] = {box = box, line = line, name = nameText}
end

local function updatePoliceEsp()
    for police, obj in pairs(policeEspObjects) do
        if not police.Parent then
            obj.box:Remove()
            obj.line:Remove()
            obj.name:Remove()
            policeEspObjects[police] = nil
        end
    end

    if not policeEspEnabled then
        for _, obj in pairs(policeEspObjects) do
            obj.box.Visible = false
            obj.line.Visible = false
            obj.name.Visible = false
        end
        return
    end

    local char = LocalPlayer.Character
    local charRoot = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if not charRoot then return end

    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and child.Name == "Police" then
            if not policeEspObjects[child] then createPoliceEsp(child) end

            local obj = policeEspObjects[child]
            if obj then
                local root = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChild("Torso") or child:FindFirstChild("UpperTorso")
                if root then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    local dist = (root.Position - charRoot.Position).Magnitude

                    if onScreen then
                        local size = 60 / pos.Z
                        obj.box.Size = Vector2.new(size * 1.5, size * 2.5)
                        obj.box.Position = Vector2.new(pos.X - obj.box.Size.X / 2, pos.Y - obj.box.Size.Y / 2)
                        obj.box.Visible = true
                        obj.name.Text = "警察 [" .. math.floor(dist) .. "m]"
                        obj.name.Position = Vector2.new(pos.X, pos.Y - obj.box.Size.Y / 2 - 15)
                        obj.name.Visible = true
                        obj.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        obj.line.To = Vector2.new(pos.X, pos.Y)
                        obj.line.Visible = true
                    else
                        obj.box.Visible = false
                        obj.name.Visible = false
                        obj.line.Visible = false
                    end
                else
                    obj.box.Visible = false
                    obj.name.Visible = false
                    obj.line.Visible = false
                end
            end
        end
    end
end

-- ==================== 玩家透视 ====================
local playerEspObjects = {}

local function createPlayerEsp(player)
    if playerEspObjects[player] or player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Thickness = 2
    box.Filled = true
    box.Transparency = 0.3
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(255, 0, 0)
    line.Thickness = 1.5
    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Color = Color3.fromRGB(255, 0, 0)
    nameText.Size = 14
    nameText.Font = Drawing.Fonts.Monospace
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0)
    nameText.Center = true
    playerEspObjects[player] = {box = box, line = line, name = nameText}
end

local function updatePlayerEsp()
    for player, obj in pairs(playerEspObjects) do
        if not Players:FindFirstChild(player.Name) then
            obj.box:Remove()
            obj.line:Remove()
            obj.name:Remove()
            playerEspObjects[player] = nil
        end
    end

    if not playerEspEnabled then
        for _, obj in pairs(playerEspObjects) do
            obj.box.Visible = false
            obj.line.Visible = false
            obj.name.Visible = false
        end
        return
    end

    local char = LocalPlayer.Character
    local charRoot = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if not charRoot then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not playerEspObjects[player] then createPlayerEsp(player) end
            local obj = playerEspObjects[player]
            if obj then
                local targetChar = player.Character
                local root = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso"))
                if root and charRoot then
                    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    local dist = (root.Position - charRoot.Position).Magnitude

                    if onScreen then
                        local size = 60 / pos.Z
                        obj.box.Size = Vector2.new(size * 1.5, size * 2.5)
                        obj.box.Position = Vector2.new(pos.X - obj.box.Size.X / 2, pos.Y - obj.box.Size.Y / 2)
                        obj.box.Visible = true
                        obj.name.Text = player.Name .. " [" .. math.floor(dist) .. "m]"
                        obj.name.Position = Vector2.new(pos.X, pos.Y - obj.box.Size.Y / 2 - 15)
                        obj.name.Visible = true
                        obj.line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        obj.line.To = Vector2.new(pos.X, pos.Y)
                        obj.line.Visible = true
                    else
                        obj.box.Visible = false
                        obj.name.Visible = false
                        obj.line.Visible = false
                    end
                else
                    obj.box.Visible = false
                    obj.name.Visible = false
                    obj.line.Visible = false
                end
            end
        end
    end
end

-- ==================== 渲染循环 ====================
RunService.RenderStepped:Connect(function()
    updatePoliceEsp()
    updatePlayerEsp()
end)

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then createPlayerEsp(player) end
end)

-- ==================== UI ====================
local Tab = Window:Tab({
    Title = "功能",
    Icon = "settings",
    Locked = false,
})

Tab:Section({Title = "传送", TextXAlignment = "Left", TextSize = 17})

Tab:Button({
    Title = "传送 城市安全区",
    Callback = function()
        teleportTo(CITY_SAFEZONE)
        WindUI:Notify({Title = "传送成功", Content = "已传送到城市安全区", Duration = 2})
    end
})

Tab:Button({
    Title = "传送 平民",
    Callback = function()
        if teleportCivilian() then
            WindUI:Notify({Title = "传送成功", Content = "已传送到平民", Duration = 2})
        else
            WindUI:Notify({Title = "传送失败", Content = "未找到平民", Duration = 2})
        end
    end
})

Tab:Button({
    Title = "传送 警察",
    Callback = function()
        if teleportPolice() then
            WindUI:Notify({Title = "传送成功", Content = "已传送到警察", Duration = 2})
        else
            WindUI:Notify({Title = "传送失败", Content = "未找到警察", Duration = 2})
        end
    end
})

Tab:Section({Title = "循环传送", TextXAlignment = "Left", TextSize = 17})

Tab:Toggle({
    Title = "循环传送 平民",
    Default = false,
    Callback = function(v)
        if v then startCivilianLoop() else stopCivilianLoop() end
    end
})

Tab:Toggle({
    Title = "循环传送 警察（背后+锁定）",
    Default = false,
    Callback = function(v)
        if v then startPoliceLoop() else stopPoliceLoop() end
    end
})

Tab:Section({Title = "透视", TextXAlignment = "Left", TextSize = 17})

Tab:Toggle({
    Title = "警察透视（蓝色）",
    Default = false,
    Callback = function(v) policeEspEnabled = v end
})

Tab:Toggle({
    Title = "玩家透视（饱满红色）",
    Default = false,
    Callback = function(v) playerEspEnabled = v end
})

Tab:Section({Title = "自动攻击", TextXAlignment = "Left", TextSize = 17})

Tab:Toggle({
    Title = "自动攻击（防检测版）",
    Default = false,
    Callback = function(v)
        if v then startAutoAttack() else stopAutoAttack() end
    end
})

Tab:Input({
    Title = "攻击速度(秒) 建议0.25-0.35",
    Placeholder = "0.28",
    Callback = function(val)
        local num = tonumber(val)
        if num and num > 0 then
            ATTACK_SPEED = num
        end
    end
})