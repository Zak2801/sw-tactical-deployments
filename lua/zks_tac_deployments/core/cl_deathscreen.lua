--[[-------------------------------------------------------------------------
  lua\zks_tac_deployments\core\cl_deathscreen.lua
  CLIENT
  Death Screen UI matching Radial Menu style
---------------------------------------------------------------------------]]

ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.UI = ZKTacticalDeployments.UI or {}

-- --------------------------------------------------------------------------
-- Handling Lua Refreshes (Hot Reload)
-- --------------------------------------------------------------------------
if IsValid(ZKTacticalDeployments.UI.DeathScreenPanel) then
    ZKTacticalDeployments.UI.DeathScreenPanel:Remove()
    ZKTacticalDeployments.UI.DeathScreenPanel = nil
end

-- --------------------------------------------------------------------------
-- Style Constants (Matched to cl_menu.lua)
-- --------------------------------------------------------------------------
local BLUR_MATERIAL = Material("pp/blurscreen")
local COL_BG        = Color(5, 25, 50, 150)
local COL_BG_HOVER  = Color(5, 25, 50, 200)
local COL_OUTLINE   = Color(255, 255, 255, 255)
local COL_TEXT      = Color(220, 220, 220)
local COL_ACCENT    = Color(238, 183, 45, 255)
local COL_DISABLED  = Color(100, 100, 100, 200)

local FONT_MAIN = "TACDEPS_HUDFont_Small"

local DeathSpawnUnlockTime = 0
local DeathSpawnLockDuration = 3

-- --------------------------------------------------------------------------
-- Helper: Efficient Blur
-- --------------------------------------------------------------------------
local function DrawBlur(panel, amount)
    local x, y = panel:LocalToScreen(0, 0)
    local scrW, scrH = ScrW(), ScrH()
    
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(BLUR_MATERIAL)
    
    for i = 1, 3 do
        BLUR_MATERIAL:SetFloat("$blur", (i / 3) * (amount or 6))
        BLUR_MATERIAL:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
    end
end

-- --------------------------------------------------------------------------
-- Helper: Get Available Rally Point
-- --------------------------------------------------------------------------
local function GetAvailableRally()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ZKTacticalDeployments then return nil end

    ZKTacticalDeployments.Groups = ZKTacticalDeployments.Groups or {}
    ZKTacticalDeployments.TeamRallies = ZKTacticalDeployments.TeamRallies or {}

    local groupName = "Public"
    -- Check if function exists to avoid errors if dependencies aren't loaded
    if ZKTacticalDeployments.Groups.GetPlyGroup then
        groupName = ZKTacticalDeployments.Groups.GetPlyGroup(ply:Team())
    end

    local rally = ZKTacticalDeployments.TeamRallies[groupName]
    return (IsValid(rally) and rally) or nil
end

-- --------------------------------------------------------------------------
-- Close Death Screen
-- --------------------------------------------------------------------------
function ZKTacticalDeployments.UI.CloseDeathScreen()
    if IsValid(ZKTacticalDeployments.UI.DeathScreenPanel) then
        ZKTacticalDeployments.UI.DeathScreenPanel:Remove()
    end
    ZKTacticalDeployments.UI.DeathScreenPanel = nil
end

