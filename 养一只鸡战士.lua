--养大一只鸡战士功能面板
--脚本作者b站UID:647396778
--XJW整合版

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 全局总开关
local globalRunning = true
local loopChallengeRunning = false
local panelVisible = false
local suspendTowerLoops = false
local detectTriggerCount = 0
local triggerCooldown = 0
local towerKeywordCooldown = 21
local retreatChaosCooldown = 0

local autoAfk = false
local rangeLimit = 16.66
local spawnPosition = nil

local autoScrapRunning = false
local reachRange = 5.5
local targetScrapPos = nil
local collectedCount = 0
local selectNum = 1
local recycleDestination

local threadPool = {}

-- ========== UI 创建 ==========
local CoreGui = game:GetService("CoreGui")
pcall(function()
    if CoreGui:FindFirstChild("ChickenWarriorUI") then
        CoreGui.ChickenWarriorUI:Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChickenWarriorUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- 拖拽函数
local function drag(frame, hold)
    hold = hold or frame
    local dragging, dragInput, dragStart, startPos = false
    hold.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, input.Position, frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- 菜单按钮
local MainButton = Instance.new("TextButton")
MainButton.Size = UDim2.new(0, 160, 0, 44)
MainButton.Position = UDim2.new(0.05, 0, 0.3, 0)
MainButton.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
MainButton.BorderColor3 = Color3.fromRGB(80, 120, 200)
MainButton.BorderSizePixel = 2
MainButton.Text = "养大一只鸡战士"
MainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MainButton.Font = Enum.Font.SourceSansBold
MainButton.TextSize = 14
MainButton.Parent = ScreenGui
Instance.new("UICorner", MainButton).CornerRadius = UDim.new(0, 6)

-- 主面板
local MainPanel = Instance.new("Frame")
MainPanel.Size = UDim2.new(0, 340, 0, 380)
MainPanel.Position = UDim2.new(0.5, -170, 0.5, -190)
MainPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainPanel.BorderColor3 = Color3.fromRGB(60, 100, 160)
MainPanel.BorderSizePixel = 2
MainPanel.Visible = false
MainPanel.Active = true
MainPanel.Parent = ScreenGui
Instance.new("UICorner", MainPanel).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("Frame", MainPanel)
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 30, 50)
titleBar.BorderSizePixel = 0
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", titleBar)
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "养大一只鸡战士功能面板"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", titleBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -34, 0, 3)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 18
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

drag(MainPanel, titleBar)

-- 版本提示
local VersionTip = Instance.new("TextLabel")
VersionTip.Size = UDim2.new(1, -20, 0, 20)
VersionTip.Position = UDim2.new(0, 10, 0, 40)
VersionTip.BackgroundTransparency = 1
VersionTip.Text = "XJW整合版 - 持续更新中"
VersionTip.TextColor3 = Color3.fromRGB(120, 180, 255)
VersionTip.Font = Enum.Font.SourceSans
VersionTip.TextSize = 11
VersionTip.TextWrapped = true
VersionTip.Parent = MainPanel

local TipLabel = Instance.new("TextLabel")
TipLabel.Size = UDim2.new(1, -20, 0, 24)
TipLabel.Position = UDim2.new(0, 10, 0, 62)
TipLabel.BackgroundTransparency = 1
TipLabel.Text = "达到重生要求会自动返回撤离并重生！"
TipLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TipLabel.Font = Enum.Font.SourceSans
TipLabel.TextSize = 11
TipLabel.TextWrapped = true
TipLabel.Parent = MainPanel

-- 按钮颜色定义
local btnColor = Color3.fromRGB(20, 25, 35)
local btnBorder = Color3.fromRGB(60, 100, 200)

local function createButton(text, posY, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 34)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = btnColor
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.BorderSizePixel = 2
    btn.BorderColor3 = btnBorder
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
    end)
    return btn
end

-- 自动重生按钮
local toggleBtn = createButton("自动重生 当前状态:[关闭] | 本次挂机已重生0次", 92, MainPanel)

-- 挂机移动按钮
local afkMoveBtn = createButton("挂机移动 当前状态:[关闭]", 130, MainPanel)

-- 自动捡垃圾按钮
local scrapBtn = createButton("自动捡垃圾 当前状态:[关闭]", 168, MainPanel)

