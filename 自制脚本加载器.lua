-- XJW中心 加载器 (SuzumeUI/WindUI 完整版)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Window = WindUI:CreateWindow({
    Title = "XJW中心",
    Icon = "sparkles",
    Author = "XJW中心",
    Folder = "XJWCenter",
    Size = UDim2.fromOffset(400, 400),
    Theme = "Blue",
    HideSearchBar = false,
})

-- 模糊效果
local blur = Instance.new("BlurEffect")
blur.Size = 12
blur.Parent = game:GetService("Lighting")

-- 边框流动效果
local mainContainer = Window.UIElements and Window.UIElements.Main
if mainContainer then
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.new(1, 1, 1)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 130, 255)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(0, 200, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 130, 255)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 130, 255)),
    })
    gradient.Enabled = true
    gradient.Parent = stroke
    stroke.Parent = mainContainer

    task.spawn(function()
        local speed = 8
        while stroke and stroke.Parent do
            task.wait()
            gradient.Rotation = (gradient.Rotation + speed) % 360
        end
    end)
end

-- 时间标签 (彩虹色)
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
    Title = "加载器",
    Color = Color3.fromHex("#7FDBFF")
})

Window:EditOpenButton({
    Title = "XJW中心加载器",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromHex("4A90D9")),
    Draggable = true,
})

-- 加载标签页
local Tab = Window:Tab({
    Title = "XJW中心",
    Icon = "rocket",
    Locked = false,
})

Tab:Section({Title = "XJW中心加载器", TextXAlignment = "Center", TextSize = 18})

Tab:Paragraph({
    Title = "XJW中心",
    Desc = "是否加载XJW中心脚本?",
    ImageSize = 20,
    Buttons = {
        {
            Title = "继续加载",
            Icon = "play",
            Variant = "Primary",
            Callback = function()
                WindUI:Notify({
                    Title = "XJW中心",
                    Content = "正在加载脚本...",
                    Duration = 3
                })
                task.wait(0.3)
                pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E8%87%AA%E5%88%B6%E8%84%9A%E6%9C%AC.lua"))()
                end)
            end
        },
        {
            Title = "取消",
            Icon = "x",
            Variant = "Tertiary",
            Callback = function()
                WindUI:Notify({
                    Title = "已取消",
                    Content = "加载已取消",
                    Duration = 3
                })
            end
        }
    }
})

-- 信息标签页
local InfoTab = Window:Tab({
    Title = "信息",
    Icon = "info",
    Locked = false,
})

InfoTab:Section({Title = "关于", TextXAlignment = "Left", TextSize = 17})

InfoTab:Paragraph({
    Title = "XJW中心",
    Desc = "XJW中心是一个缝合脚本，包含多种功能。\n加载器版本: 1.0\nUI: SuzumeUI/WindUI",
    ImageSize = 20,
    Buttons = {
        {
            Title = "复制脚本链接",
            Icon = "copy",
            Variant = "Tertiary",
            Callback = function()
                if setclipboard then
                    setclipboard("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E8%87%AA%E5%88%B6%E8%84%9A%E6%9C%AC.lua")
                    WindUI:Notify({
                        Title = "已复制",
                        Content = "脚本链接已复制到剪贴板",
                        Duration = 5
                    })
                else
                    WindUI:Notify({
                        Title = "错误",
                        Content = "当前执行器不支持复制功能",
                        Duration = 5
                    })
                end
            end
        }
    }
})
