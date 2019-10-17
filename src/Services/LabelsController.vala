public class Services.LabelsController : GLib.Object {
    construct {
        foreach (Objects.Label label in Application.database.get_all_labels ()) {
            apply_styles (label.id, Application.utils.get_color (label.color));
        }
    }

    private void apply_styles (int64 id, string color) {
        string COLOR_CSS = """
            .label-preview-%s {
                background-color: %s;
                border-radius: 4px; 
            }

            .label-item-%s {
                color: %s;
            }

            .label-%s {
                border-radius: 4px;
                padding: 2px 2px 1px 1px;
                background-image:
                    linear-gradient(
                        to bottom,
                        shade (
                        %s,
                            1
                        ),
                        %s
                    );
                border: 1px solid shade (%s, 0.9);
                color: %s
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                // Label preview
                id.to_string (),
                color,
                // Label Item
                id.to_string (),
                color,
                // Label Row
                id.to_string (),
                color,
                color,
                color,
                Application.utils.get_contrast (color)
            );
            
            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    public void add_label (Objects.Label label) {
        apply_styles (label.id, Application.utils.get_color (label.color));
    }

    public void update_label (Objects.Label label) {
        apply_styles (label.id, Application.utils.get_color (label.color));
    }
}