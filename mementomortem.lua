SS13 = require("SS13")

local admin = "fikou"
local admin_user = dm.global_vars.GLOB.directory[admin].mob

local get_turf = function(thing) return dm.global_procs._get_step(thing, 0) end

local log_mob = SS13.new("/mob/living/carbon/human/dummy")
local center_tile = nil

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

local speech_table = {}
photo_table = {}

local hearing = 0

local template = dm.global_vars.SSmapping.map_templates["Memento Mortem"]
if not SS13.is_valid(template) then
	template = SS13.new("/datum/map_template", loadMap("https://raw.githubusercontent.com/Fikou/eventassets/refs/heads/main/mementomortem.dmm", "tmp/mementomortem.dmm"), "Memento Mortem")
	dm.global_vars.SSmapping.map_templates["Memento Mortem"] = template
	SS13.await(template, "load", dm.global_procs._locate(110, 68, 1), 1)
end

overlay = nil
local door = nil
skeleton = nil
using_watch = nil

watch = SS13.new("/obj/item", get_turf(admin_user))
watch.name = "Memento Mortem"
watch.desc = "Remember death."
watch.speech_span = "papyrus"
watch.resistance_flags = 115
watch.w_class = 2
watch.icon = loadIcon("https://github.com/Fikou/eventassets/raw/refs/heads/main/mementomortem.dmi")
watch.icon_state = "watch-closed"

local watch_exam = function(clock, user, examine_list)
	list.add(examine_list, "<span class='notice'>Use in-hand to open or close the watch.</span>")
	list.add(examine_list, "<span class='notice'>When open, can be used on corpses, organs, and bodyparts to see someone's moment of death, along with words said in their vicinity in the 10 seconds before it.</span>")
end

SS13.register_signal(watch, "atom_examine", watch_exam)

local open_watch = function(clock, user)
	if watch.icon_state == "watch-closed" then
		watch.icon_state = "watch-open"
		watch.w_class = 4
		dm.global_procs.playsound(get_turf(watch), 'sound/items/lighter/zippo_on.ogg', 100, 1)
	else
		watch.icon_state = "watch-closed"
		watch.w_class = 2
		dm.global_procs.playsound(get_turf(watch), 'sound/items/lighter/zippo_off.ogg', 100, 1)
	end
end

local exit_door = function(e_door, mob)
	watch:remove_traits({"nodrop"}, "lua")
	mob:playsound_local(mob, 'sound/effects/parry.ogg', 25)
	mob.loc = center_tile
	using_watch:PossessByPlayer(mob.ckey)
	open_watch(watch, using_watch)
	using_watch = nil
end

local check_move = function(mob)
	return hearing
end

for _, landmark in dm.global_vars.landmarks_list do
	if landmark.name == "Memento Mortem" then
		center_tile = get_turf(landmark)
		for _, obj in center_tile.contents do
			if SS13.istype(obj, "/obj/effect/overlay") then
				overlay = obj
			end
		end
		if overlay == nil then
			overlay = SS13.new("/obj/effect/overlay", center_tile)
			overlay.plane = -6
			overlay.mouse_opacity = 0
			overlay.color = {3.3, 3.3, 3.3, 0, 5.9, 5.9, 5.9, 0, 1.1, 1.1, 1.1, 0, 0, 0, 0, 1, -5, -5, -5, 0}
			overlay.transform = overlay.transform:Translate(-224, -224)
		end
		skeleton = SS13.new("/mob/living/simple_animal", center_tile)
		skeleton.name = "???"
		skeleton.mouse_opacity = 0
		skeleton.maxHealth = 99999999
		skeleton.icon = loadIcon("https://github.com/Fikou/eventassets/raw/refs/heads/main/mementomortem.dmi")
		skeleton.icon_state = "skeleton"
		skeleton.icon_living = "skeleton"
		skeleton.can_have_ai = 0
		skeleton.hud_type = SS13.type("/datum/hud")
		skeleton:toggle_ai(3)
		skeleton:add_traits({"mute", "emotemute", "orbiting_forbidden"}, "lua")
		SS13.register_signal(skeleton, "mob_client_pre_move", check_move)
	elseif landmark.name == "Memento Mortem Exit" then
		for _, obj in get_turf(landmark).contents do
			if SS13.istype(obj, "/obj/effect") and obj.name == "Exit" then
				door = obj
			end
		end
		if door == nil then
			door = SS13.new("/obj/effect", get_turf(landmark))
			door.icon = loadIcon("https://github.com/Fikou/eventassets/raw/refs/heads/main/mementomortem.dmi")
			door.name = "Exit"
			door.icon_state = "exit"
			door.density = 1
			door.plane = -5
			door.dir = landmark.dir
		end
		SS13.register_signal(door, "atom_bumped", exit_door)
		door = nil
	end
end

local finish_snapshot = function(camera, target, user, pic)
	photo_table[camera.article] = pic
	for _, turf in camera.wires do
		turf.lighting_object = camera.wires[turf]
	end
	pic.names_seen = {}
	pic.caption = target
	for _, mob_weakref in pic.mobs_seen do
		local caught_mob = mob_weakref:resolve()
		if SS13.is_valid(caught_mob) then
			local speaker_speech = speech_table[caught_mob]
			if speaker_speech ~= nil then
				for say_time, text in speaker_speech do
					if tonumber(say_time) + 100 >= camera.hair_mask then
						pic.names_seen[say_time] = text
					end
				end
			end
		end
	end
	pic.names_seen = dm.global_procs.sort_list(pic.names_seen, SS13.type("/proc/cmp_num_string_asc"))
	print(tostring(target) .. "'s photo finished baking at " .. dm.world.time .. ".")
