-- XJW中心 加载器 
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local inst = Instance.new

local scriptUrl = "https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E8%87%AA%E5%88%B6%E8%84%9A%E6%9C%AC.lua"

-- 给XJW中心用的安全加载函数
_G.XJW_safeLoad = function(url)
    local ok, content = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and content and #content > 0 then
        local fn = loadstring(content)
        if fn then fn() return true end
    end
    return false
end
shared = shared or {}
shared.XJW_safeLoad = _G.XJW_safeLoad

-- 配色
local c_bg = Color3.fromRGB(30, 30, 30)
local c_stroke = Color3.fromRGB(40, 40, 40)
local c_theme = Color3.fromRGB(88, 101, 242)
local c_text = Color3.fromRGB(243, 243, 243)
local c_dim = Color3.fromRGB(180, 180, 180)
local c_error = Color3.fromRGB(220, 80, 80)
local c_success = Color3.fromRGB(80, 200, 120)

pcall(function()
    if CoreGui:FindFirstChild("XJWLoader") then
        CoreGui.XJWLoader:Destroy()
    end
end)

-- 拖拽
local function drag(frame, hold)
    hold = hold or frame
    local dragging, dragInput, dragStart, startPos = false
    hold.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, input.Position, frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ScreenGui
local sg = inst("ScreenGui")
sg.Name = "XJWLoader"
sg.Parent = CoreGui
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.ResetOnSpawn = false

-- 遮罩
local bd = inst("Frame")
bd.Size = UDim2.new(1, 0, 1, 0)
bd.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bd.BackgroundTransparency = 0.5
bd.BorderSizePixel = 0
bd.Parent = sg

-- 主窗口
local mf = inst("ImageButton")
mf.Size = UDim2.new(0, 440, 0, 260)
mf.Position = UDim2.new(0.5, -220, 0.5, -130)
mf.BackgroundColor3 = c_bg
mf.BackgroundTransparency = 0.03
mf.BorderSizePixel = 0
mf.AutoButtonColor = false
mf.Parent = bd

inst("UICorner", mf).CornerRadius = UDim.new(0, 6)

local bgg = inst("UIGradient", mf)
bgg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(32, 32, 32)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
})
bgg.Rotation = 45

-- 彩虹边框
local rs = inst("UIStroke", mf)
rs.Thickness = 1.5
rs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
rs.Transparency = 0.5
rs.Color = c_theme

local rg = inst("UIGradient", rs)
rg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, c_theme),
    ColorSequenceKeypoint.new(0.25, c_theme:Lerp(Color3.new(1, 1, 1), 0.3)),
    ColorSequenceKeypoint.new(0.5, c_theme),
    ColorSequenceKeypoint.new(0.75, c_theme:Lerp(Color3.new(0, 0, 0), 0.3)),
    ColorSequenceKeypoint.new(1, c_theme)
})

-- 边框旋转动画
local rot = 0
RunService.Heartbeat:Connect(function(dt)
    if rs and rs.Parent then
        rot = rot + dt * 40
        rg.Rotation = rot % 360
    end
end)

drag(mf)

-- 顶栏
local tb = inst("Frame", mf)
tb.Size = UDim2.new(1, 0, 0, 28)
tb.BackgroundTransparency = 1

local ic = inst("ImageLabel", tb)
ic.Size = UDim2.new(0, 18, 0, 18)
ic.Position = UDim2.new(0, 15, 0.5, -9)
ic.BackgroundTransparency = 1
ic.Image = "rbxassetid://10734901364"

local tt = inst("TextLabel", tb)
tt.Position = UDim2.new(0, 40, 0.5, 0)
tt.AnchorPoint = Vector2.new(0, 0.5)
tt.AutomaticSize = Enum.AutomaticSize.XY
tt.Text = "XJW 中心"
tt.TextXAlignment = Enum.TextXAlignment.Left
tt.TextSize = 12
tt.TextColor3 = Color3.new(1, 1, 1)
tt.BackgroundTransparency = 1
tt.Font = Enum.Font.GothamMedium

