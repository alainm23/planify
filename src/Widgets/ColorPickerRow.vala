public class Widgets.ColorPickerRow : Gtk.Grid {
    public string color { get; set; }

    public signal void color_changed (string color);

    private Gee.HashMap <string, Gtk.CheckButton> colors_hashmap;

    public ColorPickerRow () {
        Object(

        );
    }

    construct {
        colors_hashmap = new Gee.HashMap <string, Gtk.CheckButton> ();

        var colors_flowbox = new Gtk.FlowBox () {
            column_spacing = 6,
            row_spacing = 6,
            max_children_per_line = 10,
            min_children_per_line = 10,
            homogeneous = true,
            margin_top = 9,
            margin_bottom = 9,
            margin_start = 9,
            margin_end = 9,
            vexpand = true,
            hexpand = true,
            selection_mode = Gtk.SelectionMode.NONE
        };

        var radio = new Gtk.CheckButton ();
        foreach (var entry in Util.get_default ().get_colors ().entries) {
            if (!entry.key.has_prefix ("#")) {
                Gtk.CheckButton color_radio = new Gtk.CheckButton () {
                    valign = Gtk.Align.CENTER,
                    halign = Gtk.Align.CENTER,
                    tooltip_text = Util.get_default ().get_color_name (entry.key)
                };
                color_radio.add_css_class ("color-radio");
                color_radio.set_group (radio);
                
                Util.get_default ().set_widget_color (Util.get_default ().get_color (entry.key), color_radio);
                colors_hashmap [entry.key] = color_radio;
                colors_flowbox.append (colors_hashmap [entry.key]);
                
                color_radio.toggled.connect (() => {
                    color = entry.key;
                    color_changed (color);
                });

                colors_flowbox.child_activated.connect ((child) => {
                    // color = entry.key;
                    // color_changed (color);
                });
            }
        }

        attach(colors_flowbox, 0, 0);

        notify["color"].connect (() => {
            if (colors_hashmap.has_key (color)) {
                colors_hashmap [color].active = true;
            }
        });
    }
}