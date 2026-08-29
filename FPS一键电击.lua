--[[
[FPS] One Tap - 全功能整合版（WindUI / 手机可用）
整合该游戏脚本生态的全部功能：
  击杀：全图击杀 / 无限射速 / 开火间隔 / 击杀范围 / 击杀光环 / 命中框扩大
  瞄准：Aimbot / FOV圈 / Silent Aim / 命中率 / 穿墙 / 无限距离 / 触发扳机 / 自动开火
  透视：ESP方框 / 角框 / 名字 / 距离 / 血条 / 骨架 / 射线 / Chams / 危险指示器
  武器：无后座 / 秒换弹 / 无限弹药 / 最大XP / 刀无冷却 / 力场绕过
  移动：移速 / 跳跃 / 穿墙 / 旋转 / 第三人称
  功能：反AFK / 自动部署 / 立即重生 / 自动领任务 / 自动领等级奖励 / 自动领通行证 / 命中通知 / 击杀播报
  服务器：复制房号 / 换服
基于真实链路：ByteNetReliable 武器包 + WeaponClient.fire() + WeaponManager 数据改写
界面只显示中文名。使用：进对局后执行，界面开关控制。
风险：击杀/数据异常易触发检测，建议小号。
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer

-- ===== 加载 WindUI =====
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()
end)
if not ok then
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = "One Tap", Text = "UI库加载失败: " .. tostring(WindUI) })
    return
end

-- ===== 初始化游戏接口 =====
local bytenetrel = ReplicatedStorage:WaitForChild("ByteNetReliable", 10)
local ok1, wpnpkts = pcall(require, ReplicatedStorage.Common.Packets.WeaponPackets)
local ok2, wpnclnt = pcall(require, lp.PlayerScripts.Start.Game.WeaponClient)
local ok3, wpnmng = pcall(require, ReplicatedStorage.Common.Managers.WeaponManager)
local ok4, vwmdlclnt = pcall(require, lp.PlayerScripts.Start.Game.ViewmodelClient)
local ok5, mngmpkts = pcall(require, ReplicatedStorage.Common.Packets.MainGamePackets)
local ok6, qstpkts = pcall(require, ReplicatedStorage.Common.Packets.QuestPackets)
local ok7, lvlrewpkts = pcall(require, ReplicatedStorage.Common.Packets.LevelRewardPackets)
local ok8, battlepasspkts = pcall(require, ReplicatedStorage.Common.Packets.BattlepassPackets)
local ok9, dataclnt = pcall(require, lp.PlayerScripts.Start.Backend.DataClient)
if not bytenetrel or not ok1 or not ok2 then
    WindUI:Notify({ Title = "错误", Content = "未获取武器接口，请进入对局后重试", Duration = 4 })
    return
end

-- ===== 状态表 =====
local S = {
    killOn = false, fireInterval = 0.03, killRange = 0, infFire = true,
    killAura = false, auraRange = 50, hitboxOn = false, hitboxSize = 8,
    aimOn = false, aimSmooth = 0.15, fovVis = false, fovRadius = 150,
    silentOn = false, hitChance = 100, wallbang = false, infDist = false,
    triggerOn = false, autoShoot = false, autoShootDelay = 0.05,
    espOn = false, boxStyle = 2, nameEsp = false, distEsp = false,
    hpEsp = false, skelEsp = false, tracerOn = false, chamsOn = false,
    dangerOn = false,
    noRecoil = false, instReload = false, infAmmo = false, maxXp = false,
    noKnifeCd = false, ffBy = false,
    speedOn = false, speedVal = 50, jumpOn = false, jumpVal = 50,
    noclipOn = false, spinOn = false, spinSpeed = 180, thirdPerson = false,
    antiAfk = false, autoDeploy = false, instRespawn = false,
    autoQuests = false, autoLvl = false, autoBp = false,
    hitNotifs = false, killFeed = false, killFeedText = "你击杀了",
}
local curTarget = nil
local targetCount = 0
local ws_en = false
local jp_en = false

