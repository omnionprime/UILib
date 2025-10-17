local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local Http = game:GetService("HttpService")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local function jenc(t) return Http:JSONEncode(t) end
local function jdec(s) local ok,v=pcall(function() return Http:JSONDecode(s) end) return ok and v or {} end

local function hasfs()
    return typeof(isfile)=="function" and typeof(isfolder)=="function" and typeof(writefile)=="function" and typeof(readfile)=="function" and typeof(makefolder)=="function"
end

local function ensureFolders(path)
    if not hasfs() then return end
    local parts = string.split(path,"/")
    local cur = ""
    for i=1,#parts-1 do
        cur = cur..(i>1 and "/" or "")..parts[i]
        if not isfolder(cur) then makefolder(cur) end
    end
end

local function writejson(path,tbl)
    if not hasfs() then return end
    ensureFolders(path)
    writefile(path,jenc(tbl))
end
local function readjson(path)
    if not hasfs() or not isfile(path) then return {} end
    return jdec(readfile(path))
end

local function safe(f, ...)
    local ok, res = pcall(f, ...)
    return ok, res
end

local function makeDraggable(root,handle)
    local dragging, startPos, startInput
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging = true
            startInput = i
            startPos = root.Position
            i.Changed:Connect(function()
                if i.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then
            UIS.InputChanged:Connect(function(m)
                if dragging and m.UserInputType==Enum.UserInputType.MouseMovement then
                    local delta = m.Position - startInput.Position
                    root.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
                end
            end)
        end
    end)
end

local UILib = {}
UILib.Flags = {}
UILib.Configs = {}

