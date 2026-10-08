-- Tests for the rules of coastal_fish.script.tl.
-- Run through tools/check.py, which passes a loader for the compiled mod scripts.

return function(load)
	local r = load("mapzilla_balanced/coastal_fish.script.tl").rules
	local results = {}

	local function test(name, fn)
		local ok, err = pcall(fn)
		table.insert(results, { name, ok, err and tostring(err) or "" })
	end

	local FISH, MEAT, VEG, CLOTHES = 10, 11, 12, 20
	local function isFish(c) return c == FISH end
	local function canSwap(c) return c == MEAT or c == VEG end

	test("a town 0.15 water is coastal, a river (5%) is not", function()
		assert(r.isCoastal(0.15))
		assert(r.isCoastal(0.5))
		assert(not r.isCoastal(0.05))
	end)

	test("rolls are in [0, 1) and repeatable", function()
		for town = 1, 500 do
			local a = r.roll(town * 37, MEAT)
			assert(a >= 0 and a < 1, tostring(a))
			assert(a == r.roll(town * 37, MEAT))
		end
	end)

	test("about half of the coastal towns turn their first need into fish", function()
		local swapped, n = 0, 2000
		for i = 1, n do
			if r.swapIndex(1000 + i * 7, { MEAT }, {}, isFish, canSwap) == 1 then
				swapped = swapped + 1
			end
		end
		local share = swapped / n
		assert(math.abs(share - r.CONFIG.swapChance) < 0.05, tostring(share))
	end)

	test("a town that needs fish keeps its needs", function()
		for town = 1, 200 do
			assert(r.swapIndex(town, { FISH, MEAT }, {}, isFish, canSwap) == nil)
		end
	end)

	test("needs rolled for before and other tiers stay", function()
		for town = 1, 200 do
			assert(r.swapIndex(town, { MEAT, CLOTHES }, { [MEAT] = true }, isFish, canSwap) == nil)
		end
	end)

	test("a new need is rolled for, an old one is not", function()
		for town = 1, 200 do
			local i = r.swapIndex(town, { MEAT, VEG }, { [MEAT] = true }, isFish, canSwap)
			assert(i == nil or i == 2, tostring(i))
		end
	end)

	return results
end
