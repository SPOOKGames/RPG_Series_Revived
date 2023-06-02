local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))
local MaidClassModule = ReplicatedModules.Classes.Maid

local SystemsContainer = {}
local WidgetControllerModule = {}

-- // Module // --
local Module = {}

Module.WidgetMaid = MaidClassModule.New()
Module.Open = false

function Module:UpdateWidget()

end

function Module:OpenWidget()
	if Module.Open then
		return
	end
	Module.Open = true
	-- when widget opens
end

function Module:CloseWidget()
	if not Module.Open then
		return
	end
	Module.Open = false
	Module.WidgetMaid:Cleanup()
end

function Module:Start()
end

function Module:Init(ParentController, otherSystems)
	WidgetControllerModule = ParentController
	SystemsContainer = otherSystems
end

return Module
