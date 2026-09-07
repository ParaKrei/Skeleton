--[[
	All HUD-related stuff lives here.
]]

addHook("HUD", function(v, ply)
	if not(skl.objectExists(ply)) or not(skl.objectExists(ply.mo)) then return end --Don't do anything if the player or it's mobj doesn't exist.
	if ply.mo.skin ~= "skeleton" then return end --ONLY for the skeleton.
	if ply.skeleton == nil then return end --Can't do anything yet.
	if ply.playerstate ~= PST_LIVE then return end --Player's dead.

	local skel = ply.skeleton

	local minecart = ply.powers[pw_carry] == CR_MINECART
	local fof = skl.getFOFBelowMobj(ply.mo)
	local canBreakFOF = skl.P_IsFOFBustable(fof, ply.mo)

	local button = {
		x=160,y=190-3,
		btnTxt = {
			"C1",
			"SPIN"
		},
		funcTxt = {
			"Break minecart",
			"Break floor",
			"Activate wheel"
		}
	}

	--Custom 1 overlay.
	if minecart or canBreakFOF or skel.onSpinWheel then
		local funcTxt = ""
		if minecart then funcTxt=button.funcTxt[1]
		elseif canBreakFOF then funcTxt=button.funcTxt[2]
		else funcTxt=button.funcTxt[3] end

		local btnTxt = button.btnTxt[skel.onSpinWheel and 2 or 1]

		local txtWidths = {#btnTxt, #funcTxt}
		local fontWidth = 8 --V_MONOSPACE
		local border = 2

		local finalGap = (fontWidth-1)+(fontWidth*txtWidths[1])
		local offset = (txtWidths[2]*fontWidth)+finalGap
		local btnWidth = (fontWidth*txtWidths[1])+(border+(txtWidths[1]/2))
		local newX = button.x-(offset/2)
		local newY = button.y-1
		if leveltime % 30 < 15 then newY = button.y+1 end

		skl.dataDraw(v, "fill", {
			x=newX-border,y=button.y,
			width=btnWidth,height=11,
			color=25
		})
		skl.dataDraw(v, "fill", {
			x=newX-border,y=newY-1,
			width=btnWidth,height=11,
			color=10
		})
		skl.dataDraw(v, "text", {
			x=newX,y=newY,
			text=btnTxt,flags=V_MONOSPACE
		})
		skl.dataDraw(v, "text", {
			x=newX+finalGap,y=button.y,
			text=funcTxt,flags=V_MONOSPACE
		})
	end
end)