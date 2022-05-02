--[=[

Docs: https://devforum.roblox.com/t/graph-module-easily-draw-graphs-of-your-data/828982

API:

function Graph.new(Frame)
	returns a GraphHandler
	
self.Resolution = The number of points it renders
self.BaselineZero = Whether the bottom of the graph should start at zero (or at the minimum value)
self.Data = The dictionary of data sets
	(Data must be a dictionary of arrays with no holes)
	
function self:SetTheme(ThemeDictionary)
	Updates the Colors of the graph

--]=]
local TextService = game:GetService("TextService")

local packages = script.Parent
local Maid = require(packages:WaitForChild("maid"))

local Theme = {
	Name = "Dark";	
	Background = Color3.fromRGB(35,35,40);
	LightBackground = Color3.fromRGB(45,45,50);
	Text = Color3.fromRGB(220,220,230)
}
local isDark = true

local function getKeyColor(name)
	-- Shoutout to Vocksel for the core of this function
	
	local seed = 0
	for i=1, #name do
		seed = seed + (name:byte(i))
	end
	local rng = Random.new(seed)
	local hue = rng:NextInteger(0,50)/50

	return Color3.fromHSV(hue, isDark and 0.63 or 1, isDark and 0.84 or 0.8)
end

local Graph = {}
Graph.__index = Graph

function Graph:Destroy()
	-- print("Destroy")
	self._Maid:Destroy()
end

function Graph:__newindex(Key, Value)
	if Key == "Data" and type(Value) == "table" then
		rawset(self, "Data", Value)
		self:Render()
	elseif Key == "Resolution" and type(Value) == "number" then
		rawset(self, "Resolution", Value)
		self:Render()
	elseif Key == "BaselineZero" and type(Value) == "boolean" then
		rawset(self, "BaselineZero", Value)
		self:Render()
	elseif Key == "Theme" and type(Value) == "table" then
		rawset(self, "Theme", Value)
		self.Background.BackgroundColor3 = self.Theme.Background
		self.MarkerBG.BackgroundColor3 = self.Theme.LightBackground
		self.KeyNames.BackgroundColor3 = self.Theme.LightBackground
		self:Render()
	end
end

