-- ================================================
-- TITAN FISHING - AUTO SELL FISH SCRIPT
-- TĂ­nh nÄƒng: Tá»± Ä‘i tá»›i NgÆ° DĂ¢n â†’ Interact â†’ BĂ¡n CĂ¡
-- ================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- â™ï¸ CĂ€I Äáº¶T
local Settings = {
    NPCName = "NgÆ° DĂ¢n",
    SellInterval = 30,
    WalkSpeed = 24,
    InteractDistance = 8,
    AutoWalk = true,
    ToggleKey = Enum.KeyCode.F,
}

local isRunning = false
local status = "Chá»..."
local sellCount = 0
local timer = 0

-- ================================================
-- TĂŒM NPC
-- ================================================
local function findNPC()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find(Settings.NPCName) then
            return obj
        end
        if obj:IsA("BasePart") and obj.Name:find(Settings.NPCName) then
            return obj
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local nameLower = obj.Name:lower()
            if nameLower:find("ngu") or nameLower:find("dan") or
               nameLower:find("fish") or nameLower:find("merchant") or
               nameLower:find("seller") or nameLower:find("shop") then
                return obj
            end
        end
    end
    return nil
end

local function getNPCPosition(npc)
    if npc:IsA("Model") then
        local root = npc:FindFirstChild("HumanoidRootPart")
            or npc:FindFirstChild("Torso")
            or npc:FindFirstChildWhichIsA("BasePart")
        if root then return root.Position end
    elseif npc:IsA("BasePart") then
        return npc.Position
    end
    return nil
end

-- ================================================
-- DI CHUYá»‚N Tá»I NPC
-- ================================================
local function walkToNPC(targetPos)
    status = "đŸ¶ Äang Ä‘i tá»›i NgÆ° DĂ¢n..."

    local path = PathfindingService:CreatePath({
        AgentHeight = 5,
        AgentRadius = 2,
        AgentCanJump = true,
    })

    local success, err = pcall(function()
        path:ComputeAsync(HumanoidRootPart.Position, targetPos)
    end)

    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for _, waypoint in ipairs(waypoints) do
            if not isRunning then return false end
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                Humanoid.Jump = true
            end
            Humanoid:MoveTo(waypoint.Position)
            local reached = Humanoid.MoveToFinished:Wait(3)
            if not reached then break end
        end
    else
        Humanoid:MoveTo(targetPos)
        Humanoid.MoveToFinished:Wait(5)
    end

    return (HumanoidRootPart.Position - targetPos).Magnitude < Settings.InteractDistance + 5
end

-- ================================================
-- CLICK NĂT INTERACT & BĂN CĂ
-- ================================================
local function clickButton(name)
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local n = gui.Name:lower()
            local t = (gui:IsA("TextButton") and gui.Text:lower()) or ""
            if n:find(name:lower()) or t:find(name:lower()) then
                if gui.Visible then
                    gui.MouseButton1Click:Fire()
                    gui.Activated:Fire()
                    return true
                end
            end
        end
    end
    return false
end

local function pressInteract()
    status = "đŸ¤ Äang Interact..."
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("interact") or n:find("npc") or n:find("talk") then
                pcall(function() v:FireServer() end)
            end
        end
    end
    clickButton("interact")
    task.wait(0.5)
end

local function pressSellFish()
    status = "đŸŸ Äang bĂ¡n cĂ¡..."
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = v.Name:lower()
            if n:find("sell") or n:find("ban") or n:find("fish") then
                pcall(function() v:FireServer() end)
                pcall(function() v:FireServer("all") end)
            end
        end
    end
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteFunction") then
            local n = v.Name:lower()
            if n:find("sell") or n:find("ban") then
                pcall(function() v:InvokeServer() end)
                pcall(function() v:InvokeServer("all") end)
            end
        end
    end
    clickButton("bĂ¡n cĂ¡")
    clickButton("ban ca")
    clickButton("sell")
    clickButton("Sell All")
    task.wait(1)
end

-- ================================================
-- VĂ’NG Láº¶P CHĂNH
-- ================================================
local function autoSellLoop()
    while isRunning do
        Character = LocalPlayer.Character
        if not Character then task.wait(1) continue end
        HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        Humanoid = Character:FindFirstChild("Humanoid")
        if not HumanoidRootPart or not Humanoid then task.wait(1) continue end

        local npc = findNPC()
        if not npc then
            status = "âŒ KhĂ´ng tĂ¬m tháº¥y NgÆ° DĂ¢n!"
            task.wait(3)
            continue
        end

        local npcPos = getNPCPosition(npc)
        if not npcPos then task.wait(2) continue end

        local dist = (HumanoidRootPart.Position - npcPos).Magnitude

        if dist > Settings.InteractDistance and Settings.AutoWalk then
            Humanoid.WalkSpeed = Settings.WalkSpeed
            walkToNPC(npcPos)
        end

        task.wait(0.3)
        pressInteract()
        task.wait(0.8)
        pressSellFish()
        task.wait(0.5)

        sellCount = sellCount + 1
        status = "âœ… ÄĂ£ bĂ¡n! Chá» " .. Settings.SellInterval .. "s..."

        local waited = 0
        while waited < Settings.SellInterval and isRunning do
            task.wait(1)
            waited = waited + 1
            timer = Settings.SellInterval - waited
        end
    end
    status = "â›” ÄĂ£ táº¯t"
