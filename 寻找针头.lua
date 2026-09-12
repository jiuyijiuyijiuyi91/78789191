local UI_URLS = {
    "https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua",
    "https://cdn.jsdelivr.net/gh/finendss/VowLibrary@main/WINDUI.lua",
    "https://ghproxy.net/https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua",
}

local WindUI
for _, u in ipairs(UI_URLS) do
    local ok, res = pcall(function()
        return loadstring(game:HttpGet(u))()
    end)
    if ok and type(res) == "table" then
        WindUI = res
        break
    end
end

if not WindUI then
    warn("UI库加载失败，请检查网络后重试")
    return
end

pcall(function()
    if WindUI.Themes and WindUI.Themes.Dark then
        local t = {}
        for k, v in pairs(WindUI.Themes.Dark) do
            t[k] = v
        end
        t.Name = "Blue"
        t.Accent = Color3.fromHex("#0B1220")
        t.Dialog = Color3.fromHex("#0F172A")
        t.Outline = Color3.fromHex("#3B82F6")
        t.Text = Color3.fromHex("#FFFFFF")
        t.Placeholder = Color3.fromHex("#93A4BF")
        t.Background = Color3.fromHex("#070B14")
        t.Button = Color3.fromHex("#1D4ED8")
        t.Icon = Color3.fromHex("#60A5FA")
        t.Toggle = Color3.fromHex("#2563EB")
        t.Slider = Color3.fromHex("#3B82F6")
        t.Checkbox = Color3.fromHex("#3B82F6")
        t.SliderIcon = Color3.fromHex("#93C5FD")
        t.Primary = Color3.fromHex("#3B82F6")
        t.ElementBackground = Color3.fromHex("#111A2E")
        t.ElementBackgroundTransparency = 0
        WindUI.Themes.Blue = t
    end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

local State = {
    CollectInterval = 1,
    SellThreshold = 25,
    ToolInterval = 1,
    NeedleInterval = 1,
    BuyInterval = 1,
    PermInterval = 1,
    AntiAFK = true,
    BuyToolsList = {},
}

local UnloadHooks = {}

local Toggles = setmetatable({}, {
    __index = function(_, k)
        return { Value = State[k] }
    end,
})

local Options = setmetatable({}, {
    __index = function(_, k)
        return { Value = State[k] }
    end,
})

local Library = { Unloaded = false }

local Window

function Library:Notify(t)
    if type(t) ~= "table" then
        return
    end
    pcall(function()
        WindUI:Notify({
            Title = tostring(t.Title or "提示"),
            Content = tostring(t.Description or t.Content or ""),
            Duration = tonumber(t.Time) or 4,
            Type = tostring(t.Type or "Info"),
        })
    end)
end

function Library:OnUnload(fn)
    if type(fn) == "function" then
        table.insert(UnloadHooks, fn)
    end
end

function Library:Unload()
    self.Unloaded = true
    for _, fn in ipairs(UnloadHooks) do
        pcall(fn)
    end
    pcall(function()
        WindUI:Unload()
    end)
    pcall(function()
        Window:Destroy()
    end)
end

local gameName = "Chapter 1 (FARMHOUSE)"

Window = WindUI:CreateWindow({
    Title = "XJW",
    Icon = "wheat",
    Author = "XJW",
    Folder = "XJW_Ouroboros",
    Size = UDim2.fromOffset(430, 470),
    Theme = "Blue",
    HideSearchBar = false,
})

Window:Tag({
    Title = "XJW",
    Color = Color3.fromHex("#3B82F6"),
})

Window:EditOpenButton({
    Title = "寻找针头",
    Icon = "wheat",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("3B82F6")),
    Draggable = true,
})

local Tabs = {
    Collect = Window:Tab({ Title = "采集", Icon = "wheat", Locked = false }),
    Sell = Window:Tab({ Title = "出售", Icon = "coins", Locked = false }),
    Tools = Window:Tab({ Title = "工具", Icon = "hammer", Locked = false }),
    Needle = Window:Tab({ Title = "寻针", Icon = "search", Locked = false }),
    Shop = Window:Tab({ Title = "购买", Icon = "shopping-cart", Locked = false }),
    Upgrade = Window:Tab({ Title = "升级", Icon = "trending-up", Locked = false }),
    Settings = Window:Tab({ Title = "设置", Icon = "settings", Locked = false }),
}

