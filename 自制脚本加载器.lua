-- XJW中心 加载器 v3.0
-- 设计来源: BS源码 - redzUI (https://gitee.com/BS_script/script/raw/master/redz)
-- 特点: 深色主题 + Discord蓝 + 彩虹旋转边框 + 标题渐变发光 + 悬停透明度

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- redzUI 配色方案 (Dark主题)
local Theme = {
    HubColor = Color3.fromRGB(25, 25, 25),
    HubColor2 = Color3.fromRGB(30, 30, 30),
    StrokeColor = Color3.fromRGB(40, 40, 40),
    ThemeColor = Color3.fromRGB(88, 101, 242),
    TextColor = Color3.fromRGB(243, 243, 243),
    DarkTextColor = Color3.fromRGB(180, 180, 180),
    AccentHover = Color3.fromRGB(100, 110, 250),
}

-- 移除旧界面
pcall(function()
    if game.CoreGui:FindFirstChild("XJWLoader") then
        game.CoreGui.XJWLoader:Destroy()
    end
end)

local mouse = LocalPlayer:GetMouse()

-- 拖拽函数
local function makeDraggable(frame, holdFrame)
    holdFrame = holdFrame or frame
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    holdFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- 创建 ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XJWLoader"
screenGui.Parent = game.CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

-- 遮罩背景
local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.Position = UDim2.new(0, 0, 0, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.BorderSizePixel = 0
backdrop.Parent = screenGui

-- 主窗口 (ImageButton风格, 参考redzUI)
local mainFrame = Instance.new("ImageButton")
mainFrame.Size = UDim2.new(0, 440, 0, 260)
mainFrame.Position = UDim2.new(0.5, -220, 0.5, -130)
mainFrame.BackgroundColor3 = Theme.HubColor2
mainFrame.BackgroundTransparency = 0.03
mainFrame.BorderSizePixel = 0
mainFrame.AutoButtonColor = false
mainFrame.Parent = backdrop

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 6)
mainCorner.Parent = mainFrame

-- 背景渐变
local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(32, 32, 32)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
})
bgGradient.Rotation = 45
bgGradient.Parent = mainFrame

-- 彩虹旋转边框 (redzUI 标志性效果)
local rainbowStroke = Instance.new("UIStroke")
rainbowStroke.Thickness = 1.5
rainbowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
rainbowStroke.Transparency = 0.5
rainbowStroke.Color = Theme.ThemeColor
rainbowStroke.Parent = mainFrame

local rainbowGradient = Instance.new("UIGradient")
rainbowGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.ThemeColor),
    ColorSequenceKeypoint.new(0.25, Theme.ThemeColor:Lerp(Color3.new(1, 1, 1), 0.3)),
    ColorSequenceKeypoint.new(0.5, Theme.ThemeColor),
    ColorSequenceKeypoint.new(0.75, Theme.ThemeColor:Lerp(Color3.new(0, 0, 0), 0.3)),
    ColorSequenceKeypoint.new(1, Theme.ThemeColor)
})
rainbowGradient.Rotation = 0
rainbowGradient.Parent = rainbowStroke

-- 彩虹旋转动画
spawn(function()
    local rotationSpeed = 40
    while rainbowStroke and rainbowStroke.Parent do
        rainbowGradient.Rotation = (rainbowGradient.Rotation + rotationSpeed * 0.016) % 360
        RunService.Heartbeat:Wait()
    end
end)

makeDraggable(mainFrame)

-- 顶栏
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 28)
topBar.BackgroundTransparency = 1
topBar.Parent = mainFrame

-- 图标
local icon = Instance.new("ImageLabel")
icon.Size = UDim2.new(0, 18, 0, 18)
icon.Position = UDim2.new(0, 15, 0.5, -9)
icon.BackgroundTransparency = 1
icon.Image = "rbxassetid://10734901364"
icon.Parent = topBar

-- 标题 (redzUI渐变发光标题)
local title = Instance.new("TextLabel")
title.Position = UDim2.new(0, 40, 0.5, 0)
title.AnchorPoint = Vector2.new(0, 0.5)
title.AutomaticSize = Enum.AutomaticSize.XY
title.Text = "XJW 中心"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextSize = 12
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamMedium
title.Parent = topBar

