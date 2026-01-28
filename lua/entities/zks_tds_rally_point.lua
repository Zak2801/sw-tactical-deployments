AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "zks_tds_base_ent"
ENT.PrintName = "Rally Point"
ENT.Author = "Zaktak"
ENT.Category = "SWRP: TDS"
ENT.Spawnable = false

-- Child-specific defaults
ENT.Model = "models/niksacokica/tds/datacron_terminal_sith.mdl"
ENT.DefaultMaxHP = 100
ENT.OverrunEnemies = 5
ENT.InitialAmmo = 600

ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.Rallies = ZKTacticalDeployments.Rallies or {}

-- ----------------------------------------
-- INITIALIZE (child extension)
-- ----------------------------------------
if SERVER then
    function ENT:Initialize()
        self.BaseClass.Initialize(self)

        self:SetAmmoTank(self.InitialAmmo)

        -- Register rally by team
        local teamID = self:GetGroupName()

        if not teamID or teamID == "" then
            print("[RALLY] Error: No team assigned.")
            self:Remove()
            return
        end

        local succ, err = ZKTacticalDeployments.Rallies.Add(teamID, self)
        if succ == false then
            print(err)
            self:Remove()
        end
    end
end

-- ----------------------------------------
-- USE LOGIC (unique to rally)
-- ----------------------------------------
function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    -- Pickup rally if holding SHIFT
    if activator == self:GetPlacer() and activator:KeyDown(IN_SPEED) then
        self:DestroyObj("Picked up.")

        local has = false
        for _, wep in ipairs(activator:GetWeapons()) do
            if wep:GetClass() == "wp_rally_deployer" then
                wep:SetClip1(wep:Clip1() + 1)
                has = true
                break
            end
        end

        if not has then
            activator:Give("wp_rally_deployer"):SetClip1(1)
        end
        return
    end

    -- Give ammo
    if self:GetAmmoTank() <= 0 then
        activator:ChatPrint("Rally has no more ammo.")
        return
    end

    local wep = activator:GetActiveWeapon()
    if not IsValid(wep) then return end

    activator:GiveAmmo(20, wep:GetPrimaryAmmoType(), false)
    activator:ChatPrint("Collected ammo from rally point!")

    self:SetAmmoTank(self:GetAmmoTank() - 20)
end

-- ----------------------------------------
-- DRAW (custom rally UI)
-- ----------------------------------------
if CLIENT then
    function ENT:Draw()
        self:DrawModel()

        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if ply:GetPos():DistToSqr(self:GetPos()) > 500 * 500 then return end

        local text = (self:GetGroupName() or "Unknown") .. "'s Rally Point"
        local pos = self:GetPos() + Vector(0,0,50)
        local ang = (ply:EyePos() - self:GetPos()):Angle()

        ang:RotateAroundAxis(ang:Right(), 90)
        ang:RotateAroundAxis(ang:Up(), 90)

        surface.SetFont("TACDEPS_HUDFont")
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
            draw.SimpleText(text, "TACDEPS_HUDFont", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end
