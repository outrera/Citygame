extends Node

var _Turn = 0
# authority: cur, delta
var Auth  = [10,5]
# difference of authority per turn
var pop = [0,0,0] # cur, max, delta

var _state = "begin" setget set_state
var klick = [false,Vector2(-1,-1)]
var _mp
var _lmp

func set_state(_s):
	# XOR
	if (_s!="begin" and _state!="idle") or (_s=="begin" and _state=="idle"):
		call(str("e_"+_state))
	_state = _s
	if _s != "idle":
		set_process(true)
		set_process_unhandled_input(true)
		call(_state)
	else:
		set_process(false)
		set_process_unhandled_input(false)

func _process(delta):
	_mp = Global.Game.get_global_mouse_pos()
	_lmp = get_tree().get_root().get_mouse_pos()
	Global.UI.update()
	call(str("p_"+_state))
	klick[0] = false
	klick[1] = Vector2(-1,-1)

func begin():
	
	Global.Popups.generate_alert("InitPopup")
	Global.Helpers.add_map_helper("start_helper",preload("res://UI/map_icons/map_icons.png"),true,Rect2(Vector2(0,0),Vector2(32,32)))
	var _s =\
	"""Chose your start location. It must be:
\t- straight road
\t- no Forests on sides
Valid location will be marked as green square."""
	Global.Popups.create_tooltip("start_mssg")
	Global.Popups.get_node("start_mssg").set_pos(Vector2(50,50))
	Global.Popups.get_node("start_mssg").width = 305
	Global.Popups.get_node("start_mssg").set_text(_s)

func p_begin():
	
	Global.Helpers.get_node("start_helper").set_region_rect(Rect2(Vector2(32,0),Vector2(32,32)))
	if Global.Level.content_has(floor(_mp.x/64),floor(_mp.y/64),"Road"):
		if Global.Level.get_node("Roads").get_cellv((_mp/64).floor()) == 0 and\
		Global.Level.content_has_any(floor(_mp.x/64),floor(_mp.y/64)+1,["House","Trees","River"]) == false and \
		Global.Level.content_has_any(floor(_mp.x/64),floor(_mp.y/64)-1,["House","Trees","River"]) == false:
			Global.Helpers.get_node("start_helper").set_region_rect(Rect2(Vector2(0,0),Vector2(32,32)))
			if klick[0] and klick[0] == "l":
				Economy.add_entitie("House",[floor(_mp.x/64),floor(_mp.y/64)+1])
				Economy.add_entitie("House",[floor(_mp.x/64),floor(_mp.y/64)-1])
				set_state("popup_content_menu")
		elif Global.Level.get_node("Roads").get_cell((_mp/64).floor().x,(_mp/64).floor().y) == 1 and \
		Global.Level.content_has_any(floor(_mp.x/64)+1,floor(_mp.y/64),["House","Trees","River"]) == false and \
		Global.Level.content_has_any(floor(_mp.x/64)-1,floor(_mp.y/64),["House","Trees","River"]) == false:
			Global.Helpers.get_node("start_helper").set_region_rect(Rect2(Vector2(0,0),Vector2(32,32)))
			if klick[0] and klick[0] == "l":
				Economy.add_entitie("House",[floor(_mp.x/64)+1,floor(_mp.y/64)])
				Economy.add_entitie("House",[floor(_mp.x/64)-1,floor(_mp.y/64)])
				set_state("popup_content_menu")
		Global.UI.update()

func e_begin():
	
	Global.Helpers.del_map_helper("start_helper")
	Global.Popups.get_node("start_mssg").free()
	Global.UI.get_node("Stats/NextTurn").set_disabled(false)

func popup_content_menu():
	Global.Popups.create_tooltip("tooltip_man")
	Global.Popups.get_node("tooltip_man").hide()
	var _hm = PopupMenu.new()
	_hm.set_name("obj_lst")
	_hm.connect("item_pressed",self,"_pass_bbc")
	_hm.connect("about_to_show",self,"_pop_menu_opened")
	Global.HUD.add_child(_hm)