local tg = inst("UIGradient", tt)
tg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 40, 70)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(120, 30, 100)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 60, 180)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 100, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 80, 180))
})

local tgl = inst("UIStroke", tt)
tgl.Color = Color3.fromRGB(80, 100, 180)
tgl.Thickness = 1.2
tgl.Transparency = 0.8

-- 标题动画
local la = 0
RunService.Heartbeat:Connect(function(dt)
    if tg and tg.Parent then
        tg.Rotation = (tg.Rotation + dt * 45) % 360
        la = (la + dt * 60) % 360
        local l = math.sin(math.rad(la)) * 0.2 + 0.8
        tgl.Transparency = 0.3 + (1 - l) * 0.5
    end
end)

local st = inst("TextLabel", tt)
st.Size = UDim2.new(0, 0, 1, 0)
st.AutomaticSize = Enum.AutomaticSize.X
st.AnchorPoint = Vector2.new(0, 1)
st.Position = UDim2.new(1, 5, 0.9, 0)
st.Text = "加载器 v1.0"
st.TextColor3 = c_dim
st.BackgroundTransparency = 1
st.TextXAlignment = Enum.TextXAlignment.Left
st.TextYAlignment = Enum.TextYAlignment.Bottom
st.TextSize = 8
st.Font = Enum.Font.Gotham

local dv = inst("Frame", mf)
dv.Size = UDim2.new(1, 0, 0, 1)
dv.Position = UDim2.new(0, 0, 0, 28)
dv.BackgroundColor3 = c_stroke
dv.BorderSizePixel = 0

-- 内容区
local ca = inst("Frame", mf)
ca.Size = UDim2.new(1, -30, 0, 140)
ca.Position = UDim2.new(0, 15, 0, 40)
ca.BackgroundTransparency = 1

local pl = inst("TextLabel", ca)
pl.Size = UDim2.new(1, 0, 0, 25)
pl.Position = UDim2.new(0, 0, 0, 10)
pl.BackgroundTransparency = 1
pl.Text = "是否加载 XJW 中心脚本?"
pl.TextColor3 = c_text
pl.Font = Enum.Font.GothamMedium
pl.TextSize = 14
pl.TextXAlignment = Enum.TextXAlignment.Center

local dl = inst("TextLabel", ca)
dl.Size = UDim2.new(1, 0, 0, 20)
dl.Position = UDim2.new(0, 0, 0, 38)
dl.BackgroundTransparency = 1
dl.Text = "点击继续将加载主脚本"
dl.TextColor3 = c_dim
dl.Font = Enum.Font.Gotham
dl.TextSize = 11
dl.TextXAlignment = Enum.TextXAlignment.Center

local sl = inst("TextLabel", ca)
sl.Size = UDim2.new(1, 0, 0, 18)
sl.Position = UDim2.new(0, 0, 0, 65)
sl.BackgroundTransparency = 1
sl.Text = ""
sl.TextColor3 = c_theme
sl.Font = Enum.Font.Gotham
sl.TextSize = 10
sl.TextXAlignment = Enum.TextXAlignment.Center

-- 按钮容器
local bc = inst("Frame", mf)
bc.Size = UDim2.new(1, 0, 0, 40)
bc.Position = UDim2.new(0, 0, 0, 200)
bc.BackgroundTransparency = 1

local bl = inst("UIListLayout", bc)
bl.FillDirection = Enum.FillDirection.Horizontal
bl.HorizontalAlignment = Enum.HorizontalAlignment.Center
bl.VerticalAlignment = Enum.VerticalAlignment.Center
bl.Padding = UDim.new(0, 15)

-- 继续按钮
local cb = inst("TextButton", bc)
cb.Size = UDim2.new(0, 150, 0, 32)
cb.Text = ""
cb.BackgroundColor3 = c_bg
cb.AutoButtonColor = false
cb.BorderSizePixel = 0

inst("UICorner", cb).CornerRadius = UDim.new(0, 6)
local cs = inst("UIStroke", cb)
cs.Color = c_theme
cs.Thickness = 1

