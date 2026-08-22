--[[
    ============================================================
    🎮 全功能自动脚本 (基于 WindUI)
    功能：自动刷怪 / 自动转生 / 自动孵蛋 / 自动领奖 / 自动转盘 等
    ============================================================
]]

-- ========== 加载 UI 库 ==========
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ========== Knit 服务路径辅助函数 ==========
local KnitBase = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_knit@1.5.1"):WaitForChild("knit"):WaitForChild("Services")

-- 获取 Knit 服务
local function getService(serviceName)
    local ok, service = pcall(function()
        return KnitBase:WaitForChild(serviceName, 10)
    end)
    if not ok or not service then
        WindUI:Notify({Title = "⚠️ 服务获取失败", Content = "找不到服务: " .. tostring(serviceName), Duration = 5})
        return nil
    end
    return service
end

-- 获取 RemoteEvent (RE)
local function getRE(serviceName, eventName)
    local service = getService(serviceName)
    if not service then return nil end
    local re = service:WaitForChild("RE", 5)
    if not re then return nil end
    return re:WaitForChild(eventName, 5)
end

-- 获取 RemoteFunction (RF)
local function getRF(serviceName, funcName)
    local service = getService(serviceName)
    if not service then return nil end
    local rf = service:WaitForChild("RF", 5)
    if not rf then return nil end
    return rf:WaitForChild(funcName, 5)
end

-- ========== 全局状态 ==========
local Flags = {
    AutoFarm = false,
    AutoSkill = false,
    AutoAttack = false,
    AutoRebirth = false,
    AutoSpin = false,
    AutoEquipPets = false,
    AutoClaimReward = false,
    AutoHatch = false,
    AutoHatchAll = false,
    AutoKillAll = false,
}

local Settings = {
    FarmDelay = 0.3,
    SkillDelay = 0.5,
    RebirthDelay = 5,
    SpinDelay = 3,
    HatchDelay = 0.5,
    HatchEgg = "Egg_1_1",
    HatchCount = 1,
    FarmMode = "Attack",  -- Attack / Skill / Both
    KillSpeed = 20,        -- 全图击杀攻击速度等级 (1-100, 越大越快)
    KillFollow = true,    -- 自动传送到最近敌人身边
    KillUseSkill = true,   -- 使用技能攻击 (SkillAttack)
    KillUseNormal = false, -- 同时使用普攻 (Attack)
}

-- ========== 通知快捷函数 ==========
local function notify(title, content, duration)
    WindUI:Notify({Title = title, Content = content or "", Duration = duration or 4})
end

-- ============================================================
-- 🌐 全图自动击杀 辅助函数
-- ============================================================
-- 获取场景中所有存活敌人 (带 Humanoid 的 Model，排除玩家角色)
local function getEnemies()
    local enemies = {}
    local playerChars = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            playerChars[plr.Character] = true
        end
    end

    local function scan(obj)
        if obj:IsA("Model") and not playerChars[obj] then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(enemies, obj)
            end
        end
    end

    -- 优先扫描常见敌人文件夹，提升性能
    local scannedFolder = false
    for _, folderName in ipairs({"Enemies", "Mobs", "Monsters", "NPCs", "Hostiles", "Enemy", "Mob", "SpawnedMobs"}) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            scannedFolder = true
            for _, d in ipairs(folder:GetDescendants()) do
                scan(d)
            end
        end
    end

    -- 若没有敌人文件夹，则全图扫描
    if not scannedFolder then
        for _, d in ipairs(workspace:GetDescendants()) do
            scan(d)
        end
    end

    return enemies
end

-- 从敌人列表中获取离本地玩家最近的一个
local function getNearestFromList(enemies)
    if not enemies or #enemies == 0 then return nil end
    local char = LocalPlayer.Character
    local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
    local nearest, minDist = nil, math.huge
    for _, enemy in ipairs(enemies) do
        local eRoot = enemy.PrimaryPart or enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart")
        if eRoot then
            local dist = root and (root.Position - eRoot.Position).Magnitude or 0
            if dist < minDist then
                minDist = dist
                nearest = enemy
            end
        end
    end
    return nearest, minDist
