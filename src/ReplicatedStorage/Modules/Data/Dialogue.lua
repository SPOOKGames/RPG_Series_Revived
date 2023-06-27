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

function DialogueBuilder:ConditionalCheck( conditionFunction, ifTrue, ifFalse )
	return { Type = "Conditional", Condition = conditionFunction, True = ifTrue, False = ifFalse }
end

function DialogueBuilder:ExitDialogue()
	return { Type = "Exit" }
end

function DialogueBuilder:BuildExitButton()
	return {
		Display = BuildOptionDisplayData('Exit'),
		Options = DialogueBuilder:ExitDialogue(),
	}
end

function DialogueBuilder:DisplayTextContent( titleText, descriptionText, after )
	return DialogueBuilder:MultiOption(
		BuildDialogueDisplay(
			BuildDialogueTextData(titleText, false, descriptionText, false),
			"rbxassetid://-1",
			false,
			false
		),
		{
			Display = BuildOptionDisplayData('...'),
			Options = after,
		}
	)
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
				BuildDialogueTextData("Yes-No", false, "Yes for action, no to close", false),
				"rbxassetid://-1",
				false,
				false
			),
			DialogueBuilder:SingleAction( "START_QUEST:TestQuestLine2", 0 ),
			DialogueBuilder:ExitDialogue()
		),
	},

	TestDialogue2 = {
		Tree = DialogueBuilder:ConditionalCheck(
			function(LocalPlayer, PlayerData, dialogueId)
				return table.find( PlayerData.CompletedQuests, dialogueId)
			end,
			DialogueBuilder:DisplayTextContent(
				'Billy',
				'You have already completed my tasks!',
				DialogueBuilder:ExitDialogue()
			),
			DialogueBuilder:ConditionalCheck(
				function(LocalPlayer, PlayerData, dialogueId)
					return PlayerData.Quests[ dialogueId ]
				end,
				DialogueBuilder:DisplayTextContent(
					BuildDialogueDisplay(
						BuildDialogueTextData( "Billy", false, "Ya haven't completed the tasks yet.", false ),
						"rbxassetid://-1",
						false,
						false
					),
					DialogueBuilder:BuildExitButton()
				), -- they are currently busy with the quest
				DialogueBuilder:YesNoOption(
					BuildDialogueDisplay(
						BuildDialogueTextData( "Billy", false, "Start the level 3 quest?", false ),
						"rbxassetid://-1",
						false,
						false
					),
					DialogueBuilder:ConditionalCheck(
						function(LocalPlayer, PlayerData)
							return PlayerData and PlayerData.Level >= 3
						end,
						DialogueBuilder:SingleAction( "start_billy_quest", 0 ),
						DialogueBuilder:MultiOption(
							BuildDialogueDisplay(
								BuildDialogueTextData( "Billy", false, "You must be level 3 at minimum.", false ),
								"rbxassetid://-1",
								false,
								false
							),
							DialogueBuilder:BuildExitButton()
						)
					),
					DialogueBuilder:ExitDialogue()
				) -- they have not started the quest
			)
		),
	},

}

function Module:GetDialogueFromId( dialogueId )
	return Module.Dialogue[ dialogueId ]
end

return Module
