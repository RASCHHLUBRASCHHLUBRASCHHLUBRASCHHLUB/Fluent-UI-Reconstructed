-- Fluent.single.full.lua
-- Arquivo único combinando os módulos do repositório dawid-scripts/Fluent
-- Cole como ModuleScript no Roblox Studio e faça: local Fluent = require(script)

-- ====================
-- Flipper (motors & signal)
-- ====================
local Flipper = {}

-- Signal
local Signal = {}
Signal.__index = Signal
local Connection = {}
Connection.__index = Connection

function Connection.new(signal, handler)
	return setmetatable({ signal = signal, connected = true, _handler = handler }, Connection)
end
function Connection:disconnect()
	if self.connected then
		self.connected = false
		for index, connection in pairs(self.signal._connections) do
			if connection == self then
				table.remove(self.signal._connections, index)
				return
			end
		end
	end
end

function Signal.new()
	return setmetatable({ _connections = {}, _threads = {} }, Signal)
end

function Signal:fire(...)
	for _, connection in pairs(self._connections) do
		connection._handler(...)
	end
	for _, thread in pairs(self._threads) do
		coroutine.resume(thread, ...)
	end
	self._threads = {}
end

function Signal:connect(handler)
	local connection = Connection.new(self, handler)
	table.insert(self._connections, connection)
	return connection
end

function Signal:wait()
	table.insert(self._threads, coroutine.running())
	return coroutine.yield()
end

-- BaseMotor
local RunService = game:GetService("RunService")
local BaseMotor = {}
BaseMotor.__index = BaseMotor
local noop = function() end

function BaseMotor.new()
	return setmetatable({
		_onStep = Signal.new(),
		_onStart = Signal.new(),
		_onComplete = Signal.new(),
	}, BaseMotor)
end

function BaseMotor:onStep(handler)
	return self._onStep:connect(handler)
end
function BaseMotor:onStart(handler)
	return self._onStart:connect(handler)
end
function BaseMotor:onComplete(handler)
	return self._onComplete:connect(handler)
end

function BaseMotor:start()
	if not self._connection then
		self._connection = RunService.RenderStepped:Connect(function(deltaTime)
			self:step(deltaTime)
		end)
	end
end

function BaseMotor:stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

BaseMotor.destroy = BaseMotor.stop
BaseMotor.step = noop
BaseMotor.getValue = noop
BaseMotor.setGoal = noop

function BaseMotor:__tostring()
	return "Motor"
end

-- SingleMotor
local SingleMotor = setmetatable({}, BaseMotor)
SingleMotor.__index = SingleMotor

function SingleMotor.new(initialValue, useImplicitConnections)
	assert(initialValue ~= nil, "Missing argument #1: initialValue")
	assert(typeof(initialValue) == "number", "initialValue must be a number!")
	local self = setmetatable(BaseMotor.new(), SingleMotor)
	if useImplicitConnections ~= nil then
		self._useImplicitConnections = useImplicitConnections
	else
		self._useImplicitConnections = true
	end
	self._goal = nil
	self._state = { complete = true, value = initialValue }
	return self
end

function SingleMotor:step(deltaTime)
	if self._state.complete then return true end
	local newState = self._goal:step(self._state, deltaTime)
	self._state = newState
	self._onStep:fire(newState.value)
	if newState.complete then
		if self._useImplicitConnections then self:stop() end
		self._onComplete:fire()
	end
	return newState.complete
end

function SingleMotor:getValue()
	return self._state.value
end

function SingleMotor:setGoal(goal)
	self._state.complete = false
	self._goal = goal
	self._onStart:fire()
	if self._useImplicitConnections then self:start() end
end

function SingleMotor:__tostring()
	return "Motor(Single)"
end

-- GroupMotor
local GroupMotor = setmetatable({}, BaseMotor)
GroupMotor.__index = GroupMotor

local function toMotor(value)
	if tostring(value):match("^Motor") or tostring(value):match("^Motor%((.+)%)$") then
		return value
	end
	local valueType = typeof(value)
	if valueType == "number" then
		return SingleMotor.new(value, false)
	elseif valueType == "table" then
		return GroupMotor.new(value, false)
	end
	error(("Unable to convert %q to motor; type %s is unsupported"):format(tostring(value), valueType), 2)
end

function GroupMotor.new(initialValues, useImplicitConnections)
	assert(initialValues, "Missing argument #1: initialValues")
	assert(typeof(initialValues) == "table", "initialValues must be a table!")
	assert(not initialValues.step, 'initialValues contains disallowed property "step". Did you mean to put a table of values here?')
	local self = setmetatable(BaseMotor.new(), GroupMotor)
	if useImplicitConnections ~= nil then
		self._useImplicitConnections = useImplicitConnections
	else
		self._useImplicitConnections = true
	end
	self._complete = true
	self._motors = {}
	for key, value in pairs(initialValues) do
		self._motors[key] = toMotor(value)
	end
	return self
end

function GroupMotor:step(deltaTime)
	if self._complete then return true end
	local allMotorsComplete = true
	for _, motor in pairs(self._motors) do
		local complete = motor:step(deltaTime)
		if not complete then allMotorsComplete = false end
	end
	self._onStep:fire(self:getValue())
	if allMotorsComplete then
		if self._useImplicitConnections then self:stop() end
		self._complete = true
		self._onComplete:fire()
	end
	return allMotorsComplete
end

function GroupMotor:setGoal(goals)
	assert(not goals.step, 'goals contains disallowed property "step". Did you mean to put a table of goals here?')
	self._complete = false
	self._onStart:fire()
	for key, goal in pairs(goals) do
		local motor = assert(self._motors[key], ("Unknown motor for key %s"):format(key))
		motor:setGoal(goal)
	end
	if self._useImplicitConnections then self:start() end
end

function GroupMotor:getValue()
	local values = {}
	for key, motor in pairs(self._motors) do
		values[key] = motor:getValue()
	end
	return values
end

function GroupMotor:__tostring()
	return "Motor(Group)"
end

-- Instant
local Instant = {}
Instant.__index = Instant
function Instant.new(targetValue)
	return setmetatable({ _targetValue = targetValue }, Instant)
end
function Instant:step()
	return { complete = true, value = self._targetValue }
end

-- Linear
local Linear = {}
Linear.__index = Linear
function Linear.new(targetValue, options)
	assert(targetValue ~= nil, "Missing argument #1: targetValue")
	options = options or {}
	return setmetatable({ _targetValue = targetValue, _velocity = options.velocity or 1 }, Linear)
end
function Linear:step(state, dt)
	local position = state.value
	local velocity = self._velocity
	local goal = self._targetValue
	local dPos = dt * velocity
	local complete = dPos >= math.abs(goal - position)
	position = position + dPos * (goal > position and 1 or -1)
	if complete then position = self._targetValue; velocity = 0 end
	return { complete = complete, value = position, velocity = velocity }
end

-- Spring
local VELOCITY_THRESHOLD = 0.001
local POSITION_THRESHOLD = 0.001
local EPS = 0.0001
local Spring = {}
Spring.__index = Spring
function Spring.new(targetValue, options)
	assert(targetValue ~= nil, "Missing argument #1: targetValue")
	options = options or {}
	return setmetatable({ _targetValue = targetValue, _frequency = options.frequency or 4, _dampingRatio = options.dampingRatio or 1 }, Spring)
end
function Spring:step(state, dt)
	local d = self._dampingRatio
	local f = self._frequency * 2 * math.pi
	local g = self._targetValue
	local p0 = state.value
	local v0 = state.velocity or 0
	local offset = p0 - g
	local decay = math.exp(-d * f * dt)
	local p1, v1
	if d == 1 then
		p1 = (offset * (1 + f * dt) + v0 * dt) * decay + g
		v1 = (v0 * (1 - f * dt) - offset * (f * f * dt)) * decay
	elseif d < 1 then
		local c = math.sqrt(1 - d * d)
		local i = math.cos(f * c * dt)
		local j = math.sin(f * c * dt)
		local z
		if c > EPS then
			z = j / c
		else
			local a = dt * f
			z = a + ((a * a) * (c * c) * (c * c) / 20 - c * c) * (a * a * a) / 6
		end
		local y
		if f * c > EPS then
			y = j / (f * c)
		else
			local b = f * c
			y = dt + ((dt * dt) * (b * b) * (b * b) / 20 - b * b) * (dt * dt * dt) / 6
		end
		p1 = (offset * (i + d * z) + v0 * y) * decay + g
		v1 = (v0 * (i - z * d) - offset * (z * f)) * decay
	else
		local c = math.sqrt(d * d - 1)
		local r1 = -f * (d - c)
		local r2 = -f * (d + c)
		local co2 = (v0 - offset * r1) / (2 * f * c)
		local co1 = offset - co2
		local e1 = co1 * math.exp(r1 * dt)
		local e2 = co2 * math.exp(r2 * dt)
		p1 = e1 + e2 + g
		v1 = e1 * r1 + e2 * r2
	end
	local complete = math.abs(v1) < VELOCITY_THRESHOLD and math.abs(p1 - g) < POSITION_THRESHOLD
	return { complete = complete, value = complete and g or p1, velocity = v1 }
end

local function isMotor(value)
	local motorType = tostring(value):match("^Motor%((.+)%)$")
	if motorType then return true, motorType else return false end
end

-- Populate Flipper
Flipper.SingleMotor = SingleMotor
Flipper.GroupMotor = GroupMotor
Flipper.Instant = Instant
Flipper.Linear = Linear
Flipper.Spring = Spring
Flipper.isMotor = isMotor
Flipper.Signal = Signal

