--!strict
--!optimize 2

local GuiService = game:GetService("GuiService")

local Component3D = require("@self/Component3D")
local types = require("@self/types")

local LOUD_CREDIT = true

local function screen_GetRealCanvasSize(self: types.Screen3D): Vector2
	return workspace.CurrentCamera.ViewportSize
end

local function screen_GetInset(self: types.Screen3D): Vector2
	return GuiService:GetGuiInset()
end

local function screen_GetInsetCanvasSize(self: types.Screen3D): Vector2
	return self:GetRealCanvasSize() - self:GetInset()
end

local function screen_GetIntendedCanvasSize(self: types.Screen3D): Vector2
	if self.rootGui.IgnoreGuiInset then
		return self:GetRealCanvasSize()
	end
	
	return self:GetInsetCanvasSize()
end

local function screen_GetComponent3D(self: types.Screen3D, guiObject: GuiObject): types.Component3D
	return self.partIndex[guiObject]
end

local screenGen = {}

--Used with <code>Component3D:Enable(a)</code>
function screenGen.createStepped(fn: (self: types.Component3D, dt: number) -> (), async: boolean?, rate: number?): types.fn_SteppedCallback
	return { fn, async, rate, rate and os.clock() }
end

function screenGen.new(screenGui: ScreenGui, displayDistance: number): types.Screen3D
	local partIndex = {}

	local self = {
		partIndex = partIndex,
		rootGui = screenGui,
		displayDistance = displayDistance,
		rootOffset = CFrame.identity,

		GetComponent3D = screen_GetComponent3D,
	
		GetRealCanvasSize = screen_GetRealCanvasSize,
		GetInsetCanvasSize = screen_GetInsetCanvasSize,
		GetIntendedCanvasSize = screen_GetIntendedCanvasSize,
		GetInset = screen_GetInset,
	}

	for _, guiobj in screenGui:GetDescendants() do
		if guiobj:IsA("GuiObject") then
			partIndex[guiobj] = Component3D.new(guiobj, self)
		end
	end

	screenGui.DescendantAdded:Connect(function(addedObj: Instance)
		if addedObj:IsA("GuiObject") then
			partIndex[addedObj] = Component3D.new(addedObj, self)
		end
	end)

	return self
end

if LOUD_CREDIT then
	print("ScreenThriDi loaded, learn more on [link or something]")
end

return screenGen
