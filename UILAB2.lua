-- UILib.lua
-- Orion-like UI Library (Dark / Your style)
-- API: Window:MakeTab -> Tab:AddSection -> Section:Add{Label,Button,Textbox,Toggle,Slider,Dropdown,Keybind,ColorPicker}
-- Extras: Window:MakeNotification, Window:Destroy, F1 toggle, Drag, 2-column grid, SaveConfig (writefile/readfile)

--// Services
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local Tween   = game:GetService("TweenService")
local Http    = game:GetService("HttpService")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

--// Lib table
local UILib = {}
UILib.Flags   = {}     -- name -> control proxy (optionally with Set/Get)
UILib.Configs = {}     -- loaded config

--// Utils
local function safe(f, ...)
    local ok, res = pcall(f, ...)
    if not ok then warn("[UILib]:", res) end
    return res
end

local function mkfolder(path)
    if not isfolder(path) then makefolder(path) end
end

local function readjson(path)
    if not isfile(path) then return {} end
    local ok, data = pcall(function()
        return Http:JSONDecode(readfile(path))
    end)
    return ok and data or {}
end

local function writejson(path, tbl)
    local ok, data = pcall(function()
        return Http:JSONEncode(tbl)
    end)
    if ok then writefile(path, data) end
end

-- drag helper
local function makeDraggable(root, handle)
    local dragging, dragInput, startPos, startInput
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startInput = input
            startPos = root.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - startInput.Position
            root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

