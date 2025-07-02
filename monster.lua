SS13 = require("SS13")

iconsByHttp = iconsByHttp or {}
local loadIcon = function(http)
	if iconsByHttp[http] then
		return iconsByHttp[http]
	end
	local request = SS13.new("/datum/http_request")
	local file_name = "tmp/custom_map_icon.dmi"
	request:prepare("get", http, "", "", file_name)
	request:begin_async()
	while request:is_complete() == 0 do
		sleep()
	end
	iconsByHttp[http] = SS13.new("/icon", file_name)
	return iconsByHttp[http]
end

move_cooldowns = {}
attack_cooldowns = {}
local brains = 0
local monster_ref = nil

local jankbook = SS13.new("/datum/book_info")
local info = SS13.new("/atom/movable/screen")
info.screen_loc = "WEST:6,CENTER"
info.maptext_width = 96
info.maptext = "<span class='maptext'>BRAINS: 0\nHEALTH: 100%</span>"

local update_info = function()
	local monster = dm.global_procs._locate(monster_ref)
	local health = dm.global_procs._round(monster.health / monster.maxHealth * 100, 0.1)
	info.maptext = "<span class='maptext'>BRAINS: " .. dm.global_procs._num2text(brains) .. "\nHEALTH: " .. dm.global_procs._num2text(health) .. "%</span>"
end

local talk = function(brainmob, message)
	if brainmob.stat == 4 then
		return
	end
	monster = brainmob.loc
	if not SS13.istype(monster, "/mob/living/simple_animal/hostile/megafauna") then
		return
	end
	jankbook.title = message
	message = jankbook:get_title()
	local newmessage = ""
	for symbol in string.gmatch(message, ".") do
		if dm.global_procs._prob(5) == 1 then
			continue
		end
		newmessage = newmessage .. dm.global_procs.capitalize(symbol)
		if dm.global_procs._prob(10) == 1 then
			newmessage = newmessage .. dm.global_procs.capitalize(symbol)
		end
		if dm.global_procs._prob(10) == 1 then
			newmessage = newmessage .. " "
		elseif dm.global_procs._prob(5) == 1 then
			newmessage = newmessage .. "... "
		end
	end
	monster:say(newmessage)
	dm.global_procs.playsound(monster.loc, "sound/effects/hallucinations/veryfar_noise.ogg", 25, 1)
	return 2
end

local on_tentacle_hit = function(proj, firer, target)
	if not SS13.istype(target, "/mob/living") then
		return
	end
	target:Immobilize(8)
end

local click = function(brainmob, clicked_on, modifiers)
	if modifiers["alt"] or modifiers["shift"] or modifiers["ctrl"] then
		return
	end
	local monster = brainmob.loc
	if not SS13.istype(monster, "/mob/living/simple_animal/hostile/megafauna") then
		return
	end
	if attack_cooldowns[brainmob.ckey] > dm.world.time or brainmob.stat == 4 then
		return
	end
	if clicked_on == monster then
		return
	end
	if modifiers["left"] then
		monster:face_atom(clicked_on)
		if monster:Adjacent(clicked_on) == 0 then
			return
		end
		attack_cooldowns[brainmob.ckey] = dm.world.time + 8
		monster:UnarmedAttack(clicked_on, 1, modifiers)
	elseif modifiers["right"] then
		monster:face_atom(clicked_on)
		if monster:Adjacent(clicked_on) ~= 0 then
			return
		end
		if brains < 2 then
			attack_cooldowns[brainmob.ckey] = dm.world.time + 8
		elseif brains < 3 then
			attack_cooldowns[brainmob.ckey] = dm.world.time + 16
		else
			attack_cooldowns[brainmob.ckey] = dm.world.time + 24
		end
		monster:face_atom(clicked_on)
		monster:visible_message("<span class='danger'><b>The brainsucker</b> fires at " .. clicked_on.name .. "!</span>")
		local proj = monster:fire_projectile(SS13.type("/obj/projectile/tentacle"), clicked_on, "sound/effects/splat.ogg")
		SS13.register_signal(proj, "projectile_self_on_hit", on_tentacle_hit)
	elseif modifiers["middle"] then
		attack_cooldowns[brainmob.ckey] = dm.world.time + 80
		dm.global_procs.playsound(monster.loc, "sound/mobs/non-humanoids/space_dragon/space_dragon_roar.ogg", 100, 1)
		monster:visible_message("<span class='userdanger'><b>The brainsucker</b> roars furiously!</span>")
		for _, thing in dm.global_procs._view(5, monster) do
			if thing == monster then
				continue
			end
			if SS13.istype(thing, "/mob/living") then
				thing:soundbang_act(1, 5, 5, 3)
			elseif dm.global_procs._prob(33) == 0 then
				continue
			end
			thing:Shake(2, 2, 10)
		end
	end
