-- all coin changes go through here so currency stays server side and the
-- leaderstats number stays in sync

local DataService = require(script.Parent.DataService)

local CoinService = {}

local function mirror(player, amount)
	local ls = player:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("Coins")
	if coins then
		coins.Value = amount
	end
end

function CoinService.get(player)
	local data = DataService.get(player.UserId)
	return data and data.Coins or 0
end

function CoinService.add(player, amount)
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

-- only spends if they can actually afford it, otherwise changes nothing
function CoinService.trySpend(player, amount)
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
