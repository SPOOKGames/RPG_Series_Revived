local ContextActionService = game:GetService('ContextActionService')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local LocalAssets = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild('Assets')
local LocalModules = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Modules"))

local Interface = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('Interface')
local MobileInteractFrame = Interface:WaitForChild('MobileInteract')

local DesktopInteractBillboard = LocalAssets.UI.InteractDesktop:Clone()
DesktopInteractBillboard.Parent = LocalPlayer:WaitForChild('PlayerGui')
local InteractHighlight = LocalAssets.UI.InteractHighlight:Clone()
InteractHighlight.Parent = LocalPlayer:WaitForChild('PlayerGui')

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local InteractionService = ReplicatedModules.Services.InteractionService

local RemoteService = ReplicatedModules.Services.RemoteService
local InteractionEvent = RemoteService:GetRemote('InteractionEvent', 'RemoteEvent', false)
local InteractionFunction = RemoteService:GetRemote('InteractionFunction', 'RemoteFunction', false)

local SystemsContainer = {}

local ClientBarAlphaValue = Instance.new('NumberValue')
ClientBarAlphaValue.Value = 0

-- // Module // --
local Module = {}

Module.IsDesktopMode = true
Module.PlatformMaid = ReplicatedModules.Classes.Maid.New()

Module.CurrentHoldingInteractable = false
Module.CurrentHoldingID = 0
Module.ActiveTween = nil

function Module:HandleInteractionStart(InteractableClass)
	local hasDuration = InteractableClass.HoldDuration and InteractableClass.HoldDuration > 0
	local startJob = hasDuration and InteractionService.INTERACT_JOBS.Started or InteractionService.INTERACT_JOBS.Completed

	local usageState, customErr = InteractionFunction:InvokeServer( startJob, InteractableClass.TargetInstance )
	if usageState ~= InteractionService.INTERACT_EXCEPTIONS.Available then
		warn(customErr) -- TODO: show custom error
		return
	end

	Module.CurrentHoldingID += 1

	if not hasDuration then
		-- completed straight away
		Module.CurrentHoldingInteractable = nil
		InteractableClass.Events.Completed:Fire()
		return
	end

	-- start holding
	local CurrentId = Module.CurrentHoldingID
	Module.CurrentHoldingInteractable = InteractableClass
	InteractableClass.Events.Started:Fire()
	ClientBarAlphaValue.Value = 0
	if Module.ActiveTween then
		Module.ActiveTween:Cancel()
	end
	Module.ActiveTween = TweenService:Create(ClientBarAlphaValue, TweenInfo.new(InteractableClass.HoldDuration), {Value = 1})
	Module.ActiveTween:Play()
	task.delay(InteractableClass.HoldDuration, function()
		if Module.CurrentHoldingInteractable == InteractableClass and CurrentId == Module.CurrentHoldingID then
			Module.CurrentHoldingInteractable = nil
			Module.ActiveTween = nil
			InteractionFunction:InvokeServer( InteractionService.INTERACT_JOBS.Completed, InteractableClass.TargetInstance )
			InteractableClass.Events.Completed:Fire()
		end
	end)
end

function Module:HandleInteractionCancel()
	if not Module.CurrentHoldingInteractable then
		return
	end

	Module.CurrentHoldingInteractable.Events.Canceled:Fire()
	InteractionFunction:InvokeServer( InteractionService.INTERACT_JOBS.Canceled, Module.CurrentHoldingInteractable.TargetInstance )
	Module.CurrentHoldingInteractable = nil

	if Module.ActiveTween then
		Module.ActiveTween:Cancel()
	end
	Module.ActiveTween = nil

	InteractHighlight.Adornee = nil
	DesktopInteractBillboard.Adornee = nil
	MobileInteractFrame.Visible = false
end

function Module:OnInputBegan( inputObject )
	if Module.CurrentHoldingInteractable then
		return Enum.ContextActionResult.Pass
	end

	if (not Module.ClosestInteractableClass) or (not InteractionService:IsKeybindInInteractable(Module.ClosestInteractableClass, inputObject.KeyCode)) then
		return Enum.ContextActionResult.Pass
	end

	Module:HandleInteractionStart(Module.ClosestInteractableClass)
	return Enum.ContextActionResult.Sink
end

