--[[
Build A Plane 刷钱+购物 合体脚本（WindUI / 手机可用）
页签1「刷钱」：高空巡航真实飞行结算（v2 唯一可到账路线），自动循环领钱。
页签2「购物」：零件/装备清单逐项勾选，购买已选或自动购买。
界面只显示中文名，不显示英文 ID。
使用：手机注入器进游戏后执行，两个功能各自独立开关。
警告：违反 Roblox 服务条款，封号风险，建议小号。
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- ===== 加载 WindUI =====
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()
end)
if not ok then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Build A Plane", Text = "UI库加载失败: " .. tostring(WindUI)
    })
    return
end

-- ================= 刷钱相关 =================
local SET = {
    ALTITUDE   = 600,   -- 巡航高度
    STALL_TIME = 4,     -- 停滞判定秒数
    LOOP_DELAY = 4,     -- 每轮间隔
}

local LaunchEvents = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("LaunchEvents")
local LaunchRemote = LaunchEvents:WaitForChild("Launch")
local ReturnRemote = LaunchEvents:WaitForChild("Return")

local cashValue = nil
pcall(function()
    local ls = player:WaitForChild("leaderstats", 5)
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            if v:IsA("NumberValue") or v:IsA("IntValue") then
                cashValue = v
                break
            end
        end
    end
end)

local function getCash()
    return cashValue and cashValue.Value or -1
end

local function getRoot()
    local c = player.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        return c.HumanoidRootPart
    end
    return nil
end

local function holdAltitude(root)
    local cf = root.CFrame
    local p = cf.Position
    if p.Y < SET.ALTITUDE then
        root.CFrame = cf + Vector3.new(0, SET.ALTITUDE - p.Y, 0)
    end
end

local function oneRun()
    pcall(function() LaunchRemote:FireServer() end)
    task.wait(1.5)
    local root = getRoot()
    if not root then
        return 0, getCash()
    end
    local lastX = root.Position.X
    local lastMoveAt = os.clock()
    local runStartCash = getCash()
    while getgenv().BuildAPlaneFarmRunning do
        task.wait(0.5)
        root = getRoot()
        if not root then break end
        holdAltitude(root)
        local x = root.Position.X
        if x - lastX < 1 then
            if os.clock() - lastMoveAt > SET.STALL_TIME then
                break
            end
        else
            lastX = x
            lastMoveAt = os.clock()
        end
    end
    pcall(function() ReturnRemote:FireServer() end)
    task.wait(1.2)
    local endCash = getCash()
    local earned = 0
    if cashValue then
        earned = endCash - runStartCash
    end
    return earned, endCash
end

local function farmLoop(statusTag)
    local n = 0
    while getgenv().BuildAPlaneFarmRunning do
        n = n + 1
        local earned, cash = oneRun()
        if statusTag then
            statusTag:SetTitle("现金 " .. tostring(cash) .. "  |  第" .. n .. "轮 +" .. tostring(earned))
        end
        task.wait(SET.LOOP_DELAY)
    end
end

-- ================= 购物相关 =================
local BuyBlock = nil
pcall(function()
    BuyBlock = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShopEvents"):WaitForChild("BuyBlock")
end)
if not BuyBlock then
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == "BuyBlock" then
            BuyBlock = v
            break
        end
    end
end

local KNOWN_PARTS = {
    "block_1", "block_2", "block_3",
    "half_block", "reinforced_block", "glass_block", "metal_block", "titanium_block",
    "wing_1", "wing_2", "wing_3", "better_wing", "delta_wing",
    "tail_1", "better_tail", "titanium_tail",
    "fuel_1", "fuel_2", "fuel_3", "better_fuel", "barrel_fuel", "refined_fuel",
    "propeller_1", "propeller_2", "propeller_3", "better_propeller",
    "op_propeller", "helicopter_propeller",
    "seat_1", "landing_gears",
    "balloon", "balloon_deployer", "boost_1", "rocket_booster", "plasma_booster",
    "missile_1", "futuristic_missile", "shield",
}

local KNOWN_EQUIPS = {
    "paintbrush", "sign", "wrench",
}

