ZKTacticalDeployments = ZKTacticalDeployments or {}

local ZK_DeathButtons = {}
local DeathScreenVisible = false
local DeathText = ""
local DeathSpawnUnlockTime = 0     -- Time when spawning is allowed again
local DeathSpawnLockDuration = 3   -- Seconds to prevent spawning after death

-- ─────────────────────────────────────────────────────────────
-- Get Rally Entity based on user's Team and Group
-- @return rally Entity
-- ─────────────────────────────────────────────────────────────
local function GetAvailableRally()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ZKTacticalDeployments then return nil end

    ZKTacticalDeployments.Groups = ZKTacticalDeployments.Groups or {}
    ZKTacticalDeployments.TeamRallies = ZKTacticalDeployments.TeamRallies or {}

    local groupName = "Public"
    groupName = ZKTacticalDeployments.Groups.GetPlyGroup(ply:Team())

    local rally = ZKTacticalDeployments.TeamRallies[groupName]
    return (IsValid(rally) and rally) or nil
end

-- ─────────────────────────────────────────────────────────────
-- Network Receiver, Handles showing the death screen
-- @param DeathScreenVisible boolean - should we show it?
-- @return DeathText String - Who killed the player?
-- ─────────────────────────────────────────────────────────────
net.Receive("ZKTDS_ShowDeathScreen", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    DeathScreenVisible = net.ReadBool()
    DeathText = net.ReadString() or "World"

    -- Set lockout timer
    DeathSpawnUnlockTime = CurTime() + DeathSpawnLockDuration

    gui.EnableScreenClicker(DeathScreenVisible)
end)

-- ─────────────────────────────────────────────────────────────
-- Fonts
-- ─────────────────────────────────────────────────────────────
surface.CreateFont("BF2_Death_Font", {
    font = "Star Jedi",
    size = 48,
    weight = 500,
    antialias = true
})

surface.CreateFont("BF2_Death_Button", {
    font = "Star Jedi",
    size = 32,
    weight = 500,
    antialias = true
})

-- ─────────────────────────────────────────────────────────────
-- Utility Function for adding a UI Button
-- @param label String
-- @param x int
-- @param y int
-- @param action function
-- @param color Color
-- @param disabled boolean
-- @return h int - Height of the button
-- ─────────────────────────────────────────────────────────────
local function AddDeathButton(label, x, y, action, color, disabled)
    surface.SetFont("BF2_Death_Button")
    local txtW, txtH = surface.GetTextSize(label)
    local pad = 16
    local w = txtW + pad * 2
    local h = txtH + pad * 1.2

    local btn = {
        x = x - w / 2,
        y = y,
        w = w,
        h = h,
        action = (not disabled) and action or nil,
        label = label,
        color = disabled and Color(150,150,150,160) or color or Color(255,255,255,200),
        disabled = disabled
    }

    table.insert(ZK_DeathButtons, btn)
    return h
end

-- ─────────────────────────────────────────────────────────────
-- Actual drawing hook
-- @return nil
-- ─────────────────────────────────────────────────────────────
hook.Add("HUDPaint", "ZKTacticalDeployments_DeathScreenHUD", function()
    if not DeathScreenVisible then return end

    local w, h = ScrW(), ScrH()
    local panelW, panelH = math.min(350, w * 0.15), 300
    local panelX = w - panelW - 32
    local panelY = h * 0.35
    local pad = 16

    -- Lock active?
    local locked = CurTime() < DeathSpawnUnlockTime

    -- Background blur
    for i = 1, 5 do
        draw.RoundedBox(4, panelX, panelY, panelW, panelH, Color(0,0,0,80))
    end

    surface.SetDrawColor(255,255,255,200)
    surface.DrawOutlinedRect(panelX, panelY, panelW, panelH)

    draw.SimpleText("KILLED BY", "BF2_Death_Button", panelX + pad, panelY + pad, Color(190,190,190,170))
    surface.SetDrawColor(255,255,255,50)
    surface.DrawLine(panelX, panelY + pad + 35, panelX + panelW, panelY + pad + 35)

    draw.SimpleText(DeathText, "BF2_Death_Button", panelX + pad, panelY + pad + 35, Color(255,255,255))

    -- Show countdown
    if locked then
        local timeLeft = math.ceil(DeathSpawnUnlockTime - CurTime())
        draw.SimpleText("Available in " .. timeLeft, "BF2_Death_Button", panelX + pad, panelY + pad + 60, Color(255,80,80))
    end

    ZK_DeathButtons = {}
    local cursorY = panelY + 120
    local centerX = panelX + panelW / 2

    -- Normal spawn button
    cursorY = cursorY + AddDeathButton(
        "Normal Spawn",
        centerX,
        cursorY,
        function()
            net.Start("ZKTDS_SpawnAtRally")
            net.WriteEntity(nil)
            net.SendToServer()
            DeathScreenVisible = false
            gui.EnableScreenClicker(false)
        end,
        Color(225,225,225,200),
        locked  -- disabled if in lockout
    ) + 30

    -- Rally spawn button
    local rally = GetAvailableRally()
    if rally then
        AddDeathButton(
            "Spawn on Rally",
            centerX,
            cursorY,
            function()
                net.Start("ZKTDS_SpawnAtRally")
                net.WriteEntity(rally)
                net.SendToServer()
                DeathScreenVisible = false
                gui.EnableScreenClicker(false)
            end,
            Color(255,205,0,200),
            locked -- disabled if in lockout
        )
    end

    -- Draw
    for _, b in ipairs(ZK_DeathButtons) do
        for i = 1, 3 do
            draw.RoundedBox(4, b.x, b.y, b.w, b.h, Color(0,0,0,40))
        end

        surface.SetDrawColor(b.color.r, b.color.g, b.color.b, b.color.a)
        surface.DrawOutlinedRect(b.x, b.y, b.w, b.h)

        draw.SimpleText(b.label, "BF2_Death_Button", b.x + b.w / 2, b.y + b.h / 2, b.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- ─────────────────────────────────────────────────────────────
-- Hook for capturing mouse press on death
-- @return nil
-- ─────────────────────────────────────────────────────────────
hook.Add("GUIMousePressed", "ZKTacticalDeployments_DeathScreenClick", function(mc)
    if not DeathScreenVisible or mc ~= MOUSE_LEFT then return end

    -- If locked, do nothing (cannot spawn)
    if CurTime() < DeathSpawnUnlockTime then
        return
    end

    local mx, my = gui.MousePos()

    for _, b in ipairs(ZK_DeathButtons) do
        if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
            if b.action then b.action() end
            return
        end
    end

    -- Clicking outside runs default
    net.Start("ZKTDS_SpawnAtRally")
    net.WriteEntity(nil)
    net.SendToServer()

    DeathScreenVisible = false
    gui.EnableScreenClicker(false)
end)
