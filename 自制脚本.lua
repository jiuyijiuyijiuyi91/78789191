local repo = "https://raw.githubusercontent.com/ATLASTEAM01/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({ Title = "XJW中心", Footer = "1.3", Center = true, AutoShow = true })

local Tabs = {
    Announcement = Window:AddTab("公告", "megaphone"),
    Main = Window:AddTab("主页", "user"),
    Visual = Window:AddTab("视觉", "eye"),
    ["UI Settings"] = Window:AddTab("UI设置", "settings"),
}

-- 公告
local AnnouncementBox = Tabs.Announcement:AddLeftGroupbox("公告")
AnnouncementBox:AddLabel("本脚本为缝合脚本")

-- 主页
local FeatureBox = Tabs.Main:AddRightGroupbox("功能")
FeatureBox:AddButton("恐脚本飞行", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kongbaNB/9178/refs/heads/main/fly.lua"))()
end)

FeatureBox:AddButton("静默甩飞", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E9%9D%99%E9%BB%98%E7%94%A9%E9%A3%9E(%E5%BC%80%E6%BA%90).lua"))()
end)

FeatureBox:AddButton("祖国人汉化", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kongbaNB/-/refs/heads/main/祖国人汉化"))()
end)

-- 传送玩家
local TPPlayers = game:GetService("Players")
local TPDropdown = FeatureBox:AddDropdown("TP_Target", {
    Text = "选择玩家",
    Default = "",
    Values = {},
    Tooltip = "选择要传送到的玩家",
})

local function refreshPlayerList()
    local names = {}
    for _, p in pairs(TPPlayers:GetPlayers()) do
        if p ~= TPPlayers.LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    table.sort(names)
    TPDropdown:SetValues(names)
end

refreshPlayerList()
TPPlayers.PlayerAdded:Connect(refreshPlayerList)
TPPlayers.PlayerRemoving:Connect(refreshPlayerList)

FeatureBox:AddButton("传送", function()
    local target = Options.TP_Target.Value
    if target == "" then return end
    local targetPlayer = TPPlayers:FindFirstChild(target)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myChar = TPPlayers.LocalPlayer.Character
    if not targetHrp or not myChar then return end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
end)

FeatureBox:AddButton("全服传送", function()
    local myChar = TPPlayers.LocalPlayer.Character
    if not myChar then return end
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    for _, p in pairs(TPPlayers:GetPlayers()) do
        if p ~= TPPlayers.LocalPlayer and p.Character then
            local tHrp = p.Character:FindFirstChild("HumanoidRootPart")
            if tHrp then
                myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 3)
                task.wait(0.1)
            end
        end
    end
end)

-- 猫脚本甩飞 (SkidFling)
local FlingPlayers = game:GetService("Players")

local function SkidFling(TargetPlayer)
    local Player = FlingPlayers.LocalPlayer
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid, TRootPart, THead, Accessory, Handle

    if TCharacter and TCharacter:FindFirstChildOfClass("Humanoid") then
        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    end
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter and TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    if TCharacter and TCharacter:FindFirstChildOfClass("Accessory") then
        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    end
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end

    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        if not getgenv().FPDH then
            getgenv().FPDH = game:GetService("Workspace").FallenPartsDestroyHeight
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
            until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= FlingPlayers or not TargetPlayer.Character == TCharacter or (THumanoid and THumanoid.Sit) or Humanoid.Health <= 0 or tick() > Time + TimeToWait
        end

        game:GetService("Workspace").FallenPartsDestroyHeight = 0/0

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
        elseif TRootPart and not THead then
            SFBasePart(TRootPart)
        elseif not TRootPart and THead then
            SFBasePart(THead)
        elseif not TRootPart and not THead and Accessory and Handle then
            SFBasePart(Handle)
        end

        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        game:GetService("Workspace").CurrentCamera.CameraSubject = Humanoid

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
        game:GetService("Workspace").FallenPartsDestroyHeight = getgenv().FPDH
    end
end

FeatureBox:AddButton("甩飞选中", function()
    local target = Options.TP_Target.Value
    if target == "" then return end
    local targetPlayer = FlingPlayers:FindFirstChild(target)
    if not targetPlayer or not targetPlayer.Character then return end
    pcall(function()
        SkidFling(targetPlayer)
    end)
end)

FeatureBox:AddButton("全服甩飞", function()
    for _, x in pairs(FlingPlayers:GetPlayers()) do
        if x ~= FlingPlayers.LocalPlayer and x.Character then
            pcall(function()
                SkidFling(x)
            end)
            task.wait(0.5)
        end
    end
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

-- 2. 穿墙模式 (Noclip)
local noclipActive = false
local noclipConn = nil

local function startNoclip()
    noclipActive = true
    if noclipConn then return end
    noclipConn = CharRunService.Stepped:Connect(function()
        if not noclipActive or not charCharacter or not charCharacter.Parent then return end
        pcall(function()
            for _, part in pairs(charCharacter:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = false
                end
            end
        end)
    end)
end

local function stopNoclip()
    noclipActive = false
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    if not charCharacter or not charCharacter.Parent then return end
    pcall(function()
        for _, part in pairs(charCharacter:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end)
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

-- 7. 反挂机 (杂项)
local AntiAfkThread = nil
local function startAntiAfk()
    if AntiAfkThread then return end
    AntiAfkThread = task.spawn(function()
        while CharStates.AntiAfk.Enabled do
            task.wait(math.random(15, 30))
            pcall(function()
                CharVirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.05)
                CharVirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
            pcall(function()
                CharVirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                task.wait(0.1)
                CharVirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
            end)
        end
    end)
end

local function stopAntiAfk()
    CharStates.AntiAfk.Enabled = false
    AntiAfkThread = nil
end

-- 死亡后重新应用所有已开启的功能
local function reapplyAllStates()
    charRefresh()
    if not charCharacter or not charHumanoid then return end
    if CharStates.WalkSpeed.Enabled then applyWalkSpeed() end
    if CharStates.SuperJump.Enabled then applySuperJump() end
    if noclipActive then startNoclip() end
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
    loadstring(game:HttpGet("https://raw.githubusercontent.com/idrobsc/rob_script/refs/heads/main/rob.v4"))()
end)

MainSettingsBox:AddButton("AF HUB", function()
    getgenv().SCRIPT_KEY = ""
    loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/4e025c3c0ccda1554634165acb8f8ee2c1de5f0f8d7f60e7b396c622d7e6e9b0/download"))()
end)

MainSettingsBox:AddButton("叶脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/roblox-ye/QQ515966991/refs/heads/main/ROBLOX-CNVIP-XIAOYE.lua"))()
end)

-- 杂项 UI
local MiscBox = Tabs.Main:AddLeftGroupbox("杂项")
MiscBox:AddToggle("Char_AntiAfk", { Text = "反挂机", Default = false }):OnChanged(function(v)
    CharStates.AntiAfk.Enabled = v
    if v then startAntiAfk() else stopAntiAfk() end
end)

-- ============================================
-- 旋转 & 防甩飞 & 跟随 & 飞行 & 动作 & IY指令
-- ============================================

-- 旋转功能
local SpinBox = Tabs.Main:AddRightGroupbox("旋转 & 防甩飞")
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

-- 防甩飞
local antiflingRunning = false
SpinBox:AddToggle("Antifling_Enabled", { Text = "防甩飞", Default = false }):OnChanged(function(state)
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
local FollowBox = Tabs.Main:AddRightGroupbox("跟随功能")
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

local joinNotifyEnabled = false
FollowBox:AddToggle("JoinNotify_Enabled", { Text = "玩家进入通知", Default = false }):OnChanged(function(state)
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

-- 无敌少侠飞行 & 动作脚本
local ActionBox = Tabs.Main:AddRightGroupbox("飞行 & 动作")
ActionBox:AddButton("无敌少侠飞行r15", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/396abc/Script/refs/heads/main/MobileFly.lua"))()
end)

ActionBox:AddButton("动作脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua"))()
end)

