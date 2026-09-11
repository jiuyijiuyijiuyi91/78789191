local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()

local Window = WindUI:CreateWindow({
    Title = "XJW中心",
    Icon = "sparkles",
    Author = "XJW",
    Folder = "XJWCenter",
    Size = UDim2.fromOffset(420, 460),
    Theme = "Light",
    HideSearchBar = false,
})

local ClockTag = Window:Tag({
    Title = os.date("%H:%M"),
    Color = Color3.fromRGB(255, 255, 255)
})

task.spawn(function()
    while true do
        task.wait(15)
        if Window.Destroyed then break end
        pcall(function()
            ClockTag:SetTitle(os.date("%H:%M"))
            ClockTag:SetColor(Color3.fromRGB(255, 255, 255))
        end)
    end
end)

Window:Tag({
    Title = "服务器功能",
    Color = Color3.fromRGB(255, 255, 255)
})

Window:EditOpenButton({
    Title = "XJW中心",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
    Draggable = true,
})

local function loadGame(name, url)
    WindUI:Notify({ Title = "正在加载", Content = name, Duration = 3 })
    task.spawn(function()
        local ok, content = pcall(function()
            return game:HttpGet(url)
        end)
        if not ok or not content or #content == 0 then
            WindUI:Notify({ Title = "加载失败", Content = name .. " 下载失败", Duration = 5 })
            return
        end
        local fn, compileErr = loadstring(content)
        if not fn then
            WindUI:Notify({ Title = "编译失败", Content = tostring(compileErr), Duration = 5 })
            return
        end
        local runOk, runErr = pcall(fn)
        if not runOk then
            WindUI:Notify({ Title = "运行出错", Content = tostring(runErr), Duration = 5 })
        end
    end)
end

local function makeTab(title, icon)
    local ok, tab = pcall(function()
        return Window:Tab({ Title = title, Icon = icon, Locked = false })
    end)
    if ok and tab then return tab end
    local ok2, tab2 = pcall(function()
        return Window:Tab({ Title = title, Locked = false })
    end)
    if ok2 then return tab2 end
    return nil
end

local GAMES = {
    {
        Name = "忍者传奇",
        Icon = "zap",
        Url = "https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E5%BF%8D%E8%80%85%E4%BC%A0%E5%A5%87XJW.lua",
        PlaceId = "3956818381",
        Keys = { "Ninja Legends" },
    },
    {
        Name = "力量传奇（安脚本）",
        Icon = "dumbbell",
        Url = "https://raw.githubusercontent.com/Anscripterato/QQ2134702438/refs/heads/main/byato/AnScript/atoscript",
        PlaceId = "3623096087",
        Keys = { "Muscle Legends" },
    },
    {
        Name = "极速传奇",
        Icon = "rocket",
        Url = "https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/XJW%E6%9E%81%E9%80%9F%E4%BC%A0%E5%A5%87.lua",
        PlaceId = "3101667897",
        Keys = { "Legends of Speed", "Legends Of Speed" },
    },
    {
        Name = "英雄时代",
        Icon = "shield",
        Url = "https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E8%8B%B1%E9%9B%84%E6%97%B6%E4%BB%A3.lua",
        PlaceId = "4866692557",
        Keys = { "Age of Heroes" },
    },
    {
        Name = "NPC或死亡",
        Icon = "skull",
        Url = "https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/NPC%E6%88%96%E6%AD%BB%E4%BA%A1.lua",
        PlaceId = "11276071411",
        Keys = { "Be NPC or DIE", "NPC or DIE" },
    },
    {
        Name = "建造一架飞机",
        Icon = "plane",
        Url = "https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E5%BB%BA%E9%80%A0%E4%B8%80%E4%B8%AA%E9%A3%9E%E6%9C%BA.lua",
        PlaceId = "137925884276740",
        Keys = { "Build A Plane", "Build a Plane" },
    },
    {
        Name = "[FPS]一键点击",
        Icon = "mouse-pointer-click",
        Url = "https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/FPS%E4%B8%80%E9%94%AE%E7%94%B5%E5%87%BB.lua",
        PlaceId = "90568084448279",
        Keys = { "One Tap" },
    },
    {
        Name = "捕捉10亿只鸭子",
        Icon = "target",
        Url = "https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E6%8D%95%E6%8D%8910%E4%BA%BF%E5%8F%AA%E9%B8%AD%E5%AD%90.lua",
        PlaceId = "100293509865504",
        Keys = { "1 Billion Ducks", "Billion Ducks" },
    },
    {
        Name = "清理所有枫叶",
        Icon = "leaf",
        Url = "https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E6%B8%85%E7%90%86%E6%89%80%E4%BB%A5%E6%9E%AB%E5%8F%B6.lua",
        PlaceId = "92637789841354",
        Keys = { "Clean All The Leaves", "Clean All the Leaves" },
    },
}

local function detectGame()
    local placeId = ""
    pcall(function()
        placeId = tostring(game.PlaceId)
    end)
    for _, g in ipairs(GAMES) do
        if g.PlaceId == placeId then
            return g
        end
    end
    local names = {}
    pcall(function()
        local n = tostring(game.Name or "")
        if n ~= "" then table.insert(names, string.lower(n)) end
    end)
    pcall(function()
        local info = game:GetService("MarketplaceService"):GetProductInfo(tonumber(placeId))
        if info and info.Name then
            table.insert(names, string.lower(tostring(info.Name)))
        end
    end)
    for _, g in ipairs(GAMES) do
        for _, k in ipairs(g.Keys or {}) do
            local key = string.lower(k)
            for _, n in ipairs(names) do
                if n ~= "" and string.find(n, key, 1, true) then
                    return g
                end
            end
        end
    end
    return nil
end

task.spawn(function()
    local tab = makeTab("当前服务器", "server")
    if tab then
        tab:Section({ Title = "加载当前服务器", TextXAlignment = "Left", TextSize = 17 })

        local para = nil
        local ok, p = pcall(function()
            return tab:Paragraph({
                Title = "识别状态",
                Desc = "未识别到当前服务器",
            })
        end)
        if ok and p then para = p end
        if not para then
            pcall(function()
                tab:Section({ Title = "未识别到当前服务器" })
            end)
        end

        local refresh
        refresh = function()
            local g = detectGame()
            local text
            if g then
                text = "已识别当前服务器：" .. g.Name
            else
                text = "未识别到当前服务器"
            end
            if para then
                pcall(function() para:SetDesc(text) end)
            end
            return g, text
        end

        refresh()

        tab:Button({
            Title = "加载当前服务器",
            Callback = function()
                task.spawn(function()
                    local g = refresh()
                    if g then
                        WindUI:Notify({ Title = "已识别当前服务器", Content = g.Name, Duration = 3 })
                        loadGame(g.Name, g.Url)
                    else
                        WindUI:Notify({ Title = "未识别到当前服务器", Content = "当前服务器不在支持列表内", Duration = 4 })
                    end
                end)
            end,
        })
    end

    for _, g in ipairs(GAMES) do
        local gtab = makeTab(g.Name, g.Icon)
        if gtab then
            gtab:Section({ Title = "游戏脚本", TextXAlignment = "Left", TextSize = 17 })
            gtab:Button({
                Title = g.Name,
                Callback = function()
                    loadGame(g.Name, g.Url)
                end,
            })
        end
    end
end)
