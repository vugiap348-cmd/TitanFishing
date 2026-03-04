-- TITAN FISHING AUTO SELL v14
-- Vong lap day du: nem can -> ca can -> ZXCV -> ca len -> ban -> lap lai

local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("RunService")
local PFS      = game:GetService("PathfindingService")
local TS       = game:GetService("TweenService")
local VIM      = game:GetService("VirtualInputManager")
local LP       = Players.LocalPlayer

-- ============================================================
-- TRANG THAI
-- ============================================================
local isRunning    = false
local menuOpen     = true
local statusText   = "Chua bat"
local sellCount    = 0

-- Vi tri
local savedFishPos  = nil
local savedNPCPos   = nil
local savedSellPos  = nil
local savedClosePos = nil

-- Vi tri nut tren man hinh
local savedCastPos = nil          -- nut Fishing (nem can)
local zxcvPos      = {nil,nil,nil,nil}  -- Z X C V

-- Cai dat
local castWaitTime  = 6    -- thoi gian cho ca can (giay), chinh duoc
local zxcvInterval  = 0.12 -- toc do spam ZXCV
local sellEveryN    = 1    -- ban sau bao nhieu con (mac dinh: ban moi con)

-- Dem
local fishCaught   = 0
local fishSession  = 0  -- trong session hien tai