ActionBox:AddButton("r6动作脚本", function()
    loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-R6-Animations-Menu-By-Me-19427"))()
end)

-- IY指令
local IYBox = Tabs.Main:AddRightGroupbox("IY指令")
IYBox:AddButton("执行Dex", function()
    loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
end)

IYBox:AddButton("执行rspy", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"))()
end)

IYBox:AddButton("执行Cspy", function()
    loadstring(game:HttpGet("https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau"))()
end)

IYBox:AddButton("执行mdex", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))()
end)

-- 视觉 - ESP
local ESPEnabled = false
local ESPConnections = {}
local ESPCache = {}
local ESPVelocityData = {}
local ESPTimers = { lastVisRefresh = 0, lastWeaponRefresh = 0 }
local ESPVisibilityCache = {}
local ESPWeaponCache = {}
local ESPShieldCache = {}

local ESPConfig = {
    ESP_Boxes = true,
    ESP_Names = true,
    ESP_Distance = true,
    ESP_Skeleton = true,
    ESP_Weapons = true,
    ESP_MaxDist = 2000,
    ESP_Offscreen = true,
    ESP_AimDir = true,
    ESP_LookingAtYou = true,
    ESP_Tracers = false,
    ESP_Velocity = false,
    ESP_Shield = true,
    ESP_TeamCheck = false,
    TeamAttributeName = "Team",
}

local ESPTuning = {
    VisibilityRefreshRate = 0.15,
    WeaponRefreshRate = 2.0,
    ShieldDuration = 1.5,
    BoxWidthRatio = 0.6,
    NameOffset = 18,
    DistOffset = 4,
    WeaponOffset = 8,
    LookingOffset = 35,
    ShieldOffset = 50,
    OffscreenEdgeDist = 50,
    OffscreenArrowSize = 12,
    AimLineLength = 15,
    LookingThreshold = 0.85,
}

local ESPColors = {
    Enemy = Color3.fromRGB(255, 50, 50),
    EnemyVisible = Color3.fromRGB(0, 255, 0),
    Lobby = Color3.fromRGB(150, 150, 150),
    Shielded = Color3.fromRGB(255, 200, 0),
    Skeleton = Color3.fromRGB(255, 255, 255),
    SkeletonVisible = Color3.fromRGB(0, 255, 0),
    LookingAtYou = Color3.fromRGB(255, 255, 0),
    AimDir = Color3.fromRGB(255, 150, 0),
    Weapon = Color3.fromRGB(255, 200, 100),
    Tracer = Color3.fromRGB(255, 100, 100),
}

local ESPBones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}
local ESPR6Bones = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local ESPPlayers = game:GetService("Players")
local ESPRunService = game:GetService("RunService")
local ESPLocalPlayer = ESPPlayers.LocalPlayer

local function ESPgetPlayerFromCharacter(char)
    for _, p in pairs(ESPPlayers:GetPlayers()) do
        if p.Character == char then return p end
    end
    return nil
end

local function ESPgetTeamAttribute(player)
    local attr = player:GetAttribute(ESPConfig.TeamAttributeName)
    if attr ~= nil then return attr end
    if player.Character then
        attr = player.Character:GetAttribute(ESPConfig.TeamAttributeName)
        if attr ~= nil then return attr end
    end
    return nil
end

local function ESPisTeammate(char)
    if not ESPConfig.ESP_TeamCheck then return false end
    local player = ESPgetPlayerFromCharacter(char)
    if not player then return false end
    local myTeam = ESPgetTeamAttribute(ESPLocalPlayer)
    local theirTeam = ESPgetTeamAttribute(player)
    if myTeam == nil or theirTeam == nil then return false end
    return myTeam == theirTeam
end

local function ESPisInLobby(char)
    local player = ESPgetPlayerFromCharacter(char)
    if not player then return false end
    local team = ESPgetTeamAttribute(player)
    return team == "Lobby"
end

local function ESPisShielded(char)
    return ESPShieldCache[char] and tick() < ESPShieldCache[char]
end

local function ESPapplyShield(char)
    ESPShieldCache[char] = tick() + ESPTuning.ShieldDuration
end

local function ESPisVisible(character)
    if not character then return false end
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local origin = cam.CFrame.Position
    local parts = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local filter = {cam}
    if ESPLocalPlayer.Character then table.insert(filter, ESPLocalPlayer.Character) end
    table.insert(filter, character)
    rayParams.FilterDescendantsInstances = filter
    for _, partName in pairs(parts) do
        local part = character:FindFirstChild(partName)
        if part then
            local dir = (part.Position - origin)
            local result = workspace:Raycast(origin, dir.Unit * dir.Magnitude, rayParams)
            if not result or (result.Position - part.Position).Magnitude < 5 then
                return true
            end
        end
    end
    return false
end

local function ESPisLookingAtYou(char)
    if not ESPLocalPlayer.Character then return false end
    local myHead = ESPLocalPlayer.Character:FindFirstChild("Head")
    local head = char:FindFirstChild("Head")
    if not myHead or not head then return false end
    local toYou = (myHead.Position - head.Position).Unit
    return toYou:Dot(head.CFrame.LookVector) > ESPTuning.LookingThreshold
end

local function ESPgetWeapon(char)
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then return tool.Name end
    return nil
end

local function ESPisR6(char)
    return char:FindFirstChild("Torso") ~= nil
end

local function ESPrefreshVisibility()
    local count = 0
    for _, player in ipairs(ESPPlayers:GetPlayers()) do
        if player ~= ESPLocalPlayer and player.Character then
            count = count + 1
            if count > 20 then
                ESPVisibilityCache[player] = false
            else
                ESPVisibilityCache[player] = ESPisVisible(player.Character)
            end
        end
    end
end

local function ESPrefreshWeapons()
    for _, player in ipairs(ESPPlayers:GetPlayers()) do
        if player ~= ESPLocalPlayer and player.Character then
            ESPWeaponCache[player] = ESPgetWeapon(player.Character)
        end
    end
end

