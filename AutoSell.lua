-- TITAN FISHING AUTO SELL v9
-- 2 nut SAVE toa do: SellAll + X

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local VIM = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local isRunning = false
local menuOpen = true
local statusText = "Chua bat"
local sellCount = 0
local timer = 0
local savedFishPos = nil
local savedNPCPos = nil
local savedSellAllPos = nil  -- Toa do nut SellAll (tap de luu)
local savedClosePos = nil    -- Toa do nut X dong popup (tap de luu)
local waitingSellAll = false -- Dang cho nguoi dung tap SellAll
local waitingClose = false   -- Dang cho nguoi dung tap X

-- ================================================
-- CLICK TOA DO
-- ================================================
local function clickAt(x, y)
    VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.08)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    task.wait(0.1)
end

local function fireAll(obj)
    pcall(function() obj.MouseButton1Down:Fire() end)
    task.wait(0.05)
    pcall(function() obj.MouseButton1Up:Fire() end)
    pcall(function() obj.MouseButton1Click:Fire() end)
    pcall(function() obj.Activated:Fire() end)
    pcall(function()
        local p = obj.AbsolutePosition
        local s = obj.AbsoluteSize
        clickAt(p.X + s.X/2, p.Y + s.Y/2)
    end)
end

-- ================================================
-- DI BO
-- ================================================
local function walkTo(targetPos, label)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    statusText = label or "Dang di..."
    hum.WalkSpeed = 24
    local path = PathfindingService:CreatePath({AgentHeight=5,AgentRadius=2,AgentCanJump=true})
    local ok = pcall(function() path:ComputeAsync(hrp.Position, targetPos) end)
    if ok and path.Status == Enum.PathStatus.Success then
        for _, wp in ipairs(path:GetWaypoints()) do
            if not isRunning then return end
            if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
            hum:MoveTo(wp.Position)
            hum.MoveToFinished:Wait(3)
            if (hrp.Position - targetPos).Magnitude < 8 then break end
        end
    else
        hum:MoveTo(targetPos)
        local t = 0
        while t < 12 and isRunning do
            task.wait(0.2); t += 0.2
            if (hrp.Position - targetPos).Magnitude < 8 then break end
        end
    end
end

-- ================================================
-- INTERACT NPC
-- ================================================
local function doInteract()
    statusText = "Mo cua hang..."
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
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
            if n:find("interact") or n:find("npc") or n:find("talk") or n:find("shop") or n:find("open") then
                pcall(function() v:FireServer() end)
            end
        end
    end
    task.wait(0.3)
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
            local n = gui.Name:lower()
            local t = gui:IsA("TextButton") and gui.Text:lower() or ""
            if n:find("interact") or t:find("interact") then
                gui.MouseButton1Down:Fire()
                task.wait(1.2)
                gui.MouseButton1Up:Fire()
                gui.MouseButton1Click:Fire()
            end
        end
    end
    task.wait(0.8)
end

-- ================================================
-- SELL ALL - DUNG TOA DO DA LUU
-- ================================================
local function doSellAll()
    -- Kiem tra da luu chua
    if not savedSellAllPos then
        statusText = "Chua luu toa do SellAll!"
        task.wait(2)
        return false
    end
    if not savedClosePos then
        statusText = "Chua luu toa do nut X!"
        task.wait(2)
        return false
    end

    statusText = "Cho popup hien ra..."
    task.wait(0.8)

    -- Click SellAll bang toa do da luu
    statusText = "Click SellAll..."
    clickAt(savedSellAllPos.X, savedSellAllPos.Y)
    task.wait(1)

    -- Click X dong popup
    statusText = "Dong popup X..."
    clickAt(savedClosePos.X, savedClosePos.Y)
    task.wait(0.5)

    statusText = "Da ban xong!"
    return true
end

