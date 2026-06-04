--!strict
-- DataService
-- Server-authoritative player data with a session lock (stops the two-server
-- dupe), retry + backoff on DataStore calls, autosave, a guaranteed save when
-- a player leaves, and template migrations so updates never wipe old saves.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local store = DataStoreService:GetDataStore("PlayerData_v1")

local DataService = {}

-- New players start from this. Adding a key here and shipping an update will
-- backfill it onto everyone's existing save through migrate().
local TEMPLATE = {
	Coins = 0,
	Inventory = {},
	Version = 1,
}

local SESSION_TTL = 60 -- a lock older than this is treated as dead (server crash)
local AUTOSAVE_INTERVAL = 120
local MAX_RETRIES = 5

local jobId = game.JobId
local cache: { [number]: any } = {}

local function keyFor(userId: number): string
	return "Player_" .. userId
end

local function deepCopy(t: any): any
	local copy = {}
	for k, v in t do
		copy[k] = if typeof(v) == "table" then deepCopy(v) else v
	end
	return copy
end

-- Run a DataStore call, retrying with exponential backoff. Throws if it never
-- succeeds so the caller can decide what to do (we kick on a failed load).
local function retry(fn: () -> any): any
	local attempt = 0
	while true do
		local ok, result = pcall(fn)
		if ok then
			return result
		end
		attempt += 1
		if attempt >= MAX_RETRIES then
			error(result)
		end
		task.wait(2 ^ attempt * 0.1)
	end
end

-- Fill in any keys the save is missing from the template. Cheap forward
-- migration that keeps old saves valid after an update.
local function migrate(data: any): any
	for k, v in TEMPLATE do
		if data[k] == nil then
			data[k] = if typeof(v) == "table" then deepCopy(v) else v
		end
	end
	return data
end

-- Load (and lock) a player's data. Returns nil if another live server still
-- holds the lock, in which case we kick and ask them to rejoin.
function DataService.load(player: Player): any?
	local userId = player.UserId

	local data = retry(function()
		return store:UpdateAsync(keyFor(userId), function(old)
			old = old or deepCopy(TEMPLATE)
			local lock = old.__lock
			local lockAlive = lock and (os.time() - lock.time) < SESSION_TTL
			if lockAlive and lock.jobId ~= jobId then
				return nil -- someone else owns it; cancel the write
			end
			old.__lock = { jobId = jobId, time = os.time() }
			return old
		end)
	end)

	if not data then
		player:Kick("Your data is still saving on another server. Please rejoin in a moment.")
		return nil
	end

	data = migrate(data)
	cache[userId] = data
	return data
end

function DataService.get(userId: number): any?
	return cache[userId]
end

-- Save the player's data. Pass release = true on leave to also drop the lock.
-- The write is skipped if we no longer own the lock, so a stale server can't
-- stomp fresh data on another server.
function DataService.save(player: Player, release: boolean)
	local userId = player.UserId
	local data = cache[userId]
	if not data then
		return
	end

	retry(function()
		store:UpdateAsync(keyFor(userId), function(old)
			if old and old.__lock and old.__lock.jobId ~= jobId then
				return nil -- we don't own the lock anymore, don't overwrite
			end
			local toSave = deepCopy(data)
			toSave.__lock = if release then nil else { jobId = jobId, time = os.time() }
			return toSave
		end)
	end)

	if release then
		cache[userId] = nil
	end
end

Players.PlayerRemoving:Connect(function(player)
	DataService.save(player, true)
end)

-- Best-effort flush on shutdown so nobody loses the last couple minutes.
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		task.spawn(DataService.save, player, true)
	end
	task.wait(3)
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in Players:GetPlayers() do
			task.spawn(DataService.save, player, false)
		end
	end
end)

return DataService
