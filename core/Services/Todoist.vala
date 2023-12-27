/*
* Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Services.Todoist : GLib.Object {
	private Soup.Session session;
	private Json.Parser parser;

	private const string TODOIST_SYNC_URL = "https://api.todoist.com/sync/v9/sync";
	private const string PROJECTS_COLLECTION = "projects";
	private const string SECTIONS_COLLECTION = "sections";
	private const string ITEMS_COLLECTION = "items";
	private const string LABELS_COLLECTION = "labels";

	private static Todoist? _instance;
	public static Todoist get_default () {
		if (_instance == null) {
			_instance = new Todoist ();
		}

		return _instance;
	}

	public signal void sync_started ();
	public signal void sync_finished ();

	public signal void first_sync_started ();
	public signal void first_sync_finished (string inbox_project_id);
	public signal void first_sync_progress (double value);

	public signal void log_out ();
	public signal void log_in ();

	private uint server_timeout = 0;

	public Todoist () {
		session = new Soup.Session ();
		parser = new Json.Parser ();

		var network_monitor = GLib.NetworkMonitor.get_default ();
		network_monitor.network_changed.connect (() => {
			if (GLib.NetworkMonitor.get_default ().network_available &&
			    Services.Settings.get_default ().settings.get_boolean ("todoist-sync-server")) {
				sync_async ();
			}
		});
	}

	public void run_server () {
		sync_async ();

		server_timeout = Timeout.add_seconds (15 * 60, () => {
			if (Services.Settings.get_default ().settings.get_boolean ("todoist-sync-server")) {
				sync_async ();
			}

			return true;
		});
	}

	public void remove_items () {
		Services.Settings.get_default ().settings.set_string ("todoist-sync-token", "");
		Services.Settings.get_default ().settings.set_string ("todoist-access-token", "");
		Services.Settings.get_default ().settings.set_string ("todoist-last-sync", "");
		Services.Settings.get_default ().settings.set_string ("todoist-user-email", "");
		Services.Settings.get_default ().settings.set_string ("todoist-user-name", "");
		Services.Settings.get_default ().settings.set_string ("todoist-user-avatar", "");
		Services.Settings.get_default ().settings.set_string ("todoist-user-image-id", "");
		Services.Settings.get_default ().settings.set_boolean ("todoist-sync-server", false);
		Services.Settings.get_default ().settings.set_boolean ("todoist-user-is-premium", false);

		// Delete all projects, sections and items
		foreach (var project in Services.Database.get_default ().get_all_projects_by_todoist ()) {
			Services.Database.get_default ().delete_project (project);
		}

		// Delete all labels;
		foreach (var label in Services.Database.get_default ().get_all_labels_by_todoist ()) {
			Services.Database.get_default ().delete_label (label);
		}

		// Clear Queue
		Services.Database.get_default ().clear_queue ();

		// Clear CurTempIds
		Services.Database.get_default ().clear_cur_temp_ids ();

		// Check Inbox Project
		if (Services.Settings.get_default ().settings.get_enum ("default-inbox") == 1) {
			Services.Settings.get_default ().settings.set_enum ("default-inbox", 0);
			Util.get_default ().change_default_inbox ();
		}

		// Remove server_timeout
		Source.remove (server_timeout);
		server_timeout = 0;

		log_out ();
	}

	public bool invalid_token () {
		return Services.Settings.get_default ().settings.get_string ("todoist-access-token").strip () == "";
	}

	public bool is_logged_in () {
		return !invalid_token ();
	}

	public async void get_todoist_token (string _url) {
		string code = _url.split ("=") [1];
		code = code.split ("&") [0];

		string url = "https://todoist.com/oauth/access_token?client_id=%s&client_secret=%s&code=%s".printf (
			Constants.TODOIST_CLIENT_ID, Constants.TODOIST_CLIENT_SECRET, code);

		var message = new Soup.Message ("POST", url);

		try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
			parser.load_from_data ((string) stream.get_data ());

			// Debug
			print_root (parser.get_root ());

			var root = parser.get_root ().get_object ();
			var token = root.get_string_member ("access_token");

			yield first_sync (token);
		} catch (Error e) {

		}
	}

	public async void first_sync (string token) {
		first_sync_started ();

		string url = TODOIST_SYNC_URL;
		url = url + "?sync_token=" + "*";
		url = url + "&resource_types=" + "[\"all\"]";

		var message = new Soup.Message ("POST", url);
		message.request_headers.append ("Authorization", "Bearer %s".printf (token));

		try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
			parser.load_from_data ((string) stream.get_data ());

			// Debug
			print_root (parser.get_root ());
			first_sync_progress (0.15);

			Services.Settings.get_default ().settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));
			Services.Settings.get_default ().settings.set_string ("todoist-access-token", token);
			Services.Settings.get_default ().settings.set_boolean ("todoist-sync-server", true);

			// Create user
			var user_object = parser.get_root ().get_object ().get_object_member ("user");
			if (user_object.get_null_member ("image_id") == false) {
				Services.Settings.get_default ().settings.set_string ("todoist-user-image-id", user_object.get_string_member ("image_id"));
				Services.Settings.get_default ().settings.set_string ("todoist-user-avatar", user_object.get_string_member ("avatar_s640"));
			}

			// Set Inbox
			string inbox_project_id = user_object.get_string_member ("inbox_project_id");
			Services.Settings.get_default ().settings.set_string ("todoist-inbox-project-id", inbox_project_id);
			Services.Settings.get_default ().settings.set_string ("todoist-user-name", user_object.get_string_member ("full_name"));
			Services.Settings.get_default ().settings.set_string ("todoist-user-email", user_object.get_string_member ("email"));
			Services.Settings.get_default ().settings.set_boolean ("todoist-user-is-premium", user_object.get_boolean_member ("is_premium"));

			// Create Labels
			unowned Json.Array labels = parser.get_root ().get_object ().get_array_member (LABELS_COLLECTION);
			foreach (unowned Json.Node _node in labels.get_elements ()) {
				Services.Database.get_default ().insert_label (new Objects.Label.from_json (_node));
			}

			first_sync_progress (0.35);

			// Create Projects
			unowned Json.Array projects = parser.get_root ().get_object ().get_array_member (PROJECTS_COLLECTION);
			foreach (unowned Json.Node _node in projects.get_elements ()) {
				if (!_node.get_object ().get_null_member ("parent_id")) {
					Objects.Project? project = Services.Database.get_default ().get_project (_node.get_object ().get_string_member ("parent_id"));
					if (project != null) {
						project.add_subproject_if_not_exists (new Objects.Project.from_json (_node));
					}
				} else {
					Services.Database.get_default ().insert_project (new Objects.Project.from_json (_node));
				}
			}

			first_sync_progress (0.50);

			// Create Sections
			unowned Json.Array sections = parser.get_root ().get_object ().get_array_member (SECTIONS_COLLECTION);
			foreach (unowned Json.Node _node in sections.get_elements ()) {
				add_section_if_not_exists (_node);
			}

			first_sync_progress (0.75);

			// Create Items
			unowned Json.Array items = parser.get_root ().get_object ().get_array_member (ITEMS_COLLECTION);
			foreach (unowned Json.Node _node in items.get_elements ()) {
				add_item_if_not_exists (_node);
			}

			first_sync_progress (0.85);

			// Download Profile Image
			if (user_object.get_null_member ("image_id") == false) {
				Util.get_default ().download_profile_image (
					"todoist-user", user_object.get_string_member ("avatar_s640")
					);
			}

			first_sync_progress (1);
			first_sync_finished (inbox_project_id);
			log_in ();
			Services.Settings.get_default ().settings.set_string ("todoist-last-sync", new GLib.DateTime.now_local ().to_string ());
		} catch (Error e) {
			debug (e.message);
		}
	}

	/*
	 *   Sync
	 */

	public void sync_async () {
		sync_started ();
		sync.begin ((obj, res) => {
			sync.end (res);
			queue.begin ((obj, res) => {
				queue.end (res);
				sync_finished ();
			});
		});
	}

	public async void sync () {
		string url = TODOIST_SYNC_URL;
		url = url + "?sync_token=" + Services.Settings.get_default ().settings.get_string ("todoist-sync-token");
		url = url + "&resource_types=" + "[\"all\"]";

		var message = new Soup.Message ("POST", url);
		message.request_headers.append ("Authorization", "Bearer %s".printf (Services.Settings.get_default ().settings.get_string ("todoist-access-token")));

		try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.LOW, null);
			parser.load_from_data ((string) stream.get_data ());

			// Debug
			print_root (parser.get_root ());

			if (!parser.get_root ().get_object ().has_member ("error")) {
				// Update sync token
				Services.Settings.get_default ().settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));

				// Update user
				if (parser.get_root ().get_object ().has_member ("user")) {
					var user_object = parser.get_root ().get_object ().get_object_member ("user");
					Services.Settings.get_default ().settings.set_boolean ("todoist-user-is-premium", user_object.get_boolean_member ("is_premium"));
					Services.Settings.get_default ().settings.set_string ("todoist-user-name", user_object.get_string_member ("full_name"));
					Services.Settings.get_default ().settings.set_string ("todoist-user-email", user_object.get_string_member ("email"));
				}

				// Labels
				unowned Json.Array _labels = parser.get_root ().get_object ().get_array_member (LABELS_COLLECTION);
				foreach (unowned Json.Node _node in _labels.get_elements ()) {
					string _id = _node.get_object ().get_string_member ("id");
					Objects.Label? label = Services.Database.get_default ().get_label (_id);
					if (label != null) {
						if (_node.get_object ().get_boolean_member ("is_deleted")) {
							Services.Database.get_default ().delete_label (label);
						} else {
							label.update_from_json (_node);
							Services.Database.get_default ().update_label (label);
						}
					} else {
						Services.Database.get_default ().insert_label (new Objects.Label.from_json (_node));
					}
				}

				// Projects
				unowned Json.Array projects = parser.get_root ().get_object ().get_array_member (PROJECTS_COLLECTION);
				foreach (unowned Json.Node _node in projects.get_elements ()) {
					Objects.Project? project = Services.Database.get_default ().get_project (_node.get_object ().get_string_member ("id"));
					if (project != null) {
						if (_node.get_object ().get_boolean_member ("is_deleted")) {
							Services.Database.get_default ().delete_project (project);
						} else {
							string old_parent_id = project.parent_id;
							bool old_is_favorite = project.is_favorite;

							project.update_from_json (_node);
							Services.Database.get_default ().update_project (project);

							if (project.parent_id != old_parent_id) {
								Services.EventBus.get_default ().project_parent_changed (project, old_parent_id);
							}

							if (project.is_favorite != old_is_favorite) {
								Services.EventBus.get_default ().favorite_toggled (project);
							}
						}
					} else {
						Services.Database.get_default ().insert_project (new Objects.Project.from_json (_node));
					}
				}

				// Sections
				unowned Json.Array sections = parser.get_root ().get_object ().get_array_member (SECTIONS_COLLECTION);
				foreach (unowned Json.Node _node in sections.get_elements ()) {
					Objects.Section? section = Services.Database.get_default ().get_section (_node.get_object ().get_string_member ("id"));
					if (section != null) {
						if (_node.get_object ().get_boolean_member ("is_deleted")) {
							Services.Database.get_default ().delete_section (section);
						} else {
							section.update_from_json (_node);
							Services.Database.get_default ().update_section (section);
						}
					} else {
						add_section_if_not_exists (_node);
					}
				}

				// Items
				unowned Json.Array items = parser.get_root ().get_object ().get_array_member (ITEMS_COLLECTION);
				foreach (unowned Json.Node _node in items.get_elements ()) {
					Objects.Item? item = Services.Database.get_default ().get_item (_node.get_object ().get_string_member ("id"));
					if (item != null) {
						if (_node.get_object ().get_boolean_member ("is_deleted")) {
							Services.Database.get_default ().delete_item (item);
						} else {
							string old_project_id = item.project_id;
							string old_section_id = item.section_id;
							string old_parent_id = item.parent_id;

							item.update_from_json (_node);
							Services.Database.get_default ().update_item (item);

							if (old_project_id != item.project_id || old_section_id != item.section_id ||
							    old_parent_id != item.parent_id) {
								Services.EventBus.get_default ().item_moved (item, old_project_id, old_section_id, old_parent_id);
							}

							bool old_checked = item.checked;
							if (old_checked != item.checked) {
								Services.Database.get_default ().checked_toggled (item, old_checked);
							}
						}
					} else {
						add_item_if_not_exists (_node);
					}
				}

				Services.Settings.get_default ().settings.set_string ("todoist-last-sync", new GLib.DateTime.now_local ().to_string ());
			}
		} catch (Error e) {
			debug (e.message);
		}
	}

	/*
	 *   Queue
	 */

	public void queue_async () {
		queue.begin ((obj, res) => {
			queue.end (res);
		});
	}

	public async void queue () {
		Gee.ArrayList<Objects.Queue?> queue = Services.Database.get_default ().get_all_queue ();
		string json = get_queue_json (queue);

		var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
		message.request_headers.append (
			"Authorization",
			"Bearer %s".printf (Services.Settings.get_default ().settings.get_string ("todoist-access-token"))
		);
		message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

		try {
		    GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.LOW, null);
		    parser.load_from_data ((string) stream.get_data ());

		    // Debug
		    print_root (parser.get_root ());

		    var node = parser.get_root ().get_object ();
		    string sync_token = node.get_string_member ("sync_token");
		    Services.Settings.get_default ().settings.set_string ("todoist-sync-token", sync_token);

		    foreach (var q in queue) {
		        var uuid_member = node.get_object_member ("sync_status").get_member (q.uuid);
		        if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
		            if (q.query == "project_add") {
		                var id = node.get_object_member ("temp_id_mapping").get_string_member (q.temp_id);
		                Services.Database.get_default ().update_project_id (q.object_id, id);
		                Services.Database.get_default ().remove_CurTempIds (q.object_id);
		            }

		            if (q.query == "section_add") {
		                var id = node.get_object_member ("temp_id_mapping").get_string_member (q.temp_id);
		                Services.Database.get_default ().update_section_id (q.object_id, id);
		                Services.Database.get_default ().remove_CurTempIds (q.object_id);
		            }

		            if (q.query == "item_add") {
		                var id = node.get_object_member ("temp_id_mapping").get_string_member (q.temp_id);
		                Services.Database.get_default ().update_item_id (q.object_id, id);
		                Services.Database.get_default ().remove_CurTempIds (q.object_id);
		            }

		            Services.Database.get_default ().remove_queue (q.uuid);
		        } else {
		            //var http_code = (int32) sync_status.get_object_member (uuid).get_int_member ("http_code");
		            //var error_message = sync_status.get_object_member (uuid).get_string_member ("error");
		            //project_added_error (http_code, error_message);
		        }
		    }
		} catch (Error e) {

		}
	}

	public string get_queue_json (Gee.ArrayList<Objects.Queue?> queue) {
		var builder = new Json.Builder ();
		builder.begin_object ();
            builder.set_member_name ("commands");

			builder.begin_array ();
			foreach (var q in queue) {
				builder.begin_object ();

				if (q.query == "project_add") {
					builder.set_member_name ("type");
					builder.add_string_value ("project_add");

					builder.set_member_name ("temp_id");
					builder.add_string_value (q.temp_id);

					builder.set_member_name ("uuid");
					builder.add_string_value (q.uuid);

					builder.set_member_name ("args");
					builder.begin_object ();

					builder.set_member_name ("name");
					builder.add_string_value (get_string_member_by_object (q.args, "name"));

					builder.set_member_name ("color");
					builder.add_string_value (get_string_member_by_object (q.args, "color"));

					builder.end_object ();
					builder.end_object ();
				} else if (q.query == "project_update") {
					builder.set_member_name ("type");
					builder.add_string_value ("project_update");

					builder.set_member_name ("uuid");
					builder.add_string_value (q.uuid);

					builder.set_member_name ("args");
					builder.begin_object ();
					builder.set_member_name ("id");
					builder.add_string_value (get_string_member_by_object (q.args, "id"));

					builder.set_member_name ("name");
					builder.add_string_value (get_string_member_by_object (q.args, "name"));

					builder.set_member_name ("color");
					builder.add_string_value (get_string_member_by_object (q.args, "color"));

					builder.end_object ();
					builder.end_object ();
				} else if (q.query == "project_delete") {
					builder.set_member_name ("type");
					builder.add_string_value ("project_delete");

					builder.set_member_name ("uuid");
					builder.add_string_value (q.uuid);

					builder.set_member_name ("args");
					builder.begin_object ();

					builder.set_member_name ("id");
					builder.add_string_value (get_string_member_by_object (q.args, "id"));

					builder.end_object ();
					builder.end_object ();
				} else if (q.query == "section_add") {
					builder.set_member_name ("type");
					builder.add_string_value ("section_add");

					builder.set_member_name ("temp_id");
					builder.add_string_value (q.temp_id);

					builder.set_member_name ("uuid");
					builder.add_string_value (q.uuid);

					builder.set_member_name ("args");
					builder.begin_object ();

					builder.set_member_name ("name");
					builder.add_string_value (get_string_member_by_object (q.args, "name"));

					builder.set_member_name ("project_id");
					if (get_type_by_member (q.args, "project_id") == GLib.Type.STRING) {
						builder.add_string_value (get_string_member_by_object (q.args, "project_id"));
					} else {
						builder.add_string_value (get_string_member_by_object (q.args, "project_id"));
					}

					builder.end_object ();
					builder.end_object ();
				} else if (q.query == "section_update") {
					builder.set_member_name ("type");
					builder.add_string_value ("section_update");

					builder.set_member_name ("uuid");
					builder.add_string_value (q.uuid);

					builder.set_member_name ("args");
					builder.begin_object ();
					builder.set_member_name ("id");
					builder.add_string_value (get_string_member_by_object (q.args, "id"));

					builder.set_member_name ("name");
					builder.add_string_value (get_string_member_by_object (q.args, "name"));

					builder.end_object ();
					builder.end_object ();
				} else if (q.query == "section_delete") {
					builder.set_member_name ("type");
					builder.add_string_value ("section_delete");

					builder.set_member_name ("uuid");
					builder.add_string_value (q.uuid);

					builder.set_member_name ("args");
					builder.begin_object ();

					builder.set_member_name ("id");
					builder.add_string_value (get_string_member_by_object (q.args, "id"));

					builder.end_object ();
					builder.end_object ();
				} else if (q.query == "section_move") {
					builder.set_member_name ("type");
					builder.add_string_value ("section_move");

					builder.set_member_name ("uuid");
					builder.add_string_value (q.uuid);

					builder.set_member_name ("args");
					builder.begin_object ();

					builder.set_member_name ("id");
					builder.add_string_value (get_string_member_by_object (q.args, "id"));

					builder.set_member_name ("project_id");
					builder.add_string_value (get_string_member_by_object (q.args, "project_id"));

					builder.end_object ();
					builder.end_object ();
				} else if (q.query == "item_add") {
					builder.set_member_name ("type");
					builder.add_string_value ("item_add");

					builder.set_member_name ("temp_id");
					builder.add_string_value (q.temp_id);

					builder.set_member_name ("uuid");
					builder.add_string_value (q.uuid);

					builder.set_member_name ("args");
					builder.begin_object ();

					builder.set_member_name ("content");
					builder.add_string_value (get_string_member_by_object (q.args, "content"));

					builder.set_member_name ("description");
					builder.add_string_value (get_string_member_by_object (q.args, "description"));

					builder.set_member_name ("priority");
					builder.add_int_value (get_int_member_by_object (q.args, "priority"));

					builder.set_member_name ("project_id");
					builder.add_string_value (get_string_member_by_object (q.args, "project_id"));

					builder.set_member_name ("section_id");
					builder.add_string_value (get_string_member_by_object (q.args, "section_id"));

					builder.set_member_name ("parent_id");
					builder.add_string_value (get_string_member_by_object (q.args, "parent_id"));

					builder.end_object ();
					builder.end_object ();
				} else if (q.query == "item_update") {
					builder.set_member_name ("type");
					builder.add_string_value ("item_update");

					builder.set_member_name ("uuid");
					builder.add_string_value (q.uuid);

					builder.set_member_name ("args");
					builder.begin_object ();

					builder.set_member_name ("id");
					builder.add_string_value (get_string_member_by_object (q.args, "id"));

					builder.set_member_name ("content");
					builder.add_string_value (get_string_member_by_object (q.args, "content"));

					builder.set_member_name ("description");
					builder.add_string_value (get_string_member_by_object (q.args, "description"));

					builder.set_member_name ("priority");
					builder.add_int_value (get_int_member_by_object (q.args, "priority"));

					if (is_null_member (q.args, "due")) {
						builder.set_member_name ("due");
						builder.add_null_value ();
					} else {
						builder.set_member_name ("due");
						builder.begin_object ();

						Json.Object due = get_object_member_by_object (q.args, "due");

						builder.set_member_name ("date");
						builder.add_string_value (due.get_string_member ("date"));

						builder.end_object ();
					}

					builder.end_object ();
					builder.end_object ();
					builder.begin_object ();
				} else if (q.query == "item_delete") {
					builder.set_member_name ("type");
					builder.add_string_value ("item_delete");

					builder.set_member_name ("uuid");
					builder.add_string_value (q.uuid);

					builder.set_member_name ("args");
					builder.begin_object ();

					builder.set_member_name ("id");
					builder.add_string_value (get_string_member_by_object (q.args, "id"));

					builder.end_object ();
					builder.end_object ();
				} else if (q.query == "item_move") {
					builder.set_member_name ("type");
					builder.add_string_value ("item_move");

					builder.set_member_name ("uuid");
					builder.add_string_value (q.uuid);

					builder.set_member_name ("args");
					builder.begin_object ();

					builder.set_member_name ("id");
					builder.add_string_value (get_string_member_by_object (q.args, "id"));

					string type = get_string_member_by_object (q.args, "type");

					builder.set_member_name (type);
					builder.add_string_value (get_string_member_by_object (q.args, type));

					builder.end_object ();
					builder.end_object ();
				} else if (q.query == "item_complete" || q.query == "item_uncomplete") {
					builder.set_member_name ("type");
					builder.add_string_value (q.query);

					builder.set_member_name ("uuid");
					builder.add_string_value (q.uuid);

					builder.set_member_name ("args");
					builder.begin_object ();

					builder.set_member_name ("id");
					builder.add_string_value (get_string_member_by_object (q.args, "id"));

					builder.end_object ();
					builder.end_object ();
				}

				builder.end_object ();
			}

			builder.end_array ();
		builder.end_object ();

		Json.Generator generator = new Json.Generator ();
		Json.Node root = builder.get_root ();
		generator.set_root (root);

		return generator.to_data (null);
	}

	public Json.Object get_object_by_string (string object) {
		var parser = new Json.Parser ();

		try {
			parser.load_from_data (object, -1);
		} catch (Error e) {
			debug (e.message);
		}

		return parser.get_root ().get_object ();
	}

	public int64 get_int_member_by_object (string object, string member) {
		return get_object_by_string (object).get_int_member (member);
	}

	public string get_string_member_by_object (string object, string member) {
		return get_object_by_string (object).get_string_member (member);
	}

	public Json.Object get_object_member_by_object (string object, string member) {
		return get_object_by_string (object).get_object_member (member);
	}

	public GLib.Type get_type_by_member (string object, string member) {
		return get_object_by_string (object).get_member (member).get_value_type ();
	}

	public bool is_null_member (string object, string member) {
		return get_object_by_string (object).get_null_member (member);
	}

	private void add_item_if_not_exists (Json.Node node) {
		if (!node.get_object ().get_null_member ("parent_id")) {
			Objects.Item? item = Services.Database.get_default ().get_item (node.get_object ().get_string_member ("parent_id"));
			if (item != null) {
				item.add_item_if_not_exists (new Objects.Item.from_json (node));
			}

			return;
		}

		if (!node.get_object ().get_null_member ("section_id")) {
			Objects.Section? section = Services.Database.get_default ().get_section (node.get_object ().get_string_member ("section_id"));
			if (section != null) {
				section.add_item_if_not_exists (new Objects.Item.from_json (node));
			}
		} else {
			Objects.Project? project = Services.Database.get_default ().get_project (node.get_object ().get_string_member ("project_id"));
			if (project != null) {
				project.add_item_if_not_exists (new Objects.Item.from_json (node));
			}
		}
	}

	public async TodoistResponse add (Objects.BaseObject object) {
		string temp_id = Util.get_default ().generate_string ();
		string uuid = Util.get_default ().generate_string ();
		string id;
		string json = object.get_add_json (temp_id, uuid);
		
		var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
		message.request_headers.append (
			"Authorization",
			"Bearer %s".printf (Services.Settings.get_default ().settings.get_string ("todoist-access-token"))
		);
		message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

		TodoistResponse response = new TodoistResponse ();
		
		try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
			parser.load_from_data ((string) stream.get_data ());

			// Debug
			print_root (parser.get_root ());

			if (is_todoist_error (message.status_code)) {
				response.from_error_json (parser.get_root ());

				debug_error (
					message.status_code,
					get_todoist_error (message.status_code)
				);
			} else {
				var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
				var uuid_member = sync_status.get_member (uuid);

				if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
					Services.Settings.get_default ().settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));
					id = parser.get_root ().get_object ().get_object_member ("temp_id_mapping").get_string_member (temp_id);

					response.status = true;
					response.data = id;
				} else {
					response.error = sync_status.get_object_member (uuid).get_string_member ("error");

					debug_error (
						(uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
						sync_status.get_object_member (uuid).get_string_member ("error")
					);
				}
			}
		} catch (Error e) {
			if (is_todoist_error (message.status_code)) {
				response.error = e.message;

				debug_error (
					message.status_code,
					e.message
				);
			} else {
				id = Util.get_default ().generate_id (object);

				var queue = new Objects.Queue ();
				queue.uuid = uuid;
				queue.object_id = id;
				queue.temp_id = temp_id;
				queue.query = object.type_add;
				queue.args = object.to_json ();
		
				Services.Database.get_default ().insert_queue (queue);
				Services.Database.get_default ().insert_CurTempIds (object.id, temp_id, object.object_type_string);

				response.status = true;
				response.data = queue.object_id;
			}
		}

		return response;
	}

	private void debug_error (uint status_code, string message) {
		debug ("Code: %s - %s".printf (status_code.to_string (), message));
	}

	public async TodoistResponse update (Objects.BaseObject object) {
		string uuid = Util.get_default ().generate_string ();
		string json = object.get_update_json (uuid);

		var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
		message.request_headers.append (
			"Authorization",
			"Bearer %s".printf (Services.Settings.get_default ().settings.get_string ("todoist-access-token"))
		);
		message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

		TodoistResponse response = new TodoistResponse ();

		try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
			parser.load_from_data ((string) stream.get_data ());

			// Debug
			print_root (parser.get_root ());

			if (is_todoist_error (message.status_code)) {
				response.from_error_json (parser.get_root ());

				debug_error (
					message.status_code,
					get_todoist_error (message.status_code)
				);
			} else {
				var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
				var uuid_member = sync_status.get_member (uuid);
	
				if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
					Services.Settings.get_default ().settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));
					response.status = true;
				} else {
					response.error = sync_status.get_object_member (uuid).get_string_member ("error");

					debug_error (
						(uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
						sync_status.get_object_member (uuid).get_string_member ("error")
					);
				}
			}
		} catch (Error e) {
			if (is_todoist_error (message.status_code)) {
				response.error = e.message;

				debug_error (
					message.status_code,
					e.message
				);
			} else {
				var queue = new Objects.Queue ();
				queue.uuid = uuid;
				queue.object_id = object.id;
				queue.query = object.type_update;
				queue.args = object.to_json ();

				Services.Database.get_default ().insert_queue (queue);
				response.status = true;
			}
		}

		return response;
	}

	public async void update_items (Gee.ArrayList<Objects.Item> objects) {
		string json = get_update_items_json (objects);

		var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
		message.request_headers.append (
			"Authorization",
			"Bearer %s".printf (Services.Settings.get_default ().settings.get_string ("todoist-access-token"))
		);
		message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

		try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
			parser.load_from_data ((string) stream.get_data ());

			// Debug
			print_root (parser.get_root ());

			if (is_todoist_error (message.status_code)) {
				debug_error (
					message.status_code,
					get_todoist_error (message.status_code)
				);
			} else {
				Services.Settings.get_default ().settings.set_string (
					"todoist-sync-token",
					parser.get_root ().get_object ().get_string_member ("sync_token")
				);
			}
		} catch (Error e) {

		}
	}

	public string get_update_items_json (Gee.ArrayList<Objects.Item> objects) {
        var builder = new Json.Builder ();

		builder.begin_object ();
            builder.set_member_name ("commands");

			builder.begin_array ();
			foreach (var item in objects) {
				builder.begin_object ();
	
				builder.set_member_name ("type");
				builder.add_string_value ("item_update");
	
				builder.set_member_name ("uuid");
				builder.add_string_value (Util.get_default ().generate_string ());
	
				builder.set_member_name ("args");
					builder.begin_object ();
	
					builder.set_member_name ("id");
					builder.add_string_value (item.id);
	
					builder.set_member_name ("content");
					builder.add_string_value (Util.get_default ().get_encode_text (item.content));
	
					builder.set_member_name ("description");
					builder.add_string_value (Util.get_default ().get_encode_text (item.description));
	
					builder.set_member_name ("priority");
					if (item.priority == 0) {
						builder.add_int_value (Constants.PRIORITY_4);
					} else {
						builder.add_int_value (item.priority);
					}
	
					if (item.has_due) {
						builder.set_member_name ("due");
						builder.begin_object ();
	
						builder.set_member_name ("date");
						builder.add_string_value (item.due.date);
	
						builder.end_object ();
					} else {
						builder.set_member_name ("due");
						builder.add_null_value ();
					}
	
					builder.set_member_name ("labels");
						builder.begin_array ();
						foreach (Objects.Label label in item.labels) {
							builder.add_string_value (label.name);
						}
						builder.end_array ();
					builder.end_object ();
				builder.end_object ();
			}
			builder.end_array ();
		builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);
        return generator.to_data (null);
    }

	public async TodoistResponse delete (Objects.BaseObject object) {
		string uuid = Util.get_default ().generate_string ();
		string json = get_delete_json (object.id, object.type_delete, uuid);

		var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
		message.request_headers.append (
			"Authorization",
			"Bearer %s".printf (Services.Settings.get_default ().settings.get_string ("todoist-access-token"))
		);
		message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

		TodoistResponse response = new TodoistResponse ();

		try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
			parser.load_from_data ((string) stream.get_data ());

			// Debug
			print_root (parser.get_root ());

			if (is_todoist_error (message.status_code)) {
				response.from_error_json (parser.get_root ());

				debug_error (
					message.status_code,
					get_todoist_error (message.status_code)
				);
			} else {
				var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
				var uuid_member = sync_status.get_member (uuid);
	
				if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
					Services.Settings.get_default ().settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));
					response.status = true;
				} else {
					response.error = sync_status.get_object_member (uuid).get_string_member ("error");

					debug_error (
						(uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
						sync_status.get_object_member (uuid).get_string_member ("error")
					);
				}
			}
		} catch (Error e) {
			if (is_todoist_error (message.status_code)) {
				response.error = e.message;

				debug_error (
					message.status_code,
					e.message
				);
			} else {
				var queue = new Objects.Queue ();
				queue.uuid = uuid;
				queue.object_id = object.id;
				queue.query = object.type_delete;
				queue.args = object.to_json ();

				Services.Database.get_default ().insert_queue (queue);
				response.status = true;
			}
		}

		return response;
	}
	/*
	    Sections
	 */

	private void add_section_if_not_exists (Json.Node node) {
		string _id = node.get_object ().get_string_member ("project_id");
		Objects.Project? project = Services.Database.get_default ().get_project (_id);
		if (project != null) {
			project.add_section_if_not_exists (new Objects.Section.from_json (node));
		}
	}

	/*
	    Items
	 */

	public async TodoistResponse complete_item (Objects.Item item) {
		string uuid = Util.get_default ().generate_string ();
		string json = item.get_check_json (uuid, item.checked ? "item_complete" : "item_uncomplete");

		var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
		message.request_headers.append (
			"Authorization",
			"Bearer %s".printf (Services.Settings.get_default ().settings.get_string ("todoist-access-token"))
		);
		message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

		TodoistResponse response = new TodoistResponse ();

		try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
			parser.load_from_data ((string) stream.get_data ());

			// Debug
			print_root (parser.get_root ());
			
			if (is_todoist_error (message.status_code)) {
				response.from_error_json (parser.get_root ());

				debug_error (
					message.status_code,
					get_todoist_error (message.status_code)
				);
			} else {
				var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
				var uuid_member = sync_status.get_member (uuid);
	
				if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
					Services.Settings.get_default ().settings.set_string ("todoist-sync-token", parser.get_root ().get_object ().get_string_member ("sync_token"));
					response.status = true;
				} else {
					response.error = sync_status.get_object_member (uuid).get_string_member ("error");

					debug_error (
						(uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
						sync_status.get_object_member (uuid).get_string_member ("error")
					);
				}
			}
		} catch (Error e) {
			if (is_todoist_error (message.status_code)) {
				response.error = e.message;

				debug_error (
					message.status_code,
					e.message
				);
			} else {
				var queue = new Objects.Queue ();
				queue.uuid = uuid;
				queue.object_id = item.id;
				queue.query = item.checked ? "item_complete" : "item_uncomplete";
				queue.args = item.to_json ();

				Services.Database.get_default ().insert_queue (queue);
				response.status = true;
			}
		}

		return response;
	}

	private void print_root (Json.Node root) {
		Json.Generator generator = new Json.Generator ();
		generator.set_root (root);
		debug (generator.to_data (null) + "\n");
	}

	public string get_delete_json (string id, string type, string uuid) {
		var builder = new Json.Builder ();
		builder.begin_object ();
            builder.set_member_name ("commands");
			builder.begin_array ();
				builder.begin_object ();
		
				// Set type
				builder.set_member_name ("type");
				builder.add_string_value (type);
		
				builder.set_member_name ("uuid");
				builder.add_string_value (uuid);
		
				builder.set_member_name ("args");
				builder.begin_object ();
		
				builder.set_member_name ("id");
				builder.add_string_value (id);
		
				builder.end_object ();
		
				builder.end_object ();
			builder.end_array ();
		builder.end_object ();

		Json.Generator generator = new Json.Generator ();
		Json.Node root = builder.get_root ();
		generator.set_root (root);

		return generator.to_data (null);
	}

	public async TodoistResponse move_item (Objects.Item item, string type, string id) {
		string uuid = Util.get_default ().generate_string ();
		string json = item.get_move_item (uuid, type, id);

		var message = new Soup.Message ("POST", TODOIST_SYNC_URL);
		message.request_headers.append (
			"Authorization",
			"Bearer %s".printf (Services.Settings.get_default ().settings.get_string ("todoist-access-token"))
		);
		message.set_request_body_from_bytes ("application/json", new Bytes (json.data));

		TodoistResponse response = new TodoistResponse ();

		try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
			parser.load_from_data ((string) stream.get_data ());

			print_root (parser.get_root ());

			if (is_todoist_error (message.status_code)) {
				response.from_error_json (parser.get_root ());

				debug_error (
					message.status_code,
					get_todoist_error (message.status_code)
				);
			} else {
				var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
				var uuid_member = sync_status.get_member (uuid);
	
				if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
					Services.Settings.get_default ().settings.set_string (
						"todoist-sync-token",
						parser.get_root ().get_object ().get_string_member ("sync_token")
					);
					response.status = true;
				} else {
					response.error = sync_status.get_object_member (uuid).get_string_member ("error");

					debug_error (
						(uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
						sync_status.get_object_member (uuid).get_string_member ("error")
					);
				}
			}
		} catch (Error e) {
			if (is_todoist_error (message.status_code)) {
				response.error = e.message;

				debug_error (
					message.status_code,
					e.message
				);
			} else {
				var queue = new Objects.Queue ();
				queue.uuid = uuid;
				queue.object_id = item.id;
				queue.query = "item_move";
				queue.args = item.to_move_json (type, id);

				Services.Database.get_default ().insert_queue (queue);
				response.status = true;
			}
		}

		return response;
	}

	public async TodoistResponse move_project_section (Objects.BaseObject base_object, string project_id) {
		string uuid = Util.get_default ().generate_string ();

		string url = "%s?commands=%s".printf (
			TODOIST_SYNC_URL,
			base_object.get_move_json (uuid, project_id)
		);

		var message = new Soup.Message ("POST", url);
		message.request_headers.append (
			"Authorization",
			"Bearer %s".printf (Services.Settings.get_default ().settings.get_string ("todoist-access-token"))
		);

		TodoistResponse response = new TodoistResponse ();

		try {
			GLib.Bytes stream = yield session.send_and_read_async (message, GLib.Priority.HIGH, null);
			parser.load_from_data ((string) stream.get_data ());

			print_root (parser.get_root ());

			if (is_todoist_error (message.status_code)) {
				response.from_error_json (parser.get_root ());

				debug_error (
					message.status_code,
					get_todoist_error (message.status_code)
				);
			} else {
				var sync_status = parser.get_root ().get_object ().get_object_member ("sync_status");
				var uuid_member = sync_status.get_member (uuid);
	
				if (uuid_member.get_node_type () == Json.NodeType.VALUE) {
					Services.Settings.get_default ().settings.set_string (
						"todoist-sync-token",
						parser.get_root ().get_object ().get_string_member ("sync_token")
						);
					response.status = true;
				} else {
					response.error = sync_status.get_object_member (uuid).get_string_member ("error");

					debug_error (
						(uint) sync_status.get_object_member (uuid).get_int_member ("http_code"),
						sync_status.get_object_member (uuid).get_string_member ("error")
					);
				}
			}
		} catch (Error e) {
			if (is_todoist_error (message.status_code)) {
				response.error = e.message;

				debug_error (
					message.status_code,
					e.message
				);
			} else {
				var queue = new Objects.Queue ();
				queue.uuid = uuid;
				queue.object_id = base_object.id;
				if (base_object is Objects.Project) {
					queue.query = "project_move";
				} else {
					queue.query = "section_move";
				}

				queue.args = base_object.to_json ();
				response.status = true;

				Services.Database.get_default ().insert_queue (queue);
			}
		}

		return response;
	}

	public bool is_todoist_error (uint status_code) {
        return (status_code == 400 || status_code == 401 ||
            status_code == 403 || status_code == 404 ||
            status_code == 429 || status_code == 500 ||
            status_code == 503);
    }

	public string get_todoist_error (uint code) {
        var messages = new Gee.HashMap<uint, string> ();

        messages.set (400, _("The request was incorrect."));
        messages.set (401, _("Authentication is required, and has failed, or has not yet been provided."));
        messages.set (403, _("The request was valid, but for something that is forbidden."));
        messages.set (404, _("The requested resource could not be found."));
        messages.set (429, _("The user has sent too many requests in a given amount of time."));
        messages.set (500, _("The request failed due to a server error."));
        messages.set (503, _("The server is currently unable to handle the request."));

        return messages.has_key (code) ? messages.get (code) : _("Unknown error");
    }
}

public class TodoistResponse {
	public bool status { get; set; }
	public string error { get; set; default = ""; }
	public int error_code { get; set; default = 0; }
	public int http_code { get; set; default = 0; }

	public string data { get; set; }

	public void from_error_json (Json.Node node) {
		status = false;
		error_code = (int) node.get_object ().get_int_member ("error_code");
		error = node.get_object ().get_string_member ("error");
		http_code = (int) node.get_object ().get_int_member ("http_code");
	}
}
