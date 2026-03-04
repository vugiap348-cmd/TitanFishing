-- TITAN FISHING AUTO SELL v11
-- Menu rong, nut danh dau khong an, co nut an/hien rieng

local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local RS            = game:GetService("RunService")
local PFS           = game:GetService("PathfindingService")
local TS            = game:GetService("TweenService")
local VIM           = game:GetService("VirtualInputManager")
local LP            = Players.LocalPlayer

local isRunning     = false
local menuOpen      = true
local statusText    = "Chua bat"
local sellCount     = 0
local timer         = 0
local savedFishPos  = nil
local savedNPCPos   = nil
local savedSellPos  = nil   -- toa do nut SellAll
local savedClosePos = nil   -- toa do nut X

-- ================================================
-- CLICK TOA DO
-- ================================================
local function clickAt(x, y)
    VIM:SendMouseButtonEvent(x, y, 0, true,  game, 0)
    task.wait(0.08)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    task.wait(0.1)
end

-- ================================================
-- DI BO
-- ================================================
local function walkTo(pos, label)
    local char = LP.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    statusText = label or "Dang di..."
    hum.WalkSpeed = 24
    local path = PFS:CreatePath({AgentHeight=5, AgentRadius=2, AgentCanJump=true})
    local ok = pcall(function() path:ComputeAsync(hrp.Position, pos) end)
    if ok and path.Status == Enum.PathStatus.Success then
        for _, wp in ipairs(path:GetWaypoints()) do
            if not isRunning then return end
            if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
            hum:MoveTo(wp.Position)
            hum.MoveToFinished:Wait(3)
            if (hrp.Position - pos).Magnitude < 8 then break end
        end
    else
        hum:MoveTo(pos)
        local t = 0
        while t < 12 and isRunning do
            task.wait(0.2); t += 0.2
            if (hrp.Position - pos).Magnitude < 8 then break end
        end
    end
end

