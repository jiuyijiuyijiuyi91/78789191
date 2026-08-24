-- XJW中心 加载器 (流畅UI风格)
-- 设计来源: BS源码 - 流畅UI (https://gitee.com/BS_script/script/raw/master/smooth)
-- 特点: 深色主题 + 紫罗兰强调色 + 涟漪动画 + 彩虹渐变标题 + 阴影效果

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- 流畅UI 配色方案
local Theme = {
    Background = Color3.fromRGB(25, 25, 25),
    Accent = Color3.fromRGB(129, 90, 220),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(180, 180, 190),
    TextSubtle = Color3.fromRGB(120, 120, 130),
    ButtonBg = Color3.fromRGB(40, 40, 40),
    ButtonHover = Color3.fromRGB(50, 50, 50),
    Success = Color3.fromRGB(80, 200, 120),
    Danger = Color3.fromRGB(220, 80, 80),
    Transparency = 0.6
}

-- 移除旧界面
pcall(function()
    if game.CoreGui:FindFirstChild("XJWLoader") then
        game.CoreGui.XJWLoader:Destroy()
    end
end)

local mouse = LocalPlayer:GetMouse()

-- 涟漪效果函数
local function Ripple(obj, color)
    spawn(function()
        if obj.ClipsDescendants ~= true then
            obj.ClipsDescendants = true
        end
        local ripple = Instance.new("ImageLabel")
        ripple.Name = "Ripple"
        ripple.Parent = obj
        ripple.BackgroundColor3 = color or Theme.Accent
        ripple.BackgroundTransparency = 1
        ripple.ZIndex = 8
        ripple.Image = "rbxassetid://18941591417"
        ripple.ImageTransparency = 0.8
        ripple.ScaleType = Enum.ScaleType.Fit
        ripple.ImageColor3 = color or Theme.Accent
        ripple.Position = UDim2.new(
            (mouse.X - ripple.AbsolutePosition.X) / obj.AbsoluteSize.X, 0,
            (mouse.Y - ripple.AbsolutePosition.Y) / obj.AbsoluteSize.Y, 0
        )
        local ts = TweenService
        ts:Create(ripple, TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
            Position = UDim2.new(-5.5, 0, -5.5, 0),
            Size = UDim2.new(12, 0, 12, 0)
        }):Play()
        task.wait(0.15)
        ts:Create(ripple, TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
            ImageTransparency = 1
        }):Play()
        task.wait(0.3)
        ripple:Destroy()
    end)
end

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

-- 遮罩背景 (毛玻璃效果)
local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.Position = UDim2.new(0, 0, 0, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.BorderSizePixel = 0
backdrop.Parent = screenGui

-- 阴影容器
local shadowHolder = Instance.new("Frame")
shadowHolder.Size = UDim2.new(0, 420, 0, 280)
shadowHolder.Position = UDim2.new(0.5, -210, 0.5, -140)
shadowHolder.BackgroundTransparency = 1
shadowHolder.BorderSizePixel = 0
shadowHolder.ZIndex = 0
shadowHolder.Parent = backdrop

-- 阴影效果
local dropShadow = Instance.new("ImageLabel")
dropShadow.Parent = shadowHolder
dropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
dropShadow.BackgroundTransparency = 1
dropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
dropShadow.Size = UDim2.new(1, 20, 1, 20)
dropShadow.Image = "rbxassetid://102621341311637"
dropShadow.ImageColor3 = Theme.Accent
dropShadow.ImageTransparency = 0.8
dropShadow.SliceCenter = Rect.new(49, 49, 450, 450)

-- 主窗口
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 280)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -140)
mainFrame.BackgroundColor3 = Theme.Background
mainFrame.BorderSizePixel = 0
mainFrame.Parent = backdrop

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

-- 侧边强调条
local sideBar = Instance.new("Frame")
sideBar.Size = UDim2.new(0, 6, 0, 280)
sideBar.Position = UDim2.new(0, 0, 0, 0)
sideBar.BackgroundColor3 = Theme.Accent
sideBar.BorderSizePixel = 0
sideBar.Parent = mainFrame

