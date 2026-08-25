--养大一只鸡战士功能面板
--脚本作者b站UID:647396778
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- 全局总开关：整体是否运行
local globalRunning = true
local loopChallengeRunning = false
local panelVisible = false
local suspendTowerLoops = false
local detectTriggerCount = 0
local triggerCooldown = 0
local towerKeywordCooldown = 21 -- TOWER关键词冷却【已修改为21】
local retreatChaosCooldown = 0 -- RETREAT / TO CHAOS 冷却

local autoAfk = false
local rangeLimit = 16.66
local spawnPosition = nil

local autoScrapRunning = false
local reachRange = 5.5
local targetScrapPos = nil
local collectedCount = 0
local selectNum = 1
local recycleDestination

-- 保存所有协程，用于强制终止
local threadPool = {}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MainPanelUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local MainButton = Instance.new("TextButton")
MainButton.Size = UDim2.new(0, 140, 0, 48)
MainButton.Position = UDim2.new(0.05, 0, 0.3, 0)
MainButton.BackgroundColor3 = Color3.new(0.12, 0.22, 0.35)
MainButton.BorderColor3 = Color3.new(0.5, 0.8, 1)
MainButton.BorderSizePixel = 2
MainButton.Text = "养大一只鸡战士功能菜单"
MainButton.TextColor3 = Color3.new(1,1,1)
MainButton.Font = Enum.Font.SourceSansBold
MainButton.TextSize = 14
MainButton.Parent = ScreenGui

local MainPanel = Instance.new("Frame")
MainPanel.Size = UDim2.new(0, 320, 0, 290)
MainPanel.Position = UDim2.new(0.5, -160, 0.5, -145)
MainPanel.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
MainPanel.BorderColor3 = Color3.new(0.4, 0.6, 0.9)
MainPanel.BorderSizePixel = 2
MainPanel.Visible = false
MainPanel.Active = true
MainPanel.Parent = ScreenGui

-- ========== 修改版本提示文本 ==========
local VersionTip = Instance.new("TextLabel")
VersionTip.Size = UDim2.new(0.9,0,0,20)
VersionTip.Position = UDim2.new(0.05,0,0,0)
VersionTip.BackgroundTransparency = 1
VersionTip.Text = "更新时间:8月23日14时38分，更新内容:修复了手动点击撤离，后面不会自动挑战"
VersionTip.TextColor3 = Color3.new(0.65,0.85,1)
VersionTip.Font = Enum.Font.SourceSans
VersionTip.TextSize = 10
VersionTip.TextWrapped = true
VersionTip.Parent = MainPanel

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 32)
Title.BackgroundTransparency = 1
Title.Text = "功能主面板"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 17
Title.Position = UDim2.new(0,10,0.06,0)
Title.Parent = MainPanel

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -38, 0, 0)
CloseBtn.BackgroundColor3 = Color3.new(0.7,0.15,0.15)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 22
CloseBtn.Parent = MainPanel

local ResizeHandle = Instance.new("TextButton")
ResizeHandle.Size = UDim2.new(0, 32, 0, 32)
ResizeHandle.Position = UDim2.new(1, -32, 1, -32)
ResizeHandle.BackgroundTransparency = 0.6
ResizeHandle.BackgroundColor3 = Color3.new(0.35,0.45,0.65)
ResizeHandle.Text = "丿"
ResizeHandle.TextColor3 = Color3.new(1,1,1)
ResizeHandle.Font = Enum.Font.SourceSansBold
ResizeHandle.TextSize = 20
ResizeHandle.Parent = MainPanel

local TipLabel = Instance.new("TextLabel")
TipLabel.Size = UDim2.new(0.9,0,0,28)
TipLabel.Position = UDim2.new(0.05,0,0.14,0)
TipLabel.BackgroundTransparency = 1
TipLabel.Text = "达到重生要求会自动返回撤离并重生！"
TipLabel.TextColor3 = Color3.new(0.85,0.85,0.85)
TipLabel.Font = Enum.Font.SourceSans
TipLabel.TextSize = 10
TipLabel.TextWrapped = true
TipLabel.Parent = MainPanel

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.9, 0, 0, 34)
toggleBtn.Position = UDim2.new(0.05, 0, 0.24, 0)
toggleBtn.BackgroundColor3 = Color3.new(0.15,0.15,0.2)
toggleBtn.Text = "自动重生 当前状态:[关闭] | 本次挂机已重生"..detectTriggerCount.."次"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 14
toggleBtn.BorderSizePixel = 2
toggleBtn.BorderColor3 = Color3.new(0.4,0.6,1)
toggleBtn.Parent = MainPanel