local function stopWalk()
    local c = LP.Character
    local h = c and c:FindFirstChild("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if h and r then h:MoveTo(r.Position) end
end

-- ================================================
-- INTERACT
-- ================================================
local function doInteract()
    statusText = "Mo cua hang..."
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local best, bestD = nil, math.huge
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                local p = v.Parent
                if p and p:IsA("BasePart") then
                    local d = (hrp.Position - p.Position).Magnitude
                    if d < bestD then bestD = d; best = v end
                end
            end
        end
        if best and bestD < 20 then
            pcall(function() fireproximityprompt(best) end)
            task.wait(0.5)
        end
    end
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("interact") or n:find("npc") or n:find("shop") or n:find("open") then
                pcall(function() v:FireServer() end)
            end
        end
    end
    task.wait(0.3)
    for _, g in ipairs(LP.PlayerGui:GetDescendants()) do
        if (g:IsA("TextButton") or g:IsA("ImageButton")) and g.Visible then
            local n = g.Name:lower()
            local t = g:IsA("TextButton") and g.Text:lower() or ""
            if n:find("interact") or t:find("interact") then
                g.MouseButton1Down:Fire(); task.wait(1.2)
                g.MouseButton1Up:Fire();   g.MouseButton1Click:Fire()
            end
        end
    end
    task.wait(0.8)
end

-- ================================================
-- SELL ALL
-- ================================================
local function doSellAll()
    if not savedSellPos  then statusText = "Chua danh dau SellAll!" task.wait(2) return false end
    if not savedClosePos then statusText = "Chua danh dau nut X!"   task.wait(2) return false end
    statusText = "Cho popup hien..."
    task.wait(0.9)
    statusText = "Click SellAll..."
    clickAt(savedSellPos.X,  savedSellPos.Y)
    task.wait(1)
    statusText = "Dong popup X..."
    clickAt(savedClosePos.X, savedClosePos.Y)
    task.wait(0.5)
    statusText = "Da ban xong!"
    return true
end

-- ================================================
-- MAIN LOOP
-- ================================================
local function mainLoop()
    while isRunning do
        local char = LP.Character; if not char then task.wait(1) continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum then task.wait(1) continue end

        if not savedFishPos  then statusText = "Chua luu vi tri cau!" task.wait(2) continue end
        if not savedNPCPos   then statusText = "Chua luu vi tri NPC!" task.wait(2) continue end
        if not savedSellPos  then statusText = "Chua danh dau SellAll!" task.wait(2) continue end
        if not savedClosePos then statusText = "Chua danh dau nut X!"  task.wait(2) continue end

        walkTo(savedNPCPos,  "Di toi NPC ban ca...")
        if not isRunning then break end
        task.wait(0.3); stopWalk(); task.wait(0.3)

        doInteract(); task.wait(0.5)
        doSellAll();  task.wait(0.5)

        sellCount += 1
        statusText = "Da ban lan " .. sellCount .. "!"

        walkTo(savedFishPos, "Quay ve vi tri cau...")
        if not isRunning then break end
        stopWalk()

        statusText = "Cho ban tiep..."
        timer = 30
        while timer > 0 and isRunning do task.wait(1); timer -= 1 end
    end
    statusText = "Da tat"
end

-- ================================================
-- GUI
-- ================================================
local old = LP.PlayerGui:FindFirstChild("TFHub")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "TFHub"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = LP.PlayerGui

-- ======== 2 VONG TRON DANH DAU (luon hien, co the an/hien) ========
local function makeMarker(color, zidx)
    local SIZE = 56
    local m = Instance.new("TextButton")
    m.Size     = UDim2.new(0, SIZE, 0, SIZE)
    m.Position = UDim2.new(0.5, -SIZE/2, 0.5, -SIZE/2)
    m.BackgroundColor3 = color
    m.BackgroundTransparency = 0.15
    m.BorderSizePixel = 0
    m.Text    = ""
    m.ZIndex  = zidx
    m.Active  = true
    m.Draggable = true
    m.Visible = false
    m.Parent  = sg
    Instance.new("UICorner", m).CornerRadius = UDim.new(1, 0)
    -- Vien trang
    local sk = Instance.new("UIStroke", m)
    sk.Color = Color3.new(1,1,1); sk.Thickness = 2.5
    -- Crosshair ngang
    local lh = Instance.new("Frame", m)
    lh.Size = UDim2.new(0.65,0,0,2)
    lh.Position = UDim2.new(0.175,0,0.5,-1)
    lh.BackgroundColor3 = Color3.new(1,1,0)
    lh.BorderSizePixel = 0; lh.ZIndex = zidx+1
    -- Crosshair doc
    local lv = Instance.new("Frame", m)
    lv.Size = UDim2.new(0,2,0.65,0)
    lv.Position = UDim2.new(0.5,-1,0.175,0)
    lv.BackgroundColor3 = Color3.new(1,1,0)
    lv.BorderSizePixel = 0; lv.ZIndex = zidx+1
    -- Cham giua
    local dot = Instance.new("Frame", m)
    dot.Size = UDim2.new(0,7,0,7)
    dot.Position = UDim2.new(0.5,-3.5,0.5,-3.5)
    dot.BackgroundColor3 = Color3.new(1,0,0)
    dot.BorderSizePixel = 0; dot.ZIndex = zidx+2
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    return m
end

local sellMarker  = makeMarker(Color3.fromRGB(20, 200, 100), 30)
local closeMarker = makeMarker(Color3.fromRGB(220, 40,  60), 30)

-- Nhip tim marker
RS.Heartbeat:Connect(function()
    local t = tick() % 1
    local a = math.abs(math.sin(t * math.pi))
    if sellMarker.Visible  then sellMarker.BackgroundTransparency  = 0.05 + a*0.35 end
    if closeMarker.Visible then closeMarker.BackgroundTransparency = 0.05 + a*0.35 end
end)

-- ======== CUC TRON ========
local bubble = Instance.new("TextButton")
bubble.Size = UDim2.new(0,58,0,58)
bubble.Position = UDim2.new(0,14,0.5,-29)
bubble.BackgroundColor3 = Color3.fromRGB(255,140,0)
bubble.BorderSizePixel = 0; bubble.Text = "đŸ£"
bubble.TextScaled = true; bubble.Font = Enum.Font.GothamBold
bubble.Visible = false; bubble.ZIndex = 10
bubble.Active = true; bubble.Draggable = true
bubble.Parent = sg
Instance.new("UICorner", bubble).CornerRadius = UDim.new(1,0)
local bsk = Instance.new("UIStroke", bubble)
bsk.Color = Color3.fromRGB(255,210,80); bsk.Thickness = 2.5

-- ======== FRAME CHINH (rong hon) ========
local W, H = 310, 560
local frame = Instance.new("Frame")
frame.Size     = UDim2.new(0, W, 0, H)
frame.Position = UDim2.new(0, 14, 0.5, -H/2)
frame.BackgroundColor3 = Color3.fromRGB(10,10,20)
frame.BorderSizePixel = 0; frame.Active = true
frame.Draggable = true; frame.ClipsDescendants = true
frame.ZIndex = 5; frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,16)
local msk = Instance.new("UIStroke", frame)
msk.Color = Color3.fromRGB(255,140,0); msk.Thickness = 1.5
local fg = Instance.new("UIGradient", frame)
fg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18,14,35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8,8,18)),
})
fg.Rotation = 135

