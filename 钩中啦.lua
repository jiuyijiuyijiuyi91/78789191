local UI_URL = "https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"

local okUI, WindUI = pcall(function()
    return loadstring(game:HttpGet(UI_URL))()
end)
if not okUI or type(WindUI) ~= "table" then
    warn("UI库加载失败: " .. tostring(WindUI))
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

local utility = {
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
}

utility.Shared =  utility.ReplicatedStorage:WaitForChild("Shared")
utility.Core = utility.Shared:WaitForChild("Core")
utility.TEvent = require(utility.Core:WaitForChild("TEvent"))
utility.LocalPlayer = utility.Players.LocalPlayer

utility.DoAttack = function(self)
    local s, r = pcall(function(...)
        local c = self.LocalPlayer.Character
        if not c then return false end

        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return false end

        self.TEvent.FireEvent("MakeAHit", self.TEvent.UnixTimeFloat(), 1, h.CFrame)

        return true
    end)

    if s then
        return r
    end

    return false
end

utility.GetClosetPlayer = function(self)
    local s, r = pcall(function(...)
        local cl = nil
        local cd = math.huge

        for _, p in next, self.Players:GetPlayers() do
            if p == self.LocalPlayer then
                continue
            end

            if self.LocalPlayer.Team and self.LocalPlayer.Team.Name == "Lobby" then
                continue
            end

            if p.Team and p.Team.Name == self.LocalPlayer.Team and self.LocalPlayer.Team.Name then
                continue
            end

            local c = p.Character
            if not c then
                continue
            end

            local h = c:FindFirstChild("HumanoidRootPart")
            if not h then
                continue
            end

            local hu = c:FindFirstChild("Humanoid")
            if not hu or hu.Health <= 0 then
                continue
            end

            local d = self.LocalPlayer:DistanceFromCharacter(h.Position)
            if d < cd then
                cl = {
                    h = h,
                    hu = hu,
                }
                cd = d
            end
        end

        return cl
    end)

    if s then
        return r
    end

    return nil
end

local AutoAttack = false

task.spawn(function()
    while task.wait() do
        if AutoAttack then
            local data = utility:GetClosetPlayer()
            if data and typeof(data) == "table" and data.h and data.hu then
                utility:DoAttack()
            end
        end
    end
end)

local Window = WindUI:CreateWindow({
    Title = "XJW钩中啦",
    Icon = "sword",
    Author = "XJW",
    Folder = "XJW_AutoHit",
    Size = UDim2.fromOffset(340, 360),
    Theme = "Blue",
    HideSearchBar = false,
})

Window:Tag({
    Title = "XJW钩中啦",
    Color = Color3.fromHex("#3B82F6")
})

Window:EditOpenButton({
    Title = "XJW钩中啦",
    Icon = "sword",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("3B82F6")),
    Draggable = true,
})

local TabMain = Window:Tab({
    Title = "自动攻击",
    Icon = "sword",
    Locked = false,
})

TabMain:Section({ Title = "自动攻击", TextXAlignment = "Left", TextSize = 17 })

TabMain:Toggle({
    Title = "自动攻击",
    Default = false,
    Callback = function(v)
        AutoAttack = v
    end,
})

WindUI:Notify({
    Title = "XJW钩中啦",
    Content = "脚本已就绪",
    Duration = 3,
})
