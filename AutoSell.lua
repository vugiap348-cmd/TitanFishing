-- TITAN FISHING AUTO SELL v8
-- Menu hien dai: dong/mo, thu nho thanh cuc tron

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local isRunning = false
local menuOpen = true
local statusText = "Chua bat"
local sellCount = 0
local timer = 0
local savedFishPos = nil
local savedNPCPos = nil

-- ================================================
-- DI BO TOI VI TRI
-- ================================================
local function walkTo(targetPos, label)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    statusText = label or "Dang di chuyen..."
    hum.WalkSpeed = 24
    local path = PathfindingService:CreatePath({ AgentHeight=5, AgentRadius=2, AgentCanJump=true })
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
-- CLICK NUT
-- ================================================
local function clickBtn(keywords, holdTime)
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
            local n = gui.Name:lower()
            local t = gui:IsA("TextButton") and gui.Text:lower() or ""
            for _, kw in ipairs(keywords) do
                if n:find(kw) or t:find(kw) then
                    if holdTime then
                        gui.MouseButton1Down:Fire()
                        task.wait(holdTime)
                        gui.MouseButton1Up:Fire()
                    end
                    gui.MouseButton1Click:Fire()
                    return true
                end
            end
        end
    end
    return false
end

-- ================================================
-- INTERACT NPC
-- ================================================
local function doInteract()
    statusText = "Mo cua hang NPC..."
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
    clickBtn({"interact"}, 1.2)
    task.wait(0.8)
end

-- ================================================
-- SELL ALL - CLICK TOA DO MAN HINH
-- ================================================
local VIM = game:GetService("VirtualInputManager")

-- Click tai toa do tuyet doi
local function clickAt(x, y)
    VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
    task.wait(0.08)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    task.wait(0.1)
end

-- Fire moi cach co the
local function fireAll(obj)
    pcall(function() obj.MouseButton1Down:Fire() end)
    task.wait(0.05)
    pcall(function() obj.MouseButton1Up:Fire() end)
    pcall(function() obj.MouseButton1Click:Fire() end)
    pcall(function() obj.Activated:Fire() end)
    -- Click theo toa do
    pcall(function()
        local p = obj.AbsolutePosition
        local s = obj.AbsoluteSize
        clickAt(p.X + s.X/2, p.Y + s.Y/2)
    end)
end

local function doSellAll()
    statusText = "Cho popup Sell All..."
    task.wait(0.8)

    -- Cach 1: Tim nut theo TEN chinh xac, khong check Visible
    for attempt = 1, 25 do
        local found = false
        for _, obj in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            local n = obj.Name
            local t = ""
            pcall(function() t = obj.Text end)

            if n == "SellAll" or n == "Sell All"
            or t == "Sell All" or t == "SellAll"
            or n:lower() == "sellall" or t:lower() == "sell all" then
                statusText = "Click SellAll lan " .. attempt
                fireAll(obj)
                found = true
                task.wait(1)
                break
            end
        end

        if found then
            -- Dong nut X
            task.wait(0.3)
            for _, obj in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                local n = obj.Name:lower()
                local t = ""
                pcall(function() t = obj.Text end)
                if n == "close" or n:find("close") or n:find("exit")
                or t == "X" or t == "x" or t == "âœ•" then
                    fireAll(obj)
                    break
                end
            end

            -- Cach 2: Click toa do co dinh nut X tren man hinh
            -- Nut X o vi tri ~450, ~1090 (theo anh chup)
            task.wait(0.2)
            clickAt(452, 1090)
            statusText = "Da ban xong!"
            return true
        end

        task.wait(0.3)
    end

    -- Cach 2: Click toa do co dinh nut SellAll (theo anh: ~252, ~635)
    statusText = "Click toa do SellAll..."
    clickAt(252, 635)
    task.wait(0.8)
    -- Dong X
    clickAt(452, 1090)
    task.wait(0.3)

    -- Fallback RemoteEvent
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("sell") then
                pcall(function() v:FireServer("all") end)
                pcall(function() v:FireServer(true) end)
                pcall(function() v:FireServer() end)
            end
        end
        if v:IsA("RemoteFunction") then
            if v.Name:lower():find("sell") then
                pcall(function() v:InvokeServer("all") end)
            end
        end
    end
    return false
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
        if not savedNPCPos  then statusText = "Chua luu vi tri NPC!" task.wait(2) continue end

        walkTo(savedNPCPos, "Di toi NPC ban ca...")
        if not isRunning then break end
        task.wait(0.3)
        local c=LocalPlayer.Character; local h=c and c:FindFirstChild("Humanoid"); local r=c and c:FindFirstChild("HumanoidRootPart")
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
        local c2=LocalPlayer.Character; local h2=c2 and c2:FindFirstChild("Humanoid"); local r2=c2 and c2:FindFirstChild("HumanoidRootPart")
        if h2 and r2 then h2:MoveTo(r2.Position) end

        statusText = "Dang cho ban tiep..."
        timer = 30
        while timer > 0 and isRunning do task.wait(1); timer -= 1 end
    end
    statusText = "Da tat"
