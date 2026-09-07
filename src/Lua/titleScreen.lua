--[[
	The title screen lives here.
]]
--The default titlemap is MAP99.

freeslot("SPR_SPLT") --Splash text

--Since MOST of this code only runs on the titlescreen, a singleplayer-only thing, we can get away with local variables.
--The only time we need netsync is when we want to mess with the player when they are playing in the titlemap.
local scalePulse = 1
local scaleAdd = 1
local scaleBase = 20
local alpha = 9
local timeStarted = -1

--A little function to quickly check and return the state of the titlescreen.
--This can be local no matter what, since it just checks global variables that are ALWAYS netsynced.
local function G_TitlescreenCheck()
	local onTitleScreen = false
	local isInTitlemap = false

	if gamestate == GS_NULL or gamestate == GS_TITLESCREEN then --Check if the state is game load or the titlescreen state
		print("If this shows up, please let ParaKrei (me) know what map this! As far as I'm aware, this is a legacy thing!")
	elseif gamestate == GS_LEVEL then
		onTitleScreen = titlemapinaction
		isInTitlemap = gamemap == titlemap
	end

	return onTitleScreen, isInTitlemap
end

--Initalize variables in MapLoad to avoid relying on P_PreTicker for compatibility with 2.3.--
addHook("MapLoad", function()
	local titleState,isOnMap = G_TitlescreenCheck()

	if titleState then
		scalePulse = scaleBase
		scaleAdd = 1
		alpha = 9
		timeStarted = leveltime
	end
end)

--The HUD drawer.--
addHook("HUD", function(v, cam, ply)
	--Since this variable should never be -1 if we started with the titlescreen, that means we loaded later.
	--So, to ensure that nothing breaks, we have to set the scaling variables here.
	if timeStarted == -1 then
		scalePulse = scaleBase
		scaleAdd = 1
		timeStarted = leveltime
	end

	local graphic,_ = v.getSpritePatch(SPR_SPLT, 0, 0, ANG30)

	if timeStarted > 0 then
		v.drawScaled(250*FU, 150*FU, (FU/5)+(FU/scalePulse), graphic)

		scalePulse = $+scaleAdd
		if scalePulse >= scaleBase+5 or scalePulse <= scaleBase-5 then scaleAdd = $*-1 end
	else
		if leveltime >= 34 then
			if alpha == 1 then alpha = 0 end
			local flags = alpha<<V_ALPHASHIFT
			if alpha == 0 then flags = 0 end

			v.drawScaled(250*FU, 150*FU, (FU/5)+(FU/scalePulse), graphic, flags)

			scalePulse = $+scaleAdd
			if scalePulse >= scaleBase+5 or scalePulse <= scaleBase-5 then scaleAdd = $*-1 end
			if alpha > 1 and alpha ~= 0 then alpha = $-1 end
		end
	end
end, "title")