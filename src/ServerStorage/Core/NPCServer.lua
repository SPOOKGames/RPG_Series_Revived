
local ServerStorage = game:GetService("ServerStorage")
local ServerModules = require(ServerStorage:WaitForChild("Modules"))

local CombatTagService = ServerModules.Services.CombatTagService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local QuestsConfigModule = ReplicatedModules.Data.Quests

local SystemsContainer = {}

-- // Module // --
local Module = {}

function Module:OnNPCDeath( Model, Humanoid )
	local DamageData = CombatTagService:GetHumanoidCombatTags( Humanoid )
	CombatTagService:ClearHumanoidCombatTags( Humanoid )
	for LocalPlayer, Data in pairs(DamageData) do
		if Data.Damage > Humanoid.MaxHealth * 0.03 then -- minimum 3% of health damage to receive reward
			SystemsContainer.QuestServer:AppendQuestContributions( LocalPlayer, QuestsConfigModule.DictContributions.Subjugate, Model.Name, 1 )
			SystemsContainer.LootTableServer:RewardEnemyLootToPlayer( LocalPlayer, Model.Name )
		end
	end
end

function Module:SetupSimpleNPC(Model)
	local Humanoid = Model:FindFirstChildWhichIsA('Humanoid')
	if not Humanoid then
		return
	end

	local BackupModel = Model:Clone()

	local diedConnection; diedConnection = Humanoid.Died:Connect(function()
		diedConnection:Disconnect()

		Module:OnNPCDeath( Model, Humanoid )

		task.delay(5, function()
			Model:Destroy()
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
	SystemsContainer = otherSystems
end

return Module
