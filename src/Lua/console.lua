--[[
	EVERYTHING related to the console (commands and cvars) live here.
]]

local debug = false --DON'T FORGET TO SET THIS TO FALSE ON RELEASE!

--Unique suicide command with a funny.
COM_AddCommand("rct1", function(ply)
	if not G_CoopGametype() and not G_CompetitionGametype() then
		CONS_Printf(ply, "\x85This only works in Co-op and Competition!")
	else
		P_DamageMobj(ply.mo, nil, nil, 1, skl.DMG_SKLDTH)

		CONS_Printf(ply, "\x85Mr. Bone's wild ride has ended.")
	end
end)
--The nuclear option; teleports the player back to their starpost OR a spawn point.
COM_AddCommand("thebonezone", function(ply)
	skl.toStarpostOrSpawn(ply)

	S_StartSound(ply.mo, sfx_sklbb)
end)

--Variable to control what sprite Amy players use when reacting to the hug.
CV_RegisterVar({
	name="sklhug_amystyle",
	defaultvalue=0,
	flags=CV_ALLOWLUA|CV_NETVAR|CV_CALL,
	PossibleValue={mod=0, vanilla=1},
	func=function(var)
		if var.changed then
			skl.switch(var.value)
				.case(0, function()
					print("Amy players will now use the sprite style from the hug mod.")
				end)
				.case(1, function()
					print("Amy players will now use the sprite style in the game.")
				end)
			.process()
		end
	end
})

if debug then
	COM_AddCommand("tp", function(ply, x, y, z)
		skl.teleportToPos(ply, tonumber(x)*FU, tonumber(y)*FU, tonumber(z)*FU)
		CONS_Printf(ply, "Teleported to: "..tostring(ply.mo.x/FU)..", "..tostring(ply.mo.y/FU)..", "..tostring(ply.mo.z/FU))
	end)

	COM_AddCommand("killBoss", function(ply)
		skl.misc.triggeredOnTic = leveltime-TICRATE
		skl.misc.instakillBoss = true
	end)
end