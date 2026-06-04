--!strict
-- CoinService
-- The only place coins ever change. Everything goes through here so currency
-- stays server-authoritative and the leaderstats mirror stays in sync.

local DataService = require(script.Parent.DataService)

local CoinService = {}

local function mirror(player: Player, amount: number)
	local ls = player:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("Coins")
	if coins then
		coins.Value = amount
	end
end

function CoinService.get(player: Player): number
	local data = DataService.get(player.UserId)
	return if data then data.Coins else 0
end

function CoinService.add(player: Player, amount: number): boolean
	if amount <= 0 then
		return false
	end
	local data = DataService.get(player.UserId)
	if not data then
		return false
	end
	data.Coins += amount
	mirror(player, data.Coins)
	return true
end

-- Spend coins only if the player can actually afford it. Returns false and
-- changes nothing if they can't, so callers can branch cleanly.
function CoinService.trySpend(player: Player, amount: number): boolean
	if amount <= 0 then
		return false
	end
	local data = DataService.get(player.UserId)
	if not data or data.Coins < amount then
		return false
	end
	data.Coins -= amount
	mirror(player, data.Coins)
	return true
end

return CoinService
