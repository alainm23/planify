public class Views.Tasklist : Gtk.EventBox {
    public E.Source source { get; construct; }
    private ECal.ClientView? view = null;
    private E.SourceTaskList task_list;

    private Widgets.ProjectProgress project_progress;
    private Widgets.EditableLabel name_editable;

    private bool is_gtasks;

    public Tasklist (E.Source source) {
        Object (source: source);
    }

    construct {
        var color_popover = new Widgets.ColorPopover ();
        // color_popover.selected = project.color;

        project_progress = new Widgets.ProjectProgress (18) {
            enable_subprojects = true,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER
            // progress_fill_color = Util.get_default ().get_color (project.color),
            // percentage = project.percentage
        };

        var progress_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            popover = color_popover
        };
        progress_button.get_style_context ().add_class ("no-padding");
        progress_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        progress_button.add (project_progress);
        
        name_editable = new Widgets.EditableLabel ("header-title") {
            valign = Gtk.Align.CENTER
        };

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 19;
        menu_image.update_icon_name ("dots-horizontal");
        
        var menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        menu_button.add (menu_image);
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        // menu_button.clicked.connect (project.build_content_menu);
        
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

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            valign = Gtk.Align.START,
            hexpand = true
        };

        header_box.pack_start (progress_button, false, false, 0);
        header_box.pack_start (name_editable, false, false, 6);
        header_box.pack_end (menu_button, false, false, 0);
        header_box.pack_end (search_button, false, false, 0);

        var magic_button = new Widgets.MagicButton ();

        var content = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true,
            margin_start = 16,
            margin_end = 36,
            margin_bottom = 36,
            margin_top = 6
        };
        content.add (header_box);

        var content_clamp = new Hdy.Clamp () {
            maximum_size = 720
        };

        content_clamp.add (content);

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        scrolled_window.add (content_clamp);

        var overlay = new Gtk.Overlay () {
            expand = true
        };
        overlay.add_overlay (magic_button);
        overlay.add (scrolled_window);

        add (overlay);
        update_request ();
        show_all ();

        magic_button.clicked.connect (() => {
            prepare_new_item ();
        });
    }

    public void prepare_new_item (string content = "") {
        
    }

    public void update_request () {
        name_editable.text = source.dup_display_name ();
        project_progress.progress_fill_color = get_task_list_color (source);
        //  Tasks.Application.set_task_color (source, editable_title);

        //  task_list.@foreach ((row) => {
        //      if (row is Tasks.Widgets.TaskRow) {
        //          var task_row = (row as Tasks.Widgets.TaskRow);
        //          task_row.update_request ();
        //      }
        //  });
    }

    private string get_task_list_color (E.Source source) {
        if (source.has_extension (E.SOURCE_EXTENSION_TASK_LIST)) {
            var task_list = (E.SourceTaskList) source.get_extension (E.SOURCE_EXTENSION_TASK_LIST);
            return task_list.dup_color ();
        }
        
        return "";
    }
}
