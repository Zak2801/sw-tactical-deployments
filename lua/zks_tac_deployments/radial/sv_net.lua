util.AddNetworkString("ZKTDS_RequestPlaceObj")
util.AddNetworkString("ZKTDS_RequestPickupRally")

local wepClasses = {"wp_rally_deployer", "wp_radio_deployer"}

-- ─────────────────────────────────────────────────────────────
-- Gives the player a weapon and strips it when not in hands
-- @param ply Player
-- @param wepClass string
-- @return nil 
-- ─────────────────────────────────────────────────────────────
local function GiveWeaponAndStrip(ply, wepClass)
    -- Give if missing
    if not ply:HasWeapon(wepClass) then
        ply:Give(wepClass)
    end

    -- Force equip
    ply:SelectWeapon(wepClass)
    local wep = ply:GetWeapon(wepClass)
    if !IsValid(wep) then return end

    -- Function that repeatedly attempts stripping
    local function TryStrip()
        if not IsValid(ply) then return end
        if not ply:HasWeapon(wepClass) then return end

        local active = ply:GetActiveWeapon()
        if IsValid(active) and active:GetClass() == wepClass then
            -- Player is still holding it → try again in 5s
            timer.Simple(5, TryStrip)
            return
        end

        -- Safe to strip now
        ply:StripWeapon(wepClass)
    end

    -- Start first check in 5 seconds
    timer.Simple(5, TryStrip)
end


-- ─────────────────────────────────────────────────────────────
-- Player requested to place a rally (gives deployer)
-- DEPRECATED: Replaced by ZKTDS_PlaceItem
-- ─────────────────────────────────────────────────────────────
--[[
net.Receive("ZKTDS_RequestPlaceObj", function(_, ply)
    if not IsValid(ply) then return end
    local index = net.ReadInt(4)

    local succ, err = pcall(function() GiveWeaponAndStrip(ply, wepClasses[index]) end)
    if not succ then
        print(err)
    end
end)
]]

-- ─────────────────────────────────────────────────────────────
-- Player requested to pickup a rally
-- @param _ int length of the msg
-- @param ply Player
-- @return nil 
-- ─────────────────────────────────────────────────────────────
net.Receive("ZKTDS_RequestPickupRally", function(_, ply)
    if not IsValid(ply) then return end

    local ent = ply:GetEyeTrace().Entity
    if !IsValid(ent) then return end
    if ent:GetClass() ~= "zks_tds_rally_point" then ply:ChatPrint("[TDS]: You are not looking at a rally.") return end
    if ent:GetPlacer() == ply then ent:DestroyRally("Picked up.") end
    local wepClass = "wp_rally_deployer"
    GiveWeaponAndStrip(ply, wepClass)
end)