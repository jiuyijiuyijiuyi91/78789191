local repo = "https://raw.githubusercontent.com/ATLASTEAM01/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Attack = { damage = 999999, range = 60, speed = 1 }
local AutoAttack = { enabled = false }
local AttackAllMode = { enabled = false }
local AttackOneByOneMode = { enabled = false }
local ESP = { enabled = false }
local AntiCheat = { enabled = false }

local function GetDamageEvent()
    local flow = ReplicatedStorage:FindFirstChild("FlowClient")
    if flow then
        local runner = flow:FindFirstChild("ClientRunner")
        if runner then
            return runner:FindFirstChild("Event")
        end
    end
    return nil
end

local function GetTargetsInRange()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local npcs = workspace:FindFirstChild("NPCs")
    local ev = GetDamageEvent()
    if not (root and npcs and ev) then
        return {}
    end
    local list = {}
    for _, npc in ipairs(npcs:GetChildren()) do
        local hum = npc:FindFirstChildOfClass("Humanoid")
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 then
            if (hrp.Position - root.Position).Magnitude <= Attack.range then
                table.insert(list, { hum = hum, ev = ev })
            end
        end
    end
    return list
end

local function AttackAllOnce()
    local list = GetTargetsInRange()
    for _, t in ipairs(list) do
        pcall(function()
            t.ev:FireServer("NPCs", "Damage", t.hum, Attack.damage)
        end)
    end
end

local AttackOneByOneRunning = false
local function AttackOneByOne()
    if AttackOneByOneRunning then
        return
    end
    AttackOneByOneRunning = true
    task.spawn(function()
        while true do
            local list = GetTargetsInRange()
            if #list == 0 then
                break
            end
            for _, t in ipairs(list) do
                pcall(function()
                    t.ev:FireServer("NPCs", "Damage", t.hum, Attack.damage)
                end)
                task.wait(0.3 / Attack.speed)
            end
        end
        AttackOneByOneRunning = false
    end)
end

task.spawn(function()
    while true do
        if AutoAttack.enabled then
            if AttackAllMode.enabled then
                AttackAllOnce()
            elseif AttackOneByOneMode.enabled then
                AttackOneByOne()
            end
        end
        task.wait(1 / Attack.speed)
    end
end)

task.spawn(function()
    while true do
        local loot = workspace:FindFirstChild("Loot")
        if ESP.enabled then
            if loot then
                for _, item in ipairs(loot:GetChildren()) do
                    if not item:FindFirstChildOfClass("Highlight") then
                        local h = Instance.new("Highlight")
                        h.FillColor = Color3.fromRGB(255, 0, 0)
                        h.OutlineColor = Color3.fromRGB(255, 255, 255)
                        h.FillTransparency = 0.5
                        h.Parent = item
                    end
                end
            end
        elseif loot then
            for _, item in ipairs(loot:GetChildren()) do
                local h = item:FindFirstChildOfClass("Highlight")
                if h then
                    pcall(function()
                        h:Destroy()
                    end)
                end
            end
        end
        task.wait(1)
    end
end)

local oldIndex
if getrawmetatable and setreadonly and newcclosure then
    local mt, old = getrawmetatable(game), getrawmetatable(game).__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if AntiCheat.enabled and key == "AssemblyLinearVelocity" and self.Name == "HumanoidRootPart" then
            return Vector3.new()
        end
        return old(self, key)
    end)
end

local Window = Library:CreateWindow({ Title = "逃跑者", Footer = "XJW", Center = true, AutoShow = true })

local Tabs = {
    Main = Window:AddTab("功能", "user"),
    Car = Window:AddTab("汽车修改", "user"),
    ["UI Settings"] = Window:AddTab("UI设置", "settings"),
}

local MainBox = Tabs.Main:AddLeftGroupbox("功能")
MainBox:AddToggle("AutoAttack", { Text = "自动攻击", Default = false })
MainBox:AddSlider("Range", { Text = "范围", Min = 1, Max = 10000, Default = 60, Rounding = 0 })
MainBox:AddSlider("AttackDamage", { Text = "攻击伤害", Min = 1, Max = 999999, Default = 999999, Rounding = 0 })
MainBox:AddSlider("AttackSpeed", { Text = "攻速", Min = 0.1, Max = 5, Default = 1, Rounding = 1 })
MainBox:AddToggle("AttackAll", { Text = "一键攻击（需开自动攻击）", Default = false })
MainBox:AddToggle("AttackOneByOne", { Text = "逐个攻击（需开自动攻击）", Default = false })
MainBox:AddToggle("ESP", { Text = "物品透视", Default = false })
MainBox:AddToggle("AntiCheat", { Text = "反作弊绕过", Default = false })
MainBox:AddButton({ Text = "删除直升机", Func = function()
    local heli = workspace:FindFirstChild("Helicopter")
    if heli then
        pcall(function()
            heli:Destroy()
        end)
        Toast("直升机已删除")
    else
        Toast("未找到直升机")
    end
end })

local function TeleportPlayer(pos)
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

local SuppressToast = false

local function Notify(msg)
    local ok, err = pcall(function()
        Library:Notify(msg, 1)
    end)
    if not ok then
        print("[逃跑者] " .. msg)
    end
end

local function Toast(msg)
    if SuppressToast then
        return
    end
    local ok, err = pcall(function()
        Library:Notify(msg, 1)
    end)
    if not ok then
        print("[逃跑者] " .. msg)
    end
end

local function GetEndZ()
    local flowModule = ReplicatedStorage:FindFirstChild("FlowClient")
    local gui = flowModule and flowModule:FindFirstChild("Gui")
    local distanceModule = gui and gui:FindFirstChild("DistanceToBorderClient")
    if distanceModule then
        local ok, module = pcall(require, distanceModule)
        if ok and type(module) == "table" then
            local callback = module.SetEndPos_event or module.SetEndPos
            if type(callback) == "function" and debug and type(debug.getupvalues) == "function" then
                local read, upvalues = pcall(debug.getupvalues, callback)
                if read and type(upvalues) == "table" then
                    if type(upvalues[1]) == "number" then
                        return upvalues[1]
                    end
                    for _, value in upvalues do
                        if type(value) == "number" and math.abs(value) > 1000 then
                            return value
                        end
                    end
                end
            end
        end
    end
    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, label in playerGui:GetDescendants() do
            if label:IsA("TextLabel") and label.Text:find("Mexico", 1, true) then
                local current = label.Parent
                while current and current ~= playerGui do
                    local value = tonumber(current.Name:match("^Border_(-?[%d%.]+)$"))
                    if value then
                        return value
                    end
                    current = current.Parent
                end
            end
        end
    end
    return nil
end

local function GetEndPrompt()
    local map = workspace:FindFirstChild("Map")
    local buildings = map and map:FindFirstChild("Buildings")
    local customs = buildings and buildings:FindFirstChild("CustomsFinal")
    if not customs then
        return nil
    end
    local finalDoor = customs:FindFirstChild("CustomsBuilding") and customs.CustomsBuilding:FindFirstChild("FinalDoor")
    local command = finalDoor and finalDoor:FindFirstChild("Command")
    local commandButton = command and command:FindFirstChild("CommandButton")
    local holder = commandButton and commandButton:FindFirstChild("Prompt")
    local prompt = holder and (holder:IsA("ProximityPrompt") and holder or holder:FindFirstChildOfClass("ProximityPrompt"))
    if prompt then
        return prompt
    end
    local ok, candidates = pcall(customs.QueryDescendants, customs, "ProximityPrompt")
    if ok then
        for _, candidate in candidates do
            if candidate.ActionText == "Activate" and candidate:FindFirstAncestor("FinalDoor") then
                return candidate
            end
        end
    end
    return nil
end

local function GetEndPromptDestination(prompt, direction)
    local holder = prompt and prompt.Parent
    local holderCFrame
    if holder and holder:IsA("Attachment") then
        holderCFrame = holder.WorldCFrame
    elseif holder and holder:IsA("BasePart") then
        holderCFrame = holder.CFrame
    end
    if not holderCFrame then
        return nil
    end
    local outward = holderCFrame.LookVector
    if outward.Z * direction > 0 then
        outward = -outward
    end
    if math.abs(outward.Z) < 0.25 then
        outward = Vector3.new(0, 0, -direction)
    end
    local position = holderCFrame.Position + outward * 4
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = LocalPlayer.Character and { LocalPlayer.Character } or {}
    local result = workspace:Raycast(position + Vector3.yAxis * 20, Vector3.new(0, -60, 0), params)
    if result then
        position = Vector3.new(position.X, result.Position.Y + 3.25, position.Z)
    end
    return CFrame.lookAt(position, Vector3.new(holderCFrame.Position.X, position.Y, holderCFrame.Position.Z), Vector3.yAxis)
