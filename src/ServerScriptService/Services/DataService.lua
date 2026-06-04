-- player data. has a session lock so you cant load the same profile on two
-- servers and dupe stuff. retries if datastore is slow, autosaves, saves on
-- leave, and patches old saves up to the template so an update doesnt wipe ppl

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local store = DataStoreService:GetDataStore("PlayerData_v1")

local DataService = {}

local TEMPLATE = {
	Coins = 0,
	Inventory = {},
	Version = 1,
}

local SESSION_TTL = 60 -- lock older than this = dead server, take it over
local AUTOSAVE_INTERVAL = 120
local MAX_RETRIES = 5

local jobId = game.JobId
local cache = {}

local function keyFor(userId)
	return "Player_" .. userId
end

local function deepCopy(t)
	local copy = {}
	for k, v in t do
		copy[k] = if typeof(v) == "table" then deepCopy(v) else v
	end
	return copy
end

local function retry(fn)
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
		task.wait(2 ^ attempt * 0.1) -- backoff
	end
end

-- fill in anything the save is missing from the template. cheap way to add new
-- fields in an update without breaking everyones existing data
local function migrate(data)
	for k, v in TEMPLATE do
		if data[k] == nil then
			data[k] = if typeof(v) == "table" then deepCopy(v) else v
		end
	end
	return data
end

function DataService.load(player)
	local userId = player.UserId

	local data = retry(function()
		return store:UpdateAsync(keyFor(userId), function(old)
			old = old or deepCopy(TEMPLATE)
			local lock = old.__lock
			if lock and (os.time() - lock.time) < SESSION_TTL and lock.jobId ~= jobId then
				return nil -- someone else still has it, dont touch
			end
			old.__lock = { jobId = jobId, time = os.time() }
			return old
		end)
	end)

	if not data then
		player:Kick("Your data is still saving on another server, rejoin in a sec.")
		return nil
	end

	data = migrate(data)
	cache[userId] = data
	return data
end

function DataService.get(userId)
	return cache[userId]
end

-- pass release = true on leave so it drops the lock too
function DataService.save(player, release)
	local userId = player.UserId
	local data = cache[userId]
	if not data then
		return
	end

	retry(function()
		store:UpdateAsync(keyFor(userId), function(old)
			if old and old.__lock and old.__lock.jobId ~= jobId then
				return nil -- not ours anymore, dont stomp it
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

-- flush everyone on shutdown so nobody loses the last couple minutes
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
