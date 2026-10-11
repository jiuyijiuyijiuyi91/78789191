local repo = "https://raw.githubusercontent.com/ATLASTEAM01/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local ATTACK_RANGE = 200
local AUTO_INTERACT_RANGE = 12
local FALLBACK_SPEED = 16
local PICKUP_TRIGGER_INTERVAL = 0.03

local Event = ReplicatedStorage:WaitForChild("EggHitRequest")
local PICKUP_FOLDER = workspace:WaitForChild("AnimalPickups")
local PET_RETURN_POS = Vector3.new(-78.811653, 3.498025, -21.007202)

local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")

local autoRun = false
local autoRunToggle = nil
local autoAttack = false
local antiAFK = false
local antiAFKTask = nil
local autoPickup = false
local autoInteract = false
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
}

local RARITY_COLOR = {
	Common = "#FFFFFF", Uncommon = "#00FF00", Rare = "#00BFFF",
	Epic = "#A020F0", Legendary = "#FFD700", Mythic = "#FF69B4",
	Mythical = "#FF69B4", Divine = "#FFA500", Cosmic = "#8A2BE2",
	Secret = "#FF4500", Eternal = "#00FFFF",
	HUGE = "#FF1493", Huge = "#FF1493", TITANIC = "#FF0000", Titanic = "#FF0000",
	Celestial = "#FFE066", Hell = "#B22222",
}

local PET_RARITY_OPTIONS = { "普通", "罕见", "稀有", "史诗", "传说", "神话", "宇宙", "秘密", "永恒", "神圣", "天界", "地狱" }

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

local function getGroundY(pos)

	local ray = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -40, 0))
	if ray and ray.Instance then
		return ray.Position.Y
	end
	return pos.Y
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
	if h0 then anchorY = getGroundY(h0.Position) end
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
	humanoid = newChar:WaitForChild("Humanoid")
	hrp = newChar:WaitForChild("HumanoidRootPart")
	task.wait(0.3)
	updateSavedSpeed()
	isLocked = false
	if keepAliveConn then
		keepAliveConn:Disconnect()
		keepAliveConn = nil
	end
	if autoRun or autoPickup then
		lockCharacter()
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


local function getZoneGuardList()
	local guards = {}
	local zoneBuilds = workspace.Build and workspace.Build:FindFirstChild("ZoneBuilds")
	if not zoneBuilds then return guards end
	for _, zone in ipairs(zoneBuilds:GetChildren()) do
		for _, desc in ipairs(zone:GetDescendants()) do
			if desc:IsA("Model") and not desc:IsA("Folder") then
				local nm = string.lower(tostring(desc.Name))
				if not string.find(nm, "egg", 1, true) then
					local posPart = desc:FindFirstChild("HumanoidRootPart") or desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart")
					if posPart then
						table.insert(guards, { model = desc, part = posPart })
					end
				end
			end
		end
	end
	return guards
end

local function findNearestGuard(fromPos)
	local best, bestDist = nil, math.huge
	for _, g in ipairs(getZoneGuardList()) do
		local d = (g.part.Position - fromPos).Magnitude
		if d < bestDist then best, bestDist = g, d end
	end
	return best, bestDist
end

local function petGone(pet, fromPickup)
	if not pet or not pet.Parent then return true end
	if fromPickup and pet.Parent ~= PICKUP_FOLDER then return true end
	return false
end

local function panTo(targetPos, arriveDist, watchObj)
	if not char or not char.Parent then return false end
	if not autoRun and not autoPickup then return false end
	arriveDist = arriveDist or 2

	if keepAliveConn then
		keepAliveConn:Disconnect()
		keepAliveConn = nil
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

	local arrived = false
	local elapsed = 0
	while elapsed < 60 do
		if not autoRun and not autoPickup then
			pcall(function() humanoid:Move(Vector3.zero, true) end)
			return false
		end
		if watchObj and petGone(watchObj) then
			pcall(function() humanoid:Move(Vector3.zero, true) end)
			return false
		end

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
		if not curHrp then return false end
		local curPos = curHrp.Position
		local dir = Vector3.new(goal.X - curPos.X, 0, goal.Z - curPos.Z)
		if dir.Magnitude < arriveDist then arrived = true break end
		local toGoal = dir.Unit
		local cam = workspace.CurrentCamera
		local camCF = cam and cam.CFrame
		local camDir = camCF and camCF:VectorToObjectSpace(toGoal) or toGoal
		pcall(function() humanoid:Move(camDir, true) end)
		local dt = RunService.RenderStepped:Wait()
		elapsed += dt
	end

	pcall(function() humanoid:Move(Vector3.zero, true) end)
	return arrived
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
	Event:FireServer(eggPart, 1)
