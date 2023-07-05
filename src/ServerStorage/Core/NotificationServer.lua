local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local RemoteService = ReplicatedModules.Services.RemoteService
local NotificationEvent = RemoteService:GetRemote("NotificiationEvent", "RemoteEvent", false)

local SystemsContainer = {}

local NotificationCache = {}

-- // Module // --
local Module = {}

function Module:Notify(targetPlayer, titleText, titleColor, descriptionText, descriptionColor, duration)
	if NotificationCache[targetPlayer] then
		table.insert(NotificationCache[targetPlayer], {titleText, titleColor, descriptionText, descriptionColor, duration})
	else
		NotificationEvent:FireClient(targetPlayer, titleText, titleColor, descriptionText, descriptionColor, duration)
	end
end

function Module:NotifyAll(titleText, titleColor, descriptionText, descriptionColor, duration)
	for _, LocalPlayer in ipairs( Players:GetPlayers() ) do
		Module:Notify(LocalPlayer, titleText, titleColor, descriptionText, descriptionColor, duration)
	end
end

function Module:Start()

	NotificationEvent.OnServerEvent:Connect(function( LocalPlayer )
		if not NotificationCache[LocalPlayer] then
			return
		end
		local Cached = NotificationCache[LocalPlayer]
		NotificationCache[LocalPlayer] = nil
		for _, Data in ipairs( Cached ) do
			Module:Notify(LocalPlayer, unpack(Data))
		end
	end)

	Players.PlayerAdded:Connect(function( LocalPlayer )
		NotificationCache[LocalPlayer] = { }
		Module:NotifyAll(
			"A player has joined.", Color3.new(1,1,1),
			LocalPlayer.Name.." has joined the game.", Color3.new(1,1,1),
			2
		)
	end)

	Players.PlayerRemoving:Connect(function( LocalPlayer )
		NotificationCache[LocalPlayer] = nil
	end)

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module