-- ============================================================
-- DETECT CA CAN / CA LEN QUA GUI
-- Scan PlayerGui tim TextLabel/Frame co lien quan
-- ============================================================
local function scanGuiForText(keywords)
    -- Tim bat ky TextLabel nao trong PlayerGui co chua keyword
    for _, obj in ipairs(LP.PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local t = obj.Text:lower()
            for _, kw in ipairs(keywords) do
                if t:find(kw:lower()) then
                    return true, obj
                end
            end
        end
    end
    return false
end

-- Detect thanh HP ca: tim Frame/ImageLabel la thanh HP (xuat hien khi ca can)
-- Titan Fishing thuong dung ScreenGui co ten nhu "FishingGui", "BattleGui", v.v.
local function isFishBiting()
    -- Cach 1: Tim thanh HP (co gia tri HP, thay doi lien tuc)
    for _, obj in ipairs(LP.PlayerGui:GetDescendants()) do
        if obj:IsA("Frame") and obj.Visible then
            local nm = obj.Name:lower()
            if nm:find("fish") or nm:find("battle") or nm:find("hp") or nm:find("health") or nm:find("combat") then
                return true
            end
        end
        -- Titan Fishing hien thi "Rare [607]" kieu nay
        if obj:IsA("TextLabel") and obj.Visible then
            local t = obj.Text:lower()
            if t:find("rare") or t:find("common") or t:find("uncommon") or t:find("epic") or t:find("legendary") or t:find("mythic") then
                -- Co thanh HP ca dang hien
                return true
            end
        end
    end
    -- Cach 2: tim text "runaway" = ca bi mat (van dang trong session)
    local found = scanGuiForText({"runaway","fish away","escaped"})
    return found
end

local function isFishCaught()
    -- Ca len: thanh HP bien mat, hoac xuat hien popup reward/item
    -- Titan Fishing: sau khi ca len, thuong co "You caught" hoac inventory update
    for _, obj in ipairs(LP.PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Visible then
            local t = obj.Text:lower()
            if t:find("caught") or t:find("you got") or t:find("obtained") or t:find("added") then
                return true
            end
        end
    end
    return false
end

-- Kiem tra nut ZXCV co hien khong (ca dang trong trang thai danh)
local function isZXCVVisible()
    for _, obj in ipairs(LP.PlayerGui:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
            local nm = obj.Name:lower()
            local t  = obj:IsA("TextButton") and obj.Text:lower() or ""
            if nm == "z" or nm == "x" or nm == "c" or nm == "v"
            or t == "z" or t == "x" or t == "c" or t == "v" then
                return true
            end
        end
    end
    return false
end

-- ============================================================
-- CLICK TOA DO
-- ============================================================
local function clickAt(x, y)
    VIM:SendMouseButtonEvent(x, y, 0, true,  game, 0)
    task.wait(0.07)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    task.wait(0.07)
end

-- ============================================================
-- DI BO
-- ============================================================
local function walkTo(pos, label)
    local char = LP.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    statusText = label or "Dang di..."
    hum.WalkSpeed = 24
    local path = PFS:CreatePath({AgentHeight=5,AgentRadius=2,AgentCanJump=true})
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

-- ============================================================
-- INTERACT NPC
-- ============================================================
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
    task.wait(0.8)
end

-- ============================================================
-- SELL ALL
-- ============================================================
local function doSellAll()
    if not savedSellPos or not savedClosePos then
        statusText = "Chua danh dau SellAll/X!"; task.wait(2); return false
    end
    statusText = "Cho popup..."
    task.wait(0.8)
    clickAt(savedSellPos.X, savedSellPos.Y)
    task.wait(1.0)
    clickAt(savedClosePos.X, savedClosePos.Y)
    task.wait(0.4)
    statusText = "Da ban xong!"
    return true
end

-- ============================================================
-- PHASE 1: NEM CAN (spam nut Fishing cho den khi ca can)
-- ============================================================
local function phase_Cast()
    statusText = "Dang nem can..."
    if not savedCastPos then
        statusText = "Chua danh dau nut Fishing!"; task.wait(3); return false
    end

    local timeout = 60  -- toi da 60 giay cho ca can
    local elapsed = 0
    local biting  = false

    while isRunning and elapsed < timeout do
        -- Nem can
        clickAt(savedCastPos.X, savedCastPos.Y)
        task.wait(0.15)

        -- Kiem tra ca can
        if isFishBiting() or isZXCVVisible() then
            biting = true
            break
        end

        elapsed += 0.15 + 0.07
        statusText = "Cho ca can... (" .. math.floor(elapsed) .. "s)"
    end

    if not biting then
        -- Fallback: sau castWaitTime giay cu chay ZXCV
        statusText = "Timeout - bat dau danh ca..."
    end
    return true
end

-- ============================================================
-- PHASE 2: DANH CA (spam ZXCV den khi ca len)
-- ============================================================
local function phase_Fight()
    statusText = "Dang danh ca! (ZXCV)"

    -- Kiem tra co nut ZXCV nao duoc luu chua
    local hasAny = false
    for i = 1,4 do if zxcvPos[i] then hasAny = true; break end end
    if not hasAny then
        statusText = "Chua danh dau nut ZXCV!"; task.wait(3); return false
    end

    local timeout = 60   -- toi da 60 giay danh ca
    local elapsed = 0
    local caught  = false

    while isRunning and elapsed < timeout do
        -- Spam ZXCV theo thu tu
        for i = 1, 4 do
            if not isRunning then break end
            if zxcvPos[i] then
                clickAt(zxcvPos[i].X, zxcvPos[i].Y)
                task.wait(zxcvInterval)
            end
        end

        elapsed += zxcvInterval * 4 + 0.07 * 4

        -- Kiem tra ca da len chua
        -- Cach 1: isFishCaught()
        if isFishCaught() then caught = true; break end
        -- Cach 2: thanh HP bien mat (khong con detect fish biting)
        if not isFishBiting() and not isZXCVVisible() and elapsed > 2 then
            -- Wait ngan roi kiem tra lai
            task.wait(0.5)
            if not isFishBiting() and not isZXCVVisible() then
                caught = true; break
            end
        end

        statusText = "Danh ca... (" .. math.floor(elapsed) .. "s) ZXCV"
    end

    if not caught then
        statusText = "Ca thoat / timeout - thu lai..."
        task.wait(1)
    else
        fishCaught += 1
        fishSession += 1
        statusText = "CA LEN! Lan " .. fishCaught
        task.wait(0.8)
    end
    return caught
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local function mainLoop()
    fishSession = 0
    while isRunning do
        local char = LP.Character; if not char then task.wait(1) continue end

        -- Kiem tra du lieu
        if not savedFishPos  then statusText = "Chua luu vi tri cau!" task.wait(2) continue end
        if not savedNPCPos   then statusText = "Chua luu vi tri NPC!" task.wait(2) continue end
        if not savedSellPos  then statusText = "Chua danh dau SellAll!" task.wait(2) continue end
        if not savedCastPos  then statusText = "Chua danh dau nut Fishing!" task.wait(2) continue end

        -- Kiem tra co ZXCV chua
        local hasZXCV = false
        for i=1,4 do if zxcvPos[i] then hasZXCV = true; break end end
        if not hasZXCV then statusText = "Chua danh dau nut ZXCV!" task.wait(2) continue end

        -- STEP 1: Di ve vi tri cau
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and savedFishPos and (hrp.Position - savedFishPos).Magnitude > 5 then
            walkTo(savedFishPos, "Di ve vi tri cau...")
            if not isRunning then break end
            stopWalk()
            task.wait(0.5)
        end

        -- STEP 2: Nem can
        local ok = phase_Cast()
        if not isRunning then break end
        if not ok then continue end
        task.wait(0.3)

        -- STEP 3: Danh ca ZXCV
        local caught = phase_Fight()
        if not isRunning then break end

        if caught then
            -- STEP 4: Kiem tra co can ban khong
            if fishSession >= sellEveryN then
                fishSession = 0
                -- Di toi NPC
                walkTo(savedNPCPos, "Di toi NPC ban ca...")
                if not isRunning then break end
                task.wait(0.3); stopWalk(); task.wait(0.3)
                doInteract(); task.wait(0.5)
                doSellAll();  task.wait(0.5)
                sellCount += 1
                statusText = "Da ban lan " .. sellCount .. "! Quay lai..."
                task.wait(0.5)
            else
                statusText = "Ca len! Con " .. (sellEveryN - fishSession) .. " ca nua thi ban"
                task.wait(0.5)
            end
        end
        -- Lap lai tu dau
    end
    statusText = "Da tat"
end

-- ============================================================
-- GUI
-- ============================================================
local old = LP.PlayerGui:FindFirstChild("TFHub")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "TFHub"; sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = LP.PlayerGui

-- ======== MARKER HELPER ========
local function makeMarker(color, zidx, lbl)
    local SIZE = 62
    local m = Instance.new("TextButton")
    m.Size = UDim2.new(0,SIZE,0,SIZE)
    m.Position = UDim2.new(0.5,-SIZE/2, 0.5,-SIZE/2)
    m.BackgroundColor3 = color
    m.BackgroundTransparency = 0.1
    m.BorderSizePixel = 0; m.Text = ""
    m.ZIndex = zidx; m.Active = true
    m.Draggable = true; m.Visible = false
    m.Parent = sg
    Instance.new("UICorner", m).CornerRadius = UDim.new(1,0)
    local sk = Instance.new("UIStroke", m)
    sk.Color = Color3.new(1,1,1); sk.Thickness = 3
    -- Crosshair
    for _,sz in ipairs({
        {UDim2.new(0.6,0,0,2), UDim2.new(0.2,0,0.5,-1)},
        {UDim2.new(0,2,0.6,0), UDim2.new(0.5,-1,0.2,0)},
    }) do
        local f = Instance.new("Frame",m)
        f.Size=sz[1]; f.Position=sz[2]
        f.BackgroundColor3=Color3.new(1,1,0); f.BorderSizePixel=0; f.ZIndex=zidx+1
    end
    local dot = Instance.new("Frame",m)
    dot.Size=UDim2.new(0,8,0,8); dot.Position=UDim2.new(0.5,-4,0.5,-4)
    dot.BackgroundColor3=Color3.new(1,0,0); dot.BorderSizePixel=0; dot.ZIndex=zidx+2
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    if lbl then
        local nl = Instance.new("TextLabel",m)
        nl.Size=UDim2.new(1,0,0,16); nl.Position=UDim2.new(0,0,1,3)
        nl.BackgroundTransparency=1; nl.Text=lbl
        nl.TextColor3=Color3.new(1,1,0); nl.Font=Enum.Font.GothamBold
        nl.TextSize=11; nl.ZIndex=zidx+3
    end
    return m
end

-- Markers
local sellMarker  = makeMarker(Color3.fromRGB(20,200,100), 30, "SELL")
local closeMarker = makeMarker(Color3.fromRGB(220,40,60),  30, "CLOSE")
local castMarker  = makeMarker(Color3.fromRGB(255,200,0),  30, "FISHING")

local zxcvColors = {
    Color3.fromRGB(80,160,255),
    Color3.fromRGB(200,80,255),
    Color3.fromRGB(255,110,40),
    Color3.fromRGB(40,220,170),
}
local zxcvNames = {"Z","X","C","V"}
local zxcvMarkers = {}
for i = 1,4 do
    zxcvMarkers[i] = makeMarker(zxcvColors[i], 30, zxcvNames[i])
end

-- Nhip tim
RS.Heartbeat:Connect(function()
    local t  = tick() % 1
    local a  = math.abs(math.sin(t * math.pi))
    local ft = tick() % 0.4
    local fa = math.abs(math.sin(ft * math.pi))
    for _, m in ipairs({sellMarker, closeMarker, castMarker}) do
        if m.Visible then m.BackgroundTransparency = 0.05 + a*0.35 end
    end
    for i = 1,4 do
        local m = zxcvMarkers[i]
        if m.Visible then
            m.BackgroundTransparency = 0.05 + a*0.35
        end
    end
end)

-- ======== BUBBLE ========
local bubble = Instance.new("TextButton")
bubble.Size=UDim2.new(0,58,0,58); bubble.Position=UDim2.new(0,14,0.5,-29)
bubble.BackgroundColor3=Color3.fromRGB(255,140,0); bubble.BorderSizePixel=0
bubble.Text="đŸ£"; bubble.TextScaled=true; bubble.Font=Enum.Font.GothamBold
bubble.Visible=false; bubble.ZIndex=10; bubble.Active=true; bubble.Draggable=true
bubble.Parent=sg
Instance.new("UICorner",bubble).CornerRadius=UDim.new(1,0)
local bsk=Instance.new("UIStroke",bubble)
bsk.Color=Color3.fromRGB(255,210,80); bsk.Thickness=2.5

-- ======== FRAME CHINH ========
local W, H = 318, 860
local frame = Instance.new("Frame")
frame.Size=UDim2.new(0,W,0,H); frame.Position=UDim2.new(0,14,0.5,-H/2)
frame.BackgroundColor3=Color3.fromRGB(10,10,20); frame.BorderSizePixel=0
frame.Active=true; frame.Draggable=true; frame.ClipsDescendants=true
frame.ZIndex=5; frame.Parent=sg
Instance.new("UICorner",frame).CornerRadius=UDim.new(0,16)
local msk=Instance.new("UIStroke",frame)
msk.Color=Color3.fromRGB(255,140,0); msk.Thickness=1.5
local fg=Instance.new("UIGradient",frame)
fg.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(18,14,35)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(8,8,18)),
}); fg.Rotation=135

