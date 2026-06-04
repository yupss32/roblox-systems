--!strict
-- Cooldown
-- A small reusable cooldown keyed by anything (player, action name, instance).
-- Drop it on attacks, clicks, ability casts, whatever needs spam protection.

local Cooldown = {}
Cooldown.__index = Cooldown

function Cooldown.new(seconds: number)
	return setmetatable({
		seconds = seconds,
		stamps = {} :: { [any]: number },
	}, Cooldown)
end

-- Returns true if the cooldown is up (and starts a new one). Returns false if
-- it's still ticking, so you can use it directly in an if.
function Cooldown:ready(key: any): boolean
	local now = os.clock()
	local last = self.stamps[key] or 0
	if now - last < self.seconds then
		return false
	end
	self.stamps[key] = now
	return true
end

function Cooldown:clear(key: any)
	self.stamps[key] = nil
end

return Cooldown
