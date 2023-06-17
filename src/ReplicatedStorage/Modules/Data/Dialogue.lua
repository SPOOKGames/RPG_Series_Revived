
--[[
	ability to:
	- cutscene
	- audio/visual/camera effect
	- run quest event (Talk/Interact)
	- viewport & icon image
	- rich text
	- dialogue actions (DelaySeconds, MultiOption)
	- button events (onHoverStart, onHoverMove, onHoverEnd, onClick)
	- continue dialogue to another dialogue tree
]]

local Module = {}

Module.Dialogue = {

	TestDialogue1 = {

	},

}

function Module:GetDialogueFromId( dialogueId )
	return Module.Dialogue[ dialogueId ]
end

return Module
