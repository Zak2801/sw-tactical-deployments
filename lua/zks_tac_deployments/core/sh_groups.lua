ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.Groups = ZKTacticalDeployments.Groups or {}
ZKTacticalDeployments.Groups.List = ZKTacticalDeployments.Groups.List or {}
ZKTacticalDeployments.Groups.Lookup = ZKTacticalDeployments.Groups.Lookup or {}


-- ─────────────────────────────────────────────────────────────
-- Get Player's Group by teamID (gmod's built-in team id)
-- @param teamID int
-- @return group String - The Team's Name (ID) 
-- ─────────────────────────────────────────────────────────────
function ZKTacticalDeployments.Groups.GetPlyGroup(teamID)
    local group = ZKTacticalDeployments.Groups.Lookup[teamID] or "Public"
    return group
end


-- ─────────────────────────────────────────────────────────────
-- Hook on the Init of game, builds groups by darkRP jobs,
-- builds a lookup table for later.
-- @return nil
-- ─────────────────────────────────────────────────────────────
hook.Add("InitPostEntity", "ZKTacticalDeployments_Init", function()
    if not GAMEMODE or GAMEMODE.Name ~= "DarkRP" then
        ZKTacticalDeployments.Groups.List = {}
        return
    end

    local categories = DarkRP.getCategories().jobs or {}

    for teamID, jobData in pairs(RPExtraTeams) do
        local categoryName = jobData.category or "Uncategorized"
        local groups = ZKTacticalDeployments.Groups.List

        -- Create new category if missing
        if not groups[categoryName] then
            local categoryColor = Color(0, 255, 0)

            -- Match DarkRP category color if it exists
            for _, cat in ipairs(categories) do
                if cat.name == categoryName and cat.color then
                    categoryColor = cat.color
                    break
                end
            end

            groups[categoryName] = {
                name  = categoryName,
                color = categoryColor,
                jobs  = {}
            }
        end

        -- Insert job
        table.insert(groups[categoryName].jobs, {
            teamID = teamID,
            name   = jobData.name,
        })

        -- Building an O(1) lookup table (hashmap)
        ZKTacticalDeployments.Groups.Lookup[teamID] = categoryName
    end
end)
