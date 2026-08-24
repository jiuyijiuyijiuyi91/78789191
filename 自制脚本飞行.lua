-- ============================================
-- XJW飞行 独立版 (经典彩色飞行V3)
-- 作者B站UID: 3706985503525348
-- 支持: R6/R15 / WASD控制 / 加速减速 / 最小化
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- 移除旧界面
pcall(function()
    local old = game.CoreGui:FindFirstChild("XJWFlyUI")
    if old then old:Destroy() end
    local old2 = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if old2 then
        local f = old2:FindFirstChild("XJWFlyUI")
        if f then f:Destroy() end
    end
end)

local flyState = {
    speeds = 1,
    nowe = false,
    tpwalking = false,
    tis = nil,
    dis = nil,
}

local speaker = Players.LocalPlayer

-- 创建飞行GUI
local function toggleFlyGui(show)
    pcall(function()
        if speaker.PlayerGui:FindFirstChild("XJWFlyUI") then
            speaker.PlayerGui.XJWFlyUI:Destroy()
        end
    end)
    if not show then return end

    local main = Instance.new("ScreenGui")
    main.Name = "XJWFlyUI"
    main.Parent = speaker:WaitForChild("PlayerGui")
    main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    main.ResetOnSpawn = false

    local Frame = Instance.new("Frame")
    Frame.Parent = main
    Frame.BackgroundColor3 = Color3.fromRGB(163, 255, 137)
    Frame.BorderColor3 = Color3.fromRGB(103, 221, 213)
    Frame.Position = UDim2.new(0.100320168, 0, 0.379746825, 0)
    Frame.Size = UDim2.new(0, 190, 0, 57)

    local up = Instance.new("TextButton")
    up.Parent = Frame
    up.BackgroundColor3 = Color3.fromRGB(79, 255, 152)
    up.Size = UDim2.new(0, 44, 0, 28)
    up.Font = Enum.Font.SourceSans
    up.Text = "向上"
    up.TextColor3 = Color3.fromRGB(0, 0, 0)
    up.TextSize = 14

    local down = Instance.new("TextButton")
    down.Parent = Frame
    down.BackgroundColor3 = Color3.fromRGB(215, 255, 121)
    down.Position = UDim2.new(0, 0, 0.491228074, 0)
    down.Size = UDim2.new(0, 44, 0, 28)
    down.Font = Enum.Font.SourceSans
    down.Text = "下降"
    down.TextColor3 = Color3.fromRGB(0, 0, 0)
    down.TextSize = 14

    local onof = Instance.new("TextButton")
    onof.Parent = Frame
    onof.BackgroundColor3 = Color3.fromRGB(255, 249, 74)
    onof.Position = UDim2.new(0.702823281, 0, 0.491228074, 0)
    onof.Size = UDim2.new(0, 56, 0, 28)
    onof.Font = Enum.Font.SourceSans
    onof.Text = "飞行"
    onof.TextColor3 = Color3.fromRGB(0, 0, 0)
    onof.TextSize = 14

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Parent = Frame
    titleLbl.BackgroundColor3 = Color3.fromRGB(242, 60, 255)
    titleLbl.Position = UDim2.new(0.469327301, 0, 0, 0)
    titleLbl.Size = UDim2.new(0, 100, 0, 28)
    titleLbl.Font = Enum.Font.SourceSans
    titleLbl.Text = "XJW飞行"
    titleLbl.TextColor3 = Color3.fromRGB(0, 0, 0)
    titleLbl.TextScaled = true
    titleLbl.TextSize = 14
    titleLbl.TextWrapped = true

    local plus = Instance.new("TextButton")
    plus.Parent = Frame
    plus.BackgroundColor3 = Color3.fromRGB(133, 145, 255)
    plus.Position = UDim2.new(0.231578946, 0, 0, 0)
    plus.Size = UDim2.new(0, 45, 0, 28)
    plus.Font = Enum.Font.SourceSans
    plus.Text = "加速"
    plus.TextColor3 = Color3.fromRGB(0, 0, 0)
    plus.TextScaled = true
    plus.TextSize = 14
    plus.TextWrapped = true

    local speedLbl = Instance.new("TextLabel")
    speedLbl.Parent = Frame
    speedLbl.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
    speedLbl.Position = UDim2.new(0.468421042, 0, 0.491228074, 0)
    speedLbl.Size = UDim2.new(0, 44, 0, 28)
    speedLbl.Font = Enum.Font.SourceSans
    speedLbl.Text = tostring(flyState.speeds)
    speedLbl.TextColor3 = Color3.fromRGB(0, 0, 0)
    speedLbl.TextScaled = true
    speedLbl.TextSize = 14
    speedLbl.TextWrapped = true

    local mine = Instance.new("TextButton")
    mine.Parent = Frame
    mine.BackgroundColor3 = Color3.fromRGB(123, 255, 247)
    mine.Position = UDim2.new(0.231578946, 0, 0.491228074, 0)
    mine.Size = UDim2.new(0, 45, 0, 29)
    mine.Font = Enum.Font.SourceSans
    mine.Text = "减速"
    mine.TextColor3 = Color3.fromRGB(0, 0, 0)
    mine.TextScaled = true
    mine.TextSize = 14
    mine.TextWrapped = true

    local closebutton = Instance.new("TextButton")
    closebutton.Name = "Close"
    closebutton.Parent = Frame
    closebutton.BackgroundColor3 = Color3.fromRGB(225, 25, 0)
    closebutton.Font = Enum.Font.SourceSans
    closebutton.Size = UDim2.new(0, 45, 0, 28)
    closebutton.Text = "X"
    closebutton.TextColor3 = Color3.fromRGB(0, 0, 0)
    closebutton.TextSize = 30
    closebutton.Position = UDim2.new(0, 0, -1, 27)

    local mini = Instance.new("TextButton")
    mini.Name = "minimize"
    mini.Parent = Frame
    mini.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
    mini.Font = Enum.Font.SourceSans
    mini.Size = UDim2.new(0, 45, 0, 28)
    mini.Text = "-"
    mini.TextColor3 = Color3.fromRGB(0, 0, 0)
    mini.TextSize = 40
    mini.Position = UDim2.new(0, 44, -1, 27)

    local mini2 = Instance.new("TextButton")
    mini2.Name = "minimize2"
    mini2.Parent = Frame
    mini2.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
    mini2.Font = Enum.Font.SourceSans
    mini2.Size = UDim2.new(0, 45, 0, 28)
    mini2.Text = "+"
    mini2.TextColor3 = Color3.fromRGB(0, 0, 0)
    mini2.TextSize = 40
    mini2.Position = UDim2.new(0, 44, -1, 57)
    mini2.Visible = false

    Frame.Active = true
    Frame.Draggable = true

    -- 飞行开关
    onof.MouseButton1Down:Connect(function()
        if flyState.nowe == true then
            flyState.nowe = false
            flyState.tpwalking = false

            local chr = speaker.Character
            local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
            if hum then
                for _, st in pairs(Enum.HumanoidStateType:GetEnumItems()) do
                    pcall(function() hum:SetStateEnabled(st, true) end)
                end
                hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            end
            local anim = chr and chr:FindFirstChild("Animate")
            if anim then anim.Disabled = false end
        else
            flyState.nowe = true

            -- 瞬移行走线程
            for i = 1, flyState.speeds do
                task.spawn(function()
                    local hb = RunService.Heartbeat
                    flyState.tpwalking = true
                    local chr = speaker.Character
                    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                    while flyState.tpwalking and hb:Wait() and chr and hum and hum.Parent do
                        if hum.MoveDirection.Magnitude > 0 then
                            chr:TranslateBy(hum.MoveDirection)
                        end
                    end
                end)
            end

            local chr = speaker.Character
            local anim = chr and chr:FindFirstChild("Animate")
            if anim then anim.Disabled = true end
            local hum = chr and chr:FindFirstChildOfClass("Humanoid")
            if hum then
                for _, t in pairs(hum:GetPlayingAnimationTracks()) do
                    pcall(function() t:AdjustSpeed(0) end)
                end
                for _, st in pairs(Enum.HumanoidStateType:GetEnumItems()) do
                    pcall(function() hum:SetStateEnabled(st, false) end)
                end
                hum:ChangeState(Enum.HumanoidStateType.Swimming)
            end
        end

        -- R6 / R15 飞行
        local rigHum = speaker.Character and speaker.Character:FindFirstChildOfClass("Humanoid")
        if rigHum and rigHum.RigType == Enum.HumanoidRigType.R6 then
            local torso = speaker.Character:FindFirstChild("Torso")
            if not torso then return end

            local bg = Instance.new("BodyGyro", torso)
            bg.P = 9e4
            bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.cframe = torso.CFrame

            local bv = Instance.new("BodyVelocity", torso)
            bv.velocity = Vector3.new(0, 0.1, 0)
            bv.maxForce = Vector3.new(9e9, 9e9, 9e9)

            if flyState.nowe then
                rigHum.PlatformStand = true
            end

            local ctrl = {f = 0, b = 0, l = 0, r = 0}
            local lastctrl = {f = 0, b = 0, l = 0, r = 0}
            local maxspeed = 50
            local speed = 0

            -- 键盘控制
            local keyConn = UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.W then ctrl.f = 1 end
                if input.KeyCode == Enum.KeyCode.S then ctrl.b = -1 end
                if input.KeyCode == Enum.KeyCode.A then ctrl.l = -1 end
                if input.KeyCode == Enum.KeyCode.D then ctrl.r = 1 end
            end)
            local keyConn2 = UserInputService.InputEnded:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.W then ctrl.f = 0 end
                if input.KeyCode == Enum.KeyCode.S then ctrl.b = 0 end
                if input.KeyCode == Enum.KeyCode.A then ctrl.l = 0 end
                if input.KeyCode == Enum.KeyCode.D then ctrl.r = 0 end
            end)

            while flyState.nowe and rigHum and rigHum.Parent and rigHum.Health > 0 do
                RunService.RenderStepped:Wait()

                if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                    speed = speed + 0.5 + (speed / maxspeed)
                    if speed > maxspeed then speed = maxspeed end
                elseif speed ~= 0 then
                    speed = speed - 1
                    if speed < 0 then speed = 0 end
                end

                local cam = workspace.CurrentCamera
                if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                    bv.velocity = ((cam.CoordinateFrame.lookVector * (ctrl.f + ctrl.b)) + ((cam.CoordinateFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).p) - cam.CoordinateFrame.p)) * speed
                    lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
                elseif speed ~= 0 then
                    bv.velocity = ((cam.CoordinateFrame.lookVector * (lastctrl.f + lastctrl.b)) + ((cam.CoordinateFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).p) - cam.CoordinateFrame.p)) * speed
                else
                    bv.velocity = Vector3.new(0, 0, 0)
                end

                bg.cframe = cam.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / maxspeed), 0, 0)
            end

            if keyConn then keyConn:Disconnect() end
            if keyConn2 then keyConn2:Disconnect() end
            bg:Destroy()
            bv:Destroy()
            rigHum.PlatformStand = false
            local anim2 = speaker.Character and speaker.Character:FindFirstChild("Animate")
            if anim2 then anim2.Disabled = false end
            flyState.tpwalking = false
        else
            -- R15
            local UpperTorso = speaker.Character:FindFirstChild("UpperTorso")
            if not UpperTorso then return end

            local bg = Instance.new("BodyGyro", UpperTorso)
            bg.P = 9e4
            bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.cframe = UpperTorso.CFrame

            local bv = Instance.new("BodyVelocity", UpperTorso)
            bv.velocity = Vector3.new(0, 0.1, 0)
            bv.maxForce = Vector3.new(9e9, 9e9, 9e9)

            if flyState.nowe then
                rigHum.PlatformStand = true
            end

            local ctrl = {f = 0, b = 0, l = 0, r = 0}
            local lastctrl = {f = 0, b = 0, l = 0, r = 0}
            local maxspeed = 50
            local speed = 0

            local keyConn = UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.W then ctrl.f = 1 end
                if input.KeyCode == Enum.KeyCode.S then ctrl.b = -1 end
                if input.KeyCode == Enum.KeyCode.A then ctrl.l = -1 end
                if input.KeyCode == Enum.KeyCode.D then ctrl.r = 1 end
            end)
            local keyConn2 = UserInputService.InputEnded:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.W then ctrl.f = 0 end
                if input.KeyCode == Enum.KeyCode.S then ctrl.b = 0 end
                if input.KeyCode == Enum.KeyCode.A then ctrl.l = 0 end
                if input.KeyCode == Enum.KeyCode.D then ctrl.r = 0 end
            end)

            while flyState.nowe and rigHum and rigHum.Parent and rigHum.Health > 0 do
                wait()

                if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                    speed = speed + 0.5 + (speed / maxspeed)
                    if speed > maxspeed then speed = maxspeed end
                elseif speed ~= 0 then
                    speed = speed - 1
                    if speed < 0 then speed = 0 end
                end

                local cam = workspace.CurrentCamera
                if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                    bv.velocity = ((cam.CoordinateFrame.lookVector * (ctrl.f + ctrl.b)) + ((cam.CoordinateFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).p) - cam.CoordinateFrame.p)) * speed
                    lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
                elseif speed ~= 0 then
                    bv.velocity = ((cam.CoordinateFrame.lookVector * (lastctrl.f + lastctrl.b)) + ((cam.CoordinateFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).p) - cam.CoordinateFrame.p)) * speed
                else
                    bv.velocity = Vector3.new(0, 0, 0)
                end

                bg.cframe = cam.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / maxspeed), 0, 0)
            end

            if keyConn then keyConn:Disconnect() end
            if keyConn2 then keyConn2:Disconnect() end
            bg:Destroy()
            bv:Destroy()
            rigHum.PlatformStand = false
            local anim2 = speaker.Character and speaker.Character:FindFirstChild("Animate")
            if anim2 then anim2.Disabled = false end
            flyState.tpwalking = false
        end
    end)

    -- 上升按钮
    up.MouseButton1Down:Connect(function()
        flyState.tis = up.MouseEnter:Connect(function()
            while flyState.tis do
                wait()
                local hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(0, 1, 0) end
            end
        end)
    end)
    up.MouseLeave:Connect(function()
        if flyState.tis then flyState.tis:Disconnect() flyState.tis = nil end
    end)

    -- 下降按钮
    down.MouseButton1Down:Connect(function()
        flyState.dis = down.MouseEnter:Connect(function()
            while flyState.dis do
                wait()
                local hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = hrp.CFrame * CFrame.new(0, -1, 0) end
            end
        end)
    end)
    down.MouseLeave:Connect(function()
        if flyState.dis then flyState.dis:Disconnect() flyState.dis = nil end
    end)

    -- 加速
    plus.MouseButton1Down:Connect(function()
        flyState.speeds = flyState.speeds + 1
        speedLbl.Text = tostring(flyState.speeds)
        if flyState.nowe then
            flyState.tpwalking = false
            for i = 1, flyState.speeds do
                task.spawn(function()
                    local hb = RunService.Heartbeat
                    flyState.tpwalking = true
                    local chr = speaker.Character
                    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                    while flyState.tpwalking and hb:Wait() and chr and hum and hum.Parent do
                        if hum.MoveDirection.Magnitude > 0 then
                            chr:TranslateBy(hum.MoveDirection)
                        end
                    end
                end)
            end
        end
    end)

    -- 减速
    mine.MouseButton1Down:Connect(function()
        if flyState.speeds <= 1 then
            speedLbl.Text = "最小1"
            task.wait(1)
            speedLbl.Text = tostring(flyState.speeds)
        else
            flyState.speeds = flyState.speeds - 1
            speedLbl.Text = tostring(flyState.speeds)
            if flyState.nowe then
                flyState.tpwalking = false
                for i = 1, flyState.speeds do
                    task.spawn(function()
                        local hb = RunService.Heartbeat
                        flyState.tpwalking = true
                        local chr = speaker.Character
                        local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                        while flyState.tpwalking and hb:Wait() and chr and hum and hum.Parent do
                            if hum.MoveDirection.Magnitude > 0 then
                                chr:TranslateBy(hum.MoveDirection)
                            end
                        end
                    end)
                end
            end
        end
    end)

    -- 关闭
    closebutton.MouseButton1Click:Connect(function()
        flyState.nowe = false
        flyState.tpwalking = false
        pcall(function()
            local chr = speaker.Character
            local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
            if hum then
                for _, st in pairs(Enum.HumanoidStateType:GetEnumItems()) do
                    pcall(function() hum:SetStateEnabled(st, true) end)
                end
                hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
                hum.PlatformStand = false
            end
            local anim = chr and chr:FindFirstChild("Animate")
            if anim then anim.Disabled = false end
        end)
        main:Destroy()
    end)

    -- 最小化
    mini.MouseButton1Click:Connect(function()
        up.Visible = false
        down.Visible = false
        onof.Visible = false
        plus.Visible = false
        speedLbl.Visible = false
        mine.Visible = false
        mini.Visible = false
        mini2.Visible = true
        Frame.BackgroundTransparency = 1
        closebutton.Position = UDim2.new(0, 0, -1, 57)
    end)

    -- 恢复
    mini2.MouseButton1Click:Connect(function()
        up.Visible = true
        down.Visible = true
        onof.Visible = true
        plus.Visible = true
        speedLbl.Visible = true
        mine.Visible = true
        mini.Visible = true
        mini2.Visible = false
        Frame.BackgroundTransparency = 0
        closebutton.Position = UDim2.new(0, 0, -1, 27)
    end)
end

-- 角色重生时恢复
speaker.CharacterAdded:Connect(function(char)
    task.wait(0.7)
    pcall(function()
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            hum.PlatformStand = false
            for _, st in pairs(Enum.HumanoidStateType:GetEnumItems()) do
                pcall(function() hum:SetStateEnabled(st, true) end)
            end
        end
        local anim = char:FindFirstChild("Animate")
        if anim then anim.Disabled = false end
    end)
    flyState.nowe = false
    flyState.tpwalking = false
end)

-- 启动飞行面板
toggleFlyGui(true)