end

local function findNearbyPet(centerPos, radius)
	radius = radius or 25
	local closestPet, closestDist = nil, radius
	for _, pet in ipairs(PICKUP_FOLDER:GetChildren()) do
		local petPart = pet:IsA("BasePart") and pet or pet:FindFirstChildWhichIsA("BasePart")
		if petPart then
			local dist = (petPart.Position - centerPos).Magnitude
			if dist < closestDist then
				closestDist = dist
				closestPet = pet
			end
		end
	end
	return closestPet
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

local function isEggDead(obj)
	local hp = getEggHealth(obj)
	if hp == nil then return false end
	return hp <= 0
end

local PET_PREFIX_WORDS = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Mythical", "Cosmic", "Secret", "Eternal", "Divine", "HUGE", "Huge", "TITANIC", "Titanic", "Fortune", "Lucky", "Gold", "Sun", "Solar", "Starry", "Star", "Blackhole", "BlackHole", "Volcanic", "Lava", "Blossom", "Flower", "Bamboo", "Angel", "Holy", "Fallen", "FallenAngel", "Rift", "Void", "Sea", "Ocean", "Lake", "Frozen", "Ice", "Snow", "Yeti", "Rainbow", "Candy", "Tree", "Wood", "Rock", "Stone", "Forest", "Cactus", "Desert", "Bones", "Bone", "Skeleton", "Scorpion", "Easter", "Gooey", "Slime", "Sticky", "Swamp", "Water", "Aqua" }

local PET_PREFIX_CN_WORDS = { "普通", "罕见", "稀有", "史诗", "传说", "神话", "宇宙", "秘密", "永恒", "神圣", "巨大", "泰坦" }

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
	for _, cn in ipairs(PET_PREFIX_CN_WORDS) do
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

local function getPetRarity(cn)
	return PET_RARITY_CN[cn]
end

local RARITY_WORDS = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Mythical", "Cosmic", "Secret", "Eternal", "Divine", "HUGE", "Huge", "TITANIC", "Titanic", "Celestial", "Heaven", "Heavenly", "Hell", "Hades", "Infernal", "Inferno", "Underworld", "Nether" }

local RARITY_ALIAS_EN = {
	Mythical = "Mythic", Heaven = "Celestial", Heavenly = "Celestial",
	Hades = "Hell", Infernal = "Hell", Inferno = "Hell", Underworld = "Hell", Nether = "Hell",
}

