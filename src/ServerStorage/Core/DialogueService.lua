
local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