-- 滑块框架
local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(1, -20, 0, 24)
SliderFrame.Position = UDim2.new(0, 10, 0, 210)
SliderFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
SliderFrame.BorderSizePixel = 1
SliderFrame.BorderColor3 = Color3.fromRGB(50, 70, 130)
SliderFrame.Parent = MainPanel
Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 4)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(50, 180, 230)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderFrame
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 4)

local SliderKnob = Instance.new("TextButton")
SliderKnob.Size = UDim2.new(0, 18, 0, 18)
SliderKnob.Position = UDim2.new(0, -9, 0.5, -9)
SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderKnob.Text = ""
SliderKnob.BorderSizePixel = 0
SliderKnob.Parent = SliderFrame
Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(1, 0)

local TipText = Instance.new("TextLabel")
TipText.Size = UDim2.new(1, -20, 0, 18)
TipText.Position = UDim2.new(0, 10, 0, 240)
TipText.BackgroundTransparency = 1
TipText.Text = "捡（1）垃圾回去"
TipText.TextColor3 = Color3.fromRGB(220, 220, 220)
TipText.Font = Enum.Font.SourceSans
TipText.TextSize = 11
TipText.Parent = MainPanel

local NoticeText = Instance.new("TextLabel")
NoticeText.Size = UDim2.new(1, -20, 0, 36)
NoticeText.Position = UDim2.new(0, 10, 0, 262)
NoticeText.BackgroundTransparency = 1
NoticeText.Text = "提示:本脚本无防挂机功能，可用挂机移动或自动点击器代替"
NoticeText.TextColor3 = Color3.fromRGB(160, 160, 160)
NoticeText.Font = Enum.Font.SourceSans
NoticeText.TextSize = 10
NoticeText.TextWrapped = true
NoticeText.Parent = MainPanel

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -20, 0, 20)
InfoLabel.Position = UDim2.new(0, 10, 0, 300)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "脚本会持续更新，永久免费 | 作者B站UID:647396778"
InfoLabel.TextColor3 = Color3.fromRGB(100, 160, 220)
InfoLabel.Font = Enum.Font.SourceSans
InfoLabel.TextSize = 10
InfoLabel.Parent = MainPanel

-- ========== 滑块逻辑 ==========
local sliderMin = 1
local sliderMax = 6
local draggingSlider = false

local function UpdateSliderUI(val)
    local ratio = (val - sliderMin) / (sliderMax - sliderMin)
    SliderFill.Size = UDim2.new(ratio, 0, 1, 0)
    SliderKnob.Position = UDim2.new(ratio, -9, 0.5, -9)
    selectNum = math.floor(val)
    TipText.Text = string.format("捡（%d）垃圾回去", selectNum)
end
UpdateSliderUI(selectNum)

SliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local absPos = input.Position.X
        local frameAbs = SliderFrame.AbsolutePosition.X
        local frameW = SliderFrame.AbsoluteSize.X
        local t = math.clamp((absPos - frameAbs) / frameW, 0, 1)
        local v = sliderMin + t * (sliderMax - sliderMin)
        UpdateSliderUI(v)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)

-- ========== 面板显隐 ==========
MainButton.MouseButton1Click:Connect(function()
    panelVisible = not panelVisible
    MainPanel.Visible = panelVisible
    if panelVisible then
        MainPanel.Size = UDim2.new(0, 0, 0, 0)
        MainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
        TweenService:Create(MainPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 340, 0, 380),
            Position = UDim2.new(0.5, -170, 0.5, -190)
        }):Play()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    panelVisible = false
    local tw = TweenService:Create(MainPanel, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    tw:Play()
    tw.Completed:Connect(function()
        MainPanel.Visible = false
        MainPanel.Size = UDim2.new(0, 340, 0, 380)
        MainPanel.Position = UDim2.new(0.5, -170, 0.5, -190)
    end)
end)

-- ========== 检测函数 ==========
local function IsUIVisible(guiObject)
    local obj = guiObject
    while obj do
        if obj:IsA("GuiObject") then
            if not obj.Visible then return false end
        end
        obj = obj.Parent
    end
    return true
end