-- ====================
-- Themes
-- ====================
local Themes = {}
Themes.Names = { "Dark", "Darker", "Light", "Aqua", "Amethyst", "Rose" }
Themes["Dark"] = {
	Name = "Dark",
	Accent = Color3.fromRGB(96, 205, 255),
	AcrylicMain = Color3.fromRGB(60, 60, 60),
	AcrylicBorder = Color3.fromRGB(90, 90, 90),
	AcrylicGradient = ColorSequence.new(Color3.fromRGB(40, 40, 40), Color3.fromRGB(40, 40, 40)),
	AcrylicNoise = 0.9,
	TitleBarLine = Color3.fromRGB(75, 75, 75),
	Tab = Color3.fromRGB(120, 120, 120),
	Element = Color3.fromRGB(120, 120, 120),
	ElementBorder = Color3.fromRGB(35, 35, 35),
	InElementBorder = Color3.fromRGB(90, 90, 90),
	ElementTransparency = 0.87,
	ToggleSlider = Color3.fromRGB(120, 120, 120),
	ToggleToggled = Color3.fromRGB(0, 0, 0),
	SliderRail = Color3.fromRGB(120, 120, 120),
	DropdownFrame = Color3.fromRGB(160, 160, 160),
	DropdownHolder = Color3.fromRGB(45, 45, 45),
	DropdownBorder = Color3.fromRGB(35, 35, 35),
	DropdownOption = Color3.fromRGB(120, 120, 120),
	Keybind = Color3.fromRGB(120, 120, 120),
	Input = Color3.fromRGB(160, 160, 160),
	InputFocused = Color3.fromRGB(10, 10, 10),
	InputIndicator = Color3.fromRGB(150, 150, 150),
	Dialog = Color3.fromRGB(45, 45, 45),
	DialogHolder = Color3.fromRGB(35, 35, 35),
	DialogHolderLine = Color3.fromRGB(30, 30, 30),
	DialogButton = Color3.fromRGB(45, 45, 45),
	DialogButtonBorder = Color3.fromRGB(80, 80, 80),
	DialogBorder = Color3.fromRGB(70, 70, 70),
	DialogInput = Color3.fromRGB(55, 55, 55),
	DialogInputLine = Color3.fromRGB(160, 160, 160),
	Text = Color3.fromRGB(240, 240, 240),
	SubText = Color3.fromRGB(170, 170, 170),
	Hover = Color3.fromRGB(120, 120, 120),
	HoverChange = 0.07,
}
Themes["Light"] = {
	Name = "Light",
	Accent = Color3.fromRGB(0, 103, 192),
	AcrylicMain = Color3.fromRGB(200, 200, 200),
	AcrylicBorder = Color3.fromRGB(120, 120, 120),
	AcrylicGradient = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
	AcrylicNoise = 0.96,
	TitleBarLine = Color3.fromRGB(160, 160, 160),
	Tab = Color3.fromRGB(90, 90, 90),
	Element = Color3.fromRGB(255, 255, 255),
	ElementBorder = Color3.fromRGB(180, 180, 180),
	InElementBorder = Color3.fromRGB(150, 150, 150),
	ElementTransparency = 0.65,
	ToggleSlider = Color3.fromRGB(40, 40, 40),
	ToggleToggled = Color3.fromRGB(255, 255, 255),
	SliderRail = Color3.fromRGB(40, 40, 40),
	DropdownFrame = Color3.fromRGB(200, 200, 200),
	DropdownHolder = Color3.fromRGB(240, 240, 240),
	DropdownBorder = Color3.fromRGB(200, 200, 200),
	DropdownOption = Color3.fromRGB(150, 150, 150),
	Keybind = Color3.fromRGB(120, 120, 120),
	Input = Color3.fromRGB(200, 200, 200),
	InputFocused = Color3.fromRGB(100, 100, 100),
	InputIndicator = Color3.fromRGB(80, 80, 80),
	Dialog = Color3.fromRGB(255, 255, 255),
	DialogHolder = Color3.fromRGB(240, 240, 240),
	DialogHolderLine = Color3.fromRGB(228, 228, 228),
	DialogButton = Color3.fromRGB(255, 255, 255),
	DialogButtonBorder = Color3.fromRGB(190, 190, 190),
	DialogBorder = Color3.fromRGB(140, 140, 140),
	DialogInput = Color3.fromRGB(250, 250, 250),
	DialogInputLine = Color3.fromRGB(160, 160, 160),
	Text = Color3.fromRGB(0, 0, 0),
	SubText = Color3.fromRGB(40, 40, 40),
	Hover = Color3.fromRGB(50, 50, 50),
	HoverChange = 0.16,
}
Themes["Darker"] = {
	Name = "Darker",
	Accent = Color3.fromRGB(72, 138, 182),
	AcrylicMain = Color3.fromRGB(30, 30, 30),
	AcrylicBorder = Color3.fromRGB(60, 60, 60),
	AcrylicGradient = ColorSequence.new(Color3.fromRGB(25, 25, 25), Color3.fromRGB(15, 15, 15)),
	AcrylicNoise = 0.94,
	TitleBarLine = Color3.fromRGB(65, 65, 65),
	Tab = Color3.fromRGB(100, 100, 100),
	Element = Color3.fromRGB(70, 70, 70),
	ElementBorder = Color3.fromRGB(25, 25, 25),
	InElementBorder = Color3.fromRGB(55, 55, 55),
	ElementTransparency = 0.82,
	DropdownFrame = Color3.fromRGB(120, 120, 120),
	DropdownHolder = Color3.fromRGB(35, 35, 35),
	DropdownBorder = Color3.fromRGB(25, 25, 25),
	Dialog = Color3.fromRGB(35, 35, 35),
	DialogHolder = Color3.fromRGB(25, 25, 25),
	DialogHolderLine = Color3.fromRGB(20, 20, 20),
	DialogButton = Color3.fromRGB(35, 35, 35),
	DialogButtonBorder = Color3.fromRGB(55, 55, 55),
	DialogBorder = Color3.fromRGB(50, 50, 50),
	DialogInput = Color3.fromRGB(45, 45, 45),
	DialogInputLine = Color3.fromRGB(120, 120, 120),
}
Themes["Amethyst"] = {
	Name = "Amethyst",
	Accent = Color3.fromRGB(97, 62, 167),
	AcrylicMain = Color3.fromRGB(20, 20, 20),
	AcrylicBorder = Color3.fromRGB(110, 90, 130),
	AcrylicGradient = ColorSequence.new(Color3.fromRGB(85, 57, 139), Color3.fromRGB(40, 25, 65)),
	AcrylicNoise = 0.92,
	TitleBarLine = Color3.fromRGB(95, 75, 110),
	Tab = Color3.fromRGB(160, 140, 180),
	Element = Color3.fromRGB(140, 120, 160),
	ElementBorder = Color3.fromRGB(60, 50, 70),
	InElementBorder = Color3.fromRGB(100, 90, 110),
	ElementTransparency = 0.87,
	ToggleSlider = Color3.fromRGB(140, 120, 160),
	ToggleToggled = Color3.fromRGB(0, 0, 0),
	SliderRail = Color3.fromRGB(140, 120, 160),
	DropdownFrame = Color3.fromRGB(170, 160, 200),
	DropdownHolder = Color3.fromRGB(60, 45, 80),
	DropdownBorder = Color3.fromRGB(50, 40, 65),
	DropdownOption = Color3.fromRGB(140, 120, 160),
	Keybind = Color3.fromRGB(140, 120, 160),
	Input = Color3.fromRGB(140, 120, 160),
	InputFocused = Color3.fromRGB(20, 10, 30),
	InputIndicator = Color3.fromRGB(170, 150, 190),
	Dialog = Color3.fromRGB(60, 45, 80),
	DialogHolder = Color3.fromRGB(45, 30, 65),
	DialogHolderLine = Color3.fromRGB(40, 25, 60),
	DialogButton = Color3.fromRGB(60, 45, 80),
	DialogButtonBorder = Color3.fromRGB(95, 80, 110),
	DialogBorder = Color3.fromRGB(85, 70, 100),
	DialogInput = Color3.fromRGB(70, 55, 85),
	DialogInputLine = Color3.fromRGB(175, 160, 190),
	Text = Color3.fromRGB(240, 240, 240),
	SubText = Color3.fromRGB(170, 170, 170),
	Hover = Color3.fromRGB(140, 120, 160),
	HoverChange = 0.04,
}
Themes["Aqua"] = {
	Name = "Aqua",
	Accent = Color3.fromRGB(60, 165, 165),
	AcrylicMain = Color3.fromRGB(20, 20, 20),
	AcrylicBorder = Color3.fromRGB(50, 100, 100),
	AcrylicGradient = ColorSequence.new(Color3.fromRGB(60, 140, 140), Color3.fromRGB(40, 80, 80)),
	AcrylicNoise = 0.92,
	TitleBarLine = Color3.fromRGB(60, 120, 120),
	Tab = Color3.fromRGB(140, 180, 180),
	Element = Color3.fromRGB(110, 160, 160),
	ElementBorder = Color3.fromRGB(40, 70, 70),
	InElementBorder = Color3.fromRGB(80, 110, 110),
	ElementTransparency = 0.84,
	ToggleSlider = Color3.fromRGB(110, 160, 160),
	ToggleToggled = Color3.fromRGB(0, 0, 0),
	SliderRail = Color3.fromRGB(110, 160, 160),
	DropdownFrame = Color3.fromRGB(160, 200, 200),
	DropdownHolder = Color3.fromRGB(40, 80, 80),
	DropdownBorder = Color3.fromRGB(40, 65, 65),
	DropdownOption = Color3.fromRGB(110, 160, 160),
	Keybind = Color3.fromRGB(110, 160, 160),
	Input = Color3.fromRGB(110, 160, 160),
	InputFocused = Color3.fromRGB(20, 10, 30),
	InputIndicator = Color3.fromRGB(130, 170, 170),
	Dialog = Color3.fromRGB(40, 80, 80),
	DialogHolder = Color3.fromRGB(30, 60, 60),
	DialogHolderLine = Color3.fromRGB(25, 50, 50),
	DialogButton = Color3.fromRGB(40, 80, 80),
	DialogButtonBorder = Color3.fromRGB(80, 110, 110),
	DialogBorder = Color3.fromRGB(50, 100, 100),
	DialogInput = Color3.fromRGB(45, 90, 90),
	DialogInputLine = Color3.fromRGB(130, 170, 170),
	Text = Color3.fromRGB(240, 240, 240),
	SubText = Color3.fromRGB(170, 170, 170),
	Hover = Color3.fromRGB(110, 160, 160),
	HoverChange = 0.04,
}
Themes["Rose"] = {
	Name = "Rose",
	Accent = Color3.fromRGB(180, 55, 90),
	AcrylicMain = Color3.fromRGB(40, 40, 40),
	AcrylicBorder = Color3.fromRGB(130, 90, 110),
	AcrylicGradient = ColorSequence.new(Color3.fromRGB(190, 60, 135), Color3.fromRGB(165, 50, 70)),
	AcrylicNoise = 0.92,
	TitleBarLine = Color3.fromRGB(140, 85, 105),
	Tab = Color3.fromRGB(180, 140, 160),
	Element = Color3.fromRGB(200, 120, 170),
	ElementBorder = Color3.fromRGB(110, 70, 85),
	InElementBorder = Color3.fromRGB(120, 90, 90),
	ElementTransparency = 0.86,
	ToggleSlider = Color3.fromRGB(200, 120, 170),
	ToggleToggled = Color3.fromRGB(0, 0, 0),
	SliderRail = Color3.fromRGB(200, 120, 170),
	DropdownFrame = Color3.fromRGB(200, 160, 180),
	DropdownHolder = Color3.fromRGB(120, 50, 75),
	DropdownBorder = Color3.fromRGB(90, 40, 55),
	DropdownOption = Color3.fromRGB(200, 120, 170),
	Keybind = Color3.fromRGB(200, 120, 170),
	Input = Color3.fromRGB(200, 120, 170),
	InputFocused = Color3.fromRGB(20, 10, 30),
	InputIndicator = Color3.fromRGB(170, 150, 190),
	Dialog = Color3.fromRGB(120, 50, 75),
	DialogHolder = Color3.fromRGB(95, 40, 60),
	DialogHolderLine = Color3.fromRGB(90, 35, 55),
	DialogButton = Color3.fromRGB(120, 50, 75),
	DialogButtonBorder = Color3.fromRGB(155, 90, 115),
	DialogBorder = Color3.fromRGB(100, 70, 90),
	DialogInput = Color3.fromRGB(135, 55, 80),
	DialogInputLine = Color3.fromRGB(190, 160, 180),
	Text = Color3.fromRGB(240, 240, 240),
	SubText = Color3.fromRGB(170, 170, 170),
	Hover = Color3.fromRGB(200, 120, 170),
	HoverChange = 0.04,
}

-- ====================
-- Icons (assets) - abbreviated but includes used ones
-- ====================
local Icons = {
	assets = {
		["lucide-chevron-right"] = "rbxassetid://10709791437",
		["lucide-chevron-up"] = "rbxassetid://10709791523",
		["lucide-chevron-down"] = "rbxassetid://10709790948",
		["lucide-maximize"] = "rbxassetid://9886659406",
		["lucide-minimize"] = "rbxassetid://9886659276",
		["lucide-close"] = "rbxassetid://9886659671",
	},
}

-- ====================
-- Creator (UI helper)
-- ====================
local Creator = {
	Registry = {},
	Signals = {},
	TransparencyMotors = {},
	DefaultProperties = {
		ScreenGui = { ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling },
		Frame = { BackgroundColor3 = Color3.new(1,1,1), BorderColor3 = Color3.new(0,0,0), BorderSizePixel = 0 },
		ScrollingFrame = { BackgroundColor3 = Color3.new(1,1,1), BorderColor3 = Color3.new(0,0,0), ScrollBarImageColor3 = Color3.new(0,0,0) },
		TextLabel = { BackgroundColor3 = Color3.new(1,1,1), BorderColor3 = Color3.new(0,0,0), Font = Enum.Font.SourceSans, Text = "", TextColor3 = Color3.new(0,0,0), BackgroundTransparency = 1, TextSize = 14 },
		TextButton = { BackgroundColor3 = Color3.new(1,1,1), BorderColor3 = Color3.new(0,0,0), AutoButtonColor = false, Font = Enum.Font.SourceSans, Text = "", TextColor3 = Color3.new(0,0,0), TextSize = 14 },
		TextBox = { BackgroundColor3 = Color3.new(1,1,1), BorderColor3 = Color3.new(0,0,0), ClearTextOnFocus = false, Font = Enum.Font.SourceSans, Text = "", TextColor3 = Color3.new(0,0,0), TextSize = 14 },
		ImageLabel = { BackgroundTransparency = 1, BackgroundColor3 = Color3.new(1,1,1), BorderColor3 = Color3.new(0,0,0), BorderSizePixel = 0 },
		ImageButton = { BackgroundColor3 = Color3.new(1,1,1), BorderColor3 = Color3.new(0,0,0), AutoButtonColor = false },
		CanvasGroup = { BackgroundColor3 = Color3.new(1,1,1), BorderColor3 = Color3.new(0,0,0), BorderSizePixel = 0 },
	},
}

local function ApplyCustomProps(Object, Props)
	if Props and Props.ThemeTag then
		Creator.AddThemeObject(Object, Props.ThemeTag)
	end
end

function Creator.AddSignal(SignalObj, Func)
	if SignalObj and SignalObj.Connect then
		table.insert(Creator.Signals, SignalObj:Connect(Func))
	elseif typeof(SignalObj) == "RBXScriptConnection" then
		table.insert(Creator.Signals, SignalObj)
	end
end

function Creator.Disconnect()
	for Idx = #Creator.Signals, 1, -1 do
		local Connection = table.remove(Creator.Signals, Idx)
		pcall(function() Connection:Disconnect() end)
	end
end

function Creator.GetThemeProperty(Property, Library)
	if Library and Library.Theme and Themes[Library.Theme] and Themes[Library.Theme][Property] ~= nil then
		return Themes[Library.Theme][Property]
	end
	return Themes["Dark"][Property]
end

function Creator.UpdateTheme(Library)
	for Instance, Object in next, Creator.Registry do
		for Property, ColorIdx in next, Object.Properties do
			Instance[Property] = Creator.GetThemeProperty(ColorIdx, Library)
		end
	end
	for _, Motor in next, Creator.TransparencyMotors do
		Motor:setGoal(Flipper.Instant.new(Creator.GetThemeProperty("ElementTransparency", Library)))
	end
end

function Creator.AddThemeObject(Object, Properties)
	Creator.Registry[Object] = { Object = Object, Properties = Properties }
	return Object
end

function Creator.OverrideTag(Object, Properties)
	if Creator.Registry[Object] then
		Creator.Registry[Object].Properties = Properties
		-- apply immediately if possible
		for Property, ColorIdx in next, Properties do
			pcall(function() Object[Property] = Creator.GetThemeProperty(ColorIdx, nil) end)
		end
	end
end

function Creator.New(Name, Properties, Children)
	local Object = Instance.new(Name)
	for K, V in next, Creator.DefaultProperties[Name] or {} do
		pcall(function() Object[K] = V end)
	end
	for K, V in next, Properties or {} do
		if K ~= "ThemeTag" then
			pcall(function() Object[K] = V end)
		end
	end
	for _, Child in next, Children or {} do
		Child.Parent = Object
	end
	ApplyCustomProps(Object, Properties)
	return Object
end

function Creator.SpringMotor(Initial, Instance, Prop, IgnoreDialogCheck, ResetOnThemeChange, Library)
	IgnoreDialogCheck = IgnoreDialogCheck or false
	ResetOnThemeChange = ResetOnThemeChange or false
	local Motor = Flipper.SingleMotor.new(Initial)
	Motor:onStep(function(value) 
		pcall(function() Instance[Prop] = value end)
	end)
	if ResetOnThemeChange then table.insert(Creator.TransparencyMotors, Motor) end
	local function SetValue(Value, Ignore)
		Ignore = Ignore or false
		if not IgnoreDialogCheck then
			if not Ignore then
				if Prop == "BackgroundTransparency" and Library and Library.DialogOpen then
					return
				end
			end
		end
		Motor:setGoal(Flipper.Spring.new(Value, { frequency = 8 }))
	end
	return Motor, SetValue
end

-- ====================
-- Acrylic (simplified)
-- ====================
local function map(value, inMin, inMax, outMin, outMax)
	return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end
local function viewportPointToWorld(location, distance)
	local cam = workspace.CurrentCamera
	if not cam then return Vector3.new() end
	local unitRay = cam:ScreenPointToRay(location.X, location.Y)
	return unitRay.Origin + unitRay.Direction * distance
end
local function getOffset()
	local cam = workspace.CurrentCamera
	if not cam then return 16 end
	local viewportSizeY = cam.ViewportSize.Y
	return map(viewportSizeY, 0, 2560, 8, 56)
end

local function createAcrylic()
	local Part = Creator.New("Part", {
		Name = "Body", Color = Color3.new(0,0,0), Material = Enum.Material.Glass,
		Size = Vector3.new(1,1,0), Anchored = true, CanCollide = false, Locked = true,
		CastShadow = false, Transparency = 0.98,
	}, {
		Creator.New("SpecialMesh", { MeshType = Enum.MeshType.Brick, Offset = Vector3.new(0,0,-0.000001) })
	})
	return Part
