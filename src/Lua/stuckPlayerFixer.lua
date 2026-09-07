--[[
	The position fixer for all of the times the player gets stuck live here.
]]

--DEPRECATED; COULDN'T GET THIS TO WORK WITHOUT BREAKING SLOPES, IF YOU CAN, POWER TO YOU.
-- local function restoreToPos(ply, lastTbls, i, max, checkFunc, snapDown)
-- 	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return false end --Don't do anything if the player or it's mobj doesn't exist.
-- 	if ply.playerstate ~= PST_LIVE then return false end --Player's dead.

-- 	if lastTbls == nil or lastTbls.pos == nil or lastTbls.angle == nil or lastTbls.flip == nil or lastTbls.twod == nil then return end
-- 	local posTbl = lastTbls.pos
-- 	local angleTbl = lastTbls.angle
-- 	local flipTbl = lastTbls.flip
-- 	local twodTbl = lastTbls.twod
-- 	if i == nil then i = 0 end
-- 	if max == nil then max = 1 end
-- 	if checkFunc == nil then
-- 		checkFunc = function() return true end
-- 	end
-- 	if snapDown == nil then snapDown = true end

-- 	local failed = true
-- 	local count = 0

-- 	local beginningPos = {x=ply.mo.x, y=ply.mo.y, z=ply.mo.z}
	
-- 	--Try all positions in the table.
-- 	while count < max do --Doing this to prioritize newer states.
-- 		local subsector = R_PointInSubsectorOrNil(posTbl[i].x, posTbl[i].y)
-- 		if subsector == nil then
-- 			count = $+1
-- 			i = skl.clamp(($-1) % max, 0, max)
-- 			continue
-- 		end
		
-- 		if P_CheckPosition(ply.mo, posTbl[i].x, posTbl[i].y) then
-- 			local newZ = posTbl[i].z
-- 			if snapDown then
-- 				if P_MobjFlip(ply.mo) == -1 then
-- 					newZ = P_CeilingzAtPos(posTbl[i].x, posTbl[i].y, posTbl[i].z, ply.mo.height)
-- 				else
-- 					newZ = P_FloorzAtPos(posTbl[i].x, posTbl[i].y, posTbl[i].z, ply.mo.height)
-- 				end
-- 			end

-- 			skl.setMobjPos(ply.mo, posTbl[i].x, posTbl[i].y, newZ)
-- 			if flipTbl[i] then ply.mo.flags2 = $ | MF2_OBJECTFLIP else ply.mo.flags2 = $ & ~MF2_OBJECTFLIP end
-- 			if twodTbl[i] then ply.mo.flags2 = $ | MF2_TWOD else ply.mo.flags2 = $ & ~MF2_TWOD end
-- 			if not(checkFunc()) then
-- 				count = $+1
-- 				i = skl.clamp(($-1) % max, 0, max)
-- 				skl.setMobjPos(ply.mo, beginningPos.x, beginningPos.y, beginningPos.z)
-- 				continue
-- 			end
			
-- 			skl.teleportToPos(ply, posTbl[i].x, posTbl[i].y, newZ, angleTbl[i], true)
-- 			failed = false
-- 			break
-- 		else
-- 			count = $+1
-- 			i = skl.clamp(($-1) % max, 0, max)
-- 			continue
-- 		end
-- 	end
	
-- 	if failed or (not(failed) and not(checkFunc())) then return false else return true end
-- end

-- local function pushPlayerOut(ply, checkFunc, snapDown)
-- 	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return false end --Don't do anything if the player or it's mobj doesn't exist.
-- 	if ply.playerstate ~= PST_LIVE then return false end --Player's dead.

-- 	if checkFunc == nil then
-- 		checkFunc = function() return true end
-- 	end
-- 	if snapDown == nil then snapDown = true end
-- 	local pushAmt = ply.mo.radius
-- 	local pushCount = 0
-- 	local failed = true

-- 	while not(checkFunc()) or pushCount < TICRATE do
-- 		if snapDown then
-- 			if P_MobjFlip(ply.mo) == -1 then
-- 				ply.mo.z = P_CeilingzAtPos(ply.mo.x, ply.mo.y, ply.mo.z, ply.mo.height)
-- 			else
-- 				ply.mo.z = P_FloorzAtPos(ply.mo.x, ply.mo.y, ply.mo.z, ply.mo.height)
-- 			end
-- 		end