end

-- 将本地角色传送到指定敌人附近 (确保技能命中)
local function teleportToEnemy(enemy)
    local char = LocalPlayer.Character
    if not char then return end
    local eRoot = enemy.PrimaryPart or enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChildWhichIsA("BasePart")
    if not eRoot then return end
    pcall(function()
        char:PivotTo(eRoot.CFrame * CFrame.new(0, 0, 4))
    end)
end

-- ============================================================
-- 创建窗口
-- ============================================================
local Window = WindUI:CreateWindow({
    Title = "Suzume XJW脚本",
    Icon = "sparkles",
    Author = "Suzume XJW脚本",
    Folder = "SuzumeScript",
    Size = UDim2.fromOffset(480, 460),
    Theme = "Pink",
    HideSearchBar = false,
})

-- ========== 时间标签 (彩虹色) ==========
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
        TimeTag:SetTitle(hours .. ":" .. minutes)
        TimeTag:SetColor(Color3.fromHSV(hue, 1, 1))
        task.wait(0.06)
    end
end)

Window:Tag({
    Title = "Suzume",
    Color = Color3.fromHex("#7FDBFF")
})

Window:EditOpenButton({
    Title = "Suzume Script",
    Icon = "sword",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF6B6B")),
    Draggable = true,
})

-- ============================================================
-- Tab 1: 主功能 (自动刷怪 / 模式切换)
-- ============================================================
local TabFarm = Window:Tab({
    Title = "战斗",
    Icon = "sword",
    Locked = false,
})

TabFarm:Section({Title = "⚔️ 自动战斗系统", TextXAlignment = "Left", TextSize = 17})

-- 战斗模式选择
TabFarm:Dropdown({
    Title = "战斗模式选择",
    Values = {"Attack (普攻)", "Skill (技能)", "Both (双重)"},
    Value = "Attack (普攻)",
    Callback = function(value)
        if value:match("Attack") then Settings.FarmMode = "Attack"
        elseif value:match("Skill") then Settings.FarmMode = "Skill"
        elseif value:match("Both") then Settings.FarmMode = "Both"
        end
        notify("✅ 模式切换", "当前模式: " .. Settings.FarmMode)
    end
})

-- 普攻延迟滑块
TabFarm:Slider({
    Title = "普攻延迟 (秒)",
    Value = {Min = 10, Max = 500, Default = 30},
    Increment = 5,
    Callback = function(value)
        Settings.FarmDelay = value / 100
    end
})

-- 技能延迟滑块
TabFarm:Slider({
    Title = "技能延迟 (秒)",
    Value = {Min = 10, Max = 500, Default = 50},
    Increment = 5,
    Callback = function(value)
        Settings.SkillDelay = value / 100
    end
})

-- 自动刷怪总开关
TabFarm:Toggle({
    Title = "🔮 自动刷怪 (总开关)",
    Default = false,
    Callback = function(state)
        Flags.AutoFarm = state
        if state then
            notify("✅ 自动刷怪已开启", "模式: " .. Settings.FarmMode)
        else
            notify("⏹️ 自动刷怪已关闭", "")
        end
    end
})

-- 自动战斗核心循环
task.spawn(function()
    while true do
        if Flags.AutoFarm then
            local mode = Settings.FarmMode
            local doAttack = (mode == "Attack" or mode == "Both")
            local doSkill = (mode == "Skill" or mode == "Both")

            if doSkill then
                -- 切换到 Skill 模式
                local changeMode = getRE("MainService", "ChangeActionMode")
                if changeMode then
                    pcall(function() changeMode:FireServer("Skill") end)
                end
                local skillAttack = getRE("FightService", "SkillAttack")
                if skillAttack then
                    pcall(function() skillAttack:FireServer() end)
                end
                task.wait(Settings.SkillDelay)
            end

            if doAttack then
                -- 切换到 Attack 模式
                local changeMode = getRE("MainService", "ChangeActionMode")
                if changeMode then
                    pcall(function() changeMode:FireServer("Attack") end)
                end
                local attack = getRE("FightService", "Attack")
                if attack then
                    pcall(function() attack:FireServer() end)
                end
                task.wait(Settings.FarmDelay)
            end
        end
        task.wait(0.05)
    end
end)

