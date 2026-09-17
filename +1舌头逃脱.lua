if not game:IsLoaded() then
    game.Loaded:Wait()
end

if game.PlaceId ~= 122245938604556 then
    error("该脚本仅支持 +1 舌头逃脱游戏。")
end

local Environment = getgenv()
local Previous = Environment.__KlevorxTongueEscape
if Previous and type(Previous.Unload) == "function" then
    Previous.Unload()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events", 15)
local Modules = ReplicatedStorage:WaitForChild("Modules", 15)
local SharedModule = ReplicatedStorage:WaitForChild("TongueShared", 15)
assert(Events and Modules and SharedModule, "游戏数据不可用，请重新加入游戏。")

local Shared = require(SharedModule)
local PlaytimeConfig = require(Modules:WaitForChild("PlaytimeRewardsConfig", 10))
local TrailConfig = require(Modules:WaitForChild("TrailConfigurations", 10))
local GameName = "+1 舌头逃脱 ⚡"
local FooterText = "discord.gg/YgYgPZHuHN"

if CoreGui:FindFirstChild("KlevorxModernHub") then
    CoreGui.KlevorxModernHub:Destroy()
end
if CoreGui:FindFirstChild("KlevorxDiscordPopup") then
    CoreGui.KlevorxDiscordPopup:Destroy()
end

local State = {
    Alive = true,
    Flags = {AutoTongue = false, AutoRebirth = false, AutoWins = false, AutoRewards = false, AutoTrails = false, AntiAFK = false, BypassPause = false},
    Status = {AutoTongue = "Off", AutoRebirth = "Off", AutoWins = "Off", AutoRewards = "Off", AutoTrails = "Off", AntiAFK = "Off", BypassPause = "Off"},
    Connections = {},
    Threads = {},
    IdleConnections = {},
    RetryAt = {},
    LastError = {},
    TongueInterval = 0.02,
    WinInterval = 1.5,
    WinGeneration = 0,
    WinMisses = 0,
    Ready = false,
}
Environment.__KlevorxTongueEscape = State

local function Stat(Name)
    local Stats = Player:FindFirstChild("leaderstats")
    local Value = Stats and Stats:FindFirstChild(Name)
    return Value and tonumber(Value.Value) or 0
end

local function CharacterParts()
    local Character = Player.Character
    local Root = Character and Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if Root and Humanoid and Humanoid.Health > 0 then
        return Character, Root, Humanoid
    end
end

local function Number(Value)
    local Text = string.format("%.0f", Value)
    return Text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function NotifyFailure(Key, Message)
    State.Status[Key] = "重试中"
    local Now = os.clock()
    if Now - (State.LastError[Key] or -math.huge) > 30 then
        State.LastError[Key] = Now
    end
end

local function Fire(Name, ...)
    local Remote = Events:FindFirstChild(Name)
    assert(Remote and Remote:IsA("RemoteEvent"), "缺少游戏事件: " .. Name)
    Remote:FireServer(...)
end

local function ReadProperty(Object, Property)
    local Success, Value = pcall(function()
        return Object[Property]
    end)
    if not Success and type(gethiddenproperty) == "function" then
        Success, Value = pcall(gethiddenproperty, Object, Property)
    end
    return Success, Value
end

local function WriteProperty(Object, Property, Value)
    local Success = pcall(function()
        Object[Property] = Value
    end)
    if not Success and type(sethiddenproperty) == "function" then
        Success, Value = pcall(sethiddenproperty, Object, Property, Value)
    end
    return Success
end

local function RestorePause()
    if State.PauseConnection then
        State.PauseConnection:Disconnect()
        State.PauseConnection = nil
    end
    if State.PauseModeChanged and State.OriginalPauseMode ~= nil then
        WriteProperty(workspace, "StreamingIntegrityMode", State.OriginalPauseMode)
    end
    if State.OriginalPauseNotice ~= nil then
        pcall(function()
            GuiService:SetGameplayPausedNotificationEnabled(State.OriginalPauseNotice)
        end)
    end
    State.PauseModeChanged = nil
    State.OriginalPauseMode = nil
    State.OriginalPauseNotice = nil
end

local function ClearPause()
    if not State.Alive or not State.Flags.BypassPause then
        return
    end
    if Player.GameplayPaused then
        local Cleared = WriteProperty(Player, "GameplayPaused", false)
        State.Status.BypassPause = Cleared and "运行中" or "遮罩已隐藏，正在加载地图"
    end
