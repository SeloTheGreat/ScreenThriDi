export type fn_SteppedCallback = {
	[number]: ((self: Component3D, dt: number) -> ()) | (boolean?) | (number?)
}

export type Screen3D = {
	partIndex: {[GuiObject]: Component3D},
	rootGui: ScreenGui,
	displayDistance: number,
	rootOffset: CFrame,

	GetComponent3D: (self: Screen3D, guiObject: GuiObject) -> Component3D?,
	
	GetRealCanvasSize: (self: Screen3D) -> Vector2,
	GetInsetCanvasSize: (self: Screen3D) -> Vector2,
	GetIntendedCanvasSize: (self: Screen3D) -> Vector2,
	GetInset: (self: Screen3D) -> Vector2
}

export type Component3D = {
	enabled: boolean,
	
	surfaceGui: SurfaceGui?,
	component2D: GuiObject?,
	
	parent2D: GuiObject?,
	screen3D: Screen3D,
	parent3D: Component3D?,

	offset: CFrame,
	viewportSize: Vector2,

	stepped: fn_SteppedCallback?,

	Enable: (self: Component3D, stepped: fn_SteppedCallback?) -> (Component3D),
	Disable: (self: Component3D) -> (Component3D),
	
	RecomputeParent: (self: Component3D) -> (Component3D),
	
	GetStudsScreenSize: (self: Component3D, viewportSize: Vector2) -> (Vector3),
	ReadWorldCFrame: (self: Component3D) -> (CFrame),
	UDim2ToCFrame: (self: Component3D, position2D: UDim2) -> (CFrame),
	--AbsoluteUDim2ToCFrame: (component3D, position2D: UDim2) -> CFrame,
	
	GetViewportSize: (self: Component3D) -> Vector2
}

return nil