end

local function createAcrylicBlur(distance)
	distance = distance or 0.001
	local positions = { topLeft = Vector2.new(), topRight = Vector2.new(), bottomRight = Vector2.new() }
	local model = createAcrylic()
	local BlurFolder = Instance.new("Folder", workspace.CurrentCamera or workspace)
	model.Parent = BlurFolder

	local function updatePositions(size, position)
		positions.topLeft = position
		positions.topRight = position + Vector2.new(size.X, 0)
		positions.bottomRight = position + size
	end

	local function render()
		local cameraCFrame = workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new()
		local topLeft = positions.topLeft
		local topRight = positions.topRight
		local bottomRight = positions.bottomRight
		local topLeft3D = viewportPointToWorld(topLeft, distance)
		local topRight3D = viewportPointToWorld(topRight, distance)
		local bottomRight3D = viewportPointToWorld(bottomRight, distance)
		local width = (topRight3D - topLeft3D).Magnitude
		local height = (topRight3D - bottomRight3D).Magnitude
		model.CFrame = CFrame.fromMatrix((topLeft3D + bottomRight3D) / 2, cameraCFrame.XVector, cameraCFrame.YVector, cameraCFrame.ZVector)
		model.Mesh.Scale = Vector3.new(width, height, 0)
	end

	local cleanups = {}
	local function onChange(rbx)
		local offset = getOffset()
		local size = rbx.AbsoluteSize - Vector2.new(offset, offset)
		local position = rbx.AbsolutePosition + Vector2.new(offset/2, offset/2)
		updatePositions(size, position)
		task.spawn(render)
	end

	local function renderOnChange()
		local camera = workspace.CurrentCamera
		if not camera then return end
		table.insert(cleanups, camera:GetPropertyChangedSignal("CFrame"):Connect(render))
		table.insert(cleanups, camera:GetPropertyChangedSignal("ViewportSize"):Connect(render))
		table.insert(cleanups, camera:GetPropertyChangedSignal("FieldOfView"):Connect(render))
		task.spawn(render)
	end

	model.Destroying:Connect(function()
		for _, item in cleanups do pcall(function() item:Disconnect() end) end
	end)

	renderOnChange()
	return onChange, model
end

local Acrylic = {}
function Acrylic.init()
	local baseEffect = Instance.new("DepthOfFieldEffect")
	baseEffect.FarIntensity = 0
	baseEffect.InFocusRadius = 0.1
	baseEffect.NearIntensity = 1
	baseEffect.Parent = game:GetService("Lighting")
end
Acrylic.AcrylicPaint = function(Library)
	local AcrylicPaint = {}
	AcrylicPaint.Frame = Creator.New("Frame", {
		Size = UDim2.fromScale(1,1), BackgroundTransparency = 0.9, BackgroundColor3 = Color3.fromRGB(255,255,255), BorderSizePixel = 0,
	})
	local Blur, blurModel
	if Library and Library.UseAcrylic then
		local onChange, model = createAcrylicBlur()
		Blur = {}
		Blur.Frame = Creator.New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1,1) })
		Blur.Model = model
		Blur.AddParent = function(Parent)
			Parent:GetPropertyChangedSignal("Visible"):Connect(function()
				model.Transparency = Parent.Visible and 0.98 or 1
			end)
		end
		Blur.SetVisibility = function(Value) model.Transparency = Value and 0.98 or 1 end
		AcrylicPaint.Model = model
		AcrylicPaint.AddParent = Blur.AddParent
		AcrylicPaint.SetVisibility = Blur.SetVisibility
	end
	return AcrylicPaint
end
Acrylic.CreateAcrylic = createAcrylic
Acrylic.AcrylicBlur = createAcrylicBlur

-- ====================
-- Components
-- ====================
local Components = {}

-- Components.Assets
Components.Assets = function()
	return {
		Close = "rbxassetid://9886659671",
		Min = "rbxassetid://9886659276",
		Max = "rbxassetid://9886659406",
		Restore = "rbxassetid://9886659001",
	}
end

-- Component: Element (base for elements)
Components.Element = function(Title, Desc, Parent, Hover, Library)
	local Element = {}
	Element.TitleLabel = Creator.New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		Text = Title or "", TextColor3 = Color3.fromRGB(240,240,240), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1,0,0,14), BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" },
	})
	Element.DescLabel = Creator.New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Text = Desc or "", TextColor3 = Color3.fromRGB(200,200,200), TextSize = 12, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		Size = UDim2.new(1,0,0,14), ThemeTag = { TextColor3 = "SubText" },
	})
	Element.LabelHolder = Creator.New("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Position = UDim2.fromOffset(10,0), Size = UDim2.new(1,-28,0,0)
	}, {
		Creator.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }),
		Creator.New("UIPadding", { PaddingBottom = UDim.new(0,13), PaddingTop = UDim.new(0,13) }),
		Element.TitleLabel, Element.DescLabel,
	})
	Element.Border = Creator.New("UIStroke", { Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.fromRGB(0,0,0), ThemeTag = { Color = "ElementBorder" }})
	Element.Frame = Creator.New("TextButton", {
		Size = UDim2.new(1,0,0,0), BackgroundTransparency = 0.89, BackgroundColor3 = Color3.fromRGB(130,130,130),
		Parent = Parent, AutomaticSize = Enum.AutomaticSize.Y, Text = "", LayoutOrder = 7,
		ThemeTag = { BackgroundColor3 = "Element", BackgroundTransparency = "ElementTransparency" },
	}, { Creator.New("UICorner", { CornerRadius = UDim.new(0,4) }), Element.Border, Element.LabelHolder })
	function Element:SetTitle(Set) Element.TitleLabel.Text = Set end
	function Element:SetDesc(Set)
		if Set == nil then Set = "" end
		if Set == "" then Element.DescLabel.Visible = false else Element.DescLabel.Visible = true end
		Element.DescLabel.Text = Set
	end
	function Element:Destroy() Element.Frame:Destroy() end
	Element:SetTitle(Title)
	Element:SetDesc(Desc)
	if Hover and Library then
		local Motor, SetTransparency = Creator.SpringMotor(Creator.GetThemeProperty("ElementTransparency", Library), Element.Frame, "BackgroundTransparency", false, true, Library)
		Element.Frame.MouseEnter:Connect(function() SetTransparency(Creator.GetThemeProperty("ElementTransparency", Library) - Creator.GetThemeProperty("HoverChange", Library)) end)
		Element.Frame.MouseLeave:Connect(function() SetTransparency(Creator.GetThemeProperty("ElementTransparency", Library)) end)
		Element.Frame.MouseButton1Down:Connect(function() SetTransparency(Creator.GetThemeProperty("ElementTransparency", Library) + Creator.GetThemeProperty("HoverChange", Library)) end)
		Element.Frame.MouseButton1Up:Connect(function() SetTransparency(Creator.GetThemeProperty("ElementTransparency", Library) - Creator.GetThemeProperty("HoverChange", Library)) end)
	end
	return Element
end

-- Components.Button (visual button used internally by Elements.Button)
Components.Button = function(Theme, Parent, DialogCheck, Library)
	DialogCheck = DialogCheck or false
	local Button = {}
	Button.Title = Creator.New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextColor3 = Color3.fromRGB(200,200,200),
		TextSize = 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), ThemeTag = { TextColor3 = "Text" },
	})
	Button.HoverFrame = Creator.New("Frame", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, ThemeTag = { BackgroundColor3 = "Hover" }}, { Creator.New("UICorner", { CornerRadius = UDim.new(0,4) }) })
	Button.Frame = Creator.New("TextButton", { Size = UDim2.new(0,0,0,32), Parent = Parent, ThemeTag = { BackgroundColor3 = "DialogButton" } }, { Creator.New("UICorner", { CornerRadius = UDim.new(0,4) }), Creator.New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0.65, ThemeTag = { Color = "DialogButtonBorder" } }), Button.HoverFrame, Button.Title })
	local Motor, SetTransparency = Creator.SpringMotor(1, Button.HoverFrame, "BackgroundTransparency", DialogCheck, false, Library)
	Button.Frame.MouseEnter:Connect(function() SetTransparency(0.97) end)
	Button.Frame.MouseLeave:Connect(function() SetTransparency(1) end)
	Button.Frame.MouseButton1Down:Connect(function() SetTransparency(1) end)
	Button.Frame.MouseButton1Up:Connect(function() SetTransparency(0.97) end)
	return Button
end

-- Components.Textbox
Components.Textbox = function(Parent, AcrylicFlag, Library)
	AcrylicFlag = AcrylicFlag or false
	local TextService = game:GetService("TextService")
	local Textbox = {}
	Textbox.Input = Creator.New("TextBox", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		TextColor3 = Color3.fromRGB(200,200,200), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		BackgroundColor3 = Color3.fromRGB(255,255,255), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		Size = UDim2.fromScale(1,1), Position = UDim2.fromOffset(10,0), ThemeTag = { TextColor3 = "Text", PlaceholderColor3 = "SubText" },
	})
	Textbox.Container = Creator.New("Frame", { BackgroundTransparency = 1, ClipsDescendants = true, Position = UDim2.new(0,6,0,0), Size = UDim2.new(1,-12,1,0) }, { Textbox.Input })
	Textbox.Indicator = Creator.New("Frame", { Size = UDim2.new(1,-4,0,1), Position = UDim2.new(0,2,1,0), AnchorPoint = Vector2.new(0,1), BackgroundTransparency = AcrylicFlag and 0.5 or 0, ThemeTag = { BackgroundColor3 = AcrylicFlag and "InputIndicator" or "DialogInputLine" } })
	Textbox.Frame = Creator.New("Frame", { Size = UDim2.new(0,0,0,30), BackgroundTransparency = AcrylicFlag and 0.9 or 0, Parent = Parent, ThemeTag = { BackgroundColor3 = AcrylicFlag and "Input" or "DialogInput" } }, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0,4) }),
		Creator.New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = AcrylicFlag and 0.5 or 0.65, ThemeTag = { Color = AcrylicFlag and "InElementBorder" or "DialogButtonBorder" } }),
		Textbox.Indicator,
		Textbox.Container,
	})
	local function Update()
		local PADDING = 2
		local Reveal = Textbox.Container.AbsoluteSize.X
		if not Textbox.Input:IsFocused() or Textbox.Input.TextBounds.X <= Reveal - 2 * PADDING then
			Textbox.Input.Position = UDim2.new(0, PADDING, 0, 0)
		else
			local Cursor = Textbox.Input.CursorPosition
			if Cursor ~= -1 then
				local subtext = string.sub(Textbox.Input.Text, 1, Cursor - 1)
				local width = TextService:GetTextSize(subtext, Textbox.Input.TextSize, Textbox.Input.Font, Vector2.new(math.huge, math.huge)).X
				local CurrentCursorPos = Textbox.Input.Position.X.Offset + width
				if CurrentCursorPos < PADDING then
					Textbox.Input.Position = UDim2.fromOffset(PADDING - width, 0)
				elseif CurrentCursorPos > Reveal - PADDING - 1 then
					Textbox.Input.Position = UDim2.fromOffset(Reveal - width - PADDING - 1, 0)
				end
			end
		end
	end
	task.spawn(Update)
	Creator.AddSignal(Textbox.Input:GetPropertyChangedSignal("Text"), Update)
	Creator.AddSignal(Textbox.Input:GetPropertyChangedSignal("CursorPosition"), Update)
	Textbox.Input.Focused:Connect(function() Update(); Textbox.Indicator.Size = UDim2.new(1,-2,0,2); Textbox.Indicator.Position = UDim2.new(0,1,1,0); Textbox.Indicator.BackgroundTransparency = 0; Creator.OverrideTag(Textbox.Frame, { BackgroundColor3 = AcrylicFlag and "InputFocused" or "DialogHolder" }); Creator.OverrideTag(Textbox.Indicator, { BackgroundColor3 = "Accent" }) end)
	Textbox.Input.FocusLost:Connect(function() Update(); Textbox.Indicator.Size = UDim2.new(1,-4,0,1); Textbox.Indicator.Position = UDim2.new(0,2,1,0); Textbox.Indicator.BackgroundTransparency = 0.5; Creator.OverrideTag(Textbox.Frame, { BackgroundColor3 = AcrylicFlag and "Input" or "DialogInput" }); Creator.OverrideTag(Textbox.Indicator, { BackgroundColor3 = AcrylicFlag and "InputIndicator" or "DialogInputLine" }) end)
	return Textbox
end

-- Components.Section
Components.Section = function(Title, Parent)
	local Section = {}
	Section.Layout = Creator.New("UIListLayout", { Padding = UDim.new(0,5) })
	Section.Container = Creator.New("Frame", { Size = UDim2.new(1,0,0,26), Position = UDim2.fromOffset(0,24), BackgroundTransparency = 1 }, { Section.Layout })
	Section.Root = Creator.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,26), LayoutOrder = 7, Parent = Parent }, {
		Creator.New("TextLabel", {
			RichText = true, Text = Title, TextTransparency = 0, FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
			TextSize = 18, TextXAlignment = "Left", TextYAlignment = "Center", Size = UDim2.new(1,-16,0,18), Position = UDim2.fromOffset(0,2), ThemeTag = { TextColor3 = "Text" },
		}), Section.Container })
	Section.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Section.Container.Size = UDim2.new(1,0,0,Section.Layout.AbsoluteContentSize.Y)
		Section.Root.Size = UDim2.new(1,0,0,Section.Layout.AbsoluteContentSize.Y + 25)
	end)
	return Section
end