-- ======== HEADER ========
local hdr = Instance.new("Frame", frame)
hdr.Size = UDim2.new(1,0,0,54); hdr.BackgroundColor3 = Color3.fromRGB(20,12,40)
hdr.BorderSizePixel = 0; hdr.ZIndex = 6
Instance.new("UICorner", hdr).CornerRadius = UDim.new(0,16)
local hg = Instance.new("UIGradient", hdr)
hg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,120,0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,60,120)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(100,40,200)),
})
hg.Rotation = 90

local function hTxt(parent, size, pos, txt, font, tsize, col, xa)
    local l = Instance.new("TextLabel", parent)
    l.Size = size; l.Position = pos; l.BackgroundTransparency = 1
    l.Text = txt; l.Font = font; l.TextSize = tsize
    l.TextColor3 = col or Color3.new(1,1,1)
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.ZIndex = 7; return l
end
hTxt(hdr, UDim2.new(0,36,0,36), UDim2.new(0,10,0.5,-18), "đŸ£", Enum.Font.GothamBold, 20, Color3.new(1,1,1), Enum.TextXAlignment.Center)
hTxt(hdr, UDim2.new(1,-110,0,26), UDim2.new(0,54,0,8),  "TITAN FISHING",  Enum.Font.GothamBlack, 17, Color3.new(1,1,1))
hTxt(hdr, UDim2.new(1,-110,0,14), UDim2.new(0,54,1,-18),"Auto Sell v11",  Enum.Font.Gotham,      11, Color3.fromRGB(255,200,150))

local closeMenuBtn = Instance.new("TextButton", hdr)
closeMenuBtn.Size = UDim2.new(0,32,0,32); closeMenuBtn.Position = UDim2.new(1,-42,0.5,-16)
closeMenuBtn.BackgroundColor3 = Color3.fromRGB(220,50,50); closeMenuBtn.BorderSizePixel = 0
closeMenuBtn.Text = "âœ•"; closeMenuBtn.TextColor3 = Color3.new(1,1,1)
closeMenuBtn.Font = Enum.Font.GothamBold; closeMenuBtn.TextSize = 14; closeMenuBtn.ZIndex = 8
Instance.new("UICorner", closeMenuBtn).CornerRadius = UDim.new(1,0)

-- ======== SCROLL ========
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1,0,1,-54); scroll.Position = UDim2.new(0,0,0,54)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = Color3.fromRGB(255,140,0)
scroll.CanvasSize = UDim2.new(0,0,0,600); scroll.ZIndex = 6

-- Helper functions
local Y = 10 -- cursor y

local function gap(n) Y = Y + (n or 10) end

local function secLabel(txt)
    local l = Instance.new("TextLabel", scroll)
    l.Size = UDim2.new(1,-28,0,20); l.Position = UDim2.new(0,14,0,Y)
    l.BackgroundTransparency = 1; l.Text = txt
    l.TextColor3 = Color3.fromRGB(160,160,255)
    l.Font = Enum.Font.GothamBold; l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left; l.ZIndex = 6
    Y = Y + 24
end

local function divLine()
    local d = Instance.new("Frame", scroll)
    d.Size = UDim2.new(1,-28,0,1); d.Position = UDim2.new(0,14,0,Y)
    d.BackgroundColor3 = Color3.fromRGB(55,55,90); d.BorderSizePixel = 0; d.ZIndex = 6
    Y = Y + 10
