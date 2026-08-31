local repo = "https://raw.githubusercontent.com/ATLASTEAM01/Obsidian/main/"
local _startTime = tick()
local _lastUpdate = "2026年8月31日12时26分"

-- 安全加载函数
local function safeLoad(url)
    local ok, content = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and content and #content > 0 then
        local fn = loadstring(content)
        if fn then return fn() end
    end
end

local Library = safeLoad(repo .. "Library.lua")
local ThemeManager = safeLoad(repo .. "addons/ThemeManager.lua")
local SaveManager = safeLoad(repo .. "addons/SaveManager.lua")

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({ Title = "XJW中心", Footer = "1.3", Center = true, AutoShow = true })

local Tabs = {
    Announcement = Window:AddTab("公告", "megaphone"),
    Main = Window:AddTab("主页", "user"),
    TP = Window:AddTab("传送和甩飞", "send"),
    Visual = Window:AddTab("视觉", "eye"),
}

-- 公告
local AnnouncementBox = Tabs.Announcement:AddLeftGroupbox("公告")
AnnouncementBox:AddLabel("祝你天天开心，脚本禁止倒卖 ")
AnnouncementBox:AddLabel("作者B站UID: 3706985503525348")
AnnouncementBox:AddLabel("脚本会持续更新，永久免费")
AnnouncementBox:AddLabel("更新时间: " .. _lastUpdate)

-- 信息功能
local InfoBox = Tabs.Announcement:AddLeftGroupbox("信息")
local lp = game.Players.LocalPlayer
InfoBox:AddLabel("用户名: " .. lp.Name)
InfoBox:AddLabel("显示名称: " .. lp.DisplayName)
InfoBox:AddLabel("用户ID: " .. lp.UserId)
InfoBox:AddLabel("账户年龄(天): " .. lp.AccountAge)
InfoBox:AddLabel("语言: " .. lp.LocaleId)
local execName = "未知"
pcall(function() execName = identifyexecutor() end)
InfoBox:AddLabel("注入器: " .. execName)
InfoBox:AddLabel("游戏ID: " .. tostring(game.PlaceId))
InfoBox:AddLabel("服务器ID: " .. tostring(game.JobId))
InfoBox:AddLabel("Roblox版本: " .. version())
InfoBox:AddLabel("设备: " .. (game:GetService("UserInputService").TouchEnabled and "移动设备" or "电脑"))

InfoBox:AddButton("复制所有信息", function()
    local info = {}
    table.insert(info, "=== XJW中心 - 信息 ===")
    table.insert(info, "用户名: " .. lp.Name)
    table.insert(info, "显示名称: " .. lp.DisplayName)
    table.insert(info, "用户ID: " .. lp.UserId)
    table.insert(info, "账户年龄(天): " .. lp.AccountAge)
    table.insert(info, "注入器: " .. execName)
    table.insert(info, "游戏ID: " .. tostring(game.PlaceId))
    table.insert(info, "服务器ID: " .. tostring(game.JobId))
    table.insert(info, "Roblox版本: " .. version())
    table.insert(info, "=== " .. os.date("%Y-%m-%d %H:%M:%S") .. " ===")
    pcall(function() setclipboard(table.concat(info, "\n")) end)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", { Title = "成功", Text = "信息已复制到剪贴板", Duration = 3 })
    end)
end)

-- 主页
local FeatureBox = Tabs.Main:AddRightGroupbox("功能")
FeatureBox:AddButton("XJW飞行", function()
    safeLoad("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E8%87%AA%E5%88%B6%E8%84%9A%E6%9C%AC%E9%A3%9E%E8%A1%8C.lua")
end)

FeatureBox:AddButton("静默甩飞", function()
    safeLoad("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E9%9D%99%E9%BB%98%E7%94%A9%E9%A3%9E(%E5%BC%80%E6%BA%90).lua")
end)

FeatureBox:AddButton("祖国人汉化", function()
    safeLoad("https://raw.githubusercontent.com/kongbaNB/-/refs/heads/main/%E7%A5%96%E5%9B%BD%E4%BA%BA%E6%B1%89%E5%8C%96")
end)

FeatureBox:AddButton("无敌少侠飞行r15", function()
    local ok, err = pcall(function()
        safeLoad("https://raw.githubusercontent.com/396abc/Script/refs/heads/main/MobileFly.lua")
    end)
    if not ok then
        game.StarterGui:SetCore("SendNotification", {Title = "加载失败", Text = tostring(err):sub(1, 100), Duration = 5})
    end
end)

-- ============================================
-- 玩家交互功能 (传送/坐头/甩飞/视角监视/恶搞跟随)
-- ============================================
local PPlayers = game:GetService("Players")
local PLocalPlayer = PPlayers.LocalPlayer
local PRunService = game:GetService("RunService")

local function pNotify(title, text)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 3 })
    end)
end

local function getLocalChar()
    return PLocalPlayer.Character
end

local function getTargetPlayer(name)
    for _, p in ipairs(PPlayers:GetPlayers()) do
        if p.Name == name or p.DisplayName == name then return p end
    end
    return nil
end

local function disableCollision(char)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end

local function enableCollision(char)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = true end
    end
end

local PState = { conns = {}, threads = {} }
local function stopAllConns()
    for name, conn in pairs(PState.conns) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
            PState.conns[name] = nil
        end
    end
    for _, thread in ipairs(PState.threads) do
        if thread then task.cancel(thread) end
    end
    PState.threads = {}
end

-- 通用玩家列表刷新函数
local function refreshPlayerNames()
    local names = {}
    for _, p in ipairs(PPlayers:GetPlayers()) do
        if p ~= PLocalPlayer then table.insert(names, p.Name) end
    end
    table.sort(names)
    return names
end

-- ========== 1. 传送功能 ==========
local TeleportBox = Tabs.TP:AddLeftGroupbox("传送功能")
local tpTargetName = ""
local tpDropdown = TeleportBox:AddDropdown("TP2_Target", {
    Text = "选择目标玩家",
    Values = {},
    Default = "",
    Multi = false,
})
tpDropdown:OnChanged(function(v) tpTargetName = v end)

TeleportBox:AddButton("刷新玩家列表", function()
    tpDropdown:SetValues(refreshPlayerNames())
    pNotify("刷新", "已刷新玩家列表")
end)

TeleportBox:AddButton("传送到选定玩家", function()
    if tpTargetName == "" then pNotify("提示", "请先选择玩家") return end
    local target = getTargetPlayer(tpTargetName)
    if not target or not target.Character then pNotify("失败", "目标不存在") return end
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if root and targetRoot then
        root.CFrame = targetRoot.CFrame
        pNotify("成功", "已传送到 " .. target.Name)
    end
end)

local tpLoopSingle = false
TeleportBox:AddToggle("TP2_LoopSingle", { Text = "循环传送", Default = false }):OnChanged(function(v)
    tpLoopSingle = v
    if v then
        local thread = task.spawn(function()
            while tpLoopSingle do
                if tpTargetName ~= "" then
                    local target = getTargetPlayer(tpTargetName)
                    if target and target.Character then
                        local char = getLocalChar()
                        if char then
                            local root = char:FindFirstChild("HumanoidRootPart")
                            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                            if root and targetRoot then root.CFrame = targetRoot.CFrame end
                        end
                    end
                end
                task.wait(0.3)
            end
        end)
        table.insert(PState.threads, thread)
    end
end)

-- ========== 2. 坐头功能 ==========
local HeadSitBox = Tabs.TP:AddLeftGroupbox("坐头功能")
local sitHeadTargetName = ""
local sitHeadDropdown = HeadSitBox:AddDropdown("SitHead_Target", {
    Text = "选择目标玩家",
    Values = {},
    Default = "",
    Multi = false,
})
sitHeadDropdown:OnChanged(function(v) sitHeadTargetName = v end)

HeadSitBox:AddButton("刷新玩家列表", function()
    sitHeadDropdown:SetValues(refreshPlayerNames())
    pNotify("刷新", "已刷新玩家列表")
end)

local headSitActive = false
local loopHeadSit = false

local function stopHeadSit()
    headSitActive = false
    if PState.conns.headSit then
        PState.conns.headSit:Disconnect()
        PState.conns.headSit = nil
    end
    local char = getLocalChar()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = false end
        enableCollision(char)
    end
    pNotify("坐头停止", "已停止坐头")
end

local function startHeadSit(playerName)
    if PState.conns.headSit then
        PState.conns.headSit:Disconnect()
        PState.conns.headSit = nil
    end
    headSitActive = true
    local char = getLocalChar()
    if not char then pNotify("失败", "角色未加载") headSitActive = false return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then pNotify("失败", "角色缺少部件") headSitActive = false return end
    disableCollision(char)
    hum.Sit = true
    PState.conns.headSit = PRunService.Heartbeat:Connect(function()
        pcall(function()
            if not headSitActive or not char.Parent then
                if loopHeadSit and PLocalPlayer.Character then
                    task.wait(1)
                    if loopHeadSit and sitHeadTargetName ~= "" then
                        startHeadSit(sitHeadTargetName)
                    end
                else
                    stopHeadSit()
                end
                return
            end
            local target = getTargetPlayer(playerName)
            if not target or not target.Character then
                if loopHeadSit then
                    task.wait(1)
                    if loopHeadSit and sitHeadTargetName ~= "" then
                        startHeadSit(sitHeadTargetName)
                    end
                else
                    stopHeadSit()
                end
                return
            end
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if not targetRoot then return end
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 1.6, 0.4)
            disableCollision(char)
        end)
    end)
    pNotify("坐头启动", "已开始坐 " .. tostring(playerName) .. " 的头")
end

HeadSitBox:AddButton("坐选定玩家头上", function()
    if sitHeadTargetName == "" then pNotify("提示", "请先选择玩家") return end
    stopHeadSit()
    startHeadSit(sitHeadTargetName)
end)

HeadSitBox:AddToggle("SitHead_Loop", { Text = "循环坐头(死亡后继续)", Default = false }):OnChanged(function(v)
    loopHeadSit = v
    if v and sitHeadTargetName ~= "" then
        stopHeadSit()
        startHeadSit(sitHeadTargetName)
    else
        stopHeadSit()
    end
end)

HeadSitBox:AddButton("停止坐头", stopHeadSit)

-- ========== 3. 甩飞功能 ==========
local FlingBox2 = Tabs.TP:AddLeftGroupbox("甩飞功能")
local flingTargetName = ""
local flingDropdown = FlingBox2:AddDropdown("Fling2_Target", {
    Text = "选择目标玩家",
    Values = {},
    Default = "",
    Multi = false,
})
flingDropdown:OnChanged(function(v) flingTargetName = v end)

FlingBox2:AddButton("刷新玩家列表", function()
    flingDropdown:SetValues(refreshPlayerNames())
    pNotify("刷新", "已刷新玩家列表")
end)

local flingLoops2 = { single = false, all = false }

