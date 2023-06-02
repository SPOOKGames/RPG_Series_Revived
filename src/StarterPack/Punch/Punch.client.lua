local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

local PlayerModule = require(LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule'))
local PlayerControls = PlayerModule:GetControls()

local Tool = script.Parent
local CombatConfig = require(Tool:WaitForChild('Config'))

local ActiveAnimations = {}
local LastCombatTick = time()
local CurrentCombo = 1

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

	PlayerControls:Disable()

	if ActiveAnimations[CurrentCombo] then
		ActiveAnimations[CurrentCombo]:Play()
	end

	local CurrentComboValue = CurrentCombo
	task.delay(CombatConfig.MOVEMENT_DISABLE_PERIOD, function()
		if CurrentComboValue == CurrentCombo then
			PlayerControls:Enable()
		end
	end)

	LastCombatTick = time()
end)

Tool.Equipped:Connect(function()
	local Character = Tool.Parent
	local Humanoid = Character:FindFirstChildWhichIsA('Humanoid')
	if not Humanoid then
		return
	end

	for _, animationId in ipairs( CombatConfig.ANIMATION_IDS ) do
		local animationObject = Instance.new('Animation')
		animationObject.AnimationId = animationId
		local loadedAnimation = Humanoid.Animator:LoadAnimation( animationObject )
		table.insert(ActiveAnimations, loadedAnimation)
	end
end)

Tool.Unequipped:Connect(function()
	ActiveAnimations = {}
end)