local function ESPcreate()
    local skel = {}
    for i = 1, 14 do skel[i] = Drawing.new("Line") end
    return {
        Box = { Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line") },
        Name = Drawing.new("Text"),
        Dist = Drawing.new("Text"),
        Weapon = Drawing.new("Text"),
        Skel = skel,
        Offscreen = Drawing.new("Triangle"),
        AimLine = Drawing.new("Line"),
        LookingText = Drawing.new("Text"),
        ShieldText = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        VelLine = Drawing.new("Line"),
        VelArrow = Drawing.new("Triangle")
    }
end

local function ESPsetup(esp)
    for _, l in pairs(esp.Box) do l.Thickness = 1 end
    esp.Name.Size = 14
    esp.Name.Font = Drawing.Fonts.Monospace
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Dist.Size = 12
    esp.Dist.Font = Drawing.Fonts.Monospace
    esp.Dist.Center = true
    esp.Dist.Outline = true
    esp.Weapon.Size = 12
    esp.Weapon.Font = Drawing.Fonts.Monospace
    esp.Weapon.Outline = true
    for _, l in pairs(esp.Skel) do l.Thickness = 1 end
    esp.Offscreen.Filled = true
    esp.Offscreen.Thickness = 2
    esp.AimLine.Thickness = 2
    esp.LookingText.Size = 14
    esp.LookingText.Font = Drawing.Fonts.Monospace
    esp.LookingText.Center = true
    esp.LookingText.Outline = true
    esp.ShieldText.Size = 14
    esp.ShieldText.Font = Drawing.Fonts.Monospace
    esp.ShieldText.Center = true
    esp.ShieldText.Outline = true
    esp.ShieldText.Color = ESPColors.Shielded
    esp.Tracer.Thickness = 1
    esp.Tracer.Color = ESPColors.Tracer
    esp.VelLine.Thickness = 2
    esp.VelLine.Color = Color3.fromRGB(0, 255, 255)
    esp.VelArrow.Filled = true
    esp.VelArrow.Color = Color3.fromRGB(0, 255, 255)
end

local function ESPhide(esp)
    for _, l in pairs(esp.Box) do l.Visible = false end
    esp.Name.Visible = false
    esp.Dist.Visible = false
    esp.Weapon.Visible = false
    for _, l in pairs(esp.Skel) do l.Visible = false end
    esp.Offscreen.Visible = false
    esp.AimLine.Visible = false
    esp.LookingText.Visible = false
    esp.ShieldText.Visible = false
    esp.Tracer.Visible = false
    esp.VelLine.Visible = false
    esp.VelArrow.Visible = false
end

local function ESPdestroy(esp)
    pcall(function()
        for _, l in pairs(esp.Box) do l:Remove() end
        esp.Name:Remove()
        esp.Dist:Remove()
        esp.Weapon:Remove()
        for _, l in pairs(esp.Skel) do l:Remove() end
        esp.Offscreen:Remove()
        esp.AimLine:Remove()
        esp.LookingText:Remove()
        esp.ShieldText:Remove()
        esp.Tracer:Remove()
        esp.VelLine:Remove()
        esp.VelArrow:Remove()
    end)
end

local function ESPcleanup()
    local validPlayers = {}
    for _, p in ipairs(ESPPlayers:GetPlayers()) do validPlayers[p] = true end
    for player, esp in pairs(ESPCache) do
        if not validPlayers[player] then
            ESPhide(esp)
            ESPdestroy(esp)
            ESPCache[player] = nil
            ESPVelocityData[player] = nil
        end
    end
end

local function ESPhideAll()
    for _, esp in pairs(ESPCache) do ESPhide(esp) end
end

local function ESPrender(esp, player, char, root, cam, screenSize, screenCenter, dist, isLobby)
    local head = char:FindFirstChild("Head")
    local headPos = head and head.Position or (root.Position + Vector3.new(0, 2, 0))
    local feetPos = root.Position - Vector3.new(0, 3, 0)
    local topPos = headPos + Vector3.new(0, 0.5, 0)
    local rs, ron = cam:WorldToViewportPoint(root.Position)
    local hs = cam:WorldToViewportPoint(topPos)
    local fs = cam:WorldToViewportPoint(feetPos)
    local onScreen = ron and rs.Z > 0
    local visible = ESPVisibilityCache[player] or false
    local shielded = ESPisShielded(char)
    local col
    if shielded and ESPConfig.ESP_Shield then
        col = ESPColors.Shielded
    elseif isLobby then
        col = ESPColors.Lobby
    else
        col = visible and ESPColors.EnemyVisible or ESPColors.Enemy
    end
    local skelCol = visible and ESPColors.SkeletonVisible or ESPColors.Skeleton
    local lookingAtYou = visible and ESPisLookingAtYou(char) or false
    if not onScreen then
        ESPhide(esp)
        if ESPConfig.ESP_Offscreen and visible then
            local screenPos = cam:WorldToViewportPoint(root.Position)
            local dx, dy = screenPos.X - screenCenter.X, screenPos.Y - screenCenter.Y
            local angle = math.atan2(dy, dx)
            local arrowX = math.clamp(screenCenter.X + math.cos(angle) * (screenSize.X/2 - ESPTuning.OffscreenEdgeDist), ESPTuning.OffscreenEdgeDist, screenSize.X - ESPTuning.OffscreenEdgeDist)
            local arrowY = math.clamp(screenCenter.Y + math.sin(angle) * (screenSize.Y/2 - ESPTuning.OffscreenEdgeDist), ESPTuning.OffscreenEdgeDist, screenSize.Y - ESPTuning.OffscreenEdgeDist)
            local fwd = Vector2.new(math.cos(angle), math.sin(angle))
            local right = Vector2.new(-fwd.Y, fwd.X)
            local pos = Vector2.new(arrowX, arrowY)
            esp.Offscreen.PointA = pos + fwd * ESPTuning.OffscreenArrowSize
            esp.Offscreen.PointB = pos - fwd * ESPTuning.OffscreenArrowSize/2 - right * ESPTuning.OffscreenArrowSize/2
            esp.Offscreen.PointC = pos - fwd * ESPTuning.OffscreenArrowSize/2 + right * ESPTuning.OffscreenArrowSize/2
            esp.Offscreen.Color = ESPColors.EnemyVisible
            esp.Offscreen.Visible = true
        end
        return
    end
    esp.Offscreen.Visible = false
    local boxTop, boxBottom = hs.Y, fs.Y
    local boxHeight = math.abs(boxBottom - boxTop)
    local boxWidth = boxHeight * ESPTuning.BoxWidthRatio
    local cx = rs.X
    if ESPConfig.ESP_Boxes then
        esp.Box[1].From = Vector2.new(cx - boxWidth/2, boxTop)
        esp.Box[1].To = Vector2.new(cx + boxWidth/2, boxTop)
        esp.Box[2].From = Vector2.new(cx + boxWidth/2, boxTop)
        esp.Box[2].To = Vector2.new(cx + boxWidth/2, boxBottom)
        esp.Box[3].From = Vector2.new(cx + boxWidth/2, boxBottom)
        esp.Box[3].To = Vector2.new(cx - boxWidth/2, boxBottom)
        esp.Box[4].From = Vector2.new(cx - boxWidth/2, boxBottom)
        esp.Box[4].To = Vector2.new(cx - boxWidth/2, boxTop)
        for _, l in pairs(esp.Box) do l.Color = col; l.Visible = true end
    else
        for _, l in pairs(esp.Box) do l.Visible = false end
    end
    if ESPConfig.ESP_Names then
        esp.Name.Text = player.Name
        esp.Name.Position = Vector2.new(cx, hs.Y - ESPTuning.NameOffset)
        esp.Name.Color = col
        esp.Name.Visible = true
    else
        esp.Name.Visible = false
    end
    if ESPConfig.ESP_Distance then
        esp.Dist.Text = math.floor(dist) .. "m"
        esp.Dist.Position = Vector2.new(cx, fs.Y + ESPTuning.DistOffset)
        esp.Dist.Color = Color3.fromRGB(180, 180, 180)
        esp.Dist.Visible = true
    else
        esp.Dist.Visible = false
    end
    if ESPConfig.ESP_Weapons then
        local weapon = ESPWeaponCache[player]
        if weapon then
            esp.Weapon.Text = "[" .. weapon .. "]"
            esp.Weapon.Position = Vector2.new(cx + boxWidth/2 + ESPTuning.WeaponOffset, rs.Y)
            esp.Weapon.Color = ESPColors.Weapon
            esp.Weapon.Visible = true
        else
            esp.Weapon.Visible = false
        end
    else
        esp.Weapon.Visible = false
    end
    if ESPConfig.ESP_Skeleton then
        local bones = ESPisR6(char) and ESPR6Bones or ESPBones
        for i, b in pairs(bones) do
            if esp.Skel[i] then
                local p1, p2 = char:FindFirstChild(b[1]), char:FindFirstChild(b[2])
                if p1 and p2 then
                    local s1, o1 = cam:WorldToViewportPoint(p1.Position)
                    local s2, o2 = cam:WorldToViewportPoint(p2.Position)
                    if o1 and o2 and s1.Z > 0 and s2.Z > 0 then
                        esp.Skel[i].From = Vector2.new(s1.X, s1.Y)
                        esp.Skel[i].To = Vector2.new(s2.X, s2.Y)
                        esp.Skel[i].Color = skelCol
                        esp.Skel[i].Visible = true
                    else
                        esp.Skel[i].Visible = false
                    end
                else
                    esp.Skel[i].Visible = false
                end
            end
        end
        for i = #bones + 1, #esp.Skel do
            if esp.Skel[i] then esp.Skel[i].Visible = false end
        end
    else
        for _, l in pairs(esp.Skel) do l.Visible = false end
    end
    if ESPConfig.ESP_AimDir and head then
        local aimEnd = head.Position + head.CFrame.LookVector * ESPTuning.AimLineLength
        local aimScreen, aimOn = cam:WorldToViewportPoint(aimEnd)
        local headScreen = cam:WorldToViewportPoint(head.Position)
        if aimOn and headScreen.Z > 0 then
            esp.AimLine.From = Vector2.new(headScreen.X, headScreen.Y)
            esp.AimLine.To = Vector2.new(aimScreen.X, aimScreen.Y)
            esp.AimLine.Color = ESPColors.AimDir
            esp.AimLine.Visible = true
        else
            esp.AimLine.Visible = false
        end
    else
        esp.AimLine.Visible = false
    end
    if ESPConfig.ESP_LookingAtYou and lookingAtYou then
        esp.LookingText.Text = "[!] LOOKING"
        esp.LookingText.Position = Vector2.new(cx, hs.Y - ESPTuning.LookingOffset)
        esp.LookingText.Color = ESPColors.LookingAtYou
        esp.LookingText.Visible = true
    else
        esp.LookingText.Visible = false
    end
    if ESPConfig.ESP_Shield and shielded then
        local remaining = ESPShieldCache[char] - tick()
        esp.ShieldText.Text = "[SHIELDED " .. string.format("%.1f", math.max(0, remaining)) .. "s]"
        esp.ShieldText.Position = Vector2.new(cx, hs.Y - ESPTuning.ShieldOffset)
        esp.ShieldText.Visible = true
    else
        esp.ShieldText.Visible = false
    end
    if ESPConfig.ESP_Tracers then
        esp.Tracer.From = Vector2.new(screenCenter.X, screenSize.Y)
        esp.Tracer.To = Vector2.new(cx, fs.Y)
        esp.Tracer.Color = visible and ESPColors.EnemyVisible or ESPColors.Tracer
        esp.Tracer.Visible = true
    else
        esp.Tracer.Visible = false
    end
    local vd = ESPVelocityData[player]
    if not vd then
        vd = { pos = root.Position, vel = Vector3.zero, time = tick() }
        ESPVelocityData[player] = vd
    end
    local now = tick()
    local dt = now - vd.time
    if dt > 0.03 then
        local rawVel = (root.Position - vd.pos) / dt
        vd.vel = vd.vel * 0.7 + rawVel * 0.3
        vd.pos = root.Position
        vd.time = now
    end
    if ESPConfig.ESP_Velocity then
        local velFlat = Vector3.new(vd.vel.X, 0, vd.vel.Z)
        local velMag = velFlat.Magnitude
        if velMag > 2 then
            local futurePos = root.Position + velFlat.Unit * math.clamp(velMag * 0.4, 5, 20)
            local futureScreen, futureOn = cam:WorldToViewportPoint(futurePos)
            if futureOn and futureScreen.Z > 0 then
                esp.VelLine.From = Vector2.new(rs.X, rs.Y)
                esp.VelLine.To = Vector2.new(futureScreen.X, futureScreen.Y)
                esp.VelLine.Visible = true
                local dx, dy = futureScreen.X - rs.X, futureScreen.Y - rs.Y
                local len = math.sqrt(dx*dx + dy*dy)
                if len > 5 then
                    local fx, fy = dx/len, dy/len
                    esp.VelArrow.PointA = Vector2.new(futureScreen.X, futureScreen.Y)
                    esp.VelArrow.PointB = Vector2.new(futureScreen.X - fx*10 + fy*5, futureScreen.Y - fy*10 - fx*5)
                    esp.VelArrow.PointC = Vector2.new(futureScreen.X - fx*10 - fy*5, futureScreen.Y - fy*10 + fx*5)
                    esp.VelArrow.Visible = true
                else
                    esp.VelArrow.Visible = false
                end
            else
                esp.VelLine.Visible = false
                esp.VelArrow.Visible = false
            end
        else
            esp.VelLine.Visible = false
            esp.VelArrow.Visible = false
        end
    else
        esp.VelLine.Visible = false
        esp.VelArrow.Visible = false
    end
end

local function ESPstep(cam, screenSize, screenCenter)
    ESPcleanup()
    for _, player in ipairs(ESPPlayers:GetPlayers()) do
        if player == ESPLocalPlayer then continue end
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            if ESPCache[player] then ESPhide(ESPCache[player]) end
        else
            if ESPisTeammate(char) then
                if ESPCache[player] then ESPhide(ESPCache[player]) end
                continue
            end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not ESPCache[player] then
                ESPCache[player] = ESPcreate()
                ESPsetup(ESPCache[player])
            end
            local esp = ESPCache[player]
            local myChar = ESPLocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
            local isLobby = ESPisInLobby(char)
            if dist > ESPConfig.ESP_MaxDist then
                ESPhide(esp)
            else
                ESPrender(esp, player, char, root, cam, screenSize, screenCenter, dist, isLobby)
            end
        end
    end
end

local function StartESP()
    if ESPEnabled then return end
    ESPEnabled = true
    ESPConnections.render = ESPRunService.RenderStepped:Connect(function()
        if not ESPEnabled then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local screenSize = cam.ViewportSize
        local screenCenter = Vector2.new(screenSize.X/2, screenSize.Y/2)
        local now = tick()
        if now - ESPTimers.lastVisRefresh > ESPTuning.VisibilityRefreshRate then
            ESPTimers.lastVisRefresh = now
            ESPrefreshVisibility()
        end
        if now - ESPTimers.lastWeaponRefresh > ESPTuning.WeaponRefreshRate then
            ESPTimers.lastWeaponRefresh = now
            ESPrefreshWeapons()
        end
        ESPstep(cam, screenSize, screenCenter)
    end)
    ESPConnections.playerAdded = ESPPlayers.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            ESPapplyShield(char)
        end)
    end)
    for _, player in pairs(ESPPlayers:GetPlayers()) do
        if player ~= ESPLocalPlayer then
            player.CharacterAdded:Connect(function(char)
                ESPapplyShield(char)
            end)
        end
    end