end

local function statusBox()
    local box = Instance.new("Frame", scroll)
    box.Size = UDim2.new(1,-28,0,46); box.Position = UDim2.new(0,14,0,Y)
    box.BackgroundColor3 = Color3.fromRGB(16,16,32); box.BorderSizePixel = 0; box.ZIndex = 6
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", box).Color = Color3.fromRGB(55,55,95)

    local dot = Instance.new("Frame", box)
    dot.Size = UDim2.new(0,9,0,9); dot.Position = UDim2.new(0,12,0.5,-4.5)
    dot.BackgroundColor3 = Color3.fromRGB(255,80,80); dot.BorderSizePixel = 0; dot.ZIndex = 7
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

    local lbl = Instance.new("TextLabel", box)
    lbl.Size = UDim2.new(1,-30,1,0); lbl.Position = UDim2.new(0,28,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = "Chua bat"
    lbl.TextColor3 = Color3.fromRGB(255,120,120)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 7
    Y = Y + 54
    return dot, lbl
end

local function statRow()
    local row = Instance.new("Frame", scroll)
    row.Size = UDim2.new(1,-28,0,40); row.Position = UDim2.new(0,14,0,Y)
    row.BackgroundTransparency = 1; row.ZIndex = 6

    local function cell(xp, icon, col)
        local b = Instance.new("Frame", row)
        b.Size = UDim2.new(0.48,0,1,0); b.Position = UDim2.new(xp,0,0,0)
        b.BackgroundColor3 = Color3.fromRGB(16,16,32); b.BorderSizePixel = 0; b.ZIndex = 6
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,9)
        Instance.new("UIStroke", b).Color = Color3.fromRGB(45,45,85)
        local il = Instance.new("TextLabel", b)
        il.Size = UDim2.new(0,24,1,0); il.Position = UDim2.new(0,6,0,0)
        il.BackgroundTransparency = 1; il.Text = icon; il.TextScaled = true; il.ZIndex = 7
        local vl = Instance.new("TextLabel", b)
        vl.Size = UDim2.new(1,-32,1,0); vl.Position = UDim2.new(0,32,0,0)
        vl.BackgroundTransparency = 1; vl.TextColor3 = col
        vl.Font = Enum.Font.GothamBold; vl.TextSize = 13
        vl.TextXAlignment = Enum.TextXAlignment.Left; vl.ZIndex = 7
        return vl
    end
    local c1 = cell(0,    "đŸŸ", Color3.fromRGB(100,220,255))
    local c2 = cell(0.52, "â±",  Color3.fromRGB(255,200,100))
    Y = Y + 48
    return c1, c2
end

local function infoRow(icon, txt, col)
    local row = Instance.new("Frame", scroll)
    row.Size = UDim2.new(1,-28,0,32); row.Position = UDim2.new(0,14,0,Y)
    row.BackgroundColor3 = Color3.fromRGB(14,14,28); row.BorderSizePixel = 0; row.ZIndex = 6
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,9)
    local il = Instance.new("TextLabel", row)
    il.Size = UDim2.new(0,26,1,0); il.Position = UDim2.new(0,6,0,0)
    il.BackgroundTransparency = 1; il.Text = icon; il.TextScaled = true; il.ZIndex = 7
    local tl = Instance.new("TextLabel", row)
    tl.Size = UDim2.new(1,-36,1,0); tl.Position = UDim2.new(0,32,0,0)
    tl.BackgroundTransparency = 1; tl.Text = txt; tl.TextColor3 = col
    tl.Font = Enum.Font.Gotham; tl.TextSize = 12
    tl.TextXAlignment = Enum.TextXAlignment.Left; tl.ZIndex = 7
    Y = Y + 38
    return tl
end

local function btn(h, bg, txt)
    local b = Instance.new("TextButton", scroll)
    b.Size = UDim2.new(1,-28,0,h); b.Position = UDim2.new(0,14,0,Y)
    b.BackgroundColor3 = bg; b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold; b.TextSize = 13; b.ZIndex = 6
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
    Y = Y + h + 8
    return b
end

-- ======== BUILD UI ========
local sDot, sLbl = statusBox()
local cLbl, tLbl = statRow()

