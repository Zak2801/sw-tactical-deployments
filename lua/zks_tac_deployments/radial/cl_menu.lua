ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.UI = ZKTacticalDeployments.UI or {}
ZKTacticalDeployments.UI.MenuLoopSound = nil

local BLUR_MATERIAL = Material("pp/blurscreen")

local rallyMaterial = Material( "icons/rally.png", "smooth unlitgeneric ignorez" )
local placeRMaterial = Material( "icons/place.png", "smooth unlitgeneric ignorez" )
local pickupRMaterial = Material( "icons/pickup.png", "smooth unlitgeneric ignorez" )
local fobMaterial = Material( "icons/fob.png", "smooth unlitgeneric ignorez" )

local menuStructure = {
    { 
        name = "Rally", 
        icon = rallyMaterial,
        submenu = {
            { name = "Place Rally", icon = placeRMaterial, cmd = "zks_place_rally" },
            { name = "Pickup Rally", icon = pickupRMaterial, cmd = "zks_pickup_rally" },
        } 
    },
    { 
        name = "FOB",
        icon = fobMaterial,
        submenu = {
            { name = "Radio", icon = fobMaterial, cmd = "zks_spawn_fob_radio" },
            { name = "Ammo Crate", icon = fobMaterial, cmd = "zks_spawn_ammo_crate" },
            { name = "Medical Crate", icon = fobMaterial, cmd = "zks_spawn_medical_crate" },
        } 
    },
}

local radialMenu
local selectedIndex = nil
local hoveringCancel = false

local menuHistory = {} -- Stores the path (index numbers) taken to reach the current level
local currentOptions = menuStructure -- Starts at the top level

local cx_dummy, cy_dummy = ScrW(), ScrH()
local INNER_RADIUS = cx_dummy * 1.61803 / 20
local RING_THICKNESS = cx_dummy * 1.61803 / 26
local OUTER_RADIUS = INNER_RADIUS + RING_THICKNESS

local function IsAtRootLevel()
    return #menuHistory == 0
end

