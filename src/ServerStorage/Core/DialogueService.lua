local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local EventClass = ReplicatedModules.Classes.Event
local DialogueConfigModule = ReplicatedModules.Data.Dialogue

local RemoteService = ReplicatedModules.Services.RemoteService
local DialogueEvent = RemoteService:GetRemote('DialogueEvent', 'RemoteEvent', false)

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:StartDialogue( LocalPlayer, dialogueId )
	DialogueEvent:FireClient( LocalPlayer, DialogueConfigModule.DialogueEnums.OpenDialogue, dialogueId )
end

function Module:CloseDialogue( LocalPlayer )
	DialogueEvent:FireClient( LocalPlayer, DialogueConfigModule.DialogueEnums.CloseDialogue )
end

function Module:ResolveActions( LocalPlayer, dialogueId, dialogueIndexes )
	--[[
		if ActiveDialogueCache[ LocalPlayer ] ~= dialogueId then
			return
		end
		local dialogueConfig = DialogueConfigModule:GetConfigFromId( dialogueId )
	]]

	-- use interaction service + cache to keep track of active player dialogues
	-- only if they entered the dialogue, and have exited the dialogue,
	-- parse the dialogue tree indexes to the end and run the related
	-- action for that player
	warn(LocalPlayer.Name, dialogueId, dialogueIndexes)
end

function Module:Start()
	DialogueEvent.OnServerEvent:Connect(function(LocalPlayer, dialogueId, dialogueIndexes)
		Module:ResolveActions( LocalPlayer, dialogueId, dialogueIndexes )
	end)
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems

end

return Module