end

local function StopESP()
    if not ESPEnabled then return end
    ESPEnabled = false
    for _, c in pairs(ESPConnections) do
        pcall(function() c:Disconnect() end)
    end
    ESPConnections = {}
    for _, esp in pairs(ESPCache) do
        ESPhide(esp)
        ESPdestroy(esp)
    end
    ESPCache = {}
    ESPVelocityData = {}
    ESPVisibilityCache = {}
    ESPWeaponCache = {}
    ESPShieldCache = {}
end

local ESPLeftBox = Tabs.Visual:AddLeftGroupbox("ESP设置")
ESPLeftBox:AddToggle("ESP_Enabled", { Text = "启用 ESP", Default = false }):OnChanged(function(Value)
    if Value then
        StartESP()
    else
        StopESP()
    end
end)

ESPLeftBox:AddToggle("ESP_Boxes", { Text = "方框", Default = true }):OnChanged(function(Value)
    ESPConfig.ESP_Boxes = Value
end)

ESPLeftBox:AddToggle("ESP_Names", { Text = "名字", Default = true }):OnChanged(function(Value)
    ESPConfig.ESP_Names = Value
end)

ESPLeftBox:AddToggle("ESP_Distance", { Text = "距离", Default = true }):OnChanged(function(Value)
    ESPConfig.ESP_Distance = Value
end)

