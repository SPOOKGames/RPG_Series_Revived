--[==[
warn([[

	 .oooooo..o ooooooooo.     .oooooo.     .oooooo.   oooo    oooo             oooooooooooo ooooooo  ooooo oooooooooooo 
	 d8P'    `Y8 `888   `Y88.  d8P'  `Y8b   d8P'  `Y8b  `888   .8P'              `888'     `8  `8888    d8'  `888'     `8 
	 Y88bo.       888   .d88' 888      888 888      888  888  d8'                 888            Y888..8P     888         
	  `"Y8888o.   888ooo88P'  888      888 888      888  88888[                   888oooo8        `8888'      888oooo8    
		  `"Y88b  888         888      888 888      888  888`88b.                 888    "       .8PY888.     888    "    
	 oo     .d8P  888         `88b    d88' `88b    d88'  888  `88b.               888       o   d8'  `888b    888       o 
	 8""88888P'  o888o         `Y8bood8P'   `Y8bood8P'  o888o  o888o ooooooooooo o888ooooood8 o888o  o88888o o888ooooood8 
]])
--]==]

local function hasInit(tbl : table) : boolean
	return tbl.Init or (getmetatable(tbl) and getmetatable(tbl).Init)
end

local function hasStart(tbl : table) : boolean
	return tbl.Start or (getmetatable(tbl) and getmetatable(tbl).Start)
end

task.delay(2, function()
	warn("Anything past this point (which errors / warns) is considered a bug/problem. Please report it to the developers via discord!")
end)

-- // MAIN // --
local CacheTable = {}

return function(Parent)
	local Cache = CacheTable[Parent]
	if Cache then
		return Cache
	end
	Cache = {}

	-- Require Modules
	for _, ModuleScript in ipairs( Parent:GetChildren() ) do
		if ModuleScript:IsA('ModuleScript') then
			Cache[ModuleScript.Name] = require(ModuleScript)
		end
	end

	-- Initialize
	for preLoadedName, preLoaded in pairs(Cache) do
		if typeof(preLoaded) ~= 'table' or preLoaded.Initialised or (not hasInit(preLoaded)) then
			continue
		end
		local accessibles = { ParentSystems = CacheTable[Parent.Parent] }
		for otherLoadedName, differentLoaded in pairs(Cache) do
			if preLoadedName == otherLoadedName then
				continue
			end
			accessibles[otherLoadedName] = differentLoaded
		end
		preLoaded.Initialised = true
		preLoaded:Init(accessibles)
	end

	for _, preLoaded in pairs(Cache) do
		if typeof(preLoaded) ~= 'table' or preLoaded.Started or (not hasStart(preLoaded)) then
			continue
		end
		preLoaded.Started = true
		preLoaded:Start()
	end

	CacheTable[Parent] = Cache
	return Cache
end