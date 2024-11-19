SS13 = require("SS13")


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
		attacked:throw_at(dm.global_procs._get_step(table, dm.global_procs._pick(4, 8)), 1, 1)
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
end

spawn_chessboard = function(loc)
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