WindUI:Notify({
    Title = "寻找针头",
    Content = "脚本已就绪",
    Duration = 3,
})

local NeedleHaystack = ReplicatedStorage:WaitForChild("NeedleHaystack")
local Config = require(NeedleHaystack:WaitForChild("Config"))
local UpgradeConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Configs"):WaitForChild("UpgradeConfig"))
local BuyUpgrade = NeedleHaystack:WaitForChild("BuyUpgrade")
local BuyShopItem = NeedleHaystack:WaitForChild("BuyShopItem")
local PickHay = NeedleHaystack:WaitForChild("PickHay")
local PickDroppedHay = NeedleHaystack:WaitForChild("PickDroppedHay")
local SellHay = NeedleHaystack:WaitForChild("SellHay")
local CollectGem = NeedleHaystack:WaitForChild("CollectGem")
local DeployDrone = NeedleHaystack:WaitForChild("DeployDrone")
local PitchforkDig = NeedleHaystack:WaitForChild("PitchforkDig")
local TntAction = NeedleHaystack:WaitForChild("TntAction")
local VacuumAction = NeedleHaystack:WaitForChild("VacuumAction")
local NeedleHandIn = NeedleHaystack:WaitForChild("NeedleHandIn")
local BarnShop = Workspace:WaitForChild("BarnShop")
local DroppedHayFolder = Workspace:FindFirstChild("DroppedHay")
local GemsClientFolder = Workspace:FindFirstChild("GemsClient")
local function getCash()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local cash = ls and ls:FindFirstChild("Cash")
    return cash and cash.Value or 0
end
local function getGems()
    return tonumber(LocalPlayer:GetAttribute("Gems")) or 0
end
local function getHayHeld()
    local v = LocalPlayer:GetAttribute("HayHeld")
    if v ~= nil then return tonumber(v) or 0 end
    return #Workspace:FindFirstChild("DroppedHay") and 0 or 0
end
local function getHayCapacity()
    return tonumber(LocalPlayer:GetAttribute("HayCapacity")) or 25
end
local function owns(attr) return LocalPlayer:GetAttribute(attr) == true end
local function findClosestHay()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:GetAttribute("HayId") and inst:IsA("BasePart") and inst.Parent then
            local d = (inst.Position - hrp.Position).Magnitude
            if d < bestDist and d < 30 then
                bestDist = d
                best = inst
            end
        end
    end
    return best
end
local function getGrabCandidates(centerPart)
    local radius = tonumber(LocalPlayer:GetAttribute("HayGrabRadius")) or 0
    if radius <= 0 then return {} end
    local out = {}
    if not centerPart then return out end
    local cp = centerPart.Position
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst ~= centerPart and inst:GetAttribute("HayId") and inst:IsA("BasePart") then
            if (inst.Position - cp).Magnitude <= radius + 1 then
                table.insert(out, inst:GetAttribute("HayId"))
                if #out >= 6 then break end
            end
        end
    end
    return out