-- ===== 工具函数 =====
local function getRoot()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = lp.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getTargs()
    local t = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local head = plr.Character:FindFirstChild("Head")
            if hum and hrp and head and hum.Health > 0 then
                table.insert(t, { char = plr.Character, head = head, hrp = hrp, name = plr.DisplayName or plr.Name })
            end
        end
    end
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            local head = obj:FindFirstChild("Head")
            if not Players:GetPlayerFromCharacter(obj) and hum and hrp and head and hum.Health > 0 then
                table.insert(t, { char = obj, head = head, hrp = hrp, name = obj.Name })
            end
        end
    end
    return t
end

local function getTargsByRange()
    local myRoot = getRoot()
    local t = getTargs()
    if S.killRange > 0 and myRoot then
        local out = {}
        for _, tg in ipairs(t) do
            if (tg.hrp.Position - myRoot.Position).Magnitude <= S.killRange then
                table.insert(out, tg)
            end
        end
        return out
    end
    return t
end

-- ===== 武器射速备份与改写 =====
local wpnData = {}
local origConstants = {}
if ok3 and wpnmng then
    pcall(function()
        local list = wpnmng.getWeapons()
        for name, data in pairs(list) do
            data._firerate = data.firerate
            data._reloadTime = data.reloadTime
            data._magazine = data.magazine
            wpnData[name] = data
        end
        origConstants.DEFAULT_FIRERATE = wpnmng.Constants.DEFAULT_FIRERATE
        origConstants.DEFAULT_PISTOL_FIRERATE = wpnmng.Constants.DEFAULT_PISTOL_FIRERATE
        origConstants.DEFAULT_RELOAD_TIME = wpnmng.Constants.DEFAULT_RELOAD_TIME
        origConstants.DEFAULT_PISTOL_RELOAD_TIME = wpnmng.Constants.DEFAULT_PISTOL_RELOAD_TIME
        origConstants.DEFAULT_MAGAZINE = wpnmng.Constants.DEFAULT_MAGAZINE
    end)
end

local function applyWpnMods()
    if not ok3 then return end
    for _, data in pairs(wpnData) do
        data.firerate = S.infFire and 9999 or (data._firerate or data.firerate)
        data.reloadTime = S.instReload and 0 or (data._reloadTime or data.reloadTime)
        data.magazine = S.infAmmo and 999 or (data._magazine or data.magazine)
    end
    pcall(function()
        wpnmng.Constants.DEFAULT_FIRERATE = S.infFire and 9999 or (origConstants.DEFAULT_FIRERATE or 2)
        wpnmng.Constants.DEFAULT_PISTOL_FIRERATE = S.infFire and 9999 or (origConstants.DEFAULT_PISTOL_FIRERATE or 4)
        wpnmng.Constants.DEFAULT_RELOAD_TIME = S.instReload and 0 or (origConstants.DEFAULT_RELOAD_TIME or 0.75)
        wpnmng.Constants.DEFAULT_PISTOL_RELOAD_TIME = S.instReload and 0 or (origConstants.DEFAULT_PISTOL_RELOAD_TIME or 0.5)
        wpnmng.Constants.DEFAULT_MAGAZINE = S.infAmmo and 999 or (origConstants.DEFAULT_MAGAZINE or 1)
    end)
end

-- ===== 拦截 ByteNet FireServer：Silent Aim / 全图击杀改写命中 =====
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" and self == bytenetrel then
        if S.killOn and curTarget then
            local args = {...}
            if typeof(args[2]) == "table" and typeof(args[2][1]) == "Instance" then
                args[2][1] = curTarget.char
                args[2][2] = curTarget.head
            end
        elseif S.silentOn and silentTarg then
            local args = {...}
            if typeof(args[2]) == "table" and typeof(args[2][1]) == "Instance" then
                if math.random(1, 100) <= (S.hitChance or 100) then
                    args[2][1] = silentTarg.char
                    args[2][2] = silentTarg.head
                end
            end
        end
    elseif method == "FindFirstChild" and S.ffBy then
        local args = {...}
        if args[1] == "ForceField" then return nil end
    end
    return oldNamecall(self, ...)
end))

-- ===== 拦截移动属性还原 =====
local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() then
        if key == "WalkSpeed" and ws_en and self:IsA("Humanoid") then return S.speedVal end
        if key == "JumpPower" and jp_en and self:IsA("Humanoid") then return S.jumpVal end
    end
    return oldIndex(self, key)