-- 		if pushCount > 5 then --Something's REALLY wrong...
-- 			ply.mo.flags = $|MF_NOCLIP
-- 			skl.TMfPiaD(ply.mo, {dist=pushAmt, dropoff=true})
-- 		else
-- 			if pushCount > 0 then pushAmt = ply.mo.radius*(pushCount+1) end
-- 			skl.TMfPiaD(ply.mo, {dist=pushAmt, dropoff=true})
-- 		end

-- 		if checkFunc() then failed = false; break end
		
-- 		pushCount = $+1
-- 	end

-- 	if failed or (not(failed) and not(checkFunc())) then return false else return true end
-- end

-- local function fixPlayerPos(ply, checkFunc, ignorePush)
-- 	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
-- 	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
-- 	if ply.skeleton == nil then return end --Can't do anything yet.
-- 	if ply.playerstate ~= PST_LIVE then return end --Player's dead.

-- 	local skel = ply.skeleton
-- 	local trackers = ply.skeleton.lastTrackers
-- 	if checkFunc == nil then
-- 		checkFunc = function() return true end
-- 	end
-- 	if ignorePush == nil then ignorePush = false end
	
-- 	--Move to the last location that the player can exist in.
-- 	if skel.timesTeleported[1] < 5 then
-- 		if restoreToPos(ply, {pos=trackers.lastPos, angle=trackers.lastAngle, flip=trackers.lastFlip, twod=trackers.last2D}, trackers.lastTickers[1], skel.tickersMax, checkFunc) then
-- 			P_ResetPlayer(ply)
-- 			skel.timesTeleported[1] = $+1
-- 			return
-- 		end
-- 	end
	
-- 	--Move to the last position the player was standing.
-- 	if skel.timesTeleported[2] < 5 then
-- 		if restoreToPos(ply, {pos=trackers.lastPos, angle=trackers.lastAngle, flip=trackers.lastFlip, twod=trackers.last2D}, trackers.lastTickers[2], skel.tickersMax, checkFunc) then
-- 			P_ResetPlayer(ply)
-- 			skel.timesTeleported[2] = $+1
-- 			return
-- 		end
-- 	end
	
-- 	--THE STATES DIDN'T WORK!
-- 	if skel.timesTeleported[3] < 5 then
-- 		local pushSuccess = false
-- 		if not(ignorePush) then pushSuccess = pushPlayerOut(ply, checkFunc) end
-- 		if pushSuccess then
-- 			P_ResetPlayer(ply)
-- 			skel.timesTeleported[3] = $+1
-- 			return
-- 		end
-- 	end

-- 	if skel.timesTeleported[4] < 5 then
-- 		skl.toStarpostOrSpawn(ply)
-- 		P_ResetPlayer(ply)
-- 		skel.timesTeleported[4] = $+1
-- 	else
-- 		--Something has gone HORRIBLY wrong! So the player must DIE.
-- 		P_DamageMobj(ply.mo, nil, nil, 1, DMG_INSTAKILL)
-- 	end
-- end

