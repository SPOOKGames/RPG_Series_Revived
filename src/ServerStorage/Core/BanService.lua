local Players = game:GetService('Players')

local DAY_DURATION = 24 * 60 * 60
local REMAINING_TEXT_FORMAT = "Remaining Duration : %s seconds"

local SystemsContainer = {}

local function GetUTC()
	return os.time(os.date('!*t'))
end

local function RoundN( number, decimal_places )
	local pow10 = math.pow(10, decimal_places)
	return math.floor(number * pow10) / pow10
end

-- // Module // --
local Module = {}

function Module:CompileBanMessage(BannedData)
	if typeof(BannedData.Duration) == 'string' then
		return BannedData.Duration
	end
	local currentUTC = GetUTC()
	local duration = RoundN(currentUTC - BannedData.Duration, 1)
	return string.format(REMAINING_TEXT_FORMAT, duration)
end

function Module:CheckProfileBanExpired(UserId, Profile)
	local currentUTC = GetUTC()
	local BannedData = Profile.Data.Banned
	if BannedData and (currentUTC - BannedData.Start) >= BannedData.Duration then
		Profile.Data.Banned = nil
	end
	return (Profile.Data.Banned == nil)
end

function Module:ConcileBanProperties(BanProperties)
	return {
		Moderator = BanProperties.Moderator or 'Server',
		Duration = BanProperties.Duration or (1 * DAY_DURATION),
		Reason = BanProperties.Reason or 'Unknown Reason',
		Start = GetUTC(),
	}
end

function Module:BanPlayer(LocalPlayer, BanProperties)
	BanProperties = Module:ConcileBanProperties(BanProperties)

	Module:BanUserId( LocalPlayer.UserId, BanProperties )

	LocalPlayer:Kick('You have been banned for : '..BanProperties.Duration)
end

function Module:BanUserId( UserId, BanProperties )
	local LocalPlayer = Players:GetPlayerByUserId(UserId)
	if LocalPlayer then
		Module:BanPlayer(LocalPlayer, BanProperties)
		return
	end

	local Profile = SystemsContainer.DataService:_LoadDataFromUserId(UserId)
	if Profile then
		BanProperties = Module:ConcileBanProperties(BanProperties)
		Profile.Data.Banned = BanProperties
		Profile:Release()
	end
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
