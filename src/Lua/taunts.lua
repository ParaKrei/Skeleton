--[[
	Taunts live here.
]]

freeslot("sfx_sklpt") --Pizza Tower's taunt sound.
sfxinfo[sfx_sklpt].singular = true
sfxinfo[sfx_sklpt].caption = "" --I don't know what to put here.

freeslot("sfx_sklbb") --The (now infamous) "Bad to the Bone" riff, taken straight from the source.
sfxinfo[sfx_sklbb].singular = true
sfxinfo[sfx_sklbb].caption = "Bad to the Bone"

freeslot("SPR2_TNT1") --Taunt 1
freeslot("S_SKEL_TAUNT1") --Taunt 1 state
states[S_SKEL_TAUNT1] = {
	sprite = SPR_PLAY,
	frame = SPR2_TNT1,
	tics = 3,
	nextstate = S_PLAY_STND --Just in case.
}
freeslot("SPR2_TNT2") --Taunt 2
freeslot("S_SKEL_TAUNT2") --Taunt 2 state
states[S_SKEL_TAUNT2] = {
	sprite = SPR_PLAY,
	frame = SPR2_TNT2,
	tics = 75,
	nextstate = S_PLAY_STND --Just in case.
}
freeslot("SPR2_TNT3") --Taunt 3
freeslot("S_SKEL_TAUNT3") --Taunt 3 state
states[S_SKEL_TAUNT3] = {
	sprite = SPR_PLAY,
	frame = SPR2_TNT3|FF_ANIMATE,
	var1 = 4-1,
	var2 = 2,
	tics = ((4-1)+11)*2,
	nextstate = S_PLAY_STND --Just in case.
}

--Quick little function to stop taunts.
local function stopAllTaunts(ply, endState)
	if endState == nil then endState = false end

	local skel = ply.skeleton

	--Stop other taunt sounds.
	S_StopSoundByID(ply.mo, sfx_sklpt)
	S_StopSoundByID(ply.mo, sfx_sklbb)

	if endState then ply.mo.tics = 1 end
	skel.taunts.active = false
	skel.taunts.state = S_PLAY_STND
	skel.taunts.lastTic = 0
	skel.taunts.lastFrame = 0
end

--Input handler/taunt randomizer.
addHook("PlayerThink", function(ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
	if ply.skeleton == nil then return end --Can't do anything yet.
	if ply.playerstate ~= PST_LIVE then return end --Player's dead.

	local skel = ply.skeleton

	--Don't even try to taunt if the player is falling apart OR is being carried OR is in pain.
	if ply.mo.state == S_SKEL_BREAK or ply.powers[pw_carry] ~= CR_NONE or P_PlayerInPain(ply) then
		if skel.taunts.active then stopAllTaunts(ply) end
		return
	end

	--Roll for a random taunt.
	if ply.cmd.buttons & BT_TOSSFLAG and not(ply.lastbuttons & BT_TOSSFLAG) then
		--Stop other taunt sounds.
		S_StopSoundByID(ply.mo, sfx_sklpt)
		S_StopSoundByID(ply.mo, sfx_sklbb)

		local roll = P_RandomRange(1,3)

		skl.switch(roll)
			.case(1, function()
				ply.mo.state = S_SKEL_TAUNT1
			end)
			.case(2, function()
				ply.mo.state = S_SKEL_TAUNT2
			end)
			.case(3, function()
				ply.mo.state = S_SKEL_TAUNT3
			end)
		.process()
		skel.taunts.state = ply.mo.state
		skel.taunts.lastTic = 0
		skel.taunts.lastFrame = 0

		skel.taunts.active = true
	end

	local buttonCheck = {
		jump=ply.cmd.buttons & BT_JUMP ~= ply.lastbuttons & BT_JUMP,
		spin=ply.cmd.buttons & BT_SPIN ~= ply.lastbuttons & BT_SPIN
	}
	--Stop the taunt from interrupting when the player lets go of spin when they where previously crouching.
	if ply.lastbuttons & BT_SPIN then buttonCheck.spin = false end

	--If the player does anything RELATED TO MOVEMENT, then interrupt the taunt.
	if (ply.mo.state == S_SKEL_TAUNT1 or ply.mo.state == S_SKEL_TAUNT2 or ply.mo.state == S_SKEL_TAUNT3)
	and (buttonCheck.jump or buttonCheck.spin or ply.cmd.forwardmove or ply.cmd.sidemove) then
		stopAllTaunts(ply, true)
	end
end)

--Taunt handler.
addHook("PreThinkFrame", function()
	for ply in players.iterate() do
		if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then continue end --Don't do anything if the player or it's mobj doesn't exist.
		if ply.skeleton == nil then continue end --Can't do anything yet.

		local skel = ply.skeleton

		--Don't even try to taunt if the player is falling apart OR is being carried OR is in pain.
		if ply.mo.state == S_SKEL_BREAK or ply.powers[pw_carry] ~= CR_NONE or P_PlayerInPain(ply) then
			if skel.taunts.active then stopAllTaunts(ply) end
			continue
		end

		--If at ANY point the Skeleton is forced out of the taunt states, except for a few cases, force the state back.
		if not P_PlayerInPain(ply) and ply.exiting <= 0 then
			if skel.taunts.active and ply.mo.state ~= skel.taunts.state then
				ply.mo.state = skel.taunts.state
				ply.mo.tics = skel.taunts.lastTic
				ply.mo.frame = skel.taunts.lastFrame
			end
		end

		skl.switch(ply.mo.state)
			.case(S_SKEL_TAUNT1, function()
				--nothing
			end)
			.case(S_SKEL_TAUNT2, function()
				if ply.mo.tics == states[S_SKEL_TAUNT2].tics-1 then
					S_StartSound(ply.mo, sfx_sklbb)
				end
			end)
			.case(S_SKEL_TAUNT3, function()
				if ply.mo.tics == states[S_SKEL_TAUNT3].tics-1 then
					S_StartSound(ply.mo, sfx_sklpt)
				end

				if ply.mo.frame == 3|FF_ANIMATE then
					ply.mo.frame = 3
				end
			end)
			.default(function() end) --do nothing
		.process()

		if ply.mo.state == S_SKEL_TAUNT1 or ply.mo.state == S_SKEL_TAUNT2 or ply.mo.state == S_SKEL_TAUNT3 then
			skel.taunts.lastTic = ply.mo.tics
			skel.taunts.lastFrame = ply.mo.frame

			if ply.mo.tics == 1 then
				skel.taunts.active = false
				skel.taunts.state = S_PLAY_STND
				skel.taunts.lastTic = 0
				skel.taunts.lastFrame = 0
			end
		end
	end
end)