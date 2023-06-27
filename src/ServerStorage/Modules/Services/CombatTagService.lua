local HumanoidCombatTags = {}

-- // Module // --
local Module = {}

function Module:ClearHumanoidCombatTags( Humanoid )
	HumanoidCombatTags[Humanoid] = nil
end

function Module:GetHumanoidCombatTags( Humanoid, MaxTimeoutPeriod )
	MaxTimeoutPeriod = MaxTimeoutPeriod or 45
	local CacheData = HumanoidCombatTags[Humanoid]
	if CacheData then
		for PlayerInstance, Data in pairs( CacheData ) do
			if time() - Data.Time > MaxTimeoutPeriod then
				CacheData[PlayerInstance] = nil
			end
		end
	end
	return CacheData
end

function Module:CombatTagHumanoid( Humanoid, Damage, OwnerPlayer )
	if not HumanoidCombatTags[Humanoid] then
		HumanoidCombatTags[Humanoid] = {}
	end
	if HumanoidCombatTags[Humanoid][OwnerPlayer] then
		HumanoidCombatTags[Humanoid][OwnerPlayer].Damage += Damage
		HumanoidCombatTags[Humanoid][OwnerPlayer].Time = time()
	else
		HumanoidCombatTags[Humanoid][OwnerPlayer] = {Time = time(), Damage = Damage}
	end
end

function Module:CombatDamageHumanoid( Humanoid, Damage, OwnerPlayer )
	Module:CombatTagHumanoid( Humanoid, Damage, OwnerPlayer )
	Humanoid:TakeDamage(Damage)
end

return Module