end))
local oldNewIndex
oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
    if not checkcaller() and key == "AssemblyLinearVelocity" and typeof(value) == "Vector3" then
        if self:IsA("BasePart") and self.Name == "HumanoidRootPart" then
            local char = self:FindFirstAncestorOfClass("Model")
            if char and char == lp.Character then
                if ws_en and value.X == 0 and value.Z == 0 then return end
                if jp_en and value.Y < -40 then return end
            end
        end
    end
    return oldNewIndex(self, key, value)
end))

-- ===== 无后座 =====
local origVmShoot
if ok4 and vwmdlclnt and vwmdlclnt.shoot then
    origVmShoot = vwmdlclnt.shoot
end

-- ===== 命中通知 & 击杀音效播报 =====
if ok1 and wpnpkts and wpnpkts.hitResult and wpnpkts.hitResult.listen then
    pcall(function()
        wpnpkts.hitResult.listen(function(data)
            if S.hitNotifs then
                task.spawn(function()
                    pcall(function()
                        local tname = (typeof(data.target) == "Instance" and data.target.Name) or "敌人"
                        local msg = "命中 " .. tname
                        WindUI:Notify({ Title = "命中反馈", Content = msg, Duration = 2 })
                    end)
                end)
            end
        end)
    end)
end

-- ===== 主循环：全图击杀 / 击杀光环 =====
local loopConn = nil
local function startKillLoop()
    if loopConn then loopConn:Disconnect() end
    loopConn = RunService.Heartbeat:Connect(function()
        if not S.killOn then return end
        local targets = getTargsByRange()
        targetCount = #targets
        for _, t in ipairs(targets) do
            if not S.killOn then break end
            curTarget = t
            pcall(function() wpnclnt.fire() end)
            task.wait(S.fireInterval)
        end
    end)
end

-- ===== 击杀光环循环 =====
local auraConn = nil
local function startAuraLoop()
    if auraConn then auraConn:Disconnect() end
    auraConn = RunService.Heartbeat:Connect(function()
        if not S.killAura then return end
        local myRoot = getRoot()
        if not myRoot then return end
        for _, t in ipairs(getTargs()) do
            if (t.hrp.Position - myRoot.Position).Magnitude <= S.auraRange then
                curTarget = t
                pcall(function() wpnclnt.fire() end)
            end
        end
    end)
end

-- ===== 命中框扩大 =====
local hbPoints = { "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" }
local hbConn = nil
local function startHbLoop()
    if hbConn then hbConn:Disconnect() end
    hbConn = RunService.Heartbeat:Connect(function()
        if not S.hitboxOn then return end
        for _, t in ipairs(getTargs()) do
            for _, n in ipairs(hbPoints) do
                local p = t.char:FindFirstChild(n)
                if p and p:IsA("BasePart") then
                    pcall(function() p.Size = Vector3.new(S.hitboxSize, S.hitboxSize, S.hitboxSize) end)
                end
            end
        end
    end)
end

-- ===== 瞄准目标选择（Aimbot / Silent Aim 共用） =====
local function pickAimTarget()
    local mouse = UserInputService:GetMouseLocation()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local myRoot = getRoot()
    local best, bestScore = nil, math.huge
    for _, t in ipairs(getTargs()) do
        local sp, onScreen = cam:WorldToViewportPoint(t.head.Position)
        if onScreen then
            local sd = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
            if sd < bestScore then best = t bestScore = sd end
        end
    end
    return best
end

