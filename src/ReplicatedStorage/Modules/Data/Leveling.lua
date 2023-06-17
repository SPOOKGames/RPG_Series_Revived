local Module = {}

Module.MaxLevel = 50
Module.ReqExperienceToLevel = function(Level)
	local rawExp = math.pow( (Level - 1) * 10, 1.1 )
	return 50 + math.floor( rawExp )
end

return Module