--[[
	The main file.
]]

--Initalize the table.
addHook("PlayerSpawn", function(ply)
	if ply.spectator then return end --Don't try to do anything if the player is a spectator.

	if ply.skeleton == nil then
		ply.skeleton = {
			ogViewHeight = ply.viewheight,
			crouching = false,
			crouchWalking = false,
			-- lastTrackers = {
			-- 	lastPos = {}, --Yes, I'm saving the player's position in multiple different states.
			-- 	lastGroundedPos = {}, --Same as above, but grounded.
			-- 	lastAngle = {}, --Might as well do angles too.
			-- 	lastGroundedAngle = {}, --Same as above, but grounded.
			-- 	lastFlip = {}, --Saving gravity flipping as well.
			-- 	lastGroundedFlip = {}, --Same as above, but grounded.
			-- 	last2D = {}, --Saving 2D mode as well.
			-- 	lastGrounded2D = {}, --Same as above, but grounded.
			-- 	lastTickers = {0, 0}, --Sets the saving position in the tables above.
			-- },
			-- tickersMax = 5,
			-- stuck = false,
			-- stuckTimer = 0,
			-- timesTeleported = {0,0,0,0}, --Tracks how many times a stuck function was ran (last, last grounded, push, starpost/spawn).
			wasInZoomTube = false,
			gotCrushed = false,
			lastCrushed = 0, --Tracks what tic the player got crushed on.
			triedSnap = false, --Tracks if the player was already snapped to the floor.
			lastTicSinceSpring = 0,
			shieldObj = nil,
			lastSkin = "",
			onSpinWheel = false,
			lastSectorTag = -1,
			wjhTimer = 0,
			cueBreak = false,
			raise = {state=-1, lastFrame=0, lastTic=0}, ---1=empty, 0=dying, 1=dead, 2=reviving
			compat = {
				hugs = {beingHugged=false, expTimer=0, expIter=1, resetTic=0, huggers={}, huggerReactions={startTime=0, state=-1}}, --state: -1=no reaction, 0=realize, 1=transition?, 2=struggle
				gotHit = false,
				gotHitOnTic = 0,
			},
			taunts = {active=false, state=S_PLAY_STND, lastTic=0, lastFrame=0}
		}
	end
	local skel = ply.skeleton

	--Reset stuff.
	skel.crouching = false
	skel.crouchWalking = false

	--DEPRECATED; COULDN'T GET THIS TO WORK WITHOUT BREAKING SLOPES, IF YOU CAN, POWER TO YOU.--
	-- for i=0,skel.tickersMax do
	-- 	skel.lastTrackers.lastPos[i] = {x=0,y=0,z=0}
	-- 	skel.lastTrackers.lastGroundedPos[i] = {x=0,y=0,z=0}
	-- 	skel.lastTrackers.lastAngle[i] = 0
	-- 	skel.lastTrackers.lastGroundedAngle[i] = 0
	-- 	skel.lastTrackers.lastFlip[i] = 0
	-- 	skel.lastTrackers.lastGroundedFlip[i] = 0
	-- 	skel.lastTrackers.last2D[i] = 0
	-- 	skel.lastTrackers.lastGrounded2D[i] = 0
	-- end
	-- skel.stuck = false
	-- skel.stuckTimer = 0
	-- for i=1,4 do skel.timesTeleported[i] = 0 end

	skel.wasInZoomTube = false
	skel.gotCrushed = false
	skel.lastCrushed = leveltime
	skel.triedSnap = false
	skel.shieldObj = nil

	skel.onSpinWheel = false
	skel.lastSectorTag = -1

	skel.raise.state = -1
	skel.raise.lastFrame = 0
	skel.raise.lastTic = leveltime

	skel.taunts.active = false
	skel.taunts.state = S_PLAY_STND
	skel.taunts.lastTic = 0
	skel.taunts.lastFrame = 0

	skel.compat.gotHit = false
	skel.compat.gotHitOnTic = leveltime

	idTechSpawn(ply)
	if ply.mo.skin ~= "skeleton" then ply.thrustfactor = skins[ply.mo.skin].thrustfactor end
end)

