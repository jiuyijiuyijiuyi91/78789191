local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/finendss/VowLibrary/refs/heads/main/WINDUI.lua"))()
if not WindUI then
	local sg = game:GetService("StarterGui")
	sg:SetCore("SendNotification", {Title = "偷蛋脚本", Text = "WindUI 加载失败，请检查网络", Duration = 8})
	return
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local ATTACK_RANGE = 200
local AUTO_INTERACT_RANGE = 12
local FALLBACK_SPEED = 16
local PICKUP_TRIGGER_INTERVAL = 0.03
local LINK_INTERACT_INTERVAL = 0.25

local function waitChild(parent, name, timeout)
	local t = 0
	while not parent:FindFirstChild(name) and t < timeout do
		t = t + 1
		task.wait(1)
	end
	return parent:FindFirstChild(name)
end

local function waitChildLoop(parent, name)
	local c = parent:FindFirstChild(name)
	while not c do
		task.wait(1)
		c = parent:FindFirstChild(name)
	end
	return c
end

local Event = waitChild(ReplicatedStorage, "EggHitRequest", 10)
if not Event then
	game:GetService("StarterGui"):SetCore("SendNotification", {Title = "偷蛋脚本", Text = "缺少对象: ReplicatedStorage.EggHitRequest", Duration = 8})
	return
end
local PET_RETURN_POS = Vector3.new(-78.811653, 3.498025, -21.007202)

local char = player.Character or player.CharacterAdded:Wait()
local humanoid = waitChildLoop(char, "Humanoid")
local hrp = waitChildLoop(char, "HumanoidRootPart")

local autoRun = false
local autoRunToggle = nil
local autoAttack = false
local antiAFK = false
local antiAFKTask = nil
local autoPickup = false
local autoInteract = false
local autoInteractLink = false
local autoInteractLinked = false
local AutoInteractToggle = nil
local autoUpgradeTreadmill = false
local autoUpgradePlot = false
local autoEquipBest = false
local autoHome = false
local interactLoopConn = nil
local petEspEnabled = false
local eggEspEnabled = false
local isLocked = false
local keepAliveConn = nil
local savedWalkSpeed = humanoid.WalkSpeed

local EGG_DATA = {
	{ en = "Swamp", cn = "沼泽蛋", weight = nil, rarity = "Common" },
	{ en = "Rock", cn = "岩石蛋", weight = 50, rarity = "Common" },
	{ en = "Forest", cn = "森林蛋", weight = 80, rarity = "Common" },
	{ en = "Cactus", cn = "仙人掌蛋", weight = 200, rarity = "Common" },
	{ en = "Bones", cn = "骨头蛋", weight = 300, rarity = "Uncommon" },
	{ en = "Scorpion", cn = "蝎子蛋", weight = 400, rarity = "Uncommon" },
	{ en = "Frozen", cn = "冰冻蛋", weight = 500, rarity = "Uncommon" },
	{ en = "Yeti", cn = "雪人蛋", weight = 800, rarity = "Uncommon" },
	{ en = "Easter Bunny", cn = "复活节兔子蛋", weight = 1500, rarity = "Rare" },
	{ en = "Candy", cn = "糖果蛋", weight = 2000, rarity = "Rare" },
	{ en = "Rainbow", cn = "彩虹蛋", weight = 2500, rarity = "Rare" },
	{ en = "Gooey", cn = "黏糊蛋", weight = 5000, rarity = "Rare" },
	{ en = "Tree", cn = "树蛋", weight = 7000, rarity = "Epic" },
	{ en = "Lake", cn = "湖蛋", weight = 9000, rarity = "Epic" },
	{ en = "Sea Stones", cn = "海洋石蛋", weight = 15000, rarity = "Epic" },
	{ en = "Water", cn = "水蛋", weight = 20000, rarity = "Epic" },
	{ en = "Sea", cn = "海洋蛋", weight = 25000, rarity = "Legendary" },
	{ en = "Fallen Angel", cn = "坠天使蛋", weight = 50000, rarity = "Legendary" },
	{ en = "Angel", cn = "天使蛋", weight = 70000, rarity = "Legendary" },
	{ en = "Volcanic", cn = "火山蛋", weight = 100000, rarity = "Legendary" },
	{ en = "Blossom", cn = "花朵蛋", weight = 200000, rarity = "Mythic" },
	{ en = "Bamboo", cn = "竹子蛋", weight = 300000, rarity = "Mythic" },
	{ en = "Fortune", cn = "财富蛋", weight = 500000, rarity = "Mythic" },
	{ en = "Sun", cn = "太阳蛋", weight = 1000000, rarity = "Divine" },
	{ en = "Starry", cn = "星空蛋", weight = 2000000, rarity = "Divine" },
	{ en = "Blackhole", cn = "黑洞蛋", weight = 5000000, rarity = "Cosmic" },
	{ en = "Plasma", cn = "等离子蛋", weight = 6000000, rarity = "Celestial" },
	{ en = "Nebula", cn = "星云蛋", weight = 7000000, rarity = "Celestial" },
	{ en = "Supernova", cn = "超新星蛋", weight = 8000000, rarity = "Celestial" },
}

local EGG_CN_TO_EN = {}
local EGG_WEIGHT_BY_CN = {}
local EGG_RARITY_BY_CN = {}
for _, e in ipairs(EGG_DATA) do
	EGG_CN_TO_EN[e.cn] = e.en
	EGG_WEIGHT_BY_CN[e.cn] = e.weight
	EGG_RARITY_BY_CN[e.cn] = e.rarity
end

table.sort(EGG_DATA, function(a, b) return (a.weight or 0) < (b.weight or 0) end)

local EGG_OPTIONS = {}
for _, e in ipairs(EGG_DATA) do
	table.insert(EGG_OPTIONS, e.cn)
end

local PET_DATA = {
	{ en = "Chicken", cn = "鸡", value = 1, rarity = "Common" },
	{ en = "Dog", cn = "狗", value = 1, rarity = "Common" },
	{ en = "Frog", cn = "青蛙", value = 1, rarity = "Common" },
	{ en = "Duckling", cn = "小鸭", value = 1, rarity = "Common" },
	{ en = "Jerboa", cn = "跳鼠", value = 1, rarity = "Common" },
	{ en = "Bird", cn = "鸟", value = 2, rarity = "Uncommon" },
	{ en = "Catfish", cn = "鲶鱼", value = 2, rarity = "Uncommon" },
	{ en = "Fennec", cn = "耳廓狐", value = 2, rarity = "Uncommon" },
	{ en = "Owl", cn = "猫头鹰", value = 3, rarity = "Rare" },
	{ en = "Raccoon", cn = "浣熊", value = 3, rarity = "Rare" },
	{ en = "Turtle", cn = "乌龟", value = 3, rarity = "Rare" },
	{ en = "Camel", cn = "骆驼", value = 3, rarity = "Rare" },
	{ en = "Penguin", cn = "企鹅", value = 3, rarity = "Rare" },
	{ en = "Chimpanzee", cn = "黑猩猩", value = 3, rarity = "Rare" },
	{ en = "Toucan", cn = "巨嘴鸟", value = 3, rarity = "Rare" },
	{ en = "Lava Gecko", cn = "熔岩壁虎", value = 3, rarity = "Rare" },
	{ en = "Parrotfish", cn = "鹦嘴鱼", value = 3, rarity = "Rare" },
	{ en = "Dodo", cn = "渡渡鸟", value = 3, rarity = "Rare" },
	{ en = "Tung Tung Sahur", cn = "唐唐萨胡尔", value = 3, rarity = "Rare" },
	{ en = "Fox", cn = "狐狸", value = 4, rarity = "Epic" },
	{ en = "Bear", cn = "熊", value = 4, rarity = "Epic" },
	{ en = "Swan", cn = "天鹅", value = 4, rarity = "Epic" },
	{ en = "Crocodile", cn = "鳄鱼", value = 4, rarity = "Epic" },
	{ en = "Trulimero Trulicina", cn = "翠丽梅罗", value = 4, rarity = "Epic" },
	{ en = "Tob Tobi Tob Tob", cn = "托比托比", value = 4, rarity = "Epic" },
	{ en = "Centapede", cn = "蜈蚣", value = 4, rarity = "Epic" },
	{ en = "Walrus", cn = "海象", value = 4, rarity = "Epic" },
	{ en = "Lava Frog", cn = "熔岩青蛙", value = 4, rarity = "Epic" },
	{ en = "Swordfish", cn = "剑鱼", value = 4, rarity = "Epic" },
	{ en = "Crane", cn = "鹤", value = 4, rarity = "Epic" },
	{ en = "Bananita Dolphinita", cn = "香蕉海豚", value = 4, rarity = "Epic" },
	{ en = "Axolotl", cn = "美西螈", value = 5, rarity = "Legendary" },
	{ en = "Snake", cn = "蛇", value = 5, rarity = "Legendary" },
	{ en = "Gorilla", cn = "大猩猩", value = 5, rarity = "Legendary" },
	{ en = "Orangutani Ananassini", cn = "猩猩菠萝", value = 5, rarity = "Legendary" },
	{ en = "Brr Brr Patapim", cn = "帕塔皮姆", value = 5, rarity = "Legendary" },
	{ en = "Polar Bear", cn = "北极熊", value = 5, rarity = "Legendary" },
	{ en = "Flaming Bull", cn = "烈焰公牛", value = 5, rarity = "Legendary" },
	{ en = "Lava Iguana", cn = "熔岩鬣蜥", value = 5, rarity = "Legendary" },
	{ en = "Shark", cn = "鲨鱼", value = 5, rarity = "Legendary" },
	{ en = "Pterodactyl", cn = "翼龙", value = 5, rarity = "Legendary" },
	{ en = "Cosmic Gecko", cn = "宇宙壁虎", value = 5, rarity = "Legendary" },
	{ en = "Salamander", cn = "蝾螈", value = 5, rarity = "Legendary" },
	{ en = "Crustacia", cn = "甲壳蟹", value = 5, rarity = "Legendary" },
	{ en = "Spideron", cn = "蛛龙", value = 5, rarity = "Legendary" },
	{ en = "Light Dove", cn = "光鸽", value = 5, rarity = "Legendary" },
	{ en = "Glyptodon", cn = "雕齿兽", value = 5, rarity = "Legendary" },
	{ en = "Spike", cn = "尖刺鱼", value = 5, rarity = "Legendary" },
	{ en = "Scorpio", cn = "天蝎怪", value = 5, rarity = "Legendary" },
	{ en = "Rift Eye", cn = "裂隙之眼", value = 5, rarity = "Legendary" },
	{ en = "Void Angler", cn = "虚空鮟鱇", value = 5, rarity = "Legendary" },
	{ en = "Sand Spider", cn = "沙蜘蛛", value = 6, rarity = "Mythic" },
	{ en = "Scorpion", cn = "蝎子", value = 6, rarity = "Mythic" },
	{ en = "Spider", cn = "蜘蛛", value = 6, rarity = "Mythic" },
	{ en = "Tiger", cn = "老虎", value = 6, rarity = "Mythic" },
	{ en = "Mammoth", cn = "猛犸象", value = 6, rarity = "Mythic" },
	{ en = "Sabertooth Tiger", cn = "剑齿虎", value = 6, rarity = "Mythic" },
	{ en = "Chillin Chilli", cn = "冰爽辣椒", value = 6, rarity = "Mythic" },
	{ en = "Orca", cn = "虎鲸", value = 6, rarity = "Mythic" },
	{ en = "Ankylosaurus", cn = "甲龙", value = 6, rarity = "Mythic" },
	{ en = "Cosmic Gorilla", cn = "宇宙猩猩", value = 6, rarity = "Mythic" },
	{ en = "Red Panda", cn = "小熊猫", value = 6, rarity = "Mythic" },
	{ en = "Bladehide", cn = "刃皮兽", value = 6, rarity = "Mythic" },
	{ en = "Winged Lamb", cn = "翼羊", value = 6, rarity = "Mythic" },
	{ en = "Terrorbird", cn = "恐鸟", value = 6, rarity = "Mythic" },
	{ en = "Spirit Manta", cn = "幽灵蝠鲼", value = 6, rarity = "Mythic" },
	{ en = "Froggo", cn = "蛙怪", value = 6, rarity = "Mythic" },
	{ en = "Voidmaw", cn = "虚空巨口", value = 6, rarity = "Mythic" },
	{ en = "Riftwing", cn = "裂隙翼龙", value = 6, rarity = "Mythic" },
	{ en = "Shardling", cn = "碎晶兽", value = 6, rarity = "Mythic" },
	{ en = "Belula Beluga", cn = "白鲸白鲸", value = 6, rarity = "Mythic" },
	{ en = "Leviathan", cn = "利维坦", value = 7, rarity = "Cosmic" },
	{ en = "Royal Sphinx", cn = "皇家狮身人面兽", value = 7, rarity = "Cosmic" },
	{ en = "King Mammoth", cn = "巨猛犸", value = 7, rarity = "Cosmic" },
	{ en = "Whale Shark", cn = "鲸鲨", value = 7, rarity = "Cosmic" },
	{ en = "Beluga Whale", cn = "白鲸", value = 7, rarity = "Cosmic" },
	{ en = "Bronto", cn = "雷龙", value = 7, rarity = "Cosmic" },
	{ en = "Triceratops", cn = "三角龙", value = 7, rarity = "Cosmic" },
	{ en = "La Vacca Saturno Saturnita", cn = "土星奶牛", value = 7, rarity = "Cosmic" },
	{ en = "Koi", cn = "锦鲤", value = 7, rarity = "Cosmic" },
	{ en = "Snowy Owl", cn = "雪鸮", value = 7, rarity = "Cosmic" },
	{ en = "Mantaris", cn = "螳螂兽", value = 7, rarity = "Cosmic" },
	{ en = "Rhinotaur", cn = "犀牛人", value = 7, rarity = "Cosmic" },
	{ en = "Sacred Moth", cn = "圣蛾", value = 7, rarity = "Cosmic" },
	{ en = "Holy Peacock", cn = "圣孔雀", value = 7, rarity = "Cosmic" },
	{ en = "Giant Sloth", cn = "巨型树懒", value = 7, rarity = "Cosmic" },
	{ en = "Abyss Shark", cn = "深渊鲨鱼", value = 7, rarity = "Cosmic" },
	{ en = "Crawler", cn = "爬行者", value = 7, rarity = "Cosmic" },
	{ en = "Ventinal", cn = "通风魔", value = 7, rarity = "Cosmic" },
	{ en = "Dreadclaw", cn = "惧爪兽", value = 7, rarity = "Cosmic" },
	{ en = "Shattered Ram", cn = "碎晶公羊", value = 7, rarity = "Cosmic" },
	{ en = "Mangolini Parrochini", cn = "芒果鹦鹉", value = 7, rarity = "Cosmic" },
	{ en = "King Snake", cn = "蛇王", value = 8, rarity = "Secret" },
	{ en = "Yeti", cn = "雪人", value = 8, rarity = "Secret" },
	{ en = "Cerberus", cn = "地狱三头犬", value = 8, rarity = "Secret" },
	{ en = "Kraken", cn = "海怪", value = 8, rarity = "Secret" },
	{ en = "T-Rex", cn = "霸王龙", value = 8, rarity = "Secret" },
	{ en = "Tralaledon", cn = "特拉拉雷顿", value = 8, rarity = "Secret" },
	{ en = "Cosmic Dragon", cn = "宇宙龙", value = 8, rarity = "Secret" },
	{ en = "Cosmic Skeleton Boss", cn = "宇宙骷髅王", value = 8, rarity = "Secret" },
	{ en = "Stag", cn = "雄鹿", value = 8, rarity = "Secret" },
	{ en = "Mutant Shark", cn = "变异鲨鱼", value = 8, rarity = "Secret" },
	{ en = "Pure Jellyfish", cn = "纯洁水母", value = 8, rarity = "Secret" },
	{ en = "Centaur", cn = "半人马", value = 8, rarity = "Secret" },
	{ en = "Dunkleosteus", cn = "邓氏鱼", value = 8, rarity = "Secret" },
	{ en = "Electric Eel", cn = "电鳗", value = 8, rarity = "Secret" },
	{ en = "Crocodon", cn = "鳄龙", value = 8, rarity = "Secret" },
	{ en = "Wendigo", cn = "温迪戈", value = 8, rarity = "Secret" },
	{ en = "Mawbreaker", cn = "巨口粉碎者", value = 8, rarity = "Secret" },
	{ en = "Shardwing", cn = "碎晶翼", value = 8, rarity = "Secret" },
	{ en = "Bomboclat Crocolat", cn = "炸弹鳄", value = 8, rarity = "Secret" },
	{ en = "Ice Dragon", cn = "冰龙", value = 9, rarity = "Eternal" },
	{ en = "Phoenix", cn = "凤凰", value = 9, rarity = "Eternal" },
	{ en = "Lava Dragon", cn = "熔岩龙", value = 9, rarity = "Eternal" },
	{ en = "El Maja", cn = "埃尔马哈", value = 9, rarity = "Eternal" },
	{ en = "Mosasaurus", cn = "沧龙", value = 9, rarity = "Eternal" },
	{ en = "Eternal Lunar Dragon", cn = "永恒月龙", value = 9, rarity = "Eternal" },
	{ en = "Oni Tiger", cn = "鬼虎", value = 9, rarity = "Eternal" },
	{ en = "Gorilla King", cn = "猩猩王", value = 9, rarity = "Eternal" },
	{ en = "Pegasus", cn = "天马", value = 9, rarity = "Eternal" },
	{ en = "Gigantus", cn = "巨兽", value = 9, rarity = "Eternal" },
	{ en = "Terra Snapper", cn = "大地巨龟", value = 9, rarity = "Eternal" },
	{ en = "Krakenoid", cn = "克拉肯兽", value = 9, rarity = "Eternal" },
	{ en = "World Eater", cn = "吞世者", value = 9, rarity = "Eternal" },
	{ en = "Void Serpent", cn = "虚空巨蛇", value = 9, rarity = "Eternal" },
	{ en = "Shattered Drake", cn = "碎晶龙", value = 9, rarity = "Eternal" },
	{ en = "Strawberry Elephant", cn = "草莓大象", value = 9, rarity = "Eternal" },
	{ en = "Unicorn", cn = "独角兽", value = 10, rarity = "Divine" },
	{ en = "Kitsune", cn = "九尾狐", value = 10, rarity = "Divine" },
	{ en = "Nightflame", cn = "夜焰", value = 10, rarity = "Divine" },
	{ en = "ArchAngel", cn = "大天使", value = 10, rarity = "Divine" },
	{ en = "Sabertooth", cn = "剑齿兽", value = 10, rarity = "Divine" },
	{ en = "Cthulhu", cn = "克苏鲁", value = 10, rarity = "Divine" },
	{ en = "Dreadscale", cn = "惧鳞", value = 10, rarity = "Divine" },
	{ en = "Shattered Colossus", cn = "碎晶巨像", value = 10, rarity = "Divine" },
	{ en = "Eye Bat #021", cn = "眼蝠", value = 5, rarity = "Legendary" },
	{ en = "Flame Sprite", cn = "火焰精灵", value = 5, rarity = "Legendary" },
	{ en = "Toro", cn = "托罗牛", value = 6, rarity = "Mythic" },
	{ en = "Citadel Snail #007", cn = "城堡蜗牛", value = 6, rarity = "Mythic" },
	{ en = "Toxic Rat", cn = "毒鼠", value = 6, rarity = "Mythic" },
	{ en = "Imp", cn = "小恶魔", value = 7, rarity = "Cosmic" },
	{ en = "Demon Hound", cn = "恶魔猎犬", value = 7, rarity = "Cosmic" },
	{ en = "Abyss Shark", cn = "深渊鲨鱼", value = 7, rarity = "Cosmic" },
	{ en = "Mecha Crawler", cn = "机械爬行者", value = 7, rarity = "Cosmic" },
	{ en = "Gargoyle", cn = "石像鬼", value = 8, rarity = "Secret" },
	{ en = "RazorFang", cn = "剃刀牙", value = 8, rarity = "Secret" },
	{ en = "Abyss Overlord", cn = "深渊领主", value = 8, rarity = "Secret" },
	{ en = "Mecha Scorpio", cn = "机械天蝎怪", value = 8, rarity = "Secret" },
	{ en = "Mecha Froggo", cn = "机械蛙怪", value = 8, rarity = "Secret" },
	{ en = "Skeleton Horse", cn = "骷髅马", value = 9, rarity = "Eternal" },
	{ en = "Equinox", cn = "分点兽", value = 9, rarity = "Eternal" },
	{ en = "Mecha Crocodon", cn = "机械鳄龙", value = 9, rarity = "Eternal" },
	{ en = "Mecha Krakenoid", cn = "机械克拉肯兽", value = 9, rarity = "Eternal" },
	{ en = "World Burner", cn = "焚世者", value = 10, rarity = "Divine" },
	{ en = "Mecha Dreadscale", cn = "机械惧鳞", value = 10, rarity = "Divine" },
	{ en = "Cutefish", cn = "鱿鱼", value = 2, rarity = "Common" },
	{ en = "Dimetrodon", cn = "迪米特罗顿", value = 2, rarity = "Common" },
	{ en = "Brachiosaurus", cn = "梁恐龙", value = 2, rarity = "Common" },
	{ en = "Jackalope", cn = "泽卡洛普", value = 4, rarity = "Epic" },
	{ en = "Lindworm", cn = "巨翼地龙", value = 10, rarity = "Divine" },
}

