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
        t.Name = "Green"
        t.Accent = Color3.fromHex("#0B1A10")
        t.Dialog = Color3.fromHex("#0F2417")
        t.Outline = Color3.fromHex("#22C55E")
        t.Text = Color3.fromHex("#FFFFFF")
        t.Placeholder = Color3.fromHex("#86EFAC")
        t.Background = Color3.fromHex("#07120B")
        t.Button = Color3.fromHex("#16A34A")
        t.Icon = Color3.fromHex("#4ADE80")
        t.Toggle = Color3.fromHex("#16A34A")
        t.Slider = Color3.fromHex("#22C55E")
        t.Checkbox = Color3.fromHex("#22C55E")
        t.SliderIcon = Color3.fromHex("#86EFAC")
        t.Primary = Color3.fromHex("#22C55E")
        t.ElementBackground = Color3.fromHex("#11291A")
        t.ElementBackgroundTransparency = 0
        WindUI.Themes.Green = t
    end
end)

local State = {
    AutoAttack = false,
    ESP = false,
    AimBot = false,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

_G.KillAllSettings = {
    FireRateDelay = 0.04,
    TargetPart = "Head",
    PanicHealthThreshold = 40
}

local CurrentShotTargets = {}
local DeagleController = nil

pcall(function()
    local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
    DeagleController = require(PlayerScripts:WaitForChild("ModuleLoader"):WaitForChild("DeagleController"))
end)

local function IsAliveAndValid(model)
    if not model or not model:IsA("Model") or model == LocalPlayer.Character then return false end
    local hum = model:FindFirstChildWhichIsA("Humanoid")
    if not hum or hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then return false end

    local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
    if not rootPart then return false end

    if model:FindFirstChild("Dead") or model:GetAttribute("IsDead") == true then return false end
    return true
end

local function GetAllPotentialTargets()
    local targets = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and IsAliveAndValid(player.Character) then
            if player.Team and player.Team == LocalPlayer.Team then continue end
            table.insert(targets, player.Character)
        end
    end

    local queue = {workspace}
    while #queue > 0 do
        local current = table.remove(queue, 1)
        for _, child in ipairs(current:GetChildren()) do
            if child:IsA("Model") and IsAliveAndValid(child) then
                if not table.find(targets, child) then
                    local p = Players:GetPlayerFromCharacter(child)
                    if not p then
                        table.insert(targets, child)
                    end
                end
            elseif child:IsA("Folder") or child.Name:lower():find("bot") or child.Name:lower():find("npc") then
                table.insert(queue, child)
            end
        end
    end

    return targets
end

local function IsTargetVisible(targetPart, myRootPart)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    raycastParams.IgnoreWater = true

    local origin = myRootPart.Position
    local direction = targetPart.Position - origin

    local result = workspace:Raycast(origin, direction, raycastParams)
    return result == nil
end

local function GetPredictedPosition(targetPart)
    local character = targetPart.Parent
    local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")

    if rootPart and rootPart:IsA("BasePart") then
        local velocity = rootPart.AssemblyLinearVelocity
        local ping = LocalPlayer:GetNetworkPing() or 0.03

        local predictionCompensation = velocity * (ping * 1.85)

        return targetPart.Position + predictionCompensation
    end

    return targetPart.Position
end

local function ExecuteAutomatedSweep()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
    local myHum = myChar and myChar:FindFirstChildWhichIsA("Humanoid")
    if not myChar or not myRoot or not myHum or not DeagleController then return end

    local isVulnerable = (myHum.Health / myHum.MaxHealth * 100) <= _G.KillAllSettings.PanicHealthThreshold

    if typeof(DeagleController) == "table" then
        DeagleController.ShootCooldownUntil = 0
        DeagleController.CanShoot = true
        DeagleController.CurrentSpread = 0
        if DeagleController.WeaponStats then
            DeagleController.WeaponStats.Spread = 0
        end
    end

    table.clear(CurrentShotTargets)
    local activePool = GetAllPotentialTargets()

    table.sort(activePool, function(a, b)
        local rootA = a:FindFirstChild("HumanoidRootPart") or a:FindFirstChild("Torso")
        local rootB = b:FindFirstChild("HumanoidRootPart") or b:FindFirstChild("Torso")
        if rootA and rootB then
            return (myRoot.Position - rootA.Position).Magnitude < (myRoot.Position - rootB.Position).Magnitude
        end
        return false
    end)

    if isVulnerable then
        local targetFound = false
        for _, child in ipairs(activePool) do
            local targetPart = child:FindFirstChild(_G.KillAllSettings.TargetPart) or child:FindFirstChild("Head")
            if targetPart and IsTargetVisible(targetPart, myRoot) then
                CurrentShotTargets[targetPart] = true

                local aimPosition = GetPredictedPosition(targetPart)

                pcall(function()
                    if typeof(DeagleController.Shoot) == "function" then
                        DeagleController.Shoot(aimPosition)
                    elseif typeof(DeagleController.Fire) == "function" then
                        DeagleController.Fire(aimPosition)
                    end
                end)
                targetFound = true
                break
            end
        end

        if not targetFound then
            for _, child in ipairs(activePool) do
                local targetPart = child:FindFirstChild(_G.KillAllSettings.TargetPart) or child:FindFirstChild("Head")
                if targetPart then
                    CurrentShotTargets[targetPart] = true

                    local aimPosition = GetPredictedPosition(targetPart)

                    pcall(function()
                        if typeof(DeagleController.Shoot) == "function" then
                            DeagleController.Shoot(aimPosition)
                        elseif typeof(DeagleController.Fire) == "function" then
                            DeagleController.Fire(aimPosition)
                        end
                    end)
                    break
                end
            end
        end
    else
        for _, child in ipairs(activePool) do
            local targetPart = child:FindFirstChild(_G.KillAllSettings.TargetPart) or child:FindFirstChild("Head")
            if targetPart then
                CurrentShotTargets[targetPart] = true

                local aimPosition = GetPredictedPosition(targetPart)

                pcall(function()
                    if typeof(DeagleController.Shoot) == "function" then
                        DeagleController.Shoot(aimPosition)
                    elseif typeof(DeagleController.Fire) == "function" then
                        DeagleController.Fire(aimPosition)
                    end
                end)
            end
        end
    end
end

local success, DeagleShared = pcall(function()
    return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("DeagleShared"))
end)