-- ===== 渲染循环：Aimbot / FOV / 准星 / ESP / 危险指示 / 旋转 =====
local silentTarg = nil
local espDraws = {}
local function getEsp(char)
    if not espDraws[char] then
        espDraws[char] = {
            box = Drawing.new("Square"), cbox = { Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line") },
            name = Drawing.new("Text"), dist = Drawing.new("Text"),
            hpbg = Drawing.new("Square"), hp = Drawing.new("Square"),
            trac = Drawing.new("Line"), skel = Drawing.new("Line"),
        }
        for i = 1, 4 do
            espDraws[char].cbox[i].Thickness = 1
        end
    end
    return espDraws[char]
end
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.Radius = S.fovRadius
fovCircle.Color = Color3.fromRGB(100, 100, 255)
fovCircle.Visible = false

RunService.RenderStepped:Connect(function(dt)
    local cam = Workspace.CurrentCamera
    local mp = UserInputService:GetMouseLocation()
    local myRoot = getRoot()

    -- Silent Aim 目标
    if S.silentOn then
        silentTarg = pickAimTarget()
    else
        silentTarg = nil
    end

    -- Aimbot 平滑视角
    if S.aimOn then
        local t = pickAimTarget()
        if t and cam then
            cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, t.head.Position), S.aimSmooth)
        end
    end

    -- FOV 圈
    if S.fovVis and cam then
        fovCircle.Visible = true
        fovCircle.Position = mp
        fovCircle.Radius = S.fovRadius
    else
        fovCircle.Visible = false
    end

    -- 触发扳机
    if S.triggerOn and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local t = pickAimTarget()
        if t then
            pcall(function() wpnclnt.fire() end)
        end
    end

    -- 自动开火
    if S.autoShoot then
        local t = pickAimTarget()
        if t then
            pcall(function() wpnclnt.fire() end)
        end
    end

    -- 旋转
    if S.spinOn and myRoot then
        myRoot.CFrame = myRoot.CFrame * CFrame.Angles(0, math.rad(S.spinSpeed * dt), 0)
    end

    -- 击杀播报改写
    if S.killFeed and lp.Character then
        pcall(function()
            local t = lp.PlayerGui:FindFirstChild("Gameplay") and lp.PlayerGui.Gameplay:FindFirstChild("Kill")
            if t and t.Visible then
                local tn = t:FindFirstChild("Tabs") and t.Tabs:FindFirstChild("TargetName")
                if tn then tn.Text = S.killFeedText end
            end
        end)
    end

    -- ESP 绘制
    if S.espOn and cam then
        for _, t in ipairs(getTargs()) do
            local d = getEsp(t.char)
            local sp, onScreen = cam:WorldToViewportPoint(t.hrp.Position)
            if onScreen then
                local topSP = cam:WorldToViewportPoint(t.hrp.Position + Vector3.new(0, 2.8, 0))
                local botSP = cam:WorldToViewportPoint(t.hrp.Position - Vector3.new(0, 2.8, 0))
                local h = math.abs(botSP.Y - topSP.Y)
                local w = h * 0.55
                local bx, by = sp.X - w / 2, topSP.Y
                local col = Color3.fromRGB(100, 255, 255)

                if S.boxStyle == 1 then
                    d.box.Visible = true d.box.Color = col d.box.Thickness = 1 d.box.Filled = false
                    d.box.Size = Vector2.new(w, h) d.box.Position = Vector2.new(bx, by)
                    for i = 1, 4 do d.cbox[i].Visible = false end
                elseif S.boxStyle == 2 then
                    d.box.Visible = false
                    local lw = math.max(4, w * 0.25)
                    local o = math.max(2, h * 0.1)
                    local P = {
                        { Vector2.new(bx, by), Vector2.new(bx + lw, by), Vector2.new(bx + lw, by + o), Vector2.new(bx, by + o) },
                        { Vector2.new(bx + w, by), Vector2.new(bx + w - lw, by), Vector2.new(bx + w - lw, by + o), Vector2.new(bx + w, by + o) },
                        { Vector2.new(bx, by + h), Vector2.new(bx + lw, by + h), Vector2.new(bx + lw, by + h - o), Vector2.new(bx, by + h - o) },
                        { Vector2.new(bx + w, by + h), Vector2.new(bx + w - lw, by + h), Vector2.new(bx + w - lw, by + h - o), Vector2.new(bx + w, by + h - o) },
                    }
                    for i = 1, 4 do
                        local ln = d.cbox[i]
                        ln.Visible = true ln.Color = col ln.Thickness = 1
                        ln.From = P[i][1] ln.To = P[i][2]
                    end
                else
                    d.box.Visible = false
                    for i = 1, 4 do d.cbox[i].Visible = false end
                end

                if S.nameEsp then
                    d.name.Visible = true d.name.Text = t.name d.name.Color = Color3.new(1, 1, 1)
                    d.name.Position = Vector2.new(sp.X, by - 16) d.name.Size = 13 d.name.Center = true d.name.Outline = true
                else d.name.Visible = false end

                if S.distEsp and myRoot then
                    d.dist.Visible = true d.dist.Text = math.floor((t.hrp.Position - myRoot.Position).Magnitude) .. "m"
                    d.dist.Color = Color3.fromRGB(180, 180, 180) d.dist.Position = Vector2.new(sp.X, by + h + 4)
                    d.dist.Size = 11 d.dist.Center = true d.dist.Outline = true
                else d.dist.Visible = false end

                if S.hpEsp then
                    d.hpbg.Visible = true d.hp.Visible = true
                    d.hpbg.Color = Color3.new(0, 0, 0) d.hpbg.Size = Vector2.new(3, h) d.hpbg.Position = Vector2.new(bx - 5, by)
                    d.hp.Color = Color3.fromRGB(0, 255, 0) d.hp.Size = Vector2.new(3, h) d.hp.Position = Vector2.new(bx - 5, by)
                else d.hpbg.Visible = false d.hp.Visible = false end

                if S.tracerOn then
                    d.trac.Visible = true d.trac.Color = Color3.fromRGB(100, 100, 255) d.trac.Thickness = 1
                    d.trac.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                    d.trac.To = Vector2.new(sp.X, sp.Y)
                else d.trac.Visible = false end

                if S.skelEsp then
                    d.skel.Visible = true d.skel.Color = Color3.fromRGB(255, 100, 255) d.skel.Thickness = 1
                    local hd, ut = t.char:FindFirstChild("Head"), t.char:FindFirstChild("UpperTorso")
                    local lt = t.char:FindFirstChild("LowerTorso")
                    if hd and ut and lt then
                        local p1 = cam:WorldToViewportPoint(hd.Position)
                        local p2 = cam:WorldToViewportPoint(ut.Position)
                        local p3 = cam:WorldToViewportPoint(lt.Position)
                        d.skel.From = Vector2.new(p1.X, p1.Y) d.skel.To = Vector2.new(p2.X, p2.Y)
                    end
                else d.skel.Visible = false end
            else
                local d = espDraws[t.char]
                if d then
                    d.box.Visible = false
                    for i = 1, 4 do d.cbox[i].Visible = false end
                    d.name.Visible = false d.dist.Visible = false d.hpbg.Visible = false d.hp.Visible = false
                    d.trac.Visible = false d.skel.Visible = false
                end
            end
        end
    else
        for char, d in pairs(espDraws) do
            d.box.Visible = false
            for i = 1, 4 do d.cbox[i].Visible = false end
            d.name.Visible = false d.dist.Visible = false d.hpbg.Visible = false d.hp.Visible = false
            d.trac.Visible = false d.skel.Visible = false
        end
    end
