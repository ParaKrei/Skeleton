--[[
	Extra compatibility stuff with other mods.
]]

freeslot("sfx_skexp") --Explosion (Combined sounds from CSGO and the laugh from above; ripped by Cooper) [https://sounds.spriters-resource.com/pc_computer/counterstrikeglobaloffensive/]
sfxinfo[sfx_skexp].singular = true
sfxinfo[sfx_skexp].caption = "KABOOM!"

freeslot("SPR2_SKRT") --Reaction
freeslot("SPR2_SKRI") --Reaction idle
freeslot("SPR2_SKTR") --Reaction transition
freeslot("SPR2_SKST") --Struggle
freeslot("SPR2_MSKR") --Reaction: Built-in Amy version
freeslot("SPR2_MSKI") --Reaction idle: Built-in Amy version
freeslot("SPR2_MSKS") --Struggle: Built-in Amy version
freeslot("S_ROSY_HUG_SKL")
states[S_ROSY_HUG_SKL] = {
	sprite = SPR_PLAY,
	frame = 0|SPR2_MSKS|FF_ANIMATE,
	var1 = 6-1,
	var2 = 4,
	tics = -1
}

--Vanilla--
--The hug animation handler.
local function HugAnimation(mobj, skin, hugVictim, isSuper)
	if isSuper == nil then isSuper = false end

	local skinTbl = {}
	if isSuper then skinTbl = skl.hug[skin].super else skinTbl = skl.hug[skin].normal end

	local state = hugVictim.skeleton.compat.hugs.huggerReactions.state+1
	if state > 0 then
		local sprite2 = skinTbl[state]

		if sprite2 ~= nil then
			if skinTbl[4] ~= nil
			and leveltime >= (hugVictim.skeleton.compat.hugs.huggerReactions.startTime+(TICRATE*2))-(skl.hug[skin].trans_duration*4)
			and leveltime < hugVictim.skeleton.compat.hugs.huggerReactions.startTime+(TICRATE*2) then
				if mobj.player == nil then mobj.state = S_ROSY_HUG_SKL end

				mobj.sprite2 = skinTbl[4]
						
				mobj.tics = -1
				mobj.frame = A|FF_ANIMATE
				mobj.anim_duration = 4
			else
				if mobj.sprite2 ~= sprite2 then
					if mobj.player == nil then mobj.state = S_ROSY_HUG_SKL end

					mobj.sprite2 = sprite2
							
					mobj.tics = -1
					mobj.frame = A|FF_ANIMATE
					mobj.anim_duration = 4
				end
			end
		end
	end
end

--Base Amy hug support.
addHook("MobjThinker", function(amy)
	if amy.state == S_ROSY_HUG or amy.state == S_ROSY_HUG_SKL then --She's hugging someone!
		if skl.objectExists(amy.target) and skl.objectExists(amy.target.player) then --She's got someone!
			local ply = amy.target.player

			if ply.mo.skin == "skeleton" then --YOU FOOLISH HEDGEHOG! YOU FELL RIGHT INTO MY TRAP! HE HE HE HA HA HA HA!
				ply.pflags = $|PF_FULLSTASIS

				if not ply.skeleton.compat.hugs.beingHugged and not skl.tableContains(ply.skeleton.compat.hugs.huggers, amy) then --Let the Skeleton know.
					ply.skeleton.compat.hugs.beingHugged = true
					ply.skeleton.compat.hugs.expTimer = leveltime
					ply.skeleton.compat.hugs.expIter = 1
					ply.skeleton.compat.hugs.resetTic = 0
					ply.skeleton.compat.hugs.huggerReactions.startTime = leveltime
				end

				if not skl.tableContains(ply.skeleton.compat.hugs.huggers, amy) then table.insert(ply.skeleton.compat.hugs.huggers, amy) end

				HugAnimation(amy, "_amy_npc", ply)
			end
		end
	end
end, MT_ROSY)

--EveryoneHugs--
--Reset hugging variables here, as PlayerSpawn doesn't properly clear it.
addHook("MapLoad", function()
	for ply in players.iterate() do
		if ply.skeleton == nil then continue end
		local skel = ply.skeleton

		skel.compat.hugs.beingHugged = false
		skel.compat.hugs.expTimer = leveltime
		skel.compat.hugs.expIter = 1
		skel.compat.hugs.resetTic = 0
		skel.compat.hugs.huggers = {}
		skel.compat.hugs.huggerReactions = {startTime=0, state=-1}
	end
end)

--Get the sprites and animation durations from a skin, and put it into a global net table.
addHook("MapLoad", function()
	for skin in skins.iterate do
		if skl["hug"][skin.name] ~= nil then continue end

		skl["hug"][skin.name] = {normal={},super={}}

		local checkTbl = {SPR2_SKRT,SPR2_SKRI,SPR2_SKTR,SPR2_SKST,SPR2_SKRT|FF_SPR2SUPER,SPR2_SKRI|FF_SPR2SUPER,SPR2_SKTR|FF_SPR2SUPER,SPR2_SKST|FF_SPR2SUPER}
		local sprTbl = {}
		for i,spr in ipairs(checkTbl) do
			sprTbl[spr] = skin.sprites[spr].numframes ~= 0
		end
		
		skl["hug"][skin.name].normal = {
			sprTbl[SPR2_SKRT] == true and SPR2_SKRT or nil,
			sprTbl[SPR2_SKRI] == true and SPR2_SKRI or nil,
			sprTbl[SPR2_SKST] == true and SPR2_SKST or nil,
			sprTbl[SPR2_SKTR] == true and SPR2_SKTR or nil
		}
		skl["hug"][skin.name].super = {
			sprTbl[SPR2_SKRT|FF_SPR2SUPER] == true and SPR2_SKRT|FF_SPR2SUPER or sprTbl[SPR2_SKRT] == true and SPR2_SKRT or nil,
			sprTbl[SPR2_SKRI|FF_SPR2SUPER] == true and SPR2_SKRI|FF_SPR2SUPER or sprTbl[SPR2_SKRI] == true and SPR2_SKRI or nil,
			sprTbl[SPR2_SKST|FF_SPR2SUPER] == true and SPR2_SKST|FF_SPR2SUPER or sprTbl[SPR2_SKST] == true and SPR2_SKST or nil,
			sprTbl[SPR2_SKTR|FF_SPR2SUPER] == true and SPR2_SKTR|FF_SPR2SUPER or sprTbl[SPR2_SKTR] == true and SPR2_SKTR or nil
		}
		skl["hug"][skin.name].trans_duration = sprTbl[SPR2_SKTR] == true and skin.sprites[SPR2_SKTR].numframes or nil
	end

	--Table for the Amy NPC.
	skl["hug"]._amy_npc = {
		normal = {SPR2_MSKR,SPR2_MSKI,SPR2_MSKS,nil},
		super = {SPR2_MSKR,SPR2_MSKI,SPR2_MSKS,nil},
		trans_duration = nil
	}
end)

--Player hug support.
addHook("PlayerThink", function(ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.playerstate ~= PST_LIVE then return end --Player's dead.
	
	if skl.objectExists(ply.hugging) and skl.objectExists(ply.hugging.mo) then --You've doomed yourself, and there's no escape now.
		if ply.hugging.mo.skin == "skeleton" then
			ply.pflags = $|PF_FULLSTASIS
		end

		ply.releasedelay = 2 --Stop the hugger from escaping, while also ensuring that they properly detach on a new map load.

		if ply.mo.skin == "amy" and CV_FindVar("sklhug_amystyle").value then
			HugAnimation(ply.mo, "_amy_npc", ply.hugging, ply.powers[pw_super] > 0)
		else
			HugAnimation(ply.mo, ply.mo.skin, ply.hugging, ply.powers[pw_super] > 0)
		end
	end

	if ply.hugged and (ply.mo.skin == "skeleton" and ply.skeleton ~= nil) then --YOU FOOL! YOU FELL RIGHT INTO MY TRAP! HE HE HE HA HA HA HA!
		ply.pflags = $|PF_FULLSTASIS

		if not ply.skeleton.compat.hugs.beingHugged and not skl.tableContains(ply.skeleton.compat.hugs.huggers, ply.hugged.mo) then --Let the Skeleton know.
			ply.skeleton.compat.hugs.beingHugged = true
			ply.skeleton.compat.hugs.expTimer = leveltime
			ply.skeleton.compat.hugs.expIter = 1
			ply.skeleton.compat.hugs.resetTic = 0
			ply.skeleton.compat.hugs.huggerReactions.startTime = leveltime
		end

		if not skl.tableContains(ply.skeleton.compat.hugs.huggers, ply.hugged.mo) then table.insert(ply.skeleton.compat.hugs.huggers, ply.hugged.mo) end
	end
end)

--The rest of the hug stuff.
addHook("PlayerThink", function(ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
	if ply.skeleton == nil then return end --Can't do anything yet.
	if ply.playerstate ~= PST_LIVE then return end --Player's dead.

	local skel = ply.skeleton
	local hugs = skel.compat.hugs

	if hugs.beingHugged then --Start the countdown.
		if #skl.c4Tbl == hugs.expIter then
			if leveltime < hugs.expTimer+36+1 then
				ply.mo.translation = "RedFade"..tostring(leveltime-hugs.expTimer)
				ply.mo.colorized = true
				ply.mo.renderflags = $|RF_FULLBRIGHT
			end

			if leveltime == hugs.expTimer+TICRATE+26 then
				ply.mo.translation = "AllWhite"
				ply.mo.colorized = true
				ply.mo.renderflags = $|RF_FULLBRIGHT
				
				local explosion = P_SpawnMobjFromMobj(ply.mo, 0, 0, 0, MT_SKELEXPLODE)
				explosion.scale = $*3
				explosion.destscale = $*2
				explosion.anim_duration = 1

				local dust = P_SpawnMobjFromMobj(ply.mo, 0, 0, 0, MT_TNTDUST)
				dust.scale = $*2
				dust.destscale = $*4

				P_StartQuake(9*FU, TICRATE/6, {x=ply.mo.x, y=ply.mo.y, z=ply.mo.z}, 512*FU)
				
				for i,mobj in pairs(hugs.huggers) do
					if mobj.type == MT_ROSY then --Make Amy hurt.
						A_DoNPCPain(mobj)
						mobj.state = S_ROSY_PAIN
						S_StartSound(mobj, sfx_cdpcm7)
						mobj.cvmem = -100*TICRATE
					elseif mobj.type == MT_PLAYER then --Make players hurt.
						mobj.player.hugging = nil
						P_DoPlayerPain(mobj.player, ply.mo, ply.mo)
					else --Uh... make whatever this thing is hurt.
						P_DamageMobj(mobj, ply.mo, ply.mo)
					end
				end
				skl.P_BlastAway(ply.mo)

				for i=1,15 do
					local gib = P_SpawnMobjFromMobj(ply.mo, 0, 0, 0, MT_SKELGIB)
					gib.color = ply.mo.color
					P_InstaThrust(gib, FixedAngle(P_SignedRandom()*FU), 25*FU)
					gib.momz = 25*FU
					gib.fuse = 6*TICRATE
					gib.spinamt = FixedAngle(P_SignedRandom()*FU)
				end

				hugs.huggers = {}
				ply.hugged = nil
				hugs.huggerReactions.state = -1
				hugs.huggerReactions.startTime = 0
			end
			
			if leveltime > hugs.expTimer+TICRATE+26 then
				ply.mo.translation = nil
				ply.mo.colorized = false
				ply.mo.renderflags = $ & ~RF_FULLBRIGHT

				hugs.beingHugged = false
			end

			if leveltime == hugs.expTimer+1 then
				ply.mo.translation = nil
				ply.mo.colorized = false
				ply.mo.renderflags = $ & ~RF_FULLBRIGHT
				S_StartSound(ply.mo, sfx_skexp)
			end
		elseif leveltime == hugs.expTimer+skl.c4Tbl[hugs.expIter] then
			hugs.resetTic = (hugs.expTimer+skl.c4Tbl[hugs.expIter])+1
			hugs.expIter = $+1
			hugs.expTimer = leveltime
			
			S_StartSound(ply.mo, sfx_s3k89)
			ply.mo.translation = "AllWhite"
			ply.mo.colorized = true
			ply.mo.renderflags = $|RF_FULLBRIGHT
		elseif leveltime == hugs.resetTic then
			ply.mo.translation = nil
			ply.mo.colorized = false
			ply.mo.renderflags = $ & ~RF_FULLBRIGHT
		end

		if leveltime == hugs.huggerReactions.startTime+(TICRATE*2) then
			hugs.huggerReactions.state = 2
		elseif leveltime == hugs.huggerReactions.startTime+TICRATE+17 then
			hugs.huggerReactions.state = 1
		elseif leveltime == hugs.huggerReactions.startTime+TICRATE then
			hugs.huggerReactions.state = 0
		end
	end
end)

--2011x--
if not(rawget(_G, "MT_SONICEXE")) then freeslot("MT_SONICEXE") end --I need the MOBJ type, so I'll attempt to use the method 2011x uses.
if not(rawget(_G, "sfx_xscrea")) then freeslot("sfx_xscrea") end --I need this sound too.
if not(rawget(_G, "sfx_xkill")) then freeslot("sfx_xkill") end --I need this sound too.
if not(rawget(_G, "sfx_xdeath")) then freeslot("sfx_xdeath") end --I need this sound too.
if not(rawget(_G, "S_EXETAUNT")) then freeslot("S_EXETAUNT") end --I need this state too.
if not(rawget(_G, "S_EXEGLOAT")) then freeslot("S_EXEGLOAT") end --I need this state too.
if not(rawget(_G, "EXE_SpawnBlood")) then --I need this function, so I'll free up a slot for it and put in a placeholder.
	rawset(_G, "EXE_SpawnBlood", function()
		print("ERROR: EXE_SpawnBlood isn't defined!")
		print("If you see this, report this to ParaKrei immediately!")
	end)
end

--Reset X-related variables here, as PlayerSpawn doesn't properly clear it.
addHook("MapLoad", function()
	for ply in players.iterate() do
		if ply.skeleton == nil then continue end
		local skel = ply.skeleton

		--Player's table
		if skel.compat.X == nil then skel.compat.X = {} end

		skel.compat.X.beingGrabbed = false
		skel.compat.X.expTimer = leveltime
		skel.compat.X.expIter = 1
		skel.compat.X.resetTic = 0
		skel.compat.X.victim = nil
	end

	--Global table
	if skl.compat.X == nil then skl.compat.X = {} end
	skl.compat.X.deathCount = 0

	--Since MobjCollide is too slow to do any changes, I have to directly modify EXE_WouldDie do get the old functionality back.
	--This method should also be more consistant and keep working every update.
	--I don't really like having to modify a function like this, but I didn't have much of a choice.
	local func_super = rawget(_G, "EXE_WouldDie")
	rawset(_G, "EXE_WouldDie", function(target)
		if target.skin == "skeleton" and exerage or exe_ragetime then
			return P_RandomChance(FU/100) --X can randomly decide to grab you.
		end

		return func_super(target)
	end)
end)

--Blow up X if he grabs the Skeleton.
addHook("PlayerThink", function(ply)
	if exe_active == nil and activeexe == nil then return end --Can't do anything if 2011x doesn't exist!
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
	if ply.skeleton == nil then return end --Can't do anything yet.

	--Setup variables for easy access.
	local skel = ply.skeleton
	local X = exe_active or activeexe

	if X ~= 0 and skl.objectExists(X) then
		if X.target == ply.mo and X.gotcha then
			if not ply.skeleton.compat.X.beingGrabbed then --Let the Skeleton know.
				ply.skeleton.compat.X.beingGrabbed = true
				ply.skeleton.compat.X.expTimer = leveltime
				ply.skeleton.compat.X.expIter = 1
				ply.skeleton.compat.X.victim = X
			end
		end
	end
end)

--The rest of the X-related stuff.
addHook("PlayerThink", function(ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
	if ply.skeleton == nil then return end --Can't do anything yet.
	if ply.playerstate ~= PST_LIVE then return end --Player's dead.
	
	local skel = ply.skeleton
	if skel.compat.X == nil then skel.compat.X = {} end
	local X = skel.compat.X

	if X.beingGrabbed then --Start the explosion.
		if leveltime < X.expTimer+36 then
			ply.mo.translation = "RedFade"..tostring(leveltime-(X.expTimer-1))
			ply.mo.colorized = true
			ply.mo.renderflags = $|RF_FULLBRIGHT
		end

		if leveltime == X.expTimer+TICRATE+26 then
			ply.mo.translation = "AllWhite"
			ply.mo.colorized = true
			ply.mo.renderflags = $|RF_FULLBRIGHT
			
			local explosion = P_SpawnMobjFromMobj(ply.mo, 0, 0, 0, MT_SKELEXPLODE)
			explosion.scale = $*3
			explosion.destscale = $*2
			explosion.anim_duration = 1

			local dust = P_SpawnMobjFromMobj(ply.mo, 0, 0, 0, MT_TNTDUST)
			dust.scale = $*2
			dust.destscale = $*4

			P_StartQuake(9*FU, TICRATE/6, {x=ply.mo.x, y=ply.mo.y, z=ply.mo.z}, 512*FU)
			
			--Just delete X, then start the stuff to spawn him again.
			for i=1,10 do
				if i % 2 == 0 then
					EXE_SpawnBlood(X.victim, -2*FU)
				else
					EXE_SpawnBlood(X.victim, 2*FU)
				end
			end
			P_RemoveMobj(X.victim)
			X.victim = nil

			--Death sound for X here.
			S_StartSound(nil, sfx_xscrea)

			--Set the timer to 10 seconds.
			exe_timer = 10*TICRATE
			--Reset the mintimer.
			exe_mintimer = 0
			--Reset all rage stuff.
			exe_ragetime = 0
			exe_ragedone = false
			exe_blackout = false
			--Reset any tunneling.
			exe_forcetarget = -1

			--Track the amount of times X has blown up.
			if skl.compat.X.deathCount >= 3 then --X is quite pissed now; so start rage mode!
				exe_timer = 1 --Spawn X immediately
				exe_forcetarget = ply.mo --Tunnel the Skeleton player
				exe_ragetime = -1 --Rage will start next tic
				exe_ragedone = true

				skl.compat.X.deathCount = 0 --Reset the tracker
			else
				skl.compat.X.deathCount = $+1 --Increment tracker
			end
			
			--Restore the music, as X takes the music down with him.
			P_RestoreMusic(consoleplayer)

			skl.P_BlastAway(ply.mo)

			for i=1,15 do
				local gib = P_SpawnMobjFromMobj(ply.mo, 0, 0, 0, MT_SKELGIB)
				gib.color = ply.mo.color
				P_InstaThrust(gib, FixedAngle(P_SignedRandom()*FU), 25*FU)
				gib.momz = 25*FU
				gib.fuse = 6*TICRATE
				gib.spinamt = FixedAngle(P_SignedRandom()*FU)
			end
		end
		
		if leveltime > X.expTimer+TICRATE+26 then
			ply.mo.translation = nil
			ply.mo.colorized = false
			ply.mo.renderflags = $ & ~RF_FULLBRIGHT

			X.beingGrabbed = false
		end

		if leveltime == X.expTimer+1 then
			ply.mo.translation = nil
			ply.mo.colorized = false
			ply.mo.renderflags = $ & ~RF_FULLBRIGHT
			S_StartSound(ply.mo, sfx_skexp)
		end
	end
end)

--Have X taunt the Skeleton in rage mode.
addHook("PlayerThink", function(ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
	if ply.skeleton == nil then return end --Can't do anything yet.

	--Setup variables for easy access.
	local skel = ply.skeleton
	local X = exe_active or activeexe

	if X == nil then return end --Can't do anything if 2011x doesn't exist!

	if X ~= nil and X.target ~= ply.mo then return end --None of this will work if the player isn't X's target.

	if (exerage or exe_ragetime) then
		--If X rolled the grab, let him blow up WITHOUT breaking the Skeleton.
		if X.gotcha then
			ply.pflags = $|PF_GODMODE
		end
		--Stop the sounds that play upon X murdering someone.
		if X.state == S_EXEGLOAT then
			S_StopSoundByID(ply.mo, sfx_xkill)
			S_StopSoundByID(nil, sfx_xdeath)

			ply.pflags = $ & ~PF_GODMODE --Remove god mode.
		end

		if ply.mo.state == S_SKEL_BREAK then
			if X.state ~= S_EXETAUNT then
				exe_hallucination = true
				X.state = S_EXETAUNT
			end
		elseif exe_hallucination then
			exe_hallucination = false
		end
	end
end)

--Hellfire Health--
addHook("PreThinkFrame", function()
	for ply in players.iterate() do
		if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
		if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
		if ply.hellfireHealth == nil then return end --Can't do anything if Hellfire Health isn't found.

		local skel = ply.skeleton
		local hellfire = ply.hellfireHealth

		if skel.compat.gotHit then
			if hellfire.health > 1 and not(hellfire.notAllowed) and not(hellfire.options.disabled) then
				if (ply.rings == 0 and ply.powers[pw_shield] == SH_NONE) then
					local oldFlashing = ply.powers[pw_flashing] --Store the current flashing tics.
					ply.powers[pw_flashing] = 0 --Set flashing to zero so directDmg runs immediately.
					hf.directDmg(ply, 1, {pain=false})
					ply.powers[pw_flashing] = oldFlashing --Restore the original flashing tics.
					skel.cueBreak = false
				end
			end
		end
	end
end, MT_PLAYER)

addHook("ShouldDamage", function(target, cause, src, dmg, dmgType)
	if not(skl.objectExists(target)) or not(skl.objectExists(target.player)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if target.skin ~= "skeleton" then return end --ONLY for the skeleton.
	if target.player.hellfireHealth == nil then return end --Can't do anything if Hellfire Health isn't found.

	local ply = target.player
	local skel = ply.skeleton
	local hellfire = ply.hellfireHealth

	if hellfire.health == 1 and skl.canPlayerBeHurt(ply)
	and not(hellfire.notAllowed) and not(hellfire.options.disabled) then
		skl.gotHit(ply)
		hf.directLoss(ply)
		P_DoPlayerPain(ply, cause, src)
		P_PlayRinglossSound(ply.mo)
		skel.cueBreak = true

		return false
	end
end, MT_PLAYER)

--Metroid Vanguard--
--Metroid stuff

--Little helper function to get a Metroid off of the player.
local function FuckOffMetroid(metroid, victim)
	--Give the Metroid some momentum to get away from the player.
	local momentum = {
		x=victim.momx,
		y=victim.momy
	}
	if victim.player.speed <= 22<<16 then
		momentum.x = P_ReturnThrustX(victim, victim.angle, 250*FU)
		momentum.y = P_ReturnThrustY(victim, victim.angle, 250*FU)
	end

	metroid.momx = momentum.x*-1
	metroid.momy = momentum.y*-1
	metroid.momz = 2<<16

	S_StartSound(metroid, sfx_mtrd2) --pain sound

	--Stun the Metroid.
	metroid.stuntroid = 30*2
	metroid.latchsuck = 0
	metroid.actiontroid = P_RandomRange(37, 65)

	P_SamFP(victim.player, PAL_RECYCLE, 3) --visual feedback

	metroid.latchtarget = nil --detach from the player

	--Move the Metroid somewhere else.
	for dir = 1,18
		if P_TryMove(metroid,
		metroid.x+FixedMul(-50<<16, cos(ANG20*dir)),
		metroid.y+FixedMul(-50<<16, sin(ANG20*dir)),
		false) then return end
	end
end

addHook("PlayerThink", function(ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.

	local skel = ply.skeleton

	if ply.mo.metroidsnack then --AAAAAAAAAAAAAAAAAA
		--Find the attacker
		if skel.metroid == nil or not(skl.objectExists(skel.metroid)) then
			for mobj in mobjs.iterate() do
				if mobj.latchtarget ~= nil then
					if mobj.latchtarget == ply.mo then
						skel.metroid = mobj
						break
					end
				end
			end
		end

		if skel.metroid == nil then return --Must be dead.
		else
			if ply.rings == 0 then --Only do stuff if the player has no rings.
				local survival = skel.metroid.latchsuck
				if survival ~= nil then
					if survival <= 5 then --Get off of me!
						FuckOffMetroid(skel.metroid, ply.mo)
						skel.metroid = nil
					end
				end
			end

			if ply.cmd.buttons & BT_CUSTOM1 then
				FuckOffMetroid(skel.metroid, ply.mo)
				skel.metroid = nil
			end
		end
	end
end)