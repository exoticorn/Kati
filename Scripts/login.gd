const Login = preload("res://Scripts/login.gd")

const path = "user://login.res"
const key = "v8dQXEitsh17PV" # marginally better than plain-text

var user: String
var password: String
var remember_me: bool

func _init(usr: String, pw: String, remember: bool):
	user = usr
	password = pw
	remember_me = remember

func is_valid() -> bool:
	return user != "" && password != ""

func make_guest():
	if user != "Guest":
		user = "Guest"
		password = ""
		for i in 20:
			password += char(randi_range(97, 122))
		remember_me = true

func is_guest():
	return user == "Guest"

static func load() -> Login:
	var config = ConfigFile.new()
	config.load_encrypted_pass(path, key)
	return Login.new(config.get_value("login", "user", ""), config.get_value("login", "password", ""), false)

func save():
	if remember_me:
		var config = ConfigFile.new()
		config.set_value("login", "user", user)
		config.set_value("login", "password", password)
		config.save_encrypted_pass(path, key)

func forget():
	var config = ConfigFile.new()
	config.save_encrypted_pass(path, key)
