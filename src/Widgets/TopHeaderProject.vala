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
            progress_fill_color = Util.get_default ().get_color (project.color),
            percentage = project.percentage
        };
        
        var emoji_label = new Gtk.Label (project.emoji) {
            halign = Gtk.Align.CENTER
        };
        emoji_label.get_style_context ().add_class ("header-title");

        var progress_emoji_stack = new Gtk.Stack ();
        progress_emoji_stack.add_named (project_progress, "progress");
        progress_emoji_stack.add_named (emoji_label, "label");

        var progress_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            popover = color_popover
        };
        progress_button.get_style_context ().add_class ("no-padding");
        progress_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        progress_button.add (progress_emoji_stack);

        var inbox_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("planner-inbox"),
            pixel_size = 24
        };

        var icon_progress_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        icon_progress_stack.add_named (progress_button, "color");
        icon_progress_stack.add_named (inbox_icon, "icon");
        
        var name_editable = new Widgets.EditableLabel ("header-title") {
            valign = Gtk.Align.CENTER,
            editable = !project.inbox_project
        };
        name_editable.text = project.inbox_project ? _("Inbox") : project.name;

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 19;
        menu_image.update_icon_name ("dots-horizontal");
        
        var menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        menu_button.add (menu_image);
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        menu_button.clicked.connect (project.build_content_menu);
        
        var search_image = new Widgets.DynamicIcon ();
        search_image.size = 19;
        search_image.update_icon_name ("planner-search");
        
        var search_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        search_button.add (search_image);
        search_button.clicked.connect (Util.get_default ().open_quick_find);

        var projectrow_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            valign = Gtk.Align.START,
            hexpand = true
        };

        projectrow_box.pack_start (icon_progress_stack, false, false, 0);
        projectrow_box.pack_start (name_editable, false, false, 6);
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
            if (project.icon_style == ProjectIconStyle.PROGRESS) {
                progress_emoji_stack.visible_child_name = "progress";
            } else {
                progress_emoji_stack.visible_child_name = "label";
            }

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
            project_progress.percentage = project.percentage;
            
            emoji_label.label = project.emoji;
            if (project.icon_style == ProjectIconStyle.PROGRESS) {
                progress_emoji_stack.visible_child_name = "progress";
            } else {
                progress_emoji_stack.visible_child_name = "label";
            }
        });

        project.project_count_updated.connect (() => {
            project_progress.percentage = project.percentage;
        });
    }
}