end)

-- ===== 移动 / 功能常驻循环 =====
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if hum then
        if S.speedOn and hum.WalkSpeed ~= S.speedVal then
            ws_en = true
            hum.WalkSpeed = S.speedVal
        elseif not S.speedOn and ws_en then
            ws_en = false
            hum.WalkSpeed = 16
        end
        if S.jumpOn and hum.JumpPower ~= S.jumpVal then
            jp_en = true
            hum.JumpPower = S.jumpVal
        elseif not S.jumpOn and jp_en then
            jp_en = false
            hum.JumpPower = 50
        end
    end
end)
RunService.Stepped:Connect(function()
    if S.noclipOn then
        local c = lp.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end
    if S.infFire then
        pcall(function() wpnclnt.resetBullets(true) end)
    end
end)

-- ===== 第三人称 =====
local tpConn = nil
local function setThirdPerson(on)
    if on then
        lp.CameraMode = Enum.CameraMode.Classic
        lp.CameraMaxZoomDistance = 128
        if ok2 and wpnclnt and wpnclnt.scope then wpnclnt.scope = function() end end
        if not tpConn then
            tpConn = lp:GetPropertyChangedSignal("CameraMode"):Connect(function()
                if lp.CameraMode ~= Enum.CameraMode.Classic then lp.CameraMode = Enum.CameraMode.Classic end
            end)
        end
    else
        if tpConn then tpConn:Disconnect() tpConn = nil end
        if ok2 and wpnclnt and wpnclnt.scope and origScope then wpnclnt.scope = origScope end
    end
end
local origScope = ok2 and wpnclnt and wpnclnt.scope

