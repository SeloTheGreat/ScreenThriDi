--!strict
--!native
--!optimize 2

local types = require("./types")
local process = require("./Process")

local function _pivot(original: CFrame, pivot: CFrame, angle: CFrame): CFrame
	return original:Inverse() * pivot * angle * pivot:Inverse() * original
end

local function component_Enable(self: types.Component3D, stepped: types.fn_SteppedCallback?): types.Component3D
	if self.enabled or not self.component2D then
		return self
	end	

	self.enabled = true

	local surfaceGui = Instance.new("SurfaceGui")
	local surfacePart = Instance.new("Part")

	surfacePart.CanCollide = false
	surfacePart.Anchored = true
	surfacePart.Parent = surfaceGui

	surfaceGui.Parent = self.parent2D or self.screen3D.rootGui
	surfaceGui.Face =  Enum.NormalId.Back
	surfaceGui.Adornee = surfacePart
	surfaceGui.AlwaysOnTop = true

	self.surfaceGui = surfaceGui

	self.component2D.Parent = self.surfaceGui

	--self:RecomputeParent()

	self.stepped = stepped
	process(self)

	return self
end

local function component_Disable(self: types.Component3D): types.Component3D
	if not self.enabled then
		return self
	end

	process(self)

	self.enabled = false

	if self.component2D then
		self.component2D.Parent = self.parent2D or self.screen3D.rootGui
	end

	if self.surfaceGui then
		self.surfaceGui:Destroy()
	end

	return self
end

local function component_RecomputeParent(self: types.Component3D): types.Component3D
	if self.parent2D and self.parent2D:IsA("GuiObject") then
		self.parent3D = self.screen3D:GetComponent3D(self.parent2D)
	end

	if self.surfaceGui then
		local parent = self.parent3D
		local zIndex = 0

		while parent do
			zIndex += 1
			parent = parent.parent3D
		end

		self.surfaceGui.ZOffset = zIndex
	end

	return self
end

local function component_GetStudsScreenSize(self: types.Component3D, viewportSize: Vector2): Vector3
	local trueSize =  self.screen3D:GetRealCanvasSize()

	local currentCamera = workspace.CurrentCamera
	local factor = math.tan(math.rad(currentCamera.FieldOfView)/2)

	return Vector3.new(
		(trueSize.X / trueSize.Y) * factor * (viewportSize.X / trueSize.X),
		factor  * (viewportSize.Y / trueSize.Y),
		0
	) * self.screen3D.displayDistance
end

local function component_UDim2ToCFrame(self: types.Component3D, position: UDim2): CFrame
	if not self.component2D then
		return CFrame.identity
	end

	local scaleX, scaleY = position.X.Scale, position.Y.Scale
	local offsetX, offsetY = position.X.Offset, position.Y.Offset

	local viewSize = self:GetViewportSize()

	local trueScaleX, trueScaleY = (scaleX +  offsetX / viewSize.X), (scaleY + offsetY / viewSize.Y)

	local partSize = self:GetStudsScreenSize(viewSize)

	return CFrame.new(
		(partSize.X) * (trueScaleX - 0.5),
		-(partSize.Y) * (trueScaleY - 0.5),
		0
	)
end

local function component_GetViewportSize(self: types.Component3D): Vector2
	if self.parent3D and self.parent3D.component2D then
		return self.parent3D.component2D.AbsoluteSize
	end

	return self.screen3D:GetIntendedCanvasSize()
end

local function component_ReadWorldCFrame(self: types.Component3D): CFrame
	if not self.component2D then
		return CFrame.identity
	end

	self:RecomputeParent()

	local originalCFrame, udimPos, addedPosition

	local udimMax = self:UDim2ToCFrame(UDim2.fromScale(1, 1))

	if self.parent3D then
		if not self.parent3D.component2D or not self.parent2D then
			return CFrame.identity
		end

		local anchorPoint = self.parent3D.component2D.AnchorPoint

		originalCFrame = self.parent3D:ReadWorldCFrame()
		udimPos = self.parent3D.component2D.Position

		local anchorFrame = self:UDim2ToCFrame(UDim2.fromScale(-anchorPoint.X + 0.5, -anchorPoint.Y + 0.5))

		addedPosition = self.parent3D:UDim2ToCFrame(udimPos)
			* udimMax
			* anchorFrame
			* CFrame.Angles(0, 0, -math.rad(self.parent2D.Rotation))
	else
		local viewportDiff = self.screen3D:GetRealCanvasSize() - self.screen3D:GetIntendedCanvasSize()

		originalCFrame = workspace.CurrentCamera.CFrame * CFrame.new(0,0,-(self.screen3D.displayDistance)/2 ) * self.screen3D.rootOffset
		udimPos = UDim2.new(0,viewportDiff.X/2,0,viewportDiff.Y/2)
		addedPosition = self:UDim2ToCFrame(udimPos) * self:UDim2ToCFrame(UDim2.fromScale(1, 1))
	end

	local finalCFrame = originalCFrame * addedPosition

	local finalPivot = finalCFrame
		* udimMax:Inverse()
		* self:UDim2ToCFrame(self.component2D.Position)
		* udimMax

	return finalCFrame * _pivot(finalCFrame, finalPivot, self.offset)
end

local class = {}

function class.new(guiObject: GuiObject, screen3D: types.Screen3D): types.Component3D
	local self: types.Component3D = {
		enabled = false,

		component2D = guiObject,
		surfaceGui = nil,

		parent3D = nil,
		screen3D = screen3D,

		offset = CFrame.identity,
		viewportSize = screen3D:GetIntendedCanvasSize(),

		Enable = component_Enable,
		Disable = component_Disable,

		RecomputeParent = component_RecomputeParent,

		GetStudsScreenSize = component_GetStudsScreenSize,
		ReadWorldCFrame = component_ReadWorldCFrame,
		UDim2ToCFrame = component_UDim2ToCFrame,
		GetViewportSize = component_GetViewportSize
	}

	self.viewportSize = component_GetViewportSize(self)

	if guiObject.Parent and guiObject.Parent:IsA("GuiObject") then
		self.parent2D = guiObject.Parent
	end

	return self
end

return class