gap(2); divLine()
secLabel("đŸ“Œ  VI TRI DI CHUYEN")
local p1Lbl = infoRow("đŸ¯", "Vi tri cau: Chua luu",  Color3.fromRGB(120,180,255))
local p2Lbl = infoRow("đŸª", "Vi tri NPC: Chua luu",  Color3.fromRGB(255,180,80))
local saveFishBtn = btn(38, Color3.fromRGB(25,105,215), "đŸ“   SAVE Vi tri cau hien tai")
local saveNPCBtn  = btn(38, Color3.fromRGB(115,38,185), "đŸª   SAVE Vi tri NPC hien tai")

gap(4); divLine()
secLabel("đŸ¯  DANH DAU NUT SELL / X")

-- Huong dan nho
local guide = Instance.new("TextLabel", scroll)
guide.Size = UDim2.new(1,-28,0,40); guide.Position = UDim2.new(0,14,0,Y)
guide.BackgroundColor3 = Color3.fromRGB(18,18,38); guide.BorderSizePixel = 0
guide.Text = "Bam nut de hien vong tron â†’ keo den dung nut â†’ bam vao vong tron de danh dau"
guide.TextColor3 = Color3.fromRGB(190,190,255); guide.Font = Enum.Font.Gotham
guide.TextSize = 10; guide.TextWrapped = true; guide.ZIndex = 6
Instance.new("UICorner", guide).CornerRadius = UDim.new(0,8)
Y = Y + 48

local p3Lbl = infoRow("đŸ›’", "Nut SellAll: Chua danh dau", Color3.fromRGB(100,255,180))
local p4Lbl = infoRow("âŒ", "Nut X dong:  Chua danh dau", Color3.fromRGB(255,130,180))

-- Nut hien/an SellAll
local toggleSellBtn  = btn(38, Color3.fromRGB(18,148,80),  "đŸ›’   HIEN nut danh dau SellAll")
local toggleCloseBtn = btn(38, Color3.fromRGB(180,38,58),   "âŒ   HIEN nut danh dau X")

gap(4); divLine()
local toggleBtn = btn(46, Color3.fromRGB(30,185,68), "â–¶   BAT AUTO SELL")
local tGrad = Instance.new("UIGradient", toggleBtn)
tGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(45,215,82)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18,148,50)),
})
tGrad.Rotation = 90

scroll.CanvasSize = UDim2.new(0,0,0, Y+20)

-- ======== DONG / MO MENU ========
local twI = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local pingA = nil

local function openMenu()
    menuOpen = true
    if pingA then pingA:Cancel() end
    bubble.Visible = false; bubble.Size = UDim2.new(0,58,0,58)
    frame.Visible = true; frame.Size = UDim2.new(0,0,0,0)
    TS:Create(frame, twI, {Size=UDim2.new(0,W,0,H)}):Play()
end

