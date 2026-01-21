ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.Collections = ZKTacticalDeployments.Collections or {}

-- ─────────────────────────────────────────────────────────────────────────
-- Get Player's Collection of Groups by teamID (gmod's built-in team id)
-- @param teamID Int
-- @return id Int - The ID of the collection the player is in or -1 if none
-- ─────────────────────────────────────────────────────────────────────────
function ZKTacticalDeployments.Collections.GetPlyCollections(teamID)
    local group = ZKTacticalDeployments.Groups.GetPlyGroup(teamID)

    for id, col in pairs(ZKTacticalDeployments.Collections.List) do
        if table.HasValue(col.groups, group) then
            return id
        end
    end

    return -1
end
