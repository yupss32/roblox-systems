-- coin shop. prices live here on the server, client just sends an item id and
-- the server does the rest. no way to fake a price or get a free grant.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoinService = require(script.Parent.CoinService)
local DataService = require(script.Parent.DataService)
local RateLimiter = require(script.Parent.Parent.Anticheat.RateLimiter)

local ShopService = {}

local CATALOG = {
	speed_boost = { price = 500, grant = "SpeedBoost" },
	morph_slot = { price = 1500, grant = "MorphSlot" },
	coin_tag = { price = 250, grant = "CoinTag" },
}

local limiter = RateLimiter.new(5, 1) -- 5 buys a sec max

local function grant(player, itemId)
	local data = DataService.get(player.UserId)
	if not data then
		return
	end
	data.Inventory[itemId] = (data.Inventory[itemId] or 0) + 1
end

function ShopService.purchase(player, itemId)
	local item = CATALOG[itemId]
	if not item then
		return false, "unknown item"
	end
	-- spend first, if they cant afford it nothing else happens
	if not CoinService.trySpend(player, item.price) then
		return false, "not enough coins"
	end
	grant(player, item.grant)
	return true
end

function ShopService.init()
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Purchase")

	remote.OnServerEvent:Connect(function(player, itemId)
		if typeof(itemId) ~= "string" then
			return
		end
		if not limiter:check(player) then
			return -- spamming the remote, ignore
		end
		ShopService.purchase(player, itemId)
	end)
end

return ShopService
