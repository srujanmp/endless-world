extends Node
class_name EnvLoader

static func load_env(path: String = "res://.env") -> Dictionary:
	var env: Dictionary = {}

	if not FileAccess.file_exists(path):
		push_warning(".env file not found")
		return env

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return env

	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()

		if line.is_empty() or line.begins_with("#"):
			continue

		var parts := line.split("=", false, 2)
		if parts.size() != 2:
			continue

		env[parts[0].strip_edges()] = parts[1].strip_edges()

	file.close()
	return env
