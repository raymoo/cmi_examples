-- This is an example of integrating CMI into a mob.
-- It creates a simple mob that follows a player.
-- Comments starting with "(CMI)" precede code that has been included to
-- integrate the mob with CMI.

-- Its staticdata is a serialized table with the following fields:
--  hp: the health when it was serialized
--  cmi_components: component data serialized

local function on_activate(self, staticdata, dtime)
	local tab = staticdata ~= "" and minetest.parse_json(staticdata)
	local obj = self.object
	if tab then
		obj:set_hp(tab.hp)
		-- (CMI) Deserialize component data
		self.cmi_components = cmi.activate_components(tab.cmi_components)
	else
		-- (CMI) Deserialize component data
		self.cmi_components = cmi.activate_components()
	end
	-- (CMI) Notify CMI of finished activation
	cmi.notify_activate(obj)
end

local function get_staticdata(self)
	local tab = {
		hp = self.object:get_hp(),
		-- (CMI) Serialize component data
		cmi_components = cmi.serialize_components(self.cmi_components),
	}
	return minetest.write_json(tab)
end

local function on_step(self, dtime)
	local obj = self.object
	local pos = obj:getpos()
	-- (CMI) Notify CMI of step event
	cmi.notify_step(obj, dtime)
	local targets = minetest.get_objects_inside_radius(pos, 5)
	for i, target in ipairs(targets) do
		if target:is_player() then
			local t_pos = target:getpos()
			obj:setvelocity(vector.subtract(t_pos, pos))
		end
	end
end

local function attack(self, puncher, tflp, caps, dir, attacker)
	local obj = self.object
	-- (CMI) Use CMI's damage calculation
	local dmg = cmi.calculate_damage(obj, puncher, tflp, caps, dir, attacker)
	-- (CMI) Notify CMI of punch, and cancel if needed
	local cancel = cmi.notify_punch(obj, puncher, tflp, caps, dir, dmg, attacker)
	if cancel then return end
	if dmg > 0 and puncher:is_player() then
		local pname = puncher:get_player_name()
		minetest.chat_send_player(pname, "Ouch! You hurt me")
	elseif dmg > 0 and attacker and attacker.type == "player" then
		minetest.chat_send_player(attacker.identifier, "Ouch! You hurt me")
	end
	local new_hp = obj:get_hp() - dmg
	if new_hp <= 0 then
		-- (CMI) Notify CMI that the mob has died
		cmi.notify_die(obj, {
			mob = obj,
			cause = { type = "punch", puncher = puncher, attacker = attacker },
		})
	end
	-- If the health is 0 or less, the mob will be removed, so no explicit
	-- remove.
	obj:set_hp(new_hp)
end

local function on_punch(...)
	-- defer to attack
	attack(...)
end

minetest.register_entity("cmi_examples:mob", {
	hp_max = 5,
	physical = true,
	collide_with_objects = true,
	visual = "cube",
	textures = { "default_stone.png" },
	makes_footstep_sound = true,
	stepheight = 1,
	automatic_face_movement_dir = 0.0,
	nametag = "Example Mob",
	on_activate = on_activate,
	on_step = on_step,
	on_punch = on_punch,
	get_staticdata = get_staticdata,
	-- (CMI) Required field
	cmi_is_mob = true,
	-- (CMI) Optional field
	description = "Example Mob",
	-- (CMI) Optional field
	cmi_attack = attack,
})
