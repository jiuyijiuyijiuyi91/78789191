local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local Settings = {
    Follow = false,
    Attack = false,
    Dist = 3,
    AtkInterval = 0.1,
    RefreshInterval = 2,
    BuyInterval = 1000,
    Buy = {
        basic = false,
        iron = false,
        house = false,
        Paint = false,
        Save = false,
        Speed = false,
    },
}

local FollowThread = nil
local AtkThread = nil
local BuyThreads = {}

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local BuyCrate = Remotes and Remotes:FindFirstChild("BuyCrate")
local BuyTool = Remotes and Remotes:FindFirstChild("BuyTool")

local FakeZombie = Workspace:FindFirstChild("Zombie")
local tracked = {}

local function IsPlayerModel(model)
    if model == LP.Character then return true end
    if Players:GetPlayerFromCharacter(model) then return true end
    if model:IsDescendantOf(Players) then return true end
    return false
end

local function IsFake(model)
    if model == FakeZombie then return true end
    if model.Parent == Workspace and model.Name == "Zombie" then return true end
    return false
end

local ZombieCache = {}

local function RemoveFromCache(z)
    for i = #ZombieCache, 1, -1 do
        if ZombieCache[i] == z then
            table.remove(ZombieCache, i)
        end
    end
end

local function ScanEnemiesFolder()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return false end
    local list = {}
    local function collect(root)
        for _, v in ipairs(root:GetChildren()) do
            if v:IsA("Model") and not IsPlayerModel(v) and not IsFake(v) then
                local hum = v:FindFirstChildOfClass("Humanoid")
                if hum then
                    table.insert(list, v)
                    if not tracked[v] then
                        tracked[v] = true
                        hum.Died:Connect(function()
                            RemoveFromCache(v)
                        end)
                    end
                end
            end
            if v:IsA("Folder") or v:IsA("Model") then
                collect(v)
            end
        end
    end
    collect(enemies)
    ZombieCache = list
    return true
end

local function CleanupCache()
    for i = #ZombieCache, 1, -1 do
        local z = ZombieCache[i]
        if not z or not z.Parent then
            table.remove(ZombieCache, i)
        else
            local hum = z:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                table.remove(ZombieCache, i)
            end
        end
    end
end

task.spawn(function()
    task.wait(1)
    ScanEnemiesFolder()
end)

local function GetPlayerRoot()
    local ch = LP.Character
    if not ch then return nil end
    return ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso")
end

local function GetWeapon()
    local ch = LP.Character
    if ch then
        for _, t in ipairs(ch:GetChildren()) do
            if t:IsA("Tool") then return t end
        end
    end
    for _, t in ipairs(LP.Backpack:GetChildren()) do
        if t:IsA("Tool") then
            if ch then
                pcall(function() t.Parent = ch end)
            end
            return t
        end
    end
    return nil
end

local function teleportTo(position)
    local root = GetPlayerRoot()
    if root then
        root.CFrame = CFrame.new(position)
    end
end

local function teleportToPart(part)
    if not part then return false end
    local pos
    if part:IsA("BasePart") then
        pos = part.Position
    else
        local rootPart = part:FindFirstChild("HumanoidRootPart") or part.PrimaryPart or part:FindFirstChild("Torso") or part:FindFirstChild("UpperTorso")
        if rootPart then
            pos = rootPart.Position
        else
            local ok, cf = pcall(function() return part:GetBoundingBox() end)
            if ok then
                pos = cf.Position
            end
        end
    end
    if pos then
        teleportTo(pos + Vector3.new(0, 3, 0))
        return true
    end
    return false
end

local function FindNearestZombie()
    local root = GetPlayerRoot()
    if not root then return nil end
    local best, bd = nil, math.huge
    for _, z in ipairs(ZombieCache) do
        local zrp = z:FindFirstChild("HumanoidRootPart") or z.PrimaryPart
        if zrp then
            local d = (zrp.Position - root.Position).Magnitude
            if d < bd then
                bd = d
                best = zrp
            end
        end
    end
    return best, bd
end

local function teleportBehind(part, dist)
    if not part then return end
    local root = GetPlayerRoot()
    if not root then return end
    local enemyCF = part.CFrame
    local behindPos = enemyCF.Position - enemyCF.LookVector * dist
    behindPos = behindPos + Vector3.new(0, 0.5, 0)
    root.CFrame = CFrame.new(behindPos)
end

local function lockCharacterBehind(targetRoot)
    if not targetRoot then return end
    local root = GetPlayerRoot()
    if not root then return end
    local direction = (targetRoot.Position - root.Position).Unit
    root.CFrame = CFrame.new(root.Position, root.Position + direction)
end

local function StartFollow()
    Settings.Follow = true
    FollowThread = task.spawn(function()
        local lastScan = 0
        while Settings.Follow do
            CleanupCache()

            if tick() - lastScan >= Settings.RefreshInterval then
                lastScan = tick()
                ScanEnemiesFolder()
            end

            local root = GetPlayerRoot()
            if not root then
                task.wait(0.5)
                continue
            end

            local zrp, dist = FindNearestZombie()
            if not zrp then
                ScanEnemiesFolder()
                task.wait(0.1)
                continue
            end

            teleportBehind(zrp, Settings.Dist)
            lockCharacterBehind(zrp)

            task.wait(0.02)
        end
    end)
