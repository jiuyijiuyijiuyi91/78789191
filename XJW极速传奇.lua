-- ============================================================
-- XJW（极速传奇）· Obsidian 精简版（库远端加载）
-- 功能提取自 极速传奇 终极版
-- ============================================================

local repo = "https://raw.githubusercontent.com/ATLASTEAM01/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles


local Window = Library:CreateWindow({
    Title = "XJW（极速传奇）",
    Footer = "Black Obsidian",
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main  = Window:AddTab("主页", "home"),
    TP    = Window:AddTab("传送到", "map-marker"),
    Speed = Window:AddTab("速度", "rocket"),
}

-- ==================== 主页：自动刷取 ====================
local FarmBox = Tabs.Main:AddLeftGroupbox("自动刷取")

Toggles.AutoOrbs = FarmBox:AddToggle("AutoOrbs", { Text = "Auto Farm Orbs（红球）", Default = false })
Toggles.AutoOrbs:OnChanged(function(v)
    task.spawn(function()
        local ev = game.ReplicatedStorage.rEvents.orbEvent
        local cities = { "Magma City", "City", "Snow City" }
        local reps = { 17, 17, 17 }
        while v do
            task.wait()
            for i = 1, #cities do
                for j = 1, reps[i] do
                    ev:FireServer("collectOrb", "Red Orb", cities[i])
                end
            end
        end
    end)
end)

Toggles.AutoGems = FarmBox:AddToggle("AutoGems", { Text = "Auto Farm Gems（宝石）", Default = false })
Toggles.AutoGems:OnChanged(function(v)
    task.spawn(function()
        local ev = game.ReplicatedStorage.rEvents.orbEvent
        while v do
            task.wait()
            for j = 1, 28 do
                ev:FireServer("collectOrb", "Gem", "City")
            end
        end
    end)
end)

Toggles.AutoHoops = FarmBox:AddToggle("AutoHoops", { Text = "Auto Hoops（环跟随）", Default = false })
Toggles.AutoHoops:OnChanged(function(v)
    task.spawn(function()
        local plr = game.Players.LocalPlayer
        while v do
            task.wait()
            local char = plr.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local hoops = workspace:FindFirstChild("Hoops")
                    if hoops then
                        for _, child in ipairs(hoops:GetChildren()) do
                            if child.Name == "Hoop" then
                                child.CFrame = hrp.CFrame
                            end
                        end
                    end
                end
            end
        end
    end)
end)

local RebirthBox = Tabs.Main:AddRightGroupbox("重生 / 进化")

Toggles.AutoRebirth = RebirthBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth（自动重生）", Default = false })
Toggles.AutoRebirth:OnChanged(function(v)
    task.spawn(function()
        local ev = game.ReplicatedStorage.rEvents.rebirthEvent
        while v do
            task.wait()
            ev:FireServer("rebirthRequest")
        end
    end)
end)

Toggles.AutoEvolve = RebirthBox:AddToggle("AutoEvolve", { Text = "Auto Evolve（自动进化）", Default = false })
Toggles.AutoEvolve:OnChanged(function(v)
    task.spawn(function()
        local ev = game.ReplicatedStorage.rEvents.petEvolveEvent
        while v do
            task.wait()
            ev:FireServer("evolvePet", "all")
        end
    end)
end)

-- ==================== 传送到 ====================
local TPBox = Tabs.TP:AddLeftGroupbox("岛屿传送")

local tpPoints = {
    { "Spawn",           Vector3.new(-559.2, -7.45058e-08, 417.4) },
    { "Snow City",       Vector3.new(-858.358, 0.5, 2170.35) },
    { "Magma City",      Vector3.new(1707.25, 0.550008, 4331.05) },
    { "Legends Highway", Vector3.new(3594.68, 214.804, 7274.56) },
}

for _, tp in ipairs(tpPoints) do
    TPBox:AddButton(tp[1], function()
        local char = game.Players.LocalPlayer.Character
        if char then
            char:MoveTo(tp[2])
        end
    end)
end

local EggBox = Tabs.TP:AddRightGroupbox("宠物蛋")

Toggles.BestEgg = EggBox:AddToggle("BestEgg", { Text = "Best Egg（开最强蛋）", Default = false })
Toggles.BestEgg:OnChanged(function(v)
    task.spawn(function()
        local ev = game.ReplicatedStorage.rEvents.openCrystalRemote
        while v do
            task.wait()
            ev:InvokeServer("openCrystal", "Electro Legends Crystal")
        end
    end)
end)

-- ==================== 速度 ====================
local SpeedBox = Tabs.Speed:AddLeftGroupbox("推荐速度")

SpeedBox:AddButton("Speed 300", function()
    game.ReplicatedStorage.rEvents.changeSpeedJumpRemote:InvokeServer("changeSpeed", 300)
end)

SpeedBox:AddButton("Jump 200", function()
    game.ReplicatedStorage.rEvents.changeSpeedJumpRemote:InvokeServer("changeJump", 200)
end)