function Graph:Render()
	-- Validate we have stuff to render
	if not self.Frame or not self.Data or not self.Resolution then
		return
	end
	
	while self._Busy do task.wait(0.1) end
	self._Busy = true
	
	-- Clear old graph values
	self.YMarkers:ClearAllChildren()
	self.GraphingFrame:ClearAllChildren()
	self.KeyNames:ClearAllChildren()
	
	local KeyLayout = Instance.new("UIListLayout")
	KeyLayout.FillDirection = Enum.FillDirection.Horizontal
	KeyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	KeyLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	KeyLayout.Padding = UDim.new(0.01,0)
	KeyLayout.Parent = self.KeyNames
	
	local Max, Min = -math.huge,math.huge
	local Range
	
	-- Calculate our range of values

	for Key, Set in pairs(self.Data) do
		local SetAmount = #Set

		for i=1,SetAmount, math.ceil(SetAmount/self.Resolution) do
			local SortedChunk = {}
			for x=i,i+math.ceil(SetAmount/self.Resolution) do
				SortedChunk[#SortedChunk+1] = Set[x]
			end
			table.sort(SortedChunk)

			local Value = SortedChunk[math.round(#SortedChunk*0.55)]
			if not Value then continue end

			-- Record for our range calc
			Min = math.min(Min, Value)
			Max = math.max(Max, Value)
		end
	end
	
	if self.BaselineZero then
		Min = 0
		Max = Max * 1.75
	end

	Range = Max-Min
	
	-- Mark our Y axis values along the derived range
	
	for y=0,1,0.2 do
		local Marker = Instance.new("TextLabel")
		Marker.Name = y
		Marker.Size = UDim2.new(1,0,0.08,0)
		Marker.AnchorPoint = Vector2.new(0,0.5)
		Marker.Position = UDim2.new(0,0,0.9 - (y*0.9),0)
		Marker.Text = string.format("%.2f  ",(Min + (Range*y)))
		Marker.TextXAlignment = Enum.TextXAlignment.Right

		Marker.TextColor3 = Theme.Text
		Marker.Font = Enum.Font.SourceSans
		Marker.BackgroundTransparency = 1
		Marker.TextSize = (self.Frame.AbsoluteSize.X*0.03)
		Marker.ZIndex = 6
		Marker.Parent = self.YMarkers
	end
	
	-- Draw the graph at this range
	local KeyColors = {}
	for Key, Set in pairs(self.Data) do
		-- Designate a color for this dataset
		KeyColors[Key] = getKeyColor(Key)
		
		local TextSize = self.Frame.AbsoluteSize.Y*0.08
		local AbsTextSize = TextService:GetTextSize(Key, TextSize, Enum.Font.SourceSansSemibold, self.KeyNames.AbsoluteSize)
		local KeyMarker = Instance.new("TextLabel")
		KeyMarker.Text = Key
		KeyMarker.TextColor3 = KeyColors[Key]
		KeyMarker.Font = Enum.Font.SourceSansSemibold
		KeyMarker.BackgroundTransparency = 1
		KeyMarker.TextSize = TextSize
		KeyMarker.Size = UDim2.new(0,AbsTextSize.X+TextSize,1,0)
		KeyMarker.Parent = self.KeyNames
		
		-- Graph the set

		local SetAmount = #Set
		local LastPoint

		--print("  "..Key, Set)

		for i=1,SetAmount, math.ceil(SetAmount/self.Resolution) do

			local SortedChunk = {}
			for x=i,i+math.ceil(SetAmount/self.Resolution) do
				SortedChunk[#SortedChunk+1] = Set[x]
			end
			table.sort(SortedChunk)

			local Value = SortedChunk[math.round(#SortedChunk*0.55)]
			if not Value then continue end

			-- Create the point
			local Point = Instance.new("ImageLabel")
			Point.Name = Key..i
			Point.Position = UDim2.new(0.05+((i/SetAmount)*0.9),0, 0.9 - (((Value-Min)/Range)*0.9),0)
			Point.AnchorPoint = Vector2.new(0.5,0.5)
			Point.SizeConstraint = Enum.SizeConstraint.RelativeXX
			Point.Size = UDim2.new(math.clamp(0.5/self.Resolution, 0.003,0.016),0,math.clamp(0.5/self.Resolution, 0.003,0.016),0)

			Point.ImageColor3 = KeyColors[Key]
			Point.BorderSizePixel = 0
			Point.BackgroundTransparency = 1
			Point.Image = "rbxassetid://200182847"
			Point.ZIndex = 15

			local Label = Instance.new("TextLabel")
			Label.Visible = false
			Label.Text = string.format("%.7f",Value)
			Label.BackgroundColor3 = Theme.LightBackground
			Label.TextColor3 = Theme.Text
			Label.Position = UDim2.new(1,0,0.4,0)
			Label.Font = Enum.Font.Code
			Label.TextSize = (self.Frame.AbsoluteSize.X*0.025)
			Label.Size = UDim2.new(0,Label.TextSize * 0.6 * #Label.Text,0,Label.TextSize * 1.1)
			Label.Parent = Point
			Label.ZIndex = 20

			Point.MouseEnter:Connect(function()
				Label.Visible = true
			end)
			Point.MouseLeave:Connect(function()
				Label.Visible = false
			end)

			-- Create the line
			if LastPoint then
				local Connector = Instance.new("Frame")
				Connector.Name = Key..i.."-"..i-1
				Connector.BackgroundColor3 = KeyColors[Key]
				Connector.BorderSizePixel = 0
				Connector.SizeConstraint = Enum.SizeConstraint.RelativeXX
				Connector.AnchorPoint = Vector2.new(0.5, 0.5)

				local Size = self.GraphingFrame.AbsoluteSize
				local startX, startY = Point.Position.X.Scale*Size.X, Point.Position.Y.Scale*Size.Y
				local endX, endY = LastPoint.Position.X.Scale*Size.X, LastPoint.Position.Y.Scale*Size.Y

				local Distance = (Vector2.new(startX, startY) - Vector2.new(endX, endY)).Magnitude

				Connector.Size = UDim2.new(0, Distance, math.clamp(0.2/self.Resolution, 0.002,0.0035), 0)
				Connector.Position = UDim2.new(0, (startX + endX) / 2, 0, (startY + endY) / 2)
				Connector.Rotation = math.atan2(endY - startY, endX - startX) * (180 / math.pi)

				Connector.Parent = self.GraphingFrame
			end

			LastPoint = Point
			Point.Parent = self.GraphingFrame

		end

	end
	
	self._Busy = false
end

function Graph.new(Frame)
	if not Frame then error("Must give graph a frame") end
	local self = {
		Frame = Frame,
		Resolution = 75,
		_Maid = Maid.new(),
		_Busy = false,
	}

	-- Create the GUIs
	local Background = Instance.new("Frame")
	Background.Name = "Background"
	Background.BackgroundColor3 = Theme.Background
	Background.Size = UDim2.new(1,0,1,0)
	Background.Parent = self.Frame
	self.Background = Background
	self._Maid:GiveTask(Background)

	local MarkerBG = Instance.new("Frame")
	MarkerBG.Name = "MarkerBackground"
	MarkerBG.Size = UDim2.new(0.1,0,1,0)
	MarkerBG.BackgroundColor3 = Theme.LightBackground
	MarkerBG.BorderSizePixel = 0
	MarkerBG.ZIndex = 1
	MarkerBG.Parent = self.Frame
	self.MarkerBG = MarkerBG
	self._Maid:GiveTask(MarkerBG)

	local YMarkers = Instance.new("Frame")
	YMarkers.Name = "Markers"
	YMarkers.Size = UDim2.new(0.1,0,0.85,0)
	YMarkers.Position = UDim2.new(0,0,0.15,0)
	YMarkers.BackgroundTransparency = 1
	YMarkers.BorderSizePixel = 0
	YMarkers.ZIndex = 2
	YMarkers.Parent = self.Frame
	self.YMarkers = YMarkers
	self._Maid:GiveTask(YMarkers)

	local GraphingFrame = Instance.new("Frame")
	GraphingFrame.Name = "GraphingFrame"
	GraphingFrame.Size = UDim2.new(0.9,0,0.85,0)
	GraphingFrame.Position = UDim2.new(0.1,0,0.15,0)
	GraphingFrame.BackgroundTransparency = 1
	GraphingFrame.ZIndex = 4
	GraphingFrame.Parent = self.Frame
	self.GraphingFrame = GraphingFrame
	self._Maid:GiveTask(GraphingFrame)

	local KeyNames = Instance.new("Frame")
	KeyNames.Name = "KeyNames"
	KeyNames.Size = UDim2.new(1,0,0.1,0)
	KeyNames.Position = UDim2.new(0,0,0,0)
	KeyNames.BackgroundColor3 = Theme.LightBackground
	KeyNames.BorderSizePixel = 0
	KeyNames.ZIndex = 4
	KeyNames.Parent = self.Frame
	self.KeyNames = KeyNames
	self._Maid:GiveTask(KeyNames)

	-- Rerender if the frame changes size since our lines will be all wonky
	self._Maid:GiveTask(self.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local Size = self.Frame.AbsoluteSize
		task.wait(0.04)
		if Size == self.Frame.AbsoluteSize then
			self:Render()
		end
	end))

	setmetatable(self, Graph)
	return self
end


return Graph