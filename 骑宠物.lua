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
    Notice = Window:AddTab("公告", "megaphone"),
    Main = Window:AddTab("功能", "gamepad-2"),
    Farm = Window:AddTab("自动农场", "wheat"),
    Event = Window:AddTab("活动", "party-popper"),
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
local function IsQualityWordOnly(txt)
    local probe = txt
    for _, q in ipairs(QualityWords) do
        probe = probe:gsub(q, "")
    end
    probe = probe:gsub("%s", ""):gsub("[%p]", "")
    return probe == ""
end

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

    local t = TranslateName(rawName)
    if t and not IsQualityWordOnly(t) then
        return t
    end
    return "蛋"
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
    local named = OfficialFull(obj.Name) ~= "蛋"
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
    if not named then
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

local WalkFly = nil

local function EggLockSeconds(val)
    if typeof(val) ~= "number" or val <= 1 then return 1 end
    local s = 1 + 9 * (math.log10(val) / 12.4)
    if s < 1 then s = 1 end
    if s > 10 then s = 10 end
    return s
end

local function DropAndGoHome(hp, lockVal)
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
    local dropTop = dp + Vector3.new(0, 2, 0)
    WalkFly(dropTop, Options.FlySpeed.Value)
    local lockSec = 0.2
    if typeof(lockVal) == "number" and lockVal > 0 then
        lockSec = EggLockSeconds(lockVal)
    end
    local lockT0 = os.clock()
    repeat
        local rr = GetRoot()
        if rr then
            SetPos(rr, dropTop)
        end
        task.wait()
    until os.clock() - lockT0 >= lockSec
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
    local from = dropTop
    local to = hp + Vector3.new(0, 2, 0)
    local total = (to - from).Magnitude
    if total > 0.1 then
        local t0 = os.clock()
        local k = 0
        while k < 1 do
            k = math.min(1, (os.clock() - t0) * 200 / total)
            local r = GetRoot()
            if r then
                r.CFrame = CFrame.new(from:Lerp(to, k))
            end
            task.wait()
        end
    end
    local rEnd = GetRoot()
    if rEnd then
        rEnd.CFrame = CFrame.new(to)
    end
    for _ = 1, 12 do
        local rr = GetRoot()
        if rr then
            SetPos(rr, to)
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
local homePos = nil
local homeBusy = false
local MoveLock = { Owner = nil, Time = 0, Wait = {}, Prio = { pumpkin = 1, candy = 2, house = 3, yinyang = 4, dip = 5, tp2 = 6, hatch = 7 } }
MoveLock.Hold = function(owner)
    local now = os.clock()
    MoveLock.Wait[owner] = now
    if MoveLock.Owner and MoveLock.Owner ~= owner and now - MoveLock.Time < 30 then
        return false
    end
    local mine = MoveLock.Prio[owner] or 99
    for k, t in pairs(MoveLock.Wait) do
        if k ~= owner and now - t <= 3 and (MoveLock.Prio[k] or 99) < mine then
            return false
        end
    end
    MoveLock.Owner = owner
    MoveLock.Time = now
    return true
end
MoveLock.Free = function(owner)
    if MoveLock.Owner == owner then
        MoveLock.Owner = nil
    end
end
MoveLock.Keep = function(owner)
    if MoveLock.Owner ~= owner then
        return false
    end
    local now = os.clock()
    local mine = MoveLock.Prio[owner] or 99
    for k, t in pairs(MoveLock.Wait) do
        if k ~= owner and now - t <= 3 and (MoveLock.Prio[k] or 99) < mine then
            return false
        end
    end
    MoveLock.Time = now
    return true
end
local GetHomePos = nil
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
local function Unembed()
    local root = GetRoot()
    local ch = LP.Character
    if not root or not ch then return end
    local function insideSolid(pos)
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {ch}
        local hits = workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(1, 1, 1), params)
        for _, p in pairs(hits) do
            if p:IsA("BasePart") and p.CanCollide then
                local lp = p.CFrame:PointToObjectSpace(pos)
                if math.abs(lp.X) <= p.Size.X / 2 and math.abs(lp.Y) <= p.Size.Y / 2 and math.abs(lp.Z) <= p.Size.Z / 2 then
                    return true
                end
            end
        end
        local ok, mats = pcall(function()
            return workspace.Terrain:ReadVoxels(Region3.new(pos - Vector3.new(2, 2, 2), pos + Vector3.new(2, 2, 2)), 4)
        end)
        if ok and mats then
            local m = mats[1][1][1]
            if m ~= Enum.Material.Air and m ~= Enum.Material.Water then
                return true
            end
        end
        return false
    end
    if not insideSolid(root.Position) then return end
    local p0 = root.Position
    for i = 1, 15 do
        local cand = p0 + Vector3.new(0, i * 4, 0)
        if not insideSolid(cand) then
            SetPos(root, cand)
            print("[脱困] 卡墙，抬升 " .. tostring(i * 4) .. " 格脱困")
            return
        end
    end
    SetPos(root, p0 + Vector3.new(0, 60, 0))
    print("[脱困] 卡墙，抬升 60 格脱困")
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
    Unembed()
    SetNoclip(false)
end
WalkFly = function(target, speed, isStop)
    local root = GetRoot()
    if not root then return false end
    SetNoclip(true)
    local spd = math.max(speed, 1)
    local step = spd * 0.03
    local t0 = os.clock()
    local lastT = t0
    local limit = (target - root.Position).Magnitude / math.max(step, 1) * 0.06 + 2
    local last = root.Position
    local stall = 0
    while true do
        if isStop and isStop() then break end
        if os.clock() - t0 > limit then break end
        root = GetRoot()
        if not root then break end
        local nowT = os.clock()
        local dt = nowT - lastT
        lastT = nowT
        if dt < 0.01 then dt = 0.01 end
        if dt > 0.1 then dt = 0.1 end
        local move = spd * dt
        local diff = target - root.Position
        local dist = diff.Magnitude
        if dist <= 1 then break end
        if (root.Position - last).Magnitude < 0.05 then
            stall = stall + 1
            if stall >= 15 then break end
        else
            stall = 0
        end
        last = root.Position
        SetPos(root, root.Position + diff.Unit * math.min(move, dist))
        task.wait(0.03)
    end
    return true
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

