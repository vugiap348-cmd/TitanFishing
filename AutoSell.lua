-- TITAN FISHING AUTO SELL v6
-- Tu dong: Di toi NPC da luu -> Ban ca -> Quay ve vi tri cau

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local isRunning = false
local statusText = "Chua bat"
local sellCount = 0
local timer = 0
local savedFishPos = nil  -- Vi tri cau ca
local savedNPCPos = nil   -- Vi tri NPC ban ca

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
            task.wait(0.2)
            t += 0.2
            if (hrp.Position - targetPos).Magnitude < 8 then break end
        end
    end
end

-- ================================================
-- INTERACT VA BAN CA
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
        if best then
            pcall(function() fireproximityprompt(best) end)
            task.wait(0.5)
        end
    end

    -- RemoteEvent interact
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("interact") or n:find("npc") or n:find("talk") or n:find("shop") or n:find("open") then
                pcall(function() v:FireServer() end)
            end
        end
    end

    -- Nut GUI Interact (giu)
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

local function doSellAll()
    statusText = "Dang bam Sell All..."
    task.wait(0.5)

    -- Tim nut Sell All
    for i = 1, 10 do
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                local n = gui.Name:lower()
                local t = gui:IsA("TextButton") and gui.Text:lower() or ""
                if n == "sellall" or t == "sell all"
                or (n:find("sell") and n:find("all"))
                or (t:find("sell") and t:find("all")) then
                    gui.MouseButton1Click:Fire()
                    task.wait(0.3)
                    statusText = "Da ban xong!"
                    return
                end
            end
        end
        task.wait(0.2)
    end

    -- Fallback
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

        -- Kiem tra da luu ca 2 vi tri
        if not savedFishPos then
            statusText = "Chua luu vi tri cau!"
            task.wait(2) continue
        end
        if not savedNPCPos then
            statusText = "Chua luu vi tri NPC!"
            task.wait(2) continue
        end

        -- Di toi NPC
        walkTo(savedNPCPos, "Di toi NPC ban ca...")
        task.wait(0.5)

        if not isRunning then break end

        -- Dung lai
        local hum2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        local hrp2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum2 and hrp2 then hum2:MoveTo(hrp2.Position) end
        task.wait(0.3)

        -- Interact
        doInteract()
        task.wait(0.5)

        -- Ban ca
        doSellAll()
        task.wait(0.8)

        sellCount += 1
        statusText = "Da ban lan " .. sellCount .. "! Quay ve..."

        -- Quay ve vi tri cau
        task.wait(0.3)
        walkTo(savedFishPos, "Dang quay ve vi tri cau...")
        task.wait(0.5)

        -- Dung han o vi tri cau
        local hum3 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        local hrp3 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum3 and hrp3 then hum3:MoveTo(hrp3.Position) end

        statusText = "Dang cho ban tiep..."
        timer = 30
        while timer > 0 and isRunning do
            task.wait(1)
            timer -= 1
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
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(255,165,0)
stroke.Thickness = 1.5

-- Header
local hdr = Instance.new("Frame", frame)
hdr.Size = UDim2.new(1,0,0,40)
hdr.BackgroundColor3 = Color3.fromRGB(200,100,0)
hdr.BorderSizePixel = 0
Instance.new("UICorner", hdr).CornerRadius = UDim.new(0,12)
local ht = Instance.new("TextLabel", hdr)
ht.Size = UDim2.new(1,0,1,0)
ht.BackgroundTransparency = 1
ht.Text = "TITAN FISHING | Auto Sell v6"
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

local function makeBtn(posY, color, txt)
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

local sLbl   = lbl(46,  Color3.fromRGB(255,120,120), "Chua bat")
local pos1Lbl = lbl(74,  Color3.fromRGB(100,200,255), "Vi tri cau: Chua luu")
local pos2Lbl = lbl(100, Color3.fromRGB(255,200,100), "Vi tri NPC: Chua luu")
local cLbl   = lbl(126, Color3.fromRGB(180,220,255), "Da ban: 0 lan")
local tLbl   = lbl(150, Color3.fromRGB(160,160,255), "Cho: --")

-- Nut Save vi tri cau
local saveFishBtn = makeBtn(178, Color3.fromRGB(30,120,220), "SAVE Vi tri cau (dung o cho cau)")
saveFishBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        savedFishPos = hrp.Position
        pos1Lbl.Text = "Vi tri cau: Da luu âœ“"
        pos1Lbl.TextColor3 = Color3.fromRGB(100,255,100)
        saveFishBtn.BackgroundColor3 = Color3.fromRGB(20,150,60)
        saveFishBtn.Text = "âœ“ Vi tri cau da luu!"
    end
end)

-- Nut Save vi tri NPC
local saveNPCBtn = makeBtn(220, Color3.fromRGB(150,80,200), "SAVE Vi tri NPC (dung o NPC)")
saveNPCBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        savedNPCPos = hrp.Position
        pos2Lbl.Text = "Vi tri NPC: Da luu âœ“"
        pos2Lbl.TextColor3 = Color3.fromRGB(255,220,80)
        saveNPCBtn.BackgroundColor3 = Color3.fromRGB(100,40,160)
        saveNPCBtn.Text = "âœ“ Vi tri NPC da luu!"
    end
end)

-- Nut Bat/Tat
local toggleBtn = makeBtn(262, Color3.fromRGB(40,180,80), "[ F ]  BAT AUTO SELL")
toggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        if not savedFishPos or not savedNPCPos then
            statusText = "Hay luu CA 2 vi tri truoc!"
            isRunning = false
            return
        end
        statusText = "Dang chay..."
        task.spawn(mainLoop)
    else
        statusText = "Da tat"
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then hum:MoveTo(hrp.Position) end
    end
end)

UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F then
        toggleBtn.MouseButton1Click:Fire()
    end
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

print("[TitanFishing v6] Loaded!")
print("Buoc 1: Dung o cho cau ca -> Bam SAVE Vi tri cau")
print("Buoc 2: Di toi NPC ban ca -> Bam SAVE Vi tri NPC")
print("Buoc 3: Nhan F de bat!")
