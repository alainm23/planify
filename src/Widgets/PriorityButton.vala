public class Widgets.PriorityButton : Gtk.Button {
    // public Objects.Item item { get; construct set; }
    // public ECal.Component task { get; construct set; }

    private Widgets.DynamicIcon priority_image;
    private Gtk.Popover priority_picker = null;

    public signal void changed (int priority);

    public PriorityButton () {
        Object (
            can_focus: false,
            valign: Gtk.Align.CENTER,
            halign: Gtk.Align.CENTER,
            tooltip_text: _("Set the priority")
        );
    }

    //  public PriorityButton.for_component (ECal.Component task) {
    //      Object (
    //          task: task,
    //          can_focus: false,
    //          valign: Gtk.Align.CENTER,
    //          halign: Gtk.Align.CENTER,
    //          tooltip_text: _("Set the priority")
    //      );
    //  }

    construct {
        add_css_class (Granite.STYLE_CLASS_FLAT);
        add_css_class ("p3");

        priority_image = new Widgets.DynamicIcon ();
        priority_image.size = 19;

        var projectbutton_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            valign = Gtk.Align.CENTER
        };
        projectbutton_box.append (priority_image);

        child = projectbutton_box;
        // update_request (item, task);

        var gesture = new Gtk.GestureClick ();
        gesture.set_button (1);
        add_controller (gesture);

        gesture.pressed.connect ((n_press, x, y) => {
            gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            open_picker ();
        });
    }

    public void open_picker () {
        if (priority_picker != null) {
            priority_picker.popup ();
            return;
        }

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

        priority_picker.set_parent (this);
        priority_picker.popup();

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
    }
    
    public void update_from_item (Objects.Item item) {
        priority_image.update_icon_name (item.priority_icon);

        //  if (task != null) {
        //      int priority = task.get_priority ();

        //      if (priority <= 0) {
        //          priority_image.update_icon_name ("planner-flag");
        //      } else if (priority >= 1 && priority <= 4) {
        //          priority_image.update_icon_name ("planner-priority-1");
        //      } else if (priority == 5) {
        //          priority_image.update_icon_name ("planner-priority-2");
        //      } else if (priority > 5 && priority <= 9) {
        //          priority_image.update_icon_name ("planner-priority-3");
        //      } else {
        //          priority_image.update_icon_name ("planner-flag");
        //      }
        //  }
    }
}