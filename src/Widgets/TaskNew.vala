public class Widgets.TaskNew : Gtk.Revealer {
    private Gtk.FlowBox labels_flowbox;
    public Gtk.Entry name_entry;
    private Gtk.TextView note_view;
    private Gtk.Button close_button;
    private Gtk.ListBox checklist;
    private Widgets.WhenButton when_button;
    private Gtk.Paned paned;

    public bool is_inbox { get; construct; }
    public int project_id { get; construct; }

    public signal void on_signal_close ();
    public TaskNew (bool _is_inbox = false, int _project_id = 0) {
        Object (
            is_inbox: _is_inbox,
            project_id: _project_id,
            margin_start: 27,
            margin_end: 30,
            reveal_child: false
        );
    }

    construct {
        name_entry = new Gtk.Entry ();
        name_entry.margin_start = 12;
        name_entry.margin_end = 12;
        name_entry.margin_top = 6;
        name_entry.hexpand = true;
        name_entry.placeholder_text = _("New task");
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        name_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        name_entry.get_style_context ().add_class ("planner-entry");

        close_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        close_button.get_style_context ().add_class ("button-overlay-circular");
        close_button.height_request = 24;
        close_button.width_request = 24;
        close_button.can_focus = false;
        close_button.valign = Gtk.Align.START;
        close_button.halign = Gtk.Align.START;
        close_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        note_view = new Gtk.TextView ();
        note_view.opacity = 0.7;
		note_view.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
        note_view.get_style_context ().add_class ("note-view");

        var note_view_placeholder_label = new Gtk.Label (_("Note"));
        note_view_placeholder_label.opacity = 0.65;

        var note_scrolled = new Gtk.ScrolledWindow (null, null);
        note_scrolled.margin_start = 15;
        note_scrolled.margin_end = 12;
        note_scrolled.height_request = 80;
        note_scrolled.add (note_view);

        checklist = new Gtk.ListBox  ();
        checklist.activate_on_single_click = true;
        checklist.get_style_context ().add_class ("view");
        checklist.selection_mode = Gtk.SelectionMode.SINGLE;

        var checklist_button = new Gtk.CheckButton ();
        checklist_button.get_style_context ().add_class ("planner-radio-disable");
        checklist_button.sensitive = false;

        var checklist_entry = new Gtk.Entry ();
        checklist_entry.hexpand = true;
        checklist_entry.margin_bottom = 1;
        checklist_entry.max_length = 50;
        checklist_entry.placeholder_text = _("Checklist");
        checklist_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        checklist_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        checklist_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        checklist_entry.get_style_context ().add_class ("planner-entry");

        var checklist_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        checklist_box.pack_start (checklist_button, false, false, 0);
        checklist_box.pack_start (checklist_entry, true, true, 6);

        var checklist_grid = new Gtk.Grid ();
        checklist_grid.margin_start = 12;
        checklist_grid.orientation = Gtk.Orientation.VERTICAL;
        checklist_grid.add (checklist);
        checklist_grid.add (checklist_box);

        paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.position = 400;
        paned.pack1 (note_scrolled, false, false);
        paned.pack2 (checklist_grid, true, true);

        labels_flowbox = new Gtk.FlowBox ();
        labels_flowbox.selection_mode = Gtk.SelectionMode.NONE;
        labels_flowbox.margin_start = 6;
        labels_flowbox.height_request = 38;
        labels_flowbox.expand = false;

        var labels_flowbox_revealer = new Gtk.Revealer ();
        labels_flowbox_revealer.add (labels_flowbox);
        labels_flowbox_revealer.reveal_child = false;

        when_button = new Widgets.WhenButton ();

        var labels = new Widgets.LabelButton ();

        var submit_task_button = new Gtk.Button.with_label (_("Create Task"));
        submit_task_button.valign = Gtk.Align.CENTER;
        submit_task_button.margin_bottom = 6;
        submit_task_button.sensitive = false;
        submit_task_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var bottom_box =  new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        bottom_box.margin_end = 6;
        bottom_box.pack_start (when_button, false, false, 0);
        bottom_box.pack_start (labels, false, false, 0);
        bottom_box.pack_end (submit_task_button, false, false, 0);

        var main_grid = new Gtk.Grid ();
        main_grid.hexpand = true;
        main_grid.margin_top = 3;
        main_grid.margin_end = 5;
        main_grid.margin_start = 5;
        main_grid.row_spacing = 6;
        main_grid.get_style_context ().add_class ("popover");
        main_grid.get_style_context ().add_class ("planner-popover");
        main_grid.orientation = Gtk.Orientation.VERTICAL;

        main_grid.add (name_entry);
        main_grid.add (paned);
        main_grid.add (labels_flowbox_revealer);
        main_grid.add (bottom_box);

        var main_overlay = new Gtk.Overlay ();
        main_overlay.add_overlay (close_button);
        main_overlay.add (main_grid);

        add (main_overlay);

        close_button.clicked.connect (() => {
            on_signal_close ();
        });

        name_entry.activate.connect (add_task);
        name_entry.changed.connect (() => {
            if (name_entry.text == "") {
                submit_task_button.sensitive = false;
            } else {
                submit_task_button.sensitive = true;
            }
        });

        submit_task_button.clicked.connect (add_task);

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                on_signal_close ();
            }

            return false;
        });

        note_view.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                on_signal_close ();
            }

            return false;
        });

        labels.on_selected_label.connect ((label) => {
            if (is_repeted (label.id) == false) {
                var child = new Widgets.LabelChild (label);
                labels_flowbox.add (child);
            }

            labels_flowbox_revealer.reveal_child = !is_empty (labels_flowbox);
            show_all ();
        });

        labels_flowbox.remove.connect ((widget) => {
            labels_flowbox_revealer.reveal_child = !is_empty (labels_flowbox);
        });

        checklist_entry.activate.connect (() => {
            if (checklist_entry.text != "") {
                var row = new Widgets.CheckRow (checklist_entry.text, false);
                checklist.add (row);

                checklist_entry.text = "";
                show_all ();
            }
        });
    }

    private bool is_repeted (int id) {
        foreach (Gtk.Widget element in labels_flowbox.get_children ()) {
            var child = element as Widgets.LabelChild;
            if (child.label.id == id) {
                return true;
            }
        }

        return false;
    }

    private bool is_empty (Gtk.FlowBox flowbox) {
        int l = 0;
        foreach (Gtk.Widget element in flowbox.get_children ()) {
            l = l + 1;
        }

        if (l <= 0) {
            return true;
        } else {
            return false;
        }
    }

    private void add_task () {
        if (name_entry.text != "") {
            var task = new Objects.Task ();

            task.project_id = project_id;
            task.content = name_entry.text;
            task.note = note_view.buffer.text;
            task.sidebar_width = paned.position;
            if (is_inbox) {
                task.is_inbox = 1;
            } else {
                task.is_inbox = 0;
            }

            if (when_button.has_duedate) {
                task.when_date_utc = when_button.when_datetime.to_string ();
            }

            if (when_button.has_reminder) {
                task.has_reminder = 1;
                task.reminder_time = when_button.reminder_datetime.to_string ();
            }

            foreach (Gtk.Widget element in labels_flowbox.get_children ()) {
                var child = element as Widgets.LabelChild;
                task.labels = task.labels + child.label.id.to_string () + ";";
            }

            foreach (Gtk.Widget element in checklist.get_children ()) {
                var row = element as Widgets.CheckRow;
                task.checklist = task.checklist + row.get_check ();
            }

            if (Planner.database.add_task (task) == Sqlite.DONE) {
                on_signal_close ();

                name_entry.text = "";
                note_view.buffer.text = "";
                when_button.clear ();

                foreach (Gtk.Widget element in labels_flowbox.get_children ()) {
                    labels_flowbox.remove (element);
                }

                foreach (Gtk.Widget element in checklist.get_children ()) {
                    checklist.remove (element);
                }
            }
        }
    }
}