end

local function StartAttack()
    Settings.Attack = true
    AtkThread = task.spawn(function()
        while Settings.Attack do
            local tool = GetWeapon()
            if tool then
                pcall(function()
                    tool:Activate()
                    tool:Activate()
                end)
            end
            task.wait(Settings.AtkInterval)
        end
    end)
end

local function BuyOne(item)
    pcall(function()
        if item.Kind == "Crate" then
            BuyCrate:FireServer(item.Name, 1)
        else
            BuyTool:FireServer(item.Name)
        end
    end)
end

local function StartBuy(item)
    Settings.Buy[item.Name] = true
    local t = task.spawn(function()
        print("[v44] 自动购买已开启: " .. item.Name)
        while Settings.Buy[item.Name] do
            BuyOne(item)
            task.wait(Settings.BuyInterval / 1000)
        end
    end)
    BuyThreads[item.Name] = t
end

local function StopBuy(name)
    Settings.Buy[name] = false
    if BuyThreads[name] then
        task.cancel(BuyThreads[name])
        BuyThreads[name] = nil
    end
end

local Window = WindUI:CreateWindow({
    Title = "建造躲藏的生存僵尸",
    Icon = "swords",
    Author = "XJW",
    Folder = "ZombieKill",
    Size = UDim2.fromOffset(400, 640),
    Theme = "Pink",
})

local Tab = Window:Tab({Title = "功能", Icon = "swords"})

Tab:Section({Title = "传送点", TextXAlignment = "Left", TextSize = 17})

Tab:Button({
    Title = "传送安全点",
    Callback = function()
        local mdl = Workspace:FindFirstChild("Model")
        local part = mdl and mdl:FindFirstChild("Part", true)
        if part and teleportToPart(part) then
            WindUI:Notify({Title = "传送成功", Content = "已传送到安全点", Duration = 2})
        else
            WindUI:Notify({Title = "传送失败", Content = "未找到 Model.Part", Duration = 2})
        end
    end
})

Tab:Button({
    Title = "传送复活点",
    Callback = function()
        local folder = Workspace:FindFirstChild("DirthPath")
        local sp = folder and folder:FindFirstChild("SpawnLocation", true)
        if not sp then
            sp = Workspace:FindFirstChild("SpawnLocation", true)
        end
        if not sp then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("SpawnLocation") then
                    sp = v
                    break
                end
            end
        end
        if sp and teleportToPart(sp) then
            print("[v44] 复活点实际路径: " .. sp:GetFullName())
            WindUI:Notify({Title = "传送成功", Content = "已传送到复活点", Duration = 2})
        else
            print("[v44] 复活点查找失败")
            WindUI:Notify({Title = "传送失败", Content = "未找到复活点，请把场景里出生点的路径发我", Duration = 3})
        end
    end
})

Tab:Section({Title = "打僵尸", TextXAlignment = "Left", TextSize = 17})

Tab:Toggle({
    Title = "循环传送僵尸",
    Default = false,
    Callback = function(v)
        if v then
            StartFollow()
        else
            Settings.Follow = false
            if FollowThread then task.cancel(FollowThread) FollowThread = nil end
        end
    end
})

Tab:Toggle({
    Title = "自动攻击",
    Default = false,
    Callback = function(v)
        if v then
            StartAttack()
        else
            Settings.Attack = false
            if AtkThread then task.cancel(AtkThread) AtkThread = nil end
        end
    end
})

Tab:Slider({
    Title = "攻击间隔(毫秒)",
    Value = {Min = 10, Max = 1000, Default = 100},
    Increment = 10,
    Callback = function(v)
        Settings.AtkInterval = (v or 100) / 1000
    end
})

Tab:Slider({
    Title = "背后距离(格)",
    Value = {Min = 1, Max = 8, Default = 3},
    Increment = 1,
    Callback = function(v) Settings.Dist = v or 3 end
})

Tab:Section({Title = "自动购买", TextXAlignment = "Left", TextSize = 17})

local BuyToggleList = {
    {Key = "basic", Title = "自动购买 基础箱", Kind = "Crate"},
    {Key = "iron", Title = "自动购买 铁箱", Kind = "Crate"},
    {Key = "house", Title = "自动购买 房屋箱", Kind = "Crate"},
    {Key = "Paint", Title = "自动购买 油漆", Kind = "Tool"},
    {Key = "Save", Title = "自动购买 存档", Kind = "Tool"},
    {Key = "Speed", Title = "自动购买 加速", Kind = "Tool"},
}

for _, def in ipairs(BuyToggleList) do
    Tab:Toggle({
        Title = def.Title,
        Default = false,
        Callback = function(v)
            if v then
                StartBuy({Name = def.Key, Kind = def.Kind})
            else
                StopBuy(def.Key)
            end
        end
    })
end

Tab:Slider({
    Title = "购买间隔(毫秒)",
    Value = {Min = 100, Max = 10000, Default = 1000},
    Increment = 100,
    Callback = function(v)
        Settings.BuyInterval = v or 1000
    end
})
