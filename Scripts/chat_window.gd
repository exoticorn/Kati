extends PanelContainer

enum Type { DIRECT, GROUP }

class Room:
	var type: Type
	var name: String
	var messages: Array[Message] = []

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

func _ready():
	add_room(Type.GROUP, "Global")

func _process(_delta: float):
	if is_visible_in_tree() && last_added_message_control != null:
		scroll_to_last_message.call_deferred()

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		$Box/Input.grab_focus()

func add_message(type: Type, room_name: String, user: String, msg: String):
	var room_index = add_room(type, room_name)
	var room = rooms[room_index]
	var message = Message.new(user, msg)
	room.messages.push_back(message)
	if room_index == $Box/Tabs.current_tab:
		add_message_to_chat(message)

func add_room(type, room) -> int:
	for i in rooms.size():
		if rooms[i].name == room && rooms[i].type == type:
			return i
	$Box/Tabs.add_tab(room)
	rooms.push_back(Room.new(type, room))
	return rooms.size() - 1

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

func scroll_to_last_message():
	if last_added_message_control != null:
		$Box/Panel/Chat.ensure_control_visible(last_added_message_control)
		last_added_message_control = null
