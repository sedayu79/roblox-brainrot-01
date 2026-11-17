-- Brainrot Bazaar: small shared helpers (money and time formatting).

local Util = {}

local SUFFIXES = { "", "K", "M", "B", "T" }

function Util.formatMoney(amount)
	local n = math.floor(amount + 0.5)
	local negative = n < 0
	n = math.abs(n)
	local tier = 1
	while n >= 1000 and tier < #SUFFIXES do
		n = n / 1000
		tier += 1
	end
	local text
	if tier == 1 then
		text = tostring(n)
	elseif n >= 100 then
		text = tostring(math.floor(n))
	elseif n >= 10 then
		text = string.format("%.1f", n)
	else
		text = string.format("%.2f", n)
	end
	if negative then
		return "-$" .. text .. SUFFIXES[tier]
	end
	return "$" .. text .. SUFFIXES[tier]
end

function Util.formatClock(seconds)
	seconds = math.max(0, math.floor(seconds))
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", mins, secs)
end

function Util.clampNumber(value, low, high)
	if value < low then
		return low
	elseif value > high then
		return high
	end
	return value
end

return Util