-- ================================================
-- VONG LAP CHINH
-- ================================================
local function mainLoop()
    while isRunning do
        local char = LocalPlayer.Character
        if not char then task.wait(1) continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum then task.wait(1) continue end

        if not savedFishPos then statusText = "Chua luu vi tri cau!" task.wait(2) continue end
        if not savedNPCPos then statusText = "Chua luu vi tri NPC!" task.wait(2) continue end
        if not savedSellAllPos then statusText = "Chua luu toa do SellAll!" task.wait(2) continue end
        if not savedClosePos then statusText = "Chua luu toa do nut X!" task.wait(2) continue end

        walkTo(savedNPCPos, "Di toi NPC ban ca...")
        if not isRunning then break end
        task.wait(0.3)
        local c=LocalPlayer.Character
        local h=c and c:FindFirstChild("Humanoid")
        local r=c and c:FindFirstChild("HumanoidRootPart")
        if h and r then h:MoveTo(r.Position) end
        task.wait(0.3)

        doInteract()
        task.wait(0.5)
        doSellAll()
        task.wait(0.5)

        sellCount += 1
        statusText = "Da ban lan " .. sellCount .. "!"

        walkTo(savedFishPos, "Quay ve vi tri cau...")
        if not isRunning then break end
        local c2=LocalPlayer.Character
        local h2=c2 and c2:FindFirstChild("Humanoid")
        local r2=c2 and c2:FindFirstChild("HumanoidRootPart")
        if h2 and r2 then h2:MoveTo(r2.Position) end

        statusText = "Cho ban tiep..."
        timer = 30
        while timer > 0 and isRunning do task.wait(1); timer -= 1 end
    end
    statusText = "Da tat"
end

-- ================================================
-- GUI
-- ================================================
local old = LocalPlayer.PlayerGui:FindFirstChild("TFHub")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "TFHub"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = LocalPlayer.PlayerGui

-- CUC TRON
local bubble = Instance.new("TextButton")
bubble.Size = UDim2.new(0,56,0,56)
bubble.Position = UDim2.new(0,16,0.5,-28)
bubble.BackgroundColor3 = Color3.fromRGB(255,140,0)
bubble.BorderSizePixel = 0
bubble.Text = "đŸ£"
bubble.TextScaled = true
bubble.Font = Enum.Font.GothamBold
bubble.Visible = false
bubble.ZIndex = 10
bubble.Active = true
bubble.Draggable = true
bubble.Parent = sg
Instance.new("UICorner", bubble).CornerRadius = UDim.new(1,0)
local bStroke = Instance.new("UIStroke", bubble)
bStroke.Color = Color3.fromRGB(255,200,80)
bStroke.Thickness = 2.5

-- FRAME CHINH
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,280,0,420)
frame.Position = UDim2.new(0,16,0.5,-210)
frame.BackgroundColor3 = Color3.fromRGB(10,10,20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.ZIndex = 5
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,16)
local mStroke = Instance.new("UIStroke", frame)
mStroke.Color = Color3.fromRGB(255,140,0)
mStroke.Thickness = 1.5

-- Header
local hdr = Instance.new("Frame", frame)
hdr.Size = UDim2.new(1,0,0,52)
hdr.BackgroundColor3 = Color3.fromRGB(20,12,40)
hdr.BorderSizePixel = 0
hdr.ZIndex = 6
Instance.new("UICorner", hdr).CornerRadius = UDim.new(0,16)
local hGrad = Instance.new("UIGradient")
hGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,120,0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,60,120)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100,40,200)),
})
hGrad.Rotation = 90
hGrad.Parent = hdr

local fishIco = Instance.new("TextLabel", hdr)
fishIco.Size = UDim2.new(0,36,0,36)
fishIco.Position = UDim2.new(0,10,0.5,-18)
fishIco.BackgroundTransparency = 1
fishIco.Text = "đŸ£"
fishIco.TextScaled = true
fishIco.ZIndex = 7

local titleL = Instance.new("TextLabel", hdr)
titleL.Size = UDim2.new(1,-100,0,28)
titleL.Position = UDim2.new(0,52,0,6)
titleL.BackgroundTransparency = 1
titleL.Text = "TITAN FISHING"
titleL.TextColor3 = Color3.new(1,1,1)
titleL.Font = Enum.Font.GothamBlack
titleL.TextScaled = true
titleL.TextXAlignment = Enum.TextXAlignment.Left
titleL.ZIndex = 7

local subL = Instance.new("TextLabel", hdr)
subL.Size = UDim2.new(1,-100,0,14)
subL.Position = UDim2.new(0,52,1,-18)
subL.BackgroundTransparency = 1
subL.Text = "Auto Sell v9"
subL.TextColor3 = Color3.fromRGB(255,200,150)
subL.Font = Enum.Font.Gotham
subL.TextSize = 11
subL.TextXAlignment = Enum.TextXAlignment.Left
subL.ZIndex = 7