local ITEM_CN = {
    block_1 = "方块", block_2 = "方块2", block_3 = "方块3",
    half_block = "半方块", reinforced_block = "强化方块",
    glass_block = "玻璃方块", metal_block = "金属方块", titanium_block = "钛方块",
    wing_1 = "机翼", wing_2 = "机翼2", wing_3 = "机翼3",
    better_wing = "优质机翼", delta_wing = "三角翼",
    tail_1 = "尾翼", better_tail = "优质尾翼", titanium_tail = "钛尾翼",
    fuel_1 = "燃料箱", fuel_2 = "燃料箱2", fuel_3 = "燃料箱3",
    better_fuel = "优质燃料", barrel_fuel = "桶装燃料", refined_fuel = "精炼燃料",
    propeller_1 = "螺旋桨", propeller_2 = "螺旋桨2", propeller_3 = "螺旋桨3",
    better_propeller = "优质螺旋桨", op_propeller = "最强螺旋桨",
    helicopter_propeller = "直升机螺旋桨",
    seat_1 = "座椅", landing_gears = "起落架",
    balloon = "气球", balloon_deployer = "气球部署器",
    boost_1 = "推进器", rocket_booster = "火箭推进器", plasma_booster = "等离子推进器",
    missile_1 = "导弹", futuristic_missile = "未来导弹",
    shield = "能量护盾",
    paintbrush = "油漆刷", sign = "标志", wrench = "扳手",
}

local function displayName(nm)
    return ITEM_CN[nm] or nm
end

local cart = getgenv().BuildAPlaneCart3
if type(cart) ~= "table" then
    cart = {}
    getgenv().BuildAPlaneCart3 = cart
end

local function buyOne(itemName)
    return pcall(function()
        BuyBlock:FireServer(itemName)
    end)
end

local function buyList(list, statusTag, tagPrefix)
    local bought, failed = 0, 0
    for _, nm in ipairs(list) do
        if buyOne(nm) then
            bought = bought + 1
        else
            failed = failed + 1
        end
        task.wait(0.1)
    end
    if statusTag then
        statusTag:SetTitle(tagPrefix .. "本次购买 " .. tostring(bought) .. " 件  |  失败 " .. tostring(failed))
    end
    WindUI:Notify({ Title = "购买完成", Content = "成功 " .. tostring(bought) .. " 件，失败 " .. tostring(failed) .. " 件", Duration = 4 })
end

local function buySelected(statusTag)
    local list = {}
    for nm, on in pairs(cart) do
        if on then table.insert(list, nm) end
    end
    buyList(list, statusTag, "[已选] ")
end