-- 标题渐变 (redzUI 标志性渐变)
local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 40, 70)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(120, 30, 100)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 60, 180)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 100, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 80, 180))
})
titleGradient.Rotation = 0
titleGradient.Parent = title

-- 标题发光效果
local titleGlow = Instance.new("UIStroke")
titleGlow.Color = Color3.fromRGB(80, 100, 180)
titleGlow.Thickness = 1.2
titleGlow.Transparency = 0.8
titleGlow.Parent = title

-- 标题渐变旋转 + 发光呼吸动画
spawn(function()
    local lightAngle = 0
    while titleGradient and titleGradient.Parent do
        local delta = 0.016
        titleGradient.Rotation = (titleGradient.Rotation + 45 * delta) % 360
        lightAngle = (lightAngle + delta * 60) % 360
        local light = math.sin(math.rad(lightAngle)) * 0.2 + 0.8
        titleGlow.Transparency = 0.3 + (1 - light) * 0.5
        RunService.Heartbeat:Wait()
    end
end)

-- 副标题
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(0, 0, 1, 0)
subtitle.AutomaticSize = Enum.AutomaticSize.X
subtitle.AnchorPoint = Vector2.new(0, 1)
subtitle.Position = UDim2.new(1, 5, 0.9, 0)
subtitle.Text = "加载器 v3.0"
subtitle.TextColor3 = Theme.DarkTextColor
subtitle.BackgroundTransparency = 1
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextYAlignment = Enum.TextYAlignment.Bottom
subtitle.TextSize = 8
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = title

-- 分隔线
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, 0, 0, 1)
divider.Position = UDim2.new(0, 0, 0, 28)
divider.BackgroundColor3 = Theme.StrokeColor
divider.BorderSizePixel = 0
divider.Parent = mainFrame

-- 内容区域
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -30, 0, 140)
contentArea.Position = UDim2.new(0, 15, 0, 40)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

-- 提示文字
local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(1, 0, 0, 25)
promptLabel.Position = UDim2.new(0, 0, 0, 10)
promptLabel.BackgroundTransparency = 1
promptLabel.Text = "是否加载 XJW 中心脚本?"
promptLabel.TextColor3 = Theme.TextColor
promptLabel.Font = Enum.Font.GothamMedium
promptLabel.TextSize = 14
promptLabel.TextXAlignment = Enum.TextXAlignment.Center
promptLabel.Parent = contentArea

-- 描述文字
local descLabel = Instance.new("TextLabel")
descLabel.Size = UDim2.new(1, 0, 0, 20)
descLabel.Position = UDim2.new(0, 0, 0, 38)
descLabel.BackgroundTransparency = 1
descLabel.Text = "点击继续将加载主脚本"
descLabel.TextColor3 = Theme.DarkTextColor
descLabel.Font = Enum.Font.Gotham
descLabel.TextSize = 11
descLabel.TextXAlignment = Enum.TextXAlignment.Center
descLabel.Parent = contentArea

-- 状态文字
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.Position = UDim2.new(0, 0, 0, 65)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Theme.ThemeColor
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = contentArea

-- 按钮容器
local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(1, 0, 0, 40)
buttonContainer.Position = UDim2.new(0, 0, 0, 200)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = mainFrame

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Padding = UDim.new(0, 15)
btnLayout.Parent = buttonContainer

-- 继续按钮 (redzUI Button风格)
local continueBtn = Instance.new("TextButton")
continueBtn.Size = UDim2.new(0, 150, 0, 32)
continueBtn.Text = ""
continueBtn.TextColor3 = Theme.TextColor
continueBtn.Font = Enum.Font.GothamMedium
continueBtn.TextSize = 11
continueBtn.BackgroundColor3 = Theme.HubColor2
continueBtn.AutoButtonColor = false
continueBtn.BorderSizePixel = 0
continueBtn.Parent = buttonContainer

local continueCorner = Instance.new("UICorner")
continueCorner.CornerRadius = UDim.new(0, 6)
continueCorner.Parent = continueBtn

local continueStroke = Instance.new("UIStroke")
continueStroke.Color = Theme.ThemeColor
continueStroke.Thickness = 1
continueStroke.Transparency = 0
continueStroke.Parent = continueBtn