GetHomePos = function()
    local node = MyPlot
    if not node then
        pcall(ScanPlots)
        node = MyPlot
    end
    if node then
        local bp = node:IsA("BasePart") and node or node:FindFirstChild("Baseplate") or node:FindFirstChildWhichIsA("BasePart")
        if bp and bp:IsA("BasePart") then
            homePos = bp.Position
            return homePos
        end
    end
    return homePos
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
    if not DisplayName(obj) then return end
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
            local det = {}
            for _, e in ipairs(CollectEggs()) do
                local disp = OfficialFull(e.Obj.Name)
                lines[#lines + 1] = e.Obj.Name .. " -> " .. (disp or "?")
                local rawT = TranslateName(e.Obj.Name)
                if (not rawT or IsQualityWordOnly(rawT)) and #det < 30 then
                    local o = e.Obj
                    local attrs = {}
                    pcall(function()
                        for k, v in pairs(o:GetAttributes()) do
                            attrs[#attrs + 1] = tostring(k) .. "=" .. tostring(v)
                        end
                    end)
                    local kids = {}
                    pcall(function()
                        for _, c in ipairs(o:GetChildren()) do
                            if c:IsA("ValueBase") then
                                kids[#kids + 1] = c.ClassName .. ":" .. c.Name .. "=" .. tostring(c.Value)
                            elseif not c:IsA("BasePart") then
                                kids[#kids + 1] = c.ClassName .. ":" .. c.Name
                            end
                        end
                    end)
                    det[#det + 1] = o.Name .. "|" .. o.ClassName .. "|q=" .. tostring(GetQualityOf(o)) .. "|p=" .. tostring(o.Parent and o.Parent.Name) .. "|gp=" .. tostring(o.Parent and o.Parent.Parent and o.Parent.Parent.Name) .. "|attrs=" .. table.concat(attrs, ";") .. "|kids=" .. table.concat(kids, ",")
                end
            end
            if #lines > 0 then
                if makefolder and not isfolder("骑宠物") then
                    makefolder("骑宠物")
                end
                writefile("骑宠物/场上蛋名.txt", table.concat(lines, "\n"))
            end
            if #det > 0 then
                if makefolder and not isfolder("骑宠物") then
                    makefolder("骑宠物")
                end
                writefile("骑宠物/蛋详情.txt", table.concat(det, "\n"))
            end
        end)
    end
end)

task.spawn(function()
    local function Eggish(o, txt)
        if not o then return false end
        local n = o.Name:lower()
        if n:find("egg") or n:find("black") or n:find("hole") or n:find("void") then
            return true
        end
        local t = (txt or ""):lower()
        if t:find("egg") or t:find("蛋") then
            return true
        end
        return false
    end
    local function BiggestPart(root)
        local best, bestVol = nil, 0
        local function scan(n)
            for _, c in ipairs(n:GetChildren()) do
                if c:IsA("BasePart") then
                    local vol = c.Size.X * c.Size.Y * c.Size.Z
                    if vol > bestVol then
                        bestVol = vol
                        best = c
                    end
                elseif c:IsA("Model") or c:IsA("Folder") then
                    scan(c)
                end
            end
        end
        scan(root)
        return best
    end
    local function PathOf(o)
        local out = {}
        local n = o
        for _ = 1, 8 do
            if not n or n == workspace then
                break
            end
            table.insert(out, 1, n.Name)
            n = n.Parent
        end
        return table.concat(out, "/")
    end
    while true do
        task.wait(5)
        pcall(function()
            local cp = GetCharPart()
            if not cp then
                return
            end
            local cpos = cp.Position
            local plots = workspace:FindFirstChild("Plots")
            local picked = {}
            for _, e in ipairs(CollectEggs()) do
                picked[e.Obj] = true
            end
            local lines = {}
            local alerts = {}
            for _, v in ipairs(workspace:GetDescendants()) do
                local cls = v.ClassName
                if (cls == "ProximityPrompt" or cls == "ClickDetector") and v.Parent then
                    local part = FindPromptPart(v)
                    if part and (part.Position - cpos).Magnitude <= 40 then
                        local act = cls == "ProximityPrompt" and tostring(v.ActionText) or "click"
                        local inPlot = plots ~= nil and part:IsDescendantOf(plots)
                        local owner = nil
                        local n = part
                        while n do
                            if picked[n] then
                                owner = n
                                break
                            end
                            n = n.Parent
                        end
                        local info = "P:" .. PathOf(part) .. "|D:" .. string.format("%.1f", (part.Position - cpos).Magnitude) .. "|act=" .. act .. "|obj=" .. tostring(v.ObjectText) .. "|tr=" .. tostring(part.Transparency) .. "|plot=" .. tostring(inPlot) .. "|collected=" .. tostring(owner ~= nil)
                        if owner then
                            info = info .. "|egg=" .. owner.Name
                        end
                        lines[#lines + 1] = info
                        if not inPlot and not owner then
                            local top = part
                            for _ = 1, 4 do
                                if top.Parent and top.Parent ~= workspace then
                                    top = top.Parent
                                else
                                    break
                                end
                            end
                            if InEggFolders(top) or Eggish(top, act) then
                                local body = BiggestPart(top)
                                local extra = "|top=" .. top.ClassName .. ":" .. top.Name .. "|alive=" .. tostring(IsAliveEgg(top)) .. "|fold=" .. tostring(InEggFolders(top))
                                if body then
                                    extra = extra .. "|body=" .. body.Name .. "|btr=" .. tostring(body.Transparency) .. "|size=" .. tostring(body.Size)
                                end
                                local kids = {}
                                for _, c in ipairs(top:GetChildren()) do
                                    if #kids < 10 then
                                        kids[#kids + 1] = c.ClassName .. ":" .. c.Name
                                    end
                                end
                                info = info .. extra .. "|kids=" .. table.concat(kids, ",")
                                if #alerts < 3 then
                                    alerts[#alerts + 1] = info
                                end
                            end
                        end
                    end
                end
            end
            if #lines > 0 then
                pcall(function()
                    if makefolder and not isfolder("骑宠物") then
                        makefolder("骑宠物")
                    end
                    writefile("骑宠物/蛋诊断.txt", table.concat(lines, "\n"))
                end)
            end
            for _, a in ipairs(alerts) do
                print("[蛋诊断] " .. a)
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
Toggles.NoticeRight = Tabs.Notice:AddRightGroupbox("公告")
Toggles.NoticeRight:AddLabel("10月18日:已更新活动功能").TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
Toggles.NoticeRight:AddLabel("已修复黑洞蛋无法传送bug").TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
Toggles.NoticeRight:AddLabel("再次绕过反作弊").TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
Toggles.NoticeRight:AddLabel("已更新自动孵化蛋").TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
Toggles.NoticeRight:AddLabel("修复大量功能").TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
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
Toggles.AutoTP2 = HangBox:AddToggle("AutoTP2", { Text = "自动传送蛋(开自动拾取)", Default = false })
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
    dur = tonumber(dur) or 0
    if dur < 0 then dur = 0 end
    local root = GetRoot()
    if not root then return end
    local rot = root.CFrame - root.CFrame.Position
    local t0 = os.clock()
    repeat
        root = GetRoot()
        if root then
            root.CFrame = CFrame.new(pos) * rot
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        task.wait()
    until os.clock() - t0 >= dur
end
local function HoldPrompt(o, dur, noPin)
    if not o or not o.Parent then return end
    local hold = tonumber(dur) or 0
    if hold <= 0 then hold = 0.5 end
    if hold < 0.4 then hold = 0.4 end
    if hold > 5 then hold = 5 end
    local began = pcall(function()
        o:InputHoldBegin()
    end)
    if began then
        if noPin then
            task.wait(hold)
        else
            local root = GetRoot()
            local pos = root and root.Position or nil
            VolcanoHold(pos, hold)
        end
        pcall(function()
            o:InputHoldEnd()
        end)
    else
        pcall(function()
            fireproximityprompt(o, hold)
        end)
    end
end
local function VolcanoFlyTo(target, speed, keepNoclip)
    local root = GetRoot()
    if not root then return end
    SetNoclip(true)
    WalkFly(target, speed)
    root = GetRoot()
    if root then SetPos(root, target) end
    if not keepNoclip then
        Unembed()
        SetNoclip(false)
    end
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
Toggles.AutoHatchEgg = EggBox:AddToggle("AutoHatchEgg", { Text = "自动孵化蛋", Default = false })
task.spawn(function()
    while true do
        task.wait(0.8)
        if Toggles.AutoHatchEgg and Toggles.AutoHatchEgg.Value then
            ScanPlots()
            local eggs = GetHomeEggs()
            if #eggs > 0 and MoveLock.Hold("hatch") then
                for _, e in ipairs(eggs) do
                    if not (Toggles.AutoHatchEgg and Toggles.AutoHatchEgg.Value) then break end
                    if not MoveLock.Keep("hatch") then break end
                    local facePos = e.Pos + Vector3.new(0, -0.5, 0)
                    pcall(function()
                        TPTo(facePos)
                    end)
                    local ht0 = os.clock()
                    while os.clock() - ht0 < 1.5 do
                        local root = GetRoot()
                        if not root then break end
                        SetPos(root, facePos)
                        if e.Obj and not e.Obj.Parent then break end
                        task.wait(0.02)
                    end
                    local cp = GetCharPart()
                    if cp then
                        local cpos = cp.Position
                        for _, v in ipairs(workspace:GetDescendants()) do
                            if v.ClassName == "ProximityPrompt" and v.Parent then
                                local part = FindPromptPart(v)
                                if part and (part.Position - cpos).Magnitude <= 5 then
                                    pcall(function() fireproximityprompt(v, v.HoldDuration) end)
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
                MoveLock.Free("hatch")
            end
        end
    end
end)

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
local PetUtil = {}
PetUtil.RideId = "3373cbdc-44c4-424f-8e33-e321c454e3e7"
PetUtil.Busy = false
PetUtil.InvDone = false
PetUtil.Pickup = GameR and GameR:FindFirstChild("PickupPet")
PetUtil.Mount = GameR and GameR:FindFirstChild("Mounting")
PetUtil.AttrHit = function(o, id)
    local ok, at = pcall(function()
        return o:GetAttributes()
    end)
    if ok and type(at) == "table" then
        for _, v in pairs(at) do
            if tostring(v) == id then
                return true
            end
        end
    end
    return false
end
PetUtil.AttrList = function(o)
    local out = {}
    local ok, at = pcall(function()
        return o:GetAttributes()
    end)
    if ok and type(at) == "table" then
        for k, v in pairs(at) do
            out[#out + 1] = tostring(k) .. "=" .. tostring(v)
        end
    end
    return out
end
PetUtil.ValueList = function(o)
    local out = {}
    for _, d in ipairs(o:GetDescendants()) do
        if d:IsA("ValueBase") then
            out[#out + 1] = tostring(d.Name) .. "=" .. tostring(d.Value)
        end
    end
    return out
end
PetUtil.Match = function(n, id)
    if not n then return false end
    if n.Name == id then return true end
    if PetUtil.AttrHit(n, id) then return true end
    for _, d in ipairs(n:GetDescendants()) do
        if d:IsA("ValueBase") and tostring(d.Value) == id then
            return true
        end
        if PetUtil.AttrHit(d, id) then
            return true
        end
    end
    return false
end
PetUtil.MyIds = function()
    local out = {}
    local pets = MyPlot and MyPlot:FindFirstChild("Pets")
    if pets then
        for _, q in ipairs(pets:GetChildren()) do
            local v = GetPetId(q)
            if v then
                out[v] = true
            end
        end
    end
    return out
end
PetUtil.HomeId = function()
    local id = PetUtil.RideId
    local mine = PetUtil.MyIds()
    if mine[id] then return id end
    for v in pairs(mine) do
        return v
    end
    return id
end
PetUtil.BagTools = function()
    local out = {}
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                out[#out + 1] = t
            end
        end
    end
    local ch = LP.Character
    if ch then
        for _, t in ipairs(ch:GetChildren()) do
            if t:IsA("Tool") then
                out[#out + 1] = t
            end
        end
    end
    return out
end
PetUtil.ToolText = function(t)
    local att = PetUtil.AttrList(t)
    local vals = PetUtil.ValueList(t)
    local s = t.ClassName .. ":" .. tostring(t.Name) .. " 位置=" .. tostring(t.Parent and t.Parent.Name)
    if #att > 0 then
        s = s .. " 属性[" .. table.concat(att, ",") .. "]"
    end
    if #vals > 0 then
        s = s .. " 值[" .. table.concat(vals, ",") .. "]"
    end
    return s
end
PetUtil.SlotText = function(s)
    local extra = ""
    pcall(function()
        if s:IsA("ImageLabel") or s:IsA("ImageButton") then
            extra = " 图=" .. tostring(s.Image)
        end
        if s:IsA("TextLabel") or s:IsA("TextButton") then
            extra = " 文=" .. tostring(s.Text)
        end
    end)
    local att = PetUtil.AttrList(s)
    local vals = PetUtil.ValueList(s)
    local r = s.ClassName .. ":" .. tostring(s.Name) .. extra
    if #att > 0 then
        r = r .. " 属性[" .. table.concat(att, ",") .. "]"
    end
    if #vals > 0 then
        r = r .. " 值[" .. table.concat(vals, ",") .. "]"
    end
    return r
end
PetUtil.InvBrief = function()
    local tools = PetUtil.BagTools()
    print("[背包] LocalPlayer.Backpack Tool数=" .. tostring(#tools))
    for i = 1, math.min(#tools, 20) do
        print("[背包] " .. tostring(i) .. " " .. PetUtil.ToolText(tools[i]))
    end
    local hs = GetHotbarSlots()
    for i = 1, math.min(#hs, 10) do
        print("[格子] 快捷" .. tostring(i) .. " " .. PetUtil.SlotText(hs[i]))
    end
    local iv = GetInvSlots()
    print("[格子] 背包格数=" .. tostring(#iv))
    for i = 1, math.min(#iv, 20) do
        print("[格子] 背包" .. tostring(i) .. " " .. PetUtil.SlotText(iv[i]))
    end
end
PetUtil.FindTarget = function(id)
    local tools = PetUtil.BagTools()
    local tool = nil
    for _, t in ipairs(tools) do
        if PetUtil.Match(t, id) then
            tool = t
            break
        end
    end
    if not tool and #tools == 1 then
        tool = tools[1]
    end
    if not tool then
        for _, t in ipairs(tools) do
            local n = string.lower(tostring(t.Name))
            if string.find(n, "pet") or string.find(tostring(t.Name), "宠") then
                tool = t
                break
            end
        end
    end
    local slot = nil
    for _, s in ipairs(GetHotbarSlots()) do
        if PetUtil.Match(s, id) or (tool and s.Name == tool.Name) then
            slot = s
            break
        end
    end
    if not slot then
        for _, s in ipairs(GetInvSlots()) do
            if PetUtil.Match(s, id) or (tool and s.Name == tool.Name) then
                slot = s
                break
            end
        end
    end
    return slot, tool
end
PetUtil.Prepare = function()
    if PetUtil.Busy then
        local tw = os.clock()
        while PetUtil.Busy and os.clock() - tw < 1.5 do
            task.wait(0.05)
        end
        if PetUtil.Busy then
            return false
        end
    end
    if not (PetUtil.Pickup and PetUtil.Mount) then
        print("[拿蛋] 缺远程 PickupPet/Mounting")
        return false
    end
    PetUtil.Busy = true
    local id = PetUtil.HomeId()
    pcall(function()
        PetUtil.Pickup:FireServer(id)
    end)
    task.wait(0.4)
    OpenBackpack()
    task.wait(0.2)
    if not PetUtil.InvDone then
        PetUtil.InvDone = true
        PetUtil.InvBrief()
    end
    local slot, tool = PetUtil.FindTarget(id)
    if slot then
        ClickSlot(slot)
        task.wait(0.3)
    elseif tool then
        pcall(function()
            local h = LP.Character and LP.Character:FindFirstChildWhichIsA("Humanoid")
            if h then
                h:EquipTool(tool)
            end
        end)
        task.wait(0.3)
    end
    pcall(function()
        PetUtil.Mount:FireServer()
    end)
    task.wait(0.4)
    print("[拿蛋] 卸下+装备 id=" .. tostring(id) .. " 格子=" .. (slot and tostring(slot.Name) or "无") .. " Tool=" .. (tool and tostring(tool.Name) or "无"))
    PetUtil.Busy = false
    return true
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
    local ep = GetEggPlaced()
    if not ep then return end
    local function IsEggTool(o)
        if not o:IsA("Tool") then return false end
        local nm = tostring(o.Name)
        if nm:find("蛋", 1, true) then return true end
        local k = NormalName(nm)
        if k == "" then return false end
        if EggValue[k] then return true end
        if k:find("egg", 1, true) then return true end
        for _, n in ipairs(AllEggNames) do
            local an = NormalName(n)
            if an ~= "" and k:find(an, 1, true) then return true end
        end
        return false
    end
    local function ToolUuid(o)
        local found = nil
        local function chk(v)
            if found then return end
            if type(v) == "string" and v:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-") then
                found = v
            end
        end
        pcall(function()
            for _, v in pairs(o:GetAttributes()) do
                chk(tostring(v))
            end
        end)
        chk(tostring(o.Name))
        for _, d in ipairs(o:GetDescendants()) do
            chk(tostring(d.Name))
            pcall(function()
                for _, v in pairs(d:GetAttributes()) do
                    chk(tostring(v))
                end
            end)
            pcall(function()
                if d:IsA("ValueBase") then
                    chk(tostring(d.Value))
                end
            end)
        end
        return found
    end
    local function TakeEgg(o, uuid)
        if uuid and grabSeen and grabSeen.obj then
            local args = {}
            local n = select("#", unpack(grabSeen.args))
            for i = 1, n do
                args[i] = select(i, unpack(grabSeen.args))
            end
            if n >= 1 then args[1] = uuid end
            local ok = pcall(function()
                grabSeen.obj:FireServer(unpack(args))
            end)
            if ok then return true end
        end
        local ch = LP.Character
        if not ch then return false end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum:EquipTool(o)
            end)
        end
        if o.Parent ~= ch then
            pcall(function()
                o.Parent = ch
            end)
        end
        return o.Parent == ch
    end
    local function SpamPlant()
        local pos = RandomPlotPos()
        local args = { [1] = { ["PlantPosition"] = pos } }
        pcall(function()
            ep:FireServer(unpack(args))
        end)
    end
    local bp = LP:FindFirstChild("Backpack")
    if not bp then return end
    local eggs = {}
    for _, o in ipairs(bp:GetChildren()) do
        if IsEggTool(o) then
            local v = GetEggValue(o.Name)
            if type(v) ~= "number" then v = 0 end
            eggs[#eggs + 1] = { Obj = o, Val = v }
        end
    end
    if #eggs == 0 then
        if not PetUtil.PlantDump then
            PetUtil.PlantDump = true
            local lines = {}
            for _, o in ipairs(bp:GetChildren()) do
                lines[#lines + 1] = o.ClassName .. ":" .. tostring(o.Name)
                pcall(function()
                    for k, v in pairs(o:GetAttributes()) do
                        lines[#lines + 1] = "  A:" .. tostring(k) .. "=" .. tostring(v)
                    end
                end)
                pcall(function()
                    for _, d in ipairs(o:GetChildren()) do
                        lines[#lines + 1] = "  C:" .. d.ClassName .. ":" .. tostring(d.Name)
                    end
                end)
            end
            pcall(function()
                if makefolder and not isfolder("骑宠物") then makefolder("骑宠物") end
                writefile("骑宠物/背包清单.txt", table.concat(lines, "\n"))
            end)
        end
        return
    end
    table.sort(eggs, function(a, b)
        if a.Val == b.Val then
            return tostring(a.Obj.Name) < tostring(b.Obj.Name)
        end
        return a.Val > b.Val
    end)
    for _, item in ipairs(eggs) do
        if not (Toggles.PointClick and Toggles.PointClick.Value) then break end
        local o = item.Obj
        if o.Parent == bp then
            TakeEgg(o, ToolUuid(o))
            task.wait(0.35)
            for _ = 1, 8 do SpamPlant() end
            task.wait(0.25)
        end
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

Toggles.EggBox = Tabs.Event:AddLeftGroupbox("万圣节")
Toggles.BuyHalloweenEgg = Toggles.EggBox:AddToggle("BuyHalloweenEgg", { Text = "自动购买万圣节蛋", Default = false })
Toggles.EggBox:AddButton({ Text = "传送AFK区域", Func = function()
    local fn = workspace:FindFirstChild("Functionals")
    local afk = fn and fn:FindFirstChild("HalloweenAFK")
    if afk then
        local part = afk:IsA("BasePart") and afk or afk:FindFirstChildWhichIsA("BasePart")
        if part then
            pcall(function()
                TPTo(part.Position + Vector3.new(0, 1, 0))
            end)
        end
    end
end })

Toggles.CandyBox = Tabs.Event:AddLeftGroupbox("糖果")
Toggles.CandyPick = Toggles.CandyBox:AddToggle("CandyPick", { Text = "自动拾取", Default = false })
Toggles.HouseKnock = Toggles.CandyBox:AddToggle("HouseKnock", { Text = "自动敲门(开自动拾取)", Default = false })
Toggles.Candy = Toggles.CandyBox:AddToggle("Candy", { Text = "自动收集糖果(开自动拾取)", Default = false })
PetUtil.CandyValue = function(c)
    local function Grab(x)
        if type(x) == "number" then
            if x > 0 then return x end
            return nil
        end
        if type(x) == "string" then
            local n = tonumber(x:match("%d+"))
            if n and n > 0 then return n end
        end
        return nil
    end
    for _, k in ipairs({ "Value", "EggValue", "Worth", "Price", "Tokens", "Token", "Amount", "CandyValue", "Reward", "Points" }) do
        local ok, av = pcall(function() return c:GetAttribute(k) end)
        if ok then
            local n = Grab(av)
            if n then return n end
        end
    end
    local okd, kids = pcall(function() return c:GetDescendants() end)
    if okd and kids then
        for _, d in ipairs(kids) do
            if d:IsA("NumberValue") or d:IsA("IntValue") or d:IsA("StringValue") then
                local n = Grab(d.Value)
                if n then return n end
            end
        end
        for _, d in ipairs(kids) do
            local dn = tostring(d.Name):lower()
            if dn:find("value") or dn:find("token") or dn:find("worth") or dn:find("price") or dn:find("amount") then
                local n = Grab(d.Name)
                if n then return n end
            end
        end
    end
    local g = GetEggValue(c.Name)
    if g and g > 0 then return g end
    local n = Grab(c.Name)
    if n then return n end
    return 0
end
PetUtil.CandyWait = function(c)
    local val = PetUtil.CandyValue(c)
    if val <= 1 then
        return 2
    end
    local r = math.log10(val) / 9
    if r < 0 then r = 0 end
    if r > 1 then r = 1 end
    local sec = 1 + 4 * r
    if sec < 2 then sec = 2 end
    if sec > 5 then sec = 5 end
    return sec
end
PetUtil.PartPos = function(o)
    if not o then return nil end
    if o:IsA("BasePart") then return o.Position end
    local p = o.PrimaryPart
    if not p then
        p = o:FindFirstChildWhichIsA("BasePart")
    end
    return p and p.Position or nil
end
PetUtil.DropPos = function(first, second)
    for _, n in ipairs({ first, second, "CandyDropOff", "PumpkinDropOff", "HalloweenDropOff", "DropOff" }) do
        if n then
            local o = workspace:FindFirstChild(n)
            local p = PetUtil.PartPos(o)
            if p then return p, n end
        end
    end
    for _, o in ipairs(workspace:GetChildren()) do
        local ln = o.Name:lower()
        if ln:find("dropoff") or ln:find("sell") then
            local p = PetUtil.PartPos(o)
            if p then return p, o.Name end
        end
    end
    return nil, nil
end
PetUtil.IsRitual = function(nm)
    if not nm then return false end
    local low = nm:lower()
    if low:find("headless") or low:find("ritual") or low:find("cutout") or low:find("socket") then return true end
    if nm:find("阴") or nm:find("阳") then return true end
    if low:find("yang") then return true end
    if low:find("yin") and not low:find("play") and not low:find("fly") then return true end
    return false
end
Toggles.RitualBox = Tabs.Event:AddLeftGroupbox("阴阳")
Toggles.YinYang = Toggles.RitualBox:AddToggle("YinYang", { Text = "自动收集阴阳(开自动拾取)", Default = false })
Toggles.PumpkinBox = Tabs.Event:AddLeftGroupbox("南瓜")
Toggles.Pumpkin = Toggles.PumpkinBox:AddToggle("Pumpkin", { Text = "自动收集腐烂南瓜(开自动拾取)", Default = false })
task.spawn(function()
    local ready = false
    while true do
        task.wait(0.5)
        if Toggles.Candy and Toggles.Candy.Value then
            if not ready then
                ready = true
                TPTo(Vector3.new(-46032.695312, 40388.906250, -20314.591797))
                task.wait(1)
                PetUtil.Prepare()
            end
            local folder = workspace:FindFirstChild("HalloweenCandy")
            local drop = workspace:FindFirstChild("CandyDropOff")
            local dropPos = nil
            if drop then
                if drop:IsA("BasePart") then
                    dropPos = drop.Position
                else
                    local dp = drop.PrimaryPart or drop:FindFirstChildWhichIsA("BasePart")
                    if dp then
                        dropPos = dp.Position
                    end
                end
            end
            if folder then
                local candyList = {}
                for _, c in ipairs(folder:GetChildren()) do
                    local cp = nil
                    if c:IsA("BasePart") then
                        cp = c.Position
                    else
                        local p = c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart")
                        if p then
                            cp = p.Position
                        end
                    end
                    if cp then
                        table.insert(candyList, { Obj = c, Pos = cp, Val = PetUtil.CandyValue(c) })
                    end
                end
                table.sort(candyList, function(a, b)
                    return a.Val > b.Val
                end)
                if #candyList > 0 and MoveLock.Hold("candy") then
                    for _, it in ipairs(candyList) do
                        if not (Toggles.Candy and Toggles.Candy.Value) then break end
                        if not MoveLock.Keep("candy") then break end
                        WalkFly(it.Pos + Vector3.new(0, 3, 0), Options.FlySpeed.Value)
                        local cw = PetUtil.CandyWait(it.Obj)
                        print("[糖果] 到 " .. tostring(it.Obj.Name) .. " 价值=" .. tostring(it.Val) .. " 停留=" .. string.format("%.2f", cw) .. "秒")
                        task.wait(cw)
                        if dropPos then
                            WalkFly(dropPos + Vector3.new(0, 3, 0), Options.FlySpeed.Value)
                            task.wait(0.5)
                        end
                    end
                    MoveLock.Free("candy")
                end
            end
        else
            ready = false
            MoveLock.Free("candy")
        end
    end
end)

task.spawn(function()
    local function PartOf(o)
        if not o then return nil end
        if o:IsA("BasePart") then return o end
        return o:FindFirstChildWhichIsA("BasePart", true)
    end
    local function Match(o, tag)
        if not o then return false end
        local nm = o.Name
        local ln = nm:lower()
        if tag == "yang" then
            return ln:find("yang") ~= nil or nm:find("阳") ~= nil
        end
        return (ln:find("yin") ~= nil and ln:find("play") == nil and ln:find("fly") == nil) or nm:find("阴") ~= nil
    end
    local function Find(list, tag)
        for _, c in ipairs(list) do
            local p = PartOf(c)
            if p and Match(c, tag) then
                return { Obj = c, Pos = p.Position }
            end
        end
        return nil
    end
    local lastMsg = ""
    local function Say(msg)
        if msg ~= lastMsg then
            lastMsg = msg
            if msg ~= "" then
                print(msg)
            end
        end
    end
    local ready = false
    while true do
        task.wait(0.5)
        if Toggles.YinYang and Toggles.YinYang.Value then
            local ritual = workspace:FindFirstChild("HeadlessRitual")
            local runtime = ritual and ritual:FindFirstChild("Runtime")
            local sockets = ritual and ritual:FindFirstChild("SocketRecesses")
            local list = {}
            local src = runtime or ritual
            if src then
                for _, c in ipairs(src:GetDescendants()) do
                    table.insert(list, c)
                end
                if src ~= runtime then
                    table.insert(list, src)
                end
            end
            local skList = {}
            if sockets then
                for _, c in ipairs(sockets:GetDescendants()) do
                    table.insert(skList, c)
                end
            end
            local yang = Find(list, "yang")
            local yin = Find(list, "yin")
            local yCut = Find(skList, "yang")
            local yinCut = Find(skList, "yin")
            if not ritual then
                Say("[阴阳] 找不到 workspace.HeadlessRitual")
            elseif not yang and not yin then
                local names = {}
                for idx = 1, math.min(#list, 8) do
                    table.insert(names, list[idx].Name)
                end
                Say("[阴阳] 没找到阴/阳 " .. tostring(src and src:GetFullName() or "nil") .. " 对象 " .. tostring(#list) .. " 个: " .. table.concat(names, ", "))
            elseif not MoveLock.Hold("yinyang") then
                Say("[阴阳] 移动锁被占用 占用者 " .. tostring(MoveLock.Owner))
            else
                Say("")
                if not ready then
                    ready = true
                    TPTo(Vector3.new(-46032.695312, 40388.906250, -20314.591797))
                    task.wait(1)
                    PetUtil.Prepare()
                end
                local stops = {}
                if yang then
                    table.insert(stops, { Tag = "阳", Pos = yang.Pos, Obj = yang.Obj })
                end
                if yCut then
                    table.insert(stops, { Tag = "YangCutout", Pos = yCut.Pos, Obj = yCut.Obj })
                end
                if yin then
                    table.insert(stops, { Tag = "阴", Pos = yin.Pos, Obj = yin.Obj })
                end
                if yinCut then
                    table.insert(stops, { Tag = "YinCutout", Pos = yinCut.Pos, Obj = yinCut.Obj })
                end
                for _, st in ipairs(stops) do
                    if not MoveLock.Keep("yinyang") then
                        break
                    end
                    print("[阴阳] 飞向 " .. st.Tag .. " " .. tostring(st.Obj.Name))
                    WalkFly(st.Pos + Vector3.new(0, 3, 0), 3000)
                    VolcanoHold(st.Pos + Vector3.new(0, 3, 0), 1)
                end
                MoveLock.Free("yinyang")
            end
        else
            ready = false
            lastMsg = ""
        end
    end
end)

task.spawn(function()
    local doorFire = {}
    local ritualFire = {}
    while true do
        task.wait(0.1)
        if Toggles.CandyPick and Toggles.CandyPick.Value then
            local cp = GetCharPart()
            if cp then
                local cpos = cp.Position
                local now = os.clock()
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v.ClassName == "ProximityPrompt" and v.Parent then
                        local part = FindPromptPart(v)
                        if part and (part.Position - cpos).Magnitude <= 20 then
                            local n = part
                            local isEventItem = false
                            local isDoor = false
                            local isRitual = false
                            while n and n ~= workspace do
                                local ln = n.Name:lower()
                                if ln:find("candy") or ln:find("pumpkin") or ln:find("rotten") then
                                    isEventItem = true
                                    break
                                end
                                if PetUtil.IsRitual(n.Name) then
                                    isRitual = true
                                    break
                                end
                                if ln:find("door") or ln:find("house") or ln:find("knock") or ln:find("treat") or ln:find("trick") then
                                    isDoor = true
                                end
                                n = n.Parent
                            end
                            if isEventItem then
                                pcall(function()
                                    fireproximityprompt(v, v.HoldDuration)
                                end)
                            elseif isRitual and (not ritualFire[v] or now - ritualFire[v] > 3) then
                                ritualFire[v] = now
                                pcall(function()
                                    fireproximityprompt(v, v.HoldDuration)
                                end)
                            elseif isDoor and (not doorFire[v] or now - doorFire[v] > 4) then
                                doorFire[v] = now
                                if not (Toggles.HouseKnock and Toggles.HouseKnock.Value) then
                                    local hv = tonumber(v.HoldDuration) or 0
                                    HoldPrompt(v, hv, true)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    local doors, stamp, cd = {}, 0, {}
    local ready = false
    while true do
        task.wait(0.5)
        if Toggles.HouseKnock and Toggles.HouseKnock.Value then
            if not ready then
                ready = true
                TPTo(Vector3.new(-46032.695312, 40388.906250, -20314.591797))
                task.wait(1)
                PetUtil.Prepare()
            end
            local now = os.clock()
            if now - stamp > 30 then
                stamp = now
                doors = {}
                local folder = workspace:FindFirstChild("TrickOrTreatHouseModel")
                local houses = {}
                if folder then
                    local kids = folder:GetChildren()
                    if #kids > 0 then
                        for _, h in ipairs(kids) do
                            table.insert(houses, h)
                        end
                    else
                        table.insert(houses, folder)
                    end
                end
                for _, h in ipairs(houses) do
                    local obj = nil
                    local objs = {}
                    for _, x in ipairs(h:GetDescendants()) do
                        if x.ClassName == "ProximityPrompt" or x.ClassName == "ClickDetector" then
                            table.insert(objs, x)
                            if not obj then
                                obj = x
                            end
                        end
                    end
                    local part = nil
                    if obj and obj.ClassName == "ProximityPrompt" then
                        part = FindPromptPart(obj)
                    end
                    if not part then
                        local par = obj and obj.Parent or nil
                        if par then
                            if par:IsA("BasePart") then
                                part = par
                            else
                                part = par:FindFirstChildWhichIsA("BasePart")
                            end
                        end
                    end
                    if not part then
                        for _, x in ipairs(h:GetDescendants()) do
                            if x:IsA("BasePart") and x.Name:lower():find("door") then
                                part = x
                                break
                            end
                        end
                    end
                    if not part then
                        part = h:IsA("BasePart") and h or h:FindFirstChildWhichIsA("BasePart")
                    end
                    if obj and part then
                        table.insert(doors, { Obj = obj, Objs = objs, P = part, H = h })
                    end
                end
                if #doors == 0 then
                    for _, v in ipairs(workspace:GetDescendants()) do
                        if (v.ClassName == "ProximityPrompt" or v.ClassName == "ClickDetector") and v.Parent then
                            local n = v
                            local hit = false
                            while n and n ~= workspace do
                                local ln = n.Name:lower()
                                if ln:find("door") or ln:find("house") or ln:find("knock") or ln:find("treat") or ln:find("trick") then
                                    hit = true
                                    break
                                end
                                n = n.Parent
                            end
                            if hit then
                                local part = nil
                                if v.ClassName == "ProximityPrompt" then
                                    part = FindPromptPart(v)
                                end
                                if not part then
                                    local par = v.Parent
                                    if par and par:IsA("BasePart") then
                                        part = par
                                    elseif par then
                                        part = par:FindFirstChildWhichIsA("BasePart")
                                    end
                                end
                                if part then
                                    table.insert(doors, { Obj = v, Objs = { v }, P = part, H = v.Parent })
                                end
                            end
                        end
                    end
                end
                print("[敲门] TrickOrTreatHouseModel 房子 " .. tostring(#houses) .. " 个，可敲 " .. tostring(#doors) .. " 个")
            end
            if #doors > 0 and MoveLock.Hold("house") then
                local cp = GetCharPart()
                if not cp then
                    MoveLock.Free("house")
                else
                    local cpos = cp.Position
                    table.sort(doors, function(a, b)
                        return (a.P.Position - cpos).Magnitude < (b.P.Position - cpos).Magnitude
                    end)
                    for _, d in ipairs(doors) do
                        if not (Toggles.HouseKnock and Toggles.HouseKnock.Value) then
                            break
                        end
                        if not MoveLock.Keep("house") then
                            break
                        end
                        if d.P.Parent and d.Obj.Parent and (cd[d.P] or 0) <= os.clock() then
                            local name = tostring(d.H and d.H.Name or d.P.Name)
                            local cp2 = GetCharPart()
                            local hd = 0
                            if cp2 then
                                hd = (d.P.Position - cp2.Position).Magnitude
                            end
                            print("[敲门] 飞向 " .. name .. " 距离 " .. string.format("%.0f", hd))
                            WalkFly(d.P.Position + Vector3.new(0, 3, 0), Options.FlySpeed.Value > 3000 and Options.FlySpeed.Value or 3000)
                            for _, o in ipairs(d.Objs or { d.Obj }) do
                                if o.Parent then
                                    if o.ClassName == "ProximityPrompt" then
                                        local hd2 = tonumber(o.HoldDuration) or 0
                                        if hd2 <= 0 then hd2 = 0.5 end
                                        print("[敲门] 长按 " .. name .. " " .. string.format("%.2f", hd2) .. "秒")
                                        HoldPrompt(o, hd2)
                                    elseif o.ClassName == "ClickDetector" then
                                        pcall(function()
                                            fireclickdetector(o)
                                        end)
                                    end
                                end
                            end
                            cd[d.P] = os.clock() + 20
                            print("[敲门] 已敲 " .. name)
                            if d.P.Parent then
                                VolcanoHold(d.P.Position + Vector3.new(0, 3, 0), 1)
                            end
                            local dropPos, dropName = PetUtil.DropPos("CandyDropOff", "PumpkinDropOff")
                            if dropPos then
                                print("[敲门] 飞向出售区 " .. tostring(dropName))
                                WalkFly(dropPos + Vector3.new(0, 3, 0), Options.FlySpeed.Value > 3000 and Options.FlySpeed.Value or 3000)
                                VolcanoHold(dropPos + Vector3.new(0, 3, 0), 0.5)
                                Unembed()
                                SetNoclip(false)
                            end
                        end
                    end
                    do
                        local anyAvail = false
                        for _, d in ipairs(doors) do
                            if d.P.Parent and d.Obj.Parent and (cd[d.P] or 0) <= os.clock() then
                                anyAvail = true
                                break
                            end
                        end
                        local cp3 = GetCharPart()
                        if not anyAvail and cp3 then
                            local nd, np = nil, math.huge
                            for _, d in ipairs(doors) do
                                if d.P.Parent then
                                    local dist = (d.P.Position + Vector3.new(0, 3, 0) - cp3.Position).Magnitude
                                    if dist < np then
                                        np = dist
                                        nd = d
                                    end
                                end
                            end
                            if nd and np > 15 then
                                print("[敲门] 门都在冷却，回最近门口等 " .. string.format("%.0f", np))
                                WalkFly(nd.P.Position + Vector3.new(0, 3, 0), Options.FlySpeed.Value > 3000 and Options.FlySpeed.Value or 3000)
                                Unembed()
                                SetNoclip(false)
                            end
                        end
                    end
                    MoveLock.Free("house")
                end
            end
        else
            ready = false
        end
    end
end)

task.spawn(function()
    local ready = false
    while true do
        task.wait(0.5)
        if Toggles.Pumpkin and Toggles.Pumpkin.Value then
            if not ready then
                ready = true
                TPTo(Vector3.new(-46032.695312, 40388.906250, -20314.591797))
                task.wait(1)
                PetUtil.Prepare()
            end
            local folder = workspace:FindFirstChild("HalloweenPumpkins")
            local dropPos, dropName = PetUtil.DropPos("PumpkinDropOff", "CandyDropOff")
            if folder then
                local root = GetRoot()
                local list = {}
                for _, c in ipairs(folder:GetChildren()) do
                    local cp = PetUtil.PartPos(c)
                    if cp then
                        local d = root and (cp - root.Position).Magnitude or 0
                        table.insert(list, { Obj = c, Pos = cp, Dist = d })
                    end
                end
                table.sort(list, function(a, b)
                    return a.Dist < b.Dist
                end)
                if #list > 0 and MoveLock.Hold("pumpkin") then
                    for _, it in ipairs(list) do
                        if not (Toggles.Pumpkin and Toggles.Pumpkin.Value) then break end
                        if not MoveLock.Keep("pumpkin") then break end
                        local rd = GetRoot()
                        if rd and (it.Pos - rd.Position).Magnitude > 2000 then
                            pcall(function()
                                TPTo(it.Pos + Vector3.new(0, 3, 0))
                            end)
                        else
                            WalkFly(it.Pos + Vector3.new(0, 3, 0), Options.FlySpeed.Value)
                        end
                        print("[南瓜] 到 " .. tostring(it.Obj.Name) .. " 等待2秒" .. (dropName and (" 出售点=" .. tostring(dropName)) or " 未找到出售点"))
                        task.wait(2)
                        if dropPos then
                            WalkFly(dropPos + Vector3.new(0, 3, 0), Options.FlySpeed.Value)
                            task.wait(0.5)
                        end
                    end
                    MoveLock.Free("pumpkin")
                end
            end
        else
            ready = false
            MoveLock.Free("pumpkin")
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if Toggles.BuyHalloweenEgg and Toggles.BuyHalloweenEgg.Value then
            pcall(function()
                local r = ReplicatedStorage:FindFirstChild("Remotes")
                local g = r and r:FindFirstChild("Game")
                local ev = g and g:FindFirstChild("BuyHalloweenEgg")
                if ev then
                    ev:InvokeServer("Halloween Egg")
                end
            end)
        end
    end
end)

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
local TPEggVal = 0
local HomeTries = 0
task.spawn(function()
    while true do
        task.wait(0.5)
        if Toggles.AutoTP2 and Toggles.AutoTP2.Value and not VolcanoActive then
            local set = GetCheckedSet()
            if next(set) then
                local root = GetRoot()
                if root and not homeBusy and MoveLock.Hold("tp2") then
                    if GoHome then
                        if os.clock() - LastTP2 >= Options.DelayTime.Value then
                            local hp = GetHomePos()
                            if hp then
                                if (root.Position - hp).Magnitude < 8 then
                                    GoHome = false
                                    LastTP2 = 0
                                    HomeTries = 0
                                elseif HomeTries < 2 then
                                    HomeTries = HomeTries + 1
                                    homeBusy = true
                                    local okHome = DropAndGoHome(hp, TPEggVal)
                                    homeBusy = false
                                    if okHome then
                                        GoHome = false
                                        LastTP2 = 0
                                        HomeTries = 0
                                    end
                                else
                                    GoHome = false
                                    LastTP2 = os.clock()
                                    HomeTries = 0
                                end
                            else
                                GoHome = false
                                LastTP2 = os.clock()
                                HomeTries = 0
                            end
                        end
                    elseif os.clock() - LastTP2 >= Options.DelayTime.Value then
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
                        if best then
                            PetUtil.Prepare()
                            pcall(function()
                                TPTo(EggTopPos(best))
                            end)
                            LockToEgg(best, Options.DelayTime.Value, true)
                            LastTP2 = os.clock()
                            TPEggVal = GetEggValue(best.Obj.Name)
                            HomeTries = 0
                            GoHome = true
                        end
                    end
                    MoveLock.Free("tp2")
                end
            end
        else
            if not (Toggles.AutoTP2 and Toggles.AutoTP2.Value) then
                GoHome = false
                MoveLock.Free("tp2")
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
                if egg and MoveLock.Hold("dip") then
                    LastDipRun = os.clock()
                    PetUtil.Prepare()
                    pcall(function()
                        TPTo(EggTopPos(egg))
                    end)
                    LockToEgg(egg, Options.DelayTime.Value, true)
                    TPEggVal = GetEggValue(egg.Obj.Name)
                    task.wait(Options.DelayTime.Value)
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
                    local hp = GetHomePos()
                    if hp then
                        DropAndGoHome(hp, TPEggVal)
                    end
                    MoveLock.Free("dip")
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
