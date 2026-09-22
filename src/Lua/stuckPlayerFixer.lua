--[[
	The position fixer for all of the times the player gets stuck live here.
]]

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
		end

		--NOT THE HYDRAULIC PRESS
		if skel.gotCrushed then
			skl.toStarpostOrSpawn(ply) --Teleport the player to the starpost OR a spawn point.
			skel.gotCrushed = false --Clear the check.
		end
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