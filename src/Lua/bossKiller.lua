--[[
	All of the boss-instakilling stuff is here.
]]

freeslot("sfx_sklgh") --Skeleton laugh (From Sound Ideas Series 4000) [https://soundeffects.fandom.com/wiki/Sound_Ideas,_CARTOON,_LAUGHTER_-_SARCASTIC_LAUGH,_HUMAN_01]
sfxinfo[sfx_sklgh].caption = "Ha ha ha ha ha haa haaa haaaaa!"

--The main code.
addHook("PreThinkFrame", function()
	--Freeze all mobjs when the sequence starts.
	for mobj in mobjs.iterate() do
		if skl.objectExists(mobj.player) then
			if skl.misc.startedBossKiller then
				mobj.player.pflags = $|PF_FULLSTASIS

				if mobj.player.oldmom == nil then
					mobj.player.oldmom = {x=mobj.momx, y=mobj.momy, z=mobj.momz}
				end
				mobj.momx = 0
				mobj.momy = 0
				mobj.momz = 0
			end
			if skl.misc.finishedBossKiller then
				if mobj.player.oldmom ~= nil then
					mobj.momx = mobj.player.oldmom.x
					mobj.momy = mobj.player.oldmom.y
					mobj.momz = mobj.player.oldmom.z
					mobj.player.oldmom = nil
				end
			end
			if skl.misc.triggerInvert then
				P_FlashPal(mobj.player, PAL_INVERT, skl.misc.laughLength)
				
				skl.misc.triggerInvert = false
			end
		else
			if skl.misc.startedBossKiller then
				if not(mobj.flags & MF_NOTHINK) and mobj.hadABrain == nil then
					mobj.hadABrain = true
					mobj.flags = $|MF_NOTHINK
				end
			else
				if mobj.hadABrain then
					mobj.hadABrain = nil
					mobj.flags = $ & ~MF_NOTHINK
				end
			end
		end
	end

	for _,boss in ipairs(skl.bosses) do
		if not(skl.objectExists(boss)) then continue end

		--Check for revived bosses.
		if boss.health ~= 0 and skl.misc.finishedBossKiller then
			skl.misc.startedBossKiller = false
			skl.misc.triggeredOnTic = -1
			skl.misc.finishedBossKiller = false
			skl.misc.triggerInvert = false
			skl.misc.instakillBoss = P_RandomChance(FU/10)
			skl.misc.chanceRolled = true
		end
	end

	if #skl.bosses > 0 and skl.misc.instakillBoss then
		if #skl.misc.skelPlayers == 0 then
			skl.misc.triggeredOnTic = -1
			skl.misc.instakillBoss = false
			return
		end

		if skl.misc.triggeredOnTic == -1 then skl.misc.triggeredOnTic = leveltime end

		if leveltime > skl.misc.triggeredOnTic+TICRATE then
			if not(skl.misc.startedBossKiller) and not(skl.misc.finishedBossKiller) then
				skl.misc.triggerInvert = true
				S_StartSound(nil, sfx_sklgh) --Play the laugh.
				skl.misc.startedBossKiller = true
			end

			if leveltime > skl.misc.triggeredOnTic+skl.misc.laughLength and skl.misc.startedBossKiller and not(skl.misc.finishedBossKiller) then
				for _,boss in ipairs(skl.bosses) do
					if not(skl.objectExists(boss)) then continue end

					--Set the nearest player to the boss' killer.
					local whodidit = skl.closestMobjFromList(boss, skl.misc.skelPlayers)
					P_KillMobj(boss, whodidit, whodidit, DMG_INSTAKILL)
				end
				for ply in players.iterate() do
					if not(skl.objectExists(ply)) then continue end
					local hadArmageddon = ply.powers[pw_shield] & SH_ARMAGEDDON

					P_BlackOw(ply) --Trigger screen wipe.

					if hadArmageddon then ply.powers[pw_shield] = $|SH_ARMAGEDDON end --Give the armageddon shield back to players who had it.
				end

				skl.misc.startedBossKiller = false
				skl.misc.finishedBossKiller = true
				skl.misc.triggeredOnTic = -1
			end
		end
	end
end)

--Track bosses.
addHook("MobjSpawn", function(mobj)
	if mobj.flags & MF_BOSS then
		table.insert(skl.bosses, mobj)

		--Another boss?! Kill it!
		if skl.misc.finishedBossKiller then
			skl.misc.startedBossKiller = false
			skl.misc.triggeredOnTic = -1
			skl.misc.finishedBossKiller = false
			skl.misc.triggerInvert = false
			skl.misc.instakillBoss = P_RandomChance(FU/10)
			skl.misc.chanceRolled = true
		end
	end
end)

--Wipe the bosses table.
addHook("MapChange", function()
	skl.bosses = {}
	skl.misc.chanceRolled = false
end)

--Reset/roll all variables.
addHook("MapLoad", function()
	skl.misc.skelPlayers = {}
	skl.misc.skelAlreadyExisted = false

	skl.misc.startedBossKiller = false
	skl.misc.triggeredOnTic = -1
	skl.misc.finishedBossKiller = false
	skl.misc.triggerInvert = false
	skl.misc.instakillBoss = P_RandomChance(FU/10)
	skl.misc.chanceRolled = true
end)

--Skeleton player tracker.
addHook("PreThinkFrame", function()
	for ply in players.iterate() do
		if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then continue end --Don't do anything if the player or it's mobj doesn't exist.
		if ply.skeleton == nil then return end --Can't do anything yet.

		local skel = ply.skeleton

		if ply.mo.skin == "skeleton" then
			if not(skl.tableContains(skl.misc.skelPlayers, ply.mo)) then
				table.insert(skl.misc.skelPlayers, ply.mo)
			end
		else
			if skl.tableContains(skl.misc.skelPlayers, ply.mo) then
				skl.tableRemove(skl.misc.skelPlayers, ply.mo)
			end
		end
	end

	--Re-roll the chance to kill a boss if there is a skeleton player now.
	--And no, constantly switching won't work.
	if #skl.misc.skelPlayers > 0 and skl.misc.chanceRolled and not(skl.misc.skelAlreadyExisted) then
		skl.misc.startedBossKiller = false
		skl.misc.triggeredOnTic = -1
		skl.misc.finishedBossKiller = false
		skl.misc.triggerInvert = false
		skl.misc.instakillBoss = P_RandomChance(FU/10)
		skl.misc.chanceRolled = true
		skl.misc.skelAlreadyExisted = true
	end
end)