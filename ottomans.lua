SS13 = require("SS13")

local secret = false

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

soundsByHttp = soundsByHttp or {}
local loadSound = function(http)
	if soundsByHttp[http] then
		return soundsByHttp[http]
	end
	local request = SS13.new("/datum/http_request")
	local file_name = "tmp/custom_sound.ogg"
	request:prepare("get", http, "", "", file_name)
	request:begin_async()
	while request:is_complete() == 0 do
		sleep()
	end
	soundsByHttp[http] = SS13.new("/sound", file_name)
	return soundsByHttp[http]
end

mapsByHttp = mapsByHttp or {}
local loadMap = function(http, file_name)
	if mapsByHttp[http] then
		return mapsByHttp[http]
	end
	local request = SS13.new("/datum/http_request")
	request:prepare("get", http, "", "", file_name)
	request:begin_async()
	while request:is_complete() == 0 do
		sleep()
	end
	mapsByHttp[http] = file_name
	return mapsByHttp[http]
end

empire = empire or nil
local team_objective

if not SS13.is_valid(empire) then
	empire = SS13.new("/datum/team")
	empire.name = "Space Ottoman Empire"
	empire.show_roundend_report = not secret
	team_objective = SS13.new("/datum/objective")
	team_objective.explanation_text = "Conquer " .. dm.global_procs.station_name() .. "."
	empire:add_objective(team_objective)
end

sultan = sultan or nil

local template = dm.global_vars.SSmapping.map_templates["Ottoman Imperial Ship"]
if template == nil then
	template = SS13.new("/datum/map_template/shuttle", loadMap("https://raw.githubusercontent.com/Fikou/eventassets/refs/heads/main/ottoman.dmm", "tmp/ottoman.dmm", 1), "Ottoman Imperial Ship")
	dm.global_vars.SSmapping.map_templates["Ottoman Imperial Ship"] = template
end
SS13.await(dm.global_vars.SSshuttle, "action_load", template)

local raider_outfit = SS13.new("/datum/outfit")
raider_outfit.head = SS13.type("/obj/item/clothing/head/helmet/space/pirate/bandana")
raider_outfit.neck = SS13.type("/obj/item/clothing/neck/cloak")
raider_outfit.suit = SS13.type("/obj/item/clothing/suit/space/pirate")
raider_outfit.suit_store = SS13.type("/obj/item/tank/internals/oxygen/red")
raider_outfit.shoes = SS13.type("/obj/item/clothing/shoes/kim")
raider_outfit.gloves = SS13.type("/obj/item/clothing/gloves/latex/nitrile")
raider_outfit.mask = SS13.type("/obj/item/clothing/mask/gas/explorer")
raider_outfit.glasses = SS13.type("/obj/item/clothing/glasses/hud/health/night")
raider_outfit.uniform = SS13.type("/obj/item/clothing/under/costume/mummy")
raider_outfit.ears = SS13.type("/obj/item/radio/headset/headset_sec/alt")
raider_outfit.belt = SS13.type("/obj/item/melee/baton/telescopic/contractor_baton")
raider_outfit.back = SS13.type("/obj/item/storage/backpack/explorer")
raider_outfit.l_pocket = SS13.type("/obj/item/flashlight/emp")
raider_outfit.r_pocket = SS13.type("/obj/item/bodybag")
raider_outfit.id = SS13.type("/obj/item/card/id/advanced")
raider_outfit.id_trim = SS13.type("/datum/id_trim/chameleon")
raider_outfit.internals_slot = 32768
raider_outfit.implants = {SS13.type("/obj/item/implant/explosive")}
raider_outfit.backpack_contents = {
	[SS13.type("/obj/item/storage/box/handcuffs")] = 1,
	[SS13.type("/obj/item/storage/box/medipens")] = 1,
	[SS13.type("/obj/item/gun/energy/plasmacutter")] = 1,
	[SS13.type("/obj/item/crowbar/red")] = 1,
	[SS13.type("/obj/item/reagent_containers/hypospray/medipen/stimpack/traitor")] = 2,
}