local function drawCircleFilled(x, y, r, col)
    surface.SetDrawColor(col)
    draw.NoTexture()

    local poly = {}
    for a = 0, 360, 6 do
        local rad = math.rad(a)
        poly[#poly+1] = { x = x + math.cos(rad)*r, y = y + math.sin(rad)*r }
    end
    surface.DrawPoly(poly)
end

local function drawRingSegment(cx, cy, r1, r2, a1, a2, col)
    surface.SetDrawColor(col)
    draw.NoTexture()

    -- We draw the ring as a series of small "quads" (trapezoids).
    -- This prevents the "crossing lines" glitch caused by concave polygons.
    local step = 2 -- Resolution: lower is smoother, higher is faster
    
    for a = a1, a2, step do
        local startAng = a
        local endAng = math.min(a + step, a2) -- Clamp to ensure we don't overshoot
        
        local rad1 = math.rad(startAng)
        local rad2 = math.rad(endAng)

        local cos1, sin1 = math.cos(rad1), math.sin(rad1)
        local cos2, sin2 = math.cos(rad2), math.sin(rad2)

        local poly = {
            { x = cx + cos1 * r1, y = cy + sin1 * r1 }, -- Inner Start
            { x = cx + cos1 * r2, y = cy + sin1 * r2 }, -- Outer Start
            { x = cx + cos2 * r2, y = cy + sin2 * r2 }, -- Outer End
            { x = cx + cos2 * r1, y = cy + sin2 * r1 }, -- Inner End
        }
        
        surface.DrawPoly(poly)
    end
    surface.SetDrawColor(255, 255, 255, 255)
end


-------------------------------------------------------------
-- CLOSE
-------------------------------------------------------------
function ZKTacticalDeployments.UI.CloseDeployableRadial()
    if ZKTacticalDeployments.UI.MenuLoopSound then
        ZKTacticalDeployments.UI.MenuLoopSound:Stop()
    end
    
    -- Safety check: If radialMenu is already gone, stop.
    if not IsValid(radialMenu) then return end 
    
    -- --- 1. HANDLE CANCEL / BACK ---
    if hoveringCancel then
        radialMenu:Remove()
        currentOptions = menuStructure
        menuHistory = {}
        selectedIndex = nil
        hoveringCancel = false
        radialMenu = nil
        return
    end

    -- --- 2. HANDLE SELECTION ---
    if selectedIndex then
        local option = currentOptions[selectedIndex]

        -- ROOT LEVEL — DO NOTHING on key release
        if IsAtRootLevel() then
            -- Do not auto-select.
            radialMenu:Remove()
            radialMenu = nil
            return
        end

        -- SUBMENU LEVEL — keep old behavior
        if option.submenu then
            table.insert(menuHistory, selectedIndex)
            currentOptions = option.submenu
            radialMenu:Remove()
            OpenDeployableRadial()
            return
        elseif option.cmd then
            RunConsoleCommand(option.cmd)
        end
    end


    -- --- 3. FINAL CLEANUP ---
    -- If a command was run OR an invalid area was clicked, close the menu completely.
    if IsValid(radialMenu) then
        radialMenu:Remove()
    end
    currentOptions = menuStructure
    menuHistory = {}
    selectedIndex = nil
    hoveringCancel = false
    radialMenu = nil
    return
end


-------------------------------------------------------------
-- OPEN RADIAL
-------------------------------------------------------------
function ZKTacticalDeployments.UI.OpenDeployableRadial()
    if IsValid(radialMenu) then radialMenu:Remove() end
    local ply = LocalPlayer()

    if not ZKTacticalDeployments.UI.MenuLoopSound then
        ZKTacticalDeployments.UI.MenuLoopSound = CreateSound(ply, "tds_menu_loop")
    end

    if ZKTacticalDeployments.UI.MenuLoopSound then
        ZKTacticalDeployments.UI.MenuLoopSound:PlayEx(0.03, 80) -- volume, pitch
    end

    -- selectedIndex = nil
    -- menuHistory = {}
    -- currentOptions = menuStructure

    radialMenu = vgui.Create("DFrame")
    radialMenu:SetSize(ScrW(), ScrH())
    radialMenu:SetTitle("")
    radialMenu:ShowCloseButton(false)
    radialMenu:SetDraggable(false)
    radialMenu:SetKeyboardInputEnabled(false)
    radialMenu:SetMouseInputEnabled(true)
    radialMenu:MakePopup()

    radialMenu.Paint = function(self, w, h)
        local cx, cy = w/2, h/2
        local mx, my = gui.MousePos()
        local dx, dy = mx - cx, my - cy
        local dist   = math.sqrt(dx*dx + dy*dy)

        -------------------------------------------------
        -- OUTER RING AREA
        -------------------------------------------------
        -- CHANGED: Use currentOptions instead of a fixed global table
        local sliceCount = #currentOptions 
        local sliceAngle = 360 / sliceCount

        -- Calculate Mouse Angle
        local ang = math.deg(math.atan2(dy, dx))
        ang = ang + 90
        if ang < 0 then ang = ang + 360 end

        -- Determine which slice is hovered
        selectedIndex = nil
        if dist > INNER_RADIUS and dist < OUTER_RADIUS then
            selectedIndex = math.floor(ang / sliceAngle) + 1
            if selectedIndex > sliceCount then selectedIndex = 1 end
        end

        -------------------------------------------------
        -- DRAW EACH SLICE IN THE RING
        -------------------------------------------------
        -- 1. STENCIL START
        cam.StartOrthoView(0, 0, w, h)
            render.SetStencilEnable(true)
            render.SuppressEngineLighting(true)
            render.ClearStencil()

            render.SetStencilWriteMask(255)
            render.SetStencilReferenceValue(1)
            render.SetStencilCompareFunction(STENCIL_ALWAYS) 
            render.SetStencilPassOperation(STENCIL_REPLACE) 
            render.SetStencilZFailOperation(STENCIL_KEEP)
            render.SetStencilFailOperation(STENCIL_KEEP)

            -- 2. DRAW RING SHAPE TO STENCIL BUFFER
            for i = 1, sliceCount do
                local a1 = (i-1) * sliceAngle - 90
                local a2 = i * sliceAngle - 90
                
                -- Draw the filled shape to set the stencil bits
                drawRingSegment(cx, cy, INNER_RADIUS, OUTER_RADIUS, a1, a2, Color(255, 255, 255, 255))
            end

            -- 3. APPLY BLUR: Draw the blur material, but only where the stencil is set to 1
            render.SetStencilWriteMask(0) 
            render.SetStencilReferenceValue(1)
            render.SetStencilCompareFunction(STENCIL_EQUAL) 
            render.SetStencilPassOperation(STENCIL_KEEP) 
            
            -- *** THE NEW BLUR IMPLEMENTATION ***
            local blurStrength = 2 -- Blur level (1 to 10 is common)
            
            -- Set the material properties for blur
            BLUR_MATERIAL:SetFloat("$alpha", 1.0)
            BLUR_MATERIAL:SetFloat("$blur", blurStrength)
            BLUR_MATERIAL:Recompute()
            
            -- Draw the screen-sized quad using the blur material
            render.SetMaterial(BLUR_MATERIAL)
            render.DrawScreenQuad() 
            
            -- 4. STENCIL END
            render.SetStencilEnable(false)
            render.SuppressEngineLighting(false)
        cam.EndOrthoView()

        for i = 1, sliceCount do
            local a1 = (i-1) * sliceAngle - 90
            local a2 = i * sliceAngle - 90
            local mid = (a1 + a2) / 2

            local hovered = (selectedIndex == i)
            local option = currentOptions[i]

            -- Draw segment
            drawRingSegment(cx, cy, INNER_RADIUS, OUTER_RADIUS, a1, a2,
                hovered and Color(5,25,50,180) or Color(5,25,50,150)
            )

            -- Base position where text normally goes
            local txtRad = INNER_RADIUS + (RING_THICKNESS * 0.5)
            local baseX = cx + math.cos(math.rad(mid)) * txtRad
            local baseY = cy + math.sin(math.rad(mid)) * txtRad

            -----------------------------------------
            -- ICON + TEXT STACKING
            -----------------------------------------
            local iconSize = cx * 0.06      -- Adjust as needed
            local offsetY = 0        -- Vertical offset for text

            if option.icon then
                -- Draw icon centered on the same spot
                if not hovered then
                    surface.SetDrawColor(255, 255, 255, 255)
                else
                    surface.SetDrawColor(238, 183, 45, 255)
                end
                surface.SetMaterial(option.icon)
                surface.DrawTexturedRect(baseX - iconSize/2, baseY - iconSize/2, iconSize, iconSize)

                -- Push text downward under the icon
                offsetY = iconSize * 0.9
            end

            -----------------------------------------
            -- TEXT UNDER ICON (or normal if no icon)
            -----------------------------------------
            local textName = option.name

            draw.SimpleText(
                textName,
                "TACDEPS_HUDFont_Small",
                baseX,
                baseY + offsetY,
                hovered and Color(238, 183, 45, 255) or Color(220,220,220),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        -------------------------------------------------
        -- OUTER RING OUTLINE
        -------------------------------------------------
        surface.DrawCircle(cx, cy, OUTER_RADIUS, 255, 255, 255, 200)

        -------------------------------------------------
        -- INNER CIRCLE (Back/Cancel)
        -------------------------------------------------
        hoveringCancel = (dist < INNER_RADIUS)
        
        -- Check if we are in a submenu to display "Back"
        local centerText = (#menuHistory > 0) and "Back" or "Cancel" 

        -- Draw the inner dark circle
        drawCircleFilled(cx, cy, INNER_RADIUS,
            hoveringCancel and Color(0,0,50,150) or Color(0,0,50,130)
        )

        -- Draw white outline for inner circle
        surface.DrawCircle(cx, cy, INNER_RADIUS, 255, 255, 255)

        -------------------------------------------------
        -- INNER TEXT / CANCEL BUTTON
        -------------------------------------------------
        surface.SetFont("TACDEPS_HUDFont_Small")
        local tw, th = surface.GetTextSize(centerText)
        local pad = 8

        surface.SetDrawColor(hoveringCancel and Color(238, 183, 45, 255) or color_white)
        surface.DrawRect(cx - tw/2 - pad/2, cy - th/2 - pad/2, tw + pad, th + pad)

        -- "Back"/"Cancel" Text
        draw.SimpleText(
            centerText,
            "TACDEPS_HUDFont_Small",
            cx, cy,
            color_black,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    radialMenu.OnMousePressed = function(self, mc)
        if mc ~= MOUSE_LEFT then return end

        -- Click the center
        if hoveringCancel then
            if #menuHistory == 0 then
                ZKTacticalDeployments.UI.CloseDeployableRadial()
                return
            elseif #menuHistory > 0 then
                -- Remove last index from history
                table.remove(menuHistory)
                
                -- Traverse history to get the parent level options
                local tempOptions = menuStructure
                for _, idx in ipairs(menuHistory) do
                    tempOptions = tempOptions[idx].submenu
                end
                currentOptions = tempOptions
            end
        end

        -- Click a slice
        if selectedIndex then
            local option = currentOptions[selectedIndex]

            -- ROOT LEVEL: must click, so treat click as "activate"
            if IsAtRootLevel() then
                if option.submenu then
                    table.insert(menuHistory, selectedIndex)
                    currentOptions = option.submenu
                    self:Remove()
                    ZKTacticalDeployments.UI.OpenDeployableRadial()
                    return
                end
            end

            -- SUBMENU LEVEL: clicking a leaf activates immediately
            if option.cmd then
                RunConsoleCommand(option.cmd)
                if IsValid(radialMenu) then radialMenu:Remove() end
                radialMenu = nil
                return
            end

            -- SUBMENU LEVEL: clicking a submenu also works
            if option.submenu then
                table.insert(menuHistory, selectedIndex)
                currentOptions = option.submenu
                self:Remove()
                ZKTacticalDeployments.UI.OpenDeployableRadial()
                return
            end
        end
    end
end

concommand.Add("+zks_tac_deps_menu", ZKTacticalDeployments.UI.OpenDeployableRadial)
concommand.Add("-zks_tac_deps_menu", ZKTacticalDeployments.UI.CloseDeployableRadial)

concommand.Add("zks_place_rally", function()
    local ply = LocalPlayer()
    if !IsValid(ply) then return end
    ZKTacticalDeployments.DeploymentState.StartPlacement("rally")
end)

concommand.Add("zks_pickup_rally", function()
    local ply = LocalPlayer()
    if !IsValid(ply) then return end
    net.Start("ZKTDS_RequestPickupRally")
    net.SendToServer()
end)

concommand.Add("zks_spawn_fob_radio", function()
    local ply = LocalPlayer()
    if !IsValid(ply) then return end
    ZKTacticalDeployments.DeploymentState.StartPlacement("radio")
end)
