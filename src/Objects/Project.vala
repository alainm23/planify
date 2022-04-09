public class Objects.Project : Objects.BaseObject {
    public int64 parent_id { get; set; default = 0; }
    public string due_date { get; set; default = ""; }
    public string color { get; set; default = ""; }
    public string emoji { get; set; default = ""; }
    public ProjectViewStyle view_style { get; set; default = ProjectViewStyle.LIST; }
    public ProjectIconStyle icon_style { get; set; default = ProjectIconStyle.PROGRESS; }
    public bool todoist { get; set; default = false; }
    public bool inbox_project { get; set; default = false; }
    public bool team_inbox { get; set; default = false; }
    public bool is_deleted { get; set; default = false; }
    public bool is_archived { get; set; default = false; }
    public bool is_favorite { get; set; default = false; }
    public bool shared { get; set; default = false; }
    public bool collapsed { get; set; default = false; }
    
    bool _show_completed = false;
    public bool show_completed {
        get {
            return _show_completed;
        }

        set {
            _show_completed = value;
            show_completed_changed ();
        }
    }

    public int sort_order { get; set; default = 0; }
    public int child_order { get; set; default = 0; }
    
    string _view_id;
    public string view_id {
        get {
            _view_id ="project-%s".printf (id_string);
            return _view_id;
        }
    }

    string _parent_id_string;
    public string parent_id_string {
        get {
            _parent_id_string = parent_id.to_string ();
            return _parent_id_string;
        }
    }

    string _short_name;
    public string short_name {
        get {
            _short_name = Util.get_default ().get_short_name (name);
            return _short_name;
        }
    }

    Gee.ArrayList<Objects.Section> _sections;
    public Gee.ArrayList<Objects.Section> sections {
        get {
            _sections = Planner.database.get_sections_by_project (this);
            return _sections;
        }
    }

    Gee.ArrayList<Objects.Item> _items;
    public Gee.ArrayList<Objects.Item> items {
        get {
            _items = Planner.database.get_item_by_baseobject (this);
            return _items;
        }
    }

    Gee.ArrayList<Objects.Project> _subprojects;
    public Gee.ArrayList<Objects.Project> subprojects {
        get {
            _subprojects = Planner.database.get_subprojects (this);
            return _subprojects;
        }
    }

    Objects.Project? _parent;
    public Objects.Project parent {
        get {
            _parent = Planner.database.get_project (parent_id);
            return _parent;
        }
    }

    public signal void section_added (Objects.Section section);
    public signal void subproject_added (Objects.Project project);
    public signal void item_added (Objects.Item item);
    public signal void show_completed_changed ();

    int? _project_count = null;
    public int project_count {
        get {
            if (_project_count == null) {
                _project_count = update_project_count ();
            }

            return _project_count;
        }

        set {
            _project_count = value;
        }
    }

    double? _percentage = null;
    public double percentage {
        get {
            if (_percentage == null) {
                _percentage = update_percentage ();
            }
            
            return _percentage;
        }
    }

    public signal void project_count_updated ();

    construct {
        deleted.connect (() => {
            Planner.database.project_deleted (this);
        });

        Planner.event_bus.checked_toggled.connect ((item) => {
            if (item.project_id == id) {
                _project_count = update_project_count ();
                _percentage = update_percentage ();
                project_count_updated ();
            }
        });

        Planner.database.item_deleted.connect ((item) => {
            if (item.project_id == id) {
                _project_count = update_project_count ();
                _percentage = update_percentage ();
                project_count_updated ();
            }
        });

        Planner.database.item_added.connect ((item) => {
            if (item.project_id == id) {
                _project_count = update_project_count ();
                _percentage = update_percentage ();
                project_count_updated ();
            }
        });

        Planner.event_bus.item_moved.connect ((item, old_project_id, section_id, insert) => {
            if (item.project_id == id || old_project_id == id) {
                _project_count = update_project_count ();
                _percentage = update_percentage ();
                project_count_updated ();
            }
        });

        Planner.database.section_moved.connect ((section, old_project_id) => {
            if (section.project_id == id || old_project_id == id) {
                _project_count = update_project_count ();
                _percentage = update_percentage ();
                project_count_updated ();
            }
        });
    }

    public Project.from_json (Json.Node node) {
        id = node.get_object ().get_int_member ("id");
        update_from_json (node);
        todoist = true;
    }

    public void update_from_json (Json.Node node) {
        name = node.get_object ().get_string_member ("name");

        if (!node.get_object ().get_null_member ("color")) {
            color = node.get_object ().get_string_member ("color");
        }
        
        if (!node.get_object ().get_null_member ("is_deleted")) {
            is_deleted = node.get_object ().get_boolean_member ("is_deleted");
        }
        
        if (!node.get_object ().get_null_member ("is_archived")) {
            is_archived = node.get_object ().get_boolean_member ("is_archived");
        }
        
        if (!node.get_object ().get_null_member ("is_favorite")) {
            is_favorite = node.get_object ().get_boolean_member ("is_favorite");
        }
        
        if (!node.get_object ().get_null_member ("child_order")) {
            child_order = (int32) node.get_object ().get_int_member ("child_order");
        }
        
        if (!node.get_object ().get_null_member ("parent_id")) {
            parent_id = node.get_object ().get_int_member ("parent_id");
        } else {
            parent_id = Constants.INACTIVE;
        }

        if (node.get_object ().has_member ("team_inbox") && !node.get_object ().get_null_member ("team_inbox")) {
            team_inbox = node.get_object ().get_boolean_member ("team_inbox");
        }

        if (node.get_object ().has_member ("inbox_project") && !node.get_object ().get_null_member ("inbox_project")) {
            inbox_project = node.get_object ().get_boolean_member ("inbox_project");
        }

        shared = node.get_object ().get_boolean_member ("shared");
        view_style = node.get_object ().get_string_member ("view_style") == "board" ?
            ProjectViewStyle.BOARD : ProjectViewStyle.LIST;
    }

    public void update (bool cloud=true) {
        if (update_timeout_id != 0) {
            Source.remove (update_timeout_id);
        }

        update_timeout_id = Timeout.add (Constants.UPDATE_TIMEOUT, () => {
            update_timeout_id = 0;

            Planner.database.update_project (this);
            if (todoist && cloud) {
                Planner.todoist.update.begin (this, (obj, res) => {
                    Planner.todoist.update.end (res);
                });
            }

            return GLib.Source.REMOVE;
        });
    }

    public void update_async (Widgets.LoadingButton? loading_button = null) {
        if (loading_button != null) {
            loading_button.is_loading = true;
        }
        
        Planner.database.update_project (this);
        if (todoist) {
            Planner.todoist.update.begin (this, (obj, res) => {
                Planner.todoist.update.end (res);
                if (loading_button != null) {
                    loading_button.is_loading = false;
                }
            });
        }
    }

    public Objects.Project? add_subproject_if_not_exists (Objects.Project new_project) {
        Objects.Project? return_value = null;
        lock (subprojects) {
            return_value = get_subproject (new_project.id);
            if (return_value == null) {
                new_project.set_parent (this);
                Planner.database.insert_project (new_project);
                return_value = new_project;
            }
            return return_value;
        }
    }

    public Objects.Project? get_subproject (int64 id) {
        Objects.Project? return_value = null;
        lock (_subprojects) {
            foreach (var project in subprojects) {
                if (project.id == id) {
                    return_value = project;
                    break;
                }
            }
        }
        return return_value;
    }

    public void set_parent (Objects.Project project) {
        this._parent = project;
    }

    public Objects.Section add_section_if_not_exists (Objects.Section new_section) {
        Objects.Section? return_value = null;
        lock (_sections) {
            return_value = get_section (new_section.id);
            if (return_value == null) {
                new_section.set_project (this);
                add_section (new_section);
                Planner.database.insert_section (new_section);
                return_value = new_section;
            }
            return return_value;
        }
    }

    public Objects.Section? get_section (int64 id) {
        Objects.Section? return_value = null;
        lock (_sections) {
            foreach (var section in sections) {
                if (section.id == id) {
                    return_value = section;
                    break;
                }
            }
        }
        return return_value;
    }

    public void add_section (Objects.Section section) {
        this._sections.add (section);
        section.deleted.connect (() => {
            _sections.remove (section);
        });
    }

    public Objects.Item add_item_if_not_exists (Objects.Item new_item, bool insert=true) {
        Objects.Item? return_value = null;
        lock (_items) {
            return_value = get_item (new_item.id);
            if (return_value == null) {
                new_item.set_project (this);
                add_item (new_item);
                Planner.database.insert_item (new_item, insert);
                return_value = new_item;
            }
            return return_value;
        }
    }

    public Objects.Item? get_item (int64 id) {
        Objects.Item? return_value = null;
        lock (_items) {
            foreach (var item in items) {
                if (item.id == id) {
                    return_value = item;
                    break;
                }
            }
        }
        return return_value;
    }

    public void add_item (Objects.Item item) {
        this._items.add (item);
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
        builder.add_string_value (temp_id == null ? "project_update" : "project_add");

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

            builder.set_member_name ("name");
            builder.add_string_value (Util.get_default ().get_encode_text (name));

            builder.set_member_name ("color");
            builder.add_string_value (color);

            builder.set_member_name ("collapsed");
            builder.add_boolean_value (collapsed);

            builder.set_member_name ("is_favorite");
            builder.add_boolean_value (is_favorite);

            builder.end_object ();
        builder.end_object ();
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public override string to_json () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        
        builder.set_member_name ("id");
        builder.add_int_value (id);

        builder.set_member_name ("name");
        builder.add_string_value (Util.get_default ().get_encode_text (name));

        builder.set_member_name ("color");
        builder.add_string_value (color);

        builder.set_member_name ("collapsed");
        builder.add_boolean_value (collapsed);

        builder.set_member_name ("is_favorite");
        builder.add_boolean_value (is_favorite);

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }

    public void delete (bool confirm = true) {
        if (!confirm) {
            if (todoist) {
                Planner.todoist.delete.begin (this, (obj, res) => {
                    Planner.todoist.delete.end (res);
                    Planner.database.delete_project (this);
                });
            } else {
                Planner.database.delete_project (this);
            }

            return;
        }
        
        var message_dialog = new Dialogs.MessageDialog (
            _("Delete project"),
            _("Are you sure you want to delete <b>%s</b>?".printf (Util.get_default ().get_dialog_text (short_name))),
            "dialog-warning"
        );
        message_dialog.add_default_action (_("Cancel"), Gtk.ResponseType.CANCEL);
        message_dialog.show_all ();

        var remove_button = new Widgets.LoadingButton (
            LoadingButtonType.LABEL, _("Delete")) {
            hexpand = true
        };
        remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        remove_button.get_style_context ().add_class ("border-radius-6");
        message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

        message_dialog.default_action.connect ((response) => {
            if (response == Gtk.ResponseType.ACCEPT) {
                if (todoist) {
                    remove_button.is_loading = true;
                    Planner.todoist.delete.begin (this, (obj, res) => {
                        Planner.todoist.delete.end (res);
                        Planner.database.delete_project (this);
                        remove_button.is_loading = false;
                        message_dialog.hide_destroy ();
                    });
                } else {
                    Planner.database.delete_project (this);
                    message_dialog.hide_destroy ();
                }
            } else {
                message_dialog.hide_destroy ();
            }
        });
    }

    public string to_string () {       
        return """
        _________________________________
            ID: %s
            NAME: %s
            COLOR: %s
            TODOIST: %s
            INBOX: %s
            TEAM INBOX: %s
            CHILD ORDER: %i
            DELETED: %s
            ARCHIVED: %s
            FAVORITE: %s
            SHARED: %s
            VIEW: %s
            SHOW COMPLETED: %s
            SORT ORDER: %i
            COLLAPSED: %s
            PARENT ID: %s
        ---------------------------------
        """.printf (
            id.to_string (),
            name,
            color,
            todoist.to_string (),
            inbox_project.to_string (),
            team_inbox.to_string (),
            child_order,
            is_deleted.to_string (),
            is_archived.to_string (),
            is_favorite.to_string (),
            shared.to_string (),
            view_style.to_string (),
            show_completed.to_string (),
            sort_order,
            collapsed.to_string (),
            parent_id.to_string ()
        );
    }

    private int update_project_count () {
        int returned = 0;
        foreach (Objects.Item item in Planner.database.get_items_by_project (this)) {
            if (!item.checked) {
                returned++;
            }
        }
        return returned;
    }
    
    public double update_percentage () {
        int items_total = 0;
        int items_checked = 0;
        foreach (Objects.Item item in Planner.database.get_items_by_project (this)) {
            items_total++;
            if (item.checked) {
                items_checked++;
            }
        }

        return ((double) items_checked / (double) items_total);
    }

    public void build_content_menu () {
        var menu = new Dialogs.ContextMenu.Menu ();

        var edit_item = new Dialogs.ContextMenu.MenuItem (_("Edit project"), "planner-edit");
        var add_section_item = new Dialogs.ContextMenu.MenuItem (_("Add section"), "planner-plus-circle");
        
        var show_completed_item = new Dialogs.ContextMenu.MenuSwitch (
            _("Show completed"), "planner-check-circle", show_completed);

        var delete_item = new Dialogs.ContextMenu.MenuItem (_("Delete project"), "planner-trash");
        delete_item.get_style_context ().add_class ("menu-item-danger");

        if (!inbox_project) {
            menu.add_item (edit_item);
        }
        
        menu.add_item (add_section_item);
        menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
        menu.add_item (show_completed_item);


        if (!inbox_project) {
            menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
            menu.add_item (delete_item);
        }

        menu.popup ();

        edit_item.activate_item.connect (() => {
            menu.hide_destroy ();
            var dialog = new Dialogs.Project (this);
            dialog.show_all ();
        });

        show_completed_item.activate_item.connect (() => {
            show_completed = show_completed_item.active;
        });

        delete_item.activate_item.connect (() => {
            menu.hide_destroy ();
            this.delete ();
        });

        add_section_item.activate_item.connect (() => {
            Objects.Section new_section = prepare_new_section ();

            if (todoist) {
                add_section_item.is_loading = true;
                Planner.todoist.add.begin (new_section, (obj, res) => {
                    new_section.id = Planner.todoist.add.end (res);
                    add_section_if_not_exists (new_section);
                    add_section_item.is_loading = false;                    
                    menu.hide_destroy ();
                });
            } else {
                new_section.id = Util.get_default ().generate_id ();
                add_section_if_not_exists (new_section);
                menu.hide_destroy ();
            }
        });
    }

    public Objects.Section prepare_new_section () {
        Objects.Section new_section = new Objects.Section ();
        new_section.project_id = id;
        new_section.name = _("New section");
        new_section.activate_name_editable = true;

        return new_section;
    }
}