end

local function SetPauseBypass(Enabled)
    RestorePause()
    if not Enabled then
        State.Status.BypassPause = "关闭"
        return
    end
    local ReadMode, Mode = ReadProperty(workspace, "StreamingIntegrityMode")
    if ReadMode then
        State.OriginalPauseMode = Mode
        State.PauseModeChanged = WriteProperty(workspace, "StreamingIntegrityMode", Enum.StreamingIntegrityMode.Disabled)
    end
    local ReadNotice, Notice = pcall(function()
        return GuiService:GetGameplayPausedNotificationEnabled()
    end)
    if ReadNotice then
        State.OriginalPauseNotice = Notice
        pcall(function()
            GuiService:SetGameplayPausedNotificationEnabled(false)
        end)
    end
    State.PauseConnection = Player:GetPropertyChangedSignal("GameplayPaused"):Connect(ClearPause)
    State.Status.BypassPause = "运行中"
    ClearPause()
end

local function RestoreAFK()
    if State.IdleHandler then
        State.IdleHandler:Disconnect()
        State.IdleHandler = nil
    end
    for _, Connection in State.IdleConnections do
        pcall(function()
            Connection:Enable()
        end)
    end
    table.clear(State.IdleConnections)
    if State.GameAFKScript and State.GameAFKScript.Parent and State.GameAFKWasEnabled then
        pcall(function()
            State.GameAFKScript.Enabled = true
        end)
    end
    State.GameAFKScript = nil
    State.GameAFKWasEnabled = nil
end

local function SetAFK(Enabled)
    RestoreAFK()
    if not Enabled then
        State.Status.AntiAFK = "关闭"
        return
    end
    local Scripts = Player:FindFirstChild("PlayerScripts")
    local AFKScript = Scripts and Scripts:FindFirstChild("AntiAfkSystem")
    if AFKScript and AFKScript:IsA("LocalScript") then
        local Success, WasEnabled = pcall(function()
            local Old = AFKScript.Enabled
            AFKScript.Enabled = false
            return Old
        end)
        if Success then
            State.GameAFKScript = AFKScript
            State.GameAFKWasEnabled = WasEnabled
        end
    end
    if type(getconnections) == "function" then
        pcall(function()
            for _, Connection in getconnections(Player.Idled) do
                if Connection.Enabled then
                    local Success = pcall(function()
                        Connection:Disable()
                    end)
                    if Success then
                        table.insert(State.IdleConnections, Connection)
                    end
                end
            end
        end)
    end
    State.IdleHandler = Player.Idled:Connect(function()
        if not State.Alive or not State.Flags.AntiAFK then
            return
        end
        local Success = pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
        if not Success and #State.IdleConnections == 0 then
            State.Status.AntiAFK = "输入不可用"
        end
    end)
    State.Status.AntiAFK = "运行中"
end

local function Cleanup()
    if not State.Alive then
        return
    end
    State.Alive = false
    State.WinGeneration += 1
    for Key in State.Flags do
        State.Flags[Key] = false
    end
    for _, Connection in State.Connections do
        Connection:Disconnect()
    end
    for _, Thread in State.Threads do
        if Thread ~= coroutine.running() then
            pcall(task.cancel, Thread)
        end
    end
    RestoreAFK()
    RestorePause()
    if Environment.__KlevorxTongueEscape == State then
        Environment.__KlevorxTongueEscape = nil
    end
end

local repo = "https://raw.githubusercontent.com/ATLASTEAM01/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Toggles = Library.Toggles

local Window = Library:CreateWindow({ Title = GameName, Footer = FooterText, Center = true, AutoShow = true })

local Tabs = {
    Main = Window:AddTab("主页", "user"),
    ["UI设置"] = Window:AddTab("UI设置", "settings"),
}

local MainBox = Tabs.Main:AddLeftGroupbox("自动化功能")
MainBox:AddToggle("AutoTongue", { Text = "自动刷舌头", Default = false })
MainBox:AddToggle("AutoRebirth", { Text = "自动转生", Default = false })
MainBox:AddToggle("AutoWins", { Text = "自动刷胜场", Default = false })
MainBox:AddToggle("AutoRewards", { Text = "自动领奖励", Default = false })
MainBox:AddToggle("AutoTrails", { Text = "自动购买装备轨迹", Default = false })
MainBox:AddToggle("AntiAFK", { Text = "防挂机保护", Default = false })
MainBox:AddToggle("BypassPause", { Text = "绕过暂停遮罩", Default = false })

