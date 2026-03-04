-- TITAN FISHING AUTO SELL v7
-- Fix: Click SellAll va nut X dong popup

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local isRunning = false
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

    local path = PathfindingService:CreatePath({
        AgentHeight = 5, AgentRadius = 2, AgentCanJump = true,
    })
    local ok = pcall(function()
        path:ComputeAsync(hrp.Position, targetPos)
    end)

    if ok and path.Status == Enum.PathStatus.Success then
        for _, wp in ipairs(path:GetWaypoints()) do
            if not isRunning then return end
            if wp.Action == Enum.PathWaypointAction.Jump then
                hum.Jump = true
            end
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
-- CLICK BAT KY NUT NAO THEO TEN
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
    statusText = "Dang mo cua hang..."

    -- ProximityPrompt gan nhat
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

    -- RemoteEvent
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("interact") or n:find("npc") or n:find("talk") or n:find("shop") or n:find("open") then
                pcall(function() v:FireServer() end)
            end
        end
    end

    -- Giu nut Interact tren GUI
    task.wait(0.3)
    clickBtn({"interact"}, 1.2)

    task.wait(0.8)
end

-- ================================================
-- SELL ALL - CLICK DUNG NUT
-- ================================================
local function doSellAll()
    statusText = "Dang tim nut Sell All..."
    task.wait(0.5)

    -- Thu nhieu lan doi popup hien
    for attempt = 1, 15 do
        -- In debug tat ca nut dang hien
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                local n = gui.Name
                local t = gui:IsA("TextButton") and gui.Text or ""
                -- Click dung ten "SellAll" (chinh xac trong game)
                if n == "SellAll" or t == "Sell All" or t == "SellAll"
                or n == "sellall" then
                    gui.MouseButton1Click:Fire()
                    statusText = "Da click SellAll!"
                    task.wait(0.5)
                    -- Dong popup neu con
                    clickBtn({"close", "x", "cancel", "dong", "exit"}, nil)
                    return true
                end
            end
        end
        task.wait(0.3)
    end

    -- Fallback: tim theo keyword rong hon
    statusText = "Thu fallback sell..."
    local clicked = clickBtn({
        "sellall", "sell all", "sell_all",
        "bantattca", "ban tat ca"
    }, nil)

    if not clicked then
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
    end

    task.wait(0.5)
    -- Dong popup X neu con mo
    clickBtn({"close", "x", "cancel", "exit", "dong"}, nil)
    return clicked
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

        -- Di toi NPC
        walkTo(savedNPCPos, "Di toi NPC ban ca...")
        if not isRunning then break end
        task.wait(0.3)

        -- Dung lai
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if h and r then h:MoveTo(r.Position) end
        task.wait(0.3)

        -- Interact
        doInteract()
        task.wait(0.5)

        -- Sell All
        doSellAll()
        task.wait(0.5)

        sellCount += 1
        statusText = "Da ban lan " .. sellCount .. "! Quay ve..."

        -- Quay ve vi tri cau
        walkTo(savedFishPos, "Quay ve vi tri cau...")
        if not isRunning then break end

        -- Dung lai
        local c2 = LocalPlayer.Character
        local h2 = c2 and c2:FindFirstChild("Humanoid")
        local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
        if h2 and r2 then h2:MoveTo(r2.Position) end

        statusText = "Cho ban tiep..."
        timer = 30
        while timer > 0 and isRunning do
            task.wait(1); timer -= 1
        end
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
sg.Parent = LocalPlayer.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 265, 0, 310)
frame.Position = UDim2.new(0, 10, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(15,15,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)
local sk = Instance.new("UIStroke", frame)
sk.Color = Color3.fromRGB(255,165,0)
sk.Thickness = 1.5

local hdr = Instance.new("Frame", frame)
hdr.Size = UDim2.new(1,0,0,40)
hdr.BackgroundColor3 = Color3.fromRGB(200,100,0)
hdr.BorderSizePixel = 0
Instance.new("UICorner", hdr).CornerRadius = UDim.new(0,12)
local ht = Instance.new("TextLabel", hdr)
ht.Size = UDim2.new(1,0,1,0)
ht.BackgroundTransparency = 1
ht.Text = "TITAN FISHING | Auto Sell v7"
ht.TextColor3 = Color3.new(1,1,1)
ht.Font = Enum.Font.GothamBold
ht.TextScaled = true

local function lbl(posY, col, txt)
    local l = Instance.new("TextLabel", frame)
    l.Size = UDim2.new(1,-16,0,24)
    l.Position = UDim2.new(0,8,0,posY)
    l.BackgroundTransparency = 1
    l.TextColor3 = col
    l.Font = Enum.Font.Gotham
    l.TextScaled = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = txt
    return l
end

local function mkBtn(posY, color, txt)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1,-16,0,36)
    b.Position = UDim2.new(0,8,0,posY)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Text = txt
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextScaled = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    return b
end

local sLbl    = lbl(46,  Color3.fromRGB(255,120,120), "Chua bat")
local pos1Lbl = lbl(74,  Color3.fromRGB(100,200,255), "Vi tri cau: Chua luu")
local pos2Lbl = lbl(100, Color3.fromRGB(255,200,100), "Vi tri NPC: Chua luu")
local cLbl    = lbl(126, Color3.fromRGB(180,220,255), "Da ban: 0 lan")
local tLbl    = lbl(150, Color3.fromRGB(160,160,255), "Cho: --")

-- Nut luu vi tri cau
local saveFishBtn = mkBtn(178, Color3.fromRGB(30,120,220), "SAVE Vi tri cau (dung o cho cau)")
saveFishBtn.MouseButton1Click:Connect(function()
    local c = LocalPlayer.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if r then
        savedFishPos = r.Position
        pos1Lbl.Text = "Vi tri cau: Da luu âœ“"
        pos1Lbl.TextColor3 = Color3.fromRGB(100,255,100)
        saveFishBtn.BackgroundColor3 = Color3.fromRGB(20,150,60)
        saveFishBtn.Text = "âœ“ Vi tri cau da luu!"
    end
end)

-- Nut luu vi tri NPC
local saveNPCBtn = mkBtn(220, Color3.fromRGB(140,60,200), "SAVE Vi tri NPC (dung o NPC)")
saveNPCBtn.MouseButton1Click:Connect(function()
    local c = LocalPlayer.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if r then
        savedNPCPos = r.Position
        pos2Lbl.Text = "Vi tri NPC: Da luu âœ“"
        pos2Lbl.TextColor3 = Color3.fromRGB(255,220,80)
        saveNPCBtn.BackgroundColor3 = Color3.fromRGB(90,30,140)
        saveNPCBtn.Text = "âœ“ Vi tri NPC da luu!"
    end
end)

-- Nut Bat/Tat
local toggleBtn = mkBtn(262, Color3.fromRGB(40,180,80), "[ F ]  BAT AUTO SELL")
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
end)

RunService.Heartbeat:Connect(function()
    sLbl.Text = statusText
    cLbl.Text = "Da ban: " .. sellCount .. " lan"
    tLbl.Text = isRunning and ("Cho: "..timer.."s") or "Cho: --"
    if isRunning then
        sLbl.TextColor3 = Color3.fromRGB(100,255,140)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        toggleBtn.Text = "[ F ]  TAT AUTO SELL"
    else
        sLbl.TextColor3 = Color3.fromRGB(255,120,120)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40,180,80)
        toggleBtn.Text = "[ F ]  BAT AUTO SELL"
    end
end)

print("[TitanFishing v7] Loaded!")
