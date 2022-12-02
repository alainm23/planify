public class Widgets.ColorPickerRow : Gtk.Grid {
    public string lines { get; construct; }
    public string color { get; set; }

    public signal void color_changed (string color);

    private Gee.HashMap <string, Gtk.CheckButton> colors_hashmap;

    public ColorPickerRow (string lines = "inset") {
        Object(
            margin_start: 6,
            margin_top: 3,
            margin_end: 6,
            lines: lines
        );
    }

    construct {
        colors_hashmap = new Gee.HashMap <string, Gtk.CheckButton> ();

        var color_image = new Widgets.DynamicIcon ();
        color_image.size = 24;
        color_image.update_icon_name("color-swatch");

        var color_title = new Gtk.Label (_("Color"));

        var color_widget_selected = new Gtk.Grid () {
            height_request = 16,
            width_request = 16,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
        };

        color_widget_selected.add_css_class ("color-row-picker-selected");

        var arrow_image = new Widgets.DynamicIcon ();

        arrow_image.size = 24;
        arrow_image.update_icon_name("chevron-right");

        arrow_image.add_css_class ("hidden-button");

        var align_end_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            halign = Gtk.Align.END
        };
        align_end_box.append(color_widget_selected);
        align_end_box.append(arrow_image);

        var h_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);

        h_box.append(color_image);
        h_box.append(color_title);
        h_box.append(align_end_box);

        var colors_flowbox = new Gtk.FlowBox () {
            column_spacing = 6,
            row_spacing = 6,
            max_children_per_line = 10,
            min_children_per_line = 10,
            homogeneous = true,
            margin_top = 6
        };

        var colors_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        var colors_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
            margin_top = 6
        };

        colors_box.append (colors_separator);
        colors_box.append (colors_flowbox);

        var radio = new Gtk.CheckButton ();

        foreach (var entry in Util.get_default ().get_colors ().entries) {
            if (!entry.key.has_prefix ("#")) {
                Gtk.CheckButton color_radio = new Gtk.CheckButton ();
                color_radio.valign = Gtk.Align.CENTER;
                color_radio.halign = Gtk.Align.CENTER;
                color_radio.tooltip_text = Util.get_default ().get_color_name (entry.key);
                color_radio.add_css_class ("color-radio");
                color_radio.set_group (radio);
                
                Util.get_default ().set_widget_color (Util.get_default ().get_color (entry.key), color_radio);
                colors_hashmap [entry.key] = color_radio;
                colors_flowbox.append (colors_hashmap [entry.key]);
                
                color_radio.toggled.connect (() => {
                    color = entry.key;
                    color_changed (color);
                    Util.get_default ().set_widget_color (Util.get_default ().get_color (color), color_widget_selected);
                });
            }
        }
        
        var colors_revealer = new Gtk.Revealer();
        colors_revealer.child = colors_box;
    
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3
        };

        var v_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        v_box.append (h_box);
        v_box.append (colors_revealer);
        v_box.append (separator);

        attach(v_box, 0, 0);

        if (lines == "none") {
            separator.visible = false;
        }

        var gesture = new Gtk.GestureClick ();

        gesture.pressed.connect (() => {
            colors_revealer.reveal_child = !colors_revealer.reveal_child;
            
            if (colors_revealer.reveal_child) {
                arrow_image.add_css_class ("opened");
            } else {
                arrow_image.remove_css_class ("opened");
            }
        });

        h_box.add_controller (gesture);

        notify["color"].connect (() => {
            if (colors_hashmap.has_key (color)) {
                colors_hashmap [color].active = true;
                Util.get_default ().set_widget_color (Util.get_default ().get_color (color), color_widget_selected);
            }
        });
    }
}