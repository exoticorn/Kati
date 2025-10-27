extends PanelContainer

enum Type { DIRECT, GROUP, SYSTEM }

class Room:
	var type: Type
	var name: String
	var messages: Array[Message] = []
	var unread_count := 0

	func _init(t: Type, n: String):
		type = t
		name = n

class Message:
	var time: String
	var user: String
	var text: String
	
	func _init(u: String, t: String):
		var dt = Time.get_datetime_dict_from_system()
		time = "%02d:%02d" % [dt.hour, dt.minute]
		user = u
		text = t

var rooms: Array[Room]
var last_added_message_control

signal unread_count(count: int, direct: bool)
signal send_message(type: Type, room_name: String, msg: String)
signal leave_room(room_name: String)

func _ready():
	add_room(Type.GROUP, "Global")

func _process(_delta: float):
	if is_visible_in_tree() && last_added_message_control != null:
		scroll_to_last_message.call_deferred()

func _input(event: InputEvent):
	if is_visible_in_tree():
		if event is InputEventKey:
			if event.pressed == true && event.keycode == KEY_TAB:
				if rooms.size() > 1:
					var index = $Box/Tabs.current_tab
					if event.get_modifiers_mask() & KEY_MASK_SHIFT:
						index = (index + rooms.size() - 1)
					else:
						index += 1
					$Box/Tabs.current_tab = index % rooms.size()

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		$Box/Input.grab_focus()

func add_message(type: Type, room_name: String, user: String, msg: String, from_remote: bool):
	var room_index = add_room(type, room_name)
	var room = rooms[room_index]
	var message = Message.new(user, msg)
	room.messages.push_back(message)
	room.unread_count += 1
	$Box/Tabs.set_tab_title(room_index, "%s (%d)" % [room.name, room.unread_count])
	if room_index == $Box/Tabs.current_tab:
		add_message_to_chat(message)
	emit_unread_count()
	if type == Type.DIRECT && from_remote:
		$StreamPlayer.stream = preload("res://sfx/chat.wav")
		$StreamPlayer.play()
	elif type == Type.GROUP && from_remote:
		$StreamPlayer.stream = preload("res://sfx/groupchat.wav")
		$StreamPlayer.play()

func add_room(type, room) -> int:
	for i in rooms.size():
		if rooms[i].name == room && rooms[i].type == type:
			return i
	$Box/Tabs.add_tab(room)
	var room_index = rooms.size()
	rooms.push_back(Room.new(type, room))
	$Box/Tabs.current_tab = room_index
	return room_index


func select_room(room: String) -> void:
	var index = rooms.find_custom(func (r): return r.name == room)
	if index >= 0:
		$Box/Tabs.current_tab = index


func add_message_to_chat(message):
	var grid = $Box/Panel/Chat/Grid
	var time_label = Label.new()
	time_label.text = message.time
	time_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	grid.add_child(time_label)
	var name_label = Label.new()
	name_label.text = message.user
	name_label.add_theme_color_override("font_color", Color.from_hsv((message.user.md5_buffer()[0]) / 255.0, 0.5, 0.8))
	name_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	grid.add_child(name_label)
	var text_label = Label.new()
	text_label.text = message.text
	text_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	grid.add_child(text_label)
	last_added_message_control = text_label

func _on_tabs_tab_changed(tab: int) -> void:
	for child in $Box/Panel/Chat/Grid.get_children():
		child.queue_free()
	last_added_message_control = null
	if tab >= 0 && tab < rooms.size():
		var room = rooms[tab]
		for message in room.messages:
			add_message_to_chat(message)
		$Box/Input.visible = room.type != Type.SYSTEM

func scroll_to_last_message():
	if last_added_message_control != null:
		$Box/Panel/Chat.ensure_control_visible(last_added_message_control)
		last_added_message_control = null
		var room_index = $Box/Tabs.current_tab
		if room_index >= 0 && room_index < rooms.size():
			var room = rooms[room_index]
			room.unread_count = 0
			$Box/Tabs.set_tab_title(room_index, room.name)
			emit_unread_count()

func emit_unread_count():
	var unread = 0
	var direct = false
	for room in rooms:
		if room.type != Type.SYSTEM:
			unread += room.unread_count
		if room.type == Type.DIRECT && room.unread_count > 0:
			direct = true
	unread_count.emit(unread, direct)

func _on_input_text_submitted(new_text: String):
	var room_index = $Box/Tabs.current_tab
	if room_index >= 0 && room_index < rooms.size():
		var room = rooms[room_index]
		send_message.emit(room.type, room.name, new_text)
	$Box/Input.text = ""


func _on_tabs_tab_close_pressed(tab: int) -> void:
	var current_tab = $Box/Tabs.current_tab
	var room = rooms[tab]
	if room.type == Type.GROUP && room.name != "Global":
		leave_room.emit(room.name)
	$Box/Tabs.remove_tab(tab)
	rooms.remove_at(tab)
	if tab == current_tab && $Box/Tabs.current_tab == current_tab:
		_on_tabs_tab_changed(current_tab)