end

local eat_brain = function(monster, brain)
	if list.find(monster.wanted_objects, brain) ~= 0 then
		return
	end
	list.add(monster.wanted_objects, brain)
	brain:forceMove(monster)
	monster:visible_message("<span class='danger'><b>The brainsucker</b> devours " .. brain.name .. "!</span>")
	local brainmob = brain.brainmob
	if SS13.is_valid(brainmob) and SS13.is_valid(brainmob.client) then
		dm.global_procs._list_set(monster.wanted_objects, brain, brain.brainmob)
		brain.brainmob = nil
		brainmob:doMove(monster)
		brainmob:set_stat(0)
		brainmob:reset_perspective()
		brainmob.lighting_cutoff_red = 15
		brainmob.lighting_cutoff_green = 15
		brainmob.lighting_cutoff_blue = 15
		brainmob.lighting_cutoff = 15
		brainmob:update_sight()
		brainmob:remove_traits({"immobilized", "handsblocked"}, "brain-unaided")
		brainmob:add_traits({"emotemute"}, "brain-unaided")
		dm.global_procs.to_chat(brainmob, "<span class='hypnophrase big'>YOU HAVE JOINED THE H I V E M I N D</span>")
		dm.global_procs.to_chat(brainmob, "<span class='hypnophrase'>Support and speak with your brethren.</span>")
		dm.global_procs.to_chat(brainmob, "<span class='hypnophrase'>Your movement and attack waiting periods are tied.</span>")
		dm.global_procs.to_chat(brainmob, "<span class='hypnophrase'>Left-Click to rend your foes. Consumes the brains of corpses.</span>")
		dm.global_procs.to_chat(brainmob, "<span class='hypnophrase'>Right-Click to fire a tentacle. Immobilizes the hit person.</span>")
		dm.global_procs.to_chat(brainmob, "<span class='hypnophrase'>Middle-Click to roar.</span>")
		brainmob:playsound_local(brainmob, "sound/music/antag/hypnotized.ogg", 100)
		SS13.register_signal(brainmob, "living_vocal_speech", talk)
		SS13.register_signal(brainmob, "mob_clickon", click)
		list.add(brainmob.hud_used.static_inventory, info)
		brainmob.hud_used:show_hud(brainmob.hud_used.hud_version)
		move_cooldowns[brainmob.ckey] = 0
		attack_cooldowns[brainmob.ckey] = 0
	end
	local radius = dm.global_procs._rand(1, 8)
	local angle = dm.global_procs._rand(0, 359)
	local brain_image = dm.global_procs._image(monster.icon, nil, "brain")
	brain_image.pixel_x = radius * dm.global_procs._cos(angle) + 12
	brain_image.pixel_y = radius * dm.global_procs._sin(angle) + 34
	list.add(monster.underlays, brain_image)
	brains = brains + 1
	update_info()
end