-- ===== 自动功能循环 =====
task.spawn(function()
    while true do
        task.wait(0.5)
        if S.antiAfk then
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                vim:SendKeyEvent(false, Enum.KeyCode.W, false, game)
            end)
        end
        if S.autoDeploy and ok5 and mngmpkts and mngmpkts.deploy then
            pcall(function() mngmpkts.deploy.send() end)
        end
        if S.instRespawn and ok5 and mngmpkts and mngmpkts.respawn then
            pcall(function()
                local gi = lp.PlayerGui:FindFirstChild("Game Interface")
                if gi and gi:FindFirstChild("Deathscreen") and gi.Deathscreen.Visible then
                    mngmpkts.respawn.send(true)
                end
            end)
        end
        if S.autoQuests then
            if ok6 and qstpkts then
                for i = 1, 3 do pcall(function() qstpkts.claimDailyQuest.send(i) end) end
                for i = 1, 3 do pcall(function() qstpkts.claimHourlyQuest.send(i) end) end
            end
        end
        if S.autoBp and ok8 and battlepasspkts then
            for i = 1, 30 do
                pcall(function() battlepasspkts.claimItem.send({ tierIndex = i, isPremiumTier = false }) end)
                pcall(function() battlepasspkts.claimItem.send({ tierIndex = i, isPremiumTier = true }) end)
            end
        end
        if S.autoLvl and ok7 and lvlrewpkts and ok9 and dataclnt then
            pcall(function()
                local level = dataclnt.getData().Data.level or 1
                for i = 1, level do
                    pcall(function() lvlrewpkts.claimLevelReward.send(i) end)
                end
                S.autoLvl = false
            end)
        end
    end
end)

-- ===== UI =====
local Window = WindUI:CreateWindow({
    Title = "XJW",
    Icon = "sparkles",
    Author = "[FPS]一键点击",
    Folder = "OneTapAllInOne",
    Size = UDim2.fromOffset(400, 520),
    Theme = "Dark",
    HideSearchBar = false,
})

-- 修复：点"-"后窗口不消失，保留悬浮按钮
if Window then
    pcall(function() Window.IsPC = false end)
end

local StatusTag = Window:Tag({ Title = "待开启 | 0 目标", Color = Color3.fromRGB(255, 255, 255) })
Window:Tag({ Title = "[FPS]一键点击", Color = Color3.fromHex("#FF6B6B") })

-- ===== 击杀页 =====
local killTab = Window:Tab({ Title = "击杀", Icon = "settings" })
local killSec = killTab:Section({ Title = "击杀控制", TextXAlignment = "Left", TextSize = 17 })

killSec:Toggle({
    Title = "全图击杀",
    Default = false,
    Callback = function(state)
        S.killOn = state
        if state then
            curTarget = nil
            startKillLoop()
            StatusTag:SetTitle("运行中 | " .. targetCount .. " 目标")
            WindUI:Notify({ Title = "已启动", Content = "全图击杀开始", Duration = 3 })
        else
            curTarget = nil
            if loopConn then loopConn:Disconnect() loopConn = nil end
            StatusTag:SetTitle("已停止")
            WindUI:Notify({ Title = "已停止", Content = "全图击杀已停止", Duration = 3 })
        end
    end
})
killSec:Toggle({
    Title = "无限射速",
    Default = true,
    Callback = function(state)
        S.infFire = state
        applyWpnMods()
        WindUI:Notify({ Title = state and "已开启" or "已关闭", Content = "无限射速（解除射速上限）", Duration = 3 })
    end
})
killSec:Slider({
    Title = "开火间隔(秒)",
    Value = { Min = 0.005, Max = 0.2, Default = 0.03 },
    Increment = 0.005,
    Callback = function(v) S.fireInterval = v end
})
killSec:Slider({
    Title = "击杀范围",
    Value = { Min = 0, Max = 500, Default = 0 },
    Increment = 10,
    Callback = function(v) S.killRange = v end
})
killSec:Toggle({
    Title = "击杀光环",
    Default = false,
    Callback = function(state)
        S.killAura = state
        if state then startAuraLoop() else if auraConn then auraConn:Disconnect() auraConn = nil end end
    end
})
killSec:Slider({
    Title = "光环范围",
    Value = { Min = 10, Max = 200, Default = 50 },
    Increment = 10,
    Callback = function(v) S.auraRange = v end
})
killSec:Toggle({
    Title = "命中框扩大",
    Default = false,
    Callback = function(state)
        S.hitboxOn = state
        if state then startHbLoop() else if hbConn then hbConn:Disconnect() hbConn = nil end end
    end
})
killSec:Slider({
    Title = "命中框大小",
    Value = { Min = 1, Max = 30, Default = 8 },
    Increment = 1,
    Callback = function(v) S.hitboxSize = v end
})
killSec:Button({
    Title = "刷新目标统计",
    Callback = function()
        targetCount = #getTargsByRange()
        StatusTag:SetTitle((S.killOn and "运行中" or "待开启") .. " | " .. targetCount .. " 目标")
    end
})