end

-- ================================================
-- GUI HIEN DAI
-- ================================================
local old = LocalPlayer.PlayerGui:FindFirstChild("TFHub")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "TFHub"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = LocalPlayer.PlayerGui

-- === CUC TRON KHI DONG MENU ===
local bubble = Instance.new("TextButton")
bubble.Name = "Bubble"
bubble.Size = UDim2.new(0, 56, 0, 56)
bubble.Position = UDim2.new(0, 16, 0.5, -28)
bubble.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
bubble.BorderSizePixel = 0
bubble.Text = "đŸ£"
bubble.TextScaled = true
bubble.Font = Enum.Font.GothamBold
bubble.TextColor3 = Color3.new(1,1,1)
bubble.Visible = false
bubble.ZIndex = 10
bubble.Active = true
bubble.Draggable = true
bubble.Parent = sg
Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)

-- Hieu ung nhip tim cho bubble
local bubbleStroke = Instance.new("UIStroke", bubble)
bubbleStroke.Color = Color3.fromRGB(255, 200, 80)
bubbleStroke.Thickness = 2.5

-- === MENU CHINH ===
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 280, 0, 340)
frame.Position = UDim2.new(0, 16, 0.5, -170)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.ZIndex = 5
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

-- Vien ngoai sang
local mainStroke = Instance.new("UIStroke", frame)
mainStroke.Color = Color3.fromRGB(255, 140, 0)
mainStroke.Thickness = 1.5

-- Gradient nen
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 14, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 18)),
})
grad.Rotation = 135
grad.Parent = frame

-- === HEADER ===
local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1, 0, 0, 52)
header.BackgroundColor3 = Color3.fromRGB(20, 12, 40)
header.BorderSizePixel = 0
header.ZIndex = 6
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local headerGrad = Instance.new("UIGradient")
headerGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 60, 120)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 40, 200)),
})
headerGrad.Rotation = 90
headerGrad.Parent = header

-- Icon ca
local fishIcon = Instance.new("TextLabel", header)
fishIcon.Size = UDim2.new(0, 36, 0, 36)
fishIcon.Position = UDim2.new(0, 10, 0.5, -18)
fishIcon.BackgroundTransparency = 1
fishIcon.Text = "đŸ£"
fishIcon.TextScaled = true
fishIcon.ZIndex = 7

-- Ten game
local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size = UDim2.new(1, -100, 1, 0)
titleLbl.Position = UDim2.new(0, 52, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "TITAN FISHING"
titleLbl.TextColor3 = Color3.new(1, 1, 1)
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextScaled = true
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 7

local subLbl = Instance.new("TextLabel", header)
subLbl.Size = UDim2.new(1, -100, 0, 16)
subLbl.Position = UDim2.new(0, 52, 1, -18)
subLbl.BackgroundTransparency = 1
subLbl.Text = "Auto Sell v8"
subLbl.TextColor3 = Color3.fromRGB(255, 200, 150)
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 11
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.ZIndex = 7

-- Nut dong menu (X)
local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -42, 0.5, -16)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "âœ•"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.ZIndex = 8
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

-- === NOI DUNG MENU ===
local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, 0, 1, -52)
content.Position = UDim2.new(0, 0, 0, 52)
content.BackgroundTransparency = 1
content.ZIndex = 6

