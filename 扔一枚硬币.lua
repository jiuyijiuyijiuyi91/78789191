local WI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()
if not WI then print("[扔硬币] WindUI 失败"); return end

local P = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local C = game:GetService("CoreGui")
local LP = P.LocalPlayer
if not LP then return end

for _, g in ipairs(C:GetChildren()) do
    if g:IsA("ScreenGui") and (g.Name == "A" or g.Name:find("Coin") or g.Name == "WindUI") then
        pcall(function() g:Destroy() end)
    end
end

local Events = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Events")
local CoinLanded = Events and Events:FindFirstChild("CoinLanded")
local RequestUpgrade = Events and Events:FindFirstChild("RequestUpgrade")
local BuyCoin = Events and Events:FindFirstChild("BuyCoin")
local SellAll = Events and Events:FindFirstChild("SellAll")

local S = {
    AutoThrow = false, AutoBuyCoin = false, AutoUpgradeLuck = false,
    AutoUpgradeValue = false, AutoSell = false, Speed = false, Fly = false,
    ThrowMultiplier = 3, SpeedVal = 50, FlySpeed = 50
}

local WN, WN_visible = nil, false
local UI = {}
local toggleKey = Enum.KeyCode.F4
local toggleLock = 0
local coinDebounce, sellDebounce, luckDebounce, valDebounce = 0, 0, 0, 0
local flyBV2, flyGyro2, flyCtrl, flyHeartbeat2 = nil, nil, nil, nil
local coinList = {"Paradox Coin", "Lucky Coin", "Golden Coin", "Obsidian Coin", "Platinum Coin", "Ruby Coin", "Emerald Coin", "Amethyst Coin", "Topaz Coin", "Diamond Coin", "Staff Token", "VIP Token", "Developer Token", "Diamond Token"}

local function flipToggle(flag)
    S[flag] = not S[flag]
    if UI[flag] and type(UI[flag].Set) == "function" then pcall(function() UI[flag]:Set(S[flag]) end) end
    return S[flag]
end

local function getCoinName()
    local pg = LP:FindFirstChild("PlayerGui")
    local n = pg and pg:FindFirstChild("UiFolder") and pg.UiFolder:FindFirstChild("Main")
        and pg.UiFolder.Main:FindFirstChild("HUD") and pg.UiFolder.Main.HUD:FindFirstChild("Coin")
        and pg.UiFolder.Main.HUD.Coin:FindFirstChild("Main") and pg.UiFolder.Main.HUD.Coin.Main:FindFirstChild("CoinName")
    if n and n:IsA("TextLabel") and n.Text ~= "" then return n.Text end
    return nil
end

local function getMultiplier()
    local pg = LP:FindFirstChild("PlayerGui")
    local tb = pg and pg:FindFirstChild("UiFolder") and pg.UiFolder:FindFirstChild("Main")
        and pg.UiFolder.Main:FindFirstChild("HUD") and pg.UiFolder.Main.HUD:FindFirstChild("ThrowBar")
        and pg.UiFolder.Main.HUD.ThrowBar:FindFirstChild("CurrentMulti")
    if tb and tb:IsA("Frame") then return tb.Size.X.Scale * 3 end
    return 0
end

local function getHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function formatNum(v)
    if v == math.floor(v) then return tostring(math.floor(v)) end
    return string.format("%.1f", v)
end

local function doThrow()
    if not S.AutoThrow or not CoinLanded then return end
    if getMultiplier() < S.ThrowMultiplier then return end
    local coinName = getCoinName()
    if not coinName then return end
    local hrp = getHRP()
    if not hrp then return end
    local pos = hrp.Position + Vector3.new(0, -0.5, -2)
    CoinLanded:FireServer(S.ThrowMultiplier, pos, coinName, nil, nil)
    task.wait(0.5)
end

local function doBuyCoin()
    if not S.AutoBuyCoin or not BuyCoin then return end
    if tick() - coinDebounce < 3 then return end
    if getCoinName() then return end
    coinDebounce = tick()
    for _, name in ipairs(coinList) do
        pcall(function() BuyCoin:FireServer(name) end)
        task.wait(0.1)
    end
end