-- Components.Dialog (simplificado)
Components.Dialog = function(Library)
	local Dialog = {}
	function Dialog:Init(Window) Dialog.Window = Window; return Dialog end
	function Dialog:Create()
		local NewDialog = { Buttons = 0 }
		NewDialog.TintFrame = Creator.New("TextButton", { Text = "", Size = UDim2.fromScale(1,1), BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 1, Parent = Dialog.Window.Root }, { Creator.New("UICorner", { CornerRadius = UDim.new(0,8) }) })
		local TintMotor, TintTransparency = Creator.SpringMotor(1, NewDialog.TintFrame, "BackgroundTransparency", true, false, Library)
		NewDialog.ButtonHolder = Creator.New("Frame", { Size = UDim2.new(1,-40,1,-40), AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5), BackgroundTransparency = 1 }, { Creator.New("UIListLayout", { Padding = UDim.new(0,10), FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
		NewDialog.ButtonHolderFrame = Creator.New("Frame", { Size = UDim2.new(1,0,0,70), Position = UDim2.new(0,0,1,-70), ThemeTag = { BackgroundColor3 = "DialogHolder" } }, { Creator.New("Frame", { Size = UDim2.new(1,0,0,1), ThemeTag = { BackgroundColor3 = "DialogHolderLine" } }), NewDialog.ButtonHolder })
		NewDialog.Title = Creator.New("TextLabel", { Text = "Dialog", TextColor3 = Color3.fromRGB(240,240,240), TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1,0,0,22), Position = UDim2.fromOffset(20,25), BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" } })
		NewDialog.Scale = Creator.New("UIScale", { Scale = 1 })
		local ScaleMotor, Scale = Creator.SpringMotor(1.1, NewDialog.Scale, "Scale", false, false, Library)
		NewDialog.Root = Creator.New("CanvasGroup", { Size = UDim2.fromOffset(300,165), AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5), GroupTransparency = 1, Parent = NewDialog.TintFrame, ThemeTag = { BackgroundColor3 = "Dialog" } }, { Creator.New("UICorner", { CornerRadius = UDim.new(0,8) }), Creator.New("UIStroke", { Transparency = 0.5, ThemeTag = { Color = "DialogBorder" } }), NewDialog.Scale, NewDialog.Title, NewDialog.ButtonHolderFrame })
		local RootMotor, RootTransparency = Creator.SpringMotor(1, NewDialog.Root, "GroupTransparency", false, false, Library)
		function NewDialog:Open() Library.DialogOpen = true; NewDialog.Scale.Scale = 1.1; TintTransparency(0.75); RootTransparency(0); Scale(1) end
		function NewDialog:Close() Library.DialogOpen = false; TintTransparency(1); RootTransparency(1); Scale(1.1); NewDialog.Root.UIStroke:Destroy(); task.wait(0.15); NewDialog.TintFrame:Destroy() end
		function NewDialog:Button(Title, Callback)
			NewDialog.Buttons = NewDialog.Buttons + 1; Title = Title or "Button"; Callback = Callback or function() end
			local Button = Components.Button("", NewDialog.ButtonHolder, true, Library)
			Button.Title.Text = Title
			for _, Btn in next, NewDialog.ButtonHolder:GetChildren() do
				if Btn:IsA("TextButton") then
					Btn.Size = UDim2.new(1 / NewDialog.Buttons, -(((NewDialog.Buttons - 1) * 10) / NewDialog.Buttons), 0, 32)
				end
			end
			Button.Frame.MouseButton1Click:Connect(function() pcall(function() Callback() end); pcall(function() NewDialog:Close() end) end)
			return Button
		end
		return NewDialog
	end
	return Dialog
end

-- Components.TitleBar
Components.TitleBar = function(Config, Library)
	local TitleBar = {}
	local AssetsTable = Components.Assets()
	local function BarButton(Icon, Pos, Parent, Callback)
		local Button = { Callback = Callback or function() end }
		Button.Frame = Creator.New("TextButton", { Size = UDim2.new(0,34,1,-8), AnchorPoint = Vector2.new(1,0), BackgroundTransparency = 1, Parent = Parent, Position = Pos, Text = "", ThemeTag = { BackgroundColor3 = "Text" } }, {
			Creator.New("UICorner", { CornerRadius = UDim.new(0,7) }),
			Creator.New("ImageLabel", { Image = Icon, Size = UDim2.fromOffset(16,16), Position = UDim2.fromScale(0.5,0.5), AnchorPoint = Vector2.new(0.5,0.5), BackgroundTransparency = 1, Name = "Icon", ThemeTag = { ImageColor3 = "Text" } }),
		})
		local Motor, SetTransparency = Creator.SpringMotor(1, Button.Frame, "BackgroundTransparency", false, false, Library)
		Button.Frame.MouseEnter:Connect(function() SetTransparency(0.94) end)
		Button.Frame.MouseLeave:Connect(function() SetTransparency(1, true) end)
		Button.Frame.MouseButton1Down:Connect(function() SetTransparency(0.96) end)
		Button.Frame.MouseButton1Up:Connect(function() SetTransparency(0.94) end)
		Button.Frame.MouseButton1Click:Connect(function() pcall(function() Button.Callback() end) end)
		Button.SetCallback = function(Func) Button.Callback = Func end
		return Button
	end

	TitleBar.Frame = Creator.New("Frame", { Size = UDim2.new(1,0,0,42), BackgroundTransparency = 1, Parent = Config.Parent }, {
		Creator.New("Frame", { Size = UDim2.new(1,-16,1,0), Position = UDim2.new(0,16,0,0), BackgroundTransparency = 1 }, {
			Creator.New("UIListLayout", { Padding = UDim.new(0,5), FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder }),
			Creator.New("TextLabel", { RichText = true, Text = Config.Title or "", FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextSize = 12, TextXAlignment = "Left", TextYAlignment = "Center", Size = UDim2.fromScale(0,1), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" } }),
			Creator.New("TextLabel", { RichText = true, Text = Config.SubTitle or "", TextTransparency = 0.4, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextSize = 12, TextXAlignment = "Left", TextYAlignment = "Center", Size = UDim2.fromScale(0,1), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" } }),
		}),
		Creator.New("Frame", { BackgroundTransparency = 0.5, Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,1,0), ThemeTag = { BackgroundColor3 = "TitleBarLine" } }),
	})
	TitleBar.CloseButton = BarButton(AssetsTable.Close, UDim2.new(1, -4, 0, 4), TitleBar.Frame, function()
		Config.Window:Dialog({ Title = "Close", Content = "Are you sure you want to unload the interface?", Buttons = { { Title = "Yes", Callback = function() Library:Destroy() end }, { Title = "No" } } })
	end)
	TitleBar.MaxButton = BarButton(AssetsTable.Max, UDim2.new(1, -40, 0, 4), TitleBar.Frame, function()
		Config.Window.Maximize(not Config.Window.Maximized)
	end)
	TitleBar.MinButton = BarButton(AssetsTable.Min, UDim2.new(1, -80, 0, 4), TitleBar.Frame, function()
		Library.Window:Minimize()
	end)
	return TitleBar
end

-- Components.Notification
Components.Notification = function(Library)
	local Notification = {}
	function Notification:Init(GUI)
		Notification.Holder = Creator.New("Frame", { Position = UDim2.new(1,-30,1,-30), Size = UDim2.new(0,310,1,-30), AnchorPoint = Vector2.new(1,1), BackgroundTransparency = 1, Parent = GUI }, {
			Creator.New("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0,20) })
		})
	end
	function Notification:New(Config)
		Config.Title = Config.Title or "Title"
		Config.Content = Config.Content or "Content"
		Config.SubContent = Config.SubContent or ""
		Config.Duration = Config.Duration or nil
		Config.Buttons = Config.Buttons or {}
		local NewNotification = { Closed = false }
		NewNotification.AcrylicPaint = Acrylic.AcrylicPaint({}) -- will be replaced when window created
		NewNotification.Title = Creator.New("TextLabel", { Position = UDim2.fromOffset(14,17), Text = Config.Title, RichText = true, TextColor3 = Color3.fromRGB(255,255,255), FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextSize = 13, TextXAlignment = "Left", TextYAlignment = "Center", Size = UDim2.new(1,-12,0,12), TextWrapped = true, BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" } })
		NewNotification.ContentLabel = Creator.New("TextLabel", { FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), Text = Config.Content, TextColor3 = Color3.fromRGB(240,240,240), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1,0,0,14), BackgroundTransparency = 1, TextWrapped = true, ThemeTag = { TextColor3 = "Text" } })
		NewNotification.SubContentLabel = Creator.New("TextLabel", { FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), Text = Config.SubContent, TextColor3 = Color3.fromRGB(240,240,240), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1,0,0,14), BackgroundTransparency = 1, TextWrapped = true, ThemeTag = { TextColor3 = "SubText" } })
		NewNotification.LabelHolder = Creator.New("Frame", { AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Position = UDim2.fromOffset(14,40), Size = UDim2.new(1,-28,0,0) }, {
			Creator.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0,3) }),
			NewNotification.ContentLabel, NewNotification.SubContentLabel
		})
		NewNotification.CloseButton = Creator.New("TextButton", { Text = "", Position = UDim2.new(1,-14,0,13), Size = UDim2.fromOffset(20,20), AnchorPoint = Vector2.new(1,0), BackgroundTransparency = 1 }, {
			Creator.New("ImageLabel", { Image = Components.Assets().Close, Size = UDim2.fromOffset(16,16), Position = UDim2.fromScale(0.5,0.5), AnchorPoint = Vector2.new(0.5,0.5), BackgroundTransparency = 1, ThemeTag = { ImageColor3 = "Text" }})
		})
		NewNotification.Root = Creator.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), Position = UDim2.fromScale(1,0) }, { NewNotification.AcrylicPaint.Frame, NewNotification.Title, NewNotification.CloseButton, NewNotification.LabelHolder })
		if Config.Content == "" then NewNotification.ContentLabel.Visible = false end
		if Config.SubContent == "" then NewNotification.SubContentLabel.Visible = false end
		NewNotification.Holder = Creator.New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1,0,0,200), Parent = Notification.Holder }, { NewNotification.Root })
		local RootMotor = Flipper.GroupMotor.new({ Scale = 1, Offset = 60 })
		RootMotor:onStep(function(Values) NewNotification.Root.Position = UDim2.new(Values.Scale, Values.Offset, 0, 0) end)
		NewNotification.CloseButton.MouseButton1Click:Connect(function() NewNotification:Close() end)
		function NewNotification:Open()
			local ContentSize = NewNotification.LabelHolder.AbsoluteSize.Y
			NewNotification.Holder.Size = UDim2.new(1,0,0,58 + ContentSize)
			RootMotor:setGoal({ Scale = Flipper.Spring.new(0, { frequency = 5 }), Offset = Flipper.Spring.new(0, { frequency = 5 }) })
		end
		function NewNotification:Close()
			if not NewNotification.Closed then
				NewNotification.Closed = true
				task.spawn(function()
					RootMotor:setGoal({ Scale = Flipper.Spring.new(1, { frequency = 5 }), Offset = Flipper.Spring.new(60, { frequency = 5 }) })
					task.wait(0.4)
					if Library.UseAcrylic then
						pcall(function() NewNotification.AcrylicPaint.Model:Destroy() end)
					end
					NewNotification.Holder:Destroy()
				end)
			end
		end
		NewNotification:Open()
		if Config.Duration then task.delay(Config.Duration, function() NewNotification:Close() end) end
		return NewNotification
	end
	return Notification
end

-- Components.Tab (core tab logic)
Components.Tab = function(Library)
	local TabModule = { Window = nil, Tabs = {}, Containers = {}, SelectedTab = 0, TabCount = 0 }
	local Spring = Flipper.Spring.new
	local Instant = Flipper.Instant.new
	function TabModule:Init(Window) TabModule.Window = Window; return TabModule end
	function TabModule:GetCurrentTabPos()
		local TabHolderPos = TabModule.Window.TabHolder.AbsolutePosition.Y
		local TabPos = TabModule.Tabs[TabModule.SelectedTab].Frame.AbsolutePosition.Y
		return TabPos - TabHolderPos
	end
	function TabModule:New(Title, Icon, Parent)
		TabModule.TabCount = TabModule.TabCount + 1
		local TabIndex = TabModule.TabCount
		local Tab = { Selected = false, Name = Title, Type = "Tab" }
		if Library.GetIcon and Library:GetIcon(Icon) then Icon = Library:GetIcon(Icon) end
		if Icon == "" or nil then Icon = nil end
		Tab.Frame = Creator.New("TextButton", { Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1, Parent = Parent, ThemeTag = { BackgroundColor3 = "Tab" } }, {
			Creator.New("UICorner", { CornerRadius = UDim.new(0,6) }),
			Creator.New("TextLabel", { AnchorPoint = Vector2.new(0,0.5), Position = Icon and UDim2.new(0,30,0.5,0) or UDim2.new(0,12,0.5,0), Text = Title, RichText = true, TextColor3 = Color3.fromRGB(255,255,255), TextTransparency = 0, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal), TextSize = 12, TextXAlignment = "Left", TextYAlignment = "Center", Size = UDim2.new(1,-12,1,0), BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" } }),
			Creator.New("ImageLabel", { AnchorPoint = Vector2.new(0,0.5), Size = UDim2.fromOffset(16,16), Position = UDim2.new(0,8,0.5,0), BackgroundTransparency = 1, Image = Icon and Icon or nil, ThemeTag = { ImageColor3 = "Text" } }),
		})
		local ContainerLayout = Creator.New("UIListLayout", { Padding = UDim.new(0,5), SortOrder = Enum.SortOrder.LayoutOrder })
		Tab.ContainerFrame = Creator.New("ScrollingFrame", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Parent = Library.Window.ContainerHolder, Visible = false, BottomImage = "rbxassetid://6889812791", MidImage = "rbxassetid://6889812721", TopImage = "rbxassetid://6276641225", ScrollBarImageColor3 = Color3.fromRGB(255,255,255), ScrollBarImageTransparency = 0.95, ScrollBarThickness = 3, BorderSizePixel = 0, CanvasSize = UDim2.fromScale(0,0), ScrollingDirection = Enum.ScrollingDirection.Y }, { ContainerLayout, Creator.New("UIPadding", { PaddingRight = UDim.new(0,10), PaddingLeft = UDim.new(0,1), PaddingTop = UDim.new(0,1), PaddingBottom = UDim.new(0,1) }) })
		Creator.AddSignal(ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function() Tab.ContainerFrame.CanvasSize = UDim2.new(0,0,0,ContainerLayout.AbsoluteContentSize.Y + 2) end)
		Tab.Motor, Tab.SetTransparency = Creator.SpringMotor(1, Tab.Frame, "BackgroundTransparency", false, false, Library)
		Tab.Frame.MouseEnter:Connect(function() Tab.SetTransparency(Tab.Selected and 0.85 or 0.89) end)
		Tab.Frame.MouseLeave:Connect(function() Tab.SetTransparency(Tab.Selected and 0.89 or 1) end)
		Tab.Frame.MouseButton1Down:Connect(function() Tab.SetTransparency(0.92) end)
		Tab.Frame.MouseButton1Up:Connect(function() Tab.SetTransparency(Tab.Selected and 0.85 or 0.89) end)
		Tab.Frame.MouseButton1Click:Connect(function() TabModule:SelectTab(TabIndex) end)
		TabModule.Containers[TabIndex] = Tab.ContainerFrame
		TabModule.Tabs[TabIndex] = Tab
		Tab.Container = Tab.ContainerFrame
		Tab.ScrollFrame = Tab.Container
		function Tab:AddSection(SectionTitle)
			local Section = { Type = "Section" }
			local SectionFrame = Components.Section(SectionTitle, Tab.Container)
			Section.Container = SectionFrame.Container
			Section.ScrollFrame = Tab.Container
			setmetatable(Section, Library.Elements)
			return Section
		end
		setmetatable(Tab, Library.Elements)
		return Tab
	end
	function TabModule:SelectTab(Tab)
		TabModule.SelectedTab = Tab
		for _, TabObject in next, TabModule.Tabs do
			TabObject.SetTransparency(1)
			TabObject.Selected = false
		end
		TabModule.Tabs[Tab].SetTransparency(0.89)
		TabModule.Tabs[Tab].Selected = true
		Library.Window.TabDisplay.Text = TabModule.Tabs[Tab].Name
		Library.Window.SelectorPosMotor:setGoal(Flipper.Spring.new(TabModule:GetCurrentTabPos(), { frequency = 6 }))
		task.spawn(function()
			Library.Window.ContainerHolder.Parent = Library.Window.ContainerAnim
			Library.Window.ContainerPosMotor:setGoal(Flipper.Spring.new(15, { frequency = 10 }))
			Library.Window.ContainerBackMotor:setGoal(Flipper.Spring.new(1, { frequency = 10 }))
			task.wait(0.12)
			for _, Container in next, TabModule.Containers do Container.Visible = false end
			TabModule.Containers[Tab].Visible = true
			Library.Window.ContainerPosMotor:setGoal(Flipper.Spring.new(0, { frequency = 5 }))
			Library.Window.ContainerBackMotor:setGoal(Flipper.Spring.new(0, { frequency = 8 }))
			task.wait(0.12)
			Library.Window.ContainerHolder.Parent = Library.Window.ContainerCanvas
		end)
	end
	return TabModule
