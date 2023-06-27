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

function Module:ResolveDialogueTree( dialogueId, dialogueIndexes )
	local dialogueConfig = DialogueConfigModule:GetDialogueFromId( dialogueId )

	local success, value = pcall(function()
		local Parent = dialogueConfig.Tree.Options[ table.remove(dialogueIndexes, 1) ]
		while #dialogueIndexes > 0 do
			Parent = Parent.Options[ table.remove(dialogueIndexes, 1) ]
		end
		return Parent.Options.Actions
	end)

	if not success then
		task.defer(error, value, debug.traceback())
	end
	return success and value
end

function Module:ParseAction( LocalPlayer, actionString )

	local actionSplit = string.split(actionString, ":")
	local command = table.remove(actionSplit, 1)
	if command == "START_QUEST" then
		SystemsContainer.QuestServer:GiveQuestOfId( LocalPlayer, unpack(actionSplit) )
	end

end

function Module:ResolveActions( LocalPlayer, dialogueId, dialogueIndexes )
	--[[
		if ActiveDialogueCache[ LocalPlayer ] ~= dialogueId then
			return
		end
	]]
	-- use interaction service + cache to keep track of active player dialogues
	-- only if they entered the dialogue, and have exited the dialogue,
	-- parse the dialogue tree indexes to the end and run the related
	-- action for that player
	local dialogueActions = Module:ResolveDialogueTree( dialogueId, dialogueIndexes )
	if not dialogueActions then
		return
	end
	for _, actionString in ipairs( dialogueActions ) do
		Module:ParseAction( LocalPlayer, actionString )
	end
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
