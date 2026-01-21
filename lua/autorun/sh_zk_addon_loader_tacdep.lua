---------------------------------------------------------------
--  lua\autorun\sh_zk_addon_loader_tacdep.lua
---------------------------------------------------------------
ZKTacticalDeployments = ZKTacticalDeployments or {}

function ZKTacticalDeployments.LoadDirectory(path)
	local files, folders = file.Find(path .. "/*", "LUA")

	for _, fileName in ipairs(files) do
		local filePath = path .. "/" .. fileName

		if CLIENT then
			include(filePath)
		else
			if fileName:StartWith("cl_") then
				AddCSLuaFile(filePath)
			elseif fileName:StartWith("sh_") then
				AddCSLuaFile(filePath)
				include(filePath)
			else
				include(filePath)
			end
		end
	end

	return files, folders
end

function ZKTacticalDeployments.LoadDirectoryRecursive(basePath)
	local _, folders = ZKTacticalDeployments.LoadDirectory(basePath)
	for _, folderName in ipairs(folders) do
		ZKTacticalDeployments.LoadDirectoryRecursive(basePath .. "/" .. folderName)
	end
end

ZKTacticalDeployments.LoadDirectoryRecursive("zks_tac_deployments")

if SERVER then
	resource.AddFile( "materials/niksacokica/tech/datacron_set_jedi.vmt" )
	resource.AddFile( "materials/niksacokica/tech/datacron_set_sith.vmt" )
	resource.AddFile( "models/niksacokica/tds/datacron_terminal_sith.mdl" )
	resource.AddFile("resource/fonts/Starjedi.ttf")
end

if CLIENT then
	surface.CreateFont("BF2_HUDFont", {
        font = "Roboto Condensed",
        size = 60,
        weight = 500,
        antialias = true,
    })

	surface.CreateFont("BF2_HUDFont_Small", {
        font = "Roboto Condensed",
        size = 36,
        weight = 500,
        antialias = true,
    })

	sound.Add( {
		name = "tds_menu_loop",
		channel = CHAN_STATIC,
		volume = 1.0,
		level = 80,
		pitch = {95, 110},
		sound = "npc/scanner/combat_scan_loop2.wav"
	} )
end

local version = "v0.1"
MsgC( "\n", Color( 255, 255, 255 ), "---------------------------------- \n" )
MsgC( Color( 65, 215, 160 ), "[Zaktak's Tactical Deployments]\n" )
MsgC( Color( 255, 255, 255 ), "Loading Files.......\n" )
MsgC( Color( 255, 255, 255 ), "Version........ "..version.."\n" )
MsgC( Color( 255, 255, 255 ), "---------------------------------- \n" )