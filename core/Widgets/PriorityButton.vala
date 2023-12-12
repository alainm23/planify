public class Widgets.PriorityButton : Adw.Bin {
    private Widgets.DynamicIcon priority_image;
    private Gtk.MenuButton button; 
    private Gtk.Popover priority_picker = null;

    public signal void changed (int priority);

    public PriorityButton () {
        Object (
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Set the priority")
        );
    }

    construct {
        priority_image = new Widgets.DynamicIcon ();
        priority_image.size = 16;

        button = new Gtk.MenuButton () {
            css_classes = { Granite.STYLE_CLASS_FLAT },
            valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
            child = priority_image,
            popover = build_popover (),
        };

        child = button;
    }

    public Gtk.Popover build_popover () {
        var priority_1_item = new Widgets.ContextMenu.MenuItem (_("Priority 1: high"), "planner-priority-1");
        var priority_2_item = new Widgets.ContextMenu.MenuItem (_("Priority 2: medium"), "planner-priority-2");
        var priority_3_item = new Widgets.ContextMenu.MenuItem (_("Priority 3: low"), "planner-priority-3");
        var priority_4_item = new Widgets.ContextMenu.MenuItem (_("Priority 4: none"), "planner-flag");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (priority_1_item);
        menu_box.append (priority_2_item);
        menu_box.append (priority_3_item);
        menu_box.append (priority_4_item);

        priority_picker = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM
        };

        priority_1_item.clicked.connect (() => {
            priority_picker.popdown ();
            changed (Constants.PRIORITY_1);
        });

        priority_2_item.clicked.connect (() => {
            priority_picker.popdown ();
            changed (Constants.PRIORITY_2);
        });

        priority_3_item.clicked.connect (() => {
            priority_picker.popdown ();
            changed (Constants.PRIORITY_3);
        });

        priority_4_item.clicked.connect (() => {
            priority_picker.popdown ();
            changed (Constants.PRIORITY_4);
        });

        return priority_picker;
    }
    
    public void update_from_item (Objects.Item item) {
        priority_image.update_icon_name (item.priority_icon);
    }
}