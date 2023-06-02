local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer

local PlayerModule = require(LocalPlayer:WaitForChild('PlayerScripts'):WaitForChild('PlayerModule'))
local PlayerControls = PlayerModule:GetControls()

local AnimationIds = {"rbxassetid://6147296899", "rbxassetid://6147300658", "rbxassetid://6147303386"}
local ActiveAnimations = {}

local Tool = script.Parent
local LastCombatTick = tick()
local CurrentCombo = 1

local MINIMUM_INTERVAL_PERIOD = 0.2
local MOVEMENT_DISABLE_PERIOD = 0.65
local COMBO_TIMEOUT_PERIOD = 1.1

Tool.Activated:Connect(function()
	if tick() - LastCombatTick < MINIMUM_INTERVAL_PERIOD then
		return
	end

	if tick() - LastCombatTick > COMBO_TIMEOUT_PERIOD then
		CurrentCombo = 1
	else
		CurrentCombo += 1
		if CurrentCombo > #ActiveAnimations then
			CurrentCombo = 1
		end
	end

	PlayerControls:Disable()

	-- TODO: server damage stuff

	if ActiveAnimations[CurrentCombo] then
		ActiveAnimations[CurrentCombo]:Play()
	end

	local CurrentComboValue = CurrentCombo
	task.delay(MOVEMENT_DISABLE_PERIOD, function()
		if CurrentComboValue == CurrentCombo then
			PlayerControls:Enable()
		end
	end)

	LastCombatTick = tick()
end)

Tool.Equipped:Connect(function()
	local Character = Tool.Parent
	local Humanoid = Character:FindFirstChildWhichIsA('Humanoid')
	if not Humanoid then
		return
	end

	for _, animationId in ipairs( AnimationIds ) do
		local animationObject = Instance.new('Animation')
		animationObject.AnimationId = animationId
		local loadedAnimation = Humanoid.Animator:LoadAnimation( animationObject )
		table.insert(ActiveAnimations, loadedAnimation)
	end
end)

Tool.Unequipped:Connect(function()
	ActiveAnimations = {}
end)