-- ======== HEADER ========
local hdr=Instance.new("Frame",frame)
hdr.Size=UDim2.new(1,0,0,54); hdr.BackgroundColor3=Color3.fromRGB(20,12,40)
hdr.BorderSizePixel=0; hdr.ZIndex=6
Instance.new("UICorner",hdr).CornerRadius=UDim.new(0,16)
local hg=Instance.new("UIGradient",hdr)
hg.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(255,120,0)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(200,60,120)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(100,40,200)),
}); hg.Rotation=90

local function mkLbl(p,sz,ps,tx,fn,fs,col,xa)
    local l=Instance.new("TextLabel",p); l.Size=sz; l.Position=ps
    l.BackgroundTransparency=1; l.Text=tx; l.Font=fn; l.TextSize=fs
    l.TextColor3=col or Color3.new(1,1,1)
    l.TextXAlignment=xa or Enum.TextXAlignment.Left; l.ZIndex=7; return l
end
mkLbl(hdr,UDim2.new(0,36,0,36),UDim2.new(0,10,0.5,-18),"đŸ£",Enum.Font.GothamBold,20,Color3.new(1,1,1),Enum.TextXAlignment.Center)
mkLbl(hdr,UDim2.new(1,-120,0,26),UDim2.new(0,54,0,8),"TITAN FISHING",Enum.Font.GothamBlack,17)
mkLbl(hdr,UDim2.new(1,-120,0,14),UDim2.new(0,54,1,-18),"Auto Loop v14",Enum.Font.Gotham,11,Color3.fromRGB(255,200,150))