-- 模式快速切换按钮
TabFarm:Section({Title = "🎯 快速切换模式", TextXAlignment = "Left", TextSize = 15})

TabFarm:Button({
    Title = "切换到 Skill (技能模式)",
    Callback = function()
        local re = getRE("MainService", "ChangeActionMode")
        if re then
            pcall(function() re:FireServer("Skill") end)
            notify("✅ 已切换", "Skill 技能模式")
        end
    end
})

TabFarm:Button({
    Title = "切换到 Attack (普攻模式)",
    Callback = function()
        local re = getRE("MainService", "ChangeActionMode")
        if re then
            pcall(function() re:FireServer("Attack") end)
            notify("✅ 已切换", "Attack 普攻模式")
        end
    end
})

TabFarm:Button({
    Title = "切换到 Train (训练模式)",
    Callback = function()
        local re = getRE("MainService", "ChangeActionMode")
        if re then
            pcall(function() re:FireServer("Train") end)
            notify("✅ 已切换", "Train 训练模式")
        end
    end
})

-- ============================================================
-- 🌐 全图自动击杀系统
-- ============================================================
TabFarm:Section({Title = "🌐 全图自动击杀", TextXAlignment = "Left", TextSize = 17})

TabFarm:Paragraph({
    Title = "🌐 全图自动击杀",
    Desc = "自动锁定全图怪物并使用技能击杀；攻击速度可调(越大越快)；可开启自动跟随传送到最近敌人身边确保技能命中",
})

-- 攻击速度滑块 (越大越快, 越小越慢)
TabFarm:Slider({
    Title = "攻击速度 (越大越快)",
    Value = {Min = 1, Max = 100, Default = 20},
    Increment = 1,
    Callback = function(value)
        Settings.KillSpeed = value
    end
})

-- 自动跟随敌人开关
TabFarm:Toggle({
    Title = "🎯 自动跟随敌人 (传送到最近敌人)",
    Default = true,
    Callback = function(state)
        Settings.KillFollow = state
    end
})

-- 使用技能攻击开关
TabFarm:Toggle({
    Title = "💥 使用技能攻击 (SkillAttack)",
    Default = true,
    Callback = function(state)
        Settings.KillUseSkill = state
        -- 开启技能攻击且总开关已开时自动切换到 Skill 模式
        if state and Flags.AutoKillAll then
            local changeMode = getRE("MainService", "ChangeActionMode")
            if changeMode then
                pcall(function() changeMode:FireServer("Skill") end)
            end
        end
    end
})

-- 同时使用普攻开关
TabFarm:Toggle({
    Title = "⚔️ 同时使用普攻 (Attack)",
    Default = false,
    Callback = function(state)
        Settings.KillUseNormal = state
    end
})

-- 全图自动击杀总开关
TabFarm:Toggle({
    Title = "🌐 全图自动击杀 (总开关)",
    Default = false,
    Callback = function(state)
        Flags.AutoKillAll = state
        if state then
            -- 切换到技能模式
            if Settings.KillUseSkill then
                local changeMode = getRE("MainService", "ChangeActionMode")
                if changeMode then
                    pcall(function() changeMode:FireServer("Skill") end)
                end
            end
            notify("✅ 全图自动击杀已开启", "攻击速度: " .. tostring(Settings.KillSpeed))
        else
            notify("⏹️ 全图自动击杀已关闭", "")
        end
    end
})

-- 全图击杀状态标签 (实时显示敌人数)
local KillTag = Window:Tag({
    Title = "全图: 关闭",
    Color = Color3.fromHex("#FF4D4D")
})

