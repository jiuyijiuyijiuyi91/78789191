local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Window = WindUI:CreateWindow({
    Title = "NPC或死亡",
    Icon = "sparkles",
    Author = "XJW",
    Folder = "ThiefESP",
    Size = UDim2.fromOffset(400, 420),
    Theme = "Pink",
    HideSearchBar = false,
})

-- 时间标签
local TimeTag = Window:Tag({
    Title = "00:00",
    Color = Color3.fromRGB(255, 255, 255)
})

local hue = 0
task.spawn(function()
    while true do
        local now = os.date("*t")
        local hours = string.format("%02d", now.hour)
        local minutes = string.format("%02d", now.min)
        hue = (hue + 0.01) % 1
        local rainbowColor = Color3.fromHSV(hue, 1, 1)
        TimeTag:SetTitle(hours .. ":" .. minutes)
        TimeTag:SetColor(rainbowColor)
        task.wait(0.06)
    end
end)

Window:Tag({
    Title = "NPC或死亡",
    Color = Color3.fromHex("#7FDBFF")
})

Window:EditOpenButton({
    Title = "NPC或死亡",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("FF6B6B")),
    Draggable = true,
})

-- ==================== 透视配置 ====================
local espEnabled = false
local showBox = false
local showLine = false
local showText = false
local showHighlight = false

local espObjects = {}
local highlightObjects = {}

-- ==================== 判断是否是真玩家 ====================
local function isRealPlayer(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return hum.MoveDirection.Magnitude > 0
end

-- ==================== 高亮 ====================
local function createHighlight(model)
    if highlightObjects[model] then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.3
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.Parent = model
    highlightObjects[model] = highlight
end

local function removeHighlight(model)
    if highlightObjects[model] then
        highlightObjects[model]:Destroy()
        highlightObjects[model] = nil
    end
end

-- ==================== ESP绘制 ====================
local function createEsp(model)
    if espObjects[model] then return end
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
    if not root then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Thickness = 2
    box.Filled = false
    box.Transparency = 0.8

    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = Color3.fromRGB(255, 0, 0)
    line.Thickness = 1.5

    local text = Drawing.new("Text")
    text.Visible = false
    text.Color = Color3.fromRGB(255, 0, 0)
    text.Size = 14
    text.Font = Drawing.Fonts.Monospace
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Center = true

    espObjects[model] = {box = box, line = line, text = text}
end

-- ==================== 更新ESP ====================
local function updateEsp()
    if not espEnabled then
        for _, obj in pairs(espObjects) do
            obj.box.Visible = false
            obj.line.Visible = false
            obj.text.Visible = false
        end
        for model, _ in pairs(highlightObjects) do
            removeHighlight(model)
        end
        return
    end

    local char = LocalPlayer.Character
    local charRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not charRoot then return end

    for model, obj in pairs(espObjects) do
        if not model.Parent then
            obj.box:Remove()
            obj.line:Remove()
            obj.text:Remove()
            espObjects[model] = nil
            removeHighlight(model)
        end
    end

    local screenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local foundTargets = {}

    for _, v in ipairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v ~= char and isRealPlayer(v) then
            table.insert(foundTargets, v)

            if showHighlight then
                createHighlight(v)
            else
                removeHighlight(v)
            end

            if not espObjects[v] then createEsp(v) end

            local obj = espObjects[v]
            local root = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso")
            if not root then continue end

            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            local dist = (root.Position - charRoot.Position).Magnitude

            if onScreen and pos.Z > 0 then
                local size = 60 / pos.Z
                local boxSize = Vector2.new(size * 1.5, size * 2.5)
                local boxPos = Vector2.new(pos.X - boxSize.X / 2, pos.Y - boxSize.Y / 2)

                if showBox then
                    obj.box.Size = boxSize
                    obj.box.Position = boxPos
                    obj.box.Visible = true
                else
                    obj.box.Visible = false
                end

                if showText then
                    obj.text.Text = "🎯 真小偷 [" .. math.floor(dist) .. "m]"
                    obj.text.Position = Vector2.new(pos.X, pos.Y - boxSize.Y / 2 - 15)
                    obj.text.Visible = true
                else
                    obj.text.Visible = false
                end

                if showLine then
                    obj.line.From = screenBottom
                    obj.line.To = Vector2.new(pos.X, pos.Y)
                    obj.line.Visible = true
                else
                    obj.line.Visible = false
                end
            else
                obj.box.Visible = false
                obj.text.Visible = false
                obj.line.Visible = false
            end
        end
    end

    for model, _ in pairs(highlightObjects) do
        local found = false
        for _, target in ipairs(foundTargets) do
            if target == model then
                found = true
                break
            end
        end
        if not found then
            removeHighlight(model)
        end
    end
end

-- ==================== UI ====================
local Tab = Window:Tab({
    Title = "透视",
    Icon = "settings",
    Locked = false,
})

Tab:Section({Title = "透视开关", TextXAlignment = "Left", TextSize = 17})

Tab:Toggle({
    Title = "开启透视",
    Default = false,
    Callback = function(v)
        espEnabled = v
        if v then
            WindUI:Notify({Title = "透视", Content = "已开启", Duration = 2})
        else
            WindUI:Notify({Title = "透视", Content = "已关闭", Duration = 2})
        end
    end
})

Tab:Section({Title = "功能选择", TextXAlignment = "Left", TextSize = 14})

Tab:Toggle({
    Title = "全身变红",
    Default = false,
    Callback = function(v)
        showHighlight = v
    end
})

Tab:Toggle({
    Title = "方框",
    Default = false,
    Callback = function(v)
        showBox = v
    end
})

Tab:Toggle({
    Title = "线条追踪",
    Default = false,
    Callback = function(v)
        showLine = v
    end
})

Tab:Toggle({
    Title = "文本+距离",
    Default = false,
    Callback = function(v)
        showText = v
    end
})

Tab:Paragraph({
    Title = "说明",
    Desc = "此透视只能显示正在移动的玩家（通过检测MoveDirection判断）",
})

-- 渲染循环
RunService.RenderStepped:Connect(updateEsp)

print("✅ NPC或死亡 透视已加载")