local afkMoveBtn = Instance.new("TextButton")
afkMoveBtn.Size = UDim2.new(0.9, 0, 0, 34)
afkMoveBtn.Position = UDim2.new(0.05, 0, 0.39, 0)
afkMoveBtn.BackgroundColor3 = Color3.new(0.15,0.15,0.2)
afkMoveBtn.Text = "挂机移动 当前状态:[关闭]"
afkMoveBtn.TextColor3 = Color3.new(1,1,1)
afkMoveBtn.Font = Enum.Font.SourceSansBold
afkMoveBtn.TextSize = 14
afkMoveBtn.BorderSizePixel = 2
afkMoveBtn.BorderColor3 = Color3.new(0.4,0.6,1)
afkMoveBtn.Parent = MainPanel

local scrapBtn = Instance.new("TextButton")
scrapBtn.Size = UDim2.new(0.9, 0, 0, 34)
scrapBtn.Position = UDim2.new(0.05, 0, 0.54, 0)
scrapBtn.BackgroundColor3 = Color3.new(0.15,0.15,0.2)
scrapBtn.Text = "自动捡垃圾 当前状态:[关闭]"
scrapBtn.TextColor3 = Color3.new(1,1,1)
scrapBtn.Font = Enum.Font.SourceSansBold
scrapBtn.TextSize = 13
scrapBtn.BorderSizePixel = 2
scrapBtn.BorderColor3 = Color3.new(0.4,0.6,1)
scrapBtn.Parent = MainPanel

local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(0.9,0,0,20)
SliderFrame.Position = UDim2.new(0.05,0,0.68,0)
SliderFrame.BackgroundColor3 = Color3.new(0.07,0.07,0.11)
SliderFrame.BorderSizePixel =1
SliderFrame.BorderColor3 = Color3.new(0.3,0.4,0.7)
SliderFrame.Parent = MainPanel

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0,0,1,0)
SliderFill.BackgroundColor3 = Color3.new(0.2,0.7,0.9)
SliderFill.Parent = SliderFrame

local SliderKnob = Instance.new("TextButton")
SliderKnob.Size = UDim2.new(0,18,0,18)
SliderKnob.Position = UDim2.new(0,-9,0.5,-9)
SliderKnob.BackgroundColor3 = Color3.new(1,1,1)
SliderKnob.Text = ""
SliderKnob.BorderSizePixel =0
SliderKnob.Parent = SliderFrame

local TipText = Instance.new("TextLabel")
TipText.Size = UDim2.new(0.9,0,0,18)
TipText.Position = UDim2.new(0.05,0,0.78,0)
TipText.BackgroundTransparency =1
TipText.Text = "捡（1）垃圾回去"
TipText.TextColor3 = Color3.new(0.9,0.9,0.9)
TipText.Font = Enum.Font.SourceSans
TipText.TextSize =11
TipText.Parent = MainPanel

local NoticeText = Instance.new("TextLabel")
NoticeText.Size = UDim2.new(0.9,0,0,18)
NoticeText.Position = UDim2.new(0.05,0,0.84,0)
NoticeText.BackgroundTransparency =1
NoticeText.Text = "提示:本脚本无防挂机功能，可自动点击器来代替防止被检测挂机并踢出"
NoticeText.TextColor3 = Color3.new(0.75,0.75,0.75)
NoticeText.Font = Enum.Font.SourceSans
NoticeText.TextSize =10
NoticeText.Parent = MainPanel

local sliderMin =1
local sliderMax =6
local draggingSlider =false
local function UpdateSliderUI(val)
    local ratio = (val-sliderMin)/(sliderMax-sliderMin)
    SliderFill.Size = UDim2.new(ratio,0,1,0)
    SliderKnob.Position = UDim2.new(ratio,-9,0.5,-9)
    selectNum = math.floor(val)
    TipText.Text = string.format("捡（%d）垃圾回去",selectNum)
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
        local t = math.clamp((absPos-frameAbs)/frameW,0,1)
        local v = sliderMin + t*(sliderMax-sliderMin)
        UpdateSliderUI(v)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)

