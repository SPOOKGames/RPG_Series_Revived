
local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:SetupMapNPC( NPCInstance )
	--[[
		TODO:
		- check dialogue requirements
		- check quest requirements
	]]
	return SystemsContainer.InteractionServer:CreateInteraction(NPCInstance, function()
		return true
	end)
end

function Module:SetupMapInteractable( TargetInstance )
	return SystemsContainer.InteractionServer:CreateInteraction(TargetInstance, false)
end

function Module:Start()
	for _, item in ipairs( workspace.TestQuestLine:GetChildren() ) do
		local Humanoid = item:FindFirstChildWhichIsA('Humanoid')
		if Humanoid then
			Module:SetupMapNPC( item )
		else
			Module:SetupMapInteractable( item )
		end
	end

	local TestCondition = SystemsContainer.InteractionServer:CreateInteraction(
		workspace.TestConditionQuest, false)
	TestCondition:OnInteractCompleted(function( LocalPlayer )
		SystemsContainer.DialogueServer:StartDialogue( LocalPlayer, 'TestDialogue2' )
	end)

	local StartTestQuest = SystemsContainer.InteractionServer:CreateInteraction(
		workspace.TestQuestLine.StartQuest, false)
	StartTestQuest:OnInteractCompleted(function( LocalPlayer )
		warn( LocalPlayer.Name )
		SystemsContainer.QuestServer:GiveQuestOfId( LocalPlayer, 'TestQuestLine1' )
	end)

	local TDialogue1 = SystemsContainer.InteractionServer:CreateInteraction(
		workspace.TDialogue1, false)
		TDialogue1:OnInteractCompleted(function( LocalPlayer )
		SystemsContainer.DialogueServer:StartDialogue( LocalPlayer, 'TestDialogue1' )
	end)

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems.ParentSystems
end

return Module