local janissary_outfit = SS13.new("/datum/outfit")
janissary_outfit.head = SS13.type("/obj/item/clothing/head/hats/hos/shako")
janissary_outfit.suit = SS13.type("/obj/item/clothing/suit/armor/hos/hos_formal")
janissary_outfit.uniform = SS13.type("/obj/item/clothing/under/rank/civilian/chaplain/divine_archer")
janissary_outfit.shoes = SS13.type("/obj/item/clothing/shoes/kim")
janissary_outfit.gloves = SS13.type("/obj/item/clothing/gloves/combat")
janissary_outfit.belt = SS13.type("/obj/item/storage/belt/sabre")
janissary_outfit.glasses = SS13.type("/obj/item/clothing/glasses/sunglasses")
janissary_outfit.ears = SS13.type("/obj/item/radio/headset/headset_sec/alt")
janissary_outfit.l_pocket = SS13.type("/obj/item/ammo_box/strilka310")
janissary_outfit.r_pocket = SS13.type("/obj/item/ammo_box/strilka310")
janissary_outfit.id = SS13.type("/obj/item/card/id/advanced")
janissary_outfit.id_trim = SS13.type("/datum/id_trim/maint_reaper")

local sultan_outfit = SS13.new("/datum/outfit")
sultan_outfit.head = SS13.type("/obj/item/clothing/head/costume/ushanka/polar")
sultan_outfit.suit = SS13.type("/obj/item/clothing/suit/armor/hos/hos_formal")
sultan_outfit.uniform = SS13.type("/obj/item/clothing/under/rank/security/head_of_security/parade")
sultan_outfit.shoes = SS13.type("/obj/item/clothing/shoes/laceup")
sultan_outfit.gloves = SS13.type("/obj/item/clothing/gloves/combat")
sultan_outfit.belt = SS13.type("/obj/item/melee/chainofcommand")
sultan_outfit.glasses = SS13.type("/obj/item/clothing/glasses/sunglasses/oval")
sultan_outfit.ears = SS13.type("/obj/item/radio/headset/headset_sec/alt")
sultan_outfit.id = SS13.type("/obj/item/card/id/advanced/gold")
sultan_outfit.id_trim = SS13.type("/datum/id_trim/centcom/ert/commander")

equip_janissary = function(mob)
	if not SS13.is_valid(mob.mind) then
		return
	end
	if secret then
		local brainwashed = mob.mind:has_antag_datum(SS13.type("/datum/antagonist/brainwashed"))
		if SS13.is_valid(brainwashed) then
			list.add(brainwashed.objectives, SS13.new("/datum/objective/brainwashing", "Serve " .. sultan.real_name .. "'s Space Ottoman Empire and crush its enemies."))
			brainwashed:greet()
		else
			brainwashed = SS13.new("/datum/antagonist/brainwashed")
			list.add(brainwashed.objectives, SS13.new("/datum/objective/brainwashing", "Serve " .. sultan.real_name .. "'s Space Ottoman Empire and crush its enemies."))
			mob.mind:add_antag_datum(brainwashed)
		end
	else
		dm.global_procs.brainwash(mob, "Serve " .. sultan.real_name .. "'s Space Ottoman Empire and crush its enemies.")
	end
	local brainwash = mob.mind:has_antag_datum(SS13.type("/datum/antagonist/brainwashed"))
	brainwash.antagpanel_category = "Space Ottoman Empire"
	brainwash.show_in_roundend = not secret
	brainwash.show_to_ghosts = not secret
	brainwash.name = "Janissary"
	empire:add_member(mob.mind)
	mob.mind.special_role = "Janissary"
	mob:equipOutfit(janissary_outfit)
	mob.wear_id.registered_name = mob.real_name
	local radio = mob.ears
	radio.name = "crescent bowman headset"
	radio.desc = "This is used by Space Ottoman Empire forces. Protects ears from flashbangs."
	radio:set_frequency(1453)
	radio.freqlock = 1
	radio.keyslot.name = "common radio encryption key"
	radio.keyslot.channels = {["Common"] = 1}
	radio:recalculateChannels()
	local equipped = mob:get_equipped_items()
	list.remove(equipped, mob.back)
	for _, item in equipped do
		dm.global_procs._add_trait(item, "nodrop", "janissary")
	end
	local toggle = mob.wear_suit:GetComponent(SS13.type("/datum/component/toggle_icon"))
	toggle:do_icon_toggle(mob.wear_suit, nil)
	SS13.qdel(toggle)
	mob.wear_suit.name = "janissary tunic"
	mob.w_uniform.name = "janissary garb"
	mob.w_uniform.sensor_mode = 0
	mob.w_uniform.has_sensor = 0
	mob.w_uniform:update_wearer_status()
	mob.w_uniform.clothing_flags = bit32.bor(mob.w_uniform.clothing_flags, 2)
	mob.head.name = "üsküf"
	mob.head.clothing_flags = bit32.bor(mob.head.clothing_flags, 2)
end

local get_turf = function(thing) return dm.global_procs._get_step(thing, 0) end

