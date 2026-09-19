local Players = game:GetService("Players")
pcall(function()
local core = game:GetService("CoreGui")
local old = core:FindFirstChild("AuroraAimUI")
while old do
old:Destroy()
old = core:FindFirstChild("AuroraAimUI")
end
end)
pcall(function()
if Drawing and Drawing.GetDrawings then
for _, d in ipairs(Drawing:GetDrawings()) do
pcall(function() d:Remove() end)
end
end
end)
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ESPEnabled = false
local ESPBox = false
local ESPTracer = false
local ESPName = false
local ESPDistance = false
local ESPHealth = false
local ESPHeadDot = false
local ESPTeamCheck = false
local ESPDeadStop = true
local AimbotEnabled = false
local LockMode = "普通"
local AimPart = "Head"
local PriorityMode = "准星最近"
local TeamCheck = false
local WallCheck = false
local FOVSize = 150
local Smoothness = 10
local ShowFOV = false
local AutoShoot = false
local PredictionAmount = 0
local RequireWeapon = false
local IncludeNPCs = false
local SpecificTarget = nil
local Blacklist = {}
local aimbotTarget = nil
local targetVelocity = Vector3.zero
local lastTargetPosition = Vector3.zero
local lastUpdateTime = 0
local fovCircle
local function CreateFOVCircle()
pcall(function()
if fovCircle then
fovCircle:Remove()
fovCircle = nil
end
end)
local success, result = pcall(function()
local circle = Drawing.new("Circle")
circle.Visible = false;circle.Radius = FOVSize;circle.Color = Color3.fromRGB(255, 60, 60);circle.Filled = false;circle.Thickness = 2;circle.NumSides = 80;circle.Transparency = 0.6;circle.ZIndex = 999
return circle
end)
if success and result then
fovCircle = result
end
end
CreateFOVCircle()
local ESPData = {}
local function CreateESP(obj)
if ESPData[obj] then return ESPData[obj] end
local boxOutline = Drawing.new("Square")
boxOutline.Visible = false;boxOutline.Color = Color3.fromRGB(0, 0, 0);boxOutline.Thickness = 3;boxOutline.Filled = false;boxOutline.ZIndex = 2
local box = Drawing.new("Square")
box.Visible = false;box.Color = Color3.fromRGB(255, 50, 50);box.Thickness = 1.5;box.Filled = false;box.ZIndex = 3
local healthText = Drawing.new("Text")
healthText.Visible = false;healthText.Color = Color3.fromRGB(255, 255, 255);healthText.Size = 12;healthText.Center = true;healthText.Outline = true;healthText.Font = 2;healthText.ZIndex = 3
local tracer = Drawing.new("Line")
tracer.Visible = false;tracer.Color = Color3.fromRGB(255, 80, 80);tracer.Thickness = 0.8;tracer.Transparency = 0.4;tracer.ZIndex = 1
local nameText = Drawing.new("Text")
nameText.Visible = false;nameText.Color = Color3.fromRGB(255, 255, 255);nameText.Size = 13;nameText.Center = true;nameText.Outline = true;nameText.Font = 2;nameText.ZIndex = 3
local distText = Drawing.new("Text")
distText.Visible = false;distText.Color = Color3.fromRGB(200, 200, 200);distText.Size = 12;distText.Center = true;distText.Outline = true;distText.Font = 2;distText.ZIndex = 3
local headDot = Drawing.new("Circle")
headDot.Visible = false;headDot.Color = Color3.fromRGB(255, 200, 50);headDot.Filled = true;headDot.Radius = 5;headDot.NumSides = 16;headDot.ZIndex = 3
ESPData[obj] = {
boxOutline = boxOutline,
box = box,
healthText = healthText,
tracer = tracer,
nameText = nameText,
distText = distText,
headDot = headDot
}
return ESPData[obj]
end
local function IsSameTeam(obj)
if not obj or not LocalPlayer then return false end
if obj:IsA("Player") then
local success, result = pcall(function()
return obj.Team and LocalPlayer.Team and obj.Team == LocalPlayer.Team
end)
return success and result
end
if obj:IsA("Model") or obj:IsA("BasePart") then
local teamColor = obj:FindFirstChild("TeamColor")
if teamColor and LocalPlayer.Team then
return teamColor.Value == LocalPlayer.Team.TeamColor
end
local teamTag = obj:FindFirstChild("Team")
if teamTag and LocalPlayer.Team then
return tostring(teamTag.Value) == tostring(LocalPlayer.Team)
end
end
return false
end
local function IsNPC(obj)
if obj:IsA("Player") then
local success, isBot = pcall(function()
return obj:GetAttribute("IsBot") or obj:GetAttribute("Bot") or obj.UserId == 0
end)
return success and isBot
end
return false
end
local function HasWeapon()
local char = LocalPlayer.Character
if not char then return false end
for _, tool in pairs(char:GetChildren()) do
if tool:IsA("Tool") then
if tool:FindFirstChild("Handle") then
if tool:FindFirstChild("Ammo") or tool:FindFirstChild("Magazine") or
tool:FindFirstChild("FireMode") or tool:FindFirstChild("Bullets") or
tool:FindFirstChild("Damage") or tool:FindFirstChild("MaxAmmo") or
tool.ClassName == "Tool" then
return true
end
end
end
end
return false
end
local function isPartVisible(part, customOrigin)
if not part then return false end
local localCharacter = LocalPlayer.Character
if not localCharacter then return false end
local origin = customOrigin or Camera.CFrame.Position
local direction = part.Position - origin
local distance = direction.Magnitude
if distance <= 0 then return false end
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
local descendants = {}
if localCharacter then
for _, v in ipairs(localCharacter:GetDescendants()) do
if v:IsA("BasePart") then
table.insert(descendants, v)
end
end
end
if part.Parent then
for _, v in ipairs(part.Parent:GetDescendants()) do
if v:IsA("BasePart") then
table.insert(descendants, v)
end
end
end
raycastParams.FilterDescendantsInstances = descendants
local raycastResult = workspace:Raycast(origin, direction.Unit * distance, raycastParams)
return raycastResult == nil
end
local function GetCharacterFromObject(obj)
if obj:IsA("Player") then
return obj.Character
elseif obj:IsA("Model") then
if obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
return obj
end
elseif obj:IsA("BasePart") and obj.Parent then
local model = obj.Parent
if model:IsA("Model") and model:FindFirstChild("Humanoid") then
return model
end
end
return nil
end
local TweenService = game:GetService("TweenService")
local function tw(obj, props, dur, ease)
TweenService:Create(obj, TweenInfo.new(dur, ease or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end
local C_BG = Color3.fromRGB(7, 11, 20)
local C_CARD = Color3.fromRGB(17, 26, 46)
local C_CARD2 = Color3.fromRGB(13, 20, 38)
local C_ACC = Color3.fromRGB(59, 130, 246)
local C_ACCL = Color3.fromRGB(96, 165, 250)
local C_ACCS = Color3.fromRGB(147, 197, 253)
local C_TEXT = Color3.fromRGB(248, 250, 252)
local C_SUB = Color3.fromRGB(147, 164, 191)
local C_DANGER = Color3.fromRGB(239, 68, 68)
local C_OK = Color3.fromRGB(34, 197, 94)
local C_OFF = Color3.fromRGB(30, 41, 59)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game:GetService("CoreGui");ScreenGui.ResetOnSpawn = false;ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;ScreenGui.Name = "AuroraAimUI"
local FloatBorder = Instance.new("Frame")
FloatBorder.Size = UDim2.new(0, 64, 0, 64);FloatBorder.Position = UDim2.new(0, 21, 0.5, -32);FloatBorder.BackgroundColor3 = C_ACC;FloatBorder.BorderSizePixel = 0;FloatBorder.Parent = ScreenGui;FloatBorder.ZIndex = 99
Instance.new("UICorner", FloatBorder).CornerRadius = UDim.new(1, 0)
local fbGrad = Instance.new("UIGradient", FloatBorder)
local fbScale = Instance.new("UIScale", FloatBorder)
local FloatGlow = Instance.new("Frame")
FloatGlow.Size = UDim2.new(0, 72, 0, 72);FloatGlow.Position = UDim2.new(0, 18, 0.5, -36);FloatGlow.BackgroundColor3 = C_ACC;FloatGlow.BackgroundTransparency = 0.85;FloatGlow.BorderSizePixel = 0;FloatGlow.Parent = ScreenGui;FloatGlow.ZIndex = 98
Instance.new("UICorner", FloatGlow).CornerRadius = UDim.new(1, 0)
local fbGlowGrad = Instance.new("UIGradient", FloatGlow)
local fbGlowScale = Instance.new("UIScale", FloatGlow)
fbGrad.Rotation = 45
fbGlowGrad.Rotation = 45
fbGrad.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 160)),
ColorSequenceKeypoint.new(0.17, Color3.fromRGB(190, 80, 255)),
ColorSequenceKeypoint.new(0.34, Color3.fromRGB(110, 130, 255)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 190, 255)),
ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 220, 235)),
ColorSequenceKeypoint.new(0.84, Color3.fromRGB(160, 90, 255)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 160)),
})
fbGlowGrad.Color = fbGrad.Color
local rs = game:GetService("RunService")
task.spawn(function()
local lastT = os.clock()
while fbGrad and fbGrad.Parent do
local ok = pcall(function()
local now = os.clock()
local dt = math.min(now - lastT, 0.1)
lastT = now
local rot = (fbGrad.Rotation + dt * 150) % 360
fbGrad.Rotation = rot
fbGlowGrad.Rotation = rot
end)
if not ok then task.wait(0.05) end
rs.RenderStepped:Wait()
end
end)
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 58, 0, 58);FloatBtn.Position = UDim2.new(0, 24, 0.5, -29);FloatBtn.Text = "";FloatBtn.BackgroundColor3 = C_CARD;FloatBtn.BackgroundTransparency = 0.3;FloatBtn.BorderSizePixel = 0;FloatBtn.Parent = ScreenGui;FloatBtn.ZIndex = 100
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)
local fbBgGrad = Instance.new("UIGradient", FloatBtn)
fbBgGrad.Rotation = 135
fbBgGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(52, 68, 104)), ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 19, 36))})
local fbStroke = Instance.new("UIStroke", FloatBtn)
fbStroke.Color = Color3.fromRGB(255, 255, 255);fbStroke.Thickness = 1;fbStroke.Transparency = 0.82
local FloatScale = Instance.new("UIScale", FloatBtn)
local FloatLabel = Instance.new("TextLabel")
FloatLabel.Size = UDim2.new(1, 0, 1, 0);FloatLabel.BackgroundTransparency = 1;FloatLabel.Text = "XJW";FloatLabel.TextColor3 = C_ACCS;FloatLabel.Font = Enum.Font.Gotham;FloatLabel.TextSize = 26;FloatLabel.Parent = FloatBtn;FloatLabel.ZIndex = 101

