-- ================================================
-- TITAN FISHING - AUTO SELL v3 FIXED
-- Di toi "Sell Fisher" NPC -> Giu Interact -> Sell All
-- ================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local Settings = {
    SellInterval = 30,
    WalkSpeed = 24,
    InteractDistance = 12,
    ToggleKey = Enum.KeyCode.F,
}

local isRunning = false
local statusText = "Chua bat"
local sellCount = 0
local timer = 0

-- ================================================
-- TIM NPC BAN CA (Sell Fisher)
-- ================================================
local function findSellNPC()
    -- Tim chinh xac "Sell Fisher" hoac NPC co chu "Sell" + "Fish"
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local n = obj.Name:lower()
            if n == "sell fisher" or n == "sellisher" or
               (n:find("sell") and n:find("fish")) or
               n:find("sell fisher") then
                return obj
            end
        end
    end
    -- Tim NPC co BillboardGui hien "Sell Fish" hoac "Sell Fisher"
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BillboardGui") or obj:IsA("TextLabel") then
            local t = obj.Text and obj.Text:lower() or ""
            if t:find("sell fish") or t:find("sell fisher") then
                local model = obj:FindFirstAncestorWhichIsA("Model")
                if model then return model end
            end
        end
    end
    -- Fallback: tim NPC co ProximityPrompt "Interact" gan nhat
    local closest = nil
    local closestDist = math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                local dist = (HumanoidRootPart.Position - part.Position).Magnitude
                -- Chi lay NPC trong khoang 200 studs
                if dist < 200 and dist < closestDist then
                    closestDist = dist
                    closest = part:FindFirstAncestorWhichIsA("Model") or part
                end
            end
        end
    end
    return closest
end

local function getNPCPos(npc)
    if npc:IsA("Model") then
        local r = npc:FindFirstChild("HumanoidRootPart")
            or npc:FindFirstChild("Torso")
            or npc:FindFirstChildWhichIsA("BasePart")
        if r then return r.Position end
    elseif npc:IsA("BasePart") then
        return npc.Position
    end
    return nil
end

-- ================================================
-- DI CHUYEN TOI NPC
-- ================================================
local function walkTo(targetPos)
    statusText = "Dang di toi Sell Fisher..."
    local path = PathfindingService:CreatePath({
        AgentHeight = 5, AgentRadius = 2, AgentCanJump = true,
    })
    local ok = pcall(function()
        path:ComputeAsync(HumanoidRootPart.Position, targetPos)
    end)
    if ok and path.Status == Enum.PathStatus.Success then
        for _, wp in ipairs(path:GetWaypoints()) do
            if not isRunning then return end
            if wp.Action == Enum.PathWaypointAction.Jump then
                Humanoid.Jump = true
            end
            Humanoid:MoveTo(wp.Position)
            -- Dung lai neu da du gan
            local moved = Humanoid.MoveToFinished:Wait(3)
            local curDist = (HumanoidRootPart.Position - targetPos).Magnitude
            if curDist <= Settings.InteractDistance then break end
        end
    else
        -- Di thang
        Humanoid:MoveTo(targetPos)
        local t = 0
        while t < 8 and isRunning do
            task.wait(0.1)
            t += 0.1
            if (HumanoidRootPart.Position - targetPos).Magnitude <= Settings.InteractDistance then
                break
            end
        end
    end
end