local convert_janissary = function(brainwasher, janissary)
	SS13.set_timeout(2.4, function()
		if janissary.stat == 4 or janissary.loc ~= brainwasher or brainwasher.busy == 0 then
			return
		end
		local contents = list.copy(janissary.contents)
		local gore = list.copy(janissary.organs)
		list.add(gore, janissary.bodyparts)
		for _, item in contents do
			if list.find(gore, item) ~= 0 then
				continue
			end
			janissary:doUnEquip(item, 1, brainwasher.market_verb, 0, 0, 1)
		end
	end)
	SS13.set_timeout(4.9, function()
		if janissary.stat == 4 or janissary.loc ~= brainwasher or brainwasher.busy == 0 then
			return
		end
		dm.global_procs.to_chat(janissary, "<span class='hypnophrase'>You feel your mind faltering...</span>")
		janissary:emote("scream")
	end)
	SS13.set_timeout(7.3, function()
		if janissary.stat == 4 or janissary.loc ~= brainwasher or brainwasher.busy == 0 then
			return
		end
		equip_janissary(janissary)
	end)
end

local set_janissary = function(brainwasher, janissary)
	if SS13.istype(janissary, "/mob/living/carbon/human") then
		if list.find(empire.members, janissary.mind) ~= 0 then
			brainwasher:set_busy(1, "mod_installer")
			SS13.set_timeout(1.1, function()
				dm.global_procs.to_chat(janissary, "<span class='warning'>You already serve the Space Ottoman Empire!</span>")
				brainwasher.busy = 0
				brainwasher:open_machine()
			end)
			return
		end
		SS13.set_timeout(1.1, function()
			if janissary.stat ~= 4 and janissary.loc == brainwasher and brainwasher.busy == 1 then
				convert_janissary(brainwasher, janissary)
			end
		end)
	elseif janissary == nil then
		SS13.qdel(brainwasher.mod_unit)
		brainwasher.mod_unit = SS13.new("/obj/item/gun/ballistic/rifle/boltaction/donkrifle")
	end
end

local openStorage = function(storage, mob)
	SS13.set_timeout(0, function()
		if mob.active_storage == storage.atom_storage then
			mob.active_storage:hide_contents(mob)
			storage.atom_storage:hide_contents(mob)
		else
			storage.atom_storage:open_storage(mob)
		end
	end)
	return 1
end

local mousedrop_receive = function(brainwasher, mousedropped, user)
	if not SS13.istype(mousedropped, "/mob/living/carbon/human") then
		return
	end
	if mousedropped:CanReach(user) == 0 or brainwasher:CanReach(user) == 0 then
		return
	end
	if user:can_perform_action(mousedropped, 520) == 0 then
		return
	end
	brainwasher:close_machine(mousedropped)
end

local spawn_janissary_maker = function(loc)
	local storage = SS13.new("/obj/structure", dm.global_procs._get_step(loc, 1))
	storage.name = "janissary waste disposal"
	storage.desc = "Contains the old gear of new Janissary recruits."
	storage.icon = SS13.new("/icon", 'icons/obj/machines/suit_storage.dmi')
	storage.icon_state = "industrial"
	storage.density = 1
	storage.anchored = 1
	storage.resistance_flags = 115
	storage:add_overlay("industrial_open")
	local storage_datum = storage:create_storage()
	storage_datum.max_specific_storage = 6
	storage_datum.max_total_storage = 100
	storage_datum.max_slots = 100
	storage_datum.allow_big_nesting = 1
	storage_datum.animated = 0
	SS13.register_signal(storage, "atom_attack_hand", openStorage)
	SS13.register_signal(storage, "atom_attack_paw", openStorage)
	local brainwasher = SS13.new("/obj/machinery/mod_installer", loc)
	brainwasher.name = "devshirme induction chamber"
	brainwasher.desc = "Inducts new recruits into the Space Ottoman Empire's Janissary corps."
	brainwasher.resistance_flags = 115
	brainwasher.market_verb = storage
	SS13.qdel(brainwasher.mod_unit)
	brainwasher.mod_unit = SS13.new("/obj/item/gun/ballistic/rifle/boltaction/donkrifle")
	SS13.register_signal(brainwasher, "machinery_set_occupant", set_janissary)
	SS13.register_signal(brainwasher, "mousedropped_onto", mousedrop_receive)
end

local teleport = function(mob)
	if not SS13.istype(mob, "/mob/living") then
		return
	end
	if mob.mind.special_role == "Janissary" then
		dm.global_procs.to_chat(mob, "<span class='warning'>This portal is not meant for you.</span>")
		return
	end
	local areas = dm.global_procs.get_areas("/area/station/maintenance")
	local area = dm.global_procs._pick_list(areas)
	local turf = dm.global_procs._pick_list(dm.global_procs.get_area_turfs(area))
	dm.global_procs.do_teleport(mob, turf, 0, nil, nil, nil, nil, 0, "bluespace", 1)
