local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local LocalAssets = LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('Assets')
local LocalModules = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Modules"))

local Interface = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('Interface')
local NPCDialogueFrame = Interface:WaitForChild('DialogueNPC')

local UserInterfaceUtility = LocalModules.Utility.UserInterface

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedCore = require(ReplicatedStorage:WaitForChild('Core'))
local ReplicatedModules = require(ReplicatedStorage:WaitForChild('Modules'))

local ReplicatedData = ReplicatedCore.ReplicatedData

local MaidClassModule = ReplicatedModules.Classes.Maid
local DialogueConfigModule = ReplicatedModules.Data.Dialogue

local RemoteService = ReplicatedModules.Services.RemoteService
local DialogueEvent = RemoteService:GetRemote('DialogueEvent', 'RemoteEvent', false)

local SystemsContainer = {}
local WidgetControllerModule = {}

local function SetProperties( Parent, Properties )
	for propName, propValue in pairs(Properties) do
		Parent[propName] = propValue
	end
end

local function SetPropertiesRecursive( Parent, LabelToProperties )
	for LabelName, LabelProperties in pairs(LabelToProperties) do
		local Label = Parent:FindFirstChild(LabelName)
		if Label then
			SetProperties( Label, LabelProperties )
		end
	end
end

-- // Module // --
local Module = {}

Module.WidgetMaid = MaidClassModule.New()
Module.Open = false

Module.ActiveDialogueId = false
Module.ActiveDialogueOptionData = false
Module.ActiveDialogueIndexTree = { }

Module.DialogueOptionsMaid = MaidClassModule.New()

function Module:ResolveActions( dialogueId, dialogueActions, delay )
	warn( "RESOLVE_ACTIONS: ", dialogueId, dialogueActions, delay )
end

function Module:ParseDialogueDisplay( dialogueDisplay )
	if dialogueDisplay.Text then
		NPCDialogueFrame.Title.Visible = true
		NPCDialogueFrame.Description.Visible = true
		SetPropertiesRecursive( NPCDialogueFrame, dialogueDisplay.Text )
	else
		NPCDialogueFrame.Title.Visible = false
		NPCDialogueFrame.Description.Visible = false
	end

	NPCDialogueFrame.Icon.Visible = false
	--NPCDialogueFrame.Viewport.Visible = false
	if typeof(dialogueDisplay.Icon) == "string" then
		-- icon
		NPCDialogueFrame.Icon.Visible = true
		NPCDialogueFrame.Icon.Image = dialogueDisplay.Icon
	--elseif typeof(dialogueDisplay.Icon) == "table" then
		-- viewport
		--NPCDialogueFrame.Viewport.Visible = true
		--TODO: setup viewport
	end

	-- TODO: cutsceneId = cutsceneId
	-- TODO: visualEffectsArray = visualEffectsArray
end

function Module:ClearDialogueOptions()
	Module.DialogueOptionsMaid:Cleanup()
end

function Module:SetDialogueOptions( dialogueOptions )
	Module:ClearDialogueOptions()
	for optionIndex, optionData in ipairs( dialogueOptions ) do
		local TemplateFrame = LocalAssets.UI.TemplateDialogueOption:Clone()
		TemplateFrame.Name = tostring(optionIndex)..'_'..tostring(optionData.Type)
		TemplateFrame.LayoutOrder = optionIndex
		SetPropertiesRecursive( TemplateFrame, optionData.Display )
		Module.DialogueOptionsMaid:Give(UserInterfaceUtility:CreateActionButton({Parent = TemplateFrame}).Activated:Connect(function()
			Module:StepDialogue(optionIndex)
		end))
		TemplateFrame.Parent = NPCDialogueFrame.Options.Scroll
		Module.DialogueOptionsMaid:Give( TemplateFrame )
	end
end

function Module:ResolveNextDialogue( dialogueData )
	if dialogueData.Type == "Exit" or dialogueData.Type == "Action" then
		DialogueEvent:FireServer( Module.ActiveDialogueId, Module.ActiveDialogueIndexTree )
		if dialogueData.Type == "Action" then
			Module:ResolveActions( dialogueData.Actions, dialogueData.Delay )
		end
		Module:CloseDialogue()
		return
	elseif dialogueData.Type == "Conditional" then
		local isValid = dialogueData.Condition(LocalPlayer, ReplicatedData:GetData('PlayerData', false), Module.ActiveDialogueId)
		if isValid then
			dialogueData = dialogueData.True
		else
			dialogueData = dialogueData.False
		end
		Module:ResolveNextDialogue( dialogueData )
		return
	end

	Module.ActiveDialogueOptionData = dialogueData
	Module:ParseDialogueDisplay( dialogueData.Display )
	Module:SetDialogueOptions( dialogueData.Options )
end

function Module:StartDialogue( dialogueId )
	print(dialogueId)

	local dialogueConfig = DialogueConfigModule:GetDialogueFromId( dialogueId )
	if not dialogueConfig then
		warn('could not find dialogue of id - ' .. tostring(dialogueId))
		return
	end

	Module.ActiveDialogueId = dialogueId
	Module.ActiveDialogueIndexTree = { }
	Module:ResolveNextDialogue( dialogueConfig.Tree )
	Module:OpenWidget()
end

function Module:StepDialogue( optionIndex )
	if not Module.ActiveDialogueId then
		return
	end

	table.insert(Module.ActiveDialogueIndexTree, optionIndex)
	local pickedOption = Module.ActiveDialogueOptionData.Options[optionIndex]
	Module:ResolveNextDialogue( pickedOption.Options )
end

function Module:CloseDialogue()
	Module.ActiveDialogueId = false
	Module:CloseWidget()
end

function Module:UpdateWidget()

end

function Module:OpenWidget()
	if Module.Open or (not Module.ActiveDialogueId) then
		return
	end
	Module.Open = true

	Module.WidgetMaid:Give( Module.DialogueOptionsMaid )
	NPCDialogueFrame.Visible = true
end

function Module:CloseWidget()
	if not Module.Open then
		return
	end
	Module.Open = false
	Module.WidgetMaid:Cleanup()

	NPCDialogueFrame.Visible = false
end

function Module:Start()

	DialogueEvent.OnClientEvent:Connect(function( Job, ... )
		if Job == DialogueConfigModule.DialogueEnums.OpenDialogue then
			Module:StartDialogue( ... )
		elseif Job == DialogueConfigModule.DialogueEnums.CloseDialogue then
			Module:CloseDialogue( )
		end
	end)

end

function Module:Init(ParentController, otherSystems)
	WidgetControllerModule = ParentController
	SystemsContainer = otherSystems
end

return Module