local function closeMenu()
    menuOpen = false
    local tw = TS:Create(frame, twI, {Size=UDim2.new(0,0,0,0)})
    tw:Play()
    tw.Completed:Connect(function()
        frame.Visible = false; bubble.Visible = true
        pingA = TS:Create(bubble,
            TweenInfo.new(0.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
            {Size=UDim2.new(0,66,0,66)})
        pingA:Play()
    end)
end

closeMenuBtn.MouseButton1Click:Connect(closeMenu)
bubble.MouseButton1Click:Connect(openMenu)

-- ======== SAVE VI TRI ========
saveFishBtn.MouseButton1Click:Connect(function()
    local c = LP.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
    if r then
        savedFishPos = r.Position
        p1Lbl.Text = "Vi tri cau: Da luu âœ“"
        p1Lbl.TextColor3 = Color3.fromRGB(80,255,120)
        saveFishBtn.BackgroundColor3 = Color3.fromRGB(12,120,48)
        saveFishBtn.Text = "âœ“   Vi tri cau da luu!"
    end
end)

saveNPCBtn.MouseButton1Click:Connect(function()
    local c = LP.Character; local r = c and c:FindFirstChild("HumanoidRootPart")
    if r then
        savedNPCPos = r.Position
        p2Lbl.Text = "Vi tri NPC: Da luu âœ“"
        p2Lbl.TextColor3 = Color3.fromRGB(255,220,60)
        saveNPCBtn.BackgroundColor3 = Color3.fromRGB(75,18,128)
        saveNPCBtn.Text = "âœ“   Vi tri NPC da luu!"
    end
end)

-- ======== TOGGLE HIEN / AN MARKER ========
local function setupToggleMarker(marker, toggleBtn, pLbl, savedKey, colorDone, lblDone, iconOff, iconOn)
    toggleBtn.MouseButton1Click:Connect(function()
        marker.Visible = not marker.Visible
        if marker.Visible then
            toggleBtn.Text = iconOn .. "   AN nut danh dau"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(180,80,20)
            statusText = "Keo vong tron den dung nut, bam vao tam de danh dau!"
        else
            toggleBtn.Text = iconOff .. "   HIEN nut danh dau"
            toggleBtn.BackgroundColor3 = (savedKey == "sell" and savedSellPos) and Color3.fromRGB(12,100,45)
                or (savedKey == "close" and savedClosePos) and Color3.fromRGB(120,18,38)
                or toggleBtn.BackgroundColor3
        end
    end)

    -- Bam vao marker = danh dau toa do con tro
    marker.MouseButton1Click:Connect(function()
        local mp = UIS:GetMouseLocation()
        local cx, cy = mp.X, mp.Y
        if savedKey == "sell" then
            savedSellPos = Vector2.new(cx, cy)
        else
            savedClosePos = Vector2.new(cx, cy)
        end
        pLbl.Text = lblDone .. " âœ“  (" .. math.floor(cx) .. "," .. math.floor(cy) .. ")"
        pLbl.TextColor3 = colorDone
        -- Marker van hien, chi doi mau confirm
        marker.BackgroundColor3 = Color3.fromRGB(30,80,180)
        toggleBtn.Text = "âœ“ " .. iconOff .. "  Da danh dau! Bam de an/hien"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(20,80,20)
        statusText = "Da danh dau! (" .. math.floor(cx) .. "," .. math.floor(cy) .. ")"
    end)
end

setupToggleMarker(sellMarker,  toggleSellBtn,  p3Lbl, "sell",  Color3.fromRGB(80,255,180),  "Nut SellAll: Da danh dau", "đŸ›’", "đŸ›’")
setupToggleMarker(closeMarker, toggleCloseBtn, p4Lbl, "close", Color3.fromRGB(255,150,200),  "Nut X dong: Da danh dau",  "âŒ", "âŒ")

-- ======== BAT / TAT ========
toggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        if not savedFishPos or not savedNPCPos then
            statusText = "Luu vi tri cau + NPC truoc!"; isRunning = false; return end
        if not savedSellPos or not savedClosePos then
            statusText = "Danh dau SellAll + X truoc!"; isRunning = false; return end
        statusText = "Dang chay..."
        task.spawn(mainLoop)
    else
        statusText = "Da tat"; stopWalk()
    end
end)

UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F then toggleBtn.MouseButton1Click:Fire() end
    if i.KeyCode == Enum.KeyCode.H then
        if menuOpen then closeMenu() else openMenu() end
    end
end)

-- ======== UPDATE ========
RS.Heartbeat:Connect(function()
    sLbl.Text = statusText
    cLbl.Text = "Ban: " .. sellCount
    tLbl.Text = isRunning and ("Cho: " .. timer .. "s") or "Cho: --"
    if isRunning then
        sLbl.TextColor3 = Color3.fromRGB(80,255,140)
        sDot.BackgroundColor3 = Color3.fromRGB(60,255,80)
        toggleBtn.Text = "â¹   TAT AUTO SELL"
        tGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(225,50,50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(155,18,18)),
        })
    else
        sLbl.TextColor3 = Color3.fromRGB(255,120,120)
        sDot.BackgroundColor3 = Color3.fromRGB(255,80,80)
        if not isRunning then
            toggleBtn.Text = "â–¶   BAT AUTO SELL"
            tGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(45,215,82)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(18,148,50)),
            })
        end
    end
    if not menuOpen then
        bubble.Text = isRunning and "â–¶" or "đŸ£"
        bubble.BackgroundColor3 = isRunning and Color3.fromRGB(200,45,45) or Color3.fromRGB(255,140,0)
    end
end)

print("[TF v11] H=menu, F=bat/tat")
