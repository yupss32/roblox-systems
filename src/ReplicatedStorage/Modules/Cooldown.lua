-- little reusable cooldown, key it by whatever (player, action name, a part).
-- ready() returns true if its off cooldown and starts a fresh one, so you can
-- use it right inside an if

local Cooldown = {}
Cooldown.__index = Cooldown

function Cooldown.new(seconds)
	return setmetatable({ seconds = seconds, stamps = {} }, Cooldown)
end

function Cooldown:ready(key)
	local now = os.clock()
	local last = self.stamps[key] or 0
	if now - last < self.seconds then
		return false
	end
	self.stamps[key] = now
	return true
end

function Cooldown:clear(key)
	self.stamps[key] = nil
end

return Cooldown