-- 检测控件自身以及父级全部Visible是否true
local function IsUIVisible(guiObject)
    local obj = guiObject
    while obj do
        if obj:IsA("GuiObject") then
            if not obj.Visible then
                return false
            end
        end
        obj = obj.Parent
    end
    return true
end

-- 判断GUI控件是否在屏幕视口范围内
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

-- 【重点】文本检测：必须同时满足：父级全部可见 + 控件在屏幕视口内，才判定有效
local function CheckVisibleText(guiChild)
    if not (guiChild:IsA("TextLabel") or guiChild:IsA("TextButton")) then
        return false
    end
    if guiChild.Text == nil or guiChild.Text == "" then
        return false
    end
    if not IsUIVisible(guiChild) then
        return false
    end
    if not IsOnScreen(guiChild) then
        return false
    end
    return true
end

local function RunGeneratorCode()
    pcall(function()
        local args = {[1] = 5}
        game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(unpack(args))
    end)
    pcall(function()
        local args = {[1] = 3}
        game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(unpack(args))
    end)
    pcall(function()
        local args = {[1] = 4}
        game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(unpack(args))
    end)
    pcall(function()
        local args = {[1] = 6}
        game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(unpack(args))
    end)
    pcall(function()
        local args = {[1] = 6}
        game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(unpack(args))
    end)
    pcall(function()
        local args = {[1] = 4}
        game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(unpack(args))
    end)
    pcall(function()
        local args = {[1] = 3}
        game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(unpack(args))
    end)
    pcall(function()
        local args = {[1] = 5}
        game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(unpack(args))
    end)
    pcall(function()
        local args = {[1] = 1}
        game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(unpack(args))
    end)
    pcall(function()
        local args = {[1] = 2}
        game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(unpack(args))
    end)
    pcall(function()
        local args = {[1] = 1}
        game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(unpack(args))
    end)
    pcall(function()
        local args = {[1] = 2}
        game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(unpack(args))
    end)
end

local function RunTowerElevatorSequence()
    local num =1
    local totalTimes =20
    for i=1,totalTimes do
        if not loopChallengeRunning or not globalRunning then break end
        if suspendTowerLoops then break end
        pcall(function()
            local args = {[1]=num}
            game:GetService("ReplicatedStorage").Remotes.TowerElevator:InvokeServer(unpack(args))
        end)
        pcall(function()
            game:GetService("ReplicatedStorage").Remotes.TowerStart:InvokeServer()
        end)
        num = num +5
        task.wait(0.1)
    end
end