local MainBorder = Instance.new("Frame")
MainBorder.Size = UDim2.new(0, 684, 0, 294);MainBorder.Position = UDim2.new(0.5, -342, 0.5, -147);MainBorder.BackgroundColor3 = C_ACC;MainBorder.BorderSizePixel = 0;MainBorder.Parent = ScreenGui;MainBorder.ZIndex = 9
Instance.new("UICorner", MainBorder).CornerRadius = UDim.new(0, 18)
local mbGrad = Instance.new("UIGradient", MainBorder)
local mbScale = Instance.new("UIScale", MainBorder)
local MainGlow = Instance.new("Frame")
MainGlow.Size = UDim2.new(0, 694, 0, 304);MainGlow.Position = UDim2.new(0.5, -347, 0.5, -152);MainGlow.BackgroundColor3 = C_ACC;MainGlow.BackgroundTransparency = 0.88;MainGlow.BorderSizePixel = 0;MainGlow.Parent = ScreenGui;MainGlow.ZIndex = 8
Instance.new("UICorner", MainGlow).CornerRadius = UDim.new(0, 18)
local mbGlowGrad = Instance.new("UIGradient", MainGlow)
local mbGlowScale = Instance.new("UIScale", MainGlow)
mbGrad.Rotation = 45
mbGlowGrad.Rotation = 45
mbGrad.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 160)),
ColorSequenceKeypoint.new(0.17, Color3.fromRGB(190, 80, 255)),
ColorSequenceKeypoint.new(0.34, Color3.fromRGB(110, 130, 255)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 190, 255)),
ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 220, 235)),
ColorSequenceKeypoint.new(0.84, Color3.fromRGB(160, 90, 255)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 160)),
})
mbGlowGrad.Color = mbGrad.Color
task.spawn(function()
local lastT = os.clock()
while mbGrad and mbGrad.Parent do
local ok = pcall(function()
local now = os.clock()
local dt = math.min(now - lastT, 0.1)
lastT = now
local rot = (mbGrad.Rotation + dt * 110) % 360
mbGrad.Rotation = rot
mbGlowGrad.Rotation = rot
end)
if not ok then task.wait(0.05) end
rs.RenderStepped:Wait()
end
end)
local MainGroup = Instance.new("Frame")
MainGroup.Size = UDim2.new(0, 680, 0, 290);MainGroup.Position = UDim2.new(0.5, -340, 0.5, -145);MainGroup.BackgroundColor3 = C_BG;MainGroup.BackgroundTransparency = 0.55;MainGroup.BorderSizePixel = 0;MainGroup.Parent = ScreenGui;MainGroup.ZIndex = 10
Instance.new("UICorner", MainGroup).CornerRadius = UDim.new(0, 16)
local MainEdge = Instance.new("Frame")
MainEdge.Size = UDim2.new(1, -8, 0, 1);MainEdge.Position = UDim2.new(0, 4, 0, 0);MainEdge.BackgroundColor3 = Color3.fromRGB(255, 255, 255);MainEdge.BackgroundTransparency = 0.8;MainEdge.BorderSizePixel = 0;MainEdge.Parent = MainGroup;MainEdge.ZIndex = 16
local GlossLayer = Instance.new("Frame")
GlossLayer.Size = UDim2.new(1, -8, 0, 48);GlossLayer.Position = UDim2.new(0, 4, 0, 0);GlossLayer.BackgroundColor3 = Color3.fromRGB(255, 255, 255);GlossLayer.BackgroundTransparency = 0.94;GlossLayer.BorderSizePixel = 0;GlossLayer.Parent = MainGroup;GlossLayer.ZIndex = 14
local glossGrad = Instance.new("UIGradient", GlossLayer)
glossGrad.Rotation = 90
glossGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(1, 1)})
local FrostLayer = Instance.new("Frame")
FrostLayer.Size = UDim2.new(1, 0, 1, 0);FrostLayer.BackgroundTransparency = 1;FrostLayer.BorderSizePixel = 0;FrostLayer.Parent = MainGroup;FrostLayer.ZIndex = 20;FrostLayer.Name = "FrostLayer"
local frostRng = Random.new(777)
for _ = 1, 90 do
local g = Instance.new("Frame")
g.Size = UDim2.new(0, frostRng:NextNumber(1.5, 3), 0, frostRng:NextNumber(1.5, 3))
g.Position = UDim2.new(0, frostRng:NextNumber(2, 676), 0, frostRng:NextNumber(2, 286))
g.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
g.BackgroundTransparency = frostRng:NextNumber(0.72, 0.88)
g.BorderSizePixel = 0
g.ZIndex = 20
g.Parent = FrostLayer
end
local MainScale = Instance.new("UIScale", MainGroup)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42);TitleBar.BackgroundColor3 = C_BG;TitleBar.BackgroundTransparency = 0.75;TitleBar.BorderSizePixel = 0;TitleBar.Parent = MainGroup;TitleBar.ZIndex = 15
local tbCorner = Instance.new("UICorner", TitleBar)
tbCorner.CornerRadius = UDim.new(0, 16)
local TitleIcon = Instance.new("Frame")
TitleIcon.Size = UDim2.new(0, 4, 0, 20);TitleIcon.Position = UDim2.new(0, 16, 0.5, -10);TitleIcon.BackgroundColor3 = C_ACCL;TitleIcon.BorderSizePixel = 0;TitleIcon.Parent = TitleBar;TitleIcon.ZIndex = 16
Instance.new("UICorner", TitleIcon).CornerRadius = UDim.new(1, 0)
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 160, 0, 42);Title.Position = UDim2.new(0, 28, 0, 0);Title.BackgroundTransparency = 1;Title.Text = "自瞄 v3";Title.TextColor3 = C_TEXT;Title.Font = Enum.Font.GothamBold;Title.TextSize = 19;Title.TextXAlignment = Enum.TextXAlignment.Left;Title.Parent = TitleBar;Title.ZIndex = 16
local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(0, 90, 0, 42);SubTitle.Position = UDim2.new(0, 108, 0, 0);SubTitle.BackgroundTransparency = 1;SubTitle.Text = "XJW制作";SubTitle.TextColor3 = C_SUB;SubTitle.Font = Enum.Font.Gotham;SubTitle.TextSize = 12;SubTitle.TextXAlignment = Enum.TextXAlignment.Left;SubTitle.Parent = TitleBar;SubTitle.ZIndex = 16
local ThanksLabel = Instance.new("TextLabel")
ThanksLabel.Size = UDim2.new(0, 150, 0, 42);ThanksLabel.Position = UDim2.new(0, 202, 0, 0);ThanksLabel.BackgroundTransparency = 1;ThanksLabel.Text = "感谢你使用此脚本";ThanksLabel.TextColor3 = C_ACCS;ThanksLabel.Font = Enum.Font.Gotham;ThanksLabel.TextSize = 12;ThanksLabel.TextXAlignment = Enum.TextXAlignment.Left;ThanksLabel.Parent = TitleBar;ThanksLabel.ZIndex = 16
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28);CloseBtn.Position = UDim2.new(1, -34, 0, 7);CloseBtn.Text = "×";CloseBtn.TextColor3 = Color3.fromRGB(255, 150, 150);CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30);CloseBtn.BackgroundTransparency = 0.3;CloseBtn.Font = Enum.Font.GothamBold;CloseBtn.TextSize = 18;CloseBtn.BorderSizePixel = 0;CloseBtn.Parent = TitleBar;CloseBtn.ZIndex = 16
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(0, 118, 1, -52);TabBar.Position = UDim2.new(0, 6, 0, 46);TabBar.BackgroundTransparency = 1;TabBar.Parent = MainGroup;TabBar.ZIndex = 12
local TabList = Instance.new("UIListLayout")
TabList.Padding = UDim.new(0, 5);TabList.Parent = TabBar
local tabNames = {"透视功能", "自瞄功能", "自瞄选项", "自瞄参数", "特定自瞄", "黑名单管理"}
local tabBtns = {}
local activeColor = C_ACC
local inactiveColor = C_CARD2
for _, name in ipairs(tabNames) do
local b = Instance.new("TextButton")
b.Size = UDim2.new(1, 0, 0, 32);b.Text = "  " .. name;b.TextColor3 = C_SUB;b.TextSize = 15;b.Font = Enum.Font.GothamBold;b.TextXAlignment = Enum.TextXAlignment.Left;b.BackgroundColor3 = inactiveColor;b.BorderSizePixel = 0;b.Parent = TabBar;b.ZIndex = 13
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
local marker = Instance.new("Frame")
marker.Size = UDim2.new(0, 3, 0, 16);marker.Position = UDim2.new(0, 0, 0.5, -8);marker.BackgroundColor3 = C_ACCL;marker.BorderSizePixel = 0;marker.Parent = b;marker.ZIndex = 14;marker.Visible = false
Instance.new("UICorner", marker).CornerRadius = UDim.new(1, 0)
table.insert(tabBtns, b)
end
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -132, 1, -52);Content.Position = UDim2.new(0, 126, 0, 46);Content.BackgroundTransparency = 1;Content.ScrollBarThickness = 4;Content.ScrollBarImageColor3 = Color3.fromRGB(90, 100, 140);Content.CanvasSize = UDim2.new(0, 0, 0, 200);Content.AutomaticCanvasSize = Enum.AutomaticSize.Y;Content.BorderSizePixel = 0;Content.Parent = MainGroup;Content.ZIndex = 10;Content.ScrollingEnabled = true
local tabContainers = {}
local curParent = nil
local function NewContainer()
local c = Instance.new("Frame")
c.Size = UDim2.new(1, 0, 0, 0);c.AutomaticSize = Enum.AutomaticSize.Y;c.BackgroundTransparency = 1;c.BorderSizePixel = 0;c.Parent = Content;c.ZIndex = 10
return c
end
local function SectionTitle(text)
local s = Instance.new("Frame")
s.Size = UDim2.new(1, 0, 0, 30);s.BackgroundTransparency = 1;s.Parent = tabContainers[#tabContainers];s.ZIndex = 10
local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 3, 0, 16);bar.Position = UDim2.new(0, 0, 0.5, -8);bar.BackgroundColor3 = C_ACCL;bar.BorderSizePixel = 0;bar.Parent = s;bar.ZIndex = 11
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
local l = Instance.new("TextLabel")
l.Size = UDim2.new(1, -12, 1, 0);l.Position = UDim2.new(0, 12, 0, 0);l.BackgroundTransparency = 1;l.Text = text;l.TextColor3 = C_SUB;l.TextSize = 15;l.Font = Enum.Font.GothamBold;l.TextXAlignment = Enum.TextXAlignment.Left;l.Parent = s;l.ZIndex = 11
end
local function ToggleUnit(w, text, default, callback)
local f = Instance.new("Frame")
f.Size = UDim2.new(0, w, 0, 36);f.BackgroundColor3 = C_CARD;f.BorderSizePixel = 0;f.Parent = curParent or tabContainers[#tabContainers];f.ZIndex = 10
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
local fStroke = Instance.new("UIStroke", f)
fStroke.Color = C_ACC;fStroke.Thickness = 1;fStroke.Transparency = 0.85
local l = Instance.new("TextLabel")
l.Size = UDim2.new(0, w - 64, 0, 36);l.Position = UDim2.new(0, 12, 0, 0);l.BackgroundTransparency = 1;l.Text = text;l.TextColor3 = C_TEXT;l.TextSize = 14;l.Font = Enum.Font.Gotham;l.TextXAlignment = Enum.TextXAlignment.Left;l.Parent = f;l.ZIndex = 11
local b = Instance.new("TextButton")
b.Size = UDim2.new(0, 44, 0, 24);b.Position = UDim2.new(1, -52, 0.5, -12);b.Text = "";b.BackgroundColor3 = default and C_ACC or C_OFF;b.BorderSizePixel = 0;b.Parent = f;b.ZIndex = 11
Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 20, 0, 20);dot.Position = default and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 2, 0.5, -10);dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255);dot.BorderSizePixel = 0;dot.Parent = b;dot.ZIndex = 12
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
local state = default
b.MouseButton1Click:Connect(function()
state = not state
tw(b, {BackgroundColor3 = state and C_ACC or C_OFF}, 0.14)
tw(dot, {Position = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}, 0.22, Enum.EasingStyle.Back)
callback(state)
end)
end
local function InputUnit(w, text, default, callback)
local f = Instance.new("Frame")
f.Size = UDim2.new(0, w, 0, 36);f.BackgroundColor3 = C_CARD;f.BorderSizePixel = 0;f.Parent = curParent or tabContainers[#tabContainers];f.ZIndex = 10
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
local fStroke = Instance.new("UIStroke", f)
fStroke.Color = C_ACC;fStroke.Thickness = 1;fStroke.Transparency = 0.85
local l = Instance.new("TextLabel")
l.Size = UDim2.new(0, w - 100, 0, 36);l.Position = UDim2.new(0, 12, 0, 0);l.BackgroundTransparency = 1;l.Text = text;l.TextColor3 = C_TEXT;l.TextSize = 14;l.Font = Enum.Font.Gotham;l.TextXAlignment = Enum.TextXAlignment.Left;l.Parent = f;l.ZIndex = 11
local box = Instance.new("TextBox")
box.Size = UDim2.new(0, 84, 0, 24);box.Position = UDim2.new(1, -90, 0.5, -12);box.Text = tostring(default);box.TextColor3 = C_TEXT;box.BackgroundColor3 = C_CARD2;box.Font = Enum.Font.Gotham;box.TextSize = 15;box.PlaceholderText = "...";box.BorderSizePixel = 0;box.Parent = f;box.ZIndex = 11
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)
local boxStroke = Instance.new("UIStroke", box)
boxStroke.Color = C_ACCL;boxStroke.Thickness = 1;boxStroke.Transparency = 1
box.Focused:Connect(function()
boxStroke.Transparency = 0.15
end)
box.FocusLost:Connect(function(enter)
boxStroke.Transparency = 1
local num = tonumber(box.Text)
if num then
callback(num)
else
box.Text = tostring(default)
end
end)
end
local dropdownPopups = {}
local function closeAllDropdowns()
for _, p in ipairs(dropdownPopups) do
pcall(function() p:Destroy() end)
end
dropdownPopups = {}
end
local function SliderUnit(w, text, min, max, default, callback, step)
step = step or 1
local f = Instance.new("Frame")
f.Size = UDim2.new(0, w, 0, 52);f.BackgroundColor3 = C_CARD;f.BorderSizePixel = 0;f.Parent = curParent or tabContainers[#tabContainers];f.ZIndex = 10
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
local fStroke = Instance.new("UIStroke", f)
fStroke.Color = C_ACC;fStroke.Thickness = 1;fStroke.Transparency = 0.85
local l = Instance.new("TextLabel")
l.Size = UDim2.new(0, w - 80, 0, 20);l.Position = UDim2.new(0, 12, 0, 4);l.BackgroundTransparency = 1;l.Text = text;l.TextColor3 = C_TEXT;l.TextSize = 13;l.Font = Enum.Font.Gotham;l.TextXAlignment = Enum.TextXAlignment.Left;l.Parent = f;l.ZIndex = 11
local val = Instance.new("TextLabel")
val.Size = UDim2.new(0, 56, 0, 20);val.Position = UDim2.new(1, -64, 0, 4);val.BackgroundTransparency = 1;val.Text = tostring(default);val.TextColor3 = C_ACCS;val.TextSize = 14;val.Font = Enum.Font.GothamBold;val.TextXAlignment = Enum.TextXAlignment.Right;val.Parent = f;val.ZIndex = 11
local track = Instance.new("ImageButton")
track.AutoButtonColor = false;track.Image = "";track.Size = UDim2.new(1, -24, 0, 6);track.Position = UDim2.new(0, 12, 1, -16);track.BackgroundColor3 = C_OFF;track.BorderSizePixel = 0;track.Parent = f;track.ZIndex = 11
Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)
local fill = Instance.new("Frame")
fill.Size = UDim2.new(0, 0, 1, 0);fill.BackgroundColor3 = C_ACC;fill.BorderSizePixel = 0;fill.Parent = track;fill.ZIndex = 12
Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
local knob = Instance.new("TextButton")
knob.Size = UDim2.new(0, 24, 0, 24);knob.BackgroundColor3 = C_ACCL;knob.BorderSizePixel = 0;knob.Text = "";knob.Parent = f;knob.ZIndex = 13
Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 12)
local knobStroke = Instance.new("UIStroke", knob)
knobStroke.Color = Color3.fromRGB(255, 255, 255);knobStroke.Thickness = 1;knobStroke.Transparency = 0.6
local dragging = false
local function snapV(v)
return min + math.round((v - min) / step) * step
end
local function clampV(v)
return math.max(min, math.min(max, v))
end
local function ratioFromX(x)
local tw_ = track.AbsoluteSize.X
if tw_ <= 0 then return 0 end
return (x - track.AbsolutePosition.X) / tw_
end
local function setFromRatio(ratio, fire)
ratio = math.clamp(ratio, 0, 1)
local v = snapV(clampV(min + ratio * (max - min)))
if step >= 1 then
val.Text = tostring(v)
else
val.Text = string.format("%.1f", v)
end
fill.Size = UDim2.new(ratio, 0, 1, 0);knob.Position = UDim2.new(0, ratio * track.AbsoluteSize.X, 0.5, -12)
if fire then callback(v) end
end
local function init()
local r = (clampV(default) - min) / (max - min)
setFromRatio(r, false)
end
task.defer(init)
track.MouseButton1Down:Connect(function(x)
setFromRatio(ratioFromX(x), true)
end)
knob.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
tw(knob, {Size = UDim2.new(0, 28, 0, 28)}, 0.06)
setFromRatio(ratioFromX(input.Position.X), true)
input.Changed:Connect(function()
if not dragging then return end
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
setFromRatio(ratioFromX(input.Position.X), true)
end
end)
end
end)
knob.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = false
tw(knob, {Size = UDim2.new(0, 24, 0, 24)}, 0.06)
end
end)
end
local dropdownOpts = {}
local function DropdownUnit(w, text, options, default, callback)
local f = Instance.new("Frame")
dropdownOpts[f] = options
f.Size = UDim2.new(0, w, 0, 36);f.BackgroundColor3 = C_CARD;f.BorderSizePixel = 0;f.Parent = curParent or tabContainers[#tabContainers];f.ZIndex = 10
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
local fStroke = Instance.new("UIStroke", f)
fStroke.Color = C_ACC;fStroke.Thickness = 1;fStroke.Transparency = 0.85
local l = Instance.new("TextLabel")
l.Size = UDim2.new(0, w - 126, 0, 36);l.Position = UDim2.new(0, 12, 0, 0);l.BackgroundTransparency = 1;l.Text = text;l.TextColor3 = C_TEXT;l.TextSize = 14;l.Font = Enum.Font.Gotham;l.TextXAlignment = Enum.TextXAlignment.Left;l.Parent = f;l.ZIndex = 11
local b = Instance.new("TextButton")
b.Size = UDim2.new(0, 110, 0, 26);b.Position = UDim2.new(1, -116, 0.5, -13);b.Text = default;b.TextColor3 = C_TEXT;b.TextSize = 14;b.Font = Enum.Font.GothamBold;b.BackgroundColor3 = C_CARD2;b.BorderSizePixel = 0;b.Parent = f;b.ZIndex = 11
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
local bStroke = Instance.new("UIStroke", b)
bStroke.Color = C_ACC;bStroke.Thickness = 1;bStroke.Transparency = 0.7
local arr = Instance.new("TextLabel")
arr.Size = UDim2.new(0, 16, 1, 0);arr.Position = UDim2.new(1, -18, 0, 0);arr.BackgroundTransparency = 1;arr.Text = "▾";arr.TextColor3 = C_ACCL;arr.TextSize = 13;arr.Font = Enum.Font.GothamBold;arr.Parent = b;arr.ZIndex = 12
local popup = nil
local function closePopup()
if popup then
for i = #dropdownPopups, 1, -1 do
if dropdownPopups[i] == popup then
table.remove(dropdownPopups, i)
end
end
pcall(function() popup:Destroy() end)
popup = nil
end
end
b.MouseButton1Click:Connect(function()
if popup and popup.Parent then
closePopup()
return
end
closeAllDropdowns()
local opts = dropdownOpts[f] or options
local bAbs = b.AbsolutePosition
local listH = math.min(#opts * 32 + 8, math.floor(Camera.ViewportSize.Y * 0.45))
local popW = math.min(w - 16, 216)
popup = Instance.new("Frame")
popup.Size = UDim2.fromOffset(popW, listH);popup.BackgroundColor3 = C_CARD2;popup.BorderSizePixel = 0;popup.ZIndex = 200;popup.Parent = ScreenGui
Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 10)
local popStroke = Instance.new("UIStroke", popup)
popStroke.Color = C_ACC;popStroke.Thickness = 1;popStroke.Transparency = 0.4
local viewH = Camera.ViewportSize.Y
local top = bAbs.Y + b.AbsoluteSize.Y + 4
if top + listH > viewH then
top = math.max(4, bAbs.Y - listH - 4)
end
local viewW = Camera.ViewportSize.X
popup.Position = UDim2.fromOffset(math.clamp(bAbs.X, 4, math.max(4, viewW - popW - 4)), top)
local list = Instance.new("ScrollingFrame", popup)
list.Size = UDim2.new(1, 0, 1, 0);list.BackgroundTransparency = 1;list.BorderSizePixel = 0;list.ScrollBarThickness = 4;list.ScrollBarImageColor3 = C_ACC;list.ScrollingDirection = Enum.ScrollingDirection.Y;list.AutomaticCanvasSize = Enum.AutomaticSize.Y;list.CanvasPosition = Vector2.new(0, 0);list.ZIndex = 201
local lay = Instance.new("UIListLayout", list)
lay.Padding = UDim.new(0, 2)
local pad = Instance.new("UIPadding", list)
pad.PaddingTop = UDim.new(0, 4);pad.PaddingBottom = UDim.new(0, 4);pad.PaddingLeft = UDim.new(0, 4);pad.PaddingRight = UDim.new(0, 4)
for _, v in ipairs(opts) do
local it = Instance.new("TextButton")
it.Size = UDim2.new(1, 0, 0, 28);it.BackgroundTransparency = 1;it.Text = v;it.TextColor3 = C_TEXT;it.TextSize = 13;it.Font = Enum.Font.Gotham;it.BorderSizePixel = 0;it.ZIndex = 201;it.Parent = list
Instance.new("UICorner", it).CornerRadius = UDim.new(0, 6)
it.MouseEnter:Connect(function()
it.BackgroundTransparency = 0.2;it.BackgroundColor3 = C_ACC
end)
it.MouseLeave:Connect(function()
it.BackgroundTransparency = 1
end)
it.MouseButton1Click:Connect(function()
b.Text = v
tw(b, {BackgroundColor3 = Color3.fromRGB(45, 66, 110)}, 0.08)
delay(0.08, function()
tw(b, {BackgroundColor3 = C_CARD2}, 0.15)
end)
closePopup()
callback(v)
end)
end
table.insert(dropdownPopups, popup)
end)
return f
end
local function ActionUnit(w, text, color)
local f = Instance.new("Frame")
f.Size = UDim2.new(0, w, 0, 38);f.BackgroundTransparency = 1;f.Parent = curParent or tabContainers[#tabContainers];f.ZIndex = 10
local b = Instance.new("TextButton")
b.Size = UDim2.new(0, math.min(w, 240), 0, 30);b.Position = UDim2.new(0.5, -math.min(w, 240) / 2, 0.5, -15);b.Text = text;b.TextColor3 = C_TEXT;b.TextSize = 14;b.Font = Enum.Font.GothamBold;b.BackgroundColor3 = color;b.BorderSizePixel = 0;b.Parent = f;b.ZIndex = 11
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
local s = Instance.new("UIStroke", b)
s.Color = Color3.fromRGB(255, 255, 255);s.Thickness = 1;s.Transparency = 0.85
b.MouseButton1Down:Connect(function()
tw(b, {Size = UDim2.new(0, math.min(w, 240) - 4, 0, 28)}, 0.08)
end)
b.MouseButton1Up:Connect(function()
tw(b, {Size = UDim2.new(0, math.min(w, 240), 0, 30)}, 0.08)
end)
return b
end
local currentTargetLabel
local function GetPlayerList()
local list = {"无"}
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer then
table.insert(list, plr.Name)
end
end
return list
end
local container1 = NewContainer()
table.insert(tabContainers, container1)
local lay1 = Instance.new("UIListLayout")
lay1.Padding = UDim.new(0, 6);lay1.Parent = container1
SectionTitle("透视设置")
local inner1 = Instance.new("Frame")
inner1.Size = UDim2.new(1, 0, 0, 0);inner1.AutomaticSize = Enum.AutomaticSize.Y;inner1.BackgroundTransparency = 1;inner1.Parent = container1
local grid1 = Instance.new("UIGridLayout")
grid1.CellSize = UDim2.new(0, 175, 0, 36);grid1.CellPadding = UDim2.new(0, 6, 0, 6);grid1.Parent = inner1
curParent = inner1
ToggleUnit(175, "透视总开关", false, function(v) ESPEnabled = v end)
ToggleUnit(175, "2D方框", false, function(v) ESPBox = v end)
ToggleUnit(175, "天线", false, function(v) ESPTracer = v end)
ToggleUnit(175, "名字", false, function(v) ESPName = v end)
ToggleUnit(175, "距离", false, function(v) ESPDistance = v end)
ToggleUnit(175, "血量", false, function(v) ESPHealth = v end)
ToggleUnit(175, "头部圆点", false, function(v) ESPHeadDot = v end)
ToggleUnit(175, "队伍检查", false, function(v) ESPTeamCheck = v end)
ToggleUnit(175, "死亡停止", true, function(v) ESPDeadStop = v end)
curParent = nil
local container2 = NewContainer()
table.insert(tabContainers, container2)
local lay2 = Instance.new("UIListLayout")
lay2.Padding = UDim.new(0, 6);lay2.Parent = container2
SectionTitle("自瞄功能")
local inner2 = Instance.new("Frame")
inner2.Size = UDim2.new(1, 0, 0, 0);inner2.AutomaticSize = Enum.AutomaticSize.Y;inner2.BackgroundTransparency = 1;inner2.Parent = container2
local grid2 = Instance.new("UIGridLayout")
grid2.CellSize = UDim2.new(0, 175, 0, 36);grid2.CellPadding = UDim2.new(0, 6, 0, 6);grid2.Parent = inner2
curParent = inner2
ToggleUnit(175, "自瞄总开关", false, function(v) AimbotEnabled = v end)
ToggleUnit(175, "显示FOV圈", false, function(v) ShowFOV = v end)
ToggleUnit(175, "队伍判断", false, function(v) TeamCheck = v end)
ToggleUnit(175, "墙壁检查", false, function(v) WallCheck = v end)
ToggleUnit(175, "自动开枪", false, function(v) AutoShoot = v end)
ToggleUnit(175, "手持武器自瞄", false, function(v) RequireWeapon = v end)
ToggleUnit(175, "包含NPC/Bot", false, function(v) IncludeNPCs = v end)
curParent = nil
local container3 = NewContainer()
table.insert(tabContainers, container3)
local lay3 = Instance.new("UIListLayout")
lay3.Padding = UDim.new(0, 6);lay3.Parent = container3
SectionTitle("自瞄选项")
local inner3 = Instance.new("Frame")
inner3.Size = UDim2.new(1, 0, 0, 0);inner3.AutomaticSize = Enum.AutomaticSize.Y;inner3.BackgroundTransparency = 1;inner3.Parent = container3
local grid3 = Instance.new("UIGridLayout")
grid3.CellSize = UDim2.new(0, 250, 0, 36);grid3.CellPadding = UDim2.new(0, 6, 0, 6);grid3.Parent = inner3
curParent = inner3
DropdownUnit(250, "锁定模式", {"普通", "强锁", "平滑"}, "普通", function(v) LockMode = v end)
DropdownUnit(250, "瞄准部位", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, "Head", function(v) AimPart = v end)
DropdownUnit(250, "优先模式", {"准星最近", "距离最近", "血量最低"}, "准星最近", function(v) PriorityMode = v end)
curParent = nil
local container4 = NewContainer()
table.insert(tabContainers, container4)
local lay4 = Instance.new("UIListLayout")
lay4.Padding = UDim.new(0, 6);lay4.Parent = container4
SectionTitle("自瞄参数")
local inner4 = Instance.new("Frame")
inner4.Size = UDim2.new(1, 0, 0, 0);inner4.AutomaticSize = Enum.AutomaticSize.Y;inner4.BackgroundTransparency = 1;inner4.Parent = container4
local grid4 = Instance.new("UIGridLayout")
grid4.CellSize = UDim2.new(0, 250, 0, 36);grid4.CellPadding = UDim2.new(0, 6, 0, 6);grid4.Parent = inner4
curParent = inner4
SliderUnit(250, "FOV大小", 50, 500, FOVSize, function(v) FOVSize = v end, 1)
SliderUnit(250, "平滑度", 1, 30, Smoothness, function(v) Smoothness = v end, 1)
SliderUnit(250, "预判量", 0, 5, PredictionAmount, function(v) PredictionAmount = v end, 0.1)
curParent = nil
local container5 = NewContainer()
local list5 = Instance.new("UIListLayout")
list5.Padding = UDim.new(0, 6);list5.Parent = container5
table.insert(tabContainers, container5)
SectionTitle("特定目标")
local specificLabel = Instance.new("TextLabel")
specificLabel.Size = UDim2.new(1, 0, 0, 24);specificLabel.BackgroundTransparency = 1;specificLabel.Text = "  玩家名字";specificLabel.TextColor3 = C_TEXT;specificLabel.TextSize = 14;specificLabel.Font = Enum.Font.GothamBold;specificLabel.TextXAlignment = Enum.TextXAlignment.Left;specificLabel.Parent = container5;specificLabel.ZIndex = 10
local specificBox = Instance.new("TextBox")
specificBox.Size = UDim2.new(0, 280, 0, 30);specificBox.Position = UDim2.new(0, 12, 0, 0);specificBox.Text = "";specificBox.TextColor3 = C_TEXT;specificBox.BackgroundColor3 = C_CARD2;specificBox.Font = Enum.Font.Gotham;specificBox.TextSize = 15;specificBox.PlaceholderText = "输入玩家名字回车确认...";specificBox.BorderSizePixel = 0;specificBox.Parent = container5;specificBox.ZIndex = 10
Instance.new("UICorner", specificBox).CornerRadius = UDim.new(0, 8)
local specificStroke = Instance.new("UIStroke", specificBox)
specificStroke.Color = C_ACCL;specificStroke.Thickness = 1;specificStroke.Transparency = 1
specificBox.Focused:Connect(function()
specificStroke.Transparency = 0.15
end)
specificBox.FocusLost:Connect(function(enter)
specificStroke.Transparency = 1
local name = specificBox.Text
if name and name ~= "" then
SpecificTarget = name
currentTargetLabel.Text = "  当前目标: " .. name
else
SpecificTarget = nil
currentTargetLabel.Text = "  当前目标: 无"
end
end)
local targetDropdown = DropdownUnit(540, "选择目标", GetPlayerList(), "无", function(v)
if v == "无" then
SpecificTarget = nil
specificBox.Text = "";currentTargetLabel.Text = "  当前目标: 无"
else
SpecificTarget = v
specificBox.Text = v;currentTargetLabel.Text = "  当前目标: " .. v
end
end)
currentTargetLabel = Instance.new("TextLabel")
currentTargetLabel.Size = UDim2.new(0, 540, 0, 30);currentTargetLabel.Position = UDim2.new(0, 0, 0, 0);currentTargetLabel.BackgroundColor3 = Color3.fromRGB(10, 22, 20);currentTargetLabel.Text = "  当前目标: 无";currentTargetLabel.TextColor3 = C_OK;currentTargetLabel.TextSize = 15;currentTargetLabel.Font = Enum.Font.GothamBold;currentTargetLabel.TextXAlignment = Enum.TextXAlignment.Left;currentTargetLabel.BorderSizePixel = 0;currentTargetLabel.Parent = container5;currentTargetLabel.ZIndex = 10
Instance.new("UICorner", currentTargetLabel).CornerRadius = UDim.new(0, 9)
local ctlStroke = Instance.new("UIStroke", currentTargetLabel)
ctlStroke.Color = C_OK;ctlStroke.Thickness = 1;ctlStroke.Transparency = 0.6
local refreshBtn = ActionUnit(540, "刷新玩家列表", C_ACC)
refreshBtn.MouseButton1Click:Connect(function()
closeAllDropdowns()
dropdownOpts[targetDropdown] = GetPlayerList()
end)
local container6 = NewContainer()
local list6 = Instance.new("UIListLayout")
list6.Padding = UDim.new(0, 6);list6.Parent = container6
table.insert(tabContainers, container6)
SectionTitle("黑名单管理")
local blacklistLabel = Instance.new("TextLabel")
blacklistLabel.Size = UDim2.new(1, 0, 0, 24);blacklistLabel.BackgroundTransparency = 1;blacklistLabel.Text = "  添加黑名单";blacklistLabel.TextColor3 = C_TEXT;blacklistLabel.TextSize = 14;blacklistLabel.Font = Enum.Font.GothamBold;blacklistLabel.TextXAlignment = Enum.TextXAlignment.Left;blacklistLabel.Parent = container6;blacklistLabel.ZIndex = 10
local blacklistBox = Instance.new("TextBox")
blacklistBox.Size = UDim2.new(0, 280, 0, 30);blacklistBox.Position = UDim2.new(0, 12, 0, 0);blacklistBox.Text = "";blacklistBox.TextColor3 = C_TEXT;blacklistBox.BackgroundColor3 = C_CARD2;blacklistBox.Font = Enum.Font.Gotham;blacklistBox.TextSize = 15;blacklistBox.PlaceholderText = "输入玩家名字...";blacklistBox.BorderSizePixel = 0;blacklistBox.Parent = container6;blacklistBox.ZIndex = 10
Instance.new("UICorner", blacklistBox).CornerRadius = UDim.new(0, 8)
local UpdateBlacklistDisplay
local addBlacklistBtn = Instance.new("TextButton")
addBlacklistBtn.Size = UDim2.new(0, 72, 0, 30);addBlacklistBtn.Position = UDim2.new(0, 300, 0, 0);addBlacklistBtn.Text = "添加";addBlacklistBtn.TextColor3 = C_TEXT;addBlacklistBtn.TextSize = 14;addBlacklistBtn.Font = Enum.Font.GothamBold;addBlacklistBtn.BackgroundColor3 = C_DANGER;addBlacklistBtn.BorderSizePixel = 0;addBlacklistBtn.Parent = container6;addBlacklistBtn.ZIndex = 10
Instance.new("UICorner", addBlacklistBtn).CornerRadius = UDim.new(0, 8)
addBlacklistBtn.MouseButton1Click:Connect(function()
local name = blacklistBox.Text
if name and name ~= "" then
local found = false
for _, v in ipairs(Blacklist) do
if v == name then found = true; break end
end
if not found then
table.insert(Blacklist, name)
blacklistBox.Text = ""
UpdateBlacklistDisplay()
end
end
end)
local blacklistDropdown = DropdownUnit(540, "从列表添加", GetPlayerList(), "无", function(v)
if v ~= "无" then
local found = false
for _, name in ipairs(Blacklist) do
if name == v then found = true; break end
end
if not found then
table.insert(Blacklist, v)
UpdateBlacklistDisplay()
end
end
end)
local clearBlacklistBtn = ActionUnit(540, "清空黑名单", C_DANGER)
clearBlacklistBtn.MouseButton1Click:Connect(function()
Blacklist = {}
UpdateBlacklistDisplay()
end)
UpdateBlacklistDisplay = function()
for _, child in ipairs(container6:GetChildren()) do
if child:IsA("Frame") and child ~= blacklistDropdown and child:GetAttribute("blItem") then
child:Destroy()
end
end
for _, name in ipairs(Blacklist) do
local item = Instance.new("Frame")
item.Size = UDim2.new(0, 540, 0, 30);item.BackgroundColor3 = Color3.fromRGB(28, 14, 20);item.BorderSizePixel = 0
item:SetAttribute("blItem", true)
item.Parent = container6;item.ZIndex = 10
Instance.new("UICorner", item).CornerRadius = UDim.new(0, 9)
local itemStroke = Instance.new("UIStroke", item)
itemStroke.Color = C_DANGER;itemStroke.Thickness = 1;itemStroke.Transparency = 0.7
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0.8, 0, 1, 0);nameLabel.Position = UDim2.new(0, 14, 0, 0);nameLabel.BackgroundTransparency = 1;nameLabel.Text = "黑名单: " .. name;nameLabel.TextColor3 = Color3.fromRGB(255, 150, 150);nameLabel.TextSize = 14;nameLabel.Font = Enum.Font.Gotham;nameLabel.TextXAlignment = Enum.TextXAlignment.Left;nameLabel.Parent = item;nameLabel.ZIndex = 11
local removeBtn = Instance.new("TextButton")
removeBtn.Size = UDim2.new(0, 56, 0, 22);removeBtn.Position = UDim2.new(1, -62, 0.5, -11);removeBtn.Text = "移除";removeBtn.TextColor3 = C_TEXT;removeBtn.TextSize = 13;removeBtn.Font = Enum.Font.GothamBold;removeBtn.BackgroundColor3 = C_DANGER;removeBtn.BorderSizePixel = 0;removeBtn.Parent = item;removeBtn.ZIndex = 11
Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 6)
removeBtn.MouseButton1Click:Connect(function()
for i, v in ipairs(Blacklist) do
if v == name then
table.remove(Blacklist, i)
break
end
end
UpdateBlacklistDisplay()
end)
end
end
for i, c in ipairs(tabContainers) do
c.Visible = (i == 1)
end
for i, b in ipairs(tabBtns) do
local marker = b:FindFirstChildOfClass("Frame")
if i == 1 then
b.BackgroundColor3 = C_ACC;b.TextColor3 = C_TEXT
if marker then marker.Visible = true end
end
b.MouseButton1Click:Connect(function()
closeAllDropdowns()
for j, c in ipairs(tabContainers) do
c.Visible = (j == i)
local m = tabBtns[j]:FindFirstChildOfClass("Frame")
if j == i then
tabBtns[j].BackgroundColor3 = C_ACC
tabBtns[j].TextColor3 = C_TEXT
if m then m.Visible = true end
else
tabBtns[j].BackgroundColor3 = inactiveColor
tabBtns[j].TextColor3 = C_SUB
if m then m.Visible = false end
end
end
end)
end
local showState = true
local function setPanel(v)
showState = v
if v then
MainGroup.Visible = true
MainBorder.Visible = true
MainGlow.Visible = true
tw(MainGroup, {BackgroundTransparency = 0.55}, 0.14)
tw(MainBorder, {BackgroundTransparency = 0}, 0.14)
tw(MainGlow, {BackgroundTransparency = 0.88}, 0.14)
tw(MainScale, {Scale = 1}, 0.18)
tw(mbScale, {Scale = 1}, 0.18)
tw(mbGlowScale, {Scale = 1}, 0.18)
else
closeAllDropdowns()
tw(MainGroup, {BackgroundTransparency = 1}, 0.12)
tw(MainBorder, {BackgroundTransparency = 1}, 0.12)
tw(MainGlow, {BackgroundTransparency = 1}, 0.12)
tw(MainScale, {Scale = 0.92}, 0.14)
tw(mbScale, {Scale = 0.92}, 0.14)
tw(mbGlowScale, {Scale = 0.92}, 0.14)
delay(0.14, function()
if not showState then MainGroup.Visible = false
MainBorder.Visible = false
MainGlow.Visible = false end
end)
end
end
local dragActive = false
local dragMoved = false
local dragStart = Vector2.zero
local startPos = nil
local function updateDrag(input)
if not dragActive then return end
local delta = input.Position - dragStart
if not dragMoved and delta.Magnitude > 2 then
dragMoved = true
end
if dragMoved then
FloatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
FloatBorder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X - 3, startPos.Y.Scale, startPos.Y.Offset + delta.Y - 3)
FloatGlow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X - 7, startPos.Y.Scale, startPos.Y.Offset + delta.Y - 7)
end
end
FloatBtn.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragActive = true
dragMoved = false
dragStart = input.Position
startPos = FloatBtn.Position
FloatScale.Scale = 0.9
fbScale.Scale = 0.9
fbGlowScale.Scale = 0.9
input.Changed:Connect(function()
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
updateDrag(input)
end
end)
end
end)
FloatBtn.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragActive = false
tw(FloatScale, {Scale = 1}, 0.16, Enum.EasingStyle.Back)
tw(fbScale, {Scale = 1}, 0.16, Enum.EasingStyle.Back)
tw(fbGlowScale, {Scale = 1}, 0.16, Enum.EasingStyle.Back)
if not dragMoved then
setPanel(not showState)
end
end
end)
local panelDrag = false
local panelStart = Vector2.zero
local panelStartPos = nil
local function updatePanelDrag(input)
if not panelDrag then return end
local delta = input.Position - panelStart
MainGroup.Position = UDim2.new(panelStartPos.X.Scale, panelStartPos.X.Offset + delta.X, panelStartPos.Y.Scale, panelStartPos.Y.Offset + delta.Y)
MainBorder.Position = UDim2.new(panelStartPos.X.Scale, panelStartPos.X.Offset + delta.X - 2, panelStartPos.Y.Scale, panelStartPos.Y.Offset + delta.Y - 2)
MainGlow.Position = UDim2.new(panelStartPos.X.Scale, panelStartPos.X.Offset + delta.X - 7, panelStartPos.Y.Scale, panelStartPos.Y.Offset + delta.Y - 7)
end
TitleBar.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
panelDrag = true
panelStart = input.Position
panelStartPos = MainGroup.Position
input.Changed:Connect(function()
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
updatePanelDrag(input)
end
end)
end
end)
TitleBar.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
panelDrag = false
end
end)
CloseBtn.MouseButton1Click:Connect(function()
ESPEnabled = false
AimbotEnabled = false
local gui = ScreenGui
gui:Destroy()
task.defer(function()
pcall(function()
if fovCircle then
fovCircle:Remove()
fovCircle = nil
end
end)
for _, d in pairs(ESPData) do
for _, v in pairs(d) do
pcall(function() v.Parent = nil end)
end
end
ESPData = {}
end)
end)
local function GetNPCs()
local npcs = {}
for _, obj in ipairs(Workspace:GetDescendants()) do
if obj:IsA("Model") and obj ~= LocalPlayer.Character then
local humanoid = obj:FindFirstChildOfClass("Humanoid")
local rootPart = obj:FindFirstChild("HumanoidRootPart")
if humanoid and rootPart and humanoid.Health > 0 then
local isPlayerChar = false
for _, plr in ipairs(Players:GetPlayers()) do
if plr.Character == obj then
isPlayerChar = true
break
end
end
if not isPlayerChar then
table.insert(npcs, obj)
end
end
end
end
return npcs
end
local function GetTargetPart(target)
if not target then return nil end
local char = GetCharacterFromObject(target)
if not char then return nil end
local part = char:FindFirstChild(AimPart)
if not part then
part = char:FindFirstChild("Head")
end
if not part then
part = char:FindFirstChild("HumanoidRootPart")
end
return part
end
local function PredictPosition(target, part)
if not target or not part then return part.Position end
local velocity = Vector3.zero
if part:IsA("BasePart") then
velocity = part.Velocity
elseif part.Velocity then
velocity = part.Velocity
end
if velocity.Magnitude == 0 then
local char = GetCharacterFromObject(target)
if char then
local rootPart = char:FindFirstChild("HumanoidRootPart")
if rootPart and rootPart:IsA("BasePart") then
velocity = rootPart.Velocity
end
end
end
local predictedPosition = part.Position + (velocity * PredictionAmount)
local currentTime = tick()
if currentTime - lastUpdateTime > 0.05 then
targetVelocity = (part.Position - lastTargetPosition) / (currentTime - lastUpdateTime)
lastTargetPosition = part.Position
lastUpdateTime = currentTime
end
return predictedPosition
end
local lastAimTime = 0
local aimSmoothFactor = 0
RunService.RenderStepped:Connect(function(deltaTime)
local ok, err = pcall(function()
local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
pcall(function()
if not fovCircle then
CreateFOVCircle()
end
if fovCircle then
fovCircle.Position = center;fovCircle.Radius = FOVSize;fovCircle.Visible = ShowFOV and AimbotEnabled;fovCircle.ZIndex = 999
end
end)
pcall(function()
for obj, data in pairs(ESPData) do
if not obj or (obj:IsA("Player") and not obj.Parent) or (obj:IsA("Model") and not obj.Parent) then
for _, v in pairs(data) do
pcall(function() v:Remove() end)
end
ESPData[obj] = nil
end
end
end)
if ESPEnabled then
local players = Players:GetPlayers()
local espTargets = {}
for _, plr in ipairs(players) do
if plr ~= LocalPlayer then
table.insert(espTargets, plr)
end
end
if IncludeNPCs then
local npcs = GetNPCs()
for _, npc in ipairs(npcs) do
table.insert(espTargets, npc)
end
end
for _, target in ipairs(espTargets) do
local data = CreateESP(target)
if not data then continue end
local show = true
if ESPTeamCheck and IsSameTeam(target) then
show = false
end
local char = GetCharacterFromObject(target)
if ESPDeadStop then
if not char then
show = false
else
local hum = char:FindFirstChildOfClass("Humanoid")
if not hum or hum.Health <= 0 then
show = false
end
end
end
if not show or not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Head") then
data.box.Visible = false
data.boxOutline.Visible = false
data.healthText.Visible = false
data.tracer.Visible = false
data.nameText.Visible = false
data.distText.Visible = false
data.headDot.Visible = false
continue
end
local root = char.HumanoidRootPart
local head = char.Head
local hum = char:FindFirstChildOfClass("Humanoid")
if not hum or hum.Health <= 0 then
data.box.Visible = false
data.boxOutline.Visible = false
data.healthText.Visible = false
data.tracer.Visible = false
data.nameText.Visible = false
data.distText.Visible = false
data.headDot.Visible = false
continue
end
local rp, rv = Camera:WorldToViewportPoint(root.Position)
local hp, hv = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
local fp, fv = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
if not rv then
data.box.Visible = false
data.boxOutline.Visible = false
data.healthText.Visible = false
data.tracer.Visible = false
data.nameText.Visible = false
data.distText.Visible = false
data.headDot.Visible = false
continue
end
if ESPBox and hv and fv then
local bh = fp.Y - hp.Y
local bw = bh * 0.55
local bx = rp.X - bw/2
local by = hp.Y
data.boxOutline.Size = Vector2.new(bw + 2, bh + 2)
data.boxOutline.Position = Vector2.new(bx - 1, by - 1)
data.boxOutline.Visible = true
data.box.Size = Vector2.new(bw, bh)
data.box.Position = Vector2.new(bx, by)
data.box.Visible = true
else
data.boxOutline.Visible = false
data.box.Visible = false
end
if ESPHealth and hum then
local hpPercent = hum.Health / hum.MaxHealth
local hpColor
if hpPercent > 0.6 then
hpColor = Color3.fromRGB(0, 255, 100)
elseif hpPercent > 0.3 then
hpColor = Color3.fromRGB(255, 200, 40)
else
hpColor = Color3.fromRGB(255, 50, 50)
end
data.healthText.Text = math.floor(hum.Health) .. " HP"
data.healthText.Color = hpColor
data.healthText.Position = Vector2.new(rp.X, fp.Y + 4)
data.healthText.Visible = true
else
data.healthText.Visible = false
end
if ESPTracer then
data.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
data.tracer.To = Vector2.new(rp.X, rp.Y)
data.tracer.Visible = true
else
data.tracer.Visible = false
end
if ESPName then
if target:IsA("Player") then
data.nameText.Text = target.DisplayName
else
data.nameText.Text = target.Name
end
data.nameText.Position = Vector2.new(rp.X, hp.Y - 20)
data.nameText.Visible = true
else
data.nameText.Visible = false
end
if ESPDistance then
local mr = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
if mr then
data.distText.Text = string.format("%.0fm", (mr.Position - root.Position).Magnitude)
data.distText.Position = Vector2.new(rp.X, fp.Y + 4 + (ESPHealth and 16 or 0))
data.distText.Visible = true
else
data.distText.Visible = false
end
else
data.distText.Visible = false
end
if ESPHeadDot and hv then
data.headDot.Position = Vector2.new(hp.X, hp.Y)
data.headDot.Visible = true
else
data.headDot.Visible = false
end
end
else
for _, data in pairs(ESPData) do
for _, v in pairs(data) do
pcall(function() v.Visible = false end)
end
end
end
if not AimbotEnabled then
aimbotTarget = nil
if fovCircle then
fovCircle.Color = Color3.fromRGB(255, 60, 60);fovCircle.Visible = ShowFOV
end
return
end
if RequireWeapon and not HasWeapon() then
aimbotTarget = nil
if fovCircle then
fovCircle.Color = Color3.fromRGB(255, 60, 60);fovCircle.Visible = ShowFOV
end
return
end
local localChar = LocalPlayer.Character
if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then
aimbotTarget = nil
if fovCircle then
fovCircle.Color = Color3.fromRGB(255, 60, 60);fovCircle.Visible = ShowFOV
end
return
end
local targets = {}
local myRoot = localChar.HumanoidRootPart
for _, plr in ipairs(Players:GetPlayers()) do
if plr == LocalPlayer then continue end
local isBlacklisted = false
for _, name in ipairs(Blacklist) do
if plr.Name == name or plr.DisplayName == name then
isBlacklisted = true
break
end
end
if isBlacklisted then continue end
if SpecificTarget then
if plr.Name ~= SpecificTarget and plr.DisplayName ~= SpecificTarget then
continue
end
end
if TeamCheck and IsSameTeam(plr) then continue end
local char = plr.Character
if not char then continue end
local hum = char:FindFirstChildOfClass("Humanoid")
if not hum or hum.Health <= 0 then continue end
local part = GetTargetPart(plr)
if not part then continue end
if WallCheck then
if not isPartVisible(part) then continue end
end
local predictedPos = PredictPosition(plr, part)
local sp, on = Camera:WorldToViewportPoint(predictedPos)
if not on then continue end
local sd = (Vector2.new(sp.X, sp.Y) - center).Magnitude
if sd <= FOVSize then
local wd = (myRoot.Position - part.Position).Magnitude
table.insert(targets, {target=plr, part=part, sd=sd, wd=wd, hp=hum.Health, predictedPos=predictedPos})
end
end
if IncludeNPCs then
local npcs = GetNPCs()
for _, npc in ipairs(npcs) do
local hum = npc:FindFirstChildOfClass("Humanoid")
if hum and hum.Health > 0 then
local part = GetTargetPart(npc)
if part then
if WallCheck then
if not isPartVisible(part) then continue end
end
local predictedPos = PredictPosition(npc, part)
local sp, on = Camera:WorldToViewportPoint(predictedPos)
if on then
local sd = (Vector2.new(sp.X, sp.Y) - center).Magnitude
if sd <= FOVSize then
local wd = (myRoot.Position - part.Position).Magnitude
table.insert(targets, {target=npc, part=part, sd=sd, wd=wd, hp=hum.Health, predictedPos=predictedPos})
end
end
end
end
end
end
if #targets == 0 then
if fovCircle then
fovCircle.Color = Color3.fromRGB(255, 60, 60);fovCircle.Visible = ShowFOV
end
aimbotTarget = nil
currentTargetLabel.Text = "  当前目标: 无"
return
end
table.sort(targets, function(a, b)
if PriorityMode == "距离最近" then return a.wd < b.wd
elseif PriorityMode == "血量最低" then return a.hp < b.hp
else return a.sd < b.sd end
end)
local t = targets[1]
aimbotTarget = t.target
if t.target:IsA("Player") then
currentTargetLabel.Text = "  当前目标: " .. t.target.DisplayName
else
currentTargetLabel.Text = "  当前目标: " .. t.target.Name
end
if fovCircle then
fovCircle.Color = Color3.fromRGB(100, 255, 100);fovCircle.Visible = ShowFOV
end
local targetPosition = t.predictedPos or t.part.Position
if LockMode == "强锁" then
Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
elseif LockMode == "平滑" then
local targetCF = CFrame.new(Camera.CFrame.Position, targetPosition)
local smoothFactor = math.min(1, deltaTime * 10)
Camera.CFrame = Camera.CFrame:Lerp(targetCF, smoothFactor)
else
local targetCF = CFrame.new(Camera.CFrame.Position, targetPosition)
local smoothValue = 1 / Smoothness
if targetVelocity.Magnitude > 10 then
smoothValue = math.min(0.5, smoothValue * 0.8)
end
Camera.CFrame = Camera.CFrame:Lerp(targetCF, smoothValue)
end
if AutoShoot and aimbotTarget then
pcall(function()
if localChar then
for _, tool in pairs(localChar:GetChildren()) do
if tool:IsA("Tool") then
if tool:FindFirstChild("Activate") then
local handle = tool:FindFirstChild("Handle")
if handle and handle:IsA("BasePart") then
local distance = (handle.Position - targetPosition).Magnitude
if distance < 1000 then
tool:Activate()
if tool:FindFirstChild("Automatic") or tool:FindFirstChild("Auto") then
end
end
end
end
end
end
end
end)
end
end)
if not ok then
warn("[自瞄V8] 渲染循环错误:", err)
end
end)
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer then
CreateESP(plr)
end
end
Players.PlayerAdded:Connect(function(plr)
if plr ~= LocalPlayer then
CreateESP(plr)
end
end)
Players.PlayerRemoving:Connect(function(plr)
if ESPData[plr] then
for _, d in pairs(ESPData[plr]) do
pcall(function() d:Remove() end)
end
ESPData[plr] = nil
end
end)
