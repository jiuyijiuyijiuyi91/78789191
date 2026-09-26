local repo = "https://raw.githubusercontent.com/ATLASTEAM01/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({ Title = "钻探至地球核心", Footer = "XJW", Center = true, AutoShow = true })

local Tabs = {
    Main = Window:AddTab("主页", "user"),
    Drill = Window:AddTab("钻头修改", "hammer"),
    Teleport = Window:AddTab("传送", "map"),
    ["UI Settings"] = Window:AddTab("UI设置", "settings"),
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Player = Players.LocalPlayer



local function ClearArray(t)
    for i = #t, 1, -1 do
        t[i] = nil
    end
end

local GodMode = {
    Active = false,
    Connections = {},
    RenderSteps = {},
    OldCF = CFrame.new(),
    StepName1 = "",
    StepName2 = "",
}

local function RandomString()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local t = {}
    for i = 1, 24 do
        t[i] = chars:sub(math.random(1, 62), math.random(1, 62))
    end
    return table.concat(t)
end

GodMode.StepName1 = RandomString()
GodMode.StepName2 = GodMode.StepName1:reverse()

local function GetCharParts()
    local char = Player.Character
    if not char then return nil, nil, nil end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    return char, hum, root
end

local function GetRootPos()
    local _, _, root = GetCharParts()
    return root and root.Position or nil
end

local function CleanGodMode()
    for _, conn in ipairs(GodMode.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    ClearArray(GodMode.Connections)
    for _, step in ipairs(GodMode.RenderSteps) do
        pcall(function() RunService:UnbindFromRenderStep(step) end)
    end
    ClearArray(GodMode.RenderSteps)
end

function GodMode.Update(enabled)
    if not enabled then
        CleanGodMode()
        GodMode.Active = false
        local _, _, root = GetCharParts()
        if root then pcall(function() root.CFrame = GodMode.OldCF end) end
        return
    end

    local _, _, root = GetCharParts()
    if not root then return end

    GodMode.OldCF = root.CFrame
    GodMode.Active = true
    CleanGodMode()

    local rot = CFrame.Angles(math.rad(90), 0, 0)
    local depth = 7

    table.insert(GodMode.RenderSteps, GodMode.StepName1)
    RunService:BindToRenderStep(GodMode.StepName1, Enum.RenderPriority.Camera.Value - 1, function()
        local _, _, part = GetCharParts()
        if part then part.CFrame = GodMode.OldCF end
    end)
    table.insert(GodMode.Connections, RunService.PostSimulation:Connect(function()
        local _, _, part = GetCharParts()
        if part then
            GodMode.OldCF = part.CFrame
            part.CFrame = CFrame.new(part.Position - Vector3.yAxis * depth) * rot
        end
    end))
end

local function GetToolUpdateEvent()
    local ok, ev = pcall(function()
        return ReplicatedStorage.Packages._Index["sleitnick_knit@1.4.6"].knit.Services.ToolService.RE.Update
    end)
    if ok and ev then
        return ev
    end
    return nil
end

local function GetTargetPos(target)
    if not target then return nil end
    if target:IsA("BasePart") then
        return target.Position
    end
    local hrp = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso") or target:FindFirstChild("UpperTorso")
    if hrp then return hrp.Position end
    local part = target:FindFirstChildWhichIsA("BasePart")
    if part then return part.Position end
    return nil
end

local function IsValidTarget(target)
    if not target then return false end
    if not target.Parent then return false end
    local hum = target:FindFirstChildWhichIsA("Humanoid")
    if hum and hum.Health <= 0 then return false end
    return true
end

local function FaceTarget(target)
    local _, _, root = GetCharParts()
    if not root or not target then return end
    local targetPos = GetTargetPos(target)
    if not targetPos then return end
    pcall(function()
        root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
    end)
end

local function SwingTarget(target)
    if not IsValidTarget(target) then return end
    FaceTarget(target)
    local ev = GetToolUpdateEvent()
    if not ev then return end
    pcall(function()
        ev:FireServer({ "Swing", { target } })
    end)
end

local function GetNearestOre()
    local folder = workspace:FindFirstChild("Ores")
    if not folder then return nil end
    local rootPos = GetRootPos()
    if not rootPos then return nil end
    local best, bestDist = nil, math.huge
    for _, ore in ipairs(folder:GetChildren()) do
        local pos = GetTargetPos(ore)
        if pos then
            local d = (rootPos - pos).Magnitude
            if d < bestDist then
                best, bestDist = ore, d
            end
        end
    end
    return best
end

local function GetNearestNpc()
    local folder = workspace:FindFirstChild("Npc")
    if not folder then return nil end
    local rootPos = GetRootPos()
    if not rootPos then return nil end
    local best, bestDist = nil, math.huge
    for _, npc in ipairs(folder:GetChildren()) do
        if IsValidTarget(npc) then
            local pos = GetTargetPos(npc)
            if pos then
                local d = (rootPos - pos).Magnitude
                if d < bestDist then
                    best, bestDist = npc, d
                end
            end
        end
    end
    return best
end

local GodBox = Tabs.Main:AddLeftGroupbox("无敌")
Toggles.GodMode = GodBox:AddToggle("GodMode", { Text = "启用无敌", Default = false }):AddKeyPicker("GodModeBind", { Default = "F", SyncToggleState = true, Mode = "Toggle" })
Toggles.GodMode:OnChanged(function(Value)
    GodMode.Update(Value)
end)

local AttackBox = Tabs.Main:AddLeftGroupbox("自动攻击")
Toggles.AutoOre = AttackBox:AddToggle("AutoOre", { Text = "自动攻击岩石（需要靠近岩石）", Default = false })
Toggles.AutoNpc = AttackBox:AddToggle("AutoNpc", { Text = "自动攻击NPC（需要靠近NPC）", Default = false })
AttackBox:AddSlider("AttackInterval", { Text = "攻击间隔(秒)", Min = 0.1, Max = 2, Default = 0.5, Rounding = 1, Compact = false })

local CollectBox = Tabs.Main:AddLeftGroupbox("自动拾取")
Toggles.AutoCollect = CollectBox:AddToggle("AutoCollect", { Text = "自动拾取物品（需要拿袋子）", Default = false })

local ChestBox = Tabs.Main:AddLeftGroupbox("自动收集箱子")
Toggles.AutoChest = ChestBox:AddToggle("AutoChest", { Text = "自动收集箱子", Default = false })

local CollectBlacklist = {}
local function GetToolController()
    local ok, wc = pcall(function()
        return require(game:GetService("ReplicatedStorage").Packages.Knit)
    end)
    if not ok or not wc then return nil end
    local ok2, ctl = pcall(function() return wc.GetController("ToolController") end)
    if not ok2 then return nil end
    return ctl
end

local function DrillCollect()
    local ctl = GetToolController()
    if not ctl then return end
    local items = workspace:FindFirstChild("Items")
    if not items then return end
    local active = ctl.ActiveTool
    if not active or not active.Execute then return end
    local count = 0
    for _, y in ipairs(items:GetChildren()) do
        if count >= 5 then break end
        if not (y:IsA("BasePart") or y:IsA("Model")) then continue end
        local blocked = (y:GetAttribute("Blocked") == true) or (y.Name == "Money_Sack") or (y.Name == "SoulOrb")
        local shop = (y:GetAttribute("ShopItem") == true) or y:HasTag("ShopItem")
        if CollectBlacklist[y.Name] then continue end
        if not blocked and not shop then
            local canPick = true
            if type(active.Size) == "number" and type(active.MaxSize) == "number" then
                canPick = active.Size < active.MaxSize
            end
            if canPick then
                pcall(function()
                    active.Execute:Fire({ "Pickup", y })
                    count = count + 1
                end)
            else
                break
            end
        end
    end
end

local ChestTypes = { CommonChest = true, GoldChest = true, DiamondChest = true, VoidChest = true, PhoenixChest = true }

local function IsValidChest(chest)
    if not chest then return false end
    if not chest.Parent then return false end
    if not chest:IsDescendantOf(workspace) then return false end
    if chest:GetAttribute("Opened") == true then return false end
    if chest:GetAttribute("Locked") == true then return false end
    if chest:GetAttribute("RequiresKey") == true then return false end
    if chest:GetAttribute("BossDefeated") == false then return false end
    local parent, depth = chest.Parent, 0
    while parent and parent ~= workspace and depth < 10 do
        depth = depth + 1
        if parent:GetAttribute("WaveCompleted") == false then return false end
        if parent:GetAttribute("EncounterActive") == true then return false end
        if parent:GetAttribute("TriggeredFirstHit") == false then return false end
        if parent:GetAttribute("WaveActive") == true then return false end
        parent = parent.Parent
    end
    return true
end

local function IsTargetChest(obj)
    if not obj then return false end
    local name = obj.Name
    if ChestTypes[name] then return IsValidChest(obj) end
    local sel = obj:GetAttribute("SessionChestSelectedModel")
    if sel and ChestTypes[sel] then return IsValidChest(obj) end
    local parent = obj.Parent
    if parent and parent:IsA("Model") then
        if ChestTypes[parent.Name] then return IsValidChest(parent) end
        local psel = parent:GetAttribute("SessionChestSelectedModel")
        if psel and ChestTypes[psel] then return IsValidChest(parent) end
    end
    return false
end

local function GetChestPos(chest)
    if not chest then return nil end
    if chest:IsA("BasePart") then return chest.Position end
    if chest:IsA("Model") then
        local ok, pivot = pcall(function() return chest:GetPivot().Position end)
        if ok then return pivot end
    end
    local part = chest:FindFirstChildWhichIsA("BasePart")
    if part then return part.Position end
    return nil
end

local ChestCache = {}
local LastScan = 0

local function ScanChests()
    local now = tick()
    if now - LastScan < 2 then return ChestCache end
    LastScan = now
    local result, seen = {}, {}
    local function walk(node)
        for _, child in ipairs(node:GetChildren()) do
            if not seen[child] then
                seen[child] = true
                if IsTargetChest(child) then
                    result[#result + 1] = child
                end
            end
            if child:IsA("Model") or child:IsA("Folder") or child:IsA("Part") then
                walk(child)
            end
        end
    end
    walk(workspace)
    ChestCache = result
    return result
end

local NearestCache = { Chest = nil, Pos = nil, Time = 0 }

local function GetNearestChest()
    local rootPos = GetRootPos()
    if not rootPos then return nil end
    local now = tick()
    if now - NearestCache.Time < 0.5 and NearestCache.Chest then
        local cachedPos = NearestCache.Pos
        if cachedPos and (rootPos - cachedPos).Magnitude < 10 then
            return NearestCache.Chest
        end
    end
    local best, bestDist = nil, math.huge
    for _, chest in ipairs(ScanChests()) do
        local pos = GetChestPos(chest)
        if pos then
            local dist = (pos - rootPos).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = chest
            end
        end
    end
    NearestCache.Chest = best
    NearestCache.Pos = rootPos
    NearestCache.Time = now
    return best
end

local function ClearChestCache()
    ChestCache = {}
    LastScan = 0
    NearestCache.Chest = nil
    NearestCache.Time = 0
end

workspace.DescendantAdded:Connect(function(child)
    if child:IsA("BasePart") or child:IsA("Model") then
        if ChestTypes[child.Name] or child:GetAttribute("SessionChestId") then
            ClearChestCache()
        end
    end
end)

local function GetDrill()
    return workspace:FindFirstChild("Drill")
end

local function GetDrillProp(name, fallback)
    local drill = GetDrill()
    if not drill then return fallback end
    local ok, val = pcall(function() return drill:GetAttribute(name) end)
    if ok and val ~= nil then return val end
    local child = drill:FindFirstChild(name)
    if child and (child:IsA("NumberValue") or child:IsA("IntValue")) then
        return child.Value
    end
    return fallback
end

local function SetDrillProp(name, value)
    local drill = GetDrill()
    if not drill then
                return
    end
    local setOk = pcall(function() drill:SetAttribute(name, value) end)
    if setOk then
        local _, check = pcall(function() return drill:GetAttribute(name) end)
        if check ~= nil then return end
    end
    local child = drill:FindFirstChild(name)
    if child and (child:IsA("NumberValue") or child:IsA("IntValue")) then
        pcall(function() child.Value = value end)
    end
end

local DrillBox = Tabs.Drill:AddLeftGroupbox("钻头属性")
local drillProps = {
    { Key = "DrillDamage", Name = "Damage", Text = "伤害", Min = 1, Max = 1000, Default = 1, Rounding = 0 },
    { Key = "DrillDamageRate", Name = "DamageRate", Text = "伤害频率", Min = 0.1, Max = 10, Default = 1, Rounding = 1 },
    { Key = "DrillSpeed", Name = "Speed", Text = "钻速", Min = 1, Max = 500, Default = 25, Rounding = 0 },
    { Key = "DrillMaxFuel", Name = "MaxFuel", Text = "最大燃料", Min = 10, Max = 100000, Default = 100, Rounding = 0 },
    { Key = "DrillFuel", Name = "Fuel", Text = "燃料", Min = 0, Max = 100000, Default = 25, Rounding = 0 },
    { Key = "DrillThrottle", Name = "DriverThrottle", Text = "油门", Min = 0, Max = 100, Default = 0, Rounding = 0 },
    { Key = "DrillAutoPilot", Name = "AutoPilotEfficiency", Text = "自动驾驶效率", Min = 0, Max = 100, Default = 0, Rounding = 0 },
    { Key = "DrillAutoModule", Name = "AutoPilotModuleCount", Text = "自动驾驶模块数", Min = 0, Max = 100, Default = 0, Rounding = 0 },
    { Key = "DrillLeech", Name = "FuelLeechCount", Text = "燃料汲取数", Min = 0, Max = 100, Default = 0, Rounding = 0 },
}
for _, p in ipairs(drillProps) do
    DrillBox:AddSlider(p.Key, { Text = p.Text, Min = p.Min, Max = p.Max, Default = GetDrillProp(p.Name, p.Default), Rounding = p.Rounding, Compact = false }):OnChanged(function(Value)
        SetDrillProp(p.Name, Value)
    end)
end

local TeleportPoints = {
    { "0-10万米 | 市场兑换", { 13965, 3, -847 } },
    { "0-10万米 | 商店1", { 376, 4, -690 } },
    { "0-10万米 | 商店2", { 2776, 4, -690 } },
    { "0-10万米 | 商店3", { 5176, 4, -690 } },
    { "0-10万米 | 商店4", { 7576, 4, -690 } },
    { "0-10万米 | 商店5", { 9976, 4, -690 } },
    { "0-10万米 | 商店6", { 16776, 4, -690 } },
    { "0-10万米 | 商店7", { 20176, 4, -690 } },
    { "0-10万米 | 商店8", { 27976, 4, -690 } },
    { "0-10万米 | 商店9", { 33376, 4, -690 } },
    { "10万米+ | 商店1", { -536, 3, -690 } },
    { "10万米+ | 商店2", { 2866, 3, -690 } },
    { "10万米+ | 商店3", { 6266, 3, -690 } },
    { "10万米+ | 商店4", { 9666, 3, -690 } },
    { "10万米+ | 商店5", { 13066, 3, -690 } },
    { "10万米+ | 商店6", { 16466, 3, -690 } },
    { "10万米+ | 商店7", { 19866, 3, -690 } },
    { "10万米+ | 商店8", { 23266, 3, -690 } },
    { "10万米+ | 商店9", { 26666, 3, -690 } },
    { "折扣 | 最大改造器", { 13965, 3, -847 } },
}

local function TeleportTo(coord, name)
    local _, _, root = GetCharParts()
    if not root then
                return
    end
    local pos = Vector3.new(coord[1], coord[2] + 3, coord[3])
    pcall(function()
        root.CFrame = CFrame.new(pos)
    end)
    pcall(function()
        workspace:RequestStreamAroundAsync(pos)
    end)
    end

local TeleportBox = Tabs.Teleport:AddLeftGroupbox("传送点（开了无敌无法传送）")
local tpNames = {}
for _, p in ipairs(TeleportPoints) do
    tpNames[#tpNames + 1] = p[1]
end
TeleportBox:AddDropdown("TeleportSelect", { Text = "选择传送点", Values = tpNames, Default = 1, Multi = false }):OnChanged(function(Value)
    if type(Value) ~= "string" then return end
    for _, p in ipairs(TeleportPoints) do
        if p[1] == Value then
            TeleportTo(p[2], p[1])
            break
        end
    end
end)
local function TeleportToTarget(target, label)
    local _, _, root = GetCharParts()
    if not target then
                return
    end
    if not root then
                return
    end
    local pos = GetTargetPos(target)
    if not pos then
                return
    end
    pcall(function()
        root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    end)
    pcall(function()
        workspace:RequestStreamAroundAsync(pos)
    end)
    end
local OreDropdown, NpcDropdown
local function RefreshTargetLists()
    local ores, npcs = {}, {}
    local seenO, seenN = {}, {}
    local of = workspace:FindFirstChild("Ores")
    if of then
        for _, o in ipairs(of:GetChildren()) do
            if (o:IsA("Model") or o:IsA("BasePart")) and not seenO[o.Name] then
                seenO[o.Name] = true
                ores[#ores + 1] = o.Name
            end
        end
    end
    local nf = workspace:FindFirstChild("Npc")
    if nf then
        for _, n in ipairs(nf:GetChildren()) do
            if (n:IsA("Model") or n:IsA("BasePart")) and not seenN[n.Name] then
                seenN[n.Name] = true
                npcs[#npcs + 1] = n.Name
            end
        end
    end
    pcall(function()
        if OreDropdown then OreDropdown:SetValues(ores) end
        if NpcDropdown then NpcDropdown:SetValues(npcs) end
    end)
end
OreDropdown = TeleportBox:AddDropdown("OreTpSelect", { Text = "传送岩石", Values = {}, Default = 1, Multi = false })
OreDropdown:OnChanged(function(Value)
    if type(Value) ~= "string" then return end
    local of = workspace:FindFirstChild("Ores")
    if not of then return end
    local ore = of:FindFirstChild(Value)
    if ore then TeleportToTarget(ore, "岩石:" .. (Value or "")) end
end)
NpcDropdown = TeleportBox:AddDropdown("NpcTpSelect", { Text = "传送NPC", Values = {}, Default = 1, Multi = false })
NpcDropdown:OnChanged(function(Value)
    if type(Value) ~= "string" then return end
    local nf = workspace:FindFirstChild("Npc")
    if not nf then return end
    local npc = nf:FindFirstChild(Value)
    if npc then TeleportToTarget(npc, "NPC:" .. (Value or "")) end
end)
TeleportBox:AddButton({ Text = "刷新列表", Func = RefreshTargetLists })
TeleportBox:AddButton({ Text = "传送钻头", Func = function()
    local drill = GetDrill()
    if not drill then return end
    TeleportToTarget(drill, "钻头")
end })
Toggles.AutoRefresh = TeleportBox:AddToggle("AutoRefresh", { Text = "自动刷新列表", Default = false })
Toggles.AutoRefresh:OnChanged(function(Value)
    if Value then
        task.spawn(function()
            while Toggles.AutoRefresh.Value do
                task.wait(3)
                RefreshTargetLists()
            end
        end)
    end
end)
RefreshTargetLists()

local function GetEspPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        local direct = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso") or obj:FindFirstChild("UpperTorso") or obj:FindFirstChildWhichIsA("BasePart")
        if direct then return direct end
        local ok, pp = pcall(function() return obj.PrimaryPart end)
        if ok and pp then return pp end
    end
    for _, child in ipairs(obj:GetChildren()) do
        local p = GetEspPart(child)
        if p then return p end
    end
    return nil
end

local function GetHighlightTarget(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then return obj end
    local first = obj:FindFirstChildOfClass("BasePart") or obj:FindFirstChildOfClass("Model")
    if first then return first end
    for _, child in ipairs(obj:GetChildren()) do
        local t = GetHighlightTarget(child)
        if t then return t end
    end
    return nil
end

local function GetParts(obj)
    local parts = {}
    if not obj then return parts end
    if obj:IsA("BasePart") then
        parts[1] = obj
        return parts
    end
    for _, c in ipairs(obj:GetDescendants()) do
        if c:IsA("BasePart") then parts[#parts + 1] = c end
    end
    return parts
end

local function NewEspSystem(prefix, folderName, color, extraHl)
    local self = {
        Prefix = prefix,
        FolderName = folderName,
        Color = color,
        ExtraHl = extraHl,
        HlOn = false,
        NameOn = false,
        Started = false,
        Connections = {},
    }
    function self:GetFolder()
        return workspace:FindFirstChild(self.FolderName)
    end
    function self:ForEach(fn, onlyHl)
        local folder = self:GetFolder()
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                fn(obj)
            end
        end
        if onlyHl then
            local rw = workspace:FindFirstChild("RockWalls")
            if rw then
                for _, obj in ipairs(rw:GetChildren()) do
                    if obj:IsA("Model") or obj:IsA("BasePart") then fn(obj) end
                end
            end
            for _, tag in ipairs({ "Ore", "RockWall" }) do
                for _, obj in ipairs(CollectionService:GetTagged(tag)) do
                    if obj:IsA("Model") or obj:IsA("BasePart") then fn(obj) end
                end
            end
            local OreKeys = { "ore", "rock", "stone", "node", "mineral", "amethyst", "coal", "iron", "gold", "skull", "bone", "diamond", "copper", "crystal", "gem", "wall", "block" }
            for _, obj in ipairs(workspace:GetChildren()) do
                if (obj:IsA("Model") or obj:IsA("BasePart")) and not (obj == workspace:FindFirstChild("Ores") or obj == workspace:FindFirstChild("RockWalls") or obj == workspace:FindFirstChild("Npc")) then
                    local low = obj.Name:lower()
                    for _, k in ipairs(OreKeys) do
                        if low:find(k, 1, true) then
                            fn(obj)
                            break
                        end
                    end
                end
            end
        end
    end
    function self:ApplyHighlight(obj)
        if not obj then return end
        local target = GetHighlightTarget(obj)
        if not target then return end
        local parts = GetParts(target or obj)
        local mounted = 0
        for _, base in ipairs(parts) do
            if not base:FindFirstChild(self.Prefix .. "Highlight") then
                pcall(function()
                    local hl = Instance.new("Highlight")
                    hl.Name = self.Prefix .. "Highlight"
                    hl.Adornee = base
                    hl.FillTransparency = 0
                    hl.FillColor = self.Color
                    hl.OutlineTransparency = 0
                    hl.OutlineColor = Color3.new(1, 1, 1)
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = base
                end)
                mounted = mounted + 1
            end
            pcall(function()
                if not base:GetAttribute(self.Prefix .. "OldColor") then
                    base:SetAttribute(self.Prefix .. "OldColor", base.Color)
                end
                base.Color = self.Color
            end)
        end
        if self.Prefix == "OreEsp" and mounted > 0 then
            warn("[OreEsp] mount obj=" .. tostring(obj.Name) .. " type=" .. obj.ClassName .. " parts=" .. #parts)
        end
    end
    function self:ApplyName(obj)
        if not obj then return end
        if obj:FindFirstChild(self.Prefix .. "NameTag") then return end
        local target = GetHighlightTarget(obj)
        local part = GetEspPart(target or obj)
        if not part then return end
        pcall(function()
            local bg = Instance.new("BillboardGui")
            bg.Name = self.Prefix .. "NameTag"
            bg.Size = UDim2.new(0, 200, 0, 40)
            bg.AlwaysOnTop = true
            bg.Adornee = part
            bg.StudsOffset = Vector3.new(0, 3, 0)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = tostring(obj.Name)
            lbl.TextColor3 = self.Color
            lbl.TextStrokeTransparency = 0
            lbl.TextScaled = true
            lbl.Font = Enum.Font.SourceSansBold
            lbl.Parent = bg
            bg.Parent = target or obj
        end)
    end
    function self:ClearHighlight(obj)
        if not obj then return end
        local target = GetHighlightTarget(obj)
        local parts = GetParts(target or obj)
        for _, base in ipairs(parts) do
            local hl = base:FindFirstChild(self.Prefix .. "Highlight")
            if hl then pcall(function() hl:Destroy() end) end
            local old = base:GetAttribute(self.Prefix .. "OldColor")
            if old then
                pcall(function() base.Color = old end)
                base:SetAttribute(self.Prefix .. "OldColor", nil)
            end
        end
        local hl3 = obj:FindFirstChild(self.Prefix .. "Highlight")
        if hl3 then pcall(function() hl3:Destroy() end) end
    end
    function self:ClearName(obj)
        if not obj then return end
        local target = GetHighlightTarget(obj)
        if target then
            local bg = target:FindFirstChild(self.Prefix .. "NameTag")
            if bg then pcall(function() bg:Destroy() end) end
        end
        local bg2 = obj:FindFirstChild(self.Prefix .. "NameTag")
        if bg2 then pcall(function() bg2:Destroy() end) end
    end
    function self:Begin()
        local folder = self:GetFolder()
        if not folder then
            task.spawn(function()
                while true do
                    task.wait(0.5)
                    if self:GetFolder() then
                        self:Begin()
                        return
                    end
                end
            end)
            return
        end
        self:ForEach(function(obj) self:Apply(obj) end)
        self.Connections[#self.Connections + 1] = folder.ChildAdded:Connect(function(obj)
            if obj then
                task.wait(0.1)
                self:Apply(obj)
            end
        end)
        if self.ExtraHl then
            local rw = workspace:FindFirstChild("RockWalls")
            if rw then
                self.Connections[#self.Connections + 1] = rw.DescendantAdded:Connect(function(obj)
                    if obj and self.HlOn and (obj:IsA("Model") or obj:IsA("BasePart")) then
                        task.wait(0.1)
                        self:ApplyHighlight(obj)
                    end
                end)
            end
        end
    end
    function self:Start()
        if self.Started then return end
        self.Started = true
        self:Begin()
    end
    function self:Apply(obj, onlyHl)
        if self.HlOn then self:ApplyHighlight(obj) end
        if not onlyHl and self.NameOn then self:ApplyName(obj) end
    end
    function self:SetHl(on)
        if self.HlOn == on then return end
        self.HlOn = on
        if on then
            self:Start()
            self:ForEach(function(obj) self:ApplyHighlight(obj) end, true)
            if self.Prefix == "OreEsp" then
                local of = workspace:FindFirstChild("Ores")
                local rw = workspace:FindFirstChild("RockWalls")
                local wslist = {}
                for i, obj in ipairs(workspace:GetChildren()) do
                    if i > 30 then break end
                    wslist[#wslist + 1] = obj.Name .. ":" .. obj.ClassName
                end
                warn("[OreEsp] ON ores=" .. (of and #of:GetChildren() or 0) .. " rw=" .. (rw and #rw:GetChildren() or 0) .. " tagOre=" .. #CollectionService:GetTagged("Ore") .. " tagWall=" .. #CollectionService:GetTagged("RockWall"))
                warn("[OreEsp] workspace=" .. table.concat(wslist, ", "))
            end
        else
            self:ForEach(function(obj) self:ClearHighlight(obj) end, true)
        end
    end
    function self:SetName(on)
        if self.NameOn == on then return end
        self.NameOn = on
        if on then
            self:Start()
            self:ForEach(function(obj) self:ApplyName(obj) end)
        else
            self:ForEach(function(obj) self:ClearName(obj) end)
        end
    end
    return self
end

local OreEsp = NewEspSystem("OreEsp", "Ores", Color3.fromRGB(255, 200, 0), true)
local NpcEsp = NewEspSystem("NpcEsp", "Npc", Color3.fromRGB(255, 80, 80))

local OreEspBox = Tabs.Main:AddRightGroupbox("岩石透视")
Toggles.OreName = OreEspBox:AddToggle("OreName", { Text = "显示名字", Default = false })
Toggles.OreName:OnChanged(function(Value)
    OreEsp:SetName(Value)
end)

local WallBox = Tabs.Main:AddRightGroupbox("墙壁")
WallBox:AddButton({ Text = "删除所有墙壁", Func = function()
    local rw = workspace:FindFirstChild("RockWalls")
    if not rw then
                return
    end
    pcall(function() rw:Destroy() end)
    end })

local NpcEspBox = Tabs.Main:AddRightGroupbox("NPC透视")
Toggles.NpcHl = NpcEspBox:AddToggle("NpcHl", { Text = "高亮", Default = false })
Toggles.NpcHl:OnChanged(function(Value)
    NpcEsp:SetHl(Value)
end)
Toggles.NpcName = NpcEspBox:AddToggle("NpcName", { Text = "显示名字", Default = false })
Toggles.NpcName:OnChanged(function(Value)
    NpcEsp:SetName(Value)
end)

Player.CharacterAdded:Connect(function()
    task.wait(0.5)
    if GodMode.Active then
        GodMode.Update(false)
        task.wait(0.1)
        GodMode.Update(true)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if Toggles.AutoOre.Value then
            SwingTarget(GetNearestOre())
        end
        if Toggles.AutoNpc.Value then
            SwingTarget(GetNearestNpc())
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.15)
        if Toggles.AutoCollect.Value then
            DrillCollect()
        end
    end
end)

local LastChestTp = 0

task.spawn(function()
    while true do
        task.wait(1)
        if Toggles.AutoChest.Value then
            local now = tick()
            if now - LastChestTp < 1.2 then
                task.wait(0.3)
            else
                local ok, err = pcall(function()
                    local chest = GetNearestChest()
                    if chest then
                        local _, _, root = GetCharParts()
                        if root then
                            local pos = GetChestPos(chest)
                            if pos then
                                root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                                LastChestTp = now
                                task.wait(0.3)
                            end
                        end
                    end
                end)
                if not ok then
                    warn("[自动收集箱子] 错误: " .. tostring(err))
                end
            end
        end
        task.wait(0.5)
    end
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("GodModeAttack/Configs")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()
