--[[-------------------------------------------------------------------------
  lua\zks_tac_deployments\sh_deployables.lua
  SHARED
  Registry for all deployable items and their rules.
---------------------------------------------------------------------------]]

ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.Deployables = ZKTacticalDeployments.Deployables or {}
ZKTacticalDeployments.Deployables.List = {}

-----------------------------------------------------------------------------
-- Register a new deployable item
-- @param id string Unique ID
-- @param data table Item definition
-----------------------------------------------------------------------------
function ZKTacticalDeployments.Deployables.Register(id, data)
    ZKTacticalDeployments.Deployables.List[id] = data
end

-----------------------------------------------------------------------------
-- Get a deployable item by ID
-- @param id string Unique ID
-- @return table Item definition or nil
-----------------------------------------------------------------------------
function ZKTacticalDeployments.Deployables.Get(id)
    return ZKTacticalDeployments.Deployables.List[id]
end

-- Define Items
ZKTacticalDeployments.Deployables.Register("radio", {
    PrintName = "FOB Radio",
    EntName = "zks_tds_radio",
    GhostModel = "models/lordtrilobite/starwars/props/barrel_scarif2c_phys.mdl",
    
    -- Server-side validation logic
    -- @param ply Player
    -- @param pos Vector Target position
    -- @return bool, string (Success, Reason)
    ValidatePlace = function(ply, pos)
        local hasFriendlyNearby = false
        local plyCollection = ZKTacticalDeployments.Collections.GetPlyCollections(ply:Team())
    
        for _, v in ipairs(ents.FindInSphere(pos, 500)) do
            if v:IsPlayer() and ZKTacticalDeployments.Collections.GetPlyCollections(v:Team()) ==
                               plyCollection
                               and v ~= ply then
                hasFriendlyNearby = true
                break
            end
        end
    
        if not hasFriendlyNearby then
            return false, "You need a teammate nearby."
        end
    
        if ply:GetPos():Distance(pos) > 200 then
            return false, "Too far away."
        end
    
        -- Check distance to other radios and remove old ones if allowed/needed
        -- Logic adapted from wp_radio_deployer.lua
        local radios, reason = ZKTacticalDeployments.FOBs.GetRadios(plyCollection)
    
        for _, v in pairs(radios or {}) do
            if IsValid(v) then
                if v:GetPos():Distance(pos) <= 2500 then
                    -- Note: Side-effect in validation? Ideally validation is pure, but the original code
                    -- removed the old radio here. We'll keep it consistent with the original behavior 
                    -- OR handle removal in OnSpawn.
                    -- For now, we return true, but we might want to move the removal to OnSpawn.
                    -- However, the original code removed it inside IsPlacementValidServer BEFORE returning true.
                    -- We'll flag it here.
                    return true, nil, { replace_radio = v } 
                end
            end
        end
        return true
    end,

    -- Called after successful spawn
    OnSpawn = function(ply, ent, context)
        ZKTacticalDeployments.FOBs.Add(ent:GetGroupName(), ent, "radio")
        
        -- Handle replacement if flagged
        if context and context.replace_radio and IsValid(context.replace_radio) then
             local plyCollection = ZKTacticalDeployments.Collections.GetPlyCollections(ply:Team())
             ZKTacticalDeployments.FOBs.Remove(plyCollection, context.replace_radio)
        end
    end
})

ZKTacticalDeployments.Deployables.Register("rally", {
    PrintName = "Rally Point",
    EntName = "zks_tds_rally_point",
    GhostModel = "models/niksacokica/tds/datacron_terminal_sith.mdl",
    -- GhostScale = Vector(1.4, 1.4, 1.4), -- Based on weapon code: size 0.14 vs 0.1 for radio (1.4x relative?) 
    -- Wait, the weapon code says:
    -- Radio: size = Vector(0.1, 0.1, 0.1)
    -- Rally: size = Vector(0.14, 0.14, 0.14)
    -- But that's for VElements/WElements on the grenade body.
    -- The GhostModel itself is usually scale 1. The weapon code IsPlacementValidServer didn't scale the ghost.
    -- Let's check wp_zks_spawner_base.lua later for ghost scaling.
    
    ValidatePlace = function(ply, pos)
        local hasFriendlyNearby = false
    
        for _, v in ipairs(ents.FindInSphere(pos, 500)) do
            if v:IsPlayer() and ZKTacticalDeployments.Groups.GetPlyGroup(v:Team()) ==
                               ZKTacticalDeployments.Groups.GetPlyGroup(ply:Team())
                               and v ~= ply then
                hasFriendlyNearby = true
                break
            end
        end
    
        if not hasFriendlyNearby then
            return false, "You need a teammate nearby."
        end
    
        if ply:GetPos():Distance(pos) > 200 then
            return false, "Too far away."
        end
        
        return true
    end,
    
    OnSpawn = function(ply, ent)
        -- No special registration in original wp_rally_deployer.lua
    end
})