local PET_NAME_CN = {}
local PET_RARITY_CN = {}
local PET_CN_TO_EN = {}
for _, p in ipairs(PET_DATA) do
	PET_NAME_CN[p.en] = p.cn
	PET_RARITY_CN[p.cn] = p.rarity
	PET_CN_TO_EN[p.cn] = p.en
end

table.sort(PET_DATA, function(a, b) return a.value < b.value end)

local RARITY_CN = {
	Common = "普通", Uncommon = "罕见", Rare = "稀有", Epic = "史诗",
	Legendary = "传说", Mythic = "神话", Mythical = "神话", Divine = "神圣",
	Cosmic = "宇宙", Secret = "秘密", Eternal = "永恒",
	HUGE = "巨大", Huge = "巨大", TITANIC = "泰坦", Titanic = "泰坦",
	Celestial = "天界", Hell = "地狱",
	Void = "虚空", Omega = "欧米伽",
}

local RARITY_COLOR = {
	Common = "#FFFFFF", Uncommon = "#00FF00", Rare = "#00BFFF",
	Epic = "#A020F0", Legendary = "#FFD700", Mythic = "#FF69B4",
	Mythical = "#FF69B4", Divine = "#FFA500", Cosmic = "#8A2BE2",
	Secret = "#FF4500", Eternal = "#00FFFF",
	HUGE = "#FF1493", Huge = "#FF1493", TITANIC = "#FF0000", Titanic = "#FF0000",
	Celestial = "#FFE066", Hell = "#B22222",
	Void = "#4B0082", Omega = "#FF8C00",
}

local PET_RARITY_OPTIONS = { "普通", "罕见", "稀有", "史诗", "传说", "神话", "宇宙", "秘密", "永恒", "神圣", "天界", "地狱", "虚空", "欧米伽" }

local selectedEggEnglish = {}
local selectedPetRarities = {}

local petEspFilter = {}
local eggEspFilter = {}

local function updateSavedSpeed()
	if humanoid and humanoid.Parent and humanoid.WalkSpeed > 0 then
		savedWalkSpeed = humanoid.WalkSpeed
	end
end

local function getCurrentSpeed()
	if humanoid and humanoid.Parent and humanoid.WalkSpeed > 0 then
		savedWalkSpeed = humanoid.WalkSpeed
	end
	local spd = savedWalkSpeed
	if spd <= 0 then spd = FALLBACK_SPEED end
	return spd
end

local function getGroundY(pos, upOnly)

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { char }
	local ray = workspace:Raycast(pos + Vector3.new(0, 4, 0), Vector3.new(0, -400, 0), rp)
	if ray and ray.Instance then
		if upOnly and ray.Normal.Y < 0.1 then
			return nil
		end
		return ray.Position.Y
	end
	return nil
end

local lockUtil = {}

lockUtil.navAvoid = true

lockUtil.lowestY = function()
	if not char or not char.Parent then return nil end
	local low, any = nil, nil
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			local bottom = part.Position.Y - part.Size.Y * 0.5
			if not any or bottom < any then any = bottom end
			local n = part.Name
			if n == "LeftFoot" or n == "RightFoot" or n == "LeftLowerLeg" or n == "RightLowerLeg"
				or n == "LeftUpperLeg" or n == "RightUpperLeg" or n == "Torso"
				or n == "LowerTorso" or n == "UpperTorso" or n == "HumanoidRootPart" then
				if not low or bottom < low then low = bottom end
			end
		end
	end
	return low or any
end

lockUtil.placeHover = function(x, z, baseY, h)
	if not char or not char.Parent then return nil end
	if not char:FindFirstChild("HumanoidRootPart") then return nil end
	pcall(function()
		local pv = char:GetPivot()
		local _, yaw = pv:ToEulerAnglesYXZ()
		char:PivotTo(CFrame.new(x, pv.Position.Y, z) * CFrame.Angles(0, yaw, 0))
	end)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") then
			pcall(function() d.Transform = CFrame.new() end)
		end
	end
	pcall(function() RunService.Heartbeat:Wait() end)
	local low = lockUtil.lowestY()
	if not low then return nil end
	local dy = (baseY + h) - low
	pcall(function()
		char:PivotTo(char:GetPivot() + Vector3.new(0, dy, 0))
	end)
	return dy
end

local function lockCharacter()
	if not char or not char.Parent then return end
	updateSavedSpeed()
	isLocked = true
	if humanoid and humanoid.Parent then
		humanoid.PlatformStand = true
		humanoid.JumpPower = 0
	end
	local anchorY = nil
	local h0 = char:FindFirstChild("HumanoidRootPart")
	if h0 then
		anchorY = h0.Position.Y
		local gY = getGroundY(h0.Position, true)
		if gY then
			local low = lockUtil.lowestY()
			if low and low < gY + 2 then
				local up = (gY + 2) - low
				pcall(function() h0.CFrame = h0.CFrame + Vector3.new(0, up, 0) end)
				anchorY = anchorY + up
			elseif anchorY - gY > 12 then
				anchorY = gY + 4
			end
		end
	end
	if keepAliveConn then keepAliveConn:Disconnect() end
	keepAliveConn = RunService.Heartbeat:Connect(function()
		if not isLocked then return end
		if not char or not char.Parent then return end
		local h = char:FindFirstChild("HumanoidRootPart")
		if h then
			h.AssemblyLinearVelocity = Vector3.zero
			h.AssemblyAngularVelocity = Vector3.zero
			if anchorY then
				local p = h.Position
				if math.abs(p.Y - anchorY) > 0.02 then

					h.CFrame = h.CFrame * CFrame.new(0, anchorY - p.Y, 0)
				end
			end
		end
	end)
end

local function unlockCharacter()
	isLocked = false
	if keepAliveConn then
		keepAliveConn:Disconnect()
		keepAliveConn = nil
	end
	if not char or not char.Parent then return end
	if humanoid and humanoid.Parent then
		humanoid.PlatformStand = false
		humanoid.JumpPower = 50
		pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
	end
end

player.CharacterAdded:Connect(function(newChar)
	char = newChar
	humanoid = waitChildLoop(newChar, "Humanoid")
	hrp = waitChildLoop(newChar, "HumanoidRootPart")
	task.wait(0.3)
	updateSavedSpeed()
	isLocked = false
	if keepAliveConn then
		keepAliveConn:Disconnect()
		keepAliveConn = nil
	end
end)

local function getEggPart(obj)
	local eggPart = obj:FindFirstChild("Egg")
	if eggPart then
		if eggPart:IsA("BasePart") then return eggPart end
		if eggPart:IsA("Model") then
			return eggPart.PrimaryPart or eggPart:FindFirstChildWhichIsA("BasePart")
		end
	end
	if obj:IsA("BasePart") then return obj end
	if obj:IsA("Model") then
		return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function getAllZones()
	local list = {}
	local zoneBuilds = workspace.Build and workspace.Build:FindFirstChild("ZoneBuilds")
	if not zoneBuilds then return list end
	for _, zone in ipairs(zoneBuilds:GetChildren()) do
		table.insert(list, zone)
	end
	return list
end


lockUtil.zoneBoxCache = {}

lockUtil.zoneBox = function(zone)
	if lockUtil.zoneBoxCache[zone] ~= nil then return lockUtil.zoneBoxCache[zone] end
	local res = false
	pcall(function()
		local cf, size = zone:GetBoundingBox()
		res = { cf = cf, size = size, vol = size.X * size.Y * size.Z }
	end)
	lockUtil.zoneBoxCache[zone] = res
	return res
