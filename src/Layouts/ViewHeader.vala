public class Layouts.ViewHeader : Hdy.HeaderBar {
    public Objects.Project project { get; set; }
    
    private Gtk.Revealer project_revealer;
    private Gtk.Revealer end_revealer;
    private Widgets.ProjectProgress project_progress;
    private Gtk.Label name_label;
    private Gtk.Label emoji_label;
    private Gtk.Stack progress_emoji_stack;

    construct {
        var sidebar_image = new Widgets.DynamicIcon ();
        sidebar_image.size = 19;
        sidebar_image.update_icon_name ("sidebar-left");
        
        var sidebar_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        sidebar_button.add (sidebar_image);

        unowned Gtk.StyleContext sidebar_button_context = sidebar_button.get_style_context ();
        sidebar_button_context.add_class (Gtk.STYLE_CLASS_FLAT);

        project_progress = new Widgets.ProjectProgress (16);
        project_progress.enable_subprojects = true;
        project_progress.valign = Gtk.Align.CENTER;
        project_progress.halign = Gtk.Align.CENTER;
        
        emoji_label = new Gtk.Label (null) {
            halign = Gtk.Align.CENTER
        };
        
        unowned Gtk.StyleContext emoji_label_context = emoji_label.get_style_context ();
        emoji_label_context.add_class ("h4");
        emoji_label_context.add_class ("opacity-1");

        progress_emoji_stack = new Gtk.Stack ();
        progress_emoji_stack.add_named (project_progress, "progress");
        progress_emoji_stack.add_named (emoji_label, "label");

        name_label = new Gtk.Label (null);
        name_label.valign = Gtk.Align.CENTER;

        unowned Gtk.StyleContext name_label_context = name_label.get_style_context ();
        name_label_context.add_class ("h4");
        name_label_context.add_class ("opacity-1");

        var project_grid = new Gtk.Grid () {
            column_spacing = 6,
            valign = Gtk.Align.CENTER
        };
        project_grid.add (progress_emoji_stack);
        project_grid.add (name_label);

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 19;
        menu_image.update_icon_name ("dots-horizontal");
        
        var menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        menu_button.add (menu_image);
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var view_image = new Widgets.DynamicIcon ();
        view_image.size = 19;
        view_image.update_icon_name ("planner-settings-sliders");
        
        var view_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        view_button.add (view_image);
        view_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

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

        var end_grid = new Gtk.Grid () {
            column_spacing = 0,
            margin_end = 0
        };

        end_grid.add (search_button);
        end_grid.add (view_button);
        end_grid.add (menu_button);

        end_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };
        end_revealer.add (end_grid);

        project_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };
        project_revealer.add (project_grid);

        var start_grid = new Gtk.Grid () {
            column_spacing = 6
        };

        start_grid.add (sidebar_button);

        pack_start (start_grid);
        custom_title = project_revealer;
        pack_end (end_revealer);

        notify["project"].connect (() => {
            if (project == null) {
                project_revealer.reveal_child = false;
                end_revealer.reveal_child = false;
            } else {
                project_update_request ();
                project.updated.connect (project_update_request);
                project.project_count_updated.connect (() => {
                    project_progress.percentage = project.percentage;
                });
                
                menu_button.clicked.connect (project.build_content_menu);
                view_button.clicked.connect (project.build_view_menu);
            }
        });

        sidebar_button.clicked.connect (() => {
            Planner.instance.main_window.show_hide_sidebar ();
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "slim-mode") {
                if (Planner.settings.get_boolean ("slim-mode")) {
                    sidebar_image.update_icon_name ("sidebar-left");
                } else {
                    sidebar_image.update_icon_name ("sidebar-right");
                }   
            }
        });

        Planner.event_bus.view_header.connect ((reveal_child) => {
            project_revealer.reveal_child = reveal_child;
            end_revealer.reveal_child = reveal_child;
        });
    }

    private void project_update_request () {
        project_revealer.reveal_child = false;
        end_revealer.reveal_child = false;
        
        project_progress.progress_fill_color = Util.get_default ().get_color (project.color);
        project_progress.percentage = project.percentage;
        
        name_label.label = project.name;
        emoji_label.label = project.emoji;
        if (project.icon_style == ProjectIconStyle.PROGRESS) {
            progress_emoji_stack.visible_child_name = "progress";
        } else {
            progress_emoji_stack.visible_child_name = "label";
        }
    }
}
