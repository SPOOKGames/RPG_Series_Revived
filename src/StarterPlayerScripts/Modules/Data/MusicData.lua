
-- // Module // --
local Module = {}

Module.SongData = {
	Action1_Loop = {
		Properties = {
			SoundId = 'rbxassetid://13574722505',
			Volume = 0.1,
		},

		Display = false,
	},

	Action4_Loop = {
		Properties = {
			SoundId = 'rbxassetid://13574730489',
			Volume = 0.1,
		},

		Display = false,
	},

	Ambient1 = {
		Properties = {
			SoundId = 'rbxassetid://13574724252',
			Volume = 0.1,
		},

		Display = false,
	},

	Ambient2 = {
		Properties = {
			SoundId = 'rbxassetid://13574729362',
			Volume = 0.1,
		},

		Display = false,
	},

	Ambient6 = {
		Properties = {
			SoundId = 'rbxassetid://13574727184',
			Volume = 0.1,
		},

		Display = false,
	},

	Ambient8 = {
		Properties = {
			SoundId = 'rbxassetid://13574725747',
			Volume = 0.1,
		},

		Display = false,
	},
}

Module.SongIds = { } do
	for songId, _ in pairs(Module.SongData) do
		table.insert(Module.SongIds, songId)
	end
end

return Module
