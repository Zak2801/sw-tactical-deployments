if SERVER then AddCSLuaFile() end

SWEP.Base = "wp_zks_spawner_base"
SWEP.PrintName = "Rally Deployer"
SWEP.Author = "Zaktak"
SWEP.Instructions = "Deploy rally points for your team."
SWEP.Category = "SWRP: TDS"

SWEP.Spawnable = true
SWEP.AdminOnly = false

-- Set the ID to load logic from Registry
SWEP.DeployableID = "rally"

SWEP.Primary.ClipSize = 3
SWEP.Primary.DefaultClip = 3
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "RallyCharge"

SWEP.HoldType = "slam"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {
	["ValveBiped.Grenade_body"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}

SWEP.IronSightsPos = Vector(3.079, 0, 2.16)
SWEP.IronSightsAng = Vector(0, 0, 0)

SWEP.VElements = {
	["rally"] = { type = "Model", model = "models/niksacokica/tds/datacron_terminal_sith.mdl", bone = "ValveBiped.Grenade_body", rel = "", pos = Vector(-0.494, 0, 0), angle = Angle(-163.333, 12.222, -5.557), size = Vector(0.14, 0.14, 0.14), color = Color(255, 255, 255, 255), surpresslightning = true, material = "", skin = 0, bodygroup = {} }
}

SWEP.WElements = {
	["rally"] = { type = "Model", model = "models/niksacokica/tds/datacron_terminal_sith.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(2.599, 2.469, 1), angle = Angle(-163.333, 23.333, 3.332), size = Vector(0.14, 0.14, 0.14), color = Color(255, 255, 255, 255), surpresslightning = true, material = "", skin = 0, bodygroup = {} }
}