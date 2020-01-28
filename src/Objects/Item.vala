public class Objects.Item : GLib.Object {
    public int64 id { get; set; default = 0; }
    public int64 project_id { get; set; default = 0; }
    public int64 section_id { get; set; default = 0; }
    public int64 user_id { get; set; default = 0; }
    public int64 assigned_by_uid { get; set; default = 0; }
    public int64 responsible_uid { get; set; default = 0; }
    public int64 sync_id { get; set; default = 0; }
    public int64 parent_id { get; set; default = 0; } 
    public int priority { get; set; default = 0; }
    public int item_order { get; set; default = 0; }
    public int checked { get; set; default = 0; }
    public int is_deleted { get; set; default = 0; }
    public int is_todoist { get; set; default = 0; }
    public string content { get; set; default = ""; }
    public string note { get; set; default = ""; }

    public string due_date { get; set; default = ""; }
    public string due_timezone { get; set; default = ""; }
    public string due_string { get; set; default = ""; }
    public string due_lang { get; set; default = ""; }
    public int due_is_recurring { get; set; default = 0; }
    
    public string date_added { get; set; default = new GLib.DateTime.now_local ().to_string (); }
    public string date_completed { get; set; default = ""; }
    public string date_updated { get; set; default = new GLib.DateTime.now_local ().to_string (); }

    private uint timeout_id = 0;
    private uint timeout_id_2 = 0;

    public void save () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (2500, () => {
            this.date_updated = new GLib.DateTime.now_local ().to_string ();

            new Thread<void*> ("save_timeout", () => {
                Planner.database.update_item (this);
                if (this.is_todoist == 1) {
                    Planner.todoist.update_item (this);
                }

                return null;
            });
            
            Source.remove (timeout_id);
            timeout_id = 0;
            return false;
        });
    }

    public void save_local () {
        if (timeout_id_2 != 0) {
            Source.remove (timeout_id_2);
            timeout_id_2 = 0;
        }

        timeout_id_2 = Timeout.add (2500, () => {
            this.date_updated = new GLib.DateTime.now_local ().to_string ();

            new Thread<void*> ("save_local_timeout", () => {
                Planner.database.update_item (this);

                return null;
            });
            
            Source.remove (timeout_id_2);
            timeout_id_2 = 0;
            return false;
        });
    }

    public Objects.Item get_duplicate () {
        var item = new Objects.Item ();
        
        item.id = Planner.utils.generate_id ();
        item.project_id = project_id;
        item.section_id = section_id;
        item.user_id = user_id;
        item.assigned_by_uid = assigned_by_uid;
        item.responsible_uid = responsible_uid;
        item.sync_id = sync_id;
        item.parent_id = parent_id;
        item.priority = priority;
        item.is_todoist = is_todoist;
        item.content = content;
        item.note = note;
        item.due_date = due_date;
        item.due_timezone = due_timezone;
        item.due_string = due_string;
        item.due_lang = due_lang;
        item.due_is_recurring = due_is_recurring;

        return item;
    }

    public void convert_to_project () {
        var project = new Objects.Project ();
        project.id = Planner.utils.generate_id ();
        project.name = content;

        if (Planner.database.insert_project (project)) {
            foreach (var check in Planner.database.get_all_cheks_by_item (this.id)) {
                Planner.database.move_item (check, project.id);
            }

            //Planner.database.delete_item (this);
        }
    }

    public string to_json () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        
        builder.set_member_name ("id");
        builder.add_int_value (this.id);

        builder.set_member_name ("project_id");
        if (Planner.database.curTempIds_exists (this.project_id)) {
            builder.add_string_value (Planner.database.get_temp_id (this.project_id));
        } else {
            builder.add_int_value (this.project_id);
        }

        builder.set_member_name ("section_id");
        if (Planner.database.curTempIds_exists (this.section_id)) {
            builder.add_string_value (Planner.database.get_temp_id (this.section_id));
        } else {
            builder.add_int_value (this.section_id);
        }   

        builder.set_member_name ("parent_id");
        if (Planner.database.curTempIds_exists (this.parent_id)) {
            builder.add_string_value (Planner.database.get_temp_id (this.parent_id));
        } else {
            builder.add_int_value (this.parent_id);
        }

        builder.set_member_name ("content");
        builder.add_string_value (this.content);

        builder.set_member_name ("checked");
        builder.add_int_value (this.checked);
        
        builder.set_member_name ("due_date");
        builder.add_string_value (this.due_date);

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
	    Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void share_text () {
        string text = "";
        text += "- %s\n".printf (this.content);
        text += "  %s\n".printf (this.note.replace ("\n", " "));

        foreach (var check in Planner.database.get_all_cheks_by_item (this.id)) {
            text += "  - %s\n".printf (check.content);
        }

        Gtk.Clipboard.get_default (Planner.instance.main_window.get_display ()).set_text (text, -1);
        Planner.notifications.send_notification (0, _("The task was copied to the Clipboard."));
    }

    public void share_markdown () {
        string text = "";
        text += "#### %s\n".printf (this.content);
        text += "%s\n".printf (this.note.replace ("\n", " "));

        foreach (var check in Planner.database.get_all_cheks_by_item (this.id)) {
            text += "- [ ] %s\n".printf (check.content);
        }

        Gtk.Clipboard.get_default (Planner.instance.main_window.get_display ()).set_text (text, -1);
        Planner.notifications.send_notification (0, _("The task was copied to the Clipboard."));
    }
}