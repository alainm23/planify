public class Widgets.HeaderProject : Gtk.Grid {
    public Objects.Project project { get; construct; }

    private Gtk.Button menu_button;
    private Gtk.Popover context_menu = null;
    private Gtk.Button view_button;
    private Gtk.Popover view_menu = null;
    private Widgets.ContextMenu.MenuItem show_completed_item;

    private Gtk.CheckButton custom_sort_item;
    private Gtk.CheckButton alphabetically_sort_item;
    private Gtk.CheckButton due_date_sort_item;
    private Gtk.CheckButton date_added_sort_item;
    private Gtk.CheckButton priority_sort_item;

    public HeaderProject (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var circular_progress_bar = new Widgets.CircularProgressBar (10);
        circular_progress_bar.percentage = project.percentage;
        circular_progress_bar.color = project.color;

        var emoji_label = new Gtk.Label (project.emoji) {
            halign = Gtk.Align.CENTER
        };
        emoji_label.get_style_context ().add_class ("header-title");

        var progress_emoji_stack = new Gtk.Stack ();
        progress_emoji_stack.add_named (circular_progress_bar, "progress");
        progress_emoji_stack.add_named (emoji_label, "label");

        var inbox_icon = new Gtk.Image () {
            gicon = new ThemedIcon ("planner-inbox"),
            pixel_size = 24
        };

        var icon_progress_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        icon_progress_stack.add_named (progress_emoji_stack, "color");
        icon_progress_stack.add_named (inbox_icon, "icon");

        var name_editable = new Widgets.EditableLabel () {
            valign = Gtk.Align.CENTER,
            editable = !project.inbox_project
        };

        name_editable.add_style ("header-title");
        name_editable.text = project.inbox_project ? _("Inbox") : project.name;

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 21;
        menu_image.update_icon_name ("dots-horizontal");
        
        menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            halign = Gtk.Align.END
        };

        menu_button.child = menu_image;
        menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var view_image = new Widgets.DynamicIcon ();
        view_image.size = 21;
        view_image.update_icon_name ("planner-settings-sliders");
        
        view_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER
        };

        view_button.child = view_image;
        view_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var tools_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            halign = Gtk.Align.END
        };

        tools_box.append (view_button);
        tools_box.append (menu_button);

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.START,
            hexpand = true
        };

        content_box.append (icon_progress_stack);
        content_box.append (name_editable);
        content_box.append (tools_box);

        attach (content_box, 0, 0);

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

        menu_button.clicked.connect (build_context_menu);
        view_button.clicked.connect (build_view_menu);

        project.project_count_updated.connect (() => {
            circular_progress_bar.percentage = project.percentage;
        });

        project.updated.connect (() => {
            name_editable.text = project.name;
            
            circular_progress_bar.color = Util.get_default ().get_color (project.color);
            circular_progress_bar.percentage = project.percentage;
            
            emoji_label.label = project.emoji;
            if (project.icon_style == ProjectIconStyle.PROGRESS) {
                progress_emoji_stack.visible_child_name = "progress";
            } else {
                progress_emoji_stack.visible_child_name = "label";
            }
        });
    }

    private void build_context_menu () {
        if (context_menu != null) {
            show_completed_item.title = project.show_completed ? _("Hide Completed Tasks") : _("Show completed tasks");
            context_menu.popup ();
            return;
        }

        var edit_item = new Widgets.ContextMenu.MenuItem (_("Edit Project"), "planner-edit");
        
        var add_section_item = new Widgets.ContextMenu.MenuItem (_("Add Section"), "planner-section");
        show_completed_item = new Widgets.ContextMenu.MenuItem (
            project.show_completed ? _("Hide completed tasks") : _("Show Completed Tasks"),
            "planner-check-circle"
        );

        var filter_by_tags = new Widgets.ContextMenu.MenuItem (_("Filter by Labels"), "planner-tag");

        var select_item = new Widgets.ContextMenu.MenuItem (_("Select"), "unordered-list");

        var paste_item = new Widgets.ContextMenu.MenuItem (_("Paste"), "planner-clipboard");

        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete Project"), "planner-trash");
        delete_item.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;

        if (!project.inbox_project) {
            menu_box.append (edit_item);
        }
        
        menu_box.append (add_section_item);
        menu_box.append (new Dialogs.ContextMenu.MenuSeparator ());
        menu_box.append (filter_by_tags);
        menu_box.append (select_item);
        menu_box.append (paste_item);
        menu_box.append (show_completed_item);
        
        if (!project.inbox_project) {
            menu_box.append (new Dialogs.ContextMenu.MenuSeparator ());
            menu_box.append (delete_item);
        }

        context_menu = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM
        };

        context_menu.set_parent (menu_button);
        context_menu.popup ();

        edit_item.activate_item.connect (() => {
            context_menu.popdown ();

            var dialog = new Dialogs.Project (project);
            dialog.show ();
        });

        show_completed_item.activate_item.connect (() => {
            context_menu.popdown ();

            project.show_completed = !project.show_completed;
            project.update ();
        });

        add_section_item.activate_item.connect (() => {
            Objects.Section new_section = prepare_new_section ();

            if (project.backend_type == BackendType.TODOIST) {
                add_section_item.is_loading = true;
                Services.Todoist.get_default ().add.begin (new_section, (obj, res) => {
                    new_section.id = Services.Todoist.get_default ().add.end (res);
                    project.add_section_if_not_exists (new_section);
                    add_section_item.is_loading = false;                    
                    context_menu.popdown ();
                });
            } else {
                new_section.id = Util.get_default ().generate_id ();
                project.add_section_if_not_exists (new_section);
                context_menu.popdown ();
            }
        });

        paste_item.clicked.connect (() => {
            context_menu.popdown ();
            Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();

            clipboard.read_text_async.begin (null, (obj, res) => {
                try {
                    string content = clipboard.read_text_async.end (res);
                    Planner.event_bus.paste_action (project.id, content);
                } catch (GLib.Error error) {
                    debug (error.message);
                }
            });
        });

        select_item.clicked.connect (() => {
            context_menu.popdown ();
            Planner.event_bus.multi_select_enabled = true;
            Planner.event_bus.show_multi_select (true);
        });
    }

    private void build_view_menu () {
        if (view_menu != null) {
            view_menu.popup ();
            return;
        }

        var sort_by_label = new Gtk.Label (_("Sort by")) {
            halign = Gtk.Align.START,
            margin_start = 6,
            margin_bottom = 3
        };

        sort_by_label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);
        sort_by_label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        custom_sort_item = new Gtk.CheckButton.with_label (_("Custom sort order")) {
            hexpand = true
        };
        custom_sort_item.add_css_class ("checkbutton-label");

        alphabetically_sort_item = new Gtk.CheckButton.with_label (_("Alphabetically"));
        alphabetically_sort_item.set_group (custom_sort_item);
        alphabetically_sort_item.add_css_class ("checkbutton-label");

        due_date_sort_item = new Gtk.CheckButton.with_label (_("Due date"));
        due_date_sort_item.set_group (custom_sort_item);
        due_date_sort_item.add_css_class ("checkbutton-label");

        date_added_sort_item = new Gtk.CheckButton.with_label (_("Date added"));
        date_added_sort_item.set_group (custom_sort_item);
        date_added_sort_item.add_css_class ("checkbutton-label");

        priority_sort_item = new Gtk.CheckButton.with_label (_("Priority"));
        priority_sort_item.set_group (custom_sort_item);
        priority_sort_item.add_css_class ("checkbutton-label");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        
        menu_box.append (sort_by_label);
        menu_box.append (custom_sort_item);
        menu_box.append (alphabetically_sort_item);
        menu_box.append (due_date_sort_item);
        menu_box.append (date_added_sort_item);
        menu_box.append (priority_sort_item);

        view_menu = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM
        };

        view_menu.set_parent (view_button);
        view_menu.popup ();

        if (project.sort_order == 0) {
            custom_sort_item.active = true;
        } else if (project.sort_order == 1) {
            alphabetically_sort_item.active = true;
        } else if (project.sort_order == 2) {
            due_date_sort_item.active = true;
        } else if (project.sort_order == 3) {
            date_added_sort_item.active = true;
        } else if (project.sort_order == 4) {
            priority_sort_item.active = true;
        }

        custom_sort_item.toggled.connect (() => {
            project.sort_order = 0;
            project.update (false);
        });

        alphabetically_sort_item.toggled.connect (() => {
            project.sort_order = 1;
            project.update (false);
        });

        due_date_sort_item.toggled.connect (() => {
            project.sort_order = 2;
            project.update (false);
        });

        date_added_sort_item.toggled.connect (() => {
            project.sort_order = 3;
            project.update (false);
        });

        priority_sort_item.toggled.connect (() => {
            project.sort_order = 4;
            project.update (false);
        });
    }

    public Objects.Section prepare_new_section () {
        Objects.Section new_section = new Objects.Section ();
        new_section.project_id = project.id;
        new_section.name = _("New section");
        new_section.activate_name_editable = true;

        return new_section;
    }
}