extends Node
## Cloud — accounts + cross-device save via Supabase (email/password auth + a
## `saves` row per user). Talks straight to Supabase's REST/Auth endpoints over
## HTTPS (works on the web export). All calls are async and return a result dict
## {ok, data, error}. When no backend is configured, the game runs fully local
## and every call here is a graceful no-op, so nothing breaks until credentials
## are pasted into data/backend.json.

signal auth_changed(logged_in: bool)

const TOK_PATH := "user://pw_cloud.json"

var url := ""
var anon := ""
var token := ""
var refresh := ""
var uid := ""
var email := ""
var _push_pending := false

func _ready() -> void:
	url = String(Config.backend.get("supabase_url", "")).strip_edges().rstrip("/")
	anon = String(Config.backend.get("anon_key", "")).strip_edges()
	_load_tokens()

func configured() -> bool:
	return url != "" and anon != ""

func logged_in() -> bool:
	return configured() and token != "" and uid != ""

# ------------------------------------------------------------------ auth
func sign_up(mail: String, pw: String) -> Dictionary:
	if not configured(): return {"ok": false, "error": "no backend configured"}
	var res := await _req("/auth/v1/signup", HTTPClient.METHOD_POST, {"email": mail, "password": pw}, false)
	if res.code >= 200 and res.code < 300:
		_absorb_session(res.data)
		# some projects require email confirmation → no session returned yet
		if token == "":
			return {"ok": true, "data": res.data, "needs_confirm": true}
		return {"ok": true, "data": res.data}
	return {"ok": false, "error": _err(res)}

func sign_in(mail: String, pw: String) -> Dictionary:
	if not configured(): return {"ok": false, "error": "no backend configured"}
	var res := await _req("/auth/v1/token?grant_type=password", HTTPClient.METHOD_POST,
		{"email": mail, "password": pw}, false)
	if res.code >= 200 and res.code < 300:
		_absorb_session(res.data)
		_save_tokens()
		auth_changed.emit(true)
		return {"ok": true, "data": res.data}
	return {"ok": false, "error": _err(res)}

func sign_out() -> void:
	token = ""; refresh = ""; uid = ""; email = ""
	_save_tokens()
	auth_changed.emit(false)

func _absorb_session(d) -> void:
	if typeof(d) != TYPE_DICTIONARY: return
	token = String(d.get("access_token", token))
	refresh = String(d.get("refresh_token", refresh))
	var u = d.get("user", null)
	if typeof(u) == TYPE_DICTIONARY:
		uid = String(u.get("id", uid))
		email = String(u.get("email", email))

func _refresh_session() -> bool:
	if refresh == "": return false
	var res := await _req("/auth/v1/token?grant_type=refresh_token", HTTPClient.METHOD_POST,
		{"refresh_token": refresh}, false)
	if res.code >= 200 and res.code < 300:
		_absorb_session(res.data); _save_tokens(); return true
	return false

# ------------------------------------------------------------------ save sync
## Upsert the player's whole state blob to their row.
func push_save(state: Dictionary) -> Dictionary:
	if not logged_in(): return {"ok": false, "error": "not logged in"}
	var body := {"user_id": uid, "state": state, "updated_at": Time.get_datetime_string_from_system(true)}
	var res := await _rest_upsert(body)
	if res.code == 401 and await _refresh_session():
		res = await _rest_upsert(body)
	return {"ok": res.code >= 200 and res.code < 300, "error": _err(res)}

func _rest_upsert(body: Dictionary) -> Dictionary:
	var extra := PackedStringArray(["Prefer: resolution=merge-duplicates,return=minimal"])
	return await _req("/rest/v1/saves?on_conflict=user_id", HTTPClient.METHOD_POST, body, true, extra)

## Pull the cloud save, or {} if none. Returns {ok, state}.
func pull_save() -> Dictionary:
	if not logged_in(): return {"ok": false, "error": "not logged in"}
	var res := await _req("/rest/v1/saves?user_id=eq." + uid + "&select=state", HTTPClient.METHOD_GET, {}, true)
	if res.code == 401 and await _refresh_session():
		res = await _req("/rest/v1/saves?user_id=eq." + uid + "&select=state", HTTPClient.METHOD_GET, {}, true)
	if res.code >= 200 and res.code < 300 and typeof(res.data) == TYPE_ARRAY and res.data.size() > 0:
		return {"ok": true, "state": res.data[0].get("state", {})}
	return {"ok": true, "state": {}}

## Debounced background push — called from Game.persist() while logged in.
func queue_push() -> void:
	if not logged_in() or _push_pending: return
	_push_pending = true
	await get_tree().create_timer(3.0).timeout
	_push_pending = false
	await push_save(Game.s)

# ------------------------------------------------------------------ http
func _req(path: String, method: int, body: Dictionary, auth: bool, extra := PackedStringArray()) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray(["apikey: " + anon, "Content-Type: application/json"])
	if auth and token != "":
		headers.append("Authorization: Bearer " + token)
	for e in extra:
		headers.append(e)
	var payload := "" if (method == HTTPClient.METHOD_GET or body.is_empty()) else JSON.stringify(body)
	var err := http.request(url + path, headers, method, payload)
	if err != OK:
		http.queue_free()
		return {"code": 0, "data": null}
	var r = await http.request_completed
	http.queue_free()
	var code: int = r[1]
	var text: String = (r[3] as PackedByteArray).get_string_from_utf8()
	var data = JSON.parse_string(text) if text != "" else null
	return {"code": code, "data": data}

func _err(res: Dictionary) -> String:
	if typeof(res.data) == TYPE_DICTIONARY:
		var m = res.data.get("error_description", res.data.get("msg", res.data.get("message", res.data.get("error", ""))))
		if String(m) != "": return String(m)
	if int(res.code) == 0: return "network error"
	return "error %d" % int(res.code)

# ------------------------------------------------------------------ token store
func _save_tokens() -> void:
	var f := FileAccess.open(TOK_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"token": token, "refresh": refresh, "uid": uid, "email": email}))
		f.close()

func _load_tokens() -> void:
	if not FileAccess.file_exists(TOK_PATH): return
	var f := FileAccess.open(TOK_PATH, FileAccess.READ)
	if f == null: return
	var d = JSON.parse_string(f.get_as_text()); f.close()
	if typeof(d) == TYPE_DICTIONARY:
		token = String(d.get("token", "")); refresh = String(d.get("refresh", ""))
		uid = String(d.get("uid", "")); email = String(d.get("email", ""))
