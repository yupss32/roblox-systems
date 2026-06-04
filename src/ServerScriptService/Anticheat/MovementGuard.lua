-- server side speed check. measures how far you moved on x/z each step vs what
-- walkspeed should let you. falling/knockback dont count cause i drop the y.
-- builds up strikes instead of banning on one spike, bad ping happens

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MovementGuard = {}

local MAX_STUDS_PER_SEC = 24 -- 16 walkspeed + a bit of headroom for ping
local SAMPLE = 0.5
local STRIKES_TO_KICK = 6

local last = {}
local strikes = {}

local function flag(player, speed)
	strikes[player] = (strikes[player] or 0) + 1
	warn(string.format("[anticheat] %s moving %.1f studs/s (strike %d)", player.Name, speed, strikes[player]))
	if strikes[player] >= STRIKES_TO_KICK then
		player:Kick("Kicked by anticheat.")
	end
end

function MovementGuard.start()
	local accum = 0

	RunService.Heartbeat:Connect(function(dt)
		accum += dt
		if accum < SAMPLE then
			return
		end
		local step = accum
		accum = 0

		for _, player in Players:GetPlayers() do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then
				continue
			end

			local now = root.Position
			local prev = last[player]
			if prev then
				local moved = ((now - prev) * Vector3.new(1, 0, 1)).Magnitude
				if moved / step > MAX_STUDS_PER_SEC then
					flag(player, moved / step)
				end
			end
			last[player] = now
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		last[player] = nil
		strikes[player] = nil
	end)
end

return MovementGuard
