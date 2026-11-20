extends Node

var retro_font: Font = null
var retro_theme: Theme = null

var icons: Dictionary = {}
var portraits: Dictionary = {}
var ground_textures: Dictionary = {}
var world_map_tex: ImageTexture = null

var box_stone: StyleBoxTexture = null
var box_dark: StyleBoxTexture = null
var box_gold: StyleBoxTexture = null
var box_tooltip: StyleBoxTexture = null
var box_btn_norm: StyleBoxTexture = null
var box_btn_hover: StyleBoxTexture = null
var box_btn_press: StyleBoxTexture = null
var box_btn_disabled: StyleBoxTexture = null

func _ready() -> void:
	_build_font_and_theme()
	_build_ui_boxes()
	_build_icons()
	_build_portraits()
	_build_ground_textures()
	_build_world_atlas()
	_apply_theme_styles()

func _build_font_and_theme() -> void:
	var sf: SystemFont = SystemFont.new()
	sf.font_names = PackedStringArray(["Tahoma", "Verdana", "DejaVu Sans", "Liberation Sans"])
	sf.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	sf.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	sf.hinting = TextServer.HINTING_NORMAL
	retro_font = sf

	retro_theme = Theme.new()
	retro_theme.default_font = retro_font
	retro_theme.default_font_size = 13

