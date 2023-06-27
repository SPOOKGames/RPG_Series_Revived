
local RunService = game:GetService('RunService')

local InteractionClassModule = require(script.Parent.Parent.Classes.Interactable)

--[[
	CONFIGS:
		- KEYBINDS
		- DURATION OF HOLD
		- MAX DISTANCE
		- CAN-INTERACT CONDITION FUNCTION
		- USE DEFAULT INTERACTION UI?

	INPUT TYPES:
		- PRESS
		- PRESS and HOLD
		- ALL PLATFORMS

	INTERACTION EVENTS
		- INTERACT STARTED
		- INTERACT CANCELED
		- INTERACT FINISHED

	PLAYERS CAN MAKE OWN CUSTOM INTERACTABLES ON PLAYERS,
	SERVER CAN MAKE INTERACTABLES FOR ALL PLAYERS.
]]

local RemoteService = require(script.Parent.RemoteService)
local InteractionEvent = RemoteService:GetRemote('InteractionEvent', 'RemoteEvent', false)

local INTERACT_EXCEPTIONS = { NotAvailable = 1, Disabled = 2, CannotUseCondition = 3, Available = 4, }
local INTERACT_JOBS = { Started = 1, Canceled = 2, Completed = 3 }

-- // Module // --
local Module = {}
Module.ActiveInteractionClasses = { }
Module.INTERACT_EXCEPTIONS = INTERACT_EXCEPTIONS
Module.INTERACT_JOBS = INTERACT_JOBS

function Module:IsKeybindInInteractable( Interactable, Keybind )
	return table.find( Interactable.Keybinds, Keybind )
end

function Module:IsInstanceAnNPC( TargetInstance )
	return TargetInstance:FindFirstChildWhichIsA("Humanoid")
end

function Module:GetInstancePosition( TargetInstance )
	return TargetInstance:GetPivot().Position
end

function Module:CanUseInteractable( LocalPlayer, InteractableClass )
	if not InteractableClass.Enabled then
		return false, 'Interaction is not enabled.'
	end
	if InteractableClass.CanUseInteraction then
		for _, conditionCallback in ipairs( InteractableClass.CanUseInteraction ) do
			local CanUse, conditionMessage = conditionCallback(LocalPlayer)
			if not CanUse then
				return false, conditionMessage
			end
		end
	end
	return true
end

function Module:GetClosestInteractable( CharacterPosition )
	local ClosestInteractable, ClosestDistance = false, -1
	for TargetInstance, Interactable in pairs( Module.ActiveInteractionClasses ) do
		if not Interactable.Enabled then
			continue
		end
		local Position = Module:GetInstancePosition( TargetInstance )
		local Dist = (CharacterPosition - Position).Magnitude
		if Interactable.MaxDistance and Dist > Interactable.MaxDistance then
			continue
		end
		if (not ClosestInteractable) or (ClosestDistance < Dist) then
			ClosestInteractable = Interactable
			ClosestDistance = Dist
		end
	end
	return ClosestInteractable, ClosestDistance
end

function Module:GetInteraction( TargetInstance )
	return Module.ActiveInteractionClasses[TargetInstance]
end

function Module:CreateInteraction( TargetInstance, canUseCallback )
	if Module:GetInteraction( TargetInstance ) then
		return Module:GetInteraction( TargetInstance )
	end
	if RunService:IsServer() then
		InteractionEvent:FireAllClients('SetupInteraction', TargetInstance)
	end
	if not Module.ActiveInteractionClasses[TargetInstance] then
		Module.ActiveInteractionClasses[TargetInstance] = InteractionClassModule.New(TargetInstance)
	end
	if typeof(canUseCallback) == "function" then
		Module.ActiveInteractionClasses[TargetInstance]:AddConditionFunction(canUseCallback)
	end
	return Module.ActiveInteractionClasses[TargetInstance]
end

function Module:RemoveInteraction( TargetInstance )
	local Item = Module:GetInteraction( TargetInstance )
	if Item and RunService:IsServer() then
		InteractionEvent:FireAllClients('RemoveInteraction', TargetInstance)
	end
	Module.ActiveInteractionClasses[TargetInstance] = nil
end

return Module