end

local onTeleTouch = function(_, user) teleport(user) end
local onTeleAttack = function(_, _, user) teleport(user) end

local tele_entrance = nil

local spawn_teleport_entrance = function(loc)
	tele_entrance = SS13.new("/obj/effect", loc)
	tele_entrance.name = "portal"
	tele_entrance.desc = "A portal that takes Ottoman raiders to their raiding grounds."
	tele_entrance.icon = SS13.new("/icon", 'icons/obj/machines/gravity_generator.dmi')
	tele_entrance.icon_state = "activated"
	tele_entrance.color = {0.33, 0, 0, 0.33, 0, 0, 0.33, 0, 0}
	tele_entrance.particles = SS13.new("/particles/acid")
	tele_entrance.particles.color = "#DD0000"
	tele_entrance.density = 1
	tele_entrance:set_light_range_power_color(2, 3, "#DD0000")
	tele_entrance:update_light()
	local clickbox = tele_entrance:_AddComponent({SS13.type("/datum/component/clickbox"), "sphere", 0, 0, 2, min_scale = 1.5})
	clickbox:update_underlay("sphere", 1, 1)
	SS13.register_signal(tele_entrance, "atom_bumped", onTeleTouch)
	SS13.register_signal(tele_entrance, "atom_attack_hand", onTeleTouch)
	SS13.register_signal(tele_entrance, "atom_attackby", onTeleAttack)
end

local get_dragged = function(turf, channel, origturf)
	local contents = list.copy(origturf.contents)
	for _, possible_mob in origturf.contents do
		if SS13.istype(possible_mob, "/mob/living") and possible_mob.pulling ~= nil then
			dm.global_procs.do_teleport(possible_mob.pulling, turf, 0, nil, nil, nil, nil, 0, channel, 1)
		end
	end
end

local spawn_teleport_exit = function(loc)
	local tele_exit = SS13.new("/obj/effect/landmark/portal_exit", loc)
	tele_exit.id = "crescent"
	SS13.register_signal(loc, "intercept_teleported", get_dragged)
end

local use_teleporter = function(teleporter, user)
	if user.mind.special_role ~= "Ottoman Raider" then
		dm.global_procs.to_chat(user, "<span class='warning'>You don't know how this works!</span>")
		return
	end
	if SS13.await(SS13.global_proc, "do_after", user, 8, teleporter) == 0 then
		return
	end
	portal = SS13.new("/obj/effect/portal/permanent/one_way/one_use", get_turf(user), 50)
	portal.id = "crescent"
	portal.icon_state = "portal1"
	portal.sparkless = 0
	portal:set_light_color("#FF3300")
	dm.global_procs.try_move_adjacent(portal, user.dir)
	dm.global_procs.playsound(portal.loc, "portal_created", 50, 1, -9)
end

