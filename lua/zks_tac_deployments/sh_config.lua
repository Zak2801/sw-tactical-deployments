ZKTacticalDeployments = ZKTacticalDeployments or {}
ZKTacticalDeployments.Collections = ZKTacticalDeployments.Collections or {}


ZKTacticalDeployments.Collections.List = {

    -- Example: A police force HAB shared across police categories
    PoliceForce = {
        name   = "Police Forces",
        color  = Color(50, 120, 255),
        groups = { "Civil Protection", "SWAT" }
    },

    -- Example: Criminals shared fob
    Criminals = {
        name   = "Criminal Factions",
        color  = Color(255, 60, 60),
        groups = { "Gangs", "Thieves", "Mob" }
    },

}