-- 跟随 + 计数线程 (0.3 秒一次，避免频繁全图扫描造成卡顿)
task.spawn(function()
    while true do
        if Flags.AutoKillAll then
            local enemies = getEnemies()
            KillTag:SetTitle("敌人: " .. tostring(#enemies))
            if Settings.KillFollow then
                local nearest = getNearestFromList(enemies)
                if nearest then
                    teleportToEnemy(nearest)
                end
            end
        else
            KillTag:SetTitle("全图: 关闭")
        end
        task.wait(0.3)
    end
end)

-- 攻击线程 (速度可调, 越大间隔越小)
task.spawn(function()
    while true do
        if Flags.AutoKillAll then
            -- 速度越大间隔越小，下限 0.03 秒防止过于激进
            local delay = math.clamp(1 / math.max(Settings.KillSpeed, 1), 0.03, 1)

            if Settings.KillUseSkill then
                local skillAttack = getRE("FightService", "SkillAttack")
                if skillAttack then
                    pcall(function() skillAttack:FireServer() end)
                end
            end

            if Settings.KillUseNormal then
                local attack = getRE("FightService", "Attack")
                if attack then
                    pcall(function() attack:FireServer() end)
                end
            end

            task.wait(delay)
        else
            task.wait(0.3)
        end
    end
end)

-- ============================================================
-- Tab 2: 孵蛋系统
-- ============================================================
local TabEgg = Window:Tab({
    Title = "孵蛋",
    Icon = "egg",
    Locked = false,
})

TabEgg:Section({Title = "🥚 孵蛋系统", TextXAlignment = "Left", TextSize = 17})

-- 孵蛋选择
local eggList = {"Egg_1_1", "Egg_1_2", "Egg_1_3"}
TabEgg:Dropdown({
    Title = "选择蛋的类型",
    Values = eggList,
    Value = "Egg_1_1",
    Callback = function(value)
        Settings.HatchEgg = value
    end
})

-- 孵蛋数量
TabEgg:Slider({
    Title = "每次孵蛋数量",
    Value = {Min = 1, Max = 10, Default = 1},
    Increment = 1,
    Callback = function(value)
        Settings.HatchCount = value
    end
})

-- 孵蛋延迟
TabEgg:Slider({
    Title = "孵蛋间隔 (秒)",
    Value = {Min = 10, Max = 300, Default = 50},
    Increment = 5,
    Callback = function(value)
        Settings.HatchDelay = value / 100
    end
})

-- 单次孵蛋按钮
TabEgg:Button({
    Title = "🥚 孵一次 (当前选择的蛋)",
    Callback = function()
        local re = getRE("EggHatchService", "Hatch")
        if re then
            pcall(function() re:FireServer(Settings.HatchEgg, Settings.HatchCount) end)
            notify("🥚 孵蛋中", "蛋: " .. Settings.HatchEgg .. " x" .. tostring(Settings.HatchCount))
        end
    end
})

-- 一键孵化所有蛋
TabEgg:Button({
    Title = "💫 一键孵化全部蛋 (三种)",
    Callback = function()
        local re = getRE("EggHatchService", "Hatch")
        if re then
            for _, eggName in ipairs(eggList) do
                pcall(function() re:FireServer(eggName, Settings.HatchCount) end)
                task.wait(0.1)
            end
            notify("💫 全部孵化完成", "已孵化三种蛋")
        end
    end
})

-- 自动孵蛋开关 (当前选择的蛋)
TabEgg:Toggle({
    Title = "🔄 自动孵蛋 (当前蛋)",
    Default = false,
    Callback = function(state)
        Flags.AutoHatch = state
        if state then
            notify("✅ 自动孵蛋已开启", "蛋: " .. Settings.HatchEgg)
        else
            notify("⏹️ 自动孵蛋已关闭", "")
        end
    end
})

-- 自动孵蛋循环 (单个蛋)
task.spawn(function()
    while true do
        if Flags.AutoHatch then
            local re = getRE("EggHatchService", "Hatch")
            if re then
                pcall(function() re:FireServer(Settings.HatchEgg, Settings.HatchCount) end)
            end
            task.wait(Settings.HatchDelay)
        else
            task.wait(0.5)
        end
    end
end)

-- 自动孵蛋开关 (所有蛋轮流)
TabEgg:Toggle({
    Title = "🔄 自动孵化全部蛋 (轮流)",
    Default = false,
    Callback = function(state)
        Flags.AutoHatchAll = state
        if state then
            notify("✅ 自动轮流孵化已开启", "三种蛋轮流")
        else
            notify("⏹️ 自动轮流孵化已关闭", "")
        end
    end
})

-- 自动轮流孵蛋循环
task.spawn(function()
    while true do
        if Flags.AutoHatchAll then
            local re = getRE("EggHatchService", "Hatch")
            if re then
                for _, eggName in ipairs(eggList) do
                    if Flags.AutoHatchAll then
                        pcall(function() re:FireServer(eggName, Settings.HatchCount) end)
                        task.wait(0.15)
                    end
                end
            end
            task.wait(Settings.HatchDelay)
        else
            task.wait(0.5)
        end
    end
end)

-- ============================================================
-- Tab 3: 奖励系统 (在线奖励 / 转盘 / 转生)
-- ============================================================
local TabReward = Window:Tab({
    Title = "奖励",
    Icon = "gift",
    Locked = false,
})

TabReward:Section({Title = "🎁 在线奖励", TextXAlignment = "Left", TextSize = 17})

-- 一键领取全部在线奖励
TabReward:Button({
    Title = "🎁 一键领取全部在线奖励 (1-12)",
    Callback = function()
        local re = getRE("OnlineRewardService", "ClaimOnlineReward")
        if re then
            task.spawn(function()
                for i = 1, 12 do
                    pcall(function() re:FireServer(i) end)
                    task.wait(0.1)
                end
                notify("🎁 领取完成", "已尝试领取1-12全部奖励")
            end)
        end
    end
})

-- 自动领取在线奖励
TabReward:Toggle({
    Title = "🔄 自动领取在线奖励 (循环)",
    Default = false,
    Callback = function(state)
        Flags.AutoClaimReward = state
        if state then
            notify("✅ 自动领奖已开启", "")
        else
            notify("⏹️ 自动领奖已关闭", "")
        end
    end
})

-- 自动领奖循环
task.spawn(function()
    while true do
        if Flags.AutoClaimReward then
            local re = getRE("OnlineRewardService", "ClaimOnlineReward")
            if re then
                for i = 1, 12 do
                    if Flags.AutoClaimReward then
                        pcall(function() re:FireServer(i) end)
                        task.wait(0.15)
                    end
                end
            end
            task.wait(30) -- 每30秒循环一次
        else
            task.wait(1)
        end
    end
end)

-- 分别领取按钮 (快速领取单个)
TabReward:Section({Title = "📋 单独领取", TextXAlignment = "Left", TextSize = 15})

TabReward:Dropdown({
    Title = "选择要领取的奖励天数",
    Values = {"第1天","第2天","第3天","第4天","第5天","第6天","第7天","第8天","第9天","第10天","第11天","第12天"},
    Value = "第1天",
    Callback = function(value)
        local day = tonumber(value:match("%d+"))
        Settings.ClaimDay = day
    end
})

TabReward:Button({
    Title = "领取选中天数的奖励",
    Callback = function()
        local re = getRE("OnlineRewardService", "ClaimOnlineReward")
        if re and Settings.ClaimDay then
            pcall(function() re:FireServer(Settings.ClaimDay) end)
            notify("🎁 领取中", "第" .. tostring(Settings.ClaimDay) .. "天奖励")
        end
    end
})

-- ========== 转盘系统 ==========
TabReward:Section({Title = "🎡 转盘系统", TextXAlignment = "Left", TextSize = 17})

TabReward:Button({
    Title = "🎡 转一次盘",
    Callback = function()
        local rf = getRF("SpinningWheelService", "StartSpin")
        if rf then
            local ok, result = pcall(function() return rf:InvokeServer() end)
            if ok then
                notify("🎡 转盘已启动", "")
            else
                notify("⚠️ 转盘失败", tostring(result))
            end
        end
    end
})

TabReward:Toggle({
    Title = "🔄 自动转盘",
    Default = false,
    Callback = function(state)
        Flags.AutoSpin = state
        if state then
            notify("✅ 自动转盘已开启", "")
        else
            notify("⏹️ 自动转盘已关闭", "")
        end
    end
})

-- 自动转盘循环
task.spawn(function()
    while true do
        if Flags.AutoSpin then
            local rf = getRF("SpinningWheelService", "StartSpin")
            if rf then
                pcall(function() rf:InvokeServer() end)
            end
            task.wait(Settings.SpinDelay)
        else
            task.wait(1)
        end
    end
end)

-- ========== 转生系统 ==========
TabReward:Section({Title = "💫 转生系统", TextXAlignment = "Left", TextSize = 17})

TabReward:Button({
    Title = "💫 立即转生",
    Callback = function()
        local rf = getRF("RebirthService", "Rebirth")
        if rf then
            local ok, result = pcall(function() return rf:InvokeServer() end)
            if ok then
                notify("💫 转生成功", "")
            else
                notify("⚠️ 转生失败", tostring(result))
            end
        end
    end
})

TabReward:Slider({
    Title = "自动转生间隔 (秒)",
    Value = {Min = 3, Max = 60, Default = 5},
    Increment = 1,
    Callback = function(value)
        Settings.RebirthDelay = value
    end
})

TabReward:Toggle({
    Title = "🔄 自动转生",
    Default = false,
    Callback = function(state)
        Flags.AutoRebirth = state
        if state then
            notify("✅ 自动转生已开启", "")
        else
            notify("⏹️ 自动转生已关闭", "")
        end
    end
})

-- 自动转生循环
task.spawn(function()
    while true do
        if Flags.AutoRebirth then
            local rf = getRF("RebirthService", "Rebirth")
            if rf then
                pcall(function() rf:InvokeServer() end)
            end
            task.wait(Settings.RebirthDelay)
        else
            task.wait(1)
        end
    end
end)

-- ============================================================
-- Tab 4: 宠物系统
-- ============================================================
local TabPet = Window:Tab({
    Title = "宠物",
    Icon = "paw-print",
    Locked = false,
})

TabPet:Section({Title = "🐾 宠物系统", TextXAlignment = "Left", TextSize = 17})

TabPet:Button({
    Title = "🐾 一键装备最佳宠物",
    Callback = function()
        local re = getRE("PetService", "EquipBestPets")
        if re then
            pcall(function() re:FireServer() end)
            notify("🐾 已装备最佳宠物", "")
        end
    end
})

TabPet:Toggle({
    Title = "🔄 自动装备最佳宠物",
    Default = false,
    Callback = function(state)
        Flags.AutoEquipPets = state
        if state then
            notify("✅ 自动装备宠物已开启", "")
        else
            notify("⏹️ 自动装备宠物已关闭", "")
        end
    end
})

-- 自动装备宠物循环
task.spawn(function()
    while true do
        if Flags.AutoEquipPets then
            local re = getRE("PetService", "EquipBestPets")
            if re then
                pcall(function() re:FireServer() end)
            end
            task.wait(5)
        else
            task.wait(1)
        end
    end
end)

-- ============================================================
-- Tab 5: 一键全开 & 设置
-- ============================================================
local TabSetting = Window:Tab({
    Title = "一键/设置",
    Icon = "settings",
    Locked = false,
})

TabSetting:Section({Title = "🚀 一键全开", TextXAlignment = "Left", TextSize = 17})

TabSetting:Paragraph({
    Title = "🚀 一键执行全部功能",
    Desc = "点击下方按钮即可一次性执行：领取全部奖励 + 转盘 + 转生 + 装备宠物 + 孵蛋",
})

TabSetting:Button({
    Title = "🚀 一键执行全部 (单次)",
    Callback = function()
        notify("🚀 开始执行", "正在执行全部功能...")

        -- 1. 领取全部在线奖励
        local rewardRE = getRE("OnlineRewardService", "ClaimOnlineReward")
        if rewardRE then
            task.spawn(function()
                for i = 1, 12 do
                    pcall(function() rewardRE:FireServer(i) end)
                    task.wait(0.1)
                end
            end)
        end

        -- 2. 转生
        local rebirthRF = getRF("RebirthService", "Rebirth")
        if rebirthRF then
            pcall(function() rebirthRF:InvokeServer() end)
        end

        -- 3. 转盘
        local spinRF = getRF("SpinningWheelService", "StartSpin")
        if spinRF then
            pcall(function() spinRF:InvokeServer() end)
        end

        -- 4. 装备最佳宠物
        local petRE = getRE("PetService", "EquipBestPets")
        if petRE then
            pcall(function() petRE:FireServer() end)
        end

        -- 5. 孵蛋 (全部三种)
        local hatchRE = getRE("EggHatchService", "Hatch")
        if hatchRE then
            for _, eggName in ipairs({"Egg_1_1", "Egg_1_2", "Egg_1_3"}) do
                pcall(function() hatchRE:FireServer(eggName, 1) end)
                task.wait(0.1)
            end
        end

        task.wait(1)
        notify("✅ 全部执行完成", "所有单次功能已执行")
    end
})

TabSetting:Button({
    Title = "⚡ 一键开启全部自动功能",
    Callback = function()
        Flags.AutoFarm = true
        Flags.AutoHatch = true
        Flags.AutoHatchAll = true
        Flags.AutoClaimReward = true
        Flags.AutoSpin = true
        Flags.AutoRebirth = true
        Flags.AutoEquipPets = true
        notify("⚡ 全部自动已开启", "所有自动功能已激活")
    end
})

TabSetting:Button({
    Title = "🛑 一键关闭全部自动功能",
    Callback = function()
        Flags.AutoFarm = false
        Flags.AutoHatch = false
        Flags.AutoHatchAll = false
        Flags.AutoClaimReward = false
        Flags.AutoSpin = false
        Flags.AutoRebirth = false
        Flags.AutoEquipPets = false
        Flags.AutoKillAll = false
        notify("🛑 全部已关闭", "所有自动功能已停止")
    end
})

-- ========== 主题设置 ==========
TabSetting:Section({Title = "🎨 主题设置", TextXAlignment = "Left", TextSize = 17})

TabSetting:Dropdown({
    Title = "选择主题颜色",
    Values = {"Pink", "Blue", "Green", "Purple", "Red", "Orange", "Yellow", "Dark"},
    Value = "Pink",
    Callback = function(value)
        Window:SettingTheme(value)
        notify("🎨 主题已切换", value)
    end
})

-- ========== 关于 ==========
TabSetting:Section({Title = "ℹ️ 关于", TextXAlignment = "Left", TextSize = 17})

TabSetting:Paragraph({
    Title = "Suzume 全功能脚本",
    Desc = "基于 WindUI | 适配手机端\n功能包含: 自动刷怪/技能/孵蛋/领奖/转盘/转生/宠物",
    ImageSize = 20,
    Buttons = {
        {
            Title = "复制脚本信息",
            Icon = "copy",
            Variant = "Tertiary",
            Callback = function()
                if setclipboard then
                    setclipboard("Suzume Script - 全功能自动脚本")
                    notify("已复制", "脚本信息已复制到剪贴板")
                else
                    notify("错误", "当前设备不支持复制功能")
                end
            end
        }
    }
})

-- ========== 启动通知 ==========
task.wait(1)
notify("🎉 脚本已加载", "欢迎使用 Suzume 全功能脚本!")
