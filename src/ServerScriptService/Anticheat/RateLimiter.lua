--!strict
-- RateLimiter
-- Token-bucket limiter for RemoteEvents. Each player holds `rate` tokens that
-- refill smoothly over `per` seconds. Every request costs one token; run dry
-- and the request is rejected. Smooths bursts without a hard per-frame cap,
-- which is what you want against remote-spam exploits.

local RateLimiter = {}
RateLimiter.__index = RateLimiter

type Bucket = { tokens: number, last: number }

function RateLimiter.new(rate: number, per: number)
	return setmetatable({
		rate = rate,
		per = per,
		buckets = {} :: { [Player]: Bucket },
	}, RateLimiter)
end

-- Returns true and consumes a token if one is available, false otherwise.
function RateLimiter:check(player: Player): boolean
	local now = os.clock()
	local b = self.buckets[player]
	if not b then
		b = { tokens = self.rate, last = now }
		self.buckets[player] = b
	end

	-- refill based on how long it's been since we last looked
	local elapsed = now - b.last
	b.tokens = math.min(self.rate, b.tokens + elapsed * (self.rate / self.per))
	b.last = now

	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

function RateLimiter:clear(player: Player)
	self.buckets[player] = nil
end

return RateLimiter
