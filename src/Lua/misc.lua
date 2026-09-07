--[[
	All of the misc. functions live here.
]]

--Just a clamp function, can be found everywhere at this point.
--Based off of pgimeno's version on the LÖVE board.
--(https://love2d.org/forums/viewtopic.php?t=1856 on page 2)
skl["clamp"] = function(val, minVal, maxVal)
	return(max(minVal, min(maxVal, val)))
end
local clamp = skl.clamp --Required for local calls

--An amazing non-fallthrough switch statement.
--Tweaked by ParaKrei to insert the ability to call another case to avoid reusing code.
--Original made by Krystilize, from Stack Overflow; CC BY-SA 4.0
--(https://stackoverflow.com/a/65047878)
--New usage: Works like the original, but putting in another case into a string into where a function goes will call that case's function.
skl["switch"] = function(element)
	local Table = {
		["Value"] = element,
		["DefaultFunction"] = nil,
		["Functions"] = {}
	}

	Table.case = function(testElement, callback)
		Table.Functions[testElement] = callback
		return Table
	end

	Table.default = function(callback)
		Table.DefaultFunction = callback
		return Table
	end

	Table.process = function()
		local Case = Table.Functions[Table.Value]

		if type(Table.Functions[Case]) == "function" then
			Table.Functions[Case]()
		elseif Case then
			Case()
		elseif Table.DefaultFunction then
			Table.DefaultFunction()
		end
	end

	return Table
end
local switch = skl.switch --Required for local calls

--An iterator like pair(), but sorted by the table's keys.
--Taken straight from the Lua manual.
--(https://www.lua.org/pil/19.3.html)
skl["pairsByKeys"] = function(tbl, sortFunc)
	local sorted = {}

	for key in pairs(tbl) do table.insert(sorted, key) end
	table.sort(sorted, sortFunc)

	local i = 0
	local iterFunc = function()
		i = i+1

		if sorted[i] == nil then return nil
		else return sorted[i], tbl[sorted[i]] end
	end

	return iterFunc
end

--Helper function to directly compare tables to see if they are EXACT matches.
--Made by TomatoCo
--(https://www.reddit.com/r/lua/comments/417v44/efficient_table_comparison/)
--[Look, it was 1AM when I was looking for a table comparison function,
--I'm not going to make my own function, especially when this does exactly what I want.]
skl["tableCompare"] = function(tbl1, tbl2)
	if #tbl1 ~= #tbl2 then return false end

	local t1, t2 = {}, {}

	--Make local copies.
	for key,val in pairs(tbl1) do
		t1[key] = (t1[key] or 0)+1 --Count the times we've seen the same value.
	end
	for key,val in pairs(tbl2) do
		t2[key] = (t2[key] or 0)+1
	end

	for key,val in pairs(t1) do
		if val ~= t2[key] then return false end
	end

	return true
end

--Helper function to return if a string matches any entries in a table.
skl["isStringInTbl"] = function(str, tbl)
	for _,val in pairs(tbl) do
		if tostring(str):lower() == tostring(val):lower() then
			return true
		end
	end
	return false
end
local isStringInTbl = skl.isStringInTbl --Required for local calls

--Helper function to return if a string represents true or false.
skl["strToBool"] = function(str)
	local trueTbl = {"true", "1", "on"}
	local falseTbl = {"false", "0", "off"}

	if isStringInTbl(str, trueTbl) then
		return true
	elseif isStringInTbl(str, falseTbl) then
		return false
	end

	return nil
end
local strToBool = skl.strToBool --Required for local calls

--Helper function to return if an object is NOT nil and valid.
skl["objectExists"] = function(obj)
	if obj ~= nil and obj.valid then
		return true
	end

	return false
end
local objectExists = skl.objectExists --Required for local calls

--Helper function to quickly draw a list on the HUD.
skl["multilineDrawString"] = function(v, x, y, strings, flags, align)
	if v == nil then return end

	if strings == nil or type(strings) ~= "table" then strings = {""} end

	if x == nil or type(x) ~= "number" then x = 0 end
	if y == nil or type(y) ~= "number" then y = 0 end
	
	local offset = 12
	for i,str in pairs(strings) do
		v.drawString(x, (y-offset)+(offset*i), str, flags, align)
	end
end

--A little function to quickly make draw commands with object-like data.
skl["dataDraw"] = function(v, drawType, obj)
	if obj.patch == nil then obj.patch = v.getSpritePatch("UNKN") end
	if obj.flags == nil then obj.flags = 0 end
	if obj.x == nil then obj.x = 0 end
	if obj.y == nil then obj.y = 0 end
	if obj.colormap == nil then obj.colormap = v.getColormap(TC_DEFAULT) end --Just in case.
	
	if (type(drawType) == "string" and (drawType:lower() == "normal" or drawType:lower() == "n") or (tonumber(drawType) ~= nil and tonumber(drawType) == 0)) then
		v.draw(obj.x, obj.y, obj.patch, obj.flags, obj.colormap)
		return true
	elseif (type(drawType) == "string" and (drawType:lower() == "scaled" or drawType:lower() == "sc") or (tonumber(drawType) ~= nil and tonumber(drawType) == 1)) then
		if obj.scale == nil then obj.scale = FU end

		v.drawScaled(obj.x, obj.y, obj.scale, obj.patch, obj.flags, obj.colormap)
		return true
	elseif (type(drawType) == "string" and (drawType:lower() == "stretched" or drawType:lower() == "st") or (tonumber(drawType) ~= nil and tonumber(drawType) == 2)) then
		if obj.scale == nil then obj.scale = {x=FU, y=FU} end
		if obj.scale.x == nil then obj.scale.x = FU end
		if obj.scale.y == nil then obj.scale.y = FU end

		v.drawStretched(obj.x, obj.y, obj.scale.x, obj.scale.y, obj.patch, obj.flags, obj.colormap)
		return true
	elseif (type(drawType) == "string" and (drawType:lower() == "cropped" or drawType:lower() == "c") or (tonumber(drawType) ~= nil and tonumber(drawType) == 3)) then
		if obj.scale == nil then obj.scale = {x=FU, y=FU} end
		if obj.scale.x == nil then obj.scale.x = FU end
		if obj.scale.y == nil then obj.scale.y = FU end
		if obj.crop == nil then obj.crop = {x=FU, y=FU} end
		if obj.crop.x == nil then obj.crop.x = FU end
		if obj.crop.y == nil then obj.crop.y = FU end
		if obj.width == nil then obj.width = FU end
		if obj.height == nil then obj.height = FU end

		v.drawCropped(obj.x, obj.y, obj.scale.x, obj.scale.y, obj.patch, obj.flags, obj.colormap, obj.crop.x, obj.crop.y, obj.width, obj.height)
		return true
	elseif (type(drawType) == "string" and (drawType:lower() == "string" or drawType:lower() == "str" or drawType:lower() == "text" or drawType:lower() == "txt") or (tonumber(drawType) ~= nil and tonumber(drawType) == 4)) then
		if obj.text == nil then obj.text = "" end
		if obj.align == nil then obj.align = "left" end

		v.drawString(obj.x, obj.y, obj.text, obj.flags, obj.align)
		return true
	elseif (type(drawType) == "string" and (drawType:lower() == "fill" or drawType:lower() == "box" or drawType:lower() == "square") or (tonumber(drawType) ~= nil and tonumber(drawType) == 5)) then
		if obj.width == nil then obj.width = 320 end
		if obj.height == nil then obj.height = 200 end
		if obj.color == nil then obj.color = 31 end

		v.drawFill(obj.x, obj.y, obj.width, obj.height, obj.color)
		return true
	end

	return false
end

--Helper function to return an object's bounding box.
--(https://git.do.srb2.org/STJr/SRB2/-/blob/SRB2_release_2.2.15/src/p_mobj.c#L1128)
skl["getBBox"] = function(obj, options)
	if options == nil then
		options = {
			mathFunc = nil,
			x = nil,
			y = nil,
		}
	end

	local radius = obj.radius
	local x = obj.x
	local y = obj.y

	if options.mathFunc ~= nil then
		radius = options.mathFunc(radius)
	end
	if options.x ~= nil then x = options.x end
	if options.y ~= nil then y = options.y end

	local bbox = {
		BOXLEFT = x-radius,
		BOXRIGHT = x+radius,
		BOXTOP = y+radius,
		BOXBOTTOM = y-radius
	}

	return bbox
end
local getBBox = skl.getBBox --Required for local calls

--Helper function to return the corner points of an object's bounding box.
skl["getBBoxPoints"] = function(obj, options)
	local bbox = getBBox(obj, options)
	local func = P_FloorzAtPos
	if P_MobjFlip(obj) == -1 then func = P_CeilingzAtPos end

	local points = {
		TOPLEFT = {x=bbox.BOXLEFT, y=bbox.BOXTOP, z=func(bbox.BOXLEFT, bbox.BOXTOP, obj.z, obj.height)},
		TOPRIGHT = {x=bbox.BOXRIGHT, y=bbox.BOXTOP, z=func(bbox.BOXRIGHT, bbox.BOXTOP, obj.z, obj.height)},
		BOTTOMLEFT = {x=bbox.BOXLEFT, y=bbox.BOXBOTTOM, z=func(bbox.BOXLEFT, bbox.BOXBOTTOM, obj.z, obj.height)},
		BOTTOMRIGHT = {x=bbox.BOXRIGHT, y=bbox.BOXBOTTOM, z=func(bbox.BOXRIGHT, bbox.BOXBOTTOM, obj.z, obj.height)}
	}

	return points
end
local getBBoxPoints = skl.getBBoxPoints --Required for local calls

skl["getMismatchedObjZBBoxZ"] = function(obj, options)
	local points = getBBoxPoints(obj, options)

	local targetNames = {}
	for name,coords in pairs(points) do
		local check = obj.z ~= coords.z
		-- print("the tic I see: "..tostring(leveltime)..", the mobj Z I see: "..tostring(obj.z))
		
		if check then
			table.insert(targetNames, name)
		end
	end

	return targetNames
end

--Helper function to get the FOF below the target mobj.
skl["getFOFBelowMobj"] = function(mobj)
	if objectExists(mobj.floorrover) and objectExists(mobj.ceilingrover) then
		if P_MobjFlip(mobj) == -1 then
			return mobj.ceilingrover
		else
			return mobj.floorrover
		end
	elseif not(objectExists(mobj.floorrover)) then
		return mobj.ceilingrover
	elseif not(objectExists(mobj.ceilingrover)) then
		return mobj.floorrover
	else
		return nil
	end
end
local getFOFBelowMobj = skl.getFOFBelowMobj --Required for local calls

--Re-implementation of P_CheckBustableBlocks from the SRB2 source code (https://git.do.srb2.org/STJr/SRB2/-/blob/SRB2_release_2.2.15/src/p_user.c#L2713).
skl["P_BustFOF"] = function(fof, mobj, targetAll)
	if targetAll == nil then targetAll = false end
	if fof == nil or not(fof.fofflags & FOF_EXISTS) or (not(targetAll) and not(fof.fofflags & FOF_BUSTUP)) then return nil end

	if mobj ~= nil then
		--Height checks.
		if fof.bustflags & FB_ONLYBOTTOM then
			if not(mobj.z + mobj.momz + mobj.height < fof.bottomheight) then return nil end
			if not(mobj.z + mobj.momz > fof.bottomheight) then return nil end
		else
			switch(fof.busttype)
				.case(BT_TOUCH, function()
					if not(mobj.z + mobj.momz > fof.topheight) then return nil end
					if not(mobj.z + mobj.momz + mobj.height < fof.bottomheight) then return nil end
				end)
				.case(BT_SPINBUST, function()
					if not(mobj.z + mobj.momz > fof.topheight) then return nil end
					if not(mobj.z + mobj.height < fof.bottomheight) then return nil end
				end)
				.default(function()
					if not(mobj.z >= fof.topheight) then return nil end
					if not(mobj.z + mobj.height < fof.bottomheight) then return nil end
				end)
			.process()
		end

		--Delay the mobj's fall for a little bit.
		if (fof.busttype == BT_TOUCH or fof.busttype == BT_SPINBUST) and mobj.z >= fof.topheight then
			mobj.momz = $ >> 1
		elseif fof.busttype == BT_TOUCH then
			mobj.momx = $ >> 1
			mobj.momy = $ >> 1
		end
	end

	--MURDER THE FOF.
	EV_CrumbleChain(nil, fof)

	--Run the linedef execution!
	if fof.bustflags & FB_EXECUTOR then
		P_LinedefExecute(fof.busttag, mobj, fof.sector)
	end

	return true
end
local P_BustFOF = skl.P_BustFOF --Required for local calls

--Same as above, but only checks.
skl["P_IsFOFBustable"] = function(fof, mobj, targetAll)
	if targetAll == nil then targetAll = false end
	if fof == nil or not(fof.fofflags & FOF_EXISTS) or (not(targetAll) and not(fof.fofflags & FOF_BUSTUP)) then return false end

	if mobj ~= nil then
		--Height checks.
		if fof.bustflags & FB_ONLYBOTTOM then
			if not(mobj.z + mobj.momz + mobj.height < fof.bottomheight) then return false end
			if not(mobj.z + mobj.momz > fof.bottomheight) then return false end
		else
			switch(fof.busttype)
				.case(BT_TOUCH, function()
					if not(mobj.z + mobj.momz > fof.topheight) then return false end
					if not(mobj.z + mobj.momz + mobj.height < fof.bottomheight) then return false end
				end)
				.case(BT_SPINBUST, function()
					if not(mobj.z + mobj.momz > fof.topheight) then return false end
					if not(mobj.z + mobj.height < fof.bottomheight) then return false end
				end)
				.default(function()
					if not(mobj.z >= fof.topheight) then return false end
					if not(mobj.z + mobj.height < fof.bottomheight) then return false end
				end)
			.process()
		end
	end

	return true
end

--Helper function to bust up FOFs below an mobj.
skl["P_CrumbleFOFBelowMobj"] = function(mobj)
	local fof = getFOFBelowMobj(mobj)

	if P_BustFOF(fof, mobj) == nil then return nil else return true end
end

--Helper function to return if any game control is pressed through the input library.
skl["anyGameControlDown"] = function(targetP2)
	if targetP2 == nil then targetP2 = false end

	local func = input.gameControlDown
	if targetP2 then func = input.gameControl2Down end

	for i=1,NUM_GAMECONTROLS-1 do
		if func(i) then return true end
	end

	return false
end
--Helper function to return all pressed game controls through the input library.
skl["getAllPressedGameControls"] = function(targetP2)
	if targetP2 == nil then targetP2 = false end

	local func = input.gameControlDown
	if targetP2 then func = input.gameControl2Down end

	local tbl = {}
	for i=1,NUM_GAMECONTROLS-1 do
		if func(i) then table.insert(tbl, i) end
	end

	return tbl
end

--Helper function to check if a player can be hurt.
skl["canPlayerBeHurt"] = function(ply, debug)
	if debug then
		print("Is player invulnerable? "..tostring(ply.powers[pw_invulnerability] ~= 0))
		print("Is player flashing? "..tostring(ply.powers[pw_flashing] ~= 0))
		print("Is player super? "..tostring(ply.powers[pw_super] ~= 0))
		print("Does player have STR_GUARD? "..tostring(ply.powers[pw_strong] & STR_GUARD ~= 0))
		print("Is player in pain? "..tostring(P_PlayerInPain(ply)))
	end

	if ply.powers[pw_invulnerability] or
	ply.powers[pw_flashing] or
	ply.powers[pw_super] or
	(ply.powers[pw_strong] & STR_GUARD) or
	P_PlayerInPain(ply) then
		return false
	end

	return true
end

--Checks if a table contains a value.
skl["tableContains"] = function(table, target)
	for key,val in pairs(table) do
		if val == target then return true end
	end

	return false
end
local tableContains = skl["tableContains"] --Required for local calls

--Checks if a flag from a value is found within a table.
skl["flagFromTable"] = function(table, baseVal)
	for key,val in pairs(table) do
		if baseVal & val then return true end
	end

	return false
end
local flagFromTable = skl["flagFromTable"] --Required for local calls

--Removes an entry from a iterative table.
--Original made by lhf on Stack Overflow (https://stackoverflow.com/a/12397742).
skl["tableRemove"] = function(table, target)
	if not(tableContains(table, target)) then return end --Target doesn't exist.

	for i=1,#table do
		if table[i] == target then table[i] = nil end
	end

	local iFix = 0
	for i=1,#table do
		if table[i] == nil then
			iFix = $+1
			table[iFix] = table[i]
		end
	end

	for i=iFix+1,#table do
		table[i] = nil
	end
end

--A little function that will try to use P_SetOrigin, and fallback to P_TeleportMove if it doesn't work; this is to keep compatibility with pre-2.2.11.
skl["setMobjPos"] = function(mobj, x, y, z)
	if pcall(P_SetOrigin, mobj, x, y, z) ~= true then
		P_TeleportMove(mobj, x, y, z)
	end
end
local setMobjPos = skl["setMobjPos"] --Required for local calls

--A little function that will try to use P_MoveOrigin, and fallback to P_TeleportMove if it doesn't work; this is to keep compatibility with pre-2.2.11.
skl["moveMobj"] = function(mobj, x, y, z)
	if pcall(P_MoveOrigin, mobj, x, y, z) ~= true then
		P_TeleportMove(mobj, x, y, z)
	end
end
local moveMobj = skl["moveMobj"] --Required for local calls

--Distance checker that checks ALL THREE AXES.
skl["distFromTwoPoints"] = function(x2, y2, z2, x1, y1, z1)
	local diffs = {
		x=abs(x1-x2),
		y=abs(y1-y2),
		z=abs(z1-z2)
	}

	return(diffs.x+diffs.y+diffs.z)
end
local distFromTwoPoints = skl["distFromTwoPoints"] --Required for local calls

skl["closestMobjFromList"] = function(origin, challengers)
	local closestDist = INT32_MAX
	local closestObj = nil

	for _,obj in ipairs(challengers) do
		local dist = distFromTwoPoints(origin.x, origin.y, origin.z, obj.x, obj.y, obj.z)
		if dist < closestDist then
			closestDist = dist
			closestObj = obj
		end
	end

	return closestObj
end

--DEPRECATED; COULDN'T GET THIS TO WORK WITHOUT BREAKING SLOPES, IF YOU CAN, POWER TO YOU.
--Try Move from Position in all Directions.
--Does what it says on the tin.
--Returns if TryMove was successful in ANY direction.
-- skl["TMfPiaD"] = function(mobj, options)
-- 	if options == nil then
-- 		options = {
-- 			dist = 1*FU,
-- 			dropoff = false,
-- 			restorePos = false,
-- 			debug = false,
-- 		}
-- 	end
-- 	if options.dist == nil then options.dist = 1*FU end
-- 	if options.dropoff == nil then options.dropoff = false end
-- 	if options.restorePos == nil then options.restorePos = false end
-- 	if options.debug == nil then options.debug = false end

-- 	local angTbl = {
-- 		0,
-- 		ANGLE_45,
-- 		ANGLE_90,
-- 		ANGLE_135,
-- 		ANGLE_180,
-- 		ANGLE_270,
-- 		ANGLE_315,
-- 		ANGLE_MAX
-- 	}

-- 	local wasOnGround = P_IsObjectOnGround(mobj)
	
-- 	local pushFailed = true
-- 	for d=1,#angTbl do
-- 		local velo = {
-- 			x=P_ReturnThrustX(nil, angTbl[d], options.dist),
-- 			y=P_ReturnThrustY(nil, angTbl[d], options.dist)
-- 		}
-- 		local lastPos = {
-- 			x=mobj.x,
-- 			y=mobj.y,
-- 			z=mobj.z
-- 		}

-- 		if options.debug then print("Trying to move mobj to x: "..tostring(mobj.x+velo.x)..", y: "..tostring(mobj.y+velo.y)) end
-- 		if P_TryMove(mobj, mobj.x+velo.x, mobj.y+velo.y, options.dropoff) then
-- 			pushFailed = false
-- 			if options.restorePos then
-- 				local newZ = lastPos.z
-- 				if wasOnGround then
-- 					if P_MobjFlip(mobj) == -1 then
-- 						newZ = mobj.ceilingz-mobj.height
-- 					else
-- 						newZ = mobj.floorz
-- 					end
					
-- 				end
				
-- 				moveMobj(mobj, lastPos.x, lastPos.y, newZ)
-- 			end
-- 			break
-- 		end
-- 	end

-- 	return not(pushFailed)
-- end

--A little function to nicely teleport a player somewhere while also making it look nice.
skl["teleportToPos"] = function(ply, x, y, z, angle, flashing)
	if angle == nil then angle = 0 end
	if flashing == nil then flashing = false end

	P_ResetPlayer(ply)
	ply.mo.state = S_PLAY_STND
	if flashing then ply.powers[pw_flashing] = flashingtics-1 end
	ply.mo.momx = 0
	ply.mo.momy = 0
	ply.mo.momz = 0
	
	setMobjPos(ply.mo, x, y, z)
	ply.mo.angle = angle
	P_FlashPal(ply, PAL_MIXUP, 10)
	S_StartSound(ply.mo, sfx_mixup)
end
local teleportToPos = skl["teleportToPos"] --Required for local calls

--A function that teleports a player to their last starpost, or to a spawn point.
skl["toStarpostOrSpawn"] = function(ply, forceSpawn)
	if forceSpawn == nil then forceSpawn = false end

	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.playerstate ~= PST_LIVE then return end --Player's dead.

	--Restore to starpost OR player spawn(s).
	if ply.starpostnum == 0 then --No star post has been set.
		--[[ OLD PLAYER COOP SPAWN FETCHER.
		local finalPosition = {x=0,y=0,z=0}
		local finalAngle = 0

		--Randomize.
		local spawns = {}
		for mobj in mapthings.iterate do
			if mobj.type > 32 then continue end
			table.insert(spawns, mobj)
		end
		local target = spawns[P_RandomRange(1, #spawns)]
		finalPosition = {x=target.x, y=target.y, z=target.z}
		finalAngle = target.angle

		teleportToPos(ply, finalPosition.x*FU, finalPosition.y*FU, finalPosition.z*FU, finalAngle, true)
		]]

		teleportToPos(ply, ply.spawnx, ply.spawny, ply.spawnz, ply.spawnangle, true)
		if ply.spawnflip then ply.mo.flags2 = $ | MF2_OBJECTFLIP else ply.mo.flags2 = $ & ~MF2_OBJECTFLIP end
		if ply.spawn2d then ply.mo.flags2 = $ | MF2_TWOD else ply.mo.flags2 = $ & ~MF2_TWOD end
	else
		teleportToPos(ply, ply.starpostx*FU, ply.starposty*FU, ply.starpostz*FU, ply.starpostangle, true)
		if ply.starpostflip then ply.mo.flags2 = $ | MF2_OBJECTFLIP else ply.mo.flags2 = $ & ~MF2_OBJECTFLIP end
		if ply.starpost2d then ply.mo.flags2 = $ | MF2_TWOD else ply.mo.flags2 = $ & ~MF2_TWOD end
	end
end

--Blockmap-traversing function that InstaThrusts (or Thrusts) with the angle from the object to the source.
--Uses some code from PIT_RadiusAttack (https://git.do.srb2.org/STJr/SRB2/-/blob/SRB2_release_2.2.15/src/p_map.c#L4156).
skl["P_BlastAway"] = function(source, options)
	if options == nil then options = {} end

	if options.targetEverything == nil then options.targetEverything = false end
	if options.targetPlayers == nil then options.targetPlayers = true end
	if options.targetEnemies == nil then options.targetEnemies = true end
	if options.targetBosses == nil then options.targetBosses = true end
	if options.targetMissiles == nil then options.targetMissiles = true end
	if options.targetMonitors == nil then options.targetMonitors = false end
	if options.targetScenery == nil then options.targetScenery = false end
	if options.targetPushables == nil then options.targetPushables = false end

	if options.instantThrust == nil then options.instantThrust = true end
	if options.radius == nil then options.radius = 250 end
	if options.sightCheck == nil then options.sightCheck = true end

	local box = {
		l=source.x-(options.radius*FU),
		r=source.x+(options.radius*FU),
		b=source.y-(options.radius*FU),
		t=source.y+(options.radius*FU),
	}
	
	searchBlockmap("objects", function(ref, mobj)
		if not options.targetEverything then
			local flagList = {}
			if options.targetEnemies then table.insert(flagList, MF_ENEMY) end
			if options.targetBosses then table.insert(flagList, MF_BOSS) end
			if options.targetMissiles then table.insert(flagList, MF_MISSILE) end
			if options.targetMonitors then table.insert(flagList, MF_MONITOR) end
			if options.targetScenery then table.insert(flagList, MF_SCENERY) end
			if options.targetPushables then table.insert(flagList, MF_PUSHABLE) end

			if not flagFromTable(flagList, mobj.flags) and (options.targetPlayers and not objectExists(mobj.player)) then return end
		end

		local diffs = {
			x=abs(mobj.x-ref.x),
			y=abs(mobj.y-ref.y),
			z=abs((mobj.z+mobj.height)-ref.z)
		}
		local dist = P_AproxDistance(P_AproxDistance(diffs.x, diffs.y), diffs.z)
		dist = $-mobj.radius

		if dist < 0 then dist = 0 end --"dist" CANNOT be less than 0.
		if dist >= options.radius*FU then return end
		if mobj.floorz > ref.z and ref.ceilingz < mobj.z then return end
		if mobj.ceilingz < ref.z and ref.floorz > mobj.z then return end

		if options.sightCheck and not P_CheckSight(mobj, ref) then return end

		local angle = R_PointToAngle2(ref.x, ref.y, mobj.x, mobj.y)
		P_InstaThrust(mobj, angle, 32*FU)
		mobj.momz = 15*FU
	end, source, box.l, box.r, box.b, box.t)
end

skl["gotHit"] = function(ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
	if ply.skeleton == nil then return end --Can't do anything yet.
	if ply.playerstate ~= PST_LIVE then return end --Player's dead.

	local skel = ply.skeleton

	skel.compat.gotHit = true
	skel.compat.gotHitOnTic = leveltime
end