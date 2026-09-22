--[[
	The gib code lives here.
]]

freeslot("SPR_SKGB") --Bone gib sprite
freeslot("S_SKELGIB") --Bone gib state
states[S_SKELGIB] = {
	sprite = SPR_SKGB,
	frame = 0,
	nextstate = S_NULL
}
freeslot("MT_SKELGIB") --Bone gib object
mobjinfo[MT_SKELGIB] = {
	doomednum = -1,
	spawnstate = S_SKELGIB,
	radius = 16*FU,
	height = 16*FU,
	flags = MF_BOUNCE
}

--Just replicating a thrown bounce ring's behavior.
--(https://git.do.srb2.org/STJr/SRB2/-/blob/SRB2_release_2.2.15/src/p_mobj.c#L2286)
addHook("MobjThinker", function(gib)
	if gib.eflags & MFE_JUSTHITFLOOR then
		gib.momz = gib.lastmomz
	else
		gib.spriteroll = $+gib.spinamt
	end

	if gib.flags & MF_BOUNCE and (gib.z <= gib.floorz or gib.z+gib.height >= gib.ceilingz) then
		gib.momz = -FixedDiv($, FU+(FU/2))
		gib.z = $+gib.momz
		gib.spinamt = FixedDiv($, FU+(FU/2))
	end

	gib.lastmomz = gib.momz
end, MT_SKELGIB)

--Ring graphic replacer.
addHook("MobjThinker", function(ring)
	if skl.objectExists(ring.target) and skl.objectExists(ring.target.player) then
		local ply = ring.target.player

		if ply.mo.skin == "skeleton" then
			if ring.sprite ~= SPR_SKGB then
				ring.sprite = SPR_SKGB
				ring.frame = 0
				ring.color = ply.mo.color
				ring.spinamt = FixedAngle(P_SignedRandom()*FU)
			end

			if abs(ring.spinamt) >= FU then
				if ring.eflags & MFE_JUSTHITFLOOR then
					ring.spinamt = FixedDiv($, FU+(FU/2))
				else
					ring.spriteroll = $+ring.spinamt
				end
			end
		end
	end
end, MT_FLINGRING)