end

SS13.register_signal(watch, "item_attack_self", open_watch)

local attack = function(clock, target, user)
	local blood_dna = nil
	if not SS13.istype(target, "/mob/living/carbon/human") then
		if SS13.istype(target, "/obj/item/organ") or SS13.istype(target, "/obj/item/bodypart") then
			if SS13.istype(target, "/obj/item/organ") and bit32.band(target.organ_flags, 2) ~= 0 then
				dm.global_procs.to_chat(user, "<span class='warning'>Cannot gather information from robotic organs.</span>")
				return
			end
			if SS13.istype(target, "/obj/item/bodypart") and bit32.band(target.bodytype, 2) ~= 0 then
				dm.global_procs.to_chat(user, "<span class='warning'>Cannot gather information from robotic limbs.</span>")
				return
			end
			local blood_info = target.blood_dna_info[1]
			for enzymes, photo in photo_table do
				if blood_info ~= enzymes then
					continue
				end
				target = photo.caption
				blood_dna = blood_info
				break
			end
		else
			return
		end
	else
		if target.dna == nil then
			dm.global_procs.to_chat(user, "<span class='warning'>The target has no DNA.</span>")
			return 1
		end
		blood_dna = target.dna.unique_enzymes
	end
	if watch.icon_state == "watch-closed" then
		dm.global_procs.to_chat(user, "<span class='warning'>The watch is closed.</span>")
		return
	end
	if SS13.is_valid(target) then
		if not SS13.istype(target, "/mob/living/carbon/human") then
			return
		end
		if target.stat ~= 4 then
			dm.global_procs.to_chat(user, "<span class='warning'>The target needs to be dead.</span>")
			return
		end
	end
	if photo_table[blood_dna] == nil then
		dm.global_procs.to_chat(user, "<span class='warning'>This corpse is too fresh or died before the start of the shift, try again in a moment?</span>")
		return 1
	end
	watch:add_traits({"nodrop"}, "lua")
	user:playsound_local(user, 'sound/effects/gong.ogg', 50)
	user:playsound_local(user, 'sound/effects/parry.ogg', 50)
	using_watch = user
	overlay.icon = photo_table[blood_dna].picture_image
	local maptext_overlay = skeleton:overlay_fullscreen("lua", SS13.type("/atom/movable/screen/fullscreen"))
	skeleton:PossessByPlayer(user.ckey)
	maptext_overlay.icon_state = "echo"
	maptext_overlay.maptext_width = 480
	maptext_overlay.maptext_y = 256
	hearing = 1
	local i = 0
	for _, time in photo_table[blood_dna].names_seen do
		i = i + 1
		SS13.set_timeout(i * 1.5, function()
			maptext_overlay.maptext = "<span class='maptext' style='text-align: center'><font size='3'>" .. photo_table[blood_dna].names_seen[time] .. "</font></span>"
			skeleton:playsound_local(skeleton, "muffspeech", 75)
		end)
	end
	SS13.set_timeout((i + 1) * 1.5, function()
		skeleton:clear_fullscreen("lua", 5)
		hearing = 0
	end)
	return 1
end

SS13.register_signal(watch, "item_pre_attack", attack)

local drop_watch = function(clock, user)
	if skeleton.ckey ~= nil then
		exit_door(nil, skeleton)
	end
	if watch.icon_state == "watch-open" then
		open_watch(clock, user)
	end
end

SS13.register_signal(watch, "item_drop", drop_watch)

local on_say = function(_, speaker, message)
	if speaker.ckey == nil or speaker.stat == 4 then
		return
	end
	if speech_table[speaker] == nil then
		speech_table[speaker] = {}
	end
	local speaker_speech = speech_table[speaker]
	speaker_speech[tostring(dm.world.time)] = message
end

local on_death = function(_, dead, gibbed)
	if dead == using_watch then
		exit_door(nil, skeleton)
	end
	if not SS13.istype(dead, "/mob/living/carbon/human") or gibbed == 1 or dead.dna == nil then
		return
	end
	camera = SS13.new("/obj/item/camera")
	camera.flash_enabled = 0
	camera.silent = 1
	camera.print_picture_on_snap = 0
	SS13.register_signal(camera, "camera_image_captured", finish_snapshot)
	camera.article = dead.dna.unique_enzymes
	print(tostring(dead) .. "'s photo started baking at " .. dm.world.time .. ".")
	camera.hair_mask = dm.world.time
	camera.wires = {}
	local turfs = dm.global_procs.get_hear(7, get_turf(dead))
	for _, turf in turfs do
		if not SS13.istype(turf, "/turf") then
			continue
		end
		camera.wires[turf] = turf.lighting_object
		turf.lighting_object = nil
	end
	SS13.check_tick()
	camera:captureimage(dead, log_mob, 7, 7)
end

SS13.register_signal(dm.global_vars.SSdcs, "!say_special", on_say)
SS13.register_signal(dm.global_vars.SSdcs, "!mob_death", on_death)

for _, dead_guy in dm.global_vars.dead_mob_list do
	--on_death(nil, dead_guy, 0)
end
