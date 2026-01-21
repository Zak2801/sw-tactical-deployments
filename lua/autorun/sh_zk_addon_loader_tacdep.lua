---------------------------------------------------------------
--  lua\autorun\sh_zk_addon_loader_tacdep.lua
---------------------------------------------------------------
ZKTacticalDeployments = ZKTacticalDeployments or {}

ZKTacticalDeployments.VERSION = 1
ZKTacticalDeployments.VERSION_GITHUB = 0
ZKTacticalDeployments.VERSION_TYPE = ".GIT"

function ZKTacticalDeployments:GetVersion()
	return ZKTacticalDeployments.VERSION
end

function ZKTacticalDeployments:CheckUpdates()
	http.Fetch("https://raw.githubusercontent.com/Zak2801/sw-tactical-deployments/refs/heads/main/lua/autorun/sh_addon_loader_tacdep.lua", function(contents,size) 
		local Entry = string.match( contents, "ZKTacticalDeployments.VERSION%s=%s%d+" )

		if Entry then
			ZKTacticalDeployments.VERSION_GITHUB = tonumber( string.match( Entry , "%d+" ) ) or 0
		else
			ZKTacticalDeployments.VERSION_GITHUB = 0
		end

		if ZKTacticalDeployments.VERSION_GITHUB == 0 then
			print("[TacticalDeployments] Latest version could not be detected, You have Version: "..ZKTacticalDeployments:GetVersion())
		else
			if  ZKTacticalDeployments:GetVersion() >= ZKTacticalDeployments.VERSION_GITHUB then
				print("[TacticalDeployments] up to date. Version: "..ZKTacticalDeployments:GetVersion())
			else
				print("[TacticalDeployments] a newer version is available! Version: "..ZKTacticalDeployments.VERSION_GITHUB..", You have Version: "..ZKTacticalDeployments:GetVersion())

				if ZKTacticalDeployments.VERSION_TYPE == ".GIT" then
					print("[TacticalDeployments] Get the latest version at https://github.com/Zak2801/sw-tactical-deployments")
				else
					print("[TacticalDeployments] Restart your game/server to get the latest version!")
				end

				if CLIENT then 
					timer.Simple(25, function() 
						chat.AddText( Color( 255, 0, 0 ), "[TacticalDeployments] a newer version is available!" )
					end)
				end
			end
		end
	end)
end

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


hook.Add( "InitPostEntity", "!!zks_tacdeps_checkupdates", function()
	timer.Simple(12, function() ZKTacticalDeployments:CheckUpdates() end)
end )