equip_raider = function(mob, name)
	local antag = SS13.new("/datum/antagonist/custom")
	antag.name = "Ottoman Raider"
	antag.antagpanel_category = "Space Ottoman Empire"
	antag.ui_name = nil
	antag.show_in_roundend = not secret
	antag.show_to_ghosts = not secret
	local objective = SS13.new("/datum/objective")
	objective.owner = mob.mind
	objective.explanation_text = "Raid the station and abduct crewmembers for the Janissary corps."
	objective.completed = 1
	list.add(antag.objectives, objective)
	mob.mind:add_antag_datum(antag)
	mob.mind.special_role = "Ottoman Raider"
	mob.mind:announce_objectives()
	empire:add_member(mob.mind)
	dm.global_procs.to_chat(mob, "<span class='boldwarning'>You have been chosen to recruit the elite Janissary units from Space Station 13 by teleporting down, abducting the crew, teleporting back up and hooking them to the brainwashing machines.</span>")
	mob:fully_replace_character_name(nil, name)
	mob:equipOutfit(raider_outfit)
	local cloak = mob.wear_neck
	cloak.name = "crescent cloak"
	cloak.icon_state = "raidercloak_item"
	cloak.worn_icon_state = "raidercloak_worn"
	cloak.desc = "A cloak showing upmost loyalty to the Space Ottoman Empire, given to its raiders."
	cloak.icon = loadIcon("https://github.com/Fikou/eventassets/raw/refs/heads/main/cloak.dmi")
	cloak.worn_icon = loadIcon("https://github.com/Fikou/eventassets/raw/refs/heads/main/cloak.dmi")
	local radio = mob.ears
	radio.name = "crescent bowman headset"
	radio.desc = "This is used by Space Ottoman Empire forces. Protects ears from flashbangs."
	radio:set_frequency(1453)
	radio.freqlock = 1
	radio.keyslot.name = "common radio encryption key"
	radio.keyslot.channels = {["Common"] = 1}
	radio:recalculateChannels()
	mob.belt.name = "raider baton"
	mob.belt.desc = "A compact, specialised baton assigned to Ottoman raiders. Applies light electrical shocks to targets."
	mob.wear_id.registered_name = name
	mob.w_uniform.sensor_mode = 0
	mob.w_uniform.has_sensor = 0
	mob.w_uniform:update_wearer_status()
	local portal = SS13.new("/obj/item", mob.back)
	portal.name = "crescent teleporter"
	portal.desc = "Used by Space Ottoman Empire raiders to teleport themselves and their loot back to their ship."
	portal.icon = SS13.new("/icon", 'icons/obj/devices/tracker.dmi')
	portal.icon_state = "syndi-tele"
	portal.inhand_icon_state = "electronic"
	portal.worn_icon_state = "electronic"
	portal.lefthand_file = SS13.new("/icon", 'icons/mob/inhands/items/devices_lefthand.dmi')
	portal.righthand_file = SS13.new("/icon", 'icons/mob/inhands/items/devices_righthand.dmi')
	portal.w_class = 2
	portal.throw_speed = 3
	portal.throw_range = 5
	mob:_AddComponent({SS13.type("/datum/component/simple_bodycam"), "raider camera", mob.real_name, "ottoman", 1})
	SS13.register_signal(portal, "item_attack_self", use_teleporter)
	mob:regenerate_icons()
	mob:playsound_local(mob, loadSound("https://www.myinstants.com/media/sounds/tmpjjkn2gcl.mp3"), 50)
end

local sultan_names = {
	"Osman",
	"Orhan",
	"Murad",
	"Bayezid",
	"Mehmed",
	"Selim",
	"Suleiman",
	"Ahmed",
	"Mustafa",
	"Ibrahim",
	"Mahmud",
	"Abdul",
}

equip_sultan = function(mob)
	sultan = mob
	sultan:fully_replace_character_name(nil, dm.global_procs._pick_list(sultan_names) .. " " .. dm.global_procs.armor_to_protection_class(dm.global_procs._rand(1, 50) * 10))
	sultan.underwear = "Nude"
	sultan.undershirt = "Nude"
	sultan.socks = "Nude"
	sultan.gender = "male"
	sultan.physique = "male"
	sultan.eye_color_left = "#652C01"
	sultan.eye_color_right = "#652C01"
	sultan.skin_tone = "asian1"
	sultan:set_hairstyle("Bald", nil, 0)
	sultan:set_facial_hairstyle("Beard (Seven o Clock Moustache)", nil, 0)
	sultan:set_haircolor("#3A230D", nil, 0)
	sultan:set_facial_haircolor("#3A230D", nil, 0)
	sultan:update_body(1)
	local sultan_job = SS13.new("/datum/job/space_pirate")
	sultan_job.title = "Ottoman Sultan"
	sultan_job.policy_index = ""
	sultan.mind:set_assigned_role(sultan_job)
	local antag = SS13.new("/datum/antagonist/custom")
	antag.name = "Ottoman Sultan"
	antag.antagpanel_category = "Space Ottoman Empire"
	antag.ui_name = nil
	antag.show_in_roundend = not secret
	antag.show_to_ghosts = not secret
	sultan.mind:add_antag_datum(antag)
	sultan.mind.special_role = "Ottoman Sultan"
	empire:add_member(sultan.mind)
	mob:equipOutfit(sultan_outfit)
	sultan.w_uniform.name = "sultan's garb"
	sultan.w_uniform.sensor_mode = 0
	sultan.w_uniform.has_sensor = 0
	sultan.w_uniform:update_wearer_status()
	sultan.w_uniform.clothing_flags = bit32.bor(sultan.w_uniform.clothing_flags, 2)
	sultan.wear_suit.name = "sultan's robes"
	sultan.belt.force = 30
	sultan.belt.armour_penetration = 100
	sultan.belt.tool_behaviour = "crowbar"
	sultan.belt.name = "sultan's chain"
	local turban = sultan.head
	turban.name = "sultan's magnificent turban"
	turban.worn_y_offset = 1
	turban.earflaps = 0
	turban.icon_state = "ushankaup_polar"
	turban.resistance_flags = 115
	turban.clothing_flags = bit32.bor(turban.clothing_flags, 2)
	dm.global_procs._add_trait(turban, "nodrop", "sultan")
	local radio = sultan.ears
	radio.name = "crescent bowman headset"
	radio.desc = "This is used by the Space Ottoman Empire's Sultan. Protects ears from flashbangs."
	radio:set_frequency(1453)
	radio.freqlock = 1
	radio.command = 1
	radio.use_command = 1
	radio.keyslot.name = "common radio encryption key"
	radio.keyslot.channels = {["Common"] = 1, ["Command"] = 1, ["Security"] = 1, ["Engineering"] = 1, ["Medical"] = 1, ["Science"] = 1, ["Supply"] = 1, ["Service"] = 1}
	radio:recalculateChannels()
	local id = sultan.wear_id
	id.registered_name = sultan.real_name
	id.assignment = "Sultan"
	id.trim_assignment_override = "Sultan"
	id.department_color_override = "#E30A17"
	id.subdepartment_color_override = "#E30A17"
	id:update_label()
	id:update_icon()
	sultan:regenerate_icons()
