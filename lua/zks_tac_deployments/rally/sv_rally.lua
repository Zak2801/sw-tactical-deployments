util.AddNetworkString("ZKTDS_SpawnAtRally")
util.AddNetworkString("ZKTDS_ShowDeathScreen")
util.AddNetworkString("ZKTDS_SyncRallyData")

ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.Rallies = ZKTacticalDeployments.Rallies or {}
ZKTacticalDeployments.Rallies.List = ZKTacticalDeployments.Rallies.List or {}
local Rallies = ZKTacticalDeployments.Rallies

-- ─────────────────────────────────────────────────────────────
-- Get Rally Entity by team
-- @param team TeamID (string)
-- @return Rally Entity | nil 
-- ─────────────────────────────────────────────────────────────
function Rallies.Get(team)
    if !IsValid(team) then return nil, "Team is Invalid." end
    if not Rallies.List then return nil, "No Rallies." end
    return Rallies.List[team]
end

-- ─────────────────────────────────────────────────────────────
-- Add a rally for a team and network it to clients
-- @param team TeamID (string)
-- @param rally entity
-- @return boolean success, string|nil error
-- ─────────────────────────────────────────────────────────────
function Rallies.Add(team, rally)
    if !IsValid(rally) then return false, "Rally Entity Invalid." end
    Rallies.Remove(team)
    Rallies.List[team] = rally
    timer.Simple(.1, function() -- GMOD Quirk
        if not IsValid(rally) then return end

        net.Start("ZKTDS_SyncRallyData")
        net.WriteEntity(rally)
        net.WriteString(rally:GetGroupName() or "Public")
        net.Broadcast()
    end)

    return true
end

-- ─────────────────────────────────────────────────────────────
-- Remove a rally from a team
-- @param team TeamID (string)
-- @return boolean success, string|nil error
-- ─────────────────────────────────────────────────────────────
function Rallies.Remove(team)
    if IsValid(Rallies.List[team]) then
        local success, err = pcall(function() Rallies.List[team]:Remove() end)
        Rallies.List[team] = nil
        if success == false then
            return false, "Could Not Remove Rally. "..err
        end
        return true
    end
    Rallies.List[team] = nil
    return false, "Rally Entity Invalid."
end


local SAFE_SPAWN_GOD_TIME = 3     -- How long the player is invulnerable after spawning
local SAFE_SPAWN_RADIUS    = 150  -- max offset distance around rally
local SAFE_SPAWN_TRIES     = 20   -- how many random locations we try

-- ─────────────────────────────────────────────────────────────
-- Finds a safe spot near given entity
-- @param rally Entity
-- @return Vector | nil
-- ─────────────────────────────────────────────────────────────
local function FindSafeSpawnPosition(rally)
    if not IsValid(rally) then return nil end

    local basePos = rally:GetPos()

    for i = 1, SAFE_SPAWN_TRIES do
        local offset = Vector(
            math.random(-SAFE_SPAWN_RADIUS, SAFE_SPAWN_RADIUS),
            math.random(-SAFE_SPAWN_RADIUS, SAFE_SPAWN_RADIUS),
            0
        )

        local testPos = basePos + offset + Vector(0,0,5)

        -- Use a hull trace equal to player standing size to check for space
        local tr = util.TraceHull({
            start  = testPos,
            endpos = testPos,
            mins   = Vector(-16, -16, 0),
            maxs   = Vector(16, 16, 72),
            mask   = MASK_PLAYERSOLID
        })

        if not tr.Hit then
            return testPos
        end
    end

    return nil -- All tries failed
end

-- ─────────────────────────────────────────────────────────────
-- Spawn the player on a rally
-- @param len int
-- @param ply Player
-- @return nil
-- ─────────────────────────────────────────────────────────────
net.Receive("ZKTDS_SpawnAtRally", function(len, ply)
    if not IsValid(ply) then return end

    local rally = net.ReadEntity()
    local safePos

    -- Spawn player if dead
    if not ply:Alive() then
        ply:Spawn()
    end

    -- If we don't have a valid rally, fail gracefully
    if not IsValid(rally) then
        -- ply:ChatPrint("[TDS]: Rally no longer available, spawning normally.")
        return
    end

    -- Try finding a safe spawn position
    safePos = FindSafeSpawnPosition(rally)

    if not safePos then
        ply:ChatPrint("[TDS]: No safe spot found near rally! Spawning at default rally location.")
        safePos = rally:GetPos() + Vector(0,0,55)
    else
        ply:ChatPrint("[TDS]: Spawned on Rally.")
    end

    -- Move player
    ply:SetPos(safePos)

    -- Apply temporary god mode
    ply:GodEnable()

    timer.Simple(SAFE_SPAWN_GOD_TIME, function()
        if IsValid(ply) then
            ply:GodDisable()
        end
    end)
end)


-- ─────────────────────────────────────────────────────────────
-- Hook called on Player's Death,
-- we use this to display deathscreen.
-- @param victim Player - Player that died
-- @param inflictor Entity - Caused player Death
-- @param attacker Entity - Killed player
-- @return nil
-- ─────────────────────────────────────────────────────────────
hook.Add("PlayerDeath", "ZKTacticalDeployments_DeathScreen", function(victim, inflictor, attacker)
    if !IsValid(victim) then return end
    local text = "Yourself"
    if ( victim ~= attacker ) then
        if attacker:IsPlayer() then
            text = attacker:Nick()
        else
            if attacker.PrintName ~= nil then
                text = attacker.PrintName
            else
                text = attacker:GetClass()
            end
        end
    end

    net.Start("ZKTDS_ShowDeathScreen")
    net.WriteBool(true)
    net.WriteString(text)
    net.Send(victim)
end)

-- Hook when player respawns
hook.Add("PlayerSpawn", "ZKTacticalDeployments_HideDeathScreen", function(ply)
    if !IsValid(ply) then return end
    net.Start("ZKTDS_ShowDeathScreen")
    net.WriteBool(false)
    net.Send(ply)
end)