local closeMenuBtn=Instance.new("TextButton",hdr)
closeMenuBtn.Size=UDim2.new(0,32,0,32); closeMenuBtn.Position=UDim2.new(1,-42,0.5,-16)
closeMenuBtn.BackgroundColor3=Color3.fromRGB(220,50,50); closeMenuBtn.BorderSizePixel=0
closeMenuBtn.Text="âœ•"; closeMenuBtn.TextColor3=Color3.new(1,1,1)
closeMenuBtn.Font=Enum.Font.GothamBold; closeMenuBtn.TextSize=14; closeMenuBtn.ZIndex=8
Instance.new("UICorner",closeMenuBtn).CornerRadius=UDim.new(1,0)

-- ======== SCROLL ========
local scroll=Instance.new("ScrollingFrame",frame)
scroll.Size=UDim2.new(1,0,1,-54); scroll.Position=UDim2.new(0,0,0,54)
scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
scroll.ScrollBarThickness=3; scroll.ScrollBarImageColor3=Color3.fromRGB(255,140,0)
scroll.CanvasSize=UDim2.new(0,0,0,1000); scroll.ZIndex=6

-- ======== WIDGET HELPERS ========
local Y = 8

local function gap(n) Y=Y+(n or 8) end

local function sec(txt)
    local l=Instance.new("TextLabel",scroll)
    l.Size=UDim2.new(1,-28,0,20); l.Position=UDim2.new(0,14,0,Y)
    l.BackgroundTransparency=1; l.Text=txt
    l.TextColor3=Color3.fromRGB(160,160,255)
    l.Font=Enum.Font.GothamBold; l.TextSize=11
    l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=6
    Y=Y+24
end

local function div()
    local d=Instance.new("Frame",scroll)
    d.Size=UDim2.new(1,-28,0,1); d.Position=UDim2.new(0,14,0,Y)
    d.BackgroundColor3=Color3.fromRGB(50,50,85); d.BorderSizePixel=0; d.ZIndex=6
    Y=Y+9
end

local function infoLbl(icon, txt, col)
    local r=Instance.new("Frame",scroll)
    r.Size=UDim2.new(1,-28,0,30); r.Position=UDim2.new(0,14,0,Y)
    r.BackgroundColor3=Color3.fromRGB(14,14,28); r.BorderSizePixel=0; r.ZIndex=6
    Instance.new("UICorner",r).CornerRadius=UDim.new(0,8)
    local il=Instance.new("TextLabel",r)
    il.Size=UDim2.new(0,24,1,0); il.Position=UDim2.new(0,5,0,0)
    il.BackgroundTransparency=1; il.Text=icon; il.TextScaled=true; il.ZIndex=7
    local tl=Instance.new("TextLabel",r)
    tl.Size=UDim2.new(1,-34,1,0); tl.Position=UDim2.new(0,30,0,0)
    tl.BackgroundTransparency=1; tl.Text=txt; tl.TextColor3=col
    tl.Font=Enum.Font.Gotham; tl.TextSize=11
    tl.TextXAlignment=Enum.TextXAlignment.Left; tl.ZIndex=7
    Y=Y+35
    return tl
end

local function btn(h, bg, txt)
    local b=Instance.new("TextButton",scroll)
    b.Size=UDim2.new(1,-28,0,h); b.Position=UDim2.new(0,14,0,Y)
    b.BackgroundColor3=bg; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold; b.TextSize=13; b.ZIndex=6
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)
    Y=Y+h+7
    return b
end

-- ======== STATUS BOX ========
local statusBox=Instance.new("Frame",scroll)
statusBox.Size=UDim2.new(1,-28,0,44); statusBox.Position=UDim2.new(0,14,0,Y)
statusBox.BackgroundColor3=Color3.fromRGB(14,14,30); statusBox.BorderSizePixel=0; statusBox.ZIndex=6
Instance.new("UICorner",statusBox).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",statusBox).Color=Color3.fromRGB(50,50,90)
local sDot=Instance.new("Frame",statusBox)
sDot.Size=UDim2.new(0,9,0,9); sDot.Position=UDim2.new(0,11,0.5,-4.5)
sDot.BackgroundColor3=Color3.fromRGB(255,80,80); sDot.BorderSizePixel=0; sDot.ZIndex=7
Instance.new("UICorner",sDot).CornerRadius=UDim.new(1,0)
local sLbl=Instance.new("TextLabel",statusBox)
sLbl.Size=UDim2.new(1,-28,1,0); sLbl.Position=UDim2.new(0,26,0,0)
sLbl.BackgroundTransparency=1; sLbl.Text="Chua bat"
sLbl.TextColor3=Color3.fromRGB(255,120,120)
sLbl.Font=Enum.Font.GothamBold; sLbl.TextSize=12
sLbl.TextXAlignment=Enum.TextXAlignment.Left; sLbl.ZIndex=7
Y=Y+52

-- STAT ROW
local statRow=Instance.new("Frame",scroll)
statRow.Size=UDim2.new(1,-28,0,38); statRow.Position=UDim2.new(0,14,0,Y)
statRow.BackgroundTransparency=1; statRow.ZIndex=6
local function cell(xp,icon,col)
    local b=Instance.new("Frame",statRow)
    b.Size=UDim2.new(0.31,0,1,0); b.Position=UDim2.new(xp,0,0,0)
    b.BackgroundColor3=Color3.fromRGB(14,14,30); b.BorderSizePixel=0; b.ZIndex=6
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",b).Color=Color3.fromRGB(45,45,80)
    local il=Instance.new("TextLabel",b)
    il.Size=UDim2.new(0,20,1,0); il.Position=UDim2.new(0,4,0,0)
    il.BackgroundTransparency=1; il.Text=icon; il.TextScaled=true; il.ZIndex=7
    local vl=Instance.new("TextLabel",b)
    vl.Size=UDim2.new(1,-26,1,0); vl.Position=UDim2.new(0,26,0,0)
    vl.BackgroundTransparency=1; vl.TextColor3=col
    vl.Font=Enum.Font.GothamBold; vl.TextSize=12
    vl.TextXAlignment=Enum.TextXAlignment.Left; vl.ZIndex=7
    return vl