-- STATUS BOX
local statusBox = Instance.new("Frame", content)
statusBox.Size = UDim2.new(1, -20, 0, 44)
statusBox.Position = UDim2.new(0, 10, 0, 10)
statusBox.BackgroundColor3 = Color3.fromRGB(18, 18, 35)
statusBox.BorderSizePixel = 0
statusBox.ZIndex = 6
Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 10)
local statusStroke = Instance.new("UIStroke", statusBox)
statusStroke.Color = Color3.fromRGB(60, 60, 100)
statusStroke.Thickness = 1

local statusDot = Instance.new("Frame", statusBox)
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(0, 12, 0.5, -4)
statusDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 7
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local sLbl = Instance.new("TextLabel", statusBox)
sLbl.Size = UDim2.new(1, -30, 1, 0)
sLbl.Position = UDim2.new(0, 26, 0, 0)
sLbl.BackgroundTransparency = 1
sLbl.Text = "Chua bat"
sLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
sLbl.Font = Enum.Font.GothamBold
sLbl.TextSize = 13
sLbl.TextXAlignment = Enum.TextXAlignment.Left
sLbl.ZIndex = 7

-- STATS ROW
local statsRow = Instance.new("Frame", content)
statsRow.Size = UDim2.new(1, -20, 0, 36)
statsRow.Position = UDim2.new(0, 10, 0, 62)
statsRow.BackgroundTransparency = 1
statsRow.ZIndex = 6

local function statBox(parent, xPos, icon, valTxt, col)
    local box = Instance.new("Frame", parent)
    box.Size = UDim2.new(0.48, 0, 1, 0)
    box.Position = UDim2.new(xPos, 0, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(18, 18, 35)
    box.BorderSizePixel = 0
    box.ZIndex = 6
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    local sk2 = Instance.new("UIStroke", box)
    sk2.Color = Color3.fromRGB(50, 50, 90)
    sk2.Thickness = 1

    local iLbl = Instance.new("TextLabel", box)
    iLbl.Size = UDim2.new(0, 22, 1, 0)
    iLbl.Position = UDim2.new(0, 4, 0, 0)
    iLbl.BackgroundTransparency = 1
    iLbl.Text = icon
    iLbl.TextScaled = true
    iLbl.ZIndex = 7

    local vLbl = Instance.new("TextLabel", box)
    vLbl.Size = UDim2.new(1, -28, 1, 0)
    vLbl.Position = UDim2.new(0, 28, 0, 0)
    vLbl.BackgroundTransparency = 1
    vLbl.Text = valTxt
    vLbl.TextColor3 = col
    vLbl.Font = Enum.Font.GothamBold
    vLbl.TextSize = 12
    vLbl.TextXAlignment = Enum.TextXAlignment.Left
    vLbl.ZIndex = 7
    return vLbl
end

local cLbl = statBox(statsRow, 0, "đŸŸ", "Ban: 0", Color3.fromRGB(100, 220, 255))
local tLbl = statBox(statsRow, 0.52, "â±", "Cho: --", Color3.fromRGB(255, 200, 100))

-- DIVIDER
local div = Instance.new("Frame", content)
div.Size = UDim2.new(1, -20, 0, 1)
div.Position = UDim2.new(0, 10, 0, 106)
div.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
div.BorderSizePixel = 0
div.ZIndex = 6

-- VI TRI LABELS
local function posLabel(parent, posY, icon, txt, col)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -20, 0, 28)
    row.Position = UDim2.new(0, 10, 0, posY)
    row.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
    row.BorderSizePixel = 0
    row.ZIndex = 6
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local il = Instance.new("TextLabel", row)
    il.Size = UDim2.new(0, 24, 1, 0)
    il.Position = UDim2.new(0, 6, 0, 0)
    il.BackgroundTransparency = 1
    il.Text = icon
    il.TextScaled = true
    il.ZIndex = 7

    local tl = Instance.new("TextLabel", row)
    tl.Size = UDim2.new(1, -32, 1, 0)
    tl.Position = UDim2.new(0, 30, 0, 0)
    tl.BackgroundTransparency = 1
    tl.Text = txt
    tl.TextColor3 = col
    tl.Font = Enum.Font.Gotham
    tl.TextSize = 12
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.ZIndex = 7
    return tl
