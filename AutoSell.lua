-- TITAN FISHING AUTO SELL v4
-- Teleport toi NPC -> Interact -> Sell All

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local isRunning = false
local statusText = "Chua bat"
local sellCount = 0
local timer = 0

-- ================================================
-- DEBUG: In ra tat ca Model trong workspace
-- ================================================
local function debugPrintNPCs()
    print("=== DANH SACH MODEL TRONG WORKSPACE ===")
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name ~= "Workspace" then
            print("Model: " .. obj.Name)
        end
    end
    print("=== HET DANH SACH ===")
end

-- ================================================
-- TIM NPC (tat ca kieu)
-- ================================================
local function findNPC()
    -- Thu tim theo ten chinh xac truoc
    local names = {
        "Sell Fisher", "SellFisher", "Fisher", "Sell Fish",
        "Ngu Dan", "NguDan", "Shop", "Merchant", "Dealer",
        "FishSeller", "Fish Seller", "Fish Merchant"
    }
    for _, name in ipairs(names) do
        local found = workspace:FindFirstChild(name, true)
        if found and (found:IsA("Model") or found:IsA("BasePart")) then
            return found
        end
    end

    -- Tim theo keyword
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local n = obj.Name:lower()
            if n:find("sell") or n:find("fish") or n:find("shop") or
               n:find("ngu") or n:find("merchant") or n:find("dealer") then
                -- Bo qua nhung model la player
                local isPlayer = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character == obj then isPlayer = true break end
                end
                if not isPlayer then
                    return obj
                end
            end
        end
    end

    -- Tim NPC co ProximityPrompt
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local model = obj:FindFirstAncestorWhichIsA("Model")
            if model then
                local isPlayer = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character == model then isPlayer = true break end
                end
                if not isPlayer then return model end
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
-- TELEPORT TOI NPC
-- ================================================
local function teleportToNPC(pos)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    -- Teleport lui 5 studs de khong stuck vao NPC
    local offset = Vector3.new(5, 0, 5)
    hrp.CFrame = CFrame.new(pos + offset)
    task.wait(0.5)
end

-- ================================================
-- INTERACT NPC
-- ================================================
local function doInteract(npc)
    statusText = "Dang interact NPC..."

    -- 1. Thu fireproximityprompt
    if npc then
        for _, v in ipairs(npc:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                pcall(function() fireproximityprompt(v) end)
                task.wait(0.5)
            end
        end
    end

    -- 2. Thu tat ca ProximityPrompt gan nhat
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

    -- 3. Thu RemoteEvent
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("interact") or n:find("npc") or n:find("talk")
            or n:find("shop") or n:find("open") then
                pcall(function() v:FireServer() end)
            end
        end
    end

    -- 4. Thu click nut GUI Interact
    task.wait(0.3)
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
            local n = gui.Name:lower()
            local t = gui:IsA("TextButton") and gui.Text:lower() or ""
            if n:find("interact") or t:find("interact") then
                gui.MouseButton1Down:Fire()
                task.wait(1)
                gui.MouseButton1Up:Fire()
                gui.MouseButton1Click:Fire()
            end
        end
    end

    task.wait(1)
end

-- ================================================
-- SELL ALL
-- ================================================
local function doSellAll()
    statusText = "Dang bam Sell All..."
    task.wait(0.5)

    -- Thu click nut SellAll trong GUI
    for i = 1, 8 do
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
    -- In debug de biet NPC ten gi
    debugPrintNPCs()

    while isRunning do
        local char = LocalPlayer.Character
        if not char then task.wait(1) continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum then task.wait(1) continue end

        -- Tim NPC
        statusText = "Dang tim NPC..."
        local npc = findNPC()

        if not npc then
            statusText = "KHONG TIM THAY NPC! Xem console (F9)"
            task.wait(3)
            continue
        end

        statusText = "Tim thay: " .. npc.Name
        local npcPos = getNPCPos(npc)
        if not npcPos then task.wait(2) continue end

        -- Teleport toi gan NPC
        teleportToNPC(npcPos)
        task.wait(0.5)

        -- Interact
        doInteract(npc)
        task.wait(0.8)

        -- Sell All
        doSellAll()
        task.wait(0.5)

        sellCount += 1
        statusText = "Da ban lan " .. sellCount .. "!"

        -- Doi
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
frame.Size = UDim2.new(0, 260, 0, 230)
frame.Position = UDim2.new(0, 10, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(15,15,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(255,165,0)
stroke.Thickness = 1.5

local hdr = Instance.new("Frame", frame)
hdr.Size = UDim2.new(1,0,0,40)
hdr.BackgroundColor3 = Color3.fromRGB(200,100,0)
hdr.BorderSizePixel = 0
Instance.new("UICorner", hdr).CornerRadius = UDim.new(0,12)
local ht = Instance.new("TextLabel", hdr)
ht.Size = UDim2.new(1,0,1,0)
ht.BackgroundTransparency = 1
ht.Text = "TITAN FISHING | Auto Sell v4"
ht.TextColor3 = Color3.new(1,1,1)
ht.Font = Enum.Font.GothamBold
ht.TextScaled = true

local function lbl(posY, col)
    local l = Instance.new("TextLabel", frame)
    l.Size = UDim2.new(1,-16,0,26)
    l.Position = UDim2.new(0,8,0,posY)
    l.BackgroundTransparency = 1
    l.TextColor3 = col
    l.Font = Enum.Font.Gotham
    l.TextScaled = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local sLbl = lbl(46, Color3.fromRGB(255,120,120))
sLbl.Text = "Chua bat"
local nLbl = lbl(74, Color3.fromRGB(255,200,100))
nLbl.Text = "NPC: Chua tim"
local cLbl = lbl(102, Color3.fromRGB(180,220,255))
cLbl.Text = "Da ban: 0 lan"
local tLbl = lbl(128, Color3.fromRGB(160,160,255))
tLbl.Text = "Cho: --"

-- Debug button
local dbgBtn = Instance.new("TextButton", frame)
dbgBtn.Size = UDim2.new(1,-16,0,28)
dbgBtn.Position = UDim2.new(0,8,0,156)
dbgBtn.BackgroundColor3 = Color3.fromRGB(60,60,120)
dbgBtn.BorderSizePixel = 0
dbgBtn.Text = "DEBUG: In ten NPC (F9)"
dbgBtn.TextColor3 = Color3.new(1,1,1)
dbgBtn.Font = Enum.Font.Gotham
dbgBtn.TextScaled = true
Instance.new("UICorner", dbgBtn).CornerRadius = UDim.new(0,6)
dbgBtn.MouseButton1Click:Connect(debugPrintNPCs)

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(1,-16,0,36)
toggleBtn.Position = UDim2.new(0,8,0,186)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40,180,80)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "[ F ]  BAT AUTO SELL"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextScaled = true
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,8)

local npc = findNPC()
nLbl.Text = "NPC: " .. (npc and npc.Name or "Chua tim")

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
        statusText = "Dang chay..."
        thread = task.spawn(mainLoop)
    else
        statusText = "Da tat"
        if thread then task.cancel(thread) end
    end
end

toggleBtn.MouseButton1Click:Connect(toggle)
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Settings and Settings.ToggleKey then toggle()
    elseif i.KeyCode == Enum.KeyCode.F then toggle() end
end)

print("[TitanFishing v4] Loaded! Nhan F de bat. Nhan DEBUG de xem ten NPC.")