ESPLeftBox:AddToggle("ESP_Skeleton", { Text = "骨骼", Default = true }):OnChanged(function(Value)
    ESPConfig.ESP_Skeleton = Value
end)

ESPLeftBox:AddToggle("ESP_Weapons", { Text = "武器", Default = true }):OnChanged(function(Value)
    ESPConfig.ESP_Weapons = Value
end)

ESPLeftBox:AddToggle("ESP_AimDir", { Text = "瞄准线", Default = true }):OnChanged(function(Value)
    ESPConfig.ESP_AimDir = Value
end)

ESPLeftBox:AddToggle("ESP_LookingAtYou", { Text = "正在看你", Default = true }):OnChanged(function(Value)
    ESPConfig.ESP_LookingAtYou = Value
end)

local ESPRightBox = Tabs.Visual:AddRightGroupbox("其他设置")
ESPRightBox:AddToggle("ESP_Shield", { Text = "护盾指示器", Default = true }):OnChanged(function(Value)
    ESPConfig.ESP_Shield = Value
end)

ESPRightBox:AddToggle("ESP_Offscreen", { Text = "屏幕外箭头", Default = true }):OnChanged(function(Value)
    ESPConfig.ESP_Offscreen = Value
end)

ESPRightBox:AddToggle("ESP_Tracers", { Text = "轨迹线", Default = false }):OnChanged(function(Value)
    ESPConfig.ESP_Tracers = Value
end)

ESPRightBox:AddToggle("ESP_Velocity", { Text = "速度线", Default = false }):OnChanged(function(Value)
    ESPConfig.ESP_Velocity = Value
end)

ESPRightBox:AddToggle("ESP_TeamCheck", { Text = "队伍检测(不透视队友)", Default = false }):OnChanged(function(Value)
    ESPConfig.ESP_TeamCheck = Value
end)

ESPRightBox:AddSlider("ESP_MaxDist", { Text = "最大显示距离", Default = 2000, Min = 500, Max = 5000, Rounding = 0 }):OnChanged(function(Value)
    ESPConfig.ESP_MaxDist = Value
end)

-- ============================================
-- 玩家标签页 - 信息/甩飞/坐头/传送/监视/跟随
-- ============================================
do
local Tabs_Player = Window:AddTab("玩家", "users")

local RunService = game:GetService("RunService")
local LocalPlayer = game.Players.LocalPlayer

-- 公共状态
local PState = {
    selectedPlayer = nil,
    conns = {},
    threads = {},
}

local function pNotify(title, text)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 3 })
    end)
end

local function getLocalChar()
    return LocalPlayer.Character
end

local function getTargetPlayer(name)
    for _, p in ipairs(game.Players:GetPlayers()) do
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

-- ============================================
-- 1. 信息功能
-- ============================================
local InfoBox = Tabs_Player:AddLeftGroupbox("信息")
local lp = LocalPlayer
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
    pNotify("成功", "信息已复制到剪贴板")
end)

-- ============================================
-- 公共玩家选择器
-- ============================================
local PlayerSelectBox = Tabs_Player:AddLeftGroupbox("选择玩家")
local playerDropdown = PlayerSelectBox:AddDropdown("P_PlayerSelect", {
    Text = "选择目标玩家",
    Values = {},
    Default = "",
    Multi = false,
})
playerDropdown:OnChanged(function(v)
    PState.selectedPlayer = v
end)

PlayerSelectBox:AddButton("刷新玩家列表", function()
    local names = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    playerDropdown:SetValues(names)
    pNotify("刷新", "已刷新玩家列表")
end)

-- ============================================
-- 2. 甩飞功能
-- ============================================
local FlingBox = Tabs_Player:AddLeftGroupbox("甩飞功能")

local flingLoops = { single = false, all = false }

local function SkidFling(targetPlayer)
    local Character = LocalPlayer.Character
    if not Character then return end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
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
        until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= targetPlayer.Character or targetPlayer.Parent ~= game.Players or not targetPlayer.Character == TCharacter or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
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

FlingBox:AddButton("甩飞一次指定玩家", function()
    if not PState.selectedPlayer then pNotify("错误", "请先选择玩家") return end
    local target = getTargetPlayer(PState.selectedPlayer)
    if not target then pNotify("错误", "未找到玩家") return end
    pcall(function() SkidFling(target) end)
    pNotify("成功", "甩飞玩家一次")
end)