local function startLoop()
    loopChallengeRunning = true
    suspendTowerLoops = false
    toggleBtn.Text = "自动重生 当前状态:[开启] | 本次挂机已重生"..detectTriggerCount.."次"

    table.insert(threadPool, task.spawn(function()
        if loopChallengeRunning and globalRunning then
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.TowerStart:InvokeServer()
            end)
            RunTowerElevatorSequence()
        end
    end))

    table.insert(threadPool, task.spawn(function()
        while loopChallengeRunning and globalRunning do
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.Rebirth:InvokeServer()
            end)
            task.wait(0.5)
        end
    end))

    table.insert(threadPool, task.spawn(function()
        local keywordRebirth = "REBIRTH READY!"
        local keywordNoThanks = "NO THANKS"
        local keywordTower = "TOWER"
        local keywordRetreat = "RETREAT"
        local keywordToChaos = "TO CHAOS"
        local noThanksCooldown = 0
        -- 循环间隔0.5秒
        while loopChallengeRunning and globalRunning do
            task.wait(0.5)
            local playerGui = localPlayer:FindFirstChild("PlayerGui")
            if not playerGui then continue end
            if triggerCooldown > 0 then
                triggerCooldown -= 0.5
            end
            if noThanksCooldown > 0 then
                noThanksCooldown -= 0.5
            end
            if towerKeywordCooldown > 0 then
                towerKeywordCooldown -= 0.5
            end
            if retreatChaosCooldown > 0 then
                retreatChaosCooldown -= 0.5
            end

            local foundRebirth = false
            local foundNoThanks = false
            local foundTower = false
            local foundRetreat = false
            local foundToChaos = false

            for _,child in ipairs(playerGui:GetDescendants()) do
                if not child:IsDescendantOf(game) then continue end
                -- 使用可见文本检测
                if CheckVisibleText(child) then
                    if string.find(child.Text, keywordRebirth,1,true) then
                        foundRebirth = true
                    end
                    if string.find(child.Text, keywordNoThanks,1,true) then
                        foundNoThanks = true
                    end
                    if string.find(child.Text, keywordTower,1,true) then
                        foundTower = true
                    end
                    if string.find(child.Text, keywordRetreat,1,true) then
                        foundRetreat = true
                    end
                    if string.find(child.Text, keywordToChaos,1,true) then
                        foundToChaos = true
                    end
                end
            end

            -- ========== 新增 RETREAT / TO CHAOS 逻辑 ==========
            if (foundRetreat or foundToChaos) and retreatChaosCooldown <= 0 then
                retreatChaosCooldown = 2
                table.insert(threadPool, task.spawn(function()
                    task.wait(0.5)
                    if loopChallengeRunning and globalRunning then
                        local args = {
                            [1] = "coop"
                        }
                        game:GetService("ReplicatedStorage").Remotes.SetChickenOrder:FireServer(unpack(args))
                    end
                end))
            end

            if foundRebirth and triggerCooldown <= 0 then
                detectTriggerCount +=1
                triggerCooldown = 6.66
                suspendTowerLoops = true
                toggleBtn.Text = "自动重生 当前状态:[开启] | 本次挂机已重生"..detectTriggerCount.."次"

                pcall(function()
                    local args = {[1] = "coop"}
                    game:GetService("ReplicatedStorage").Remotes.SetChickenOrder:FireServer(unpack(args))
                end)
                pcall(function()
                    game:GetService("ReplicatedStorage").Remotes.TowerSurrender:InvokeServer()
                end)

                -- REBIRTH READY! 等待9.99秒重启塔流程
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

            -- NO THANKS：仅执行TowerContinueDecline，不再运行塔式电梯、塔启动
            if foundNoThanks and noThanksCooldown <= 0 then
                print("检测到 NO THANKS，执行 TowerContinueDecline")
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

            -- TOWER关键词逻辑：冷却21秒，检测到等待20秒执行塔式电梯，再执行塔启动【已修改】
            if foundTower and towerKeywordCooldown <= 0 then
                print("检测到 TOWER，开始计时20秒执行塔式电梯")
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

    table.insert(threadPool, task.spawn(function()
        while loopChallengeRunning and globalRunning do
            RunGeneratorCode()
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.ExpandCoop:InvokeServer()
            end)
            task.wait(1)
        end
    end))

    table.insert(threadPool, task.spawn(function()
        while loopChallengeRunning and globalRunning do
            RunGeneratorCode()
            task.wait(0.9)
        end
    end))

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
    toggleBtn.Text = "自动重生 当前状态:[关闭] | 本次挂机已重生"..detectTriggerCount.."次"
end

toggleBtn.MouseButton1Click:Connect(function()
    if loopChallengeRunning then
        stopLoop()
    else
        startLoop()
    end
end)

local directions = {
    Vector3.new(1,0,-1),
    Vector3.new(-1,0,-1),
    Vector3.new(-1,0,1),
    Vector3.new(1,0,1),
    Vector3.new(0,0,-1),
    Vector3.new(0,0,1),
    Vector3.new(-1,0,0),
    Vector3.new(1,0,0)
}
local afkThread
afkThread = task.spawn(function()
    local baseMoveStep = 10
    local maxDistance = 6.6
    local tickDelay = 0.05
    local currentDirIndex = math.random(1,#directions)
    local traveled = 0
    while task.wait(tickDelay) do
        if not globalRunning or not autoAfk then
            currentDirIndex = math.random(1,#directions)
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
            currentDirIndex = math.random(1,#directions)
            traveled = 0
            continue
        end
        root.CFrame += targetDir * baseMoveStep * tickDelay
        traveled += baseMoveStep * tickDelay
        if traveled >= maxDistance then
            currentDirIndex = math.random(1,#directions)
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
            table.sort(scrapTable, function(a,b)
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

local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Sx…"
 https://raw.githubusercontent.com/30124OAO/yi/main/yangdayizhijizhanshi#:~:text=%2D%2D%E5%85%BB%E5%A4%A7%E4%B8%80,x6e%5Cx64%5Cx29%22