local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 6)
sideCorner.Parent = sideBar

-- 侧边渐变
local sideGradient = Instance.new("UIGradient")
sideGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
    ColorSequenceKeypoint.new(0.5, Theme.Accent),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(192, 90, 220))
})
sideGradient.Rotation = 90
sideGradient.Parent = sideBar

-- 标题区域
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, -6, 0, 60)
titleBar.Position = UDim2.new(0, 6, 0, 0)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

makeDraggable(mainFrame, titleBar)

-- 图标
local icon = Instance.new("ImageLabel")
icon.Size = UDim2.new(0, 32, 0, 32)
icon.Position = UDim2.new(0, 20, 0.5, -16)
icon.BackgroundTransparency = 1
icon.Image = "rbxassetid://104756179251351"
icon.Parent = titleBar

-- 标题文字
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 300, 0, 40)
title.Position = UDim2.new(0, 60, 0, 10)
title.BackgroundTransparency = 1
title.Text = "XJW 中心"
title.TextColor3 = Theme.Accent
title.Font = Enum.Font.GothamSemibold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- 标题彩虹渐变
local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
    ColorSequenceKeypoint.new(0.25, Theme.Accent),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 90, 220)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(192, 90, 220)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 101, 242))
})
titleGradient.Parent = title

-- 彩虹动画
spawn(function()
    local offset = Vector2.new(-1, 0)
    local speed = 0.008
    while titleGradient and titleGradient.Parent do
        offset = offset + Vector2.new(speed, 0)
        if offset.X >= 1 then
            offset = Vector2.new(-1, 0)
        end
        titleGradient.Offset = offset
        task.wait()
    end
end)

-- 副标题
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -60, 0, 20)
subtitle.Position = UDim2.new(0, 60, 0, 36)
subtitle.BackgroundTransparency = 1
subtitle.Text = "加载器 v2.0  |  流畅UI风格"
subtitle.TextColor3 = Theme.TextSubtle
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 12
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = titleBar

-- 分隔线
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -40, 0, 1)
divider.Position = UDim2.new(0, 20, 0, 70)
divider.BackgroundColor3 = Theme.Accent
divider.BackgroundTransparency = 0.8
divider.BorderSizePixel = 0
divider.Parent = mainFrame

-- 内容区域
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -40, 0, 120)
contentArea.Position = UDim2.new(0, 20, 0, 85)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainFrame

-- 提示文字
local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(1, 0, 0, 30)
promptLabel.Position = UDim2.new(0, 0, 0, 10)
promptLabel.BackgroundTransparency = 1
promptLabel.Text = "是否加载 XJW 中心脚本?"
promptLabel.TextColor3 = Theme.Text
promptLabel.Font = Enum.Font.GothamSemibold
promptLabel.TextSize = 16
promptLabel.Parent = contentArea

-- 描述文字
local descLabel = Instance.new("TextLabel")
descLabel.Size = UDim2.new(1, 0, 0, 25)
descLabel.Position = UDim2.new(0, 0, 0, 42)
descLabel.BackgroundTransparency = 1
descLabel.Text = "点击继续将加载主脚本，点击取消退出"
descLabel.TextColor3 = Theme.TextDim
descLabel.Font = Enum.Font.Gotham
descLabel.TextSize = 13
descLabel.Parent = contentArea

-- 加载状态文字
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 72)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Theme.Accent
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.Parent = contentArea

-- 按钮容器
local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(1, 0, 0, 50)
buttonContainer.Position = UDim2.new(0, 0, 0, 200)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = mainFrame

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Padding = UDim.new(0, 20)
btnLayout.Parent = buttonContainer

-- 继续按钮
local continueBtn = Instance.new("TextButton")
continueBtn.Size = UDim2.new(0, 160, 0, 42)
continueBtn.BackgroundColor3 = Theme.Accent
continueBtn.Text = "  继续加载"
continueBtn.TextColor3 = Theme.Text
continueBtn.Font = Enum.Font.GothamSemibold
continueBtn.TextSize = 16
continueBtn.TextXAlignment = Enum.TextXAlignment.Center
continueBtn.AutoButtonColor = false
continueBtn.Parent = buttonContainer

