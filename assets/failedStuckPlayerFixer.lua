--[[
	A failed attempt to constantly check and push the player out of walls, just in case the base game's didn't work.
	This consistently breaks slopes, so I made the decision to scrap it.
	If you can get this to work, go ahead! Also, please share it with me so I can see what you did!
	I took the time to separate it from the stuckPlayerFixer so it could be easier to modify.
	-ParaKrei
]]

--A little function that will try to use P_SetOrigin, and fallback to P_TeleportMove if it doesn't work; this is to keep compatibility with pre-2.2.11.
function setMobjPos(mobj, x, y, z)
	if pcall(P_SetOrigin, mobj, x, y, z) ~= true then
		P_TeleportMove(mobj, x, y, z)
	end
end

--A little function that will try to use P_MoveOrigin, and fallback to P_TeleportMove if it doesn't work; this is to keep compatibility with pre-2.2.11.
local function moveMobj(mobj, x, y, z)
	if pcall(P_MoveOrigin, mobj, x, y, z) ~= true then
		P_TeleportMove(mobj, x, y, z)
	end
end

--Just a clamp function, can be found everywhere at this point.
--Based off of pgimeno's version on the LÖVE board.
--(https://love2d.org/forums/viewtopic.php?t=1856 on page 2)
local function clamp(val, minVal, maxVal)
	return(max(minVal, min(maxVal, val)))
end

--A function that teleports a player to their last starpost, or to a spawn point.
local function toStarpostOrSpawn(ply, forceSpawn)
	if forceSpawn == nil then forceSpawn = false end

	if not(objectExists(ply)) or not(objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.playerstate ~= PST_LIVE then return end --Player's dead.

	--Restore to starpost OR player spawn(s).
	if ply.starpostnum == 0 then --No star post has been set.
		teleportToPos(ply, ply.spawnx, ply.spawny, ply.spawnz, ply.spawnangle, true)
		if ply.spawnflip then ply.mo.flags2 = $ | MF2_OBJECTFLIP else ply.mo.flags2 = $ & ~MF2_OBJECTFLIP end
		if ply.spawn2d then ply.mo.flags2 = $ | MF2_TWOD else ply.mo.flags2 = $ & ~MF2_TWOD end
	else
		teleportToPos(ply, ply.starpostx*FU, ply.starposty*FU, ply.starpostz*FU, ply.starpostangle, true)
		if ply.starpostflip then ply.mo.flags2 = $ | MF2_OBJECTFLIP else ply.mo.flags2 = $ & ~MF2_OBJECTFLIP end
		if ply.starpost2d then ply.mo.flags2 = $ | MF2_TWOD else ply.mo.flags2 = $ & ~MF2_TWOD end
	end
end

--Try Move from Position in all Directions.
--Does what it says on the tin.
--Returns if TryMove was successful in ANY direction.
local function TMfPiaD(mobj, options)
	if options == nil then
		options = {
			dist = 1*FU,
			dropoff = false,
			restorePos = false,
			debug = false,
		}
	end
	if options.dist == nil then options.dist = 1*FU end
	if options.dropoff == nil then options.dropoff = false end
	if options.restorePos == nil then options.restorePos = false end
	if options.debug == nil then options.debug = false end

	local angTbl = {
		0,
		ANGLE_45,
		ANGLE_90,
		ANGLE_135,
		ANGLE_180,
		ANGLE_270,
		ANGLE_315,
		ANGLE_MAX
	}

	local wasOnGround = P_IsObjectOnGround(mobj)
	
	local pushFailed = true
	for d=1,#angTbl do
		local velo = {
			x=P_ReturnThrustX(nil, angTbl[d], options.dist),
			y=P_ReturnThrustY(nil, angTbl[d], options.dist)
		}
		local lastPos = {
			x=mobj.x,
			y=mobj.y,
			z=mobj.z
		}

		if options.debug then print("Trying to move mobj to x: "..tostring(mobj.x+velo.x)..", y: "..tostring(mobj.y+velo.y)) end
		if P_TryMove(mobj, mobj.x+velo.x, mobj.y+velo.y, options.dropoff) then
			pushFailed = false
			if options.restorePos then
				local newZ = lastPos.z
				if wasOnGround then
					if P_MobjFlip(mobj) == -1 then
						newZ = mobj.ceilingz-mobj.height
					else
						newZ = mobj.floorz
					end
					
				end
				
				moveMobj(mobj, lastPos.x, lastPos.y, newZ)
			end
			break
		end
	end

	return not(pushFailed)
end

local function restoreToPos(ply, lastTbls, i, max, checkFunc, snapDown)
	if not(objectExists(ply)) or not(objectExists(ply.mo)) then return false end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.playerstate ~= PST_LIVE then return false end --Player's dead.

	if lastTbls == nil or lastTbls.pos == nil or lastTbls.angle == nil or lastTbls.flip == nil or lastTbls.twod == nil then return end
	local posTbl = lastTbls.pos
	local angleTbl = lastTbls.angle
	local flipTbl = lastTbls.flip
	local twodTbl = lastTbls.twod
	if i == nil then i = 0 end
	if max == nil then max = 1 end
	if checkFunc == nil then
		checkFunc = function() return true end
	end
	if snapDown == nil then snapDown = true end

	local failed = true
	local count = 0

	local beginningPos = {x=ply.mo.x, y=ply.mo.y, z=ply.mo.z}
	
	--Try all positions in the table.
	while count < max do --Doing this to prioritize newer states.
		local subsector = R_PointInSubsectorOrNil(posTbl[i].x, posTbl[i].y)
		if subsector == nil then
			count = $+1
			i = clamp(($-1) % max, 0, max)
			continue
		end
		
		if P_CheckPosition(ply.mo, posTbl[i].x, posTbl[i].y) then
			local newZ = posTbl[i].z
			if snapDown then
				if P_MobjFlip(ply.mo) == -1 then
					newZ = P_CeilingzAtPos(posTbl[i].x, posTbl[i].y, posTbl[i].z, ply.mo.height)
				else
					newZ = P_FloorzAtPos(posTbl[i].x, posTbl[i].y, posTbl[i].z, ply.mo.height)
				end
			end

			setMobjPos(ply.mo, posTbl[i].x, posTbl[i].y, newZ)
			if flipTbl[i] then ply.mo.flags2 = $ | MF2_OBJECTFLIP else ply.mo.flags2 = $ & ~MF2_OBJECTFLIP end
			if twodTbl[i] then ply.mo.flags2 = $ | MF2_TWOD else ply.mo.flags2 = $ & ~MF2_TWOD end
			if not(checkFunc()) then
				count = $+1
				i = clamp(($-1) % max, 0, max)
				setMobjPos(ply.mo, beginningPos.x, beginningPos.y, beginningPos.z)
				continue
			end
			
			teleportToPos(ply, posTbl[i].x, posTbl[i].y, newZ, angleTbl[i], true)
			failed = false
			break
		else
			count = $+1
			i = clamp(($-1) % max, 0, max)
			continue
		end
	end
	
	if failed or (not(failed) and not(checkFunc())) then return false else return true end
end

local function pushPlayerOut(ply, checkFunc, snapDown)
	if not(objectExists(ply)) or not(objectExists(ply.mo)) then return false end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.playerstate ~= PST_LIVE then return false end --Player's dead.

	if checkFunc == nil then
		checkFunc = function() return true end
	end
	if snapDown == nil then snapDown = true end
	local pushAmt = ply.mo.radius
	local pushCount = 0
	local failed = true

	while not(checkFunc()) or pushCount < TICRATE do
		if snapDown then
			if P_MobjFlip(ply.mo) == -1 then
				ply.mo.z = P_CeilingzAtPos(ply.mo.x, ply.mo.y, ply.mo.z, ply.mo.height)
			else
				ply.mo.z = P_FloorzAtPos(ply.mo.x, ply.mo.y, ply.mo.z, ply.mo.height)
			end
		end

		if pushCount > 5 then --Something's REALLY wrong...
			ply.mo.flags = $|MF_NOCLIP
			TMfPiaD(ply.mo, {dist=pushAmt, dropoff=true})
		else
			if pushCount > 0 then pushAmt = ply.mo.radius*(pushCount+1) end
			TMfPiaD(ply.mo, {dist=pushAmt, dropoff=true})
		end

		if checkFunc() then failed = false; break end
		
		pushCount = $+1
	end

	if failed or (not(failed) and not(checkFunc())) then return false else return true end
end

local function fixPlayerPos(ply, checkFunc, ignorePush)
	if not(objectExists(ply)) or not(objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.stuckPlayerFixer == nil then return end --Can't do anything yet.
	if ply.playerstate ~= PST_LIVE then return end --Player's dead.

	local spf = ply.stuckPlayerFixer
	local trackers = ply.stuckPlayerFixer.lastTrackers
	if checkFunc == nil then
		checkFunc = function() return true end
	end
	if ignorePush == nil then ignorePush = false end
	
	--Move to the last location that the player can exist in.
	if spf.timesTeleported[1] < 5 then
		if restoreToPos(ply, {pos=trackers.lastPos, angle=trackers.lastAngle, flip=trackers.lastFlip, twod=trackers.last2D}, trackers.lastTickers[1], spf.tickersMax, checkFunc) then
			P_ResetPlayer(ply)
			spf.timesTeleported[1] = $+1
			return
		end
	end
	
	--Move to the last position the player was standing.
	if spf.timesTeleported[2] < 5 then
		if restoreToPos(ply, {pos=trackers.lastPos, angle=trackers.lastAngle, flip=trackers.lastFlip, twod=trackers.last2D}, trackers.lastTickers[2], spf.tickersMax, checkFunc) then
			P_ResetPlayer(ply)
			spf.timesTeleported[2] = $+1
			return
		end
	end
	
	--THE STATES DIDN'T WORK!
	if spf.timesTeleported[3] < 5 then
		local pushSuccess = false
		if not(ignorePush) then pushSuccess = pushPlayerOut(ply, checkFunc) end
		if pushSuccess then
			P_ResetPlayer(ply)
			spf.timesTeleported[3] = $+1
			return
		end
	end

	if spf.timesTeleported[4] < 5 then
		toStarpostOrSpawn(ply)
		P_ResetPlayer(ply)
		spf.timesTeleported[4] = $+1
	else
		--Something has gone HORRIBLY wrong! So the player must DIE.
		P_DamageMobj(ply.mo, nil, nil, 1, DMG_INSTAKILL)
	end
end

--Setup variables.
addHook("PlayerSpawn", function()
	if ply.spectator then return end --Don't try to do anything if the player is a spectator.

	if ply.stuckPlayerFixer == nil then
		ply.stuckPlayerFixer = {
			lastTrackers = {
				lastPos = {}, --Yes, I'm saving the player's position in multiple different states.
				lastGroundedPos = {}, --Same as above, but grounded.
				lastAngle = {}, --Might as well do angles too.
				lastGroundedAngle = {}, --Same as above, but grounded.
				lastFlip = {}, --Saving gravity flipping as well.
				lastGroundedFlip = {}, --Same as above, but grounded.
				last2D = {}, --Saving 2D mode as well.
				lastGrounded2D = {}, --Same as above, but grounded.
				lastTickers = {0, 0}, --Sets the saving position in the tables above.
			},
			tickersMax = 5,
			stuck = false,
			stuckTimer = 0,
			timesTeleported = {0,0,0,0}, --Tracks how many times a stuck function was ran (last, last grounded, push, starpost/spawn).
			gotCrushed = false
		}
	end
	local spf = ply.stuckPlayerFixer

	for i=0,spf.tickersMax do
		spf.lastTrackers.lastPos[i] = {x=0,y=0,z=0}
		spf.lastTrackers.lastGroundedPos[i] = {x=0,y=0,z=0}
		spf.lastTrackers.lastAngle[i] = 0
		spf.lastTrackers.lastGroundedAngle[i] = 0
		spf.lastTrackers.lastFlip[i] = 0
		spf.lastTrackers.lastGroundedFlip[i] = 0
		spf.lastTrackers.last2D[i] = 0
		spf.lastTrackers.lastGrounded2D[i] = 0
	end
	spf.stuck = false
	spf.stuckTimer = 0
	for i=1,4 do spf.timesTeleported[i] = 0 end
end)

--Crusher detection.--
addHook("ShouldDamage", function(target, cause, src, dmg, dmgType)
	if not(skl.objectExists(target)) or not(skl.objectExists(target.player)) then return end --Don't do anything if the player or it's mobj doesn't exist.

	local ply = target.player
	local spf = ply.stuckPlayerFixer

	if dmgType == DMG_CRUSHED then
		spf.gotCrushed = true
	end
end, MT_PLAYER)

--Main code lives here.
addHook("PreThinkFrame", function()
	for ply in players.iterate() do
		if not(objectExists(ply)) or not(objectExists(ply.mo)) then continue end --Don't do anything if the player or it's mobj doesn't exist.
		if ply.stuckPlayerFixer == nil then continue end --Can't do anything yet.
		if ply.playerstate ~= PST_LIVE then continue end --Player's dead.

		local spf = ply.stuckPlayerFixer
		local trackers = ply.stuckPlayerFixer.lastTrackers

		if P_CheckDeathPitCollide(ply.mo) then
			spf.stuck = true
			spf.stuckTimer = TICRATE/3

			fixPlayerPos(ply, function()
				return not(P_CheckDeathPitCollide(ply.mo)) --Returns true if not in a death pit.
			end, true)
		end

		--NOT THE HYDRAULIC PRESS
		if spf.gotCrushed then
			spf.stuck = true
			spf.stuckTimer = TICRATE/3
		end

		--I'M STUCK
		if not(TMfPiaD(ply.mo, {dist=1*FU, dropoff=true, restorePos=true})) and leveltime > 0 then
			--Don't do anything if the player is in a zoom tube.
			if not(ply.powers[pw_carry] & CR_ZOOMTUBE) then
				--(https://youtu.be/KbqAiEEatWo?si=-g2eIRl0TkEJ6nZi&t=30)
				if not(ply.mo.eflags & MFE_TOUCHWATER) then --It was just water... false alarm!
					spf.stuck = true
					spf.stuckTimer = TICRATE/3
					
					--The player might just be stuck in the ground, snap them to the floor/ceiling first.
					if P_MobjFlip(ply.mo) == -1 then
						ply.mo.z = P_CeilingzAtPos(ply.mo.x, ply.mo.y, ply.mo.z, ply.mo.height)
					else
						ply.mo.z = P_FloorzAtPos(ply.mo.x, ply.mo.y, ply.mo.z, ply.mo.height)
					end

					if TMfPiaD(ply.mo, {dist=1*FU, dropoff=true, restorePos=true}) then --It worked!
						spf.stuck = false
						return
					end
					
					fixPlayerPos(ply, function()
						return TMfPiaD(ply.mo, {dist=1*FU, dropoff=true, restorePos=true}) --Returns true if the player can move.
					end)
				end
			end
		else
			spf.stuck = false
		end
	end
end)

--Stuck timer handler.
addHook("PlayerThink", function(ply)
	if skel.stuckTimer > 0 then skel.stuckTimer = $-1 end

	if ply.pflags & PF_SPINNING and skel.stuckTimer == 0 then
		ply.pflags = $ & ~PF_SPINNING
		ply.mo.state = S_PLAY_STND
	end

	if skel.stuckTimer == 0 then for i=1,4 do skel.timesTeleported[i] = 0 end end --Reset timesTeleported.
end)

--All of the trackers are updated here.
addHook("PostThinkFrame", function()
	for ply in players.iterate() do
		if not(objectExists(ply)) or not(objectExists(ply.mo)) then continue end --Don't do anything if the player or it's mobj doesn't exist.
		if ply.stuckPlayerFixer == nil then continue end --Can't do anything yet.
		if ply.playerstate ~= PST_LIVE then continue end --Player's dead.

		local spf = ply.stuckPlayerFixer
		local trackers = spf.lastTrackers

		trackers.lastTickers[1] = ($+1) % (spf.tickersMax+1)
		trackers.lastPos[trackers.lastTickers[1]] = {
			x=ply.mo.x,
			y=ply.mo.y,
			z=ply.mo.z
		}
		trackers.lastAngle[trackers.lastTickers[1]] = ply.mo.angle
		trackers.lastFlip[trackers.lastTickers[1]] = ply.mo.flags2 & MF2_OBJECTFLIP
		trackers.last2D[trackers.lastTickers[1]] = ply.mo.flags2 & MF2_TWOD

		if P_IsObjectOnGround(ply.mo) and not(P_CheckDeathPitCollide(ply.mo)) then
			trackers.lastTickers[2] = ($+1) % (spf.tickersMax+1)
			trackers.lastGroundedPos[trackers.lastTickers[2]] = {
				x=ply.mo.x,
				y=ply.mo.y,
				z=ply.mo.z
			}
			trackers.lastGroundedAngle[trackers.lastTickers[2]] = ply.mo.angle
			trackers.lastGroundedFlip[trackers.lastTickers[2]] = ply.mo.flags2 & MF2_OBJECTFLIP
			trackers.lastGrounded2D[trackers.lastTickers[2]] = ply.mo.flags2 & MF2_TWOD
		end

		if ply.starpostnum ~= ply.laststarpostnum then
			ply.starpostflip = ply.mo.flags2 & MF2_OBJECTFLIP
			ply.starpost2d = ply.mo.flags2 & MF2_TWOD
		end

		ply.laststarpostnum = ply.starpostnum
	end
end)

--Reset spawn-related trackers.
addHook("MapChange", function()
	for ply in players.iterate() do
		if objectExists(ply) then
			ply.spawnx = nil
			ply.spawny = nil
			ply.spawnz = nil
			ply.spawnangle = nil

			ply.spawnflip = nil
			ply.spawn2d = nil
		end
	end
end)

--Player spawn checker and saver; required here as PlayerSpawn is too fast.
addHook("MapLoad", function()
	for ply in players.iterate() do
		if ply.spectator then continue end --Don't try to do anything if the player is a spectator.
		--Get if the spawn position is flipped or in 2D.
		if ply.mo.flags2 & MF2_OBJECTFLIP or ply.mo.eflags & MFE_VERTICALFLIP then ply.spawnflip = true else ply.spawnflip = false end
		if ply.mo.flags2 & MF2_TWOD then ply.spawn2d = true else ply.spawn2d = false end

		--Save the spawning position.
		ply.spawnx = ply.mo.x
		ply.spawny = ply.mo.y
		ply.spawnz = ply.mo.z
		ply.spawnangle = ply.mo.angle

		--Reset the starpost trackers.
		ply.starpostflip = 0
		ply.laststarpostnum = 0
		ply.starpost2d = 0
	end
end)

--Backup for when the MapLoad hook fails.
addHook("PlayerSpawn", function(ply)
	if ply.spectator then return end --Don't try to do anything if the player is a spectator.
	--Get if the spawn position is flipped or in 2D.
	if ply.spawnflip == nil then
		if ply.mo.flags2 & MF2_OBJECTFLIP or ply.mo.eflags & MFE_VERTICALFLIP then ply.spawnflip = true else ply.spawnflip = false end
	end
	if ply.spawn2d == nil then
		if ply.mo.flags2 & MF2_TWOD then ply.spawn2d = true else ply.spawn2d = false end
	end

	--Save the spawning position.
	if ply.spawnx == nil then ply.spawnx = ply.mo.x end
	if ply.spawny == nil then ply.spawny = ply.mo.y end
	if ply.spawnz == nil then ply.spawnz = ply.mo.z end
	if ply.spawnangle == nil then ply.spawnangle = ply.mo.angle end
end)