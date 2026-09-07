--[[
EVERYTHING in here is pulled from Metroid Vanguard.

Thank you SO MUCH Golden Shine! Your work is legendary!
]]

--YEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEES--
local function FuckMinecarts(collided, collider)
	if skl.objectExists(collider)
	and collider.type == MT_PLAYER and skl.objectExists(collider.player)
	and collider.skin == "skeleton" and collider.player.skeleton ~= nil then
		if (collided.z > collider.z+80<<16)
		or (collider.z > collided.z+80<<16)
		or (collided.flags & MF_NOCLIP) then
			return false
		end

		S_StartSoundAtVolume(collided, sfx_s1b9, 128)

		for d=0,12 do
			local debris = P_SpawnMobj(
			collided.x+(P_RandomRange(-50,50)*collided.scale),
			collided.y+(P_RandomRange(-50,50)*collided.scale),
			collided.z+(P_RandomRange(5,80)*collided.scale),
			MT_WOODDEBRIS)

			if debris and debris.valid then
				debris.flags = $|MF_BOUNCE|MF_GRENADEBOUNCE|MF_NOCLIPTHING
				P_InstaThrust(debris, collider.angle+(P_RandomRange(-20,20)*ANG1), 27<<16)
				P_SetObjectMomZ(debris, P_RandomRange(-4,11)<<16, false)
			end
		end

		collided.flags = $|MF_NOCLIP
		if (collided.type == MT_SALOONDOOR) then
			P_KillMobj(collided, collider, collider)
		end
		P_AddPlayerScore(collider.player, 50)

		return true
	end
end
for i=1,2 do
	addHook("MobjCollide", FuckMinecarts, (i==1 and MT_SALOONDOORCENTER) or MT_SALOONDOOR)
	addHook("MobjMoveCollide", FuckMinecarts, (i==1 and MT_SALOONDOORCENTER) or MT_SALOONDOOR)
end