local RARITY_CN_TO_EN = {
	["普通"] = "Common", ["罕见"] = "Uncommon", ["稀有"] = "Rare",
	["史诗"] = "Epic", ["传说"] = "Legendary", ["神话"] = "Mythic",
	["宇宙"] = "Cosmic", ["秘密"] = "Secret", ["永恒"] = "Eternal",
	["神圣"] = "Divine", ["天界"] = "Celestial", ["地狱"] = "Hell",
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

local function dumpPetStructure(pet)
	pcall(function()
		local special = {}
		local total = 0
		for _, k in ipairs(pet:GetDescendants()) do
			total += 1
			local cn = k.ClassName
			if cn == "ProximityPrompt" or cn == "ClickDetector" or cn == "RemoteEvent" or cn == "RemoteFunction" or cn == "Humanoid" then
				table.insert(special, tostring(k.Name) .. ":" .. cn)
			end
		end
		local top = {}
		for _, k in ipairs(pet:GetChildren()) do
			table.insert(top, k.ClassName)
		end
		print("宠物诊断 name=" .. tostring(pet.Name) .. " 子对象=" .. table.concat(top, ",") .. " 特殊=" .. table.concat(special, ",") .. " 描述=" .. tostring(total))
	end)
end

local function findAnyPetToPickup()
	local bestPet, bestDist = nil, math.huge
	for _, pet in ipairs(PICKUP_FOLDER:GetChildren()) do
		local part = getPetPart(pet)
		if part and matchesSelectedPetName(pet) then
			local curHrp = char and char:FindFirstChild("HumanoidRootPart")
			if curHrp then
				local d = (part.Position - curHrp.Position).Magnitude
				if d < bestDist then
					bestDist = d
					bestPet = pet
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

local function dumpPickupRemotes()
	pcall(function()
		local hits = {}
		local kw = { "pick", "collect", "claim", "take", "grab", "steal", "get", "receive", "pet", "egg" }
		local function scan(obj)
			for _, d in ipairs(obj:GetDescendants()) do
				if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
					local n = string.lower(tostring(d.Name))
					for _, k in ipairs(kw) do
						if string.find(n, k, 1, true) then
							table.insert(hits, tostring(d.Parent and d.Parent.Name or "?") .. "." .. d.Name .. ":" .. d.ClassName)
							break
						end
					end
				end
			end
		end
		for _, r in ipairs({ workspace, game:GetService("ReplicatedStorage") }) do
			if r then scan(r) end
		end
		if #hits > 0 then
			print("宠物远程 " .. table.concat(hits, ","))
		else
			print("宠物远程 无")
		end
	end)
end

local pickupBusy = false


local homeMethod = "walk"
local GUARD_SAFE_DIST = 16
local GUARD_TELEPORT_WAIT = 2
local TEMP_TELEPORT_POS = Vector3.new(-75.241516, 3.498025, 13.681024)
local HOME_TELEPORT_LOOPS = 1


local fullLockConn = nil
local fullLockSnap = {}

local FULL_LOCK_SINK = 3

local function lockCharacterFull()
	if fullLockConn then return end
	if not char or not humanoid or not humanoid.Parent then return end
	pcall(function()
		humanoid.PlatformStand = true
		humanoid.JumpPower = 0
	end)
	local dy = 0
	pcall(function()
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local groundY = getGroundY(hrp.Position)
			local lowestBottom = hrp.Position.Y
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					local bottom = part.Position.Y - part.Size.Y / 2
					if bottom < lowestBottom then
						lowestBottom = bottom
					end
				end
			end
			dy = (groundY - FULL_LOCK_SINK) - lowestBottom
		end
	end)
	table.clear(fullLockSnap)
	local sinkCF = CFrame.new(0, dy, 0)
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CFrame = part.CFrame * sinkCF
			fullLockSnap[part] = part.CFrame
		end
	end
	fullLockConn = RunService.Heartbeat:Connect(function()
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

local function teleportHomeViaGuard()

	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local guards = getZoneGuardList()
	print("[传送回家] 扫描到守卫 " .. #guards .. " 个")
	local guard, guardDist = findNearestGuard(hrp.Position)
	if not guard then
		print("[传送回家] 未找到守卫，退回走路回家")
		lockCharacter()
		local ok = panTo(PET_RETURN_POS)
		unlockCharacter()
		return ok
	end
	local guardPart = guard.part
	print("[传送回家] 最近守卫=" .. guard.model.Name .. " 距离=" .. string.format("%.1f", guardDist) .. "m")
	if guardDist > GUARD_SAFE_DIST then
		print("[传送回家] 走向守卫安全距离 " .. GUARD_SAFE_DIST .. "m")
		lockCharacter()
		if not panTo(guardPart.Position, GUARD_SAFE_DIST) then
			print("[传送回家] 走路失败，取消本次传送")
			unlockCharacter()
			return false
		end
	end
	print("[传送回家] 已到安全距离，全身锁定 2 秒")
	lockCharacterFull()

	local t = 0
	while t < GUARD_TELEPORT_WAIT do
		if not autoRun and not autoPickup then
			unlockCharacterFull()
			return false
		end
		local dt = RunService.Heartbeat:Wait()
		t += dt
	end



	local originPos = hrp.Position
	unlockCharacterFull()
	for i = 1, HOME_TELEPORT_LOOPS do
		if not autoRun and not autoPickup then
			print("[传送回家] 已停止，中断循环传送")
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
		print("[传送回家] 第 " .. i .. "/" .. HOME_TELEPORT_LOOPS .. " 次传送完成")
		task.wait(1)
	end
	return true
end

local function doMoveToPetAndBack(pet)
	local fromPickupFolder = pet.Parent == PICKUP_FOLDER
	while not petGone(pet, fromPickupFolder) do
		local petPart = getPetPart(pet)
		if not petPart then break end

		local interactions = collectPetInteractions(pet)
		local targetPos = petPart.Position
		if #interactions > 0 then
			targetPos = interactions[1].part.Position
		end

		local nearTarget = false
		if #interactions > 0 then
			local myPos = char and char:GetPivot().Position
			if myPos and (interactions[1].part.Position - myPos).Magnitude <= AUTO_INTERACT_RANGE then
				nearTarget = true
			end
		end

		if nearTarget then
			unlockCharacter()
			pcall(function() humanoid:Move(Vector3.zero, true) end)
		else
			lockCharacter()
			if not panTo(targetPos, 1.2) then
				unlockCharacter()
				return false
			end
			pcall(function() humanoid:Move(Vector3.zero, true) end)
		end

		local gotIt = false
		if #interactions > 0 then
			local startT = os.clock()
			while os.clock() - startT < 2 do
				if not autoRun and not autoPickup then break end
				if petGone(pet, fromPickupFolder) then gotIt = true break end
				for _, it in ipairs(interactions) do
					if it.kind == "prompt" then
						if it.obj.Enabled then triggerPrompt(it.obj) end
					else
						triggerClick(it.obj)
					end
				end
				if not waitOrStop(PICKUP_TRIGGER_INTERVAL) then break end
			end
			if petGone(pet, fromPickupFolder) then gotIt = true end
		end

		if gotIt then
			if homeMethod == "teleport" then
				if not teleportHomeViaGuard() then
					unlockCharacter()
					return false
				end
				return true
			end
			lockCharacter()
			if not panTo(PET_RETURN_POS) then
				unlockCharacter()
				return false
			end
			unlockCharacter()
			return true
		end

		if not autoRun and not autoPickup then
			unlockCharacter()
			return false
		end
		if not fromPickupFolder then break end
	end
	unlockCharacter()
	return true
end

local function moveToPetAndBack(pet)
	if pickupBusy then return false end
	pickupBusy = true
	local ok, res = pcall(doMoveToPetAndBack, pet)
	pickupBusy = false
	if ok then return res end
	return false
end

local function startAutoInteract()
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
			task.wait(PICKUP_TRIGGER_INTERVAL)
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
	print("购买稿子：" .. PICKAXE_SHOP[id].name)
end

local function buyTrail(id)
	fireShop(TrailShopRequest, "Buy", id)
	print("购买踪迹：" .. TRAIL_SHOP[id].name)
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
			game:GetService("ReplicatedStorage"):WaitForChild("UpgradeTreadmillRequest"):FireServer()
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
			game:GetService("ReplicatedStorage"):WaitForChild("UpgradePlotRequest"):FireServer()
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
			game:GetService("ReplicatedStorage"):WaitForChild("PetsInventoryRemote"):FireServer(unpack(args))
			task.wait(0.5)
		end
		equipBestConn = nil
	end)
end

local function getMyPlot()
	local plotsFolder = workspace:FindFirstChild("Plots")
	if not plotsFolder then
		print("自动回家：找不到 workspace.Plots")
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
		print("自动回家：归属检测未命中，使用兜底自家 Base_2")
		return fallback
	end


	pcall(function()
		print("自动回家：玩家名=" .. player.Name .. " ID=" .. player.UserId)
		for _, ch in ipairs(plotsFolder:GetChildren()) do
			local parts = { "[" .. tostring(ch.ClassName) .. "]" .. ch.Name }
			for _, c2 in ipairs(ch:GetChildren()) do
				local extra = ""
				if c2:IsA("ValueBase") then
					extra = "=" .. tostring(c2.Value)
				elseif c2:IsA("Model") or c2:IsA("Folder") then
					local subn = {}
					for _, c3 in ipairs(c2:GetChildren()) do
						table.insert(subn, c3.Name)
					end
					extra = "{子:" .. table.concat(subn, ",") .. "}"
				end
				table.insert(parts, c2.Name .. extra)
			end
			print("自动回家Plots[" .. ch.Name .. "]：" .. table.concat(parts, " | "))
		end
	end)
	return nil
end

local function walkToPlot(targetPos, arriveDist)
	if not char or not char.Parent then return false end
	arriveDist = arriveDist or 2
	if keepAliveConn then
		keepAliveConn:Disconnect()
		keepAliveConn = nil
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
	local elapsed = 0
	while elapsed < 30 do
		if not autoHome then
			pcall(function() humanoid:Move(Vector3.zero, true) end)
			return false
		end
		local curHrp = char:FindFirstChild("HumanoidRootPart")
		if not curHrp then return false end
		local curPos = curHrp.Position
		local dir = Vector3.new(goal.X - curPos.X, 0, goal.Z - curPos.Z)
		if dir.Magnitude < arriveDist then break end
		local toGoal = dir.Unit
		local cam = workspace.CurrentCamera
		local camCF = cam and cam.CFrame
		local camDir = camCF and camCF:VectorToObjectSpace(toGoal) or toGoal
		pcall(function() humanoid:Move(camDir, true) end)
		local dt = RunService.RenderStepped:Wait()
		elapsed += dt
	end
	pcall(function() humanoid:Move(Vector3.zero, true) end)
	return true
end

local autoHomeConn = nil
local function startAutoHome()
	if autoHomeConn then return end
	autoHomeConn = task.spawn(function()
		while autoHome do
			local plot = getMyPlot()
			if plot then
				local treadmill = plot:FindFirstChild("Futuristic Treadmill")
				local homePart = plot:FindFirstChild("Baseplate") or plot.PrimaryPart or plot:FindFirstChildWhichIsA("BasePart")
				local treadPart = nil
				if treadmill then
					if treadmill:IsA("BasePart") then
						treadPart = treadmill
					else
						treadPart = treadmill:FindFirstChildWhichIsA("BasePart")
					end
				end
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

local function stopAutoRun()
	autoRun = false
	unlockCharacter()
	if autoRunToggle then
		pcall(function() autoRunToggle:SetValue(false) end)
	end
end

local function panToPickupAware(targetPos, arriveDist)
	if not char or not char.Parent then return false end
	if not autoRun and not autoPickup then return false end
	arriveDist = arriveDist or 2

	if keepAliveConn then
		keepAliveConn:Disconnect()
		keepAliveConn = nil
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

	local arrived = false
	local elapsed = 0
	while elapsed < 60 do
		if not autoRun and not autoPickup then
			pcall(function() humanoid:Move(Vector3.zero, true) end)
			return false
		end
		if autoPickup and findAnyPetToPickup() then
			pcall(function() humanoid:Move(Vector3.zero, true) end)
			return "pet"
		end

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
		if not curHrp then return false end
		local curPos = curHrp.Position
		local dir = Vector3.new(goal.X - curPos.X, 0, goal.Z - curPos.Z)
		if dir.Magnitude < arriveDist then arrived = true break end
		local toGoal = dir.Unit
		local cam = workspace.CurrentCamera
		local camCF = cam and cam.CFrame
		local camDir = camCF and camCF:VectorToObjectSpace(toGoal) or toGoal
		pcall(function() humanoid:Move(camDir, true) end)
		local dt = RunService.RenderStepped:Wait()
		elapsed += dt
	end

	pcall(function() humanoid:Move(Vector3.zero, true) end)
	return arrived
end

local function handlePetPriority()
	if not autoPickup then return end
	local pet = findAnyPetToPickup()
	if pet then
		moveToPetAndBack(pet)
	end
end

local function approachWithPetPriority(standPos)
	local r = panToPickupAware(standPos)
	while r == "pet" do
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

							if not approachWithPetPriority(standPos) then return end
							lockCharacter()

							local timeout = eggHp and 60 or 10
							local elapsed = 0
							local attackCd = 0
							while elapsed < timeout do
								if not autoRun then return end

								if not part.Parent then break end
								eggHp = getEggHealth(egg)
								if eggHp ~= nil and eggHp <= 0 then break end

								if autoPickup and findAnyPetToPickup() then
									unlockCharacter()
									if not approachWithPetPriority(standPos) then return end
									lockCharacter()
									if not part.Parent then break end
									eggHp = getEggHealth(egg)
									if eggHp ~= nil and eggHp <= 0 then break end
								end

								local h = char:FindFirstChild("HumanoidRootPart")
								if h then
									local curPos = h.Position
									local eggPosNow = part.Position
									h.CFrame = CFrame.lookAt(
										Vector3.new(curPos.X, curPos.Y, curPos.Z),
										Vector3.new(eggPosNow.X, curPos.Y, eggPosNow.Z)
									)
								end

								local dt = RunService.Heartbeat:Wait()
								attackCd += dt
								if attackCd >= 0.35 then
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
}

local function normalizeEggName(raw, obj)
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
	if direct then return direct end

	if obj then
		for _, d in ipairs(obj:GetDescendants()) do
			if d ~= obj and d.Name then
				local sub = matchString(d.Name)
				if sub then return sub end
			end
		end
	end

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
	return luck, price
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
		local luck, price = scanEggAttributes(obj)
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

		local eggWeight = getEggWeight(eggName)
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
	for _, pet in ipairs(PICKUP_FOLDER:GetChildren()) do
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

PICKUP_FOLDER.ChildAdded:Connect(function(pet)
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

PICKUP_FOLDER.ChildRemoved:Connect(function(pet)
	removeEsp(pet, petEspCache)
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

local Window = Library:CreateWindow({
	Title = "打破并偷走一个鸡蛋",
	Footer = "XJW",
	Center = true,
	AutoShow = true,
})

local Tabs = {
	Announce = Window:AddTab("公告", "info"),
	Main = Window:AddTab("主页", "house"),
	Purchase = Window:AddTab("购买", "coins"),
	Activity = Window:AddTab("活动", "flame"),
	Esp = Window:AddTab("透视", "eye"),
	["UI 设置"] = Window:AddTab("UI 设置", "settings"),
}

local AnnounceBox = Tabs.Announce:AddLeftGroupbox("公告")
local announceShown = pcall(function()
	AnnounceBox:AddLabel("AnnounceText", { Text = "10月11日: 传送回拿宠物已绕过反作弊" })
end)
if not announceShown then
	pcall(function()
		AnnounceBox:AddButton({ Text = "10月11日: 传送回拿宠物已绕过反作弊", Func = function() end })
	end)
end

local BossBox = Tabs.Activity:AddLeftGroupbox("恶魔之王")
BossBox:AddToggle("AutoWalkBossToggle", { Text = "自动走到恶魔之王", Default = false }):OnChanged(function(v)
	autoWalkBoss = v
	if v then startAutoWalkBoss() end
end)

BossBox:AddToggle("AutoAttackBossToggle", { Text = "自动攻击恶魔之王", Default = false }):OnChanged(function(v)
	autoAttackBoss = v
	if v then startAutoAttackBoss() end
end)

local RiftBox = Tabs.Activity:AddLeftGroupbox("裂缝")
RiftBox:AddToggle("AutoGoRiftToggle", { Text = "自动前往裂缝", Default = false }):OnChanged(function(v)
	autoGoRift = v
	if v then startAutoGoRift() end
end)

local UpgradeBox = Tabs.Purchase:AddLeftGroupbox("自动升级")
UpgradeBox:AddToggle("AutoUpgradePlotToggle", { Text = "自动升级宠物格子", Default = false }):OnChanged(function(v)
	autoUpgradePlot = v
	if v then startAutoUpgradePlot() end
end)

local PickaxeBox = Tabs.Purchase:AddLeftGroupbox("稿子商店")
autoBuyPickaxeToggle = PickaxeBox:AddToggle("AutoBuyPickaxeToggle", { Text = "自动购买稿子", Default = false })
autoBuyPickaxeToggle:OnChanged(function(v)
	autoBuyPickaxe = v
	if v then
		startAutoBuyPickaxe()
	end
end)
for i, item in ipairs(PICKAXE_SHOP) do
	PickaxeBox:AddButton({ Text = item.cn .. "稿子", Func = function()
		buyPickaxe(i)
	end })
end

local TrailBox = Tabs.Purchase:AddRightGroupbox("踪迹商店")
autoBuyTrailToggle = TrailBox:AddToggle("AutoBuyTrailToggle", { Text = "自动购买踪迹", Default = false })
autoBuyTrailToggle:OnChanged(function(v)
	autoBuyTrail = v
	if v then
		startAutoBuyTrail()
	end
end)
for i, item in ipairs(TRAIL_SHOP) do
	TrailBox:AddButton({ Text = item.cn .. "踪迹", Func = function()
		buyTrail(i)
	end })
end

local MainBox = Tabs.Main:AddLeftGroupbox("自动化(两个一起开的话优先开第1个再开第2个)")

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
	print("防卡顿：已删除9区Decor(含各区Bones/Cactus)、关闭9区地面(Parts)纹理、删除其他家、关闭全图纹理并设为最低画质；分辨率/显卡驱动/后台程序请游戏外手动处理")
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

autoRunToggle = MainBox:AddToggle("AutoRunToggle", { Text = "自动打蛋", Default = false })
autoRunToggle:OnChanged(function(v)
	autoRun = v
	if v then
		if hasSelectedEgg() and not pickupBusy then
			lockCharacter()
		else
			unlockCharacter()
		end
	else
		unlockCharacter()
	end
end)

MainBox:AddToggle("AutoPickupToggle", { Text = "自动拿宠物", Default = false }):OnChanged(function(v)
	autoPickup = v
	if v then
		if autoRun and not pickupBusy then lockCharacter() end
	else
		if not autoRun then unlockCharacter() end
	end
end)

MainBox:AddDropdown("HomeMethodDropdown", {
	Values = { "走回", "传送(开自动拾取)" },
	Default = "走回",
	Text = "拿宠物方式",
}):OnChanged(function(v)
	if type(v) == "table" then return end
	homeMethod = (v == "传送") and "teleport" or "walk"
end)

local OtherBox = Tabs.Main:AddLeftGroupbox("其他")
OtherBox:AddToggle("AutoEquipBestToggle", { Text = "自动装备最好宠物", Default = false }):OnChanged(function(v)
	autoEquipBest = v
	if v then startAutoEquipBest() end
end)

OtherBox:AddToggle("AntiAFKToggle", { Text = "防挂机", Default = false }):OnChanged(function(v)
	antiAFK = v
	if v then
		startAntiAFK()
	else
		stopAntiAFK()
	end
end)

OtherBox:AddToggle("AntiLagToggle", { Text = "防卡顿优化", Default = false }):OnChanged(function(v)
	antiLag = v
	if v then
		startAntiLag()
	else
		stopAntiLag()
	end
end)

local TreadmillBox = Tabs.Main:AddLeftGroupbox("跑步机")
TreadmillBox:AddToggle("AutoHomeToggle", { Text = "自动跑步机", Default = false }):OnChanged(function(v)
	autoHome = v
	if v then startAutoHome() end
end)

TreadmillBox:AddToggle("AutoUpgradeTreadmillToggle", { Text = "自动升级跑步机", Default = false }):OnChanged(function(v)
	autoUpgradeTreadmill = v
	if v then startAutoUpgradeTreadmill() end
end)

local FuncBox = Tabs.Main:AddLeftGroupbox("功能")
FuncBox:AddToggle("AutoInteractToggle", { Text = "自动拾取", Default = false }):OnChanged(function(v)
	autoInteract = v
	if v then
		startAutoInteract()
	else
		stopAutoInteract()
	end
end)

FuncBox:AddToggle("AutoAttackToggle", { Text = "自动攻击", Default = false }):OnChanged(function(v)
	autoAttack = v
end)

local SelectBox = Tabs.Main:AddRightGroupbox("选择设置")

SelectBox:AddDropdown("EggSelect", {
	Values = EGG_OPTIONS,
	Default = {},
	Multi = true,
	Text = "选择打蛋类型(没选=全部)",
}):OnChanged(function(Values)
	selectedEggEnglish = {}
	if type(Values) == "table" then
		for k, _ in pairs(Values) do
			local cn = tostring(k)
			local en = EGG_CN_TO_EN[cn]
			if en then selectedEggEnglish[en] = true end
		end
	end
	if autoRun then
		if hasSelectedEgg() and not pickupBusy then
			lockCharacter()
		else
			unlockCharacter()
		end
	end
end)

SelectBox:AddDropdown("PetSelect", {
	Values = PET_RARITY_OPTIONS,
	Default = {},
	Multi = true,
	Text = "选择宠物品质(没选=全部)",
}):OnChanged(function(Values)
	selectedPetRarities = {}
	if type(Values) == "table" then
		for k, _ in pairs(Values) do
			local cn = tostring(k)
			local en = RARITY_CN_TO_EN[cn] or cn
			selectedPetRarities[en] = true
		end
	end
end)

local EspBox = Tabs.Esp:AddLeftGroupbox("透视开关")

EspBox:AddDropdown("PetEspFilter", {
	Values = PET_RARITY_OPTIONS,
	Default = {},
	Multi = true,
	Text = "宠物透视品质筛选(没选=全部)",
}):OnChanged(function(Values)
	petEspFilter = {}
	if type(Values) == "table" then
		for k, _ in pairs(Values) do
			local cn = tostring(k)
			local en = RARITY_CN_TO_EN[cn] or cn
			petEspFilter[en] = true
		end
	end
	for pet, cached in pairs(petEspCache) do
		if cached.billboard then cached.billboard:Destroy() end
		petEspCache[pet] = nil
	end
	if petEspEnabled then refreshPetEsp() end
end)

EspBox:AddToggle("PetEspToggle", { Text = "宠物透视", Default = false }):OnChanged(function(v)
	petEspEnabled = v
	if v then
		refreshPetEsp()
	else
		for pet, cached in pairs(petEspCache) do
			if cached.billboard then cached.billboard:Destroy() end
			petEspCache[pet] = nil
		end
	end
end)

EspBox:AddDropdown("EggEspFilter", {
	Values = EGG_OPTIONS,
	Default = {},
	Multi = true,
	Text = "蛋透视筛选(没选=全部)",
}):OnChanged(function(Values)
	eggEspFilter = {}
	if type(Values) == "table" then
		for k, _ in pairs(Values) do
			eggEspFilter[tostring(k)] = true
		end
	end
	for egg, cached in pairs(eggEspCache) do
		if cached.billboard then cached.billboard:Destroy() end
		eggEspCache[egg] = nil
	end
	if eggEspEnabled then refreshEggEsp() end
end)

EspBox:AddToggle("EggEspToggle", { Text = "蛋透视", Default = false }):OnChanged(function(v)
	eggEspEnabled = v
	if v then
		refreshEggEsp()
	else
		for egg, cached in pairs(eggEspCache) do
			if cached.billboard then cached.billboard:Destroy() end
			eggEspCache[egg] = nil
		end
	end
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
SaveManager:SetFolder("EggAuto/Configs")
SaveManager:BuildConfigSection(Tabs["UI 设置"])
ThemeManager:ApplyToTab(Tabs["UI 设置"])
SaveManager:LoadAutoloadConfig()

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

