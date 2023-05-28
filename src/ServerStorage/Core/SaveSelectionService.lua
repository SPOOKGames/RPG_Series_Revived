local Players = game:GetService('Players')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedCore = require(ReplicatedStorage:WaitForChild('Core'))

local ReplicatedData = ReplicatedCore.ReplicatedData

local SystemsContainer = {}

-- // Module // --
local Module = {}

-- When the player joins the game, ...
function Module:OnPlayerAdded( LocalPlayer )
	print('Loading', LocalPlayer.Name, "'s profile data.")

	local playerProfile = SystemsContainer.DataService:_LoadDataFromPlayer( LocalPlayer )

	ReplicatedData:SetData('PlayerData', playerProfile.Data, {LocalPlayer})

	return playerProfile
end

-- When the player leaves the game, ...
function Module:OnPlayerRemoving( LocalPlayer )
	-- TODO: any last edits?
	SystemsContainer.DataService:ReleasePlayer( LocalPlayer )
end

function Module:Start()
	for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
		task.defer(function()
			Module:OnPlayerAdded( LocalPlayer )
		end)
	end

	Players.PlayerAdded:Connect(function(LocalPlayer)
		Module:OnPlayerAdded( LocalPlayer )
	end)

	Players.PlayerRemoving:Connect(function(LocalPlayer)
		Module:OnPlayerRemoving( LocalPlayer )
	end)
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