end

local pos1Lbl = posLabel(content, 114, "đŸ¯", "Vi tri cau: Chua luu", Color3.fromRGB(120, 180, 255))
local pos2Lbl = posLabel(content, 148, "đŸª", "Vi tri NPC: Chua luu", Color3.fromRGB(255, 180, 80))

-- BUTTONS
local function mkBtn(parent, posY, h, bg, txt, zidx)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, -20, 0, h)
    b.Position = UDim2.new(0, 10, 0, posY)
    b.BackgroundColor3 = bg
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.ZIndex = zidx or 6
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    return b
end

local saveFishBtn = mkBtn(content, 184, 34, Color3.fromRGB(25, 100, 210), "đŸ“  SAVE Vi tri cau")
local saveNPCBtn  = mkBtn(content, 224, 34, Color3.fromRGB(120, 40, 180), "đŸª  SAVE Vi tri NPC")
local toggleBtn   = mkBtn(content, 264, 40, Color3.fromRGB(30, 180, 70),  "â–¶  BAT AUTO SELL")

-- Gradient cho toggle button
local tBtnGrad = Instance.new("UIGradient")
tBtnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 210, 80)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 150, 60)),
})
tBtnGrad.Rotation = 90
tBtnGrad.Parent = toggleBtn

-- ================================================
-- DONG MO MENU (ANIMATION)
-- ================================================
local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function openMenu()
    menuOpen = true
    bubble.Visible = false
    frame.Visible = true
    frame.Size = UDim2.new(0, 0, 0, 0)
    local tween = TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0, 280, 0, 340)})
    tween:Play()
end

local function closeMenu()
    menuOpen = false
    local tween = TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0, 0, 0, 0)})
    tween:Play()
    tween.Completed:Connect(function()
        frame.Visible = false
        bubble.Visible = true
        -- Nhip tim bubble
        local ping = TweenService:Create(bubble, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {Size = UDim2.new(0, 62, 0, 62)})
        ping:Play()
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
        pos1Lbl.Text = "Vi tri cau: Da luu âœ“"
        pos1Lbl.TextColor3 = Color3.fromRGB(80, 255, 120)
        saveFishBtn.BackgroundColor3 = Color3.fromRGB(15, 130, 50)
        saveFishBtn.Text = "âœ“  Vi tri cau da luu!"
    end
end)

saveNPCBtn.MouseButton1Click:Connect(function()
    local c = LocalPlayer.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if r then
        savedNPCPos = r.Position
        pos2Lbl.Text = "Vi tri NPC: Da luu âœ“"
        pos2Lbl.TextColor3 = Color3.fromRGB(255, 220, 60)
        saveNPCBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 130)
        saveNPCBtn.Text = "âœ“  Vi tri NPC da luu!"
    end
end)

-- ================================================
-- BAT / TAT AUTO SELL
-- ================================================
toggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        if not savedFishPos or not savedNPCPos then
            statusText = "Luu CA 2 vi tri truoc!"
            isRunning = false
            return
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

-- ================================================
-- UPDATE GUI
-- ================================================
RunService.Heartbeat:Connect(function()
    sLbl.Text = statusText
    cLbl.Text = "Ban: " .. sellCount
    tLbl.Text = isRunning and ("Cho: "..timer.."s") or "Cho: --"

    if isRunning then
        sLbl.TextColor3 = Color3.fromRGB(80, 255, 140)
        statusDot.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
        toggleBtn.Text = "â¹  TAT AUTO SELL"
        tBtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 50, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 20, 20)),
        })
    else
        sLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
        statusDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        toggleBtn.Text = "â–¶  BAT AUTO SELL"
        tBtnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 210, 80)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 150, 60)),
        })
    end

    -- Bubble hien thi trang thai
    if not menuOpen then
        bubble.Text = isRunning and "â–¶" or "đŸ£"
        bubble.BackgroundColor3 = isRunning
            and Color3.fromRGB(200, 50, 50)
            or  Color3.fromRGB(255, 140, 0)
    end
end)

print("[TitanFishing v8] Loaded! F = bat/tat | H = dong/mo menu")