end
local function findClosestDropped()
    if not DroppedHayFolder then DroppedHayFolder = Workspace:FindFirstChild("DroppedHay") end
    if not DroppedHayFolder then return nil end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist = nil, 28
    for _, m in ipairs(DroppedHayFolder:GetChildren()) do
        local part = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart")
        if part then
            local d = (part.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best = part.Parent:IsA("BasePart") and part.Parent or m
            end
        end
    end
    return best
end
local function findClosestGem()
    if not GemsClientFolder then GemsClientFolder = Workspace:FindFirstChild("GemsClient") end
    local root = GemsClientFolder or Workspace
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bestDist, bestId = nil, 35, nil
    for _, mdl in ipairs(root:GetDescendants()) do
        if mdl:IsA("BasePart") and mdl:GetAttribute("GemId") then
            local d = (mdl.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best = mdl
                bestId = mdl:GetAttribute("GemId")
            end
        end
    end
    if best and bestId then return best, bestId end
    for _, mdl in ipairs(Workspace:GetDescendants()) do
        if mdl:GetAttribute("GemId") and mdl:IsA("BasePart") then
            local d = (mdl.Position - hrp.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best = mdl
                bestId = mdl:GetAttribute("GemId")
            end
        end
    end
    if best then return best, bestId end
    return nil, nil
end
local function isBagFull()
    return getHayHeld() >= getHayCapacity()
end
local function getNearestSellPart()
    local CollectionService = game:GetService("CollectionService")
    local camPos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position or (LocalPlayer.Character and LocalPlayer.Character:GetPivot().Position or Vector3.new(0,0,0))
    local best, bestDist = nil, math.huge
    for _, part in ipairs(CollectionService:GetTagged(Config.SELL_PART_NAME)) do
        if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
            local d = (part.Position - camPos).Magnitude
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local cd = (part.Position - hrp.Position).Magnitude
                d = math.min(d, cd)
            end
            if d < bestDist then
                bestDist = d
                best = part
            end
        end
    end
    if not best then
        for _, inst in ipairs(workspace.SellModel:GetDescendants()) do
            if inst.Name == "SellPart" and inst:IsA("BasePart") then
                return inst
            end
        end
    end
    return best
end
local function trySell()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local sellPart = getNearestSellPart()
    if hrp and sellPart then
        local dist = (hrp.Position - sellPart.Position).Magnitude
        if dist > 14 then
            local target = sellPart.CFrame + Vector3.new(0, 3, 2)
            hrp.CFrame = target
            if workspace.CurrentCamera then
                workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, sellPart.Position)
            end
            task.wait(0.25)
        else
            if workspace.CurrentCamera then
                pcall(function()
                    workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, sellPart.Position)
                end)
            end
            task.wait(0.05)
        end
    end
    local ok, err = pcall(function() SellHay:FireServer() end)
    if not ok then
        Library:Notify({Title="Sell Failed", Description=tostring(err), Time=2, Type="Error"})
    end
    task.spawn(function()
        local before = getHayHeld()
        task.wait(0.6)
        if before > 0 and getHayHeld() == before and hrp and sellPart then
            hrp.CFrame = sellPart.CFrame + Vector3.new(0, 4, 0)
            task.wait(0.2)
            pcall(function() SellHay:FireServer() end)
        end
    end)
    task.spawn(function()
        task.wait(1.0)
        local needReturn = false
        if Toggles.AutoPickHay and Toggles.AutoPickHay.Value then needReturn = true end
        if Toggles.AutoCollectDroppedHay and Toggles.AutoCollectDroppedHay.Value then needReturn = true end
        if Toggles.AutoCollectGems and Toggles.AutoCollectGems.Value then needReturn = true end
        if Toggles.AutoVacuumCollect and Toggles.AutoVacuumCollect.Value then needReturn = true end
        if Toggles.AutoVacuum and Toggles.AutoVacuum.Value then needReturn = true end
        if Toggles.AutoUsePitchfork and Toggles.AutoUsePitchfork.Value then needReturn = true end
        if Toggles.AutoFindNeedle and Toggles.AutoFindNeedle.Value then needReturn = true end
        if needReturn and getHayHeld() == 0 then
            local pile = Config.PILE_CENTER
            local hrp2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp2 and (hrp2.Position - pile).Magnitude > 22 then
                hrp2.CFrame = CFrame.new(pile + Vector3.new(math.random(-2,2), 5, math.random(-2,2)))
                if workspace.CurrentCamera then
                    workspace.CurrentCamera.CFrame = CFrame.new(hrp2.Position + Vector3.new(0,4,0), pile)
                end
            end
        end
    end)
end

local TabCollect = Tabs.Collect
TabCollect:Section({ Title = "资源采集", TextXAlignment = "Left", TextSize = 17 })
TabCollect:Toggle({ Title = "自动拾取干草", Default = false, Callback = function(v) State.AutoPickHay = v end })
TabCollect:Toggle({ Title = "自动收集掉落干草", Default = false, Callback = function(v) State.AutoCollectDroppedHay = v end })
TabCollect:Toggle({ Title = "自动收集宝石", Default = false, Callback = function(v) State.AutoCollectGems = v end })
TabCollect:Toggle({ Title = "自动吸尘器收集", Default = false, Callback = function(v) State.AutoVacuumCollect = v end })
TabCollect:Slider({
    Title = "循环间隔(秒)",
    Value = { Min = 0.1, Max = 3, Default = 1 },
    Increment = 0.1,
    Callback = function(v) State.CollectInterval = v end,
})

local TabSell = Tabs.Sell
TabSell:Section({ Title = "自动出售", TextXAlignment = "Left", TextSize = 17 })
TabSell:Toggle({ Title = "自动出售干草", Default = false, Callback = function(v) State.AutoSellHay = v end })
TabSell:Slider({
    Title = "持有量达到此值即出售",
    Value = { Min = 1, Max = 250, Default = 25 },
    Increment = 1,
    Callback = function(v) State.SellThreshold = v end,
})
TabSell:Toggle({ Title = "仅在满袋时出售", Default = false, Callback = function(v) State.SellOnlyIfFull = v end })
TabSell:Button({ Title = "立即出售一次", Callback = function() task.spawn(trySell) end })

local TabTools = Tabs.Tools
TabTools:Section({ Title = "自动使用工具", TextXAlignment = "Left", TextSize = 17 })
TabTools:Toggle({ Title = "自动使用 TNT", Default = false, Callback = function(v) State.AutoUseTNT = v end })
TabTools:Toggle({ Title = "自动使用干草叉", Default = false, Callback = function(v) State.AutoUsePitchfork = v end })
TabTools:Toggle({ Title = "自动部署无人机", Default = false, Callback = function(v) State.AutoDeployDrone = v end })
TabTools:Toggle({ Title = "自动吸尘器(循环)", Default = false, Callback = function(v) State.AutoVacuum = v end })
TabTools:Slider({
    Title = "工具间隔(秒)",
    Value = { Min = 0.2, Max = 5, Default = 1 },
    Increment = 0.1,
    Callback = function(v) State.ToolInterval = v end,
})

local TabNeedle = Tabs.Needle
TabNeedle:Section({ Title = "寻针", TextXAlignment = "Left", TextSize = 17 })
TabNeedle:Toggle({ Title = "自动寻针", Default = false, Callback = function(v) State.AutoFindNeedle = v end })
TabNeedle:Toggle({ Title = "自动交付针", Default = false, Callback = function(v) State.AutoHandInNeedle = v end })
TabNeedle:Slider({
    Title = "寻针间隔(秒)",
    Value = { Min = 0.2, Max = 3, Default = 1 },
    Increment = 0.1,
    Callback = function(v) State.NeedleInterval = v end,
})

local TabShop = Tabs.Shop
TabShop:Section({ Title = "购买工具", TextXAlignment = "Left", TextSize = 17 })

local buyOptions = { "Pitchfork", "TNT", "Drone", "Vacuum", "Infinite Bag", "Capacity Bag" }

local function applyBuyList(v)
    local t = {}
    if type(v) == "table" then
        for k, val in pairs(v) do
            if val == true then
                t[k] = true
            elseif type(k) == "number" and type(val) == "string" then
                t[val] = true
            end
        end
    elseif type(v) == "string" then
        t[v] = true
    end
    State.BuyToolsList = t
end

local ddOk = pcall(function()
    TabShop:Dropdown({
        Title = "要购买的工具(可多选)",
        Values = buyOptions,
        Multi = true,
        Callback = applyBuyList,
    })
end)

if not ddOk then
    local buyNames = { "干草叉", "TNT", "无人机", "吸尘器", "无限背包", "容量背包" }
    for i, name in ipairs(buyOptions) do
        TabShop:Toggle({
            Title = "购买: " .. buyNames[i],
            Default = false,
            Callback = function(v)
                local cur = {}
                for k, val in pairs(State.BuyToolsList or {}) do
                    cur[k] = val
                end
                if v then
                    cur[name] = true
                else
                    cur[name] = nil
                end
                State.BuyToolsList = cur
            end,
        })
    end
end

TabShop:Toggle({ Title = "自动购买选中工具", Default = false, Callback = function(v) State.AutoBuyTools = v end })
TabShop:Slider({
    Title = "购买间隔(秒)",
    Value = { Min = 0.5, Max = 5, Default = 1 },
    Increment = 0.1,
    Callback = function(v) State.BuyInterval = v end,
})
TabShop:Button({
    Title = "检查已拥有道具",
    Callback = function()
        local t = {}
        for _, k in ipairs({ "PitchforkOwned", "TntOwned", "DroneOwned", "VacuumOwned", "InfiniteBagOwned", "HayUpgradeCapacity" }) do
            table.insert(t, k .. ": " .. tostring(LocalPlayer:GetAttribute(k)))
        end
        Library:Notify({ Title = "拥有情况", Description = table.concat(t, "\n"), Time = 4 })
    end,
})

local TabUp = Tabs.Upgrade
TabUp:Section({ Title = "永久升级(宝石)", TextXAlignment = "Left", TextSize = 17 })
TabUp:Toggle({ Title = "自动升级背包容量", Default = false, Callback = function(v) State.UpgBagSize = v end })
TabUp:Toggle({ Title = "自动升级手持数量", Default = false, Callback = function(v) State.UpgExtraTake = v end })
TabUp:Toggle({ Title = "自动升级宝石价值", Default = false, Callback = function(v) State.UpgGemValue = v end })
TabUp:Toggle({ Title = "自动升级干草价值", Default = false, Callback = function(v) State.UpgHayValue = v end })
TabUp:Slider({
    Title = "永久升级循环(秒)",
    Value = { Min = 0.5, Max = 5, Default = 1 },
    Increment = 0.1,
    Callback = function(v) State.PermInterval = v end,
})
TabUp:Section({ Title = "手部升级(现金)", TextXAlignment = "Left", TextSize = 17 })
TabUp:Toggle({ Title = "自动升级手速", Default = false, Callback = function(v) State.UpgHandSpeed = v end })
TabUp:Toggle({ Title = "自动升级抓取", Default = false, Callback = function(v) State.UpgHandGrab = v end })
TabUp:Toggle({ Title = "自动升级持握", Default = false, Callback = function(v) State.UpgHandHold = v end })
TabUp:Section({ Title = "TNT 升级", TextXAlignment = "Left", TextSize = 17 })
TabUp:Toggle({ Title = "自动升级幸运爆破", Default = false, Callback = function(v) State.UpgTntLuck = v end })
TabUp:Toggle({ Title = "自动升级冷却", Default = false, Callback = function(v) State.UpgTntCooldown = v end })
TabUp:Toggle({ Title = "自动升级威力", Default = false, Callback = function(v) State.UpgTntPower = v end })
TabUp:Section({ Title = "干草叉升级", TextXAlignment = "Left", TextSize = 17 })
TabUp:Toggle({ Title = "自动升级冷却", Default = false, Callback = function(v) State.UpgPitchCooldown = v end })
TabUp:Toggle({ Title = "自动升级持握", Default = false, Callback = function(v) State.UpgPitchHold = v end })
TabUp:Toggle({ Title = "自动升级挥扫", Default = false, Callback = function(v) State.UpgPitchSweep = v end })
TabUp:Section({ Title = "无人机升级", TextXAlignment = "Left", TextSize = 17 })
TabUp:Toggle({ Title = "自动升级速度", Default = false, Callback = function(v) State.UpgDroneSpeed = v end })
TabUp:Toggle({ Title = "自动升级抓取", Default = false, Callback = function(v) State.UpgDroneGrab = v end })
TabUp:Toggle({ Title = "自动升级容量", Default = false, Callback = function(v) State.UpgDroneCapacity = v end })
TabUp:Section({ Title = "吸尘器升级", TextXAlignment = "Left", TextSize = 17 })
TabUp:Toggle({ Title = "自动升级功率", Default = false, Callback = function(v) State.UpgVacPower = v end })
TabUp:Toggle({ Title = "自动升级散热", Default = false, Callback = function(v) State.UpgVacCooling = v end })
TabUp:Toggle({ Title = "自动升级续航", Default = false, Callback = function(v) State.UpgVacRuntime = v end })
TabUp:Section({ Title = "容量升级", TextXAlignment = "Left", TextSize = 17 })
TabUp:Toggle({ Title = "自动升级携带容量", Default = false, Callback = function(v) State.UpgCapacity = v end })

local TabSet = Tabs.Settings
TabSet:Section({ Title = "系统", TextXAlignment = "Left", TextSize = 17 })
TabSet:Toggle({ Title = "防挂机(每5分钟跳动)", Default = true, Callback = function(v) State.AntiAFK = v end })
TabSet:Toggle({ Title = "重进时通知", Default = false, Callback = function(v) State.AutoRejoin = v end })
TabSet:Section({ Title = "操作", TextXAlignment = "Left", TextSize = 17 })
TabSet:Button({ Title = "卸载脚本", Callback = function() Library:Unload() end })

local function waitInterval(optName, fallback)
    local v = Options[optName] and Options[optName].Value or fallback
    return tonumber(v) or fallback
end
local function ensureNearPileForPick()
    local pile = Config.PILE_CENTER
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local distToPile = (hrp.Position - pile).Magnitude
    if distToPile > 28 then
        hrp.CFrame = CFrame.new(pile + Vector3.new(math.random(-3,3), 5, math.random(-3,3)))
        if workspace.CurrentCamera then
            workspace.CurrentCamera.CFrame = CFrame.new(hrp.Position + Vector3.new(0,4,0), pile)
        end
        task.wait(0.25)
    end
end
local function teleportToPart(part, yOffset)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not part then return end
    local dist = (hrp.Position - part.Position).Magnitude
    if dist > 15 then
        hrp.CFrame = part.CFrame + Vector3.new(0, yOffset or 4, 1.5)
        if workspace.CurrentCamera then
            pcall(function() workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, part.Position) end)
        end
        task.wait(0.18)
    else
        if workspace.CurrentCamera then
            pcall(function() workspace.CurrentCamera.CFrame = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, part.Position) end)
        end
    end