end

-- Components.Window (core window)
Components.Window = function(Config, Library)
	local Camera = workspace.CurrentCamera
	local Window = {
		Minimized = false, Maximized = false, Size = Config.Size, CurrentPos = 0, TabWidth = 0,
		Position = UDim2.fromOffset((Camera and Camera.ViewportSize.X or 800) / 2 - Config.Size.X.Offset / 2, (Camera and Camera.ViewportSize.Y or 600) / 2 - Config.Size.Y.Offset / 2)
	}
	local Dragging, DragInput, MousePos, StartPos = false
	local Resizing, ResizePos = false
	local MinimizeNotif = false
	Window.AcrylicPaint = Acrylic.AcrylicPaint({})
	Window.TabWidth = Config.TabWidth or 180
	local Selector = Creator.New("Frame", { Size = UDim2.fromOffset(4,0), BackgroundColor3 = Color3.fromRGB(76,194,255), Position = UDim2.fromOffset(0,17), AnchorPoint = Vector2.new(0,0.5), ThemeTag = { BackgroundColor3 = "Accent" } }, { Creator.New("UICorner", { CornerRadius = UDim.new(0,2) }) })
	local ResizeStartFrame = Creator.New("Frame", { Size = UDim2.fromOffset(20,20), BackgroundTransparency = 1, Position = UDim2.new(1, -20, 1, -20) })
	Window.TabHolder = Creator.New("ScrollingFrame", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, ScrollBarImageTransparency = 1, ScrollBarThickness = 0, BorderSizePixel = 0, CanvasSize = UDim2.fromScale(0,0), ScrollingDirection = Enum.ScrollingDirection.Y }, { Creator.New("UIListLayout", { Padding = UDim.new(0,4) }) })
	local TabFrame = Creator.New("Frame", { Size = UDim2.new(0, Window.TabWidth, 1, -66), Position = UDim2.new(0,12,0,54), BackgroundTransparency = 1, ClipsDescendants = true }, { Window.TabHolder, Selector })
	Window.TabDisplay = Creator.New("TextLabel", { RichText = true, Text = "Tab", FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal), TextSize = 28, TextXAlignment = "Left", TextYAlignment = "Center", Size = UDim2.new(1, -16, 0, 28), Position = UDim2.fromOffset(Window.TabWidth + 26, 56), BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" } })
	Window.ContainerHolder = Creator.New("Frame", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1 })
	Window.ContainerAnim = Creator.New("CanvasGroup", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1 })
	Window.ContainerCanvas = Creator.New("Frame", { Size = UDim2.new(1, -Window.TabWidth - 32, 1, -102), Position = UDim2.fromOffset(Window.TabWidth + 26, 90), BackgroundTransparency = 1 }, { Window.ContainerAnim, Window.ContainerHolder })
	Window.Root = Creator.New("Frame", { BackgroundTransparency = 1, Size = Window.Size, Position = Window.Position, Parent = Config.Parent }, { Window.AcrylicPaint.Frame, Window.TabDisplay, Window.ContainerCanvas, TabFrame, ResizeStartFrame })
	Window.TitleBar = Components.TitleBar({ Title = Config.Title, SubTitle = Config.SubTitle, Parent = Window.Root, Window = Window }, Library)
	if Library.UseAcrylic and Window.AcrylicPaint.AddParent then Window.AcrylicPaint.AddParent(Window.Root) end
	local SizeMotor = Flipper.GroupMotor.new({ X = Window.Size.X.Offset, Y = Window.Size.Y.Offset })
	local PosMotor = Flipper.GroupMotor.new({ X = Window.Position.X.Offset, Y = Window.Position.Y.Offset })
	Window.SelectorPosMotor = Flipper.SingleMotor.new(17)
	Window.SelectorSizeMotor = Flipper.SingleMotor.new(0)
	Window.ContainerBackMotor = Flipper.SingleMotor.new(0)
	Window.ContainerPosMotor = Flipper.SingleMotor.new(94)
	SizeMotor:onStep(function(values) Window.Root.Size = UDim2.new(0, values.X, 0, values.Y) end)
	PosMotor:onStep(function(values) Window.Root.Position = UDim2.new(0, values.X, 0, values.Y) end)
	Window.SelectorPosMotor:onStep(function(Value)
		Selector.Position = UDim2.new(0,0,0,Value + 17)
	end)
	Window.SelectorSizeMotor:onStep(function(Value) Selector.Size = UDim2.new(0,4,0,Value) end)
	Window.ContainerBackMotor:onStep(function(Value) Window.ContainerAnim.GroupTransparency = Value end)
	Window.ContainerPosMotor:onStep(function(Value) Window.ContainerAnim.Position = UDim2.fromOffset(0, Value) end)

	local OldSizeX, OldSizeY
	function Window.Maximize(Value, NoPos, InstantFlag)
		Window.Maximized = Value
		Window.TitleBar.MaxButton.Frame.Icon.Image = Value and Components.Assets().Restore or Components.Assets().Max
		if Value then OldSizeX = Window.Size.X.Offset; OldSizeY = Window.Size.Y.Offset end
		local SizeX = Value and (Camera and Camera.ViewportSize.X or OldSizeX) or OldSizeX
		local SizeY = Value and (Camera and Camera.ViewportSize.Y or OldSizeY) or OldSizeY
		SizeMotor:setGoal({ X = Flipper[InstantFlag and "Instant" or "Spring"].new(SizeX, { frequency = 6 }), Y = Flipper[InstantFlag and "Instant" or "Spring"].new(SizeY, { frequency = 6 }) })
		Window.Size = UDim2.fromOffset(SizeX, SizeY)
		if not NoPos then
			PosMotor:setGoal({ X = Flipper.Spring.new(Value and 0 or Window.Position.X.Offset, { frequency = 6 }), Y = Flipper.Spring.new(Value and 0 or Window.Position.Y.Offset, { frequency = 6 }) })
		end
	end

	-- Dragging & resizing signals
	Window.TitleBar.Frame.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			MousePos = Input.Position
			StartPos = Window.Root.Position
			if Window.Maximized then
				StartPos = UDim2.fromOffset(Input.Position.X - (Input.Position.X * ((OldSizeX - 100) / Window.Root.AbsoluteSize.X)), Input.Position.Y - (Input.Position.Y * (OldSizeY / Window.Root.AbsoluteSize.Y)))
			end
			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then Dragging = false end
			end)
		end
	end)
	Window.TitleBar.Frame.InputChanged:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then DragInput = Input end end)
	ResizeStartFrame.InputBegan:Connect(function(Input) if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then Resizing = true; ResizePos = Input.Position end end)
	game:GetService("UserInputService").InputChanged:Connect(function(Input)
		if Input == DragInput and Dragging then
			local Delta = Input.Position - MousePos
			Window.Position = UDim2.fromOffset(StartPos.X.Offset + Delta.X, StartPos.Y.Offset + Delta.Y)
			PosMotor:setGoal({ X = Flipper.Instant.new(Window.Position.X.Offset), Y = Flipper.Instant.new(Window.Position.Y.Offset) })
			if Window.Maximized then Window.Maximize(false, true, true) end
		end
		if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) and Resizing then
			local Delta = Input.Position - ResizePos
			local StartSize = Window.Size
			local TargetSize = Vector3.new(StartSize.X.Offset, StartSize.Y.Offset, 0) + Vector3.new(1,1,0) * Delta
			local TargetSizeClamped = Vector2.new(math.clamp(TargetSize.X, 470, 2048), math.clamp(TargetSize.Y, 380, 2048))
			SizeMotor:setGoal({ X = Flipper.Instant.new(TargetSizeClamped.X), Y = Flipper.Instant.new(TargetSizeClamped.Y) })
		end
	end)
	game:GetService("UserInputService").InputEnded:Connect(function(Input)
		if Resizing == true or Input.UserInputType == Enum.UserInputType.Touch then
			Resizing = false
			Window.Size = UDim2.fromOffset(SizeMotor:getValue().X, SizeMotor:getValue().Y)
		end
	end)
	Window.TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Window.TabHolder.CanvasSize = UDim2.new(0,0,0,Window.TabHolder.UIListLayout.AbsoluteContentSize.Y) end)

	-- Minimize keybind behavior
	game:GetService("UserInputService").InputBegan:Connect(function(Input)
		if type(Library.MinimizeKeybind) == "table" and Library.MinimizeKeybind.Type == "Keybind" and not game:GetService("UserInputService"):GetFocusedTextBox() then
			if Input.KeyCode.Name == Library.MinimizeKeybind.Value then Window:Minimize() end
		elseif Input.KeyCode == Library.MinimizeKey and not game:GetService("UserInputService"):GetFocusedTextBox() then
			Window:Minimize()
		end
	end)

	function Window:Minimize()
		Window.Minimized = not Window.Minimized
		Window.Root.Visible = not Window.Minimized
		if not MinimizeNotif then
			MinimizeNotif = true
			local Key = Library.MinimizeKeybind and Library.MinimizeKeybind.Value or Library.MinimizeKey.Name
			Library:Notify({ Title = "Interface", Content = "Press " .. Key .. " to toggle the interface.", Duration = 6 })
		end
	end
	function Window:Destroy()
		if Library.UseAcrylic and Window.AcrylicPaint and Window.AcrylicPaint.Model then pcall(function() Window.AcrylicPaint.Model:Destroy() end) end
		Window.Root:Destroy()
	end

	-- Dialog and Tabs
	local DialogModule = Components.Dialog(Library):Init(Window)
	function Window:Dialog(Config) local D = DialogModule:Create(); D.Title.Text = Config.Title; D.Root.Size = UDim2.fromOffset((function() local Content = Creator.New("TextLabel", { Text = Config.Content or "", FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"), TextColor3 = Color3.fromRGB(240,240,240), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1,-40,1,0), Position = UDim2.fromOffset(20,60), BackgroundTransparency = 1, ThemeTag = { TextColor3 = "Text" }}) return Content.TextBounds.X + 40 end)(), 165); D:Open() end
	local TabModule = Components.Tab(Library):Init(Window)
	function Window:AddTab(TabConfig) return TabModule:New(TabConfig.Title, TabConfig.Icon, Window.TabHolder) end
	function Window:SelectTab(Tab) TabModule:SelectTab(1) end

	Window.TabHolder:GetPropertyChangedSignal("CanvasPosition"):Connect(function() Window.SelectorPosMotor:setGoal(Flipper.Instant.new(0)) end)

	return Window
end

-- ====================
-- Elements modules (inlined & adapted)
-- These modules expect being called as methods on an object with .Container, .ScrollFrame, .Library fields.
-- We'll set up Library.Elements metatable to dispatch to these.
-- ====================

-- Element: Toggle
local Element_Toggle = {}
function Element_Toggle:New(Idx, Config)
	local TweenService = game:GetService("TweenService")
	local Library = self.Library
	assert(Config.Title, "Toggle - Missing Title")

	local Toggle = {
		Value = Config.Default or false,
		Callback = Config.Callback or function(Value) end,
		Type = "Toggle",
	}

	local ToggleFrame = Components.Element(Config.Title, Config.Description, self.Container, true, Library)
	ToggleFrame.DescLabel.Size = UDim2.new(1, -54, 0, 14)

	Toggle.SetTitle = ToggleFrame.SetTitle
	Toggle.SetDesc = ToggleFrame.SetDesc

	local ToggleCircle = Creator.New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 2, 0.5, 0),
		Image = "rbxassetid://12266946128",
		ImageTransparency = 0.5,
		ThemeTag = {
			ImageColor3 = "ToggleSlider",
		},
	})

	local ToggleBorder = Creator.New("UIStroke", {
		Transparency = 0.5,
		ThemeTag = {
			Color = "ToggleSlider",
		},
	})

	local ToggleSlider = Creator.New("Frame", {
		Size = UDim2.fromOffset(36, 18),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Parent = ToggleFrame.Frame,
		BackgroundTransparency = 1,
		ThemeTag = {
			BackgroundColor3 = "Accent",
		},
	}, {
		Creator.New("UICorner", {
			CornerRadius = UDim.new(0, 9),
		}),
		ToggleBorder,
		ToggleCircle,
	})

	function Toggle:OnChanged(Func)
		Toggle.Changed = Func
		Func(Toggle.Value)
	end

	function Toggle:SetValue(Value)
		Value = not not Value
		Toggle.Value = Value

		Creator.OverrideTag(ToggleBorder, { Color = Toggle.Value and "Accent" or "ToggleSlider" })
		Creator.OverrideTag(ToggleCircle, { ImageColor3 = Toggle.Value and "ToggleToggled" or "ToggleSlider" })
		TweenService:Create(
			ToggleCircle,
			TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0, Toggle.Value and 19 or 2, 0.5, 0) }
		):Play()
		TweenService:Create(
			ToggleSlider,
			TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ BackgroundTransparency = Toggle.Value and 0 or 1 }
		):Play()
		ToggleCircle.ImageTransparency = Toggle.Value and 0 or 0.5

		if Library then
			Library:SafeCallback(Toggle.Callback, Toggle.Value)
			Library:SafeCallback(Toggle.Changed, Toggle.Value)
		end
	end

	function Toggle:Destroy()
		ToggleFrame:Destroy()
		if Library then Library.Options[Idx] = nil end
	end

	Creator.AddSignal(ToggleFrame.Frame.MouseButton1Click, function()
		Toggle:SetValue(not Toggle.Value)
	end)

	Toggle:SetValue(Toggle.Value)

	if Library then Library.Options[Idx] = Toggle end
	return Toggle