local closeBtn = Instance.new("TextButton", hdr)
closeBtn.Size = UDim2.new(0,32,0,32)
closeBtn.Position = UDim2.new(1,-42,0.5,-16)
closeBtn.BackgroundColor3 = Color3.fromRGB(255,60,60)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "âœ•"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.ZIndex = 8
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)

-- CONTENT
local ct = Instance.new("Frame", frame)
ct.Size = UDim2.new(1,0,1,-52)
ct.Position = UDim2.new(0,0,0,52)
ct.BackgroundTransparency = 1
ct.ZIndex = 6

-- Status box
local sBox = Instance.new("Frame", ct)
sBox.Size = UDim2.new(1,-20,0,40)
sBox.Position = UDim2.new(0,10,0,8)
sBox.BackgroundColor3 = Color3.fromRGB(18,18,35)
sBox.BorderSizePixel = 0
sBox.ZIndex = 6
Instance.new("UICorner", sBox).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", sBox).Color = Color3.fromRGB(60,60,100)

local sDot = Instance.new("Frame", sBox)
sDot.Size = UDim2.new(0,8,0,8)
sDot.Position = UDim2.new(0,10,0.5,-4)
sDot.BackgroundColor3 = Color3.fromRGB(255,80,80)
sDot.BorderSizePixel = 0
sDot.ZIndex = 7
Instance.new("UICorner", sDot).CornerRadius = UDim.new(1,0)

local sLbl = Instance.new("TextLabel", sBox)
sLbl.Size = UDim2.new(1,-26,1,0)
sLbl.Position = UDim2.new(0,24,0,0)
sLbl.BackgroundTransparency = 1
sLbl.Text = "Chua bat"
sLbl.TextColor3 = Color3.fromRGB(255,120,120)
sLbl.Font = Enum.Font.GothamBold
sLbl.TextSize = 12
sLbl.TextXAlignment = Enum.TextXAlignment.Left
sLbl.ZIndex = 7

-- Stats
local statsRow = Instance.new("Frame", ct)
statsRow.Size = UDim2.new(1,-20,0,34)
statsRow.Position = UDim2.new(0,10,0,55)
statsRow.BackgroundTransparency = 1
statsRow.ZIndex = 6

local function statBox(xp, icon, col)
    local b = Instance.new("Frame", statsRow)
    b.Size = UDim2.new(0.48,0,1,0)
    b.Position = UDim2.new(xp,0,0,0)
    b.BackgroundColor3 = Color3.fromRGB(18,18,35)
    b.BorderSizePixel = 0
    b.ZIndex = 6
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    Instance.new("UIStroke", b).Color = Color3.fromRGB(50,50,90)
    local il = Instance.new("TextLabel", b)
    il.Size = UDim2.new(0,22,1,0); il.Position = UDim2.new(0,4,0,0)
    il.BackgroundTransparency = 1; il.Text = icon; il.TextScaled = true; il.ZIndex = 7
    local vl = Instance.new("TextLabel", b)
    vl.Size = UDim2.new(1,-28,1,0); vl.Position = UDim2.new(0,28,0,0)
    vl.BackgroundTransparency = 1; vl.TextColor3 = col
    vl.Font = Enum.Font.GothamBold; vl.TextSize = 12
    vl.TextXAlignment = Enum.TextXAlignment.Left; vl.ZIndex = 7
    return vl
end
local cLbl = statBox(0, "đŸŸ", Color3.fromRGB(100,220,255))
local tLbl = statBox(0.52, "â±", Color3.fromRGB(255,200,100))

-- Divider
local div = Instance.new("Frame", ct)
div.Size = UDim2.new(1,-20,0,1); div.Position = UDim2.new(0,10,0,96)
div.BackgroundColor3 = Color3.fromRGB(40,40,70); div.BorderSizePixel = 0; div.ZIndex = 6

