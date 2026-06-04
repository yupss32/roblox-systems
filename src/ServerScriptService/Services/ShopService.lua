--!strict
-- ShopService
-- A coin shop where the prices live on the server and nowhere else. The client
-- sends an item id, the server decides everything: price, whether they can
-- afford it, and what they get. No client path to fake a price or a grant.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoinService = require(script.Parent.CoinService)
local DataService = require(script.Parent.DataService)
local RateLimiter = require(script.Parent.Parent.Anticheat.RateLimiter)

local ShopService = {}

-- Single source of truth for the shop. The client never sees prices except as
-- read-only display data you choose to send it.
local CATALOG = {
	speed_boost = { price = 500, grant = "SpeedBoost" },
	morph_slot = { price = 1500, grant = "MorphSlot" },
	coin_tag = { price = 250, grant = "CoinTag" },
}

-- at most 5 purchase attempts per second per player
local limiter = RateLimiter.new(5, 1)

local function grant(player: Player, itemId: string)
	local data = DataService.get(player.UserId)
	if not data then
		return
	end
	data.Inventory[itemId] = (data.Inventory[itemId] or 0) + 1
end

-- Returns ok, reason. Spends first; if they can't afford it nothing else runs.
function ShopService.purchase(player: Player, itemId: string): (boolean, string?)
	local item = CATALOG[itemId]
	if not item then
		return false, "unknown item"
	end
	if not CoinService.trySpend(player, item.price) then
		return false, "not enough coins"
	end
	grant(player, item.grant)
	return true, nil
end

function ShopService.init()
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Purchase")

	remote.OnServerEvent:Connect(function(player, itemId)
		-- validate the input before it touches any logic
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
