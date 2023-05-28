local Players = game:GetService('Players')

local ServerStorage = game:GetService("ServerStorage")
local ServerModules = require(ServerStorage:WaitForChild("Modules"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedCore = require(ReplicatedStorage:WaitForChild('Core'))
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local ReplicatedData = ReplicatedCore.ReplicatedData

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:OnPlayerAdded( LocalPlayer )
	print('Loading', LocalPlayer.Name, "'s profile data.")

	local profile = SystemsContainer.DataService:_LoadDataFromPlayer( LocalPlayer )

	ReplicatedData:SetData('PlayerData', profile.Data, {LocalPlayer})

	return profile
end

function Module:OnPlayerRemoving( LocalPlayer )
	-- any last edits?
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