local function IsOnScreen(guiObj)
    local cam = workspace.CurrentCamera
    local absPos = guiObj.AbsolutePosition
    local absSize = guiObj.AbsoluteSize
    local screenW, screenH = cam.ViewportSize.X, cam.ViewportSize.Y
    local x1, y1 = absPos.X, absPos.Y
    local x2, y2 = absPos.X + absSize.X, absPos.Y + absSize.Y
    if x2 < 0 or x1 > screenW then return false end
    if y2 < 0 or y1 > screenH then return false end
    return true
end

local function CheckVisibleText(guiChild)
    if not (guiChild:IsA("TextLabel") or guiChild:IsA("TextButton")) then return false end
    if guiChild.Text == nil or guiChild.Text == "" then return false end
    if not IsUIVisible(guiChild) then return false end
    if not IsOnScreen(guiChild) then return false end
    return true
end

-- ========== 游戏功能 ==========
local function RunGeneratorCode()
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(5)
    end)
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(3)
    end)
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(4)
    end)
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(6)
    end)
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(6)
    end)
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(4)
    end)
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(3)
    end)
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(5)
    end)
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(1)
    end)
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(2)
    end)
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(1)
    end)
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(2)
    end)
end

local function RunTowerElevatorSequence()
    local num = 1
    local totalTimes = 20
    for i = 1, totalTimes do
        if not loopChallengeRunning or not globalRunning then break end
        if suspendTowerLoops then break end
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.TowerElevator:InvokeServer(num)
        end)
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.TowerStart:InvokeServer()
        end)
        num = num + 5
        task.wait(0.1)
    end
end

-- ========== 自动重生 ==========
local function startLoop()
    loopChallengeRunning = true
    suspendTowerLoops = false
    toggleBtn.Text = "自动重生 当前状态:[开启] | 本次挂机已重生" .. detectTriggerCount .. "次"

    -- 塔启动 + 塔式电梯
    table.insert(threadPool, task.spawn(function()
        if loopChallengeRunning and globalRunning then
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.TowerStart:InvokeServer()
            end)
            RunTowerElevatorSequence()
        end
    end))

    -- 自动重生
    table.insert(threadPool, task.spawn(function()
        while loopChallengeRunning and globalRunning do
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.Rebirth:InvokeServer()
            end)
            task.wait(0.5)
        end
    end))

    -- 关键词检测
    table.insert(threadPool, task.spawn(function()
        local keywordRebirth = "REBIRTH READY!"
        local keywordNoThanks = "NO THANKS"
        local keywordTower = "TOWER"
        local keywordRetreat = "RETREAT"
        local keywordToChaos = "TO CHAOS"
        local noThanksCooldown = 0

        while loopChallengeRunning and globalRunning do
            task.wait(0.5)
            local playerGui = localPlayer:FindFirstChild("PlayerGui")
            if not playerGui then continue end

            if triggerCooldown > 0 then triggerCooldown -= 0.5 end
            if noThanksCooldown > 0 then noThanksCooldown -= 0.5 end
            if towerKeywordCooldown > 0 then towerKeywordCooldown -= 0.5 end
            if retreatChaosCooldown > 0 then retreatChaosCooldown -= 0.5 end

            local foundRebirth = false
            local foundNoThanks = false
            local foundTower = false
            local foundRetreat = false
            local foundToChaos = false

            for _, child in ipairs(playerGui:GetDescendants()) do
                if not child:IsDescendantOf(game) then continue end
                if CheckVisibleText(child) then
                    if string.find(child.Text, keywordRebirth, 1, true) then foundRebirth = true end
                    if string.find(child.Text, keywordNoThanks, 1, true) then foundNoThanks = true end
                    if string.find(child.Text, keywordTower, 1, true) then foundTower = true end
                    if string.find(child.Text, keywordRetreat, 1, true) then foundRetreat = true end
                    if string.find(child.Text, keywordToChaos, 1, true) then foundToChaos = true end
                end
            end

            -- RETREAT / TO CHAOS 逻辑
            if (foundRetreat or foundToChaos) and retreatChaosCooldown <= 0 then
                retreatChaosCooldown = 2
                table.insert(threadPool, task.spawn(function()
                    task.wait(0.5)
                    if loopChallengeRunning and globalRunning then
                        pcall(function()
                            game:GetService("ReplicatedStorage").Remotes.SetChickenOrder:FireServer("coop")
                        end)
                    end
                end))
            end

            -- REBIRTH READY 逻辑
            if foundRebirth and triggerCooldown <= 0 then
                detectTriggerCount += 1
                triggerCooldown = 6.66
                suspendTowerLoops = true
                toggleBtn.Text = "自动重生 当前状态:[开启] | 本次挂机已重生" .. detectTriggerCount .. "次"

                pcall(function()
                    game:GetService("ReplicatedStorage").Remotes.SetChickenOrder:FireServer("coop")
                end)
                pcall(function()
                    game:GetService("ReplicatedStorage").Remotes.TowerSurrender:InvokeServer()
                end)

                table.insert(threadPool, task.spawn(function()
                    task.wait(9.99)
                    if loopChallengeRunning and globalRunning then
                        suspendTowerLoops = false
                        pcall(function()
                            game:GetService("ReplicatedStorage").Remotes.TowerStart:InvokeServer()
                        end)
                        RunTowerElevatorSequence()
                    end
                end))
            end

            -- NO THANKS 逻辑
            if foundNoThanks and noThanksCooldown <= 0 then
                noThanksCooldown = 20
                table.insert(threadPool, task.spawn(function()
                    task.wait(0.6)
                    if loopChallengeRunning and globalRunning then
                        pcall(function()
                            game:GetService("ReplicatedStorage").Remotes.TowerContinueDecline:FireServer()
                        end)
                    end
                end))
            end

            -- TOWER 关键词逻辑
            if foundTower and towerKeywordCooldown <= 0 then
                towerKeywordCooldown = 21
                table.insert(threadPool, task.spawn(function()
                    task.wait(20)
                    if not (loopChallengeRunning and globalRunning) then return end
                    RunTowerElevatorSequence()
                    if loopChallengeRunning and globalRunning then
                        pcall(function()
                            game:GetService("ReplicatedStorage").Remotes.TowerStart:InvokeServer()
                        end)
                    end
                end))
            end
        end
    end))

    -- 生成器升级 + 鸡舍扩展
    table.insert(threadPool, task.spawn(function()
        while loopChallengeRunning and globalRunning do
            RunGeneratorCode()
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.ExpandCoop:InvokeServer()
            end)
            task.wait(1)
        end
    end))

    -- 生成器升级循环2
    table.insert(threadPool, task.spawn(function()
        while loopChallengeRunning and globalRunning do
            RunGeneratorCode()
            task.wait(0.9)
        end
    end))

    -- 孵化器领取
    table.insert(threadPool, task.spawn(function()
        while loopChallengeRunning and globalRunning do
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.IncubatorClaim:InvokeServer()
            end)
            task.wait(1)
        end
    end))
