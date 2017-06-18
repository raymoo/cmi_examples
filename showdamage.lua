cmi.register_on_punchmob(function(mob, hitter, tflp, toolcaps, dir, damage)
	if hitter and hitter:is_player() then
		local pname = hitter:get_player_name()
		local id = cmi.get_uid(mob)
		minetest.chat_send_all(id .. " got hit by " .. pname .. " for " .. tostring(damage) .. " damage!")
	end
end)

cmi.register_on_diemob(function(mob, cause)
	if cause.type == "punch" and cause.puncher and cause.puncher:is_player() then
		local id = cmi.get_uid(mob)
		local pname = cause.puncher:get_player_name()
		minetest.chat_send_all(id .. " was killed by " .. pname .. "!")
	end
end)