local ondeath = function(monster)
	for _, brain in monster.wanted_objects do
		local brainmob = dm.global_procs._list_get(monster.wanted_objects, brain)
		brain:forceMove(monster:drop_location())
		if SS13.is_valid(brainmob) then
			brainmob:forceMove(brain)
			brainmob:set_stat(4)
			brainmob:reset_perspective()
			brainmob.lighting_cutoff_red = 0
			brainmob.lighting_cutoff_green = 0
			brainmob.lighting_cutoff_blue = 0
			brainmob.lighting_cutoff = 0
			brainmob:update_sight()
			brainmob:add_traits({"immobilized", "handsblocked"}, "brain-unaided")
			brainmob:remove_traits({"emotemute"}, "brain-unaided")
			SS13.unregister_signal(brainmob, "living_vocal_speech")
			SS13.unregister_signal(brainmob, "mob_clickon")
			list.remove(brainmob.hud_used.static_inventory, info)
			brainmob.hud_used:show_hud(brainmob.hud_used.hud_version)
		end
		brain:throw_at(dm.global_procs.get_edge_target_turf(brain, dm.global_procs._pick_list(dm.global_vars.alldirs)), 2, 3)
	end
	SS13.new("/obj/effect/gibspawner/generic", monster:drop_location())
	SS13.new("/obj/effect/gibspawner/generic", monster:drop_location())
	SS13.new("/obj/effect/gibspawner/generic", monster:drop_location())
	SS13.new("/obj/effect/gibspawner/generic", monster:drop_location())
	SS13.new("/obj/effect/gibspawner/generic", monster:drop_location())
	SS13.new("/obj/effect/temp_visual/explosion/fast", monster:drop_location())
end

local devour_robot = function(monster, who, success)
	if success == 0 or who.stat ~= 4 then
		return
	end
	if not SS13.is_valid(who.mmi) then
		return
	end
	if SS13.istype(who.mmi, "/obj/item/mmi/posibrain") then
		return
	end
	local mmi = who.mmi
	local brain = mmi.brain
	who:dump_into_mmi(who:drop_location())
	mmi:eject_brain(monster)
	mmi:update_appearance()
	mmi.name = SS13.new("/obj/item/mmi").name
	eat_brain(monster, brain)
	SS13.new("/obj/effect/gibspawner/robot", who:drop_location())
	SS13.new("/obj/effect/decal/cleanable/blood/oil", who:drop_location())
end

local devour = function(monster, who, success)
	if not SS13.istype(who, "/mob/living/carbon/human") then
		if SS13.istype(who, "/obj/item/bodypart/head") then
			local brain = nil
			for _, possible_brain in who.contents do
				if SS13.istype(possible_brain, "/obj/item/organ/brain") then
					brain = possible_brain
				end
			end
			who:drop_organs(nil, 0)
			eat_brain(monster, brain)
			SS13.new("/obj/effect/gibspawner/generic", who:drop_location())
		elseif SS13.istype(who, "/obj/item/organ/brain") then
			eat_brain(monster, who)
		elseif SS13.istype(who, "/obj/item/mmi") and SS13.is_valid(who.brain) then
			local brain = who.brain
			mmi:eject_brain(monster)
			mmi:update_appearance()
			mmi.name = SS13.new("/obj/item/mmi").name
			eat_brain(monster, brain)
		elseif SS13.istype(who, "/mob/living/silicon/robot") then
			devour_robot(monster, who, success)
		end
		return
	end
	if success == 0 or who.stat ~= 4 then
		return
	end
	local brain = who:get_organ_slot("brain")
	if not SS13.is_valid(brain) then
		return
	end
	monster:heal_overall_damage(who.maxHealth * 0.5)
	brain:Remove(who)
	eat_brain(monster, brain)
	local head = who:get_bodypart("head")
	head:dismember()
	SS13.new("/obj/effect/gibspawner/human/bodypartless", who:drop_location())
	head:take_damage(10000)
	dm.global_procs.playsound(monster.loc, "sound/effects/changeling_absorb/changeling_absorb1.ogg", 100, 1)
end