--Main code lives here.
addHook("PreThinkFrame", function()
	for ply in players.iterate() do
		if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then continue end --Don't do anything if the player or it's mobj doesn't exist.
		if ply.mo.skin ~= "skeleton" then continue end --ONLY for the skeleton.
		if ply.skeleton == nil then continue end --Can't do anything yet.
		if ply.playerstate ~= PST_LIVE then continue end --Player's dead.

		local skel = ply.skeleton
		local trackers = ply.skeleton.lastTrackers

		if P_CheckDeathPitCollide(ply.mo) then
			skl.toStarpostOrSpawn(ply) --Teleport the player to the starpost OR a spawn point.

			--DEPRECATED; COULDN'T GET THIS TO WORK WITHOUT BREAKING SLOPES, IF YOU CAN, POWER TO YOU.--
			-- skel.stuck = true
			-- skel.stuckTimer = TICRATE/3

			-- fixPlayerPos(ply, function()
			-- 	return not(P_CheckDeathPitCollide(ply.mo)) --Returns true if not in a death pit.
			-- end, true)
		end

		--NOT THE HYDRAULIC PRESS
		if skel.gotCrushed then
			--DEPRECATED; COULDN'T GET THIS TO WORK WITHOUT BREAKING SLOPES, IF YOU CAN, POWER TO YOU.--
			-- skel.stuck = true
			-- skel.stuckTimer = TICRATE/3

			skl.toStarpostOrSpawn(ply) --Teleport the player to the starpost OR a spawn point.
			skel.gotCrushed = false --Clear the check.
		end

		--DEPRECATED; COULDN'T GET THIS TO WORK WITHOUT BREAKING SLOPES, IF YOU CAN, POWER TO YOU.--
		--I'M STUCK
		-- if not(skl.TMfPiaD(ply.mo, {dist=1*FU, dropoff=true, restorePos=true})) and leveltime > 0 then
		-- 	--Don't do anything if the player is in a zoom tube.
		-- 	if not(ply.powers[pw_carry] & CR_ZOOMTUBE) then
		-- 		--(https://youtu.be/KbqAiEEatWo?si=-g2eIRl0TkEJ6nZi&t=30)
		-- 		if not(ply.mo.eflags & MFE_TOUCHWATER) then --It was just water... false alarm!
		-- 			skel.stuck = true
		-- 			skel.stuckTimer = TICRATE/3
					
		-- 			--The player might just be stuck in the ground, snap them to the floor/ceiling first.
		-- 			if P_MobjFlip(ply.mo) == -1 then
		-- 				ply.mo.z = P_CeilingzAtPos(ply.mo.x, ply.mo.y, ply.mo.z, ply.mo.height)
		-- 			else
		-- 				ply.mo.z = P_FloorzAtPos(ply.mo.x, ply.mo.y, ply.mo.z, ply.mo.height)
		-- 			end

		-- 			if skl.TMfPiaD(ply.mo, {dist=1*FU, dropoff=true, restorePos=true}) then --It worked!
		-- 				skel.stuck = false
		-- 				return
		-- 			end
					
		-- 			fixPlayerPos(ply, function()
		-- 				return skl.TMfPiaD(ply.mo, {dist=1*FU, dropoff=true, restorePos=true}) --Returns true if the player can move.
		-- 			end)
		-- 		end
		-- 	end
		-- else
		-- 	skel.stuck = false
		-- end

		if not(skl.objectExists(skel.shieldObj)) then skel.shieldObj = nil end
	end
end)

--All of the trackers are updated here.
addHook("PostThinkFrame", function()
	for ply in players.iterate() do
		if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then continue end --Don't do anything if the player or it's mobj doesn't exist.
		if ply.mo.skin ~= "skeleton" then continue end --ONLY for the skeleton.
		if ply.skeleton == nil then continue end --Can't do anything yet.
		if ply.playerstate ~= PST_LIVE then continue end --Player's dead.

		local skel = ply.skeleton
		local trackers = skel.lastTrackers

		skel.wasInZoomTube = ply.powers[pw_carry] & CR_ZOOMTUBE ~= 0

		--DEPRECATED; COULDN'T GET THIS TO WORK WITHOUT BREAKING SLOPES, IF YOU CAN, POWER TO YOU.--
		-- trackers.lastTickers[1] = ($+1) % (skel.tickersMax+1)
		-- trackers.lastPos[trackers.lastTickers[1]] = {
		-- 	x=ply.mo.x,
		-- 	y=ply.mo.y,
		-- 	z=ply.mo.z
		-- }
		-- trackers.lastAngle[trackers.lastTickers[1]] = ply.mo.angle
		-- trackers.lastFlip[trackers.lastTickers[1]] = ply.mo.flags2 & MF2_OBJECTFLIP
		-- trackers.last2D[trackers.lastTickers[1]] = ply.mo.flags2 & MF2_TWOD

		-- if P_IsObjectOnGround(ply.mo) and not(P_CheckDeathPitCollide(ply.mo)) then
		-- 	trackers.lastTickers[2] = ($+1) % (skel.tickersMax+1)
		-- 	trackers.lastGroundedPos[trackers.lastTickers[2]] = {
		-- 		x=ply.mo.x,
		-- 		y=ply.mo.y,
		-- 		z=ply.mo.z
		-- 	}
		-- 	trackers.lastGroundedAngle[trackers.lastTickers[2]] = ply.mo.angle
		-- 	trackers.lastGroundedFlip[trackers.lastTickers[2]] = ply.mo.flags2 & MF2_OBJECTFLIP
		-- 	trackers.lastGrounded2D[trackers.lastTickers[2]] = ply.mo.flags2 & MF2_TWOD
		-- end

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
		if skl.objectExists(ply) then
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