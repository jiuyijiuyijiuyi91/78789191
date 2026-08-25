--养大一只鸡战士脚本
--XJW整合版

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- 全局状态
local globalRunning = true
local loopChallengeRunning = false
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

-- ========== 检测函数（前置声明） ==========
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

-- ========== 游戏功能函数 ==========
local function RunGeneratorCode()
    pcall(function() game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(5) end)
    pcall(function() game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(3) end)
    pcall(function() game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(4) end)
    pcall(function() game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(6) end)
    pcall(function() game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(6) end)
    pcall(function() game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(4) end)
    pcall(function() game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(3) end)
    pcall(function() game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(5) end)
    pcall(function() game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(1) end)
    pcall(function() game:GetService("ReplicatedStorage").Remotes.BuyGenerator:InvokeServer(2) end)
    pcall(function() game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(1) end)
    pcall(function() game:GetService("ReplicatedStorage").Remotes.UpgradeGenerator:InvokeServer(2) end)
end

local function RunTowerElevatorSequence()
    local num = 1
    for i = 1, 20 do
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

-- ========== 挂机移动协程 ==========
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

-- ========== 自动捡垃圾协程 ==========
local scrapThread1 = task.spawn(function()
    while globalRunning do
        if not autoScrapRunning then
            task.wait(0.5)
            continue
        end
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
end)
table.insert(threadPool, scrapThread1)

local scrapThread2 = task.spawn(function()
    while globalRunning do
        if autoScrapRunning then
            pcall(function()
                game:GetService("ReplicatedStorage").Remotes.UpgradeRecycler:InvokeServer()
            end)
        end
        task.wait(0.5)
    end
end)
table.insert(threadPool, scrapThread2)

-- ========== 创建UI ==========
local Window = WindUI:CreateWindow({
    Title = "养大一只鸡战士",
    Icon = "sparkles",
    Author = "XJW",
    Folder = "ChickenWarrior",
    Size = UDim2.fromOffset(450, 420),
    Theme = "Dark",
    HideSearchBar = false,
})

Window:EditOpenButton({
    Title = "养大一只鸡战士",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF6B6B")),
    Draggable = true,
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
    Title = "脚本会持续更新，永久免费",
    Color = Color3.fromHex("#7FDBFF")
})

-- ========== 主功能 Tab ==========
local Tab = Window:Tab({
    Title = "功能",
    Icon = "settings",
    Locked = false,
})

Tab:Section({Title = "自动功能", TextXAlignment = "Left", TextSize = 17})

-- 自动重生开关
Tab:Toggle({
    Title = "自动重生",
    Default = false,
    Callback = function(state)
        loopChallengeRunning = state
        if state then
            suspendTowerLoops = false
            WindUI:Notify({Title = "自动重生", Content = "已开启自动重生", Duration = 3})

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

                    local foundRebirth, foundNoThanks, foundTower, foundRetreat, foundToChaos = false, false, false, false, false

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

                    if foundRebirth and triggerCooldown <= 0 then
                        detectTriggerCount += 1
                        triggerCooldown = 6.66
                        suspendTowerLoops = true

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
        else
            suspendTowerLoops = false
            WindUI:Notify({Title = "自动重生", Content = "已关闭 | 本次挂机已重生" .. detectTriggerCount .. "次", Duration = 3})
        end
    end
})

-- 挂机移动开关
Tab:Toggle({
    Title = "挂机移动",
    Default = false,
    Callback = function(state)
        autoAfk = state
        if state then
            WindUI:Notify({Title = "挂机移动", Content = "已开启挂机移动", Duration = 3})
        else
            WindUI:Notify({Title = "挂机移动", Content = "已关闭挂机移动", Duration = 3})
        end
    end
})

-- 自动捡垃圾开关
Tab:Toggle({
    Title = "自动捡垃圾",
    Default = false,
    Callback = function(state)
        autoScrapRunning = state
        if state then
            targetScrapPos = nil
            collectedCount = 0
            WindUI:Notify({Title = "自动捡垃圾", Content = "已开启自动捡垃圾", Duration = 3})
        else
            targetScrapPos = nil
            local char = localPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char.Humanoid:Stop()
            end
            WindUI:Notify({Title = "自动捡垃圾", Content = "已关闭自动捡垃圾", Duration = 3})
        end
    end
})

Tab:Section({Title = "捡垃圾数量", TextXAlignment = "Left", TextSize = 17})

-- 滑块: 捡垃圾数量 (1-10)
local scrapSlider = Tab:Slider({
    Title = "捡（1）垃圾回去",
    Value = {Min = 1, Max = 10, Default = 1},
    Increment = 1,
    Callback = function(value)
        selectNum = math.floor(value)
        scrapSlider:SetTitle(string.format("捡（%d）垃圾回去", selectNum))
    end
})

WindUI:Notify({
    Title = "养大一只鸡战士",
    Content = "脚本已加载！",
    Duration = 5
})