func p_popup_content_menu():
	if typeof(klick[0]) == 4:
		if klick[0] == "l":
			if Global.HUD.get_node("obj_lst").is_hidden():
				Global.HUD.get_node("obj_lst").clear()
				Global.HUD.get_node("obj_lst").set_pos(_lmp.floor())
				for i in Global.content(Vector2(_mp/64).floor()):
					if i.values()[0].get("tooltip") != null:
						Global.HUD.get_node("obj_lst").add_item(i.keys()[0])
				Global.HUD.get_node("obj_lst").add_item("Range")
				Global.HUD.get_node("obj_lst").add_item("Res")
				Global.HUD.get_node("obj_lst").popup()
			else:
				Global.HUD.get_node("obj_lst").hide()
			if !Global.Popups.get_node("tooltip_man").is_hidden():
				Global.Popups.get_node("tooltip_man").hide()
				Global.Popups.get_node("tooltip_man").clear()
		if klick[0] == "r":
			Global.HUD.get_node("obj_lst").hide()
			Global.Popups.get_node("tooltip_man").hide()

func e_popup_content_menu():
	Global.Popups.get_node("tooltip_man").free()
	Global.HUD.get_node("obj_lst").free()

func layers():
	Global.Helpers.delete_light_helpers()
	var _il = Global.UI.get_node("PanelContainer/VBoxContainer/ItemList")
	_il.show()
	var _si = _il.get_selected_items()
	var _msx = Global.Level.map_size.x
	var _msy = Global.Level.map_size.y
	var _tex = preload("res://UI/map_icons/res.png")
	var _rec =Rect2(Vector2(0,0),Vector2(0,0))
	for x in range(_msx):
		for y in range(_msy):
			for j in Global.Level._content[x][y]:
				for i in _si:
					if j.keys()[0]==(_il.get_item_text(i)):
						Global.Helpers.light_static_helper(_tex,false,_rec,Vector2(2,2),Vector2(x*64,y*64))
#						Global.Helpers.add_map_helper(null,_tex,false,_rec,Vector2(2,2),false,Vector2(x*64,y*64))

func p_layers():
	return

func e_layers():
	Global.Helpers.delete_light_helpers()
	Global.UI.get_node("PanelContainer/VBoxContainer/ItemList").hide()

var _klicked
func _pass_bbc(i):
	
	if Global.HUD.get_node("obj_lst").get_item_text(i)=="Res":
		var _p = Global.Helpers.get_range((_klicked/64).floor().x,(_klicked/64).floor().y,4)
		var wood = 0
		var __tex = preload("res://UI/map_icons/res.png")
		for i in _p:
			if Global.Level.content_has(i.x,i.y,"Trees"):
				wood += Global.Level.content_get(i.x,i.y,"Trees").wood
				Global.Helpers.light_static_helper_v2(__tex,Vector2(2,2),i*64)
		Global.Popups.get_node("tooltip_man").set_text("wood: "+str(wood))
		Global.Popups.get_node("tooltip_man").set_pos(get_viewport().get_mouse_pos())
		Global.Popups.get_node("tooltip_man").show()
	elif Global.HUD.get_node("obj_lst").get_item_text(i)=="Range":
		var _p = Global.Helpers.get_range((_klicked/64).floor().x,(_klicked/64).floor().y,4)
#		var __L = Label.new()
#		__L.set_pos(i*64+Vector2(32,32))
#		__L.set_text(str(__checked[1][__checked[0].find(i)]))
#		add_child(__L)
		var __tex = preload("res://UI/map_icons/res.png")
		for i in _p:
			Global.Helpers.light_static_helper_v2(__tex,Vector2(2,2),i*64)
	else:
		Global.Popups.get_node("tooltip_man").show()
		if Global.content((_klicked/64).floor())[i].values()[0].get("tooltip") != null:
			Global.Popups.get_node("tooltip_man").set_text(Global.content((_klicked/64).floor())[i].values()[0].get("tooltip"))
			Global.Popups.get_node("tooltip_man").show()
			Global.Popups.get_node("tooltip_man").set_pos(_lmp)

func _pop_menu_opened():
	_klicked = _mp
	
var __was_pressed = false
func _unhandled_input(event):
	
	if event.type==InputEvent.MOUSE_BUTTON:
		if event.is_pressed() == true:
			__was_pressed = true
		elif event.is_pressed()==false and event.button_index==1 and __was_pressed == true:
			klick[0] = "l"
			klick[1] = event.global_pos
			__was_pressed = false
		elif event.is_pressed()==false and event.button_index==2 and __was_pressed == true:
			klick[0] = "r"
			klick[1] = event.global_pos
			__was_pressed = false