end
local caughtLbl = cell(0,    "đŸŸ", Color3.fromRGB(100,220,255))
local sellLbl   = cell(0.34, "đŸ›’", Color3.fromRGB(100,255,160))
local sesLbl    = cell(0.68, "đŸ”„", Color3.fromRGB(255,200,80))
Y=Y+46

gap(4); div()

-- ======== SECTION: VI TRI ========
sec("đŸ“Œ  VI TRI DI CHUYEN")
local p1Lbl = infoLbl("đŸ¯","Vi tri cau: Chua luu",   Color3.fromRGB(120,180,255))
local p2Lbl = infoLbl("đŸª","Vi tri NPC: Chua luu",   Color3.fromRGB(255,180,80))
local saveFishBtn = btn(36, Color3.fromRGB(25,100,210), "đŸ“   SAVE Vi tri cau hien tai")
local saveNPCBtn  = btn(36, Color3.fromRGB(110,35,180), "đŸª   SAVE Vi tri NPC hien tai")

gap(4); div()

-- ======== SECTION: SELL / CLOSE ========
sec("đŸ›’  NUT BAN CA (danh dau toa do)")
local p3Lbl = infoLbl("đŸ›’","Nut SellAll: Chua luu", Color3.fromRGB(80,255,180))
local p4Lbl = infoLbl("âŒ","Nut X dong: Chua luu",  Color3.fromRGB(255,130,180))
local toggleSellBtn  = btn(34, Color3.fromRGB(18,140,75),  "đŸ›’   HIEN vong tron SellAll")
local toggleCloseBtn = btn(34, Color3.fromRGB(175,35,55),  "âŒ   HIEN vong tron X dong")

gap(4); div()

-- ======== SECTION: NEM CAN ========
sec("đŸ£  NUT NEM CAN (Fishing button)")
local p5Lbl = infoLbl("đŸŸ¡","Nut Fishing: Chua luu", Color3.fromRGB(255,230,80))
local toggleCastBtn = btn(34, Color3.fromRGB(155,115,0), "đŸŸ¡   HIEN vong tron nut Fishing")

gap(4); div()

-- ======== SECTION: ZXCV ========
sec("â¡  NUT CHIEU Z X C V")

-- Ghi chu: thu tu spam
local noteBox = Instance.new("Frame", scroll)
noteBox.Size=UDim2.new(1,-28,0,32); noteBox.Position=UDim2.new(0,14,0,Y)
noteBox.BackgroundColor3=Color3.fromRGB(20,20,50); noteBox.BorderSizePixel=0; noteBox.ZIndex=6
Instance.new("UICorner",noteBox).CornerRadius=UDim.new(0,8)
local noteLbl=Instance.new("TextLabel",noteBox)
noteLbl.Size=UDim2.new(1,-10,1,0); noteLbl.Position=UDim2.new(0,8,0,0)
noteLbl.BackgroundTransparency=1
noteLbl.Text="â†ª Tu dong spam Zâ†’Xâ†’Câ†’V khi ca can cau"
noteLbl.TextColor3=Color3.fromRGB(200,200,255); noteLbl.Font=Enum.Font.Gotham
noteLbl.TextSize=10; noteLbl.ZIndex=7
Y=Y+38

-- 4 hang ZXCV
local zxcvToggleBtns = {}
local zxcvInfoLbls   = {}

for i = 1, 4 do
    local nm  = zxcvNames[i]
    local col = zxcvColors[i]

    local row=Instance.new("Frame",scroll)
    row.Size=UDim2.new(1,-28,0,34); row.Position=UDim2.new(0,14,0,Y)
    row.BackgroundTransparency=1; row.ZIndex=6

    -- Badge mau
    local badge=Instance.new("Frame",row)
    badge.Size=UDim2.new(0,30,0,30); badge.Position=UDim2.new(0,0,0.5,-15)
    badge.BackgroundColor3=col; badge.BorderSizePixel=0; badge.ZIndex=6
    Instance.new("UICorner",badge).CornerRadius=UDim.new(0,8)
    local bl=Instance.new("TextLabel",badge)
    bl.Size=UDim2.new(1,0,1,0); bl.BackgroundTransparency=1
    bl.Text=nm; bl.Font=Enum.Font.GothamBlack; bl.TextSize=15
    bl.TextColor3=Color3.new(1,1,1); bl.ZIndex=7

    -- Status
    local sl=Instance.new("TextLabel",row)
    sl.Size=UDim2.new(0.45,0,1,0); sl.Position=UDim2.new(0,36,0,0)
    sl.BackgroundTransparency=1
    sl.Text="Chua luu"; sl.TextColor3=col
    sl.Font=Enum.Font.Gotham; sl.TextSize=11
    sl.TextXAlignment=Enum.TextXAlignment.Left; sl.ZIndex=6
    zxcvInfoLbls[i] = sl

    -- Nut hien marker
    local tb=Instance.new("TextButton",row)
    tb.Size=UDim2.new(0.48,0,0.88,0); tb.Position=UDim2.new(0.52,0,0.06,0)
    tb.BackgroundColor3=col; tb.BorderSizePixel=0
    tb.Text="HIEN "..nm; tb.TextColor3=Color3.new(1,1,1)
    tb.Font=Enum.Font.GothamBold; tb.TextSize=11; tb.ZIndex=6
    Instance.new("UICorner",tb).CornerRadius=UDim.new(0,8)
    zxcvToggleBtns[i] = tb
    Y=Y+40
