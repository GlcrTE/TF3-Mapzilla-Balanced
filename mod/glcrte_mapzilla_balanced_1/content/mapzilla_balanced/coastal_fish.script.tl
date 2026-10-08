-- Mapzilla Balanced - coastal fish
-- Towns at the coast ask for fish more often than inland towns.
--
-- The game picks a town's needs in two places: the engine picks the first
-- ones when the map is created, and the base game script
-- (towns/town_growth.script) adds more as the town levels up. Neither can be
-- steered from the map generator, so this script looks at the needs after
-- they are picked. Each time a coastal town gets a new commercial need of
-- the same tier as fish (meat or vegetables), and it doesn't need fish yet,
-- the need is turned into fish with a chance of CONFIG.swapChance. A town
-- that turned a need down rolls again on its next one, so the chance grows
-- with the town's level. Inland towns are left alone.
--
-- A town is coastal if water covers at least CONFIG.coastShare of the land
-- within CONFIG.radius of its centre. A river through the town covers about
-- 5% of that; a big lake next to it can count as coast.
--
-- Fish has to be produced on the map (the base game's rule for new needs).
-- On a new game the script waits up to CONFIG.graceDays for that. When the
-- mod is added to a running game, the needs towns already have stay as they
-- are; only needs they get from then on can turn into fish.

local MOD_TAG <const> = "[Mapzilla Balanced]"

local CONFIG <const> = {
	-- metres around the town centre that are looked at
	radius = 1000,
	-- spacing of the water samples in that circle, metres
	step = 100,
	-- share of the circle that must be water for a coastal town
	coastShare = 0.15,
	-- chance that a coastal town's new need (meat or vegetables) becomes fish
	swapChance = 0.5,
	-- the towns are checked this many times per in-game day
	checksPerDay = 16,
	-- a new game waits this many days for fish to be produced
	graceDays = 1,
}

local COMMERCIAL <const> = 2

---------------------------------------------------------------------------
-- Rules (pure, no game API)
---------------------------------------------------------------------------

local function isCoastal(waterShare : number) : boolean
	return waterShare >= CONFIG.coastShare
end

-- A fixed number in [0, 1) for this town and cargo type, so a save that is
-- loaded again makes the same choices.
local function roll(town : integer, cargo : integer) : number
	local h = (town * 73856093 + cargo * 19349663) % 1000003
	return h / 1000003
end

-- The index in `commercial` (the town's commercial needs, cargo type ids)
-- to turn into fish, or nil. `seen` holds the needs rolled for before;
-- `isFish` and `canSwap` tell fish and needs of the same tier as fish.
local function swapIndex(town : integer, commercial : {integer}, seen : {integer : boolean},
		isFish : function(integer) : boolean, canSwap : function(integer) : boolean) : integer
	for _, cargo in ipairs(commercial) do
		if isFish(cargo) then
			return nil
		end
	end
	for i, cargo in ipairs(commercial) do
		if not seen[cargo] and canSwap(cargo) and roll(town, cargo) < CONFIG.swapChance then
			return i
		end
	end
	return nil
end

---------------------------------------------------------------------------
-- Game
---------------------------------------------------------------------------

local record TownState
	coastal : boolean
	-- commercial needs already rolled for
	seen : {integer}
end

local record State
	-- town entity -> what is known about it
	towns : {integer : TownState}
end

local errorReported = false

local function reportError(err : any)
	if not errorReported then
		errorReported = true
		debugPrint(MOD_TAG .. " error: " .. tostring(err))
	end
end

local function gameTime() : integer
	local timeComp : Engine.Component.GameTime =
		api.engine.getComponent(api.engine.util.getWorld(), api.type.ComponentType.GAME_TIME)
	return timeComp.gameTime
end

local function waterShare(townEntity : Engine.Entity) : number
	local bv = api.engine.getComponent(townEntity, api.type.ComponentType.BOUNDING_VOLUME) as Engine.Component.BoundingVolume
	if bv == nil then
		return 0
	end
	local cx = (bv.bbox.min.x + bv.bbox.max.x) * 0.5
	local cy = (bv.bbox.min.y + bv.bbox.max.y) * 0.5
	local r, step = CONFIG.radius, CONFIG.step
	local samples, wet = 0, 0
	for dx = -r, r, step do
		for dy = -r, r, step do
			if dx * dx + dy * dy <= r * r then
				local p = api.type.Vec2f.new(cx + dx, cy + dy)
				if api.engine.terrain.isValidCoordinate(p) then
					samples = samples + 1
					if api.engine.terrain.isOnWater(p) then
						wet = wet + 1
					end
				end
			end
		end
	end
	return samples > 0 and wet / samples or 0
end

local record Fish
	-- the fish cargo type that is produced on the map, nil if none
	produced : integer
	ids : {integer : boolean}
	tier : integer
	-- cargo type id -> tier of its category
	tiers : {integer : integer}
end

local function findFish() : Fish
	local economy = api.res.economyRep.get(api.res.economyRep.find(api.res.getBaseConfig().economyId))
	local fish : Fish = { ids = {}, tiers = {} }
	local all : {integer} = {}
	for id in pairs(api.res.cargoTypeRep.getAll()) do
		table.insert(all, id as integer)
	end
	table.sort(all)
	for _, id in ipairs(all) do
		local cargoType = api.res.cargoTypeRep.get(id as CargoTypeId)
		local cat = cargoType.category ~= "" and economy.cargoCategories[cargoType.category] or nil
		if cat ~= nil then
			fish.tiers[id] = cat.tier
			if cargoType.category == "fish" then
				fish.ids[id] = true
				fish.tier = cat.tier
				if fish.produced == nil and api.engine.util.stock.isCargoTypeCurrentlyProduced(id as CargoTypeId) then
					fish.produced = id
				end
			end
		end
	end
	return fish
end

-- Rolls for the town's new commercial needs; returns true if the state changed.
local function checkTown(townEntity : Engine.Entity, ts : TownState, fish : Fish, recordOnly : boolean) : boolean
	local town = api.engine.getComponent(townEntity, api.type.ComponentType.TOWN) as Engine.Component.Town
	local needs : {{integer}} = {}
	for k = 1, #town.cargoNeeds do
		needs[k] = {}
		for _, cargoAndFactor in ipairs(town.cargoNeeds[k]) do
			table.insert(needs[k], cargoAndFactor[1] as integer)
		end
	end
	local commercial = needs[COMMERCIAL] or {}

	local seen : {integer : boolean} = {}
	for _, cargo in ipairs(ts.seen) do
		seen[cargo] = true
	end
	local changed = false
	for _, cargo in ipairs(commercial) do
		if not seen[cargo] then
			changed = true
		end
	end
	if not changed then
		return false
	end

	if ts.coastal and not recordOnly and fish.produced ~= nil then
		local i = swapIndex(townEntity as integer, commercial, seen,
			function(c : integer) : boolean return fish.ids[c] end,
			function(c : integer) : boolean return not fish.ids[c] and fish.tiers[c] == fish.tier end)
		if i ~= nil then
			seen[commercial[i]] = true
			commercial[i] = fish.produced
			api.cmd.sendCommand(api.cmd.makeTownUpdateCargoNeedsCmd(townEntity, needs as {{CargoTypeId}}, true))
		end
	end

	for _, cargo in ipairs(commercial) do
		seen[cargo] = true
	end
	ts.seen = {}
	for cargo in pairs(seen) do
		table.insert(ts.seen, cargo)
	end
	table.sort(ts.seen)
	return true
end

-- game time this Lua state last checked the towns
local lastCheck : integer = nil

local function update(state : GameScriptState<State>)
	local now = gameTime()
	local day = api.util.getDefaultDayDuration()
	if lastCheck ~= nil and now >= lastCheck and now - lastCheck < day / CONFIG.checksPerDay then
		return
	end
	lastCheck = now

	local s = state:get()
	local fish = findFish()
	local isNew = s == nil or s.towns == nil
	if isNew and fish.produced == nil and now < day * CONFIG.graceDays then
		-- new game: fishing grounds may not have produced yet
		return
	end
	-- added to a running game: keep the needs towns already have
	local recordOnly = isNew and now >= day * CONFIG.graceDays
	if isNew then
		s = { towns = {} }
	end

	local changed = isNew
	api.engine.forEachEntityWithComponent(function(townEntity : Engine.Entity)
		local key = townEntity as integer
		local ts = s.towns[key]
		if ts == nil then
			ts = { coastal = isCoastal(waterShare(townEntity)), seen = {} }
			s.towns[key] = ts
			changed = true
		end
		if checkTown(townEntity, ts, fish, recordOnly) then
			changed = true
		end
	end, api.type.ComponentType.TOWN)

	if changed then
		state:set(s)
	end
end

local coastalFish = {}

function coastalFish.update(_userParams : table, state : GameScriptState<State>, dt : number) : any
	if dt == 0.0 then
		return nil
	end
	local ok, err : boolean, any = pcall(update, state)
	if not ok then
		reportError(err)
	end
	return nil
end

-- exposed for tests
;(coastalFish as any as {string : any})["rules"] = {
	CONFIG = CONFIG,
	isCoastal = isCoastal,
	roll = roll,
	swapIndex = swapIndex,
}

return coastalFish
