public class Widgets.LabelRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }
    public Gtk.Entry name_entry;
    private Gtk.Popover popover = null;
    private Gtk.ToggleButton color_button;
    private Gtk.Revealer buttons_revealer;
    private int color_selected = 30;
    public LabelRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    construct {
        color_selected = label.color;
        can_focus = false;
        get_style_context ().add_class ("label-row");

        var button_image = new Gtk.Image.from_icon_name ("tag-symbolic", Gtk.IconSize.MENU);
        button_image.valign = Gtk.Align.CENTER;
        button_image.halign = Gtk.Align.CENTER;
        button_image.can_focus = false;
        button_image.get_style_context ().add_class ("label-%s".printf (label.id.to_string ()));

        name_entry = new Gtk.Entry ();
        name_entry.text = label.name;
        name_entry.placeholder_text = _("Home");
        name_entry.get_style_context ().add_class ("h3");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("check-entry");
        name_entry.get_style_context ().add_class ("font-weight-600");
        name_entry.hexpand = true;

        color_button = new Gtk.ToggleButton ();
        color_button.valign = Gtk.Align.CENTER;
        color_button.get_style_context ().add_class ("flat");
        color_button.get_style_context ().add_class ("delete-check-button");

        var color_image = new Gtk.Image ();
        color_image.gicon = new ThemedIcon ("preferences-color-symbolic");
        color_image.pixel_size = 16;

        color_button.add (color_image);

        var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic");
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.can_focus = false;
        delete_button.get_style_context ().add_class ("flat");
        delete_button.get_style_context ().add_class ("delete-check-button");

        var buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        buttons_box.pack_start (color_button, false, false, 0);
        buttons_box.pack_start (delete_button, false, true, 0);

        buttons_revealer = new Gtk.Revealer ();
        buttons_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        buttons_revealer.add (buttons_box);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.margin_start = 12;
        box.margin_end = 12;
        box.margin_top = 3;
        box.margin_bottom = 3;
        box.pack_start (button_image, false, false, 0);
        box.pack_start (name_entry, false, true, 0);
        box.pack_end (buttons_revealer, false, true, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.pack_start (box, false, false, 0);
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);

        var handle = new Gtk.EventBox ();
        handle.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        handle.add (main_box);

        add (handle);

        handle.enter_notify_event.connect ((event) => {
            buttons_revealer.reveal_child = true;

            return true;
        });

        handle.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }
            
            if (color_button.active == false) {
                buttons_revealer.reveal_child = false;
            }

            return true;
        });

        delete_button.clicked.connect (() => {
            Planner.database.delete_label (label);
        });

        color_button.toggled.connect (() => {
            if (color_button.active) {
                if (popover == null) {
                    create_popover ();
                }

                popover.show_all ();
            }
        });

        name_entry.changed.connect (() => {
            save ();
        }); 
        
        Planner.database.label_deleted.connect ((l) => {
            if (label.id == l.id) {
                destroy ();
            }
        });
    }
    
    private void save () {
        label.name = name_entry.text;
        label.color = color_selected;

        label.save ();
    }

    private void create_popover () {
        popover = new Gtk.Popover (color_button);
        popover.position = Gtk.PositionType.BOTTOM;

        var color_30 = new Gtk.RadioButton (null);
        color_30.valign = Gtk.Align.START;
        color_30.halign = Gtk.Align.START;
        color_30.get_style_context ().add_class ("color-30");
        color_30.get_style_context ().add_class ("color-radio");

        var color_31 = new Gtk.RadioButton.from_widget (color_30);
        color_31.valign = Gtk.Align.START;
        color_31.halign = Gtk.Align.START;
        color_31.get_style_context ().add_class ("color-31");
        color_31.get_style_context ().add_class ("color-radio");

        var color_32 = new Gtk.RadioButton.from_widget (color_30);
        color_32.valign = Gtk.Align.START;
        color_32.halign = Gtk.Align.START;
        color_32.get_style_context ().add_class ("color-32");
        color_32.get_style_context ().add_class ("color-radio");

        var color_33 = new Gtk.RadioButton.from_widget (color_30);
        color_33.valign = Gtk.Align.START;
        color_33.halign = Gtk.Align.START;
        color_33.get_style_context ().add_class ("color-33");
        color_33.get_style_context ().add_class ("color-radio");

        var color_34 = new Gtk.RadioButton.from_widget (color_30);
        color_34.valign = Gtk.Align.START;
        color_34.halign = Gtk.Align.START;
        color_34.get_style_context ().add_class ("color-34");
        color_34.get_style_context ().add_class ("color-radio");

        var color_35 = new Gtk.RadioButton.from_widget (color_30);
        color_35.valign = Gtk.Align.START;
        color_35.halign = Gtk.Align.START;
        color_35.get_style_context ().add_class ("color-35");
        color_35.get_style_context ().add_class ("color-radio");

        var color_36 = new Gtk.RadioButton.from_widget (color_30);
        color_36.valign = Gtk.Align.START;
        color_36.halign = Gtk.Align.START;
        color_36.get_style_context ().add_class ("color-36");
        color_36.get_style_context ().add_class ("color-radio");

        var color_37 = new Gtk.RadioButton.from_widget (color_30);
        color_37.valign = Gtk.Align.START;
        color_37.halign = Gtk.Align.START;
        color_37.get_style_context ().add_class ("color-37");
        color_37.get_style_context ().add_class ("color-radio");

        var color_38 = new Gtk.RadioButton.from_widget (color_30);
        color_38.valign = Gtk.Align.START;
        color_38.halign = Gtk.Align.START;
        color_38.get_style_context ().add_class ("color-38");
        color_38.get_style_context ().add_class ("color-radio");

        var color_39 = new Gtk.RadioButton.from_widget (color_30);
        color_39.valign = Gtk.Align.START;
        color_39.halign = Gtk.Align.START;
        color_39.get_style_context ().add_class ("color-39");
        color_39.get_style_context ().add_class ("color-radio");

        var color_40 = new Gtk.RadioButton.from_widget (color_30);
        color_40.valign = Gtk.Align.START;
        color_40.halign = Gtk.Align.START;
        color_40.get_style_context ().add_class ("color-40");
        color_40.get_style_context ().add_class ("color-radio");

        var color_41 = new Gtk.RadioButton.from_widget (color_30);
        color_41.valign = Gtk.Align.START;
        color_41.halign = Gtk.Align.START;
        color_41.get_style_context ().add_class ("color-41");
        color_41.get_style_context ().add_class ("color-radio");

        var color_42 = new Gtk.RadioButton.from_widget (color_30);
        color_42.valign = Gtk.Align.START;
        color_42.halign = Gtk.Align.START;
        color_42.get_style_context ().add_class ("color-42");
        color_42.get_style_context ().add_class ("color-radio");

        var color_43 = new Gtk.RadioButton.from_widget (color_30);
        color_43.valign = Gtk.Align.START;
        color_43.halign = Gtk.Align.START;
        color_43.get_style_context ().add_class ("color-43");
        color_43.get_style_context ().add_class ("color-radio");

        var color_44 = new Gtk.RadioButton.from_widget (color_30);
        color_44.valign = Gtk.Align.START;
        color_44.halign = Gtk.Align.START;
        color_44.get_style_context ().add_class ("color-44");
        color_44.get_style_context ().add_class ("color-radio");

        var color_45 = new Gtk.RadioButton.from_widget (color_30);
        color_45.valign = Gtk.Align.START;
        color_45.halign = Gtk.Align.START;
        color_45.get_style_context ().add_class ("color-45");
        color_45.get_style_context ().add_class ("color-radio");
        
        var color_46 = new Gtk.RadioButton.from_widget (color_30);
        color_46.valign = Gtk.Align.START;
        color_46.halign = Gtk.Align.START;
        color_46.get_style_context ().add_class ("color-46");
        color_46.get_style_context ().add_class ("color-radio");

        var color_47 = new Gtk.RadioButton.from_widget (color_30);
        color_47.valign = Gtk.Align.START;
        color_47.halign = Gtk.Align.START;
        color_47.get_style_context ().add_class ("color-47");
        color_47.get_style_context ().add_class ("color-radio");

        var color_48 = new Gtk.RadioButton.from_widget (color_30);
        color_48.valign = Gtk.Align.START;
        color_48.halign = Gtk.Align.START;
        color_48.get_style_context ().add_class ("color-48");
        color_48.get_style_context ().add_class ("color-radio");

        var color_49 = new Gtk.RadioButton.from_widget (color_30);
        color_49.valign = Gtk.Align.START;
        color_49.halign = Gtk.Align.START;
        color_49.get_style_context ().add_class ("color-49");
        color_49.get_style_context ().add_class ("color-radio");

        var color_box = new Gtk.Grid ();
        color_box.hexpand = true;
        color_box.margin_start = 6;
        color_box.margin_end = 6;
        color_box.column_homogeneous = true;
        color_box.row_homogeneous = true;
        color_box.row_spacing = 9;
        color_box.column_spacing = 12;

        color_box.attach (color_30, 0, 0, 1, 1);
        color_box.attach (color_31, 1, 0, 1, 1);
        color_box.attach (color_32, 2, 0, 1, 1);
        color_box.attach (color_33, 3, 0, 1, 1);
        color_box.attach (color_34, 4, 0, 1, 1);
        color_box.attach (color_35, 5, 0, 1, 1);
        color_box.attach (color_36, 6, 0, 1, 1);
        color_box.attach (color_37, 0, 1, 1, 1);
        color_box.attach (color_38, 1, 1, 1, 1);
        color_box.attach (color_39, 2, 1, 1, 1);
        color_box.attach (color_40, 3, 1, 1, 1);
        color_box.attach (color_41, 4, 1, 1, 1);
        color_box.attach (color_42, 5, 1, 1, 1);
        color_box.attach (color_43, 6, 1, 1, 1);
        color_box.attach (color_44, 0, 2, 1, 1);
        color_box.attach (color_45, 1, 2, 1, 1);
        color_box.attach (color_46, 2, 2, 1, 1);
        color_box.attach (color_47, 3, 2, 1, 1);
        color_box.attach (color_48, 4, 2, 1, 1);
        color_box.attach (color_49, 5, 2, 1, 1);

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 235;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 6;
        popover_grid.margin_bottom = 6;
        popover_grid.add (color_box);

        popover.add (popover_grid);

        popover.closed.connect (() => {
            buttons_revealer.reveal_child = false;
            color_button.active = false;
        });

        color_30.toggled.connect (() => {
            color_selected = 30;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_31.toggled.connect (() => {
            color_selected = 31;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_32.toggled.connect (() => {
            color_selected = 32;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_33.toggled.connect (() => {
            color_selected = 33;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_34.toggled.connect (() => {
            color_selected = 34;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_35.toggled.connect (() => {
            color_selected = 35;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_36.toggled.connect (() => {
            color_selected = 36;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_37.toggled.connect (() => {
            color_selected = 37;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_38.toggled.connect (() => {
            color_selected = 38;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_39.toggled.connect (() => {
            color_selected = 39;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_40.toggled.connect (() => {
            color_selected = 40;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_41.toggled.connect (() => {
            color_selected = 41;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_42.toggled.connect (() => {
            color_selected = 42;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_43.toggled.connect (() => {
            color_selected = 43;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_44.toggled.connect (() => {
            color_selected = 44;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_45.toggled.connect (() => {
            color_selected = 45;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_46.toggled.connect (() => {
            color_selected = 46;
        });

        color_47.toggled.connect (() => {
            color_selected = 47;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_48.toggled.connect (() => {
            color_selected = 48;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });

        color_49.toggled.connect (() => {
            color_selected = 49;
            save ();
            //apply_styles (Planner.utils.get_color (color_selected));
            //apply_styles (Planner.utils.get_color (color_selected));
        });
    }

    private void apply_styles (string color) {
        string COLOR_CSS = """
            .label-%s {
                color: %s
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                label.id.to_string (),
                color
            );
            
            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }
}