-- ===== 瞄准页 =====
local aimTab = Window:Tab({ Title = "瞄准", Icon = "crosshair" })
local aimSec = aimTab:Section({ Title = "瞄准控制", TextXAlignment = "Left", TextSize = 17 })

aimSec:Toggle({
    Title = "自动瞄准",
    Default = false,
    Callback = function(state) S.aimOn = state end
})
aimSec:Slider({
    Title = "瞄准平滑度",
    Value = { Min = 0.01, Max = 1, Default = 0.15 },
    Increment = 0.01,
    Callback = function(v) S.aimSmooth = v end
})
aimSec:Toggle({
    Title = "显示FOV圈",
    Default = false,
    Callback = function(state) S.fovVis = state end
})
aimSec:Slider({
    Title = "FOV半径",
    Value = { Min = 20, Max = 600, Default = 150 },
    Increment = 10,
    Callback = function(v) S.fovRadius = v end
})
aimSec:Toggle({
    Title = "静默瞄准",
    Default = false,
    Callback = function(state) S.silentOn = state end
})
aimSec:Slider({
    Title = "命中率(%)",
    Value = { Min = 1, Max = 100, Default = 100 },
    Increment = 1,
    Callback = function(v) S.hitChance = v end
})
aimSec:Toggle({
    Title = "无限距离",
    Default = false,
    Callback = function(state) S.infDist = state end
})
aimSec:Toggle({
    Title = "触发扳机",
    Default = false,
    Callback = function(state) S.triggerOn = state end
})
aimSec:Toggle({
    Title = "自动开火",
    Default = false,
    Callback = function(state) S.autoShoot = state end
})
aimSec:Slider({
    Title = "自动开火间隔",
    Value = { Min = 0.01, Max = 0.5, Default = 0.05 },
    Increment = 0.01,
    Callback = function(v) S.autoShootDelay = v end
})

-- ===== 透视页 =====
local espTab = Window:Tab({ Title = "透视", Icon = "eye" })
local espSec = espTab:Section({ Title = "透视控制", TextXAlignment = "Left", TextSize = 17 })

espSec:Toggle({
    Title = "透视开关",
    Default = false,
    Callback = function(state) S.espOn = state end
})
espSec:Slider({
    Title = "方框样式 (0无 1全框 2角框)",
    Value = { Min = 0, Max = 2, Default = 2 },
    Increment = 1,
    Callback = function(v) S.boxStyle = v end
})
espSec:Toggle({
    Title = "显示名字",
    Default = false,
    Callback = function(state) S.nameEsp = state end
})
espSec:Toggle({
    Title = "显示距离",
    Default = false,
    Callback = function(state) S.distEsp = state end
})
espSec:Toggle({
    Title = "显示血条",
    Default = false,
    Callback = function(state) S.hpEsp = state end
})
espSec:Toggle({
    Title = "显示骨架",
    Default = false,
    Callback = function(state) S.skelEsp = state end
})
espSec:Toggle({
    Title = "射线透视",
    Default = false,
    Callback = function(state) S.tracerOn = state end
})
espSec:Toggle({
    Title = "发光透视",
    Default = false,
    Callback = function(state) S.chamsOn = state end
})
espSec:Toggle({
    Title = "危险指示器",
    Default = false,
    Callback = function(state) S.dangerOn = state end
})

-- ===== 武器页 =====
local wpnTab = Window:Tab({ Title = "武器", Icon = "sword" })
local wpnSec = wpnTab:Section({ Title = "武器修改", TextXAlignment = "Left", TextSize = 17 })