local function SkidFling2(targetPlayer)
    local Player = PLocalPlayer
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    if not RootPart then return end

    local TCharacter = targetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if RootPart.Velocity.Magnitude < 50 then
        getgenv().OldPos = RootPart.CFrame
    end
    if THumanoid and THumanoid.Sit then return end
    if THead then
        workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then
        workspace.CurrentCamera.CameraSubject = Handle
    elseif THumanoid then
        workspace.CurrentCamera.CameraSubject = THumanoid
    end

    local FPos = function(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local SFBasePart = function(BasePart)
        local TimeToWait = 2
        local Time = tick()
        local Angle = 0
        repeat
            if RootPart and THumanoid then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                end
            else
                break
            end
        until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= targetPlayer.Character or targetPlayer.Parent ~= PPlayers or not targetPlayer.Character == TCharacter or (THumanoid and THumanoid.Sit) or Humanoid.Health <= 0 or tick() > Time + TimeToWait
    end

    workspace.FallenPartsDestroyHeight = 0/0
    local BV = Instance.new("BodyVelocity")
    BV.Name = "EpixVel"
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if TRootPart and THead then
        if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
            SFBasePart(THead)
        else
            SFBasePart(TRootPart)
        end
    elseif TRootPart then
        SFBasePart(TRootPart)
    elseif THead then
        SFBasePart(THead)
    elseif Handle then
        SFBasePart(Handle)
    else
        return
    end

    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = Humanoid

    repeat
        RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
        Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
        Humanoid:ChangeState("GettingUp")
        table.foreach(Character:GetChildren(), function(_, x)
            if x:IsA("BasePart") then
                x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
            end
        end)
        task.wait()
    until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
    workspace.FallenPartsDestroyHeight = getgenv().FPDH
end

FlingBox2:AddButton("甩飞选定玩家", function()
    if flingTargetName == "" then pNotify("错误", "请先选择玩家") return end
    local target = getTargetPlayer(flingTargetName)
    if not target then pNotify("错误", "未找到玩家") return end
    pcall(function() SkidFling2(target) end)
    pNotify("成功", "甩飞玩家一次")
end)

FlingBox2:AddToggle("Fling2_LoopSingle", { Text = "循环甩飞选定玩家", Default = false }):OnChanged(function(v)
    flingLoops2.single = v
    if v then
        local thread = task.spawn(function()
            while flingLoops2.single do
                if flingTargetName ~= "" then
                    local target = getTargetPlayer(flingTargetName)
                    if target then pcall(function() SkidFling2(target) end) end
                end
                task.wait(0.1)
            end
        end)
        table.insert(PState.threads, thread)
        pNotify("开始", "循环甩飞玩家")
    else
        pNotify("停止", "循环甩飞已停止")
    end
end)

FlingBox2:AddButton("甩飞所有玩家", function()
    local count = 0
    for _, p in ipairs(PPlayers:GetPlayers()) do
        if p ~= PLocalPlayer and p.Character then
            pcall(function() SkidFling2(p) end)
            count = count + 1
            task.wait(0.1)
        end
    end
    pNotify("成功", "已甩飞 " .. count .. " 个玩家")
end)

FlingBox2:AddToggle("Fling2_LoopAll", { Text = "循环甩飞所有玩家", Default = false }):OnChanged(function(v)
    flingLoops2.all = v
    if v then
        local thread = task.spawn(function()
            while flingLoops2.all do
                for _, p in ipairs(PPlayers:GetPlayers()) do
                    if p ~= PLocalPlayer and p.Character then
                        pcall(function() SkidFling2(p) end)
                    end
                    task.wait(0.05)
                end
                task.wait(0.1)
            end
        end)
        table.insert(PState.threads, thread)
        pNotify("开始", "循环甩飞所有玩家")
    else
        pNotify("停止", "循环甩飞所有玩家已停止")
    end
end)

FlingBox2:AddButton("停止所有甩飞", function()
    flingLoops2.single = false
    flingLoops2.all = false
    pNotify("停止", "已停止所有甩飞")
end)

-- ========== 4. 视角监视 ==========
local MonitorBox2 = Tabs.TP:AddRightGroupbox("视角监视")
local monitorTargetName = ""
local monitorDropdown = MonitorBox2:AddDropdown("Monitor2_Target", {
    Text = "选择目标玩家",
    Values = {},
    Default = "",
    Multi = false,
})
monitorDropdown:OnChanged(function(v) monitorTargetName = v end)

MonitorBox2:AddButton("刷新玩家列表", function()
    monitorDropdown:SetValues(refreshPlayerNames())
    pNotify("刷新", "已刷新玩家列表")
end)

local function stopMonitor2()
    if PState.conns.monitor then
        PState.conns.monitor:Disconnect()
        PState.conns.monitor = nil
    end
    local char = getLocalChar()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then workspace.CurrentCamera.CameraSubject = hum end
    end
    pNotify("监视停止", "已停止监视")
end

local function startMonitor2(playerName)
    if PState.conns.monitor then
        PState.conns.monitor:Disconnect()
        PState.conns.monitor = nil
    end
    local camera = workspace.CurrentCamera
    if not camera then return end
    PState.conns.monitor = PRunService.Heartbeat:Connect(function()
        pcall(function()
            local target = getTargetPlayer(playerName)
            if not target or not target.Character then
                stopMonitor2()
                return
            end
            local subject = target.Character:FindFirstChildOfClass("Humanoid")
            if not subject then
                subject = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
            end
            if subject then
                camera.CameraSubject = subject
            end
        end)
    end)
    pNotify("监视启动", "已开始监视 " .. playerName)
end

MonitorBox2:AddButton("开始监视选定玩家", function()
    if monitorTargetName == "" then pNotify("提示", "请先选择玩家") return end
    stopMonitor2()
    startMonitor2(monitorTargetName)
end)

MonitorBox2:AddButton("停止监视", stopMonitor2)

-- ========== 5. 恶搞跟随 (14种模式) ==========
local FollowBox2 = Tabs.TP:AddRightGroupbox("恶搞跟随")
local followTargetName = ""
local followDropdown = FollowBox2:AddDropdown("Follow2_Target", {
    Text = "选择目标玩家",
    Values = {},
    Default = "",
    Multi = false,
})
followDropdown:OnChanged(function(v) followTargetName = v end)

FollowBox2:AddButton("刷新玩家列表", function()
    followDropdown:SetValues(refreshPlayerNames())
    pNotify("刷新", "已刷新玩家列表")
end)

local followStates2 = {}

local function stopAllFollows2()
    for name, _ in pairs(followStates2) do
        followStates2[name] = false
    end
    for name, conn in pairs(PState.conns) do
        if name:find("follow2_") then
            conn:Disconnect()
            PState.conns[name] = nil
        end
    end
    local char = getLocalChar()
    if char then enableCollision(char) end
end

local function makeFollow(id, desc, offset_fn)
    followStates2[id] = false
    return function(target)
        stopAllFollows2()
        followStates2[id] = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if offset_fn.collide == false then
            -- keep collision
        else
            disableCollision(char)
        end
        PState.conns["follow2_" .. id] = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2[id] or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                local cf = offset_fn(tr, root, char)
                if cf then root.CFrame = cf end
            end)
        end)
    end
end

local followToggles2 = {
    { id = "orbit", text = "旋转环绕", fn = function(target)
        followStates2.orbit = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        disableCollision(char)
        local angle = 0
        PState.conns.follow2_orbit = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.orbit or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                angle = angle + 0.05
                if angle > 360 then angle = 0 end
                root.CFrame = CFrame.new(tr.Position + Vector3.new(math.cos(angle)*5, 2, math.sin(angle)*5), tr.Position)
            end)
        end)
    end },
    { id = "mirror", text = "镜像", fn = function(target)
        followStates2.mirror = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        disableCollision(char)
        PState.conns.follow2_mirror = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.mirror or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                local pos = tr.CFrame * CFrame.new(4, 0, 0)
                root.CFrame = CFrame.new(pos.Position) * CFrame.Angles(0, math.pi, 0)
            end)
        end)
    end },
    { id = "float", text = "漂浮", fn = function(target)
        followStates2.float = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        disableCollision(char)
        PState.conns.follow2_float = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.float or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                root.CFrame = CFrame.new(tr.Position + Vector3.new(0, 3, 0))
            end)
        end)
    end },
    { id = "shadow", text = "影子", fn = function(target)
        followStates2.shadow = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        disableCollision(char)
        PState.conns.follow2_shadow = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.shadow or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                root.CFrame = tr.CFrame * CFrame.new(0, -2.8, 0)
            end)
        end)
    end },
    { id = "anti", text = "反向跟随", fn = function(target)
        followStates2.anti = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        PState.conns.follow2_anti = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.anti or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                local dist = (root.Position - tr.Position).Magnitude
                if dist < 8 then
                    local away = (root.Position - tr.Position).Unit
                    root.CFrame = CFrame.new(tr.Position + away * 8)
                end
            end)
        end)
    end },
    { id = "spin", text = "旋转", fn = function(target)
        followStates2.spin = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        disableCollision(char)
        local angle = 0
        PState.conns.follow2_spin = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.spin or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                angle = angle + 5
                root.CFrame = CFrame.new(tr.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad(angle), 0)
            end)
        end)
    end },
    { id = "shake", text = "抖动", fn = function(target)
        followStates2.shake = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        disableCollision(char)
        PState.conns.follow2_shake = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.shake or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                local offset = Vector3.new(math.random(-2, 2), math.random(0, 3), math.random(-2, 2))
                root.CFrame = CFrame.new(tr.Position + offset)
            end)
        end)
    end },
    { id = "face", text = "站头后", fn = function(target)
        followStates2.face = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        disableCollision(char)
        PState.conns.follow2_face = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.face or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                root.CFrame = tr.CFrame * CFrame.new(0, 3.5, 0)
            end)
        end)
    end },
    { id = "back", text = "坐前面", fn = function(target)
        followStates2.back = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = true end
        disableCollision(char)
        PState.conns.follow2_back = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.back or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                root.CFrame = tr.CFrame * CFrame.new(0, 0, 2)
                if hum then hum.Sit = true end
            end)
        end)
    end },
    { id = "auto", text = "动画跟随", fn = function(target)
        followStates2.auto = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        disableCollision(char)
        PState.conns.follow2_auto = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.auto or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                root.CFrame = tr.CFrame * CFrame.new(0, 0, -3)
            end)
        end)
    end },
    { id = "suck", text = "口交", fn = function(target)
        followStates2.suck = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        disableCollision(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = true end
        PState.conns.follow2_suck = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.suck or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                root.CFrame = tr.CFrame * CFrame.new(0, -1, 1)
                if hum then hum.Sit = true end
            end)
        end)
    end },
    { id = "sus", text = "被超", fn = function(target)
        followStates2.sus = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        disableCollision(char)
        PState.conns.follow2_sus = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.sus or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                root.CFrame = tr.CFrame * CFrame.new(0, 0, -1)
            end)
        end)
    end },
    { id = "modern", text = "超别人", fn = function(target)
        followStates2.modern = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        disableCollision(char)
        PState.conns.follow2_modern = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.modern or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                root.CFrame = tr.CFrame * CFrame.new(0, 0, 1)
            end)
        end)
    end },
    { id = "enhanced", text = "给别人口", fn = function(target)
        followStates2.enhanced = true
        local char = getLocalChar()
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        disableCollision(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = true end
        PState.conns.follow2_enhanced = PRunService.Heartbeat:Connect(function()
            pcall(function()
                if not followStates2.enhanced or not char.Parent then return end
                if not target.Character then stopAllFollows2() return end
                local tr = target.Character:FindFirstChild("HumanoidRootPart")
                if not tr then return end
                root.CFrame = tr.CFrame * CFrame.new(0, -1, -0.5)
                if hum then hum.Sit = true end
            end)
        end)
    end },
}

for _, ft in ipairs(followToggles2) do
    FollowBox2:AddToggle("F2_" .. ft.id, { Text = ft.text, Default = false }):OnChanged(function(v)
        if v then
            stopAllFollows2()
            if followTargetName == "" then pNotify("提示", "请先选择玩家") return end
            local target = getTargetPlayer(followTargetName)
            if target then
                ft.fn(target)
                pNotify("跟随", "已开启: " .. ft.text)
            end
        else
            stopAllFollows2()
            pNotify("停止", "已停止所有跟随")
        end
    end)
end

FollowBox2:AddButton("停止所有跟随", function()
    stopAllFollows2()
    pNotify("停止", "已停止所有恶搞跟随")
end)

-- ============================================
-- 角色修改功能 (6个功能)
-- ============================================
local CharPlayers = game:GetService("Players")
local CharRunService = game:GetService("RunService")
local CharLighting = game:GetService("Lighting")
local CharUserInputService = game:GetService("UserInputService")
local CharVirtualInputManager = game:GetService("VirtualInputManager")
local CharWorkspace = game:GetService("Workspace")
local CharLocalPlayer = CharPlayers.LocalPlayer

local charCharacter, charHumanoid, charHrp
local function charRefresh()
    charCharacter = CharLocalPlayer.Character
    if charCharacter then
        charHumanoid = charCharacter:FindFirstChildOfClass("Humanoid")
        charHrp = charCharacter:FindFirstChild("HumanoidRootPart")
    end
end
charRefresh()

local CharStates = {
    WalkSpeed = {Enabled = false, Value = 100, Default = 16},
    Noclip = {Enabled = false},
    BunnyHop = {Enabled = false, Value = 5},
    SuperJump = {Enabled = false, Value = 200},
    WallClimb = {Enabled = false, Value = 50},
    NightVision = {Enabled = false},
    AntiAfk = {Enabled = false},
}

local CharConns = {}
local function charBind(name, conn)
    if CharConns[name] then CharConns[name]:Disconnect() end
    CharConns[name] = conn
end

-- 1. 修改移速
local function applyWalkSpeed()
    if not charHumanoid then return end
    if CharStates.WalkSpeed.Enabled then
        charHumanoid.WalkSpeed = CharStates.WalkSpeed.Value
    else
        charHumanoid.WalkSpeed = CharStates.WalkSpeed.Default
    end
end

-- 2. 穿墙模式 (Noclip) - BS源码版
local noclipActive = false
local noclipConn = nil
local noclipCharAddedConn = nil
local noclipDescendantConns = {}
local noclipOriginalCollisions = {}

local function setupNoclipForChar(character)
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if not noclipOriginalCollisions[part] then
                noclipOriginalCollisions[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end
    local dc = character.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            if not noclipOriginalCollisions[descendant] then
                noclipOriginalCollisions[descendant] = descendant.CanCollide
            end
            descendant.CanCollide = false
        end
    end)
    noclipDescendantConns[character] = dc
end