FlingBox:AddToggle("P_LoopFlingSingle", { Text = "循环甩飞指定玩家", Default = false }):OnChanged(function(v)
    flingLoops.single = v
    if v then
        local thread = task.spawn(function()
            while flingLoops.single do
                if PState.selectedPlayer then
                    local target = getTargetPlayer(PState.selectedPlayer)
                    if target then pcall(function() SkidFling(target) end) end
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

FlingBox:AddButton("甩飞一次所有玩家", function()
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= LocalPlayer then
            pcall(function() SkidFling(p) end)
        end
    end
    pNotify("成功", "甩飞所有玩家一次")
end)

FlingBox:AddToggle("P_LoopFlingAll", { Text = "循环甩飞所有玩家", Default = false }):OnChanged(function(v)
    flingLoops.all = v
    if v then
        local thread = task.spawn(function()
            while flingLoops.all do
                for _, p in ipairs(game.Players:GetPlayers()) do
                    if not flingLoops.all then break end
                    if p ~= LocalPlayer then
                        pcall(function() SkidFling(p) end)
                    end
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

FlingBox:AddButton("停止所有甩飞", function()
    flingLoops.single = false
    flingLoops.all = false
    pNotify("停止", "已停止所有甩飞")
end)

-- ============================================
-- 3. 坐头功能
-- ============================================
local HeadSitBox = Tabs_Player:AddLeftGroupbox("坐头功能")
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

    PState.conns.headSit = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not headSitActive or not char.Parent then
                if loopHeadSit and LocalPlayer.Character then
                    task.wait(1)
                    if loopHeadSit and PState.selectedPlayer then
                        startHeadSit(PState.selectedPlayer)
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
                    if loopHeadSit and PState.selectedPlayer then
                        startHeadSit(PState.selectedPlayer)
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
    if not PState.selectedPlayer then pNotify("提示", "请先选择玩家") return end
    stopHeadSit()
    startHeadSit(PState.selectedPlayer)
end)

HeadSitBox:AddToggle("P_LoopHeadSit", { Text = "循环坐头(死亡后继续)", Default = false }):OnChanged(function(v)
    loopHeadSit = v
    if v and PState.selectedPlayer then
        stopHeadSit()
        startHeadSit(PState.selectedPlayer)
    else
        stopHeadSit()
    end
end)

HeadSitBox:AddButton("停止坐头", stopHeadSit)

-- ============================================
-- 4. 传送功能
-- ============================================
local TeleportBox = Tabs_Player:AddLeftGroupbox("传送功能")
local tpLoops = { single = false, all = false }

local function teleportToPlayer(targetPlayer)
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if targetRoot then
        root.CFrame = targetRoot.CFrame
    end
end

TeleportBox:AddButton("传送到选定玩家", function()
    if not PState.selectedPlayer then pNotify("提示", "请先选择玩家") return end
    local target = getTargetPlayer(PState.selectedPlayer)
    if not target or not target.Character then pNotify("失败", "目标不存在") return end
    teleportToPlayer(target)
    pNotify("成功", "已传送到 " .. target.Name)
end)

TeleportBox:AddToggle("P_LoopTPSingle", { Text = "循环传送同个玩家", Default = false }):OnChanged(function(v)
    tpLoops.single = v
    if v then
        local thread = task.spawn(function()
            while tpLoops.single do
                if PState.selectedPlayer then
                    local target = getTargetPlayer(PState.selectedPlayer)
                    if target and target.Character then teleportToPlayer(target) end
                end
                task.wait(0.3)
            end
        end)
        table.insert(PState.threads, thread)
    end
end)

TeleportBox:AddToggle("P_LoopTPAll", { Text = "循环传送所有玩家", Default = false }):OnChanged(function(v)
    tpLoops.all = v
    if v then
        local thread = task.spawn(function()
            while tpLoops.all do
                for _, p in ipairs(game.Players:GetPlayers()) do
                    if not tpLoops.all then break end
                    if p ~= LocalPlayer and p.Character then
                        teleportToPlayer(p)
                        task.wait(0.3)
                    end
                end
            end
        end)
        table.insert(PState.threads, thread)
    end
end)

-- ============================================
-- 5. 视角监视
-- ============================================
local MonitorBox = Tabs_Player:AddRightGroupbox("视角监视")

local function stopMonitor()
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

local function startMonitor(playerName)
    if PState.conns.monitor then
        PState.conns.monitor:Disconnect()
        PState.conns.monitor = nil
    end
    local camera = workspace.CurrentCamera
    if not camera then return end

    PState.conns.monitor = RunService.Heartbeat:Connect(function()
        pcall(function()
            local target = getTargetPlayer(playerName)
            if not target or not target.Character then
                stopMonitor()
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

MonitorBox:AddButton("开始监视选定玩家", function()
    if not PState.selectedPlayer then pNotify("提示", "请先选择玩家") return end
    stopMonitor()
    startMonitor(PState.selectedPlayer)
end)

MonitorBox:AddButton("停止监视", stopMonitor)

-- ============================================
-- 6. 恶搞跟随 (14种模式)
-- ============================================
local FollowBox = Tabs_Player:AddRightGroupbox("恶搞跟随")
local followStates = {}

local function stopAllFollows()
    for name, _ in pairs(followStates) do
        followStates[name] = false
    end
    for name, conn in pairs(PState.conns) do
        if name:find("follow_") then
            conn:Disconnect()
            PState.conns[name] = nil
        end
    end
    local char = getLocalChar()
    if char then enableCollision(char) end
end

-- 旋转环绕
local function startOrbit(target)
    followStates.orbit = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    disableCollision(char)
    local angle = 0
    PState.conns.follow_orbit = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.orbit or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            angle = angle + 0.05
            if angle > 360 then angle = 0 end
            root.CFrame = CFrame.new(tr.Position + Vector3.new(math.cos(angle)*5, 2, math.sin(angle)*5), tr.Position)
        end)
    end)
end

-- 镜像
local function startMirror(target)
    followStates.mirror = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    disableCollision(char)
    PState.conns.follow_mirror = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.mirror or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            local pos = tr.CFrame * CFrame.new(4, 0, 0)
            root.CFrame = CFrame.new(pos.Position) * CFrame.Angles(0, math.pi, 0)
        end)
    end)
end

-- 漂浮
local function startFloat(target)
    followStates.float = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    disableCollision(char)
    PState.conns.follow_float = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.float or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            root.CFrame = CFrame.new(tr.Position + Vector3.new(0, 3, 0))
        end)
    end)
end

-- 影子
local function startShadow(target)
    followStates.shadow = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    disableCollision(char)
    PState.conns.follow_shadow = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.shadow or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            root.CFrame = tr.CFrame * CFrame.new(0, -2.8, 0)
        end)
    end)
end

-- 反向跟随
local function startAntiFollow(target)
    followStates.anti = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    PState.conns.follow_anti = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.anti or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            local dist = (root.Position - tr.Position).Magnitude
            if dist < 8 then
                local away = (root.Position - tr.Position).Unit
                root.CFrame = CFrame.new(tr.Position + away * 8)
            end
        end)
    end)
end

-- 旋转
local function startSpin(target)
    followStates.spin = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    disableCollision(char)
    local angle = 0
    PState.conns.follow_spin = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.spin or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            angle = angle + 5
            root.CFrame = CFrame.new(tr.Position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.rad(angle), 0)
        end)
    end)
end

-- 抖动
local function startShake(target)
    followStates.shake = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    disableCollision(char)
    PState.conns.follow_shake = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.shake or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            local offset = Vector3.new(math.random(-2, 2), math.random(0, 3), math.random(-2, 2))
            root.CFrame = CFrame.new(tr.Position + offset)
        end)
    end)
end

-- 站头后
local function startFaceStand(target)
    followStates.face = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    disableCollision(char)
    PState.conns.follow_face = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.face or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            root.CFrame = tr.CFrame * CFrame.new(0, 3.5, 0)
        end)
    end)
end

-- 坐前面
local function startBackSit(target)
    followStates.back = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = true end
    disableCollision(char)
    PState.conns.follow_back = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.back or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            root.CFrame = tr.CFrame * CFrame.new(0, 0, 2)
            if hum then hum.Sit = true end
        end)
    end)
end

-- 动画跟随
local function startAutoFollow(target)
    followStates.auto = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    disableCollision(char)
    PState.conns.follow_auto = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.auto or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            root.CFrame = tr.CFrame * CFrame.new(0, 0, -3)
        end)
    end)
end

-- 口交
local function startSuckFollow(target)
    followStates.suck = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    disableCollision(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = true end
    PState.conns.follow_suck = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.suck or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            root.CFrame = tr.CFrame * CFrame.new(0, -1, 1)
            if hum then hum.Sit = true end
        end)
    end)
end

-- 被超
local function startSusFollow(target)
    followStates.sus = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    disableCollision(char)
    PState.conns.follow_sus = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.sus or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            root.CFrame = tr.CFrame * CFrame.new(0, 0, -1)
        end)
    end)
end

-- 超别人
local function startModernFollow(target)
    followStates.modern = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    disableCollision(char)
    PState.conns.follow_modern = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.modern or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            root.CFrame = tr.CFrame * CFrame.new(0, 0, 1)
        end)
    end)
end

-- 给别人口
local function startEnhancedSuck(target)
    followStates.enhanced = true
    local char = getLocalChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    disableCollision(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = true end
    PState.conns.follow_enhanced = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not followStates.enhanced or not char.Parent then return end
            if not target.Character then stopAllFollows() return end
            local tr = target.Character:FindFirstChild("HumanoidRootPart")
            if not tr then return end
            root.CFrame = tr.CFrame * CFrame.new(0, -1, -0.5)
            if hum then hum.Sit = true end
        end)
    end)
end

local followToggles = {
    { id = "P_Orbit", text = "旋转环绕", fn = startOrbit },
    { id = "P_Mirror", text = "镜像", fn = startMirror },
    { id = "P_Float", text = "漂浮", fn = startFloat },
    { id = "P_Shadow", text = "影子", fn = startShadow },
    { id = "P_AntiFollow", text = "反向跟随", fn = startAntiFollow },
    { id = "P_Spin", text = "旋转", fn = startSpin },
    { id = "P_Shake", text = "抖动", fn = startShake },
    { id = "P_FaceStand", text = "站头后", fn = startFaceStand },
    { id = "P_BackSit", text = "坐前面", fn = startBackSit },
    { id = "P_AutoFollow", text = "动画跟随", fn = startAutoFollow },
    { id = "P_Suck", text = "口交", fn = startSuckFollow },
    { id = "P_Sus", text = "被超", fn = startSusFollow },
    { id = "P_Modern", text = "超别人", fn = startModernFollow },
    { id = "P_Enhanced", text = "给别人口", fn = startEnhancedSuck },
}

