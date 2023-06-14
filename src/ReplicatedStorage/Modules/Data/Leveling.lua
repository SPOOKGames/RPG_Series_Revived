local Module = {}

Module.MaxLevel = 50
Module.ReqExperienceToLevel = function(Level)
	return 50 + math.pow( (Level - 1) * 10, 1.1 )
end

return Module