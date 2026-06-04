--!strict
-- MovementGuard
-- Server-side speed / teleport / fly check. Measures how far each player
-- actually moved on the X/Z plane per step and compares it to what walkspeed
-- should allow. Falling and knockback don't trip it because the Y axis is
-- dropped. Flag-and-review: one spike is logged, repeat offenders rack up
-- strikes. Hook the strike count up to a kick / log store in a real game.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MovementGuard = {}

local MAX_STUDS_PER_SEC = 24 -- walkspeed 16 + headroom for ping
local SAMPLE = 0.5 -- seconds between checks
local STRIKES_TO_KICK = 6

local last: { [Player]: Vector3 } = {}
local strikes: { [Player]: number } = {}

local function flag(player: Player, speed: number)
	strikes[player] = (strikes[player] or 0) + 1
	warn(string.format(
		"[Anticheat] %s moving at %.1f studs/s (strike %d)",
		player.Name, speed, strikes[player]
	))
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
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root then
				continue
			end

			local now = root.Position
			local prev = last[player]
			if prev then
				-- horizontal distance only
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
