public class Dialogs.Settings.SettingsSwitch : Gtk.EventBox {
    public string title { get; construct; }

    private Gtk.Label title_label;
    private Gtk.Switch enabled_switch;

    public signal void activated (bool active);

    public bool active {
        set {
            enabled_switch.active = value;
        }

        get {
            return enabled_switch.active;
        }
    }

    public SettingsSwitch (string title) {
        Object (
            title: title
        );
    }

    construct {
        hexpand = true;

        title_label = new Gtk.Label (title) {
            halign = Gtk.Align.START
        };

        enabled_switch = new Gtk.Switch ();
        enabled_switch.get_style_context ().add_class ("active-switch");
        
        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin = 3
        };

        main_box.pack_start (title_label, false, true, 0);
        main_box.pack_end (enabled_switch, false, false, 0);

        add (main_box);

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                enabled_switch.activate ();
            }

            return Gdk.EVENT_PROPAGATE;
        });

        enabled_switch.notify["active"].connect ((val) => {
            activated (active);
        });
    }
}