end

gap(4); div()

-- ======== CAI DAT ========
sec("â™  CAI DAT VONG LAP")

-- Toc do ZXCV
local speedRow=Instance.new("Frame",scroll)
speedRow.Size=UDim2.new(1,-28,0,38); speedRow.Position=UDim2.new(0,14,0,Y)
speedRow.BackgroundColor3=Color3.fromRGB(14,14,30); speedRow.BorderSizePixel=0; speedRow.ZIndex=6
Instance.new("UICorner",speedRow).CornerRadius=UDim.new(0,9)
Instance.new("UIStroke",speedRow).Color=Color3.fromRGB(50,50,90)
local speedLbl=Instance.new("TextLabel",speedRow)
speedLbl.Size=UDim2.new(0.55,0,1,0); speedLbl.Position=UDim2.new(0,10,0,0)
speedLbl.BackgroundTransparency=1
speedLbl.Text="Toc do ZXCV: " .. math.floor(1/zxcvInterval) .. "/s"
speedLbl.TextColor3=Color3.fromRGB(200,200,255); speedLbl.Font=Enum.Font.GothamBold
speedLbl.TextSize=11; speedLbl.TextXAlignment=Enum.TextXAlignment.Left; speedLbl.ZIndex=7
local sMinBtn=Instance.new("TextButton",speedRow)
sMinBtn.Size=UDim2.new(0,28,0,26); sMinBtn.Position=UDim2.new(0.57,0,0.5,-13)
sMinBtn.BackgroundColor3=Color3.fromRGB(160,40,40); sMinBtn.BorderSizePixel=0
sMinBtn.Text="âˆ’"; sMinBtn.TextColor3=Color3.new(1,1,1)
sMinBtn.Font=Enum.Font.GothamBold; sMinBtn.TextSize=15; sMinBtn.ZIndex=7
Instance.new("UICorner",sMinBtn).CornerRadius=UDim.new(0,6)
local sPlusBtn=Instance.new("TextButton",speedRow)
sPlusBtn.Size=UDim2.new(0,28,0,26); sPlusBtn.Position=UDim2.new(0.57,62,0.5,-13)
sPlusBtn.BackgroundColor3=Color3.fromRGB(30,150,55); sPlusBtn.BorderSizePixel=0
sPlusBtn.Text="+"; sPlusBtn.TextColor3=Color3.new(1,1,1)
sPlusBtn.Font=Enum.Font.GothamBold; sPlusBtn.TextSize=15; sPlusBtn.ZIndex=7
Instance.new("UICorner",sPlusBtn).CornerRadius=UDim.new(0,6)
Y=Y+46

-- Ban sau N con
local sellNRow=Instance.new("Frame",scroll)
sellNRow.Size=UDim2.new(1,-28,0,38); sellNRow.Position=UDim2.new(0,14,0,Y)
sellNRow.BackgroundColor3=Color3.fromRGB(14,14,30); sellNRow.BorderSizePixel=0; sellNRow.ZIndex=6
Instance.new("UICorner",sellNRow).CornerRadius=UDim.new(0,9)
Instance.new("UIStroke",sellNRow).Color=Color3.fromRGB(50,50,90)
local sellNLbl=Instance.new("TextLabel",sellNRow)
sellNLbl.Size=UDim2.new(0.55,0,1,0); sellNLbl.Position=UDim2.new(0,10,0,0)
sellNLbl.BackgroundTransparency=1
sellNLbl.Text="Ban sau: " .. sellEveryN .. " con ca"
sellNLbl.TextColor3=Color3.fromRGB(100,255,160); sellNLbl.Font=Enum.Font.GothamBold
sellNLbl.TextSize=11; sellNLbl.TextXAlignment=Enum.TextXAlignment.Left; sellNLbl.ZIndex=7
local nMinBtn=Instance.new("TextButton",sellNRow)
nMinBtn.Size=UDim2.new(0,28,0,26); nMinBtn.Position=UDim2.new(0.57,0,0.5,-13)
nMinBtn.BackgroundColor3=Color3.fromRGB(160,40,40); nMinBtn.BorderSizePixel=0
nMinBtn.Text="âˆ’"; nMinBtn.TextColor3=Color3.new(1,1,1)
nMinBtn.Font=Enum.Font.GothamBold; nMinBtn.TextSize=15; nMinBtn.ZIndex=7
Instance.new("UICorner",nMinBtn).CornerRadius=UDim.new(0,6)
local nPlusBtn=Instance.new("TextButton",sellNRow)
nPlusBtn.Size=UDim2.new(0,28,0,26); nPlusBtn.Position=UDim2.new(0.57,62,0.5,-13)
nPlusBtn.BackgroundColor3=Color3.fromRGB(30,150,55); nPlusBtn.BorderSizePixel=0
nPlusBtn.Text="+"; nPlusBtn.TextColor3=Color3.new(1,1,1)
nPlusBtn.Font=Enum.Font.GothamBold; nPlusBtn.TextSize=15; nPlusBtn.ZIndex=7
Instance.new("UICorner",nPlusBtn).CornerRadius=UDim.new(0,6)
Y=Y+46

gap(4); div()

-- ======== NUT BAT/TAT ========
local toggleBtn = btn(50, Color3.fromRGB(30,180,65), "â–¶   BAT VONG LAP TU DONG")
local tGrad=Instance.new("UIGradient",toggleBtn)
tGrad.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(45,215,82)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(18,148,50)),
}); tGrad.Rotation=90

scroll.CanvasSize = UDim2.new(0,0,0, Y+20)

