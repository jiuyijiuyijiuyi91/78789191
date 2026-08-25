local _kwIqKr60 = game:GetService("TweenService")
local _znLcf20 = game:GetService("UserInputService")
local _WVeOj65 = game:GetService("RunService")
local _xwLJbUao51 = game:GetService("CoreGui")
local _PnHpiLtK51 = Instance.new
local _tYHNawpU38 = "https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E8%87%AA%E5%88%B6%E8%84%9A%E6%9C%AC.lua"
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
local _vzvKe33 = Color3.fromRGB(30, 30, 30)
local _XyKhtK28 = Color3.fromRGB(40, 40, 40)
local _sshGC13 = Color3.fromRGB(88, 101, 242)
local _esKkznW27 = Color3.fromRGB(243, 243, 243)
local _glGATK73 = Color3.fromRGB(180, 180, 180)
local _fMfklv63 = Color3.fromRGB(220, 80, 80)
local _yabRCdph22 = Color3.fromRGB(80, 200, 120)
pcall(function()
    if _xwLJbUao51:FindFirstChild("XJWLoader") then
        _xwLJbUao51.XJWLoader:Destroy()
    end
end)
local function _JKJvf73(frame, hold)
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
    _znLcf20.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end
local _mwJcfPd61 = _PnHpiLtK51("ScreenGui")
_mwJcfPd61.Name = "XJWLoader"
_mwJcfPd61.Parent = _xwLJbUao51
_mwJcfPd61.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
_mwJcfPd61.ResetOnSpawn = false
local _ypsCeFR89 = _PnHpiLtK51("Frame")
_ypsCeFR89.Size = UDim2.new(1, 0, 1, 0)
_ypsCeFR89.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
_ypsCeFR89.BackgroundTransparency = 0.5
_ypsCeFR89.BorderSizePixel = 0
_ypsCeFR89.Parent = _mwJcfPd61
local _uruGl59 = _PnHpiLtK51("ImageButton")
_uruGl59.Size = UDim2.new(0, 440, 0, 260)
_uruGl59.Position = UDim2.new(0.5, -220, 0.5, -130)
_uruGl59.BackgroundColor3 = _vzvKe33
_uruGl59.BackgroundTransparency = 0.03
_uruGl59.BorderSizePixel = 0
_uruGl59.AutoButtonColor = false
_uruGl59.Parent = _ypsCeFR89
_PnHpiLtK51("UICorner", _uruGl59).CornerRadius = UDim.new(0, 6)
local _ECfhU24 = _PnHpiLtK51("UIGradient", _uruGl59)
_ECfhU24.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 25)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(32, 32, 32)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
})
_ECfhU24.Rotation = 45
local _jqxxk78 = _PnHpiLtK51("UIStroke", _uruGl59)
_jqxxk78.Thickness = 1.5
_jqxxk78.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
_jqxxk78.Transparency = 0.5
_jqxxk78.Color = _sshGC13
local _eSimJ87 = _PnHpiLtK51("UIGradient", _jqxxk78)
_eSimJ87.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, _sshGC13),
    ColorSequenceKeypoint.new(0.25, _sshGC13:Lerp(Color3.new(1, 1, 1), 0.3)),
    ColorSequenceKeypoint.new(0.5, _sshGC13),
    ColorSequenceKeypoint.new(0.75, _sshGC13:Lerp(Color3.new(0, 0, 0), 0.3)),
    ColorSequenceKeypoint.new(1, _sshGC13)
})
local _HLQfrcr65 = 0
_WVeOj65.Heartbeat:Connect(function(dt)
    if _jqxxk78 and _jqxxk78.Parent then
        _HLQfrcr65 = _HLQfrcr65 + dt * 40
        _eSimJ87.Rotation = _HLQfrcr65 % 360
    end
end)
_JKJvf73(_uruGl59)
local _hgoWBM57 = _PnHpiLtK51("Frame", _uruGl59)
_hgoWBM57.Size = UDim2.new(1, 0, 0, 28)
_hgoWBM57.BackgroundTransparency = 1
local _iyXitnJ48 = _PnHpiLtK51("ImageLabel", _hgoWBM57)
_iyXitnJ48.Size = UDim2.new(0, 18, 0, 18)
_iyXitnJ48.Position = UDim2.new(0, 15, 0.5, -9)
_iyXitnJ48.BackgroundTransparency = 1
_iyXitnJ48.Image = "rbxassetid://10734901364"
local _ONYrzj21 = _PnHpiLtK51("TextLabel", _hgoWBM57)
_ONYrzj21.Position = UDim2.new(0, 40, 0.5, 0)
_ONYrzj21.AnchorPoint = Vector2.new(0, 0.5)
_ONYrzj21.AutomaticSize = Enum.AutomaticSize.XY
_ONYrzj21.Text = "XJW 中心"
_ONYrzj21.TextXAlignment = Enum.TextXAlignment.Left
_ONYrzj21.TextSize = 12
_ONYrzj21.TextColor3 = Color3.new(1, 1, 1)
_ONYrzj21.BackgroundTransparency = 1
_ONYrzj21.Font = Enum.Font.GothamMedium
local _ZfEkT31 = _PnHpiLtK51("UIGradient", _ONYrzj21)
_ZfEkT31.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 40, 70)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(120, 30, 100)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 60, 180)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 100, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 80, 180))
})
local _wpwhGKXk44 = _PnHpiLtK51("UIStroke", _ONYrzj21)
_wpwhGKXk44.Color = Color3.fromRGB(80, 100, 180)
_wpwhGKXk44.Thickness = 1.2
_wpwhGKXk44.Transparency = 0.8
local _QWBjv73 = 0
_WVeOj65.Heartbeat:Connect(function(dt)
    if _ZfEkT31 and _ZfEkT31.Parent then
        _ZfEkT31.Rotation = (_ZfEkT31.Rotation + dt * 45) % 360
        _QWBjv73 = (_QWBjv73 + dt * 60) % 360
        local l = math.sin(math.rad(_QWBjv73)) * 0.2 + 0.8
        _wpwhGKXk44.Transparency = 0.3 + (1 - l) * 0.5
    end
end)
local _XnAloOZ73 = _PnHpiLtK51("TextLabel", _ONYrzj21)
_XnAloOZ73.Size = UDim2.new(0, 0, 1, 0)
_XnAloOZ73.AutomaticSize = Enum.AutomaticSize.X
_XnAloOZ73.AnchorPoint = Vector2.new(0, 1)
_XnAloOZ73.Position = UDim2.new(1, 5, 0.9, 0)
_XnAloOZ73.Text = "加载器 v1.0"
_XnAloOZ73.TextColor3 = _glGATK73
_XnAloOZ73.BackgroundTransparency = 1
_XnAloOZ73.TextXAlignment = Enum.TextXAlignment.Left
_XnAloOZ73.TextYAlignment = Enum.TextYAlignment.Bottom
_XnAloOZ73.TextSize = 8
_XnAloOZ73.Font = Enum.Font.Gotham
local _GANohfVQ36 = _PnHpiLtK51("Frame", _uruGl59)
_GANohfVQ36.Size = UDim2.new(1, 0, 0, 1)
_GANohfVQ36.Position = UDim2.new(0, 0, 0, 28)
_GANohfVQ36.BackgroundColor3 = _XyKhtK28
_GANohfVQ36.BorderSizePixel = 0
local _XrZvcHjy75 = _PnHpiLtK51("Frame", _uruGl59)
_XrZvcHjy75.Size = UDim2.new(1, -30, 0, 140)
_XrZvcHjy75.Position = UDim2.new(0, 15, 0, 40)
_XrZvcHjy75.BackgroundTransparency = 1
local _egwMfwT18 = _PnHpiLtK51("TextLabel", _XrZvcHjy75)
_egwMfwT18.Size = UDim2.new(1, 0, 0, 25)
_egwMfwT18.Position = UDim2.new(0, 0, 0, 10)
_egwMfwT18.BackgroundTransparency = 1
_egwMfwT18.Text = "是否加载 XJW 中心脚本?"
_egwMfwT18.TextColor3 = _esKkznW27
_egwMfwT18.Font = Enum.Font.GothamMedium
_egwMfwT18.TextSize = 14
_egwMfwT18.TextXAlignment = Enum.TextXAlignment.Center
local _XYOumz85 = _PnHpiLtK51("TextLabel", _XrZvcHjy75)
_XYOumz85.Size = UDim2.new(1, 0, 0, 20)
_XYOumz85.Position = UDim2.new(0, 0, 0, 38)
_XYOumz85.BackgroundTransparency = 1
_XYOumz85.Text = "点击继续将加载主脚本"
_XYOumz85.TextColor3 = _glGATK73
_XYOumz85.Font = Enum.Font.Gotham
_XYOumz85.TextSize = 11
_XYOumz85.TextXAlignment = Enum.TextXAlignment.Center
local _ctcWI74 = _PnHpiLtK51("TextLabel", _XrZvcHjy75)
_ctcWI74.Size = UDim2.new(1, 0, 0, 18)
_ctcWI74.Position = UDim2.new(0, 0, 0, 65)
_ctcWI74.BackgroundTransparency = 1
_ctcWI74.Text = ""
_ctcWI74.TextColor3 = _sshGC13
_ctcWI74.Font = Enum.Font.Gotham
_ctcWI74.TextSize = 10
_ctcWI74.TextXAlignment = Enum.TextXAlignment.Center
local _zqmQY11 = _PnHpiLtK51("Frame", _uruGl59)
_zqmQY11.Size = UDim2.new(1, 0, 0, 40)
_zqmQY11.Position = UDim2.new(0, 0, 0, 200)
_zqmQY11.BackgroundTransparency = 1
local _PkLRZ17 = _PnHpiLtK51("UIListLayout", _zqmQY11)
_PkLRZ17.FillDirection = Enum.FillDirection.Horizontal
_PkLRZ17.HorizontalAlignment = Enum.HorizontalAlignment.Center
_PkLRZ17.VerticalAlignment = Enum.VerticalAlignment.Center
_PkLRZ17.Padding = UDim.new(0, 15)
local _dmMsFmPs57 = _PnHpiLtK51("TextButton", _zqmQY11)
_dmMsFmPs57.Size = UDim2.new(0, 150, 0, 32)
_dmMsFmPs57.Text = ""
_dmMsFmPs57.BackgroundColor3 = _vzvKe33
_dmMsFmPs57.AutoButtonColor = false
_dmMsFmPs57.BorderSizePixel = 0
_PnHpiLtK51("UICorner", _dmMsFmPs57).CornerRadius = UDim.new(0, 6)
local _HGuqnclH81 = _PnHpiLtK51("UIStroke", _dmMsFmPs57)
_HGuqnclH81.Color = _sshGC13
_HGuqnclH81.Thickness = 1
local _ymXOuK37 = _PnHpiLtK51("TextLabel", _dmMsFmPs57)
_ymXOuK37.Size = UDim2.new(1, 0, 1, 0)
_ymXOuK37.BackgroundTransparency = 1
_ymXOuK37.Text = "继续加载"
_ymXOuK37.TextColor3 = _esKkznW27
_ymXOuK37.Font = Enum.Font.GothamMedium
_ymXOuK37.TextSize = 11
local _FfRpHYv72 = _PnHpiLtK51("TextButton", _zqmQY11)
_FfRpHYv72.Size = UDim2.new(0, 110, 0, 32)
_FfRpHYv72.Text = ""
_FfRpHYv72.BackgroundColor3 = _vzvKe33
_FfRpHYv72.AutoButtonColor = false
_FfRpHYv72.BorderSizePixel = 0
_PnHpiLtK51("UICorner", _FfRpHYv72).CornerRadius = UDim.new(0, 6)
local _rEmRC71 = _PnHpiLtK51("UIStroke", _FfRpHYv72)
_rEmRC71.Color = _XyKhtK28
_rEmRC71.Thickness = 1
local _sxYph69 = _PnHpiLtK51("TextLabel", _FfRpHYv72)
_sxYph69.Size = UDim2.new(1, 0, 1, 0)
_sxYph69.BackgroundTransparency = 1
_sxYph69.Text = "取消"
_sxYph69.TextColor3 = _glGATK73
_sxYph69.Font = Enum.Font.GothamMedium
_sxYph69.TextSize = 11
local _jUYIGy68 = _PnHpiLtK51("Frame", _uruGl59)
_jUYIGy68.Size = UDim2.new(1, 0, 0, 2)
_jUYIGy68.Position = UDim2.new(0, 0, 1, 0)
_jUYIGy68.BackgroundColor3 = _XyKhtK28
_jUYIGy68.BorderSizePixel = 0
local _dafIs12 = _PnHpiLtK51("Frame", _jUYIGy68)
_dafIs12.Size = UDim2.new(0, 0, 0, 2)
_dafIs12.BackgroundColor3 = _sshGC13
_dafIs12.BorderSizePixel = 0
_dmMsFmPs57.MouseEnter:Connect(function() _kwIqKr60:Create(_dmMsFmPs57, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play() end)
_dmMsFmPs57.MouseLeave:Connect(function() _kwIqKr60:Create(_dmMsFmPs57, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play() end)
_FfRpHYv72.MouseEnter:Connect(function() _kwIqKr60:Create(_FfRpHYv72, TweenInfo.new(0.2), {BackgroundTransparency = 0.4}):Play() end)
_FfRpHYv72.MouseLeave:Connect(function() _kwIqKr60:Create(_FfRpHYv72, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play() end)
_dmMsFmPs57.MouseButton1Click:Connect(function()
    _dmMsFmPs57.Visible = false
    _FfRpHYv72.Visible = false
    _egwMfwT18.Text = "正在加载..."
    _XYOumz85.Text = "请稍候，正在连接服务器"
    _ctcWI74.Text = "下载中..."
    _ctcWI74.TextColor3 = _sshGC13
    _kwIqKr60:Create(_dafIs12, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 2)}):Play()
    task.spawn(function()
        local ok, content = pcall(function()
            return game:HttpGet(_tYHNawpU38)
        end)
        if not ok or not content or #content == 0 then
            _ctcWI74.Text = "加载失败!"
            _ctcWI74.TextColor3 = _fMfklv63
            _XYOumz85.Text = "下载失败: " .. tostring(content)
            _dafIs12.Size = UDim2.new(0, 0, 0, 2)
            _dmMsFmPs57.Visible = true
            _FfRpHYv72.Visible = true
            _egwMfwT18.Text = "是否加载 XJW 中心脚本?"
            return
        end
        local fn, compileErr = loadstring(content)
        if not fn then
            _ctcWI74.Text = "编译失败!"
            _ctcWI74.TextColor3 = _fMfklv63
            _XYOumz85.Text = "编译错误: " .. tostring(compileErr)
            _dafIs12.Size = UDim2.new(0, 0, 0, 2)
            _dmMsFmPs57.Visible = true
            _FfRpHYv72.Visible = true
            _egwMfwT18.Text = "是否加载 XJW 中心脚本?"
            return
        end
        _ctcWI74.Text = "加载完成!"
        _ctcWI74.TextColor3 = _yabRCdph22
        _dafIs12.Size = UDim2.new(1, 0, 0, 2)
        local fo = _kwIqKr60:Create(_uruGl59, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
        local fo2 = _kwIqKr60:Create(_ypsCeFR89, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
        _jqxxk78.Transparency = 1
        fo:Play()
        fo2:Play()
        fo.Completed:Wait()
        _mwJcfPd61:Destroy()
        local runOk, runErr = pcall(fn)
        if not runOk then
            warn("[XJW加载器] 脚本运行错误: " .. tostring(runErr))
        end
    end)
end)
_FfRpHYv72.MouseButton1Click:Connect(function()
    local fo = _kwIqKr60:Create(_ypsCeFR89, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
    _jqxxk78.Transparency = 1
    fo:Play()
    fo.Completed:Connect(function()
        _mwJcfPd61:Destroy()
    end)
end)
_uruGl59.Size = UDim2.new(0, 440, 0, 0)
_uruGl59.Position = UDim2.new(0.5, -220, 0.5, 0)
_uruGl59.BackgroundTransparency = 1
_ypsCeFR89.BackgroundTransparency = 1
local bdTween = _kwIqKr60:Create(_ypsCeFR89, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5})
bdTween:Play()
bdTween.Completed:Connect(function()
    _kwIqKr60:Create(_uruGl59, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 440, 0, 260),
        Position = UDim2.new(0.5, -220, 0.5, -130),
        BackgroundTransparency = 0.03
    }):Play()
end)