function UILib:MakeWindow(opts)
    opts = opts or {}
    local wname = opts.Name or "YOUR HUB"
    local save = opts.SaveConfig or false
    local folder = opts.ConfigFolder or "Default"
    local cfgdir = "OrionConfig/"..folder
    local cfgpath = cfgdir.."/MainConfig.json"
    if save then
        if hasfs() then
            if not isfolder("OrionConfig") then makefolder("OrionConfig") end
            if not isfolder(cfgdir) then makefolder(cfgdir) end
            UILib.Configs = readjson(cfgpath)
        else
            save = false
        end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "UILib"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false
    gui.Parent = PG

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.AnchorPoint = Vector2.new(0,0)
    root.Position = UDim2.new(0.18,0,0.16,0)
    root.Size = UDim2.new(0,980,0,580)
    root.BackgroundTransparency = 1
    root.Parent = gui

    local left = Instance.new("Frame")
    left.Name = "Left"
    left.Size = UDim2.new(0,200,1,0)
    left.BackgroundColor3 = Color3.fromRGB(6,6,6)
    left.BackgroundTransparency = 0.15
    left.BorderSizePixel = 0
    left.Parent = root

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1,-16,0,64)
    title.Position = UDim2.new(0,8,0,6)
    title.Font = Enum.Font.Creepster
    title.TextSize = 40
    title.TextColor3 = Color3.new(1,1,1)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = wname
    title.Parent = left

    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.BackgroundTransparency = 1
    tabBar.Position = UDim2.new(0,0,0,70)
    tabBar.Size = UDim2.new(1,0,1,-70)
    tabBar.Parent = left
    local tl = Instance.new("UIListLayout",tabBar)
    tl.Padding = UDim.new(0,10)
    tl.SortOrder = Enum.SortOrder.LayoutOrder
    local tpad = Instance.new("UIPadding",tabBar)
    tpad.PaddingLeft = UDim.new(0,8)
    tpad.PaddingTop = UDim.new(0,6)
    tpad.PaddingRight = UDim.new(0,8)

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Position = UDim2.new(0,200,0,0)
    main.Size = UDim2.new(1,-200,1,0)
    main.BackgroundColor3 = Color3.fromRGB(6,6,6)
    main.BorderSizePixel = 0
    main.Parent = root

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Scroll"
    scroll.BackgroundTransparency = 1
    scroll.Position = UDim2.new(0,12,0,12)
    scroll.Size = UDim2.new(1,-24,1,-24)
    scroll.ScrollBarThickness = 6
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.Parent = main

    local pages = Instance.new("Folder",scroll)
    pages.Name = "Pages"

    UIS.InputBegan:Connect(function(i,g)
        if g then return end
        if i.KeyCode==Enum.KeyCode.F1 then gui.Enabled = not gui.Enabled end
    end)

    makeDraggable(root,left)

    local Window = { _gui=gui,_root=root,_tabBar=tabBar,_pages=pages,_current=nil,_tabs={}, _save=save, _cfgpath=cfgpath }

    function Window:Destroy() self._gui:Destroy() end

    function Window:MakeNotification(data)
        data = data or {}
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0,320,0,68)
        frame.AnchorPoint = Vector2.new(0.5,0)
        frame.Position = UDim2.new(0.5,0,0,8)
        frame.BackgroundColor3 = Color3.fromRGB(12,12,12)
        frame.BorderSizePixel = 0
        frame.BackgroundTransparency = 0.25
        frame.Parent = self._gui
        local corner = Instance.new("UICorner",frame); corner.CornerRadius = UDim.new(0,8)
        local lbl = Instance.new("TextLabel",frame)
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1,-16,1,-12)
        lbl.Position = UDim2.new(0,8,0,6)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Top
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextWrapped = true
        lbl.TextSize = 18
        lbl.Text = (data.Name or "Info").."\n"..(data.Content or "")
        Tween:Create(frame,TweenInfo.new(0.2),{BackgroundTransparency=0.1}):Play()
        task.delay(data.Time or 3,function()
            Tween:Create(frame,TweenInfo.new(0.25),{BackgroundTransparency=1}):Play()
            task.wait(0.25); frame:Destroy()
        end)
    end

    function Window:MakeTab(t)
        t = t or {}
        local tname = t.Name or "Tab"

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1,-16,0,36)
        tabBtn.BackgroundTransparency = 1
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left
        tabBtn.Text = tname
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 16
        tabBtn.TextColor3 = Color3.fromRGB(220,220,220)
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = self._tabBar

        local page = Instance.new("Frame",self._pages)
        page.Visible = false
        page.BackgroundTransparency = 1
        page.Size = UDim2.new(1,0,1,0)
        page.Name = "Page_"..tname
        local grid = Instance.new("UIGridLayout",page)
        grid.CellSize = UDim2.new(0,340,0,360)
        grid.CellPadding = UDim2.new(0,18,0,18)
        grid.FillDirectionMaxCells = 2
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        local ppad = Instance.new("UIPadding",page)
        ppad.PaddingBottom = UDim.new(0,2)

        local Tab = { _window=self, _page=page, _btn=tabBtn, _sections={} }
        self._tabs[tname] = Tab

        local function switch()
            for _,tb in pairs(self._tabs) do
                tb._page.Visible = false
                tb._btn.TextColor3 = Color3.fromRGB(220,220,220)
            end
            page.Visible = true
            tabBtn.TextColor3 = Color3.fromRGB(255,170,0)
            self._current = Tab
        end

        tabBtn.MouseButton1Click:Connect(switch)
        if not self._current then switch() end

        function Tab:AddSection(s)
            s = s or {}
            local sname = s.Name or "Section"

            local card = Instance.new("Frame",page)
            card.BackgroundColor3 = Color3.fromRGB(12,12,12)
            card.BorderSizePixel = 0
            card.Size = UDim2.new(0,340,0,360)
            local cc = Instance.new("UICorner",card); cc.CornerRadius = UDim.new(0,10)

            local head = Instance.new("TextLabel",card)
            head.BackgroundTransparency = 1
            head.Position = UDim2.new(0,12,0,8)
            head.Size = UDim2.new(1,-24,0,26)
            head.Font = Enum.Font.GothamBold
            head.TextSize = 18
            head.TextXAlignment = Enum.TextXAlignment.Left
            head.TextColor3 = Color3.fromRGB(255,170,0)
            head.Text = sname

            local body = Instance.new("Frame",card)
            body.BackgroundColor3 = Color3.fromRGB(8,8,8)
            body.BorderSizePixel = 0
            body.Position = UDim2.new(0,12,0,40)
            body.Size = UDim2.new(1,-24,1,-52)
            local bc = Instance.new("UICorner",body); bc.CornerRadius = UDim.new(0,8)
            local bl = Instance.new("UIListLayout",body); bl.Padding=UDim.new(0,10); bl.SortOrder=Enum.SortOrder.LayoutOrder
            local bpad = Instance.new("UIPadding",body); bpad.PaddingLeft=UDim.new(0,10); bpad.PaddingTop=UDim.new(0,10); bpad.PaddingRight=UDim.new(0,10); bpad.PaddingBottom=UDim.new(0,10)

            local Section = { _tab=Tab, _body=body, _window=self._window }

            local function cfgGet(name, default)
                if not Window._save then return default end
                local v = UILib.Configs[name]
                if v==nil then return default end
                return v
            end
            local function cfgSet(name, value)
                if not Window._save then return end
                UILib.Configs[name] = value
                writejson(Window._cfgpath, UILib.Configs)
            end

            function Section:AddLabel(text)
                local lbl = Instance.new("TextLabel",body)
                lbl.Size = UDim2.new(1,0,0,22)
                lbl.BackgroundTransparency = 1
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 16
                lbl.TextColor3 = Color3.fromRGB(230,230,230)
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Text = text or "Label"
            end

            function Section:AddButton(data)
                data = data or {}
                local btn = Instance.new("TextButton",body)
                btn.Size = UDim2.new(1,0,0,34)
                btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Text = data.Name or "Button"
                btn.Font = Enum.Font.GothamSemibold
                btn.TextSize = 15
                btn.TextColor3 = Color3.fromRGB(255,255,255)
                local cr = Instance.new("UICorner",btn); cr.CornerRadius = UDim.new(0,6)
                btn.MouseEnter:Connect(function() Tween:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(40,40,40)}):Play() end)
                btn.MouseLeave:Connect(function() Tween:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(20,20,20)}):Play() end)
                btn.MouseButton1Click:Connect(function()
                    Tween:Create(btn,TweenInfo.new(0.05),{BackgroundColor3=Color3.fromRGB(255,170,0)}):Play()
                    task.wait(0.08)
                    Tween:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(20,20,20)}):Play()
                    if data.Callback then safe(data.Callback) end
                end)
            end

            function Section:AddTextbox(data)
                data = data or {}
                local row = Instance.new("Frame",body)
                row.Size = UDim2.new(1,0,0,30)
                row.BackgroundTransparency = 1
                local name = Instance.new("TextLabel",row)
                name.BackgroundTransparency=1
                name.Size = UDim2.new(1,-130,1,0)
                name.Font=Enum.Font.Gotham; name.TextSize=16; name.TextColor3=Color3.fromRGB(230,230,230); name.TextXAlignment=Enum.TextXAlignment.Left
                name.Text = data.Name or "Textbox"
                local box = Instance.new("TextBox",row)
                box.Size=UDim2.new(0,120,0,26); box.Position=UDim2.new(1,-120,0.5,-13)
                box.BackgroundColor3=Color3.fromRGB(25,25,25); box.BorderSizePixel=0; box.Font=Enum.Font.Gotham; box.TextSize=14; box.TextColor3=Color3.new(1,1,1)
                box.PlaceholderText = data.Placeholder or ""
                box.Text = cfgGet(data.Name,data.Default or "")
                local cr = Instance.new("UICorner",box); cr.CornerRadius=UDim.new(0,4)
                box.FocusLost:Connect(function()
                    cfgSet(data.Name,box.Text)
                    if data.Callback then safe(data.Callback,box.Text) end
                end)
            end

            function Section:AddToggle(data)
                data = data or {}
                local row = Instance.new("Frame",body)
                row.Size = UDim2.new(1,0,0,28)
                row.BackgroundTransparency = 1
                local name = Instance.new("TextLabel",row)
                name.BackgroundTransparency=1; name.Size=UDim2.new(1,-52,1,0); name.Font=Enum.Font.Gotham; name.TextSize=16; name.TextColor3=Color3.fromRGB(230,230,230); name.TextXAlignment=Enum.TextXAlignment.Left
                name.Text = data.Name or "Toggle"
                local btn = Instance.new("TextButton",row)
                btn.Size=UDim2.new(0,44,0,20); btn.Position=UDim2.new(1,-44,0.5,-10); btn.BackgroundColor3=Color3.fromRGB(35,35,35)
                btn.AutoButtonColor=false; btn.Text=""; btn.BorderSizePixel=0
                local cr = Instance.new("UICorner",btn); cr.CornerRadius=UDim.new(1,0)
                local knob = Instance.new("Frame",btn)
                knob.Size=UDim2.new(0,18,0,18); knob.Position=UDim2.new(0,1,0.5,-9); knob.BackgroundColor3=Color3.new(1,1,1); knob.BorderSizePixel=0
                local kr = Instance.new("UICorner",knob); kr.CornerRadius=UDim.new(1,0)
                local state = cfgGet(data.Name,data.Default or false)
                local function render()
                    if state then
                        Tween:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(255,170,0)}):Play()
                        Tween:Create(knob,TweenInfo.new(0.1),{Position=UDim2.new(1,-19,0.5,-9)}):Play()
                    else
                        Tween:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(35,35,35)}):Play()
                        Tween:Create(knob,TweenInfo.new(0.1),{Position=UDim2.new(0,1,0.5,-9)}):Play()
                    end
                end
                render()
                local proxy = {}
                function proxy:Set(v)
                    state = v and true or false
                    cfgSet(data.Name,state); render()
                    if data.Callback then safe(data.Callback,state) end
                end
                function proxy:Get() return state end
                UILib.Flags[data.Name] = proxy
                btn.MouseButton1Click:Connect(function() proxy:Set(not state) end)
            end

            function Section:AddSlider(data)
                data = data or {}
                local min,max = data.Min or 0, data.Max or 100
                local default = cfgGet(data.Name,data.Default or min)
                local inc = data.Increment

                local row = Instance.new("Frame",body)
                row.Size = UDim2.new(1,0,0,48)
                row.BackgroundTransparency = 1
                local name = Instance.new("TextLabel",row)
                name.BackgroundTransparency=1; name.Size=UDim2.new(1,-64,0,20); name.Font=Enum.Font.Gotham; name.TextSize=16; name.TextColor3=Color3.fromRGB(230,230,230); name.TextXAlignment=Enum.TextXAlignment.Left
                name.Text = data.Name or "Slider"
                local val = Instance.new("TextLabel",row)
                val.BackgroundTransparency=1; val.Size=UDim2.new(0,60,0,20); val.Position=UDim2.new(1,-60,0,0); val.Font=Enum.Font.Gotham; val.TextSize=14; val.TextColor3=Color3.fromRGB(230,230,230); val.TextXAlignment=Enum.TextXAlignment.Right
                local bar = Instance.new("Frame",row)
                bar.Size=UDim2.new(1,0,0,8); bar.Position=UDim2.new(0,0,0,28); bar.BackgroundColor3=Color3.fromRGB(30,30,30); bar.BorderSizePixel=0
                local br = Instance.new("UICorner",bar); br.CornerRadius=UDim.new(0,4)
                local fill = Instance.new("Frame",bar)
                fill.BackgroundColor3=Color3.fromRGB(255,170,0); fill.BorderSizePixel=0; fill.Size=UDim2.new(0,0,1,0)
                local fr = Instance.new("UICorner",fill); fr.CornerRadius=UDim.new(0,4)
                local knob = Instance.new("Frame",bar)
                knob.Size=UDim2.new(0,14,0,14); knob.Position=UDim2.new(0,-7,0.5,-7); knob.BackgroundColor3=Color3.new(1,1,1); knob.BorderSizePixel=0
                local kr = Instance.new("UICorner",knob); kr.CornerRadius=UDim.new(1,0)

                local value = default
                local function setAlpha(a)
                    a = math.clamp(a,0,1)
                    value = min + (max-min)*a
                    if inc and inc>0 then
                        value = math.floor(value/inc + 0.5)*inc
                        value = math.clamp(value,min,max)
                    end
                    fill.Size = UDim2.new((value-min)/(max-min),0,1,0)
                    knob.Position = UDim2.new((value-min)/(max-min),-7,0.5,-7)
                    val.Text = tostring(value)
                    cfgSet(data.Name,value)
                    if data.Callback then safe(data.Callback,value) end
                end
                setAlpha((default-min)/(max-min))

                local dragging=false
                bar.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then
                        dragging=true
                        setAlpha((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X)
                    end
                end)
                UIS.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                        setAlpha((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
                end)
            end

            function Section:AddDropdown(data)
                data = data or {}
                local list = data.Options or data.List or {}
                local current = cfgGet(data.Name,data.Default or list[1] or "")

                local row = Instance.new("Frame",body)
                row.Size = UDim2.new(1,0,0,32)
                row.BackgroundTransparency = 1
                local name = Instance.new("TextLabel",row)
                name.BackgroundTransparency=1; name.Size=UDim2.new(1,-130,1,0); name.Font=Enum.Font.Gotham; name.TextSize=16; name.TextColor3=Color3.fromRGB(230,230,230); name.TextXAlignment=Enum.TextXAlignment.Left
                name.Text = data.Name or "Dropdown"
                local btn = Instance.new("TextButton",row)
                btn.Size=UDim2.new(0,120,0,26); btn.Position=UDim2.new(1,-120,0.5,-13); btn.BackgroundColor3=Color3.fromRGB(25,25,25); btn.BorderSizePixel=0; btn.AutoButtonColor=false
                btn.Font=Enum.Font.Gotham; btn.TextSize=14; btn.TextColor3=Color3.new(1,1,1); btn.Text=current
                local cr = Instance.new("UICorner",btn); cr.CornerRadius=UDim.new(0,4)

                local menu = Instance.new("Frame",row)
                menu.Visible=false; menu.Size=UDim2.new(0,120,0,#list*24+8); menu.Position=UDim2.new(1,-120,1,4)
                menu.BackgroundColor3=Color3.fromRGB(15,15,15); menu.BorderSizePixel=0
                local mcr = Instance.new("UICorner",menu); mcr.CornerRadius=UDim.new(0,6)
                local ml = Instance.new("UIListLayout",menu); ml.Padding=UDim.new(0,4)
                local mp = Instance.new("UIPadding",menu); mp.PaddingTop=UDim.new(0,4); mp.PaddingBottom=UDim.new(0,4); mp.PaddingLeft=UDim.new(0,4); mp.PaddingRight=UDim.new(0,4)

                local function choose(v)
                    current = v
                    btn.Text = v
                    cfgSet(data.Name,v)
                    if data.Callback then safe(data.Callback,v) end
                    menu.Visible=false
                end

                for _,v in ipairs(list) do
                    local it = Instance.new("TextButton",menu)
                    it.Size=UDim2.new(1,0,0,20); it.BackgroundColor3=Color3.fromRGB(30,30,30); it.BorderSizePixel=0; it.TextColor3=Color3.new(1,1,1)
                    it.Font=Enum.Font.Gotham; it.TextSize=14; it.Text=tostring(v)
                    local icr = Instance.new("UICorner",it); icr.CornerRadius=UDim.new(0,4)
                    it.MouseButton1Click:Connect(function() choose(v) end)
                end

                btn.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)
            end

            function Section:AddKeybind(data)
                data = data or {}
                local row = Instance.new("Frame",body)
                row.Size = UDim2.new(1,0,0,32)
                row.BackgroundTransparency = 1
                local name = Instance.new("TextLabel",row)
                name.BackgroundTransparency=1; name.Size=UDim2.new(1,-120,1,0); name.Font=Enum.Font.Gotham; name.TextSize=16; name.TextColor3=Color3.fromRGB(230,230,230); name.TextXAlignment=Enum.TextXAlignment.Left
                name.Text = data.Name or "Keybind"
                local btn = Instance.new("TextButton",row)
                btn.Size=UDim2.new(0,100,0,26); btn.Position=UDim2.new(1,-100,0.5,-13); btn.BackgroundColor3=Color3.fromRGB(25,25,25)
                btn.BorderSizePixel=0; btn.AutoButtonColor=false; btn.Font=Enum.Font.Gotham; btn.TextSize=14; btn.TextColor3=Color3.new(1,1,1)
                local cr = Instance.new("UICorner",btn); cr.CornerRadius=UDim.new(0,4)

                local initial = data.Default
                if typeof(initial)=="EnumItem" then initial = initial end
                if typeof(initial)=="string" and Enum.KeyCode[initial] then initial = Enum.KeyCode[initial] end
                if typeof(initial)~="EnumItem" then initial = Enum.KeyCode.None end
                local key = cfgGet(data.Name, initial.Name) ; key = Enum.KeyCode[key] or initial

                local binding=false
                local function label() btn.Text = "["..(key~=Enum.KeyCode.None and key.Name or "None").."]" end
                label()
                btn.MouseButton1Click:Connect(function() binding=true; btn.Text="[Press...]" end)
                UIS.InputBegan:Connect(function(i,g)
                    if g then return end
                    if binding and i.KeyCode~=Enum.KeyCode.Unknown then
                        key = i.KeyCode
                        cfgSet(data.Name,key.Name)
                        label()
                        binding=false
                    elseif i.KeyCode==key then
                        if data.Callback then safe(data.Callback) end
                    end
                end)
            end

            function Section:AddColorPicker(data)
                data = data or {}
                local row = Instance.new("Frame",body)
                row.Size=UDim2.new(1,0,0,32)
                row.BackgroundTransparency=1
                local name = Instance.new("TextLabel",row)
                name.BackgroundTransparency=1; name.Size=UDim2.new(1,-130,1,0); name.Font=Enum.Font.Gotham; name.TextSize=16; name.TextColor3=Color3.fromRGB(230,230,230); name.TextXAlignment=Enum.TextXAlignment.Left
                name.Text = data.Name or "Color"
                local saved = cfgGet(data.Name,nil)
                local base = data.Default or Color3.fromRGB(255,170,0)
                if type(saved)=="table" and saved.h then base = Color3.fromHSV(saved.h or 0, saved.s or 1, saved.v or 1) end
                local btn = Instance.new("TextButton",row)
                btn.Size=UDim2.new(0,120,0,26); btn.Position=UDim2.new(1,-120,0.5,-13); btn.BackgroundColor3=base; btn.BorderSizePixel=0; btn.AutoButtonColor=false; btn.Text=""
                local cr = Instance.new("UICorner",btn); cr.CornerRadius=UDim.new(0,4)

                local box = Instance.new("Frame",row)
                box.Visible=false; box.Size=UDim2.new(0,180,0,130); box.Position=UDim2.new(1,-180,1,4); box.BackgroundColor3=Color3.fromRGB(15,15,15); box.BorderSizePixel=0
                local bcr = Instance.new("UICorner",box); bcr.CornerRadius=UDim.new(0,6)
                local function mk(y,txt)
                    local tb = Instance.new("TextBox",box)
                    tb.Size=UDim2.new(0,60,0,24); tb.Position=UDim2.new(0,10,0,y); tb.BackgroundColor3=Color3.fromRGB(25,25,25); tb.TextColor3=Color3.new(1,1,1)
                    tb.BorderSizePixel=0; tb.Font=Enum.Font.Gotham; tb.TextSize=14; tb.Text=txt
                    local tcr = Instance.new("UICorner",tb); tcr.CornerRadius=UDim.new(0,4)
                    return tb
                end
                local h,s,v = base:ToHSV()
                local H = mk(10,tostring(math.floor(h*1000)/1000))
                local S = mk(40,tostring(math.floor(s*1000)/1000))
                local V = mk(70,tostring(math.floor(v*1000)/1000))
                local apply = Instance.new("TextButton",box)
                apply.Size=UDim2.new(0,160,0,24); apply.Position=UDim2.new(0,10,0,100); apply.BackgroundColor3=Color3.fromRGB(25,25,25); apply.Text="Apply"; apply.Font=Enum.Font.Gotham; apply.TextColor3=Color3.new(1,1,1); apply.TextSize=14; apply.BorderSizePixel=0
                local acr = Instance.new("UICorner",apply); acr.CornerRadius=UDim.new(0,4)

                local function applyColor()
                    local hh = tonumber(H.Text) or 0
                    local ss = tonumber(S.Text) or 1
                    local vv = tonumber(V.Text) or 1
                    hh,ss,vv = math.clamp(hh,0,1), math.clamp(ss,0,1), math.clamp(vv,0,1)
                    local c = Color3.fromHSV(hh,ss,vv)
                    btn.BackgroundColor3 = c
                    cfgSet(data.Name,{h=hh,s=ss,v=vv})
                    if data.Callback then safe(data.Callback,c) end
                end
                apply.MouseButton1Click:Connect(applyColor)
                btn.MouseButton1Click:Connect(function() box.Visible = not box.Visible end)
            end

            return Section
        end

        return Tab
    end

    if save then
        for k,v in pairs(UILib.Configs) do
            local flag = UILib.Flags[k]
            if type(v)=="boolean" and flag and flag.Set then flag:Set(v) end
        end
    end

    return Window
end

return UILib
