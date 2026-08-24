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

-- UI设置
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("UniversalSilentAim/Configs")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()
