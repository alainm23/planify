public class Widgets.TopHeaderProject : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    public TopHeaderProject (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var color_popover = new Widgets.ColorPopover ();
        color_popover.selected = project.color;

        var project_progress = new Widgets.ProjectProgress (18) {
            enable_subprojects = true,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            progress_fill_color = Util.get_default ().get_color (project.color)
        };

        var progress_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            popover = color_popover
        };
        progress_button.get_style_context ().add_class ("no-padding");
        progress_button.get_style_context ().add_class ("flat");
        progress_button.add (project_progress);

        var inbox_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("planner-inbox"),
            pixel_size = 24
        };

        var icon_progress_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        icon_progress_stack.add_named (progress_button, "color");
        icon_progress_stack.add_named (inbox_icon, "icon");
        
        var name_editable = new Widgets.EditableLabel ("title") {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            editable = !project.inbox_project
        };
        name_editable.text = project.inbox_project ? _("Inbox") : project.name;

        var menu_image = new Gtk.Image () {
            gicon = new ThemedIcon ("content-loading-symbolic"),
            pixel_size = 16
        };
        
        var menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        menu_button.add (menu_image);
        menu_button.get_style_context ().add_class ("flat");

        var search_image = new Widgets.DynamicIcon ();
        search_image.size = 19;
        search_image.update_icon_name ("planner-search");
        
        var search_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        search_button.get_style_context ().add_class ("flat");
        search_button.add (search_image);

        var projectrow_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.START,
            hexpand = true,
            margin_start = 2,
            margin_end = 6
        };

        projectrow_box.pack_start (icon_progress_stack, false, false, 0);
        projectrow_box.pack_start (name_editable, false, true, 0);
        projectrow_box.pack_end (menu_button, false, false, 0);
        projectrow_box.pack_end (search_button, false, false, 0);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            hexpand = true
        };
        main_grid.add (projectrow_box);

        add (main_grid);

        Timeout.add (icon_progress_stack.transition_duration, () => {
            icon_progress_stack.visible_child_name = project.inbox_project ? "icon" : "color";
            return GLib.Source.REMOVE;
        });
        
        name_editable.changed.connect (() => {
            project.name = name_editable.text;
            project.update ();
        });

        color_popover.color_changed.connect ((color) => {
            project.color = color;
            project.update ();
        });

        project.updated.connect (() => {
            name_editable.text = project.name;
            color_popover.selected = project.color;
            project_progress.progress_fill_color = Util.get_default ().get_color (project.color);
        });
    }
}