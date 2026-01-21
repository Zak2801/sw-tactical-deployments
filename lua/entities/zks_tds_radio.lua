AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "zks_tds_base_ent"
ENT.PrintName = "Rally Point"
ENT.Author = "Zaktak"
ENT.Category = "SWRP: TDS"
ENT.Spawnable = false

-- Child-specific defaults
ENT.Model = "models/lordtrilobite/starwars/props/barrel_scarif2c_phys.mdl"
ENT.DefaultMaxHP = 500
ENT.OverrunEnemies = 5
ENT.InitialAmmo = 600
ENT.LinkedEnts = {}
ENT.MaxHabs = 2
ENT.MaxHabDistance = 1000

ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.FOBs = ZKTacticalDeployments.FOBs or {}
ZKTacticalDeployments.Collections = ZKTacticalDeployments.Collections or {}


function ENT:AddLinked(ent, typ)
    if IsValid(ent) then
        self.LinkedEnts[ent] = typ or 'default'
        local id = ent:GetCreationID()..CurTime()   -- This Should be a completly unique ID
        ent._TDS_ID = id
    end
end

function ENT:RemoveLinked(ent)
    self.LinkedEnts[ent] = nil
end

function ENT:GetLinkedHabs()
    local habs = {}
    for ent, typ in pairs(self.LinkedEnts) do
        if typ == 'hab' then
            habs[#habs + 1] = ent
        end
    end

    return habs
end


-- ----------------------------------------
-- INITIALIZE (child extension)
-- ----------------------------------------
if SERVER then
    function ENT:Initialize()
        self.BaseClass.Initialize(self)
        local teamID = self:GetTeam()

        if not teamID or teamID == "" then
            print("[RADIO] Error: No team assigned.")
            self:Remove()
            return
        end

        local collectionID = ZKTacticalDeployments.Collections.GetPlyCollections(teamID)

        if not collectionID or collectionID == "" then
            print("[RADIO] Error: No collection group assigned.")
            self:Remove()
            return
        end

        self:SetGroupName(collectionID)
        
        -- local succ, err = ZKTacticalDeployments.FOBs.Add(collectionID, self)
        -- if succ == false then
        --     print(err)
        --     self:Remove()
        -- end
    end
end

-- ----------------------------------------
-- USE LOGIC
-- ----------------------------------------
function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    -- Pickup radio if holding SHIFT
    if activator == self:GetPlacer() and activator:KeyDown(IN_SPEED) then
        self:DestroyObj("Picked up.")

        local has = false
        for _, wep in ipairs(activator:GetWeapons()) do
            if wep:GetClass() == "wp_radio_deployer" then
                wep:SetClip1(wep:Clip1() + 1)
                has = true
                break
            end
        end

        if not has then
            activator:Give("wp_radio_deployer"):SetClip1(1)
        end
        return
    end
end

function ENT:LinkHab(ent)
    if not IsValid(ent) then return false, "Invalid HAB entity." end
    if ent:GetClass() ~= "zks_tds_hab" then return false, "Entity is not a HAB." end
    if self:GetLinkedHabs() >= self.MaxHabs then return false, "Maximum linked HABs reached." end
    if ent:GetPos():DistToSqr(self:GetPos()) > self.MaxHabDistance * self.MaxHabDistance then
        return false, "HAB is too far from the radio."
    end

    self:AddLinked(ent, 'hab')
    return true
end


function ENT:DestroyObj()
    for ent, _ in pairs(self.LinkedEnts) do
        if IsValid(ent) then
            local succ, err = pcall(function() ent:DestroyObj("Linked radio destroyed.") end)
            if not succ then
                if IsValid(ent) then ent:Remove() end
            end
        end
    end

    self.BaseClass.DestroyObj(self)
end

-- ----------------------------------------
-- DRAW
-- ----------------------------------------
if CLIENT then
    function ENT:Draw()
        self:DrawModel()

        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if ply:GetPos():DistToSqr(self:GetPos()) > 500 * 500 then return end

        local text = "Radio"
        local pos = self:GetPos() + Vector(0,0,80) + self:GetForward() * 1.2
        local ang = (ply:EyePos() - self:GetPos()):Angle()

        ang:RotateAroundAxis(ang:Right(), 90)
        ang:RotateAroundAxis(ang:Up(), 90)

        surface.SetFont("BF2_HUDFont")
        local tw, th = surface.GetTextSize(text)
        local pad = 14
        local bw, bh = tw + pad*2, th + pad*1.2

        cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.08)
            surface.SetDrawColor(0,0,0,200)
            for i = 1,4 do
                draw.RoundedBox(8, -bw/2, -bh/2, bw, bh, Color(0,0,0,50))
            end
            surface.SetDrawColor(255,255,255,220)
            surface.DrawOutlinedRect(-bw/2, -bh/2, bw, bh)
            draw.SimpleText(text, "BF2_HUDFont", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end
