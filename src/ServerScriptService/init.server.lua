--!strict
-- Server bootstrap.
-- Loads (and locks) data when a player joins, sets up their leaderstats from
-- the saved value, and starts the anticheat + shop. Keeping the wiring in one
-- place makes the boot order obvious instead of scattered across scripts.

local Players = game:GetService("Players")

local Services = script.Services
local Anticheat = script.Anticheat

local DataService = require(Services.DataService)
local ShopService = require(Services.ShopService)
local MovementGuard = require(Anticheat.MovementGuard)

local function setupLeaderstats(player: Player, coins: number)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"

	local coinValue = Instance.new("IntValue")
	coinValue.Name = "Coins"
	coinValue.Value = coins
	coinValue.Parent = ls

	ls.Parent = player
end

Players.PlayerAdded:Connect(function(player)
	local data = DataService.load(player)
	if not data then
		return -- load() already kicked them on a lock conflict
	end
	setupLeaderstats(player, data.Coins)
end)

MovementGuard.start()
ShopService.init()
