local Repos = {
    "https://raw.githubusercontent.com/ATLASTEAM01/Obsidian/main/",
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/",
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/master/",
}

local function Fetch(path)
    for attempt = 1, 3 do
        for _, repo in ipairs(Repos) do
            local ok, res = pcall(function()
                return game:HttpGet(repo .. path)
            end)
            if ok and res and #res > 0 then
                return res
            end
        end
        task.wait(1)
    end
    return nil
end

local libSrc = Fetch("Library.lua")
if not libSrc then
    return
end
local Library = loadstring(libSrc)()
local ThemeManager = nil
local SaveManager = nil
local themeSrc = Fetch("addons/ThemeManager.lua")
if themeSrc then
    local ok, f = pcall(loadstring, themeSrc)
    if ok and f then
        pcall(function()
            ThemeManager = f()
        end)
    end
end
local saveSrc = Fetch("addons/SaveManager.lua")
if saveSrc then
    local ok, f = pcall(loadstring, saveSrc)
    if ok and f then
        pcall(function()
            SaveManager = f()
        end)
    end
end

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({ Title = "骑宠物", Footer = "XJW", Center = true, AutoShow = true })

local Tabs = {
    Main = Window:AddTab("主页", "user"),
    ["UI Settings"] = Window:AddTab("UI设置", "settings"),
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LP = game:GetService("Players").LocalPlayer

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local GameR = Remotes and Remotes:FindFirstChild("Game")
local Plot = GameR and GameR:FindFirstChild("Plot")
local Upgrades = Plot and Plot:FindFirstChild("Upgrades")
local PetCollect = GameR and GameR:FindFirstChild("PetCollect")
local function GetPetId(pet)
	if type(pet) ~= "userdata" then return nil end
	if type(pet.Name) == "string" and pet.Name:match("^[%x%-]+$") then
		return pet.Name
	end
	for _, k in ipairs({"Id","ID","PetId","PetID","UID","Uid","Value","UUID"}) do
		local v = pet:FindFirstChild(k)
		if v and v:IsA("ValueBase") and type(v.Value) == "string" and v.Value ~= "" then
			return v.Value
		end
	end
	for _, v in ipairs(pet:GetChildren()) do
		if v:IsA("ValueBase") and type(v.Value) == "string" and v.Value:match("^[%x%-]+$") then
			return v.Value
		end
	end
	local ok, a = pcall(function()
		return pet:GetAttribute("Id") or pet:GetAttribute("ID") or pet:GetAttribute("PetId") or pet:GetAttribute("UID") or pet:GetAttribute("UUID")
	end)
	if ok and type(a) == "string" and a ~= "" then return a end
	return nil
end
local function CollectPetIds()
	local seen, ids = {}, {}
	local plots = workspace:FindFirstChild("Plots")
	if not plots then return ids end
	for _, plot in ipairs(plots:GetChildren()) do
		local pets = plot:FindFirstChild("Pets")
		if pets then
			for _, pet in ipairs(pets:GetChildren()) do
				local id = GetPetId(pet)
				if id and not seen[id] then
					seen[id] = true
					ids[#ids+1] = id
				end
			end
		end
	end
	return ids
end
local Rebirth = GameR and GameR:FindFirstChild("Rebirth")

local EggFolders = {}
do
    local a = workspace:FindFirstChild("EggSpawns")
    if a then EggFolders[#EggFolders + 1] = a end
    local b = workspace:FindFirstChild("RenderedEggs")
    if b then EggFolders[#EggFolders + 1] = b end
    local c = workspace:FindFirstChild("Eggs")
    if c then EggFolders[#EggFolders + 1] = c end
end

local TranslateMap = {
    Common = "普通", Uncommon = "罕见", Rare = "稀有", Epic = "史诗",
    Legendary = "传说", Mythic = "神话", Ultimate = "终极", Ultra = "超级",
    Super = "超级", Mega = "巨型", Divine = "神圣", Celestial = "天体",
    Cosmic = "宇宙", Galactic = "星系", Space = "太空", Star = "星星",
    Galaxy = "银河", Moon = "月亮", Sun = "太阳", Shadow = "暗影",
    Dark = "黑暗", Light = "光明", Fire = "火焰", Flame = "烈焰",
    Ice = "冰霜", Frost = "寒霜", Water = "水", Aqua = "水",
    Ocean = "海洋", Earth = "大地", Nature = "自然", Plant = "植物",
    Leaf = "叶子", Electric = "闪电", Thunder = "雷电", Lightning = "闪电",
    Wind = "风", Air = "风", Rock = "岩石", Stone = "石头",
    Metal = "金属", Gold = "黄金", Golden = "黄金", Silver = "白银",
    Diamond = "钻石", Crystal = "水晶", Ruby = "红宝石", Emerald = "绿宝石",
    Sapphire = "蓝宝石", Amethyst = "紫水晶", Pearl = "珍珠", Dragon = "龙",
    Drake = "龙", Wyvern = "双足飞龙", Phoenix = "凤凰", Unicorn = "独角兽",
    Pegasus = "天马", Griffin = "狮鹫", Hydra = "九头蛇", Kraken = "海妖",
    Leviathan = "巨兽", Titan = "泰坦", Giant = "巨人", Dino = "恐龙",
    Dinosaur = "恐龙", Rex = "霸王龙", Wolf = "狼", Fox = "狐狸",
    Bear = "熊", Tiger = "老虎", Lion = "狮子", Panther = "黑豹",
    Cat = "猫", Kitten = "小猫", Dog = "狗", Puppy = "小狗",
    Bunny = "兔子", Rabbit = "兔子", Bird = "鸟", Owl = "猫头鹰",
    Eagle = "鹰", Hawk = "鹰", Penguin = "企鹅", Panda = "熊猫",
    Koala = "考拉", Monkey = "猴子", Elephant = "大象", Giraffe = "长颈鹿",
    Zebra = "斑马", Horse = "马", Cow = "牛", Pig = "猪",
    Sheep = "羊", Goat = "山羊", Chicken = "鸡", Duck = "鸭",
    Frog = "青蛙", Turtle = "乌龟", Snake = "蛇", Shark = "鲨鱼",
    Whale = "鲸鱼", Dolphin = "海豚", Fish = "鱼", Crab = "螃蟹",
    Octopus = "章鱼", Jellyfish = "水母", Spider = "蜘蛛", Scorpion = "蝎子",
    Bee = "蜜蜂", Butterfly = "蝴蝶", Bug = "虫子", Egg = "蛋",
    Royal = "皇家", King = "国王", Queen = "女王", Emperor = "帝王",
    Guardian = "守护者", Ancient = "远古", Primal = "原始", Wild = "野性",
    Cursed = "诅咒", Corrupt = "腐化", Void = "虚空", Abyss = "深渊",
    Inferno = "地狱", Blaze = "烈焰", Storm = "风暴", Venom = "毒液",
    Poison = "剧毒", Toxic = "剧毒", Fairy = "精灵", Elf = "精灵",
    Angel = "天使", Demon = "恶魔", Devil = "恶魔", Ghost = "幽灵",
    Spirit = "灵魂", Skeleton = "骷髅", Zombie = "僵尸", Vampire = "吸血鬼",
    Werewolf = "狼人", Mermaid = "美人鱼", Robot = "机器人", Mech = "机甲",
    Cyber = "赛博", Neon = "霓虹", Laser = "激光", Plasma = "等离子",
    Quantum = "量子", Time = "时空", Chrono = "时空", Candy = "糖果",
    Lollipop = "棒棒糖", Cookie = "饼干", Cake = "蛋糕", IceCream = "冰淇淋",
    Volcanic = "火山",
    White = "白色", Brown = "棕色", Cracked = "破裂", Slime = "史莱姆",
    Glass = "玻璃", Skull = "骷髅", Asteroid = "小行星", Dominus = "至尊",
    Flaming = "燃烧", Sinister = "凶煞", Soul = "灵魂", Tidal = "潮汐",
    Bloom = "绽放", BlackHole = "黑洞", Black = "黑", Hole = "洞", Solaris = "太阳神", Cherub = "天使",
    Sacred = "神圣", Holy = "神圣", Blessed = "祝福", Godly = "神级",
    Shiny = "闪光", Luminous = "发光", Radiant = "光辉", Ethereal = "空灵",
    Enchanted = "附魔", Magical = "魔法", Mystic = "神秘", Spectral = "幽灵",
    Phantom = "幻影", Prism = "棱镜", Aurora = "极光", Comet = "彗星",
    Meteor = "流星", Nebula = "星云", Solar = "太阳", Lunar = "月亮",
    Angelic = "天使", Demonic = "恶魔", Mythical = "神话", Exotic = "异域",
    Fabled = "传说",
    Alpha = "阿尔法", Omega = "欧米伽", Beta = "贝塔", Gamma = "伽马", Delta = "德尔塔",
    Rainbow = "彩虹", Prismatic = "棱镜", Stardust = "星尘", Starfall = "流星雨",
    Supernova = "超新星", Blackhole = "黑洞", Wormhole = "虫洞", Galaxy = "星系",
    Celestial = "天体", Cosmic = "宇宙", Nebula = "星云", Comet = "彗星",
    Glacier = "冰川", Arctic = "北极", Polar = "极地", Snowy = "雪", Winter = "冬季",
    Frozen = "冰冻", Frost = "寒霜", Blizzard = "暴风雪", Molten = "熔融", Magma = "岩浆",
    Lava = "熔岩", Ember = "余烬", Inferno = "地狱", Scorch = "灼烧", Cinder = "灰烬",
    Eternal = "永恒", Immortal = "不朽", Infinite = "无限", Infinity = "无限",
    Supreme = "至高", Prime = "至尊", Hyper = "超级", Mighty = "强大", Majestic = "雄伟",
    Abyssal = "深渊", Deep = "深海", Abyss = "深渊", Void = "虚空", Nether = "下界",
    Hell = "地狱", Devil = "恶魔", Demon = "恶魔", Reaper = "死神", Grim = "死神",
    Mummy = "木乃伊", Pharaoh = "法老", Necro = "死灵", Haunted = "闹鬼",
    Spooky = "惊悚", Pumpkin = "南瓜", Ghostly = "幽灵", Wraith = "怨灵",
    Christmas = "圣诞", Easter = "复活节", Halloween = "万圣节", Candy = "糖果",
    Huge = "巨型", Mega = "巨型", Gargantuan = "庞然大物", Titan = "泰坦",
    King = "国王", Queen = "女王", Emperor = "帝王", Empress = "女皇",
    Royal = "皇家", Noble = "贵族", Knight = "骑士", Paladin = "圣骑士",
    Wizard = "巫师", Witch = "女巫", Mage = "法师", Sorcerer = "巫师",
    Ninja = "忍者", Samurai = "武士", Pirate = "海盗", Viking = "维京人",
    Dragon = "龙", Drake = "龙", Wyvern = "飞龙", Hydra = "九头蛇", Serpent = "巨蛇",
    Basilisk = "蛇怪", Chimera = "奇美拉", Golem = "魔像", Yeti = "雪人",
    Bigfoot = "大脚怪", Sasquatch = "大脚怪", Nessie = "尼斯湖水怪", Loch = "湖怪",
    Megalodon = "巨齿鲨", Shark = "鲨鱼", Kraken = "海妖", Leviathan = "巨兽",
    Squid = "鱿鱼", Jellyfish = "水母", Octopus = "章鱼", Crab = "螃蟹",
    Lobster = "龙虾", Turtle = "乌龟", Crocodile = "鳄鱼", Dinosaur = "恐龙",
    Rex = "霸王龙", Raptor = "迅猛龙", Pterodactyl = "翼龙", Stegosaurus = "剑龙",
    Triceratops = "三角龙", Brontosaurus = "雷龙", Mammoth = "猛犸", Saber = "剑齿虎",
    Unicorn = "独角兽", Pegasus = "天马", Griffin = "狮鹫", Phoenix = "凤凰",
    Fairy = "精灵", Elf = "精灵", Pixie = "小仙子", Sprite = "小精灵", Gnome = "地精",
    Goblin = "哥布林", Orc = "兽人", Troll = "巨魔", Ogre = "食人魔", Dwarf = "矮人",
    Zombie = "僵尸", Skeleton = "骷髅", Ghost = "幽灵", Vampire = "吸血鬼",
    Werewolf = "狼人", Wolf = "狼", Fox = "狐狸", Bear = "熊", Panda = "熊猫",
    Koala = "考拉", Tiger = "老虎", Lion = "狮子", Leopard = "豹", Panther = "黑豹",
    Cheetah = "猎豹", Jaguar = "美洲豹", Elephant = "大象", Giraffe = "长颈鹿",
    Zebra = "斑马", Rhino = "犀牛", Hippo = "河马", Camel = "骆驼", Kangaroo = "袋鼠",
    Monkey = "猴子", Gorilla = "大猩猩", Chimpanzee = "黑猩猩", Penguin = "企鹅",
    Owl = "猫头鹰", Eagle = "鹰", Hawk = "隼", Falcon = "猎鹰", Raven = "乌鸦",
    Crow = "乌鸦", Parrot = "鹦鹉", Flamingo = "火烈鸟", Peacock = "孔雀",
    Swan = "天鹅", Goose = "鹅", Turkey = "火鸡", Duck = "鸭子", Chicken = "鸡",
    Frog = "青蛙", Toad = "蟾蜍", Snake = "蛇", Lizard = "蜥蜴", Chameleon = "变色龙",
    Butterfly = "蝴蝶", Bee = "蜜蜂", Wasp = "黄蜂", Spider = "蜘蛛", Scorpion = "蝎子",
    Ant = "蚂蚁", Beetle = "甲虫", Ladybug = "瓢虫", Caterpillar = "毛毛虫",
    Fish = "鱼", Whale = "鲸鱼", Dolphin = "海豚", Seal = "海豹", Walrus = "海象",
    Penguin = "企鹅", Shark = "鲨鱼", Starfish = "海星", Seahorse = "海马",
    Jellyfish = "水母", Coral = "珊瑚", Shell = "贝壳", Pearl = "珍珠",
    Flower = "花", Rose = "玫瑰", Tulip = "郁金香", Lily = "百合", Lotus = "莲花",
    Cherry = "樱花", Blossom = "花", Tree = "树", Pine = "松树", Cactus = "仙人掌",
    Bamboo = "竹子", Mushroom = "蘑菇", Berry = "浆果", Strawberry = "草莓",
    Watermelon = "西瓜", Apple = "苹果", Orange = "橙子", Lemon = "柠檬",
    Grape = "葡萄", Peach = "桃子", Banana = "香蕉", Coconut = "椰子",
    Cookie = "饼干", Cake = "蛋糕", Cupcake = "纸杯蛋糕", Donut = "甜甜圈",
    Icecream = "冰淇淋", Chocolate = "巧克力", Gummy = "软糖", Candy = "糖果",
    Ruby = "红宝石", Sapphire = "蓝宝石", Emerald = "绿宝石", Diamond = "钻石",
    Amethyst = "紫水晶", Opal = "蛋白石", Jade = "翡翠", Onyx = "黑玛瑙",
    Obsidian = "黑曜石", Garnet = "石榴石", Topaz = "黄玉", Amber = "琥珀",
    Quartz = "石英", Crystal = "水晶", Gem = "宝石", Gold = "黄金", Silver = "白银",
    Bronze = "青铜", Iron = "铁", Steel = "钢", Copper = "铜", Platinum = "铂金",
    Neon = "霓虹", Glow = "发光", Glowstick = "荧光棒", Light = "光", Dark = "黑暗",
    Shadow = "暗影", Night = "夜晚", Midnight = "午夜", Dawn = "黎明", Dusk = "黄昏",
    Sunrise = "日出", Sunset = "日落", Sky = "天空", Cloud = "云", Star = "星星",
    Moon = "月亮", Sun = "太阳", Fire = "火", Flame = "烈焰", Water = "水",
    Ice = "冰", Snow = "雪", Wind = "风", Storm = "风暴", Thunder = "雷电",
    Lightning = "闪电", Hurricane = "飓风", Tornado = "龙卷风", Tsunami = "海啸",
    Earthquake = "地震", Jungle = "丛林", Desert = "沙漠", Forest = "森林",
    Savanna = "草原", Tundra = "冻土", Mountain = "山", River = "河", Lake = "湖",
    Island = "岛屿", Beach = "海滩", Cave = "洞穴", Mine = "矿洞", Volcano = "火山",
    Baby = "宝宝", Pet = "宠物", Champ = "冠军", Hero = "英雄", Legend = "传奇",
}

local QualityWords = {
    "普通", "罕见", "稀有", "史诗", "传说", "神话", "终极", "超级", "巨型",
    "神圣", "天体", "宇宙", "星系", "太空", "银河", "皇家", "国王", "女王",
    "帝王", "守护者", "远古", "原始", "野性", "诅咒", "腐化", "虚空", "深渊",
    "地狱", "烈焰", "暗影", "黑暗", "光明", "黄金", "白银", "火山",
    "祝福", "神级", "闪光", "发光", "光辉", "空灵", "附魔", "异域",
}

local function SplitCamel(name)
    local parts = {}
    for w in name:gmatch("%u?%l+") do
        parts[#parts + 1] = w
    end
    if #parts == 0 then
        local low = name:lower()
        if low == name then
            parts[#parts + 1] = name:gsub("^%l", string.upper)
        elseif name:match("^%u+$") then
            parts[#parts + 1] = low:gsub("^%l", string.upper)
        else
            parts[#parts + 1] = name
        end
    end
    return parts
end

local UnknownWords = {}

local function CollectUnknown(w)
    if not UnknownWords[w] then
        UnknownWords[w] = true
    end
end

local function TranslateName(name)
    local words = {}
    for w in name:gmatch("[^%s_]+") do
        words[#words + 1] = w
    end
    if #words == 0 then words = { name } end
    local out = {}
    for _, w in ipairs(words) do
        w = w:gsub("%d+", "")
        if w ~= "" then
            local t = TranslateMap[w]
            if not t then
                local sub = SplitCamel(w)
                local subOut = {}
                local foundAny = false
                for _, s in ipairs(sub) do
                    local ts = TranslateMap[s]
                    if ts then
                        subOut[#subOut + 1] = ts
                        foundAny = true
                    else
                        CollectUnknown(s)
                    end
                end
                if not foundAny then
                    CollectUnknown(w)
                end
                if #subOut > 0 then
                    t = table.concat(subOut)
                end
            end
            if t then
                out[#out + 1] = t
            end
        end
    end
    if #out == 0 then
        return nil
    end
    return table.concat(out)
end

local AllEggNames = {
    "White Egg", "Brown Egg", "Cracked Egg", "Easter Egg", "Stone Egg",
    "Leaf Egg", "Mushroom Egg", "Flower Egg", "Slime Egg", "Ice Egg",
    "Glass Egg", "Golden Egg", "Diamond Egg", "Crystal Egg", "Skull Egg",
    "Asteroid Egg", "Dominus Egg", "Flaming Egg", "Sinister Egg", "Soul Egg",
    "Tidal Egg", "Aurora Egg", "Galaxy Egg", "Bloom Egg", "Black Hole Egg",
    "Solaris Egg", "Cherub Egg", "Volcanic Egg",
}
local function NormalName(s)
    return s:gsub("[^%a]+", ""):lower()
end

local EggAliases = {
    ["Celestial Egg"] = "Aurora Egg",
    ["Black Dog Egg"] = "Black Hole Egg",
    ["Black Dog"] = "Black Hole Egg",
    ["Dog"] = "Black Hole Egg",
}
local function OfficialFull(rawName)


    local key = NormalName(rawName)
    for alias, target in pairs(EggAliases) do
        local ak = NormalName(alias)
        if key == ak or key:sub(-#ak) == ak then
            rawName = target
            break
        end
    end



    local key2 = NormalName(rawName)
    for _, n in ipairs(AllEggNames) do
        local nk = NormalName(n)
        local core = nk:gsub("egg$", "")
        if key2 == nk or key2:sub(-#nk) == nk or (#core >= 3 and key2:find(core, 1, true)) then
            return TranslateName(n) or "蛋"
        end
    end

    return TranslateName(rawName) or "蛋"
end

task.spawn(function()
    while true do
        task.wait(5)
        local words = {}
        for w in pairs(UnknownWords) do
            words[#words + 1] = w
        end
        if #words > 0 then
            table.sort(words)
            local content = table.concat(words, "\n")
            pcall(function()
                if makefolder and not isfolder("骑宠物") then
                    makefolder("骑宠物")
                end
                writefile("骑宠物/未知词.txt", content)
            end)
        end
    end
end)

local function CleanName(obj)
    local t = OfficialFull(obj.Name)
    if not t then return nil end
    t = t:gsub("蛋$", "")
    for _, q in ipairs(QualityWords) do
        t = t:gsub(q, "")
    end
    if #t == 0 then return nil end
    return t
end

local function DisplayName(obj)
    local t = OfficialFull(obj.Name)
    if not t then return nil end
    t = t:gsub("蛋$", "")
    if #t == 0 then return nil end
    return t
end
local function GetChar()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function GetRoot()
    local char = GetChar()
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
end

local function IsExcluded(name)
    return name == "Common"
end

local HatchedMarks = { "Hatched", "Claimed", "Collected", "Used", "Open", "Taken", "PickedUp", "Gone", "IsHatched", "Hatching", "Stolen", "StolenBy", "CollectedBy", "Incubated" }

local function IsAliveEgg(obj)
    if not obj.Parent then return false end
    local parts = {}
    local function walk(n)
        for _, c in ipairs(n:GetChildren()) do
            if c:IsA("BasePart") then
                parts[#parts + 1] = c
            elseif c:IsA("Model") or c:IsA("Folder") then
                walk(c)
            end
        end
    end
    if obj:IsA("BasePart") then
        parts[#parts + 1] = obj
    end
    walk(obj)
    if #parts == 0 then return false end
    local maxP, maxVol = nil, 0
    for _, p in ipairs(parts) do
        local v = p.Size.X * p.Size.Y * p.Size.Z
        if v > maxVol then
            maxVol = v
            maxP = p
        end
    end
    if not maxP then return false end
    if maxP.Transparency >= 0.3 then return false end
    local mn = maxP.Name:lower()
    if mn:find("base") or mn:find("pedestal") or mn:find("stand") or mn:find("platform") or mn:find("ground") or mn:find("ring") or mn:find("circle") or mn:find("holder") or mn:find("plate") or mn:find("decal") or mn:find("fx") or mn:find("effect") or mn:find("glow") or mn:find("spawn") or mn:find("decoration") or mn:find("truss") or mn:find("mesh") or mn:find("attachment") or mn:find("surface") or mn:find("light") or mn:find("pillar") or mn:find("column") or mn:find("floor") or mn:find("tile") then
        return false
    end
    local function hasMark(n)
        for _, c in ipairs(n:GetChildren()) do
            if c:IsA("BoolValue") and c.Value then
                for _, m in ipairs(HatchedMarks) do
                    if c.Name == m then return true end
                end
            end
            if (c:IsA("Model") or c:IsA("Folder")) and hasMark(c) then return true end
        end
        return false
    end
    if hasMark(obj) then return false end
    return true
end

local function CollectEggs()
    local list = {}
    local function walk(node)
        for _, child in ipairs(node:GetChildren()) do
            if not IsExcluded(child.Name) then
                local pos = nil
                if child:IsA("BasePart") then
                    pos = child.Position
                else
                    local part = child:FindFirstChildWhichIsA("BasePart")
                    if part then pos = part.Position end
                end
                if pos and IsAliveEgg(child) then
                    list[#list + 1] = { Obj = child, Pos = pos }
                end
                if child:IsA("Model") or child:IsA("Folder") then
                    walk(child)
                end
            end
        end
    end
    for _, folder in ipairs(EggFolders) do
        walk(folder)
    end
    return list
end

local function SetPos(root, pos)
    root.CFrame = root.CFrame + (pos - root.Position)
    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
end

local function TPTo(target)
    local root = GetRoot()
    if not root then return end
    SetPos(root, target)
end

local LastArrive = 0
local GoHome = false
local Flying = false
local FlyBody = nil
local FlyGyro = nil
local NoClipActive = false
local NoClipConn = nil
local NoClipCharConn = nil
local NoClipDescConns = {}
local NoClipOrig = {}
local function NoClipSetupChar(char)
    if not char then return end
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            if not NoClipOrig[p] then
                NoClipOrig[p] = p.CanCollide
            end
            p.CanCollide = false
        end
    end
    local dc = char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then
            if not NoClipOrig[d] then
                NoClipOrig[d] = d.CanCollide
            end
            d.CanCollide = false
        end
    end)
    NoClipDescConns[char] = dc
end
local function SetNoclip(on)
    if on then
        if NoClipActive then return end
        NoClipActive = true
        local char = LP.Character
        if char then NoClipSetupChar(char) end
        if not NoClipConn then
            NoClipConn = RunService.Stepped:Connect(function()
                if not NoClipActive then return end
                local c = LP.Character
                if not c then return end
                for _, p in pairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end)
        end
        if NoClipCharConn then NoClipCharConn:Disconnect() end
        NoClipCharConn = LP.CharacterAdded:Connect(function(newChar)
            if NoClipActive then
                task.wait()
                NoClipSetupChar(newChar)
            end
        end)
    else
        NoClipActive = false
        if NoClipConn then
            NoClipConn:Disconnect()
            NoClipConn = nil
        end
        if NoClipCharConn then
            NoClipCharConn:Disconnect()
            NoClipCharConn = nil
        end
        for p, orig in pairs(NoClipOrig) do
            pcall(function()
                if p and p.Parent then
                    p.CanCollide = orig
                end
            end)
        end
        for char, conn in pairs(NoClipDescConns) do
            if conn then conn:Disconnect() end
        end
        NoClipDescConns = {}
        NoClipOrig = {}
    end
end
local function StopFly()
    Flying = false
    if FlyBody then
        pcall(function()
            FlyBody:Destroy()
        end)
        FlyBody = nil
    end
    if FlyGyro then
        pcall(function()
            FlyGyro:Destroy()
        end)
        FlyGyro = nil
    end
    SetNoclip(false)
end
local function FlyTo(target, speed, isEgg)
    if Flying then return end
    local root = GetRoot()
    if not root then return end
    Flying = true
    SetNoclip(true)
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e5, 9e5, 9e5)
    bv.Parent = root
    FlyBody = bv
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9e5, 9e5, 9e5)
    bg.D = 500
    bg.P = 20000
    bg.CFrame = root.CFrame
    bg.Parent = root
    FlyGyro = bg
    task.spawn(function()
        while Flying and root and root.Parent do
            if not (Toggles.AutoTP and Toggles.AutoTP.Value) then
                break
            end
            local diff = target - root.Position
            local dist = diff.Magnitude
            if dist < 5 then
                if isEgg then
                    LastArrive = os.clock()
                end
                GoHome = true
                break
            end
            bv.Velocity = diff.Unit * math.min(speed, dist * 3)
            if diff.Magnitude > 0.1 then
                bg.CFrame = CFrame.lookAt(root.Position, root.Position + diff.Unit)
            end
            task.wait()
        end
        bv.Velocity = Vector3.new(0, 0, 0)
        task.wait(0.1)
        StopFly()
    end)
end
local function FindPromptPart(v)
    local p = v.Parent
    if not p then return nil end
    if p:IsA("BasePart") then
        return p
    end
    if p:IsA("Attachment") and p.Parent and p.Parent:IsA("BasePart") then
        return p.Parent
    end
    local found = p:FindFirstChildWhichIsA("BasePart", true)
    if found then
        return found
    end
    local gp = p.Parent
    if gp then
        found = gp:FindFirstChildWhichIsA("BasePart", true)
        if found then
            return found
        end
    end
    return nil
end
local function GetCharPart()
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            return hrp
        end
        return char:FindFirstChild("Head")
    end
    return nil
end
local function GetEggOfPart(part)
    local eggSet = {}
    for _, e in ipairs(CollectEggs()) do
        eggSet[e.Obj] = e
    end
    local p = part
    while p do
        local e = eggSet[p]
        if e then
            return e
        end
        p = p.Parent
    end
    return nil
end
task.spawn(function()
    while true do
        task.wait(0.5)
        if Toggles.AutoPick.Value then
            local cp = GetCharPart()
            if cp then
                local cpos = cp.Position
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v.ClassName == "ProximityPrompt" and v.Parent then
                        local part = FindPromptPart(v)
                        if part and (part.Position - cpos).Magnitude <= 12 then
                            local e = GetEggOfPart(part)
                            if e then
                                pcall(function() fireproximityprompt(v, v.HoldDuration) end)
                            end
                        end
                    end
                end
            end
        end
    end
end)
local function GetCheckedSet()
    local out = {}
    local dd = Options.AutoEgg
    if not dd then return out end
    local v = dd.Value
    if type(v) == "table" then
        local vals = dd.Values or {}
        for k, val in pairs(v) do
            if type(k) == "number" then
                local name = vals[k]
                if name then
                    out[name] = true
                end
            elseif type(k) == "string" then
                out[k] = true
            end
        end
    elseif type(v) == "string" then
        out[v] = true
    end
    return out
end

local function GetNearestEgg()
    local root = GetRoot()
    if not root then return nil end
    local best, bestDist = nil, math.huge
    for _, e in ipairs(CollectEggs()) do
        local d = (e.Pos - root.Position).Magnitude
        if d < bestDist then
            bestDist = d
            best = e
        end
    end
    return best
end

local function GetNearestEggOfType(full)
    local root = GetRoot()
    if not root then return nil end
    local best, bestDist = nil, math.huge
    for _, e in ipairs(CollectEggs()) do
        local f = OfficialFull(e.Obj.Name)
        if f == full then
            local d = (e.Pos - root.Position).Magnitude
            if d < bestDist then
                bestDist = d
                best = e
            end
        end
    end
    return best
end

local EggValue = {
    whiteegg = 1, brownegg = 5, crackedegg = 30, easteregg = 50, stoneegg = 100,
    leafegg = 200, mushroomegg = 500, floweregg = 750, slimeegg = 1000, iceegg = 3000,
    glassegg = 10000, goldenegg = 30000, diamondegg = 90000, crystalegg = 150000, skulleg = 250000,
    asteroidegg = 500000, dominusegg = 700000, flamingegg = 1000000, sinisteregg = 3000000, soulegg = 7000000,
    tidalegg = 8000000, auroraegg = 300000000, galaxyegg = 1500000000, bloomegg = 2000000000, blackholeegg = 100000000000,
    solarisegg = 300000000000, cherubegg = 1000000000000, volcanicegg = 2500000000000,
}
local function GetEggValue(rawName)
    local k = NormalName(rawName)
    local v = EggValue[k]
    if v then return v end
    for alias, target in pairs(EggAliases) do
        local ak = NormalName(alias)
        if k == ak or k:sub(-#ak) == ak then
            return EggValue[NormalName(target)]
        end
    end
    local bestVal = 0
    for name, val in pairs(EggValue) do
        local core = name:gsub("egg$", "")
        if #core >= 3 and k:find(core, 1, true) and val > bestVal then
            bestVal = val
        end
    end
    return bestVal
end
local function GetHighestValueEgg()
    local root = GetRoot()
    if not root then return nil end
    local best, bestVal = nil, -1
    for _, e in ipairs(CollectEggs()) do
        local val = GetEggValue(e.Obj.Name)
        if val > bestVal then
            bestVal = val
            best = e
        end
    end
    return best
end
local PlotNames = {}
local PlotObjs = {}
local MyPlot = nil

local function GetPlotOwner(child)
    local data = child:FindFirstChild("Data")
    if data then
        local owner = data:FindFirstChild("Owner")
        if owner then
            if owner:IsA("ValueBase") then
                return tostring(owner.Value)
            end
            return owner.Name
        end
    end
    local ok, a = pcall(function()
        return child:GetAttribute("Owner")
    end)
    if ok and type(a) == "string" then return a end
    return nil
end

local function ScanPlots()
    local list = {}
    local objs = {}
    MyPlot = nil
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        local idx = 0
        for _, child in ipairs(plots:GetChildren()) do
            local part = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart")
            if part then
                idx = idx + 1
                local key = "家" .. idx
                local owner = GetPlotOwner(child)
                if owner and (owner == LP.Name or (owner:match("^%d+$") and owner == tostring(LP.UserId))) then
                    MyPlot = child
                end
                list[#list + 1] = key
                objs[key] = child
            end
        end
    end
    PlotNames = list
    PlotObjs = objs
    return list
end

local EggNames = {}
local EggObjs = {}
local EggTypeMap = {}

local function BuildEggList()
    local groups = {}
    local order = {}
    local eggs = CollectEggs()
    for _, e in ipairs(eggs) do
        local full = OfficialFull(e.Obj.Name)
        if full ~= "蛋" then
            local g = groups[full]
            if not g then
                g = { count = 0, obj = e.Obj }
                groups[full] = g
                order[#order + 1] = full
            end
            g.count = g.count + 1
            g.obj = e.Obj
        end
    end
    local list = {}
    local objs = {}
    local types = {}
    for _, full in ipairs(order) do
        local g = groups[full]
        local key = full .. "(" .. g.count .. ")"
        list[#list + 1] = key
        objs[key] = g.obj
        types[key] = full
    end
    EggNames = list
    EggObjs = objs
    EggTypeMap = types
    return list
end

local ESPTags = {}

local function SnapshotParts(root)
    local parts = {}
    local function walk(n)
        for _, c in ipairs(n:GetChildren()) do
            if c:IsA("BasePart") then
                parts[#parts + 1] = c
            elseif c:IsA("Model") or c:IsA("Folder") then
                walk(c)
            end
        end
    end
    walk(root)
    return parts
end

local function AddESP(obj)
    if ESPTags[obj] then return end
    local tag = {}
    local hl = Instance.new("Highlight")
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.fromRGB(255, 255, 0)
    hl.Adornee = obj
    hl.Parent = obj
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 160, 0, 30)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 500
    gui.Adornee = obj
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = DisplayName(obj) or ""
    label.TextColor3 = Color3.fromRGB(255, 255, 0)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 12
    label.Parent = gui
    gui.Parent = obj
    tag.Highlight = hl
    tag.Gui = gui
    tag.Snapshot = SnapshotParts(obj)
    local okE, ext = pcall(function()
        return obj:GetExtentsSize().Magnitude
    end)
    tag.Extents = okE and ext or 0
    ESPTags[obj] = tag
end

local function RemoveESP(obj)
    local tag = ESPTags[obj]
    if tag then
        pcall(function()
            tag.Highlight:Destroy()
        end)
        pcall(function()
            tag.Gui:Destroy()
        end)
        ESPTags[obj] = nil
    end
end

local function InEggFolders(obj)
    for _, folder in ipairs(EggFolders) do
        if obj:IsDescendantOf(folder) then
            return true
        end
    end
    return false
end

local function IsEggGone(obj, tag)
    if not obj.Parent then return true end
    if not InEggFolders(obj) then return true end
    if not IsAliveEgg(obj) then return true end
    if tag and tag.Snapshot and #tag.Snapshot > 0 then
        local cur = SnapshotParts(obj)
        if #cur < math.max(1, math.floor(#tag.Snapshot * 0.6)) then return true end
    end
    if tag and tag.Extents and tag.Extents > 0 then
        local okE, ext = pcall(function()
            return obj:GetExtentsSize().Magnitude
        end)
        if okE and ext < tag.Extents * 0.6 then return true end
    end
    return false
end

local function RefreshESP()
    for obj in pairs(ESPTags) do
        local tag = ESPTags[obj]
        if not tag or IsEggGone(obj, tag) then
            RemoveESP(obj)
        end
    end
end

local function WatchFolder(folder)
    folder.ChildAdded:Connect(function(child)
        if not (Toggles.ESP and Toggles.ESP.Value) then return end
        local part = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart")
        if part and IsAliveEgg(child) then
            AddESP(child)
        end
        if child:IsA("Model") or child:IsA("Folder") then
            WatchFolder(child)
        end
    end)
end

for _, folder in ipairs(EggFolders) do
    WatchFolder(folder)
end

RunService.Heartbeat:Connect(function()
    if Toggles.ESP and Toggles.ESP.Value then
        for _, e in ipairs(CollectEggs()) do
            AddESP(e.Obj)
        end
        RefreshESP()
    else
        for obj in pairs(ESPTags) do
            RemoveESP(obj)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if Toggles.ESP and Toggles.ESP.Value then
            RefreshESP()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(5)
        pcall(function()
            local lines = {}
            for _, e in ipairs(CollectEggs()) do
                lines[#lines + 1] = e.Obj.Name .. " -> " .. (OfficialFull(e.Obj.Name) or "?")
            end
            if #lines > 0 then
                if makefolder and not isfolder("骑宠物") then
                    makefolder("骑宠物")
                end
                writefile("骑宠物/场上蛋名.txt", table.concat(lines, "\n"))
            end
        end)
    end
end)

local function GetInterval()
    return 1
end

task.spawn(function()
    while true do
        task.wait(GetInterval())
        if Toggles.Luck and Toggles.Luck.Value and Upgrades then
            pcall(function()
                Upgrades:FireServer()
            end)
        end
    end
end)

task.spawn(function()
	while true do
		task.wait(GetInterval())
		if Toggles.Money and Toggles.Money.Value and PetCollect then
			local ids = CollectPetIds()
			for _, id in ipairs(ids) do
				pcall(function()
					PetCollect:FireServer(id)
				end)
			end
		end
	end
end)

task.spawn(function()
    while true do
        task.wait(GetInterval())
        if Toggles.Rebirth and Toggles.Rebirth.Value and Rebirth then
            pcall(function()
                Rebirth:FireServer()
            end)
        end
    end
end)

local AutoBox = Tabs.Main:AddLeftGroupbox("自动功能")
Toggles.Luck = AutoBox:AddToggle("Luck", { Text = "升级运气", Default = false })
Toggles.Money = AutoBox:AddToggle("Money", { Text = "自动领钱", Default = false })
Toggles.Rebirth = AutoBox:AddToggle("Rebirth", { Text = "自动重生", Default = false })
local function UniqueEggFulls()
    local seen = {}
    local list = {}
    for _, n in ipairs(AllEggNames) do
        local full = OfficialFull(n)
        if not seen[full] then
            seen[full] = true
            list[#list + 1] = full
        end
    end
    return list
end
local eggValues = UniqueEggFulls()
Toggles.AutoPick = AutoBox:AddToggle("AutoPick", { Text = "自动拾取", Default = false })
Toggles.AutoTP = AutoBox:AddToggle("AutoTP", { Text = "自动飞行蛋", Default = false })
Options.FlySpeed = AutoBox:AddSlider("FlySpeed", { Text = "飞行速度", Min = 1, Max = 1000, Default = 400, Rounding = 1 })
Options.DelayTime = AutoBox:AddSlider("DelayTime", { Text = "停留秒数", Min = 1, Max = 10, Default = 3, Rounding = 1 })
Options.AutoEgg = AutoBox:AddDropdown("AutoEgg", { Text = "选择飞行蛋", Values = #eggValues > 0 and eggValues or { "无蛋" }, Default = 1, Multi = true })
local EggBox = Tabs.Main:AddRightGroupbox("蛋操作")
Toggles.ESP = EggBox:AddToggle("ESP", { Text = "透视蛋", Default = false })
Toggles.AutoRefresh = EggBox:AddToggle("AutoRefresh", { Text = "自动刷新列表", Default = true })

local eggList = BuildEggList()
Options.EggSelect = EggBox:AddDropdown("EggSelect", { Text = "传送蛋（数字代表蛋的数量）", Values = #eggList > 0 and eggList or { "无蛋" }, Default = 1, Multi = false })
EggBox:AddButton({ Text = "传送当前选择蛋", Func = function()
    local key = Options.EggSelect.Value
    local e = nil
    if key and EggTypeMap[key] then
        e = GetNearestEggOfType(EggTypeMap[key])
    end
    if not e then
        e = GetNearestEgg()
    end
    if e then
        pcall(function()
            TPTo(e.Pos + Vector3.new(0, 1, 0))
        end)
    end
end })
EggBox:AddButton({ Text = "传送最高价值蛋", Func = function()
    local e = GetHighestValueEgg()
    if not e then return end
    TPTo(e.Pos + Vector3.new(0, 1, 0))
end })

local PlotBox = Tabs.Main:AddRightGroupbox("传送点")
local plots = ScanPlots()
Options.PlotSelect = PlotBox:AddDropdown("PlotSelect", { Text = "选择传送点", Values = #plots > 0 and plots or { "无传送点" }, Default = 1, Multi = false })
PlotBox:AddButton({ Text = "传送到自家", Func = function()
    if MyPlot then
        local part = MyPlot:IsA("BasePart") and MyPlot or MyPlot:FindFirstChildWhichIsA("BasePart")
        if part then
            pcall(function()
                TPTo(part.Position + Vector3.new(0, 1, 0))
            end)
        end
    end
end })
PlotBox:AddButton({ Text = "传送", Func = function()
    local name = Options.PlotSelect.Value
    local obj = PlotObjs[name]
    if obj then
        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
        if part then
            pcall(function()
                TPTo(part.Position + Vector3.new(0, 1, 0))
            end)
        end
    end
end })

local lastPlotList = nil
task.spawn(function()
    while true do
        task.wait(3)
        if Toggles.AutoRefresh and Toggles.AutoRefresh.Value then
            local newList = ScanPlots()
            if #newList > 0 then
                local cur = Options.PlotSelect.Value
                local changed = lastPlotList == nil or #newList ~= #lastPlotList
                if not changed then
                    for i = 1, #newList do
                        if newList[i] ~= lastPlotList[i] then
                            changed = true
                            break
                        end
                    end
                end
                if changed then
                    lastPlotList = newList
                    pcall(function()
                        Options.PlotSelect:SetValues(newList)
                    end)
                    local keep = false
                    for _, n in ipairs(newList) do
                        if n == cur then
                            keep = true
                            break
                        end
                    end
                    if keep then
                        pcall(function()
                            Options.PlotSelect:SetValue(cur)
                        end)
                    end
                end
            end
        end
    end
end)

local lastEggList = nil
task.spawn(function()
    while true do
        task.wait(3)
        if Toggles.AutoRefresh and Toggles.AutoRefresh.Value then
            local newList = BuildEggList()
            if #newList > 0 then
                local cur = Options.EggSelect.Value
                local changed = lastEggList == nil or #newList ~= #lastEggList
                if not changed then
                    for i = 1, #newList do
                        if newList[i] ~= lastEggList[i] then
                            changed = true
                            break
                        end
                    end
                end
                if changed then
                    lastEggList = newList
                    pcall(function()
                        Options.EggSelect:SetValues(newList)
                    end)
                    local keep = false
                    for _, n in ipairs(newList) do
                        if n == cur then
                            keep = true
                            break
                        end
                    end
                    if keep then
                        pcall(function()
                            Options.EggSelect:SetValue(cur)
                        end)
                    end
                end
            end
        end
    end
end)

if ThemeManager then
    ThemeManager:SetLibrary(Library)
end
if SaveManager then
    SaveManager:SetLibrary(Library)
end

local UIMenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("菜单")
UIMenuGroup:AddLabel("菜单按键"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "菜单按键"
})
Library.ToggleKeybind = Options.MenuKeybind
UIMenuGroup:AddButton({ Text = "卸载脚本", Func = function()
    Library:Unload()
end })

if SaveManager then
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    SaveManager:SetFolder("AutoLuckMoneyRebirth/Configs")
    SaveManager:BuildConfigSection(Tabs["UI Settings"])
end
if ThemeManager then
    ThemeManager:SetFolder("AutoLuckMoneyRebirth/Theme")
    pcall(function()
        ThemeManager:ApplyToTab(Tabs["UI Settings"])
        ThemeManager:ApplyTheme("Default")
    end)
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if Toggles.AutoTP and Toggles.AutoTP.Value then
            local set = GetCheckedSet()
            if next(set) then
                local root = GetRoot()
                if root and not Flying then
                    if GoHome then
                        if os.clock() - LastArrive >= Options.DelayTime.Value then
                            local homePart = nil
                            if MyPlot then
                                homePart = MyPlot:IsA("BasePart") and MyPlot or MyPlot:FindFirstChildWhichIsA("BasePart")
                            end
                            if homePart then
                                local hp = homePart.Position
                                if (root.Position - hp).Magnitude < 8 then
                                    GoHome = false
                                    LastArrive = 0
                                else
                                    FlyTo(hp + Vector3.new(0, 1, 0), Options.FlySpeed.Value)
                                end
                            else
                                GoHome = false
                                LastArrive = 0
                            end
                        end
                    elseif os.clock() - LastArrive >= Options.DelayTime.Value then
                        local best, bestDist = nil, math.huge
                        for _, e in ipairs(CollectEggs()) do
                            if set[OfficialFull(e.Obj.Name)] then
                                local d = (e.Pos - root.Position).Magnitude
                                if d < bestDist then
                                    bestDist = d
                                    best = e
                                end
                            end
                        end
                        if best and bestDist > 6 then
                            FlyTo(best.Pos + Vector3.new(0, 1, 0), Options.FlySpeed.Value, true)
                        end
                    end
                end
            end
        else
            if Flying then
                StopFly()
            end
            GoHome = false
        end
    end
end)
