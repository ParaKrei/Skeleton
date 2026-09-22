--[[
	Recreation of id Tech 2/id Tech 3/Source Engine physics in SRB2!
	Inspired by zweek's video over airstrafing (https://www.youtube.com/watch?v=gRqoXy-0d84)
	and Cobaltn't's Quake physics mod (https://mb.srb2.org/addons/quake-physics.5018/).
	This code is a translation of Quake's own code, which can be found here: (https://github.com/id-Software/Quake/blob/master/WinQuake/sv_user.c).

	Made by ParaKrei.
]]

local debug = false --DON'T FORGET TO SET THIS TO FALSE ON RELEASE!

--Just a clamp function, can be found everywhere at this point.
--Based off of pgimeno's version on the LÖVE board.
--(https://love2d.org/forums/viewtopic.php?t=1856 on page 2)
local function clamp(val, minVal, maxVal)
	return(max(minVal, min(maxVal, val)))
end

--Helper function to return if an object is NOT nil and valid.
local function objectExists(obj)
	if obj ~= nil and obj.valid then
		return true
	end

	return false
end

--Helper function to convert decimals to SRB2's fixed format.
--Thank you Clairebun! (https://wiki.srb2.org/wiki/User:Clairebun/Sandbox/Common_Lua_Functions)
local function L_DecimalFixed(str)
	if str == nil return nil end
	local dec_offset = string.find(str,'%.')
	if dec_offset == nil
		return (tonumber(str) or 0)*FRACUNIT
	end
	local whole = tonumber(string.sub(str,0,dec_offset-1)) or 0
	local decstr = string.sub(str,dec_offset+1)
	local decimal = tonumber(decstr) or 0

	if(decimal==0)
		decstr = "0"
	end

	whole = $ * FRACUNIT
	local dec_len = string.len(decstr)
	decimal = $ * FRACUNIT / (10^dec_len)
	return whole + decimal
end

local function DotProduct(v1, v2)
	local result = FixedMul(v1[1],v2[1])+FixedMul(v1[2],v2[2])
	if v1[3] ~= nil and v2[3] ~= nil then result = FixedMul(v1[1],v2[1])+FixedMul(v1[2],v2[2])+FixedMul(v1[3],v2[3]) end

	return(result)
end

local function VectorScale(vector, scale)
	local result = {vector[1]*scale, vector[2]*scale}
	if vector[3] ~= nil then result = {vector[1]*scale, vector[2]*scale, vector[3]*scale} end

	return(result)
end
local function VectorDivide(vector, scale)
	local result = {vector[1]/scale, vector[2]/scale}
	if vector[3] ~= nil then result = {vector[1]/scale, vector[2]/scale, vector[3]/scale} end

	return(result)
end
local function VectorSubtract(v1, v2)
	local result = {v1[1]-v2[1], v1[2]-v2[2]}
	if v1[3] ~= nil and v2[3] ~= nil then result = {v1[1]-v2[1], v1[2]-v2[2], v1[3]-v2[3]} end

	return(result)
end

local function MassFixedMul(values)
	local curValue = nil
	for _,num in ipairs(values) do
		if curValue ~= nil then
			curValue = FixedMul($, num)
		else
			curValue = num
		end
	end

	return curValue
end

local function VectorNormalize(vector)
	if vector[3] ~= nil then
		--Calculate length of vector and square root it.
		local newVector = {vector[1],vector[2],vector[3]}
		local length = FixedMul(vector[1], vector[1])+FixedMul(vector[2], vector[2])+FixedMul(vector[3], vector[3])
		length = FixedSqrt($)

		--Normalize the vector.
		if length then
			local normalizer = FixedDiv(1*FU, length);
			newVector[1] = FixedMul($,normalizer)
			newVector[2] = FixedMul($,normalizer)
			newVector[3] = FixedMul($,normalizer)
		end

		return length, newVector
	else
		--Calculate length of vector and square root it.
		local newVector = {vector[1],vector[2]}
		local length = FixedMul(vector[1], vector[1])+FixedMul(vector[2], vector[2])
		length = FixedSqrt($)

		--Normalize the vector.
		if length then
			local normalizer = FixedDiv(1*FU, length);
			newVector[1] = FixedMul($,normalizer)
			newVector[2] = FixedMul($,normalizer)
		end

		return length, newVector
	end
end

--(https://stackoverflow.com/questions/39776819/function-to-normalize-any-number-from-0-1)
local function normalize(num, minimum, maximum)
	if num == nil or minimum == nil or maximum == nil then return -1 end
	return max(0, min(1, (num-minimum)/(maximum-minimum)))
end

local function ApplyWaterSlow(ply)
	local phys = ply.idPhys

	if ply.mo.eflags & MFE_UNDERWATER then
		if not(phys.wasInWater) then
			phys.lasts.accelerate = phys.accelerate
			phys.lasts.maxspeed = phys.maxspeed
			phys.lasts.wishspeedcap = phys.wishspeedcap

			phys.accelerate = 2*$/3
			phys.maxspeed = $/2
			phys.wishspeedcap = $/2

			phys.wasInWater = true
		end
	else
		if phys.wasInWater then
			phys.accelerate = phys.lasts.accelerate
			phys.maxspeed = phys.lasts.maxspeed
			phys.wishspeedcap = phys.lasts.wishspeedcap

			phys.wasInWater = false
		end
	end
end

local function SV_AirAccelerate(ply)
	local phys = ply.idPhys

	local wishSpeed, newWishVelo = VectorNormalize(phys.wishVelocity)
	phys.wishVelocity = newWishVelo
	if wishSpeed > phys.wishspeedcap then wishSpeed = phys.wishspeedcap end
	local currentSpeed = DotProduct({ply.rmomx, ply.rmomy}, phys.wishVelocity)
	local addedSpeed = phys.wishSpeed - currentSpeed
	if addedSpeed <= 0 then return end
	local accelSpeed = MassFixedMul({phys.accelerate, ply.idPhys.ticTime, phys.wishSpeed})
	if accelSpeed > addedSpeed then accelSpeed = addedSpeed end

	accelSpeed = $/2 --Reduce air speed, as it's a bit much.

	ply.mo.momx = $+FixedMul(accelSpeed, phys.wishVelocity[1])
	ply.mo.momy = $+FixedMul(accelSpeed, phys.wishVelocity[2])
end

local function SV_Accelerate(ply)
	local phys = ply.idPhys

	local currentSpeed = DotProduct({ply.rmomx, ply.rmomy}, phys.wishDir)
	local addedSpeed = phys.wishSpeed - currentSpeed
	if addedSpeed <= 0 then return end
	local accelSpeed = MassFixedMul({phys.accelerate, ply.idPhys.ticTime, phys.wishSpeed})
	if accelSpeed > addedSpeed then accelSpeed = addedSpeed end

	ply.mo.momx = $+FixedMul(accelSpeed, phys.wishDir[1])
	ply.mo.momy = $+FixedMul(accelSpeed, phys.wishDir[2])
end

local function SV_AirMove(ply)
	local phys = ply.idPhys

	if ply.powers[pw_carry] ~= CR_NONE then return end --Don't do anything if the player is being carried.

	--rmom isn't properly set anymore, so I gotta do it myself!
	ply.rmomx = ply.mo.momx-ply.cmomx
	ply.rmomy = ply.mo.momy-ply.cmomy
	if (ply.mo.flags2 & MF2_TWOD) or twodlevel then
		ply.speed = abs(ply.rmomx)
	else
		ply.speed = P_AproxDistance(ply.rmomx, ply.rmomy)
	end

	local fmove = ply.cmd.forwardmove*FU
	local smove = ply.cmd.sidemove*-FU

	if ply.pflags & PF_STARTDASH or P_PlayerInPain(ply) or ply.pflags & PF_STASIS or ply.playerstate ~= PST_LIVE then
		fmove = 0; smove = 0
	end

	local speedUp = ply.powers[pw_super] or ply.powers[pw_sneakers]

	--Dash mode, Super, and Super Sneakers implementation.
	if ply.dashmode < 3*TICRATE then
		if phys.lastdashmode >= 3*TICRATE then
			if not speedUp then
				phys.accelerate = phys.defaults.accelerate
				phys.maxspeed = phys.defaults.maxspeed
			else
				phys.accelerate = phys.defaults.accelerate+(phys.defaults.accelerate/3)
				phys.maxspeed = (phys.defaults.maxspeed/2)+(phys.defaults.accelerate/2)
			end
		else
			if not speedUp then
				phys.accelerate = phys.defaults.accelerate
				phys.maxspeed = phys.defaults.maxspeed
			else
				phys.accelerate = phys.defaults.accelerate+(phys.defaults.accelerate/3)
				phys.maxspeed = (phys.defaults.maxspeed/2)+(phys.defaults.accelerate/2)
			end
		end
	elseif (P_IsObjectOnGround(ply.mo) and ply.dashmode >= 3*TICRATE)
	and ply.normalspeed < skins[ply.skin].normalspeed*2 then
		phys.accelerate = $+(FU/5)
		if not speedUp then
			phys.maxspeed = (skins[ply.mo.skin].accelstart*FU)+(skins[ply.mo.skin].normalspeed*2)
		else
			phys.maxspeed = $+((skins[ply.mo.skin].accelstart*FU)+(skins[ply.mo.skin].normalspeed*2))
		end
	end

	ApplyWaterSlow(ply)

	phys.wishMove = FixedHypot(fmove, smove)
	phys.wishAngle = R_PointToAngle2(0, 0, fmove, smove) + ply.mo.angle

	if (ply.mo.flags2 & MF2_TWOD) or twodlevel then
		if smove < 0 then
			phys.wishAngle = 0
		elseif smove > 0 then
			phys.wishAngle = ANGLE_180
		end

		phys.wishMove = abs(smove)
	end

	phys.wishVelocity = {
		P_ReturnThrustX(nil, phys.wishAngle, phys.accelerate*normalize(phys.wishMove, -FU, FU)),
		P_ReturnThrustY(nil, phys.wishAngle, phys.accelerate*normalize(phys.wishMove, -FU, FU))
	}

	if ply.pflags & PF_SPINNING and P_IsObjectOnGround(ply.mo) then
		if FixedMul(ply.rmomx, ply.rmomx)+FixedMul(ply.rmomy, ply.rmomy) < 64*FU then
			phys.wishVelocity = VectorDivide(phys.wishVelocity, 10)
		else
			phys.wishVelocity = VectorDivide(phys.wishVelocity, 5)
		end
	end

	phys.wishDir = {phys.wishVelocity[1], phys.wishVelocity[2]}
	phys.wishSpeed, phys.wishDir = VectorNormalize(phys.wishDir)
	if phys.wishSpeed > phys.maxspeed then
		phys.wishVelocity = VectorScale(phys.wishVelocity, FixedDiv(phys.maxspeed, phys.wishSpeed))
	end
	
	if P_IsObjectOnGround(ply.mo) then
		SV_Accelerate(ply)
	else
		SV_AirAccelerate(ply)
	end
end

rawset(_G, "idTechThinker", function(ply)
	if not(objectExists(ply)) or not(objectExists(ply.mo)) then return end
	
	ply.idPhys.ticTime = FixedDiv((leveltime+1)-ply.idPhys.lastTic, 1000)
	--Clamp the value into a range, just like the original game.
	ply.idPhys.ticTime = clamp($, L_DecimalFixed("0.001"), L_DecimalFixed("0.1"))

	if ply.thrustfactor ~= 0 then ply.thrustfactor = 0 end --FORCE thrustfactor to zero always.
	
	if ply.powers[pw_carry] == CR_NONE then SV_AirMove(ply) end

	ply.idPhys.lastTic = leveltime
	ply.idPhys.lastdashmode = ply.dashmode
end)

rawset(_G, "idTechSpawn", function(ply)
	if not(objectExists(ply)) or not(objectExists(ply.mo)) then return end

	if ply.idPhys == nil then
		ply.idPhys = {
			accelerate = 1*FU, --Acceleration speed.
			maxspeed = 1*FU, --Max speed the player can go.
			wishspeedcap = 30*FU, --Cap for AirAccel's wishspeed.
			wishVelocity = {0, 0}, --Where the player WANTS to move.
			wishDir = {0, 0, 0}, --Copy of wishVelocity.
			wishSpeed = 0, --How fast the player WANTS to move.
			wishAngle = 0, --The angle the player WANTS to move towards.
			lastTic = 0, --The last saved time.
			ticTime = 0, --How long it took for a frame.
			lastdashmode = 0, --Self-explanatory.
			dashmodeadd = 0, --Self-explanatory.
			wasInWater = false, --Self-explanatory.
			defaults = { --Storing defaults to more reliably slow down/speed up later.
				accelerate = 1*FU,
				maxspeed = 1*FU,
				wishspeedcap = 30*FU,
			},
			lasts = { --Storing pre-modified variables for more reliablity.
				accelerate = 1*FU,
				maxspeed = 1*FU,
				wishspeedcap = 30*FU,
			}
		}
	end

	local plySkin = skins[ply.mo.skin]

	ply.idPhys.maxspeed = plySkin.normalspeed*10
	ply.idPhys.accelerate = plySkin.acceleration*FU
	ply.idPhys.defaults.maxspeed = ply.idPhys.maxspeed
	ply.idPhys.defaults.accelerate = ply.idPhys.accelerate
	ply.idPhys.lasts.maxspeed = ply.idPhys.maxspeed
	ply.idPhys.lasts.accelerate = ply.idPhys.accelerate
	ply.idPhys.lastTic = 0
	ply.idPhys.wasInWater = false
	ply.thrustfactor = 0
end)

--DEBUG STUFF--
if debug then
	addHook("MobjMoveBlocked", function(moving, mobj, line)
		if mobj ~= nil then
			if mobj ~= moving.lastHitMobj then print("BONK! Hit mobj at "..tostring(leveltime)..".") end
		elseif line ~= nil then
			if line ~= moving.lastHitLine then print("BONK! Hit line at "..tostring(leveltime)..".") end
		end

		if mobj ~= nil then moving.lastHitMobj = mobj end
		if line ~= nil then moving.lastHitLine = line end
	end, MT_PLAYER)

	--Helper function to quickly draw a list on the HUD.
	local function multilineDrawString(v, x, y, strings, flags, align)
		if v == nil then return end

		if strings == nil or type(strings) ~= "table" then strings = {""} end

		if x == nil or type(x) ~= "number" then x = 0 end
		if y == nil or type(y) ~= "number" then y = 0 end
		
		local offset = 12
		for i,str in pairs(strings) do
			v.drawString(x, (y-offset)+(offset*i), str, flags, align)
		end
	end

	hud.add(function(v, ply, cam)
		local phys = ply.idPhys
		local plySkin = skins[ply.mo.skin]

		multilineDrawString(v, 16, 50, {
			"position: x="..tostring(ply.mo.x)..", y="..tostring(ply.mo.y)..", z="..tostring(ply.mo.z),
			"mom.xy: "..tostring(ply.mo.momx)..", "..tostring(ply.mo.momy),
			"mom.xy-cmom: "..tostring(ply.mo.momx-ply.cmomx)..", "..tostring(ply.mo.momx-ply.cmomy),
			"rmom: "..tostring(ply.rmomx)..", "..tostring(ply.rmomy),
			"speed: "..tostring(ply.speed),
			"momz: "..tostring(ply.mo.momz),
			"IsOnGround: "..tostring(P_IsObjectOnGround(ply.mo)),
			"movefactor: "..tostring(ply.mo.movefactor),
			"IsInZoomTube: "..tostring(ply.powers[pw_carry] & CR_ZOOMTUBE ~= 0)
		}, V_SNAPTOLEFT, "thin")

		multilineDrawString(v, 320-16, 50, {
			"maxspeed: "..tostring(phys.maxspeed),
			"accelerate: "..tostring(phys.accelerate),
			"ticTime: "..tostring(phys.ticTime),
			"wishDir: "..tostring(phys.wishDir[1])..", "..tostring(phys.wishDir[2]),
			"wishSpeed: "..tostring(phys.wishSpeed),
			"wishVelocity: "..tostring(phys.wishVelocity[1])..", "..tostring(phys.wishVelocity[2]),
			"wishMove: "..tostring(phys.wishMove),
			"wishAngle: "..tostring(phys.wishAngle),
			"wasInWater: "..tostring(phys.wasInWater)
		}, V_SNAPTORIGHT, "thin-right")
	end, "game")
end