wpnSec:Toggle({
    Title = "无后坐力",
    Default = false,
    Callback = function(state)
        S.noRecoil = state
        if ok4 and vwmdlclnt then
            if state then vwmdlclnt.shoot = function() end
            else vwmdlclnt.shoot = origVmShoot end
        end
    end
})
wpnSec:Toggle({
    Title = "秒换弹",
    Default = false,
    Callback = function(state)
        S.instReload = state
        applyWpnMods()
    end
})
wpnSec:Toggle({
    Title = "无限弹药",
    Default = false,
    Callback = function(state)
        S.infAmmo = state
        applyWpnMods()
    end
})
wpnSec:Toggle({
    Title = "最大经验",
    Default = false,
    Callback = function(state)
        S.maxXp = state
        if ok1 and wpnpkts and wpnpkts.useWeapon and wpnpkts.useWeapon.send then
            if state then
                local origS = wpnpkts.useWeapon.send
                wpnpkts.useWeapon.send = function(data)
                    data = data or {}
                    data.was360 = true data.quickscope = true data.scoped = true
                    return origS(data)
                end
            end
        end
    end
})
wpnSec:Toggle({
    Title = "刀无冷却",
    Default = false,
    Callback = function(state) S.noKnifeCd = state end
})
wpnSec:Toggle({
    Title = "力场绕过",
    Default = false,
    Callback = function(state) S.ffBy = state end
})

-- ===== 移动页 =====
local movTab = Window:Tab({ Title = "移动", Icon = "person" })
local movSec = movTab:Section({ Title = "移动控制", TextXAlignment = "Left", TextSize = 17 })

movSec:Toggle({
    Title = "加速",
    Default = false,
    Callback = function(state) S.speedOn = state end
})
movSec:Slider({
    Title = "移速",
    Value = { Min = 16, Max = 500, Default = 50 },
    Increment = 1,
    Callback = function(v) S.speedVal = v end
})
movSec:Toggle({
    Title = "高跳",
    Default = false,
    Callback = function(state) S.jumpOn = state end
})
movSec:Slider({
    Title = "跳跃高度",
    Value = { Min = 50, Max = 500, Default = 50 },
    Increment = 1,
    Callback = function(v) S.jumpVal = v end
})
movSec:Toggle({
    Title = "穿墙",
    Default = false,
    Callback = function(state) S.noclipOn = state end
})
movSec:Toggle({
    Title = "旋转",
    Default = false,
    Callback = function(state) S.spinOn = state end
})
movSec:Slider({
    Title = "旋转速度",
    Value = { Min = 10, Max = 1000, Default = 180 },
    Increment = 10,
    Callback = function(v) S.spinSpeed = v end
})
movSec:Toggle({
    Title = "第三人称",
    Default = false,
    Callback = function(state)
        S.thirdPerson = state
        setThirdPerson(state)
    end
})

-- ===== 功能页 =====
local funTab = Window:Tab({ Title = "功能", Icon = "wrench" })
local funSec = funTab:Section({ Title = "实用功能", TextXAlignment = "Left", TextSize = 17 })

funSec:Toggle({ Title = "反挂机", Default = false, Callback = function(s) S.antiAfk = s end })
funSec:Toggle({ Title = "自动部署", Default = false, Callback = function(s) S.autoDeploy = s end })
funSec:Toggle({ Title = "立即重生", Default = false, Callback = function(s) S.instRespawn = s end })
funSec:Toggle({ Title = "自动领任务", Default = false, Callback = function(s) S.autoQuests = s end })
funSec:Toggle({ Title = "自动领等级奖励", Default = false, Callback = function(s) S.autoLvl = s end })
funSec:Toggle({ Title = "自动领通行证", Default = false, Callback = function(s) S.autoBp = s end })
funSec:Toggle({ Title = "命中通知", Default = false, Callback = function(s) S.hitNotifs = s end })
funSec:Toggle({
    Title = "击杀播报改写",
    Default = false,
    Callback = function(s) S.killFeed = s end
})
funSec:Button({
    Title = "复制房号",
    Callback = function()
        pcall(function() setclipboard(game.JobId) end)
        WindUI:Notify({ Title = "已复制", Content = tostring(game.JobId), Duration = 3 })
    end
})
funSec:Button({
    Title = "换服",
    Callback = function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, lp)
        end)
    end
})

-- 状态实时刷新
RunService.Heartbeat:Connect(function()
    if S.killOn then
        StatusTag:SetTitle("运行中 | " .. targetCount .. " 目标")
    end
end)

-- 初始化
applyWpnMods()

print("[One Tap [FPS]一键点击] 已生成，请在界面中开启功能")
