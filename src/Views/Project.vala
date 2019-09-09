public class Views.Project : Gtk.EventBox {
    public Objects.Project project { get; set; }
    construct {
        var grid_color = new Gtk.Grid ();
        grid_color.margin_start = 3;
        grid_color.set_size_request (16, 16);
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
        settings_button.tooltip_text = _("Edit Name and Appearance");
        settings_button.popover = project_settings_popover;
        settings_button.get_style_context ().add_class ("flat");
        settings_button.get_style_context ().add_class ("dim-label");

        var settings_image = new Gtk.Image ();
        settings_image.gicon = new ThemedIcon ("view-more-horizontal-symbolic");
        settings_image.pixel_size = 14;
        settings_button.add (settings_image);

        var add_button = new Gtk.Button (); 
        add_button.can_focus = false;
        //add_button.tooltip_text = _("Synchronizing");
        //add_button.margin_start = 9;
        //add_button.margin_end = 3;
        add_button.width_request = 32;
        add_button.height_request = 32;
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
        top_box.margin_start = 24;
        top_box.margin_end = 24;

        top_box.pack_start (grid_color, false, false, 0);
        top_box.pack_start (name_label, false, false, 7);
        //top_box.pack_start (settings_button, false, false, 0);
        //top_box.pack_end (mode_button, false, false, 6);
        //top_box.pack_end (add_button, false, false, 6);

        add (top_box);

        settings_button.toggled.connect (() => {
            if (settings_button.active) {
                project_settings_popover.project = project;
            }
        });

        notify["project"].connect (() => {
            if (project != null) {
                name_label.label = project.name;
            
                grid_color.get_style_context ().list_classes ().foreach ((c) => {
                    if (c != "horizontal") {
                        grid_color.get_style_context ().remove_class (c);
                    }
                });

                grid_color.get_style_context ().add_class ("project-%s".printf (project.id.to_string ()));
            } else {
                name_label.label = "";
            }

            show_all ();
        });

        Application.database.project_updated.connect ((p) => {
            if (project != null && p.id == project.id) {
                project = p;
            }
        });
    }
}