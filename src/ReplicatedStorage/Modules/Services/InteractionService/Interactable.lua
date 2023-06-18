local EventClass = require(script.Parent.Parent.Parent.Classes.Event)
local MaidClass = require(script.Parent.Parent.Parent.Classes.Maid)

-- // Class // --
local Class = {}
Class.__index = Class

function Class.New( TargetInstance, CanUseInteractionCallbacks )
	if typeof(CanUseInteractionCallbacks) == "function" then
		CanUseInteractionCallbacks = { CanUseInteractionCallbacks }
	end

	local StartedEvent = EventClass.New()
	local CanceledEvent = EventClass.New()
	local CompletedEvent = EventClass.New()
	return setmetatable({
		TargetInstance = TargetInstance,
		Destroyed = nil,

		Keybinds = { Enum.KeyCode.F, Enum.KeyCode.ButtonB },
		Duration = 3,
		--MaxDistance = 30,

		Enabled = true,
		CanUseInteraction = CanUseInteractionCallbacks or false,

		_Maid = MaidClass.New(StartedEvent, CanceledEvent, CompletedEvent),
		Events = {
			Started = StartedEvent,
			Canceled = CanceledEvent,
			Completed = CompletedEvent,
		},
	}, Class)
end

function Class:SetKeybinds( ... )
	self.Keybinds = { ... }
end

function Class:SetCanUseFunction( Callback )
	self.CanUseInteraction = Callback
end

function Class:OnInteractStarted( callback )
	local connection = self.Events.Started:Connect(callback)
	self._Maid:Give(connection)
	return connection
end

function Class:OnInteractCanceled( callback )
	local connection = self.Events.Canceled:Connect(callback)
	self._Maid:Give(connection)
	return connection
end

function Class:OnInteractCompleted( callback )
	local connection = self.Events.Completed:Connect(callback)
	self._Maid:Give(connection)
	return connection
end

function Class:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true

	self._Maid:Cleanup()
	self.Events.Started:Disconnect()
	self.Events.Canceled:Disconnect()
	self.Events.Completed:Disconnect()
end

return Class
