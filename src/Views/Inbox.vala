public class Views.Inbox : Gtk.EventBox {
    public MainWindow window { get; construct; }
    private Widgets.TaskNew task_new_revealer;
    private Gtk.ListBox tasks_list;
    private Gtk.Button add_task_button;
    private Gtk.Revealer add_task_revealer;
    public Inbox () {
        Object (
            expand: true
        );
    }

    construct {
        get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);

        var inbox_icon = new Gtk.Image.from_icon_name ("planner-inbox", Gtk.IconSize.DND);

        var inbox_name = new Gtk.Label ("<b>%s</b>".printf (_("Inbox")));
        inbox_name.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        inbox_name.use_markup = true;

        var settings_button = new Gtk.ToggleButton ();
        settings_button.add (new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.BUTTON));
        settings_button.tooltip_text = _("Settings");
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.halign = Gtk.Align.CENTER;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var menu_popover = new Widgets.Popovers.ItemMenu (settings_button);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.valign = Gtk.Align.START;
        top_box.hexpand = true;
        top_box.margin_start = 24;
        top_box.margin_end = 24;
        top_box.margin_top = 24;

        top_box.pack_start (inbox_icon, false, false, 0);
        top_box.pack_start (inbox_name, false, false, 12);
        top_box.pack_end (settings_button, false, false, 0);

        tasks_list = new Gtk.ListBox  ();
        tasks_list.activate_on_single_click = true;
        //tasks_list.get_style_context ().add_class (Gtk.STYLE_CLASS_BACKGROUND);
        tasks_list.selection_mode = Gtk.SelectionMode.SINGLE;
        tasks_list.expand = true;
        tasks_list.margin_start = 24;
        tasks_list.margin_end = 6;
        tasks_list.margin_top = 12;

        add_task_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        add_task_button.height_request = 32;
        add_task_button.width_request = 32;
        add_task_button.get_style_context ().add_class ("button-circular");
        add_task_button.get_style_context ().add_class ("no-padding");
        add_task_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
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

        var alert = new Granite.Widgets.AlertView (_("No Input task"),
                                           _("Create a task"),
                                           "dialog-error");
        alert.get_style_context ().remove_class (Gtk.STYLE_CLASS_VIEW);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.expand = true;

        box.pack_start (top_box, false, false, 0);
        box.pack_start (tasks_list, true, true, 0);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (scrolled, true, true, 0);

        var main_overlay = new Gtk.Overlay ();
        main_overlay.add_overlay (add_task_revealer);
        main_overlay.add_overlay (task_new_revealer);
        main_overlay.add (main_box);

        add (main_overlay);
        update_tasks_list ();

        Gdk.Display display = Gdk.Display.get_default ();
        Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);

        add_task_button.clicked.connect (() => {
            task_on_revealer ();
        });

        this.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                foreach (Gtk.Widget element in tasks_list.get_children ()) {
                    var row = element as Widgets.TaskRow;
                    row.hide_content ();
                }
            }

            return false;
        });

        task_new_revealer.on_signal_close.connect (() => {
            task_on_revealer ();
        });

        settings_button.toggled.connect (() => {
            if (settings_button.active) {
                menu_popover.show_all ();
            }
        });

        menu_popover.closed.connect (() => {
            settings_button.active = false;
        });

        menu_popover.on_selected_menu.connect((index) => {
            if (index == 1) {
                string text = clipboard.wait_for_text ();
                task_new_revealer.name_entry.text = text ?? "";

                if (task_new_revealer.reveal_child == false) {
                    task_on_revealer ();
                }
            }
        });

        Planner.database.add_inbox_task_signal.connect (() => {
            update_tasks_list ();
        });
    }

    public void update_tasks_list () {
        foreach (Gtk.Widget element in tasks_list.get_children ()) {
            tasks_list.remove (element);
        }

        var all_tasks = new Gee.ArrayList<Objects.Task?> ();
        all_tasks = Planner.database.get_all_inbox_tasks ();

        foreach (var task in all_tasks) {
            var row = new Widgets.TaskRow (task);
            tasks_list.add (row);
        }

        show_all ();
    }

    private void task_on_revealer () {
        if (task_new_revealer.reveal_child) {
            task_new_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            task_new_revealer.reveal_child = false;

            add_task_revealer.reveal_child = true;
        } else {
            task_new_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            task_new_revealer.reveal_child = true;

            add_task_revealer.reveal_child = false;
            task_new_revealer.name_entry.grab_focus ();
        }
    }
}
