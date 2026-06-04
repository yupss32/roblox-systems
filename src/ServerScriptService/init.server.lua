-- server boot. loads data on join, makes leaderstats from the saved coins,
-- starts anticheat + the shop. keeping the wiring in one spot so the boot
-- order is obvious

local Players = game:GetService("Players")

local Services = script.Services
local Anticheat = script.Anticheat

local DataService = require(Services.DataService)
local ShopService = require(Services.ShopService)
local MovementGuard = require(Anticheat.MovementGuard)

local function setupLeaderstats(player, coins)
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
		return -- load already kicked them
	end
	setupLeaderstats(player, data.Coins)
end)

MovementGuard.start()
ShopService.init()