local risingTypes = {190,191,192,193,194,195} --Flag 6 (Not Climbable) is the spindash charge.
addHook("MapLoad", function()
	skl.linedefs.spinRiser = {}
	
	--Finds all risers that require a spindash.
	for line in lines.iterate do
		if skl.isStringInTbl(line.special, risingTypes) then
			if line.flags & ML_NOCLIMB then
				table.insert(skl.linedefs.spinRiser, line)
			end
		end
	end
end)

--Just copied straight from SRB2's code.
local function hoverAbility(player)
	if not(player.pflags & PF_THOKKED) or player.charflags & SF_MULTIABILITY then
		if player.charflags & SF_DASHMODE and player.dashmode >= 3*TICRATE then
			player.mo.state = S_PLAY_DASH
		elseif player.speed >= FixedMul(player.runspeed, player.mo.scale) then
			player.mo.state = S_PLAY_FLOAT_RUN
		else
			player.mo.state = S_PLAY_FLOAT
		end

		player.pflags = $ | PF_THOKKED
		player.pflags = $ & ~(PF_JUMPED|PF_NOJUMPDAMAGE|PF_SPINNING)

		local potentialmomz = player.speed < 10*player.mo.scale and (player.speed - 10*player.mo.scale)/5 or 0
		if P_MobjFlip(player.mo)*player.mo.momz < potentialmomz then
			player.mo.momz = P_MobjFlip(player.mo)*potentialmomz
		end
	end
end

local function fixZ(ply, down)
	if down == nil then down = false end

	local newZ = ply.mo.z+(FixedDiv(P_GetPlayerHeight(ply), 2*FU)*P_MobjFlip(ply.mo))
	if down then newZ = ply.mo.z-(FixedDiv(P_GetPlayerHeight(ply), 2*FU)*P_MobjFlip(ply.mo)) end
	local floorZ = P_FloorzAtPos(ply.mo.x, ply.mo.y, ply.mo.z, ply.mo.height)
	local ceilZ = P_CeilingzAtPos(ply.mo.x, ply.mo.y, ply.mo.z, ply.mo.height)
	newZ = skl.clamp($, floorZ, ceilZ)

	ply.mo.z = newZ
end

