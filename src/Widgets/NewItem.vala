public class Widgets.NewItem : Gtk.ListBoxRow {
    public int64 project_id { get; set; }
    public int64 header_id { get; set; }
    public int is_todoist { get; set; }

    private Gtk.CheckButton checked_button;
    private Gtk.Entry content_entry;

    public NewItem (int64 project_id, int64 header_id, int is_todoist) {
        Object (
            project_id: project_id,
            header_id: header_id,
            is_todoist: is_todoist
        );
    }

    construct {
        activatable = false;
        selectable = false;
        get_style_context ().add_class ("item-row");
        //margin_start = 35;
        margin_end = 35;
        margin_top = 3;
        margin_bottom = 3;

        var loading_spinner = new Gtk.Spinner ();
        loading_spinner.start ();

        var loading_revealer = new Gtk.Revealer ();
        loading_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        loading_revealer.add (loading_spinner);

        var checked_button = new Gtk.CheckButton ();
        checked_button.margin_start = 6;
        //checked_button.get_style_context ().add_class ("checked-button");
        checked_button.valign = Gtk.Align.CENTER;

        content_entry = new Gtk.Entry ();
        content_entry.hexpand = true;
        content_entry.margin_start = 3;
        content_entry.margin_bottom = 1;
        content_entry.placeholder_text = _("Add a new subtask");
        content_entry.get_style_context ().add_class ("welcome");
        content_entry.get_style_context ().add_class ("flat");
        content_entry.get_style_context ().add_class ("check-entry");
        content_entry.get_style_context ().add_class ("no-padding-right");
 
        var content_grid = new Gtk.Grid ();
        content_grid.get_style_context ().add_class ("check-eventbox");
        content_grid.add (checked_button);
        content_grid.add (content_entry);
        
        var grid = new Gtk.Grid ();
        grid.margin_start = 14;
        grid.column_spacing = 6;
        grid.add (loading_revealer);
        grid.add (content_grid);

        var submit_button = new Gtk.Button.with_label (_("Add"));
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.get_style_context ().add_class ("new-item-action-button");

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("new-item-action-button");

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_start = 41;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.row_spacing = 9;
        main_grid.add (grid);
        main_grid.add (action_grid);

        var main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        main_revealer.add (main_grid);
        main_revealer.reveal_child = false;

        add (main_revealer);

        Timeout.add (140, () => {
            main_revealer.reveal_child = true;
            content_entry.grab_focus ();

            return false;
        });

        content_entry.activate.connect (insert_item);
        submit_button.clicked.connect (insert_item);

        content_entry.changed.connect (() => {
            if (content_entry.text != "") {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        content_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                destroy ();
            }

            return false;
        });

        cancel_button.clicked.connect (() => {
            destroy ();
        });

        Application.todoist.item_added_started.connect ((id) => {
            loading_revealer.reveal_child = true;
            sensitive = false;
        });

        Application.todoist.item_added_completed.connect ((id) => {
            destroy ();
        });

        Application.todoist.item_added_error.connect ((id) => {

        });
    }
    
    private void insert_item () {
        if (content_entry.text != "") {
            var item = new Objects.Item ();
            item.id = Application.utils.generate_id ();
            item.content = content_entry.text;
            item.project_id = project_id;
            item.header_id = header_id;

            if (is_todoist == 1) {
                if (Application.utils.check_connection ()) {
                    Application.todoist.add_item (item);
                } else {

                }
            } else {
                if (Application.database.insert_item (item)) {
                    content_entry.text = "";
                    destroy ();
                }
            }
        }
    }
}