--[[-------------------------------------------------------------------------
  lua\zks_tac_deployments\core\sv_deployment.lua
  SERVER
  Handles network requests for placing items.
---------------------------------------------------------------------------]]

util.AddNetworkString("ZKTDS_PlaceItem")

-----------------------------------------------------------------------------
-- Net Handler: Place Item
-----------------------------------------------------------------------------
net.Receive("ZKTDS_PlaceItem", function(len, ply)
    if not IsValid(ply) then return end
    
    local itemID = net.ReadString()
    local item = ZKTacticalDeployments.Deployables.Get(itemID)
    
    if not item then return end
    
    -- Perform authoritative validation
    local tr = ply:GetEyeTrace()
    local valid, reason, context = ZKTacticalDeployments.Deployment.AttemptPlace(ply, itemID, tr)
    
    if not valid then
        ply:ChatPrint("[TDS] Failed to place: " .. (reason or "Unknown error"))
        return
    end
    
    -- Spawn Entity
    local ent = ents.Create(item.EntName)
    if not IsValid(ent) then
        print("[TDS] Error: Could not create entity " .. item.EntName)
        return
    end
    
    ent:SetTeam(ply:Team())
    
    -- Group logic
    ZKTacticalDeployments.Groups = ZKTacticalDeployments.Groups or {}
    local groupName = "Public"
    if ZKTacticalDeployments.Groups.GetPlyGroup then
        groupName = ZKTacticalDeployments.Groups.GetPlyGroup(ply:Team())
    end
    ent:SetGroupName(groupName)

    MsgC(Color(0, 255, 0, 255), "[TDS] Player " .. ply:Nick() .. " deployed " .. item.PrintName .. " for group " .. groupName .. ".\n")
    
    -- Position
    -- If items define specific offsets, we should handle them. 
    -- The base weapon had Vector(0,0,1).
    ent:SetPos(tr.HitPos + Vector(0,0,1))
    ent:SetAngles(Angle(0, ply:EyeAngles().yaw, 0))
    ent:Spawn()
    ent:Activate()
    
    if ent.SetPlacer then
        ent:SetPlacer(ply)
    end
    
    -- Post-Spawn Logic (Registration, Removal of old items)
    if item.OnSpawn then
        item.OnSpawn(ply, ent, context)
    end
    
    ply:ChatPrint("[TDS] Deployed " .. item.PrintName)
end)