end

declare_war = function()
	dm.global_procs.priority_announce("Message from " .. sultan.real_name .. ": You are weak, and I am strong. There is no other justification needed for me to come and take what I wish from you!", "Declaration of War from Space Ottoman Empire", loadSound("https://www.myinstants.com/media/sounds/tmpjjkn2gcl.mp3"))
	SS13.qdel(tele_entrance)
end

win_war = function()
	dm.global_procs.priority_announce("Message from " .. sultan.real_name .. ": As expected, the Ottomans reign over your puny station. For the glory of the Empire.", "Message from Space Ottoman Empire")
	team_objective.completed = 1
end

raider_job = raider_job or SS13.new("/datum/job/space_pirate")
raider_job.title = "Ottoman Raider"
raider_job.policy_index = ""
raider_job.spawn_positions = 4
raider_job.job_flags = 516

local setupRaiders = function()
	local candidates = list.copy(dm.global_vars.new_player_list)
	for _, player in candidates do
		if not SS13.is_valid(player) or player.ready ~= 1 or not SS13.is_valid(player.mind) or not player:check_preferences() then
			list.remove(candidates, player)
		end
		if list.find(player.client.prefs.be_special, "Operative") == 0 then
			list.remove(candidates, player)
		end
	end
	while raider_job.current_positions < raider_job.spawn_positions and #candidates > 0 do
		candidate = dm.global_procs.pick_n_take(candidates)
		candidate.mind:set_assigned_role(raider_job)
		raider_job.current_positions = raider_job.current_positions + 1
	end
end

local raiders = 0

local raider_spawn = function(_, job, mob)
	if job == raider_job then
		SS13.set_timeout(0.5, function()
			raiders = raiders + 1
			equip_raider(mob, "Azeb " .. dm.global_procs.random_capital_letter() .. dm.global_procs._num2text(raiders))
		end)
	end
end

SS13.register_signal(dm.global_vars.SSdcs, "!pre_roles_assigned", setupRaiders)
SS13.register_signal(dm.global_vars.SSdcs, "!job_after_spawn", raider_spawn)

local table
local chess_icon = SS13.new("/icon", 'icons/obj/toys/chess.dmi')

local knock_piece = function(attacked, attacking, user)
	if attacked.loc ~= table.loc then
		return
	end
	if attacking.desc == "A chess piece." then
		if user:transferItemToLoc(attacking, table.loc) == 1 then
			attacking.pixel_x = attacked.pixel_x
			attacking.pixel_y = attacked.pixel_y
		end
		attacked:throw_at(dm.global_procs._get_step(table, 8), 1, 1)
	end
end

local renderers = {30, 31, 40}

local zoom_in = function(chair, mob)
	for _, render in renderers do
		local y_offset = 0
		local x_offset = 0
		if chair.dir == 1 then
			y_offset = -96
		elseif chair.dir == 2 then
			y_offset = 96
		end
		if chair.dir == 4 then
			x_offset = -96
		elseif chair.dir == 8 then
			x_offset = 96
		end
		local game_renderer = mob.hud_used:get_plane_master(render)
		game_renderer.appearance_flags = bit32.bor(game_renderer.appearance_flags, 512)
		dm.global_procs._animate(game_renderer, {["transform"] = SS13.new("/matrix", 3, 0, x_offset, 0, 3, y_offset)}, 5)
	end
end

local zoom_out = function(chair, mob)
	for _, render in renderers do
		local game_renderer = mob.hud_used:get_plane_master(render)
		game_renderer.appearance_flags = bit32.band(game_renderer.appearance_flags, bit32.bnot(512))
		dm.global_procs._animate(game_renderer, {["transform"] = SS13.new("/matrix", 1, 0, 0, 0, 1, 0)}, 5)
	end