local function doUpgradeLuck()
    if not S.AutoUpgradeLuck or not RequestUpgrade then return end
    if tick() - luckDebounce < 1 then return end
    luckDebounce = tick()
    pcall(function() RequestUpgrade:FireServer("Luck Multiplier") end)
end

local function doUpgradeValue()
    if not S.AutoUpgradeValue or not RequestUpgrade then return end
    if tick() - valDebounce < 1 then return end
    valDebounce = tick()
    pcall(function() RequestUpgrade:FireServer("Value Multiplier") end)
end

local function doSell()
    if not S.AutoSell or not SellAll then return end
    if tick() - sellDebounce < 2 then return end
    sellDebounce = tick()
    SellAll:FireServer()
end

local function toggleFly(on)
    if flyHeartbeat2 then flyHeartbeat2:Disconnect(); flyHeartbeat2 = nil end
    if flyBV2 then flyBV2:Destroy(); flyBV2 = nil end
    if flyGyro2 then flyGyro2:Destroy(); flyGyro2 = nil end
    local c = LP.Character
    if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    if on then
        h.PlatformStand = true
        flyCtrl = {f = 0, b = 0, l = 0, r = 0}
        local torso = c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
        if not torso then return end
        flyGyro2 = Instance.new("BodyGyro", torso)
        flyGyro2.P = 9e4
        flyGyro2.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyGyro2.CFrame = workspace.CurrentCamera.CoordinateFrame
        flyBV2 = Instance.new("BodyVelocity", torso)
        flyBV2.Velocity = Vector3.new(0, 0.1, 0)
        flyBV2.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        local speed = 0
        flyHeartbeat2 = game:GetService("RunService").RenderStepped:Connect(function()
            if not S.Fly or not LP.Character then return end
            flyCtrl = {f = 0, b = 0, l = 0, r = 0}
            if UIS:IsKeyDown(Enum.KeyCode.W) then flyCtrl.f = 1 end
            if UIS:IsKeyDown(Enum.KeyCode.S) then flyCtrl.b = 1 end
            if UIS:IsKeyDown(Enum.KeyCode.A) then flyCtrl.l = 1 end
            if UIS:IsKeyDown(Enum.KeyCode.D) then flyCtrl.r = 1 end
            local v = (flyCtrl.f + flyCtrl.b)
            local h2 = (flyCtrl.l + flyCtrl.r)
            local ms = S.FlySpeed
            if v ~= 0 or h2 ~= 0 then
                speed = speed + 0.5 + (speed / ms)
                if speed > ms then speed = ms end
            elseif speed ~= 0 then
                speed = speed - 1
                if speed < 0 then speed = 0 end
            end
            local cf = workspace.CurrentCamera.CoordinateFrame
            if v ~= 0 or h2 ~= 0 then
                flyBV2.Velocity = (cf.LookVector * v + ((cf * CFrame.new(h2, v * 0.2, 0).p) - cf.p)) * speed
            elseif speed ~= 0 then
                flyBV2.Velocity = (cf.LookVector * (flyCtrl.f + flyCtrl.b) + ((cf * CFrame.new(flyCtrl.l + flyCtrl.r, (flyCtrl.f + flyCtrl.b) * 0.2, 0).p) - cf.p)) * speed
            else
                flyBV2.Velocity = Vector3.new(0, 0, 0)
            end
            flyGyro2.CFrame = cf * CFrame.Angles(-math.rad(v * 50 * speed / ms), 0, 0)
            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                local hr = c:FindFirstChild("HumanoidRootPart")
                if hr then hr.CFrame = hr.CFrame * CFrame.new(0, 1, 0) end
            end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                local hr = c:FindFirstChild("HumanoidRootPart")
                if hr then hr.CFrame = hr.CFrame * CFrame.new(0, -1, 0) end
            end
        end)
    else
        h.PlatformStand = false
    end
end

local function addToggle(tab, flag, title, onChange)
    local obj
    local ok = pcall(function()
        obj = tab:Toggle({
            Title = title,
            Value = false,
            Callback = function(v)
                local nv
                if type(v) == "boolean" then nv = v else nv = not S[flag] end
                S[flag] = nv
                if onChange then pcall(onChange, nv) end
            end,
        })
    end)
    if ok and obj then
        UI[flag] = obj
        return
    end
    pcall(function()
        obj = tab:Button({
            Title = title,
            Callback = function()
                local nv = flipToggle(flag)
                if onChange then pcall(onChange, nv) end
                pcall(function() WI:Notify({Title = title, Content = (nv and "开" or "关"), Duration = 2}) end)
            end,
        })
    end)
    if obj then UI[flag] = obj end
