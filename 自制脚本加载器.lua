-- XJW中心 加载器 v3.2 (混淆兼容版 - 极简加载逻辑)
-- 策略: UI部分正常写, 加载逻辑只用最简单的同步调用, 无嵌套回调

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- 缓存全局函数
local inst = Instance.new
local tspawn = task.spawn
local twait = task.wait
local pcall = pcall
local loadstr = loadstring
local _game = game  -- 缓存game对象, 防止混淆器VM重新包装

-- 关键: 缓存HTTP函数引用本身, 不用方法调用语法
local httpGet = game.HttpGet

-- 备用HTTP函数 (不同执行器提供不同的)
local httpRequest = nil
pcall(function()
    httpRequest = (syn and syn.request) or (http_request) or (request) or nil
end)

-- ============================================
-- 关键: 注入安全加载函数到全局环境
-- 这些引用在混淆器VM启动时就已缓存, 是真正的原生函数
-- XJW中心从GitHub加载后, 优先使用这个注入的函数
-- 防止混淆器VM包装全局环境后game:HttpGet失效
-- ============================================
_G.XJW_safeLoad = function(url)
    -- 方式1: 缓存的函数引用
    local ok, content = pcall(httpGet, _game, url)
    -- 方式2: request备用
    if not ok or not content or #content == 0 then
        if httpRequest then
            local r1, r2 = pcall(httpRequest, {Url = url, Method = "GET"})
            if r1 and r2 and type(r2) == "table" and r2.Body then
                ok, content = true, r2.Body
            end
        end
    end
    -- 方式3: 直接方法调用兜底
    if not ok or not content or #content == 0 then
        ok, content = pcall(function()
            return _game:HttpGet(url)
        end)
    end
    -- 编译并执行
    if ok and content and #content > 0 then
        local fn = loadstr(content)
        if fn then
            return fn()
        end
    end
end

-- 同时注入到shared (部分混淆器可能修改_G但不修改shared)
shared = shared or {}
shared.XJW_safeLoad = _G.XJW_safeLoad

-- 配色
local c_bg = Color3.fromRGB(30, 30, 30)
local c_stroke = Color3.fromRGB(40, 40, 40)
local c_theme = Color3.fromRGB(88, 101, 242)
local c_text = Color3.fromRGB(243, 243, 243)
local c_dim = Color3.fromRGB(180, 180, 180)

-- 移除旧界面
pcall(function()
    local old = CoreGui:FindFirstChild("XJWLoader")
    if old then old:Destroy() end
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

tspawn(function()
    while rs and rs.Parent do
        rg.Rotation = (rg.Rotation + 0.64) % 360
        task.wait()
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

tspawn(function()
    local la = 0
    while tg and tg.Parent do
        tg.Rotation = (tg.Rotation + 0.72) % 360
        la = (la + 0.96) % 360
        local l = math.sin(math.rad(la)) * 0.2 + 0.8
        tgl.Transparency = 0.3 + (1 - l) * 0.5
        task.wait()
    end
end)

local st = inst("TextLabel", tt)
st.Size = UDim2.new(0, 0, 1, 0)
st.AutomaticSize = Enum.AutomaticSize.X
st.AnchorPoint = Vector2.new(0, 1)
st.Position = UDim2.new(1, 5, 0.9, 0)
st.Text = "加载器 v3.2"
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

-- 内容
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

-- 按钮
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

-- 悬停
cb.MouseEnter:Connect(function() TweenService:Create(cb, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play() end)
cb.MouseLeave:Connect(function() TweenService:Create(cb, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play() end)
xb.MouseEnter:Connect(function() TweenService:Create(xb, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play() end)
xb.MouseLeave:Connect(function() TweenService:Create(xb, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play() end)

-- 脚本URL
local url = "https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E8%87%AA%E5%88%B6%E8%84%9A%E6%9C%AC.lua"

-- ============================================
-- 加载逻辑: 极简版, 无嵌套回调, 混淆安全
-- ============================================
cb.MouseButton1Click:Connect(function()
    cb.Visible = false
    xb.Visible = false
    pl.Text = "正在加载..."
    dl.Text = "请稍候，正在连接服务器"
    sl.Text = "下载中..."

    -- 进度条动画
    local pt = TweenService:Create(pf, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 2)})
    pt:Play()

    -- 同步下载脚本 (用缓存的函数引用 + 缓存的_game)
    local ok, content = pcall(httpGet, _game, url)
    
    -- 备用HTTP方式
    if not ok and httpRequest then
        local resp = httpRequest({Url = url, Method = "GET"})
        if resp and resp.Body then
            ok, content = true, resp.Body
        end
    end

    if ok and content and #content > 0 then
        sl.Text = "加载完成!"
        pf.Size = UDim2.new(1, 0, 0, 2)

        -- 淡出动画
        local fo = TweenService:Create(mf, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
        local fo2 = TweenService:Create(bd, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
        rs.Transparency = 1
        fo:Play()
        fo2:Play()

        -- 用回调代替Wait(), 混淆安全
        fo.Completed:Connect(function()
            sg:Destroy()
            -- 分两步: 先编译, 再执行
            local fn = loadstr(content)
            if fn then
                pcall(fn)
            end
        end)
    else
        sl.Text = "加载失败!"
        sl.TextColor3 = Color3.fromRGB(220, 80, 80)
        dl.Text = "无法连接服务器，请重试"
        pf.Size = UDim2.new(0, 0, 0, 2)
        cb.Visible = true
        xb.Visible = true
        pl.Text = "是否加载 XJW 中心脚本?"
        sl.Text = ""
        sl.TextColor3 = c_theme
    end
end)

-- 取消
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
-- 用回调代替twait, 混淆安全
bdTween.Completed:Connect(function()
    TweenService:Create(mf, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 440, 0, 260), Position = UDim2.new(0.5, -220, 0.5, -130), BackgroundTransparency = 0.03}):Play()
end)