--The splash spawner recreated and adjusted from p_mobj.c (https://git.do.srb2.org/STJr/SRB2/-/blob/SRB2_release_2.2.15/src/p_mobj.c#L3213)!
local function spawnSplash(ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.playerstate ~= PST_LIVE then return end --Player's dead.
	if (not(ply.mo.eflags & MFE_TOUCHWATER) and not(ply.mo.eflags & MFE_TOUCHLAVA)) or ply.mo.eflags & MFE_UNDERWATER then return end
	
	local mobj = ply.mo
	local splish = nil
	local splishtype = mobj.eflags & MFE_TOUCHLAVA and MT_LAVASPLISH or MT_SPLISH
	local pos = {x=mobj.x, y=mobj.y, z=mobj.eflags & MFE_VERTICALFLIP and (mobj.waterbottom-FixedMul(mobjinfo[splishtype].height, mobj.scale)) or mobj.watertop}
	
	if mobj.eflags & MFE_JUSTHITFLOOR then
		splish = P_SpawnMobj(pos.x, pos.y, pos.z, splishtype)

		if mobj.eflags & MFE_VERTICALFLIP then
			if skl.objectExists(splish) then
				splish.flags2 = $|MF2_OBJECTFLIP
				splish.eflags = $|MFE_VERTICALFLIP
			end
		end
		
		if skl.objectExists(splish) then
			P_SetScale(splish, mobj.scale, true)
		end

		if splishtype == MT_LAVASPLISH then
			S_StartSound(mobj, sfx_splash)
		else
			S_StartSound(mobj, sfx_wslap)
		end
	end

	return splish
end

--Hack to stop odd behavior with springs and goo.
addHook("MobjMoveCollide", function(me, mobj)
	if me.eflags & MFE_SPRUNG and me.eflags & MFE_GOOWATER then
		--The springs look like they need a little help, so let's give it some more power!
		local power = -(P_GetPlayerSpinHeight(me.player))
		if mobj.eflags & MFE_VERTICALFLIP then power = $*-1 end --Flip the power if the spring object is upside-down!

		P_SetObjectMomZ(me, power, true)
	end
end, MT_PLAYER)

--The main player thinker.
addHook("PlayerThink", function(ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
	if ply.skeleton == nil then return end --Can't do anything yet.
	if ply.playerstate ~= PST_LIVE then return end --Player's dead.

	local skel = ply.skeleton

	--Disable drowning in ALL scenarios.
	ply.powers[pw_underwater] = -1
	ply.powers[pw_spacetime] = -1

	--Water jump height timer.
	if skel.wjhTimer > 0 then skel.wjhTimer = $-1 end
	if skel.wjhTimer == 0 then ply.jumpfactor = skins[ply.mo.skin].jumpfactor end

	--Murder mode.
	ply.powers[pw_strong] = STR_ATTACK|STR_SPIKE
	
	--DEPRECATED; COULDN'T GET THIS TO WORK WITHOUT BREAKING SLOPES, IF YOU CAN, POWER TO YOU.--
	-- if skel.stuckTimer > 0 then skel.stuckTimer = $-1 end

	-- if ply.pflags & PF_SPINNING and skel.stuckTimer == 0 then
	-- 	ply.pflags = $ & ~PF_SPINNING
	-- 	ply.mo.state = S_PLAY_STND
	-- end

	-- if skel.stuckTimer == 0 then for i=1,4 do skel.timesTeleported[i] = 0 end end --Reset timesTeleported.

	--Initalize the break animation.
	if skel.cueBreak then
		if ply.mo.recoveryWait ~= nil then ply.mo.recoveryWait = -1 end --Stop MMT's recovery jump.

		if P_IsObjectOnGround(ply.mo) then
			S_StartSound(ply.mo, sfx_skfla)
			ply.mo.state = S_SKEL_BREAK
			skel.cueBreak = false
		end
	end

	local check = ply.mo.state ~= S_SKEL_BREAK and not ply.skeleton.compat.hugs.beingHugged and not ply.skeleton.taunts.active and not P_PlayerInPain(ply)
	local checkPainless = ply.mo.state ~= S_SKEL_BREAK and not ply.skeleton.compat.hugs.beingHugged and not ply.skeleton.taunts.active

	if ply.cmd.buttons & BT_SPIN and check then
		hoverAbility(ply) --CA_FLOAT re-implemented in Lua.

		--Activate any spin wheels the playe is on.
		if skel.onSpinWheel then ply.pflags = $|PF_STARTDASH end
	end
	
	--Stuff for spindash-activated risers.
	if ply.mo.subsector.sector.tag ~= skel.lastSectorTag then --Only run when the player is in a new sector with a new tag.
		if skl.linedefs.spinRiser ~= nil and #skl.linedefs.spinRiser > 0 then
			for i = 1,#skl.linedefs.spinRiser do
				local line = skl.linedefs.spinRiser[i]

				if line.tag == ply.mo.subsector.sector.tag then
					skel.onSpinWheel = true
					break
				end
				
				skel.onSpinWheel = false
			end
		end

		skel.lastSectorTag = ply.mo.subsector.sector.tag
	end

	--Auto-bhop!
	if not(ply.pflags & PF_JUMPSTASIS) and not(ply.pflags & PF_JUMPED) and ply.lastbuttons & BT_JUMP and P_IsObjectOnGround(ply.mo)
	and ply.playerstate == PST_LIVE and ply.exiting == 0 and check then
		P_DoJump(ply)
	end

	if ply.cmd.buttons & BT_CUSTOM1 and check then
		--Minecart Destroyer 9000!
		if ply.powers[pw_carry] == CR_MINECART then
			if skl.objectExists(ply.mo.tracer) and ply.mo.tracer.type == MT_MINECART then
				ply.powers[pw_carry] = CR_NONE

				ply.mo.momx = ply.mo.tracer.momx
				ply.mo.momy = ply.mo.tracer.momy

				ply.mo.momz = (12*ply.mo.scale)*P_MobjFlip(ply.mo)
				ply.mo.state = S_PLAY_ROLL
				ply.mo.tracer.target = nil
			end
		end

		--Break the floor beneath you.
		skl.P_CrumbleFOFBelowMobj(ply.mo)
	end

	--Source Engine-esque crouch-jump implementation (this was not taken from Gordon Freeman, as he wasn't public when this code was created for a different project).
	--I don't even know if Gordon HAS this yet. [message written on 2/10/2026]
	if ply.powers[pw_carry] == CR_ZOOMTUBE then
		ply.mo.spritexscale = 2*FU
		ply.mo.spriteyscale = FU/2
		if skl.objectExists(skel.shieldObj) then
			skel.shieldObj.spriteyscale = FU/2
			skel.shieldObj.spriteyoffset = skel.shieldObj.oldspriteyoffset+FixedDiv(47*FU, 2*FU)
			
			if skl.objectExists(skel.shieldObj.tracer) then
				skel.shieldObj.tracer.spriteyscale = FU/2
				skel.shieldObj.tracer.spriteyoffset = skel.shieldObj.tracer.oldspriteyoffset+FixedDiv(47*FU, 2*FU)
			end
		end
		ply.viewheight = FixedDiv(ply.skeleton.ogViewHeight, 2*FU)
	else
		if skel.wasInZoomTube then
			ply.viewheight = ply.skeleton.ogViewHeight
			ply.mo.spritexscale = FU
			ply.mo.spriteyscale = FU
			if skl.objectExists(skel.shieldObj) then
				skel.shieldObj.spriteyscale = FU
				skel.shieldObj.spriteyoffset = skel.shieldObj.oldspriteyoffset

				if skl.objectExists(skel.shieldObj.tracer) then
					skel.shieldObj.tracer.spriteyscale = FU
					skel.shieldObj.tracer.spriteyoffset = skel.shieldObj.tracer.oldspriteyoffset
				end
			end
		end

		local heightCheck = (ply.mo.ceilingz - ply.mo.floorz) < P_GetPlayerHeight(ply)

		if checkPainless then
			if ply.cmd.buttons & BT_SPIN or heightCheck then
				skel.crouching = true
				ply.mo.spritexscale = 2*FU
				ply.mo.spriteyscale = FU/2
				if skl.objectExists(skel.shieldObj) then
					skel.shieldObj.spriteyscale = FU/2
					skel.shieldObj.spriteyoffset = skel.shieldObj.oldspriteyoffset+FixedDiv(47*FU, 2*FU)
					
					if skl.objectExists(skel.shieldObj.tracer) then
						skel.shieldObj.tracer.spriteyscale = FU/2
						skel.shieldObj.tracer.spriteyoffset = skel.shieldObj.tracer.oldspriteyoffset+FixedDiv(47*FU, 2*FU)
					end
				end

				if P_IsObjectOnGround(ply.mo) then
					if ply.mo.momx == 0 and ply.mo.momy == 0 then skel.crouchWalking = true end
					if (ply.mo.momx > 0 or ply.mo.momy > 0) and not(skel.crouchWalking) then
						ply.pflags = $|PF_STASIS
						P_SpawnSkidDust(ply, ply.mo.radius, true)
					end

					if skel.crouchWalking then
						ply.mo.momx = skl.clamp($, -FU*4, FU*4)
						ply.mo.momy = skl.clamp($, -FU*4, FU*4)
					end
				else
					if not(ply.lastbuttons & BT_SPIN) then
						fixZ(ply)
					end
				end

				ply.viewheight = FixedDiv(ply.skeleton.ogViewHeight, 2*FU)
			else
				if ply.lastbuttons & BT_SPIN or (not heightCheck and skel.crouching) then
					skel.crouching = false
					skel.crouchWalking = false
					fixZ(ply, true)

					ply.viewheight = ply.skeleton.ogViewHeight
					ply.mo.spritexscale = FU
					ply.mo.spriteyscale = FU
					if skl.objectExists(skel.shieldObj) then
						skel.shieldObj.spriteyscale = FU
						skel.shieldObj.spriteyoffset = skel.shieldObj.oldspriteyoffset

						if skl.objectExists(skel.shieldObj.tracer) then
							skel.shieldObj.tracer.spriteyscale = FU
							skel.shieldObj.tracer.spriteyoffset = skel.shieldObj.tracer.oldspriteyoffset
						end
					end
				end
			end
		else
			if skel.crouching and not heightCheck then
				skel.crouching = false
				skel.crouchWalking = false
				if P_IsObjectOnGround(ply.mo) then fixZ(ply, true) end

				ply.viewheight = ply.skeleton.ogViewHeight
				ply.mo.spritexscale = FU
				ply.mo.spriteyscale = FU
				if skl.objectExists(skel.shieldObj) then
					skel.shieldObj.spriteyscale = FU
					skel.shieldObj.spriteyoffset = skel.shieldObj.oldspriteyoffset

					if skl.objectExists(skel.shieldObj.tracer) then
						skel.shieldObj.tracer.spriteyscale = FU
						skel.shieldObj.tracer.spriteyoffset = skel.shieldObj.tracer.oldspriteyoffset
					end
				end
			end
		end
	end

	idTechThinker(ply) --Quake physics; must be at bottom.
end)

--"Death" animation stuff.
addHook("PreThinkFrame", function()
	for ply in players.iterate() do
		if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then continue end --Don't do anything if the player or it's mobj doesn't exist.
		if ply.skeleton == nil then continue end --Can't do anything yet.

		local skel = ply.skeleton

		if ply.mo.state == S_SKEL_BREAK then
			skl.switch(skel.raise.state)
				.case(-1, function()
					ply.powers[pw_nocontrol] = 64+TICRATE+64
					skel.raise.state = 0
					skel.raise.lastFrame = 0
					skel.raise.lastTic = leveltime
					ply.powers[pw_flashing] = 0
				end)
				.case(0, function()
					if leveltime > skel.raise.lastTic then
						skel.raise.lastFrame = skl.clamp($+1, 0, 63)
						skel.raise.lastTic = leveltime
					end

					ply.mo.frame = skel.raise.lastFrame

					if ply.mo.frame == 63 then skel.raise.state = 1 end
				end)
				.case(1, function()
					if leveltime >= skel.raise.lastTic+TICRATE then
						skel.raise.state = 2
					end
				end)
				.case(2, function()
					if skel.raise.lastFrame == 63 then
						S_StartSound(ply.mo, sfx_skrfm) --Reformers! More than meets the eye!
					end

					if leveltime > skel.raise.lastTic then
						skel.raise.lastFrame = $-1
						skel.raise.lastTic = leveltime
					end

					ply.mo.frame = skel.raise.lastFrame

					if ply.mo.frame == 0 then
						skel.raise.state = -1
						ply.mo.state = S_PLAY_STND
						ply.powers[pw_flashing] = flashingtics-1
					end
				end)
			.process()
		end

		if skel.raise.state > -1 and ply.mo.state ~= S_SKEL_BREAK then
			ply.mo.state = S_SKEL_BREAK
		end
	end
end)

--Air bubble code.
addHook("TouchSpecial", function(mobj, target)
	local ply = target.player
	if not(skl.objectExists(target)) or not(skl.objectExists(ply)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if target.skin ~= "skeleton" then return end --ONLY for the skeleton.
	if ply.skeleton == nil then return end --Can't do anything yet.
	if ply.playerstate ~= PST_LIVE then return end --Player's dead.
	if mobj.state ~= S_EXTRALARGEBUBBLE then return end --Can't do anything if the bubble's still spawning.

	if ply.skeleton.wjhTimer == 0 then ply.jumpfactor = skins[ply.mo.skin].jumpfactor*2 end
	ply.skeleton.wjhTimer = 11*TICRATE+1
end, MT_EXTRALARGEBUBBLE)

--Splash systems; misc.
addHook("PostThinkFrame", function()
	for ply in players.iterate() do
		if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then continue end --Don't do anything if the player or it's mobj doesn't exist.
		if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
		if ply.skeleton == nil then continue end --Can't do anything yet.

		spawnSplash(ply)

		if ply.skeleton.compat.gotHit and leveltime > ply.skeleton.compat.gotHitOnTic+1 then
			ply.skeleton.compat.gotHit = false
		end
	end
end)

local function shieldThinker(mobj)
	if not(mobj.flags2 & MF2_SHIELD) then return false end

	if (skl.objectExists(mobj.target) and skl.objectExists(mobj.target.player))
	and (mobj.target.player.skeleton ~= nil and mobj.target.player.mo.skin == "skeleton")
	and not(skl.objectExists(mobj.target.player.skeleton.shieldObj)) then
		mobj.oldspriteyoffset = mobj.spriteyoffset
		if skl.objectExists(mobj.tracer) then
			mobj.tracer.oldspriteyoffset = mobj.tracer.spriteyoffset
		end

		mobj.target.player.skeleton.shieldObj = mobj
		return false
	end
end

local orbs = {
	MT_PITY_ORB,
	MT_WHIRLWIND_ORB,
	MT_ARMAGEDDON_ORB,
	MT_ATTRACT_ORB,
	MT_ELEMENTAL_ORB,
	MT_FORCE_ORB,
	MT_FLAMEAURA_ORB,
	MT_BUBBLEWRAP_ORB,
	MT_THUNDERCOIN_ORB
}
for _,objType in pairs(orbs) do
	addHook("MobjThinker", shieldThinker, objType)
end

--Height setter for crouching.--
addHook("PlayerHeight", function(ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
	if ply.skeleton == nil then return end --Can't do anything yet.

	local skel = ply.skeleton

	if skel.crouching then
		return P_GetPlayerSpinHeight(ply)
	else
		return nil
	end
end)

--Spin gap stuff--
addHook("PlayerCanEnterSpinGaps", function(ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
	if ply.skeleton == nil then return end --Can't do anything yet.

	local skel = ply.skeleton

	if skel.crouching then
		return true
	else
		return nil
	end
end)

--The main damage code.--
addHook("ShouldDamage", function(target, cause, src, dmg, dmgType)
	if not(skl.objectExists(target)) or not(skl.objectExists(target.player)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if target.skin ~= "skeleton" then return end --ONLY for the skeleton.

	local ply = target.player
	local skel = ply.skeleton

	if cause == nil and src == nil and dmg == 1 and dmgType & skl.DMG_SKLDTH then --Unique suicide command handler.
		return true
	elseif dmgType == DMG_CRUSHED then --Track crusher damage for teleportation.
		if leveltime == skel.lastCrushed+1 then --Something has gone horribly wrong.
			if skel.triedSnap then --PANIC!
				P_DamageMobj(ply.mo, nil, nil, 1, skl.DMG_SKLDTH) --Just kill the player.
			else
				--Hopefully the player is just stuck in a floor.
				if P_MobjFlip(ply.mo) == -1 then
					ply.mo.z = P_CeilingzAtPos(ply.mo.x, ply.mo.y, ply.mo.z, ply.mo.height)
				else
					ply.mo.z = P_FloorzAtPos(ply.mo.x, ply.mo.y, ply.mo.z, ply.mo.height)
				end
				skel.triedSnap = true
			end
		else
			skel.lastCrushed = leveltime
			skel.gotCrushed = true
			skel.triedSnap = false
		end
	elseif not G_CoopGametype() and not G_CompetitionGametype() then --Use (most of) the original death code if in a PVP mode.
		if dmgType & DMG_DEATHPIT or dmgType & DMG_CRUSHED then
			return false
		else
			return nil
		end
	elseif (skl.objectExists(cause) and cause.flags & MF_SHOOTABLE) --The mobj will die soon anyways.
	or ply.mo.state == S_SKEL_BREAK
	or dmgType & DMG_DEATHMASK
	or dmgType == DMG_FIRE --Immunity to ALL fire attacks.
	or ((skl.objectExists(cause) and cause.type == MT_PLAYER) or (skl.objectExists(src) and src.type == MT_PLAYER) and G_CoopGametype()) then --NO friendly fire.
		return false
	elseif (ply.rings > 0 or ply.powers[pw_shield] ~= SH_NONE) and not G_IsSpecialStage() then
		skl.gotHit(ply)
		return nil
	else
		--Punish the player for getting hit with no rings; for balance.
		if skl.canPlayerBeHurt(ply) then
			P_DoPlayerPain(ply, cause, src)
			P_PlayRinglossSound(ply.mo)
			skel.cueBreak = true

			skl.gotHit(ply)
		end
		return false
	end
end, MT_PLAYER)

--Death animation handler.--
addHook("PlayerThink", function(ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.

	if ply.playerstate ~= PST_LIVE then
		if not P_IsObjectOnGround(ply.mo) then --You are NOT allowed to respawn until you touch the floor!
			ply.deadtimer = 1
			ply.mo.fuse = gameovertics

			--You are ONLY going down.
			if ply.mo.momz > 0 then ply.mo.momz = 0 end

			ply.mo.momz = $-FU
		else
			if ply.mo.sprite2 ~= SPR2_BREK then
				S_StartSound(ply.mo, sfx_skfla) --Play the sound.
				ply.mo.sprite2 = SPR2_BREK
				ply.mo.frame = 0
				if ply.mo.momz < -25*FU then
					P_Earthquake(ply.mo, ply.mo, ply.mo.momz-(15*FU))
					S_StartSound(ply.mo, sfx_kc40)
				end
			end
			
			ply.mo.flags = $ & ~MF_NOCLIP & ~MF_NOCLIPHEIGHT --Don't fall through the floor!
			ply.mo.momz = 0 --Don't move.

			--Pause on the last frame.
			if ply.mo.frame & ~FF_ANIMATE >= 63 then
				ply.mo.frame = 63
				ply.mo.anim_duration = 0
			else
				ply.mo.frame = $+1
			end
		end
	end
end)

--The main death handler.--
addHook("MobjDeath", function(target, cause, src, dmgType)
	if not(skl.objectExists(target)) or not(skl.objectExists(target.player)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if target.skin ~= "skeleton" then return end --ONLY for the skeleton.

	local ply = target.player

	if ply.powers[pw_carry] & CR_MINECART then
		ply.powers[pw_carry] = $ & ~CR_MINECART
	end

	ply.powers[pw_strong] = STR_NONE --Don't do ANY damage if you're dead!

	if cause == nil and src == nil and dmgType & skl.DMG_SKLDTH then --For the unique suicide command.
		return nil
	elseif not G_CoopGametype() and not G_CompetitionGametype() then --Use (most of) the original death code if in a PVP mode.
		if dmgType & DMG_DEATHPIT or dmgType & DMG_CRUSHED then
			--Become TRULY immortal.
			if ply.mo.health <= 0 then
				ply.mo.health = 1
				ply.deadtimer = 0
				ply.playerstate = PST_LIVE
				P_RestoreMusic(ply)
			end

			return true
		else
			return nil
		end
	else
		--Become TRULY immortal.
		if ply.mo.health <= 0 then
			ply.mo.health = 1
			ply.deadtimer = 0
			ply.playerstate = PST_LIVE
			P_RestoreMusic(ply)
		end

		return true
	end
end, MT_PLAYER)

--Handle skin switching.
addHook("PreThinkFrame", function()
	for ply in players.iterate() do
		if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then continue end --Don't do anything if the player or it's mobj doesn't exist.
		if ply.skeleton == nil then continue end --Can't do anything yet.

		local skel = ply.skeleton

		if skel.lastSkin == "skeleton" and ply.mo.skin ~= skel.lastSkin then
			P_ResetPlayer(ply)
		elseif ply.mo.skin == "skeleton" and ply.mo.skin ~= skel.lastSkin then
			idTechSpawn(ply)
		end
		skel.lastSkin = ply.mo.skin
	end
end)

--DEBUG--
-- hud.add(function(v, ply, cam)
-- 	local skel = ply.skeleton

-- 	skl.multilineDrawString(v, 16, 50, {
-- 		"current tic: "..tostring(leveltime),
-- 		"is crouchWalking: "..tostring(skel.crouchWalking),
-- 		"is on ground: "..tostring(P_IsObjectOnGround(ply.mo)),
-- 		"current starpost num: "..tostring(ply.starpostnum),
-- 		"current starpost pos: {x="..tostring(ply.starpostx*FU)..", y="..tostring(ply.starpostx*FU)..", z="..tostring(ply.starpostx*FU).."}",
-- 		"in zoom tube: "..tostring(ply.powers[pw_carry] & CR_ZOOMTUBE ~= 0),
-- 		"wjhTimer: "..tostring(skel.wjhTimer),
-- 		"current z: "..tostring(ply.mo.z),
-- 		"current floorz: "..tostring(ply.mo.floorz),
-- 		"z = floorz?: "..tostring(ply.mo.z == ply.mo.floorz),
-- 		"current ceilingz: "..tostring(ply.mo.ceilingz),
-- 		"ceilingz - floorz: "..tostring(ply.mo.ceilingz - ply.mo.floorz),
-- 		"default height: "..tostring(P_GetPlayerHeight(ply)),
-- 		"current height: "..tostring(ply.mo.height),
-- 		"height check: "..tostring((ply.mo.ceilingz - ply.mo.floorz) < P_GetPlayerHeight(ply)),
-- 		"current momz: "..tostring(ply.mo.momz),
-- 	}, V_SNAPTOLEFT, "thin")
-- end, "game")