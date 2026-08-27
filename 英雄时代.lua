local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Window = WindUI:CreateWindow({
    Title = "XJW",
    Icon = "sparkles",
    Author = "英雄时代",
    Folder = "XJW_HeroAge",
    Size = UDim2.fromOffset(400, 520),
    Theme = "Pink",
    HideSearchBar = false,
})

-- 时间标签
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

-- ==================== 反作弊绕过 ====================
pcall(function()
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ==================== 配置 ====================
local ATTACK_SPEED = 0.15
local constantAttackEnabled = false
local playerEspEnabled = false
local policeEspEnabled = false
local civilianEspEnabled = false
local thugEspEnabled = false
local civilianLoopEnabled = false
local policeLoopEnabled = false
local thugLoopEnabled = false
local currentPolice = nil
local currentCivilian = nil
local currentThug = nil

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

-- ==================== 传送到敌人背后 ====================
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

-- ==================== 人物模型锁定到目标背后 ====================
local function lockCharacterBehind(targetRoot)
    if not targetRoot then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end
    local direction = (targetRoot.Position - root.Position).Unit
    root.CFrame = CFrame.new(root.Position, root.Position + direction)
end

-- ==================== 平民传送（路径：workspace:GetChildren()[71]） ====================
local function teleportCivilian()
    local children = Workspace:GetChildren()
    if #children >= 71 then
        local target = children[71]
        if target then
            local root = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
            if root then
                teleportToPart(root)
                return true
            end
        end
    end
    return false
end

-- ==================== 警察传送 ====================
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

-- ==================== 暴徒传送（路径：workspace:GetChildren()[82]） ====================
local function teleportThug()
    local children = Workspace:GetChildren()
    if #children >= 82 then
        local target = children[82]
        if target then
            local root = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
            if root then
                teleportToPart(root)
                return true
            end
        end
    end
    return false
end

-- ==================== 获取所有平民（用于循环传送和透视） ====================
local function getAllCivilians()
    local list = {}
    for _, v in ipairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v.Name == "Civilian" then
            table.insert(list, v)
        end
    end
    return list
end

-- ==================== 获取所有暴徒（用于循环传送和透视） ====================
local function getAllThugs()
    local list = {}
    for _, v in ipairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v.Name == "Thug" then
            table.insert(list, v)
        end
    end
    return list
end

-- ==================== 获取最近的警察（锁定机制） ====================
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

-- ==================== 获取最近的平民（锁定机制） ====================
local function GetNearestCivilian()
    if currentCivilian and currentCivilian.Parent then
        local hum = currentCivilian:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            return currentCivilian
        end
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearest = nil
    local nearestDist = math.huge

    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and child.Name == "Civilian" then
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

    currentCivilian = nearest
    return nearest
end

-- ==================== 获取最近的暴徒（锁定机制） ====================
local function GetNearestThug()
    if currentThug and currentThug.Parent then
        local hum = currentThug:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            return currentThug
        end
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearest = nil
    local nearestDist = math.huge

    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and child.Name == "Thug" then
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

    currentThug = nearest
    return nearest
end

-- ==================== 警察循环传送 ====================
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

-- ==================== 平民循环传送 ====================
local function startCivilianLoop()
    if civilianLoopEnabled then return end
    civilianLoopEnabled = true
    currentCivilian = nil

    task.spawn(function()
        while civilianLoopEnabled do
            local target = GetNearestCivilian()
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

local function stopCivilianLoop()
    civilianLoopEnabled = false
    currentCivilian = nil
end

-- ==================== 暴徒循环传送 ====================
local function startThugLoop()
    if thugLoopEnabled then return end
    thugLoopEnabled = true
    currentThug = nil

    task.spawn(function()
        while thugLoopEnabled do
            local target = GetNearestThug()
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

local function stopThugLoop()
    thugLoopEnabled = false
    currentThug = nil
end

-- ==================== 一直攻击（不管有没有敌人） ====================
local attackTimer = 0
local burstCounter = 0
local burstTimer = 0

local function sendPunch()
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    -- 爆发攻击模式（防检测）
    if tick() - burstTimer > 0.8 then
        burstCounter = 0
    end

    if burstCounter >= 2 then
        return
    end

    -- 随机延迟（防检测）
    if tick() - attackTimer < ATTACK_SPEED + math.random() * 0.05 then
        return
    end

    -- 执行攻击
    ReplicatedStorage:WaitForChild("Events"):WaitForChild("Punch"):FireServer(0, 0.1, 1)

    attackTimer = tick()
    burstCounter = burstCounter + 1
    if burstCounter >= 2 then
        burstTimer = tick()
    end
end

local function startConstantAttack()
    if constantAttackEnabled then return end
    constantAttackEnabled = true
    attackTimer = 0
    burstCounter = 0
    burstTimer = 0

    task.spawn(function()
        while constantAttackEnabled do
            pcall(sendPunch)
            task.wait(0.05)
        end
    end)
end

local function stopConstantAttack()
    constantAttackEnabled = false
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

-- ==================== 平民透视 ====================
local civilianEspObjects = {}

local function createCivilianEsp(civilian)
    if civilianEspObjects[civilian] then return end
    local root = civilian:FindFirstChild("HumanoidRootPart") or civilian:FindFirstChild("Torso") or civilian:FindFirstChild("UpperTorso")
    if not root then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(0, 255, 100)
    box.Thickness = 2
    box.Filled = false
    box.Transparency = 0.5

    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(0, 255, 100)
    line.Thickness = 1.5

    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Color = Color3.fromRGB(0, 255, 100)
    nameText.Size = 14
    nameText.Font = Drawing.Fonts.Monospace
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0)
    nameText.Center = true

    civilianEspObjects[civilian] = {box = box, line = line, name = nameText}
end

local function updateCivilianEsp()
    for civilian, obj in pairs(civilianEspObjects) do
        if not civilian.Parent then
            obj.box:Remove()
            obj.line:Remove()
            obj.name:Remove()
            civilianEspObjects[civilian] = nil
        end
    end

    if not civilianEspEnabled then
        for _, obj in pairs(civilianEspObjects) do
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
        if child:IsA("Model") and child.Name == "Civilian" then
            if not civilianEspObjects[child] then createCivilianEsp(child) end
            local obj = civilianEspObjects[child]
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
                        obj.name.Text = "平民 [" .. math.floor(dist) .. "m]"
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

-- ==================== 暴徒透视 ====================
local thugEspObjects = {}

local function createThugEsp(thug)
    if thugEspObjects[thug] then return end
    local root = thug:FindFirstChild("HumanoidRootPart") or thug:FindFirstChild("Torso") or thug:FindFirstChild("UpperTorso")
    if not root then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 150, 0)
    box.Thickness = 2
    box.Filled = false
    box.Transparency = 0.5

    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(255, 150, 0)
    line.Thickness = 1.5

    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Color = Color3.fromRGB(255, 150, 0)
    nameText.Size = 14
    nameText.Font = Drawing.Fonts.Monospace
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0)
    nameText.Center = true

    thugEspObjects[thug] = {box = box, line = line, name = nameText}
