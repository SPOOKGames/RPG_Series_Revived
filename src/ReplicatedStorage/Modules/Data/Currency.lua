
-- // Module // --
local Module = {}

Module.CurrencyToCopper = { Copper = 1, Silver = 8, Gold = 64, Platinum = 512 }
Module.OrderedCoinNames = { 'Platinum', 'Gold', 'Silver', 'Copper', }

function Module:ToCopperCoins( currencyTable )
	local totalCopper = 0
	for coinName, coinValue in pairs( currencyTable ) do
		local copperValue = Module.CurrencyToCopper[coinName]
		if copperValue then
			totalCopper += (coinValue * copperValue)
		end
	end
	return totalCopper
end

function Module:ToAssortedCoins( copperCoins )
	local assortedCurrency = { }
	for _, coinName in ipairs( Module.OrderedCoinNames ) do
		local totalConverted = math.floor( copperCoins / Module.CurrencyToCopper[coinName] )
		if totalConverted > 0 then
			local amount = totalConverted * Module.CurrencyToCopper[coinName]
			copperCoins -= amount
			assortedCurrency[coinName] = totalConverted
		else
			assortedCurrency[coinName] = 0
		end
	end
	return assortedCurrency
end

return Module
