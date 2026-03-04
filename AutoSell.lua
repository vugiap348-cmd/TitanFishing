-- TITAN FISHING AUTO SELL v5
-- Di bo toi NPC -> Ban ca -> Quay ve vi tri cau

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local isRunning = false
local statusText = "Chua bat"
local sellCount = 0
local timer = 0
local savedPos = nil  -- Vi tri cau da luu

-- ================================================
-- TIM NPC
-- ================================================
local function findNPC()
    local names = {
        "Grass Carp Fish", "GrassCarpFish",
        "Sell Fisher", "SellFisher", "Fisher",
        "Sell Fish", "Ngu Dan", "Shop", "Merchant"
    }
    for _, name in ipairs(names) do
        local found = workspace:FindFirstChild(name, true)
        if found and (found:IsA("Model") or found:IsA("BasePart")) then
            return found
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local n = obj.Name:lower()
            local isPlayer = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character == obj then isPlayer = true break end
            end
            if not isPlayer then
                if n:find("sell") or n:find("fisher") or n:find("merchant") or n:find("dealer") then
                    return obj
                end
            end
        end
    end
    return nil
end

local function getNPCPos(npc)
    if npc:IsA("Model") then
        local r = npc:FindFirstChild("HumanoidRootPart")
            or npc:FindFirstChild("Torso")
            or npc:FindFirstChild("Head")
            or npc:FindFirstChildWhichIsA("BasePart")
        if r then return r.Position end
    elseif npc:IsA("BasePart") then
        return npc.Position
    end
    return nil
end

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
            -- Dung som neu da den gan
            if (hrp.Position - targetPos).Magnitude < 8 then break end
        end
    else
        -- Fallback di thang
        hum:MoveTo(targetPos)
        local t = 0
        while t < 10 and isRunning do
            task.wait(0.2)
            t += 0.2
            if (hrp.Position - targetPos).Magnitude < 8 then break end
        end
    end
end

-- ================================================
-- INTERACT NPC
-- ================================================
local function doInteract(npc)
    statusText = "Dang interact NPC..."

    -- Thu ProximityPrompt tren NPC
    if npc then
        for _, v in ipairs(npc:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                pcall(function() fireproximityprompt(v) end)
                task.wait(0.4)
            end
        end
    end

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
            task.wait(0.4)
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

    -- Nut GUI Interact
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
-- SELL ALL
-- ================================================
local function doSellAll()
    statusText = "Dang ban tat ca ca..."
    task.wait(0.5)

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
            local n = v.Name:lower()
            if n:find("sell") then
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

        -- Kiem tra da luu vi tri chua
        if not savedPos then
            statusText = "Hay luu vi tri cau truoc!"
            task.wait(2)
            continue
        end

        -- Tim NPC
        statusText = "Dang tim NPC..."
        local npc = findNPC()
        if not npc then
            statusText = "Khong tim thay NPC!"
            task.wait(3)
            continue
        end

        local npcPos = getNPCPos(npc)
        if not npcPos then task.wait(2) continue end

        -- Di bo toi NPC
        local dist = (hrp.Position - npcPos).Magnitude
        if dist > 8 then
            walkTo(npcPos, "Di toi NPC: " .. npc.Name)
            task.wait(0.5)
        end

        -- Dung lai
        hum:MoveTo(hrp.Position)
        task.wait(0.3)

        -- Interact
        doInteract(npc)
        task.wait(0.5)

        -- Ban ca
        doSellAll()
        task.wait(0.8)

        sellCount += 1
        statusText = "Da ban lan " .. sellCount .. "! Quay ve..."

        -- Quay ve vi tri cau
        task.wait(0.5)
        walkTo(savedPos, "Dang quay ve vi tri cau...")
        task.wait(0.5)

        -- Dung lai o vi tri cau
        local char2 = LocalPlayer.Character
        local hum2 = char2 and char2:FindFirstChild("Humanoid")
        local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
        if hum2 and hrp2 then
            hum2:MoveTo(hrp2.Position)
        end

        statusText = "Ve vi tri cau! Cho " .. 30 .. "s..."

        -- Doi 30 giay
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
frame.Size = UDim2.new(0, 260, 0, 270)
frame.Position = UDim2.new(0, 10, 0.15, 0)
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
ht.Text = "TITAN FISHING | Auto Sell v5"
ht.TextColor3 = Color3.new(1,1,1)
ht.Font = Enum.Font.GothamBold
ht.TextScaled = true

-- Labels
local function lbl(posY, col, txt)
    local l = Instance.new("TextLabel", frame)
    l.Size = UDim2.new(1,-16,0,26)
    l.Position = UDim2.new(0,8,0,posY)
    l.BackgroundTransparency = 1
    l.TextColor3 = col
    l.Font = Enum.Font.Gotham
    l.TextScaled = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = txt or ""
    return l
end

local sLbl  = lbl(46,  Color3.fromRGB(255,120,120), "Chua bat")
local posLbl = lbl(74,  Color3.fromRGB(100,255,200), "Vi tri cau: Chua luu")
local nLbl  = lbl(102, Color3.fromRGB(255,200,100), "NPC: Chua tim")
local cLbl  = lbl(130, Color3.fromRGB(180,220,255), "Da ban: 0 lan")
local tLbl  = lbl(156, Color3.fromRGB(160,160,255), "Cho: --")

-- Nut LUU VI TRI
local saveBtn = Instance.new("TextButton", frame)
saveBtn.Size = UDim2.new(1,-16,0,36)
saveBtn.Position = UDim2.new(0,8,0,186)
saveBtn.BackgroundColor3 = Color3.fromRGB(30,120,200)
saveBtn.BorderSizePixel = 0
saveBtn.Text = "SAVE Vi tri cau hien tai"
saveBtn.TextColor3 = Color3.new(1,1,1)
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextScaled = true
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0,8)

saveBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        savedPos = hrp.Position
        posLbl.Text = "Vi tri cau: Da luu! âœ“"
        posLbl.TextColor3 = Color3.fromRGB(100,255,100)
        saveBtn.BackgroundColor3 = Color3.fromRGB(20,160,60)
        saveBtn.Text = "âœ“ Da luu vi tri cau!"
        print("[TitanFishing] Da luu vi tri: " .. tostring(savedPos))
    end
end)

-- Nut BAT/TAT
local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(1,-16,0,36)
toggleBtn.Position = UDim2.new(0,8,0,226)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40,180,80)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "[ F ]  BAT AUTO SELL"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextScaled = true
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,8)

-- Cap nhat NPC label
local npc = findNPC()
nLbl.Text = "NPC: " .. (npc and npc.Name or "Chua tim")

-- Update GUI
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

local thread = nil
local function toggle()
    isRunning = not isRunning
    if isRunning then
        if not savedPos then
            statusText = "Hay bam SAVE vi tri truoc!"
            isRunning = false
            return
        end
        statusText = "Dang chay..."
        thread = task.spawn(mainLoop)
    else
        statusText = "Da tat"
        if thread then task.cancel(thread) end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then hum:MoveTo(hrp.Position) end
    end
end

toggleBtn.MouseButton1Click:Connect(toggle)
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F then toggle() end
end)

print("[TitanFishing v5] Loaded! Buoc 1: Bam SAVE. Buoc 2: Nhan F de bat!")
