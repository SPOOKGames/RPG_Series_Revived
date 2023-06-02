local Players = game:GetService('Players')

local ServerStorage = game:GetService('ServerStorage')
local ServerModules = require(ServerStorage:WaitForChild("Modules"))

local ProfileService = ServerModules.Services.ProfileService

local ProfileCache = {}
local Loading = {}
local GameProfileStore = false

local TemplateData = {
	Version = 1,
	Banned = false,

	Level = 1,
	Experience = 0,
	Currency = { Copper = 0, Silver = 0, Gold = 0, Platinum = 0, },

	Attributes = { },
	Inventory = { },
	Quests = {},
}

local SystemsContainer = {}

-- // Module // --
local Module = {}

-- Get the player's profile (optional Yield until present)
function Module:GetProfileFromPlayer(LocalPlayer, Yield)
	while (not ProfileCache[LocalPlayer.UserId]) and Yield and LocalPlayer:IsDescendantOf(Players) do
		task.wait(0.1)
	end
	return ProfileCache[LocalPlayer.UserId]
end

-- Load the user id's data profile
function Module:_LoadDataFromUserId( UserId )
	if Loading[ UserId ] then
		while Loading[ UserId ] do
			task.wait(0.1)
		end
		return ProfileCache[ UserId ]
	end

	if ProfileCache[UserId] then
		return ProfileCache[UserId]
	end

	Loading[ UserId ] = true

	local LoadedProfile = GameProfileStore:LoadProfileAsync( tostring(UserId), "ForceLoad" )
	if LoadedProfile then
		LoadedProfile:Reconcile()
		LoadedProfile:AddUserId(UserId)
		LoadedProfile:ListenToRelease(function()
			ProfileCache[UserId] = nil
		end)
	end

	Loading[ UserId ] = nil
	return LoadedProfile
end

-- Load the given player's data profile
function Module:_LoadDataFromPlayer( LocalPlayer )
	local UserId = LocalPlayer.UserId
	local Profile = Module:_LoadDataFromUserId( UserId )

	if not Profile then
		LocalPlayer:Kick('Failed to load your profile data.')
		return false
	end

	Profile:ListenToRelease(function()
		ProfileCache[UserId] = nil
		if not Profile.Data.Banned then
			LocalPlayer:Kick('Profile has been loaded elsewhere.')
		end
	end)

	if LocalPlayer:IsDescendantOf(Players) then
		local IsBanned = SystemsContainer.BanService:CheckProfileBanExpired(LocalPlayer.UserId, Profile)
		if IsBanned then
			Profile:Release()
			local BanMessage = SystemsContainer.BanService:CompileBanMessage(Profile.Data.Banned)
			if LocalPlayer:IsDescendantOf(Players) then
				LocalPlayer:Kick(BanMessage)
			end
			return false
		end
		ProfileCache[LocalPlayer.UserId] = Profile
	else
		Profile:Release()
		ProfileCache[LocalPlayer.UserId] = nil
	end

	ProfileCache[LocalPlayer.UserId] = Profile
	return Profile
end

-- Release the data profile for this given userId
function Module:ReleaseUserId( UserId )
	local activeProfile = ProfileCache[UserId]
	if activeProfile then
		ProfileCache[UserId]:Release()
	end
	ProfileCache[UserId] = nil
	Loading[UserId] = nil
end

-- Release the given player's data profile
function Module:ReleasePlayer( LocalPlayer )
	return Module:ReleaseUserId( LocalPlayer.UserId )
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems

	GameProfileStore = ProfileService.GetProfileStore('PlayerData1', TemplateData).Mock -- NOTE: .Mock means data DOES NOT save.
end

return Module