end

local on_dir_change = function(chair)
	if chair:has_buckled_mobs() == 1 then
		zoom_in(chair, chair.buckled_mobs[1])
	end
end

local make_chair = function(loc, dir)
	local chair = SS13.new("/obj/structure/chair/comfy/shuttle", loc)
	chair.name = "chess chair"
	chair.desc = "A chair that helps you focus on your chess game."
	chair.dir = dir
	SS13.register_signal(chair, "buckle", zoom_in)
	SS13.register_signal(chair, "unbuckle", zoom_out)
	SS13.register_signal(chair, "atom_post_dir_change", on_dir_change)
end

local upsize = function(item)
	item.transform = SS13.new("/matrix", 1, 0, 0, 0, 1, 0)
end

local downsize = function(item)
	item.transform = SS13.new("/matrix", 0.25, 0, 0, 0, 0.25, 3)
end

local make_piece = function(icon, name, px, py)
	local chess_piece = SS13.new("/obj/item", table.loc)
	chess_piece.name = name
	chess_piece.desc = "A chess piece."
	chess_piece.icon = chess_icon
	chess_piece.icon_state = icon
	chess_piece.w_class = 1
	chess_piece.pixel_x = px
	chess_piece.pixel_y = py
	chess_piece.resistance_flags = 4
	chess_piece.transform = SS13.new("/matrix", 0.25, 0, 0, 0, 0.25, 3)
	SS13.register_signal(chess_piece, "atom_attackby", knock_piece)
	SS13.register_signal(chess_piece, "item_equip", upsize)
	SS13.register_signal(chess_piece, "item_drop", downsize)
end

local spawn_chessboard = function(loc)
	table = SS13.new("/obj/structure/table/wood", loc)
	local checker = SS13.new("/icon", 'icons/turf/floors.dmi', "kitchen_small")
	local ma1 = SS13.new("/mutable_appearance", checker)
	ma1.transform = SS13.new("/matrix", 0.375, 0, -6, 0, 0.3125, -2)
	ma1.appearance_flags = 769
	table:add_overlay(ma1)
	local ma2 = SS13.new("/mutable_appearance", checker)
	ma2.transform = SS13.new("/matrix", 0.375, 0, 6, 0, 0.3125, -2)
	ma2.appearance_flags = 769
	table:add_overlay(ma2)
	local ma3 = SS13.new("/mutable_appearance", checker)
	ma3.transform = SS13.new("/matrix", 0.375, 0, -6, 0, 0.3125, 8)
	ma3.appearance_flags = 769
	table:add_overlay(ma3)
	local ma4 = SS13.new("/mutable_appearance", checker)
	ma4.transform = SS13.new("/matrix", 0.375, 0, 6, 0, 0.3125, 8)
	ma4.appearance_flags = 769
	table:add_overlay(ma4)

	for i = 1, 8 do
		make_piece("black_pawn", "black pawn", -13 + i * 3, 9)
	end

	make_piece("black_rook", "black rook", -10, 12)
	make_piece("black_rook", "black rook", 11, 12)
	make_piece("black_knight", "black knight", -7, 12)
	make_piece("black_knight", "black knight", 8, 12)
	make_piece("black_bishop", "black bishop", -4, 12)
	make_piece("black_bishop", "black bishop", 5, 12)
	make_piece("black_queen", "black queen", -1, 12)
	make_piece("black_king", "black king", 2, 12)

	for i = 1, 8 do
		make_piece("white_pawn", "white pawn", -13 + i * 3, -3)
	end

	make_piece("white_rook", "white rook", -10, -6)
	make_piece("white_rook", "white rook", 11, -6)
	make_piece("white_knight", "white knight", -7, -6)
	make_piece("white_knight", "white knight", 8, -6)
	make_piece("white_bishop", "white bishop", -4, -6)
	make_piece("white_bishop", "white bishop", 5, -6)
	make_piece("white_queen", "white queen", -1, -6)
	make_piece("white_king", "white king", 2, -6)

	make_chair(dm.global_procs._get_step(table, 1), 2)
	make_chair(dm.global_procs._get_step(table, 2), 1)
end

local lowtable
local button

local lower_table = function(_, button_pressed)
	if button_pressed ~= button then
		return
	end
	if lowtable.density == 1 then
		lowtable.density = 0
		dm.global_procs._animate(lowtable, {["transform"] = SS13.new("/matrix", 1, 0, 0, 0, 0.75, -8)}, 5)
		dm.global_procs._animate(button, {["pixel_y"] = -5}, 5)
	else
		lowtable.density = 1
		dm.global_procs._animate(lowtable, {["transform"] = SS13.new("/matrix", 1, 0, 0, 0, 1, 0)}, 5)
		dm.global_procs._animate(button, {["pixel_y"] = 4}, 5)
	end
