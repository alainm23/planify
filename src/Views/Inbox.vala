public class Views.Inbox : Gtk.EventBox {
    private Gtk.Revealer action_bar_revealer;
    private Widgets.TaskNew task_new_revealer;
    private Gtk.ListBox tasks_list;
    private Gtk.ToggleButton add_task_button;

    public Inbox () {
        Object (
            expand: true
        );
    }

    construct {
        get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);

        var inbox_icon = new Gtk.Image.from_icon_name ("internet-mail", Gtk.IconSize.DND);

        var inbox_name = new Gtk.Label ("<b>%s</b>".printf (_("Inbox")));
        inbox_name.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        inbox_name.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.valign = Gtk.Align.START;
        top_box.hexpand = true;
        top_box.margin_start = 24;
        top_box.margin_end = 24;
        top_box.margin_top = 24;

        top_box.pack_start (inbox_icon, false, false, 0);
        top_box.pack_start (inbox_name, false, false, 12);

        tasks_list = new Gtk.ListBox  ();
        tasks_list.activate_on_single_click = true;
        tasks_list.get_style_context ().add_class (Gtk.STYLE_CLASS_BACKGROUND);
        tasks_list.selection_mode = Gtk.SelectionMode.SINGLE;
        tasks_list.expand = true;
        tasks_list.margin_start = 24;
        tasks_list.margin_end = 6;
        tasks_list.margin_top = 12;

        var close_all_button = new Gtk.Button ();
        close_all_button.valign = Gtk.Align.CENTER;
        close_all_button.margin_start = 12;
        close_all_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        close_all_button.get_style_context ().add_class ("button-circular");

        var close_all_grid = new Gtk.Grid ();
        close_all_grid.add (new Gtk.Image.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU));
        close_all_grid.add (new Gtk.Label (_("Close all")));

        close_all_button.add (close_all_grid);

        add_task_button = new Gtk.ToggleButton ();
        add_task_button.valign = Gtk.Align.CENTER;
        add_task_button.halign = Gtk.Align.CENTER;
        add_task_button.margin = 6;
        add_task_button.height_request = 24;
        add_task_button.width_request = 24;
        add_task_button.get_style_context ().add_class ("button-circular");
        add_task_button.get_style_context ().add_class ("no-padding");
        add_task_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        add_task_button.tooltip_text = _("Add new task");
        add_task_button.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR));

        var settings_button = new Gtk.ToggleButton ();
        settings_button.add (new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.BUTTON));
        settings_button.tooltip_text = _("Settings");
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.halign = Gtk.Align.CENTER;
        settings_button.margin_end = 6;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.pack_start (close_all_button);
        action_bar.pack_end (add_task_button);

        action_bar_revealer = new Gtk.Revealer ();
        action_bar_revealer.add (action_bar);
        action_bar_revealer.reveal_child = true;

        task_new_revealer = new Widgets.TaskNew (true);

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
        main_box.pack_end (action_bar_revealer, false, false, 0);
        main_box.pack_end (task_new_revealer, false, false, 0);

        add (main_box);
        update_tasks_list ();

        add_task_button.toggled.connect (() => {
            if (add_task_button.active) {
                task_on_revealer ();
            }
        });

        close_all_button.clicked.connect (() => {
            foreach (Gtk.Widget element in tasks_list.get_children ()) {
                var row = element as Widgets.TaskRow;

                row.hide_content ();
            }
        });

        /*
        this.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {

            }

            return false;
        });
        */

        task_new_revealer.on_signal_close.connect (() => {
            task_on_revealer ();
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
        if (action_bar_revealer.reveal_child) {
            action_bar_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
            task_new_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;

            action_bar_revealer.reveal_child = false;
            task_new_revealer.reveal_child = true;

            add_task_button.active = false;
            task_new_revealer.name_entry.grab_focus ();
        } else {
            action_bar_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
            task_new_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

            task_new_revealer.reveal_child = false;
            action_bar_revealer.reveal_child = true;
        }
    }
}