for _, Key in ipairs({ "AutoTongue", "AutoRebirth", "AutoWins", "AutoRewards", "AutoTrails", "AntiAFK", "BypassPause" }) do
    Toggles[Key]:OnChanged(function(Value)
        State.Flags[Key] = Value
        State.Status[Key] = Value and "启动中" or "关闭"
        if Key == "AntiAFK" then
            SetAFK(Value)
        elseif Key == "BypassPause" then
            SetPauseBypass(Value)
        elseif Key == "AutoWins" then
            State.WinGeneration += 1
            State.WinMisses = 0
        end
    end)
end

local StatusBox = Tabs.Main:AddRightGroupbox("实时状态看板")
local StatusLabel = StatusBox:AddLabel("正在初始化数据看板...", { DoesWrap = true })

table.insert(State.Threads, task.spawn(function()
    while State.Alive do
        pcall(function()
            local tongue = Number(Stat("Tongue"))
            local level = Number(Stat("Level"))
            local wins = Number(Stat("Wins"))
            local rebirths = Number(Stat("Rebirths"))
            StatusLabel:SetText(string.format("舌头: %s  等级: %s\n胜场: %s  转生: %s", tongue, level, wins, rebirths))
        end)
        task.wait(1)
    end
end))

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("KlevorxTongueEscape/Configs")

SaveManager:BuildConfigSection(Tabs["UI设置"])
ThemeManager:ApplyToTab(Tabs["UI设置"])

SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    Cleanup()
end)

local function StartLoop(Key, Interval, Action)
    local Thread = task.spawn(function()
        while State.Alive do
            if State.Flags[Key] then
                local Success = pcall(Action)
                if not Success and State.Alive and State.Flags[Key] then
                    NotifyFailure(Key, "功能不可用，重试中...")
                    task.wait(2)
                end
            end
            task.wait(type(Interval) == "function" and Interval() or Interval)
        end
    end)
    table.insert(State.Threads, Thread)
end

StartLoop("AutoTongue", function()
    return State.TongueInterval
end, function()
    if not CharacterParts() then
        return
    end
    Fire("AddTongue")
    State.Status.AutoTongue = "训练中"
end)

StartLoop("AutoRebirth", 1, function()
    local Required = Shared.levelForRebirth(Stat("Rebirths"))
    if Stat("Level") < Required then
        return
    end
    local Remote = Events:FindFirstChild("RequestRebirth")
    assert(Remote and Remote:IsA("RemoteFunction"), "转生功能不可用")
    Remote:InvokeServer()
end)

StartLoop("AutoTrails", 1, function()
    local Owned = Player:FindFirstChild("Trails")
    if not Owned then
        return
    end
    local BestOwned, Purchase
    local Wins = Stat("Wins")
    for _, Trail in TrailConfig.Trails do
        if Owned:FindFirstChild(Trail.ID) then
            if not BestOwned or Trail.TongueBoost > BestOwned.TongueBoost then
                BestOwned = Trail
            end
        elseif type(Trail.WinCost) == "number" and Trail.WinCost >= 0 then
            if Trail.WinCost <= Wins and (not Purchase or Trail.TongueBoost > Purchase.TongueBoost) then
                Purchase = Trail
            end
        end
    end
    local Now = os.clock()
    local Equipped = Owned:FindFirstChild("Equipped")
    if BestOwned and Equipped and Equipped.Value ~= BestOwned.ID and Now >= (State.RetryAt.EquipTrail or 0) then
        Fire("TrailAction", "Equip", BestOwned.ID)
        State.RetryAt.EquipTrail = Now + 3
    end
    if Purchase then
        Fire("TrailAction", "BuyWins", Purchase.ID)
    end
end)

