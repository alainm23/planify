public class Objects.Reminder : Objects.BaseObject {
    public int64 notify_uid { get; set; default = Constants.INACTIVE; }
    public int64 item_id { get; set; default = Constants.INACTIVE; }
    public string service { get; set; default = ""; }
    public Objects.DueDate due { get; set; default = new Objects.DueDate (); }
    public int mm_offset { get; set; default = Constants.INACTIVE; }
    public int is_deleted { get; set; default = Constants.INACTIVE; }

    Objects.Item? _item;
    public Objects.Item item {
        get {
            _item = Planner.database.get_item (item_id);
            return _item;
        }

        set {
            _item = value;
        }
    }

    construct {
        deleted.connect (() => {
            Planner.database.reminder_deleted (this);
        });
    }

    public override string get_add_json (string temp_id, string uuid) {
        return get_update_json (uuid, temp_id);
    }

    public override string get_update_json (string uuid, string? temp_id = null) {
        var builder = new Json.Builder ();
        builder.begin_array ();
        builder.begin_object ();

        // Set type
        builder.set_member_name ("type");
        builder.add_string_value (temp_id == null ? "reminder_update" : "reminder_add");

        builder.set_member_name ("uuid");
        builder.add_string_value (uuid);

        if (temp_id != null) {
            builder.set_member_name ("temp_id");
            builder.add_string_value (temp_id);
        }

        builder.set_member_name ("args");
            builder.begin_object ();

            if (temp_id == null) {
                builder.set_member_name ("id");
                builder.add_int_value (id);
            }

            builder.set_member_name ("item_id");
            builder.add_int_value (item_id);

            builder.set_member_name ("due");
            builder.begin_object ();

            builder.set_member_name ("date");
            builder.add_string_value (due.date);

            builder.set_member_name ("is_recurring");
            builder.add_boolean_value (due.is_recurring);

            builder.set_member_name ("string");
            builder.add_string_value (due.text);

            builder.set_member_name ("lang");
            builder.add_string_value (due.lang);

            builder.end_object ();

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void delete (Widgets.LoadingButton? loading_button = null) {
        if (item.project.todoist) {
            if (loading_button != null) {
                loading_button.is_loading = true;
            }

            Planner.todoist.delete.begin (this, (obj, res) => {
                if (Planner.todoist.delete.end (res)) {
                    Planner.database.delete_reminder (this);
                } else {
                    if (loading_button != null) {
                        loading_button.is_loading = false;
                    }
                }
            });
        } else {
            Planner.database.delete_reminder (this);
        }
    }
}