end

local function stopLoop()
    loopChallengeRunning = false
    suspendTowerLoops = false
    toggleBtn.Text = "自动重生 当前状态:[关闭] | 本次挂机已重生" .. detectTriggerCount .. "次"
end

toggleBtn.MouseButton1Click:Connect(function()
    if loopChallengeRunning then
        stopLoop()
    else
        startLoop()
    end
end)

-- ========== 挂机移动 ==========
local directions = {
    Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1),
    Vector3.new(-1, 0, 1), Vector3.new(1, 0, 1),
    Vector3.new(0, 0, -1), Vector3.new(0, 0, 1),
    Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0)
}

local afkThread = task.spawn(function()
    local baseMoveStep = 10
    local maxDistance = 6.6
    local tickDelay = 0.05
    local currentDirIndex = math.random(1, #directions)
    local traveled = 0
    while task.wait(tickDelay) do
        if not globalRunning or not autoAfk then
            currentDirIndex = math.random(1, #directions)
            traveled = 0
            spawnPosition = nil
            continue
        end
        local char = localPlayer.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        if not spawnPosition then
            spawnPosition = root.Position
        end
        local targetDir = directions[currentDirIndex].Unit
        local nextPos = root.Position + targetDir * baseMoveStep * tickDelay
        local dx = math.abs(nextPos.X - spawnPosition.X)
        local dz = math.abs(nextPos.Z - spawnPosition.Z)
        if dx > rangeLimit or dz > rangeLimit then
            root.CFrame = CFrame.new(spawnPosition)
            currentDirIndex = math.random(1, #directions)
            traveled = 0
            continue
        end
        root.CFrame += targetDir * baseMoveStep * tickDelay
        traveled += baseMoveStep * tickDelay
        if traveled >= maxDistance then
            currentDirIndex = math.random(1, #directions)
            traveled = 0
        end
    end
end)
table.insert(threadPool, afkThread)

afkMoveBtn.MouseButton1Click:Connect(function()
    autoAfk = not autoAfk
    if autoAfk then
        afkMoveBtn.Text = "挂机移动 当前状态:[开启]"
    else
        afkMoveBtn.Text = "挂机移动 当前状态:[关闭]"
    end
end)

-- ========== 自动捡垃圾 ==========
local scrapThread1, scrapThread2

local function ScrapMainLoop()
    while autoScrapRunning and globalRunning do
        local delayTime = 0.5
        local recyclerUI = workspace:FindFirstChild("Recyclers") and workspace.Recyclers:FindFirstChild("RecyclerUI")
        if recyclerUI and recyclerUI:FindFirstChildOfClass("Part") then
            recycleDestination = recyclerUI:FindFirstChildOfClass("Part").Position
        end

        local Character = localPlayer.Character
        if not Character then
            task.wait(delayTime)
            continue
        end
        local RootPart = Character:WaitForChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid or not recycleDestination then
            task.wait(delayTime)
            continue
        end

        local state
        if collectedCount < selectNum then
            state = "FindScrap"
        else
            state = "GoHome"
        end

        if state == "FindScrap" then
            local scrapTable = {}
            local playerPos = RootPart.Position
            for _, item in ipairs(workspace:GetChildren()) do
                if item:IsA("Model") and item.Name == "PitScrap" then
                    local scrapPart = item:FindFirstChildOfClass("Part")
                    if scrapPart then
                        local dist = (playerPos - scrapPart.Position).Magnitude
                        table.insert(scrapTable, {
                            Model = item,
                            PartPos = scrapPart.Position,
                            Dist = dist
                        })
                    end
                end
            end
            table.sort(scrapTable, function(a, b)
                return a.Dist < b.Dist
            end)

            if #scrapTable > 0 then
                local nearestScrap = scrapTable[1]
                targetScrapPos = nearestScrap.PartPos
                local dist = (playerPos - targetScrapPos).Magnitude
                if dist <= reachRange then
                    collectedCount += 1
                    targetScrapPos = nil
                else
                    Humanoid:MoveTo(targetScrapPos)
                end
            end
        elseif state == "GoHome" then
            local dist = (RootPart.Position - recycleDestination).Magnitude
            if dist <= reachRange then
                collectedCount = 0
            else
                Humanoid:MoveTo(recycleDestination)
            end
        end
        task.wait(delayTime)
    end
    local char = localPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char.Humanoid:Stop()
    end
end

local function UpgradeRecyclerLoop()
    while autoScrapRunning and globalRunning do
        task.wait(0.5)
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.UpgradeRecycler:InvokeServer()
        end)
    end
end

scrapBtn.MouseButton1Click:Connect(function()
    autoScrapRunning = not autoScrapRunning
    if autoScrapRunning then
        scrapBtn.Text = "自动捡垃圾 当前状态:[开启]"
        targetScrapPos = nil
        collectedCount = 0
        scrapThread1 = task.spawn(ScrapMainLoop)
        scrapThread2 = task.spawn(UpgradeRecyclerLoop)
        table.insert(threadPool, scrapThread1)
        table.insert(threadPool, scrapThread2)
    else
        scrapBtn.Text = "自动捡垃圾 当前状态:[关闭]"
        autoScrapRunning = false
        targetScrapPos = nil
        local char = localPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            char.Humanoid:Stop()
        end
    end
end)

-- ========== 入场动画 ==========
MainButton.Size = UDim2.new(0, 0, 0, 0)
MainButton.Position = UDim2.new(0.05, 0, 0.3, 0)
TweenService:Create(MainButton, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 160, 0, 44)
}):Play()

-- 通知
pcall(function()
    game.StarterGui:SetCore("SendNotification", {
        Title = "养大一只鸡战士",
        Text = "脚本已加载！点击菜单按钮打开面板",
        Duration = 5
    })
end)
