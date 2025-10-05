extends VBoxContainer

class Toast:
	var label: Label
	var expirery: int

var toasts: Array[Toast] = []

func _process(_delta: float):
	var ticks = Time.get_ticks_msec()
	while !toasts.is_empty() && toasts[0].expirery < ticks:
		toasts.pop_front().label.queue_free()

func add_toast(text: String):
	while toasts.size() > 3:
		toasts.pop_front().label.queue_free()
	var toast = Toast.new()
	toast.label = Label.new()
	if text.length() > 128:
		text = text.left(128) + "…"
	toast.label.text = text
	toast.label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(toast.label)
	toast.expirery = Time.get_ticks_msec() + 15000
	toasts.push_back(toast)