end

lockUtil.zonePivotPos = function(zone)
	local ok, p = pcall(function() return zone:GetPivot().Position end)
	if ok then return p end
	return nil
end

lockUtil.zoneOfPoint = function(pos)
	local best, bestD, bestVol, bestC = nil, nil, nil, nil
	for _, zone in ipairs(getAllZones()) do
		if zone.Parent then
			local box = lockUtil.zoneBox(zone)
			local pv = lockUtil.zonePivotPos(zone)
			local cd = pv and (pv - pos).Magnitude or math.huge
			local d, vol
			if box then
				local rel = box.cf:PointToObjectSpace(pos)
				local dx = math.max(0, math.abs(rel.X) - box.size.X / 2)
				local dy = math.max(0, math.abs(rel.Y) - box.size.Y / 2)
				local dz = math.max(0, math.abs(rel.Z) - box.size.Z / 2)
				d = math.sqrt(dx * dx + dy * dy + dz * dz)
				vol = box.vol
			else
				d, vol = cd, math.huge
			end
			local better = false
			if not best then
				better = true
			elseif d < bestD - 0.01 then
				better = true
			elseif math.abs(d - bestD) <= 0.01 then
				if vol < bestVol - 0.001 then
					better = true
				elseif math.abs(vol - bestVol) <= 0.001 and cd < bestC then
					better = true
				end
			end
			if better then best, bestD, bestVol, bestC = zone, d, vol, cd end
		end
	end
	return best, bestD
end

local function collectGuardsFromZone(zone, guards, allGuards)
	for _, desc in ipairs(zone:GetDescendants()) do
		if desc:IsA("Model") and not desc:IsA("Folder") then
			local nm = string.lower(tostring(desc.Name))
			if not string.find(nm, "egg", 1, true) then
				local hasHum = desc:FindFirstChildOfClass("Humanoid") ~= nil or desc:FindFirstChildWhichIsA("Humanoid", true) ~= nil
				local posPart = desc:FindFirstChild("HumanoidRootPart") or desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart")
				if posPart then
					local item = { model = desc, part = posPart, humanoid = hasHum }
					if allGuards then table.insert(allGuards, item) end
					if hasHum or string.find(nm, "guard", 1, true) then
						table.insert(guards, item)
					end
				end
			end
		end
	end
end

local function getZoneGuardList(zone)
	local all = {}
	local zoneBuilds = workspace.Build and workspace.Build:FindFirstChild("ZoneBuilds")
	if not zoneBuilds then return {} end
	local now = os.clock()
	local cache = lockUtil.guardScanCache
	if not cache then
		cache = { t = 0, all = {} }
		lockUtil.guardScanCache = cache
	end
	if #cache.all == 0 or now - cache.t > 3 then
		local fresh = {}
		for _, z in ipairs(zoneBuilds:GetChildren()) do
			local tmp = {}
			collectGuardsFromZone(z, tmp, fresh)
		end
		cache.all = fresh
		cache.t = now
	end
	for _, g in ipairs(cache.all) do
		if g.model.Parent then table.insert(all, g) end
	end
	local function zoneOwner(m)
		local node = m
		while node and node.Parent do
			if node.Parent == zoneBuilds then return node end
			node = node.Parent
		end
		return nil
	end
	local function isGuard(g)
		if g.humanoid then return true end
		return string.find(string.lower(tostring(g.model.Name)), "guard", 1, true) ~= nil
	end
	local zoneGuards, zoneAll, globalGuards = {}, {}, {}
	local tgt = (zone and zone.Parent) and zone or nil
	for _, g in ipairs(all) do
		if isGuard(g) then table.insert(globalGuards, g) end
		if tgt then
			local byTree = zoneOwner(g.model)
			local byPos = lockUtil.zoneOfPoint and lockUtil.zoneOfPoint(g.part.Position)
			if not byPos then byPos = byTree end
			if byTree == tgt or byPos == tgt then
				table.insert(zoneAll, g)
				if isGuard(g) then table.insert(zoneGuards, g) end
			end
		end
	end
	if #zoneGuards > 0 then return zoneGuards end
	if #zoneAll > 0 then return zoneAll end
	if #globalGuards > 0 then return globalGuards end
	return all
end

local function findNearestGuard(fromPos, zone)
	local best, bestDist = nil, math.huge
	for _, g in ipairs(getZoneGuardList(zone)) do
		local d = (g.part.Position - fromPos).Magnitude
		if d < bestDist then best, bestDist = g, d end
	end
	return best, bestDist
end

local function petGone(pet, fromPickup)
	if not pet or not pet.Parent then return true end
	if fromPickup then
		local folder = workspace:FindFirstChild("AnimalPickups")
		if folder and pet.Parent ~= folder then return true end
	end
	return false
end

lockUtil.navService = function()
	if lockUtil.navSvc == nil then
		local ok, svc = pcall(function() return game:GetService("PathfindingService") end)
		if ok and svc then
			lockUtil.navSvc = svc
		else
			lockUtil.navSvc = false
		end
	end
	if lockUtil.navSvc == false then return nil end
	return lockUtil.navSvc
end

lockUtil.navPath = function(fromPos, goalPos)
	if lockUtil.navAvoid == false then return nil end
	local svc = lockUtil.navService()
	if not svc then return nil end
	local list = nil
	pcall(function()
		local path = svc:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentMaxSlope = 89, WaypointSpacing = 4 })
		path:ComputeAsync(fromPos, goalPos)
		if path.Status == Enum.PathStatus.Success then
			local wps = path:GetWaypoints()
			if wps and #wps >= 2 then
				local out = {}
				for i = 2, #wps do
					table.insert(out, wps[i].Position)
				end
				if #out > 0 then list = out end
			end
		end
	end)
	return list
end

lockUtil.navJump = function()
	if humanoid and humanoid.Parent and humanoid.Health > 0 then
		pcall(function()
			if humanoid.JumpPower and humanoid.JumpPower < 50 then humanoid.JumpPower = 50 end
			humanoid.Jump = true
		end)
	end
end

lockUtil.navStep = function(dirWorld, duration, spd)
	if not dirWorld then return end
	if dirWorld.Magnitude < 0.01 then return end
	local unit = dirWorld.Unit
	local cam = workspace.CurrentCamera
	local camCF = cam and cam.CFrame
	local mDir = camCF and camCF:VectorToObjectSpace(unit) or unit
	local t = 0
	while t < duration do
		if humanoid and humanoid.Parent then
			pcall(function()
				if spd and humanoid.WalkSpeed < spd then humanoid.WalkSpeed = spd end
				humanoid:Move(mDir, true)
			end)
		end
		t += RunService.RenderStepped:Wait()
	end
end

lockUtil.navWalk = function(targetPos, arriveDist, opts)
	if not char or not char.Parent then return "stop" end
	opts = opts or {}
	arriveDist = arriveDist or 2
	local maxTime = opts.maxTime or 60
	if keepAliveConn then
		keepAliveConn:Disconnect()
		keepAliveConn = nil
	end
	local baseSpd = getCurrentSpeed()
	if baseSpd < 1 then baseSpd = 1 end
	local boostSpd = baseSpd
	if boostSpd < 16 then boostSpd = 16 end
	local function restoreSpd()
		if humanoid and humanoid.Parent then
			pcall(function() humanoid.WalkSpeed = baseSpd end)
		end
	end
	if humanoid and humanoid.Parent then
		pcall(function()
			humanoid.PlatformStand = false
			humanoid.JumpPower = 50
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
	local startPos = char:GetPivot().Position
	local goal = Vector3.new(targetPos.X, startPos.Y, targetPos.Z)
	local wps = nil
	local wi = 1
	if (Vector3.new(goal.X - startPos.X, 0, goal.Z - startPos.Z)).Magnitude > 14 then
		wps = lockUtil.navPath(startPos, goal)
	end
	local elapsed = 0
	local lastPos = startPos
	local stallT = 0
	local stuckN = 0
	local repathN = 0
	local result = "timeout"
	while elapsed < maxTime do
		if opts.cancel and opts.cancel() then result = "stop" break end
		pcall(function()
			if keepAliveConn then
				keepAliveConn:Disconnect()
				keepAliveConn = nil
			end
			if humanoid and humanoid.Parent then
				humanoid.PlatformStand = false
				humanoid.JumpPower = 50
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
		end)
		local curHrp = char:FindFirstChild("HumanoidRootPart")
		if not curHrp then result = "stop" break end
		local curPos = curHrp.Position
		local remain = (Vector3.new(goal.X - curPos.X, 0, goal.Z - curPos.Z)).Magnitude
		if remain < arriveDist then result = "arrive" break end
		if wps then
			while wps and wi <= #wps and (Vector3.new(wps[wi].X - curPos.X, 0, wps[wi].Z - curPos.Z)).Magnitude < 4 do
				wi += 1
				stuckN = 0
			end
			if wi > #wps then wps = nil end
		end
		local legend = goal
		if wps and wps[wi] then legend = Vector3.new(wps[wi].X, curPos.Y, wps[wi].Z) end
		local dir = Vector3.new(legend.X - curPos.X, 0, legend.Z - curPos.Z)
		local toGoal = dir.Unit
		local cam = workspace.CurrentCamera
		local camCF = cam and cam.CFrame
		local camDir = camCF and camCF:VectorToObjectSpace(toGoal) or toGoal
		if opts.brake then
			local brakeD = baseSpd * 0.15
			if brakeD < 3 then brakeD = 3 end
			local useSpd = baseSpd
			if remain < brakeD then
				useSpd = remain * 8
				if useSpd < 2 then useSpd = 2 end
				if useSpd > baseSpd then useSpd = baseSpd end
			end
			if humanoid and humanoid.Parent and math.abs(humanoid.WalkSpeed - useSpd) > 0.1 then
				pcall(function() humanoid.WalkSpeed = useSpd end)
			end
		end
		pcall(function() humanoid:Move(camDir, true) end)
		local dt = RunService.RenderStepped:Wait()
		elapsed += dt
		local moved = (curHrp.Position - lastPos).Magnitude
		lastPos = curHrp.Position
		if moved < 0.05 then
			stallT += dt
			if stallT > 0.4 then
				stallT = 0
				stuckN += 1
				if stuckN > 10 then result = "stuck" break end
				lockUtil.navJump()
				local gdir = Vector3.new(goal.X - curHrp.Position.X, 0, goal.Z - curHrp.Position.Z)
				if gdir.Magnitude < 0.1 then gdir = toGoal end
				gdir = gdir.Unit
				local side = 1
				if math.floor((stuckN - 1) / 2) % 2 == 1 then side = -1 end
				local perp = Vector3.new(-gdir.Z, 0, gdir.X) * side
				local fwd = 0.15
				if stuckN == 1 then fwd = 0.4 end
				lockUtil.navStep((gdir * fwd + perp).Unit, 0.5, boostSpd)
				if (stuckN == 2 or stuckN == 5 or stuckN == 8) and repathN < 3 and remain > 6 then
					repathN += 1
					local np = lockUtil.navPath(curHrp.Position, goal)
					if np then
						wps = np
						wi = 1
					end
				end
			end
		else
			stallT = 0
		end
	end
	pcall(function() humanoid:Move(Vector3.zero, true) end)
	restoreSpd()
	return result
end

lockUtil.tapSlot1Btn = nil
lockUtil.tapSlot1Miss = 0
lockUtil.tapSlot1Last = 0
lockUtil.tapSlot1Button = function()
	local nowT = os.clock()
	if nowT - lockUtil.tapSlot1Last < 0.15 then return end
	lockUtil.tapSlot1Last = nowT
	local btn = lockUtil.tapSlot1Btn
	if btn == nil or not btn.Parent then
		if lockUtil.tapSlot1Miss > 0 then
			lockUtil.tapSlot1Miss -= 1
			return
		end
		pcall(function()
			btn = game:GetService("Players").LocalPlayer.PlayerGui.MobileScatchel.HotBarUi.BottomHUD["1"]
		end)
		if btn == nil then
			lockUtil.tapSlot1Miss = 60
			return
		end
		lockUtil.tapSlot1Btn = btn
	end
	local target = btn
	if not btn:IsA("GuiButton") then
		local child = btn:FindFirstChildWhichIsA("GuiButton", true)
		if child then target = child end
	end
	local fired = 0
	local function TryFire(sig)
		if sig == nil then return end
		local okc, conns = pcall(getconnections, sig)
		if okc and type(conns) == "table" then
			for _, cn in ipairs(conns) do
				pcall(function() cn:Fire() end)
				fired += 1
			end
		end
	end
	pcall(function()
		TryFire(target.MouseButton1Click)
		TryFire(target.MouseButton1Down)
		TryFire(target.Activated)
	end)
	if fired > 0 then return end
	pcall(function()
		if target:IsA("GuiButton") then target:Click() end
		for _, d in ipairs(target:GetDescendants()) do
			if d:IsA("GuiButton") then d:Click() end
		end
	end)
	pcall(function()
		local vim = game:GetService("VirtualInputManager")
		local pos = target.AbsolutePosition + target.AbsoluteSize * 0.5
		vim:SendMouseMoveEvent(pos.X, pos.Y, 0)
		vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, Enum.UserInputType.MouseButton1, false)
		vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, Enum.UserInputType.MouseButton1, false)
	end)
	pcall(function()
		local vim = game:GetService("VirtualInputManager")
		local pos = target.AbsolutePosition + target.AbsoluteSize * 0.5
		vim:SendTouchEvent(1, Vector2.new(pos.X, pos.Y), Enum.TouchState.Began, false)
		vim:SendTouchEvent(1, Vector2.new(pos.X, pos.Y), Enum.TouchState.Ended, false)
	end)
end

local function panTo(targetPos, arriveDist, watchObj)
	if not autoRun and not autoPickup then return false end
	local function cancel()
		if not autoRun and not autoPickup then return true end
		if watchObj and petGone(watchObj) then return true end
		return false
	end
	local r = lockUtil.navWalk(targetPos, arriveDist, { brake = true, cancel = cancel })
	return r == "arrive"
end

local function waitOrStop(t)
	local elapsed = 0
	while elapsed < t do
		if not autoRun and not autoPickup then return false end
		local dt = RunService.Heartbeat:Wait()
		elapsed += dt
	end
	return true
end

