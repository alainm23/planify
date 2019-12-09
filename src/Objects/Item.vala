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
                if (this.is_todoist == 0) {
                    Planner.database.update_item (this);
                } else {
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
            foreach (var check in Planner.database.get_all_cheks_by_item (this)) {
                Planner.database.move_item (check, project.id);
            }

            //Planner.database.delete_item (this);
        }
    }
}