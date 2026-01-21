AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "ZK Tactical Deployable (Base)"
ENT.Author = "Zaktak"
ENT.Spawnable = false
ENT.AdminOnly = false

-- GLOBAL TABLE
ZKTacticalDeployments = ZKTacticalDeployments or {}

-- ----------------------------------------
-- NETWORKED VARS
-- ----------------------------------------
function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "Placer")
    self:NetworkVar("Int", 0, "Team")
    self:NetworkVar("Int", 1, "HP")
    self:NetworkVar("Int", 2, "MaxHP")
    self:NetworkVar("Int", 3, "OverrunHostileCount")
    self:NetworkVar("Int", 4, "AmmoTank")
    self:NetworkVar("String", 0, "GroupName")
end

-- ----------------------------------------
-- INITIALIZE
-- ----------------------------------------
if SERVER then
    function ENT:Initialize()

        -- PLEASE override SetModel in child entity
        if not self.Model then
            self:SetModel("models/props_junk/wood_crate001a.mdl")
        else
            self:SetModel(self.Model)
        end

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() phys:EnableMotion(false) end

        -- Default stats (can be overridden by children)
        self:SetMaxHP(self.DefaultMaxHP or 100)
        self:SetHP(self:GetMaxHP())
        self:SetOverrunHostileCount(self.OverrunEnemies or 5)
        self:SetAmmoTank(-1)

        -- Handle team/group logic (optional for specific entities)
        local group = self:GetGroupName()
        if group and group != "" then
            ZKTacticalDeployments[group] = ZKTacticalDeployments[group] or {}
            table.insert(ZKTacticalDeployments[group], self)
        end
    end
end

-- ----------------------------------------
-- THINK (basic overrun logic)
-- ----------------------------------------
function ENT:Think()
    if SERVER then
        local count = 0
        local maxHostiles = self:GetOverrunHostileCount()

        for _, ent in ipairs(ents.FindInSphere(self:GetPos(), 500)) do
            if ent:IsNPC() and ent:Disposition(self:GetPlacer()) == D_HT then
                count = count + 1
            end
        end

        if maxHostiles > 0 and count >= maxHostiles then
            self:DestroyObj("Overrun by enemies")
            return
        end

        self:NextThink(CurTime() + 3)
        return true
    end
end

-- ----------------------------------------
-- DAMAGE
-- ----------------------------------------
function ENT:OnTakeDamage(dmg)
    if SERVER then
        local hp = self:GetHP() - dmg:GetDamage()

        if hp <= 0 then
            self:DestroyObj("Destroyed")
        else
            self:SetHP(hp)
        end
    end
end

-- ----------------------------------------
-- DESTROY OBJECT
-- ----------------------------------------
function ENT:DestroyObj(reason)
    local owner = self:GetPlacer()

    -- Remove from group
    local group = self:GetGroupName()
    if group and ZKTacticalDeployments[group] then
        table.RemoveByValue(ZKTacticalDeployments[group], self)
    end

    if IsValid(owner) then
        owner:ChatPrint("Your deployable was removed: " .. (reason or "Unknown reason"))
    end

    self:Remove()
end

-- ----------------------------------------
-- USE (empty - defined by child)
-- ----------------------------------------
function ENT:Use(activator)
    -- child entities override this
end
