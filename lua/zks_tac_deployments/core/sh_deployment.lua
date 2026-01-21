--[[-------------------------------------------------------------------------
  lua\zks_tac_deployments\core\sh_deployment.lua
  SHARED
  Shared logic for validating placement (Geometry, Distance, Physics).
---------------------------------------------------------------------------]]

ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.Deployment = ZKTacticalDeployments.Deployment or {}

-- Configurable limits
local MAX_DIST = 200
local MAX_SLOPE = 45 -- degrees

-----------------------------------------------------------------------------
-- Checks if the position is geometrically valid (Slope, Distance, Line of Sight)
-- @param ply Player The player attempting to place
-- @param traceResult table The trace result from the player's eyes
-- @return bool, string (Success, Reason)
-----------------------------------------------------------------------------
function ZKTacticalDeployments.Deployment.CanPlaceGeometry(ply, traceResult)
    if not traceResult.Hit then return false, "Too far." end

    -- 1. Distance Check
    if traceResult.HitPos:Distance(ply:GetPos()) > MAX_DIST then
        return false, "Too far away."
    end

    -- 2. Ground/World Check
    if not traceResult.Entity:IsWorld() then
        -- Optional: Allow placing on specific static props? For now, stick to world geometry.
        -- If we want to allow props, we can check traceResult.Entity:GetPhysicsObject():IsMotionEnabled() etc.
        -- But typically Squad/PR restrict to world.
        if not traceResult.Entity:GetClass():find("func_brush") and not traceResult.Entity:IsWorld() then
             return false, "Must be placed on the ground."
        end
    end

    -- 3. Slope Check
    -- HitNormal is perpendicular to the surface.
    -- Angle between Up Vector (0,0,1) and HitNormal.
    local slopeAngle = math.deg(math.acos(traceResult.HitNormal:Dot(Vector(0, 0, 1))))
    
    if slopeAngle > MAX_SLOPE then
        return false, "Too steep."
    end
    
    -- 4. Line of Sight (Implicit in the trace passed, but good to verify if trace is manipulated)
    
    return true
end

-----------------------------------------------------------------------------
-- Attempts to place an item (Server-side Entry Point)
-- @param ply Player
-- @param itemID string
-- @param viewTrace table (Optional) Override trace for VR/Tools? Default is EyeTrace.
-- @return bool, string
-----------------------------------------------------------------------------
function ZKTacticalDeployments.Deployment.AttemptPlace(ply, itemID, viewTrace)
    local item = ZKTacticalDeployments.Deployables.Get(itemID)
    if not item then return false, "Invalid item." end

    local tr = viewTrace or ply:GetEyeTrace()
    
    -- 1. Geometry Check
    local geoOk, geoErr = ZKTacticalDeployments.Deployment.CanPlaceGeometry(ply, tr)
    if not geoOk then return false, geoErr end

    -- 2. Item-Specific Logic (Team, etc.)
    if item.ValidatePlace then
        local valid, reason, context = item.ValidatePlace(ply, tr.HitPos)
        if not valid then return false, reason end
        return true, nil, context -- Pass context (e.g., replace_radio)
    end

    return true
end
