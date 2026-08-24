local P = game:GetService("Players").LocalPlayer
local PlayerGui = P:FindFirstChild("PlayerGui") or P:WaitForChild("PlayerGui", 10)
local S = game:GetService("RunService")
local Players = game:GetService("Players")

if PlayerGui:FindFirstChild("TerukumaAntiStiff") then 
    PlayerGui.TerukumaAntiStiff:Destroy() 
end

local isActive = false 

S.Stepped:Connect(function()
    local char = P.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if hum and hrp then
        hum.PlatformStand = false
        hum.Sit = false
        
        hum.AutoRotate = true

        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Physics or 
           state == Enum.HumanoidStateType.FallingDown or 
           state == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    if isActive then
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer ~= P and otherPlayer.Character then
                for _, part in pairs(otherPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        S.Heartbeat:Wait()
        
        if isActive and P.Character and P.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = P.Character.HumanoidRootPart
            local hum = P.Character:FindFirstChildOfClass("Humanoid")
            
            local currentVel = hrp.AssemblyLinearVelocity
            
            hum:ChangeState(Enum.HumanoidStateType.Running)
            
            local safeY = currentVel.Y
            if safeY > 40 then safeY = 40 end
            if safeY < -40 then safeY = -40 end
            
            hrp.AssemblyAngularVelocity = Vector3.new(50000, 50000, 50000)
            
            hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X * 1.1, safeY, currentVel.Z * 1.1)
            
            S.RenderStepped:Wait()
            
            if hrp then
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, safeY, currentVel.Z)
            end
        end
    end
end)

local g = Instance.new("ScreenGui", PlayerGui)
g.Name = "TerukumaAntiStiff"
g.ResetOnSpawn = false

local f = Instance.new("Frame", g)
f.Size = UDim2.new(0, 90, 0, 90)
f.Position = UDim2.new(0.9, 0, 0.45, 0)
f.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
f.Active = true
f.Draggable = true
Instance.new("UICorner", f)

local l = Instance.new("TextLabel", f)
l.Size = UDim2.new(1, 0, 0, 35)
l.Text = "静默甩飞 by说痛的话"
l.TextColor3 = Color3.fromRGB(255, 200, 0)
l.TextSize = 12
l.Font = Enum.Font.SourceSansBold
l.BackgroundTransparency = 1

local btn = Instance.new("TextButton", f)
btn.Size = UDim2.new(0.85, 0, 0, 45)
btn.Position = UDim2.new(0.075, 0, 0, 35)
btn.Text = "OFF"
btn.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.SourceSansBold
btn.TextSize = 18
Instance.new("UICorner", btn)

btn.MouseButton1Click:Connect(function()
    isActive = not isActive
    if isActive then
        btn.Text = "ON"
        btn.BackgroundColor3 = Color3.fromRGB(20, 100, 20)
    else
        btn.Text = "OFF"
        btn.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
    end
end)