local function BestWinButton()
    local Map = workspace:FindFirstChild("Map")
    local GiveWins = Map and Map:FindFirstChild("GiveWins")
    local Row = GiveWins and GiveWins:FindFirstChild("OneWin")
    if not Row then
        return
    end
    local Best, BestAmount = nil, -1
    for _, Model in Row:GetChildren() do
        local Amount = tonumber(Model:GetAttribute("WinAmount")) or 0
        if Model:IsA("Model") and Amount > BestAmount then
            Best, BestAmount = Model, Amount
        end
    end
    return Best, BestAmount
end

StartLoop("AutoWins", function()
    return State.WinInterval
end, function()
    local Character, Root, Humanoid = CharacterParts()
    if not Root then
        return
    end
    local Generation = State.WinGeneration
    local Model, Amount = BestWinButton()
    if not Model then
        return
    end
    local Pivot = Model:GetPivot()
    local Touch = Model:FindFirstChild("Touch")
    if not Touch then
        pcall(function()
            Player:RequestStreamAroundAsync(Pivot.Position, 3)
        end)
        Touch = Model:FindFirstChild("Touch")
    end
    if not State.Alive or not State.Flags.AutoWins or Generation ~= State.WinGeneration or Player.Character ~= Character then
        return
    end
    local Before = Stat("Wins")
    local UsedTouch = false
    if Touch and Touch:IsA("BasePart") and type(firetouchinterest) == "function" and State.WinMisses < 2 then
        UsedTouch = pcall(function()
            firetouchinterest(Root, Touch, 0)
            task.wait(0.1)
            if Root.Parent and Touch.Parent then
                firetouchinterest(Root, Touch, 1)
            end
        end)
    end
    if not UsedTouch then
        local Target = Touch and Touch.CFrame or Pivot
        Humanoid.Sit = false
        if (Root.Position - Target.Position).Magnitude < 12 then
            Character:PivotTo(Target + Vector3.new(0, 7, 14))
            task.wait(0.15)
        end
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
        Character:PivotTo(Target + Vector3.new(0, 3, 0))
    end
    local Deadline = os.clock() + 1.2
    repeat
        task.wait(0.1)
    until not State.Alive or not State.Flags.AutoWins or Generation ~= State.WinGeneration or Stat("Wins") > Before or os.clock() >= Deadline
    if State.Alive and State.Flags.AutoWins and Generation == State.WinGeneration then
        local Collected = Stat("Wins") > Before
        State.WinMisses = Collected and 0 or State.WinMisses + 1
    end
end)

local function ClaimOnce(Key, Remote, Cooldown, ...)
    if not State.Flags.AutoRewards or not State.Alive then
        return
    end
    local Now = os.clock()
    if Now < (State.RetryAt[Key] or 0) then
        return
    end
    Fire(Remote, ...)
    State.RetryAt[Key] = Now + Cooldown
    task.wait(0.2)
end

StartLoop("AutoRewards", 5, function()
    local Now = workspace:GetServerTimeNow()
    local Start = Player:GetAttribute("PlaytimeStart")
    local Elapsed = typeof(Start) == "number" and math.max(0, (tonumber(Player:GetAttribute("PlaytimeBase")) or 0) + Now - Start) or 0
    local Claimed = {}
    for Index in tostring(Player:GetAttribute("PlaytimeClaimed") or ""):gmatch("%d+") do
        Claimed[tonumber(Index)] = true
    end
    for Index, Reward in PlaytimeConfig.Rewards do
        if not Claimed[Index] and Elapsed >= Reward.Minute * 60 then
            ClaimOnce("Playtime" .. Index, "PlaytimeClaim", 10, Index)
        end
    end
    local LastDaily = tonumber(Player:GetAttribute("DailyLastClaim"))
    if LastDaily and (LastDaily <= 0 or Now - LastDaily >= 86400) then
        ClaimOnce("Daily", "DailyClaim", 15)
    end
    if Player:GetAttribute("LeaveBonusClaimed") == false then
        ClaimOnce("LeaveBonus", "LeaveBonusClaim", 30)
    end
    if Player:GetAttribute("GroupRewardClaimed") == false then
        local CheckAt = State.RetryAt.GroupCheck or 0
        if os.clock() >= CheckAt then
            State.RetryAt.GroupCheck = os.clock() + 120
            local Success, Member = pcall(function()
                return Player:IsInGroupAsync(602332660)
            end)
            if Success and Member then
                ClaimOnce("Group", "GroupRewardClaim", 120)
            end
        end
    end
end)

SetPauseBypass(true)
State.Ready = true