end

-- Element: Dropdown
local Element_Dropdown = {}
function Element_Dropdown:New(Idx, Config)
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local Mouse = game:GetService("Players").LocalPlayer:GetMouse()
	local Camera = workspace.CurrentCamera

	local Library = self.Library

	local Dropdown = {
		Values = Config.Values,
		Value = Config.Default,
		Multi = Config.Multi,
		Buttons = {},
		Opened = false,
		Type = "Dropdown",
		Callback = Config.Callback or function() end,
	}

	local DropdownFrame = Components.Element(Config.Title, Config.Description, self.Container, false, Library)
	DropdownFrame.DescLabel.Size = UDim2.new(1, -170, 0, 14)

	Dropdown.SetTitle = DropdownFrame.SetTitle
	Dropdown.SetDesc = DropdownFrame.SetDesc

	local DropdownDisplay = Creator.New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Text = "Value",
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -30, 0, 14),
		Position = UDim2.new(0, 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	local DropdownIco = Creator.New("ImageLabel", {
		Image = "rbxassetid://10709790948",
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundTransparency = 1,
		ThemeTag = {
			ImageColor3 = "SubText",
		},
	})

	local DropdownInner = Creator.New("TextButton", {
		Size = UDim2.fromOffset(160, 30),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 0.9,
		Parent = DropdownFrame.Frame,
		ThemeTag = {
			BackgroundColor3 = "DropdownFrame",
		},
	}, {
		Creator.New("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
		Creator.New("UIStroke", {
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "InElementBorder",
			},
		}),
		DropdownIco,
		DropdownDisplay,
	})

	local DropdownListLayout = Creator.New("UIListLayout", {
		Padding = UDim.new(0, 3),
	})

	local DropdownScrollFrame = Creator.New("ScrollingFrame", {
		Size = UDim2.new(1, -5, 1, -10),
		Position = UDim2.fromOffset(5, 5),
		BackgroundTransparency = 1,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 4,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
	}, {
		DropdownListLayout,
	})

	local DropdownHolderFrame = Creator.New("Frame", {
		Size = UDim2.fromScale(1, 0.6),
		ThemeTag = {
			BackgroundColor3 = "DropdownHolder",
		},
	}, {
		DropdownScrollFrame,
		Creator.New("UICorner", {
			CornerRadius = UDim.new(0, 7),
		}),
		Creator.New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "DropdownBorder",
			},
		}),
		Creator.New("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://5554236805",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(23, 23, 277, 277),
			Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(30, 30),
			Position = UDim2.fromOffset(-15, -15),
			ImageColor3 = Color3.fromRGB(0, 0, 0),
			ImageTransparency = 0.1,
		}),
	})

	local DropdownHolderCanvas = Creator.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(170, 300),
		Parent = self.Library.GUI,
		Visible = false,
	}, {
		DropdownHolderFrame,
		Creator.New("UISizeConstraint", {
			MinSize = Vector2.new(170, 0),
		}),
	})
	table.insert(Library.OpenFrames, DropdownHolderCanvas)

	local function RecalculateListPosition()
		local Add = 0
		if Camera and (Camera.ViewportSize.Y - DropdownInner.AbsolutePosition.Y) < (DropdownHolderCanvas.AbsoluteSize.Y - 5) then
			Add = DropdownHolderCanvas.AbsoluteSize.Y - 5 - (Camera.ViewportSize.Y - DropdownInner.AbsolutePosition.Y) + 40
		end
		DropdownHolderCanvas.Position = UDim2.fromOffset(DropdownInner.AbsolutePosition.X - 1, DropdownInner.AbsolutePosition.Y - 5 - Add)
	end

	local ListSizeX = 0
	local function RecalculateListSize()
		if #Dropdown.Values > 10 then
			DropdownHolderCanvas.Size = UDim2.fromOffset(ListSizeX, 392)
		else
			DropdownHolderCanvas.Size = UDim2.fromOffset(ListSizeX, DropdownListLayout.AbsoluteContentSize.Y + 10)
		end
	end

	local function RecalculateCanvasSize()
		DropdownScrollFrame.CanvasSize = UDim2.fromOffset(0, DropdownListLayout.AbsoluteContentSize.Y)
	end

	RecalculateListPosition()
	RecalculateListSize()

	Creator.AddSignal(DropdownInner:GetPropertyChangedSignal("AbsolutePosition"), RecalculateListPosition)

	Creator.AddSignal(DropdownInner.MouseButton1Click, function()
		Dropdown:Open()
	end)

	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			local AbsPos, AbsSize = DropdownHolderFrame.AbsolutePosition, DropdownHolderFrame.AbsoluteSize
			if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then
				Dropdown:Close()
			end
		end
	end)

	local ScrollFrame = self.ScrollFrame
	function Dropdown:Open()
		Dropdown.Opened = true
		ScrollFrame.ScrollingEnabled = false
		DropdownHolderCanvas.Visible = true
		TweenService:Create(
			DropdownHolderFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(1, 1) }
		):Play()
	end

	function Dropdown:Close()
		Dropdown.Opened = false
		ScrollFrame.ScrollingEnabled = true
		DropdownHolderFrame.Size = UDim2.fromScale(1, 0.6)
		DropdownHolderCanvas.Visible = false
	end

	function Dropdown:Display()
		local Values = Dropdown.Values
		local Str = ""

		if Config.Multi then
			for Idx, Value in next, Values do
				if Dropdown.Value and Dropdown.Value[Value] then
					Str = Str .. Value .. ", "
				end
			end
			Str = Str:sub(1, #Str - 2)
		else
			Str = Dropdown.Value or ""
		end

		DropdownDisplay.Text = (Str == "" and "--" or Str)
	end

	function Dropdown:GetActiveValues()
		if Config.Multi then
			local T = {}
			for Value, Bool in next, Dropdown.Value or {} do
				table.insert(T, Value)
			end
			return T
		else
			return Dropdown.Value and 1 or 0
		end
	end

	function Dropdown:BuildDropdownList()
		local Values = Dropdown.Values
		local Buttons = {}

		for _, Element in next, DropdownScrollFrame:GetChildren() do
			if not Element:IsA("UIListLayout") then
				Element:Destroy()
			end
		end

		local Count = 0

		for Idx, Value in next, Values do
			local Table = {}
			Count = Count + 1

			local ButtonSelector = Creator.New("Frame", {
				Size = UDim2.fromOffset(4, 14),
				BackgroundColor3 = Color3.fromRGB(76, 194, 255),
				Position = UDim2.fromOffset(-1, 16),
				AnchorPoint = Vector2.new(0, 0.5),
				ThemeTag = {
					BackgroundColor3 = "Accent",
				},
			}, {
				Creator.New("UICorner", { CornerRadius = UDim.new(0, 2) }),
			})

			local ButtonLabel = Creator.New("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
				Text = Value,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromOffset(10, 0),
				Name = "ButtonLabel",
				ThemeTag = {
					TextColor3 = "Text",
				},
			})

			local Button = Creator.New("TextButton", {
				Size = UDim2.new(1, -5, 0, 32),
				BackgroundTransparency = 1,
				ZIndex = 23,
				Text = "",
				Parent = DropdownScrollFrame,
				ThemeTag = {
					BackgroundColor3 = "DropdownOption",
				},
			}, {
				ButtonSelector,
				ButtonLabel,
				Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
			})

			local Selected

			if Config.Multi then
				Selected = Dropdown.Value and Dropdown.Value[Value]
			else
				Selected = Dropdown.Value == Value
			end

			local BackMotor, SetBackTransparency = Creator.SpringMotor(1, Button, "BackgroundTransparency")
			local SelMotor, SetSelTransparency = Creator.SpringMotor(1, ButtonSelector, "BackgroundTransparency")
			local SelectorSizeMotor = Flipper.SingleMotor.new(6)

			SelectorSizeMotor:onStep(function(value)
				ButtonSelector.Size = UDim2.new(0, 4, 0, value)
			end)

			Creator.AddSignal(Button.MouseEnter, function()
				SetBackTransparency(Selected and 0.85 or 0.89)
			end)
			Creator.AddSignal(Button.MouseLeave, function()
				SetBackTransparency(Selected and 0.89 or 1)
			end)
			Creator.AddSignal(Button.MouseButton1Down, function()
				SetBackTransparency(0.92)
			end)
			Creator.AddSignal(Button.MouseButton1Up, function()
				SetBackTransparency(Selected and 0.85 or 0.89)
			end)

			function Table:UpdateButton()
				if Config.Multi then
					Selected = Dropdown.Value and Dropdown.Value[Value]
					if Selected then
						SetBackTransparency(0.89)
					end
				else
					Selected = Dropdown.Value == Value
					SetBackTransparency(Selected and 0.89 or 1)
				end

				SelectorSizeMotor:setGoal(Flipper.Spring.new(Selected and 14 or 6, { frequency = 6 }))
				SetSelTransparency(Selected and 0 or 1)
			end

			ButtonLabel.InputBegan:Connect(function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
					local Try = not Selected

					if Dropdown:GetActiveValues() == 1 and not Try and not Config.AllowNull then
					else
						if Config.Multi then
							Selected = Try
							Dropdown.Value[Value] = Selected and true or nil
						else
							Selected = Try
							Dropdown.Value = Selected and Value or nil

							for _, OtherButton in next, Buttons do
								OtherButton:UpdateButton()
							end
						end

						Table:UpdateButton()
						Dropdown:Display()

						if Library then
							Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
							Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
						end
					end
				end
			end)

			Table:UpdateButton()
			Dropdown:Display()

			Buttons[Button] = Table
		end

		ListSizeX = 0
		for Button, Table in next, Buttons do
			if Button.ButtonLabel then
				if Button.ButtonLabel.TextBounds.X > ListSizeX then
					ListSizeX = Button.ButtonLabel.TextBounds.X
				end
			end
		end
		ListSizeX = ListSizeX + 30

		RecalculateCanvasSize()
		RecalculateListSize()
	end

	function Dropdown:SetValues(NewValues)
		if NewValues then
			Dropdown.Values = NewValues
		end
		Dropdown:BuildDropdownList()
	end

	function Dropdown:OnChanged(Func)
		Dropdown.Changed = Func
		Func(Dropdown.Value)
	end

	function Dropdown:SetValue(Val)
		if Dropdown.Multi then
			local nTable = {}
			for Value, Bool in next, Val do
				if table.find(Dropdown.Values, Value) then
					nTable[Value] = true
				end
			end
			Dropdown.Value = nTable
		else
			if not Val then
				Dropdown.Value = nil
			elseif table.find(Dropdown.Values, Val) then
				Dropdown.Value = Val
			end
		end

		Dropdown:BuildDropdownList()

		if Library then
			Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
			Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
		end
	end

	function Dropdown:Destroy()
		DropdownFrame:Destroy()
		if Library then Library.Options[Idx] = nil end
	end

	Dropdown:BuildDropdownList()
	Dropdown:Display()

	local Defaults = {}

	if type(Config.Default) == "string" then
		local Idx = table.find(Dropdown.Values, Config.Default)
		if Idx then table.insert(Defaults, Idx) end
	elseif type(Config.Default) == "table" then
		for _, Value in next, Config.Default do
			local Idx = table.find(Dropdown.Values, Value)
			if Idx then table.insert(Defaults, Idx) end
		end
	elseif type(Config.Default) == "number" and Dropdown.Values[Config.Default] ~= nil then
		table.insert(Defaults, Config.Default)
	end

	if next(Defaults) then
		for i = 1, #Defaults do
			local Index = Defaults[i]
			if Config.Multi then
				Dropdown.Value[Dropdown.Values[Index]] = true
			else
				Dropdown.Value = Dropdown.Values[Index]
			end
			if not Config.Multi then break end
		end
		Dropdown:BuildDropdownList()
		Dropdown:Display()
	end

	if Library then Library.Options[Idx] = Dropdown end
	return Dropdown
end

-- Element: Input
local Element_Input = {}
function Element_Input:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "Input - Missing Title")
	Config.Callback = Config.Callback or function() end

	local Input = {
		Value = Config.Default or "",
		Numeric = Config.Numeric or false,
		Finished = Config.Finished or false,
		Callback = Config.Callback or function(Value) end,
		Type = "Input",
	}

	local InputFrame = Components.Element(Config.Title, Config.Description, self.Container, false, Library)

	Input.SetTitle = InputFrame.SetTitle
	Input.SetDesc = InputFrame.SetDesc

	local Textbox = Components.Textbox(InputFrame.Frame, true, Library)
	Textbox.Frame.Position = UDim2.new(1, -10, 0.5, 0)
	Textbox.Frame.AnchorPoint = Vector2.new(1, 0.5)
	Textbox.Frame.Size = UDim2.fromOffset(160, 30)
	Textbox.Input.Text = Config.Default or ""
	Textbox.Input.PlaceholderText = Config.Placeholder or ""

	local Box = Textbox.Input

	function Input:SetValue(Text)
		if Config.MaxLength and #Text > Config.MaxLength then
			Text = Text:sub(1, Config.MaxLength)
		end

		if Input.Numeric then
			if (not tonumber(Text)) and Text:len() > 0 then
				Text = Input.Value
			end
		end

		Input.Value = Text
		Box.Text = Text

		if Library then
			Library:SafeCallback(Input.Callback, Input.Value)
			Library:SafeCallback(Input.Changed, Input.Value)
		end
	end

	if Input.Finished then
		Creator.AddSignal(Box.FocusLost, function(enter)
			if not enter then
				return
			end
			Input:SetValue(Box.Text)
		end)
	else
		Creator.AddSignal(Box:GetPropertyChangedSignal("Text"), function()
			Input:SetValue(Box.Text)
		end)
	end

	function Input:OnChanged(Func)
		Input.Changed = Func
		Func(Input.Value)
	end

	function Input:Destroy()
		InputFrame:Destroy()
		if Library then Library.Options[Idx] = nil end
	end

	if Config.Default then Input:SetValue(Config.Default) end
	if Library then Library.Options[Idx] = Input end
	return Input
