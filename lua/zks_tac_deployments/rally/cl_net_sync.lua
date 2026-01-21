
ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.Groups = ZKTacticalDeployments.Groups or {}
ZKTacticalDeployments.TeamRallies = ZKTacticalDeployments.TeamRallies or {}

-- ─────────────────────────────────────────────────────────────
-- Sync Rally Data to clients
-- @param rally Entity
-- @return teamCategoryName String - The Team's Name (ID) 
-- ─────────────────────────────────────────────────────────────
net.Receive("ZKTDS_SyncRallyData", function()
    local rally = net.ReadEntity()
    local teamCategoryName = net.ReadString()
    if !IsValid(rally) or not teamCategoryName then return end

    ZKTacticalDeployments.TeamRallies[teamCategoryName] = rally
end)