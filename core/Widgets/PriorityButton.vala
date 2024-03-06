public class Widgets.PriorityButton : Adw.Bin {
    private Gtk.Image priority_image;
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
        priority_image = new Gtk.Image.from_icon_name ("flag-outline-thick-symbolic");

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
        var priority_1_item = new Widgets.ContextMenu.MenuItem (_("Priority 1: high"), "flag-outline-thick-symbolic");
        priority_1_item.add_css_class ("priority-1-button");

        var priority_2_item = new Widgets.ContextMenu.MenuItem (_("Priority 2: medium"), "flag-outline-thick-symbolic");
        priority_2_item.add_css_class ("priority-2-button");

        var priority_3_item = new Widgets.ContextMenu.MenuItem (_("Priority 3: low"), "flag-outline-thick-symbolic");
        priority_3_item.add_css_class ("priority-3-button");

        var priority_4_item = new Widgets.ContextMenu.MenuItem (_("Priority 4: none"), "flag-outline-thick-symbolic");

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
        if (item.priority == Constants.PRIORITY_1) {
            priority_image.css_classes = { "flat", "priority-1-icon" };
        } else if (item.priority == Constants.PRIORITY_2) {
            priority_image.css_classes = { "flat", "priority-2-icon" };
        } else if (item.priority == Constants.PRIORITY_3) {
            priority_image.css_classes = { "flat", "priority-3-icon" };
        } else {
            priority_image.css_classes = {  };
        }
    }

    public void set_priority (int priority) {
        if (priority == Constants.PRIORITY_1) {
            priority_image.css_classes = { "flat", "priority-1-icon" };
        } else if (priority == Constants.PRIORITY_2) {
            priority_image.css_classes = { "flat", "priority-2-icon" };
        } else if (priority == Constants.PRIORITY_3) {
            priority_image.css_classes = { "flat", "priority-3-icon" };
        } else {
            priority_image.css_classes = { "flat" };
        }
    }
    
    public void reset () {
        priority_image.icon_name = "flag-outline-thick-symbolic";
    }
}
