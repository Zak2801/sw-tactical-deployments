util.AddNetworkString("ZKTDS_SpawnAtRally")
util.AddNetworkString("ZKTDS_ShowDeathScreen")
util.AddNetworkString("ZKTDS_SyncRallyData")

ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.FOBs = ZKTacticalDeployments.FOBs or {}
ZKTacticalDeployments.FOBs.List = ZKTacticalDeployments.FOBs.List or {}
local FOBS = ZKTacticalDeployments.FOBs

-- ─────────────────────────────────────────────────────────────
-- Get all FOBs of a team
-- @param team TeamID (string)
-- @return Rally Entity | nil 
-- ─────────────────────────────────────────────────────────────
function FOBS.Get(team)
    if team then return nil, "Team is Invalid." end
    if not FOBS.List then return nil, "No FOBS." end
    return FOBS.List[team]
end

-- ─────────────────────────────────────────────────────────────
-- Get all FOBs of a team
-- @param team TeamID (string)
-- @return Rally Entity | nil 
-- ─────────────────────────────────────────────────────────────
function FOBS.GetRadios(team)
    if not team then return nil, "Team is Invalid." end
    team = tostring(team)
    if not FOBS.List then return nil, "No FOBS." end
    if not FOBS.List[team] then return nil, "Team has no Radios" end

    local radios = {}
    for _, v in pairs(FOBS.List[team]) do
        if v.type == "radio" then
            table.insert(radios, v.entity)
        end
    end
    return radios
end

-- ─────────────────────────────────────────────────────────────
-- Add a rally for a team and network it to clients
-- @param team TeamID (string)
-- @param rally entity
-- @return boolean success, string|nil error
-- ─────────────────────────────────────────────────────────────
function FOBS.Add(team, ent, typ)
    if !IsValid(ent) then return false, "FOB Entity Invalid." end
    -- FOBS.Remove(team)
    FOBS.List[team] = FOBS.List[team] or {}
    FOBS.List[team][#FOBS.List[team] + 1] = {entity = ent, type = typ}
    PrintTable(FOBS.List)
    timer.Simple(0, function() -- GMOD Quirk
        if not IsValid(ent) then return end

        -- net.Start("ZKTDS_SyncRallyData")
        -- net.WriteEntity(rally)
        -- net.WriteString(rally:GetGroupName() or "Public")
        -- net.Broadcast()
    end)
    return true
end

-- ─────────────────────────────────────────────────────────────
-- Remove a ent from a team
-- @param team TeamID (string)
-- @return boolean success, string|nil error
-- ─────────────────────────────────────────────────────────────
function FOBS.Remove(team, ent)
    if not team then return end
    team = tostring(team)
    if not FOBS.List[team] then return end
    for _, tbl in pairs(FOBS.List[team]) do
        if tbl.entity == ent then
            local success, err = pcall(function() ent:Remove() end)
            tbl = nil
            if success == false then
                return false, "Could Not Remove FOB Entity. "..err
            end
            return true
        end
    end
    return false, "FOB Entity not found."
end


-- local SAFE_SPAWN_GOD_TIME = 3     -- How long the player is invulnerable after spawning
-- local SAFE_SPAWN_RADIUS    = 150  -- max offset distance around rally
-- local SAFE_SPAWN_TRIES     = 20   -- how many random locations we try

-- -- ─────────────────────────────────────────────────────────────
-- -- Finds a safe spot near given entity
-- -- @param rally Entity
-- -- @return Vector | nil
-- -- ─────────────────────────────────────────────────────────────
-- local function FindSafeSpawnPosition(rally)
--     if not IsValid(rally) then return nil end

--     local basePos = rally:GetPos()

--     for i = 1, SAFE_SPAWN_TRIES do
--         local offset = Vector(
--             math.random(-SAFE_SPAWN_RADIUS, SAFE_SPAWN_RADIUS),
--             math.random(-SAFE_SPAWN_RADIUS, SAFE_SPAWN_RADIUS),
--             0
--         )

--         local testPos = basePos + offset + Vector(0,0,5)

--         -- Use a hull trace equal to player standing size to check for space
--         local tr = util.TraceHull({
--             start  = testPos,
--             endpos = testPos,
--             mins   = Vector(-16, -16, 0),
--             maxs   = Vector(16, 16, 72),
--             mask   = MASK_PLAYERSOLID
--         })

--         if not tr.Hit then
--             return testPos
--         end
--     end

--     return nil -- All tries failed
-- end

-- -- ─────────────────────────────────────────────────────────────
-- -- Spawn the player on a rally
-- -- @param len int
-- -- @param ply Player
-- -- @return nil
-- -- ─────────────────────────────────────────────────────────────
-- net.Receive("ZKTDS_SpawnAtRally", function(len, ply)
--     if not IsValid(ply) then return end

--     local rally = net.ReadEntity()
--     local safePos

--     -- Spawn player if dead
--     if not ply:Alive() then
--         ply:Spawn()
--     end

--     -- If we don't have a valid rally, fail gracefully
--     if not IsValid(rally) then
--         -- ply:ChatPrint("[TDS]: Rally no longer available, spawning normally.")
--         return
--     end

--     -- Try finding a safe spawn position
--     safePos = FindSafeSpawnPosition(rally)

--     if not safePos then
--         ply:ChatPrint("[TDS]: No safe spot found near rally! Spawning at default rally location.")
--         safePos = rally:GetPos() + Vector(0,0,55)
--     else
--         ply:ChatPrint("[TDS]: Spawned on Rally.")
--     end

--     -- Move player
--     ply:SetPos(safePos)

--     -- Apply temporary god mode
--     ply:GodEnable()

--     timer.Simple(SAFE_SPAWN_GOD_TIME, function()
--         if IsValid(ply) then
--             ply:GodDisable()
--         end
--     end)
-- end)


-- -- ─────────────────────────────────────────────────────────────
-- -- Hook called on Player's Death,
-- -- we use this to display deathscreen.
-- -- @param victim Player - Player that died
-- -- @param inflictor Entity - Caused player Death
-- -- @param attacker Entity - Killed player
-- -- @return nil
-- -- ─────────────────────────────────────────────────────────────
-- hook.Add("PlayerDeath", "ZKTacticalDeployments_DeathScreen", function(victim, inflictor, attacker)
--     if !IsValid(victim) then return end
--     local text = "Yourself"
--     if ( victim ~= attacker ) then
--         if attacker:IsPlayer() then
--             text = attacker:Nick()
--         else
--             if attacker.PrintName ~= nil then
--                 text = attacker.PrintName
--             else
--                 text = attacker:GetClass()
--             end
--         end
--     end

--     net.Start("ZKTDS_ShowDeathScreen")
--     net.WriteBool(true)
--     net.WriteString(text)
--     net.Send(victim)
-- end)

-- -- Hook when player respawns
-- hook.Add("PlayerSpawn", "ZKTacticalDeployments_HideDeathScreen", function(ply)
--     if !IsValid(ply) then return end
--     net.Start("ZKTDS_ShowDeathScreen")
--     net.WriteBool(false)
--     net.Send(ply)
-- end)