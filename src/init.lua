--[[
Skeleton; created by ParaKrei and JimSquid.

Mod started on January 28, 2026, completed on September 6, 2026.

Some functions are from Metroid Vanguard (Samus).
]]

--Create global object to hold everything--
rawset(_G, "skl", {})

--Compatibility function table--
if skl["compat"] == nil then
	skl["compat"] = {}
end
--Linedef tracker table--
if skl["linedefs"] == nil then
	skl["linedefs"] = {}
end
--Boss tracker table--
if skl["bosses"] == nil then
	skl["bosses"] = {}
end
--Hug animation table--
if skl["hug"] == nil then
	skl["hug"] = {}
end
--Misc net table--
if skl["misc"] == nil then
	skl["misc"] = {
		instakillBoss = false,
		startedBossKiller = false,
		finishedBossKiller = false,
		triggerInvert = false,
		triggeredOnTic = -1,
		laughLength = TICRATE*3,
		chanceRolled = false,
		skelPlayers = {},
		skelAlreadyExisted = false,
	}
end
--Explosion timing tables--
if skl["expTbl"] == nil then
	skl["expTbl"] = {
		10+1,16+1,16+1,
		4+1,4+1,4+1,4+1,
		2+1,2+1,2+1,2+1,2+1
	}
end
if skl["c4Tbl"] == nil then
	skl["c4Tbl"] = {
		10+1,16+1,16+1,16+1,16+1,16+1,
		2+1,2+1,2+1,2+1,2+1
	}
end

skl.DMG_SKLDTH = DMG_DEATHMASK+6

--Custom animations.
freeslot("SPR2_BREK") --"Death" animation
freeslot("S_SKEL_BREAK") --"Death" state
states[S_SKEL_BREAK] = {
	sprite = SPR_PLAY,
	frame = SPR2_BREK,
	tics = -1,
	nextstate = S_PLAY_STND --Just in case.
}

--New object definitions.
freeslot("SPR_SKEX") --Explosion graphic
freeslot("S_SKELEXPLODE") --Explosion state
states[S_SKELEXPLODE] = {
	sprite = SPR_SKEX,
	frame = FF_FULLBRIGHT|FF_ANIMATE,
	var1 = 9-1, --Frame count-1
	var2 = 2, --Tics per frame
	tics = 8*2, --var1*var2
	nextstate = S_NULL
}
freeslot("MT_SKELEXPLODE") --Explosion object
mobjinfo[MT_SKELEXPLODE] = {
	doomednum = -1,
	spawnstate = S_SKELEXPLODE,
	radius = 32*FU,
	height = 32*FU,
	spawnhealth = 1000,
	reactiontime = 8,
	mass = 4,
	flags = MF_SCENERY|MF_NOBLOCKMAP|MF_NOCLIP|MF_NOGRAVITY|MF_NOCLIPHEIGHT
}

--Network syncs--
addHook("NetVars", function(net)
	skl.linedefs = net(skl.linedefs)
	skl.bosses = net(skl.bosses)
	skl.misc = net(skl.misc)
	skl.hug = net(skl.hug)
end)

--(https://youtu.be/ou7GZDeOp3g) [Don't worry, this is NOT a rick-roll; it's one of the sources of inspiration for this mod.]--
--Sounds--
freeslot("sfx_skfla") --Lego death sound [fallapart4] (From Lego Star Wars: The Skywalkers Saga; ripped by iteachvader) [https://sounds.spriters-resource.com/pc_computer/legostarwarstheskywalkersaga/asset/438593/]
sfxinfo[sfx_skfla].caption = "I'm falling apart!"
freeslot("sfx_skrfm") --Lego building sound [form1-3] (From Lego Star Wars: The Skywalkers Saga; ripped by iteachvader) [https://sounds.spriters-resource.com/pc_computer/legostarwarstheskywalkersaga/asset/438593/]
sfxinfo[sfx_skrfm].caption = "YOU CANNOT KILL ME."

--Misc. functions--
dofile("misc.lua")
dofile("samusStuff.lua")
dofile("lib/L_idTechPhysics-v1.lua")

--Main stuff--
dofile("main.lua")
dofile("bossKiller.lua")
dofile("stuckPlayerFixer.lua")

--Funny gibs--
dofile("gibs.lua")

--Taunts--
dofile("taunts.lua")

--Eggrobo stuff--
dofile("eggrobo.lua")

--Console commands + cvars--
dofile("console.lua")

--HUD handler--
dofile("hud.lua")

--Title screen handler--
dofile("titleScreen.lua")

--Compatibility stuff--
dofile("compat.lua")