end

local spawn_lowtable = function(loc)
	lowtable = SS13.new("/obj/structure/table/wood/fancy/red", loc)
	button = SS13.new("/obj/machinery/button", loc)
	button.req_access = {"cent_captain"}
	button.name = "sultan's secret button"
	button.pixel_y = 4
	SS13.register_signal(dm.global_vars.SSdcs, "!button_pressed", lower_table)
end

local duldul

local banner = SS13.new("/obj/item/banner")
banner.name = "Ottoman Banner"
banner.desc = "A banner of the Space Ottoman Empire."
banner.icon = loadIcon("https://github.com/Fikou/eventassets/raw/refs/heads/main/banner.dmi")
banner.icon_state = "banner"
banner.morale_cooldown = 299
banner.role_loyalties = {"Ottoman Sultan", "Ottoman Raider", "Janissary"}

local warcries = {
	"Zafer bizimdir!",
	"Durmayın, vurun!",
	"Padişahım çok yaşa!",
}

local use_banner = function(action)
	banner.warcry = dm.global_procs._pick_list(warcries)
	banner:attack_self(action.owner)
	duldul:manual_emote("neighs!")
end

local banner_action = SS13.new("/datum/action/cooldown")
banner_action.name = "Use Banner"
banner_action.desc = "Inspire your allies with the banner of the Space Ottoman Empire."
banner_action.button_icon = loadIcon("https://github.com/Fikou/eventassets/raw/refs/heads/main/banner.dmi")
banner_action.button_icon_state = "banner"
banner_action.cooldown_time = 300
SS13.register_signal(banner_action, "action_trigger", use_banner)

local give_banner = function(horse, mob)
	banner_action:Grant(mob)
end

local take_banner = function(horse, mob)
	banner_action:Remove(mob)
end

local spawn_duldul = function(loc)
	duldul = SS13.new("/mob/living/basic/pony", loc)
	duldul.real_name = "Duldul"
	duldul.name = "Duldul"
	duldul.desc = "The mighty imperial steed of the Sultan, usually given to an elite Janissary."
	duldul.maxHealth = 300
	duldul:set_health(300)
	duldul.ponycolors = {"#d0cecc", "#353841"}
	duldul.combat_mode = 1
	duldul.unique_tamer = 1
	duldul:_AddComponent({SS13.type("/datum/component/tameable"), {SS13.type("/obj/item/food/grown/apple/gold")}, 100, 100, 1})
	duldul:apply_colour()
	duldul:add_overlay(SS13.new("/mutable_appearance", SS13.new("/icon", loadIcon("https://github.com/Fikou/eventassets/raw/refs/heads/main/banner.dmi"), "duldul_banner")))
	banner:forceMove(duldul)
	SS13.register_signal(duldul, "buckle", give_banner)
	SS13.register_signal(duldul, "unbuckle", take_banner)
end

local landmarks = list.copy(dm.global_vars.landmarks_list)
for _, landmark in landmarks do
	if landmark.name == "Ottoman Sultan" then
		local newsultan = SS13.new("/mob/living/carbon/human", get_turf(landmark))
		newsultan:mind_initialize()
		equip_sultan(newsultan)
	elseif landmark.name == "Janissary Maker" then
		spawn_janissary_maker(get_turf(landmark))
	elseif landmark.name == "Ottoman Portal Entrance" then
		spawn_teleport_entrance(get_turf(landmark))
	elseif landmark.name == "Ottoman Portal Exit" then
		spawn_teleport_exit(get_turf(landmark))
	elseif landmark.name == "Ottoman Chess" then
		spawn_chessboard(get_turf(landmark))
	elseif landmark.name == "Lowering Table" then
		spawn_lowtable(get_turf(landmark))
	elseif landmark.name == "Duldul" then
		spawn_duldul(get_turf(landmark))
	else
		continue
	end
	list.remove(dm.global_vars.landmarks_list, landmark)
	SS13.qdel(landmark)
end

people_i_dont_like = {
--	"mimepride",
}

local function remove_person_i_dont_like(_, client)
	if list.find(people_i_dont_like, client.ckey) == 1 then
		SS13.qdel(client)
	end
end

SS13.register_signal(dm.global_vars.SSdcs, "!client_connect", remove_person_i_dont_like)
for _, client in dm.global_vars.clients do
	remove_person_i_dont_like(nil, client)
end