end

local function updateThugEsp()
    for thug, obj in pairs(thugEspObjects) do
        if not thug.Parent then
            obj.box:Remove()
            obj.line:Remove()
            obj.name:Remove()
            thugEspObjects[thug] = nil
        end
    end

    if not thugEspEnabled then
        for _, obj in pairs(thugEspObjects) do
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
        if child:IsA("Model") and child.Name == "Thug" then
            if not thugEspObjects[child] then createThugEsp(child) end
            local obj = thugEspObjects[child]
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
                        obj.name.Text = "暴徒 [" .. math.floor(dist) .. "m]"
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
    updateCivilianEsp()
    updateThugEsp()
end)

-- ==================== UI ====================
local Tab = Window:Tab({
    Title = "功能",
    Icon = "settings",
    Locked = false,
})

-- ==================== 传送部分 ====================
Tab:Section({Title = "传送", TextXAlignment = "Left", TextSize = 17})

Tab:Button({
    Title = "传送 城市安全区",
    Callback = function()
        teleportTo(CITY_SAFEZONE)
        WindUI:Notify({Title = "传送成功", Content = "已传送到城市安全区", Duration = 2})
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
    Title = "传送 暴徒",
    Callback = function()
        if teleportThug() then
            WindUI:Notify({Title = "传送成功", Content = "已传送到暴徒", Duration = 2})
        else
            WindUI:Notify({Title = "传送失败", Content = "未找到暴徒", Duration = 2})
        end
    end
})

-- ==================== 循环传送部分 ====================
Tab:Section({Title = "循环传送（背后+锁定）", TextXAlignment = "Left", TextSize = 17})

Tab:Toggle({
    Title = "循环传送 警察",
    Default = false,
    Callback = function(v)
        if v then startPoliceLoop() else stopPoliceLoop() end
    end
})

Tab:Toggle({
    Title = "循环传送 平民",
    Default = false,
    Callback = function(v)
        if v then startCivilianLoop() else stopCivilianLoop() end
    end
})

Tab:Toggle({
    Title = "循环传送 暴徒",
    Default = false,
    Callback = function(v)
        if v then startThugLoop() else stopThugLoop() end
    end
})

-- ==================== 透视部分 ====================
Tab:Section({Title = "透视", TextXAlignment = "Left", TextSize = 17})

Tab:Toggle({
    Title = "警察透视（蓝色）",
    Default = false,
    Callback = function(v) policeEspEnabled = v end
})

Tab:Toggle({
    Title = "平民透视（绿色）",
    Default = false,
    Callback = function(v) civilianEspEnabled = v end
})

Tab:Toggle({
    Title = "暴徒透视（橙色）",
    Default = false,
    Callback = function(v) thugEspEnabled = v end
})

-- ==================== 一直攻击部分 ====================
Tab:Section({Title = "一直攻击", TextXAlignment = "Left", TextSize = 17})

Tab:Toggle({
    Title = "一直攻击（不管有没有敌人）",
    Default = false,
    Callback = function(v)
        if v then startConstantAttack() else stopConstantAttack() end
    end
})

Tab:Input({
    Title = "攻击速度(秒) 建议0.15-0.3",
    Placeholder = "0.15",
    Callback = function(val)
        local num = tonumber(val)
        if num and num > 0 then
            ATTACK_SPEED = num
        end
    end
})