end

-- Element: Paragraph
local Element_Paragraph = {}
function Element_Paragraph:New(Config)
	assert(Config.Title, "Paragraph - Missing Title")
	Config.Content = Config.Content or ""
	local Paragraph = Components.Element(Config.Title, Config.Content, self.Container, false, self.Library)
	Paragraph.Frame.BackgroundTransparency = 0.92
	Paragraph.Border.Transparency = 0.6
	return Paragraph
end

-- Element: Button (element; uses Components.Button)
local Element_Button = {}
function Element_Button:New(Config)
	assert(Config.Title, "Button - Missing Title")
	Config.Callback = Config.Callback or function() end
	local ButtonFrame = Components.Element(Config.Title, Config.Description, self.Container, true, self.Library)
	local ButtonIco = Creator.New("ImageLabel", {
		Image = "rbxassetid://10709791437",
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		BackgroundTransparency = 1,
		Parent = ButtonFrame.Frame,
		ThemeTag = {
			ImageColor3 = "Text",
		},
	})
	Creator.AddSignal(ButtonFrame.Frame.MouseButton1Click, function()
		self.Library:SafeCallback(Config.Callback)
	end)
	return ButtonFrame
end

-- Element: Keybind
local Element_Keybind = {}
function Element_Keybind:New(Idx, Config)
	local UserInputService = game:GetService("UserInputService")
	local Library = self.Library
	assert(Config.Title, "KeyBind - Missing Title")
	assert(Config.Default, "KeyBind - Missing default value.")

	local Keybind = {
		Value = Config.Default,
		Toggled = false,
		Mode = Config.Mode or "Toggle",
		Type = "Keybind",
		Callback = Config.Callback or function(Value) end,
		ChangedCallback = Config.ChangedCallback or function(New) end,
	}
	local Picking = false
	local KeybindFrame = Components.Element(Config.Title, Config.Description, self.Container, true, Library)
	Keybind.SetTitle = KeybindFrame.SetTitle
	Keybind.SetDesc = KeybindFrame.SetDesc

	local KeybindDisplayLabel = Creator.New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Text = Config.Default,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(0, 0, 0, 14),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	local KeybindDisplayFrame = Creator.New("TextButton", {
		Size = UDim2.fromOffset(0, 30),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 0.9,
		Parent = KeybindFrame.Frame,
		AutomaticSize = Enum.AutomaticSize.X,
		ThemeTag = {
			BackgroundColor3 = "Keybind",
		},
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Creator.New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
		Creator.New("UIStroke", { Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, ThemeTag = { Color = "InElementBorder" } }),
		KeybindDisplayLabel,
	})

	function Keybind:GetState()
		if UserInputService:GetFocusedTextBox() and Keybind.Mode ~= "Always" then
			return false
		end

		if Keybind.Mode == "Always" then
			return true
		elseif Keybind.Mode == "Hold" then
			if Keybind.Value == "None" then
				return false
			end

			local Key = Keybind.Value

			if Key == "MouseLeft" or Key == "MouseRight" then
				return Key == "MouseLeft" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
					or Key == "MouseRight"
						and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			else
				return UserInputService:IsKeyDown(Enum.KeyCode[Keybind.Value])
			end
		else
			return Keybind.Toggled
		end
	end

	function Keybind:SetValue(Key, Mode)
		Key = Key or Keybind.Key
		Mode = Mode or Keybind.Mode

		KeybindDisplayLabel.Text = Key
		Keybind.Value = Key
		Keybind.Mode = Mode
	end

	function Keybind:OnClick(Callback)
		Keybind.Clicked = Callback
	end

	function Keybind:OnChanged(Callback)
		Keybind.Changed = Callback
		Callback(Keybind.Value)
	end

	function Keybind:DoClick()
		Library:SafeCallback(Keybind.Callback, Keybind.Toggled)
		Library:SafeCallback(Keybind.Clicked, Keybind.Toggled)
	end

	function Keybind:Destroy()
		KeybindFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Creator.AddSignal(KeybindDisplayFrame.InputBegan, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Picking = true
			KeybindDisplayLabel.Text = "..."
			wait(0.2)
			local Event
			Event = UserInputService.InputBegan:Connect(function(Input)
				local Key
				if Input.UserInputType == Enum.UserInputType.Keyboard then
					Key = Input.KeyCode.Name
				elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
					Key = "MouseLeft"
				elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
					Key = "MouseRight"
				end
				local EndedEvent
				EndedEvent = UserInputService.InputEnded:Connect(function(Input)
					if Input.KeyCode.Name == Key or Key == "MouseLeft" and Input.UserInputType == Enum.UserInputType.MouseButton1 or Key == "MouseRight" and Input.UserInputType == Enum.UserInputType.MouseButton2 then
						Picking = false
						KeybindDisplayLabel.Text = Key
						Keybind.Value = Key
						Library:SafeCallback(Keybind.ChangedCallback, Input.KeyCode or Input.UserInputType)
						Library:SafeCallback(Keybind.Changed, Input.KeyCode or Input.UserInputType)
						Event:Disconnect()
						EndedEvent:Disconnect()
					end
				end)
			end)
		end
	end)

	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if not Picking and not UserInputService:GetFocusedTextBox() then
			if Keybind.Mode == "Toggle" then
				local Key = Keybind.Value
				if Key == "MouseLeft" or Key == "MouseRight" then
					if Key == "MouseLeft" and Input.UserInputType == Enum.UserInputType.MouseButton1 or Key == "MouseRight" and Input.UserInputType == Enum.UserInputType.MouseButton2 then
						Keybind.Toggled = not Keybind.Toggled
						Keybind:DoClick()
					end
				elseif Input.UserInputType == Enum.UserInputType.Keyboard then
					if Input.KeyCode.Name == Key then
						Keybind.Toggled = not Keybind.Toggled
						Keybind:DoClick()
					end
				end
			end
		end
	end)

	if Library then Library.Options[Idx] = Keybind end
	return Keybind
end

-- Element: Slider
local Element_Slider = {}
function Element_Slider:New(Idx, Config)
	local UserInputService = game:GetService("UserInputService")
	local Library = self.Library
	assert(Config.Title, "Slider - Missing Title.")
	assert(Config.Default ~= nil, "Slider - Missing default value.")
	assert(Config.Min ~= nil, "Slider - Missing minimum value.")
	assert(Config.Max ~= nil, "Slider - Missing maximum value.")
	assert(Config.Rounding ~= nil, "Slider - Missing rounding value.")

	local Slider = {
		Value = nil,
		Min = Config.Min,
		Max = Config.Max,
		Rounding = Config.Rounding,
		Callback = Config.Callback or function(Value) end,
		Type = "Slider",
	}

	local Dragging = false

	local SliderFrame = Components.Element(Config.Title, Config.Description, self.Container, false, Library)
	SliderFrame.DescLabel.Size = UDim2.new(1, -170, 0, 14)

	Slider.SetTitle = SliderFrame.SetTitle
	Slider.SetDesc = SliderFrame.SetDesc

	local SliderDot = Creator.New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -7, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Image = "rbxassetid://12266946128",
		ThemeTag = {
			ImageColor3 = "Accent",
		},
	})

	local SliderRail = Creator.New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(7, 0),
		Size = UDim2.new(1, -14, 1, 0),
	}, {
		SliderDot,
	})

	local SliderFill = Creator.New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		ThemeTag = {
			BackgroundColor3 = "Accent",
		},
	}, {
		Creator.New("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
	})

	local SliderDisplay = Creator.New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Text = "Value",
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 100, 0, 14),
		Position = UDim2.new(0, -4, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ThemeTag = {
			TextColor3 = "SubText",
		},
	})

	local SliderInner = Creator.New("Frame", {
		Size = UDim2.new(1, 0, 0, 4),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		BackgroundTransparency = 0.4,
		Parent = SliderFrame.Frame,
		ThemeTag = {
			BackgroundColor3 = "SliderRail",
		},
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Creator.New("UISizeConstraint", { MaxSize = Vector2.new(150, math.huge) }),
		SliderDisplay,
		SliderFill,
		SliderRail,
	})

	Creator.AddSignal(SliderDot.InputBegan, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
		end
	end)

	Creator.AddSignal(SliderDot.InputEnded, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = false
		end
	end)

	Creator.AddSignal(UserInputService.InputChanged, function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
			local SizeScale = math.clamp((Input.Position.X - SliderRail.AbsolutePosition.X) / SliderRail.AbsoluteSize.X, 0, 1)
			Slider:SetValue(Slider.Min + ((Slider.Max - Slider.Min) * SizeScale))
		end
	end)

	function Slider:OnChanged(Func)
		Slider.Changed = Func
		Func(Slider.Value)
	end

	function Slider:SetValue(Value)
		self.Value = Library:Round(math.clamp(Value, Slider.Min, Slider.Max), Slider.Rounding)
		SliderDot.Position = UDim2.new((self.Value - Slider.Min) / (Slider.Max - Slider.Min), -7, 0.5, 0)
		SliderFill.Size = UDim2.fromScale((self.Value - Slider.Min) / (Slider.Max - Slider.Min), 1)
		SliderDisplay.Text = tostring(self.Value)
		Library:SafeCallback(Slider.Callback, self.Value)
		Library:SafeCallback(Slider.Changed, self.Value)
	end

	function Slider:Destroy()
		SliderFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Slider:SetValue(Config.Default)

	if Library then Library.Options[Idx] = Slider end
	return Slider
end