local ct = inst("TextLabel", cb)
ct.Size = UDim2.new(1, 0, 1, 0)
ct.BackgroundTransparency = 1
ct.Text = "继续加载"
ct.TextColor3 = c_text
ct.Font = Enum.Font.GothamMedium
ct.TextSize = 11

-- 取消按钮
local xb = inst("TextButton", bc)
xb.Size = UDim2.new(0, 110, 0, 32)
xb.Text = ""
xb.BackgroundColor3 = c_bg
xb.AutoButtonColor = false
xb.BorderSizePixel = 0

inst("UICorner", xb).CornerRadius = UDim.new(0, 6)
local xs = inst("UIStroke", xb)
xs.Color = c_stroke
xs.Thickness = 1

local xt = inst("TextLabel", xb)
xt.Size = UDim2.new(1, 0, 1, 0)
xt.BackgroundTransparency = 1
xt.Text = "取消"
xt.TextColor3 = c_dim
xt.Font = Enum.Font.GothamMedium
xt.TextSize = 11

-- 进度条
local pbg = inst("Frame", mf)
pbg.Size = UDim2.new(1, 0, 0, 2)
pbg.Position = UDim2.new(0, 0, 1, 0)
pbg.BackgroundColor3 = c_stroke
pbg.BorderSizePixel = 0

local pf = inst("Frame", pbg)
pf.Size = UDim2.new(0, 0, 0, 2)
pf.BackgroundColor3 = c_theme
pf.BorderSizePixel = 0

-- 按钮悬停
cb.MouseEnter:Connect(function() TweenService:Create(cb, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play() end)
cb.MouseLeave:Connect(function() TweenService:Create(cb, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play() end)
xb.MouseEnter:Connect(function() TweenService:Create(xb, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play() end)
xb.MouseLeave:Connect(function() TweenService:Create(xb, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play() end)

-- 继续按钮: 下载并执行
cb.MouseButton1Click:Connect(function()
    cb.Visible = false
    xb.Visible = false
    pl.Text = "正在加载..."
    dl.Text = "请稍候，正在连接服务器"
    sl.Text = "下载中..."
    sl.TextColor3 = c_theme

    -- 进度条动画
    TweenService:Create(pf, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 2)}):Play()

    task.spawn(function()
        -- 下载脚本
        local ok, content = pcall(function()
            return game:HttpGet(scriptUrl)
        end)

        if ok and content and #content > 0 then
            sl.Text = "加载完成!"
            sl.TextColor3 = c_success
            pf.Size = UDim2.new(1, 0, 0, 2)

            -- 淡出
            local fo = TweenService:Create(mf, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
            local fo2 = TweenService:Create(bd, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
            rs.Transparency = 1
            fo:Play()
            fo2:Play()
            fo.Completed:Wait()

            sg:Destroy()

            -- 执行脚本
            local fn = loadstring(content)
            if fn then fn() end
        else
            sl.Text = "加载失败!"
            sl.TextColor3 = c_error
            dl.Text = "无法连接服务器，请重试"
            pf.Size = UDim2.new(0, 0, 0, 2)
            cb.Visible = true
            xb.Visible = true
            pl.Text = "是否加载 XJW 中心脚本?"
        end
    end)
end)

-- 取消按钮
xb.MouseButton1Click:Connect(function()
    local fo = TweenService:Create(bd, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
    rs.Transparency = 1
    fo:Play()
    fo.Completed:Connect(function()
        sg:Destroy()
    end)
end)

-- 入场动画
mf.Size = UDim2.new(0, 440, 0, 0)
mf.Position = UDim2.new(0.5, -220, 0.5, 0)
mf.BackgroundTransparency = 1
bd.BackgroundTransparency = 1

local bdTween = TweenService:Create(bd, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5})
bdTween:Play()
bdTween.Completed:Connect(function()
    TweenService:Create(mf, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 440, 0, 260),
        Position = UDim2.new(0.5, -220, 0.5, -130),
        BackgroundTransparency = 0.03
    }):Play()
end)