local onmove = function(monster, brainmob, direction)
	if move_cooldowns[brainmob.ckey] > dm.world.time or brainmob.stat == 4 then
		return
	end
	move_cooldowns[brainmob.ckey] = dm.world.time + 4
	monster:try_step_multiz(direction)
	return 1
end

spawn_monster = function(loc, ghost_amount)
	local monster = SS13.new("/mob/living/simple_animal/hostile/megafauna", loc)
	monster.icon_living = "creature"
	monster.icon_state = "creature"
	monster.icon = loadIcon("https://github.com/Fikou/eventassets/raw/refs/heads/main/brainsucker.dmi")
	monster.can_have_ai = 0
	monster.melee_damage_lower = 25
	monster.melee_damage_upper = 25
	monster.armour_penetration = 30
	monster.wound_bonus = 0
	monster.sharpness = 2
	monster.zone_selected = "head"
	monster.attack_verb_simple = "rend"
	monster.attack_verb_continuous = "rends"
	monster.attack_vis_effect = "bite"
	monster.name = "brainsucker"
	monster.real_name = "brainsucker"
	monster.desc = "Brainstorm incarnate."
	monster.del_on_death = 1
	monster.can_buckle_to = 0
	monster.move_force = 5000
	monster.mouse_opacity = 1
	monster.next_move_modifier = 0
	monster.environment_smash = 2
	monster.gender = "neuter"
	monster.footstep_type = "footstep_heavy"
	monster.verb_say = "screeches"
	monster.verb_exclaim = "roars"
	monster.verb_sing = "screeches"
	monster.attack_sound = "sound/items/weapons/resonator_blast.ogg"
	monster.death_sound = "sound/effects/hallucinations/wail.ogg"
	monster.death_message = "bursts into gore and brains!"
	monster.maxHealth = 500
	monster:set_health(500)
	monster:_RemoveElement({SS13.type("/datum/element/simple_flying")})
	monster:add_traits({"advancedtooluser"}, lol)
	monster:set_light_on(0)
	monster:update_light()
	monster:add_overlay("ball")
	monster:add_overlay({dm.global_procs.emissive_appearance(monster.icon, "eyes", monster, 255)})
	monster:toggle_ai(3)
	monster:updatehealth()
	monster:_AddElement({SS13.type("/datum/element/footstep"), "footstep_claw"})
	local radio = SS13.new("/obj/item/radio")
	radio:forceMove(monster)
	radio:_AddElement({SS13.type("/datum/element/empprotection"), 7})
	SS13.qdel(monster:GetComponent(SS13.type("/datum/component/basic_mob_attack_telegraph")))
	SS13.qdel(monster:GetComponent(SS13.type("/datum/component/gps")))
	SS13.register_signal(monster, "hostile_post_attackingtarget", devour)
	SS13.register_signal(monster, "living_death", ondeath)
	SS13.register_signal(monster, "driver_move", onmove)
	SS13.register_signal(monster, "living_health_update", update_info)
	monster:mind_initialize()
	monster_ref = dm.global_procs.REF(monster)
	if ghost_amount ~= nil and ghost_amount > 0 then
		local brains = {}
		for i=1,ghost_amount do
			local human = SS13.new("/mob/living/carbon/human", monster:drop_location())
			human:death()
			brains[i] = human
		end
		local antag = SS13.new("/datum/antagonist/custom")
		antag.name = "Brainsucker"
		antag.antagpanel_category = "The Hivemind"
		antag.ui_name = nil
		antag.show_in_roundend = 1
		antag.show_to_ghosts = 1
		monster.mind:add_antag_datum(antag)
		local candidates, runtime = SS13.await(dm.global_vars.SSpolling, "poll_ghosts_for_targets", "Would you like to join the Hivemind?", "Sentience Potion Spawn", "Sentience Potion Spawn", 150, brains, nil, 1, nil, monster, "part of the hivemind")
		for i, candidate in candidates do
			brains[i]:PossessByPlayer(candidate.ckey)
			devour(monster, brains[i], 1)
		end
	end
end