-- 继续按钮文字
local continueText = Instance.new("TextLabel")
continueText.Size = UDim2.new(1, 0, 1, 0)
continueText.BackgroundTransparency = 1
continueText.Text = "继续加载"
continueText.TextColor3 = Theme.TextColor
continueText.Font = Enum.Font.GothamMedium
continueText.TextSize = 11
continueText.Parent = continueBtn

-- 取消按钮
local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(0, 110, 0, 32)
cancelBtn.Text = ""
cancelBtn.TextColor3 = Theme.DarkTextColor
cancelBtn.Font = Enum.Font.GothamMedium
cancelBtn.TextSize = 11
cancelBtn.BackgroundColor3 = Theme.HubColor2
cancelBtn.AutoButtonColor = false
cancelBtn.BorderSizePixel = 0
cancelBtn.Parent = buttonContainer

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 6)
cancelCorner.Parent = cancelBtn

local cancelStroke = Instance.new("UIStroke")
cancelStroke.Color = Theme.StrokeColor
cancelStroke.Thickness = 1
cancelStroke.Transparency = 0
cancelStroke.Parent = cancelBtn

local cancelText = Instance.new("TextLabel")
cancelText.Size = UDim2.new(1, 0, 1, 0)
cancelText.BackgroundTransparency = 1
cancelText.Text = "取消"
cancelText.TextColor3 = Theme.DarkTextColor
cancelText.Font = Enum.Font.GothamMedium
cancelText.TextSize = 11
cancelText.Parent = cancelBtn

-- 进度条
local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(1, 0, 0, 2)
progressBg.Position = UDim2.new(0, 0, 1, 0)
progressBg.BackgroundColor3 = Theme.StrokeColor
progressBg.BorderSizePixel = 0
progressBg.Parent = mainFrame

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 0, 2)
progressFill.Position = UDim2.new(0, 0, 0, 0)
progressFill.BackgroundColor3 = Theme.ThemeColor
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg

-- redzUI 按钮悬停效果 (透明度变化)
continueBtn.MouseEnter:Connect(function()
    TweenService:Create(continueBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
end)
continueBtn.MouseLeave:Connect(function()
    TweenService:Create(continueBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
end)

cancelBtn.MouseEnter:Connect(function()
    TweenService:Create(cancelBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play()
end)
cancelBtn.MouseLeave:Connect(function()
    TweenService:Create(cancelBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
end)

-- 继续按钮事件
continueBtn.MouseButton1Click:Connect(function()
    continueBtn.Visible = false
    cancelBtn.Visible = false
    promptLabel.Text = "正在加载..."
    descLabel.Text = "请稍候，正在连接服务器"
    statusLabel.Text = "初始化中..."

    -- 进度动画
    local progressTween = TweenService:Create(progressFill, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 0, 2)
    })
    progressTween:Play()

    -- 状态文字动画
    spawn(function()
        local states = {"初始化中...", "连接服务器...", "下载脚本...", "验证完整性...", "加载完成!"}
        for i, state in ipairs(states) do
            if not progressFill or not progressFill.Parent then return end
            statusLabel.Text = state
            task.wait(0.25)
        end
    end)

    progressTween.Completed:Connect(function()
        task.wait(0.3)
        -- 淡出动画
        local fadeOut1 = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        local fadeOut2 = TweenService:Create(backdrop, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        rainbowStroke.Transparency = 1
        fadeOut1:Play()
        fadeOut2:Play()
        task.wait(0.4)
        screenGui:Destroy()

        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E8%87%AA%E5%88%B6%E8%84%9A%E6%9C%AC.lua"))()
        end)
    end)
end)

-- 取消按钮事件
cancelBtn.MouseButton1Click:Connect(function()
    local fadeOut = TweenService:Create(backdrop, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    })
    rainbowStroke.Transparency = 1
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        screenGui:Destroy()
    end)
end)

-- 入场动画
mainFrame.Size = UDim2.new(0, 440, 0, 0)
mainFrame.Position = UDim2.new(0.5, -220, 0.5, 0)
mainFrame.BackgroundTransparency = 1
backdrop.BackgroundTransparency = 1

local fadeIn1 = TweenService:Create(backdrop, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0.5
})
local fadeIn2 = TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 440, 0, 260),
    Position = UDim2.new(0.5, -220, 0.5, -130),
    BackgroundTransparency = 0.03
})

fadeIn1:Play()
task.wait(0.05)
fadeIn2:Play()
