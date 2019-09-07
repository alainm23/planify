public class Views.Project : Gtk.EventBox {
    public Objects.Project project { get; set; }

    construct {
        var grid_color = new Gtk.Grid ();
        grid_color.margin_start = 4;
        grid_color.set_size_request (24, 24);
        grid_color.valign = Gtk.Align.CENTER;
        grid_color.halign = Gtk.Align.CENTER;

        var name_label = new Gtk.Label (null);//"<b>%s</b>".printf (_("Inbox")));
        name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        name_label.get_style_context ().add_class ("font-bold");
        name_label.use_markup = true;

        var project_settings_popover = new Widgets.Popovers.ProjectSettings ();

        var settings_button = new Gtk.MenuButton ();
        settings_button.can_focus = false;
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.width_request = 32;
        settings_button.tooltip_text = _("Edit Name and Appearance");
        settings_button.popover = project_settings_popover;
        settings_button.add (new Gtk.Image.from_icon_name ("view-more-horizontal-symbolic", Gtk.IconSize.MENU));

        var add_button = new Gtk.Button ();
        add_button.can_focus = false;
        //add_button.tooltip_text = _("Synchronizing");
        //add_button.margin_start = 9;
        //add_button.margin_end = 3;
        add_button.width_request = 32;
        add_button.valign = Gtk.Align.CENTER;
        add_button.halign = Gtk.Align.CENTER;
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        //add_button.get_style_context ().add_class ("sync");
        //add_button.get_style_context ().add_class ("headerbar-widget");
        add_button.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.BUTTON));

        var mode_button = new Granite.Widgets.ModeButton ();
        mode_button.get_style_context ().add_class ("mode-button");
        mode_button.append_text (_("Task"));
        mode_button.append_text (_("Issues"));
        //mode_button.append_text (_("Lyrics"));
        mode_button.selected = 0;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_start = 30;
        top_box.margin_end = 30;

        top_box.pack_start (grid_color, false, false, 0);
        top_box.pack_start (name_label, false, false, 6);
        top_box.pack_end (settings_button, false, false, 0);
        //top_box.pack_end (mode_button, false, false, 6);
        top_box.pack_end (add_button, false, false, 6);

        add (top_box);

        settings_button.toggled.connect (() => {
            if (settings_button.active) {
                project_settings_popover.project = project;
            }
        });

        notify["project"].connect (() => {
            if (project != null) {
                name_label.label = project.name;
                grid_color.get_style_context ().add_class ("project-view-%i".printf ((int32) project.id));

                apply_styles (Application.utils.get_color (project.color));
            } else {
                name_label.label = "";
            }

            show_all ();
        });
    }

    private void apply_styles (string color) {
        string COLOR_CSS = """
            .project-view-%i {
                background-color: %s;
                border-radius: 50%;
                box-shadow: inset 0px 0px 0px 1px rgba(0, 0, 0, 0.2);
            }
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = COLOR_CSS.printf (
                (int32) project.id,
                color
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }
}