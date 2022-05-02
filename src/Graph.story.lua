return function(coreGui)
	local TweenService = game:GetService("TweenService")

	local package = script.Parent
	local packages = package.Parent
	local Maid = require(packages:WaitForChild("maid"))

	local maid = Maid.new()

	local success, msg = pcall(function()
		local Graph = require(package)
	
		local frame = Instance.new("Frame", coreGui)
		frame.AnchorPoint = Vector2.new(0.5,0.5)
		frame.Position = UDim2.fromScale(0.5,0.5)
		frame.Size = UDim2.fromScale(0.8,0.8)
		maid:GiveTask(frame)

		local Data = {}

		for _,Style in pairs(Enum.EasingStyle:GetEnumItems()) do
			local LineData = table.create(100)
			
			for i=1, 100 do
				LineData[i] = TweenService:GetValue(i/100, Style, Enum.EasingDirection.In)
			end
			
			Data[Style.Name] = LineData
			
			task.wait() -- Prevent studio from freezing
		end

		local graph = Graph.new(frame)
		graph.Data = Data
		graph.Resolution = 100
		maid:GiveTask(graph)
	end)
	if not success then
		warn(msg)
	end
	return function ()
		maid:Destroy()
	end
end