-- Labels vi tri
local function rowLbl(posY, icon, txt, col)
    local row = Instance.new("Frame", ct)
    row.Size = UDim2.new(1,-20,0,26); row.Position = UDim2.new(0,10,0,posY)
    row.BackgroundColor3 = Color3.fromRGB(15,15,30); row.BorderSizePixel = 0; row.ZIndex = 6
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
    local il = Instance.new("TextLabel", row)
    il.Size = UDim2.new(0,22,1,0); il.Position = UDim2.new(0,4,0,0)
    il.BackgroundTransparency = 1; il.Text = icon; il.TextScaled = true; il.ZIndex = 7
    local tl = Instance.new("TextLabel", row)
    tl.Size = UDim2.new(1,-30,1,0); tl.Position = UDim2.new(0,28,0,0)
    tl.BackgroundTransparency = 1; tl.Text = txt; tl.TextColor3 = col
    tl.Font = Enum.Font.Gotham; tl.TextSize = 11
    tl.TextXAlignment = Enum.TextXAlignment.Left; tl.ZIndex = 7
    return tl
end

local p1Lbl = rowLbl(103, "đŸ¯", "Vi tri cau: Chua luu", Color3.fromRGB(120,180,255))
local p2Lbl = rowLbl(132, "đŸª", "Vi tri NPC: Chua luu", Color3.fromRGB(255,180,80))
local p3Lbl = rowLbl(161, "đŸ›’", "Nut SellAll: Chua luu", Color3.fromRGB(100,255,180))
local p4Lbl = rowLbl(190, "âŒ", "Nut X dong: Chua luu", Color3.fromRGB(255,120,180))

-- Buttons
local function mkBtn(posY, h, bg, txt)
    local b = Instance.new("TextButton", ct)
    b.Size = UDim2.new(1,-20,0,h); b.Position = UDim2.new(0,10,0,posY)
    b.BackgroundColor3 = bg; b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.ZIndex = 6
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
    return b
end

local saveFishBtn  = mkBtn(224, 30, Color3.fromRGB(25,100,210),  "đŸ“ SAVE Vi tri cau")
local saveNPCBtn   = mkBtn(258, 30, Color3.fromRGB(120,40,180),  "đŸª SAVE Vi tri NPC")
local saveSellBtn  = mkBtn(292, 30, Color3.fromRGB(20,140,80),   "đŸ›’ SAVE Nut SellAll (tap o day khi popup hien)")
local saveCloseBtn = mkBtn(326, 30, Color3.fromRGB(180,40,80),   "âŒ SAVE Nut X (tap o day khi popup hien)")
local toggleBtn    = mkBtn(362, 36, Color3.fromRGB(30,180,70),   "â–¶  BAT AUTO SELL")

-- Gradient toggle
local tGrad = Instance.new("UIGradient")
tGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40,210,80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20,150,60)),
})
tGrad.Rotation = 90
tGrad.Parent = toggleBtn

-- ================================================
-- DONG MO MENU
-- ================================================
local twInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local pingAnim = nil

local function openMenu()
    menuOpen = true
    if pingAnim then pingAnim:Cancel() end
    bubble.Visible = false
    bubble.Size = UDim2.new(0,56,0,56)
    frame.Visible = true
    frame.Size = UDim2.new(0,0,0,0)
    TweenService:Create(frame, twInfo, {Size=UDim2.new(0,280,0,420)}):Play()
end

