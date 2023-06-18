
local RunService = game:GetService('RunService')

local InteractionClassModule = require(script.Interactable)

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

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RemoteService = ReplicatedModules.Services.RemoteService
local InteractionEvent = RemoteService:GetRemote('InteractionEvent', 'RemoteEvent', false)
local InteractionFunction = RemoteService:GetRemote('InteractionFunction', 'RemoteFunction', false)

local ActiveInteractionClasses = { }

local INTERACT_EXCEPTIONS = { NotAvailable = 1, Disabled = 2, CannotUseCondition = 3, Available = 4, }
local INTERACT_JOBS = { Started = 1, Canceled = 2, Completed = 3 }

-- // Module // --
local Module = {}

function Module:GetInstanceInteraction( TargetInstance, doCreateIfMissing, canUseInteractableCallback )
	if not ActiveInteractionClasses[TargetInstance] and doCreateIfMissing then
		local Base = InteractionClassModule.New(TargetInstance, canUseInteractableCallback)
		ActiveInteractionClasses[TargetInstance] = Base
		if RunService:IsServer() then
			InteractionEvent:FireAllClients('SetupInteraction', TargetInstance)
		end
	end
	return ActiveInteractionClasses[TargetInstance]
end

function Module:OnInteractCompleted( TargetInstance, Callback, canUseCallback )
	local class = Module:GetInteractionClass( TargetInstance, true, canUseCallback )
	class:OnInteractCompleted(Callback)
	return class
end

function Module:RemoveInteraction( TargetInstance )
	local class = Module:GetInteractionClass( TargetInstance )
	if class then
		class:Destroy()
	end
	if RunService:IsServer() then
		InteractionEvent:FireAllClients('RemoveInteraction', TargetInstance)
	end
end

if RunService:IsServer() then

	function Module:HandleServerInvoke( LocalPlayer, Job, Interactable)--, ... )
		--local Args = {...}

		local InteractableClass = Module:GetInteractionClass( Interactable, false )
		if not InteractableClass then
			return INTERACT_EXCEPTIONS.NotAvailable, "Not a valid interaction."
		end

		if not InteractableClass.Enabled then
			return INTERACT_EXCEPTIONS.Disabled, "Interaction is disabled."
		end

		if not InteractableClass.CanUseInteraction then
			return true
		end

		for _, conditionCallback in ipairs( InteractableClass.CanUseInteraction ) do
			local CanUse, conditionMessage = conditionCallback(LocalPlayer)
			if not CanUse then
				return INTERACT_EXCEPTIONS.CannotUseCondition, conditionMessage or 'Cannot use this interactable.'
			end
		end

		if Job == INTERACT_JOBS.Started then
			InteractableClass.Events.Started:Fire(LocalPlayer)
		elseif Job == INTERACT_JOBS.Canceled then
			InteractableClass.Events.Canceled:Fire(LocalPlayer)
		elseif Job == INTERACT_JOBS.Completed then
			InteractableClass.Events.Completed:Fire(LocalPlayer)
		end

		return INTERACT_EXCEPTIONS.Available, 'Successfully used the interactable.'
	end

	InteractionFunction.OnServerInvoke = function( ... )
		return Module:HandleServerInvoke( ... )
	end

	-- when client requests, setup all interactions on that client
	InteractionEvent.OnServerEvent:Connect(function(LocalPlayer)
		for TargetInstance, _ in pairs( ActiveInteractionClasses ) do
			InteractionEvent:FireClient(LocalPlayer, 'SetupInteraction', TargetInstance)
		end
	end)

else

	-- TODO: client side

end

return Module