-- ================================================
-- GIU INTERACT (ProximityPrompt hoac nut GUI)
-- ================================================
local function holdInteract(npc)
    statusText = "Giu Interact..."

    -- Thu fireproximityprompt tren NPC
    if npc then
        for _, v in ipairs(npc:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                pcall(function() fireproximityprompt(v) end)
                task.wait(0.3)
            end
        end
    end

    -- Thu tat ca ProximityPrompt trong workspace gan nhat
    local bestPP = nil
    local bestDist = math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local part = v.Parent
            if part and part:IsA("BasePart") then
                local d = (HumanoidRootPart.Position - part.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestPP = v
                end
            end
        end
    end
    if bestPP and bestDist < 20 then
        pcall(function() fireproximityprompt(bestPP) end)
        task.wait(0.5)
    end

    -- Thu RemoteEvent interact
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("interact") or n:find("npc") or n:find("talk") or n:find("open") or n:find("shop") then
                pcall(function() v:FireServer() end)
            end
        end
    end

    -- Thu click nut "Interact" tren GUI
    task.wait(0.3)
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
            local n = gui.Name:lower()
            local t = (gui:IsA("TextButton") and gui.Text:lower()) or ""
            if n:find("interact") or t:find("interact") then
                gui.MouseButton1Down:Fire()
                task.wait(1.5)
                gui.MouseButton1Up:Fire()
                gui.MouseButton1Click:Fire()
                break
            end
        end
    end

    task.wait(1)
end

-- ================================================
-- CLICK SELL ALL
-- ================================================
local function clickSellAll()
    statusText = "Dang bam Sell All..."

    -- Doi popup hien ra
    task.wait(0.5)

    -- Tim nut "Sell All" chinh xac
    for i = 1, 5 do -- Thu 5 lan
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                local n = gui.Name:lower()
                local t = (gui:IsA("TextButton") and gui.Text:lower()) or ""
                -- Khop "SellAll" hoac "Sell All"
                if n == "sellall" or t == "sell all" or
                   n:find("sellall") or t:find("sell all") or
                   (t:find("sell") and t:find("all")) then
                    gui.MouseButton1Click:Fire()
                    statusText = "Da bam Sell All!"
                    task.wait(0.5)
                    return true
                end
            end
        end
        task.wait(0.3)
    end

    -- Fallback: thu RemoteEvent sell
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
                pcall(function() v:InvokeServer() end)
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
        -- Cap nhat character
        Character = LocalPlayer.Character
        if not Character then task.wait(1) continue end
        HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        Humanoid = Character:FindFirstChild("Humanoid")
        if not HumanoidRootPart or not Humanoid then task.wait(1) continue end

        -- Tim NPC
        statusText = "Dang tim Sell Fisher NPC..."
        local npc = findSellNPC()
        if not npc then
            statusText = "Khong tim thay NPC! Thu lai..."
            task.wait(3)
            continue
        end

        local npcPos = getNPCPos(npc)
        if not npcPos then task.wait(2) continue end

        -- Di toi NPC
        local dist = (HumanoidRootPart.Position - npcPos).Magnitude
        if dist > Settings.InteractDistance then
            Humanoid.WalkSpeed = Settings.WalkSpeed
            walkTo(npcPos)
        end

        -- Dung lai dung cho
        Humanoid:MoveTo(HumanoidRootPart.Position)
        task.wait(0.3)

        -- Kiem tra khoang cach lan 2
        local dist2 = (HumanoidRootPart.Position - npcPos).Magnitude
        if dist2 > Settings.InteractDistance + 5 then
            statusText = "Chua toi NPC, di lai..."
            continue
        end

        -- Giu Interact
        holdInteract(npc)
        task.wait(0.5)

        -- Click Sell All
        clickSellAll()
        task.wait(0.5)

        sellCount += 1
        statusText = "Da ban lan " .. sellCount .. "! Cho " .. Settings.SellInterval .. "s..."

        -- Doi interval
        timer = Settings.SellInterval
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
local oldGui = LocalPlayer.PlayerGui:FindFirstChild("TitanFishHub")
if oldGui then oldGui:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "TitanFishHub"
sg.ResetOnSpawn = false
sg.Parent = LocalPlayer.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 220)
frame.Position = UDim2.new(0, 10, 0.25, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local st = Instance.new("UIStroke", frame)
st.Color = Color3.fromRGB(255, 165, 0)
st.Thickness = 1.5

-- Header
local hdr = Instance.new("Frame", frame)
hdr.Size = UDim2.new(1, 0, 0, 40)
hdr.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
hdr.BorderSizePixel = 0
Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 12)
local htl = Instance.new("TextLabel", hdr)
htl.Size = UDim2.new(1, 0, 1, 0)
htl.BackgroundTransparency = 1
htl.Text = "TITAN FISHING | Auto Sell v3"
htl.TextColor3 = Color3.new(1,1,1)
htl.Font = Enum.Font.GothamBold
htl.TextScaled = true

-- Labels
local function makeLabel(parent, posY, color)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1, -16, 0, 26)
    l.Position = UDim2.new(0, 8, 0, posY)
    l.BackgroundTransparency = 1
    l.TextColor3 = color
    l.Font = Enum.Font.Gotham
    l.TextScaled = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local statusLbl = makeLabel(frame, 46, Color3.fromRGB(255,120,120))
statusLbl.Text = "Chua bat"

local npcLbl = makeLabel(frame, 74, Color3.fromRGB(255,200,100))
npcLbl.Text = "NPC: Sell Fisher"

local sellLbl = makeLabel(frame, 102, Color3.fromRGB(180,220,255))
sellLbl.Text = "Da ban: 0 lan"

local timerLbl = makeLabel(frame, 128, Color3.fromRGB(160,160,255))
timerLbl.Text = "Cho: --"

-- Toggle button
local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(1, -16, 0, 38)
toggleBtn.Position = UDim2.new(0, 8, 0, 166)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "[ F ]  BAT AUTO SELL"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextScaled = true
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

-- Update GUI
RunService.Heartbeat:Connect(function()
    statusLbl.Text = statusText
    sellLbl.Text = "Da ban: " .. sellCount .. " lan"
    timerLbl.Text = isRunning and ("Cho: " .. timer .. "s") or "Cho: --"
    if isRunning then
        statusLbl.TextColor3 = Color3.fromRGB(100,255,140)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
        toggleBtn.Text = "[ F ]  TAT AUTO SELL"
    else
        statusLbl.TextColor3 = Color3.fromRGB(255,120,120)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40,180,80)
        toggleBtn.Text = "[ F ]  BAT AUTO SELL"
    end
end)

local thread = nil
local function toggle()
    isRunning = not isRunning
    if isRunning then
        statusText = "Dang khoi dong..."
        thread = task.spawn(mainLoop)
    else
        statusText = "Da tat"
        if thread then task.cancel(thread) end
        if Humanoid then Humanoid:MoveTo(HumanoidRootPart.Position) end
    end
end

toggleBtn.MouseButton1Click:Connect(toggle)
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Settings.ToggleKey then toggle() end
end)

print("[TitanFishing v3] Script loaded! Nhan F de bat!")