local function closeMenu()
    menuOpen = false
    local tw = TweenService:Create(frame, twInfo, {Size=UDim2.new(0,0,0,0)})
    tw:Play()
    tw.Completed:Connect(function()
        frame.Visible = false
        bubble.Visible = true
        pingAnim = TweenService:Create(bubble,
            TweenInfo.new(0.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
            {Size=UDim2.new(0,64,0,64)})
        pingAnim:Play()
    end)
end

closeBtn.MouseButton1Click:Connect(closeMenu)
bubble.MouseButton1Click:Connect(openMenu)

-- ================================================
-- SAVE VI TRI
-- ================================================
saveFishBtn.MouseButton1Click:Connect(function()
    local c = LocalPlayer.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if r then
        savedFishPos = r.Position
        p1Lbl.Text = "Vi tri cau: Da luu âœ“"
        p1Lbl.TextColor3 = Color3.fromRGB(80,255,120)
        saveFishBtn.BackgroundColor3 = Color3.fromRGB(15,130,50)
        saveFishBtn.Text = "âœ“ Vi tri cau da luu!"
    end
end)

saveNPCBtn.MouseButton1Click:Connect(function()
    local c = LocalPlayer.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if r then
        savedNPCPos = r.Position
        p2Lbl.Text = "Vi tri NPC: Da luu âœ“"
        p2Lbl.TextColor3 = Color3.fromRGB(255,220,60)
        saveNPCBtn.BackgroundColor3 = Color3.fromRGB(80,20,130)
        saveNPCBtn.Text = "âœ“ Vi tri NPC da luu!"
    end
end)

-- ================================================
-- SAVE TOA DO NUT SELLALL VA X
-- Khi nguoi dung tap vao nut nay thi script
-- lay vi tri con tro chuot lam toa do luon
-- ================================================
saveSellBtn.MouseButton1Click:Connect(function()
    -- Lay toa do nut nay (nguoi dung tap vao day)
    local p = saveSellBtn.AbsolutePosition
    local s = saveSellBtn.AbsoluteSize
    savedSellAllPos = Vector2.new(p.X + s.X/2, p.Y + s.Y/2)
    p3Lbl.Text = "Nut SellAll: Da luu âœ“"
    p3Lbl.TextColor3 = Color3.fromRGB(80,255,180)
    saveSellBtn.BackgroundColor3 = Color3.fromRGB(10,100,50)
    saveSellBtn.Text = "âœ“ SellAll da luu! Tap lai de chinh"
    -- Hien thi huong dan
    statusText = "Luu SellAll xong! Bay gio luu nut X"
end)

saveCloseBtn.MouseButton1Click:Connect(function()
    local p = saveCloseBtn.AbsolutePosition
    local s = saveCloseBtn.AbsoluteSize
    savedClosePos = Vector2.new(p.X + s.X/2, p.Y + s.Y/2)
    p4Lbl.Text = "Nut X dong: Da luu âœ“"
    p4Lbl.TextColor3 = Color3.fromRGB(255,150,200)
    saveCloseBtn.BackgroundColor3 = Color3.fromRGB(120,20,50)
    saveCloseBtn.Text = "âœ“ Nut X da luu! Tap lai de chinh"
    statusText = "Tat ca da san sang!"
end)

-- ================================================
-- BAT / TAT
-- ================================================
toggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        if not savedFishPos or not savedNPCPos then
            statusText = "Luu vi tri cau + NPC truoc!"
            isRunning = false; return
        end
        if not savedSellAllPos or not savedClosePos then
            statusText = "Luu toa do SellAll + X truoc!"
            isRunning = false; return
        end
        statusText = "Dang chay..."
        task.spawn(mainLoop)
    else
        statusText = "Da tat"
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if h and r then h:MoveTo(r.Position) end
    end
end)

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F then toggleBtn.MouseButton1Click:Fire() end
    if i.KeyCode == Enum.KeyCode.H then
        if menuOpen then closeMenu() else openMenu() end
    end
end)

-- UPDATE
RunService.Heartbeat:Connect(function()
    sLbl.Text = statusText
    cLbl.Text = "Ban: " .. sellCount
    tLbl.Text = isRunning and ("Cho: "..timer.."s") or "Cho: --"
    if isRunning then
        sLbl.TextColor3 = Color3.fromRGB(80,255,140)
        sDot.BackgroundColor3 = Color3.fromRGB(80,255,80)
        toggleBtn.Text = "â¹  TAT AUTO SELL"
        tGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(220,50,50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160,20,20)),
        })
    else
        sLbl.TextColor3 = Color3.fromRGB(255,120,120)
        sDot.BackgroundColor3 = Color3.fromRGB(255,80,80)
        toggleBtn.Text = "â–¶  BAT AUTO SELL"
        tGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40,210,80)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20,150,60)),
        })
    end
    if not menuOpen then
        bubble.Text = isRunning and "â–¶" or "đŸ£"
        bubble.BackgroundColor3 = isRunning and Color3.fromRGB(200,50,50) or Color3.fromRGB(255,140,0)
    end
end)

print("[TitanFishing v9] Loaded!")
print("Buoc 1: SAVE vi tri cau")
print("Buoc 2: SAVE vi tri NPC")  
print("Buoc 3: Mo popup ban ca -> SAVE toa do SellAll (drag nut xanh len dung vi tri SellAll)")
print("Buoc 4: SAVE toa do nut X tuong tu")
print("Buoc 5: Nhan F de bat!")
