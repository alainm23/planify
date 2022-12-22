public class Widgets.HeaderProject : Gtk.Grid {
    public Objects.Project project { get; construct; }

    private Gtk.Button menu_button;
    private Gtk.Popover context_menu = null;
    private Widgets.ContextMenu.MenuItem show_completed_item;

    public HeaderProject (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        var circular_progress_bar = new Widgets.CircularProgressBar (12);
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
        menu_image.size = 19;
        menu_image.update_icon_name ("dots-horizontal");
        
        menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            halign = Gtk.Align.END
        };

        menu_button.child = menu_image;
        menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.START,
            hexpand = true
        };

        content_box.append (icon_progress_stack);
        content_box.append (name_editable);
        content_box.append (menu_button);

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
            show_completed_item.title = project.show_completed ? _("Hide completed tasks") : _("Show completed tasks");
            context_menu.popup ();
            return;
        }

        var edit_item = new Widgets.ContextMenu.MenuItem (_("Edit project"), "planner-edit");
        var add_section_item = new Widgets.ContextMenu.MenuItem (_("Add section"), "planner-plus-circle");
        show_completed_item = new Widgets.ContextMenu.MenuItem (
            project.show_completed ? _("Hide completed tasks") : _("Show completed tasks"),
            "planner-check-circle"
        );

        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete project"), "planner-trash");
        delete_item.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;

        if (!project.inbox_project) {
            menu_box.append (edit_item);
        }
        
        menu_box.append (add_section_item);
        menu_box.append (new Dialogs.ContextMenu.MenuSeparator ());
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

            if (project.todoist) {
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
    }

    public Objects.Section prepare_new_section () {
        Objects.Section new_section = new Objects.Section ();
        new_section.project_id = project.id;
        new_section.name = _("New section");
        new_section.activate_name_editable = true;

        return new_section;
    }
}