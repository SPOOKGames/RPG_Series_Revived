local Players = game:GetService('Players')
local MessagingService = game:GetService('MessagingService')

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

-- Check if a player profile is still banned or if the ban has expired
function Module:CheckProfileBanExpired(_, Profile)
	local currentUTC = GetUTC()
	local BannedData = Profile.Data.Banned
	if BannedData and (currentUTC - BannedData.Start) >= BannedData.Duration then
		Profile.Data.Banned = nil
	end
	return (Profile.Data.Banned == nil)
end

-- Compile a ban message data into the string version
function Module:CompileBanMessage(BannedData)
	if typeof(BannedData.Duration) == 'string' then
		return BannedData.Duration
	end
	local currentUTC = GetUTC()
	local duration = RoundN(currentUTC - BannedData.Duration, 1)
	return string.format(REMAINING_TEXT_FORMAT, duration)
end

-- Add any missing properties of the ban data
function Module:ConcileBanProperties(BanProperties)
	return {
		Moderator = BanProperties.Moderator or 'Server',
		Duration = BanProperties.Duration or (1 * DAY_DURATION),
		Reason = BanProperties.Reason or 'Unknown Reason',
		Start = GetUTC(),
	}
end

-- Ban the given userid
function Module:BanUserId( UserId, BanProperties )
	local LocalPlayer = Players:GetPlayerByUserId(UserId)
	if LocalPlayer then
		LocalPlayer:Kick('You have been banned.')
	end

	task.defer(function()
		MessagingService:PublishAsync('BanServiceNotif', { UserId, BanProperties.Reason })
	end)

	local Profile = SystemsContainer.DataServer:_LoadDataFromUserId(UserId)
	if Profile then
		BanProperties = Module:ConcileBanProperties(BanProperties)
		Profile.Data.Banned = BanProperties
		Profile:Release()
	end
end

-- ban the given player
function Module:BanPlayer(LocalPlayer, BanProperties)
	return Module:BanUserId( LocalPlayer.UserId, BanProperties )
end

function Module:Start()

	MessagingService:SubscribeAsync('BanServiceNotif', function(data)
		local userId, banReason = unpack(data)
		local LocalPlayer = Players:GetPlayerByUserId( userId )
		if LocalPlayer then
			LocalPlayer:Kick('You have been banned! ' .. tostring(banReason))
		end
	end)

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