end
task.spawn(function()
    while true do
        task.wait(waitInterval("CollectInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoPickHay and Toggles.AutoPickHay.Value then
            if not isBagFull() then
                local hay = findClosestHay()
                if not hay then
                    ensureNearPileForPick()
                    hay = findClosestHay()
                end
                if hay then
                    teleportToPart(hay, 4)
                    local id = hay:GetAttribute("HayId")
                    if id then
                        local candidates = getGrabCandidates(hay)
                        pcall(function() PickHay:FireServer(id, candidates) end)
                    else
                        pcall(function() PickDroppedHay:FireServer(hay) end)
                    end
                else
                    ensureNearPileForPick()
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(waitInterval("CollectInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoCollectDroppedHay and Toggles.AutoCollectDroppedHay.Value then
            if not isBagFull() then
                local d = findClosestDropped()
                if not d then
                    ensureNearPileForPick()
                    d = findClosestDropped()
                end
                if d then
                    local part = d:IsA("BasePart") and d or d:FindFirstChildWhichIsA("BasePart")
                    if part then teleportToPart(part, 3) end
                    pcall(function() PickDroppedHay:FireServer(d) end)
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(waitInterval("CollectInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoCollectGems and Toggles.AutoCollectGems.Value then
            local gemPart, id = findClosestGem()
            if not gemPart then
                ensureNearPileForPick()
                gemPart, id = findClosestGem()
            end
            if gemPart and id then
                teleportToPart(gemPart, 3)
                pcall(function() CollectGem:FireServer(id) end)
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(waitInterval("SellThreshold",1) and 1 or 1)
        if Library.Unloaded then break end
        if Toggles.AutoSellHay and Toggles.AutoSellHay.Value then
            local held = getHayHeld()
            local thresh = Options.SellThreshold and Options.SellThreshold.Value or 25
            local onlyFull = Toggles.SellOnlyIfFull and Toggles.SellOnlyIfFull.Value
            local should = false
            if onlyFull then should = isBagFull()
            else should = held >= thresh end
            if should and held > 0 then trySell() end
        end
    end
end)
do
    local vacActive = false
    task.spawn(function()
        while true do
            task.wait(waitInterval("CollectInterval",1))
            if Library.Unloaded then break end
            local want = Toggles.AutoVacuumCollect and Toggles.AutoVacuumCollect.Value
            local want2 = Toggles.AutoVacuum and Toggles.AutoVacuum.Value
            local should = want or want2
            if should and owns("VacuumOwned") then
                if not vacActive and not isBagFull() then
                    local hay = findClosestHay()
                    if not hay then ensureNearPileForPick() hay = findClosestHay() end
                    if hay then teleportToPart(hay, 5) end
                    pcall(function() VacuumAction:FireServer("Start") end)
                    vacActive = true
                elseif isBagFull() and vacActive then
                    pcall(function() VacuumAction:FireServer("Stop") end)
                    vacActive = false
                    trySell()
                end
            else
                if vacActive then pcall(function() VacuumAction:FireServer("Stop") end) vacActive=false end
            end
            if vacActive and LocalPlayer:GetAttribute("VacuumOverheated") then
                pcall(function() VacuumAction:FireServer("Stop") end) vacActive=false
                task.wait(0.5)
                ensureNearPileForPick()
            end
        end
    end)
end
task.spawn(function()
    while true do
        task.wait(waitInterval("ToolInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoUseTNT and Toggles.AutoUseTNT.Value and owns("TntOwned") then
            local ok = not LocalPlayer:GetAttribute("NeedleInputLocked")
            if ok then
                pcall(function() TntAction:FireServer("light") end)
                task.wait(0.4)
                local cam = Workspace.CurrentCamera
                if cam then
                    local dir = cam.CFrame.LookVector * 40 + Vector3.new(0,8,0)
                    local cf = cam.CFrame
                    pcall(function() TntAction:FireServer("throw", cf, dir) end)
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(waitInterval("ToolInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoUsePitchfork and Toggles.AutoUsePitchfork.Value and owns("PitchforkOwned") then
            local hay = findClosestHay()
            if not hay then ensureNearPileForPick() hay = findClosestHay() end
            if hay then teleportToPart(hay, 4) end
            local id = hay and hay:GetAttribute("HayId")
            if id then
                pcall(function() PitchforkDig:FireServer(id) end)
            else
                local fakeId = LocalPlayer:GetAttribute("HoveredHayId")
                if fakeId then
                    ensureNearPileForPick()
                    pcall(function() PitchforkDig:FireServer(fakeId) end)
                end
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(waitInterval("ToolInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoDeployDrone and Toggles.AutoDeployDrone.Value and owns("DroneOwned") then
            if not LocalPlayer:GetAttribute("DroneDeployed") then
                pcall(function() DeployDrone:FireServer() end)
            end
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(waitInterval("NeedleInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoFindNeedle and Toggles.AutoFindNeedle.Value then
            if not LocalPlayer:GetAttribute("NeedleRoundComplete") then
                local hay = findClosestHay()
                if not hay then ensureNearPileForPick() hay = findClosestHay() end
                if hay then
                    teleportToPart(hay, 4)
                    local id = hay:GetAttribute("HayId")
                    if id and not isBagFull() then
                        pcall(function() PickHay:FireServer(id, getGrabCandidates(hay)) end)
                    elseif isBagFull() then
                        trySell()
                    end
                else
                    ensureNearPileForPick()
                end
            end
        end
        if Toggles.AutoHandInNeedle and Toggles.AutoHandInNeedle.Value then
            local farmer = workspace:FindFirstChild("NPC") and workspace.NPC:FindFirstChild("Farmer_NPC")
            if farmer and farmer:GetPivot() then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - farmer:GetPivot().Position).Magnitude > 20 then
                    hrp.CFrame = farmer:GetPivot() * CFrame.new(0,0,4)
                    task.wait(0.2)
                end
            end
            pcall(function() NeedleHandIn:FireServer() end)
        end
    end
end)
task.spawn(function()
    while true do
        task.wait(waitInterval("BuyInterval",1))
        if Library.Unloaded then break end
        if Toggles.AutoBuyTools and Toggles.AutoBuyTools.Value then
            local sel = Options.BuyToolsList and Options.BuyToolsList.Value or {}
            local list = {}
            if typeof(sel) == "table" then
                for k,v in pairs(sel) do if v then table.insert(list, k) end end
                if #list==0 then for _,v in ipairs(sel) do table.insert(list, v) end end
            end
            for _, name in ipairs(list) do
                if name == "Pitchfork" and not owns("PitchforkOwned") then pcall(function() BuyShopItem:FireServer("Pitchfork") end)
                elseif name == "TNT" and not owns("TntOwned") then pcall(function() BuyShopItem:FireServer("Tnt") end)
                elseif name == "Drone" and not owns("DroneOwned") then pcall(function() BuyShopItem:FireServer("Drone") end)
                elseif name == "Vacuum" and not owns("VacuumOwned") then pcall(function() BuyShopItem:FireServer("Vacuum") end)
                elseif name == "Infinite Bag" and not owns("InfiniteBagOwned") then pcall(function() BuyShopItem:FireServer("InfiniteBag") end)
                elseif name == "Capacity Bag" then
                    local st = tonumber(LocalPlayer:GetAttribute("HayUpgradeCapacity")) or 1
                    local track = Config.UPGRADE_TRACKS["Capacity"]
                    if track and st < #track.Levels then
                        local cost = track.Levels[st+1].Cost
                        if getCash() >= (cost or 0) then pcall(function() BuyUpgrade:FireServer("Capacity") end) end
                    end
                end
            end
        end
    end
end)
local function tryBuyTrack(trackName)
    local track = Config.UPGRADE_TRACKS[trackName]
    if not track then return end
    local cur = tonumber(LocalPlayer:GetAttribute("HayUpgrade"..trackName)) or 1
    if cur >= #track.Levels then return end
    local nxt = track.Levels[cur+1]
    if not nxt then return end
    local cost = nxt.Cost or 0
    if getCash() >= cost then
        pcall(function() BuyUpgrade:FireServer(trackName) end)
    end
end
local function tryBuyPermanent(id)
    local u = UpgradeConfig.getUpgrade(id)
    if not u then return end
    local cur = tonumber(LocalPlayer:GetAttribute("Upgrade"..id)) or 0
    local max = UpgradeConfig.getMaxLevel(u)
    if cur >= max then return end
    local price = UpgradeConfig.getPrice(u, cur)
    if price and getGems() >= price then
        pcall(function() BuyUpgrade:FireServer(id) end)
    end
end
task.spawn(function()
    while true do
        task.wait(waitInterval("PermInterval",1))
        if Library.Unloaded then break end
        if Toggles.UpgBagSize and Toggles.UpgBagSize.Value then tryBuyPermanent("ExtraHoldAmount") end
        if Toggles.UpgExtraTake and Toggles.UpgExtraTake.Value then tryBuyPermanent("ExtraTakeAmount") end
        if Toggles.UpgGemValue and Toggles.UpgGemValue.Value then tryBuyPermanent("GemValue") end
        if Toggles.UpgHayValue and Toggles.UpgHayValue.Value then tryBuyPermanent("ExtraHayValuePercentage") end
    end
end)
task.spawn(function()
    while true do
        task.wait(1.2)
        if Library.Unloaded then break end
        if Toggles.UpgCapacity and Toggles.UpgCapacity.Value then tryBuyTrack("Capacity") end
        if Toggles.UpgHandSpeed and Toggles.UpgHandSpeed.Value then tryBuyTrack("Speed") end
        if Toggles["UpgHandGrab"] and Toggles["UpgHandGrab"].Value then 
            tryBuyTrack("Grab")
        end
        if Toggles.UpgHandHold and Toggles.UpgHandHold.Value then tryBuyTrack("HandHold") end
        if Toggles.UpgTntLuck and Toggles.UpgTntLuck.Value then tryBuyTrack("TntLuck") end
        if Toggles.UpgTntCooldown and Toggles.UpgTntCooldown.Value then tryBuyTrack("TntCooldown") end
        if Toggles.UpgTntPower and Toggles.UpgTntPower.Value then tryBuyTrack("TntPower") end
        if Toggles.UpgPitchCooldown and Toggles.UpgPitchCooldown.Value then tryBuyTrack("PitchforkCooldown") end
        if Toggles.UpgPitchHold and Toggles.UpgPitchHold.Value then tryBuyTrack("PitchforkHold") end
        if Toggles.UpgPitchSweep and Toggles.UpgPitchSweep.Value then tryBuyTrack("Pitchfork") end
        if Toggles.UpgDroneSpeed and Toggles.UpgDroneSpeed.Value then tryBuyTrack("DroneSpeed") end
        if Toggles.UpgDroneGrab and Toggles.UpgDroneGrab.Value then tryBuyTrack("DroneGrab") end
        if Toggles.UpgDroneCapacity and Toggles.UpgDroneCapacity.Value then tryBuyTrack("DroneCapacity") end
        if Toggles.UpgVacPower and Toggles.UpgVacPower.Value then tryBuyTrack("VacuumPower") end
        if Toggles.UpgVacCooling and Toggles.UpgVacCooling.Value then tryBuyTrack("VacuumCooling") end
        if Toggles.UpgVacRuntime and Toggles.UpgVacRuntime.Value then tryBuyTrack("VacuumRuntime") end
    end
end)
task.spawn(function()
    while true do
        task.wait(300)
        if Library.Unloaded then break end
        if Toggles.AntiAFK and Toggles.AntiAFK.Value then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) hum.Jump = true end
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)
Library:OnUnload(function()
    pcall(function() VacuumAction:FireServer("Stop") end)
    Library.Unloaded = true
    print("[Ouroboros] Unloaded @hidevin - "..gameName)
end)
Library:Notify({ Title = "@hidevin", Description = gameName.." loaded. Farming=collect/sell/tools | Inventory=shop/upgrades", Time = 5, Type = "Success" })
print("[Ouroboros] Loaded "..gameName.." via ObsidianUltra")
