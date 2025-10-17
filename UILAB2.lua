

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local UILib = {}
UILib.Flags = {}
UILib.Configs = {}

-- utils
local function safe(f, ...)
	local ok, res = pcall(f, ...)
	if not ok then warn("[UILib Error]:", res) end
	return res
end

local function makeFolder(path)
	if not isfolder(path) then
		makefolder(path)
	end
end

local function readConfig(path)
	if not isfile(path) then return {} end
	local data = readfile(path)
	local ok, json = pcall(HttpService.JSONDecode, HttpService, data)
	return ok and json or {}
end

local function writeConfig(path, data)
	local ok, json = pcall(HttpService.JSONEncode, HttpService, data)
	if ok then
		writefile(path, json)
	end
end

-- draggable helper
local function makeDraggable(obj, dragHandle)
	local UIS = game:GetService("UserInputService")
	local dragging = false
	local dragInput, dragStart, startPos

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = obj.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- CORE UI CREATION
function UILib:MakeWindow(opts)
	opts = opts or {}
	local windowName = opts.Name or "Window"
	local saveConfig = opts.SaveConfig or false
	local configFolder = opts.ConfigFolder or "Default"
	local configPath = "OrionConfig/"..configFolder.."/MainConfig.json"

	if saveConfig then
		makeFolder("OrionConfig")
		makeFolder("OrionConfig/"..configFolder)
		UILib.Configs = readConfig(configPath)
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "UILibGui"
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = PG

	local group = Instance.new("Frame")
	group.Name = "MainGroup"
	group.Size = UDim2.new(0, 960, 0, 540)
	group.Position = UDim2.new(0.2, 0, 0.2, 0)
	group.BackgroundTransparency = 1
	group.Parent = gui

	-- left bar
	local left = Instance.new("Frame")
	left.Name = "LeftBar"
	left.Size = UDim2.new(0, 200, 0, 540)
	left.BackgroundColor3 = Color3.fromRGB(6,6,6)
	left.BackgroundTransparency = 0.1
	left.BorderSizePixel = 0
	left.Parent = group

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 60)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Creepster
	title.Text = windowName
	title.TextColor3 = Color3.new(1,1,1)
	title.TextSize = 40
	title.Parent = left

	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.BackgroundTransparency = 1
	tabBar.Size = UDim2.new(1, 0, 1, -60)
	tabBar.Position = UDim2.new(0, 0, 0, 60)
	tabBar.Parent = left
	local tabLayout = Instance.new("UIListLayout", tabBar)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 8)
	local tabPad = Instance.new("UIPadding", tabBar)
	tabPad.PaddingTop = UDim.new(0, 8)
	tabPad.PaddingLeft = UDim.new(0, 8)

	-- main content
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(1, -200, 1, 0)
	main.Position = UDim2.new(0, 200, 0, 0)
	main.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
	main.BorderSizePixel = 0
	main.Parent = group

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1, -20, 1, -20)
	scroll.Position = UDim2.new(0, 10, 0, 10)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.Parent = main

	local tabFolder = Instance.new("Folder")
	tabFolder.Name = "Tabs"
	tabFolder.Parent = scroll

	local Window = {}
	Window._gui = gui
	Window._group = group
	Window._tabBar = tabBar
	Window._tabFolder = tabFolder
	Window._tabs = {}
	Window._currentTab = nil
	Window._configPath = configPath
	Window._saveConfig = saveConfig

	-- hide/show with F1
	UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.F1 then
			gui.Enabled = not gui.Enabled
		end
	end)

	-- drag main
	makeDraggable(group, left)

	function Window:Destroy()
		gui:Destroy()
	end

	function Window:MakeNotification(data)
		local msg = Instance.new("TextLabel")
		msg.Parent = gui
		msg.BackgroundColor3 = Color3.fromRGB(0,0,0)
		msg.BackgroundTransparency = 0.3
		msg.Size = UDim2.new(0, 300, 0, 60)
		msg.Position = UDim2.new(0.5, -150, 0.1, 0)
		msg.Font = Enum.Font.GothamBold
		msg.TextColor3 = Color3.new(1,1,1)
		msg.TextSize = 18
		msg.Text = data.Name.."\n"..(data.Content or "")
		msg.TextWrapped = true
		msg.TextYAlignment = Enum.TextYAlignment.Center
		msg.TextXAlignment = Enum.TextXAlignment.Center
		Instance.new("UICorner", msg).CornerRadius = UDim.new(0, 10)
		local tween = Tween:Create(msg, TweenInfo.new(0.3), {BackgroundTransparency = 0})
		tween:Play()
		task.wait(data.Time or 3)
		Tween:Create(msg, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		task.wait(0.3)
		msg:Destroy()
	end

		-- CREATE TAB
	function Window:MakeTab(tabData)
		tabData = tabData or {}
		local tabName = tabData.Name or "Tab"
		local icon = tabData.Icon or nil

		-- кнопка во вкладках
		local tabButton = Instance.new("TextButton")
		tabButton.Name = "Tab_" .. tabName
		tabButton.Size = UDim2.new(1, -16, 0, 36)
		tabButton.BackgroundTransparency = 1
		tabButton.Text = tabName
		tabButton.Font = Enum.Font.GothamBold
		tabButton.TextSize = 16
		tabButton.TextColor3 = Color3.fromRGB(220,220,220)
		tabButton.AutoButtonColor = false
		tabButton.Parent = self._tabBar

		-- страница вкладки
		local tabPage = Instance.new("Frame")
		tabPage.Name = tabName
		tabPage.Visible = false
		tabPage.BackgroundTransparency = 1
		tabPage.Size = UDim2.new(1,0,1,0)
		tabPage.Parent = self._tabFolder

		-- layout секций
		local grid = Instance.new("UIGridLayout")
		grid.CellSize = UDim2.new(0, 320, 0, 360)
		grid.CellPadding = UDim2.new(0, 16, 0, 16)
		grid.FillDirectionMaxCells = 2
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = tabPage

		self._tabs[tabName] = {
			Page = tabPage,
			Button = tabButton,
			Sections = {}
		}

		tabButton.MouseButton1Click:Connect(function()
			for _,t in pairs(self._tabs) do
				t.Page.Visible = false
				t.Button.TextColor3 = Color3.fromRGB(220,220,220)
			end
			tabPage.Visible = true
			tabButton.TextColor3 = Color3.fromRGB(255,170,0)
			self._currentTab = self._tabs[tabName]
		end)

		if not self._currentTab then
			tabPage.Visible = true
			tabButton.TextColor3 = Color3.fromRGB(255,170,0)
			self._currentTab = self._tabs[tabName]
		end

		local Tab = {}
		Tab._window = self
		Tab._tab = self._tabs[tabName]

		-- создание секции
		function Tab:AddSection(secData)
			secData = secData or {}
			local secName = secData.Name or "Section"

			local secFrame = Instance.new("Frame")
			secFrame.Name = secName
			secFrame.Size = UDim2.new(0, 320, 0, 360)
			secFrame.BackgroundColor3 = Color3.fromRGB(16,16,16)
			secFrame.BorderSizePixel = 0
			secFrame.Parent = Tab._tab.Page
			Instance.new("UICorner", secFrame).CornerRadius = UDim.new(0, 8)

			local header = Instance.new("TextLabel")
			header.Name = "Header"
			header.BackgroundTransparency = 1
			header.Size = UDim2.new(1, -20, 0, 30)
			header.Position = UDim2.new(0, 10, 0, 6)
			header.Font = Enum.Font.GothamBold
			header.TextColor3 = Color3.fromRGB(255,170,0)
			header.TextSize = 18
			header.TextXAlignment = Enum.TextXAlignment.Left
			header.Text = secName
			header.Parent = secFrame

			local body = Instance.new("Frame")
			body.Name = "Body"
			body.Size = UDim2.new(1, -20, 1, -46)
			body.Position = UDim2.new(0, 10, 0, 40)
			body.BackgroundColor3 = Color3.fromRGB(10,10,10)
			body.BorderSizePixel = 0
			body.Parent = secFrame
			Instance.new("UICorner", body).CornerRadius = UDim.new(0, 6)

			local layout = Instance.new("UIListLayout")
			layout.Padding = UDim.new(0, 8)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Parent = body

			local padding = Instance.new("UIPadding")
			padding.PaddingTop = UDim.new(0, 8)
			padding.PaddingLeft = UDim.new(0, 10)
			padding.PaddingRight = UDim.new(0, 10)
			padding.PaddingBottom = UDim.new(0, 8)
			padding.Parent = body

			local Section = {}
			Section._tab = Tab
			Section._window = self
			Section._body = body
			Section._flags = {}

			table.insert(Tab._tab.Sections, Section)

			-- функции добавления элементов (реализуются дальше)
			function Section:AddLabel(text)
				local lbl = Instance.new("TextLabel")
				lbl.Name = "Label"
				lbl.Size = UDim2.new(1,0,0,24)
				lbl.BackgroundTransparency = 1
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 16
				lbl.TextColor3 = Color3.fromRGB(220,220,220)
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Text = text or "Label"
				lbl.Parent = body
			end

			return Section
		end

		return Tab
	end

	return Window
end

return UILib

			-- BUTTON
			function Section:AddButton(data)
				data = data or {}
				local btn = Instance.new("TextButton")
				btn.Name = data.Name or "Button"
				btn.Size = UDim2.new(1, 0, 0, 32)
				btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
				btn.BorderSizePixel = 0
				btn.Font = Enum.Font.GothamSemibold
				btn.TextSize = 15
				btn.TextColor3 = Color3.fromRGB(255,255,255)
				btn.Text = data.Name or "Button"
				btn.AutoButtonColor = false
				btn.Parent = self._body
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

				btn.MouseEnter:Connect(function()
					Tween:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40,40,40)}):Play()
				end)
				btn.MouseLeave:Connect(function()
					Tween:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(20,20,20)}):Play()
				end)
				btn.MouseButton1Click:Connect(function()
					Tween:Create(btn, TweenInfo.new(0.05), {BackgroundColor3 = Color3.fromRGB(255,170,0)}):Play()
					task.wait(0.1)
					Tween:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20,20,20)}):Play()
					if data.Callback then safe(data.Callback) end
				end)
			end

			-- TOGGLE
			function Section:AddToggle(data)
				data = data or {}
				local holder = Instance.new("Frame")
				holder.Name = data.Name or "Toggle"
				holder.Size = UDim2.new(1, 0, 0, 28)
				holder.BackgroundTransparency = 1
				holder.Parent = self._body

				local name = Instance.new("TextLabel")
				name.Size = UDim2.new(1, -50, 1, 0)
				name.BackgroundTransparency = 1
				name.Font = Enum.Font.Gotham
				name.TextSize = 16
				name.TextColor3 = Color3.fromRGB(230,230,230)
				name.TextXAlignment = Enum.TextXAlignment.Left
				name.Text = data.Name or "Toggle"
				name.Parent = holder

				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(0, 42, 0, 20)
				btn.Position = UDim2.new(1, -42, 0.5, -10)
				btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
				btn.Text = ""
				btn.AutoButtonColor = false
				btn.BorderSizePixel = 0
				btn.Parent = holder
				Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

				local knob = Instance.new("Frame")
				knob.Size = UDim2.new(0, 18, 0, 18)
				knob.Position = UDim2.new(0, 1, 0.5, -9)
				knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
				knob.BorderSizePixel = 0
				knob.Parent = btn
				Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

				local state = data.Default or false
				local function render()
					if state then
						Tween:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255,170,0)}):Play()
						Tween:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(1, -19, 0.5, -9)}):Play()
					else
						Tween:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35,35,35)}):Play()
						Tween:Create(knob, TweenInfo.new(0.15), {Position = UDim2.new(0, 1, 0.5, -9)}):Play()
					end
				end
				render()

				btn.MouseButton1Click:Connect(function()
					state = not state
					render()
					if data.Callback then safe(data.Callback, state) end
					if self._window._saveConfig then
						UILib.Configs[data.Name] = state
						writeConfig(self._window._configPath, UILib.Configs)
					end
				end)
			end

			-- SLIDER
			function Section:AddSlider(data)
				data = data or {}
				local min, max, default = data.Min or 0, data.Max or 100, data.Default or 0

				local holder = Instance.new("Frame")
				holder.Name = data.Name or "Slider"
				holder.Size = UDim2.new(1, 0, 0, 46)
				holder.BackgroundTransparency = 1
				holder.Parent = self._body

				local name = Instance.new("TextLabel")
				name.Size = UDim2.new(1, 0, 0, 20)
				name.BackgroundTransparency = 1
				name.Font = Enum.Font.Gotham
				name.TextSize = 16
				name.TextColor3 = Color3.fromRGB(230,230,230)
				name.TextXAlignment = Enum.TextXAlignment.Left
				name.Text = data.Name or "Slider"
				name.Parent = holder

				local val = Instance.new("TextLabel")
				val.Size = UDim2.new(0, 60, 0, 20)
				val.Position = UDim2.new(1, -60, 0, 0)
				val.BackgroundTransparency = 1
				val.Font = Enum.Font.Gotham
				val.TextSize = 14
				val.TextColor3 = Color3.fromRGB(230,230,230)
				val.TextXAlignment = Enum.TextXAlignment.Right
				val.Parent = holder

				local bar = Instance.new("Frame")
				bar.Size = UDim2.new(1, 0, 0, 8)
				bar.Position = UDim2.new(0, 0, 0, 28)
				bar.BackgroundColor3 = Color3.fromRGB(30,30,30)
				bar.BorderSizePixel = 0
				bar.Parent = holder
				Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

				local fill = Instance.new("Frame", bar)
				fill.BackgroundColor3 = Color3.fromRGB(255,170,0)
				fill.BorderSizePixel = 0
				fill.Size = UDim2.new(0,0,1,0)
				Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

				local knob = Instance.new("Frame", bar)
				knob.Size = UDim2.new(0, 14, 0, 14)
				knob.Position = UDim2.new(0, -7, 0.5, -7)
				knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
				knob.BorderSizePixel = 0
				Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

				local value = default
				local dragging = false
				local function update(x)
					local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
					value = math.floor((min + rel * (max - min)) * (data.Increment or 1)) / (data.Increment or 1)
					fill.Size = UDim2.new(rel, 0, 1, 0)
					knob.Position = UDim2.new(rel, -7, 0.5, -7)
					val.Text = tostring(value)
					if data.Callback then safe(data.Callback, value) end
					if self._window._saveConfig then
						UILib.Configs[data.Name] = value
						writeConfig(self._window._configPath, UILib.Configs)
					end
				end
				update(bar.AbsolutePosition.X)

				bar.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						update(i.Position.X)
					end
				end)
				UIS.InputChanged:Connect(function(i)
					if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
						update(i.Position.X)
					end
				end)
				UIS.InputEnded:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
					end
				end)
			end

			-- DROPDOWN
			function Section:AddDropdown(data)
				data = data or {}
				local holder = Instance.new("Frame")
				holder.Name = data.Name or "Dropdown"
				holder.Size = UDim2.new(1, 0, 0, 30)
				holder.BackgroundTransparency = 1
				holder.Parent = self._body

				local name = Instance.new("TextLabel")
				name.Size = UDim2.new(1, -130, 1, 0)
				name.BackgroundTransparency = 1
				name.Font = Enum.Font.Gotham
				name.TextSize = 16
				name.TextColor3 = Color3.fromRGB(230,230,230)
				name.TextXAlignment = Enum.TextXAlignment.Left
				name.Text = data.Name or "Dropdown"
				name.Parent = holder

				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(0, 120, 0, 26)
				btn.Position = UDim2.new(1, -120, 0.5, -13)
				btn.BackgroundColor3 = Color3.fromRGB(25,25,25)
				btn.Font = Enum.Font.Gotham
				btn.TextSize = 14
				btn.TextColor3 = Color3.fromRGB(255,255,255)
				btn.Text = data.Default or (data.List and data.List[1]) or ""
				btn.AutoButtonColor = false
				btn.BorderSizePixel = 0
				btn.Parent = holder
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

				local menu = Instance.new("Frame")
				menu.Visible = false
				menu.Size = UDim2.new(0, 120, 0, (#data.List * 24) + 8)
				menu.Position = UDim2.new(1, -120, 1, 4)
				menu.BackgroundColor3 = Color3.fromRGB(15,15,15)
				menu.BorderSizePixel = 0
				menu.Parent = holder
				Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 6)

				local list = Instance.new("UIListLayout", menu)
				list.Padding = UDim.new(0, 4)
				local pad = Instance.new("UIPadding", menu)
				pad.PaddingTop = UDim.new(0, 4)
				pad.PaddingLeft = UDim.new(0, 4)
				pad.PaddingRight = UDim.new(0, 4)
				pad.PaddingBottom = UDim.new(0, 4)

				local current = btn.Text
				for _,v in ipairs(data.List or {}) do
					local o = Instance.new("TextButton")
					o.Size = UDim2.new(1, 0, 0, 20)
					o.BackgroundColor3 = Color3.fromRGB(30,30,30)
					o.BorderSizePixel = 0
					o.Font = Enum.Font.Gotham
					o.TextSize = 14
					o.TextColor3 = Color3.fromRGB(255,255,255)
					o.Text = v
					o.Parent = menu
					Instance.new("UICorner", o).CornerRadius = UDim.new(0, 4)
					o.MouseButton1Click:Connect(function()
						current = v
						btn.Text = v
						menu.Visible = false
						if data.Callback then safe(data.Callback, v) end
						if self._window._saveConfig then
							UILib.Configs[data.Name] = v
							writeConfig(self._window._configPath, UILib.Configs)
						end
					end)
				end

				btn.MouseButton1Click:Connect(function()
					menu.Visible = not menu.Visible
				end)
			end

			-- KEYBIND
			function Section:AddKeybind(data)
				data = data or {}
				local holder = Instance.new("Frame")
				holder.Name = data.Name or "Keybind"
				holder.Size = UDim2.new(1, 0, 0, 30)
				holder.BackgroundTransparency = 1
				holder.Parent = self._body

				local name = Instance.new("TextLabel")
				name.Size = UDim2.new(1, -120, 1, 0)
				name.BackgroundTransparency = 1
				name.Font = Enum.Font.Gotham
				name.TextSize = 16
				name.TextColor3 = Color3.fromRGB(230,230,230)
				name.TextXAlignment = Enum.TextXAlignment.Left
				name.Text = data.Name or "Keybind"
				name.Parent = holder

				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(0, 100, 0, 26)
				btn.Position = UDim2.new(1, -100, 0.5, -13)
				btn.BackgroundColor3 = Color3.fromRGB(25,25,25)
				btn.Font = Enum.Font.Gotham
				btn.TextSize = 14
				btn.TextColor3 = Color3.fromRGB(255,255,255)
				btn.Text = "["..((data.Default and data.Default.Name) or "None").."]"
				btn.AutoButtonColor = false
				btn.BorderSizePixel = 0
				btn.Parent = holder
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

				local binding = false
				local key = data.Default or Enum.KeyCode.None
				btn.MouseButton1Click:Connect(function()
					binding = true
					btn.Text = "[Press...]"
				end)
				UIS.InputBegan:Connect(function(i, g)
					if g then return end
					if binding then
						if i.KeyCode ~= Enum.KeyCode.Unknown then
							key = i.KeyCode
							btn.Text = "["..key.Name.."]"
							binding = false
							if self._window._saveConfig then
								UILib.Configs[data.Name] = key.Name
								writeConfig(self._window._configPath, UILib.Configs)
							end
						end
					elseif i.KeyCode == key then
						if data.Callback then safe(data.Callback) end
					end
				end)
			end

			-- TEXTBOX
			function Section:AddTextbox(data)
				data = data or {}
				local holder = Instance.new("Frame")
				holder.Name = data.Name or "Textbox"
				holder.Size = UDim2.new(1, 0, 0, 30)
				holder.BackgroundTransparency = 1
				holder.Parent = self._body

				local name = Instance.new("TextLabel")
				name.Size = UDim2.new(1, -130, 1, 0)
				name.BackgroundTransparency = 1
				name.Font = Enum.Font.Gotham
				name.TextSize = 16
				name.TextColor3 = Color3.fromRGB(230,230,230)
				name.TextXAlignment = Enum.TextXAlignment.Left
				name.Text = data.Name or "Textbox"
				name.Parent = holder

				local box = Instance.new("TextBox")
				box.Size = UDim2.new(0, 120, 0, 26)
				box.Position = UDim2.new(1, -120, 0.5, -13)
				box.BackgroundColor3 = Color3.fromRGB(25,25,25)
				box.Font = Enum.Font.Gotham
				box.TextSize = 14
				box.TextColor3 = Color3.fromRGB(255,255,255)
				box.PlaceholderText = data.Placeholder or ""
				box.Text = data.Default or ""
				box.BorderSizePixel = 0
				box.Parent = holder
				Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

				box.FocusLost:Connect(function()
					local text = box.Text
					if data.Callback then safe(data.Callback, text) end
					if self._window._saveConfig then
						UILib.Configs[data.Name] = text
						writeConfig(self._window._configPath, UILib.Configs)
					end
				end)
			end

			-- COLOR PICKER
			function Section:AddColorPicker(data)
				data = data or {}
				local holder = Instance.new("Frame")
				holder.Name = data.Name or "ColorPicker"
				holder.Size = UDim2.new(1, 0, 0, 30)
				holder.BackgroundTransparency = 1
				holder.Parent = self._body

				local name = Instance.new("TextLabel")
				name.Size = UDim2.new(1, -130, 1, 0)
				name.BackgroundTransparency = 1
				name.Font = Enum.Font.Gotham
				name.TextSize = 16
				name.TextColor3 = Color3.fromRGB(230,230,230)
				name.TextXAlignment = Enum.TextXAlignment.Left
				name.Text = data.Name or "ColorPicker"
				name.Parent = holder

				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(0, 120, 0, 26)
				btn.Position = UDim2.new(1, -120, 0.5, -13)
				btn.BackgroundColor3 = data.Default or Color3.fromRGB(255,170,0)
				btn.Font = Enum.Font.Gotham
				btn.TextSize = 14
				btn.Text = ""
				btn.AutoButtonColor = false
				btn.BorderSizePixel = 0
				btn.Parent = holder
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

				local picker = Instance.new("Frame")
				picker.Visible = false
				picker.Size = UDim2.new(0, 180, 0, 130)
				picker.Position = UDim2.new(1, -180, 1, 4)
				picker.BackgroundColor3 = Color3.fromRGB(15,15,15)
				picker.BorderSizePixel = 0
				picker.Parent = holder
				Instance.new("UICorner", picker).CornerRadius = UDim.new(0, 6)

				local hue = Instance.new("TextBox")
				hue.Size = UDim2.new(0, 60, 0, 24)
				hue.Position = UDim2.new(0, 10, 0, 10)
				hue.Text = "0"
				hue.TextColor3 = Color3.new(1,1,1)
				hue.BackgroundColor3 = Color3.fromRGB(25,25,25)
				hue.BorderSizePixel = 0
				hue.Font = Enum.Font.Gotham
				hue.TextSize = 14
				hue.Parent = picker
				Instance.new("UICorner", hue).CornerRadius = UDim.new(0, 4)

				local sat = hue:Clone()
				sat.Position = UDim2.new(0, 10, 0, 40)
				sat.Text = "1"
				sat.Parent = picker

				local val = hue:Clone()
				val.Position = UDim2.new(0, 10, 0, 70)
				val.Text = "1"
				val.Parent = picker

				local apply = Instance.new("TextButton")
				apply.Size = UDim2.new(0, 160, 0, 24)
				apply.Position = UDim2.new(0, 10, 0, 100)
				apply.Text = "Apply"
				apply.Font = Enum.Font.Gotham
				apply.TextSize = 14
				apply.TextColor3 = Color3.new(1,1,1)
				apply.BackgroundColor3 = Color3.fromRGB(25,25,25)
				apply.BorderSizePixel = 0
				apply.Parent = picker
				Instance.new("UICorner", apply).CornerRadius = UDim.new(0, 4)

				local function applyColor()
					local h = tonumber(hue.Text) or 0
					local s = tonumber(sat.Text) or 1
					local v = tonumber(val.Text) or 1
					local c = Color3.fromHSV(math.clamp(h,0,1), math.clamp(s,0,1), math.clamp(v,0,1))
					btn.BackgroundColor3 = c
					if data.Callback then safe(data.Callback, c) end
					if self._window._saveConfig then
						local hsv = {h=h,s=s,v=v}
						UILib.Configs[data.Name] = hsv
						writeConfig(self._window._configPath, UILib.Configs)
					end
				end

				apply.MouseButton1Click:Connect(applyColor)
				btn.MouseButton1Click:Connect(function()
					picker.Visible = not picker.Visible
				end)
			end

			-- LOAD CONFIG ON STARTUP
			if self._window._saveConfig then
				for name, value in pairs(UILib.Configs) do
					if typeof(value) == "boolean" then
						if value == true then
							if UILib.Flags[name] and UILib.Flags[name].Set then
								UILib.Flags[name]:Set(true)
							end
						end
					end
				end
			end

		end -- end of Section:AddSection
		return Tab
	end -- end of MakeTab
	return Window
end -- end of MakeWindow
end
return UILib
