--[[
	ability to:
	- cutscene
	- audio/visual/camera effect
	- run quest event (Talk/Interact)
	- viewport & icon image
	- rich text
	- dialogue actions (DelaySeconds, MultiOption, StartNewDialogueId)
]]

-- // Internal // --
local function BuildDialogueDisplay( textData, iconData, cutsceneId, visualEffectsArray )
	return { Text = textData, Icon = iconData, cutsceneId = cutsceneId, visualEffectsArray = visualEffectsArray }
end

local function BuildDialogueTextData( TitleText, TitleCol, DescText, DescCol )
	TitleCol = TitleCol or Color3.new(1,1,1)
	DescCol = DescCol or Color3.new(1,1,1)
	return { Title = { Text = TitleText, TextColor3 = TitleCol }, Description = { Text = DescText, TextColor3 = DescCol } }
end

local function BuildOptionDisplayData( Text, TextColor3 )
	TextColor3 = TextColor3 or Color3.new(1,1,1)
	return { Label = { Text = Text, TextColor3 = TextColor3 } }
end

-- // Dialogue Builder // --
local DialogueBuilder = {}

function DialogueBuilder:MultiOption( optionDisplayData, ... )
	return { Type = 'MultiOption', Display = optionDisplayData, Options = { ... }, }
end

function DialogueBuilder:YesNoOption( displayData, yesDialogue, noDialogue )
	return DialogueBuilder:MultiOption( displayData, {
		Display = BuildOptionDisplayData('Yes'),
		Options = yesDialogue,
	}, {
		Display = BuildOptionDisplayData('No'),
		Options = noDialogue,
	})
end

function DialogueBuilder:MultipleActions( actionsArray, delayPeriod )
	return { Type = "Action", Actions = actionsArray, Delay = delayPeriod }
end

function DialogueBuilder:SingleAction( action, delayPeriod )
	return DialogueBuilder:MultipleActions( {action}, delayPeriod )
end

function DialogueBuilder:ExitDialogue()
	return { Type = "Exit" }
end

-- // Module // --
local Module = {}

Module.DialogueBuilder = DialogueBuilder

Module.DialogueEnums = {
	OpenDialogue = 1,
	CloseDialogue = 2,

	StartedDialogue = 3,
	SteppedDialogue = 4,
	EndedDialogue = 5,
}

Module.Dialogue = {

	TestDialogue1 = {
		Tree = DialogueBuilder:YesNoOption(
			BuildDialogueDisplay(
				BuildDialogueTextData( "YesNo1", false, "Yes-No 101", false ),
				"rbxassetid://-1",
				false,
				false
			),
			DialogueBuilder:SingleAction(
				"dialogue1_action1",
				0
			),
			DialogueBuilder:SingleAction(
				"dialogue1_action2",
				0
			)
		),
	},

}

function Module:GetDialogueFromId( dialogueId )
	return Module.Dialogue[ dialogueId ]
end

return Module
