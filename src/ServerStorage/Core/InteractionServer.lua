local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local QuestsConfigModule = ReplicatedModules.Data.Quests
local InteractionService = ReplicatedModules.Services.InteractionService

local RemoteService = ReplicatedModules.Services.RemoteService
local InteractionEvent = RemoteService:GetRemote('InteractionEvent', 'RemoteEvent', false)
local InteractionFunction = RemoteService:GetRemote('InteractionFunction', 'RemoteFunction', false)

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:HandleServerInvoke( LocalPlayer, Job, Interactable )--, ... )
	--local Args = {...}

	local InteractableClass = InteractionService:GetInteraction( Interactable )
	if not InteractableClass then
		return InteractionService.INTERACT_EXCEPTIONS.NotAvailable, "Not a valid interaction."
	end

	if not InteractableClass.Enabled then
		return InteractionService.INTERACT_EXCEPTIONS.Disabled, "Interaction is disabled."
	end

	local CharacterPosition = LocalPlayer.Character and LocalPlayer.Character:GetPivot().Position
	if not CharacterPosition then
		return InteractionService.INTERACT_EXCEPTIONS.CannotUseCondition, 'No character instance.'
	end

	local Dist = CharacterPosition and (InteractableClass.TargetInstance:GetPivot().Position - CharacterPosition).Magnitude
	if Dist > InteractableClass.MaxDistance then
		return InteractionService.INTERACT_EXCEPTIONS.CannotUseCondition, 'Too far away from interactable.'
	end

	local Success, customErr = InteractionService:CanUseInteractable( LocalPlayer, InteractableClass )
	if not Success then
		return InteractionService.INTERACT_EXCEPTIONS.CannotUseCondition, customErr or 'Cannot use this interactable.'
	end

	-- TODO: reconsider this?
	-- add arithmetic logic and loops to count hold duration and such
	if Job == InteractionService.INTERACT_JOBS.Started then
		InteractableClass.Events.Started:Fire(LocalPlayer)
		return InteractionService.INTERACT_EXCEPTIONS.Available, 'Started interaction.'
	elseif Job == InteractionService.INTERACT_JOBS.Canceled then
		InteractableClass.Events.Canceled:Fire(LocalPlayer)
		return InteractionService.INTERACT_EXCEPTIONS.Available, 'Canceled interaction.'
	elseif Job == InteractionService.INTERACT_JOBS.Completed then
		InteractableClass.Events.Completed:Fire(LocalPlayer)
		local InstanceName = InteractableClass.TargetInstance.Name
		SystemsContainer.QuestServer:AppendQuestContributions(LocalPlayer, QuestsConfigModule.ArrayContributions.Interact, InstanceName, 1)
		if InteractionService:IsInstanceAnNPC( InteractableClass.TargetInstance ) then
			SystemsContainer.QuestServer:AppendQuestContributions(LocalPlayer, QuestsConfigModule.ArrayContributions.Talk, InstanceName, 1)
		end
		-- return
		return InteractionService.INTERACT_EXCEPTIONS.Available, 'Completed interaction.'
	end

	return InteractionService.INTERACT_EXCEPTIONS.Available, 'Successfully interacted with.'
end

function Module:CreateInteraction( TargetInstance, canUseCallback )
	return InteractionService:CreateInteraction( TargetInstance, canUseCallback )
end

function Module:RemoveInteraction( TargetInstance )
	InteractionService:RemoveInteraction( TargetInstance )
end

function Module:Start()
	InteractionFunction.OnServerInvoke = function( ... )
		return Module:HandleServerInvoke( ... )
	end

	-- when client requests, setup all interactions on that client
	InteractionEvent.OnServerEvent:Connect(function(LocalPlayer)
		for TargetInstance, _ in pairs( InteractionService.ActiveInteractionClasses ) do
			InteractionEvent:FireClient(LocalPlayer, 'SetupInteraction', TargetInstance)
		end
	end)
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module