-- XJW中心 加载器 (SuzumeUI/WindUI)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()

local Window = WindUI:CreateWindow({
    Title = "XJW中心",
    Icon = "sparkles",
    Author = "XJW中心",
    Folder = "XJWCenter",
    Size = UDim2.fromOffset(400, 300),
    Theme = "Blue",
    HideSearchBar = true,
})

-- 时间标签
local TimeTag = Window:Tag({
    Title = "00:00",
    Color = Color3.fromRGB(255, 255, 255)
})

task.spawn(function()
    while true do
        local now = os.date("*t")
        TimeTag:SetTitle(string.format("%02d:%02d", now.hour, now.min))
        task.wait(0.5)
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

local Tab = Window:Tab({
    Title = "加载",
    Icon = "rocket",
    Locked = false,
})

Tab:Section({Title = "XJW中心", TextXAlignment = "Center", TextSize = 18})

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
                    Content = "正在加载...",
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
