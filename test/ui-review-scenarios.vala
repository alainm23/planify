/* Opt-in IPC harness for disposable upstream-review profiling recordings.
 * The Python driver supplies pointer events; this target calls production APIs
 * only for setup, navigation, and operations explicitly named in its event log.
 */
namespace PlanifyUIReview {
    private string run_dir;
    private MainLoop loop;
    private Adw.PreferencesDialog? preferences;
    private int last_request;
    private bool busy;

    private void pause (uint milliseconds) {
        var nested = new MainLoop ();
        Timeout.add (milliseconds, () => { nested.quit (); return Source.REMOVE; });
        nested.run ();
    }

    private void string_member (Json.Builder b, string key, string? value) {
        b.set_member_name (key);
        b.add_string_value (value ?? "");
    }

    private void integer_member (Json.Builder b, string key, int64 value) {
        b.set_member_name (key);
        b.add_int_value (value);
    }

    private void widgets (Gtk.Widget widget, Gtk.Window window, Json.Builder b,
                          Gee.HashMap<string, int> counts, ref int rows) {
        string kind = widget.get_type ().name ();
        counts[kind] = counts.has_key (kind) ? counts[kind] + 1 : 1;
        string id = "";
        string text = "";
        bool include = false;
        if (widget is Layouts.ItemBase) {
            rows++;
            id = ((Layouts.ItemBase) widget).item.id;
            text = ((Layouts.ItemBase) widget).item.content;
            include = rows < 100;
        } else if (widget is Layouts.ProjectRow) {
            id = ((Layouts.ProjectRow) widget).project.id;
            text = ((Layouts.ProjectRow) widget).project.name;
            include = true;
        } else if (widget is Widgets.LoadingButton) {
            text = ((Widgets.LoadingButton) widget).text_icon;
            include = true;
        } else if (widget is Gtk.Button) {
            text = ((Gtk.Button) widget).label ?? widget.tooltip_text;
            include = text != null && text != "";
        } else if (widget is Gtk.Editable) {
            text = ((Gtk.Editable) widget).get_text ();
            include = true;
        } else if (widget is Gtk.Label) {
            text = ((Gtk.Label) widget).label;
            include = text.length < 100;
        }
        Graphene.Rect bounds = Graphene.Rect ();
        Gtk.Widget hit_widget = widget;
        if (widget is Layouts.ItemRow) hit_widget = ((Layouts.ItemRow) widget).itemrow_box;
        if (include && hit_widget.get_mapped () && hit_widget.compute_bounds (window, out bounds)) {
            b.begin_object ();
            string_member (b, "type", kind);
            string_member (b, "id", id);
            string_member (b, "text", text);
            string_member (b, "window", window.title);
            b.set_member_name ("bounds"); b.begin_array ();
            b.add_double_value (bounds.origin.x); b.add_double_value (bounds.origin.y);
            b.add_double_value (bounds.size.width); b.add_double_value (bounds.size.height);
            b.end_array (); b.end_object ();
        }
        for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
            widgets (child, window, b, counts, ref rows);
        }
    }

    private void respond (int id, string command, string result, int64 began) throws Error {
        var b = new Json.Builder ();
        b.begin_object ();
        integer_member (b, "id", id);
        string_member (b, "command", command);
        string_member (b, "result", result);
        integer_member (b, "monotonic_us", get_monotonic_time ());
        integer_member (b, "action_us", get_monotonic_time () - began);
        integer_member (b, "store_items", Services.Store.instance ().items.size);
        var counts = new Gee.HashMap<string, int> ();
        int rows = 0;
        b.set_member_name ("widgets"); b.begin_array ();
        var toplevels = Gtk.Window.get_toplevels ();
        for (uint i = 0; i < toplevels.get_n_items (); i++) {
            var window = (Gtk.Window) toplevels.get_item (i);
            if (window.visible) widgets (window, window, b, counts, ref rows);
        }
        b.end_array ();
        integer_member (b, "task_widgets", rows);
        b.set_member_name ("widget_counts"); b.begin_object ();
        foreach (var entry in counts.entries) integer_member (b, entry.key, entry.value);
        b.end_object (); b.end_object ();
        var generator = new Json.Generator ();
        generator.set_root (b.get_root ());
        string json = generator.to_data (null);
        FileUtils.set_contents (run_dir + "/recording/response.json", json);
        print ("REVIEW %d %s %s\n", id, command, result);
        stdout.flush ();
    }

    private Gtk.Widget? find_task (Gtk.Widget widget, string id) {
        if (widget is Layouts.ItemBase && ((Layouts.ItemBase) widget).item.id == id) return widget;
        for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
            var match = find_task (child, id);
            if (match != null) return match;
        }
        return null;
    }

    private bool fill_chooser (Gtk.Widget widget, string path) {
        if (widget.get_type ().name () == "GtkFileChooserEntry" && widget.get_mapped ()) {
            ((Gtk.Editable) widget).set_text (path);
            return true;
        }
        for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
            if (fill_chooser (child, path)) return true;
        }
        return false;
    }

    private void drag_began (Gtk.DragSource source, Gdk.Drag drag) {
        print ("DND begin %s\n", source.widget.get_type ().name ()); stdout.flush ();
    }

    private void drag_ended (Gtk.DragSource source, Gdk.Drag drag, bool deleted) {
        print ("DND end delete=%s action=%u\n", deleted.to_string (), (uint) drag.get_selected_action ()); stdout.flush ();
    }

    private void drop_changed (Object object, ParamSpec pspec) {
        var target = (Gtk.DropTarget) object;
        print ("DND target %s current=%s\n", target.widget.get_type ().name (),
            (target.get_current_drop () != null).to_string ()); stdout.flush ();
    }

    private void observe_dnd (Gtk.Widget widget) {
        var controllers = widget.observe_controllers ();
        for (uint i = 0; i < controllers.get_n_items (); i++) {
            var controller = controllers.get_item (i);
            if (controller.get_data<bool> ("review-observed")) continue;
            controller.set_data<bool> ("review-observed", true);
            if (controller is Gtk.DragSource) {
                ((Gtk.DragSource) controller).drag_begin.connect (drag_began);
                ((Gtk.DragSource) controller).drag_end.connect (drag_ended);
            } else if (controller is Gtk.DropTarget) {
                controller.notify["current-drop"].connect (drop_changed);
            }
        }
        for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) observe_dnd (child);
    }

    private void backend_seed (string url) {
        assert_true (url.has_prefix ("http://127.0.0.1:"));
        var source = new Objects.Source ();
        source.id = "review-caldav";
        source.display_name = "Disposable CalDAV";
        source.source_type = SourceType.CALDAV;
        source.sync_server = false;
        source.data = new Objects.SourceCalDAVData.from_json (
            "{\"server_url\":\"%s\",\"username\":\"review\",\"password\":\"review\"}".printf (url));
        Services.Store.instance ().insert_source (source);
        foreach (string name in new string[] { "a", "b" }) {
            var project = new Objects.Project ();
            project.id = "review-dav-" + name;
            project.name = "Review DAV " + name;
            project.source_id = source.id;
            project.calendar_url = url + "review/" + name + "/";
            Services.Store.instance ().insert_project (project);
        }
    }

    private bool poll () {
        if (busy) return Source.CONTINUE;
        busy = true;
        int id = 0;
        string command = "";
        int64 began = get_monotonic_time ();
        try {
            string data;
            if (!FileUtils.get_contents (run_dir + "/request.json", out data)) { busy = false; return Source.CONTINUE; }
            var parser = new Json.Parser ();
            parser.load_from_data (data);
            var object = parser.get_root ().get_object ();
            id = (int) object.get_int_member ("id");
            if (id <= last_request) { busy = false; return Source.CONTINUE; }
            last_request = id;
            command = object.get_string_member ("command");
            var args = object.get_array_member ("args");
            string result = "ok";
            var app = Planify.instance;
            var window = app.main_window;
            if (command == "navigate") {
                string pane = args.get_string_element (0);
                Services.EventBus.get_default ().pane_selected (
                    pane == "project" ? PaneType.PROJECT : pane == "label" ? PaneType.LABEL : PaneType.FILTER,
                    args.get_string_element (1));
                pause (2000);
            } else if (command == "pause") {
                pause ((uint) int.parse (args.get_string_element (0)));
            } else if (command == "focus-task") {
                var task = find_task (window, args.get_string_element (0));
                result = task != null && task.grab_focus () ? "focused" : "not found";
                pause (500);
            } else if (command == "observe-dnd") {
                observe_dnd (window);
            } else if (command == "fill-chooser") {
                var windows = Gtk.Window.get_toplevels ();
                bool filled = false;
                for (uint i = 0; i < windows.get_n_items (); i++) {
                    var other = (Gtk.Window) windows.get_item (i);
                    if (other.visible && other != window && fill_chooser (other, args.get_string_element (0))) filled = true;
                }
                result = filled ? "filled" : "not found";
                pause (250);
            } else if (command == "backup-page") {
                preferences = new Adw.PreferencesDialog () { content_width = 750, content_height = 800 };
                preferences.add (new Adw.PreferencesPage ());
                preferences.push_subpage (new Dialogs.Preferences.Pages.Backup (preferences));
                preferences.present (window);
                pause (750);
            } else if (command == "backup-create") {
                var manager = Services.BackupManager.get_default ();
                int before = manager.backups.size;
                var file = manager.create_backup ();
                result = file == null ? "failed" : file.get_path ();
                pause (250);
            } else if (command == "save-as") {
                var backup = new Objects.Backup.from_file (File.new_for_path (args.get_string_element (0)));
                Services.BackupManager.get_default ().save_file_as (backup);
                pause (400);
            } else if (command == "restore-preview") {
                var backup = new Objects.Backup.from_file (File.new_for_path (args.get_string_element (0)));
                result = backup.valid () ? "valid" : backup.error;
                preferences = new Adw.PreferencesDialog () { content_width = 750, content_height = 800 };
                preferences.add (new Adw.PreferencesPage ());
                preferences.push_subpage (new Dialogs.Preferences.Pages.Backup.ImportView (preferences, backup));
                preferences.present (window);
                pause (750);
            } else if (command == "marker") {
                var task = new Objects.Item ();
                task.id = "review-restore-marker";
                task.content = "This task must disappear after restore";
                task.project_id = "synthetic-inbox";
                Services.Store.instance ().insert_item (task);
            } else if (command == "backend-seed") {
                backend_seed (args.get_string_element (0));
                pause (500);
            } else if (command == "seed-task") {
                var task = new Objects.Item ();
                task.id = args.get_string_element (0);
                task.content = task.id;
                task.description = "Review payload preservation";
                task.project_id = args.get_string_element (1);
                task.priority = 3;
                task.extra_data = "{\"review-sentinel\":\"preserve me\"}";
                Services.Store.instance ().insert_item (task);
                if (args.get_length () > 2) {
                    var child = new Objects.Item ();
                    child.id = task.id + "-child";
                    child.content = child.id;
                    child.project_id = task.project_id;
                    child.parent_id = task.id;
                    Services.Store.instance ().insert_item (child);
                }
                pause (500);
            } else if (command == "cross-move") {
                var item = Services.Store.instance ().get_item (args.get_string_element (0));
                var project = Services.Store.instance ().get_project (args.get_string_element (1));
                bool done = false;
                Util.get_default ().move_backend_type_item.begin (item, project, "", false, (obj, res) => {
                    Util.get_default ().move_backend_type_item.end (res);
                    done = true;
                });
                var deadline = get_monotonic_time () + 60 * TimeSpan.SECOND;
                while (!done && get_monotonic_time () < deadline) pause (25);
                result = done ? "completed" : "timeout";
                pause (500);
            } else if (command == "close-dialog") {
                if (preferences != null) preferences.close ();
                preferences = null;
                pause (500);
            } else if (command == "quit") {
                window.destroy ();
                loop.quit ();
            } else if (command != "snapshot") {
                result = "unknown command";
            }
            respond (id, command, result, began);
        } catch (Error e) {
            // No request exists while the external driver is starting up.
            if (id > 0) {
                try { respond (id, command, "error: " + e.message, began); }
                catch (Error ignored) { stderr.printf ("%s\n", ignored.message); }
            }
        }
        busy = false;
        return Source.CONTINUE;
    }

    public int main (string[] args) {
        try {
            string data_home = Environment.get_variable ("XDG_DATA_HOME");
            assert_true (data_home != null && data_home.has_suffix ("/data"));
            run_dir = Path.get_dirname (data_home);
            assert_true (FileUtils.test (run_dir + "/manifest.json", FileTest.IS_REGULAR));
            DirUtils.create_with_parents (run_dir + "/recording", 0700);
            var manifest = new Json.Parser ();
            manifest.load_from_file (run_dir + "/manifest.json");
            assert_false (manifest.get_root ().get_object ().get_boolean_member ("network_accounts"));
            if (Environment.get_variable ("PLANIFY_REVIEW_RESTART") != "1") {
                uint8[] bytes;
                FileUtils.get_data (data_home + "/io.github.alainm23.planify/database.db", out bytes);
                assert_cmpstr (Checksum.compute_for_data (ChecksumType.SHA256, bytes), CompareOperator.EQ,
                    manifest.get_root ().get_object ().get_string_member ("sha256"));
            }
            if (!Gtk.init_check ()) return 77;
            Adw.init ();
            Services.Database.get_default ().init_database ();
            foreach (var source in Services.Store.instance ().sources) assert_true (source.source_type == SourceType.LOCAL);
            var app = Planify.instance;
            assert_true (app.register ());
            app.main_window = new MainWindow (app);
            app.main_window.set_default_size (1280, 900);
            app.main_window.present ();
            pause (1500);
            uint8[] marker = new uint8[1234567]; marker[0] = 1;
            marker = null;
            respond (0, "ready", "ok", get_monotonic_time ());
            loop = new MainLoop ();
            Timeout.add (50, poll);
            loop.run ();
            return 0;
        } catch (Error e) { stderr.printf ("%s\n", e.message); return 1; }
    }
}