local function attackEgg(eggPart)
	if not eggPart or not eggPart.Parent then return end
	lockUtil.tapSlot1Button()
	Event:FireServer(eggPart, 1)
end

local function getEggHealth(obj)
	local hp = nil
	pcall(function()
		local candidates = {}
		local attrs = obj:GetAttributes()
		for name, value in pairs(attrs) do
			local num = tonumber(value)
			if num then table.insert(candidates, { name = string.lower(name), value = num }) end
		end
		for _, d in ipairs(obj:GetDescendants()) do
			if d:IsA("IntValue") or d:IsA("NumberValue") then
				local num = tonumber(d.Value)
				if num then table.insert(candidates, { name = string.lower(d.Name), value = num }) end
			end
			local dAttrs = d:GetAttributes()
			for name, value in pairs(dAttrs) do
				local num = tonumber(value)
				if num then table.insert(candidates, { name = string.lower(name), value = num }) end
			end
		end
		local exact = { "health", "hp", "血量", "血", "currhealth", "currenthealth", "currenthp", "curhp", "hitpoints", "hitpoint" }
		for _, c in ipairs(candidates) do
			for _, k in ipairs(exact) do
				if c.name == k then hp = c.value end
			end
		end
		if hp == nil then
			for _, c in ipairs(candidates) do
				local n = c.name
				if string.find(n, "health", 1, true) or string.find(n, "hp", 1, true) or string.find(n, "血量", 1, true) or string.find(n, "hitpoint", 1, true) then
					if not string.find(n, "max", 1, true) and not string.find(n, "weight", 1, true) and not string.find(n, "mass", 1, true) and not string.find(n, "price", 1, true) and not string.find(n, "cost", 1, true) and not string.find(n, "luck", 1, true) and not string.find(n, "幸运", 1, true) then
						hp = c.value
						break
					end
				end
			end
		end
	end)
	return hp
end

local PET_PREFIX_WORDS = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Mythical", "Cosmic", "Secret", "Eternal", "Divine", "HUGE", "Huge", "TITANIC", "Titanic", "Fortune", "Lucky", "Gold", "Sun", "Solar", "Starry", "Star", "Blackhole", "BlackHole", "Volcanic", "Lava", "Blossom", "Flower", "Bamboo", "Angel", "Holy", "Fallen", "FallenAngel", "Rift", "Void", "Celestial", "Omega", "Sea", "Ocean", "Lake", "Frozen", "Ice", "Snow", "Yeti", "Rainbow", "Candy", "Tree", "Wood", "Rock", "Stone", "Forest", "Cactus", "Desert", "Bones", "Bone", "Skeleton", "Scorpion", "Easter", "Gooey", "Slime", "Sticky", "Swamp", "Water", "Aqua" }

PET_PREFIX_WORDS.cn = { "普通", "罕见", "稀有", "史诗", "传说", "神话", "宇宙", "秘密", "永恒", "神圣", "巨大", "泰坦", "天界", "虚空", "欧米伽" }

