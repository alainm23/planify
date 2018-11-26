public class Views.Project : Gtk.EventBox {
    public weak MainWindow parent_window { get; construct; }
    public Objects.Project project { get; construct; }

    private Gtk.Entry name_entry;
    private Gtk.TextView note_view;

    private Widgets.TaskNew task_new_revealer;
    private Gtk.ListBox tasks_list;
    private Gtk.Button add_task_button;
    private Gtk.Revealer add_task_revealer;
    private Gtk.InfoBar infobar;
    private Gtk.Label infobar_label;
    private Gtk.FlowBox labels_flowbox;

    private Widgets.Popovers.LabelsPopover labels_popover;
    private Granite.Widgets.Toast notification_toast;

    public Project (Objects.Project _project, MainWindow parent) {
        Object (
            parent_window: parent,
            project: _project,
            expand: true
        );
    }

    construct {
        get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);

        var color_image = new Gtk.Image ();
        color_image.gicon = new ThemedIcon ("mail-unread-symbolic");
        color_image.get_style_context ().add_class ("proyect-%i".printf (project.id));
        color_image.pixel_size = 24;

        var color_button = new Gtk.Button ();
        color_button.valign = Gtk.Align.CENTER;
        color_button.halign = Gtk.Align.CENTER;
        color_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        color_button.get_style_context ().add_class ("button-circular");
        color_button.get_style_context ().add_class ("no-padding");
        color_button.tooltip_text = _("Add new project");
        color_button.add (color_image);

        name_entry = new Gtk.Entry ();
        name_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        name_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        name_entry.get_style_context ().add_class ("planner-entry");
        name_entry.get_style_context ().add_class ("no-padding");
        name_entry.get_style_context ().add_class ("planner-entry-bold");
        name_entry.hexpand = true;
        name_entry.text = project.name;
        name_entry.placeholder_text = _("Name");

        var paste_button = new Gtk.Button.from_icon_name ("planner-paste-symbolic", Gtk.IconSize.MENU);
        paste_button.get_style_context ().add_class ("planner-paste-menu");
        paste_button.tooltip_text = _("Paste");
        paste_button.valign = Gtk.Align.CENTER;
        paste_button.halign = Gtk.Align.CENTER;

        var labels_button = new Gtk.Button.from_icon_name ("planner-label-symbolic", Gtk.IconSize.MENU);
        labels_button.get_style_context ().add_class ("planner-label-menu");
        labels_button.tooltip_text = _("Filter by Label");
        labels_button.valign = Gtk.Align.CENTER;
        labels_button.halign = Gtk.Align.CENTER;

        labels_popover = new Widgets.Popovers.LabelsPopover (labels_button);
        labels_popover.position = Gtk.PositionType.BOTTOM;

        var share_button = new Gtk.Button.from_icon_name ("planner-share-symbolic", Gtk.IconSize.MENU);
        share_button.get_style_context ().add_class ("planner-share-menu");
        share_button.tooltip_text = _("Share");
        share_button.valign = Gtk.Align.CENTER;
        share_button.halign = Gtk.Align.CENTER;

        var show_all_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU);
        show_all_button.get_style_context ().add_class ("planner-zoom-in-menu");
        show_all_button.tooltip_text = _("Open all tasks");
        show_all_button.valign = Gtk.Align.CENTER;
        show_all_button.halign = Gtk.Align.CENTER;

        var hide_all_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic", Gtk.IconSize.MENU);
        hide_all_button.get_style_context ().add_class ("planner-zoom-out-menu");
        hide_all_button.tooltip_text = _("Close all tasks");
        hide_all_button.valign = Gtk.Align.CENTER;
        hide_all_button.halign = Gtk.Align.CENTER;

        var action_grid = new Gtk.Grid ();
        action_grid.column_spacing = 12;

        action_grid.add (labels_button);
        action_grid.add (paste_button);
        action_grid.add (share_button);
        action_grid.add (show_all_button);
        action_grid.add (hide_all_button);

        var action_revealer = new Gtk.Revealer ();
        action_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        action_revealer.add (action_grid);

        var settings_button = new Gtk.ToggleButton ();
		settings_button.active = true;
        settings_button.valign = Gtk.Align.START;
		settings_button.get_style_context ().add_class ("show-settings-button");
        settings_button.get_style_context ().add_class ("button-circular");
        settings_button.get_style_context ().remove_class ("button");
		settings_button.add (new Gtk.Image.from_icon_name ("pan-start-symbolic", Gtk.IconSize.MENU));

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.valign = Gtk.Align.START;
        top_box.hexpand = true;
        top_box.margin_start = 12;
        top_box.margin_end = 16;
        top_box.margin_top = 24;

        top_box.pack_start (color_button, false, false, 12);
        top_box.pack_start (name_entry, true, true, 0);
        top_box.pack_end (settings_button, false, false, 12);
        top_box.pack_end (action_revealer, false, false, 0);

        note_view = new Gtk.TextView ();
        note_view.opacity = 0.8;
		note_view.set_wrap_mode (Gtk.WrapMode.WORD);
        note_view.margin_start = 30;
        note_view.margin_top = 6;
        note_view.margin_end = 32;
		note_view.buffer.text = project.note;
        note_view.get_style_context ().add_class ("note-view");

        var note_view_placeholder_label = new Gtk.Label (_("Note"));
        note_view_placeholder_label.opacity = 0.65;
        note_view.add (note_view_placeholder_label);

        if (note_view.buffer.text != "") {
            note_view_placeholder_label.visible = false;
            note_view_placeholder_label.no_show_all = true;
        }

        tasks_list = new Gtk.ListBox  ();
        tasks_list.activate_on_single_click = true;
        tasks_list.selection_mode = Gtk.SelectionMode.SINGLE;
        tasks_list.expand = true;
        tasks_list.margin_start = 20;
        tasks_list.margin_end = 6;
        tasks_list.margin_top = 6;

        add_task_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        add_task_button.height_request = 32;
        add_task_button.width_request = 32;
        add_task_button.get_style_context ().add_class ("button-circular");
        add_task_button.get_style_context ().add_class ("no-padding");
        add_task_button.tooltip_text = _("Add new task");

        add_task_revealer = new Gtk.Revealer ();
        add_task_revealer.valign = Gtk.Align.END;
        add_task_revealer.halign = Gtk.Align.END;
        add_task_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        add_task_revealer.add (add_task_button);
        add_task_revealer.margin = 12;
        add_task_revealer.reveal_child = true;

        task_new_revealer = new Widgets.TaskNew (true);
        task_new_revealer.valign = Gtk.Align.END;

        labels_flowbox = new Gtk.FlowBox ();
        labels_flowbox.selection_mode = Gtk.SelectionMode.NONE;
        labels_flowbox.margin_start = 6;
        labels_flowbox.height_request = 38;
        labels_flowbox.expand = false;

        var labels_flowbox_revealer = new Gtk.Revealer ();
        labels_flowbox_revealer.margin_start = 12;
        labels_flowbox_revealer.margin_top = 6;
        labels_flowbox_revealer.add (labels_flowbox);
        labels_flowbox_revealer.reveal_child = false;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.expand = true;
        box.pack_start (top_box, false, false, 0);
        box.pack_start (note_view, false, false, 0);
        box.pack_start (labels_flowbox_revealer, false, false, 0);
        box.pack_start (tasks_list, true, true, 0);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (box);

        infobar = new Gtk.InfoBar ();
        infobar.add_button (_("OK"), 1);
        infobar.revealed = false;
        infobar.get_style_context ().add_class ("planner-infobar");

        infobar_label = new Gtk.Label ("");
        infobar.get_content_area ().add (infobar_label);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (infobar, false, false, 0);
        main_box.pack_start (scrolled, true, true, 0);

        var main_overlay = new Gtk.Overlay ();
        main_overlay.add_overlay (add_task_revealer);
        main_overlay.add_overlay (task_new_revealer);
        main_overlay.add_overlay (notification_toast);
        main_overlay.add (main_box);

        add (main_overlay);

        // Signals
        name_entry.focus_out_event.connect (() => {
            update_project ();
            return false;
        });

        name_entry.activate.connect (() => {
            update_project ();
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                update_project ();
            }

            return false;
        });

        color_button.clicked.connect (() => {
            var color_dialog = new Gtk.ColorChooserDialog (_("Select Your Favorite Color"), parent_window);
    		if (color_dialog.run () == Gtk.ResponseType.OK) {
                project.color = Application.utils.rgb_to_hex_string (color_dialog.rgba);

                update_project ();
    		}

    		color_dialog.close ();
        });

        settings_button.toggled.connect (() => {
            if (action_revealer.reveal_child) {
                settings_button.get_style_context ().remove_class ("closed");
                action_revealer.reveal_child = false;
            } else {
                action_revealer.reveal_child = true;
                settings_button.get_style_context ().add_class ("closed");
            }
        });

        note_view.focus_out_event.connect (() => {
            if (note_view.buffer.text == "") {
                note_view_placeholder_label.visible = true;
                note_view_placeholder_label.no_show_all = false;
            }

            project.note = note_view.buffer.text;
            update_project ();

            return false;
        });

        note_view.focus_in_event.connect (() => {
            note_view_placeholder_label.visible = false;
            note_view_placeholder_label.no_show_all = true;

            return false;
        });

        Application.database.update_project_signal.connect ((_project) => {
            if (project.id == _project.id) {
                name_entry.text = _project.name;
            }
        });
    }

    private void update_project () {
        if (name_entry.text == "") {
            name_entry.text = project.name;
        } else {
            project.name = name_entry.text;

            if (Application.database.update_project (project) == Sqlite.DONE) {

            }
        }
    }
}
