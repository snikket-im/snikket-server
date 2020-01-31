cache = true
allow_defined_top = true
unused_secondaries = false
max_line_length = 150
codes = true
ignore = { "411/err", "421/err", "411/ok", "421/ok", "211/_ENV" };
read_globals = {
	"prosody",
	"hosts",
	"import",

	-- Module instance
	"module.name",
	"module.host",
	"module._log",
	"module.event_handlers",
	"module.reloading",
	"module.saved_state",
	"module.global",
	"module.path",

	-- Module API
	"module.add_extension",
	"module.add_feature",
	"module.add_identity",
	"module.add_item",
	"module.add_timer",
	"module.broadcast",
	"module.context",
	"module.depends",
	"module.fire_event",
	"module.get_directory",
	"module.get_host",
	"module.get_host_items",
	"module.get_host_type",
	"module.get_name",
	"module.get_option",
	"module.get_option_array",
	"module.get_option_boolean",
	"module.get_option_inherited_set",
	"module.get_option_number",
	"module.get_option_path",
	"module.get_option_set",
	"module.get_option_string",
	"module.get_status",
	"module.handle_items",
	"module.hook",
	"module.hook_global",
	"module.hook_object_event",
	"module.hook_tag",
	"module.load_resource",
	"module.log",
	"module.log_status",
	"module.measure",
	"module.measure_event",
	"module.measure_global_event",
	"module.measure_object_event",
	"module.open_store",
	"module.provides",
	"module.remove_item",
	"module.require",
	"module.send",
	"module.send_iq",
	"module.set_global",
	"module.set_status",
	"module.shared",
	"module.unhook",
	"module.unhook_object_event",
	"module.wrap_event",
	"module.wrap_global",
	"module.wrap_object_event",

	-- mod_http API
	"module.http_url",
}
globals = {
	-- Methods that can be set on module API
	"module.unload",
	"module.add_host",
	"module.load",
	"module.add_host",
	"module.save",
	"module.restore",
	"module.command",
	"module.environment",
}
