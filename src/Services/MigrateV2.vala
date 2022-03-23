public class Services.MigrateV2 : GLib.Object {
    private static MigrateV2? _instance;
    public static MigrateV2 get_default () {
        if (_instance == null) {
            _instance = new MigrateV2 ();
        }

        return _instance;
    }

    public void export_v2_database () {
        Sqlite.Database db;
        string db_path = Environment.get_user_data_dir () + "/com.github.alainm23.planner/database.db";

        Sqlite.Database.open (db_path, out db);
        save_file_as (db);
    }

    private Gee.ArrayList<Objects.ProjectV2> get_all_projects (Sqlite.Database db) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, area_id, name, note, due_date, color, is_todoist, inbox_project, team_inbox,
                item_order, is_deleted, is_archived, is_favorite, is_sync, shared, is_kanban, show_completed,
                sort_order, parent_id, collapsed
            FROM Projects ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.ProjectV2?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var p = new Objects.ProjectV2 ();

            p.id = stmt.column_int64 (0);
            p.area_id = stmt.column_int64 (1);
            p.name = stmt.column_text (2);
            p.note = stmt.column_text (3);
            p.due_date = stmt.column_text (4);
            p.color = stmt.column_int (5);
            p.is_todoist = stmt.column_int (6);
            p.inbox_project = stmt.column_int (7);
            p.team_inbox = stmt.column_int (8);
            p.item_order = stmt.column_int (9);
            p.is_deleted = stmt.column_int (10);
            p.is_archived = stmt.column_int (11);
            p.is_favorite = stmt.column_int (12);
            p.is_sync = stmt.column_int (13);
            p.shared = stmt.column_int (14);
            p.is_kanban = stmt.column_int (15);
            p.show_completed = stmt.column_int (16);
            p.sort_order = stmt.column_int (17);
            p.parent_id = stmt.column_int64 (18);
            p.collapsed = stmt.column_int (19);

            all.add (p);
        }

        stmt.reset ();
        return all;
    }

    private Gee.ArrayList<Objects.SectionV2> get_all_sections (Sqlite.Database db) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, name, project_id, item_order, collapsed, sync_id, is_deleted, is_archived,
                date_archived, date_added, is_todoist, note
            FROM Sections ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.SectionV2> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var s = new Objects.SectionV2 ();

            s.id = stmt.column_int64 (0);
            s.name = stmt.column_text (1);
            s.project_id = stmt.column_int64 (2);
            s.item_order = stmt.column_int (3);
            s.collapsed = stmt.column_int (4);
            s.sync_id = stmt.column_int64 (5);
            s.is_deleted = stmt.column_int (6);
            s.is_archived = stmt.column_int (7);
            s.date_archived = stmt.column_text (8);
            s.date_added = stmt.column_text (9);
            s.is_todoist = stmt.column_int (10);
            s.note = stmt.column_text (11);

            all.add (s);
        }

        stmt.reset ();
        return all;
    }

    private Gee.ArrayList<Objects.ItemV2> get_all_items (Sqlite.Database db) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, project_id, section_id, user_id, assigned_by_uid, responsible_uid,
                sync_id, parent_id, priority, item_order, checked, is_deleted, content, note,
                due_date, due_timezone, due_string, due_lang, due_is_recurring, date_added,
                date_completed, date_updated, is_todoist, day_order, collapsed
            FROM Items ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.ItemV2> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.ItemV2 ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.due_timezone = stmt.column_text (15);
            i.due_string = stmt.column_text (16);
            i.due_lang = stmt.column_text (17);
            i.due_is_recurring = stmt.column_int (18);
            i.date_added = stmt.column_text (19);
            i.date_completed = stmt.column_text (20);
            i.date_updated = stmt.column_text (21);
            i.is_todoist = stmt.column_int (22);
            i.day_order = stmt.column_int (23);
            i.collapsed = stmt.column_int (24);

            all.add (i);
        }

        stmt.reset ();
        return all;
    }

    public bool export_to_json (string path, Sqlite.Database db) {      
        Json.Builder builder = new Json.Builder ();
        bool returned = false;

        builder.begin_object ();
            // Projects
            builder.set_member_name ("projects");
            builder.begin_array ();
                foreach (var project in get_all_projects (db)) {
                    builder.begin_object ();
                    builder.set_member_name ("parent_id");
                    builder.add_int_value (project.parent_id);

                    builder.set_member_name ("id");
                    builder.add_int_value (project.id);

                    builder.set_member_name ("name");
                    builder.add_string_value (project.name);

                    builder.set_member_name ("note");
                    builder.add_string_value (project.note);

                    builder.set_member_name ("due_date");
                    builder.add_string_value (project.due_date);

                    builder.set_member_name ("color");
                    builder.add_int_value (project.color);

                    builder.set_member_name ("is_todoist");
                    builder.add_int_value (project.is_todoist);

                    builder.set_member_name ("inbox_project");
                    builder.add_int_value (project.inbox_project);

                    builder.set_member_name ("team_inbox");
                    builder.add_int_value (project.team_inbox);

                    builder.set_member_name ("item_order");
                    builder.add_int_value (project.item_order);

                    builder.set_member_name ("is_deleted");
                    builder.add_int_value (project.is_deleted);

                    builder.set_member_name ("is_archived");
                    builder.add_int_value (project.is_archived);

                    builder.set_member_name ("is_favorite");
                    builder.add_int_value (project.is_favorite);

                    builder.set_member_name ("is_sync");
                    builder.add_int_value (project.is_sync);

                    builder.set_member_name ("shared");
                    builder.add_int_value (project.shared);

                    builder.set_member_name ("is_kanban");
                    builder.add_int_value (project.is_kanban);

                    builder.set_member_name ("show_completed");
                    builder.add_int_value (project.show_completed);

                    builder.set_member_name ("sort_order");
                    builder.add_int_value (project.sort_order);
                    builder.end_object ();
                }
            builder.end_array ();

            // Sections
            builder.set_member_name ("sections");
            builder.begin_array ();
                foreach (var section in get_all_sections (db)) {
                    builder.begin_object ();
                    builder.set_member_name ("id");
                    builder.add_int_value (section.id);

                    builder.set_member_name ("project_id");
                    builder.add_int_value (section.project_id);

                    builder.set_member_name ("sync_id");
                    builder.add_int_value (section.sync_id);

                    builder.set_member_name ("name");
                    builder.add_string_value (section.name);

                    builder.set_member_name ("note");
                    builder.add_string_value (section.note);

                    builder.set_member_name ("item_order");
                    builder.add_int_value (section.item_order);

                    builder.set_member_name ("collapsed");
                    builder.add_int_value (section.collapsed);

                    builder.set_member_name ("is_todoist");
                    builder.add_int_value (section.is_todoist);

                    builder.set_member_name ("is_deleted");
                    builder.add_int_value (section.is_deleted);

                    builder.set_member_name ("is_archived");
                    builder.add_int_value (section.is_archived);

                    builder.set_member_name ("date_archived");
                    builder.add_string_value (section.date_archived);

                    builder.set_member_name ("date_added");
                    builder.add_string_value (section.date_added);
                    builder.end_object ();
                }
            builder.end_array ();

            // Items
            builder.set_member_name ("items");
            builder.begin_array ();
                foreach (var item in get_all_items (db)) {
                    builder.begin_object ();
                    builder.set_member_name ("id");
                    builder.add_int_value (item.id);

                    builder.set_member_name ("project_id");
                    builder.add_int_value (item.project_id);

                    builder.set_member_name ("section_id");
                    builder.add_int_value (item.section_id);

                    builder.set_member_name ("user_id");
                    builder.add_int_value (item.user_id);

                    builder.set_member_name ("assigned_by_uid");
                    builder.add_int_value (item.assigned_by_uid);

                    builder.set_member_name ("responsible_uid");
                    builder.add_int_value (item.responsible_uid);

                    builder.set_member_name ("sync_id");
                    builder.add_int_value (item.sync_id);

                    builder.set_member_name ("parent_id");
                    builder.add_int_value (item.parent_id);

                    builder.set_member_name ("priority");
                    builder.add_int_value (item.priority);

                    builder.set_member_name ("item_order");
                    builder.add_int_value (item.item_order);

                    builder.set_member_name ("day_order");
                    builder.add_int_value (item.day_order);

                    builder.set_member_name ("checked");
                    builder.add_int_value (item.checked);

                    builder.set_member_name ("is_deleted");
                    builder.add_int_value (item.is_deleted);

                    builder.set_member_name ("is_todoist");
                    builder.add_int_value (item.is_todoist);

                    builder.set_member_name ("content");
                    builder.add_string_value (item.content);
                    
                    builder.set_member_name ("note");
                    builder.add_string_value (item.note);

                    builder.set_member_name ("due_date");
                    builder.add_string_value (item.due_date);

                    builder.set_member_name ("due_timezone");
                    builder.add_string_value (item.due_timezone);

                    builder.set_member_name ("due_string");
                    builder.add_string_value (item.due_string);

                    builder.set_member_name ("due_lang");
                    builder.add_string_value (item.due_lang);

                    builder.set_member_name ("due_is_recurring");
                    builder.add_int_value (item.due_is_recurring);

                    builder.set_member_name ("date_added");
                    builder.add_string_value (item.date_added);

                    builder.set_member_name ("date_completed");
                    builder.add_string_value (item.date_completed);

                    builder.set_member_name ("date_updated");
                    builder.add_string_value (item.date_updated);
                    
                    builder.end_object ();
                }
            builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        generator.pretty = true;

        Json.Node root = builder.get_root ();
        generator.set_root (root);

        try {
            returned = generator.to_file (path);
        } catch (Error e) {
            print ("Error: %s\n", e.message);
        }

        return returned;
    }

    public void save_file_as (Sqlite.Database db) {
        var dialog = new Gtk.FileChooserNative (
            _("Save backup file"), Planner.instance.main_window,
            Gtk.FileChooserAction.SAVE,
            _("Save"),
            _("Cancel"));

        dialog.set_do_overwrite_confirmation (true);
        add_filters (dialog);
        dialog.set_modal (true);
        
        if (dialog.run () == Gtk.ResponseType.ACCEPT) {
            var file = dialog.get_file ();

            if (!file.get_basename ().down ().has_suffix (".json")) {
                if (export_to_json (file.get_path () + ".json", db)) {
                    Util.get_default ().clear_database_query ();
                    Planner.settings.set_string ("version", Constants.VERSION);
                }
            }
        }

        dialog.destroy ();
    }

    private void add_filters (Gtk.FileChooserNative chooser) {
        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.add_pattern ("*.json");
        filter.set_filter_name (_("JSON files"));
        chooser.add_filter (filter);

        filter = new Gtk.FileFilter ();
        filter.add_pattern ("*");
        filter.set_filter_name (_("All files"));
        chooser.add_filter (filter);
    }
}