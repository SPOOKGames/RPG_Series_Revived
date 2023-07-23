
local Module = {}

function Module:WeldInstance( Part0, Part1 )
	local Weld = Instance.new('WeldConstraint')
	Weld.Part0 = Part0
	Weld.Part1 = Part1
	Weld.Parent = Part0
	return Weld
end

return Module
