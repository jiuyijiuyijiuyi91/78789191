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
    Notice = Window:AddTab("公告", "user"),
    Main = Window:AddTab("功能", "user"),
    Farm = Window:AddTab("自动农场", "user"),
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
local OfflineEarnings = GameR and GameR:FindFirstChild("OfflineEarnings")
local Autobuy = GameR and GameR:FindFirstChild("Autobuy")
local PlacePet = GameR and GameR:FindFirstChild("PlacePet")
local EggPlaced = GameR and GameR:FindFirstChild("EggPlaced")
local BasketDrop = GameR and GameR:FindFirstChild("BasketDrop")

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

local QualityList = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic",
    "Divine", "Celestial", "Cosmic", "Galactic", "Galaxy", "Universe",
    "Space", "Astral", "Royal", "King", "Queen", "Emperor", "Guardian",
    "Ancient", "Primal", "Cursed", "Corrupted", "Void", "Abyss", "Hell",
    "Flame", "Shadow", "Dark", "Light", "Golden", "Silver", "Blessed",
    "Godly", "Shiny", "Glowing", "Radiant", "Ethereal", "Enchanted",
    "Exotic", "Ultimate", "Super", "Giant", "Holy", "Volcanic",
}

local NumQuality = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Godly" }

local QualityColors = {
    Common = Color3.fromRGB(80, 255, 80),
    Uncommon = Color3.fromRGB(255, 255, 80),
    Rare = Color3.fromRGB(80, 160, 255),
    Epic = Color3.fromRGB(255, 120, 40),
    Legendary = Color3.fromRGB(255, 210, 40),
    Mythic = Color3.fromRGB(200, 80, 255),
    Divine = Color3.fromRGB(255, 80, 80),
    Celestial = Color3.fromRGB(120, 220, 255),
    Cosmic = Color3.fromRGB(255, 120, 220),
    Galactic = Color3.fromRGB(120, 120, 255),
    Galaxy = Color3.fromRGB(120, 120, 255),
    Universe = Color3.fromRGB(160, 80, 255),
    Space = Color3.fromRGB(60, 60, 120),
    Astral = Color3.fromRGB(140, 100, 255),
    Royal = Color3.fromRGB(255, 200, 120),
    King = Color3.fromRGB(255, 210, 80),
    Queen = Color3.fromRGB(255, 160, 200),
    Emperor = Color3.fromRGB(255, 120, 60),
    Guardian = Color3.fromRGB(120, 200, 120),
    Ancient = Color3.fromRGB(160, 120, 60),
    Primal = Color3.fromRGB(120, 200, 80),
    Cursed = Color3.fromRGB(120, 40, 40),
    Corrupted = Color3.fromRGB(200, 40, 120),
    Void = Color3.fromRGB(60, 40, 120),
    Abyss = Color3.fromRGB(30, 30, 60),
    Hell = Color3.fromRGB(255, 60, 0),
    Flame = Color3.fromRGB(255, 120, 0),
    Shadow = Color3.fromRGB(80, 80, 100),
    Dark = Color3.fromRGB(60, 60, 70),
    Light = Color3.fromRGB(255, 255, 255),
    Golden = Color3.fromRGB(255, 200, 40),
    Silver = Color3.fromRGB(200, 210, 220),
    Blessed = Color3.fromRGB(255, 240, 160),
    Godly = Color3.fromRGB(255, 60, 60),
    Shiny = Color3.fromRGB(120, 255, 220),
    Glowing = Color3.fromRGB(120, 255, 120),
    Radiant = Color3.fromRGB(255, 255, 120),
    Ethereal = Color3.fromRGB(200, 200, 255),
    Enchanted = Color3.fromRGB(160, 120, 255),
    Exotic = Color3.fromRGB(255, 80, 160),
    Ultimate = Color3.fromRGB(255, 170, 40),
    Super = Color3.fromRGB(255, 140, 60),
    Giant = Color3.fromRGB(140, 200, 80),
    Holy = Color3.fromRGB(255, 255, 220),
    Volcanic = Color3.fromRGB(255, 80, 30),
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
        if key2 == nk or key2:sub(-#nk) == nk then
            return TranslateName(n) or "蛋"
        end
    end
    for _, n in ipairs(AllEggNames) do
        local nk = NormalName(n)
        local core = nk:gsub("egg$", "")
        if #core >= 3 and key2:find(core, 1, true) then
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
local function QualityFromName(rawName)
    local num = tonumber(rawName)
    if num then
        return NumQuality[num]
    end
    local key = (rawName or ""):gsub("[^%a]", ""):lower()
    for _, q in ipairs(QualityList) do
        local qk = q:lower()
        if key == qk then
            return q
        end
    end
    for _, q in ipairs(QualityList) do
        local qk = q:lower()
        if key:find(qk, 1, true) and not key:find("un" .. qk, 1, true) then
            return q
        end
    end
    return nil
end
local EggQualityMap = {
    whiteegg = "Common", brownegg = "Common", crackedegg = "Common", easteregg = "Common",
    stoneegg = "Uncommon", leafegg = "Uncommon", mushroomegg = "Uncommon", floweregg = "Uncommon",
    slimeegg = "Rare", iceegg = "Rare", glassegg = "Rare",
    goldenegg = "Epic", diamondegg = "Epic", crystalegg = "Epic",
    skulleg = "Legendary", asteroidegg = "Legendary", dominusegg = "Legendary",
    flamingegg = "Mythic", sinisteregg = "Mythic", soulegg = "Mythic", tidalegg = "Mythic",
    auroraegg = "Divine", galaxyegg = "Divine", bloomegg = "Divine",
    blackholeegg = "Ethereal", solarisegg = "Ethereal", cherubegg = "Ethereal", volcanicegg = "Ethereal",
}
local function GetQualityOf(obj)
    local mapQ = EggQualityMap[NormalName(obj.Name)]
    if mapQ then return mapQ end
    for alias, target in pairs(EggAliases) do
        local ak = NormalName(alias)
        local k = NormalName(obj.Name)
        if k == ak or k:sub(-#ak) == ak then
            local t = EggQualityMap[NormalName(target)]
            if t then return t end
        end
    end
    local found = nil
    pcall(function()
        for _, c in ipairs(obj:GetChildren()) do
            if c:IsA("ValueBase") then
                local n = c.Name:lower()
                if n:find("rar") or n:find("qual") or n == "tier" or n == "grade" then
                    local v = c.Value
                    if v ~= nil then
                        found = QualityFromName(tostring(v))
                        if found then return end
                    end
                end
            end
        end
    end)
    if found then return found end
    pcall(function()
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("ValueBase") then
                local n = d.Name:lower()
                if n:find("rar") or n:find("qual") or n == "tier" or n == "grade" then
                    local v = d.Value
                    if v ~= nil then
                        found = QualityFromName(tostring(v))
                        if found then return end
                    end
                end
            end
        end
    end)
    if found then return found end
    pcall(function()
        local attrs = obj:GetAttributes()
        for k, v in pairs(attrs) do
            local n = k:lower()
            if n:find("rar") or n:find("qual") or n == "tier" or n == "grade" then
                local q = QualityFromName(tostring(v))
                if q then found = q end
            end
        end
    end)
    if found then return found end
    pcall(function()
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("TextLabel") then
                local t = d.Text
                if t and t ~= "" then
                    local q = QualityFromName(t)
                    if q then found = q return end
                end
            end
        end
    end)
    if found then return found end
    local node = obj.Parent
    for _ = 1, 3 do
        if not node then break end
        if node:IsA("Folder") then
            local q = QualityFromName(node.Name)
            if q then return q end
        end
        node = node.Parent
    end
    return QualityFromName(obj.Name)
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
local function IsAliveEggLight(obj)
    if not obj.Parent then return false end
    if obj:IsA("BasePart") and obj.Transparency >= 0.3 then return false end
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
    return not hasMark(obj)
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
                local alive = pos and IsAliveEgg(child)
                if alive then
                    list[#list + 1] = { Obj = child, Pos = pos }
                elseif child:IsA("Model") or child:IsA("Folder") then
                    walk(child)
                end
            elseif child:IsA("Model") or child:IsA("Folder") then
                walk(child)
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
    local start = root.Position
    local dist = (target - start).Magnitude
    if dist <= 1200 then
        SetPos(root, target)
        return
    end
    local steps = math.ceil(dist / 1200)
    for i = 1, steps do
        local t = start:Lerp(target, i / steps)
        SetPos(root, t + Vector3.new(0, 3, 0))
        task.wait(0.05)
    end
    local hold = target + Vector3.new(0, 3, 0)
    SetPos(root, hold)
    local t0 = os.clock()
    while os.clock() - t0 < 0.1 do
        SetPos(root, hold)
        task.wait(0.02)
    end
    SetPos(root, target)
end

local function EggTopPos(e)
    local h = 5
    pcall(function()
        local part = e.Obj
        if part:IsA("BasePart") then
            h = part.Size.Y / 2 + 3
        else
            local es = part:GetExtentsSize()
            h = es.Y / 2 + 3
        end
    end)
    return e.Pos + Vector3.new(0, h, 0)
end

local function DropAndGoHome(hp)
    if typeof(hp) == "Instance" then
        hp = hp.Position
    end
    local bp = nil
    if MyPlot then
        bp = MyPlot:FindFirstChild("Baseplate") or MyPlot:FindFirstChildWhichIsA("BasePart")
    end
    local root = GetRoot()
    if not root then return false end
    local hp = bp and bp.Position or hp
    if not hp then return false end
    local dir = root.Position - hp
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude < 0.1 then
        dir = Vector3.new(0, 0, -1)
    else
        dir = dir.Unit
    end
    local dp = hp + dir * 70
    pcall(function()
        TPTo(dp + Vector3.new(0, 1, 0))
    end)
    task.wait(0.3)
    if BasketDrop then
        pcall(function()
            BasketDrop:FireServer()
        end)
    end
    root = GetRoot()
    if root then
        pcall(function()
            root.CFrame = CFrame.lookAt(root.Position, root.Position - dir * 5)
        end)
    end
    task.wait(1)
    root = GetRoot()
    if root then
        pcall(function()
            root.CFrame = CFrame.lookAt(root.Position, hp + Vector3.new(0, root.Position.Y, 0))
        end)
    end
    local from = dp + Vector3.new(0, 1, 0)
    local to = hp + Vector3.new(0, 1, 0)
    local spd = 12
    local dist = (to - from).Magnitude
    local moved = 0
    local last = os.clock()
    while moved < 1 do
        local now = os.clock()
        local dt = now - last
        last = now
        moved = moved + spd * dt / dist
        if moved > 1 then moved = 1 end
        local r = GetRoot()
        if r then
            r.CFrame = CFrame.new(from:Lerp(to, moved))
        end
        task.wait()
    end
    if not bp then return true end
    root = GetRoot()
    if not root then return false end
    local lp = nil
    pcall(function()
        lp = bp.CFrame:PointToObjectSpace(root.Position)
    end)
    if not lp then return false end
    local half = bp.Size / 2
    return math.abs(lp.X) <= half.X and math.abs(lp.Z) <= half.Z
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
local function FlyTo(target, speed, isEgg, skipAutoTP, duration, force, sync)
    if Flying then
        if not force then return end
        StopFly()
    end
    local root = GetRoot()
    if not root then return end
    Flying = true
    SetNoclip(true)
    local startDist = (target - root.Position).Magnitude
    local rate = duration and (startDist / duration) or speed
    local function run()
        while Flying and root and root.Parent do
            if not skipAutoTP and not (Toggles.AutoTP and Toggles.AutoTP.Value) then
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
            local step = math.min(rate * 0.03, dist)
            local nxt = root.Position + diff.Unit * step
            SetPos(root, nxt)
            task.wait(0.03)
        end
        StopFly()
    end
    if sync then
        run()
    else
        task.spawn(run)
    end
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
        task.wait(0.1)
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
            local q = GetQualityOf(e.Obj)
            local qz = q and TranslateMap[q] or q
            local gkey = q and (full .. "(" .. qz .. ")") or full
            local g = groups[gkey]
            if not g then
                g = { count = 0, obj = e.Obj }
                groups[gkey] = g
                order[#order + 1] = gkey
            end
            g.count = g.count + 1
            g.obj = e.Obj
        end
    end
    local list = {}
    local objs = {}
    local types = {}
    for _, gkey in ipairs(order) do
        local g = groups[gkey]
        local key = gkey .. "(" .. g.count .. ")"
        list[#list + 1] = key
        objs[key] = g.obj
        types[key] = gkey:gsub("%(.*%)$", "")
    end
    EggNames = list
    EggObjs = objs
    EggTypeMap = types
    return list
end

local VolcanoNames = {}
local VolcanoObjs = {}
local VolcanoTypeMap = {}
local function BuildVolcanoList()
    local groups = {}
    local order = {}
    local eggs = CollectEggs()
    for _, e in ipairs(eggs) do
        if GetEggValue(e.Obj.Name) == 2500000000000 then
            local full = OfficialFull(e.Obj.Name)
            local q = GetQualityOf(e.Obj)
            local qz = q and TranslateMap[q] or q
            local gkey = q and (full .. "(" .. qz .. ")") or full
            local g = groups[gkey]
            if not g then
                g = { count = 0, obj = e.Obj }
                groups[gkey] = g
                order[#order + 1] = gkey
            end
            g.count = g.count + 1
            g.obj = e.Obj
        end
    end
    local list = {}
    local objs = {}
    local types = {}
    for _, gkey in ipairs(order) do
        local g = groups[gkey]
        local key = gkey .. "(" .. g.count .. ")"
        list[#list + 1] = key
        objs[key] = g.obj
        types[key] = gkey:gsub("%(.*%)$", "")
    end
    VolcanoNames = list
    VolcanoObjs = objs
    VolcanoTypeMap = types
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
    local anchor = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
    if not anchor then anchor = obj end
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 160, 0, 56)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 500
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.Adornee = anchor
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 34)
    label.BackgroundTransparency = 1
    label.Text = DisplayName(obj) or ""
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 12
    label.Parent = gui
    local q = GetQualityOf(obj)
    local qLabel = Instance.new("TextLabel")
    qLabel.Position = UDim2.new(0, 0, 0, 34)
    qLabel.Size = UDim2.new(1, 0, 0, 22)
    qLabel.BackgroundTransparency = 1
    qLabel.Text = (q and TranslateMap[q]) or q or ""
    qLabel.TextColor3 = q and QualityColors[q] or Color3.fromRGB(255, 255, 255)
    qLabel.TextStrokeTransparency = 0
    qLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    qLabel.Font = Enum.Font.SourceSansBold
    qLabel.TextSize = 10
    qLabel.Parent = gui
    gui.Parent = anchor
    tag.Quality = q
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
        elseif child:IsA("Model") or child:IsA("Folder") then
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
local VolcanoEntranceCoord = Vector3.new(-4950.240723, 41275.976562, -3673.967773)
local VolcanoReturnCoord = Vector3.new(-4929.169434, 41278.230469, -3686.674561)
local VolcanoEntryA = Vector3.new(-4928.673828, 41276.207031, -3696.049805)
local VolcanoMidB = Vector3.new(-4960.288574, 41278.105469, -3662.760010)
local VolcanoManualEggC = Vector3.new(-5325.944824, 40912.410156, -3574.948730)
local VolcanoEggCoord = Vector3.new(-5321.760742, 40912.421875, -3571.401855)
local VolcanoTopCoord = Vector3.new(-5114.554688, 41404.617188, -3472.936035)
local VolcanoOutPos = Vector3.new(-4931.401855, 41280.886719, -3688.148438)

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

task.spawn(function()
    while true do
        task.wait(GetInterval())
        if Toggles.Offline and Toggles.Offline.Value and OfflineEarnings then
            pcall(function()
                OfflineEarnings:FireServer()
            end)
        end
    end
end)

local RadarList = {
    { Key = "RadarAdv", Name = "Advanced Radar" },
    { Key = "RadarJewel", Name = "Jewel Radar" },
    { Key = "RadarRoyal", Name = "Royal Radar" },
    { Key = "RadarMagic", Name = "Magic Radar" },
    { Key = "RadarAngelic", Name = "Angelic Radar" },
    { Key = "RadarEternal", Name = "Eternal Radar" },
    { Key = "RadarNameTag", Name = "NameTag" },
}
local RadarSent = {}
task.spawn(function()
    while true do
        task.wait(0.2)
        for _, item in ipairs(RadarList) do
            local t = Toggles[item.Key]
            local want = t and t.Value or false
            if RadarSent[item.Key] ~= want then
                RadarSent[item.Key] = want
                if Autobuy then
                    pcall(function()
                        Autobuy:FireServer("Gears", item.Name, want)
                    end)
                end
            end
        end
    end
end)

local NoticeBox = Tabs.Notice:AddLeftGroupbox("公告")
local NoticeLabel = NoticeBox:AddLabel("10月4日: 垃圾游戏已绕过距离检测反作弊")
NoticeLabel.TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
local AutoBox = Tabs.Main:AddLeftGroupbox("自动化")
Toggles.Luck = AutoBox:AddToggle("Luck", { Text = "升级运气", Default = false })
Toggles.Money = AutoBox:AddToggle("Money", { Text = "自动领钱", Default = false })
Toggles.Rebirth = AutoBox:AddToggle("Rebirth", { Text = "自动重生", Default = false })
Toggles.Offline = AutoBox:AddToggle("Offline", { Text = "自动领离线收益", Default = false })
Toggles.Optimize = AutoBox:AddToggle("Optimize", { Text = "防卡顿优化", Default = false })
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
local HangBox = Tabs.Farm:AddLeftGroupbox("挂机")
Toggles.AutoPick = HangBox:AddToggle("AutoPick", { Text = "自动拾取", Default = false })
Toggles.AutoTP = HangBox:AddToggle("AutoTP", { Text = "自动飞行蛋(2选1,开自动拾取)", Default = false })
Toggles.AutoTP2 = HangBox:AddToggle("AutoTP2", { Text = "自动传送蛋(2选1,开自动拾取)", Default = false })
Options.FlySpeed = HangBox:AddSlider("FlySpeed", { Text = "飞行速度", Min = 1000, Max = 2000, Default = 1500, Rounding = 1 })
Options.DelayTime = HangBox:AddSlider("DelayTime", { Text = "停留秒数", Min = 0.05, Max = 10, Default = 3, Rounding = 2 })
Options.AutoEgg = HangBox:AddDropdown("AutoEgg", { Text = "选择蛋", Values = #eggValues > 0 and eggValues or { "无蛋" }, Default = 1, Multi = true })
local VolcanoActive = false
local LastVolcanoRun = 0

local VolcanoRunXD = nil
local function VolcanoFindEggXD()
    local re = workspace:FindFirstChild("RenderedEggs")
    if re then
        local egg = re:FindFirstChild("Volcanic Egg")
        if egg and egg:IsA("Model") then
            return egg
        end
        for _, c in ipairs(re:GetChildren()) do
            if c:IsA("Model") and (c.Name:lower():find("volcanic") or GetEggValue(c.Name) == 2500000000000) then
                return c
            end
        end
    end
    local root = GetRoot()
    local best, bestD = nil, math.huge
    for _, e in ipairs(CollectEggs()) do
        if GetEggValue(e.Obj.Name) == 2500000000000 then
            local d = root and (e.Pos - root.Position).Magnitude or 0
            if d < bestD then
                bestD = d
                best = e
            end
        end
    end
    return best and best.Obj or nil
end
local function VolcanoPartPos(v)
    if not v then return nil end
    if v:IsA("BasePart") then return v.Position end
    local p = v:FindFirstChildWhichIsA("BasePart")
    return p and p.Position or nil
end
local function VolcanoEggTopPos(egg)
    local ep = nil
    if egg:IsA("BasePart") then
        ep = egg.Position
    else
        local ok, p = pcall(function()
            return egg:GetPivot().Position
        end)
        if ok then ep = p end
    end
    if not ep then
        local part = egg:FindFirstChildWhichIsA("BasePart")
        if part then ep = part.Position end
    end
    return ep
end
local function VolcanoPickPrompt(egg)
    if not egg then return false end
    local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(function()
            fireproximityprompt(prompt, prompt.HoldDuration)
        end)
        return true
    end
    local root = GetRoot()
    if root then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.ClassName == "ProximityPrompt" and v.Parent then
                local part = FindPromptPart(v)
                if part and (part.Position - root.Position).Magnitude <= 15 then
                    pcall(function()
                        fireproximityprompt(v, v.HoldDuration)
                    end)
                end
            end
        end
    end
    return true
end
local function VolcanoReturnHome()
    if MyPlot then
        local bp = MyPlot:FindFirstChild("Baseplate") or MyPlot:FindFirstChildWhichIsA("BasePart")
        if bp and bp:IsA("BasePart") then
            local root = GetRoot()
            if root then
                local sp = root.Position
                local lp = bp.CFrame:PointToObjectSpace(sp)
                local half = bp.Size / 2
                local closest = Vector3.new(math.clamp(lp.X, -half.X, half.X), math.clamp(lp.Y, -half.Y, half.Y), math.clamp(lp.Z, -half.Z, half.Z))
                local target = bp.CFrame:PointToWorldSpace(closest) + Vector3.new(0, 1, 0)
                local dist = (target - sp).Magnitude
                local dir = Vector3.new(target.X - sp.X, 0, target.Z - sp.Z)
                if dir.Magnitude < 0.1 then dir = (target - sp).Unit end
                if dir.Magnitude > 0 then dir = dir.Unit end
                for i = 1, 10 do
                    local wp = sp + dir * (dist * (i / 11))
                    root = GetRoot()
                    if root then
                        root.CFrame = CFrame.new(wp + Vector3.new(0, 1, 0))
                    end
                    task.wait(1)
                end
                root = GetRoot()
                if root then
                    root.CFrame = CFrame.new(target)
                end
                return true
            end
        else
            local home = MyPlot:IsA("BasePart") and MyPlot or MyPlot:FindFirstChildWhichIsA("BasePart")
            if home then
                DropAndGoHome(home)
                return true
            end
        end
    end
    return false
end
local function VolcanoHold(pos, dur)
    local t0 = os.clock()
    while os.clock() - t0 < dur do
        local root = GetRoot()
        if root then
            root.CFrame = CFrame.new(pos)
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
        task.wait(0.05)
    end
end
local function VolcanoFlyTo(target, speed, keepNoclip)
    local root = GetRoot()
    if not root then return end
    SetNoclip(true)
    while true do
        root = GetRoot()
        if not root then break end
        local diff = target - root.Position
        local dist = diff.Magnitude
        if dist < 1 then break end
        local step = math.min(speed * 0.05, dist)
        SetPos(root, root.Position + diff.Unit * step)
        task.wait(0.05)
    end
    root = GetRoot()
    if root then SetPos(root, target) end
    if not keepNoclip then SetNoclip(false) end
end
VolcanoRunXD = function()
    local root = GetRoot()
    if not root then return false end
    local vol = workspace:FindFirstChild("Volcano")
    if not vol then return false end
    pcall(function()
        workspace:RequestStreamAroundAsync(vol:GetPivot().Position)
    end)
    root = GetRoot()
    if not root then return false end
    root.CFrame = CFrame.new(VolcanoOutPos + Vector3.new(0, 1, 0))
    VolcanoHold(VolcanoOutPos + Vector3.new(0, 1, 0), 2)
    VolcanoFlyTo(VolcanoEntranceCoord + Vector3.new(0, 1, 0), 200)
    VolcanoFlyTo(VolcanoMidB + Vector3.new(0, 1, 0), 200)
    root = GetRoot()
    if root then VolcanoHold(root.Position, 2) end
    local egg = VolcanoFindEggXD()
    local ep = egg and VolcanoEggTopPos(egg) or VolcanoEggCoord
    VolcanoFlyTo(ep + Vector3.new(0, 3, 0), 1000, true)
    root = GetRoot()
    if not root then return false end
    local t1 = os.clock()
    while not egg and os.clock() - t1 < 1 do
        task.wait(0.25)
        egg = VolcanoFindEggXD()
    end
    root = GetRoot()
    if root and egg then
        ep = VolcanoEggTopPos(egg)
        VolcanoFlyTo(ep + Vector3.new(0, 3, 0), 1000, true)
        VolcanoPickPrompt(egg)
        task.wait(0.2)
    end
    VolcanoFlyTo(VolcanoMidB + Vector3.new(0, 1, 0), 200, true)
    VolcanoFlyTo(VolcanoEntranceCoord + Vector3.new(0, 1, 0), 200, true)
    VolcanoFlyTo(VolcanoOutPos + Vector3.new(0, 1, 0), 200)
    if MyPlot then
        local home = MyPlot:IsA("BasePart") and MyPlot or MyPlot:FindFirstChildWhichIsA("BasePart")
        if home then
            DropAndGoHome(home)
        end
    end
    return true
end

local VolcanoBox = Tabs.Farm:AddRightGroupbox("火山顶变异蛋")
Options.DipEgg = VolcanoBox:AddDropdown("DipEgg", { Text = "选择蛋", Values = #eggValues > 0 and eggValues or { "无蛋" }, Default = 1, Multi = true })
Toggles.AutoDip = VolcanoBox:AddToggle("AutoDip", { Text = "自动火山顶变异蛋(开自动拾取)", Default = false })
VolcanoBox:AddButton({ Text = "手动拿火山蛋(开自动拾取)", Func = function()
    pcall(function()
        VolcanoRunXD()
    end)
end })
local function GetHomeEggs()
    local list = {}
    if not MyPlot then return list end
    local eggsFolder = nil
    local function findEggs(node, depth)
        if eggsFolder then return end
        for _, c in ipairs(node:GetChildren()) do
            if c.Name == "Eggs" then
                eggsFolder = c
                return
            end
            if (c:IsA("Model") or c:IsA("Folder")) and (not depth or depth > 0) then
                findEggs(c, depth and depth - 1 or nil)
            end
        end
    end
    findEggs(MyPlot, 3)
    if not eggsFolder then return list end
    local function walk(node)
        for _, child in ipairs(node:GetChildren()) do
            local pos = nil
            if child:IsA("BasePart") then
                pos = child.Position
            else
                local part = child:FindFirstChildWhichIsA("BasePart")
                if part then pos = part.Position end
            end
            local alive = pos and IsAliveEggLight(child)
            if alive then
                list[#list + 1] = { Obj = child, Pos = pos }
            elseif child:IsA("Model") or child:IsA("Folder") then
                walk(child)
            end
        end
    end
    walk(eggsFolder)
    return list
end
local function PartBelongsToEgg(part, egg)
    local p = part
    while p do
        if p == egg.Obj then return true end
        p = p.Parent
    end
    return false
end
local EggBox = Tabs.Main:AddRightGroupbox("蛋操作")
Toggles.ESP = EggBox:AddToggle("ESP", { Text = "透视蛋", Default = false })
Toggles.AutoRefresh = EggBox:AddToggle("AutoRefresh", { Text = "自动刷新列表", Default = true })

local eggList = BuildEggList()
local function LockToEgg(e, dur, untilGone)
    local pos = EggTopPos(e)
    task.spawn(function()
        local t0 = os.clock()
        local limit = dur or 0.5
        while os.clock() - t0 < limit do
            local root = GetRoot()
            if not root then break end
            SetPos(root, pos)
            if untilGone and e.Obj and not e.Obj.Parent then break end
            task.wait(0.02)
        end
    end)
end
local function LockToPos(pos, dur)
    task.spawn(function()
        local t0 = os.clock()
        local limit = dur or 0.5
        while os.clock() - t0 < limit do
            local root = GetRoot()
            if not root then break end
            SetPos(root, pos)
            task.wait(0.02)
        end
    end)
end
Options.EggSelect = EggBox:AddDropdown("EggSelect", { Text = "传送蛋（数字代表蛋的数量）", Values = #eggList > 0 and eggList or { "无蛋" }, Default = 1, Multi = false })
EggBox:AddButton({ Text = "传送最近蛋", Func = function()
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
            TPTo(EggTopPos(e))
        end)
        LockToEgg(e)
    end
end })
EggBox:AddButton({ Text = "传送最高价值蛋", Func = function()
    local e = GetHighestValueEgg()
    if not e then return end
    TPTo(EggTopPos(e))
    LockToEgg(e)
end })

local function MkVec(x, y, z)
    local ok, v = pcall(function()
        return vector.create(x, y, z)
    end)
    if ok and v then return v end
    return Vector3.new(x, y, z)
end
local function RandomPlotPos()
    local bp = nil
    if MyPlot then
        bp = MyPlot:FindFirstChild("Baseplate")
        if not bp then
            bp = MyPlot:FindFirstChildWhichIsA("BasePart")
        end
    end
    if not bp then
        local plots = workspace:FindFirstChild("Plots")
        if plots then
            for _, c in ipairs(plots:GetChildren()) do
                local owner = GetPlotOwner(c)
                if owner and (owner == LP.Name or (owner:match("^%d+$") and owner == tostring(LP.UserId))) then
                    bp = c:FindFirstChild("Baseplate") or c:FindFirstChildWhichIsA("BasePart")
                    if bp then break end
                end
            end
        end
    end
    if bp then
        local sz = bp.Size
        local p = bp.Position
        local hw = math.max(sz.X / 2 - 2, 1)
        local hd = math.max(sz.Z / 2 - 2, 1)
        local x = p.X + (math.random() * 2 - 1) * hw
        local z = p.Z + (math.random() * 2 - 1) * hd
        return MkVec(x, p.Y + 1.5, z)
    end
    return MkVec(73.46701049804688, 40312.4921875, 812.1331176757812)
end

local function GetEggPlaced()
    local ok, ep = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Game"):WaitForChild("EggPlaced", 5)
    end)
    if ok and ep then return ep end
    return nil
end

local function GetBackpackGui()
    local pg = LP:FindFirstChild("PlayerGui")
    return pg and pg:FindFirstChild("BackpackGui")
end
local function GetHotbarSlots()
    local out = {}
    local bg = GetBackpackGui()
    local hb = bg and bg:FindFirstChild("Backpack") and bg.Backpack:FindFirstChild("Hotbar")
    if not hb then return out end
    for i = 1, 10 do
        local s = hb:FindFirstChild(tostring(i))
        if s then out[#out + 1] = s end
    end
    return out
end
local function GetInvSlots()
    local out = {}
    local bg = GetBackpackGui()
    local inv = bg and bg:FindFirstChild("Backpack") and bg.Backpack:FindFirstChild("Inventory")
    local sf = inv and inv:FindFirstChild("ScrollingFrame")
    local grid = sf and sf:FindFirstChild("UIGridFrame")
    if grid then
        for _, c in ipairs(grid:GetChildren()) do
            if c:IsA("GuiObject") then
                out[#out + 1] = c
            end
        end
    end
    return out
end
local inputHookDone = false
local function ClickSlot(slot)
    if not slot then return false end
    local clicked = false
    local function TryClick(n)
        if not n:IsA("GuiButton") then return end
        pcall(function()
            n:Click()
        end)
        clicked = true
    end
    TryClick(slot)
    if not clicked then
        for _, d in ipairs(slot:GetDescendants()) do
            if d:IsA("GuiButton") then
                TryClick(d)
            end
        end
    end
    pcall(function()
        local ac = slot.AbsolutePosition
        local sz = slot.AbsoluteSize
        if ac and sz and sz.X > 0 and sz.Y > 0 then
            local cx = ac.X + sz.X / 2
            local cy = ac.Y + sz.Y / 2
            local moved = false
            if type(_G.mousemove) == "function" then
                pcall(function() _G.mousemove(cx, cy) end); moved = true
            elseif type(_G.mousemoveabs) == "function" then
                pcall(function() _G.mousemoveabs(cx, cy) end); moved = true
            elseif type(_G.setcursorpos) == "function" then
                pcall(function() _G.setcursorpos(cx, cy) end); moved = true
            elseif type(_G.setmouseposition) == "function" then
                pcall(function() _G.setmouseposition(cx, cy) end); moved = true
            elseif type(_G.mousemoverel) == "function" then
                pcall(function() _G.mousemoverel(cx, cy) end); moved = true
            end
            if moved then task.wait(0.06) end
            if type(_G.mouse1click) == "function" then
                pcall(function() _G.mouse1click() end)
                clicked = true
                task.wait(0.06)
                pcall(function() _G.mouse1click() end)
                clicked = true
            end
            if type(_G.fireinput) == "function" then
                pcall(function()
                    local obj = Instance.new("InputObject")
                    obj.UserInputType = Enum.UserInputType.MouseButton1
                    obj.InputState = Enum.InputState.Begin
                    obj.Position = Vector3.new(cx, cy, 0)
                    _G.fireinput(obj)
                    task.wait(0.06)
                    obj.InputState = Enum.InputState.End
                    _G.fireinput(obj)
                    clicked = true
                end)
            end
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendMouseMoveEvent(cx, cy, 0)
                task.wait(0.05)
                vim:SendMouseButtonEvent(cx, cy, 0, true, Enum.UserInputType.MouseButton1, false)
                task.wait(0.05)
                vim:SendMouseButtonEvent(cx, cy, 0, false, Enum.UserInputType.MouseButton1, false)
                clicked = true
            end)
            pcall(function()
                local vim = game:GetService("VirtualInputManager")
                vim:SendTouchEvent(1, Vector2.new(cx, cy), Enum.TouchState.Began, false)
                task.wait(0.06)
                vim:SendTouchEvent(1, Vector2.new(cx, cy), Enum.TouchState.Ended, false)
                clicked = true
            end)
        end
    end)
    return clicked
end
local function OpenBackpack()
    local bg = GetBackpackGui()
    if not bg then return end
    local bp = bg:FindFirstChild("Backpack")
    local hb = bp and bp:FindFirstChild("Hotbar")
    local btn = hb and hb:FindFirstChild("BackpackButton")
    if not (btn and btn:IsA("GuiButton")) then return end
    local function InvVisible()
        local inv = bp and bp:FindFirstChild("Inventory")
        local sf = inv and inv:FindFirstChild("ScrollingFrame")
        return sf and sf.Visible == true
    end
    if not InvVisible() then
        pcall(function()
            btn:Click()
        end)
        task.wait(0.4)
    end
    if not InvVisible() then
        pcall(function()
            btn:Click()
        end)
        task.wait(0.4)
    end
end
local UIS = game:GetService("UserInputService")
local probeCount = {}
local probeConn = nil
do
    local ok, uis = pcall(function() return game:GetService("UserInputService") end)
    if ok and uis then
        probeConn = uis.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            local t = "?"
            pcall(function() t = tostring(input.UserInputType) end)
            probeCount[t] = (probeCount[t] or 0) + 1
        end)
    end
end
local function ProbeSummary()
    local parts = {}
    for k, v in pairs(probeCount) do
        parts[#parts + 1] = k .. ":" .. v
    end
    table.sort(parts)
    return table.concat(parts, " ")
end
local function SlotState(slot)
    local ok, v = pcall(function() return slot.Selected end)
    if ok and type(v) == "boolean" then
        return v and "选中" or "未选"
    end
    local ok2, v2 = pcall(function() return slot.Visible end)
    if ok2 then return "vis=" .. tostring(v2) end
    return "?"
end
local function SlotCenter(slot)
    local ac = slot.AbsolutePosition
    local sz = slot.AbsoluteSize
    if not (ac and sz and sz.X > 0 and sz.Y > 0) then
        error("格子无有效尺寸")
    end
    return ac.X + sz.X / 2, ac.Y + sz.Y / 2
end
local function TrySlotClick(slot, label)
    local before = SlotState(slot)
    local function Run(name, fn)
        local ok, err = pcall(fn)
        task.wait(0.12)
    end
    Run("Click", function()
        if slot:IsA("GuiButton") then slot:Click() end
        for _, d in ipairs(slot:GetDescendants()) do
            if d:IsA("GuiButton") then d:Click() end
        end
    end)
    Run("mousemove+click", function()
        local cx, cy = SlotCenter(slot)
        local moved = false
        if type(_G.mousemove) == "function" then pcall(function() _G.mousemove(cx, cy) end); moved = true
        elseif type(_G.mousemoveabs) == "function" then pcall(function() _G.mousemoveabs(cx, cy) end); moved = true
        elseif type(_G.setcursorpos) == "function" then pcall(function() _G.setcursorpos(cx, cy) end); moved = true
        elseif type(_G.setmouseposition) == "function" then pcall(function() _G.setmouseposition(cx, cy) end); moved = true
        end
        if not moved then error("无鼠标移动API") end
        task.wait(0.08)
        if type(_G.mouse1click) == "function" then
            pcall(function() _G.mouse1click() end)
            task.wait(0.06)
            pcall(function() _G.mouse1click() end)
        end
    end)
    Run("fireinput", function()
        if type(_G.fireinput) ~= "function" then error("无fireinput") end
        local cx, cy = SlotCenter(slot)
        local obj = Instance.new("InputObject")
        obj.UserInputType = Enum.UserInputType.MouseButton1
        obj.InputState = Enum.InputState.Begin
        obj.Position = Vector3.new(cx, cy, 0)
        _G.fireinput(obj)
        task.wait(0.08)
        obj.InputState = Enum.InputState.End
        _G.fireinput(obj)
    end)
    Run("VIM鼠标", function()
        local vim = game:GetService("VirtualInputManager")
        local cx, cy = SlotCenter(slot)
        vim:SendMouseMoveEvent(cx, cy, 0)
        task.wait(0.06)
        vim:SendMouseButtonEvent(cx, cy, 0, true, Enum.UserInputType.MouseButton1, false)
        task.wait(0.06)
        vim:SendMouseButtonEvent(cx, cy, 0, false, Enum.UserInputType.MouseButton1, false)
    end)
    Run("VIM触摸", function()
        local vim = game:GetService("VirtualInputManager")
        local cx, cy = SlotCenter(slot)
        vim:SendTouchEvent(1, Vector2.new(cx, cy), Enum.TouchState.Began, false)
        task.wait(0.08)
        vim:SendTouchEvent(1, Vector2.new(cx, cy), Enum.TouchState.Ended, false)
    end)
    Run("firesignal", function()
        local fired = 0
        local function TryFire(name)
            local ok, sig = pcall(function() return slot[name] end)
            if ok and sig then
                local okc, conns = pcall(getconnections, sig)
                if okc and type(conns) == "table" and #conns > 0 then
                    for _, cn in ipairs(conns) do
                        pcall(function() cn:Fire() end)
                        fired = fired + 1
                    end
                end
            end
        end
        TryFire("MouseButton1Click")
        TryFire("MouseButton1Down")
        TryFire("Activated")
        if fired == 0 then error("无可用连接") end
    end)
end
local function DiagnoseClick()
    OpenBackpack()
    task.wait(0.5)
    local hs = GetHotbarSlots()
    local iv = GetInvSlots()
    if #hs > 0 then
        TrySlotClick(hs[1], "H1")
        return
    end
    if #iv > 0 then
        TrySlotClick(iv[1], "I1")
        return
    end
end

local dbgCount = 0
local function DBG(msg)
    dbgCount = dbgCount + 1
end
local capCount = 0
local grabSeen = nil
local GRAB_WHITE = { EggPlaced = true, PetCollect = true, Ping = true, PlayerActivity = true, Autobuy = true, Upgrades = true, Rebirth = true, OfflineEarnings = true, PlacePet = true, VolcanoDip = true, RequestPlotEggs = true, RadarState = true, GameLoaded = true }
if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
    local oldHook
    oldHook = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" or method == "InvokeServer" then
            local nm = "?"
            pcall(function() nm = self.Name end)
            local a1 = ...
            local t1 = type(a1)
            local s1 = tostring(a1)
            if GRAB_WHITE[nm] then
                return oldHook(self, ...)
            end
            capCount = capCount + 1
            local n = select("#", ...)
            if capCount <= 30 then
                local pr = "?"
                pcall(function() pr = self.Parent and self.Parent.Name end)
            end
            if t1 == "string" and s1:match("^%x%x%x%x%x%x%x%x%-") and not grabSeen then
                grabSeen = { obj = self, name = nm, args = { ... } }
            end
        end
        return oldHook(self, ...)
    end))
end
local function SlotInfo(slot)
    local text, sel = "?", "?"
    pcall(function() text = slot.Text end)
    pcall(function() sel = slot.Selected end)
    return tostring(text), tostring(sel)
end
local function DumpSlotData(slot, tag)
    local info = { tag, slot.ClassName, slot.Name }
    pcall(function() info[#info + 1] = "Text=" .. tostring(slot.Text) end)
    pcall(function() info[#info + 1] = "Image=" .. tostring(slot.Image) end)
    pcall(function() info[#info + 1] = "LayoutOrder=" .. tostring(slot.LayoutOrder) end)
    pcall(function() info[#info + 1] = "Visible=" .. tostring(slot.Visible) end)
    pcall(function()
        for k, v in pairs(slot:GetAttributes()) do
            info[#info + 1] = "attr:" .. tostring(k) .. "=" .. tostring(v)
        end
    end)
    for _, c in ipairs(slot:GetChildren()) do
        local ci = { "child:" .. c.ClassName .. ":" .. c.Name }
        pcall(function()
            if c:IsA("TextLabel") or c:IsA("TextButton") then
                ci[#ci + 1] = "Text=" .. tostring(c.Text)
            end
        end)
        pcall(function()
            if c:IsA("ImageLabel") or c:IsA("ImageButton") then
                ci[#ci + 1] = "Image=" .. tostring(c.Image)
            end
        end)
        pcall(function()
            if c:IsA("ValueBase") then
                ci[#ci + 1] = "Val=" .. tostring(c.Value)
            end
        end)
        pcall(function()
            for k, v in pairs(c:GetAttributes()) do
                ci[#ci + 1] = "attr:" .. tostring(k) .. "=" .. tostring(v)
            end
        end)
        if c:IsA("Frame") or c:IsA("ScrollingFrame") or c:IsA("ViewportFrame") then
            for _, g in ipairs(c:GetChildren()) do
                ci[#ci + 1] = "g:" .. g.ClassName .. ":" .. g.Name
                pcall(function()
                    if g:IsA("TextLabel") then ci[#ci + 1] = "t=" .. tostring(g.Text) end
                end)
                pcall(function()
                    if g:IsA("ImageLabel") then ci[#ci + 1] = "img=" .. tostring(g.Image) end
                end)
                pcall(function()
                    if g:IsA("ValueBase") then ci[#ci + 1] = "val=" .. tostring(g.Value) end
                end)
            end
        end
        info[#info + 1] = table.concat(ci, " ")
    end
end
local function PlantFromSlots()
    local ep = GetEggPlaced()
    if not ep then DBG("远程EggPlaced未找到"); return false end
    if not grabSeen then
        DBG("未学到拿取远程：请在背包里手动点一次蛋格子，等[★抓取]行出现后再开自动放蛋")
        return false
    end
    OpenBackpack()
    local hs = GetHotbarSlots()
    local iv = GetInvSlots()
    local function ScanSlot(slot, tag)
        local uuids = {}
        local seen = {}
        local lines = {}
        local function push(v)
            if type(v) == "string" and v:match("^%x%x%x%x%x%x%x%x%-") and not seen[v] then
                seen[v] = true
                uuids[#uuids + 1] = v
            end
        end
        local function walk(n, depth, prefix)
            if depth > 5 then return end
            local ln = prefix .. n.ClassName .. ":" .. n.Name
            pcall(function()
                if n:IsA("TextLabel") or n:IsA("TextButton") then ln = ln .. " T=" .. tostring(n.Text) end
            end)
            pcall(function()
                if n:IsA("ImageLabel") or n:IsA("ImageButton") then ln = ln .. " IMG=" .. tostring(n.Image) end
            end)
            pcall(function()
                if n:IsA("ValueBase") then ln = ln .. " V=" .. tostring(n.Value) end
            end)
            pcall(function()
                local attrs = n:GetAttributes()
                for k, v in pairs(attrs) do
                    ln = ln .. " A:" .. tostring(k) .. "=" .. tostring(v)
                    push(tostring(v))
                end
            end)
            push(n.Name)
            push(n.Image)
            lines[#lines + 1] = ln
            for _, c in ipairs(n:GetChildren()) do
                walk(c, depth + 1, prefix .. "  ")
            end
        end
        walk(slot, 0, "")
        pcall(function()
            for _, d in ipairs(slot:GetDescendants()) do
                if d:IsA("Model") then
                    push(d.Name)
                    lines[#lines + 1] = "MODEL:" .. d.Name
                end
            end
        end)
        return uuids, lines
    end
    local function FireGrab(uuid)
        local args = {}
        local n = select("#", unpack(grabSeen.args))
        for i = 1, n do
            args[i] = select(i, unpack(grabSeen.args))
        end
        if n >= 1 then args[1] = uuid end
        local ok = pcall(function()
            grabSeen.obj:FireServer(unpack(args))
        end)
        DBG("直发拿取 " .. grabSeen.name .. " uuid=" .. uuid .. " ok=" .. tostring(ok))
        return ok
    end
    local dumpCount = 0
    local function TryPlant(slot, tag)
        local uuids, lines = ScanSlot(slot, tag)
        if #uuids == 0 then
            DBG(tag .. " 无UUID 跳过")
            if dumpCount < 2 then
                dumpCount = dumpCount + 1
                pcall(function()
                    if makefolder and not isfolder("骑宠物") then makefolder("骑宠物") end
                    writefile("骑宠物/格子数据.txt", tag .. "\n" .. table.concat(lines, "\n"))
                end)
            end
            return false
        end
        local planted = false
        for _, uuid in ipairs(uuids) do
            if not FireGrab(uuid) then break end
            task.wait(0.35)
            local pos = RandomPlotPos()
            local args = {
                [1] = {
                    ["PlantPosition"] = pos
                }
            }
            local okEp = pcall(function()
                ep:FireServer(unpack(args))
            end)
            DBG(tag .. " 放置 uuid=" .. uuid .. " epOk=" .. tostring(okEp))
            planted = true
            task.wait(0.3)
        end
        return planted
    end
    local done = 0
    for i, slot in ipairs(hs) do
        if TryPlant(slot, "H" .. tostring(i)) then done = done + 1 end
        task.wait(0.15)
    end
    for i = 1, math.min(#iv, 30) do
        if TryPlant(iv[i], "I" .. tostring(i)) then done = done + 1 end
        task.wait(0.15)
    end
    DBG("本轮拿取放置完成 done=" .. done)
    return done > 0
end

local function QuietClick(slot)
    local fired = 0
    local function TryFire(name)
        local ok, sig = pcall(function() return slot[name] end)
        if ok and sig then
            local okc, conns = pcall(getconnections, sig)
            if okc and type(conns) == "table" and #conns > 0 then
                for _, cn in ipairs(conns) do
                    pcall(function() cn:Fire() end)
                    fired = fired + 1
                end
            end
        end
    end
    TryFire("MouseButton1Click")
    TryFire("MouseButton1Down")
    TryFire("Activated")
    if fired > 0 then return true end
    pcall(function()
        if slot:IsA("GuiButton") then slot:Click() end
        for _, d in ipairs(slot:GetDescendants()) do
            if d:IsA("GuiButton") then d:Click() end
        end
    end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        local cx, cy = SlotCenter(slot)
        vim:SendMouseMoveEvent(cx, cy, 0)
        task.wait(0.05)
        vim:SendMouseButtonEvent(cx, cy, 0, true, Enum.UserInputType.MouseButton1, false)
        task.wait(0.05)
        vim:SendMouseButtonEvent(cx, cy, 0, false, Enum.UserInputType.MouseButton1, false)
    end)
    return fired > 0
end
local function SlotIsEgg(slot)
    local buf = ""
    pcall(function()
        local function add(t)
            if t and t ~= "" and t ~= " " and t ~= "?" then
                buf = buf .. " " .. tostring(t)
            end
        end
        add(slot.Text)
        add(slot.Name)
        for _, d in ipairs(slot:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                add(d.Text)
            elseif (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.Name then
                add(d.Name)
            end
        end
    end)
    if buf == "" then return false end
    if buf:find("蛋", 1, true) then return true end
    local nk = NormalName(buf)
    for _, n in ipairs(AllEggNames) do
        local an = NormalName(n)
        if nk == an or nk:find(an, 1, true) or an:find(nk, 1, true) then
            return true
        end
    end
    return false
end
local function PointLoopOnce()
    OpenBackpack()
    task.wait(0.4)
    local ep = GetEggPlaced()
    local hs = GetHotbarSlots()
    local iv = GetInvSlots()
    local function SpamPlant()
        if not ep then return end
        local pos = RandomPlotPos()
        local args = { [1] = { ["PlantPosition"] = pos } }
        pcall(function()
            ep:FireServer(unpack(args))
        end)
    end
    for i, slot in ipairs(hs) do
        if not (Toggles.PointClick and Toggles.PointClick.Value) then break end
        QuietClick(slot)
        for _ = 1, 8 do SpamPlant() end
        task.wait(0.15)
    end
    for i, slot in ipairs(iv) do
        if not (Toggles.PointClick and Toggles.PointClick.Value) then break end
        QuietClick(slot)
        for _ = 1, 8 do SpamPlant() end
        task.wait(0.15)
    end
end
task.spawn(function()
    while true do
        task.wait(0.15)
        if Toggles.PointClick and Toggles.PointClick.Value then
            PointLoopOnce()
            local ep = GetEggPlaced()
            if ep then
                local pos = RandomPlotPos()
                local args = { [1] = { ["PlantPosition"] = pos } }
                pcall(function()
                    ep:FireServer(unpack(args))
                end)
            end
        end
    end
end)

Toggles.PointClick = EggBox:AddToggle("PointClick", { Text = "自动放蛋(首先你的物品栏和背包得要有蛋)", Default = false })

local RadarBox = Tabs.Main:AddRightGroupbox("自动购买雷达")
Toggles.RadarAdv = RadarBox:AddToggle("RadarAdv", { Text = "高级雷达", Default = false })
Toggles.RadarJewel = RadarBox:AddToggle("RadarJewel", { Text = "宝石雷达", Default = false })
Toggles.RadarRoyal = RadarBox:AddToggle("RadarRoyal", { Text = "皇家雷达", Default = false })
Toggles.RadarMagic = RadarBox:AddToggle("RadarMagic", { Text = "魔法雷达", Default = false })
Toggles.RadarAngelic = RadarBox:AddToggle("RadarAngelic", { Text = "天使雷达", Default = false })
Toggles.RadarEternal = RadarBox:AddToggle("RadarEternal", { Text = "永恒雷达", Default = false })
Toggles.RadarNameTag = RadarBox:AddToggle("RadarNameTag", { Text = "名牌雷达", Default = false })

local PlotBox = Tabs.Main:AddLeftGroupbox("传送点")
local plots = ScanPlots()
Options.PlotSelect = PlotBox:AddDropdown("PlotSelect", { Text = "选择传送点", Values = #plots > 0 and plots or { "无传送点" }, Default = 1, Multi = false })
PlotBox:AddButton({ Text = "传送到我的家", Func = function()
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
PlotBox:AddButton({ Text = "传送到火山口", Func = function()
    pcall(function()
        TPTo(VolcanoEntranceCoord + Vector3.new(0, 1, 0))
    end)
end })
PlotBox:AddButton({ Text = "传送到火山顶", Func = function()
    pcall(function()
        TPTo(VolcanoTopCoord + Vector3.new(0, 1, 0))
    end)
end })

local PetBox = Tabs.Main:AddLeftGroupbox("宠物放置最佳位置")
local defaultPetId = "1f7170d5-fff0-4173-95c1-34a9dd50d827"
Toggles.PlaceBestPet = PetBox:AddToggle("PlaceBestPet", { Text = "自动放置最佳位置", Default = false })
task.spawn(function()
    while true do
        task.wait(1)
        if Toggles.PlaceBestPet and Toggles.PlaceBestPet.Value then
            if PlacePet then
                pcall(function()
                    PlacePet:FireServer(defaultPetId, Vector3.new(57.463157653808594, 40316.42578125, 1016.2613525390625))
                end)
            end
        end
    end
end)

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

local LastTP2 = 0
task.spawn(function()
    while true do
        task.wait(0.5)
        if Toggles.AutoTP2 and Toggles.AutoTP2.Value and not VolcanoActive then
            local set = GetCheckedSet()
            if next(set) then
                local root = GetRoot()
                if root then
                    if GoHome then
                        if os.clock() - LastTP2 >= Options.DelayTime.Value then
                            local homePart = nil
                            if MyPlot then
                                homePart = MyPlot:IsA("BasePart") and MyPlot or MyPlot:FindFirstChildWhichIsA("BasePart")
                            end
                            if homePart then
                                local hp = homePart.Position
                                if (root.Position - hp).Magnitude < 8 then
                                    GoHome = false
                                    LastTP2 = 0
                                else
                                    if DropAndGoHome(hp) then
                                        GoHome = false
                                        LastTP2 = 0
                                    end
                                end
                            else
                                GoHome = false
                                LastTP2 = 0
                            end
                        end
                    elseif os.clock() - LastTP2 >= Options.DelayTime.Value then
                        local best, bestDist = nil, math.huge
                        for _, e in ipairs(CollectEggs()) do
                            local isVolcano = GetEggValue(e.Obj.Name) == 2500000000000
                            if isVolcano or set[OfficialFull(e.Obj.Name)] then
                                local d = (e.Pos - root.Position).Magnitude
                                if isVolcano then d = d - 1e9 end
                                if d < bestDist then
                                    bestDist = d
                                    best = e
                                end
                            end
                        end
                        if best then
                            if GetEggValue(best.Obj.Name) == 2500000000000 then
                                if os.clock() - LastVolcanoRun >= 3 then
                                    LastVolcanoRun = os.clock()
                                    VolcanoActive = true
                                    pcall(function()
                                        VolcanoRunXD()
                                    end)
                                    VolcanoActive = false
                                end
                            else
                                LastTP2 = os.clock()
                                pcall(function()
                                    TPTo(EggTopPos(best))
                                end)
                                LockToEgg(best, Options.DelayTime.Value, true)
                                GoHome = true
                            end
                        end
                    end
                end
            end
        else
            if not (Toggles.AutoTP and Toggles.AutoTP.Value) then
                GoHome = false
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if Toggles.AutoTP and Toggles.AutoTP.Value and not (Toggles.AutoTP2 and Toggles.AutoTP2.Value) then
            local set = GetCheckedSet()
            if next(set) then
                local root = GetRoot()
                if root and not Flying and not VolcanoActive then
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
                                    DropAndGoHome(hp)
                                end
                            else
                                GoHome = false
                                LastArrive = 0
                            end
                        end
                    elseif os.clock() - LastArrive >= Options.DelayTime.Value then
                        if not VolcanoActive then
                            local best, bestDist = nil, math.huge
                            for _, e in ipairs(CollectEggs()) do
                                local isVolcano = GetEggValue(e.Obj.Name) == 2500000000000
                                if isVolcano or set[OfficialFull(e.Obj.Name)] then
                                    local d = (e.Pos - root.Position).Magnitude
                                    if isVolcano then d = d - 1e9 end
                                    if d < bestDist then
                                        bestDist = d
                                        best = e
                                    end
                                end
                            end
                            if best then
                                if GetEggValue(best.Obj.Name) == 2500000000000 then
                                    if os.clock() - LastVolcanoRun >= 3 then
                                        LastVolcanoRun = os.clock()
                                        VolcanoActive = true
                                        pcall(function()
                                            VolcanoRunXD()
                                        end)
                                        VolcanoActive = false
                                    end
                                elseif bestDist > 6 then
                                    FlyTo(EggTopPos(best), Options.FlySpeed.Value, true)
                                end
                            end
                        end
                    end
                end
            end
        else
            if Flying and not VolcanoActive then
                StopFly()
            end
            if not (Toggles.AutoTP2 and Toggles.AutoTP2.Value) then
                GoHome = false
            end
        end
    end
end)

local VolcanoDipCoord = Vector3.new(-5102.842773, 41405.410156, -3489.114014)
local function GetCheckedSetOf(dd)
    local out = {}
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
local LastDipRun = 0
task.spawn(function()
    while true do
        task.wait(0.5)
        if Toggles.AutoDip and Toggles.AutoDip.Value then
            if os.clock() - LastDipRun >= 3 then
                local root = GetRoot()
                local egg = nil
                if root then
                    local dipSet = GetCheckedSetOf(Options.DipEgg)
                    local set = GetCheckedSet()
                    local bestDist = math.huge
                    if next(dipSet) then
                        for _, e in ipairs(CollectEggs()) do
                            if dipSet[OfficialFull(e.Obj.Name)] then
                                local d = (e.Pos - root.Position).Magnitude
                                if d < bestDist then
                                    bestDist = d
                                    egg = e
                                end
                            end
                        end
                    elseif next(set) then
                        for _, e in ipairs(CollectEggs()) do
                            if set[OfficialFull(e.Obj.Name)] then
                                local d = (e.Pos - root.Position).Magnitude
                                if d < bestDist then
                                    bestDist = d
                                    egg = e
                                end
                            end
                        end
                    else
                        egg = GetNearestEgg()
                    end
                end
                if egg then
                    LastDipRun = os.clock()
                    pcall(function()
                        TPTo(EggTopPos(egg))
                    end)
                    task.wait(1)
                    pcall(function()
                        TPTo(VolcanoDipCoord)
                    end)
                    task.spawn(function()
                        local t0 = os.clock()
                        local hold = VolcanoDipCoord + Vector3.new(0, 10, 0)
                        while os.clock() - t0 < 10 do
                            local r = GetRoot()
                            if r then
                                SetPos(r, hold)
                            end
                            pcall(function()
                                game:GetService("ReplicatedStorage"):WaitForChild("packages"):WaitForChild("Net"):WaitForChild("RE/VolcanoDip"):FireServer()
                            end)
                            task.wait(0.2)
                        end
                    end)
                    task.wait(10)
                    if MyPlot then
                        local home = MyPlot:IsA("BasePart") and MyPlot or MyPlot:FindFirstChildWhichIsA("BasePart")
                        if home then
                            DropAndGoHome(home)
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    local Lighting = game:GetService("Lighting")
    local Players = game:GetService("Players")
    local UserGS = nil
    pcall(function()
        UserGS = game:GetService("UserGameSettings")
    end)
    local FXKinds = { "ParticleEmitter", "Beam", "Fire", "Smoke", "Sparkles", "Trail", "Explosion", "Sound" }
    local function KillFX(node)
        for _, v in ipairs(node:GetDescendants()) do
            for _, k in ipairs(FXKinds) do
                if v:IsA(k) then
                    pcall(function() v:Destroy() end)
                    break
                end
            end
        end
    end
    local function HidePlayers()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                pcall(function()
                    p.Character:Destroy()
                end)
            end
        end
    end
    local function HideDistant(node, dist)
        for _, v in ipairs(node:GetDescendants()) do
            if v:IsA("BasePart") then
                local rp = GetRoot()
                if rp and (v.Position - rp.Position).Magnitude > dist then
                    pcall(function() v.LocalTransparencyModifier = 1 end)
                end
            end
        end
    end
    while true do
        task.wait(2)
        if Toggles.Optimize and Toggles.Optimize.Value then
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 1e9
                Lighting.Brightness = 1
                Lighting.Ambient = Color3.fromRGB(200, 200, 200)
                Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
                Lighting.ColorShift_Top = Color3.fromRGB(170, 170, 170)
                Lighting.ColorShift_Bottom = Color3.fromRGB(170, 170, 170)
            end)
            pcall(function()
                KillFX(workspace)
            end)
            pcall(function()
                HidePlayers()
            end)
            pcall(function()
                HideDistant(workspace, 600)
            end)
            pcall(function()
                UserGS:SetQualityLevel(1)
            end)
            pcall(function()
                local m = workspace:FindFirstChild("Map")
                if m then m:Destroy() end
            end)
            pcall(function()
                local plots = workspace:FindFirstChild("Plots")
                if plots then
                    for _, ch in ipairs(plots:GetChildren()) do
                        if ch ~= MyPlot then
                            ch:Destroy()
                        end
                    end
                end
            end)
            pcall(function()
                local plots = workspace:FindFirstChild("Plots")
                if plots then
                    for _, ch in ipairs(plots:GetChildren()) do
                        local pets = ch:FindFirstChild("Pets")
                        if pets then
                            for _, pet in ipairs(pets:GetChildren()) do
                                for _, d in ipairs(pet:GetDescendants()) do
                                    if d:IsA("BasePart") then
                                        d.Color = Color3.fromRGB(230, 230, 230)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(5)
        local lines = {}
        lines[#lines+1] = "folders=" .. #EggFolders
        for _, f in ipairs(EggFolders) do
            lines[#lines+1] = "F:" .. f.Name
        end
        local eggs = CollectEggs()
        lines[#lines+1] = "eggs=" .. #eggs
        for _, e in ipairs(eggs) do
            local o = e.Obj
            lines[#lines+1] = "E:" .. o.Name .. "|Q=" .. (GetQualityOf(o) or "nil")
            pcall(function()
                for _, c in ipairs(o:GetChildren()) do
                    if c:IsA("ValueBase") then
                        lines[#lines+1] = "  V:" .. c.Name .. "=" .. tostring(c.Value)
                    end
                end
                for k, v in pairs(o:GetAttributes()) do
                    lines[#lines+1] = "  A:" .. k .. "=" .. tostring(v)
                end
                for _, d in ipairs(o:GetDescendants()) do
                    if d:IsA("ValueBase") then
                        lines[#lines+1] = "  DV:" .. d.Name .. "=" .. tostring(d.Value)
                    elseif d:IsA("TextLabel") and d.Text and d.Text ~= "" then
                        lines[#lines+1] = "  T:" .. d.Text
                    end
                end
                local node = o.Parent
                for _ = 1, 3 do
                    if not node then break end
                    if node:IsA("Folder") then
                        lines[#lines+1] = "  FOLDER:" .. node.Name
                    end
                    node = node.Parent
                end
            end)
        end
        local n = 0
        for _ in pairs(ESPTags) do n = n + 1 end
        lines[#lines+1] = "esp=" .. n
        local content = table.concat(lines, "\n")
        pcall(function()
            if makefolder and not isfolder("骑宠物") then makefolder("骑宠物") end
            writefile("骑宠物/esp诊断.txt", content)
        end)
    end
end)