local function autoBuySelectedLoop(statusTag)
    local rounds = 0
    while getgenv().BuildAPlaneAutoCart3 do
        rounds = rounds + 1
        local list = {}
        for nm, on in pairs(cart) do
            if on then table.insert(list, nm) end
        end
        local bought = 0
        for _, nm in ipairs(list) do
            if not getgenv().BuildAPlaneAutoCart3 then break end
            if buyOne(nm) then bought = bought + 1 end
            task.wait(0.1)
        end
        if statusTag then
            statusTag:SetTitle("第" .. tostring(rounds) .. "轮 已购 " .. tostring(bought) .. " / 选中 " .. tostring(#list))
        end
        task.wait(5)
    end
end

-- ================= 加速相关（改螺旋桨推进力，NXP 验证过的有效方案） =================
local PROPS = { "propeller_0", "propeller_1", "propeller_2", "propeller_3", "propeller_blood" }
local BlockInfo = nil
local origPropForce = nil
pcall(function()
    local mods = ReplicatedStorage:FindFirstChild("Modules")
    if mods and mods:FindFirstChild("Utilities") then
        local mu = mods.Utilities
        if mu:FindFirstChild("BlocksUtil") then
            local BLK = require(mu.BlocksUtil)
            BlockInfo = BLK and BLK.BlockInfo
        end
    end
end)

local boostSpeed = 150
local boostOn = false

local function setPropForce(v)
    if not BlockInfo then return false end
    for _, p in ipairs(PROPS) do
        local bd = BlockInfo[p]
        if bd then
            bd.Force = v
        end
    end
    return true
end

local function storeOrigForce()
    origPropForce = {}
    if not BlockInfo then return end
    for _, p in ipairs(PROPS) do
        local bd = BlockInfo[p]
        if bd then
            origPropForce[p] = bd.Force
        end
    end
end

local function restoreOrigForce()
    if not BlockInfo or not origPropForce then return end
    for p, v in pairs(origPropForce) do
        local bd = BlockInfo[p]
        if bd then bd.Force = v end
    end
    origPropForce = nil
end

-- ================= UI =================
local Window = WindUI:CreateWindow({
    Title = "XJW",
    Icon = "sparkles",
    Author = "建造飞机",
    Folder = "BuildAPlane",
    Size = UDim2.fromOffset(400, 500),
    Theme = "Dark",
    HideSearchBar = false,
})

local StatusTag = Window:Tag({
    Title = "现金 " .. tostring(getCash()),
    Color = Color3.fromRGB(255, 255, 255)
})

Window:Tag({ Title = "建造飞机", Color = Color3.fromHex("#7FDBFF") })

-- ===== 页签1：刷钱 =====
local farmTab = Window:Tab({ Title = "刷钱", Icon = "settings" })
local farmSec = farmTab:Section({ Title = "刷钱控制", TextXAlignment = "Left", TextSize = 17 })

farmSec:Toggle({
    Title = "自动刷钱",
    Default = false,
    Callback = function(state)
        getgenv().BuildAPlaneFarmRunning = state
        if state then
            task.spawn(farmLoop, StatusTag)
            WindUI:Notify({ Title = "已启动", Content = "高空巡航刷钱开始", Duration = 3 })
        else
            WindUI:Notify({ Title = "已停止", Content = "刷钱循环已停止", Duration = 3 })
        end
    end
})

farmSec:Slider({
    Title = "巡航高度",
    Value = { Min = 300, Max = 1500, Default = SET.ALTITUDE },
    Increment = 50,
    Callback = function(v)
        SET.ALTITUDE = v
    end
})

farmSec:Slider({
    Title = "熄火判定(秒)",
    Value = { Min = 1, Max = 10, Default = SET.STALL_TIME },
    Increment = 1,
    Callback = function(v)
        SET.STALL_TIME = v
    end
})

farmSec:Slider({
    Title = "循环间隔(秒)",
    Value = { Min = 1, Max = 10, Default = SET.LOOP_DELAY },
    Increment = 1,
    Callback = function(v)
        SET.LOOP_DELAY = v
    end
})

farmSec:Button({
    Title = "手动结算",
    Callback = function()
        pcall(function() ReturnRemote:FireServer() end)
        WindUI:Notify({ Title = "已结算", Content = "已请求 Return 结算", Duration = 3 })
    end
})

-- ===== 移速加速（改螺旋桨推进力，起飞后生效） =====
farmSec:Toggle({
    Title = "移速加速",
    Default = false,
    Callback = function(state)
        boostOn = state
        if state then
            if not BlockInfo then
                WindUI:Notify({ Title = "错误", Content = "未找到BlocksUtil，加速不可用", Duration = 4 })
                return
            end
            storeOrigForce()
            setPropForce(boostSpeed)
            WindUI:Notify({ Title = "已启动", Content = "螺旋桨推力已提升，起飞后生效", Duration = 3 })
        else
            restoreOrigForce()
            WindUI:Notify({ Title = "已停止", Content = "螺旋桨推力已恢复", Duration = 3 })
        end
    end
})

farmSec:Slider({
    Title = "移速值",
    Value = { Min = 60, Max = 400, Default = boostSpeed },
    Increment = 10,
    Callback = function(v)
        boostSpeed = v
        if boostOn and BlockInfo then
            setPropForce(v)
        end
    end
})

-- ===== 页签2：购物 =====
local shopTab = Window:Tab({ Title = "购物", Icon = "settings" })

local opSection = shopTab:Section({ Title = "操作", TextXAlignment = "Left", TextSize = 17 })

opSection:Toggle({
    Title = "自动购买已选",
    Default = false,
    Callback = function(state)
        getgenv().BuildAPlaneAutoCart3 = state
        if state then
            task.spawn(autoBuySelectedLoop, StatusTag)
            WindUI:Notify({ Title = "已启动", Content = "自动购买已选物品", Duration = 3 })
        else
            WindUI:Notify({ Title = "已停止", Content = "自动购买已停止", Duration = 3 })
        end
    end
})

opSection:Button({
    Title = "购买已选物品",
    Callback = function()
        task.spawn(buySelected, StatusTag)
    end
})

local itemToggles = {}

local function buildListSection(sectionTitle, list)
    local sec = shopTab:Section({ Title = sectionTitle, TextXAlignment = "Left", TextSize = 15 })
    for _, nm in ipairs(list) do
        local tg = sec:Toggle({
            Title = displayName(nm),
            Default = cart[nm] == true,
            Callback = function(state)
                cart[nm] = state
            end
        })
        itemToggles[nm] = tg
    end
    sec:Button({
        Title = "全选本区",
        Callback = function()
            for _, nm in ipairs(list) do
                cart[nm] = true
                local tg = itemToggles[nm]
                if tg then pcall(function() tg:SetValue(true) end) end
            end
            StatusTag:SetTitle("已全选: " .. sectionTitle)
        end
    })
    sec:Button({
        Title = "清空本区",
        Callback = function()
            for _, nm in ipairs(list) do
                cart[nm] = false
                local tg = itemToggles[nm]
                if tg then pcall(function() tg:SetValue(false) end) end
            end
            StatusTag:SetTitle("已清空: " .. sectionTitle)
        end
    })
end

buildListSection("零件（37 种）", KNOWN_PARTS)
buildListSection("装备（3 种）", KNOWN_EQUIPS)

print("[Build A Plane 刷钱+购物合体] 已生成，请切页签使用")