end

local function addSlider(tab, flag, title, min, max, def, step, onChange)
    local obj
    local ok = pcall(function()
        obj = tab:Slider({Title = title, Min = min, Max = max, Step = step or 1, Value = def, Callback = function(v) S[flag] = v; if onChange then pcall(onChange, v) end end})
    end)
    if ok and obj then UI[flag] = obj; return end
    pcall(function()
        obj = tab:Slider({Title = title, Value = {Min = min, Max = max, Default = def}, Callback = function(v) S[flag] = v; if onChange then pcall(onChange, v) end end})
    end)
    if obj then UI[flag] = obj; return end
    pcall(function()
        obj = tab:Dropdown({Title = title, Values = {tostring(min), tostring(math.floor((min + max) / 2)), tostring(max)}, Value = tostring(def), Callback = function(v) S[flag] = tonumber(v) or def; if onChange then pcall(onChange, S[flag]) end end})
    end)
    if obj then UI[flag] = obj end
end

local function addSection(tab, title)
    pcall(function() tab:Section({Title = title, TextXAlignment = "Left", TextSize = 17}) end)
end

local function mW()
    WN = WI:CreateWindow({
        Title = "XJW",
        Author = "扔一枚硬币",
        Icon = "solar:coin-bold",
        Size = UDim2.fromOffset(500, 560),
        Folder = "CoinTossXJW",
        Theme = "Light",
        HideSearchBar = false,
        OnClose = function()
            toggleFly(false)
            S.AutoThrow = false; S.AutoBuyCoin = false
            S.AutoUpgradeLuck = false; S.AutoUpgradeValue = false
            S.AutoSell = false; S.Speed = false; S.Fly = false
            WN_visible = false
            for _, ct in pairs(UI) do
                if ct and type(ct.Set) == "function" then pcall(function() ct:Set(false) end) end
            end
        end,
        OnOpen = function()
            WN_visible = true
        end,
    })
    WN_visible = true

    local t1
    pcall(function() t1 = WN:Tab({Title = "功能", Icon = "solar:slider-vertical-bold"}) end)
    if t1 then
        addSection(t1, "投币")
        addToggle(t1, "AutoThrow", "最佳投币")
        addToggle(t1, "AutoBuyCoin", "自动购买硬币")
        addSection(t1, "升级")
        addToggle(t1, "AutoUpgradeLuck", "升级 (运气)")
        addToggle(t1, "AutoUpgradeValue", "升级 (钱倍率)")
        addSection(t1, "出售")
        addToggle(t1, "AutoSell", "自动出售")
    end
end

task.spawn(function()
    while true do
        if S.Speed then
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = S.SpeedVal end
        end
        if S.AutoThrow then pcall(doThrow) end
        if S.AutoBuyCoin then pcall(doBuyCoin) end
        if S.AutoUpgradeLuck then pcall(doUpgradeLuck) end
        if S.AutoUpgradeValue then pcall(doUpgradeValue) end
        if S.AutoSell then pcall(doSell) end
        task.wait(0.2)
    end
end)

task.spawn(function()
    local ok, err = pcall(mW)
    if not ok then warn("[扔硬币] UI 构建异常: " .. tostring(err)) end
end)

pcall(function() WI:SetTheme("Light") end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode ~= toggleKey then return end
    local now = tick()
    if now - toggleLock < 0.3 then return end
    toggleLock = now
    if not WN then return end
    if WN_visible then
        WN_visible = false; pcall(function() WN:Close() end)
    else
        WN_visible = true; pcall(function() WN:Open() end)
    end
end)

LP.CharacterAdded:Connect(function(nc)
    task.wait(1)
    local h = nc:FindFirstChildOfClass("Humanoid")
    if S.Fly then toggleFly(true) end
    if S.Speed and h then h.WalkSpeed = S.SpeedVal end
end)
