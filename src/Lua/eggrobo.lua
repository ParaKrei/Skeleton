--[[
	The unique Eggrobo code lives here, mainly to clean up the main Lua file.
]]

--Do a funny spin.--
addHook("MobjThinker", function(eggrobo)
	if eggrobo.launched then
		eggrobo.spriteroll = $+ANGLE_90

		if #skl.expTbl == eggrobo.expIter then
			P_KillMobj(eggrobo, eggrobo, eggrobo.target) --die.
		elseif leveltime == eggrobo.expTimer+skl.expTbl[eggrobo.expIter] then
			eggrobo.resetTic = (eggrobo.expTimer+skl.expTbl[eggrobo.expIter])+1
			eggrobo.expIter = $+1
			eggrobo.expTimer = leveltime
			
			S_StartSound(eggrobo, sfx_s3k89)
			eggrobo.translation = "AllWhite"
			eggrobo.colorized = true
			eggrobo.renderflags = $|RF_FULLBRIGHT
		elseif leveltime == eggrobo.resetTic then
			eggrobo.translation = nil
			eggrobo.colorized = false
			eggrobo.renderflags = $ & ~RF_FULLBRIGHT
		end
	end
end, MT_EGGROBO1)

--Replicate the TNT barrel's combo system.--
addHook("MobjCollide", function(eggrobo, proj)
	if eggrobo == proj then return end
	if proj.type == MT_EGGROBO1 and proj.launched then
		S_StartSound(eggrobo, sfx_bowl)
		P_KillMobj(eggrobo, proj, proj.target) --Collateral damage.

		return true
	end
end, MT_EGGROBO1)

--Die when being blocked by any other entity except for the killer and other Eggrobos.--
addHook("MobjMoveBlocked", function(eggrobo, mobj, line)
	if eggrobo.launched then
		if (skl.objectExists(mobj) and (mobj ~= eggrobo.target and mobj.type ~= MT_EGGROBO1))
		or skl.objectExists(line) then
			P_KillMobj(eggrobo, eggrobo.target, eggrobo.target) --Die upon contact.
		end
	end
end, MT_EGGROBO1)

--Eggrobo death (as it doesn't have one).--
addHook("MobjDeath", function(target, cause, src, dmgtype)
	local explosion = P_SpawnMobjFromMobj(target, 0, 0, 0, MT_SKELEXPLODE)
	explosion.scale = $*3
	explosion.destscale = $*2
	explosion.anim_duration = 1

	local dust = P_SpawnMobjFromMobj(target, 0, 0, 0, MT_TNTDUST)
	dust.scale = $*2
	dust.destscale = $*4

	P_StartQuake(9*FU, TICRATE/6, {x=target.x, y=target.y, z=target.z}, 512*FU)
	S_StartSound(target, sfx_bebomb)

	P_RemoveMobj(target)
end, MT_EGGROBO1)

--YOU FOOLISH MACHINE! I AM IMMUNE TO YOUR "HOME-RUNS"!--
addHook("TouchSpecial", function(eggrobo, victim)
	if victim.type == MT_PLAYER and victim.skin == "skeleton" then
		if not(eggrobo.launched) then
			eggrobo.launched = true
			eggrobo.expTimer = leveltime
			eggrobo.expIter = 1
			eggrobo.resetTic = 0
			eggrobo.target = victim
			P_InstaThrust(eggrobo, victim.angle, 500*FU)
			S_StartSound(victim, sfx_bedeen)
		end

		return true
	end
end, MT_EGGROBO1)