local function stripNamePrefix(raw)
	if not raw then return raw end
	local out = raw
	local lower = string.lower(out)
	for _, w in ipairs(PET_PREFIX_WORDS) do
		local lw = string.lower(w)
		if string.sub(lower, 1, #lw) == lw then
			out = string.sub(out, #lw + 1)
			out = string.gsub(out, "^[%s_%-]+", "")
			lower = string.lower(out)
			break
		end
	end
	for _, cn in ipairs(PET_PREFIX_WORDS.cn) do
		if string.sub(out, 1, #cn) == cn then
			out = string.sub(out, #cn + 1)
			out = string.gsub(out, "^[%s_%-]+", "")
			break
		end
	end
	return out
end

local function normalizePetName(raw)
	if not raw then return nil end
	local lower = string.lower(raw)

	for en, cn in pairs(PET_NAME_CN) do
		if string.lower(en) == lower then
			return cn
		end
	end

	local bestMatch = nil
	local bestLen = 0
	for keyword, cn in pairs(PET_NAME_CN) do
		local kl = string.lower(keyword)
		if string.find(lower, kl, 1, true) then
			if #kl > bestLen then
				bestLen = #kl
				bestMatch = cn
			end
		end
	end
	if bestMatch then return bestMatch end

	local stripped = stripNamePrefix(raw)
	if stripped and #stripped > 0 then return stripped end

	return nil
end

local RARITY_WORDS = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Mythical", "Cosmic", "Secret", "Eternal", "Divine", "HUGE", "Huge", "TITANIC", "Titanic", "Celestial", "Heaven", "Heavenly", "Hell", "Hades", "Infernal", "Inferno", "Underworld", "Nether", "Void", "Omega" }

local RARITY_ALIAS_EN = {
	Mythical = "Mythic", Heaven = "Celestial", Heavenly = "Celestial",
	Hades = "Hell", Infernal = "Hell", Inferno = "Hell", Underworld = "Hell", Nether = "Hell",
}

local RARITY_CN_TO_EN = {
	["普通"] = "Common", ["罕见"] = "Uncommon", ["稀有"] = "Rare",
	["史诗"] = "Epic", ["传说"] = "Legendary", ["神话"] = "Mythic",
	["宇宙"] = "Cosmic", ["秘密"] = "Secret", ["永恒"] = "Eternal",
	["神圣"] = "Divine", ["天界"] = "Celestial", ["地狱"] = "Hell",
	["虚空"] = "Void", ["欧米伽"] = "Omega",
}

local function extractRarityFromName(raw)
	if not raw then return nil end
	for cn, en in pairs(RARITY_CN_TO_EN) do
		if string.find(raw, cn, 1, true) then
			return en
		end
	end
	local lower = string.lower(raw)
	for _, w in ipairs(RARITY_WORDS) do
		if string.find(lower, string.lower(w), 1, true) then
			return RARITY_ALIAS_EN[w] or w
		end
	end
	return nil
end

local RARITY_ATTR_KEYWORDS = { "rarity", "quality", "tier", "rank", "grade", "rare", "稀有", "品质", "阶级" }

local function scanRarityFromAttributes(obj)
	if not obj then return nil end
	local function tryValue(name, value)
		for _, kw in ipairs(RARITY_ATTR_KEYWORDS) do
			if string.find(string.lower(name), kw, 1, true) then
				local r = extractRarityFromName(tostring(value))
				if r then return r end
			end
		end
		return nil
	end
	local attrs = obj:GetAttributes()
	for name, value in pairs(attrs) do
		local r = tryValue(name, value)
		if r then return r end
	end
	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("StringValue") or d:IsA("IntValue") or d:IsA("NumberValue") or d:IsA("BoolValue") then
			local r = tryValue(d.Name, d.Value)
			if r then return r end
		end
		local dAttrs = d:GetAttributes()
		for name, value in pairs(dAttrs) do
			local r = tryValue(name, value)
			if r then return r end
		end
	end
	return nil
end

local function getDisplayRarity(obj)
	if not obj then return nil end
	local fromAttr = scanRarityFromAttributes(obj)
	if fromAttr then return fromAttr end
	local fromName = extractRarityFromName(obj.Name)
	if fromName then return fromName end
	for _, d in ipairs(obj:GetDescendants()) do
		local r = extractRarityFromName(d.Name)
		if r then return r end
	end
	return nil
end

local function matchesSelectedPetName(pet)
	local selectedCount = 0
	for _ in pairs(selectedPetRarities) do
		selectedCount += 1
	end
	if selectedCount == 0 then return true end

	local rarity = getDisplayRarity(pet)
	if not rarity then rarity = "Common" end
	if rarity == "Mythical" then rarity = "Mythic" end
	return selectedPetRarities[rarity] == true
end

local function getPetPart(pet)
	if pet:IsA("BasePart") then return pet end
	return pet:FindFirstChildWhichIsA("BasePart")
end

local pickupCooldown = {}

local function findAnyPetToPickup()
	local bestPet, bestDist = nil, math.huge
	local nowT = os.clock()
	local pickups = workspace:FindFirstChild("AnimalPickups")
	for _, pet in ipairs(pickups and pickups:GetChildren() or {}) do
		local cd = pickupCooldown[pet]
		if cd and cd <= nowT then pickupCooldown[pet] = nil cd = nil end
		local part = not cd and getPetPart(pet) or nil
		if part and matchesSelectedPetName(pet) then
			local curHrp = char and char:FindFirstChild("HumanoidRootPart")
			if curHrp then
				local d = (part.Position - curHrp.Position).Magnitude
				if d < bestDist then
					bestDist = d
					bestPet = pet
					lockUtil.petName = pet.Name
					lockUtil.petPos = part.Position
				end
			end
		end
	end
	return bestPet
end

local function findPromptPart(v)
	local p = v.Parent
	if not p then return nil end
	if p:IsA("BasePart") then return p end
	if p:IsA("Attachment") and p.Parent and p.Parent:IsA("BasePart") then return p.Parent end
	local found = p:FindFirstChildWhichIsA("BasePart", true)
	if found then return found end
	local gp = p.Parent
	if gp then
		found = gp:FindFirstChildWhichIsA("BasePart", true)
		if found then return found end
	end
	return nil
end

local function triggerPrompt(prompt)
	pcall(function() fireproximityprompt(prompt, prompt.HoldDuration) end)
end

local function triggerClick(detector)
	pcall(function() fireclickdetector(detector, 1) end)
end

local function collectPetInteractions(pet)
	local list = {}
	local seen = {}
	local fallbackPart = getPetPart(pet)
	local myPos = char and char:GetPivot().Position or Vector3.new()
	pcall(function()
		local function addOne(obj, part)
			if seen[obj] then return end
			seen[obj] = true
			part = part or (findPromptPart(obj) or fallbackPart)
			if not part then return end
			table.insert(list, {
				kind = obj:IsA("ProximityPrompt") and "prompt" or "det",
				obj = obj,
				part = part,
				dist = (part.Position - myPos).Magnitude,
			})
		end
		if pet:IsA("ProximityPrompt") or pet:IsA("ClickDetector") then
			addOne(pet)
		end
		for _, d in ipairs(pet:GetDescendants()) do
			if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
				addOne(d)
			end
		end
		local center = fallbackPart and fallbackPart.Position or myPos
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
				local part = findPromptPart(d)
				if part and (part.Position - center).Magnitude <= 8 then
					addOne(d, part)
				end
			end
		end
	end)
	table.sort(list, function(a, b) return a.dist < b.dist end)
	return list
end

local pickupBusy = false


local homeMethod = "walk"
local GUARD_SAFE_DIST = 20
local GUARD_TELEPORT_WAIT = 1
local TEMP_TELEPORT_POS = Vector3.new(-75.241516, 3.498025, 13.681024)
local HOME_TELEPORT_LOOPS = 1


local fullLockConn = nil
local fullLockSnap = {}

local function lockCharacterFull()
	if fullLockConn then return end
	if not char or not humanoid or not humanoid.Parent then return end
	local floatH = 2
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	pcall(function()
		humanoid.PlatformStand = true
		humanoid.JumpPower = 0
	end)
	local groundY = getGroundY(hrp.Position, true)
	local pivot = char:GetPivot()
	local _, yaw = pivot:ToEulerAnglesYXZ()
	pcall(function()
		char:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, yaw, 0))
	end)
	local joints = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") then
			table.insert(joints, d)
		end
	end
	for _, d in ipairs(joints) do
		pcall(function() d.Transform = CFrame.new() end)
	end
	local allParts = {}
	local lowest = nil
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(allParts, part)
			local bottom = part.Position.Y - part.Size.Y / 2
			if not lowest or bottom < lowest then
				lowest = bottom
			end
		end
	end
	if #allParts == 0 or not lowest then
		pcall(function()
			if humanoid and humanoid.Parent then
				humanoid.PlatformStand = false
				humanoid.JumpPower = 50
			end
		end)
		return
	end
	local lift = floatH
	if groundY then
		local g = (groundY + floatH) - lowest
		if g > lift then lift = g end
	end
	local cur = char:GetPivot()
	pcall(function()
		char:PivotTo(cur + Vector3.new(0, lift, 0))
	end)
	table.clear(fullLockSnap)
	for _, part in ipairs(allParts) do
		if part.Parent then
			fullLockSnap[part] = part.CFrame
		end
	end
	fullLockConn = RunService.Heartbeat:Connect(function()
		if humanoid and humanoid.Parent then
			humanoid.PlatformStand = true
			humanoid.JumpPower = 0
		end
		for _, d in ipairs(joints) do
			if d.Parent then
				pcall(function() d.Transform = CFrame.new() end)
			end
		end
		for part, cf in pairs(fullLockSnap) do
			if part.Parent then
				part.CFrame = cf
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end
	end)
end

local function unlockCharacterFull()
	if fullLockConn then
		fullLockConn:Disconnect()
		fullLockConn = nil
	end
	table.clear(fullLockSnap)
	pcall(function()
		if humanoid and humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid.JumpPower = 50
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)
end

local function ensureFreeMove()
	unlockCharacterFull()
	unlockCharacter()
	if humanoid and humanoid.Parent then
		pcall(function()
			humanoid.PlatformStand = false
			humanoid.JumpPower = 50
			if humanoid.WalkSpeed <= 0 then humanoid.WalkSpeed = getCurrentSpeed() end
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
end

local function guardAimDistance(guardPart)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not guardPart then return nil end
	local p, g = hrp.Position, guardPart.Position
	local dx, dz = p.X - g.X, p.Z - g.Z
	return math.sqrt(dx * dx + dz * dz)
end

local function walkToGuardAndLock(guard, lockDist, zone)
	local list = getZoneGuardList(zone)
	if guard then
		local found = false
		for _, g in ipairs(list) do
			if g.model == guard.model then found = true break end
		end
		if not found then table.insert(list, guard) end
	end
	local elapsed = 0
	if humanoid and humanoid.Parent then
		pcall(function() humanoid.WalkSpeed = 16 end)
	end
	local locked = false
	ensureFreeMove()
	while elapsed < 15 do
		if not autoRun and not autoPickup then break end
		local h = char and char:FindFirstChild("HumanoidRootPart")
		if not h then break end
		local pos = h.Position
		local best, bestD = nil, math.huge
		local humBest, humD = nil, math.huge
		for _, g in ipairs(list) do
			local gp = g.part and g.part.Position
			if gp then
				local dx = gp.X - pos.X
				local dz = gp.Z - pos.Z
				local d = math.sqrt(dx * dx + dz * dz)
				if d < bestD then bestD, best = d, g end
				if g.humanoid and d < humD then humD, humBest = d, g end
			end
		end
		local aimM, aimD = best, bestD
		if humBest then aimM, aimD = humBest, humD end
		if aimM then
			local spdNow = humanoid and humanoid.WalkSpeed or 60
			local capSpd = nil
			if aimD <= lockDist + 5 then
				capSpd = 12
			elseif aimD <= lockDist + 20 then
				capSpd = 30
			end
			if capSpd and spdNow > capSpd then
				pcall(function() humanoid.WalkSpeed = capSpd end)
			end
		end
		if aimM and aimD <= lockDist then
			ensureFreeMove()
			lockCharacterFull()
			locked = true
			break
		end
		local tp = aimM and aimM.part and aimM.part.Position
		if not tp then
			pcall(function() humanoid:Move(Vector3.zero, true) end)
			break
		end
		local dx = tp.X - pos.X
		local dz = tp.Z - pos.Z
		local toGoal = Vector3.new(dx, 0, dz).Unit
		local cam = workspace.CurrentCamera
		local camCF = cam and cam.CFrame
		local moveDir = camCF and camCF:VectorToObjectSpace(toGoal) or toGoal
		pcall(function() humanoid:Move(moveDir, true) end)
		elapsed += RunService.RenderStepped:Wait()
	end
	pcall(function() humanoid:Move(Vector3.zero, true) end)
	return locked
end

local function teleportHomeViaGuard()

	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local spdBefore = humanoid and humanoid.WalkSpeed or 16
	if spdBefore < 1 then spdBefore = 16 end
	local function restoreGuardSpeed()
		if humanoid and humanoid.Parent then
			pcall(function() humanoid.WalkSpeed = spdBefore end)
		end
	end
	local zone = lockUtil.guardZone
	if zone and not zone.Parent then zone = nil end
	local petZone, petD = nil, nil
	if lockUtil.petPos and lockUtil.zoneOfPoint then
		petZone, petD = lockUtil.zoneOfPoint(lockUtil.petPos)
	end
	if petZone and petZone.Parent and petZone ~= zone then
		zone = petZone
		lockUtil.guardZone = petZone
	end
	local guard, guardDist = findNearestGuard(hrp.Position, zone)
	if not guard then
		local ok = panTo(PET_RETURN_POS)
		if ok then waitOrStop(1) end
		return ok
	end
	local guardPart = guard.part
	lockUtil.guardZone = zone
	if not walkToGuardAndLock(guard, GUARD_SAFE_DIST, zone) then
		restoreGuardSpeed()
		return false
	end
	if not autoInteract then autoInteractLink = true end

	local t = 0
	while t < GUARD_TELEPORT_WAIT do
		if not autoRun and not autoPickup then
			unlockCharacterFull()
			unlockCharacter()
			autoInteractLink = false
			restoreGuardSpeed()
			return false
		end
		t += RunService.Heartbeat:Wait()
	end

	local originPos = hrp.Position
	unlockCharacterFull()
	unlockCharacter()
	for i = 1, HOME_TELEPORT_LOOPS do
		if not autoRun and not autoPickup then
			autoInteractLink = false
			unlockCharacter()
			restoreGuardSpeed()
			return false
		end

		pcall(function()
			hrp.CFrame = CFrame.new(TEMP_TELEPORT_POS)
		end)

		lockCharacterFull()
		task.wait(0.15)

		unlockCharacterFull()
		pcall(function()
			hrp.CFrame = CFrame.new(originPos)
		end)
		task.wait(1)
	end
	autoInteractLink = false
	unlockCharacter()
	restoreGuardSpeed()
	return true
end

local function doMoveToPetAndBack(pet)
	local fromPickupFolder = pet.Parent == workspace:FindFirstChild("AnimalPickups")
	local deadline = os.clock() + 8
	local idleT = 0
	local gotIt = false
	while not petGone(pet, fromPickupFolder) do
		if os.clock() > deadline then break end
		if not autoRun and not autoPickup then break end

		local petPart = getPetPart(pet)
		if not petPart then break end

		local interactions = collectPetInteractions(pet)
		if #interactions == 0 then
			if idleT >= 2 then break end
			idleT = idleT + 0.1
			task.wait(0.1)
		else
			idleT = 0
			local targetPos = interactions[1].part.Position

			local myPos = char and char:GetPivot().Position
			local needStep = myPos and (targetPos - myPos).Magnitude > 2

			unlockCharacter()
			if needStep and not fullLockConn then
				if not panTo(targetPos, 1.2) then
					unlockCharacter()
					return false
				end
			end
			pcall(function() humanoid:Move(Vector3.zero, true) end)

			local startT = os.clock()
			local nearPet = false
			while os.clock() - startT < 2 do
				if not autoRun and not autoPickup then break end
				local ppNow = getPetPart(pet)
				local hrpNow = char and char:FindFirstChild("HumanoidRootPart")
				if ppNow and hrpNow and (ppNow.Position - hrpNow.Position).Magnitude <= 12 then nearPet = true end
				if nearPet and petGone(pet, fromPickupFolder) then gotIt = true break end
				for _, it in ipairs(interactions) do
					if it.kind == "prompt" then
						if it.obj.Enabled then triggerPrompt(it.obj) end
					else
						triggerClick(it.obj)
					end
				end
				if not waitOrStop(PICKUP_TRIGGER_INTERVAL) then break end
			end
			if nearPet and petGone(pet, fromPickupFolder) then gotIt = true end

			if gotIt then
				lockUtil.petPos = petPart.Position
				if homeMethod == "teleport" then
					local ok = teleportHomeViaGuard()
					unlockCharacter()
					if not ok then
						waitOrStop(1)
						return false
					end
					return true
				end
				unlockCharacter()
				if not panTo(PET_RETURN_POS) then
					unlockCharacter()
					return false
				end
				unlockCharacter()
				waitOrStop(1)
				return true
			end
		end
	end
	if not petGone(pet, fromPickupFolder) then
		pickupCooldown[pet] = os.clock() + 5
	end
	unlockCharacter()
	return gotIt
end

local function moveToPetAndBack(pet)
	if pickupBusy then return false end
	pickupBusy = true
	local ok, res = pcall(doMoveToPetAndBack, pet)
	pickupBusy = false
	if ok then return res end
	return false
end

local function startAutoInteract(interval)
	if interactLoopConn then return end
	interactLoopConn = task.spawn(function()
		while autoInteract do
			pcall(function()
				local curHrp = char and char:FindFirstChild("HumanoidRootPart")
				if curHrp then
					local cpos = curHrp.Position
					for _, v in ipairs(workspace:GetDescendants()) do
						if not autoInteract then break end
						if v.ClassName == "ProximityPrompt" and v.Enabled and v.Parent then
							local part = findPromptPart(v)
							if part and (part.Position - cpos).Magnitude <= AUTO_INTERACT_RANGE then
								triggerPrompt(v)
							end
						elseif v.ClassName == "ClickDetector" and v.Parent then
							local part = findPromptPart(v)
							if part and (part.Position - cpos).Magnitude <= AUTO_INTERACT_RANGE then
								triggerClick(v)
							end
						end
					end
				end
			end)
			task.wait(interval or PICKUP_TRIGGER_INTERVAL)
		end
		interactLoopConn = nil
	end)
end

local function stopAutoInteract()
	autoInteract = false
	if interactLoopConn then
		pcall(function() task.cancel(interactLoopConn) end)
		interactLoopConn = nil
	end
end

local function hasSelectedEgg()
	for _ in pairs(selectedEggEnglish) do
		return true
	end
	return false
end

local function matchesSelectedName(egg)
	local name = string.lower(egg.Name)
	for key in pairs(selectedEggEnglish) do
		if string.find(name, string.lower(key), 1, true) then
			return true
		end
	end
	return false
end




local PICKAXE_SHOP = {
	{ name = "Wooden", cn = "木质" },
	{ name = "Stone", cn = "石制" },
	{ name = "Iron", cn = "铁质" },
	{ name = "Golden", cn = "黄金" },
	{ name = "Diamond", cn = "钻石" },
	{ name = "Strawberry", cn = "草莓" },
	{ name = "Cactus", cn = "仙人掌" },
	{ name = "Lightning", cn = "闪电" },
	{ name = "Candy", cn = "糖果" },
	{ name = "Rainbow", cn = "彩虹" },
	{ name = "Crystal", cn = "水晶" },
	{ name = "Demon", cn = "恶魔" },
	{ name = "Hacker", cn = "黑客" },
	{ name = "UFO", cn = "飞碟" },
	{ name = "Secret", cn = "秘密" },
	{ name = "Cool", cn = "酷炫" },
	{ name = "Galaxy", cn = "银河" },
	{ name = "Celestial", cn = "神圣" },
}
local TRAIL_SHOP = {
	{ name = "White", cn = "白色" },
	{ name = "Blue", cn = "蓝色" },
	{ name = "Green", cn = "绿色" },
	{ name = "Purple", cn = "紫色" },
	{ name = "Red", cn = "红色" },
	{ name = "Golden", cn = "金色" },
	{ name = "Rainbow", cn = "彩虹" },
	{ name = "Galactic", cn = "银河" },
	{ name = "Secret", cn = "秘密" },
	{ name = "Laser", cn = "激光" },
	{ name = "Moonlight", cn = "月光" },
}
local PickaxeShopRequest = ReplicatedStorage:FindFirstChild("PickaxeShopRequest")
local TrailShopRequest = ReplicatedStorage:FindFirstChild("TrailShopRequest")

local function fireShop(remote, action, id)
	if not remote then return false end
	local ok = pcall(function()
		remote:FireServer(action, id)
	end)
	return ok
end

local function buyPickaxe(id)
	fireShop(PickaxeShopRequest, "Buy", id)
end

local function buyTrail(id)
	fireShop(TrailShopRequest, "Buy", id)
end


local autoBuyPickaxe = false
local autoBuyPickaxeConn = nil
local function startAutoBuyPickaxe()
	if autoBuyPickaxeConn then return end
	autoBuyPickaxeConn = task.spawn(function()
		local idx = 1
		while autoBuyPickaxe do
			buyPickaxe(idx)
			idx = idx % #PICKAXE_SHOP + 1
			task.wait(1)
		end
		autoBuyPickaxeConn = nil
	end)
end

local autoBuyTrail = false
local autoBuyTrailConn = nil
local function startAutoBuyTrail()
	if autoBuyTrailConn then return end
	autoBuyTrailConn = task.spawn(function()
		local idx = 1
		while autoBuyTrail do
			buyTrail(idx)
			idx = idx % #TRAIL_SHOP + 1
			task.wait(1)
		end
		autoBuyTrailConn = nil
	end)
end

local upgradeTreadmillConn = nil
local function startAutoUpgradeTreadmill()
	if upgradeTreadmillConn then return end
	upgradeTreadmillConn = task.spawn(function()
		while autoUpgradeTreadmill do
			local r = game:GetService("ReplicatedStorage"):FindFirstChild("UpgradeTreadmillRequest")
			if r then r:FireServer() end
			task.wait(0.5)
		end
		upgradeTreadmillConn = nil
	end)
end

local upgradePlotConn = nil
local function startAutoUpgradePlot()
	if upgradePlotConn then return end
	upgradePlotConn = task.spawn(function()
		while autoUpgradePlot do
			local r = game:GetService("ReplicatedStorage"):FindFirstChild("UpgradePlotRequest")
			if r then r:FireServer() end
			task.wait(0.5)
		end
		upgradePlotConn = nil
	end)
end

local equipBestConn = nil
local function startAutoEquipBest()
	if equipBestConn then return end
	equipBestConn = task.spawn(function()
		while autoEquipBest do
			local args = { "EquipBest" }
			local r = game:GetService("ReplicatedStorage"):FindFirstChild("PetsInventoryRemote")
			if r then r:FireServer(unpack(args)) end
			task.wait(0.5)
		end
		equipBestConn = nil
	end)
end

local function getMyPlot()
	local plotsFolder = workspace:FindFirstChild("Plots")
	if not plotsFolder then
		return nil
	end
	local myName = string.lower(player.Name)
	local myId = tostring(player.UserId)

	local function ownerMatches(v)
		if v == nil then return false end
		local s = tostring(v)
		return string.lower(s) == myName or s == myId
	end


	local function scanOwnerContainer(container)
		for _, ownerName in ipairs({ "Owner", "OwnerValue", "OwnerId", "Player", "Belongs" }) do
			local owner = container:FindFirstChild(ownerName)
			if owner then
				if owner:IsA("ValueBase") then
					if ownerMatches(owner.Value) then return true end
				elseif ownerMatches(owner.Name) then
					return true
				end
			end
		end
		return false
	end


	local function scanAllValues(model)
		local found = false
		local function rec(obj, depth)
			if found or depth > 2 then return end
			for _, c in ipairs(obj:GetChildren()) do
				if c:IsA("ValueBase") then
					if ownerMatches(c.Value) then found = true; return end
				elseif not c:IsA("BasePart") then
					rec(c, depth + 1)
				end
			end
		end
		rec(model, 0)
		return found
	end

	for _, plot in ipairs(plotsFolder:GetChildren()) do

		if scanOwnerContainer(plot) then return plot end

		if scanAllValues(plot) then return plot end

		for k, val in pairs(plot:GetAttributes()) do
			if ownerMatches(val) then return plot end
		end

		if string.find(string.lower(plot.Name), myName, 1, true) then
			return plot
		end
	end


	local fallback = plotsFolder:FindFirstChild("Base_2")
	if fallback then
		return fallback
	end

	return nil
end

local function walkToPlot(targetPos, arriveDist)
	local function cancel()
		return not autoHome
	end
	local r = lockUtil.navWalk(targetPos, arriveDist, { maxTime = 30, cancel = cancel })
	return r ~= "stop"
end

local autoHomeConn = nil
local function startAutoHome()
	if autoHomeConn then return end
	autoHomeConn = task.spawn(function()
		local treadCache = nil
		local treadRecheck = 0
		local function findTreadmill(root)
			if not root then return nil end
			local function hasTread(inst)
				return string.find(string.lower(inst.Name), "treadmill", 1, true) ~= nil
			end
			for _, ch in ipairs(root:GetChildren()) do
				if hasTread(ch) then
					if ch:IsA("Folder") then
						local inner = ch:FindFirstChildWhichIsA("Model") or ch:FindFirstChildWhichIsA("BasePart")
						if inner then return inner end
					end
					return ch
				end
			end
			for _, ch in ipairs(root:GetDescendants()) do
				if (ch:IsA("Model") or ch:IsA("BasePart")) and hasTread(ch) then
					return ch
				end
			end
			for _, ch in ipairs(root:GetDescendants()) do
				if ch:IsA("ProximityPrompt") and string.find(string.lower(ch.Name), "tread", 1, true) then
					local top = ch
					while top.Parent and top.Parent ~= root do
						top = top.Parent
					end
					if top:IsA("Folder") then
						top = top:FindFirstChildWhichIsA("Model") or top:FindFirstChildWhichIsA("BasePart") or top
					end
					return top
				end
			end
			return nil
		end
		while autoHome do
			local plot = getMyPlot()
			if plot then
				local now = os.clock()
				if treadCache and (not treadCache:IsDescendantOf(plot) or now >= treadRecheck) then treadCache = nil end
				if not treadCache then
					treadCache = findTreadmill(plot)
					treadRecheck = now + 3
				end
				local treadmill = treadCache
				local homePart = plot:FindFirstChild("Baseplate") or plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")
				local treadPart = nil
				if treadmill then
					if treadmill:IsA("BasePart") then
						treadPart = treadmill
					else
						treadPart = treadmill:FindFirstChildWhichIsA("BasePart")
					end
				end
				if not treadPart then treadCache = nil end
				local curHrp = char and char:FindFirstChild("HumanoidRootPart")
				if curHrp then
					local curPos = curHrp.Position
					local targetPos = nil

					if homePart then
						local homePos = homePart.Position
						if (homePos - curPos).Magnitude > 6 then
							targetPos = homePos
						elseif treadPart and (treadPart.Position - curPos).Magnitude > 1.5 then
							targetPos = treadPart.Position
						end
					elseif treadPart and (treadPart.Position - curPos).Magnitude > 1.5 then
						targetPos = treadPart.Position
					end
					if targetPos then
						lockCharacter()
						walkToPlot(targetPos, 2)
						unlockCharacter()
					end
				end
			end
			task.wait(0.5)
		end
		autoHomeConn = nil
	end)
end


local HellBossFight = workspace:FindFirstChild("HellBossFight")
local DemonBoss = HellBossFight and HellBossFight:FindFirstChild("DemonBoss")
local BatHitRequest = ReplicatedStorage:FindFirstChild("BatHitRequest")
local BOSS_ATTACK_COOLDOWN = 0.6
local autoWalkBoss = false
local autoAttackBoss = false
local walkBossConn = nil
local attackBossConn = nil

local function getDemonBossPart()
	if not DemonBoss then return nil end
	if DemonBoss:IsA("Model") then
		return DemonBoss.PrimaryPart or DemonBoss:FindFirstChild("HumanoidRootPart") or DemonBoss:FindFirstChildWhichIsA("BasePart")
	end
	if DemonBoss:IsA("BasePart") then return DemonBoss end
	return nil
end

local function startAutoWalkBoss()
	if walkBossConn then return end
	walkBossConn = task.spawn(function()
		while autoWalkBoss do
			local bossPart = getDemonBossPart()
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if bossPart and hrp then
				local bossPos = bossPart.Position
				local curPos = hrp.Position
				local dir = Vector3.new(bossPos.X - curPos.X, 0, bossPos.Z - curPos.Z)
				if dir.Magnitude > 3 then
					pcall(function()
						if keepAliveConn then
							keepAliveConn:Disconnect()
							keepAliveConn = nil
						end
						if humanoid and humanoid.Parent then
							humanoid.PlatformStand = false
							humanoid.JumpPower = 50
							humanoid:ChangeState(Enum.HumanoidStateType.Running)
						end
					end)
					local toGoal = dir.Unit
					local cam = workspace.CurrentCamera
					local camCF = cam and cam.CFrame
					local camDir = camCF and camCF:VectorToObjectSpace(toGoal) or toGoal
					pcall(function() humanoid:Move(camDir, true) end)
				else
					pcall(function() humanoid:Move(Vector3.zero, true) end)
				end
			end
			RunService.RenderStepped:Wait()
		end
		pcall(function()
			if humanoid and humanoid.Parent then humanoid:Move(Vector3.zero, true) end
		end)
		walkBossConn = nil
	end)
end

local function startAutoAttackBoss()
	if attackBossConn then return end
	attackBossConn = task.spawn(function()
		while autoAttackBoss do
			if BatHitRequest then
				pcall(function() BatHitRequest:FireServer(nil) end)
			end
			task.wait(BOSS_ATTACK_COOLDOWN)
		end
		attackBossConn = nil
	end)
end

local autoGoRift = false
local goRiftConn = nil

local function getRiftJoinHellPart()
	local zoneBuilds = workspace.Build and workspace.Build:FindFirstChild("ZoneBuilds")
	if not zoneBuilds then return nil end
	local zone7 = zoneBuilds:FindFirstChild("Zone7")
	if not zone7 then return nil end
	local jh = zone7:FindFirstChild("JoinHell")
	if not jh then return nil end
	if jh:IsA("BasePart") then return jh end
	if jh:IsA("Model") then
		return jh.PrimaryPart or jh:FindFirstChild("HumanoidRootPart") or jh:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function startAutoGoRift()
	if goRiftConn then return end
	goRiftConn = task.spawn(function()
		while autoGoRift do
			local riftPart = getRiftJoinHellPart()
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if riftPart and hrp then
				local riftPos = riftPart.Position
				local curPos = hrp.Position
				local dir = Vector3.new(riftPos.X - curPos.X, 0, riftPos.Z - curPos.Z)
				if dir.Magnitude > 4 then
					pcall(function()
						if keepAliveConn then
							keepAliveConn:Disconnect()
							keepAliveConn = nil
						end
						if humanoid and humanoid.Parent then
							humanoid.PlatformStand = false
							humanoid.JumpPower = 50
							humanoid:ChangeState(Enum.HumanoidStateType.Running)
						end
					end)
					local toGoal = dir.Unit
					local cam = workspace.CurrentCamera
					local camCF = cam and cam.CFrame
					local camDir = camCF and camCF:VectorToObjectSpace(toGoal) or toGoal
					pcall(function() humanoid:Move(camDir, true) end)
				else
					pcall(function() humanoid:Move(Vector3.zero, true) end)
				end
			end
			RunService.RenderStepped:Wait()
		end
		pcall(function()
			if humanoid and humanoid.Parent then humanoid:Move(Vector3.zero, true) end
		end)
		goRiftConn = nil
	end)
end

local function panToPickupAware(targetPos, arriveDist)
	if not autoRun and not autoPickup then return false end
	local petHit = false
	local function cancel()
		if not autoRun and not autoPickup then return true end
		if autoPickup and findAnyPetToPickup() then
			petHit = true
			return true
		end
		return false
	end
	local r = lockUtil.navWalk(targetPos, arriveDist, { cancel = cancel })
	if petHit then return "pet" end
	return r == "arrive"
end

local function handlePetPriority()
	if not autoPickup then return end
	local pet = findAnyPetToPickup()
	if pet then
		moveToPetAndBack(pet)
	end
end

local function approachWithPetPriority(standPos)
	local busyWait = 0
	while pickupBusy and autoRun and busyWait < 20 do
		busyWait += RunService.Heartbeat:Wait()
	end
	if not autoRun and not autoPickup then return false end
	local r = panToPickupAware(standPos)
	local guard = 0
	while r == "pet" and guard < 3 do
		guard += 1
		handlePetPriority()
		if not autoRun then return false end
		r = panToPickupAware(standPos)
	end
	return r
end

local function farmAllZones()
	if not autoRun then return end
	if not hasSelectedEgg() then
		unlockCharacter()
		return
	end

	local foundAny = false
	for _, zone in ipairs(getAllZones()) do
		if not autoRun then return end
		local eggsFolder = zone:FindFirstChild("Eggs")
		if eggsFolder then
			for _, egg in ipairs(eggsFolder:GetChildren()) do
				if not autoRun then return end
				if matchesSelectedName(egg) then
					local part = getEggPart(egg)
					if part then
						local eggHp = getEggHealth(egg)
						if eggHp == nil or eggHp > 0 then
							foundAny = true
							lockUtil.guardZone = zone
							lockUtil.eggPos = part.Position
							local eggPos = part.Position
							local standPos = eggPos
							local curHrp = char:FindFirstChild("HumanoidRootPart")
							if curHrp then
								local toEgg = eggPos - curHrp.Position
								local flatDir = Vector3.new(toEgg.X, 0, toEgg.Z)
								local flatLen = flatDir.Magnitude
								if flatLen >= 1 then
									standPos = eggPos - flatDir.Unit * 5
								else
									standPos = eggPos - Vector3.new(5, 0, 0)
								end
							end

							if not approachWithPetPriority(standPos) then break end

							local timeout = eggHp and 60 or 10
							local elapsed = 0
							local attackCd = 0
							local lastHealth = humanoid and humanoid.Health or 100
							while elapsed < timeout do
								if not autoRun then return end

								if not part.Parent then break end
								eggHp = getEggHealth(egg)
								if eggHp ~= nil and eggHp <= 0 then break end

								if autoPickup and not pickupBusy and findAnyPetToPickup() then
									unlockCharacter()
									if not approachWithPetPriority(standPos) then break end
									if not part.Parent then break end
									eggHp = getEggHealth(egg)
									if eggHp ~= nil and eggHp <= 0 then break end
								end

								local curHealth = humanoid and humanoid.Health or lastHealth
								local gotHit = (not pickupBusy) and curHealth < lastHealth - 0.5
								lastHealth = curHealth

								if not gotHit and not pickupBusy then
									local hh = char and char:FindFirstChild("HumanoidRootPart")
									if hh then
										local dxx = hh.Position.X - standPos.X
										local dzz = hh.Position.Z - standPos.Z
										if (dxx * dxx + dzz * dzz) > 144 then gotHit = true end
									end
								end
								local h = (not pickupBusy) and char:FindFirstChild("HumanoidRootPart")
								if h then
									local eggPosNow = part.Position
									if gotHit then
										RunService.Heartbeat:Wait()
										local gY0 = getGroundY(Vector3.new(standPos.X, standPos.Y + 4, standPos.Z), true)
										lockUtil.placeHover(standPos.X, standPos.Z, gY0 or standPos.Y, 2)
										h.AssemblyLinearVelocity = Vector3.zero
										lockCharacter()
										local settleElapsed = 0
										local settleAtk = 0
										while settleElapsed < 0.5 do
											if not autoRun then unlockCharacter() return end
											if not part.Parent then break end
											if autoPickup and findAnyPetToPickup() then
												unlockCharacter()
												if not approachWithPetPriority(standPos) then break end
											end
											if not part.Parent then break end
											eggHp = getEggHealth(egg)
											if eggHp ~= nil and eggHp <= 0 then break end
											local dt2 = RunService.Heartbeat:Wait()
											settleElapsed = settleElapsed + dt2
											settleAtk = settleAtk + dt2
											if settleAtk >= 0.1 then
												attackEgg(part)
												settleAtk = 0
											end
										end
										unlockCharacter()
										if not part.Parent then break end
										eggHp = getEggHealth(egg)
										if eggHp ~= nil and eggHp <= 0 then break end
									end
									local curPos = h.Position
									h.CFrame = CFrame.lookAt(
										Vector3.new(curPos.X, curPos.Y, curPos.Z),
										Vector3.new(eggPosNow.X, curPos.Y, eggPosNow.Z)
									)
								end

								local dt = RunService.Heartbeat:Wait()
								attackCd += dt
								if attackCd >= 0.35 and not pickupBusy then
									attackEgg(part)
									attackCd = 0
								end
								elapsed += dt
							end
						end
					end
				end
			end
		end
	end
	if not foundAny then
		unlockCharacter()
	end
end

local EGG_ALIAS = {
	["Rock"] = "岩石蛋", ["Stone"] = "岩石蛋",
	["Forest"] = "森林蛋", ["Wood"] = "森林蛋", ["Grass"] = "森林蛋",
	["Cactus"] = "仙人掌蛋", ["Desert"] = "仙人掌蛋",
	["Bones"] = "骨头蛋", ["Bone"] = "骨头蛋", ["Skeleton"] = "骨头蛋",
	["Scorpion Egg"] = "蝎子蛋",
	["Frozen"] = "冰冻蛋", ["Frost"] = "冰冻蛋", ["Ice"] = "冰冻蛋", ["Glacier"] = "冰冻蛋",
	["Yeti"] = "雪人蛋", ["Snowman"] = "雪人蛋", ["Snow"] = "雪人蛋",
	["Easter Bunny"] = "复活节兔子蛋", ["Easter"] = "复活节兔子蛋",
	["Candy"] = "糖果蛋", ["Sweet"] = "糖果蛋",
	["Rainbow"] = "彩虹蛋", ["Color"] = "彩虹蛋",
	["Gooey"] = "黏糊蛋", ["Slime"] = "黏糊蛋", ["Sticky"] = "黏糊蛋",
	["Swamp Egg"] = "沼泽蛋", ["Swamp"] = "沼泽蛋",
	["Tree Egg"] = "树蛋", ["Wooden"] = "树蛋",
	["Lake"] = "湖蛋", ["Pond"] = "湖蛋",
	["Sea Stones"] = "海洋石蛋", ["SeaStone"] = "海洋石蛋", ["Seastone"] = "海洋石蛋",
	["Water"] = "水蛋", ["Aqua"] = "水蛋",
	["Sea Egg"] = "海洋蛋", ["Ocean"] = "海洋蛋",
	["Fallen Angel"] = "坠天使蛋", ["FallenAngel"] = "坠天使蛋", ["Fallen"] = "坠天使蛋",
	["Angel"] = "天使蛋", ["Holy"] = "天使蛋",
	["Volcanic"] = "火山蛋", ["Lava"] = "火山蛋", ["Magma"] = "火山蛋",
	["Blossom"] = "花朵蛋", ["Flower"] = "花朵蛋",
	["Bamboo"] = "竹子蛋",
	["Fortune Egg"] = "财富蛋", ["Lucky"] = "财富蛋", ["Gold"] = "财富蛋",
	["Sun"] = "太阳蛋", ["Solar"] = "太阳蛋",
	["Starry"] = "星空蛋", ["Star"] = "星空蛋",
	["Blackhole"] = "黑洞蛋", ["BlackHole"] = "黑洞蛋",
	["Plasma"] = "等离子蛋", ["Plasma Egg"] = "等离子蛋",
	["Nebula"] = "星云蛋", ["Nebula Egg"] = "星云蛋",
	["Supernova"] = "超新星蛋", ["Supernova Egg"] = "超新星蛋",
}

local eggNameCache = {}
local function normalizeEggName(raw, obj)
	local key = raw or ""
	if eggNameCache[key] ~= nil then return eggNameCache[key] or nil end
	local function matchString(s)
		if not s then return nil end
		local lower = string.lower(s)
		local bestMatch = nil
		local bestLen = 0
		for keyword, cn in pairs(EGG_ALIAS) do
			local kl = string.lower(keyword)
			if string.find(lower, kl, 1, true) then
				if #kl > bestLen then
					bestLen = #kl
					bestMatch = cn
				end
			end
		end
		return bestMatch
	end

	local direct = matchString(raw)
	if direct then eggNameCache[key] = direct return direct end

	if obj then
		for _, d in ipairs(obj:GetDescendants()) do
			if d ~= obj and d.Name then
				local sub = matchString(d.Name)
				if sub then eggNameCache[key] = sub return sub end
			end
		end
	end

	eggNameCache[key] = false
	return nil
end

local function getEggWeight(cn)
	return EGG_WEIGHT_BY_CN[cn]
end

local function getEggRarity(cn)
	return EGG_RARITY_BY_CN[cn]
end

local function scanAll(obj)
	local data = {}
	local function consider(name, value)
		if value == nil then return end
		local n = string.lower(name)
		if data[n] == nil then
			data[n] = value
		end
	end

	local attrs = obj:GetAttributes()
	for name, value in pairs(attrs) do consider(name, value) end

	for _, d in ipairs(obj:GetDescendants()) do
		if d ~= obj then
			local dAttrs = d:GetAttributes()
			for name, value in pairs(dAttrs) do consider(name, value) end
		end
	end

	for _, d in ipairs(obj:GetDescendants()) do
		if d:IsA("StringValue") or d:IsA("IntValue") or d:IsA("NumberValue") or d:IsA("BoolValue") then
			consider(d.Name, d.Value)
		end
	end

	return data
end

local function toNumber(v)
	if type(v) == "number" then return v end
	if type(v) == "string" then
		local n = tonumber(v)
		if n then return n end
		local matched = string.match(v, "[-%d%.]+")
		if matched then return tonumber(matched) end
	end
	return nil
end

local function findValue(data, keywords)
	for _, keyword in ipairs(keywords) do
		for k, v in pairs(data) do
			if string.find(k, keyword, 1, true) then
				return v
			end
		end
	end
	return nil
end

local function findMaxNumber(data, keywords)
	local maxVal = nil
	for _, keyword in ipairs(keywords) do
		for k, v in pairs(data) do
			if string.find(k, keyword, 1, true) then
				local n = toNumber(v)
				if n then
					if maxVal == nil or n > maxVal then
						maxVal = n
					end
				end
			end
		end
	end
	return maxVal
end

local function scanEggAttributes(obj)
	local data = scanAll(obj)
	local luck = findMaxNumber(data, { "luck", "幸运" })
	local price = findValue(data, { "price", "worth", "cost", "money", "sell", "reward", "payout", "cash", "value" })
	local weight = findValue(data, { "weight", "kg", "mass", "重量" })
	return luck, price, weight
end

local function scanPetAttributes(obj)
	local data = scanAll(obj)
	local income = findValue(data, { "income", "money", "earn", "cash", "persecond", "per_second", "rate", "reward", "payout" })
	local weight = findValue(data, { "weight", "kg", "mass", "重量" })
	local gender = findValue(data, { "gender", "sex" })
	return income, weight, gender
end

local function formatMoney(value)
	if value == nil then return "?" end
	if type(value) ~= "number" then return tostring(value) end
	if value >= 1e12 then return string.format("$%.1f万亿/秒", value / 1e12)
	elseif value >= 1e9 then return string.format("$%.1f亿/秒", value / 1e9)
	elseif value >= 1e6 then return string.format("$%.1f百万/秒", value / 1e6)
	elseif value >= 1e3 then return string.format("$%.1f千/秒", value / 1e3)
	else return string.format("$%d/秒", value) end
end

local function formatWeight(value)
	if value == nil then return "?" end
	local n = toNumber(value)
	if not n then return tostring(value) end
	if n >= 1e6 then return string.format("%.2f百万吨", n / 1e6)
	elseif n >= 1e3 then return string.format("%.2f吨", n / 1e3)
	else return string.format("%.2f千克", n) end
end

local function buildEggText(obj)
	local ok, result = pcall(function()
		local luck, price, weight = scanEggAttributes(obj)
		local lines = {}

		local eggName = normalizeEggName(obj.Name, obj)
		if not eggName then return nil end

		local rarity = scanRarityFromAttributes(obj)
		if not rarity then rarity = extractRarityFromName(obj.Name) end
		if not rarity then rarity = getEggRarity(eggName) end
		local rarityCn = (rarity and RARITY_CN[rarity]) or rarity or "普通"
		local rarityColor = (rarity and RARITY_COLOR[rarity]) or "#FFFFFF"

		local first = string.format('<font color="%s">%s</font>', rarityColor, eggName)
		if luck ~= nil and luck > 1 then
			first = first .. string.format('  <font color="%s">x%.2f 幸运</font>', rarityColor, luck)
		end
		table.insert(lines, first)

		if price ~= nil then
			table.insert(lines, string.format('<font color="%s">%s</font>', rarityColor, tostring(price)))
		end

		table.insert(lines, string.format('<font color="%s">%s</font>', rarityColor, rarityCn))

		local eggWeight = weight or getEggWeight(eggName)
		if eggWeight then
			table.insert(lines, string.format('<font color="%s">%s</font>', rarityColor, formatWeight(eggWeight)))
		end

		return table.concat(lines, "\n")
	end)

	if ok then return result end
	return nil
end

local function buildPetText(obj)
	local ok, result = pcall(function()
		local income, weight, gender = scanPetAttributes(obj)
		local lines = {}

		local rawName = obj.Name or ""
		local petName = normalizePetName(rawName)
		if not petName then return nil end

		if EGG_CN_TO_EN[petName] then return nil end
		if petName == "Egg" or petName == "蛋" then return nil end


		local strippedEn = stripNamePrefix(rawName)
		local displayName = (strippedEn and #strippedEn > 0) and strippedEn or rawName

		local rarity = getDisplayRarity(obj)
		local rarityCn = (rarity and RARITY_CN[rarity]) or rarity or "普通"
		local rarityColor = (rarity and RARITY_COLOR[rarity]) or "#FFFFFF"

		local first = string.format('<font color="%s">%s</font>', rarityColor, displayName)
		first = first .. string.format('  <font color="%s">%s</font>', rarityColor, rarityCn)
		if gender then
			if gender == "Male" or gender == "M" then
				first = first .. string.format('  <font color="%s">♂</font>', rarityColor)
			elseif gender == "Female" or gender == "F" then
				first = first .. string.format('  <font color="%s">♀</font>', rarityColor)
			end
		end
		table.insert(lines, first)

		if income ~= nil then
			table.insert(lines, string.format('<font color="%s">%s</font>', rarityColor, formatMoney(income)))
		end

		return table.concat(lines, "\n")
	end)

	if ok then return result end
	return nil
end

local function matchesEggFilter(obj)
	local selectedCount = 0
	for _ in pairs(eggEspFilter) do
		selectedCount += 1
	end
	if selectedCount == 0 then return true end

	local eggName = normalizeEggName(obj.Name, obj)
	if not eggName then return false end
	return eggEspFilter[eggName] == true
end

local function matchesPetFilter(obj)
	local selectedCount = 0
	for _ in pairs(petEspFilter) do
		selectedCount += 1
	end
	if selectedCount == 0 then return true end

	local rarity = getDisplayRarity(obj)
	if not rarity then return false end
	if rarity == "Mythical" then rarity = "Mythic" end
	return petEspFilter[rarity] == true
end

local petEspCache = {}
local eggEspCache = {}

local function createEsp(obj, cache, name, isPet)
	if cache[obj] then return end

	local text = isPet and buildPetText(obj) or buildEggText(obj)
	if not text then return end

	if isPet and not matchesPetFilter(obj) then return end
	if not isPet and not matchesEggFilter(obj) then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = name
	billboard.Size = UDim2.new(0, 400, 0, 80)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 10000
	billboard.Adornee = obj

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextWrapped = true
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.RichText = true
	label.Parent = billboard

	billboard.Parent = obj
	cache[obj] = { billboard = billboard, label = label, lastText = label.Text }
end

local function removeEsp(obj, cache)
	local cached = cache[obj]
	if cached and cached.billboard then cached.billboard:Destroy() end
	cache[obj] = nil
end

local function updateEsp(cache, isPet)
	for obj, cached in pairs(cache) do
		if not obj.Parent then
			if cached.billboard then cached.billboard:Destroy() end
			cache[obj] = nil
		else
			local text = isPet and buildPetText(obj) or buildEggText(obj)
			local visible = true
			if not text then
				visible = false
			elseif isPet and not matchesPetFilter(obj) then
				visible = false
			elseif not isPet and not matchesEggFilter(obj) then
				visible = false
			end

			if not visible then
				if cached.billboard then cached.billboard:Destroy() end
				cache[obj] = nil
			elseif text ~= cached.lastText then
				cached.label.Text = text
				cached.lastText = text
			end
		end
	end
end

local function refreshPetEsp()
	local pickups = workspace:FindFirstChild("AnimalPickups")
	for _, pet in ipairs(pickups and pickups:GetChildren() or {}) do
		createEsp(pet, petEspCache, "PetBB", true)
	end
end

local function collectAllEggs()
	local list = {}
	local zoneBuilds = workspace.Build and workspace.Build:FindFirstChild("ZoneBuilds")
	if not zoneBuilds then return list end
	for _, zone in ipairs(zoneBuilds:GetChildren()) do
		local eggsFolder = zone:FindFirstChild("Eggs")
		if eggsFolder then
			for _, egg in ipairs(eggsFolder:GetChildren()) do
				if getEggPart(egg) then table.insert(list, egg) end
			end
		end
	end
	return list
end

local function refreshEggEsp()
	for _, egg in ipairs(collectAllEggs()) do
		createEsp(egg, eggEspCache, "EggBB", false)
	end
end

task.spawn(function()
	local folder = workspace:FindFirstChild("AnimalPickups") or waitChildLoop(workspace, "AnimalPickups")
	folder.ChildAdded:Connect(function(pet)
		if petEspEnabled then
			task.wait(0.2)
			if pet.Parent then createEsp(pet, petEspCache, "PetBB", true) end
		end
		if autoPickup then
			task.wait(0.05)
			if pet.Parent then
				local petPart = getPetPart(pet)
				if petPart and matchesSelectedPetName(pet) then
					moveToPetAndBack(pet)
				end
			end
		end
	end)

	folder.ChildRemoved:Connect(function(pet)
		removeEsp(pet, petEspCache)
	end)
end)

task.spawn(function()
	while true do
		if petEspEnabled then
			updateEsp(petEspCache, true)
			refreshPetEsp()
		end
		task.wait(0.5)
	end
end)

task.spawn(function()
	while true do
		if eggEspEnabled then
			updateEsp(eggEspCache, false)
			refreshEggEsp()
		end
		task.wait(0.5)
	end
end)

local function doAntiAFKMove()
	if not humanoid or not humanoid.Parent then return end
	if humanoid.PlatformStand then return end
	if humanoid.MoveDirection.Magnitude > 0.1 then return end
	if autoRun or autoPickup or autoInteract or autoWalkBoss or autoAttackBoss then return end
	local act = math.random(1, 5)
	if act == 1 then
		humanoid.Jump = true
	elseif act == 2 then
		humanoid.Jump = true
		task.wait(0.15)
		humanoid.Jump = true
	elseif act == 3 then
		local dir = (math.random(0, 1) == 0) and Vector3.new(1, 0, 0) or Vector3.new(-1, 0, 0)
		humanoid:Move(dir, true)
		task.wait(0.4 + math.random() * 0.5)
		humanoid:Move(Vector3.zero, true)
	elseif act == 4 then
		local dir = (math.random(0, 1) == 0) and Vector3.new(0, 0, 1) or Vector3.new(0, 0, -1)
		humanoid:Move(dir, true)
		task.wait(0.4 + math.random() * 0.5)
		humanoid:Move(Vector3.zero, true)
	else
		task.wait(1 + math.random() * 2)
	end
end

local function startAntiAFK()
	if antiAFKTask then return end
	antiAFKTask = task.spawn(function()
		while antiAFK do
			task.wait(40 + math.random() * 50)
			if antiAFK then
				pcall(doAntiAFKMove)
			end
		end
		antiAFKTask = nil
	end)
end

local function stopAntiAFK()
	antiAFK = false
	if antiAFKTask then
		task.cancel(antiAFKTask)
		antiAFKTask = nil
	end
end

local Window = WindUI:CreateWindow({
	Title = "打破并偷走一个鸡蛋",
	Author = "由i制作",
	Folder = "EggAuto",
	Size = UDim2.fromOffset(420, 440),
	Theme = "Dark",
	HideSearchBar = true,
})

local BrandLabel = Instance.new("TextLabel")
BrandLabel.Name = "XJW"
BrandLabel.Text = "XJW"
BrandLabel.Font = Enum.Font.GothamBold
BrandLabel.TextSize = 16
BrandLabel.BackgroundTransparency = 1
BrandLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
BrandLabel.TextXAlignment = Enum.TextXAlignment.Left
BrandLabel.AutomaticSize = Enum.AutomaticSize.X
BrandLabel.Size = UDim2.new(0, 0, 0, 22)
BrandLabel.LayoutOrder = 1
BrandLabel.Parent = Window.UIElements.Main.Main.Topbar.Left

local Tabs = {
	Announce = Window:Tab({ Title = "公告", Icon = "table-of-contents", Locked = false }),
	Main = Window:Tab({ Title = "主页", Icon = "settings", Locked = false }),
	Purchase = Window:Tab({ Title = "购买", Icon = "monitor", Locked = false }),
	Activity = Window:Tab({ Title = "活动", Icon = "sparkles", Locked = false }),
	Esp = Window:Tab({ Title = "透视", Icon = "command", Locked = false }),
	Treadmill = Window:Tab({ Title = "跑步机", Icon = "activity", Locked = false }),
	["UI 设置"] = Window:Tab({ Title = "UI 设置", Icon = "settings", Locked = false }),
}

local AnnounceTab = Tabs.Announce
AnnounceTab:Section({ Title = "公告", TextXAlignment = "Left", TextSize = 17 })
AnnounceTab:Paragraph({ Title = "10月13日", Desc = "已修复传送宠物 增加新区域蛋和宠物和品质 防卡顿升级" })
AnnounceTab:Paragraph({ Title = "10月11日", Desc = "传送回拿宠物已绕过反作弊" })

local ActivityTab = Tabs.Activity
ActivityTab:Section({ Title = "恶魔之王", TextXAlignment = "Left", TextSize = 17 })
ActivityTab:Toggle({ Title = "自动走到恶魔之王", Default = false, Callback = function(v)
	autoWalkBoss = v
	if v then startAutoWalkBoss() end
end })
ActivityTab:Toggle({ Title = "自动攻击恶魔之王", Default = false, Callback = function(v)
	autoAttackBoss = v
	if v then startAutoAttackBoss() end
end })
ActivityTab:Section({ Title = "裂缝", TextXAlignment = "Left", TextSize = 17 })
ActivityTab:Toggle({ Title = "自动前往裂缝", Default = false, Callback = function(v)
	autoGoRift = v
	if v then startAutoGoRift() end
end })

local PurchaseTab = Tabs.Purchase
PurchaseTab:Section({ Title = "自动升级", TextXAlignment = "Left", TextSize = 17 })
PurchaseTab:Toggle({ Title = "自动升级宠物格子", Default = false, Callback = function(v)
	autoUpgradePlot = v
	if v then startAutoUpgradePlot() end
end })
PurchaseTab:Section({ Title = "稿子商店", TextXAlignment = "Left", TextSize = 17 })
autoBuyPickaxeToggle = PurchaseTab:Toggle({ Title = "自动购买稿子", Default = false, Callback = function(v)
	autoBuyPickaxe = v
	if v then startAutoBuyPickaxe() end
end })
for i, item in ipairs(PICKAXE_SHOP) do
	PurchaseTab:Button({ Title = item.cn .. "稿子", Callback = function()
		buyPickaxe(i)
	end })
end
PurchaseTab:Section({ Title = "踪迹商店", TextXAlignment = "Left", TextSize = 17 })
autoBuyTrailToggle = PurchaseTab:Toggle({ Title = "自动购买踪迹", Default = false, Callback = function(v)
	autoBuyTrail = v
	if v then startAutoBuyTrail() end
end })
for i, item in ipairs(TRAIL_SHOP) do
	PurchaseTab:Button({ Title = item.cn .. "踪迹", Callback = function()
		buyTrail(i)
	end })
end
local antiLag = false
local antiLagTask = nil
local Lighting = game:GetService("Lighting")
local UserGS = nil
local function getUserGS()
	if not UserGS then
		pcall(function() UserGS = game:GetService("UserGameSettings") end)
	end
	return UserGS
end
local RS = nil
pcall(function() RS = game:GetService("RenderSettings") end)
local function deleteZoneDecor()
	local zoneBuilds = workspace.Build and workspace.Build:FindFirstChild("ZoneBuilds")
	if not zoneBuilds then return end
	local extraPaths = {
		{ "Zone10", "AlienMap" },
		{ "Zone9", "Galaxy/space aura" },
		{ "Zone9", "Stars" },
		{ "Zone8", "Build" },
		{ "Zone7", "Build" },
	}
	for _, spec in ipairs(extraPaths) do
		local zone = zoneBuilds:FindFirstChild(spec[1])
		if zone then
			local node = zone:FindFirstChild(spec[2])
			if node then
				pcall(function() node:Destroy() end)
			end
		end
	end
	for _, zone in ipairs(zoneBuilds:GetChildren()) do
		local decor = zone:FindFirstChild("Decor")
		if decor then
			local bones = decor:FindFirstChild("Bones")
			if bones then pcall(function() bones:Destroy() end) end
			local cactus = decor:FindFirstChild("Cactus")
			if cactus then pcall(function() cactus:Destroy() end) end
			pcall(function() decor:Destroy() end)
		end
	end
end
local function killZonePartsTextures()
	local zoneBuilds = workspace.Build and workspace.Build:FindFirstChild("ZoneBuilds")
	if not zoneBuilds then return end
	for _, zone in ipairs(zoneBuilds:GetChildren()) do
		local parts = zone:FindFirstChild("Parts")
		if parts then
			killTextures(parts)
		end
	end
end
local function deleteOtherPlots()
	local plotsFolder = workspace:FindFirstChild("Plots")
	if not plotsFolder then return end
	local myPlot = getMyPlot()
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot ~= myPlot then
			pcall(function() plot:Destroy() end)
		end
	end
end
local function killTextures(root)
	if not root then return end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("Decal") then
			pcall(function() d.Transparency = 1 end)
		elseif d:IsA("SurfaceAppearance") then
			pcall(function() d:Destroy() end)
		end
	end
end
local function applyGraphicsLow()
	local ug = getUserGS()
	if ug then
		pcall(function() ug:SetQualityLevel(1) end)
	end
	pcall(function() RS.AutoQualityEnabled = false end)
	pcall(function() RS.QualityLevel = 1 end)
	pcall(function() RS.GlobalShadows = false end)
	pcall(function() Lighting.GlobalShadows = false end)
	pcall(function() Lighting.ShadowSoftness = 0 end)
	pcall(function() Lighting.Technology = Enum.Technology.Compatibility end)
	pcall(function()
		for _, aa in ipairs(Enum.AntiAliasing:GetEnumItems()) do
			if string.find(string.lower(aa.Name), "none") then
				RS.AntiAliasing = aa
				break
			end
		end
	end)
	pcall(function()
		for _, mq in ipairs(Enum.MasterTextureQuality:GetEnumItems()) do
			if mq.Value == 0 then
				RS.MasterTextureQuality = mq
				break
			end
		end
	end)
end
local FX_CLASSES = {
	ParticleEmitter = true, Beam = true, Fire = true, Smoke = true,
	Sparkles = true, Trail = true, Explosion = true, Sound = true,
	PointLight = true, SurfaceLight = true, SpotLight = true,
}
local function killFx(root)
	for _, d in ipairs(root:GetDescendants()) do
		if FX_CLASSES[d.ClassName] then
			pcall(function() d:Destroy() end)
		end
	end
end
local function hideChar(ch)
	if not ch then return end
	for _, part in ipairs(ch:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 1
		end
	end
end
local function startAntiLag()
	if antiLagTask then return end
	pcall(function() deleteZoneDecor() end)
	pcall(function() killZonePartsTextures() end)
	pcall(function() deleteOtherPlots() end)
	pcall(function() killTextures(workspace) end)
	pcall(function() applyGraphicsLow() end)
	antiLagTask = task.spawn(function()
		while antiLag do
			pcall(function() killFx(workspace) end)
			pcall(function() deleteZoneDecor() end)
			pcall(function() killZonePartsTextures() end)
			pcall(function() deleteOtherPlots() end)
			pcall(function() killTextures(workspace) end)
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player then
					pcall(function() hideChar(p.Character) end)
				end
			end
			task.wait(5)
		end
		antiLagTask = nil
	end)
end
local function stopAntiLag()
	antiLag = false
end

local MainTab = Tabs.Main
MainTab:Section({ Title = "自动化(两个一起开的话优先开第1个再开第2个)", TextXAlignment = "Left", TextSize = 17 })
autoRunToggle = MainTab:Toggle({ Title = "自动打蛋", Default = false, Callback = function(v)
	autoRun = v
	unlockCharacter()
end })
MainTab:Toggle({ Title = "自动拿宠物", Default = false, Callback = function(v)
	autoPickup = v
	if not v and not autoRun then unlockCharacter() end
end })
MainTab:Dropdown({ Title = "拿宠物回家方式", Values = { "走回", "传送" }, Value = "走回", Callback = function(v)
	if type(v) == "table" then return end
	homeMethod = (v == "传送") and "teleport" or "walk"
end })

MainTab:Dropdown({ Title = "选择蛋类型", Values = EGG_OPTIONS, Value = {}, Multi = true, AllowNone = true, Callback = function(Values)
	selectedEggEnglish = {}
	if type(Values) == "table" then
		for _, d in ipairs(Values) do
			local cn = (type(d) == "table" and d.Title) or d
			local en = EGG_CN_TO_EN[cn]
			if en then selectedEggEnglish[en] = true end
		end
	end
end })
MainTab:Dropdown({ Title = "选择宠物品质", Values = PET_RARITY_OPTIONS, Value = {}, Multi = true, AllowNone = true, Callback = function(Values)
	selectedPetRarities = {}
	if type(Values) == "table" then
		for _, d in ipairs(Values) do
			local cn = (type(d) == "table" and d.Title) or d
			local en = RARITY_CN_TO_EN[cn] or cn
			selectedPetRarities[en] = true
		end
	end
end })

MainTab:Section({ Title = "其他", TextXAlignment = "Left", TextSize = 17 })
MainTab:Toggle({ Title = "自动装备最好宠物", Default = false, Callback = function(v)
	autoEquipBest = v
	if v then startAutoEquipBest() end
end })
MainTab:Toggle({ Title = "防挂机", Default = false, Callback = function(v)
	antiAFK = v
	if v then
		startAntiAFK()
	else
		stopAntiAFK()
	end
end })
MainTab:Toggle({ Title = "防卡顿优化", Default = true, Callback = function(v)
	antiLag = v
	if v then
		startAntiLag()
	else
		stopAntiLag()
	end
end })
Tabs.Treadmill:Section({ Title = "跑步机", TextXAlignment = "Left", TextSize = 17 })
Tabs.Treadmill:Toggle({ Title = "自动跑步机", Default = false, Callback = function(v)
	autoHome = v
	if v then startAutoHome() end
end })
Tabs.Treadmill:Toggle({ Title = "自动升级跑步机", Default = false, Callback = function(v)
	autoUpgradeTreadmill = v
	if v then startAutoUpgradeTreadmill() end
end })

MainTab:Section({ Title = "功能", TextXAlignment = "Left", TextSize = 17 })
AutoInteractToggle = MainTab:Toggle({ Title = "自动拾取", Default = false, Callback = function(v)
	autoInteract = v
	if v then
		startAutoInteract()
	else
		stopAutoInteract()
	end
end })
MainTab:Toggle({ Title = "自动攻击", Default = false, Callback = function(v)
	autoAttack = v
end })


local EspTab = Tabs.Esp
EspTab:Section({ Title = "透视开关", TextXAlignment = "Left", TextSize = 17 })
EspTab:Dropdown({ Title = "宠物透视品质筛选", Values = PET_RARITY_OPTIONS, Value = {}, Multi = true, AllowNone = true, Callback = function(Values)
	petEspFilter = {}
	if type(Values) == "table" then
		for _, d in ipairs(Values) do
			local cn = (type(d) == "table" and d.Title) or d
			local en = RARITY_CN_TO_EN[cn] or cn
			petEspFilter[en] = true
		end
	end
	for pet, cached in pairs(petEspCache) do
		if cached.billboard then cached.billboard:Destroy() end
		petEspCache[pet] = nil
	end
	if petEspEnabled then refreshPetEsp() end
end })
EspTab:Toggle({ Title = "宠物透视", Default = false, Callback = function(v)
	petEspEnabled = v
	if v then
		refreshPetEsp()
	else
		for pet, cached in pairs(petEspCache) do
			if cached.billboard then cached.billboard:Destroy() end
			petEspCache[pet] = nil
		end
	end
end })
EspTab:Dropdown({ Title = "蛋透视筛选", Values = EGG_OPTIONS, Value = {}, Multi = true, AllowNone = true, Callback = function(Values)
	eggEspFilter = {}
	if type(Values) == "table" then
		for _, d in ipairs(Values) do
			local cn = (type(d) == "table" and d.Title) or d
			eggEspFilter[cn] = true
		end
	end
	for egg, cached in pairs(eggEspCache) do
		if cached.billboard then cached.billboard:Destroy() end
		eggEspCache[egg] = nil
	end
	if eggEspEnabled then refreshEggEsp() end
end })
EspTab:Toggle({ Title = "蛋透视", Default = false, Callback = function(v)
	eggEspEnabled = v
	if v then
		refreshEggEsp()
	else
		for egg, cached in pairs(eggEspCache) do
			if cached.billboard then cached.billboard:Destroy() end
			eggEspCache[egg] = nil
		end
	end
end })

local UiTab = Tabs["UI 设置"]
UiTab:Section({ Title = "配置", TextXAlignment = "Left", TextSize = 17 })
UiTab:Paragraph({ Title = "自动保存", Desc = "配置随窗口 Folder 自动保存与加载" })
task.spawn(function()
	while true do
		if autoInteractLink then
			if not autoInteract then
				autoInteract = true
				startAutoInteract(LINK_INTERACT_INTERVAL)
			end
			if AutoInteractToggle and not AutoInteractToggle.Value then
				pcall(function() AutoInteractToggle:Set(true) end)
			end
			autoInteractLinked = true
		elseif autoInteractLinked then
			autoInteract = false
			stopAutoInteract()
			if AutoInteractToggle and AutoInteractToggle.Value then
				pcall(function() AutoInteractToggle:Set(false) end)
			end
			autoInteractLinked = false
		end
		task.wait(0.2)
	end
end)

task.spawn(function()
	while true do
		if autoPickup then
			local pet = findAnyPetToPickup()
			if pet then
				moveToPetAndBack(pet)
			elseif autoRun then
				farmAllZones()
			end
		elseif autoRun then
			farmAllZones()
		end
		task.wait(0.2)
	end
end)

task.spawn(function()
	while true do
		if autoAttack and char and char.Parent then
			local curHrp = char:FindFirstChild("HumanoidRootPart")
			if curHrp then
				if not autoRun then
					local curPos = curHrp.Position
					local bestPart, bestDist = nil, ATTACK_RANGE
					for _, zone in ipairs(getAllZones()) do
						local eggs = zone:FindFirstChild("Eggs")
						local source = eggs or zone
						for _, child in ipairs(source:GetChildren()) do
							local part = getEggPart(child)
							if part and part.Parent then
								local dist = (curPos - part.Position).Magnitude
								if dist < bestDist then
									bestDist = dist
									bestPart = part
								end
							end
						end
					end
					if bestPart then
						Event:FireServer(bestPart, 1)
					end
				end
			end
			task.wait(0.35)
		else
			task.wait(0.15)
		end
	end
end)