local function startNoclip()
    noclipActive = true
    if noclipConn then return end
    local char = CharLocalPlayer.Character
    if char then setupNoclipForChar(char) end
    noclipConn = CharRunService.Stepped:Connect(function()
        if not noclipActive then return end
        local currentChar = CharLocalPlayer.Character
        if not currentChar then return end
        for _, part in pairs(currentChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    if noclipCharAddedConn then noclipCharAddedConn:Disconnect() end
    noclipCharAddedConn = CharLocalPlayer.CharacterAdded:Connect(function(newChar)
        if noclipActive then
            task.wait()
            setupNoclipForChar(newChar)
        end
    end)
end

local function stopNoclip()
    noclipActive = false
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    if noclipCharAddedConn then
        noclipCharAddedConn:Disconnect()
        noclipCharAddedConn = nil
    end
    for part, originalState in pairs(noclipOriginalCollisions) do
        if part and part.Parent then
            part.CanCollide = originalState
        end
    end
    for character, conn in pairs(noclipDescendantConns) do
        if conn then conn:Disconnect() end
    end
    noclipDescendantConns = {}
    noclipOriginalCollisions = {}
end

-- 3. 无限跳 (JumpRequest触发连续跳跃)
charBind("BunnyHop", CharUserInputService.JumpRequest:Connect(function()
    if CharStates.BunnyHop.Enabled and charHumanoid then
        charHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

-- 4. 超级跳跃
local function applySuperJump()
    if not charHumanoid then return end
    if CharStates.SuperJump.Enabled then
        pcall(function()
            charHumanoid.UseJumpPower = true
            charHumanoid.JumpPower = CharStates.SuperJump.Value
            charHumanoid.JumpHeight = CharStates.SuperJump.Value
        end)
    else
        pcall(function()
            charHumanoid.JumpPower = 50
            charHumanoid.JumpHeight = 7.2
        end)
    end
end

charBind("SuperJump", CharUserInputService.JumpRequest:Connect(function()
    if CharStates.SuperJump.Enabled and charHumanoid then
        pcall(function()
            charHumanoid.UseJumpPower = true
            charHumanoid.JumpPower = CharStates.SuperJump.Value
            charHumanoid.JumpHeight = CharStates.SuperJump.Value
        end)
    end
end))

-- 5. 爬墙模式
charBind("WallClimb", CharRunService.Heartbeat:Connect(function()
    if not CharStates.WallClimb.Enabled then return end
    if not charCharacter or not charHrp or not charHumanoid then return end
    if not charCharacter.Parent then return end
    pcall(function()
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {charCharacter}
        local forward = charHrp.CFrame.LookVector
        local result = CharWorkspace:Raycast(charHrp.Position, forward * 3, rayParams)
        if result then
            local normal = result.Normal
            if math.abs(normal.Y) < 0.5 then
                charHumanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                charHrp.Velocity = Vector3.new(charHrp.Velocity.X, CharStates.WallClimb.Value, charHrp.Velocity.Z)
            end
        end
    end)
end))

-- 7. 反挂机 (杂项) - VirtualUser版
local AntiAfkConn = nil
local function startAntiAfk()
    if AntiAfkConn then return end
    local VirtualUser = game:GetService("VirtualUser")
    AntiAfkConn = CharLocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

local function stopAntiAfk()
    if AntiAfkConn then
        AntiAfkConn:Disconnect()
        AntiAfkConn = nil
    end
end

-- 死亡后重新应用所有已开启的功能
local function reapplyAllStates()
    charRefresh()
    if not charCharacter or not charHumanoid then return end
    if CharStates.WalkSpeed.Enabled then applyWalkSpeed() end
    if CharStates.SuperJump.Enabled then applySuperJump() end
    if CharStates.Noclip.Enabled then startNoclip() end
end

CharLocalPlayer.CharacterAdded:Connect(function(c)
    charCharacter = c
    charHumanoid = c:FindFirstChildOfClass("Humanoid")
    charHrp = c:FindFirstChild("HumanoidRootPart")
    task.spawn(function()
        charHumanoid = c:WaitForChild("Humanoid")
        charHrp = c:WaitForChild("HumanoidRootPart")
        reapplyAllStates()
    end)
    task.delay(1, reapplyAllStates)
    task.delay(3, reapplyAllStates)
end)

-- 角色修改 UI
local CharBox = Tabs.Main:AddLeftGroupbox("角色修改")
CharBox:AddToggle("Char_WalkSpeed", { Text = "修改移速", Default = false }):OnChanged(function(v)
    CharStates.WalkSpeed.Enabled = v
    applyWalkSpeed()
end)
CharBox:AddSlider("Char_WalkSpeedVal", { Text = "移速值", Default = 100, Min = 1, Max = 500, Rounding = 0 }):OnChanged(function(v)
    CharStates.WalkSpeed.Value = v
    if CharStates.WalkSpeed.Enabled then applyWalkSpeed() end
end)

CharBox:AddToggle("Char_Noclip", { Text = "穿墙模式", Default = false }):OnChanged(function(v)
    CharStates.Noclip.Enabled = v
    if v then startNoclip() else stopNoclip() end
end)

CharBox:AddToggle("Char_BunnyHop", { Text = "无限跳", Default = false }):OnChanged(function(v)
    CharStates.BunnyHop.Enabled = v
end)

CharBox:AddToggle("Char_SuperJump", { Text = "超级跳跃", Default = false }):OnChanged(function(v)
    CharStates.SuperJump.Enabled = v
    applySuperJump()
end)
CharBox:AddSlider("Char_SuperJumpVal", { Text = "跳跃高度", Default = 200, Min = 1, Max = 500, Rounding = 0 }):OnChanged(function(v)
    CharStates.SuperJump.Value = v
    if CharStates.SuperJump.Enabled then applySuperJump() end
end)

CharBox:AddToggle("Char_WallClimb", { Text = "爬墙模式", Default = false }):OnChanged(function(v)
    CharStates.WallClimb.Enabled = v
end)
CharBox:AddSlider("Char_WallClimbVal", { Text = "爬墙速度", Default = 50, Min = 1, Max = 200, Rounding = 0 }):OnChanged(function(v)
    CharStates.WallClimb.Value = v
end)

-- 脚本区
local MainSettingsBox = Tabs.Main:AddLeftGroupbox("脚本区")
MainSettingsBox:AddButton("ROBv4", function()
    safeLoad("https://raw.githubusercontent.com/idrobsc/rob_script/refs/heads/main/rob.v4")
end)

MainSettingsBox:AddButton("AF HUB", function()
    getgenv().SCRIPT_KEY = ""
    safeLoad("https://api.jnkie.com/api/v1/luascripts/public/4e025c3c0ccda1554634165acb8f8ee2c1de5f0f8d7f60e7b396c622d7e6e9b0/download")
end)

MainSettingsBox:AddButton("叶脚本", function()
    safeLoad("https://raw.githubusercontent.com/roblox-ye/QQ515966991/refs/heads/main/ROBLOX-CNVIP-XIAOYE.lua")
end)

MainSettingsBox:AddButton("恐脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kongbaNB/9178/refs/heads/main/恐脚本加载器"))()
end)

-- 杂项 UI
local MiscBox = Tabs.Main:AddLeftGroupbox("杂项")
MiscBox:AddToggle("Char_AntiAfk", { Text = "反挂机", Default = false }):OnChanged(function(v)
    CharStates.AntiAfk.Enabled = v
    if v then startAntiAfk() else stopAntiAfk() end
end)

-- 假延迟 (Fake Lag) - 整合自假延迟源码
local FakeLag = {
    Enabled = false,
    Interval = 0.07,
    AnchoredDuration = 0.4,
    TeleportEnabled = false,
    TeleportDistance = 10,
}
local fakeLagRunning = false
local function FakeLag_DoTeleport()
    local Character = game.Players.LocalPlayer.Character
    if Character then
        local Root = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChild("Humanoid")
        if Root and Humanoid then
            local MoveDir = Humanoid.MoveDirection
            if MoveDir.Magnitude > 0 then
                local Distance = math.random(FakeLag.TeleportDistance * 100) / 100
                local RootCFrame = Root.CFrame
                local TargetPos = RootCFrame.Position + MoveDir.Unit * Distance
                local LookVector = RootCFrame.LookVector
                Root.CFrame = CFrame.new(TargetPos, TargetPos + LookVector)
            end
        end
    end
end
MiscBox:AddToggle("FakeLag_Enabled", { Text = "假延迟", Default = false }):OnChanged(function(v)
    FakeLag.Enabled = v
    if v and not fakeLagRunning then
        fakeLagRunning = true
        task.spawn(function()
            while fakeLagRunning do
                if FakeLag.Enabled then
                    local Character = game.Players.LocalPlayer.Character
                    if Character then
                        local Root = Character:FindFirstChild("HumanoidRootPart")
                        if Root then
                            Root.Anchored = true
                            task.wait(FakeLag.AnchoredDuration)
                            Root.Anchored = false
                            if FakeLag.TeleportEnabled then
                                FakeLag_DoTeleport()
                            end
                        end
                    end
                end
                task.wait(FakeLag.Interval)
            end
        end)
    end
end)
MiscBox:AddSlider("FakeLag_Interval", { Text = "假延迟间隔", Default = 0.07, Min = 0.07, Max = 1, Rounding = 2 }):OnChanged(function(v)
    FakeLag.Interval = v
end)
MiscBox:AddSlider("FakeLag_Anchored", { Text = "锚定时长", Default = 0.4, Min = 0.1, Max = 10, Rounding = 2 }):OnChanged(function(v)
    FakeLag.AnchoredDuration = v
end)
MiscBox:AddToggle("FakeLag_Teleport", { Text = "假wifi瞬移", Default = false }):OnChanged(function(v)
    FakeLag.TeleportEnabled = v
end)
MiscBox:AddSlider("FakeLag_TeleportDist", { Text = "瞬移距离", Default = 10, Min = 5, Max = 50, Rounding = 0 }):OnChanged(function(v)
    FakeLag.TeleportDistance = v
end)

-- ============================================
-- 旋转 & 防甩飞 & 跟随 & 飞行 & 动作 & IY指令
-- ============================================

-- 旋转功能
local SpinBox = Tabs.Main:AddRightGroupbox("旋转")
local spinRunning = false
local spinSpeed = 10

SpinBox:AddInput("Spin_Speed", { Text = "旋转速度", Default = "10", Numeric = true }):OnChanged(function(text)
    spinSpeed = tonumber(text) or 10
end)

SpinBox:AddToggle("Spin_Enabled", { Text = "旋转开关", Default = false }):OnChanged(function(state)
    if state then
        spinRunning = true
        task.spawn(function()
            local player = game.Players.LocalPlayer
            while spinRunning do
                task.wait()
                local character = player.Character
                if character then
                    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
                    end
                end
            end
        end)
    else
        spinRunning = false
    end
end)

-- 防甩飞 (移到杂项)
local antiflingRunning = false
MiscBox:AddToggle("Antifling_Enabled", { Text = "防甩飞", Default = false }):OnChanged(function(state)
    if state then
        antiflingRunning = true
        task.spawn(function()
            local Players = game:GetService("Players")
            local localPlayer = Players.LocalPlayer
            while antiflingRunning do
                task.wait(0.3)
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= localPlayer and player.Character then
                        for _, part in ipairs(player.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end
        end)
    else
        antiflingRunning = false
        local Players = game:GetService("Players")
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
end)

-- 跟随功能
local FollowBox = Tabs.TP:AddRightGroupbox("跟随功能")
local followTarget = nil
local followForward = 5
local followSide = 0
local followHeight = 0
local followEnabled = false
local followRunning = false

local followDropdown = FollowBox:AddDropdown("Follow_Target", {
    Text = "选择跟随目标",
    Values = {},
    Default = "",
    Multi = false,
})
followDropdown:OnChanged(function(value)
    followTarget = value
end)

FollowBox:AddButton("刷新玩家列表", function()
    local names = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    followDropdown:SetValues(names)
end)

FollowBox:AddSlider("Follow_Forward", { Text = "前后距离", Default = 5, Min = -20, Max = 20, Rounding = 0 }):OnChanged(function(v)
    followForward = v
end)
FollowBox:AddSlider("Follow_Side", { Text = "左右距离", Default = 0, Min = -20, Max = 20, Rounding = 0 }):OnChanged(function(v)
    followSide = v
end)
FollowBox:AddSlider("Follow_Height", { Text = "上下高度", Default = 0, Min = -20, Max = 20, Rounding = 0 }):OnChanged(function(v)
    followHeight = v
end)

FollowBox:AddToggle("Follow_Enabled", { Text = "跟随玩家", Default = false }):OnChanged(function(state)
    followEnabled = state
    if state then
        followRunning = true
        task.spawn(function()
            local player = game.Players.LocalPlayer
            local runService = game:GetService("RunService")
            while followEnabled and followRunning do
                if not followTarget then task.wait(0.1) continue end
                local target = game.Players:FindFirstChild(followTarget)
                local myCharacter = player.Character
                if not target or not target.Character or not myCharacter then task.wait(0.1) continue end
                local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
                if not targetRoot or not myRoot then task.wait(0.1) continue end
                local newPosition = targetRoot.CFrame.Position
                    + (targetRoot.CFrame.LookVector * -followForward)
                    + (targetRoot.CFrame.RightVector * followSide)
                    + (Vector3.new(0, followHeight, 0))
                myRoot.CFrame = CFrame.new(newPosition) * CFrame.Angles(0, targetRoot.CFrame.LookVector.Y, 0)
                runService.RenderStepped:Wait()
            end
        end)
    else
        followRunning = false
    end
end)

-- 玩家进入通知 (移到杂项)
local joinNotifyEnabled = false
MiscBox:AddToggle("JoinNotify_Enabled", { Text = "玩家进入通知", Default = false }):OnChanged(function(state)
    joinNotifyEnabled = state
end)

game.Players.PlayerAdded:Connect(function(player)
    if not joinNotifyEnabled then return end
    local success, thumbnail = pcall(function()
        return game:GetService("Players"):GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    local Frame = Instance.new("Frame")
    Frame.Parent = ScreenGui
    Frame.Size = UDim2.new(0, 250, 0, 50)
    Frame.Position = UDim2.new(0.1, -125, 0.15, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Frame.BorderSizePixel = 0
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Frame
    if success then
        local Avatar = Instance.new("ImageLabel")
        Avatar.Parent = Frame
        Avatar.Size = UDim2.new(0, 35, 0, 35)
        Avatar.Position = UDim2.new(0, 8, 0.5, -17)
        Avatar.Image = thumbnail
    end
    local Title = Instance.new("TextLabel")
    Title.Parent = Frame
    Title.Size = UDim2.new(1, -50, 0, 20)
    Title.Position = UDim2.new(0, 50, 0, 5)
    Title.BackgroundTransparency = 1
    Title.Text = "玩家进入"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    local Content = Instance.new("TextLabel")
    Content.Parent = Frame
    Content.Size = UDim2.new(1, -50, 0, 20)
    Content.Position = UDim2.new(0, 50, 0, 27)
    Content.BackgroundTransparency = 1
    Content.Text = player.DisplayName .. " (@" .. player.Name .. ")"
    Content.TextColor3 = Color3.fromRGB(180, 180, 180)
    Content.Font = Enum.Font.SourceSans
    Content.TextSize = 13
    Content.TextXAlignment = Enum.TextXAlignment.Left
    task.delay(5, function()
        ScreenGui:Destroy()
    end)
end)

-- 动作脚本
local ActionBox = Tabs.Main:AddRightGroupbox("动作脚本")
ActionBox:AddButton("动作脚本", function()
    safeLoad("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua")
end)

ActionBox:AddButton("r6动作脚本", function()
    safeLoad("https://rawscripts.net/raw/Universal-Script-R6-Animations-Menu-By-Me-19427")
end)

-- IY指令
local IYBox = Tabs.Main:AddRightGroupbox("IY指令")
IYBox:AddButton("执行Dex", function()
    safeLoad("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua")
end)

IYBox:AddButton("执行rspy", function()
    safeLoad("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua")
end)

IYBox:AddButton("执行Cspy", function()
    safeLoad("https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau")
end)

IYBox:AddButton("执行mdex", function()
    safeLoad("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua")
end)

-- ============================================================
pcall(function()
-- BS ESP 高级功能 (从BS源码提取)
-- ============================================================
local BSESPBox = Tabs.Visual:AddLeftGroupbox("ESP设置")

getgenv().BSESPConfig = getgenv().BSESPConfig or {
    ESPEnabled = false,
    ShowBox = false,
    Show3DBox = false,
    ShowHealth = false,
    ShowName = false,
    ShowDistance = false,
    ShowTracer = false,
    TeamCheck = false,
    ShowSkeleton = false,
    ShowRadar = false,
    ShowPlayerCount = false,
    ShowWeapon = false,
    RainbowMode = false,
    HighlightPlayers = false,
    TracerColor = Color3.new(1, 0, 0),
    SkeletonColor = Color3.new(0.2, 0.8, 1),
    BoxColor = Color3.new(1, 1, 1),
    Box3DColor = Color3.new(0, 1, 1),
    HealthBarColor = Color3.new(0, 1, 0),
    HealthTextColor = Color3.new(1, 1, 1),
    NameColor = Color3.new(1, 1, 1),
    DistanceColor = Color3.new(1, 1, 0),
    WeaponColor = Color3.new(1, 0.5, 0),
    ArrowColor = Color3.new(1, 0, 0),
    FOVColor = Color3.new(1, 1, 1),
    HighlightColor = Color3.new(1, 0, 0),
    BoxThickness = 1,
    TracerThickness = 1,
    SkeletonThickness = 2,
    FOVRadius = 100,
    ArrowSize = 15,
}

local BSPlayers = game:GetService("Players")
local BSRunService = game:GetService("RunService")
local BSCamera = workspace.CurrentCamera
local BSLocalPlayer = BSPlayers.LocalPlayer
local BSESPComponents = {}
local BSHighlightInstances = {}
local BSRadarDrawings = {}

local function getBSRainbowColor(time)
    local r = math.sin(time * 2) * 0.5 + 0.5
    local g = math.sin(time * 3) * 0.5 + 0.5
    local b = math.sin(time * 4) * 0.5 + 0.5
    return Color3.new(r, g, b)
end

local function getBSCurrentColor(fixedColor)
    if getgenv().BSESPConfig.RainbowMode then
        return getBSRainbowColor(tick())
    end
    return fixedColor
end

local function initBSRadar()
    local radarFrame = Drawing.new("Square")
    radarFrame.Visible = false
    radarFrame.Color = Color3.new(0, 0, 0)
    radarFrame.Thickness = 2
    radarFrame.Filled = true
    radarFrame.Transparency = 0.5
    radarFrame.Size = Vector2.new(200, 200)
    local radarBorder = Drawing.new("Square")
    radarBorder.Visible = false
    radarBorder.Color = Color3.new(1, 1, 1)
    radarBorder.Thickness = 2
    radarBorder.Filled = false
    radarBorder.Size = Vector2.new(200, 200)
    local radarCrosshairV = Drawing.new("Line")
    radarCrosshairV.Visible = false
    radarCrosshairV.Color = Color3.new(0.5, 0.5, 0.5)
    radarCrosshairV.Thickness = 1
    local radarCrosshairH = Drawing.new("Line")
    radarCrosshairH.Visible = false
    radarCrosshairH.Color = Color3.new(0.5, 0.5, 0.5)
    radarCrosshairH.Thickness = 1
    local localPlayerDot = Drawing.new("Circle")
    localPlayerDot.Visible = false
    localPlayerDot.Color = Color3.new(0, 1, 0)
    localPlayerDot.Radius = 4
    localPlayerDot.Filled = true
    BSRadarDrawings = {
        frame = radarFrame,
        border = radarBorder,
        crosshairV = radarCrosshairV,
        crosshairH = radarCrosshairH,
        localPlayer = localPlayerDot,
        players = {}
    }
end
pcall(function() initBSRadar() end)

local BSplayerCountText
pcall(function() BSplayerCountText = Drawing.new("Text") end)
if BSplayerCountText then
    BSplayerCountText.Visible = false
    BSplayerCountText.Size = 20
    BSplayerCountText.Font = Drawing.Fonts.Monospace
    BSplayerCountText.Outline = true
    BSplayerCountText.OutlineColor = Color3.new(0, 0, 0)
end
BSplayerCountText.Visible = false
BSplayerCountText.Size = 20
BSplayerCountText.Font = Drawing.Fonts.Monospace
BSplayerCountText.Outline = true
BSplayerCountText.OutlineColor = Color3.new(0, 0, 0)

local BSfovCircle
pcall(function()
    BSfovCircle = Drawing.new("Circle")
    BSfovCircle.Thickness = 2
    BSfovCircle.Filled = false
    BSfovCircle.NumSides = 64
end)

local function updateBSRadar()
    if not getgenv().BSESPConfig.ShowRadar or not getgenv().BSESPConfig.ESPEnabled then
        for _, drawing in pairs(BSRadarDrawings) do
            if typeof(drawing) == "table" and drawing.Visible ~= nil then
                drawing.Visible = false
            elseif typeof(drawing) == "table" then
                for _, d in pairs(drawing) do
                    if d.Visible ~= nil then d.Visible = false end
                end
            end
        end
        return
    end
    local radarRadius = 100
    local radarPos = Vector2.new(BSCamera.ViewportSize.X - 220, 20)
    local center = radarPos + Vector2.new(radarRadius, radarRadius)
    BSRadarDrawings.frame.Position = radarPos
    BSRadarDrawings.frame.Visible = true
    BSRadarDrawings.border.Position = radarPos
    BSRadarDrawings.border.Visible = true
    if getgenv().BSESPConfig.RainbowMode then
        local rainbow = getBSRainbowColor(tick())
        BSRadarDrawings.frame.Color = rainbow
        BSRadarDrawings.border.Color = rainbow
    end
    BSRadarDrawings.crosshairV.From = Vector2.new(center.X, radarPos.Y)
    BSRadarDrawings.crosshairV.To = Vector2.new(center.X, radarPos.Y + 200)
    BSRadarDrawings.crosshairV.Visible = true
    BSRadarDrawings.crosshairH.From = Vector2.new(radarPos.X, center.Y)
    BSRadarDrawings.crosshairH.To = Vector2.new(radarPos.X + 200, center.Y)
    BSRadarDrawings.crosshairH.Visible = true
    BSRadarDrawings.localPlayer.Position = center
    BSRadarDrawings.localPlayer.Visible = true
    if getgenv().BSESPConfig.RainbowMode then
        BSRadarDrawings.localPlayer.Color = getBSRainbowColor(tick())
    end
    for player, dot in pairs(BSRadarDrawings.players) do
        if not BSPlayers:FindFirstChild(player.Name) or player == BSLocalPlayer then
            dot:Remove()
            BSRadarDrawings.players[player] = nil
        end
    end
    if BSLocalPlayer.Character and BSLocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local localPos = BSLocalPlayer.Character.HumanoidRootPart.Position
        local localRot = BSLocalPlayer.Character.HumanoidRootPart.CFrame.LookVector
        local localAngle = math.atan2(localRot.X, localRot.Z)
        for _, player in pairs(BSPlayers:GetPlayers()) do
            if player ~= BSLocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local targetPos = player.Character.HumanoidRootPart.Position
                local relativePos = targetPos - localPos
                local rotatedX = relativePos.X * math.cos(-localAngle) - relativePos.Z * math.sin(-localAngle)
                local rotatedZ = relativePos.X * math.sin(-localAngle) + relativePos.Z * math.cos(-localAngle)
                local radarX = rotatedX * 0.5
                local radarY = -rotatedZ * 0.5
                local distance = math.sqrt(radarX^2 + radarY^2)
                local clipped = false
                if distance > radarRadius - 5 then
                    local scale = (radarRadius - 5) / distance
                    radarX = radarX * scale
                    radarY = radarY * scale
                    clipped = true
                end
                if not BSRadarDrawings.players[player] then
                    local dot = Drawing.new("Circle")
                    dot.Radius = clipped and 2 or 3
                    dot.Filled = true
                    dot.Thickness = 1
                    BSRadarDrawings.players[player] = dot
                end
                local dot = BSRadarDrawings.players[player]
                dot.Position = center + Vector2.new(radarX, radarY)
                dot.Visible = true
                if getgenv().BSESPConfig.TeamCheck and player.Team == BSLocalPlayer.Team then
                    dot.Color = Color3.new(0, 1, 0)
                    dot.Radius = 3
                else
                    dot.Color = getBSCurrentColor(Color3.new(1, 0, 0))
                    dot.Radius = clipped and 2 or 3
                end
            elseif BSRadarDrawings.players[player] then
                BSRadarDrawings.players[player].Visible = false
            end
        end
    end
end

local function updateBSHighlights()
    for player, highlight in pairs(BSHighlightInstances) do
        if not BSPlayers:FindFirstChild(player.Name) then
            highlight:Destroy()
            BSHighlightInstances[player] = nil
        end
    end
    if not getgenv().BSESPConfig.HighlightPlayers or not getgenv().BSESPConfig.ESPEnabled then
        for _, highlight in pairs(BSHighlightInstances) do
            highlight:Destroy()
        end
        BSHighlightInstances = {}
        return
    end
    for _, player in pairs(BSPlayers:GetPlayers()) do
        if player ~= BSLocalPlayer and player.Character then
            local shouldShow = true
            if getgenv().BSESPConfig.TeamCheck and player.Team == BSLocalPlayer.Team then
                shouldShow = false
            end
            if shouldShow then
                if not BSHighlightInstances[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.FillTransparency = 0.3
                    highlight.OutlineTransparency = 0
                    highlight.Parent = player.Character
                    BSHighlightInstances[player] = highlight
                end
                local highlight = BSHighlightInstances[player]
                local color = getBSCurrentColor(getgenv().BSESPConfig.HighlightColor)
                highlight.FillColor = color
                highlight.OutlineColor = color
                if highlight.Parent ~= player.Character then
                    highlight.Parent = player.Character
                end
            elseif BSHighlightInstances[player] then
                BSHighlightInstances[player]:Destroy()
                BSHighlightInstances[player] = nil
            end
        end
    end
end

local function updateBSGlobalDrawings()
    if getgenv().BSESPConfig.ESPEnabled and getgenv().BSESPConfig.ShowPlayerCount then
        BSplayerCountText.Text = "在线玩家: " .. #BSPlayers:GetPlayers()
        BSplayerCountText.Position = Vector2.new(BSCamera.ViewportSize.X / 2, 10)
        BSplayerCountText.Visible = true
        BSplayerCountText.Color = getBSCurrentColor(Color3.new(1, 1, 1))
    else
        BSplayerCountText.Visible = false
    end
    if getgenv().BSESPConfig.ESPEnabled and getgenv().BSESPConfig.ShowFOV then
        BSfovCircle.Radius = getgenv().BSESPConfig.FOVRadius
        BSfovCircle.Position = Vector2.new(BSCamera.ViewportSize.X / 2, BSCamera.ViewportSize.Y / 2)
        BSfovCircle.Visible = true
        BSfovCircle.Color = getBSCurrentColor(getgenv().BSESPConfig.FOVColor)
    else
        BSfovCircle.Visible = false
    end
end

local function createBSESP(player)
    local box
    if not Drawing then return end
    box = Drawing.new("Square")
    box.Visible = false
    box.Color = getgenv().BSESPConfig.BoxColor
    box.Thickness = getgenv().BSESPConfig.BoxThickness
    box.Filled = false
    local box3D = {}
    for i = 1, 12 do
        box3D[i] = Drawing.new("Line")
        box3D[i].Visible = false
        box3D[i].Thickness = getgenv().BSESPConfig.BoxThickness
    end
    local healthBar = Drawing.new("Square")
    healthBar.Visible = false
    healthBar.Filled = true
    local healthBarBackground = Drawing.new("Square")
    healthBarBackground.Visible = false
    healthBarBackground.Color = Color3.new(0, 0, 0)
    healthBarBackground.Transparency = 0.5
    healthBarBackground.Filled = true
    local healthText = Drawing.new("Text")
    healthText.Visible = false
    healthText.Color = getgenv().BSESPConfig.HealthTextColor
    healthText.Size = 14
    healthText.Font = Drawing.Fonts.Monospace
    healthText.Outline = true
    healthText.OutlineColor = Color3.new(0, 0, 0)
    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Size = 16
    nameText.Font = Drawing.Fonts.Monospace
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0)
    local distanceText = Drawing.new("Text")
    distanceText.Visible = false
    distanceText.Size = 14
    distanceText.Font = Drawing.Fonts.Monospace
    distanceText.Outline = true
    distanceText.OutlineColor = Color3.new(0, 0, 0)
    local weaponText = Drawing.new("Text")
    weaponText.Visible = false
    weaponText.Size = 14
    weaponText.Font = Drawing.Fonts.Monospace
    weaponText.Outline = true
    weaponText.OutlineColor = Color3.new(0, 0, 0)
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = getgenv().BSESPConfig.TracerColor
    tracer.Thickness = getgenv().BSESPConfig.TracerThickness
    local arrow = Drawing.new("Triangle")
    arrow.Visible = false
    arrow.Filled = true
    arrow.Thickness = 1
    local skeletonLines = {}
    for i = 1, 15 do
        skeletonLines[i] = Drawing.new("Line")
        skeletonLines[i].Visible = false
        skeletonLines[i].Color = getgenv().BSESPConfig.SkeletonColor
        skeletonLines[i].Thickness = getgenv().BSESPConfig.SkeletonThickness
    end
    local lastHealth = 100
    local smoothHealth = 100
    BSESPComponents[player] = {
        box = box, box3D = box3D, healthBar = healthBar,
        healthBarBackground = healthBarBackground, healthText = healthText,
        nameText = nameText, distanceText = distanceText, weaponText = weaponText,
        tracer = tracer, arrow = arrow, skeletonLines = skeletonLines,
    }
    BSRunService.RenderStepped:Connect(function()
        if not getgenv().BSESPConfig.ESPEnabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") or player == BSLocalPlayer then
            box.Visible = false
            for i = 1, 12 do box3D[i].Visible = false end
            healthBar.Visible = false
            healthBarBackground.Visible = false
            healthText.Visible = false
            nameText.Visible = false
            distanceText.Visible = false
            weaponText.Visible = false
            tracer.Visible = false
            arrow.Visible = false
            for _, line in pairs(skeletonLines) do line.Visible = false end
            return
        end
        if getgenv().BSESPConfig.TeamCheck and player.Team == BSLocalPlayer.Team then
            box.Visible = false
            for i = 1, 12 do box3D[i].Visible = false end
            healthBar.Visible = false
            healthBarBackground.Visible = false
            healthText.Visible = false
            nameText.Visible = false
            distanceText.Visible = false
            weaponText.Visible = false
            tracer.Visible = false
            arrow.Visible = false
            for _, line in pairs(skeletonLines) do line.Visible = false end
            return
        end
        local character = player.Character
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if rootPart and humanoid and humanoid.Health > 0 then
            local rootPos, onScreen = BSCamera:WorldToViewportPoint(rootPart.Position)
            local headPos = BSCamera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0))
            local legPos = BSCamera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
            local weaponName = "无武器"
            for _, tool in ipairs(character:GetChildren()) do
                if tool:IsA("Tool") then weaponName = tool.Name break end
            end
            if getgenv().BSESPConfig.ShowBox and onScreen then
                box.Size = Vector2.new(1000 / rootPos.Z, headPos.Y - legPos.Y)
                box.Position = Vector2.new(rootPos.X - box.Size.X / 2, rootPos.Y - box.Size.Y / 2)
                box.Visible = true
                box.Color = getBSCurrentColor(getgenv().BSESPConfig.BoxColor)
                box.Thickness = getgenv().BSESPConfig.BoxThickness
            else
                box.Visible = false
            end
            if getgenv().BSESPConfig.Show3DBox then
                local size = Vector3.new(4, 6, 2)
                local cf = rootPart.CFrame
                local corners = {
                    cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
                    cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
                    cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
                    cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
                    cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
                    cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
                    cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
                    cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2)
                }
                local screenCorners = {}
                local allOnScreen = true
                for i, corner in ipairs(corners) do
                    local pos, visible = BSCamera:WorldToViewportPoint(corner.Position)
                    screenCorners[i] = Vector2.new(pos.X, pos.Y)
                    if not visible then allOnScreen = false end
                end
                local color = getBSCurrentColor(getgenv().BSESPConfig.Box3DColor)
                local lines = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
                for i, line in ipairs(lines) do
                    box3D[i].From = screenCorners[line[1]]
                    box3D[i].To = screenCorners[line[2]]
                    box3D[i].Color = color
                    box3D[i].Thickness = getgenv().BSESPConfig.BoxThickness
                    box3D[i].Visible = true
                end
            else
                for i = 1, 12 do box3D[i].Visible = false end
            end
            if getgenv().BSESPConfig.ShowHealth and onScreen then
                local healthPercentage = humanoid.Health / humanoid.MaxHealth
                local barWidth = 50
                local barHeight = 5
                local barX = headPos.X - barWidth / 2
                local barY = headPos.Y - 20
                healthBarBackground.Size = Vector2.new(barWidth, barHeight)
                healthBarBackground.Position = Vector2.new(barX, barY)
                healthBarBackground.Visible = true
                smoothHealth = smoothHealth + (humanoid.Health - smoothHealth) * 0.1
                local smoothHealthPercentage = smoothHealth / humanoid.MaxHealth
                healthBar.Size = Vector2.new(barWidth * smoothHealthPercentage, barHeight)
                healthBar.Position = Vector2.new(barX, barY)
                if smoothHealthPercentage >= 0.8 then
                    healthBar.Color = Color3.new(0, 1, 0)
                elseif smoothHealthPercentage >= 0.5 then
                    healthBar.Color = Color3.new(1, 1, 0)
                elseif smoothHealthPercentage >= 0.2 then
                    healthBar.Color = Color3.new(1, 0.5, 0)
                else
                    healthBar.Color = Color3.new(1, 0, 0)
                end
                healthBar.Visible = true
                healthText.Position = Vector2.new(barX + barWidth + 5, barY - 5)
                healthText.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                healthText.Visible = true
                healthText.Color = getBSCurrentColor(getgenv().BSESPConfig.HealthTextColor)
            else
                healthBar.Visible = false
                healthBarBackground.Visible = false
                healthText.Visible = false
            end
            if getgenv().BSESPConfig.ShowName and onScreen then
                nameText.Position = Vector2.new(headPos.X, headPos.Y - 35)
                nameText.Text = player.Name
                nameText.Visible = true
                nameText.Color = getBSCurrentColor(getgenv().BSESPConfig.NameColor)
                if getgenv().BSESPConfig.ShowDistance then
                    local distance = (BSLocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                    distanceText.Position = Vector2.new(headPos.X, headPos.Y + 10)
                    distanceText.Text = math.floor(distance) .. "m"
                    distanceText.Visible = true
                    distanceText.Color = getBSCurrentColor(getgenv().BSESPConfig.DistanceColor)
                else
                    distanceText.Visible = false
                end
                if getgenv().BSESPConfig.ShowWeapon then
                    weaponText.Position = Vector2.new(headPos.X, headPos.Y - 50)
                    weaponText.Text = weaponName
                    weaponText.Visible = true
                    weaponText.Color = getBSCurrentColor(getgenv().BSESPConfig.WeaponColor)
                else
                    weaponText.Visible = false
                end
            else
                nameText.Visible = false
                distanceText.Visible = false
                weaponText.Visible = false
            end
            if getgenv().BSESPConfig.ShowTracer then
                local head = character:FindFirstChild("Head")
                if head then
                    local hPos, hOnScreen = BSCamera:WorldToViewportPoint(head.Position)
                    if hOnScreen then
                        tracer.From = Vector2.new(BSCamera.ViewportSize.X / 2, BSCamera.ViewportSize.Y)
                        tracer.To = Vector2.new(hPos.X, hPos.Y)
                        tracer.Visible = true
                        tracer.Color = getBSCurrentColor(getgenv().BSESPConfig.TracerColor)
                        tracer.Thickness = getgenv().BSESPConfig.TracerThickness
                    else
                        tracer.Visible = false
                    end
                else
                    tracer.Visible = false
                end
            else
                tracer.Visible = false
            end
            if getgenv().BSESPConfig.OutOfViewArrows and not onScreen then
                local direction = (rootPart.Position - BSCamera.CFrame.Position).Unit
                local dotProduct = BSCamera.CFrame.RightVector:Dot(direction)
                local crossProduct = BSCamera.CFrame.RightVector:Cross(direction)
                local screenPosition = Vector2.new(
                    BSCamera.ViewportSize.X / 2 + dotProduct * BSCamera.ViewportSize.X / 3,
                    BSCamera.ViewportSize.Y / 2 - crossProduct.Y * BSCamera.ViewportSize.Y / 3
                )
                screenPosition = Vector2.new(
                    math.clamp(screenPosition.X, getgenv().BSESPConfig.ArrowSize, BSCamera.ViewportSize.X - getgenv().BSESPConfig.ArrowSize),
                    math.clamp(screenPosition.Y, getgenv().BSESPConfig.ArrowSize, BSCamera.ViewportSize.Y - getgenv().BSESPConfig.ArrowSize)
                )
                local angle = math.atan2(screenPosition.Y - BSCamera.ViewportSize.Y / 2, screenPosition.X - BSCamera.ViewportSize.X / 2)
                arrow.PointA = screenPosition
                arrow.PointB = Vector2.new(screenPosition.X - getgenv().BSESPConfig.ArrowSize * math.cos(angle - 0.5), screenPosition.Y - getgenv().BSESPConfig.ArrowSize * math.sin(angle - 0.5))
                arrow.PointC = Vector2.new(screenPosition.X - getgenv().BSESPConfig.ArrowSize * math.cos(angle + 0.5), screenPosition.Y - getgenv().BSESPConfig.ArrowSize * math.sin(angle + 0.5))
                arrow.Color = getBSCurrentColor(getgenv().BSESPConfig.ArrowColor)
                arrow.Visible = true
            else
                arrow.Visible = false
            end
            if getgenv().BSESPConfig.ShowSkeleton and onScreen then
                local head = character:FindFirstChild("Head")
                local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
                local leftArm = character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftUpperArm")
                local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightUpperArm")
                local leftLeg = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftUpperLeg")
                local rightLeg = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightUpperLeg")
                local skeletonColor = getBSCurrentColor(getgenv().BSESPConfig.SkeletonColor)
                if head and torso and leftArm and rightArm and leftLeg and rightLeg then
                    local connections = {
                        {head, torso}, {torso, leftArm}, {torso, rightArm},
                        {torso, leftLeg}, {torso, rightLeg}
                    }
                    for i, conn in ipairs(connections) do
                        local pos1 = BSCamera:WorldToViewportPoint(conn[1].Position)
                        local pos2 = BSCamera:WorldToViewportPoint(conn[2].Position)
                        skeletonLines[i].From = Vector2.new(pos1.X, pos1.Y)
                        skeletonLines[i].To = Vector2.new(pos2.X, pos2.Y)
                        skeletonLines[i].Color = skeletonColor
                        skeletonLines[i].Visible = true
                    end
                    for i = #connections + 1, 15 do
                        skeletonLines[i].Visible = false
                    end
                else
                    for _, line in pairs(skeletonLines) do line.Visible = false end
                end
            else
                for _, line in pairs(skeletonLines) do line.Visible = false end
            end
        end
    end)
end

for _, player in pairs(BSPlayers:GetPlayers()) do
    if player ~= BSLocalPlayer then
        createBSESP(player)
    end
end
BSPlayers.PlayerAdded:Connect(function(player)
    createBSESP(player)
end)

-- 使用pcall包裹防止Drawing API不支持导致脚本中断
pcall(function()
    BSRunService.RenderStepped:Connect(updateBSGlobalDrawings)
    BSRunService.RenderStepped:Connect(updateBSRadar)
    BSRunService.RenderStepped:Connect(updateBSHighlights)
end)

-- BS ESP UI 控件
BSESPBox:AddToggle("BS_ESP_Enabled", { Text = "ESP总开关", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.ESPEnabled = v
end)
BSESPBox:AddToggle("BS_ShowBox", { Text = "显示方框", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.ShowBox = v
end)
BSESPBox:AddToggle("BS_Show3DBox", { Text = "显示3D方框", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.Show3DBox = v
end)
BSESPBox:AddToggle("BS_ShowHealth", { Text = "显示血量", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.ShowHealth = v
end)
BSESPBox:AddToggle("BS_ShowName", { Text = "显示名称", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.ShowName = v
end)
BSESPBox:AddToggle("BS_ShowDistance", { Text = "显示距离", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.ShowDistance = v
end)
BSESPBox:AddToggle("BS_ShowTracer", { Text = "显示射线", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.ShowTracer = v
end)
BSESPBox:AddToggle("BS_TeamCheck", { Text = "队伍检查", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.TeamCheck = v
end)

local BSESPRightBox = Tabs.Visual:AddRightGroupbox("其他设置")
BSESPRightBox:AddToggle("BS_ShowSkeleton", { Text = "显示骨骼", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.ShowSkeleton = v
end)
BSESPRightBox:AddToggle("BS_ShowRadar", { Text = "显示雷达", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.ShowRadar = v
end)
BSESPRightBox:AddToggle("BS_ShowPlayerCount", { Text = "显示玩家计数", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.ShowPlayerCount = v
end)
BSESPRightBox:AddToggle("BS_ShowWeapon", { Text = "显示武器", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.ShowWeapon = v
end)
BSESPRightBox:AddToggle("BS_RainbowMode", { Text = "彩虹色模式", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.RainbowMode = v
end)
BSESPRightBox:AddToggle("BS_HighlightPlayers", { Text = "高亮玩家", Default = false }):OnChanged(function(v)
    getgenv().BSESPConfig.HighlightPlayers = v
end)
end)

-- ---------- 高级功能 (移至杂项) ----------
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Lighting      = game:GetService("Lighting")
local StarterGui    = game:GetService("StarterGui")
local VirtualUser   = game:GetService("VirtualUser")
local LocalPlayer    = Players.LocalPlayer

-- ---------- 公共兼容封装 ----------
local _newcclosure = newcclosure or function(f) return f end
local _getrawmetatable = getrawmetatable or getmetatable
local _setreadonly = setreadonly or function(mt, _state) end
local _isreadonly = isreadonly or function() return false end
local _hookmetamethod = hookmetamethod
local _hookfunction = hookfunction
local _getnamecallmethod = getnamecallmethod
local _checkcaller = checkcaller
local _getgc = getgc

-- ---------- 通知函数 ----------
local function Notify(title, text, duration)
    duration = duration or 3
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
end

-- 安全获取角色 & HumanoidRootPart
local function getCharacterRoot()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    return char, root
end


-- ############################################################
--  左侧分组
-- ############################################################

-- ============================================================
-- 1. 夜视功能
-- ============================================================
local NightVisionBox = Tabs.Main:AddLeftGroupbox("夜视功能")

local nightVisionEnabled  = false
local nightVisionConn      = nil
local originalLighting      = {}

local function saveOriginalLighting()
    originalLighting.ClockTime           = Lighting.ClockTime
    originalLighting.Brightness          = Lighting.Brightness
    originalLighting.ExposureCompensation= Lighting.ExposureCompensation
    originalLighting.Ambient             = Lighting.Ambient
    originalLighting.OutdoorAmbient      = Lighting.OutdoorAmbient
    originalLighting.GlobalShadows       = Lighting.GlobalShadows
end

local function restoreOriginalLighting()
    pcall(function()
        Lighting.ClockTime            = originalLighting.ClockTime            or 14
        Lighting.Brightness           = originalLighting.Brightness           or 2
        Lighting.ExposureCompensation = originalLighting.ExposureCompensation or 0
        Lighting.Ambient              = originalLighting.Ambient             or Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient       = originalLighting.OutdoorAmbient      or Color3.fromRGB(128, 128, 128)
        Lighting.GlobalShadows       = originalLighting.GlobalShadows
    end)
end

NightVisionBox:AddToggle("NightVisionToggle", {
    Text    = "夜视模式",
    Default = false,
}):OnChanged(function(v)
    nightVisionEnabled = v
    if v then
        saveOriginalLighting()
        if nightVisionConn then nightVisionConn:Disconnect() end
        nightVisionConn = RunService.RenderStepped:Connect(function()
            Lighting.ClockTime            = 15
            Lighting.Brightness           = 2
            Lighting.ExposureCompensation = 0.5
            Lighting.Ambient              = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient       = Color3.fromRGB(255, 255, 255)
        end)
        Notify("夜视", "夜视模式已开启", 3)
    else
        if nightVisionConn then
            nightVisionConn:Disconnect()
            nightVisionConn = nil
        end
        restoreOriginalLighting()
        Notify("夜视", "夜视模式已关闭，已恢复原值", 3)
    end
end)



FeatureBox:AddButton("踏空行走", function()
    pcall(function()
        safeLoad('https://raw.githubusercontent.com/GhostPlayer352/Test4/main/Float')
    end)
    Notify("踏空行走", "踏空行走脚本已加载", 3)
end)

local airSwimEnabled = false
local airSwimConns = {}
local airSwimBV = nil
local airSwimBG = nil

FeatureBox:AddToggle("AirSwimToggle", {
    Text    = "空中游泳",
    Default = false,
}):OnChanged(function(state)
    airSwimEnabled = state
    local speaker = game:GetService("Players").LocalPlayer
    if state then
        -- 禁用所有Humanoid状态
        local char = speaker.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        local states = {
            Enum.HumanoidStateType.Climbing,
            Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.Flying,
            Enum.HumanoidStateType.Freefall,
            Enum.HumanoidStateType.GettingUp,
            Enum.HumanoidStateType.Jumping,
            Enum.HumanoidStateType.Landed,
            Enum.HumanoidStateType.Physics,
            Enum.HumanoidStateType.PlatformStanding,
            Enum.HumanoidStateType.Ragdoll,
            Enum.HumanoidStateType.Running,
            Enum.HumanoidStateType.RunningNoPhysics,
            Enum.HumanoidStateType.Seated,
            Enum.HumanoidStateType.StrafingNoPhysics,
            Enum.HumanoidStateType.Swimming,
        }
        for _, s in ipairs(states) do
            hum:SetStateEnabled(s, false)
        end
        hum:ChangeState(Enum.HumanoidStateType.Swimming)

        local swimControl = {
            enabled = true,
            speed = 25,
            moving = { forward = false, backward = false, left = false, right = false, up = false, down = false }
        }

        airSwimBV = Instance.new("BodyVelocity")
        airSwimBV.Name = "SwimBodyVelocity"
        airSwimBV.Parent = root
        airSwimBV.MaxForce = Vector3.new(4000, 4000, 4000)
        airSwimBV.Velocity = Vector3.new(0, 0, 0)

        airSwimBG = Instance.new("BodyGyro")
        airSwimBG.Name = "SwimBodyGyro"
        airSwimBG.Parent = root
        airSwimBG.MaxTorque = Vector3.new(2000, 2000, 2000)
        airSwimBG.D = 500
        airSwimBG.P = 8000

        local UIS = game:GetService("UserInputService")
        airSwimConns.inputBegin = UIS.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.W then swimControl.moving.forward = true
            elseif input.KeyCode == Enum.KeyCode.S then swimControl.moving.backward = true
            elseif input.KeyCode == Enum.KeyCode.A then swimControl.moving.left = true
            elseif input.KeyCode == Enum.KeyCode.D then swimControl.moving.right = true
            elseif input.KeyCode == Enum.KeyCode.Space then swimControl.moving.up = true
            elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftShift then swimControl.moving.down = true
            end
        end)

        airSwimConns.inputEnd = UIS.InputEnded:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.W then swimControl.moving.forward = false
            elseif input.KeyCode == Enum.KeyCode.S then swimControl.moving.backward = false
            elseif input.KeyCode == Enum.KeyCode.A then swimControl.moving.left = false
            elseif input.KeyCode == Enum.KeyCode.D then swimControl.moving.right = false
            elseif input.KeyCode == Enum.KeyCode.Space then swimControl.moving.up = false
            elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.LeftShift then swimControl.moving.down = false
            end
        end)

        airSwimConns.heartbeat = RunService.Heartbeat:Connect(function()
            if not swimControl.enabled then return end
            local moveDir = Vector3.new(0, 0, 0)
            if swimControl.moving.forward then moveDir = moveDir + workspace.CurrentCamera.CFrame.LookVector end
            if swimControl.moving.backward then moveDir = moveDir - workspace.CurrentCamera.CFrame.LookVector end
            if swimControl.moving.left then moveDir = moveDir - workspace.CurrentCamera.CFrame.RightVector end
            if swimControl.moving.right then moveDir = moveDir + workspace.CurrentCamera.CFrame.RightVector end
            if swimControl.moving.up then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if swimControl.moving.down then moveDir = moveDir + Vector3.new(0, -1, 0) end
            if moveDir.Magnitude > 0 then
                airSwimBV.Velocity = moveDir.Unit * swimControl.speed
            else
                airSwimBV.Velocity = Vector3.new(0, 0, 0)
            end
            airSwimBG.CFrame = CFrame.new(root.Position, root.Position + workspace.CurrentCamera.CFrame.LookVector)
        end)

        -- 角色重生后重新设置
        airSwimConns.charAdded = speaker.CharacterAdded:Connect(function(newChar)
            task.wait(0.7)
            local newHum = newChar:FindFirstChildOfClass("Humanoid")
            if newHum then
                for _, s in ipairs(states) do
                    newHum:SetStateEnabled(s, false)
                end
                newHum:ChangeState(Enum.HumanoidStateType.Swimming)
            end
            if swimControl.enabled then
                local newRoot = newChar:WaitForChild("HumanoidRootPart")
                if airSwimBV then airSwimBV:Destroy() end
                if airSwimBG then airSwimBG:Destroy() end
                airSwimBV = Instance.new("BodyVelocity")
                airSwimBV.Name = "SwimBodyVelocity"
                airSwimBV.Parent = newRoot
                airSwimBV.MaxForce = Vector3.new(4000, 4000, 4000)
                airSwimBV.Velocity = Vector3.new(0, 0, 0)
                airSwimBG = Instance.new("BodyGyro")
                airSwimBG.Name = "SwimBodyGyro"
                airSwimBG.Parent = newRoot
                airSwimBG.MaxTorque = Vector3.new(2000, 2000, 2000)
                airSwimBG.D = 500
                airSwimBG.P = 8000
            end
        end)

        Notify("空中游泳", "空中游泳已开启 - 可在空中自由移动", 3)
    else
        -- 恢复所有Humanoid状态
        local char = speaker.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local states = {
                    Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown,
                    Enum.HumanoidStateType.Flying, Enum.HumanoidStateType.Freefall,
                    Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Jumping,
                    Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Physics,
                    Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Ragdoll,
                    Enum.HumanoidStateType.Running, Enum.HumanoidStateType.RunningNoPhysics,
                    Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.StrafingNoPhysics,
                    Enum.HumanoidStateType.Swimming,
                }
                for _, s in ipairs(states) do
                    hum:SetStateEnabled(s, true)
                end
                hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            end
        end
        -- 断开所有连接
        for name, conn in pairs(airSwimConns) do
            if typeof(conn) == "RBXScriptConnection" then
                conn:Disconnect()
                airSwimConns[name] = nil
            end
        end
        if airSwimBV then airSwimBV:Destroy() airSwimBV = nil end
        if airSwimBG then airSwimBG:Destroy() airSwimBG = nil end
        Notify("空中游泳", "空中游泳已关闭", 3)
    end
end)



-- ============================================================
-- 3. 防虚空 (BS源码版 - PlayerProtection.AntiVoid)
-- ============================================================
local AntiVoidBox = Tabs.Main:AddLeftGroupbox("防虚空")

local antiVoidThreshold = -100
AntiVoidBox:AddSlider("AntiVoid_Threshold", {
    Text = "触发高度(Y轴)",
    Default = -100,
    Min = -1000,
    Max = 0,
    Rounding = 0,
}):OnChanged(function(val)
    antiVoidThreshold = val
end)

local bsAntiVoid = {
    _enabled = false,
    _loop = nil,
    _voidY = -100,
    _platform = nil,
}

function bsAntiVoid:_createPlatform()
    if self._platform then
        self._platform:Destroy()
    end
    self._platform = Instance.new("Part")
    self._platform.Name = "AntiVoidPlatform"
    self._platform.Size = Vector3.new(50, 2, 50)
    self._platform.Anchored = true
    self._platform.CanCollide = true
    self._platform.Material = Enum.Material.Plastic
    self._platform.Transparency = 0.9
    self._platform.BrickColor = BrickColor.new("Institutional white")
    self._platform.Parent = workspace
end

function bsAntiVoid:_core()
    self._voidY = antiVoidThreshold
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if rootPart and humanoid and humanoid.Health > 0 then
        if rootPart.Position.Y < self._voidY then
            -- 在玩家下方创建透明平台
            if not self._platform then
                self:_createPlatform()
            end
            -- 平台放在玩家下方稍低位置
            self._platform.Position = Vector3.new(
                rootPart.Position.X,
                self._voidY - 5,
                rootPart.Position.Z
            )
            -- 同时把角色托上去
            rootPart.CFrame = CFrame.new(rootPart.Position.X, self._voidY + 3, rootPart.Position.Z)
            rootPart.Velocity = Vector3.new(0, 0, 0)
        else
            -- 玩家在安全高度，移除平台
            if self._platform then
                self._platform:Destroy()
                self._platform = nil
            end
        end
    else
        -- 角色无效，移除平台
        if self._platform then
            self._platform:Destroy()
            self._platform = nil
        end
    end
end

function bsAntiVoid:enable()
    self._enabled = true
    if self._loop then self._loop:Disconnect() end
    self._loop = RunService.RenderStepped:Connect(function()
        self:_core()
    end)
    -- 角色重生后自动重启
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        newChar:WaitForChild("HumanoidRootPart")
        if self._enabled and not self._loop then
            self:enable()
        end
    end)
    Notify("防虚空", "防虚空已开启, 触发高度: " .. self._voidY, 3)
end

function bsAntiVoid:disable()
    self._enabled = false
    if self._loop then
        self._loop:Disconnect()
        self._loop = nil
    end
    if self._platform then
        self._platform:Destroy()
        self._platform = nil
    end
    Notify("防虚空", "防虚空已关闭", 3)
end

AntiVoidBox:AddToggle("AntiVoidToggle", {
    Text    = "防虚空掉落",
    Default = false,
}):OnChanged(function(state)
    if state then
        bsAntiVoid:enable()
    else
        bsAntiVoid:disable()
    end
end)



-- ============================================================
-- 4. 防卡顿优化
-- ============================================================
local OptimizeBox = Tabs.Main:AddLeftGroupbox("防卡顿优化")

local optimizeEnabled   = false
local optimizeOriginal   = {}
local disabledParticles  = {}

local function applyOptimization()
    -- 全局阴影
    optimizeOriginal.GlobalShadows = Lighting.GlobalShadows
    Lighting.GlobalShadows = false

    -- 关闭后处理特效 (Bloom / ColorCorrection / SunRays / Blur / DepthOfField)
    optimizeOriginal.PostEffects = {}
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("PostEffect")
            or obj:IsA("BloomEffect")
            or obj:IsA("ColorCorrectionEffect")
            or obj:IsA("SunRaysEffect")
            or obj:IsA("BlurEffect")
            or obj:IsA("DepthOfFieldEffect") then
            table.insert(optimizeOriginal.PostEffects, {obj = obj, enabled = obj.Enabled})
            obj.Enabled = false
        end
    end

    -- 降低模拟/流式半径
    pcall(function()
        if workspace.StreamingEnabled then
            optimizeOriginal.StreamingTargetRadius = workspace.StreamingTargetRadius
            workspace.StreamingTargetRadius = 50
            optimizeOriginal.StreamingMinRadius = workspace.StreamingMinRadius
            workspace.StreamingMinRadius = 50
        end
    end)

    -- 禁用所有粒子特效
    disabledParticles = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            if obj.Enabled then
                table.insert(disabledParticles, obj)
                obj.Enabled = false
            end
        end
    end
end

local function restoreOptimization()
    pcall(function()
        Lighting.GlobalShadows = optimizeOriginal.GlobalShadows
    end)
    if optimizeOriginal.PostEffects then
        for _, entry in ipairs(optimizeOriginal.PostEffects) do
            pcall(function() entry.obj.Enabled = entry.enabled end)
        end
        optimizeOriginal.PostEffects = {}
    end
    pcall(function()
        if workspace.StreamingEnabled then
            if optimizeOriginal.StreamingTargetRadius then workspace.StreamingTargetRadius = optimizeOriginal.StreamingTargetRadius end
            if optimizeOriginal.StreamingMinRadius then workspace.StreamingMinRadius = optimizeOriginal.StreamingMinRadius end
        end
    end)
    for _, obj in ipairs(disabledParticles) do
        pcall(function() obj.Enabled = true end)
    end
    disabledParticles = {}
end

OptimizeBox:AddToggle("OptimizeToggle", {
    Text    = "性能优化",
    Default = false,
}):OnChanged(function(v)
    optimizeEnabled = v
    if v then
        applyOptimization()
        Notify("防卡顿优化", "优化已开启", 3)
    else
        restoreOptimization()
        Notify("防卡顿优化", "已恢复原设置", 3)
    end
end)



-- ############################################################
--  右侧分组
-- ############################################################

-- ============================================================
-- 7. 防踢功能
-- ============================================================
local AntiKickBox = Tabs.Main:AddRightGroupbox("防踢功能")

local antiKickApplied = false

local function setupAntiKick()
    if antiKickApplied then
        Notify("防踢", "防踢已启用，无需重复", 3)
        return
    end

    local ok1 = false
    -- hookmetamethod: 拦截 __namecall 中的 Kick
    if _hookmetamethod then
        ok1 = pcall(function()
            local oldNamecall
            oldNamecall = _hookmetamethod(game, "__namecall", _newcclosure(function(self, ...)
                local method = _getnamecallmethod and _getnamecallmethod() or ""
                if method == "Kick" then
                    local isCaller = _checkcaller and _checkcaller()
                    if not isCaller then
                        Notify("防踢", "拦截 __namecall Kick 调用", 4)
                        return nil
                    end
                end
                return oldNamecall(self, ...)
            end))
        end)
    end

    -- hookfunction: 拦截 LocalPlayer.Kick
    local ok2 = false
    if _hookfunction then
        ok2 = pcall(function()
            local oldKick
            oldKick = _hookfunction(LocalPlayer.Kick, _newcclosure(function(...)
                Notify("防踢", "拦截 LocalPlayer.Kick 调用", 4)
                return nil
            end))
        end)
    end

    if ok1 or ok2 then
        antiKickApplied = true
        Notify("防踢", "防踢已启用，将拦截所有Kick调用", 4)
    else
        Notify("防踢", "防踢启用失败，执行器可能不支持", 4)
    end
end

AntiKickBox:AddButton("启用防踢", function()
    setupAntiKick()
end)



-- ============================================================
-- 8. 绕过反作弊
-- ============================================================
local BypassBox = Tabs.Main:AddRightGroupbox("绕过功能")

BypassBox:AddButton("绕过反作弊(Adonis)", function()
    local ok, err = pcall(function()
        safeLoad("https://raw.githubusercontent.com/.../adoniscries.lua")
    end)
    if ok then
        Notify("绕过", "绕过反作弊脚本已加载", 3)
    else
        Notify("绕过", "加载失败: " .. tostring(err), 4)
    end
end)


-- ============================================================
-- 9. 绕过移动检测
-- ============================================================
local walkSpeedProtected = false

BypassBox:AddButton("绕过移动检测", function()
    local cleared = 0
    -- 遍历 getgc() 表，置空相关检测函数
    if _getgc then
        pcall(function()
            local keys = {"restrictTeleport", "checkCFrame", "validateMove", "restrictMove"}
            for _, v in ipairs(_getgc()) do
                if type(v) == "table" then
                    for _, key in ipairs(keys) do
                        if rawget(v, key) ~= nil then
                            pcall(function()
                                rawset(v, key, nil)
                            end)
                            cleared = cleared + 1
                        end
                    end
                end
            end
        end)
    end

    -- WalkSpeed 保护 (低于16时重置为16)
    if not walkSpeedProtected then
        walkSpeedProtected = true
        task.spawn(function()
            while walkSpeedProtected do
                pcall(function()
                    local char, root = getCharacterRoot()
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.WalkSpeed < 16 then
                            hum.WalkSpeed = 16
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    end

    Notify("绕过", string.format("移动检测已绕过(清理%d项)，WalkSpeed保护已开启", cleared), 4)
end)

-- ============================================================
-- 工具 Tab
-- ============================================================
do
local Tabs_Tools = Window:AddTab("工具", "wrench")

-- 服务
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- 前置声明
local CoordDropdown
local selectedCoord = ""

-- 坐标存储 {name = Vector3}
local SavedCoords = {}
local coordCounter = 0

-- ============================================================
-- 通用辅助函数
-- ============================================================
local function notify(title, text, duration)
	duration = duration or 3
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = duration
		})
	end)
end

local function getCharacter()
	return LocalPlayer.Character
end

local function getRootPart()
	local char = getCharacter()
	if char then
		return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
	end
end

local function getHumanoid()
	local char = getCharacter()
	if char then
		return char:FindFirstChildOfClass("Humanoid")
	end
end

-- 刷新坐标下拉列表
local function refreshCoordDropdown()
	local names = {}
	for name in pairs(SavedCoords) do
		table.insert(names, name)
	end
	table.sort(names)
	if CoordDropdown then
		CoordDropdown:SetValues(names)
	end
end

-- ============================================================
-- 1. 坐标管理
-- ============================================================
local CoordGroup = Tabs_Tools:AddLeftGroupbox("坐标管理")

-- 自动命名保存当前坐标
CoordGroup:AddButton("保存当前坐标", function()
	local root = getRootPart()
	if not root then
		notify("坐标", "未找到角色", 3)
		return
	end
	coordCounter = coordCounter + 1
	local name = "coord" .. coordCounter
	SavedCoords[name] = root.Position
	notify("坐标保存", name .. " 已保存: " .. tostring(root.Position), 3)
	refreshCoordDropdown()
end)

-- 自定义名称保存
local customCoordInput = CoordGroup:AddInput("CustomCoordName", {
	Text = "自定义坐标名",
	Default = "",
	Numeric = false
})

local customCoordName = ""
customCoordInput:OnChanged(function(text)
	customCoordName = text or ""
end)

CoordGroup:AddButton("保存自定义坐标", function()
	local root = getRootPart()
	if not root then
		notify("坐标", "未找到角色", 3)
		return
	end
	local name = customCoordName
	if not name or name == "" then
		notify("坐标", "请输入坐标名称", 3)
		return
	end
	SavedCoords[name] = root.Position
	notify("坐标保存", name .. " 已保存", 3)
	refreshCoordDropdown()
end)

CoordGroup:AddLabel("已保存坐标列表")

CoordDropdown = CoordGroup:AddDropdown("CoordList", {
	Text = "坐标列表",
	Values = {},
	Default = "",
	Multi = false
})

CoordDropdown:OnChanged(function(v)
	selectedCoord = v
end)

CoordGroup:AddButton("传送到选中坐标", function()
	if selectedCoord == "" or not SavedCoords[selectedCoord] then
		notify("传送", "请选择有效坐标", 3)
		return
	end
	local root = getRootPart()
	if not root then
		notify("传送", "未找到角色", 3)
		return
	end
	root.CFrame = CFrame.new(SavedCoords[selectedCoord])
	notify("传送", "已传送到 " .. selectedCoord, 3)
end)

-- 循环传送开关
local loopTeleport = false
local loopConn = nil
CoordGroup:AddToggle("LoopTeleport", {
	Text = "循环传送选中坐标",
	Default = false
}):OnChanged(function(v)
	loopTeleport = v
	if v then
		notify("循环传送", "已开启循环传送", 3)
		pcall(function()
			if loopConn then loopConn:Disconnect() end
			loopConn = RunService.Heartbeat:Connect(function()
				if loopTeleport and selectedCoord ~= "" and SavedCoords[selectedCoord] then
					local root = getRootPart()
					if root then
						root.CFrame = CFrame.new(SavedCoords[selectedCoord])
					end
				end
			end)
		end)
	else
		notify("循环传送", "已关闭循环传送", 3)
		if loopConn then
			loopConn:Disconnect()
			loopConn = nil
		end
	end
end)

-- ============================================================
-- 2. 传送工具
-- ============================================================
local TeleportGroup = Tabs_Tools:AddLeftGroupbox("传送工具")

TeleportGroup:AddButton("点击传送", function()
	pcall(function()
		-- 移除已存在的同名工具
		for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if item:IsA("Tool") and item.Name == "[XJW]传送工具" then
				item:Destroy()
			end
		end

		local tool = Instance.new("Tool")
		tool.Name = "[XJW]传送工具"
		tool.RequiresHandle = false
		tool.ToolTip = "点击任意位置传送"
		tool.Parent = LocalPlayer.Backpack

		tool.Activated:Connect(function()
			local root = getRootPart()
			local char = getCharacter()
			if not root or not char then return end

			local mouse = LocalPlayer:GetMouse()
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = { char }
			rayParams.FilterType = Enum.RaycastFilterType.Exclude

			local origin = mouse.UnitRay.Origin
			local direction = mouse.UnitRay.Direction * 1000
			local result = Workspace:Raycast(origin, direction, rayParams)

			if result then
				root.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
				notify("传送", "已传送到点击位置", 2)
			else
				root.CFrame = mouse.Hit
				notify("传送", "已传送到点击位置", 2)
			end
		end)

		notify("传送工具", "[XJW]传送工具 已创建，装备后点击传送", 4)
	end)
end)

-- ============================================================
-- 3. 坐标工具
-- ============================================================
local CoordToolGroup = Tabs_Tools:AddRightGroupbox("坐标工具")

-- 保存所有坐标到文件
CoordToolGroup:AddButton("保存坐标到文件", function()
	pcall(function()
		local data = {}
		for name, pos in pairs(SavedCoords) do
			table.insert(data, string.format('["%s"] = Vector3.new(%f, %f, %f)', name, pos.X, pos.Y, pos.Z))
		end
		local content = "return {\n  " .. table.concat(data, ",\n  ") .. "\n}"
		writefile("SavedCoords.txt", content)
		setclipboard(content)
		notify("坐标", "已保存到文件并复制到剪贴板", 4)
	end)
end)

-- 删除选中坐标
CoordToolGroup:AddButton("删除选中坐标", function()
	if selectedCoord == "" or not SavedCoords[selectedCoord] then
		notify("坐标", "请选择有效坐标", 3)
		return
	end
	SavedCoords[selectedCoord] = nil
	notify("坐标", "已删除 " .. selectedCoord, 3)
	refreshCoordDropdown()
end)

-- 删除全部坐标
CoordToolGroup:AddButton("删除全部坐标", function()
	SavedCoords = {}
	coordCounter = 0
	selectedCoord = ""
	refreshCoordDropdown()
	notify("坐标", "已删除全部坐标", 3)
end)

-- 复制当前坐标
CoordToolGroup:AddButton("复制当前坐标", function()
	local root = getRootPart()
	if not root then
		notify("坐标", "未找到角色", 3)
		return
	end
	local pos = root.Position
	local text = string.format("%f, %f, %f", pos.X, pos.Y, pos.Z)
	setclipboard(text)
	notify("坐标", "当前坐标已复制: " .. text, 4)
end)

-- ============================================================
-- 4. 美化包
-- ============================================================
local BeautifyGroup = Tabs_Tools:AddRightGroupbox("美化包")

-- 删除所有饰品
local function deleteAccessories(char)
	char = char or getCharacter()
	if not char then return end
	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("Accessory") then
			pcall(function() v:Destroy() end)
		end
	end
end

-- 删除所有饰品和衣服
local function deleteAccessoriesAndClothes(char)
	char = char or getCharacter()
	if not char then return end
	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("BodyColors") then
			pcall(function() v:Destroy() end)
		end
	end
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("Decal") or v:IsA("Texture") then
			pcall(function() v:Destroy() end)
		end
	end
end

-- 角色随机颜色
local function randomColor(char)
	char = char or getCharacter()
	if not char then return end
	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("BasePart") then
			pcall(function()
				v.BrickColor = BrickColor.Random()
				v.Color = Color3.new(math.random(), math.random(), math.random())
			end)
		end
	end
end

BeautifyGroup:AddButton("删除所有饰品", function()
	deleteAccessories()
	notify("美化", "已删除所有饰品", 3)
end)

-- 重生自动删除开关
local autoDeleteOnRespawn = false
BeautifyGroup:AddToggle("AutoDeleteOnRespawn", {
	Text = "重生自动删除饰品和衣服",
	Default = false
}):OnChanged(function(v)
	autoDeleteOnRespawn = v
	notify("美化", v and "已开启重生自动删除" or "已关闭重生自动删除", 3)
end)

BeautifyGroup:AddButton("删除所有饰品和衣服", function()
	deleteAccessoriesAndClothes()
	notify("美化", "已删除所有饰品和衣服", 3)
end)

-- 角色随机颜色
BeautifyGroup:AddButton("角色随机颜色", function()
	randomColor()
	notify("美化", "已应用随机颜色", 3)
end)

local autoColorOnRespawn = false
BeautifyGroup:AddToggle("AutoColorOnRespawn", {
	Text = "重生自动应用随机颜色",
	Default = false
}):OnChanged(function(v)
	autoColorOnRespawn = v
	notify("美化", v and "已开启重生随机颜色" or "已关闭重生随机颜色", 3)
end)

-- 彩虹角色开关
local rainbowOn = false
local rainbowConn = nil
BeautifyGroup:AddToggle("RainbowCharacter", {
	Text = "彩虹角色 (Neon循环变色)",
	Default = false
}):OnChanged(function(v)
	rainbowOn = v
	if v then
		notify("美化", "已开启彩虹角色", 3)
		local hue = 0
		pcall(function()
			if rainbowConn then rainbowConn:Disconnect() end
			rainbowConn = RunService.Heartbeat:Connect(function()
				if not rainbowOn then return end
				hue = hue + 0.005
				if hue > 1 then hue = 0 end
				local color = Color3.fromHSV(hue, 1, 1)
				local char = getCharacter()
				if char then
					for _, part in ipairs(char:GetChildren()) do
						if part:IsA("BasePart") then
							pcall(function()
								part.Color = color
								part.Material = Enum.Material.Neon
							end)
						end
					end
				end
			end)
		end)
	else
		notify("美化", "已关闭彩虹角色", 3)
		if rainbowConn then
			rainbowConn:Disconnect()
			rainbowConn = nil
		end
		-- 恢复材质
		local char = getCharacter()
		if char then
			for _, part in ipairs(char:GetChildren()) do
				if part:IsA("BasePart") then
					pcall(function() part.Material = Enum.Material.Plastic end)
				end
			end
		end
	end
end)

-- 断腿开关 (右腿 korblox)
local brokenLegOn = false
local function applyKorblox(char)
	char = char or getCharacter()
	if not char then return end
	local rightLeg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLeg")
	if not rightLeg then return end
	local existing = rightLeg:FindFirstChildOfClass("SpecialMesh")
	if existing then existing:Destroy() end
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshId = "rbxassetid://6658418826"
	mesh.TextureId = "rbxassetid://6658420819"
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.VertexColor = Vector3.new(1, 1, 1)
	mesh.Parent = rightLeg
end

local function removeKorblox(char)
	char = char or getCharacter()
	if not char then return end
	local rightLeg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLeg")
	if not rightLeg then return end
	local mesh = rightLeg:FindFirstChildOfClass("SpecialMesh")
	if mesh then mesh:Destroy() end
end

BeautifyGroup:AddToggle("BrokenLeg", {
	Text = "断腿 (Korblox右腿)",
	Default = false
}):OnChanged(function(v)
	brokenLegOn = v
	if v then
		applyKorblox()
		notify("美化", "已应用断腿", 3)
	else
		removeKorblox()
		notify("美化", "已恢复右腿", 3)
	end
end)

-- 无头开关
local headlessOn = false
local originalHeadTransparency = 0
BeautifyGroup:AddToggle("Headless", {
	Text = "无头 (头部透明)",
	Default = false
}):OnChanged(function(v)
	headlessOn = v
	local char = getCharacter()
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end
	if v then
		originalHeadTransparency = head.Transparency
		pcall(function()
			head.Transparency = 1
			for _, d in ipairs(head:GetChildren()) do
				if d:IsA("Decal") or d:IsA("Texture") then
					d:Destroy()
				end
			end
		end)
		notify("美化", "已应用无头", 3)
	else
		pcall(function()
			head.Transparency = originalHeadTransparency
		end)
		notify("美化", "已恢复头部", 3)
	end
end)

-- 重生事件处理 (自动删除 / 自动颜色)
LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	if autoDeleteOnRespawn then
		deleteAccessoriesAndClothes(char)
	end
	if autoColorOnRespawn then
		randomColor(char)
	end
	if brokenLegOn then
		applyKorblox(char)
	end
	if headlessOn then
		pcall(function()
			local head = char:FindFirstChild("Head")
			if head then
				originalHeadTransparency = head.Transparency
				head.Transparency = 1
				for _, d in ipairs(head:GetChildren()) do
					if d:IsA("Decal") or d:IsA("Texture") then
						d:Destroy()
					end
				end
			end
		end)
	end
end)

-- ============================================================
-- 6. 动作功能
-- ============================================================
local ActionGroup = Tabs_Tools:AddLeftGroupbox("动作功能")

ActionGroup:AddButton("R6动作包", function()
	pcall(function()
		safeLoad("https://raw.githubusercontent.com/GreenNumber42/Roblox-Scripts/main/R6Animations.lua")
	end)
	notify("动作", "正在加载R6动作包", 3)
end)

ActionGroup:AddButton("动作V2", function()
	pcall(function()
		safeLoad("https://raw.githubusercontent.com/GreenNumber42/Roblox-Scripts/main/EmotesV2.lua")
	end)
	notify("动作", "正在加载动作V2", 3)
end)

ActionGroup:AddLabel("播放自定义动画")

local animIdInput = ActionGroup:AddInput("PlayAnimID", {
	Text = "动画ID",
	Default = "",
	Numeric = true
})

local playAnimID = ""
animIdInput:OnChanged(function(text)
	playAnimID = text or ""
end)

ActionGroup:AddButton("播放动画", function()
	local id = tonumber(playAnimID)
	if not id then
		notify("动画", "请输入有效动画ID", 3)
		return
	end
	pcall(function()
		local humanoid = getHumanoid()
		local char = getCharacter()
		if not humanoid or not char then
			notify("动画", "未找到角色", 3)
			return
		end
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = char:FindFirstChildOfClass("Animator")
		end
		if not animator then
			animator = humanoid:FindFirstChild("Animator")
		end
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(id)
		local track = animator:LoadAnimation(anim)
		track:Play()
		notify("动画", "正在播放动画 " .. id, 3)
	end)
end)
end -- 工具标签页 do...end

-- 服务器功能
local Tabs_Server = Window:AddTab("服务器功能", "server")
local ServerBox = Tabs_Server:AddLeftGroupbox("游戏脚本")
ServerBox:AddButton("忍者传奇", function()
    safeLoad("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E5%BF%8D%E8%80%85%E4%BC%A0%E5%A5%87XJW.lua")
end)
ServerBox:AddButton("力量传奇（安脚本）", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Anscripterato/QQ2134702438/refs/heads/main/byato/AnScript/atoscript"))()
end)
ServerBox:AddButton("极速传奇", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/XJW%E6%9E%81%E9%80%9F%E4%BC%A0%E5%A5%87.lua"))()
end)
ServerBox:AddButton("英雄时代", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E8%8B%B1%E9%9B%84%E6%97%B6%E4%BB%A3.lua"))()
end)
ServerBox:AddButton("NPC或死亡", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/NPC%E6%88%96%E6%AD%BB%E4%BA%A1.lua"))()
end)
ServerBox:AddButton("建造一架飞机", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E5%BB%BA%E9%80%A0%E4%B8%80%E4%B8%AA%E9%A3%9E%E6%9C%BA.lua"))()
end)
ServerBox:AddButton("[FPS]一键点击", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/FPS%E4%B8%80%E9%94%AE%E7%94%B5%E5%87%BB.lua"))()
end)
ServerBox:AddButton("捕捉10亿鸭子", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E6%8D%95%E6%8D%8910%E4%BA%BF%E5%8F%AA%E9%B8%AD%E5%AD%90.lua"))()
end)
-- UI设置
Tabs["UI Settings"] = Window:AddTab("UI设置", "settings")

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("UniversalSilentAim/Configs")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()

-- 启动成功通知
local _elapsed = tick() - _startTime
local _msg = string.format("耗时 %.2f 秒", _elapsed)
pcall(function()
    game.StarterGui:SetCore("SendNotification", {
        Title = "XJW中心加载成功",
        Text = _msg,
        Duration = 5,
    })
end)