func _tex_from_image(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

func _from_ascii(rows: Array, pal: Dictionary, scale: int = 1) -> ImageTexture:
	var h: int = rows.size()
	var w: int = str(rows[0]).length() if h > 0 else 16
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var line: String = str(rows[y])
		for x in range(w):
			var ch: String = line.substr(x, 1) if x < line.length() else "."
			var col: Color = pal.get(ch, Color(0, 0, 0, 0))
			img.set_pixel(x, y, col)
	if scale > 1:
		img.resize(w * scale, h * scale, Image.INTERPOLATE_NEAREST)
	return _tex_from_image(img)

func _make_9slice_tex(w: int, h: int, bg1: Color, bg2: Color, border_outer: Color, border_hi: Color, border_lo: Color, rivet: Color) -> StyleBoxTexture:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var col: Color = bg1 if ((x + y) % 2 == 0) else bg2
			if x == 0 or y == 0 or x == w - 1 or y == h - 1:
				col = border_outer
			elif x == 1 or y == 1:
				col = border_hi
			elif x == w - 2 or y == h - 2:
				col = border_lo
			elif x == 2 or y == 2 or x == w - 3 or y == h - 3:
				col = border_outer.lerp(border_lo, 0.5)
			img.set_pixel(x, y, col)
	for cx in [2, w - 3]:
		for cy in [2, h - 3]:
			img.set_pixel(cx, cy, rivet)
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = _tex_from_image(img)
	sb.texture_margin_left = 4
	sb.texture_margin_right = 4
	sb.texture_margin_top = 4
	sb.texture_margin_bottom = 4
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

func _build_ui_boxes() -> void:
	box_stone = _make_9slice_tex(
		24, 24,
		Color(0.14, 0.13, 0.16, 0.96), Color(0.12, 0.11, 0.14, 0.96),
		Color(0.05, 0.04, 0.05, 1.0), Color(0.68, 0.54, 0.28, 1.0), Color(0.32, 0.24, 0.12, 1.0),
		Color(0.95, 0.80, 0.42, 1.0)
	)
	box_dark = _make_9slice_tex(
		20, 20,
		Color(0.08, 0.08, 0.10, 0.94), Color(0.07, 0.07, 0.09, 0.94),
		Color(0.03, 0.03, 0.04, 1.0), Color(0.42, 0.40, 0.46, 1.0), Color(0.20, 0.19, 0.23, 1.0),
		Color(0.70, 0.65, 0.55, 1.0)
	)
	box_gold = _make_9slice_tex(
		24, 24,
		Color(0.18, 0.14, 0.11, 0.97), Color(0.15, 0.12, 0.09, 0.97),
		Color(0.10, 0.06, 0.03, 1.0), Color(0.92, 0.75, 0.34, 1.0), Color(0.48, 0.34, 0.12, 1.0),
		Color(1.0, 0.92, 0.55, 1.0)
	)
	box_tooltip = _make_9slice_tex(
		20, 20,
		Color(0.05, 0.05, 0.07, 0.98), Color(0.04, 0.04, 0.06, 0.98),
		Color(0.02, 0.02, 0.03, 1.0), Color(0.84, 0.68, 0.30, 1.0), Color(0.34, 0.26, 0.12, 1.0),
		Color(1.0, 0.88, 0.44, 1.0)
	)
	box_btn_norm = _make_9slice_tex(
		16, 16,
		Color(0.22, 0.20, 0.24, 1.0), Color(0.20, 0.18, 0.22, 1.0),
		Color(0.06, 0.05, 0.06, 1.0), Color(0.62, 0.50, 0.28, 1.0), Color(0.28, 0.22, 0.14, 1.0),
		Color(0.82, 0.68, 0.36, 1.0)
	)
	box_btn_hover = _make_9slice_tex(
		16, 16,
		Color(0.30, 0.25, 0.20, 1.0), Color(0.27, 0.22, 0.18, 1.0),
		Color(0.10, 0.07, 0.04, 1.0), Color(0.95, 0.80, 0.38, 1.0), Color(0.46, 0.34, 0.16, 1.0),
		Color(1.0, 0.92, 0.55, 1.0)
	)
	box_btn_press = _make_9slice_tex(
		16, 16,
		Color(0.14, 0.12, 0.14, 1.0), Color(0.12, 0.11, 0.12, 1.0),
		Color(0.04, 0.03, 0.04, 1.0), Color(0.24, 0.20, 0.12, 1.0), Color(0.60, 0.48, 0.24, 1.0),
		Color(0.70, 0.56, 0.28, 1.0)
	)
	box_btn_disabled = _make_9slice_tex(
		16, 16,
		Color(0.12, 0.12, 0.14, 0.85), Color(0.11, 0.11, 0.13, 0.85),
		Color(0.04, 0.04, 0.05, 1.0), Color(0.32, 0.30, 0.34, 1.0), Color(0.16, 0.16, 0.18, 1.0),
		Color(0.42, 0.40, 0.44, 1.0)
	)

func _apply_theme_styles() -> void:
	retro_theme.set_stylebox("panel", "PanelContainer", box_stone)
	retro_theme.set_stylebox("panel", "TooltipPanel", box_tooltip)
	retro_theme.set_color("font_color", "TooltipLabel", Color(0.96, 0.94, 0.86))
	retro_theme.set_font_size("font_size", "TooltipLabel", 12)
	retro_theme.set_stylebox("normal", "Button", box_btn_norm)
	retro_theme.set_stylebox("hover", "Button", box_btn_hover)
	retro_theme.set_stylebox("pressed", "Button", box_btn_press)
	retro_theme.set_stylebox("focus", "Button", box_btn_hover)
	retro_theme.set_stylebox("disabled", "Button", box_btn_disabled)
	retro_theme.set_color("font_disabled_color", "Button", Color(0.55, 0.54, 0.58))
	retro_theme.set_color("font_color", "Button", Color(0.96, 0.92, 0.78))
	retro_theme.set_color("font_hover_color", "Button", Color(1.0, 0.96, 0.60))
	retro_theme.set_color("font_pressed_color", "Button", Color(0.88, 0.75, 0.42))
	retro_theme.set_color("font_color", "Label", Color(0.95, 0.92, 0.84))
	retro_theme.set_color("font_shadow_color", "Label", Color(0.05, 0.04, 0.06, 0.95))
	retro_theme.set_constant("shadow_offset_x", "Label", 1)
	retro_theme.set_constant("shadow_offset_y", "Label", 1)

func _build_icons() -> void:
	var O := Color(0.08, 0.07, 0.09)
	var S := Color(0.78, 0.84, 0.92)
	var D := Color(0.46, 0.52, 0.62)
	var G := Color(0.95, 0.76, 0.24)
	var W := Color(0.55, 0.34, 0.18)
	var R := Color(0.95, 0.24, 0.16)
	var F := Color(1.0, 0.68, 0.18)
	var B := Color(0.24, 0.68, 1.0)
	var I := Color(0.75, 0.94, 1.0)
	var E := Color(0.28, 0.90, 0.38)
	var P := Color(0.78, 0.34, 0.98)
	var H := Color(1.0, 0.96, 0.68)

	icons["weapon"] = _from_ascii([
		"............OOO.",
		"...........OSSO.",
		"..........OSSDO.",
		".........OSSDO..",
		"........OSSDO...",
		".......OSSDO....",
		"......OSSDO.....",
		".....OSSDO......",
		"...OOSSDO.......",
		"..OGGSSO........",
		"...OGGO.........",
		"..OWOGGO........",
		".OWWO..O........",
		".OGWO...........",
		"..OO............",
		"................"
	], {"O": O, "S": S, "D": D, "G": G, "W": W}, 2)
	icons["w1"] = icons["weapon"]

	icons["w2"] = _from_ascii([
		"....OOOOOOOO....",
		"..OOSSSSSSSSOO..",
		".OSSDDDDDDDDSSO.",
		".OSDO......ODSO.",
		"OSDO..OOOO..ODSO",
		"OSO..OSSSSO..OSO",
		"OSO.OSSOOSSO.OSO",
		"OSO.OSO..OSO.OSO",
		"OSO.OSSOOSSO.OSO",
		"OSO..OSSSSO..OSO",
		"OSDO..OOOO..ODSO",
		".OSDO......ODSO.",
		".OSSDDDDDDDDSSO.",
		"..OOSSSSSSSSOO..",
		"....OOOOOOOO....",
		"................"
	], {"O": O, "S": S, "D": D}, 2)

	icons["w3"] = _from_ascii([
		"................",
		"......OOOO......",
		".....ORRRRO.....",
		"...OORFFFFRO....",
		"..ORRFFYYFFRO...",
		".ORRFYY..YYFRO..",
		".ORRY......RRO..",
		"..OOOOO..ORRO...",
		"...ORRRRRRRO....",
		"..OFFYYYYFFO....",
		".ORFFYYYYFFRO...",
		"ORRO......ORRO..",
		"OOO........OOO..",
		"................",
		"................",
		"................"
	], {"O": O, "R": R, "F": F, "Y": H}, 2)

	icons["armor"] = _from_ascii([
		"..OOOOOOOOOOOO..",
		".OSSSSSSSSSSSSO.",
		".OSDDDDGGDDDDSO.",
		".OSDDDGGGGDDDSO.",
		".OSDDDGGGGDDDSO.",
		".OSDDDDGGDDDDSO.",
		".OSDDDDGGDDDDSO.",
		"..OSDDDGGDDDSO..",
		"..OSDDDGGDDDSO..",
		"...OSDDGGDDSO...",
		"...OSDDGGDDSO...",
		"....OSDGGDSO....",
		".....OSGGSO.....",
		"......OSSO......",
		".......OO.......",
		"................"
	], {"O": O, "S": S, "D": D, "G": G}, 2)
	icons["w4"] = icons["armor"]

	icons["w5"] = _from_ascii([
		"....OOOOOOOO....",
		"..OORRRRRRRROO..",
		".ORRRSSSSSSRRRO.",
		".ORRSSSSSSSSSSRO",
		".ORSSSOOOOSSSORO",
		".ORSSOOOOOOSSORO",
		".ORSSSOOOOSSSORO",
		".ORRSSSSSSSSSRRO",
		"..ORRSSOSSOSSRRO",
		"...ORSSSSSSSSRO.",
		"...ORSOOSOOOSRO.",
		"....ORSOOSOSRO..",
		"....OOOOOOOOOO..",
		"................",
		"................",
		"................"
	], {"O": O, "R": R, "S": S}, 2)

	icons["m1"] = _from_ascii([
		"........OOOO....",
		"......OORRRRO...",
		".....ORRFFFFRO..",
		"....ORFFYYYYFRO.",
		"..OORFFYYHHYFRO.",
		".ORRFFYYHHHHYFO.",
		"ORRFFYYHHHHYYFO.",
		"ORRFFYYHHHHYYFO.",
		".ORRFFYYHHYYFRO.",
		"..ORRFFYYYYFRO..",
		"...ORRFFFFFFO...",
		"....OORRRRRO....",
		"..OORRRROOO.....",
		".ORRRRO.........",
		"..OOOO..........",
		"................"
	], {"O": O, "R": R, "F": F, "Y": G, "H": H}, 2)

	icons["m2"] = _from_ascii([
		".......OO.......",
		"......OIIO......",
		"...OO.OBBO.OO...",
		"..OBIOOBBOOBIO..",
		"...OBBOIIOBBO...",
		".OO.OBBIIBBBO.OO",
		"OIIOIIIIIIIIOIIO",
		".OO.OBBIIBBBO.OO",
		"...OBBOIIOBBO...",
		"..OBIOOBBOOBIO..",
		"...OO.OBBO.OO...",
		"......OIIO......",
		".......OO.......",
		"................",
		"................",
		"................"
	], {"O": O, "B": B, "I": I}, 2)

	icons["m3"] = _from_ascii([
		"......OOOO......",
		"....OOPPPPOO....",
		"...OPPBIIBPPO...",
		"..OPBIIIIIIBPO..",
		".OPBIIHHHHIIBPO.",
		".OPBIIHHHHIIBPO.",
		"..OPBIIIIIIBPO..",
		"...OPPBIIBPPO...",
		"....OOPPPPOO....",
		"...OPPPPPPPPO...",
		"..OPB......BPO..",
		".OPB........BPO.",
		"..OO........OO..",
		"................",
		"................",
		"................"
	], {"O": O, "P": P, "B": B, "I": I, "H": H}, 2)

	icons["m4"] = _from_ascii([
		"...OOOOOOOOOO...",
		"..OIIIIIIIIIIO..",
		".OIBBBBBBBBBBIO.",
		".OIBBIIIIIIBBIO.",
		".OIBBIHHHHIBBIO.",
		".OIBBIHHHHIBBIO.",
		".OIBBIIIIIIBBIO.",
		"..OIBBBBBBBBIO..",
		"..OIBBIIIIBBIO..",
		"...OIBBIIBBIO...",
		"....OIBBBBIO....",
		".....OIBBIO.....",
		"......OIIO......",
		".......OO.......",
		"................",
		"................"
	], {"O": O, "B": B, "I": I, "H": H}, 2)

	icons["m5"] = _from_ascii([
		"..........OOOO..",
		"........OORFFRO.",
		".......ORRFFYYRO",
		"......ORRFFYYFRO",
		"....OORRRFFYYFO.",
		"..OORRRRRRFFFO..",
		".ORRFFYYYYFFRO..",
		"ORRFFYYHHYYFFRO.",
		"ORRFFYYHHYYFFRO.",
		"ORRFFYYYYYYFFRO.",
		".ORRFFFFFFFFRO..",
		"..OORRRRRRRRO...",
		"....OOOOOOOO....",
		"................",
		"................",
		"................"
	], {"O": O, "R": R, "F": F, "Y": G, "H": H}, 2)

	icons["p1"] = _from_ascii([
		"......OOOO......",
		".....OGHHGO.....",
		".....OGHHGO.....",
		".....OGHHGO.....",
		".OOOOGGHHGGOOOO.",
		"OGHHHHGGGGHHHHO.",
		".OOOOGGHHGGOOOO.",
		".....OGHHGO.....",
		".....OGHHGO.....",
		".....OGHHGO.....",
		".....OGGGGO.....",
		".....OGGGGO.....",
		"......OWWO......",
		"......OWWO......",
		".......OO.......",
		"................"
	], {"O": O, "G": G, "H": H, "W": W}, 2)

	icons["p2"] = _from_ascii([
		"....OOOOOOOO....",
		"..OOGGGGGGGGOO..",
		".OGGHHHHHHHHGGO.",
		".OGHHOOOOOOHHGO.",
		"OGHO.OGHHGO.OHGO",
		"OGHOOGHHHHGOOHGO",
		"OGHOOHHHHHHOOHGO",
		"OGHOOGHHHHGOOHGO",
		"OGHO.OGHHGO.OHGO",
		".OGHHOOOOOOHHGO.",
		".OGGHHHHHHHHGGO.",
		"..OOGGGGGGGGOO..",
		"....OOOOOOOO....",
		"................",
		"................",
		"................"
	], {"O": O, "G": G, "H": H}, 2)

	icons["p3"] = _from_ascii([
		"..OOOOOOOOOOOO..",
		".OGGGGGGGGGGGGO.",
		".OGHHHHHHHHHHGO.",
		".OGGGGGGGGGGGGO.",
		"..OOOOOGGOOOOO..",
		"......OWWO......",
		"......OWWO......",
		"......OWWO......",
		"......OWWO......",
		"......OWWO......",
		"......OWWO......",
		"......OWWO......",
		"......OGGO......",
		".......OO.......",
		"................",
		"................"
	], {"O": O, "G": G, "H": H, "W": W}, 2)

	icons["p4"] = _from_ascii([
		".....OOOOOO.....",
		"....OEEEEEEO....",
		"....OEHHHHEO....",
		".OOOOEHHHHEOOOO.",
		"OEEEEHHHHHHEEEEO",
		"OEHHHHHHHHHHHHEO",
		"OEHHHHHHHHHHHHEO",
		"OEEEEHHHHHHEEEEO",
		".OOOOEHHHHEOOOO.",
		"....OEHHHHEO....",
		"....OEEEEEEO....",
		".....OOOOOO.....",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "E": E, "H": H}, 2)

	icons["p5"] = icons["p2"]

	icons["r1"] = _from_ascii([
		"......OOOO......",
		"....OOWWWWO.....",
		"...OWWO..OSO....",
		"..OWWO...OSSSO..",
		".OWWO....OSSO...",
		".OWO.....OSO....",
		"OWO.....OSOO....",
		"OWO....OSOWO....",
		"OWO...OSOWO.....",
		".OWO.OSOWO......",
		".OWWOSOWO.......",
		"..OWWSWO........",
		"...OWWO.........",
		"....OOO.........",
		"................",
		"................"
	], {"O": O, "W": W, "S": S}, 2)

	icons["r2"] = _from_ascii([
		".OO....OO....OO.",
		"OSSO..OSSO..OSSO",
		".OSO...OSO...OSO",
		".OSO...OSO...OSO",
		".OSO...OSO...OSO",
		".OWO...OWO...OWO",
		".OWO...OWO...OWO",
		".OWO...OWO...OWO",
		"OEEO..OEEO..OEEO",
		".OO....OO....OO.",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "S": S, "W": W, "E": E}, 2)

	icons["r3"] = icons["m2"]
	icons["r4"] = icons["p4"]
	icons["r5"] = icons["w5"]

	icons["potion"] = _from_ascii([
		".....OOOOOO.....",
		".....OWWWWO.....",
		"......OSSO......",
		"......OSSO......",
		"....OORRRROO....",
		"...ORRRRRRRRO...",
		"..ORRHHRRRRRRO..",
		"..ORRHHRRRRRRO..",
		"..ORRRRRRRRRRO..",
		"..ORRRRRRRRRRO..",
		"..ORRRRRRRRRRO..",
		"...ORRRRRRRRO...",
		"....OOOOOOOO....",
		"................",
		"................",
		"................"
	], {"O": O, "W": W, "S": S, "R": R, "H": H}, 2)

	icons["mount"] = _from_ascii([
		"........OOOO....",
		"......OOWWGGO...",
		".....OWWWWWWO...",
		"....OWWWOOWWWWO.",
		"...OWDDO..OOGGO.",
		"..OWWRRRROO.....",
		".OWWRRRRRRROO...",
		".OWWRRRRRRRRO...",
		".OWO.OWWO.OWO...",
		".OWO.OWWO.OWO...",
		".ODO.ODDO.ODO...",
		".OOO..OOO.OOO...",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "W": W, "G": G, "R": R, "D": D}, 2)

	icons["helm"] = _from_ascii([
		"....OOOOOOOO....",
		"..OOSSSSSSSSOO..",
		".OSSSSSSSSSSSSO.",
		".OSSDDDDDDDDSSO.",
		".OSDOOSSSSOODSO.",
		".OSDOOSSSSOODSO.",
		".OSDDGGGGGGDDSO.",
		".OSDDGG..GGDDSO.",
		".OSDDGG..GGDDSO.",
		"..OSDDD..DDDSO..",
		"...OOOOOOOOOO...",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "S": S, "D": D, "G": G}, 2)

	icons["shoulders"] = _from_ascii([
		".OOOOO....OOOOO.",
		"OGGGGGSOOSGGGGGO",
		"OSSSSSSO.OSSSSSO",
		"OSDDDDDO.ODDDDSO",
		"OSDDDDDO.ODDDDSO",
		".OSDDDO...ODDSO.",
		"..OOOO.....OOOO.",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "S": S, "D": D, "G": G}, 2)

	icons["amulet"] = _from_ascii([
		".....OOOOOO.....",
		"....OGGGGGGO....",
		"...OG......GO...",
		"...OG......GO...",
		"....OG....GO....",
		".....OGGGGO.....",
		".....OGBBGO.....",
		"....OGBIIBGO....",
		"....OGBIIBGO....",
		".....OGBBGO.....",
		"......OGGO......",
		".......OO.......",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "G": G, "B": B, "I": I}, 2)

	icons["ring"] = _from_ascii([
		"................",
		"......OOOO......",
		".....OGBBGO.....",
		"....OGGGGGGO....",
		"...OGGO..OGGO...",
		"..OGGO....OGGO..",
		"..OGGO....OGGO..",
		"...OGGO..OGGO...",
		"....OGGGGGGO....",
		".....OOOOOO.....",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "G": G, "B": B}, 2)

	icons["gold"] = _from_ascii([
		"....OOOOOOOO....",
		"..OOGGGGGGGGOO..",
		".OGGHHHHHHHHGGO.",
		".OGHGGGGGGGGHGO.",
		"OGHGGGOOOOGGGHGO",
		"OGHGGOGHHGOGGHGO",
		"OGHGGOGHHGOGGHGO",
		"OGHGGGOOOOGGGHGO",
		".OGHGGGGGGGGHGO.",
		".OGGGGGGGGGGGGO.",
		"..OOGGGGGGGGOO..",
		"....OOOOOOOO....",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "G": G, "H": H}, 2)

	icons["chest"] = _from_ascii([
		"................",
		"..OOOOOOOOOOOO..",
		".OWWWWWWWWWWWWO.",
		"OWWGGGGGGGGGGWWO",
		"OWWGWWWWWWWWGWWO",
		"OWWGGGGGGGGGGWWO",
		"OOOOOOOGGOOOOOOO",
		"OWWWWWOGGOWWWWWO",
		"OWWWWWOOOOWWWWWO",
		"OWWGGGGGGGGGGWWO",
		"OWWWWWWWWWWWWWWO",
		"OWWWWWWWWWWWWWWO",
		".OOOOOOOOOOOOOO.",
		"................",
		"................",
		"................"
	], {"O": O, "W": W, "G": G}, 2)

	icons["map"] = _from_ascii([
		"................",
		".OOOOO..OOOOO...",
		"OEEEEEOOSSSSSO..",
		"OEEWEEOOSBBBSO..",
		"OEWWWEOOSBBBSO..",
		"OEEWEEOOSSGGSO..",
		"OEEEEEOOSSGGSO..",
		"OEEERREOSSSSSO..",
		"OEERRREOSSSSSO..",
		"OEEEEEOOSSSSSO..",
		".OOOOO..OOOOO...",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "E": E, "W": W, "S": Color(0.86, 0.78, 0.56), "B": B, "G": G, "R": R}, 2)

	icons["lock"] = _from_ascii([
		"................",
		".....OOOOOO.....",
		"....OSSSSSSO....",
		"...OSSOOOOSSO...",
		"...OSO....OSO...",
		"...OSO....OSO...",
		"..OOOOOOOOOOOO..",
		"..OGGGGGGGGGGO..",
		"..OGGGOOOOGGGO..",
		"..OGGGOOOOGGGO..",
		"..OGGGGOOGGGGO..",
		"..OGGGGOOGGGGO..",
		"..OGGGGGGGGGGO..",
		"..OOOOOOOOOOOO..",
		"................",
		"................"
	], {"O": O, "S": S, "G": G}, 2)

	icons["hearth"] = _from_ascii([
		".....OOOOOO.....",
		"....OSSSSSSO....",
		"...OSSBBBBSSO...",
		"..OSBBIIIISSBO..",
		"..OSBIWWWWIBSO..",
		".OSBIWBSSBWIBSO.",
		".OSBIWSBBWSIBSO.",
		".OSBIWSIBWSIBSO.",
		".OSBIWWSSWWIBSO.",
		"..OSBIIIIIIBSO..",
		"..OSSBBBBBBSSO..",
		"...OSSSSSSSSO...",
		"....OSSSSSSO....",
		".....OOOOOO.....",
		"................",
		"................"
	], {"O": O, "S": D, "B": B, "I": I, "W": Color(0.90, 0.96, 1.0)}, 2)

func _build_portraits() -> void:
	var O := Color(0.06, 0.05, 0.07)
	var K := Color(0.95, 0.78, 0.62)
	var KS := Color(0.76, 0.56, 0.42)
	var S := Color(0.76, 0.82, 0.90)
	var D := Color(0.42, 0.48, 0.58)
	var G := Color(0.96, 0.76, 0.24)
	var R := Color(0.86, 0.20, 0.16)
	var B := Color(0.24, 0.62, 0.98)
	var I := Color(0.72, 0.92, 1.0)
	var E := Color(0.24, 0.72, 0.32)
	var W := Color(0.96, 0.96, 0.98)
	var H := Color(0.28, 0.18, 0.12)

	portraits["warrior"] = _from_ascii([
		"....OOOOOOOO....",
		"...OSSSSSSSSO...",
		"..OSSSSSSSSSSO..",
		"..OSSDDDDDDSSO..",
		"..OSDOKKKKODSO..",
		"..OSOKWOKWOKSO..",
		"..OSOKKKKKOKSO..",
		"..OSDKKOOKKDSO..",
		"...OSKHHHHKSO...",
		"..OOGGGGGGGGOO..",
		".ORRGGGGGGGGRRO.",
		".ORRDDDDDDDDRRO.",
		".ODDDDDDDDDDDDO.",
		"..OOOOOOOOOOOO..",
		"................",
		"................"
	], {"O": O, "S": S, "D": D, "K": K, "W": B, "H": H, "G": G, "R": R}, 3)

	portraits["mage"] = _from_ascii([
		"......OOOO......",
		"....OOBBBBOO....",
		"...OBBBBBBBBO...",
		"..OBBBGGGGBBBO..",
		"..OBBOOOOOOBBO..",
		"..OBOKKKKKKOBO..",
		"..OBOKIOKIOKBO..",
		"..OBOKKKKKKOBO..",
		"..OBOKSSSSKOBO..",
		"...OBBWWWWBBO...",
		"..OOBBBBBBBBOO..",
		".OBBGGGGGGGGBBO.",
		".OBBBBBBBBBBBBO.",
		"..OOOOOOOOOOOO..",
		"................",
		"................"
	], {"O": O, "B": B, "G": G, "K": K, "I": I, "S": KS, "W": W}, 3)

	portraits["paladin"] = _from_ascii([
		"....OOOOOOOO....",
		"...OGGGGGGGGO...",
		"..OGGHHHHHHGGO..",
		"..OGGDDDDDDGGO..",
		"..OGOKKKKKKOGO..",
		"..OGOKBOKBOKGO..",
		"..OGOKKKKKKOGO..",
		"..OGOKKSSKKOGO..",
		"...OGGGGGGGGO...",
		"..OOGGGGGGGGOO..",
		".OSSSSGGGGSSSSO.",
		".OSSDDDDDDDDSSO.",
		".ODDDDDDDDDDDDO.",
		"..OOOOOOOOOOOO..",
		"................",
		"................"
	], {"O": O, "G": G, "H": W, "D": D, "K": K, "B": B, "S": S}, 3)

	portraits["ranger"] = _from_ascii([
		"....OOOOOOOO....",
		"...OEEEEEEEEO...",
		"..OEEEEEEEEEEO..",
		"..OEEHHHHHHEEO..",
		"..OEOKKKKKKOEO..",
		"..OEOKGOKGOKEO..",
		"..OEOKKKKKKOEO..",
		"..OEOOKKKKOOEO..",
		"...OEEEEEEEEO...",
		"..OOWWEEEEWWOO..",
		".OWWWEEEEEEWWWO.",
		".OWWDDDDDDDDWWO.",
		".ODDDDDDDDDDDDO.",
		"..OOOOOOOOOOOO..",
		"................",
		"................"
	], {"O": O, "E": E, "H": H, "K": K, "G": G, "W": Color(0.54, 0.34, 0.18), "D": D}, 3)

	portraits["rogue"] = _from_ascii([
		"....OOOOOOOO....",
		"...ODDDDDDDDO...",
		"..ODDDDDDDDDDO..",
		"..ODOKKKKKKODO..",
		"..ODOKROKROKDO..",
		"..ODOKKKKKKODO..",
		"..ODDDDDDDDDDO..",
		"...ODGGGGGGDO...",
		"..OODDDDDDDDOO..",
		".ODDDGGGGGGDDDO.",
		".ODDDDDDDDDDDDO.",
		"..OOOOOOOOOOOO..",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "D": D, "K": K, "R": R, "G": G}, 3)

	portraits["priest"] = _from_ascii([
		"....OOOOOOOO....",
		"...OWWWWWWWWO...",
		"..OWWGGGGGGWWO..",
		"..OWOKKKKKKOWO..",
		"..OWOKBOKBOOWO..",
		"..OWOKKKKKKOWO..",
		"...OWWWWWWWWO...",
		"..OOWWGGGGWWOO..",
		".OWWWWGGGGWWWWO.",
		".OWWWWWWWWWWWWO.",
		"..OOOOOOOOOOOO..",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "W": W, "G": G, "K": K, "B": B}, 3)

	portraits["warlock"] = _from_ascii([
		"..OO........OO..",
		".OGGO.OOOO.OGGO.",
		"..OGGOPPPPOGGO..",
		"..OPPPPPPPPPPO..",
		"..OPOKKKKKKOPO..",
		"..OPOKROKROKPO..",
		"..OPOKKKKKKOPO..",
		"...OPPPPPPPPO...",
		"..OOPPGGGGPPOO..",
		".OPPPPGGGGPPPPO.",
		".OPPPPPPPPPPPPO.",
		"..OOOOOOOOOOOO..",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "P": Color(0.56, 0.22, 0.85), "G": G, "K": K, "R": R}, 3)

	portraits["shaman"] = _from_ascii([
		"....OOOOOOOO....",
		"...OBBBBBBBBO...",
		"..OBBWWBBWWBBO..",
		"..OBOKKKKKKOBO..",
		"..OBOKIOKIOKBO..",
		"..OBOKKKKKKOBO..",
		"...OBBBBBBBBO...",
		"..OOBBWWWWBBOO..",
		".OBBWWWWWWWWBBO.",
		".OBBBBBBBBBBBBO.",
		"..OOOOOOOOOOOO..",
		"................",
		"................",
		"................",
		"................",
		"................"
	], {"O": O, "B": B, "W": Color(0.75, 0.42, 0.22), "K": K, "I": I}, 3)

	portraits["boss"] = _from_ascii([
		"..OO........OO..",
		".ORRO.OOOO.ORRO.",
		".ORRROOOOORRRO..",
		"..ORRDDDDDDRRO..",
		"..ORROKKKKORRO..",
		"..OROKROKROKRO..",
		"..OROKKKKKOKRO..",
		"..ORDKKOOKKDRO..",
		"...ORDWWWWDRRO..",
		"..OORRRRRRRROO..",
		".ODDDRRRRRRDDDO.",
		".ODDDDDDDDDDDDO.",
		"..OOOOOOOOOOOO..",
		"................",
		"................",
		"................"
	], {"O": O, "R": R, "D": D, "K": Color(0.45, 0.55, 0.42), "W": W}, 3)

	portraits["mob"] = _from_ascii([
		"................",
		"...OO......OO...",
		"..ODDO....ODDO..",
		"..ODDDDDDDDDDO..",
		"..ODDDDDDDDDDO..",
		"..ODDRROORRDDO..",
		"..ODDDDDDDDDDO..",
		"..ODDDOOOODDDO..",
		"...ODWOOOOOWO...",
		"...ODDDDDDDDO...",
		"..OODDDDDDDDOO..",
		".ODDDDDDDDDDDDO.",
		"..OOOOOOOOOOOO..",
		"................",
		"................",
		"................"
	], {"O": O, "D": Color(0.55, 0.42, 0.32), "R": R, "W": W}, 3)

func make_orb_texture(fill_col: Color) -> ImageTexture:
	var sz: int = 28
	var img: Image = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(13.5, 13.5)
	for y in range(sz):
		for x in range(sz):
			var d: float = Vector2(x, y).distance_to(center)
			if d > 13.5:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif d > 12.0:
				img.set_pixel(x, y, Color(0.08, 0.06, 0.05, 1.0))
			elif d > 10.7:
				img.set_pixel(x, y, Color(0.75, 0.60, 0.28, 1.0))
			elif d > 9.8:
				img.set_pixel(x, y, Color(0.18, 0.14, 0.10, 1.0))
			else:
				var c: Color = fill_col
				var spec: float = Vector2(x, y).distance_to(Vector2(9.5, 9.0))
				if spec < 2.3:
					c = c.lerp(Color.WHITE, 0.72)
				elif spec < 4.2 and ((x + y) % 2 == 0):
					c = c.lerp(Color.WHITE, 0.30)
				elif d > 7.4:
					c = c.darkened(0.38)
				img.set_pixel(x, y, c)
	img.resize(sz * 2, sz * 2, Image.INTERPOLATE_NEAREST)
	return _tex_from_image(img)

func _build_ground_textures() -> void:
	for z in GameData.ZONES:
		var id: String = str(z["id"])
		var base: Color = z["ground"]
		var acc: Color = z["accent"]
		var img: Image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for y in range(64):
			for x in range(64):
				var h: int = abs(((x * 73856093) ^ (y * 19349663) ^ id.hash()) % 120)
				var c: Color = base
				if h < 18:
					c = acc
				elif h < 28:
					c = base.lightened(0.11)
				elif h < 34:
					c = base.darkened(0.10)
				if id == "elwynn":
					if h == 45:
						c = Color(0.95, 0.85, 0.25)
					elif h == 46:
						c = Color(0.88, 0.36, 0.42)
					elif h >= 50 and h <= 56:
						c = Color(0.26, 0.56, 0.22)
				elif id == "duskwood":
					if h == 60:
						c = Color(0.32, 0.55, 0.58)
				elif id == "barrens":
					if (x + y * 2) % 19 == 0 and h < 45:
						c = acc.darkened(0.22)
				elif id == "frostpeak":
					if h == 70 or h == 71:
						c = Color(0.88, 0.96, 1.0)
				elif id == "plaguelands":
					if h >= 80 and h <= 84:
						c = Color(0.45, 0.72, 0.16)
				elif id == "citadel":
					if (x % 16 == 0 or y % 16 == 0) and h < 42:
						c = Color(0.95, 0.34, 0.06)
				img.set_pixel(x, y, c)
		ground_textures[id] = _tex_from_image(img)

	var road_img: Image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var row: int = y / 8
			var ox: int = (x + (row % 2) * 4) % 16
			var oy: int = y % 8
			var c: Color = Color(0.44, 0.37, 0.28)
			if ox == 0 or oy == 0:
				c = Color(0.24, 0.20, 0.15)
			elif ox == 1 or oy == 1:
				c = Color(0.54, 0.46, 0.35)
			elif ((x * 13 + y * 7) % 17) == 0:
				c = Color(0.38, 0.31, 0.23)
			road_img.set_pixel(x, y, c)
	ground_textures["road"] = _tex_from_image(road_img)

	var dng_img: Image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var tx: int = x % 16
			var ty: int = y % 16
			var c: Color = Color(0.30, 0.29, 0.33)
			if tx == 0 or ty == 0:
				c = Color(0.12, 0.11, 0.14)
			elif tx == 1 or ty == 1:
				c = Color(0.38, 0.37, 0.42)
			elif ((x * 5 + y * 11) % 23) == 0:
				c = Color(0.24, 0.23, 0.27)
			dng_img.set_pixel(x, y, c)
	ground_textures["dungeon"] = _tex_from_image(dng_img)

func _build_world_atlas() -> void:
	var mw: int = 264
	var mh: int = 176
	var img: Image = Image.create(mw, mh, false, Image.FORMAT_RGBA8)
	for py in range(mh):
		var wz: float = (float(py) + 0.5) * (GameData.WORLD_H / float(mh))
		for px in range(mw):
			var wx: float = (float(px) + 0.5) * (GameData.WORLD_W / float(mw))
			var coast: float = GameData.get_coast_signed_dist(wx, wz)
			var h: float = GameData.get_terrain_height(wx, wz)
			var zb: Dictionary = GameData.get_zone_blended(wx, wz)
			var zid: String = str(zb["id"])
			var col: Color = zb["ground"]

			if coast <= 0.0 or h < GameData.WATER_Y + 0.04:
				if coast > -0.045 and coast <= 0.0:
					col = Color(0.56, 0.80, 0.94)
				else:
					col = Color(0.06, 0.22, 0.44) if ((px + py) % 3 != 0) else Color(0.10, 0.28, 0.52)
			elif GameData.get_road_dist(wx, wz) < 3.6:
				col = Color(0.38, 0.28, 0.22) if zid == "citadel" else Color(0.62, 0.50, 0.34)
			else:
				if h < GameData.WATER_Y + 0.48:
					col = Color(0.28, 0.20, 0.16) if zid == "citadel" else Color(0.76, 0.66, 0.46)
				var h_dx: float = GameData.get_terrain_height(wx + 3.0, wz) - h
				var h_dz: float = GameData.get_terrain_height(wx, wz + 3.0) - h
				var slope: float = clampf(-(h_dx + h_dz) * 0.38, -0.28, 0.28)
				if h > 2.8:
					if zid == "frostpeak":
						col = Color(0.90, 0.96, 1.0)
					elif zid == "citadel":
						col = Color(0.24, 0.14, 0.14)
					else:
						col = Color(0.46, 0.44, 0.48)
				col = col.lightened(maxf(0.0, slope)) if slope >= 0.0 else col.darkened(maxf(0.0, -slope))

			if px == 0 or py == 0 or px == mw - 1 or py == mh - 1:
				col = Color(0.10, 0.08, 0.06)
			img.set_pixel(px, py, col)
	world_map_tex = _tex_from_image(img)

func get_skill_icon(skill_id: String) -> ImageTexture:
	if icons.has(skill_id):
		return icons[skill_id]
	return icons["weapon"]

func get_item_icon(slot: String) -> ImageTexture:
	if icons.has(slot):
		return icons[slot]
	return icons["weapon"]