for _, ft in ipairs(followToggles) do
    FollowBox:AddToggle(ft.id, { Text = ft.text, Default = false }):OnChanged(function(v)
        if v then
            stopAllFollows()
            if not PState.selectedPlayer then pNotify("提示", "请先选择玩家") return end
            local target = getTargetPlayer(PState.selectedPlayer)
            if target then
                ft.fn(target)
                pNotify("跟随", "已开启: " .. ft.text)
            end
        else
            stopAllFollows()
            pNotify("停止", "已停止所有跟随")
        end
    end)
end

FollowBox:AddButton("停止所有跟随", function()
    stopAllFollows()
    pNotify("停止", "已停止所有恶搞跟随")
end)
end -- 玩家标签页 do...end
-- ============================================================
-- Tab: 高级 (Advanced)  —— 适配 Obsidian UI 库
-- 依赖: 外部已创建 Window 对象
-- ============================================================
do
local Tabs_Advanced = Window:AddTab("高级", "shield")

-- ---------- 服务与公共引用 ----------
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
local NightVisionBox = Tabs_Advanced:AddLeftGroupbox("夜视功能")

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
    Tooltip = "开启时持续保持明亮光照，关闭恢复原值"
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

NightVisionBox:AddLabel("说明: 开启后用RunService持续锁定光照参数")


-- ============================================================
-- 2. 踏空行走
-- ============================================================
local WalkAirBox = Tabs_Advanced:AddLeftGroupbox("踏空行走")

WalkAirBox:AddButton("加载Float脚本", function()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/.../Float.lua"))()
    end)
    if ok then
        Notify("踏空行走", "Float脚本已加载", 3)
    else
        Notify("踏空行走", "加载失败: " .. tostring(err), 4)
    end
end)

local walkAirEnabled  = false
local walkAirPlatform = nil
local walkAirConn     = nil

WalkAirBox:AddToggle("WalkAirToggle", {
    Text    = "踏空平台(自带)",
    Default = false,
    Tooltip = "开启时在脚下持续生成透明Anchored平台，关闭时删除"
}):OnChanged(function(v)
    walkAirEnabled = v
    if v then
        if walkAirConn then walkAirConn:Disconnect() end
        walkAirConn = RunService.Heartbeat:Connect(function()
            if not walkAirEnabled then return end
            local _, root = getCharacterRoot()
            if not root then return end
            if walkAirPlatform and walkAirPlatform.Parent then
                walkAirPlatform.CFrame = CFrame.new(root.Position.X, root.Position.Y - 3.2, root.Position.Z)
            else
                local part = Instance.new("Part")
                part.Name         = "WalkAirPlatform"
                part.Size         = Vector3.new(10, 1, 10)
                part.Anchored     = true
                part.CanCollide   = true
                part.Transparency = 1
                part.Material     = Enum.Material.Neon
                part.Color       = Color3.fromRGB(255, 255, 255)
                part.Parent       = workspace
                walkAirPlatform   = part
            end
        end)
        Notify("踏空行走", "踏空平台已开启", 3)
    else
        if walkAirConn then
            walkAirConn:Disconnect()
            walkAirConn = nil
        end
        if walkAirPlatform then
            walkAirPlatform:Destroy()
            walkAirPlatform = nil
        end
        Notify("踏空行走", "踏空平台已关闭", 3)
    end
end)

WalkAirBox:AddLabel("说明: 开启后脚下会出现透明可踩平台")


-- ============================================================
-- 3. 防虚空
-- ============================================================
local AntiVoidBox = Tabs_Advanced:AddLeftGroupbox("防虚空")

local antiVoidEnabled  = false
local antiVoidPlatform = nil
local antiVoidConn     = nil

AntiVoidBox:AddToggle("AntiVoidToggle", {
    Text    = "防虚空掉落",
    Default = false,
    Tooltip = "角色Y轴低于-1时在下方生成50x2x50平台接住"
}):OnChanged(function(v)
    antiVoidEnabled = v
    if v then
        if antiVoidConn then antiVoidConn:Disconnect() end
        antiVoidConn = RunService.Heartbeat:Connect(function()
            if not antiVoidEnabled then return end
            local _, root = getCharacterRoot()
            if not root then return end
            if root.Position.Y < -1 then
                if not (antiVoidPlatform and antiVoidPlatform.Parent) then
                    local part = Instance.new("Part")
                    part.Name         = "AntiVoidPlatform"
                    part.Size         = Vector3.new(50, 2, 50)
                    part.Anchored     = true
                    part.CanCollide   = true
                    part.Transparency = 1
                    part.Material     = Enum.Material.Neon
                    part.Color       = Color3.fromRGB(255, 255, 255)
                    part.Parent       = workspace
                    antiVoidPlatform  = part
                end
                antiVoidPlatform.CFrame = CFrame.new(root.Position.X, root.Position.Y - 5, root.Position.Z)
            else
                if antiVoidPlatform then
                    antiVoidPlatform:Destroy()
                    antiVoidPlatform = nil
                end
            end
        end)
        Notify("防虚空", "防虚空已开启", 3)
    else
        if antiVoidConn then
            antiVoidConn:Disconnect()
            antiVoidConn = nil
        end
        if antiVoidPlatform then
            antiVoidPlatform:Destroy()
            antiVoidPlatform = nil
        end
        Notify("防虚空", "防虚空已关闭", 3)
    end
end)

AntiVoidBox:AddLabel("说明: Y轴低于-1时自动生成50x2x50平台")


-- ============================================================
-- 4. 防卡顿优化
-- ============================================================
local OptimizeBox = Tabs_Advanced:AddLeftGroupbox("防卡顿优化")

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
    Tooltip = "关闭阴影/后处理/粒子，降低模拟半径"
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

OptimizeBox:AddLabel("说明: 关闭全局阴影/Bloom/ColorCorrection/粒子")


-- ############################################################
--  右侧分组
-- ############################################################

-- ============================================================
-- 5. 隐身功能
-- ============================================================
local InvisBox = Tabs_Advanced:AddRightGroupbox("隐身功能")

InvisBox:AddButton("隐身方案一", function()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://pastebin.com/raw/AbCxYz12"))()
    end)
    if ok then
        Notify("隐身", "隐身方案一已加载", 3)
    else
        Notify("隐身", "加载失败: " .. tostring(err), 4)
    end
end)

InvisBox:AddButton("隐身方案二", function()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://pastebin.com/raw/AbCxYz12"))()
    end)
    if ok then
        Notify("隐身", "隐身方案二已加载", 3)
    else
        Notify("隐身", "加载失败: " .. tostring(err), 4)
    end
end)

InvisBox:AddLabel("说明: 两种隐身方案，按需加载")


-- ============================================================
-- 6. 反挂机 (独立实现)
-- ============================================================
local AntiAfkBox = Tabs_Advanced:AddRightGroupbox("反挂机")

local antiAfkEnabled = false
local antiAfkConn    = nil

AntiAfkBox:AddToggle("AntiAfkToggle", {
    Text    = "反挂机",
    Default = false,
    Tooltip = "监听Idled事件并模拟按键，防止被判定挂机"
}):OnChanged(function(v)
    antiAfkEnabled = v
    if v then
        if antiAfkConn then antiAfkConn:Disconnect() end
        antiAfkConn = LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            Notify("反挂机", "检测到挂机，已模拟操作", 2)
        end)
        Notify("反挂机", "反挂机已开启", 3)
    else
        if antiAfkConn then
            antiAfkConn:Disconnect()
            antiAfkConn = nil
        end
        Notify("反挂机", "反挂机已关闭", 3)
    end