end

-- ================================================
-- GUI
-- ================================================
local sg = Instance.new("ScreenGui")
sg.Name = "TitanFishHub"
sg.ResetOnSpawn = false
sg.Parent = LocalPlayer.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 200)
frame.Position = UDim2.new(0, 20, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = sg
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(255, 165, 0)
stroke.Thickness = 1.5

local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size = UDim2.new(1, 0, 1, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "đŸ£  TITAN FISHING  |  Auto Sell"
titleLbl.TextColor3 = Color3.new(1,1,1)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextScaled = true

local statusLbl = Instance.new("TextLabel", frame)
statusLbl.Size = UDim2.new(1, -16, 0, 28)
statusLbl.Position = UDim2.new(0, 8, 0, 46)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "â›” ChÆ°a báº­t"
statusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
statusLbl.Font = Enum.Font.Gotham
statusLbl.TextScaled = true
statusLbl.TextXAlignment = Enum.TextXAlignment.Left

local npcLbl = Instance.new("TextLabel", frame)
npcLbl.Size = UDim2.new(1, -16, 0, 24)
npcLbl.Position = UDim2.new(0, 8, 0, 76)
npcLbl.BackgroundTransparency = 1
npcLbl.Text = "đŸ§ NPC: " .. Settings.NPCName
npcLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
npcLbl.Font = Enum.Font.Gotham
npcLbl.TextScaled = true
npcLbl.TextXAlignment = Enum.TextXAlignment.Left

local sellLbl = Instance.new("TextLabel", frame)
sellLbl.Size = UDim2.new(1, -16, 0, 24)
sellLbl.Position = UDim2.new(0, 8, 0, 102)
sellLbl.BackgroundTransparency = 1
sellLbl.Text = "đŸŸ ÄĂ£ bĂ¡n: 0 láº§n  |  â± Chá»: --"
sellLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
sellLbl.Font = Enum.Font.Gotham
sellLbl.TextScaled = true
sellLbl.TextXAlignment = Enum.TextXAlignment.Left

local intervalLbl = Instance.new("TextLabel", frame)
intervalLbl.Size = UDim2.new(1, -16, 0, 22)
intervalLbl.Position = UDim2.new(0, 8, 0, 128)
intervalLbl.BackgroundTransparency = 1
intervalLbl.Text = "â° BĂ¡n má»—i: " .. Settings.SellInterval .. "s"
intervalLbl.TextColor3 = Color3.fromRGB(160, 160, 255)
intervalLbl.Font = Enum.Font.Gotham
intervalLbl.TextScaled = true
intervalLbl.TextXAlignment = Enum.TextXAlignment.Left

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(1, -16, 0, 36)
toggleBtn.Position = UDim2.new(0, 8, 0, 154)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "[ F ]  Báº¬T AUTO SELL"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextScaled = true
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local thread = nil

local function updateGUI()
    statusLbl.Text = status
    sellLbl.Text = "đŸŸ ÄĂ£ bĂ¡n: " .. sellCount .. " láº§n  |  â± " .. (isRunning and timer.."s" or "--")
    if isRunning then
        statusLbl.TextColor3 = Color3.fromRGB(100, 255, 140)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        toggleBtn.Text = "[ F ]  Táº®T AUTO SELL"
    else
        statusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        toggleBtn.Text = "[ F ]  Báº¬T AUTO SELL"
    end
end

RunService.Heartbeat:Connect(updateGUI)

local function toggle()
    isRunning = not isRunning
    if isRunning then
        status = "đŸ”„ Äang khá»Ÿi Ä‘á»™ng..."
        thread = task.spawn(autoSellLoop)
    else
        status = "â›” ÄĂ£ táº¯t"
        if thread then task.cancel(thread) end
        if Humanoid then Humanoid:MoveTo(HumanoidRootPart.Position) end
    end
end

toggleBtn.MouseButton1Click:Connect(toggle)
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Settings.ToggleKey then toggle() end
end)

print("[TitanFishing] âœ… Script loaded! Nháº¥n [F] Ä‘á»ƒ báº­t Auto Sell CĂ¡")