end

local function GetEndAnchor()
    local map = workspace:FindFirstChild("Map")
    local buildings = map and map:FindFirstChild("Buildings")
    local customs = buildings and buildings:FindFirstChild("CustomsFinal")
    if customs then
        local ok, pivot = pcall(customs.GetPivot, customs)
        if ok then
            return pivot:PointToWorldSpace(Vector3.new(-44.4001, 4.65, -16.5))
        end
    end
    return nil
end

local TeleportBox = Tabs.Main:AddLeftGroupbox("传送")

local function MapReady()
    local endZ = GetEndZ()
    if not endZ then return false end
    local prompt = GetEndPrompt()
    if prompt then return true end
    local anchor = GetEndAnchor()
    if anchor then return true end
    return false
end

local function GetRoadZones()
    local map = workspace:FindFirstChild("Map")
    local ground = map and map:FindFirstChild("Ground")
    local road = ground and ground:FindFirstChild("Road")
    local target = road
    if not target then
        return nil
    end
    local zones = {}
    for _, child in ipairs(target:GetChildren()) do
        local num = tonumber(child.Name)
        if num then
            table.insert(zones, { num = num, obj = child })
        end
    end
    table.sort(zones, function(a, b)
        return a.num < b.num
    end)
    return zones
end

local function GetZonePosition(zone)
    local obj = zone.obj
    if obj:IsA("BasePart") then
        return obj.Position
    end
    -- 优先取模型内所有 BasePart 的平均位置（几何中心），
    -- 防止 zone 由左右两条线/多个部件组成时取到偏侧点
    local parts = {}
    for _, p in ipairs(obj:GetDescendants()) do
        if p:IsA("BasePart") then
            table.insert(parts, p)
        end
    end
    if #parts > 0 then
        local sum = Vector3.new()
        for _, p in ipairs(parts) do
            sum = sum + p.Position
        end
        return sum / #parts
    end
    local ok, pivot = pcall(obj.GetPivot, obj)
    if ok and pivot then
        return pivot.Position
    end
    local pp = obj:FindFirstChild("PrimaryPart")
    if pp then
        return pp.Position
    end
    local part = obj:FindFirstChildOfClass("BasePart")
    if part then
        return part.Position
    end
    return nil
end

local FlyTargetIdx = nil
local FlyLastDir = nil
local function GetNextFlyTarget(pos)
    local zones = GetRoadZones()
    if zones and #zones > 0 then
        if FlyTargetIdx == nil then
            -- 起飞首帧：只锁定玩家前方（Z 更大）的最近区块作为起点，绝不选身后区块
            local best, bestDist = nil, math.huge
            for i, z in ipairs(zones) do
                local p = GetZonePosition(z)
                if p and p.Z > pos.Z then
                    local d = (p - pos).Magnitude
                    if d < bestDist then
                        best, bestDist = i, d
                    end
                end
            end
            -- 若前方无区块（已在末端附近），直接锁最大编号区块
            FlyTargetIdx = best or #zones
        end
        while FlyTargetIdx <= #zones do
            local zp = GetZonePosition(zones[FlyTargetIdx])
            if zp then
                local flat = Vector3.new(zp.X - pos.X, 0, zp.Z - pos.Z)
                local dist = flat.Magnitude
                if dist <= 20 then
                    FlyTargetIdx = FlyTargetIdx + 1
                elseif FlyLastDir and flat:Dot(FlyLastDir) < 0 then
                    FlyTargetIdx = FlyTargetIdx + 1
                else
                    FlyLastDir = flat.Unit
                    return zp
                end
            else
                FlyTargetIdx = FlyTargetIdx + 1
            end
        end
    end
    local anchor = GetEndAnchor()
    if anchor then
        local flat = Vector3.new(anchor.X - pos.X, 0, anchor.Z - pos.Z)
        if flat.Magnitude > 0.001 then
            FlyLastDir = flat.Unit
        end
        return anchor
    end
    return nil
end