end)

AntiAfkBox:AddLabel("说明: 独立实现，通过VirtualUser模拟操作")


-- ============================================================
-- 7. 防踢功能
-- ============================================================
local AntiKickBox = Tabs_Advanced:AddRightGroupbox("防踢功能")

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

AntiKickBox:AddLabel("说明: hookmetamethod + hookfunction 双重拦截")


-- ============================================================
-- 8. 绕过反作弊
-- ============================================================
local BypassBox = Tabs_Advanced:AddRightGroupbox("绕过功能")

BypassBox:AddButton("绕过反作弊(Adonis)", function()
    local ok, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/.../adoniscries.lua"))()
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

BypassBox:AddLabel("说明: 清理移动检测函数 + WalkSpeed保护")
end -- 高级标签页 do...end
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
local AnimationDropdown
local selectedCoord = ""
local selectedAnimPack = ""

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
-- 4. 动画包
-- ============================================================
-- 动画包数据：每个包含 idle(2个) walk run jump climb fall
local AnimationPacks = {
	["吸血鬼"] = {
		idle = {10852992727, 10852993334},
		walk = {10852995455},
		run = {10852996012},
		jump = {10852989555},
		climb = {10852990123},
		fall = {10852990890},
	},
	["英雄"] = {
		idle = {8409679938, 8409680042},
		walk = {8409678118},
		run = {8409677138},
		jump = {8409680678},
		climb = {8409681438},
		fall = {8409682158},
	},
	["经典僵尸"] = {
		idle = {507766666, 507766951},
		walk = {507777826},
		run = {507767714},
		jump = {507765000},
		climb = {507770343},
		fall = {507767968},
	},
	["法师"] = {
		idle = {10220623841, 10220624011},
		walk = {10220620801},
		run = {10220621501},
		jump = {10220624541},
		climb = {10220625291},
		fall = {10220626061},
	},
	["幽灵"] = {
		idle = {9102066436, 9102066512},
		walk = {9102064242},
		run = {9102063518},
		jump = {9102067232},
		climb = {9102068002},
		fall = {9102068768},
	},
	["长者"] = {
		idle = {31154759, 31154765},
		walk = {31154716},
		run = {31154731},
		jump = {31154739},
		climb = {31154748},
		fall = {31154754},
	},
	["悬浮"] = {
		idle = {8922380208, 8922380312},
		walk = {8922380508},
		run = {8922380612},
		jump = {8922380820},
		climb = {8922380920},
		fall = {8922381020},
	},
	["宇航员"] = {
		idle = {8921204144, 8921204234},
		walk = {8921201402},
		run = {8921199464},
		jump = {8921205942},
		climb = {8921207471},
		fall = {8921208973},
	},
	["忍者"] = {
		idle = {656030078, 656030124},
		walk = {656029944},
		run = {656029918},
		jump = {656030014},
		climb = {656030052},
		fall = {656030066},
	},
	["狼人"] = {
		idle = {10815833120, 10815833420},
		walk = {10815830235},
		run = {10815831310},
		jump = {10815834254},
		climb = {10815835274},
		fall = {10815835938},
	},
	["卡通"] = {
		idle = {298860834, 298860872},
		walk = {298860822},
		run = {298860788},
		jump = {298860846},
		climb = {298860892},
		fall = {298860904},
	},
	["海盗"] = {
		idle = {7501779588, 7501779650},
		walk = {7501778322},
		run = {7501777758},
		jump = {7501780100},
		climb = {7501780670},
		fall = {7501781140},
	},
	["潜行"] = {
		idle = {10828853653, 10828853821},
		walk = {10828850953},
		run = {10828851753},
		jump = {10828854573},
		climb = {10828855573},
		fall = {10828856453},
	},
	["玩具"] = {
		idle = {782830788, 782830812},
		walk = {782830698},
		run = {782830646},
		jump = {782830820},
		climb = {782830892},
		fall = {782830912},
	},
	["骑士"] = {
		idle = {6570335262, 6570335382},
		walk = {6570328971},
		run = {6570330771},
		jump = {6570336044},
		climb = {6570336752},
		fall = {6570337395},
	},
	["自信"] = {
		idle = {8869686280, 8869686350},
		walk = {8869684700},
		run = {8869683546},
		jump = {8869687476},
		climb = {8869688474},
		fall = {8869689270},
	},
	["流行明星"] = {
		idle = {337960636, 337960672},
		walk = {337960244},
		run = {337960326},
		jump = {337960402},
		climb = {337960498},
		fall = {337960578},
	},
	["公主"] = {
		idle = {8409209258, 8409209330},
		walk = {8409207526},
		run = {8409206730},
		jump = {8409209980},
		climb = {8409210690},
		fall = {8409211370},
	},
	["牛仔"] = {
		idle = {1015788775, 1015788812},
		walk = {1015788649},
		run = {1015788525},
		jump = {1015788909},
		climb = {1015789005},
		fall = {1015789091},
	},
	["巡逻"] = {
		idle = {10276609148, 10276609321},
		walk = {10276589092},
		run = {10276589812},
		jump = {10276594412},
		climb = {10276600084},
		fall = {10276601524},
	},
}

-- SetAnimations：替换角色 Animate 对象中的动画ID
local function SetAnimations(pack)
	local char = getCharacter()
	if not char then
		notify("动画", "未找到角色", 3)
		return
	end
	local animate = char:FindFirstChild("Animate")
	if not animate then
		notify("动画", "未找到 Animate 对象", 3)
		return
	end

	-- 通用设置：遍历文件夹内所有 Animation 对象，按顺序替换ID
	local function setAnimId(folderName, ids)
		pcall(function()
			local folder = animate:FindFirstChild(folderName)
			if not folder then return end
			local count = 0
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("Animation") then
					count = count + 1
					local id = ids[count] or ids[1]
					if id then
						child.AnimationId = "rbxassetid://" .. tostring(id)
					end
				end
			end
		end)
	end

	setAnimId("idle", pack.idle)
	setAnimId("walk", pack.walk)
	setAnimId("run", pack.run)
	setAnimId("jump", pack.jump)
	setAnimId("climb", pack.climb)
	setAnimId("fall", pack.fall)

	-- 重置动画状态以应用更改
	pcall(function()
		local humanoid = getHumanoid()
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			task.wait(0.1)
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)

	notify("动画包", "已应用 [" .. selectedAnimPack .. "] 动画包", 3)
end

-- 动画包 UI
local AnimGroup = Tabs_Tools:AddRightGroupbox("动画包")

AnimGroup:AddLabel("选择动画包后点击应用")

local packNames = {}
for name in pairs(AnimationPacks) do
	table.insert(packNames, name)
end
table.sort(packNames)

AnimationDropdown = AnimGroup:AddDropdown("AnimPackSelect", {
	Text = "动画包",
	Values = packNames,
	Default = "",
	Multi = false
})

AnimationDropdown:OnChanged(function(v)
	selectedAnimPack = v
end)

AnimGroup:AddButton("应用动画包", function()
	if selectedAnimPack == "" or not AnimationPacks[selectedAnimPack] then
		notify("动画", "请选择动画包", 3)
		return
	end
	SetAnimations(AnimationPacks[selectedAnimPack])
end)

-- ============================================================
-- 5. 美化包
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
		loadstring(game:HttpGet("https://raw.githubusercontent.com/GreenNumber42/Roblox-Scripts/main/R6Animations.lua"))()
	end)
	notify("动作", "正在加载R6动作包", 3)
end)

ActionGroup:AddButton("动作V2", function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/GreenNumber42/Roblox-Scripts/main/EmotesV2.lua"))()
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
-- UI设置
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("UniversalSilentAim/Configs")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()
