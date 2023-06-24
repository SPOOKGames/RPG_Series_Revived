
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local CombatTagService = ReplicatedModules.Services.CombatTagService

local SystemsContainer = {}

local LOOT_TABLE_ID = 'Generic_TestDummyTable'

-- // Module // --
local Module = {}

function Module:SetupSimpleNPC(Model)
	local Humanoid = Model:FindFirstChildWhichIsA('Humanoid')
	if not Humanoid then
		return
	end

	local BackupModel = Model:Clone()

	local diedConnection; diedConnection = Humanoid.Died:Connect(function()
		diedConnection:Disconnect()

		local DamageData = CombatTagService:GetHumanoidCombatTags( Humanoid )
		CombatTagService:ClearHumanoidCombatTags( Humanoid )
		for LocalPlayer, Data in pairs(DamageData) do
			if Data.Damage > Humanoid.MaxHealth * (3/100) then -- minimum 3% of health damage to receive reward
				SystemsContainer.LootTableServer:RewardEnemyLootToPlayer( LocalPlayer, LOOT_TABLE_ID )
			end
		end

		task.delay(5, function()
			BackupModel.Parent = workspace
			Module:SetupSimpleNPC(BackupModel)
		end)
	end)

end

function Module:Start()
	for _, Model in ipairs( workspace:WaitForChild('SimpleNPCs'):GetChildren() ) do
		Module:SetupSimpleNPC(Model)
	end
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems.ParentSystems
end

return Module
