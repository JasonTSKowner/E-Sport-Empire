class_name BackupCodec
extends RefCounted

const PREFIX := "EE22-"


static func encode(save_data: Dictionary) -> String:
	var payload := save_data.duplicate(true)
	payload["backup_exported_at"] = int(Time.get_unix_time_from_system())
	var json := JSON.stringify(payload)
	var raw := json.to_utf8_buffer()
	var compressed := raw.compress(FileAccess.COMPRESSION_GZIP)
	var body := Marshalls.raw_to_base64(compressed)
	var checksum := body.sha256_text().left(12).to_upper()
	return "%s%s-%s" % [PREFIX, checksum, body]


static func decode(code: String) -> Dictionary:
	var cleaned := code.strip_edges().replace("\n", "").replace("\r", "")
	if not cleaned.begins_with(PREFIX):
		return {"ok": false, "message": "Kein gültiger Empire-Backup-Code."}
	var payload := cleaned.trim_prefix(PREFIX)
	var separator := payload.find("-")
	if separator <= 0:
		return {"ok": false, "message": "Backup-Code ist unvollständig."}
	var checksum := payload.left(separator)
	var body := payload.substr(separator + 1)
	if body.sha256_text().left(12).to_upper() != checksum:
		return {"ok": false, "message": "Backup-Code ist beschädigt oder verändert."}
	var compressed := Marshalls.base64_to_raw(body)
	if compressed.is_empty():
		return {"ok": false, "message": "Backup-Daten konnten nicht gelesen werden."}
	var raw := compressed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	if raw.is_empty():
		return {"ok": false, "message": "Backup-Daten konnten nicht entpackt werden."}
	var parsed = JSON.parse_string(raw.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "message": "Backup enthält keinen gültigen Spielstand."}
	return {"ok": true, "data": parsed}