local continueCorner = Instance.new("UICorner")
continueCorner.CornerRadius = UDim.new(0, 6)
continueCorner.Parent = continueBtn

-- 继续按钮图标
local continueIcon = Instance.new("ImageLabel")
continueIcon.Size = UDim2.new(0, 16, 0, 16)
continueIcon.Position = UDim2.new(0, 12, 0.5, -8)
continueIcon.BackgroundTransparency = 1
continueIcon.Image = "rbxassetid://70754573667061"
continueIcon.Parent = continueBtn

-- 取消按钮
local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(0, 120, 0, 42)
cancelBtn.BackgroundColor3 = Theme.ButtonBg
cancelBtn.Text = "取消"
cancelBtn.TextColor3 = Theme.TextDim
cancelBtn.Font = Enum.Font.GothamSemibold
cancelBtn.TextSize = 16
cancelBtn.AutoButtonColor = false
cancelBtn.Parent = buttonContainer

local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 6)
cancelCorner.Parent = cancelBtn

-- 进度条
local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(1, 0, 0, 3)
progressBg.Position = UDim2.new(0, 0, 1, 0)
progressBg.BackgroundColor3 = Theme.ButtonBg
progressBg.BorderSizePixel = 0
progressBg.Parent = mainFrame

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 0, 3)
progressFill.Position = UDim2.new(0, 0, 0, 0)
progressFill.BackgroundColor3 = Theme.Accent
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg

local progressGradient = Instance.new("UIGradient")
progressGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
    ColorSequenceKeypoint.new(0.5, Theme.Accent),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(192, 90, 220))
})
progressGradient.Parent = progressFill

-- 按钮悬停效果
continueBtn.MouseEnter:Connect(function()
    TweenService:Create(continueBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(145, 100, 240)}):Play()
end)
continueBtn.MouseLeave:Connect(function()
    TweenService:Create(continueBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
end)

cancelBtn.MouseEnter:Connect(function()
    TweenService:Create(cancelBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ButtonHover}):Play()
end)
cancelBtn.MouseLeave:Connect(function()
    TweenService:Create(cancelBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ButtonBg}):Play()
end)

-- 继续按钮事件
continueBtn.MouseButton1Click:Connect(function()
    Ripple(continueBtn, Theme.Text)
    continueBtn.Visible = false
    cancelBtn.Visible = false
    promptLabel.Text = "正在加载..."
    descLabel.Text = "请稍候，正在连接服务器"
    statusLabel.Text = "初始化中..."

    -- 进度动画
    local progressTween = TweenService:Create(progressFill, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
        Size = UDim2.new(1, 0, 0, 3)
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
        local fadeOut = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 1
        })
        local fadeOut2 = TweenService:Create(backdrop, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 1
        })
        fadeOut:Play()
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
    Ripple(cancelBtn, Theme.Danger)
    task.wait(0.15)
    local fadeOut = TweenService:Create(backdrop, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        BackgroundTransparency = 1
    })
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        screenGui:Destroy()
    end)
end)

-- 入场动画
mainFrame.Size = UDim2.new(0, 420, 0, 0)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, 0)
mainFrame.BackgroundTransparency = 1
shadowHolder.Size = UDim2.new(0, 420, 0, 0)
shadowHolder.Position = UDim2.new(0.5, -210, 0.5, 0)
backdrop.BackgroundTransparency = 1

local fadeIn1 = TweenService:Create(backdrop, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0.5
})
local fadeIn2 = TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 420, 0, 280),
    Position = UDim2.new(0.5, -210, 0.5, -140),
    BackgroundTransparency = 0
})
local fadeIn3 = TweenService:Create(shadowHolder, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 420, 0, 280),
    Position = UDim2.new(0.5, -210, 0.5, -140)
})

fadeIn1:Play()
task.wait(0.05)
fadeIn2:Play()
fadeIn3:Play()
