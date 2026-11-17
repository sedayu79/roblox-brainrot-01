-- Brainrot Bazaar: small shared helpers — money formatting and clamps.

local Util = {}

-- $950 -> "$950", $1500 -> "$1.5K", $2,400,000 -> "$2.4M", $1,500,000,000 -> "$1.5B"
function Util.formatMoney(amount)
	amount = math.floor(amount + 0.5)
	if amount < 1000 then
		return "$" .. tostring(amount)
	elseif amount < 1000000 then
		return string.format("$%.1fK", amount / 1000)
	elseif amount < 1000000000 then
		return string.format("$%.1fM", amount / 1000000)
	else
		return string.format("$%.1fB", amount / 1000000000)
	end
end

function Util.formatRate(rate)
	return Util.formatMoney(rate) .. "/dtk"
end

function Util.clamp(value, low, high)
	if value < low then
		return low
	elseif value > high then
		return high
	end
	return value
end

return Util