-- ======== DONG / MO MENU ========
local twI=TweenInfo.new(0.25,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
local pingA=nil

local function openMenu()
    menuOpen=true
    if pingA then pingA:Cancel() end
    bubble.Visible=false; bubble.Size=UDim2.new(0,58,0,58)
    frame.Visible=true; frame.Size=UDim2.new(0,0,0,0)
    TS:Create(frame,twI,{Size=UDim2.new(0,W,0,H)}):Play()
end

local function closeMenu()
    menuOpen=false
    local tw=TS:Create(frame,twI,{Size=UDim2.new(0,0,0,0)})
    tw:Play()
    tw.Completed:Connect(function()
        if not menuOpen then
            frame.Visible=false; bubble.Visible=true
            pingA=TS:Create(bubble,
                TweenInfo.new(0.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
                {Size=UDim2.new(0,66,0,66)})
            pingA:Play()
        end
    end)
end

closeMenuBtn.MouseButton1Click:Connect(closeMenu)
bubble.MouseButton1Click:Connect(openMenu)

-- ======== SAVE VI TRI ========
saveFishBtn.MouseButton1Click:Connect(function()
    local c=LP.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
    if r then
        savedFishPos=r.Position
        p1Lbl.Text="Vi tri cau: Da luu âœ“"
        p1Lbl.TextColor3=Color3.fromRGB(80,255,120)
        saveFishBtn.Text="âœ“   Vi tri cau da luu!"
        saveFishBtn.BackgroundColor3=Color3.fromRGB(12,100,45)
    end
end)

saveNPCBtn.MouseButton1Click:Connect(function()
    local c=LP.Character; local r=c and c:FindFirstChild("HumanoidRootPart")
    if r then
        savedNPCPos=r.Position
        p2Lbl.Text="Vi tri NPC: Da luu âœ“"
        p2Lbl.TextColor3=Color3.fromRGB(255,220,60)
        saveNPCBtn.Text="âœ“   Vi tri NPC da luu!"
        saveNPCBtn.BackgroundColor3=Color3.fromRGB(70,15,125)
    end
end)

-- ======== HELPER MARKER TOGGLE ========
local function setupMarker(marker, tBtn, infoLblRef, savedTable, key, doneText, doneCol, offTxt)
    tBtn.MouseButton1Click:Connect(function()
        marker.Visible = not marker.Visible
        tBtn.Text = marker.Visible and ("AN vong tron") or offTxt
        if marker.Visible then tBtn.BackgroundColor3=Color3.fromRGB(140,55,15) end
    end)
    marker.MouseButton1Click:Connect(function()
        local mp=UIS:GetMouseLocation()
        if key then savedTable[key]=Vector2.new(mp.X,mp.Y)
        else savedTable[1]=Vector2.new(mp.X,mp.Y) end
        infoLblRef.Text=doneText.." âœ“ ("..math.floor(mp.X)..","..math.floor(mp.Y)..")"
        infoLblRef.TextColor3=doneCol
        marker.BackgroundColor3=Color3.fromRGB(30,70,170)
        tBtn.Text="âœ“ Da danh dau! ("..math.floor(mp.X)..","..math.floor(mp.Y)..")"
        tBtn.BackgroundColor3=Color3.fromRGB(20,80,20)
        statusText="Da luu!"
    end)
end

-- Sell / Close markers
do
    local sellSaved = {}
    toggleSellBtn.MouseButton1Click:Connect(function()
        sellMarker.Visible=not sellMarker.Visible
        toggleSellBtn.Text=sellMarker.Visible and "AN vong tron SellAll" or "đŸ›’   HIEN vong tron SellAll"
        if sellMarker.Visible then toggleSellBtn.BackgroundColor3=Color3.fromRGB(140,55,15) end
    end)
    sellMarker.MouseButton1Click:Connect(function()
        local mp=UIS:GetMouseLocation()
        savedSellPos=Vector2.new(mp.X,mp.Y)
        p3Lbl.Text="Nut SellAll: Da luu âœ“ ("..math.floor(mp.X)..","..math.floor(mp.Y)..")"
        p3Lbl.TextColor3=Color3.fromRGB(80,255,180)
        sellMarker.BackgroundColor3=Color3.fromRGB(30,70,170)
        toggleSellBtn.Text="âœ“ SellAll da danh dau!"
        toggleSellBtn.BackgroundColor3=Color3.fromRGB(20,80,20)
        statusText="Da luu SellAll!"
    end)

    toggleCloseBtn.MouseButton1Click:Connect(function()
        closeMarker.Visible=not closeMarker.Visible
        toggleCloseBtn.Text=closeMarker.Visible and "AN vong tron X" or "âŒ   HIEN vong tron X dong"
        if closeMarker.Visible then toggleCloseBtn.BackgroundColor3=Color3.fromRGB(140,55,15) end
    end)
    closeMarker.MouseButton1Click:Connect(function()
        local mp=UIS:GetMouseLocation()
        savedClosePos=Vector2.new(mp.X,mp.Y)
        p4Lbl.Text="Nut X dong: Da luu âœ“ ("..math.floor(mp.X)..","..math.floor(mp.Y)..")"
        p4Lbl.TextColor3=Color3.fromRGB(255,150,200)
        closeMarker.BackgroundColor3=Color3.fromRGB(30,70,170)
        toggleCloseBtn.Text="âœ“ X dong da danh dau!"
        toggleCloseBtn.BackgroundColor3=Color3.fromRGB(20,80,20)
        statusText="Da luu X!"
    end)
end

-- Cast marker
toggleCastBtn.MouseButton1Click:Connect(function()
    castMarker.Visible=not castMarker.Visible
    toggleCastBtn.Text=castMarker.Visible and "AN vong tron Fishing" or "đŸŸ¡   HIEN vong tron nut Fishing"
    if castMarker.Visible then toggleCastBtn.BackgroundColor3=Color3.fromRGB(130,70,0) end
end)
castMarker.MouseButton1Click:Connect(function()
    local mp=UIS:GetMouseLocation()
    savedCastPos=Vector2.new(mp.X,mp.Y)
    p5Lbl.Text="Nut Fishing: Da luu âœ“ ("..math.floor(mp.X)..","..math.floor(mp.Y)..")"
    p5Lbl.TextColor3=Color3.fromRGB(255,230,80)
    castMarker.BackgroundColor3=Color3.fromRGB(30,70,170)
    toggleCastBtn.Text="âœ“ Fishing da danh dau!"
    toggleCastBtn.BackgroundColor3=Color3.fromRGB(20,80,20)
    statusText="Da luu Fishing!"
end)

-- ZXCV markers
for i = 1,4 do
    local m  = zxcvMarkers[i]
    local tb = zxcvToggleBtns[i]
    local sl = zxcvInfoLbls[i]
    local col= zxcvColors[i]
    local nm = zxcvNames[i]

    tb.MouseButton1Click:Connect(function()
        m.Visible=not m.Visible
        tb.Text=m.Visible and ("AN "..nm) or ("HIEN "..nm)
        if m.Visible then tb.BackgroundColor3=Color3.fromRGB(140,55,15)
        else tb.BackgroundColor3=col end
    end)
    m.MouseButton1Click:Connect(function()
        local mp=UIS:GetMouseLocation()
        zxcvPos[i]=Vector2.new(mp.X,mp.Y)
        sl.Text="Da luu âœ“ ("..math.floor(mp.X)..","..math.floor(mp.Y)..")"
        sl.TextColor3=Color3.fromRGB(200,255,200)
        m.BackgroundColor3=Color3.fromRGB(30,70,170)
        tb.Text="âœ“ "..nm.." da danh dau!"
        tb.BackgroundColor3=Color3.fromRGB(20,80,20)
        statusText="Da luu nut "..nm.."!"
    end)
end

-- ======== CAI DAT ========
sMinBtn.MouseButton1Click:Connect(function()
    zxcvInterval=math.min(0.5, zxcvInterval+0.02)
    speedLbl.Text="Toc do ZXCV: "..math.floor(1/zxcvInterval).."/s"
end)
sPlusBtn.MouseButton1Click:Connect(function()
    zxcvInterval=math.max(0.05, zxcvInterval-0.02)
    speedLbl.Text="Toc do ZXCV: "..math.floor(1/zxcvInterval).."/s"
end)
nMinBtn.MouseButton1Click:Connect(function()
    sellEveryN=math.max(1,sellEveryN-1)
    sellNLbl.Text="Ban sau: "..sellEveryN.." con ca"
end)
nPlusBtn.MouseButton1Click:Connect(function()
    sellEveryN=sellEveryN+1
    sellNLbl.Text="Ban sau: "..sellEveryN.." con ca"
end)

-- ======== BAT / TAT VONG LAP ========
toggleBtn.MouseButton1Click:Connect(function()
    isRunning=not isRunning
    if isRunning then
        -- Validate
        local errs={}
        if not savedFishPos  then table.insert(errs,"vi tri cau") end
        if not savedNPCPos   then table.insert(errs,"vi tri NPC") end
        if not savedSellPos  then table.insert(errs,"nut SellAll") end
        if not savedClosePos then table.insert(errs,"nut X dong") end
        if not savedCastPos  then table.insert(errs,"nut Fishing") end
        local hasZ=false; for i=1,4 do if zxcvPos[i] then hasZ=true end end
        if not hasZ then table.insert(errs,"it nhat 1 nut ZXCV") end
        if #errs > 0 then
            statusText="Thieu: "..table.concat(errs,", ").."!"
            isRunning=false; return
        end
        fishCaught=0; fishSession=0
        statusText="Bat dau vong lap!"
        task.spawn(mainLoop)
    else
        statusText="Da tat"
        stopWalk()
    end
end)

UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.F then toggleBtn.MouseButton1Click:Fire() end
    if i.KeyCode==Enum.KeyCode.H then
        if menuOpen then closeMenu() else openMenu() end
    end
end)

-- ======== UPDATE DISPLAY ========
RS.Heartbeat:Connect(function()
    sLbl.Text=statusText
    caughtLbl.Text="Ca: "..fishCaught
    sellLbl.Text="Ban: "..sellCount
    sesLbl.Text="Session: "..fishSession.."/"..sellEveryN

    if isRunning then
        sLbl.TextColor3=Color3.fromRGB(80,255,140)
        sDot.BackgroundColor3=Color3.fromRGB(60,255,80)
        toggleBtn.Text="â¹   TAT VONG LAP"
        tGrad.Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(225,50,50)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(155,18,18)),
        })
    else
        sLbl.TextColor3=Color3.fromRGB(255,120,120)
        sDot.BackgroundColor3=Color3.fromRGB(255,80,80)
        toggleBtn.Text="â–¶   BAT VONG LAP TU DONG"
        tGrad.Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(45,215,82)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(18,148,50)),
        })
    end
    if not menuOpen then
        bubble.Text=isRunning and "â–¶" or "đŸ£"
        bubble.BackgroundColor3=isRunning and Color3.fromRGB(200,45,45) or Color3.fromRGB(255,140,0)
    end
end)

print("[TF v14] H=menu | F=bat/tat vong lap tu dong")
print("Vong lap: Nem can â†’ Ca can â†’ ZXCV â†’ Ca len â†’ Ban â†’ Lap lai")
