--[[-------------------------------------------------------------------------
  lua\zks_tac_deployments\core\cl_deployment_state.lua
  CLIENT
  Manages the "Hands-Free" placement state (Ghosting, Input).
---------------------------------------------------------------------------]]

ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.DeploymentState = ZKTacticalDeployments.DeploymentState or {}

local State = {
    Active = false,
    WaitForRelease = false,
    ItemID = nil,
    GhostEnt = nil,
    LastTrace = nil
}

local function RemoveGhost()
    if IsValid(State.GhostEnt) then
        State.GhostEnt:Remove()
    end
    State.GhostEnt = nil
end

-----------------------------------------------------------------------------
-- Start placement mode for an item
-- @param itemID string
-----------------------------------------------------------------------------
function ZKTacticalDeployments.DeploymentState.StartPlacement(itemID)
    local item = ZKTacticalDeployments.Deployables.Get(itemID)
    if not item then return end

    State.Active = true
    State.WaitForRelease = false
    State.ItemID = itemID
    
    RemoveGhost()
    
    -- Create Ghost
    State.GhostEnt = ClientsideModel(item.GhostModel)
    if IsValid(State.GhostEnt) then
        State.GhostEnt:SetRenderMode(RENDERMODE_TRANSCOLOR)
        State.GhostEnt:SetColor(Color(0, 255, 0, 150))
        
        -- Apply scale if defined in registry
        if item.GhostScale then
             -- ClientsideModel doesn't always support SetModelScale immediately in some engine versions without EnableMatrix,
             -- but let's try standard SetModelScale first.
             State.GhostEnt:SetModelScale(item.GhostScale.x) -- Assuming uniform for simple call
             
             -- Or usage of matrix for non-uniform
             local mat = Matrix()
             mat:Scale(item.GhostScale)
             State.GhostEnt:EnableMatrix("RenderMultiply", mat)
        end
    end
    
    chat.AddText(Color(0, 255, 0), "[TDS] ", Color(255, 255, 255), "Placement Mode: " .. item.PrintName)
    chat.AddText(Color(255, 255, 255), "Left-Click to Place. Right-Click to Cancel.")
end

-----------------------------------------------------------------------------
-- Stop placement mode
-----------------------------------------------------------------------------
function ZKTacticalDeployments.DeploymentState.StopPlacement()
    if State.Active then
        State.Active = false
        State.WaitForRelease = true
        State.ItemID = nil
        RemoveGhost()
        -- chat.AddText(Color(255, 255, 0), "[TDS] ", Color(255, 255, 255), "Placement Cancelled.")
    end
end

-----------------------------------------------------------------------------
-- HOOK: CreateMove
-- Handle Input (Left/Right Click) and suppress weapon fire
-----------------------------------------------------------------------------
hook.Add("CreateMove", "ZKTDS_DeploymentInput", function(cmd)
    -- 1. Handle Input Release Safety
    -- If we just finished placing/cancelling, block input until buttons are released
    -- to prevent accidental shooting.
    if State.WaitForRelease then
        local attack1 = cmd:KeyDown(IN_ATTACK)
        local attack2 = cmd:KeyDown(IN_ATTACK2)

        if attack1 or attack2 then
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2)
            return
        else
            State.WaitForRelease = false
        end
    end

    if not State.Active then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then 
        ZKTacticalDeployments.DeploymentState.StopPlacement()
        return 
    end

    -- Update Ghost Position (Logic similar to Think, but synchronized with input)
    -- Actually, visual updates are better in Think/PostDraw, but we need the trace for validation here.
    
    -- CANCEL (Attack2)
    if cmd:KeyDown(IN_ATTACK2) then
        cmd:RemoveKey(IN_ATTACK2) -- Consume key
        ZKTacticalDeployments.DeploymentState.StopPlacement()
        return
    end

    -- PLACE (Attack1)
    if cmd:KeyDown(IN_ATTACK) then
        -- Only trigger on 'Just Pressed' simulation. 
        -- CreateMove runs every tick, we don't want spam.
        -- We can use a cooldown or check if it was not down previously (harder in CreateMove without tracking).
        -- Or just rely on the server validation to prevent spam, but net spam is bad.
        -- Let's use a simple cooldown.
        
        if (State.NextClick or 0) < CurTime() then
            State.NextClick = CurTime() + 0.5
            
            -- Validate Client Side Geometry First
            local tr = ply:GetEyeTrace()
            local valid, reason = ZKTacticalDeployments.Deployment.CanPlaceGeometry(ply, tr)
            
            if valid then
                -- Send to Server
                net.Start("ZKTDS_PlaceItem")
                net.WriteString(State.ItemID)
                net.SendToServer()
                
                -- Optimistic finish? Or wait for server?
                -- Usually better to wait, but for smooth feel let's stop placement.
                -- If it fails server-side, they have to open menu again. 
                -- Alternatively, keep it open until confirmed.
                ZKTacticalDeployments.DeploymentState.StopPlacement()
            else
                chat.AddText(Color(255, 0, 0), "[TDS] Cannot place: " .. reason)
                surface.PlaySound("buttons/button10.wav")
            end
        end
        
        cmd:RemoveKey(IN_ATTACK) -- Consume key so they don't shoot
    end
end)

-----------------------------------------------------------------------------
-- HOOK: PostDrawTranslucentRenderables or Think
-- Draw Ghost
-----------------------------------------------------------------------------
hook.Add("Think", "ZKTDS_GhostUpdate", function()
    if not State.Active or not IsValid(State.GhostEnt) then return end
    
    local ply = LocalPlayer()
    local tr = ply:GetEyeTrace()
    
    State.GhostEnt:SetPos(tr.HitPos)
    State.GhostEnt:SetAngles(Angle(0, ply:EyeAngles().yaw, 0))
    
    -- Color based on validity
    local valid, _ = ZKTacticalDeployments.Deployment.CanPlaceGeometry(ply, tr)
    if valid then
        State.GhostEnt:SetColor(Color(0, 255, 0, 150))
    else
        State.GhostEnt:SetColor(Color(255, 0, 0, 150))
    end
end)