-- Element: Colorpicker
local Element_Colorpicker = {}
function Element_Colorpicker:New(Idx, Config)
	local UserInputService = game:GetService("UserInputService")
	local TouchInputService = game:GetService("TouchInputService")
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local RenderStepped = RunService.RenderStepped
	local LocalPlayer = Players.LocalPlayer
	local Mouse = LocalPlayer:GetMouse()

	local Library = self.Library
	assert(Config.Title, "Colorpicker - Missing Title")
	assert(Config.Default, "AddColorPicker: Missing default value.")

	local Colorpicker = {
		Value = Config.Default,
		Transparency = Config.Transparency or 0,
		Type = "Colorpicker",
		Title = type(Config.Title) == "string" and Config.Title or "Colorpicker",
		Callback = Config.Callback or function(Color) end,
	}

	function Colorpicker:SetHSVFromRGB(Color)
		local H, S, V = Color3.toHSV(Color)
		Colorpicker.Hue = H
		Colorpicker.Sat = S
		Colorpicker.Vib = V
	end

	Colorpicker:SetHSVFromRGB(Colorpicker.Value)

	local ColorpickerFrame = Components.Element(Config.Title, Config.Description, self.Container, true, Library)

	Colorpicker.SetTitle = ColorpickerFrame.SetTitle
	Colorpicker.SetDesc = ColorpickerFrame.SetDesc

	local DisplayFrameColor = Creator.New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Colorpicker.Value,
		Parent = ColorpickerFrame.Frame,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
	})

	local DisplayFrame = Creator.New("ImageLabel", {
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Parent = ColorpickerFrame.Frame,
		Image = "rbxassetid://14204231522",
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(40, 40),
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
		DisplayFrameColor,
	})

	local function CreateColorDialog()
		local Dialog = Components.Dialog(Library):Create()
		Dialog.Title.Text = Colorpicker.Title
		Dialog.Root.Size = UDim2.fromOffset(430, 330)

		local Hue, Sat, Vib = Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib
		local Transparency = Colorpicker.Transparency

		local function CreateInput()
			local Box = Components.Textbox()
			Box.Frame.Parent = Dialog.Root
			Box.Frame.Size = UDim2.new(0, 90, 0, 32)
			return Box
		end

		local function CreateInputLabel(Text, Pos)
			return Creator.New("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
				Text = Text,
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 0, 32),
				Position = Pos,
				BackgroundTransparency = 1,
				Parent = Dialog.Root,
				ThemeTag = { TextColor3 = "Text" },
			})
		end

		local function GetRGB()
			local Value = Color3.fromHSV(Hue, Sat, Vib)
			return { R = math.floor(Value.r * 255), G = math.floor(Value.g * 255), B = math.floor(Value.b * 255) }
		end

		local SatCursor = Creator.New("ImageLabel", {
			Size = UDim2.new(0, 18, 0, 18),
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "rbxassetid://4805639000",
		})

		local SatVibMap = Creator.New("ImageLabel", {
			Size = UDim2.fromOffset(180, 160),
			Position = UDim2.fromOffset(20, 55),
			Image = "rbxassetid://4155801252",
			BackgroundColor3 = Colorpicker.Value,
			BackgroundTransparency = 0,
			Parent = Dialog.Root,
		}, {
			Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
			SatCursor,
		})

		local OldColorFrame = Creator.New("Frame", {
			BackgroundColor3 = Colorpicker.Value,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = Colorpicker.Transparency,
		}, {
			Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
		})

		local OldColorFrameChecker = Creator.New("ImageLabel", {
			Image = "rbxassetid://14204231522",
			ImageTransparency = 0.45,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(112, 220),
			Size = UDim2.fromOffset(88, 24),
			Parent = Dialog.Root,
		}, {
			Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
			Creator.New("UIStroke", { Thickness = 2, Transparency = 0.75 }),
			OldColorFrame,
		})

		local DialogDisplayFrame = Creator.New("Frame", {
			BackgroundColor3 = Colorpicker.Value,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 0,
		}, {
			Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
		})

		local DialogDisplayFrameChecker = Creator.New("ImageLabel", {
			Image = "rbxassetid://14204231522",
			ImageTransparency = 0.45,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(20, 220),
			Size = UDim2.fromOffset(88, 24),
			Parent = Dialog.Root,
		}, {
			Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
			Creator.New("UIStroke", { Thickness = 2, Transparency = 0.75 }),
			DialogDisplayFrame,
		})

		local SequenceTable = {}
		for Color = 0, 1, 0.1 do
			table.insert(SequenceTable, ColorSequenceKeypoint.new(Color, Color3.fromHSV(Color, 1, 1)))
		end

		local HueSliderGradient = Creator.New("UIGradient", { Color = ColorSequence.new(SequenceTable), Rotation = 90 })

		local HueDragHolder = Creator.New("Frame", { Size = UDim2.new(1, 0, 1, -10), Position = UDim2.fromOffset(0, 5), BackgroundTransparency = 1 })
		local HueDrag = Creator.New("ImageLabel", { Size = UDim2.fromOffset(14, 14), Image = "rbxassetid://12266946128", Parent = HueDragHolder, ThemeTag = { ImageColor3 = "DialogInput" } })
		local HueSlider = Creator.New("Frame", { Size = UDim2.fromOffset(12, 190), Position = UDim2.fromOffset(210, 55), Parent = Dialog.Root }, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }), HueSliderGradient, HueDragHolder })

		local HexInput = CreateInput()
		HexInput.Frame.Position = UDim2.fromOffset(Config.Transparency and 260 or 240, 55)
		CreateInputLabel("Hex", UDim2.fromOffset(Config.Transparency and 360 or 340, 55))

		local RedInput = CreateInput()
		RedInput.Frame.Position = UDim2.fromOffset(Config.Transparency and 260 or 240, 95)
		CreateInputLabel("Red", UDim2.fromOffset(Config.Transparency and 360 or 340, 95))

		local GreenInput = CreateInput()
		GreenInput.Frame.Position = UDim2.fromOffset(Config.Transparency and 260 or 240, 135)
		CreateInputLabel("Green", UDim2.fromOffset(Config.Transparency and 360 or 340, 135))

		local BlueInput = CreateInput()
		BlueInput.Frame.Position = UDim2.fromOffset(Config.Transparency and 260 or 240, 175)
		CreateInputLabel("Blue", UDim2.fromOffset(Config.Transparency and 360 or 340, 175))

		local AlphaInput
		if Config.Transparency then
			AlphaInput = CreateInput()
			AlphaInput.Frame.Position = UDim2.fromOffset(260, 215)
			CreateInputLabel("Alpha", UDim2.fromOffset(360, 215))
		end

		local TransparencySlider, TransparencyDrag, TransparencyColor
		if Config.Transparency then
			local TransparencyDragHolder = Creator.New("Frame", { Size = UDim2.new(1, 0, 1, -10), Position = UDim2.fromOffset(0, 5), BackgroundTransparency = 1 })
			TransparencyDrag = Creator.New("ImageLabel", { Size = UDim2.fromOffset(14, 14), Image = "rbxassetid://12266946128", Parent = TransparencyDragHolder, ThemeTag = { ImageColor3 = "DialogInput" } })
			TransparencyColor = Creator.New("Frame", { Size = UDim2.fromScale(1, 1) }, {
				Creator.New("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }), Rotation = 270 }),
				Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
			})
			TransparencySlider = Creator.New("Frame", { Size = UDim2.fromOffset(12, 190), Position = UDim2.fromOffset(230, 55), Parent = Dialog.Root, BackgroundTransparency = 1 }, {
				Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Creator.New("ImageLabel", { Image = "rbxassetid://14204231522", ImageTransparency = 0.45, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = Dialog.Root }, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }) }),
				TransparencyColor,
				TransparencyDragHolder,
			})
		end

		local function Display()
			SatVibMap.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
			HueDrag.Position = UDim2.new(0, -1, Hue, -6)
			SatCursor.Position = UDim2.new(Sat, 0, 1 - Vib, 0)
			DialogDisplayFrame.BackgroundColor3 = Color3.fromHSV(Hue, Sat, Vib)
			HexInput.Input.Text = "#" .. Color3.fromHSV(Hue, Sat, Vib):ToHex()
			RedInput.Input.Text = GetRGB()["R"]
			GreenInput.Input.Text = GetRGB()["G"]
			BlueInput.Input.Text = GetRGB()["B"]
			if Config.Transparency then
				TransparencyColor.BackgroundColor3 = Color3.fromHSV(Hue, Sat, Vib)
				DialogDisplayFrame.BackgroundTransparency = Transparency
				TransparencyDrag.Position = UDim2.new(0, -1, 1 - Transparency, -6)
				AlphaInput.Input.Text = tostring(math.floor((1 - Transparency) * 100)) .. "%"
			end
		end

		Creator.AddSignal(HexInput.Input.FocusLost, function(Enter)
			if Enter then
				local Success, Result = pcall(Color3.fromHex, HexInput.Input.Text)
				if Success and typeof(Result) == "Color3" then
					Hue, Sat, Vib = Color3.toHSV(Result)
				end
			end
			Display()
		end)

		Creator.AddSignal(RedInput.Input.FocusLost, function(Enter)
			if Enter then
				local CurrentColor = GetRGB()
				local Success, Result = pcall(Color3.fromRGB, RedInput.Input.Text, CurrentColor["G"], CurrentColor["B"])
				if Success and typeof(Result) == "Color3" then
					if tonumber(RedInput.Input.Text) <= 255 then
						Hue, Sat, Vib = Color3.toHSV(Result)
					end
				end
			end
			Display()
		end)

		Creator.AddSignal(GreenInput.Input.FocusLost, function(Enter)
			if Enter then
				local CurrentColor = GetRGB()
				local Success, Result = pcall(Color3.fromRGB, CurrentColor["R"], GreenInput.Input.Text, CurrentColor["B"])
				if Success and typeof(Result) == "Color3" then
					if tonumber(GreenInput.Input.Text) <= 255 then
						Hue, Sat, Vib = Color3.toHSV(Result)
					end
				end
			end
			Display()
		end)

		Creator.AddSignal(BlueInput.Input.FocusLost, function(Enter)
			if Enter then
				local CurrentColor = GetRGB()
				local Success, Result = pcall(Color3.fromRGB, CurrentColor["R"], CurrentColor["G"], BlueInput.Input.Text)
				if Success and typeof(Result) == "Color3" then
					if tonumber(BlueInput.Input.Text) <= 255 then
						Hue, Sat, Vib = Color3.toHSV(Result)
					end
				end
			end
			Display()
		end)

		if Config.Transparency then
			Creator.AddSignal(AlphaInput.Input.FocusLost, function(Enter)
				if Enter then
					pcall(function()
						local Value = tonumber(AlphaInput.Input.Text)
						if Value >= 0 and Value <= 100 then
							Transparency = 1 - Value * 0.01
						end
					end)
				end
				Display()
			end)
		end

		Creator.AddSignal(SatVibMap.InputBegan, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local MinX = SatVibMap.AbsolutePosition.X
					local MaxX = MinX + SatVibMap.AbsoluteSize.X
					local MouseX = math.clamp(Mouse.X, MinX, MaxX)
					local MinY = SatVibMap.AbsolutePosition.Y
					local MaxY = MinY + SatVibMap.AbsoluteSize.Y
					local MouseY = math.clamp(Mouse.Y, MinY, MaxY)
					Sat = (MouseX - MinX) / (MaxX - MinX)
					Vib = 1 - ((MouseY - MinY) / (MaxY - MinY))
					Display()
					RenderStepped:Wait()
				end
			end
		end)

		Creator.AddSignal(HueSlider.InputBegan, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
					local MinY = HueSlider.AbsolutePosition.Y
					local MaxY = MinY + HueSlider.AbsoluteSize.Y
					local MouseY = math.clamp(Mouse.Y, MinY, MaxY)
					Hue = ((MouseY - MinY) / (MaxY - MinY))
					Display()
					RenderStepped:Wait()
				end
			end
		end)

		if Config.Transparency then
			Creator.AddSignal(TransparencySlider.InputBegan, function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					while UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
						local MinY = TransparencySlider.AbsolutePosition.Y
						local MaxY = MinY + TransparencySlider.AbsoluteSize.Y
						local MouseY = math.clamp(Mouse.Y, MinY, MaxY)
						Transparency = 1 - ((MouseY - MinY) / (MaxY - MinY))
						Display()
						RenderStepped:Wait()
					end
				end
			end)
		end

		Display()

		Dialog:Button("Done", function()
			Colorpicker:SetValue({ Hue, Sat, Vib }, Transparency)
		end)
		Dialog:Button("Cancel")
		Dialog:Open()
	end

	function Colorpicker:Display()
		Colorpicker.Value = Color3.fromHSV(Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Vib)
		DisplayFrameColor.BackgroundColor3 = Colorpicker.Value
		DisplayFrameColor.BackgroundTransparency = Colorpicker.Transparency
		self.Library:SafeCallback(Colorpicker.Callback, Colorpicker.Value)
		self.Library:SafeCallback(Colorpicker.Changed, Colorpicker.Value)
	end

	function Colorpicker:SetValue(HSV, Transparency)
		local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])
		Colorpicker.Transparency = Transparency or 0
		Colorpicker:SetHSVFromRGB(Color)
		Colorpicker:Display()
	end

	function Colorpicker:SetValueRGB(Color, Transparency)
		Colorpicker.Transparency = Transparency or 0
		Colorpicker:SetHSVFromRGB(Color)
		Colorpicker:Display()
	end

	function Colorpicker:OnChanged(Func)
		Colorpicker.Changed = Func
		Func(Colorpicker.Value)
	end

	function Colorpicker:Destroy()
		ColorpickerFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Creator.AddSignal(ColorpickerFrame.Frame.MouseButton1Click, function()
		CreateColorDialog()
	end)

	Colorpicker:Display()

	if Library then Library.Options[Idx] = Colorpicker end
	return Colorpicker
end

-- ====================
-- Library (root)
-- ====================
local Library = {
	Version = "1.1.0",
	OpenFrames = {},
	Options = {},
	Themes = Themes.Names,
	Window = nil,
	WindowFrame = nil,
	Unloaded = false,
	Theme = "Dark",
	DialogOpen = false,
	UseAcrylic = false,
	Acrylic = false,
	Transparency = true,
	MinimizeKeybind = nil,
	MinimizeKey = Enum.KeyCode.LeftControl,
	GUI = nil,
	Elements = nil,
}

-- SafeCallback & helpers
function Library:SafeCallback(Function, ...)
	if not Function then return end
	local Success, Event = pcall(Function, ...)
	if not Success then
		local _, i = Event:find(":%d+: ")
		if not i then
			return Library:Notify({ Title = "Interface", Content = "Callback error", SubContent = Event, Duration = 5 })
		end
		return Library:Notify({ Title = "Interface", Content = "Callback error", SubContent = Event:sub(i + 1), Duration = 5 })
	end
end

function Library:Round(Number, Factor)
	if Factor == 0 then return math.floor(Number) end
	Number = tostring(Number)
	return Number:find("%.") and tonumber(Number:sub(1, Number:find("%.") + Factor)) or Number
end

local New = Creator.New
function Library:GetIcon(Name)
	if Name ~= nil and Icons.assets["lucide-" .. Name] then return Icons.assets["lucide-" .. Name] end
	return nil
end

-- Elements dispatcher: map names to modules above
local ElementsModules = {
	Toggle = Element_Toggle,
	Dropdown = Element_Dropdown,
	Input = Element_Input,
	Paragraph = Element_Paragraph,
	Button = Element_Button,
	Keybind = Element_Keybind,
	Slider = Element_Slider,
	Colorpicker = Element_Colorpicker,
}

-- Library.Elements metatable that dispatches element creation to inline modules
Library.Elements = {}
setmetatable(Library.Elements, {
	__index = function(tbl, key)
		local mod = ElementsModules[key]
		if mod and mod.New then
			-- Return a function suitable for method-call syntax: obj:Button(Idx, Config)
			return function(self, ...)
				-- 'self' should be the container (Tab or Section) and must have .Library, .Container, .ScrollFrame
				-- If .Library missing, set it to global Library
				if not self.Library then self.Library = Library end
				return mod.New(self, ...)
			end
		end
		return nil
	end
})

-- Creator.UpdateTheme wrapper
function Creator.UpdateThemeForLibrary(lib) Creator.UpdateTheme(lib) end

-- Create GUI and initialize
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end
local GUI = New("ScreenGui", { Parent = RunService:IsStudio() and (LocalPlayer and LocalPlayer.PlayerGui) or game:GetService("CoreGui") })
pcall(function() ProtectGui(GUI) end)
Library.GUI = GUI

-- Notification module init
local NotificationModule = Components.Notification(Library)
NotificationModule:Init(GUI)

-- Expose API functions used in repo: CreateWindow, SetTheme, Destroy, ToggleAcrylic, ToggleTransparency, Notify
function Library:CreateWindow(Config)
	assert(Config.Title, "Window - Missing Title")
	if Library.Window then
		print("You cannot create more than one window.")
		return
	end
	Library.MinimizeKey = Config.MinimizeKey or Enum.KeyCode.LeftControl
	Library.UseAcrylic = Config.Acrylic or false
	Library.Acrylic = Config.Acrylic or false
	Library.Theme = Config.Theme or "Dark"
	if Config.Acrylic then Acrylic.init() end
	local Window = Components.Window({ Parent = GUI, Size = Config.Size, Title = Config.Title, SubTitle = Config.SubTitle, TabWidth = Config.TabWidth }, Library)
	Library.Window = Window
	Library:SetTheme(Config.Theme)
	return Window
end

function Library:SetTheme(Value)
	if Library.Window and table.find(Library.Themes, Value) then
		Library.Theme = Value
		Creator.UpdateTheme(Library)
	end
end

function Library:Destroy()
	if Library.Window then
		Library.Unloaded = true
		if Library.UseAcrylic and Library.Window.AcrylicPaint and Library.Window.AcrylicPaint.Model then pcall(function() Library.Window.AcrylicPaint.Model:Destroy() end) end
		Creator.Disconnect()
		Library.GUI:Destroy()
	end
end

function Library:ToggleAcrylic(Value)
	if Library.Window and Library.UseAcrylic then
		Library.Acrylic = Value
		if Library.Window.AcrylicPaint and Library.Window.AcrylicPaint.Model then
			Library.Window.AcrylicPaint.Model.Transparency = Value and 0.98 or 1
		end
		if Value then Acrylic.Enable() else Acrylic.Disable() end
	end
end

function Library:ToggleTransparency(Value)
	if Library.Window then
		if Library.Window.AcrylicPaint and Library.Window.AcrylicPaint.Frame and Library.Window.AcrylicPaint.Frame.Background then
			Library.Window.AcrylicPaint.Frame.Background.BackgroundTransparency = Value and 0.35 or 0
		end
	end
end

function Library:Notify(Config)
	return NotificationModule:New(Config)
end

-- Make global optionally
if getgenv then getgenv().Fluent = Library end

return Library
