public class Widgets.LabelChild : Gtk.FlowBoxChild {
    public Objects.Label label { get; construct; }
    public bool show_close = true;
    public const string COLOR_CSS = """
        .label-%i {
            background-image:
                linear-gradient(
                    to bottom,
                    shade (
                    %s,
                        1.3
                    ),
                    %s
                );
            border: 1px solid shade (%s, 0.9);
            border-radius: 3px;
            box-shadow:
                inset 0 0 0 1px alpha (#fff, 0.05),
                inset 0 1px 0 0 alpha (#fff, 0.25),
                inset 0 -1px 0 0 alpha (#fff, 0.1),
                0 1px 2px alpha (#000, 0.3);
            color: %s;
            padding: 1 6px;
            font-size: 11px;
            font-weight: 700;
            margin: 2px;
            min-width: 18px;
            min-height: 18px;
            text-shadow: 0 1px 1px alpha (#000, 0.3);
        }
    """;
    public LabelChild (Objects.Label _label) {
        Object (
            label: _label
        );
    }

    construct {
        get_style_context ().add_class ("label-child");

        var remove_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU);
        remove_button.get_style_context ().add_class ("button-overlay-circular");

        var remove_revealer = new Gtk.Revealer ();
        remove_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        remove_revealer.valign = Gtk.Align.START;
        remove_revealer.halign = Gtk.Align.START;
        remove_revealer.add (remove_button);
        remove_revealer.reveal_child = false;

        var name_label = new Gtk.Label (label.name);
        name_label.margin = 6;
        name_label.get_style_context ().add_class ("label-" + label.id.to_string ());

        var overlay = new Gtk.Overlay ();
        overlay.add_overlay (remove_revealer);
        overlay.add (name_label);

        var eventbox = new Gtk.EventBox ();
        eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        eventbox.add (overlay);

        add (eventbox);
        show_all ();

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                label.id,
                label.color,
                label.color,
                label.color,                                // Background Color
                Planner.utils.convert_invert (label.color)  // Text Color
            );
            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }

        eventbox.enter_notify_event.connect ((event) => {
            if (show_close) {
                remove_revealer.reveal_child = true;
            }

            return false;
        });

        eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (show_close) {
                remove_revealer.reveal_child = false;
            }

            return false;
        });

        remove_button.clicked.connect (() => {
            Timeout.add (20, () => {
                this.opacity = this.opacity - 0.1;

                if (this.opacity <= 0) {
                    destroy ();
                    return false;
                }

                return true;
            });
        });
    }
}