function Module:OnInputEnded( inputObject )
	-- stop dialogue bar
	if not Module.CurrentHoldingInteractable then
		return Enum.ContextActionResult.Pass
	end

	if not InteractionService:IsKeybindInInteractable(Module.CurrentHoldingInteractable, inputObject.KeyCode) then
		return Enum.ContextActionResult.Pass
	end

	Module:HandleInteractionCancel()
	return Enum.ContextActionResult.Sink
end

function Module:SetupPlatformControls()
	Module.PlatformMaid:Cleanup()

	if Module.IsDesktopMode then
		-- desktop / gamepad
		ContextActionService:BindAction('InteractionKeybind', function(actionName, inputState, inputObject)
			if actionName == 'InteractionKeybind' then
				if inputState == Enum.UserInputState.Begin then
					return Module:OnInputBegan(inputObject)
				else
					return Module:OnInputEnded(inputObject)
				end
			end
			return Enum.ContextActionResult.Pass
		end, false, unpack( Enum.KeyCode:GetEnumItems() ))

		Module.PlatformMaid:Give(function()
			ContextActionService:UnbindAction('InteractionKeybind')
		end)
	else
		-- mobile
		Module.PlatformMaid:Give(MobileInteractFrame.Button.Activated:Connect(function()
			if Module.ClosestInteractableClass then
				Module:HandleInteractionStart( Module.ClosestInteractableClass )
			end
		end))

		Module.PlatformMaid:Give(MobileInteractFrame.Button.Deactivated:Connect(function()
			Module:HandleInteractionCancel( )
		end))
	end
end

function Module:Update()
	local Position = LocalPlayer.Character and LocalPlayer.Character:GetPivot().Position
	local InteractableClass, _ = InteractionService:GetClosestInteractable( Position )
	Module.ClosestInteractableClass = InteractableClass
	if not InteractableClass then
		InteractHighlight.Adornee = nil
		DesktopInteractBillboard.Adornee = nil
		MobileInteractFrame.Visible = false
		return
	end

	local IsNPC = InteractionService:IsInstanceAnNPC( InteractableClass.TargetInstance )
	local TALK_TO_TEXT = "Talk to [%s]"
	local INTERACT_WITH_TEXT = "Interact with [%s]"
	local INTERACT_NPC_TEXT = "Press [%s] to talk to the NPC"
	local INTERACT_KEYBIND_TEXT = "Press [%s] to interact with the object"

	InteractHighlight.Adornee = InteractableClass.TargetInstance
	DesktopInteractBillboard.Adornee = InteractableClass.TargetInstance
	MobileInteractFrame.Visible = (not Module.IsDesktopMode)

	local INTERACT_TITLE_TEXT = string.format(
		IsNPC and TALK_TO_TEXT or INTERACT_WITH_TEXT,
		InteractableClass.TargetInstance.Name
	)
	if Module.IsDesktopMode then
		DesktopInteractBillboard.Frame.TitleLabel.Text = INTERACT_TITLE_TEXT
		local GamepadEnabled = #UserInputService:GetConnectedGamepads() > 0
		DesktopInteractBillboard.Frame.KeybindLabel.Text = string.format(
			IsNPC and INTERACT_NPC_TEXT or INTERACT_KEYBIND_TEXT,
			InteractableClass.Keybinds[ GamepadEnabled and 2 or 1 ].Name
		)
	else
		DesktopInteractBillboard.Frame.KeybindLabel.Visible = false
		MobileInteractFrame.Title.Text = INTERACT_TITLE_TEXT
	end
end

function Module:Start()

	Module:SetupPlatformControls()

	ClientBarAlphaValue.Changed:Connect(function(value)
		value = math.clamp(value, 0.02, 0.99)
		DesktopInteractBillboard.Frame.Bar.UIGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(value - 0.01, 0),
			NumberSequenceKeypoint.new(value, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
	end)

	RunService.Heartbeat:Connect(function()
		DesktopInteractBillboard.Frame.Bar.Visible = (Module.ActiveTween ~= nil)
		Module:Update()
	end)

	InteractionEvent.OnClientEvent:Connect(function(Job, TargetInstance)
		if Job == 'RemoveInteraction' then
			InteractionService:RemoveInteraction(TargetInstance)
		elseif Job == 'SetupInteraction' then
			if not InteractionService:GetInteraction(TargetInstance) then
				InteractionService:CreateInteraction( TargetInstance, false )
			end
		end
	end)
	InteractionEvent:FireServer()
end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems

	local ActivePlatform = LocalModules.Utility.Platform:GetPlatform()
	Module.IsDesktopMode =  ActivePlatform ~= "Mobile"
end

return Module