-- --------------------------------------------------------------------------
-- Open Death Screen
-- --------------------------------------------------------------------------
function ZKTacticalDeployments.UI.OpenDeathScreen(killerName)
    ZKTacticalDeployments.UI.CloseDeathScreen()

    local scrW, scrH = ScrW(), ScrH()
    
    -- 1. Main Container (Invisible/Faint, covers screen)
    local panel = vgui.Create("DPanel")
    panel:SetSize(scrW, scrH)
    panel:MakePopup()
    panel:SetKeyboardInputEnabled(false) -- Allow looking around if game permits
    
    -- Handle "Click Outside" -> Normal Spawn
    panel.OnMousePressed = function(self, mc)
        if mc == MOUSE_LEFT then
            -- Only allow spawn if timer is up
            if CurTime() < DeathSpawnUnlockTime then return end
            
            net.Start("ZKTDS_SpawnAtRally")
            net.WriteEntity(nil)
            net.SendToServer()
            ZKTacticalDeployments.UI.CloseDeathScreen()
        end
    end

    panel.Paint = function(self, w, h) 
        -- Very subtle dimming (User requested "less obv")
        surface.SetDrawColor(0, 0, 0, 1) 
        surface.DrawRect(0, 0, w, h)
    end

    -- Store globally
    ZKTacticalDeployments.UI.DeathScreenPanel = panel

    -- 2. Central Card
    local cardW, cardH = 380, 320
    local card = vgui.Create("DPanel", panel)
    card:SetSize(cardW, cardH)
    
    -- Position: Center-Right (10% padding from right edge)
    local cardX = scrW - cardW - (scrW * 0.02) 
    local cardY = (scrH - cardH) / 2
    card:SetPos(cardX, cardY)
    
    -- Prevent background clicks when clicking the card itself
    card.OnMousePressed = function() end 
    
    card.Paint = function(self, w, h)
        -- Blur only behind the card
        DrawBlur(self, 4)
        
        -- Dark Blue Background
        surface.SetDrawColor(COL_BG)
        surface.DrawRect(0, 0, w, h)
        
        -- White Outline
        surface.SetDrawColor(COL_OUTLINE)
        surface.DrawOutlinedRect(0, 0, w, h)
        
        -- Header Text
        draw.SimpleText("KILLED BY", FONT_MAIN, w/2, 25, Color(190,190,190), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText(killerName, FONT_MAIN, w/2, 55, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        -- Separator Line
        surface.SetDrawColor(255, 255, 255, 50)
        surface.DrawLine(30, 90, w-30, 90)
        
        -- Countdown Timer
        local timeLeft = math.ceil(DeathSpawnUnlockTime - CurTime())
        if timeLeft > 0 then
             draw.SimpleText("Available in " .. timeLeft, FONT_MAIN, w/2, 110, Color(255, 80, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        else
             draw.SimpleText("Ready to Deploy", FONT_MAIN, w/2, 110, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    end

    -- 2.5 Close Button (X) - Top Right of Card
    local closeBtn = vgui.Create("DButton", card)
    closeBtn:SetText("")
    closeBtn:SetSize(24, 24)
    closeBtn:SetPos(cardW - 28, 4)
    closeBtn.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.SimpleText("✕", "TACDEPS_HUDFont_Small", w/2, h/2, COL_ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("✕", "TACDEPS_HUDFont_Small", w/2, h/2, Color(200, 200, 200, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    closeBtn.DoClick = function()
        ZKTacticalDeployments.UI.CloseDeathScreen()
    end
    
    -- 3. Button Helper
    local function CreateDeployButton(label, yPos, colorOverride, onClick)
        local btn = vgui.Create("DButton", card)
        btn:SetText("")
        btn:SetSize(cardW - 60, 45)
        btn:SetPos(30, yPos)
        
        btn.Paint = function(self, w, h)
            local locked = CurTime() < DeathSpawnUnlockTime
            local isHovered = self:IsHovered() and not locked
            
            -- Background
            if isHovered then
                surface.SetDrawColor(COL_BG_HOVER)
            else
                surface.SetDrawColor(0, 0, 0, 50) -- Subtle dark fill normally
            end
            surface.DrawRect(0, 0, w, h)
            
            -- Outline
            if locked then
                surface.SetDrawColor(100, 100, 100, 50)
            elseif isHovered then
                surface.SetDrawColor(COL_ACCENT)
            else
                surface.SetDrawColor(COL_OUTLINE)
            end
            surface.DrawOutlinedRect(0, 0, w, h)
            
            -- Label
            local txtCol = COL_TEXT
            if locked then 
                txtCol = COL_DISABLED 
            elseif isHovered then 
                txtCol = COL_ACCENT 
            elseif colorOverride then
                txtCol = colorOverride
            end
            
            draw.SimpleText(label, FONT_MAIN, w/2, h/2, txtCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        btn.DoClick = function()
            if CurTime() < DeathSpawnUnlockTime then return end
            if onClick then onClick() end
        end
        
        return btn
    end
    
    -- 4. Add Buttons
    local startY = 160
    local spacing = 55
    
    -- Normal Spawn
    CreateDeployButton("Default Spawn", startY, nil, function()
        net.Start("ZKTDS_SpawnAtRally")
        net.WriteEntity(nil)
        net.SendToServer()
        ZKTacticalDeployments.UI.CloseDeathScreen()
    end)
    
    -- Rally Spawn (if exists)
    local rally = GetAvailableRally()
    if rally then
        CreateDeployButton("Rally Point", startY + spacing, Color(255, 205, 0), function()
            net.Start("ZKTDS_SpawnAtRally")
            net.WriteEntity(rally)
            net.SendToServer()
            ZKTacticalDeployments.UI.CloseDeathScreen()
        end)
    end
end

-- --------------------------------------------------------------------------
-- Network Receiver
-- --------------------------------------------------------------------------
net.Receive("ZKTDS_ShowDeathScreen", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local shouldShow = net.ReadBool()
    local killerName = net.ReadString() or "World"

    if shouldShow then
        DeathSpawnUnlockTime = CurTime() + DeathSpawnLockDuration
        ZKTacticalDeployments.UI.OpenDeathScreen(killerName)
    else
        ZKTacticalDeployments.UI.CloseDeathScreen()
    end
end)

-- --------------------------------------------------------------------------
-- Console Command: Close Death Screen
-- --------------------------------------------------------------------------
concommand.Add("tds_close_deathscreen", function()
    ZKTacticalDeployments.UI.CloseDeathScreen()
end)
