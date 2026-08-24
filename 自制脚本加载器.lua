-- XJW中心 加载器
-- 弹出选择窗口，点击"继续"加载XJW中心

local function createLoaderUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XJWLoader"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false

    -- 遮罩背景
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.Position = UDim2.new(0, 0, 0, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.3
    backdrop.BorderSizePixel = 0
    backdrop.Parent = screenGui

    -- 主窗口
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 340, 0, 180)
    frame.Position = UDim2.new(0.5, -170, 0.5, -90)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.BorderSizePixel = 0
    frame.Parent = backdrop

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    -- 顶部强调线
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 3)
    accentLine.Position = UDim2.new(0, 0, 0, 0)
    accentLine.BackgroundColor3 = Color3.fromRGB(100, 130, 255)
    accentLine.BorderSizePixel = 0
    accentLine.Parent = frame

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 10)
    accentCorner.Parent = accentLine

    -- 标题
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "XJW中心"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 22
    title.Parent = frame

    -- 提示文字
    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(0.9, 0, 0, 35)
    message.Position = UDim2.new(0.05, 0, 0, 50)
    message.BackgroundTransparency = 1
    message.Text = "是否加载XJW中心?"
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.Font = Enum.Font.SourceSans
    message.TextSize = 16
    message.Parent = frame

    -- 按钮容器
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(0.9, 0, 0, 42)
    buttonContainer.Position = UDim2.new(0.05, 0, 0, 115)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = frame

    -- 继续按钮
    local continueButton = Instance.new("TextButton")
    continueButton.Size = UDim2.new(0.47, 0, 1, 0)
    continueButton.Position = UDim2.new(0, 0, 0, 0)
    continueButton.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
    continueButton.Text = "继续"
    continueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    continueButton.Font = Enum.Font.SourceSansBold
    continueButton.TextSize = 17
    continueButton.AutoButtonColor = true
    continueButton.Parent = buttonContainer

    local yesCorner = Instance.new("UICorner")
    yesCorner.CornerRadius = UDim.new(0, 6)
    yesCorner.Parent = continueButton

    -- 取消按钮
    local cancelButton = Instance.new("TextButton")
    cancelButton.Size = UDim2.new(0.47, 0, 1, 0)
    cancelButton.Position = UDim2.new(0.53, 0, 0, 0)
    cancelButton.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
    cancelButton.Text = "取消"
    cancelButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    cancelButton.Font = Enum.Font.SourceSansBold
    cancelButton.TextSize = 17
    cancelButton.AutoButtonColor = true
    cancelButton.Parent = buttonContainer

    local noCorner = Instance.new("UICorner")
    noCorner.CornerRadius = UDim.new(0, 6)
    noCorner.Parent = cancelButton

    -- 按钮事件
    continueButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E8%87%AA%E5%88%B6%E8%84%9A%E6%9C%AC.lua"))()
        end)
    end)

    cancelButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
end

createLoaderUI()
