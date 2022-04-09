public class Widgets.PriorityButton : Gtk.Button {
    public Objects.Item item { get; construct set; }
    public ECal.Component task { get; construct set; }

    private Widgets.DynamicIcon priority_image;

    public signal void changed (int priority);
    public signal void dialog_open (bool value);

    public PriorityButton (Objects.Item item) {
        Object (
            item: item,
            can_focus: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER
        );
    }

    public PriorityButton.for_component (ECal.Component task) {
        Object (
            task: task,
            can_focus: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        priority_image = new Widgets.DynamicIcon ();
        priority_image.size = 19;

        var projectbutton_grid = new Gtk.Grid () {
            column_spacing = 6,
            valign = Gtk.Align.CENTER
        };
        projectbutton_grid.add (priority_image);

        add (projectbutton_grid);
        update_request (item, task);

        clicked.connect (() => {
            var menu = new Dialogs.ContextMenu.Menu ();

            var priority_1_item = new Dialogs.ContextMenu.MenuItem (_("Priority 1: hight"), "planner-priority-1");
            var priority_2_item = new Dialogs.ContextMenu.MenuItem (_("Priority 2: medium"), "planner-priority-2");
            var priority_3_item = new Dialogs.ContextMenu.MenuItem (_("Priority 3: low"), "planner-priority-3");
            var priority_4_item = new Dialogs.ContextMenu.MenuItem (_("Priority 4: none"), "planner-flag");

            menu.add_item (priority_1_item);
            menu.add_item (priority_2_item);
            menu.add_item (priority_3_item);
            menu.add_item (priority_4_item);

            dialog_open (true);
            menu.popup ();

            priority_1_item.clicked.connect (() => {
                menu.hide_destroy ();
                changed (Constants.PRIORITY_1);
            });

            priority_2_item.clicked.connect (() => {
                menu.hide_destroy ();
                changed (Constants.PRIORITY_2);
            });

            priority_3_item.clicked.connect (() => {
                menu.hide_destroy ();
                changed (Constants.PRIORITY_3);
            });

            priority_4_item.clicked.connect (() => {
                menu.hide_destroy ();
                changed (Constants.PRIORITY_4);
            });

            menu.destroy.connect (() => {
                dialog_open (false);
            });
        });
    }
    
    public void update_request (Objects.Item? item = null, ECal.Component? task = null) {
        if (item != null) {
            priority_image.update_icon_name (item.priority_icon);
        }

        if (task != null) {
            int priority = task.get_priority ();

            if (priority <= 0) {
                priority_image.update_icon_name ("planner-flag");
            } else if (priority >= 1 && priority <= 4) {
                priority_image.update_icon_name ("planner-priority-1");
            } else if (priority == 5) {
                priority_image.update_icon_name ("planner-priority-2");
            } else if (priority > 5 && priority <= 9) {
                priority_image.update_icon_name ("planner-priority-3");
            } else {
                priority_image.update_icon_name ("planner-flag");
            }
        }
    }
}