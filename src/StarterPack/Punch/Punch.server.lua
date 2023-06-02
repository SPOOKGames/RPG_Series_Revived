local Players = game:GetService("Players")
local LocalPlayer = nil

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedCore = require(ReplicatedStorage:WaitForChild('Core'))
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local CombatCoreModule = ReplicatedCore.CombatCore

local CombatTagService = ReplicatedModules.Services.CombatTagService
local HitboxService = ReplicatedModules.Services.HitboxService
local VisualizersModule = ReplicatedModules.Utility.Visualizers

local Tool = script.Parent
local CombatConfig = require(Tool:WaitForChild('Config'))

local CurrentCombo = 1
local LastCombatTick = time()
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

Tool.Activated:Connect(function()
	if time() - LastCombatTick < CombatConfig.MINIMUM_INTERVAL_PERIOD then
		return
	end

	if time() - LastCombatTick > CombatConfig.COMBO_TIMEOUT_PERIOD then
		CurrentCombo = 1
	else
		CurrentCombo += 1
		if CurrentCombo > #CombatConfig.ANIMATION_IDS then
			CurrentCombo = 1
		end
	end

	local characterPivot = Tool.Parent:GetPivot()
	local offsetCFrame = characterPivot + (characterPivot.LookVector * 3)
	local hitboxSize = Vector3.one * 4

	local hitParts = HitboxService:GetHitsInBounds( offsetCFrame, hitboxSize, overlapParams )
	VisualizersModule:BasePart(offsetCFrame, 0.4, {Size = hitboxSize, Transparency = 0.4, Color = Color3.new(0.9,0,0)})

	local doApplyKnockback = (CurrentCombo == #CombatConfig.ANIMATION_IDS)

	local hitHumanoids = HitboxService:FindHumanoidsFromHits( hitParts )
	for _, humanoid in ipairs( hitHumanoids ) do
		if doApplyKnockback then
			CombatCoreModule:Knockback( humanoid.Parent.PrimaryPart, Tool.Parent:GetPivot().Position )
		end
		CombatTagService:CombatDamageHumanoid( humanoid, 30, LocalPlayer )
	end

	LastCombatTick = time()
end)

Tool.Equipped:Connect(function()
	overlapParams.FilterDescendantsInstances = { Tool.Parent }
	LocalPlayer = Players:GetPlayerFromCharacter( Tool.Parent )
end)

Tool.Unequipped:Connect(function()
	overlapParams.FilterDescendantsInstances = { }
	LocalPlayer = nil
end)