if success and DeagleShared and DeagleShared.Raycast then
    local oldRaycast = DeagleShared.Raycast
    DeagleShared.Raycast = function(p1, p2, p3, ...)
        for targetPart, _ in pairs(CurrentShotTargets) do
            if targetPart and targetPart.Parent and IsAliveAndValid(targetPart.Parent) then
                return {
                    Instance = targetPart,
                    Position = GetPredictedPosition(targetPart),
                    Normal = Vector3.new(0, 1, 0),
                    Material = Enum.Material.Plastic
                }
            end
        end
        return oldRaycast(p1, p2, p3, ...)
    end
end

task.spawn(function()
    while true do
        task.wait(_G.KillAllSettings.FireRateDelay)
        if State.AutoAttack then
            pcall(ExecuteAutomatedSweep)
        end
    end
end)

local espCache = {}

local function updateESP()
    local alive = {}
    for _, model in ipairs(GetAllPotentialTargets()) do
        alive[model] = true
        local hl = espCache[model]
        if not hl or not hl.Parent then
            hl = Instance.new("Highlight")
            hl.Name = "DGR_ESP"
            hl.FillColor = Color3.fromHex("#22C55E")
            hl.OutlineColor = Color3.fromHex("#86EFAC")
            hl.FillTransparency = 0.6
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = model
            espCache[model] = hl
        end
    end
    for model, hl in pairs(espCache) do
        if not alive[model] or not model.Parent then
            pcall(function()
                hl:Destroy()
            end)
            espCache[model] = nil
        end
    end
end

local function clearESP()
    for _, hl in pairs(espCache) do
        pcall(function()
            hl:Destroy()
        end)
    end
    espCache = {}
end

task.spawn(function()
    while true do
        task.wait(0.4)
        if State.ESP then
            pcall(updateESP)
        elseif next(espCache) then
            clearESP()
        end
    end
end)

task.spawn(function()
    while true do
        RunService.RenderStepped:Wait()
        if State.AimBot then
            pcall(function()
                local cam = workspace.CurrentCamera
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not cam or not myRoot then
                    return
                end
                local best, bestDist = nil, math.huge
                for _, model in ipairs(GetAllPotentialTargets()) do
                    local part = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
                    if part then
                        local d = (part.Position - myRoot.Position).Magnitude
                        if d < bestDist then
                            bestDist = d
                            best = part
                        end
                    end
                end
                if best then
                    cam.CFrame = CFrame.new(cam.CFrame.Position, GetPredictedPosition(best))
                end
            end)
        end
    end
end)

local Window = WindUI:CreateWindow({
    Title = "迪格尔竞技场",
    Icon = "crosshair",
    Author = "XJW",
    Folder = "DGR_Arena",
    Size = UDim2.fromOffset(380, 400),
    Theme = "Green",
    HideSearchBar = false,
})

Window:Tag({
    Title = "迪格尔竞技场",
    Color = Color3.fromHex("#22C55E"),
})

Window:EditOpenButton({
    Title = "迪格尔竞技场",
    Icon = "crosshair",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("22C55E")),
    Draggable = true,
})

local TabAttack = Window:Tab({ Title = "自动攻击", Icon = "sword", Locked = false })
local TabESP = Window:Tab({ Title = "全图透视", Icon = "eye", Locked = false })
local TabAim = Window:Tab({ Title = "自瞄", Icon = "crosshair", Locked = false })

TabAttack:Section({ Title = "自动攻击", TextXAlignment = "Left", TextSize = 17 })
TabAttack:Toggle({ Title = "自动攻击", Default = false, Callback = function(v) State.AutoAttack = v end })
TabAttack:Slider({
    Title = "射速间隔",
    Value = { Min = 0.02, Max = 0.5, Default = 0.04 },
    Increment = 0.01,
    Callback = function(v) _G.KillAllSettings.FireRateDelay = math.max(0.01, tonumber(v) or 0.04) end,
})

TabESP:Section({ Title = "全图透视", TextXAlignment = "Left", TextSize = 17 })
TabESP:Toggle({ Title = "全图透视", Default = false, Callback = function(v) State.ESP = v end })

TabAim:Section({ Title = "自瞄", TextXAlignment = "Left", TextSize = 17 })
TabAim:Toggle({ Title = "自瞄", Default = false, Callback = function(v) State.AimBot = v end })

WindUI:Notify({
    Title = "迪格尔竞技场",
    Content = "脚本已就绪",
    Duration = 3,
})