--// Create Window
function UILib:MakeWindow(opts)
    opts = opts or {}
    local title       = opts.Name or "YOUR HUB"
    local saveConfig  = opts.SaveConfig or false
    local folder      = opts.ConfigFolder or "Default"
    local configDir   = "OrionConfig/"..folder
    local configPath  = configDir.."/MainConfig.json"

    if saveConfig then
        mkfolder("OrionConfig")
        mkfolder(configDir)
        UILib.Configs = readjson(configPath)
    end

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "UILibGui"
    gui.IgnoreGuiInset, gui.ResetOnSpawn = true, false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PG

    -- Root group (for dragging)
    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Position = UDim2.new(0.18, 0, 0.18, 0)
    root.Size     = UDim2.new(0, 960, 0, 560)
    root.BackgroundTransparency = 1
    root.Parent = gui

    -- Left bar
    local left = Instance.new("Frame")
    left.Name = "LeftBar"
    left.Size = UDim2.new(0, 200, 1, 0)
    left.BackgroundColor3 = Color3.fromRGB(6,6,6)
    left.BackgroundTransparency = 0.1
    left.BorderSizePixel = 0
    left.Parent = root

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -16, 0, 60)
    lbl.Position = UDim2.new(0, 8, 0, 6)
    lbl.Font = Enum.Font.Creepster
    lbl.Text = title
    lbl.TextSize = 40
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Parent = left

    local tabBar = Instance.new("Frame", left)
    tabBar.Name = "TabBar"
    tabBar.BackgroundTransparency = 1
    tabBar.Position = UDim2.new(0, 0, 0, 66)
    tabBar.Size     = UDim2.new(1, 0, 1, -66)
    local tabList = Instance.new("UIListLayout", tabBar)
    tabList.Padding = UDim.new(0, 8)
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", tabBar).PaddingLeft = UDim.new(0, 8)

    -- Main panel
    local main = Instance.new("Frame", root)
    main.Name = "Main"
    main.Position = UDim2.new(0, 200, 0, 0)
    main.Size     = UDim2.new(1, -200, 1, 0)
    main.BackgroundColor3 = Color3.fromRGB(8,8,8)
    main.BorderSizePixel = 0

    local scroll = Instance.new("ScrollingFrame", main)
    scroll.Name = "Scroll"
    scroll.BackgroundTransparency = 1
    scroll.Position = UDim2.new(0, 10, 0, 10)
    scroll.Size     = UDim2.new(1, -20, 1, -20)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.new(0,0,0,0)

    local pages = Instance.new("Folder", scroll); pages.Name = "Pages"

    -- Toggle with F1
    UIS.InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.F1 then gui.Enabled = not gui.Enabled end
    end)

    -- drag window by left bar
    makeDraggable(root, left)

    -- Window object
    local Window = {
        _gui = gui, _root = root, _tabBar = tabBar, _pages = pages,
        _tabs = {}, _current = nil, _save = saveConfig, _path = configPath
    }

    function Window:Destroy() self._gui:Destroy() end

    function Window:MakeNotification(data)
        data = data or {}
        local note = Instance.new("TextLabel")
        note.Size = UDim2.new(0, 300, 0, 64)
        note.Position = UDim2.new(0.5, -150, 0.08, 0)
        note.BackgroundColor3 = Color3.new(0,0,0)
        note.BackgroundTransparency = 0.25
        note.Text = (data.Name or "Info").."\n"..(data.Content or "")
        note.Font = Enum.Font.GothamBold
        note.TextSize = 18
        note.TextColor3 = Color3.new(1,1,1)
        note.TextWrapped = true
        note.Parent = self._gui
        Instance.new("UICorner", note).CornerRadius = UDim.new(0, 10)
        Tween:Create(note, TweenInfo.new(0.2), {BackgroundTransparency = 0.1}):Play()
        task.delay(data.Time or 3, function()
            Tween:Create(note, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
            task.wait(0.25); note:Destroy()
        end)
    end

    -- MakeTab
    function Window:MakeTab(t)
        t = t or {}
        local tabName = t.Name or "Tab"

        -- Button in left bar
        local btn = Instance.new("TextButton", self._tabBar)
        btn.Size = UDim2.new(1, -16, 0, 36)
        btn.BackgroundTransparency = 1
        btn.AutoButtonColor = false
        btn.Text = tabName
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.TextColor3 = Color3.fromRGB(220,220,220)
        btn.TextXAlignment = Enum.TextXAlignment.Left

        -- Tab page
        local page = Instance.new("Frame", self._pages)
        page.Visible = false
        page.BackgroundTransparency = 1
        page.Size = UDim2.new(1, 0, 1, 0)
        page.Name = "Page_"..tabName

        local grid = Instance.new("UIGridLayout", page)
        grid.CellSize = UDim2.new(0, 320, 0, 360)
        grid.CellPadding = UDim2.new(0, 16, 0, 16)
        grid.FillDirectionMaxCells = 2
        grid.SortOrder = Enum.SortOrder.LayoutOrder

        local Tab = { _window = self, _page = page, _btn = btn, _sections = {} }
        self._tabs[tabName] = Tab

        local function switch()
            for _, ttb in pairs(self._tabs) do
                ttb._page.Visible = false
                ttb._btn.TextColor3 = Color3.fromRGB(220,220,220)
            end
            page.Visible = true
            btn.TextColor3 = Color3.fromRGB(255,170,0)
            self._current = Tab
        end

        btn.MouseButton1Click:Connect(switch)
        if not self._current then switch() end

        -- AddSection
        function Tab:AddSection(s)
            s = s or {}
            local name = s.Name or "Section"

            local holder = Instance.new("Frame", page)
            holder.BackgroundColor3 = Color3.fromRGB(16,16,16)
            holder.BorderSizePixel = 0
            holder.Size = UDim2.new(0, 320, 0, 360)
            Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 8)

            local header = Instance.new("TextLabel", holder)
            header.BackgroundTransparency = 1
            header.Position = UDim2.new(0, 10, 0, 6)
            header.Size = UDim2.new(1, -20, 0, 28)
            header.Font = Enum.Font.GothamBold
            header.Text = name
            header.TextXAlignment = Enum.TextXAlignment.Left
            header.TextColor3 = Color3.fromRGB(255,170,0)
            header.TextSize = 18

            local body = Instance.new("Frame", holder)
            body.BackgroundColor3 = Color3.fromRGB(10,10,10)
            body.BorderSizePixel = 0
            body.Position = UDim2.new(0, 10, 0, 40)
            body.Size     = UDim2.new(1, -20, 1, -50)
            Instance.new("UICorner", body).CornerRadius = UDim.new(0, 6)

            local list = Instance.new("UIListLayout", body)
            list.Padding = UDim.new(0, 8)
            list.SortOrder = Enum.SortOrder.LayoutOrder
            local pad = Instance.new("UIPadding", body)
            pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0,10),UDim.new(0,10),UDim.new(0,8),UDim.new(0,8)

            local Section = { _tab = Tab, _body = body, _window = self._window }

            -- helpers config
            local function cfgGet(name, default)
                if not Window._save then return default end
                local v = UILib.Configs[name]
                if v == nil then return default end
                return v
            end
            local function cfgSet(name, value)
                if not Window._save then return end
                UILib.Configs[name] = value
                writejson(Window._path, UILib.Configs)
            end

            function Section:AddLabel(text)
                local lbl = Instance.new("TextLabel", body)
                lbl.Size = UDim2.new(1,0,0,22)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 16
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextColor3 = Color3.fromRGB(220,220,220)
                lbl.Text = text or "Label"
            end

            function Section:AddButton(data)
                data = data or {}
                local btn = Instance.new("TextButton", body)
                btn.Size = UDim2.new(1,0,0,32)
                btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Text = data.Name or "Button"
                btn.Font = Enum.Font.GothamSemibold
                btn.TextSize = 15
                btn.TextColor3 = Color3.fromRGB(255,255,255)
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                btn.MouseEnter:Connect(function() Tween:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(40,40,40)}):Play() end)
                btn.MouseLeave:Connect(function() Tween:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(20,20,20)}):Play() end)
                btn.MouseButton1Click:Connect(function()
                    Tween:Create(btn, TweenInfo.new(0.05), {BackgroundColor3 = Color3.fromRGB(255,170,0)}):Play()
                    task.wait(0.08)
                    Tween:Create(btn, TweenInfo.new(0.16), {BackgroundColor3 = Color3.fromRGB(20,20,20)}):Play()
                    if data.Callback then safe(data.Callback) end
                end)
            end

            function Section:AddTextbox(data)
                data = data or {}
                local row = Instance.new("Frame", body)
                row.Size = UDim2.new(1,0,0,30)
                row.BackgroundTransparency = 1
                local name = Instance.new("TextLabel", row)
                name.BackgroundTransparency = 1
                name.Size = UDim2.new(1, -130, 1, 0)
                name.Font = Enum.Font.Gotham
                name.TextSize = 16
                name.TextColor3 = Color3.fromRGB(230,230,230)
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.Text = data.Name or "Textbox"
                local box = Instance.new("TextBox", row)
                box.Size = UDim2.new(0, 120, 0, 26)
                box.Position = UDim2.new(1, -120, 0.5, -13)
                box.BackgroundColor3 = Color3.fromRGB(25,25,25)
                box.BorderSizePixel = 0
                box.Font = Enum.Font.Gotham
                box.TextSize = 14
                box.TextColor3 = Color3.fromRGB(255,255,255)
                box.PlaceholderText = data.Placeholder or ""
                box.Text = cfgGet(data.Name, data.Default or "")
                Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
                box.FocusLost:Connect(function()
                    cfgSet(data.Name, box.Text)
                    if data.Callback then safe(data.Callback, box.Text) end
                end)
            end

            function Section:AddToggle(data)
                data = data or {}
                local row = Instance.new("Frame", body)
                row.Size = UDim2.new(1,0,0,28)
                row.BackgroundTransparency = 1

                local name = Instance.new("TextLabel", row)
                name.BackgroundTransparency = 1
                name.Size = UDim2.new(1, -52, 1, 0)
                name.Font = Enum.Font.Gotham
                name.TextSize = 16
                name.TextColor3 = Color3.fromRGB(230,230,230)
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.Text = data.Name or "Toggle"

                local btn = Instance.new("TextButton", row)
                btn.Size = UDim2.new(0, 44, 0, 20)
                btn.Position = UDim2.new(1, -44, 0.5, -10)
                btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
                btn.AutoButtonColor = false
                btn.Text = ""
                btn.BorderSizePixel = 0
                Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

                local knob = Instance.new("Frame", btn)
                knob.Size = UDim2.new(0, 18, 0, 18)
                knob.Position = UDim2.new(0, 1, 0.5, -9)
                knob.BackgroundColor3 = Color3.new(1,1,1)
                knob.BorderSizePixel = 0
                Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

                local state = cfgGet(data.Name, data.Default or false)
                local function render()
                    if state then
                        Tween:Create(btn,  TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(255,170,0)}):Play()
                        Tween:Create(knob, TweenInfo.new(0.12), {Position = UDim2.new(1, -19, 0.5, -9)}):Play()
                    else
                        Tween:Create(btn,  TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(35,35,35)}):Play()
                        Tween:Create(knob, TweenInfo.new(0.12), {Position = UDim2.new(0, 1, 0.5, -9)}):Play()
                    end
                end
                render()

                local proxy = {}
                function proxy:Set(v)
                    state = v and true or false
                    cfgSet(data.Name, state); render()
                    if data.Callback then safe(data.Callback, state) end
                end
                UILib.Flags[data.Name] = proxy

                btn.MouseButton1Click:Connect(function()
                    proxy:Set(not state)
                end)
            end

            function Section:AddSlider(data)
                data = data or {}
                local min, max = data.Min or 0, data.Max or 100
                local default = cfgGet(data.Name, data.Default or min)

                local row = Instance.new("Frame", body)
                row.Size = UDim2.new(1,0,0,46)
                row.BackgroundTransparency = 1

                local name = Instance.new("TextLabel", row)
                name.BackgroundTransparency = 1
                name.Size = UDim2.new(1, -64, 0, 20)
                name.Font = Enum.Font.Gotham
                name.TextSize = 16
                name.TextColor3 = Color3.fromRGB(230,230,230)
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.Text = data.Name or "Slider"

                local val = Instance.new("TextLabel", row)
                val.BackgroundTransparency = 1
                val.Size = UDim2.new(0, 60, 0, 20)
                val.Position = UDim2.new(1, -60, 0, 0)
                val.Font = Enum.Font.Gotham
                val.TextSize = 14
                val.TextColor3 = Color3.fromRGB(230,230,230)
                val.TextXAlignment = Enum.TextXAlignment.Right

                local bar = Instance.new("Frame", row)
                bar.Size = UDim2.new(1, 0, 0, 8)
                bar.Position = UDim2.new(0, 0, 0, 28)
                bar.BackgroundColor3 = Color3.fromRGB(30,30,30)
                bar.BorderSizePixel = 0
                Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

                local fill = Instance.new("Frame", bar)
                fill.BackgroundColor3 = Color3.fromRGB(255,170,0)
                fill.BorderSizePixel = 0
                fill.Size = UDim2.new(0,0,1,0)
                Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

                local knob = Instance.new("Frame", bar)
                knob.Size = UDim2.new(0, 14, 0, 14)
                knob.Position = UDim2.new(0, -7, 0.5, -7)
                knob.BackgroundColor3 = Color3.new(1,1,1)
                knob.BorderSizePixel = 0
                Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

                local value = default
                local function setFromAlpha(a)
                    a = math.clamp(a, 0, 1)
                    value = min + (max-min)*a
                    if data.Increment and data.Increment > 0 then
                        value = math.floor(value / data.Increment + 0.5) * data.Increment
                        value = math.clamp(value, min, max)
                    end
                    fill.Size = UDim2.new((value-min)/(max-min),0,1,0)
                    knob.Position = UDim2.new((value-min)/(max-min), -7, 0.5, -7)
                    val.Text = tostring(value)
                    cfgSet(data.Name, value)
                    if data.Callback then safe(data.Callback, value) end
                end

                setFromAlpha((default-min)/(max-min))

                local dragging = false
                bar.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        setFromAlpha((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X)
                    end
                end)
                UIS.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                        setFromAlpha((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
            end

            function Section:AddDropdown(data)
                data = data or {}
                local list = data.List or data.Options or {}
                local current = cfgGet(data.Name, data.Default or list[1] or "")

                local row = Instance.new("Frame", body)
                row.Size = UDim2.new(1,0,0,30)
                row.BackgroundTransparency = 1

                local name = Instance.new("TextLabel", row)
                name.BackgroundTransparency = 1
                name.Size = UDim2.new(1, -130, 1, 0)
                name.Font = Enum.Font.Gotham
                name.TextSize = 16
                name.TextColor3 = Color3.fromRGB(230,230,230)
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.Text = data.Name or "Dropdown"

                local btn = Instance.new("TextButton", row)
                btn.Size = UDim2.new(0, 120, 0, 26)
                btn.Position = UDim2.new(1, -120, 0.5, -13)
                btn.BackgroundColor3 = Color3.fromRGB(25,25,25)
                btn.TextColor3 = Color3.new(1,1,1)
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 14
                btn.Text = current
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

                local menu = Instance.new("Frame", row)
                menu.Visible = false
                menu.Size = UDim2.new(0, 120, 0, (#list*24 + 8))
                menu.Position = UDim2.new(1, -120, 1, 4)
                menu.BackgroundColor3 = Color3.fromRGB(15,15,15)
                menu.BorderSizePixel = 0
                Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 6)
                local ll = Instance.new("UIListLayout", menu); ll.Padding = UDim.new(0,4)
                local pp = Instance.new("UIPadding", menu); pp.PaddingLeft=UDim.new(0,4); pp.PaddingTop=UDim.new(0,4); pp.PaddingRight=UDim.new(0,4); pp.PaddingBottom=UDim.new(0,4)

                local function choose(v)
                    current = v
                    btn.Text = v
                    menu.Visible = false
                    cfgSet(data.Name, v)
                    if data.Callback then safe(data.Callback, v) end
                end

                for _,v in ipairs(list) do
                    local opt = Instance.new("TextButton", menu)
                    opt.Size = UDim2.new(1, 0, 0, 20)
                    opt.BackgroundColor3 = Color3.fromRGB(30,30,30)
                    opt.BorderSizePixel = 0
                    opt.TextColor3 = Color3.new(1,1,1)
                    opt.Font = Enum.Font.Gotham
                    opt.TextSize = 14
                    opt.Text = tostring(v)
                    Instance.new("UICorner", opt).CornerRadius = UDim.new(0, 4)
                    opt.MouseButton1Click:Connect(function() choose(v) end)
                end

                btn.MouseButton1Click:Connect(function()
                    menu.Visible = not menu.Visible
                end)
            end

            function Section:AddKeybind(data)
                data = data or {}
                local row = Instance.new("Frame", body)
                row.Size = UDim2.new(1,0,0,30)
                row.BackgroundTransparency = 1

                local name = Instance.new("TextLabel", row)
                name.BackgroundTransparency = 1
                name.Size = UDim2.new(1, -120, 1, 0)
                name.Font = Enum.Font.Gotham
                name.TextSize = 16
                name.TextColor3 = Color3.fromRGB(230,230,230)
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.Text = data.Name or "Keybind"

                local key = Enum.KeyCode[data.Default and data.Default.Name or (data.Default and tostring(data.Default))] or data.Default or Enum.KeyCode.None

                local btn = Instance.new("TextButton", row)
                btn.Size = UDim2.new(0, 100, 0, 26)
                btn.Position = UDim2.new(1, -100, 0.5, -13)
                btn.BackgroundColor3 = Color3.fromRGB(25,25,25)
                btn.TextColor3 = Color3.new(1,1,1)
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Font = Enum.Font.Gotham
                btn.TextSize = 14
                btn.Text = "["..(key ~= Enum.KeyCode.None and key.Name or "None").."]"
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

                local binding = false
                btn.MouseButton1Click:Connect(function()
                    binding = true
                    btn.Text = "[Press...]"
                end)

                UIS.InputBegan:Connect(function(i, g)
                    if g then return end
                    if binding and i.KeyCode ~= Enum.KeyCode.Unknown then
                        key = i.KeyCode
                        btn.Text = "["..key.Name.."]"
                        binding = false
                        cfgSet(data.Name, key.Name)
                    elseif i.KeyCode == key then
                        if data.Callback then safe(data.Callback) end
                    end
                end)
            end

            function Section:AddColorPicker(data)
                data = data or {}
                local hsvDefault = data.Default -- Color3 or nil
                local row = Instance.new("Frame", body)
                row.Size = UDim2.new(1,0,0,30)
                row.BackgroundTransparency = 1

                local name = Instance.new("TextLabel", row)
                name.BackgroundTransparency = 1
                name.Size = UDim2.new(1, -130, 1, 0)
                name.Font = Enum.Font.Gotham
                name.TextSize = 16
                name.TextColor3 = Color3.fromRGB(230,230,230)
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.Text = data.Name or "Color"

                local saved = cfgGet(data.Name, nil)
                local color = hsvDefault or Color3.fromRGB(255,170,0)
                if type(saved) == "table" and saved.h then color = Color3.fromHSV(saved.h or 0, saved.s or 1, saved.v or 1) end

                local btn = Instance.new("TextButton", row)
                btn.Size = UDim2.new(0, 120, 0, 26)
                btn.Position = UDim2.new(1, -120, 0.5, -13)
                btn.BackgroundColor3 = color
                btn.BorderSizePixel = 0; btn.Text = ""
                btn.AutoButtonColor = false
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

                local box = Instance.new("Frame", row)
                box.Visible = false
                box.Size = UDim2.new(0, 180, 0, 130)
                box.Position = UDim2.new(1, -180, 1, 4)
                box.BackgroundColor3 = Color3.fromRGB(15,15,15)
                box.BorderSizePixel = 0
                Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

                local function mkField(y, txt)
                    local f = Instance.new("TextBox", box)
                    f.Size = UDim2.new(0, 60, 0, 24)
                    f.Position = UDim2.new(0, 10, 0, y)
                    f.BackgroundColor3 = Color3.fromRGB(25,25,25)
                    f.TextColor3 = Color3.new(1,1,1)
                    f.BorderSizePixel = 0
                    f.Font = Enum.Font.Gotham
                    f.TextSize = 14
                    f.Text = txt
                    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
                    return f
                end

                local h0,s0,v0 = color:ToHSV()
                local H = mkField(10,  tostring(math.floor(h0*1000)/1000))
                local S = mkField(40,  tostring(math.floor(s0*1000)/1000))
                local V = mkField(70,  tostring(math.floor(v0*1000)/1000))

                local apply = Instance.new("TextButton", box)
                apply.Size = UDim2.new(0, 160, 0, 24)
                apply.Position = UDim2.new(0, 10, 0, 100)
                apply.BackgroundColor3 = Color3.fromRGB(25,25,25)
                apply.Text = "Apply"
                apply.Font = Enum.Font.Gotham
                apply.TextColor3 = Color3.new(1,1,1)
                apply.TextSize = 14
                apply.BorderSizePixel = 0
                Instance.new("UICorner", apply).CornerRadius = UDim.new(0, 4)

                local function applyColor()
                    local h = tonumber(H.Text) or 0
                    local s = tonumber(S.Text) or 1
                    local v = tonumber(V.Text) or 1
                    h, s, v = math.clamp(h,0,1), math.clamp(s,0,1), math.clamp(v,0,1)
                    local c = Color3.fromHSV(h,s,v)
                    btn.BackgroundColor3 = c
                    cfgSet(data.Name, {h=h,s=s,v=v})
                    if data.Callback then safe(data.Callback, c) end
                end
                apply.MouseButton1Click:Connect(applyColor)
                btn.MouseButton1Click:Connect(function() box.Visible = not box.Visible end)
            end

            return Section
        end -- AddSection

        return Tab
    end -- MakeTab

    return Window
end -- MakeWindow

return UILib
