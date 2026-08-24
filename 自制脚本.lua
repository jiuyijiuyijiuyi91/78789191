local repo = "https://raw.githubusercontent.com/ATLASTEAM01/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({ Title = "XJW中心", Footer = "1.3", Center = true, AutoShow = true })

local Tabs = {
    Main = Window:AddTab("主页", "user"),
    ["UI Settings"] = Window:AddTab("UI设置", "settings"),
}

-- 主页
local AnnouncementBox = Tabs.Main:AddLeftGroupbox("公告")
AnnouncementBox:AddLabel("本脚本为缝合脚本")

local MainSettingsBox = Tabs.Main:AddLeftGroupbox("脚本区")
MainSettingsBox:AddButton("ROBv4", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/idrobsc/rob_script/refs/heads/main/rob.v4"))()
end)

MainSettingsBox:AddButton("AF HUB", function()
    getgenv().SCRIPT_KEY = ""
    loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/4e025c3c0ccda1554634165acb8f8ee2c1de5f0f8d7f60e7b396c622d7e6e9b0/download"))()
end)

MainSettingsBox:AddButton("叶脚本", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/roblox-ye/QQ515966991/refs/heads/main/ROBLOX-CNVIP-XIAOYE.lua"))()
end)

local FeatureBox = Tabs.Main:AddRightGroupbox("功能")
FeatureBox:AddButton("恐脚本飞行", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kongbaNB/9178/refs/heads/main/fly.lua"))()
end)

FeatureBox:AddButton("静默甩飞", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/jiuyijiuyijiuyi91/78789191/refs/heads/main/%E9%9D%99%E9%BB%98%E7%94%A9%E9%A3%9E(%E5%BC%80%E6%BA%90).lua"))()
end)

FeatureBox:AddButton("祖国人汉化", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kongbaNB/-/refs/heads/main/祖国人汉化"))()
end)

-- UI设置
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("UniversalSilentAim/Configs")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()