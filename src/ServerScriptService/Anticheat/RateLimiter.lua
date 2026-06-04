-- token bucket for remotes. each player gets `rate` tokens that refill over
-- `per` seconds, every request eats one. run out and it gets rejected. good
-- against remote spam without a harsh per-frame cap.

local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(rate, per)
	return setmetatable({
		rate = rate,
		per = per,
		buckets = {},
	}, RateLimiter)
end

function RateLimiter:check(player)
	local now = os.clock()
	local b = self.buckets[player]
	if not b then
		b = { tokens = self.rate, last = now }
		self.buckets[player] = b
	end

	-- refill for however long its been since last check
	local elapsed = now - b.last
	b.tokens = math.min(self.rate, b.tokens + elapsed * (self.rate / self.per))
	b.last = now

	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

function RateLimiter:clear(player)
	self.buckets[player] = nil
end

return RateLimiter
