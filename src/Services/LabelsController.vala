public class Services.LabelsController : GLib.Object {
    construct {
        foreach (Objects.Label label in Planner.database.get_all_labels ()) {
            apply_styles (label.id, Planner.utils.get_color (label.color));
        }
    }

    private void apply_styles (int64 id, string color) {
        string COLOR_CSS = """
            .label-preview-%s {
                background-color: alpha (%s, 0.25);
                color: @text_color;
                padding : 0px 6px 1px 6px;
                border-radius: 50px;
                font-size: 9px;
                font-weight: 700;
                border: 1px solid shade (%s, 0.95)
            }

            .label-item-%s {
                color: %s;
            }

            .label-%s {
                color: %s
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                // Label preview
                id.to_string (),
                color,
                color,
                // Label Item
                id.to_string (),
                color,
                // Label Row
                id.to_string (),
                color
            );
            
            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    public void add_label (Objects.Label label) {
        apply_styles (label.id, Planner.utils.get_color (label.color));
    }

    public void update_label (Objects.Label label) {
        apply_styles (label.id, Planner.utils.get_color (label.color));
    }
}