local FlyPath = nil
local FlySeg = 1
local function BuildSmoothPath(pts, maxGap)
    local out = {}
    for i = 1, #pts - 1 do
        local a = pts[i]
        local b = pts[i + 1]
        local seg = b - a
        local len = seg.Magnitude
        if len >= 0.0001 then
            local n = math.max(1, math.floor(len / maxGap))
            for j = 0, n - 1 do
                table.insert(out, a + seg * (j / n))
            end
        end
    end
    table.insert(out, pts[#pts])
    return out
end
local function FlyPathNearest(pos)
    -- 遍历整条路径，返回距离 pos 最近的投影点及所在段索引（不依赖 FlySeg）
    if not FlyPath then
        return nil, nil
    end
    local bestProj, bestIdx, bestDist = nil, 1, math.huge
    for i = 1, #FlyPath - 1 do
        local a = FlyPath[i]
        local b = FlyPath[i + 1]
        local ab = b - a
        local len2 = ab:Dot(ab)
        if len2 > 0.0001 then
            local t = math.clamp((pos - a):Dot(ab) / len2, 0, 1)
            local proj = a + ab * t
            local d = (proj - pos).Magnitude
            if d < bestDist then
                bestDist, bestProj, bestIdx = d, proj, i
            end
        end
    end
    return bestProj, bestIdx
end

local function FlyPathTarget(pos)
    -- 从最近投影点出发，沿路径向前取 LOOKAHEAD 距离的目标点：
    -- 弯道处目标点提前转向，角色朝目标点飞，不会沿旧段方向冲出线外
    local proj, idx = FlyPathNearest(pos)
    if not proj then
        return nil
    end
    local LOOKAHEAD = 40
    local dist = 0
    local target = proj
    local i = idx
    local from = proj
    while i < #FlyPath do
        local a = FlyPath[i]
        local b = FlyPath[i + 1]
        local seg = b - a
        local segLen = seg.Magnitude
        if segLen < 0.0001 then
            i = i + 1
        else
            local segDir = seg.Unit
            local remain = segLen - (from - a).Magnitude
            if dist + remain >= LOOKAHEAD then
                target = from + segDir * (LOOKAHEAD - dist)
                return target
            else
                dist = dist + remain
                i = i + 1
                from = b
            end
        end
    end
    -- 路径已到尽头：返回最后一点，由调用方决定是否重建
    return FlyPath[#FlyPath]
end

local function FlyPathUpdate(pos)
    if FlyPath == nil then
        local zones = GetRoadZones()
        if not (zones and #zones > 0) then
            return nil
        end
        local pts = {}
        for _, z in ipairs(zones) do
            local p = GetZonePosition(z)
            if p then
                table.insert(pts, Vector3.new(p.X, 0, p.Z))
            end
        end
        if #pts < 2 then
            return nil
        end
        -- 路径点加密：相邻 zone 间按最大 15 格间距插值，弯道平滑且不易耗尽
        FlyPath = BuildSmoothPath(pts, 15)
    end
    local proj = FlyPathNearest(pos)
    if not proj then
        return nil
    end
    -- 偏离中线过远：判定已脱轨，重建路径重新贴线
    local flat = Vector3.new(pos.X - proj.X, 0, pos.Z - proj.Z)
    if flat.Magnitude > 150 then
        FlyPath = nil
        return nil
    end
    local target = FlyPathTarget(pos)
    if not target then
        return nil
    end
    -- 已到路径尽头：下一帧基于当前位置重建，继续沿道路飞，杜绝直飞穿线
    if (target - proj).Magnitude < 1 then
        FlyPath = nil
    end
    return target
end

local function FlyPathClamp(pos)
    if not FlyPath then
        return pos
    end
    local proj = FlyPathNearest(pos)
    if not proj then
        return pos
    end
    return Vector3.new(proj.X, pos.Y, proj.Z)
end

TeleportBox:AddButton({ Text = "传送到墨西哥", Func = function()
    Notify("请等待地图加载")
    TeleportPlayer(Vector3.new(-175.421982, 2604.443115, 83648.421875))
    task.spawn(function()
        local Elapsed = 0
        repeat
            task.wait(1)
            Elapsed = Elapsed + 1
        until MapReady() or Elapsed >= 90
        if not MapReady() then
            Notify("地图加载超时，未自动传送终点")
            return
        end
        task.wait(1)
        local endZ = GetEndZ()
        if not endZ then
            Notify("终点 Z 读取失败，未传送")
            return
        end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            Notify("角色不可用，未传送")
            return
        end
        local start = workspace:FindFirstChildOfClass("SpawnLocation")
        local direction = (not start or endZ >= start.Position.Z) and 1 or -1
        local prompt = GetEndPrompt()
        local destination
        if prompt then
            destination = GetEndPromptDestination(prompt, direction)
        end
        if not destination then
            local anchor = GetEndAnchor()
            if not anchor then
                Notify("未找到终点闸门，未传送")
                return
            end
            destination = CFrame.lookAt(anchor, Vector3.new(anchor.X, anchor.Y, anchor.Z - direction))
        end
        root.CFrame = destination
        Notify("成功传送墨西哥")
    end)
end })

local FlyRun = false
local FlyBody = nil
local FlyConn = nil
local FlySpeedValue = 100
local FlyGroundY = nil
local FlyPlat = nil
local FlyCan = nil
local FlyService = game:GetService("RunService")
local FlyVoidMiss = 0
local FlyInVoid = false
local VoidHintLabel = nil

local function SetVoidHint(show)
    local ok1, err1 = pcall(function()
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not playerGui then
            error("PlayerGui not found")
        end
        if show then
            if not VoidHintLabel or not VoidHintLabel.Parent then
                local sg = Instance.new("ScreenGui")
                sg.Name = "VoidHintGui"
                sg.IgnoreGuiInset = true
                sg.ResetOnSpawn = false
                sg.DisplayOrder = 999
                sg.Parent = playerGui
                local label = Instance.new("TextLabel")
                label.Name = "VoidHintLabel"
                label.Text = "已检测到掉虚空 正在返回地面"
                label.Font = Enum.Font.GothamBold
                label.TextSize = 24
                label.TextColor3 = Color3.fromRGB(255, 90, 90)
                label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                label.BackgroundTransparency = 0.3
                label.BorderSizePixel = 0
                label.Size = UDim2.new(0, 340, 0, 48)
                label.Position = UDim2.new(1, -356, 0, 20)
                label.ZIndex = 99
                label.Parent = sg
                VoidHintLabel = label
            end
            VoidHintLabel.Visible = true
        else
            if VoidHintLabel then
                VoidHintLabel.Visible = false
            end
        end
    end)
    if not ok1 then
        print("[逃跑者] 虚空提示UI失败: " .. tostring(err1))
    end
end

local function StopFly()
    FlyRun = false
    FlyInVoid = false
    SetVoidHint(false)
    if FlyConn then
        FlyConn:Disconnect()
        FlyConn = nil
    end
    if FlyBody then
        pcall(function()
            FlyBody:Destroy()
        end)
        FlyBody = nil
    end
    if FlyPlat then
        pcall(function()
            FlyPlat.PlatformStand = false
        end)
        FlyPlat = nil
    end
    if FlyCan ~= nil then
        local ch = LocalPlayer.Character
        local rt = ch and ch:FindFirstChild("HumanoidRootPart")
        if rt then
            pcall(function()
                rt.CanCollide = FlyCan
            end)
        end
        FlyCan = nil
    end
end

local function FlyTick(dt)
    if not FlyRun then
        return
    end
    local ch = LocalPlayer.Character
    local rt = ch and ch:FindFirstChild("HumanoidRootPart")
    if not rt then
        StopFly()
        return
    end
    local flyTarget = FlyPathUpdate(rt.Position)
    local step = FlySpeedValue * 3 * (dt or 0.016)
    local moveVec
    if FlyInVoid then
        moveVec = Vector3.new(0, step * 2, 0)
    elseif flyTarget then
        local flat = Vector3.new(flyTarget.X - rt.Position.X, 0, flyTarget.Z - rt.Position.Z)
        if flat.Magnitude > 0.001 then
            moveVec = flat.Unit * step
        else
            moveVec = Vector3.new(0, 0, step)
        end
    else
        local anchor = GetEndAnchor()
        local flat
        if anchor then
            flat = Vector3.new(anchor.X - rt.Position.X, 0, anchor.Z - rt.Position.Z)
        end
        if flat and flat.Magnitude > 0.001 then
            moveVec = flat.Unit * step
        else
            moveVec = Vector3.new(0, 0, step)
        end
    end
    if moveVec then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = LocalPlayer.Character and { LocalPlayer.Character } or {}

        local left = moveVec
        while left.Magnitude > 0.001 do
            local mv = left
            if mv.Magnitude > 20 then
                mv = mv.Unit * 20
            end
            rt.CFrame = rt.CFrame + mv
            left = left - mv
        end

        rt.AssemblyLinearVelocity = Vector3.new()
        rt.AssemblyAngularVelocity = Vector3.new()

        local ray2 = workspace:Raycast(rt.Position + Vector3.new(0, 5, 0), Vector3.new(0, -500, 0), params)
        local wantY = rt.Position.Y
        if FlyInVoid then
            local gap = ray2 and (rt.Position.Y - ray2.Position.Y) or math.huge
            if (ray2 and gap <= 15) or (FlyGroundY and rt.Position.Y >= FlyGroundY + 50) then
                FlyInVoid = false
                FlyVoidMiss = 0
                SetVoidHint(false)
                Notify("已飞回陆地，恢复路径飞行")
            end
        else
            if ray2 then
                local gap = rt.Position.Y - ray2.Position.Y
                if FlyGroundY and rt.Position.Y < FlyGroundY - 30 then
                    FlyInVoid = true
                    SetVoidHint(true)
                    Notify("检测到掉虚空，开始向上飞")
                elseif gap <= 40 then
                    FlyGroundY = ray2.Position.Y
                    FlyVoidMiss = 0
                    wantY = ray2.Position.Y + 10
                else
                    FlyVoidMiss = FlyVoidMiss + 1
                    if FlyVoidMiss >= 10 and (not FlyGroundY or rt.Position.Y < FlyGroundY - 30) then
                        FlyInVoid = true
                        SetVoidHint(true)
                        Notify("检测到掉虚空，开始向上飞")
                    end
                end
            else
                FlyVoidMiss = FlyVoidMiss + 1
                if FlyVoidMiss >= 10 and (not FlyGroundY or rt.Position.Y < FlyGroundY - 30) then
                    FlyInVoid = true
                    SetVoidHint(true)
                    Notify("检测到掉虚空，开始向上飞")
                end
            end
        end
        local clampPos = FlyInVoid and rt.Position or FlyPathClamp(rt.Position)
        local rot2 = rt.CFrame - rt.CFrame.Position
        rt.CFrame = CFrame.new(clampPos.X, wantY, clampPos.Z) * rot2
    end
    local anchor = GetEndAnchor()
    if anchor and (anchor - rt.Position).Magnitude < 60 then
        StopFly()
        Notify("成功到达墨西哥")
    end
end

TeleportBox:AddButton({ Text = "传送到车子", Func = function()
    local vehFolder = workspace:FindFirstChild("Vehicles")
    local clap = vehFolder and vehFolder:FindFirstChild("Claptima")
    if clap then
        local ok, pos = pcall(function()
            local pivot = clap:GetPivot()
            if pivot then
                return pivot.Position
            end
            local pp = clap:FindFirstChild("PrimaryPart")
            if pp then
                return pp.Position
            end
            return nil
        end)
        if ok and pos then
            TeleportPlayer(pos + Vector3.new(0, 5, 0))
            Toast("已传送到车子")
        else
            Toast("未找到车子")
        end
    else
        Toast("未找到车子")
    end
end })

TeleportBox:AddButton({ Text = "传送到最近店铺", Func = function()
    local map = workspace:FindFirstChild("Map")
    local buildings = map and map:FindFirstChild("Buildings")
    if not buildings then
        Toast("未找到 Buildings 文件夹")
        return
    end

    local shops = {}
    for _, v in ipairs(buildings:GetChildren()) do
        if v:IsA("Model") then
            local lower = v.Name:lower()
            if lower:find("pawn") or lower:find("shop") or lower:find("store") or lower:find("market") or lower:find("当铺") or lower:find("典当") then
                table.insert(shops, v)
            end
        end
    end
    if #shops == 0 then
        Toast("未找到店铺")
        return
    end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        Toast("角色不可用，未传送")
        return
    end
    local best, bestDist
    for _, shop in ipairs(shops) do
        local ok, pivot = pcall(shop.GetPivot, shop)
        if ok and pivot then
            local dist = (pivot.Position - root.Position).Magnitude
            if not bestDist or dist < bestDist then
                best, bestDist = shop, dist
            end
        end
    end
    if not best then
        Toast("店铺位置读取失败，未传送")
        return
    end
    local ok2, pos = pcall(function()
        local pivot = best:GetPivot()
        return pivot and pivot.Position
    end)
    if ok2 and pos then
        TeleportPlayer(pos + Vector3.new(0, 5, 0))
        Toast("已传送到最近店铺：" .. best.Name)
    else
        Toast("店铺位置读取失败，未传送")
    end
end })

local AutoLootRun = false

local function GetEquipable(item)
    if item:IsA("Tool") or item:IsA("Accessory") then
        return item
    end
    local t = item:FindFirstChildOfClass("Tool")
    if t then
        return t
    end
    local a = item:FindFirstChildOfClass("Accessory")
    if a then
        return a
    end
    return nil
end

local function GetItemPos(item)
    if item:IsA("BasePart") then
        return item.Position
    end
    local ok, pivot = pcall(function()
        return item:GetPivot().Position
    end)
    if ok and pivot and pivot.Magnitude > 0.1 then
        return pivot
    end
    local handle = item:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then
        return handle.Position
    end
    local root = item:FindFirstChild("HumanoidRootPart") or item:FindFirstChildOfClass("BasePart")
    if root then
        return root.Position
    end
    return nil
end

local function TryPickup(item)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if root and firetouchinterest then
        local parts = {}
        if item:IsA("BasePart") then
            table.insert(parts, item)
        end
        for _, p in ipairs(item:GetDescendants()) do
            if p:IsA("BasePart") then
                table.insert(parts, p)
            end
        end
        for _, p in ipairs(parts) do
            pcall(function()
                firetouchinterest(p, root, 0)
            end)
        end
        task.wait(0.15)
        for _, p in ipairs(parts) do
            pcall(function()
                firetouchinterest(p, root, 1)
            end)
        end
    end

    for _, prompt in ipairs(item:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            pcall(function()
                prompt:InputHoldBegin()
            end)
        end
    end
    task.wait(0.2)
    for _, prompt in ipairs(item:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            pcall(function()
                prompt:InputHoldEnd()
            end)
        end
    end
end

function isLoot(item)
    if not item or not item:IsA("Model") then
        return false
    end
    local pp = item.PrimaryPart
    if not (pp and pp:IsA("BasePart") and pp.Parent == item) then
        return false
    end
    local hasDrag = item:HasTag("Draggable") or item:HasTag("draggable")
    local hasEquip = item:HasTag("Equippable") or item:HasTag("equippable")
    if not (hasDrag and hasEquip) then
        return false
    end
    if item:HasTag("BuyableLoot") then
        return false
    end
    return true
end

local FlowTable = nil
local function getFlow()
    if FlowTable then
        return FlowTable
    end
    local fc = ReplicatedStorage:FindFirstChild("FlowClient")
    if not fc then
        return nil, "no FlowClient"
    end
    local ok, mod = pcall(require, fc)
    if ok and type(mod) == "table" then
        FlowTable = mod
        return mod
    end
    return nil, tostring(mod)
end

local PickupFunc = nil
local function findPickup()
    if PickupFunc then
        return PickupFunc
    end
    local ok, fns = pcall(filtergc, "function", { Name = "pickup" }, false)
    if ok and type(fns) == "table" then
        for _, f in ipairs(fns) do
            local info = debug.getinfo(f)
            if info and info.source and info.source:find("FlowClient.Draggables", 1, true) then
                PickupFunc = f
                return f
            end
        end
    end
    return nil
end

local function grabLoot(part)
    local f = findPickup()
    if not f then
        return false, "no pickup fn"
    end
    local ok, err = pcall(f, part)
    return ok, err
end

local LootRemote = nil
local function getClientRunnerRemote()
    if LootRemote then
        return LootRemote
    end
    local fc = ReplicatedStorage:FindFirstChild("FlowClient")
    local runner = fc and fc:FindFirstChild("ClientRunner")
    local fn = runner and runner:FindFirstChild("Function")
    if fn and (fn:IsA("RemoteFunction") or fn:IsA("RemoteEvent")) then
        LootRemote = fn
    end
    return LootRemote
end

local function lootPart(item, alt)
    if not alt then
        return item.PrimaryPart
    end
    for _, name in ipairs({ "Watch", "Handle" }) do
        local p = item:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            return p
        end
    end
    return item:FindFirstChildOfClass("BasePart")
end

local BackpackBalance = nil
local function getBackpackUsage()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then
        return nil, nil
    end
    if not BackpackBalance then
        local d = ReplicatedStorage:FindFirstChild("Data")
        if d then
            local ok, mod = pcall(require, d)
            if ok and type(mod) == "table" and type(mod.Balance) == "table" then
                BackpackBalance = mod.Balance
            end
        end
    end
    local used = #backpack:GetChildren()
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Tool") then
        used = used + 1
    end
    for _, name in ipairs({ "BackpackLarge", "BackpackMedium", "BackpackSmall" }) do
        local found = backpack:FindFirstChild(name) or (char and char:FindFirstChild(name))
        if found and BackpackBalance then
            local key = "MaxToolsLargeBackpack"
            if name == "BackpackMedium" then
                key = "MaxToolsMediumBackpack"
            elseif name == "BackpackSmall" then
                key = "MaxToolsSmallBackpack"
            end
            return used, BackpackBalance[key]
        end
    end
    return used, BackpackBalance and BackpackBalance.MaxTools or nil
end

local function isInventoryFull()
    local used, limit = getBackpackUsage()
    if not used or not limit then
        return false, false
    end
    return used >= limit, true
end

local CannotEquipByName = {}

local ClientRunnerEvent = nil
local function getClientRunnerEvent()
    if ClientRunnerEvent then
        return ClientRunnerEvent
    end
    local fc = ReplicatedStorage:FindFirstChild("FlowClient")
    local runner = fc and fc:FindFirstChild("ClientRunner")
    local ev = runner and runner:FindFirstChild("Event")
    if ev and ev:IsA("RemoteEvent") then
        ClientRunnerEvent = ev
    end
    return ClientRunnerEvent
end

local function getNilByName(name)
    if not getnilinstances then
        return nil
    end
    local ok, list = pcall(getnilinstances)
    if ok and type(list) == "table" then
        for _, obj in ipairs(list) do
            if obj.Name == name then
                return obj
            end
        end
    end
    return nil
end

local function dropLoot(item, cframe)
    local ev = getClientRunnerEvent()
    if not ev then
        return false, "no ClientRunner.Event"
    end
    local obj = item
    local ok, err = pcall(function()
        ev:FireServer("Loot", "LootUnequip", obj, false, false, cframe or CFrame.new())
    end)
    return ok, err
end

local function equipByInvoke(item, alt)
    local fn = getClientRunnerRemote()
    if not fn then
        return false, "no ClientRunner.Function", nil
    end
    local part = lootPart(item, alt)
    if not part then
        return false, "no part", nil
    end
    if fn:IsA("RemoteFunction") then
        local ok, res = pcall(function()
            return fn:InvokeServer("Loot", "LootEquip", part)
        end)
        if ok then
            return true, "invoke ok", res
        end
        return false, tostring(res), res
    end
    fn:FireServer("Loot", "LootEquip", part)
    return true, "fired", nil
end

local function EquipItem(eq, hum, char)
    local ok = pcall(function()
        if eq:IsA("Tool") then
            hum:EquipTool(eq)
        else
            hum:AddAccessory(eq)
        end
    end)
    if not ok then
        pcall(function()
            eq.Parent = char
        end)
    end
    return ok
end


local function findNearestPawn()
    local map = workspace:FindFirstChild("Map")
    local buildings = map and map:FindFirstChild("Buildings")
    if not buildings then
        return nil
    end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local myPos = root and root.Position or Vector3.new()
    local best, bestDist
    for _, b in ipairs(buildings:GetChildren()) do
        if b:IsA("Model") then
            local name = b.Name:lower()
            if name:find("pawn") or name:find("shop") or name:find("store") or name:find("market") or name:find("当铺") or name:find("典当") then
                local ok, pivot = pcall(b.GetPivot, b)
                if ok and pivot then
                    local dist = (pivot.Position - myPos).Magnitude
                    if not bestDist or dist < bestDist then
                        best, bestDist = b, dist
                    end
                end
            end
        end
    end
    return best
end

local function getPawnDropPos(pawn)
    local counter = pawn:FindFirstChild("PawnCounter", true)
    local volume = counter and counter:FindFirstChild("Volume", true)
    if volume and volume:IsA("BasePart") then
        return volume.Position
    end
    local ok, pivot = pcall(pawn.GetPivot, pawn)
    if ok and pivot then
        return pivot.Position
    end
    return nil
end

local AutoDropRun = false


local VehFlyRun = false
local VehFlyConn = nil
local VehParts = nil
local VehModel = nil
local VehVoidMiss = 0
local VehInVoid = false
local VehGroundY = nil

local function VehAnchorModel(model)
    local list = {}
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(list, { part = part, anchored = part.Anchored, cancollide = part.CanCollide })
            part.Anchored = true
            part.CanCollide = false
        end
    end
    return list
end

local function VehRestore(list)
    for _, item in ipairs(list or {}) do
        pcall(function()
            item.part.Anchored = item.anchored
            item.part.CanCollide = item.cancollide
        end)
    end
end

local function StopVehFly()
    VehFlyRun = false
    VehInVoid = false
    SetVoidHint(false)
    if VehFlyConn then
        VehFlyConn:Disconnect()
        VehFlyConn = nil
    end
    VehRestore(VehParts)
    VehParts = nil
end

local function VehFlyTick(dt)
    if not VehFlyRun then
        return
    end
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    if not (seat and seat:IsA("VehicleSeat")) then
        StopVehFly()
        Notify("未坐在载具上，已停止")
        return
    end
    if not VehParts then

        local model = seat
        while model do
            if model:IsA("Model") and model ~= ch and model ~= workspace then
                break
            end
            model = model.Parent
        end
        VehModel = model
        VehParts = model and VehAnchorModel(model) or {}
    end
    local flyTarget = FlyPathUpdate(seat.Position)
    local step = FlySpeedValue * 3 * (dt or 0.016)
    local moveVec
    if VehInVoid then
        moveVec = Vector3.new(0, step * 2, 0)
    elseif flyTarget then
        local flat = Vector3.new(flyTarget.X - seat.Position.X, 0, flyTarget.Z - seat.Position.Z)
        if flat.Magnitude > 0.001 then
            moveVec = flat.Unit * step
        else
            moveVec = Vector3.new(0, 0, step)
        end
    else
        local anchor = GetEndAnchor()
        local flat
        if anchor then
            flat = Vector3.new(anchor.X - seat.Position.X, 0, anchor.Z - seat.Position.Z)
        end
        if flat and flat.Magnitude > 0.001 then
            moveVec = flat.Unit * step
        else
            moveVec = Vector3.new(0, 0, step)
        end
    end

    local function VehMoveAll(delta)
        for _, item in ipairs(VehParts or {}) do
            pcall(function()
                item.part.CFrame = item.part.CFrame + delta
            end)
        end
    end
    local left = moveVec
    while left.Magnitude > 0.001 do
        local mv = left
        if mv.Magnitude > 20 then
            mv = mv.Unit * 20
        end
        VehMoveAll(mv)
        left = left - mv
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excludes = {}
    if ch then
        table.insert(excludes, ch)
    end
    if VehModel then
        table.insert(excludes, VehModel)
    end
    params.FilterDescendantsInstances = excludes
    local ray = workspace:Raycast(seat.Position + Vector3.new(0, 5, 0), Vector3.new(0, -300, 0), params)
    if VehInVoid then
        local gap = ray and (seat.Position.Y - ray.Position.Y) or math.huge
        if (ray and gap <= 15) or (VehGroundY and seat.Position.Y >= VehGroundY + 50) then
            VehInVoid = false
            VehVoidMiss = 0
            SetVoidHint(false)
            Notify("已飞回陆地，恢复路径飞行")
        end
    else
        if ray then
            local gap = seat.Position.Y - ray.Position.Y
            if VehGroundY and seat.Position.Y < VehGroundY - 30 then
                VehInVoid = true
                SetVoidHint(true)
                Notify("检测到掉虚空，开始向上飞")
            elseif gap <= 40 then
                VehGroundY = ray.Position.Y
                VehVoidMiss = 0
                local deltaY = (ray.Position.Y + 10) - seat.Position.Y
                if math.abs(deltaY) > 0.001 then
                    VehMoveAll(Vector3.new(0, deltaY, 0))
                end
            else
                VehVoidMiss = VehVoidMiss + 1
                if VehVoidMiss >= 10 and (not VehGroundY or seat.Position.Y < VehGroundY - 30) then
                    VehInVoid = true
                    SetVoidHint(true)
                    Notify("检测到掉虚空，开始向上飞")
                end
            end
        else
            VehVoidMiss = VehVoidMiss + 1
            if VehVoidMiss >= 10 and (not VehGroundY or seat.Position.Y < VehGroundY - 30) then
                VehInVoid = true
                SetVoidHint(true)
                Notify("检测到掉虚空，开始向上飞")
            end
        end
    end
    local clampPos = VehInVoid and seat.Position or FlyPathClamp(seat.Position)
    local dx = clampPos.X - seat.Position.X
    local dz = clampPos.Z - seat.Position.Z
    if math.abs(dx) > 0.001 or math.abs(dz) > 0.001 then
        VehMoveAll(Vector3.new(dx, 0, dz))
    end
    local anchor = GetEndAnchor()
    if anchor and (anchor - seat.Position).Magnitude < 60 then
        StopVehFly()
        Notify("载具已到达墨西哥")
    end
end

local FlyBox = Tabs.Main:AddRightGroupbox("飞行")
FlyBox:AddSlider("FlySpeed", { Text = "飞行速度", Min = 1, Max = 300, Default = 100, Rounding = 0 })
FlyBox:AddButton({ Text = "飞行到墨西哥", Func = function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (root and hum) then
        Notify("角色不可用，无法飞行")
        return
    end
    if FlyRun then
        Notify("飞行已在进行中")
        return
    end
    FlyRun = true
    FlyTargetIdx = nil
    FlyLastDir = nil
    FlyPath = nil
    FlySeg = 1
    FlyPlat = hum
    FlyInVoid = false
    FlyVoidMiss = 0
    FlyGroundY = nil
    hum.PlatformStand = true
    FlyCan = root.CanCollide
    root.CanCollide = false
    Notify("开始飞往墨西哥，请等待地图加载")
    FlyConn = FlyService.Heartbeat:Connect(FlyTick)
end })
FlyBox:AddButton({ Text = "车子飞行到墨西哥", Func = function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    if not (seat and seat:IsA("VehicleSeat")) then
        Notify("请先上车再飞行")
        return
    end
    if VehFlyRun then
        Notify("载具飞行已在进行中")
        return
    end
    VehFlyRun = true
    FlyTargetIdx = nil
    FlyLastDir = nil
    FlyPath = nil
    FlySeg = 1
    VehInVoid = false
    VehVoidMiss = 0
    VehGroundY = nil
    Notify("载具开始飞往墨西哥")
    VehFlyConn = FlyService.Heartbeat:Connect(VehFlyTick)
end })
FlyBox:AddButton({ Text = "停止飞行", Func = function()
    local stopped = false
    if FlyRun then
        StopFly()
        stopped = true
    end
    if VehFlyRun then
        StopVehFly()
        stopped = true
    end
    Notify(stopped and "已停止飞行" or "当前没有飞行")
end })

FlyBox:AddLabel("自动化")
FlyBox:AddButton({ Text = "自动偷取战利品", Func = function()
    if AutoLootRun then
        AutoLootRun = false
        Notify("已停止自动偷取")
        return
    end
    local loot = workspace:FindFirstChild("Loot")
    if not loot then
        Notify("未找到 Loot 容器")
        return
    end
    local items = {}
    for _, item in ipairs(loot:GetChildren()) do
        if not (item:IsA("Highlight") or item:IsA("BillboardGui") or item:IsA("Sound")) then
            local lootOk = isLoot(item)
            local eq = lootOk and nil or GetEquipable(item)
            table.insert(items, { item = item, eq = eq, lootOk = lootOk })
        end
    end
    if #items == 0 then
        local parts = {}
        for _, item in ipairs(loot:GetChildren()) do
            local hasTool = item:FindFirstChildOfClass("Tool") and "含Tool" or (item:IsA("Tool") and "是Tool" or "")
            local hasHandle = item:FindFirstChild("Handle") and "含Handle" or ""
            local tags = {}
            for _, t in ipairs(item:GetTags()) do
                table.insert(tags, t)
            end
            local tagStr = #tags > 0 and ("标签=" .. table.concat(tags, ",")) or "无标签"
            table.insert(parts, item.Name .. "(" .. item.ClassName .. hasTool .. hasHandle .. "," .. tagStr .. ")")
        end
        local sample = table.concat(parts, ", ")
        if #sample > 80 then
            sample = sample:sub(1, 80) .. "..."
        end
        Notify("Loot 共 " .. #parts .. " 项：" .. sample)
        print("[自动装备] Loot 结构: " .. table.concat(parts, " | "))
        return
    end
    local fullStart = isInventoryFull()
    if fullStart then
        Notify("库存已满")
        return
    end
    AutoLootRun = true
    Notify("找到 " .. #items .. " 个可装备物品，开始自动偷取")
    task.spawn(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        for i, entry in ipairs(items) do
            if not AutoLootRun then
                return
            end
            if isInventoryFull() then
                Notify("库存已满，停止自动偷取")
                AutoLootRun = false
                return
            end
            local pos = GetItemPos(entry.item)
            if pos then
                TeleportPlayer(pos + Vector3.new(0, 3, 0))
                print("[自动装备] " .. i .. "/" .. #items .. " -> " .. entry.item.Name)
                if entry.eq then
                    EquipItem(entry.eq, hum, char)
                    local eqWait = 0
                    while AutoLootRun and eqWait < 1.5 do
                        local inHand = hum and hum:FindFirstChildOfClass("Tool") == entry.eq
                        local onChar = entry.eq.Parent == char
                        if inHand or onChar then
                            break
                        end
                        task.wait(0.1)
                        eqWait = eqWait + 0.1
                    end
                    Notify("已装备 " .. entry.eq.Name)
                else
                    if CannotEquipByName[entry.item.Name] then
                        print("[自动装备] 跳过(仅可拖动): " .. entry.item.Name)
                        Notify(entry.item.Name .. " 只能拖动，已跳过")
                        task.wait(0.2)
                    else
                        TeleportPlayer(pos)
                        task.wait(0.2)
                        local eqOk, eqMsg, eqRes = equipByInvoke(entry.item)
                        print("[自动装备] Invoke LootEquip: " .. tostring(eqOk) .. " " .. tostring(eqMsg) .. " res=" .. tostring(eqRes))
                        local done = false
                        if eqOk then
                            local wait = 0
                            while AutoLootRun and wait < 0.6 do
                                if not entry.item.Parent then
                                    done = true
                                    break
                                end
                                task.wait(0.1)
                                wait = wait + 0.1
                            end
                        end
                        if not done then
                            TeleportPlayer(pos)
                            task.wait(0.15)
                            local eq2, eq2msg, eq2res = equipByInvoke(entry.item, true)
                            print("[自动装备] 兜底 Invoke LootEquip: " .. tostring(eq2) .. " " .. tostring(eq2msg) .. " res=" .. tostring(eq2res))
                            if eq2 then
                                local wait2 = 0
                                while AutoLootRun and wait2 < 0.6 do
                                    if not entry.item.Parent then
                                        done = true
                                        break
                                    end
                                    task.wait(0.1)
                                    wait2 = wait2 + 0.1
                                end
                            end
                        end
                        if done then
                            Notify("已装备 " .. entry.item.Name)
                        else
                            CannotEquipByName[entry.item.Name] = true
                            print("[自动装备] 不可装备(仅可拖动): " .. entry.item.Name)
                            Notify(entry.item.Name .. " 只能拖动，已跳过")
                        end
                    end
                end
                task.wait(0.2)
            end
        end
        AutoLootRun = false
        Notify("自动偷取完成")
    end)
end })
FlyBox:AddButton({ Text = "自动出售", Func = function()
    if AutoDropRun then
        AutoDropRun = false
        Notify("已停止自动出售")
        return
    end
    local candidates = {}
    local seen = {}
    local function addObj(obj)
        if obj and not seen[obj] then
            seen[obj] = true
            table.insert(candidates, obj)
        end
    end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, obj in ipairs(backpack:GetChildren()) do
            if obj:IsA("Tool") or obj:IsA("Accessory") or obj:IsA("Model") then
                addObj(obj)
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Tool") or obj:IsA("Accessory") or obj:IsA("Model") then
                addObj(obj)
            end
        end
    end
    if getnilinstances then
        local ok, list = pcall(getnilinstances)
        if ok and type(list) == "table" then
            for _, obj in ipairs(list) do
                if obj:IsA("Model") and (obj:HasTag("Draggable") or obj:HasTag("Equippable") or obj:HasTag("BuyableLoot")) then
                    addObj(obj)
                end
            end
        end
    end
    if #candidates == 0 then
        Notify("物品栏是空的")
        return
    end
    AutoDropRun = true
    Notify("找到 " .. #candidates .. " 个物品，开始放下")
    task.spawn(function()
        local pawn = findNearestPawn()
        local lookTarget = nil
        if pawn then
            local dropPos = getPawnDropPos(pawn)
            if dropPos then
                local backPos = dropPos
                local okp, pivot = pcall(pawn.GetPivot, pawn)
                if okp and pivot then
                    local dir = pivot.Position - dropPos
                    if dir.Magnitude > 0.01 then
                        backPos = dropPos + dir.Unit * 2
                    end
                end
                TeleportPlayer(backPos + Vector3.new(0, 3, 0))
                Notify("已传送到 " .. pawn.Name .. " 后面")
                lookTarget = dropPos + Vector3.new(0, 2, 0)
                task.wait(0.3)
            else
                Notify("柜台位置读取失败，原地放下")
            end
        else
            Notify("未找到店铺，原地放下")
        end
        local conn = nil
        if lookTarget then
            local cam = workspace.CurrentCamera
            local oldType = cam and cam.CameraType
            if cam then
                cam.CameraType = Enum.CameraType.Scriptable
            end
            local startT = os.clock()
            conn = game:GetService("RunService").RenderStepped:Connect(function()
                if not AutoDropRun or not cam or (os.clock() - startT) >= 2 then
                    if conn then
                        conn:Disconnect()
                    end
                    if cam and oldType then
                        cam.CameraType = oldType
                    end
                    return
                end
                local cp = cam.CFrame.Position
                cam.CFrame = CFrame.lookAt(cp, lookTarget)
            end)
        end
        local n = 0
        for _, obj in ipairs(candidates) do
            if not AutoDropRun then
                return
            end
            local dropCFrame = nil
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                dropCFrame = root.CFrame
            end
            if not dropCFrame then
                dropCFrame = CFrame.new()
            end
            local ok, err = dropLoot(obj, dropCFrame)
            print("[放下物品栏] " .. obj.Name .. ": " .. tostring(ok) .. " " .. tostring(err))
            if ok then
                n = n + 1
                Notify("已放下 " .. obj.Name)
            else
                Notify(obj.Name .. " 放下失败")
            end
            task.wait(0.05)
        end
        AutoDropRun = false
        if n > 0 then
            Notify("放下完成，共 " .. n .. " 个，开始出售")
        end
        local target = nil
        for _, v in workspace:GetDescendants() do
            if v:IsA("ProximityPrompt") then
                local text = tostring(v.ObjectText) .. tostring(v.ActionText)
                if text:find("Sell") or text:find("sell") then
                    target = v
                    break
                end
            end
        end
        if not target then
            Notify("未找到出售按钮，跳过自动出售")
            return
        end
        if conn then
            conn:Disconnect()
            conn = nil
            local cam0 = workspace.CurrentCamera
            if cam0 then
                cam0.CameraType = Enum.CameraType.Custom
            end
        end
        Notify("找到出售按钮: " .. tostring(target.ActionText or ""))
        local cam = workspace.CurrentCamera
        local oldCamType = cam and cam.CameraType
        local sellLook = nil
        local bell = pawn and pawn:FindFirstChild("CallBell", true)
        if not bell then
            local map = workspace:FindFirstChild("Map")
            local buildings = map and map:FindFirstChild("Buildings")
            local kid7 = buildings and buildings:GetChildren()[7]
            if kid7 then
                bell = kid7:FindFirstChild("CallBell", true)
            end
        end
        if bell then
            local bp = bell:IsA("BasePart") and bell or bell:FindFirstChild("BasePart", true)
            if bp then
                sellLook = bp.Position
            end
        end
        if not sellLook then
            sellLook = dropPos
        end
        local sellRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if sellRoot and sellLook then
            local btnPos = sellLook
            local outDir = Vector3.new(0, 0, -1)
            local okp2, piv2 = pcall(pawn.GetPivot, pawn)
            if okp2 and piv2 then
                local d = (sellLook - piv2.Position)
                if d.Magnitude > 0.01 then
                    outDir = d.Unit
                end
            end
            local standPos = sellLook + outDir * 1.5
            TeleportPlayer(standPos + Vector3.new(0, 1, 0))
            task.wait(0.3)
        end
        local sellConn = nil
        if cam and sellLook then
            cam.CameraType = Enum.CameraType.Scriptable
            local startT2 = os.clock()
            local timeLimit = (target.HoldDuration or 1) + 1
            sellConn = game:GetService("RunService").RenderStepped:Connect(function()
                if not cam or (os.clock() - startT2) >= timeLimit then
                    if sellConn then
                        sellConn:Disconnect()
                    end
                    if cam and oldCamType then
                        cam.CameraType = oldCamType
                    end
                    return
                end
                local cp = cam.CFrame.Position
                cam.CFrame = CFrame.lookAt(cp, sellLook)
            end)
        end
        task.wait(1)
        local holdOK = pcall(function() target:InputHoldBegin() end)
        if not holdOK then
            Notify("出售长按失败")
            if sellConn then
                sellConn:Disconnect()
                sellConn = nil
                if cam and oldCamType then
                    cam.CameraType = oldCamType
                end
            end
            return
        end
        local anchorConn = nil
        local anchorCF = sellRoot and sellRoot.CFrame
        if sellRoot and anchorCF then
            anchorConn = game:GetService("RunService").RenderStepped:Connect(function()
                if not sellRoot then
                    if anchorConn then
                        anchorConn:Disconnect()
                        anchorConn = nil
                    end
                    return
                end
                sellRoot.CFrame = anchorCF
                sellRoot.AssemblyLinearVelocity = Vector3.new()
                sellRoot.AssemblyAngularVelocity = Vector3.new()
            end)
        end
        task.wait((target.HoldDuration or 1) + 0.3)
        pcall(function() target:InputHoldEnd() end)
        if anchorConn then
            anchorConn:Disconnect()
            anchorConn = nil
        end
        if sellConn then
            sellConn:Disconnect()
            sellConn = nil
            if cam and oldCamType then
                cam.CameraType = oldCamType
            end
        end
        Notify("自动出售完成")
    end)
end })

local VehicleBox = Tabs.Car:AddLeftGroupbox("车辆属性")

local VehicleWordMap = {
    Max = "最大", Min = "最小", Speed = "速度", Acceleration = "加速度",
    Turn = "转向", Steering = "转向", Brake = "刹车", Power = "动力",
    Horsepower = "马力", Torque = "扭矩", Suspension = "悬挂", Handling = "操控",
    Weight = "重量", Fuel = "燃料", Tank = "油箱", Engine = "引擎",
    Gear = "挡位", Reverse = "倒挡", Boost = "加速", Nitro = "氮气",
    Force = "力", Rate = "速率", Time = "时间", Distance = "距离",
    Height = "高度", Angle = "角度", Radius = "半径", Range = "范围",
    Value = "值", Multiplier = "倍率", Modifier = "修正", Limit = "限制",
    Front = "前", Rear = "后", Left = "左", Right = "右", Wheel = "轮子",
    Tire = "轮胎", Grip = "抓地力", Friction = "摩擦", Drag = "阻力",
    Downforce = "下压力", Springs = "弹簧", Damper = "阻尼", Stiffness = "刚度",
    Center = "中心", Mass = "质量", Inertia = "惯量", Scale = "缩放",
    Auto = "自动", Manual = "手动", Shift = "换挡", Clutch = "离合",
    Throttle = "油门", Idle = "怠速", RPM = "转速", Redline = "红线转速",
    Top = "顶部", Bottom = "底部", Body = "车身", Chassis = "底盘",
    Roll = "侧倾", Pitch = "俯仰", Yaw = "偏航", Bank = "倾斜",
    Air = "空中", Ground = "地面", Water = "水中", Drift = "漂移",
    Lock = "锁定", Unlock = "解锁", Door = "车门", Window = "车窗",
    Horn = "喇叭", Light = "灯光", Headlight = "前灯", Taillight = "尾灯",
    BrakeLight = "刹车灯", TurnSignal = "转向灯", Windshield = "挡风玻璃",
    Mirror = "后视镜", Seat = "座椅", Wheelbase = "轴距", Track = "轮距",
    Clearance = "离地间隙", AngleOfAttack = "攻角", TopSpeed = "极速",
    Velocity = "速度", Accel = "加速度", AccelRate = "加速度率",
    BrakeForce = "制动力", SteeringAngle = "转向角", TurnRadius = "转弯半径",
    SpringRate = "弹簧刚度", Damping = "阻尼", Rebound = "回弹",
    Compression = "压缩", Camber = "外倾角", Toe = "束角", Caster = "主销后倾",
    Sway = "横向稳定", AntiRoll = "防侧倾", GearRatio = "传动比",
    Differential = "差速器", FinalDrive = "主减速比", Transmission = "变速箱",
    AWD = "四驱", FWD = "前驱", RWD = "后驱", FourWheelDrive = "四轮驱动",
    Traction = "牵引力", TractionControl = "牵引力控制", Stability = "稳定性",
    ESP = "车身稳定", ABS = "防抱死", TorqueVectoring = "扭矩矢量",
    TireWidth = "轮胎宽度", TireRadius = "轮胎半径", WheelSize = "轮毂尺寸",
    Rim = "轮毂", TirePressure = "胎压", Surface = "路面", Terrain = "地形",
    Offroad = "越野", Onroad = "公路", MaxSpeed = "最高速度", MaxTorque = "最大扭矩",
    MaxPower = "最大功率", MaxRPM = "最高转速", IdleRPM = "怠速转速",
    RedlineRPM = "红线转速", FuelCapacity = "油箱容量", FuelConsumption = "油耗",
    FuelEfficiency = "燃油效率", Battery = "电池", Electric = "电动",
    Motor = "电机", Regenerative = "动能回收", Cooling = "冷却", Radiator = "散热器",
    Turbo = "涡轮", Supercharger = "机械增压", Intercooler = "中冷器",
    Exhaust = "排气", Intake = "进气", Oil = "机油", Temperature = "温度",
    Heat = "热量", Sound = "声音", Volume = "音量", HornSound = "喇叭声",
    EngineSound = "引擎声", TireSound = "轮胎声", Skidmark = "胎痕",
    Smoke = "烟雾", Dust = "尘土", Particle = "粒子", Effect = "特效",
    Visual = "视觉", Model = "模型", Color = "颜色", Paint = "漆面",
    Tint = "色调", Neon = "霓虹", UnderGlow = "底盘灯", Spoiler = "尾翼",
    Bumper = "保险杠", Hood = "引擎盖", Trunk = "后备箱", Roof = "车顶",
    Sunroof = "天窗", Convertible = "敞篷", SoftTop = "软顶", HardTop = "硬顶",
    OffroadTires = "越野胎", AllTerrain = "全地形", Slick = "光头胎",
    Damage = "伤害", Health = "生命", Armor = "装甲", Durability = "耐久",
    Repair = "修复", Maintenance = "保养", Upgrade = "升级", Tuning = "调校",
    Perf = "性能", Performance = "性能", Sport = "运动", Race = "竞速",
    DriftMode = "漂移模式", Launch = "起步", LaunchControl = "起步控制",
    Cruise = "巡航", CruiseControl = "定速巡航", Parking = "停车",
    Handbrake = "手刹", EBrake = "手刹", HillStart = "坡道起步",
    Trailer = "拖车", Hitch = "拖钩", Load = "载荷", Payload = "载重",
    Cargo = "货物", Capacity = "容量", Passenger = "乘客", SeatCount = "座位数",
    Airbag = "气囊", Seatbelt = "安全带", Safety = "安全", Crash = "碰撞",
    Impact = "冲击", Deformation = "变形", Rigidity = "刚性", Frame = "车架",
    Panel = "面板", Glass = "玻璃", Bulletproof = "防弹", Seats = "座位",
    Doors = "车门数", Wheels = "轮子数", Axle = "车轴", Axles = "车轴数",
    Tires = "轮胎", EngineType = "引擎类型", DriveType = "驱动类型",
    BodyType = "车身类型", VehicleType = "车辆类型", Class = "等级",
    Tier = "级别", Level = "等级", Rank = "排名", Score = "分数",
    Price = "价格", Cost = "成本", Selling = "出售",
    Buy = "购买", Sell = "出售", Rental = "租赁", Locked = "已锁定",
    Unlocked = "已解锁", Owned = "已拥有", Stock = "库存",
}

local function TranslateVehicleName(name)
    local spaced = name:gsub("(%l)(%u)", "%1 %2"):gsub("(%u)(%u%l)", "%1 %2")
    local parts = {}
    for w in spaced:gmatch("[^%s_]+") do
        table.insert(parts, VehicleWordMap[w] or w)
    end
    return table.concat(parts, " ")
end

local CreatedVehicleProps = {}
local VehicleStatus = VehicleBox:AddLabel("正在扫描车辆属性...")

local function FindAllVehicleProps()
    local found = {}
    local function scan(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "VehicleProperty" then
                table.insert(found, child)
            end
            if child:IsA("Folder") or child:IsA("Model") or child:IsA("Configuration") or child:IsA("Tool") then
                scan(child)
            end
        end
    end
    pcall(scan, workspace)
    return found
end

local function CollectValueProps(vp)
    local list = {}
    local ok, attrs = pcall(function()
        return vp:GetAttributes()
    end)
    if ok and attrs then
        for name, value in pairs(attrs) do
            table.insert(list, { Name = name, Value = value })
        end
    end
    return list
end

local function VehicleOwnerName(vp)
    local owner = vp.Parent
    if owner then
        return owner.Name
    end
    return "未知车辆"
end

task.spawn(function()
    while true do
        local props = FindAllVehicleProps()
        if #props == 0 then
            pcall(function()
                if VehicleStatus then
                    VehicleStatus:SetText("请到对局中")
                end
            end)
        else
            local totalProps = 0
            for _, vp in ipairs(props) do
                totalProps = totalProps + #CollectValueProps(vp)
            end
            pcall(function()
                if VehicleStatus then
                    if totalProps == 0 then
                        VehicleStatus:SetText("找到 " .. #props .. " 辆车 · 无可修改属性")
                    else
                        VehicleStatus:SetText("找到 " .. #props .. " 辆车 · " .. totalProps .. " 个属性")
                    end
                end
            end)
            for _, vp in ipairs(props) do
                local vehName = VehicleOwnerName(vp)
                local valueProps = CollectValueProps(vp)
                for _, prop in ipairs(valueProps) do
                    local key = vehName .. "_" .. prop.Name
                    if not CreatedVehicleProps[key] then
                        CreatedVehicleProps[key] = true
                        local label = "车子 · " .. TranslateVehicleName(prop.Name)
                        local ptype = type(prop.Value)
                        local ok1, err1 = pcall(function()
                            if ptype == "boolean" then
                                local opt = VehicleBox:AddToggle(key, {
                                    Text = label,
                                    Default = prop.Value,
                                })
                                opt:OnChanged(function(Value)
                                    pcall(function()
                                        vp:SetAttribute(prop.Name, Value)
                                    end)
                                end)
                            elseif ptype == "number" then
                                local curVal = tonumber(prop.Value) or 0
                                local isFloat = math.abs(curVal - math.floor(curVal)) > 0.0001
                                local maxVal = math.max(math.ceil(curVal * 10), 1000)
                                if maxVal > 1000000 then maxVal = 1000000 end
                                if curVal > maxVal then maxVal = curVal end
                                local opt = VehicleBox:AddSlider(key, {
                                    Text = label,
                                    Min = 0,
                                    Max = maxVal,
                                    Default = curVal,
                                    Rounding = isFloat and 2 or 0,
                                })
                                opt:OnChanged(function(Value)
                                    pcall(function()
                                        vp:SetAttribute(prop.Name, Value)
                                    end)
                                end)
                            else
                                local opt = VehicleBox:AddInput(key, {
                                    Text = label,
                                    Default = tostring(prop.Value),
                                    Numeric = false,
                                })
                                opt:OnChanged(function(Value)
                                    pcall(function()
                                        vp:SetAttribute(prop.Name, Value)
                                    end)
                                end)
                            end
                        end)
                        if not ok1 then
                            warn("[车辆属性] 创建控件失败:", key, err1)
                        end
                    end
                end
            end

            task.wait()
            pcall(function()
                VehicleBox:Resize()
                Tabs.Main:Resize()
            end)
        end
        task.wait(2)
    end
end)

Toggles.AutoAttack:OnChanged(function(Value)
    AutoAttack.enabled = Value
    Toast(Value and "自动攻击开启成功" or "自动攻击已关闭")
end)
Toggles.AttackAll:OnChanged(function(Value)
    AttackAllMode.enabled = Value
    if Value then
        SuppressToast = true
        Toggles.AttackOneByOne:SetValue(false)
        SuppressToast = false
    end
    Toast(Value and "一键攻击开启成功" or "一键攻击已关闭")
end)
Toggles.AttackOneByOne:OnChanged(function(Value)
    AttackOneByOneMode.enabled = Value
    if Value then
        SuppressToast = true
        Toggles.AttackAll:SetValue(false)
        SuppressToast = false
    end
    Toast(Value and "逐个攻击开启成功" or "逐个攻击已关闭")
end)
Options.Range:OnChanged(function(Value)
    Attack.range = Value
end)
Options.AttackDamage:OnChanged(function(Value)
    Attack.damage = Value
end)
Options.AttackSpeed:OnChanged(function(Value)
    Attack.speed = Value
end)
Options.FlySpeed:OnChanged(function(Value)
    FlySpeedValue = Value
end)
Toggles.ESP:OnChanged(function(Value)
    ESP.enabled = Value
    Toast(Value and "物品透视开启成功" or "物品透视已关闭")
end)
Toggles.AntiCheat:OnChanged(function(Value)
    AntiCheat.enabled = Value
    Toast(Value and "反作弊绕过开启成功" or "反作弊绕过已关闭")
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("TaoPaoZhe/Configs")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

task.spawn(function()
    task.wait(0.1)
    SuppressToast = true
    Toggles.AutoAttack:SetValue(false)
    Toggles.AttackAll:SetValue(false)
    Toggles.AttackOneByOne:SetValue(false)
    Toggles.ESP:SetValue(false)
    Toggles.AntiCheat:SetValue(false)
    SuppressToast = false
end)

local TranslateMap = {
    ["Configuration"] = "配置",
    ["Config name"] = "配置名",
    ["Create config"] = "新建配置",
    ["Config list"] = "配置列表",
    ["Load config"] = "加载配置",
    ["Overwrite config"] = "覆盖配置",
    ["Delete config"] = "删除配置",
    ["Refresh list"] = "刷新列表",
    ["Set as autoload"] = "设为自动加载",
    ["Reset autoload"] = "重置自动加载",
    ["Current autoload config:"] = "当前自动加载配置：",
    ["Themes"] = "主题",
    ["Background color"] = "背景颜色",
    ["Main color"] = "主色",
    ["Accent color"] = "强调色",
    ["Outline color"] = "描边色",
    ["Font color"] = "字体颜色",
    ["Font Face"] = "字体",
    ["Theme list"] = "主题列表",
    ["Set as default"] = "设为默认",
    ["Custom theme name"] = "自定义主题名",
    ["Create theme"] = "创建主题",
    ["Custom themes"] = "自定义主题",
    ["Load theme"] = "加载主题",
    ["Overwrite theme"] = "覆盖主题",
    ["Delete theme"] = "删除主题",
    ["Reset default"] = "重置默认",
    ["None"] = "无",
    ["Search..."] = "搜索...",
    ["Toggle"] = "开关",
    ["Input"] = "输入",
    ["Slider"] = "滑块",
    ["KeyPicker"] = "按键",
}

local function TranslateText(root)
    local function Walk(obj)
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                local t = child.Text
                if t and t ~= "" then
                    local newT = t
                    for en, cn in pairs(TranslateMap) do
                        if newT == en then
                            newT = cn
                        elseif #en > 6 and newT:find(en, 1, true) then
                            newT = newT:gsub(en, cn)
                        end
                    end
                    if newT ~= t then
                        child.Text = newT
                    end
                end
            end
            Walk(child)
        end
    end
    Walk(root)
end

local function TranslateAll()
    local homes = {}
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        table.insert(homes, pg)
    end
    local cg = cloneref and cloneref(game:GetService("CoreGui"))
    if cg then
        table.insert(homes, cg)
    end
    local ok, gui = pcall(function()
        return gethui()
    end)
    if ok and gui then
        table.insert(homes, gui)
    end
    for _, root in ipairs(homes) do
        pcall(TranslateText, root)
    end
end

task.spawn(function()
    task.wait(0.5)
    while true do
        pcall(TranslateAll)
        task.wait(0.5)
    end
end)
