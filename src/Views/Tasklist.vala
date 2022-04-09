public class Views.Tasklist : Gtk.EventBox {
    public E.Source source { get; construct; }
    private ECal.ClientView? view = null;

    private Widgets.ProjectProgress project_progress;
    private Widgets.EditableLabel name_editable;
    private Gtk.ListBox listbox;
    private Gtk.ListBox checked_listbox;
    private Gtk.Revealer checked_revealer;
    private Gtk.Stack listbox_stack;

    private bool show_completed = false;
    private bool is_gtasks;
    private Gee.HashMap <string, Layouts.TaskRow> tasks_map = null;
    private Gee.HashMap <string, Layouts.TaskRow> tasks_checked = null;

    private bool has_items {
        get {
            if (show_completed) {
                return listbox.get_children ().length () > 0 || checked_listbox.get_children ().length () > 0;
            } else {
                return listbox.get_children ().length () > 0;
            }
        }
    }

    public Tasklist (E.Source source) {
        Object (source: source);
    }

    construct {
        E.SourceRegistry? registry = null;

        try {
            registry = Services.CalDAV.get_default ().get_registry_sync ();
            is_gtasks = Services.CalDAV.get_default ().get_collection_backend_name (source, registry) == "google";
        } catch (Error e) {
            warning ("unable to get the registry, assuming task list is not from gtasks");
        }

        var color_popover = new Widgets.ColorPopover ();
        color_popover.selected = Util.get_default ().get_color (get_task_list_color (source));

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
            valign = Gtk.Align.CENTER,
            editable = source.dup_uid () != "system-task-list"
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
            hexpand = true,
            margin_start = 23,
            margin_end = 6
        };

        header_box.pack_start (progress_button, false, false, 0);
        header_box.pack_start (name_editable, false, true, 6);
        header_box.pack_end (menu_button, false, false, 0);
        header_box.pack_end (search_button, false, false, 0);

        var magic_button = new Widgets.MagicButton ();

        listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            hexpand = true
        };

        unowned Gtk.StyleContext listbox_context = listbox.get_style_context ();
        listbox_context.add_class ("listbox-background");

        checked_listbox = new Gtk.ListBox () {
            valign = Gtk.Align.START,
            activate_on_single_click = true,
            selection_mode = Gtk.SelectionMode.SINGLE,
            expand = true
        };

        unowned Gtk.StyleContext checked_listbox_context = checked_listbox.get_style_context ();
        checked_listbox_context.add_class ("listbox-background");

        var checked_listbox_grid = new Gtk.Grid () {
            valign = Gtk.Align.START
        };
        checked_listbox_grid.add (checked_listbox);

        checked_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            valign = Gtk.Align.START,
            reveal_child = show_completed
        };

        checked_revealer.add (checked_listbox_grid);

        var listbox_grid = new Gtk.Grid () {
            margin_top = 12,
            orientation = Gtk.Orientation.VERTICAL
        };
        
        listbox_grid.add (listbox);
        listbox_grid.add (checked_revealer);
        
        var listbox_placeholder = new Widgets.Placeholder (
            source.dup_display_name (), _("No tasks with this tasklist at the moment"), "planner-emoji-happy");

        listbox_stack = new Gtk.Stack () {
            expand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        listbox_stack.add_named (listbox_grid, "listbox");
        listbox_stack.add_named (listbox_placeholder, "placeholder");

        var content = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true,
            margin_start = 16,
            margin_end = 36,
            margin_bottom = 36,
            margin_top = 6
        };
        content.add (header_box);
        content.add (listbox_stack);

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
        add_view ();
        show_all ();

        Timeout.add (listbox_stack.transition_duration, () => {
            validate_placeholder ();
            return GLib.Source.REMOVE;
        });

        magic_button.clicked.connect (() => {
            prepare_new_item ();
        });

        name_editable.changed.connect (() => {
            Services.CalDAV.get_default ().update_task_list_display_name.begin (source,
                name_editable.text, (obj, res) => {
                GLib.Idle.add (() => {
                    try {
                        Services.CalDAV.get_default ().update_task_list_display_name.end (res);
                    } catch (Error e) {
                        name_editable.text = source.display_name;

                        var error_dialog = new Granite.MessageDialog (
                            _("Renaming task list failed"),
                            _("The task list registry may be unavailable or unable to be written to."),
                            new ThemedIcon ("dialog-error"),
                            Gtk.ButtonsType.CLOSE
                        );
                        error_dialog.show_error_details (e.message);
                        error_dialog.run ();
                        error_dialog.destroy ();
                    }

                    return GLib.Source.REMOVE;
                });
            });
        });

        color_popover.color_changed.connect ((color) => {
            update_task_list_color (source, Util.get_default ().get_color (color));
        });

        listbox.add.connect ((widget) => {
            validate_placeholder ();
        });

        listbox.remove.connect (() => {
            validate_placeholder ();
        });

        checked_listbox.add.connect (() => {
            validate_placeholder ();
        });

        checked_listbox.remove.connect (() => {
            validate_placeholder ();
        });

        menu_button.clicked.connect (build_content_menu);
    }

    private void update_task_list_color (E.Source source, string color) {
        var old_color = get_task_list_color (source);
        if (old_color == color) {
            return;
        }

        Services.CalDAV.get_default ().update_task_list_color.begin (source, color, (obj, res) => {
            try {
                Services.CalDAV.get_default ().update_task_list_color.end (res);
                update_request ();
            } catch (Error e) {
                dialog_update_task_list_color_error (e);
            }
        });
    }

    private void dialog_update_task_list_color_error (Error e) {
        var error_dialog = new Granite.MessageDialog (
            _("Could not change the task list color"),
            _("The task list registry may be unavailable or write-protected."),
            new ThemedIcon ("dialog-error"),
            Gtk.ButtonsType.CLOSE
        );
        error_dialog.show_error_details (e.message);
        error_dialog.run ();
        error_dialog.destroy ();
    }

    private void validate_placeholder () {
        listbox_stack.visible_child_name = has_items ? "listbox" : "placeholder";
    }

    public void prepare_new_item (string content = "") {
        var row = new Layouts.TaskRow.for_source (source);
        listbox.add (row);
        listbox.show_all ();
    }

    public void update_request () {
        name_editable.text = source.dup_uid () == "system-task-list" ? _("Inbox") : source.dup_display_name ();
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

    private void add_view () {
        set_view_for_query ("(contains? 'any' '')");
    }

    private void set_view_for_query (string query) {
        foreach (unowned var child in listbox.get_children ()) {
            listbox.remove (child);
        }

        if (view != null) {
            Services.CalDAV.get_default ().destroy_task_list_view (view);
        }

        try {
            view = Services.CalDAV.get_default ().create_task_list_view (
                source,
                query,
                on_tasks_added,
                on_tasks_modified,
                on_tasks_removed
            );
        } catch (Error e) {
            critical ("Error creating view with query for source %s[%s]: %s", source.display_name, query, e.message);
        }
    }

    private void on_tasks_added (Gee.Collection<ECal.Component> tasks, E.Source source) {
        if (tasks_map == null) {
            tasks_map = new Gee.HashMap <string, Layouts.TaskRow> ();
        }

        if (tasks_checked == null) {
            tasks_checked = new Gee.HashMap <string, Layouts.TaskRow> ();
        }
        
        Layouts.TaskRow task_row = null;
        var row_index = 0;

        do {
            task_row = (Layouts.TaskRow) listbox.get_row_at_index (row_index);

            if (task_row != null) {
                foreach (ECal.Component task in tasks) {
                    string uid = task.get_icalcomponent ().get_uid ();
                    if (CalDAVUtil.calcomponent_equal_func (task_row.task, task) && !task_row.created) {
                        task_row.task = task;
                        tasks_map[uid] = task_row;
                        task_row.edit = false;
                        break;
                    }
                }
            }

            row_index++;
        } while (task_row != null);
        
        foreach (ECal.Component task in tasks) {
            unowned ICal.Component ical_task = task.get_icalcomponent ();
            string uid = task.get_icalcomponent ().get_uid ();

            if (ical_task.get_status () == ICal.PropertyStatus.COMPLETED) {
                if (!tasks_checked.has_key (uid)) {
                    tasks_checked[uid] = new Layouts.TaskRow.for_component (task, source);
                    checked_listbox.add (tasks_checked[uid]);
                }
            } else {
                if (!tasks_map.has_key (uid)) {
                    tasks_map[uid] = new Layouts.TaskRow.for_component (task, source);
                    listbox.add (tasks_map[uid]);
                }
            }
        }

        listbox.show_all ();
        checked_listbox.show_all ();
        validate_placeholder ();
    }

    private void on_tasks_modified (Gee.Collection<ECal.Component> tasks) {
        foreach (ECal.Component task in tasks) {
            unowned ICal.Component ical_task = task.get_icalcomponent ();
            string uid = task.get_icalcomponent ().get_uid ();

            if (ical_task.get_status () == ICal.PropertyStatus.COMPLETED) {
                if (tasks_map.has_key (uid)) {
                    tasks_map[uid].hide_destroy ();
                    tasks_map.unset (uid);   
                }

                if (!tasks_checked.has_key (uid)) {
                    tasks_checked[uid] = new Layouts.TaskRow.for_component (task, source);
                    checked_listbox.insert (tasks_checked[uid], 0);
                } else {
                    tasks_checked[uid].task = task;
                }
            } else {
                if (tasks_checked.has_key (uid)) {
                    tasks_checked[uid].hide_destroy ();
                    tasks_checked.unset (uid);
                }

                if (!tasks_map.has_key (uid)) {
                    tasks_map[uid] = new Layouts.TaskRow.for_component (task, source);
                    listbox.add (tasks_map[uid]);
                } else {
                    tasks_map [uid].task = task;
                }
            }
        }

        listbox.show_all ();
        checked_listbox.show_all ();
    }

    private void on_tasks_removed (SList<ECal.ComponentId?> cids) {
        foreach (unowned ECal.ComponentId cid in cids) {
            if (tasks_map.has_key (cid.get_uid ())) {
                tasks_map.get (cid.get_uid ()).hide_destroy ();
                tasks_map.unset (cid.get_uid ());   
            }

            if (tasks_checked.has_key (cid.get_uid ())) {
                tasks_checked.get (cid.get_uid ()).hide_destroy ();
                tasks_checked.unset (cid.get_uid ());   
            }
        }
    }

    public void build_content_menu () {
        var menu = new Dialogs.ContextMenu.Menu ();

        var edit_item = new Dialogs.ContextMenu.MenuItem (_("Edit tasklist"), "planner-edit");
        
        var show_completed_item = new Dialogs.ContextMenu.MenuSwitch (
            _("Show completed"), "planner-check-circle", show_completed);

        var delete_item = new Dialogs.ContextMenu.MenuItem (_("Delete project"), "planner-trash");
        delete_item.get_style_context ().add_class ("menu-item-danger");
        delete_item.sensitive = Services.CalDAV.get_default ().is_remove_task_list_supported (source);

        menu.add_item (show_completed_item);
        menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
        menu.add_item (delete_item);

        menu.popup ();

        edit_item.activate_item.connect (() => {
            menu.hide_destroy ();
        });

        show_completed_item.activate_item.connect (() => {
            show_completed = show_completed_item.active;
            checked_revealer.reveal_child = show_completed;
            validate_placeholder ();
        });

        delete_item.activate_item.connect (() => {
            menu.hide_destroy ();

            var message_dialog = new Dialogs.MessageDialog (
                _("Delete “%s”?".printf (source.display_name)),
                _("The list and all its tasks will be permanently deleted. If you've shared this list, other people will no longer have access."),
                "dialog-warning"
            ) {
                transient_for = (Gtk.Window) get_toplevel ()
            };
            message_dialog.add_default_action (_("Cancel"), Gtk.ResponseType.CANCEL);
            message_dialog.show_all ();
    
            var remove_button = new Widgets.LoadingButton (
                LoadingButtonType.LABEL, _("Delete")) {
                hexpand = true
            };
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            remove_button.get_style_context ().add_class ("border-radius-6");
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);
    
            message_dialog.default_action.connect ((response) => {
                if (response == Gtk.ResponseType.ACCEPT) {
                    remove_button.is_loading = true;
                    Services.CalDAV.get_default ().remove_task_list.begin (source, (obj, res) => {
                        try {
                            Services.CalDAV.get_default ().remove_task_list.end (res);
                            remove_button.is_loading = false;
                            message_dialog.hide_destroy ();
                        } catch (Error e) {
                            message_dialog.hide_destroy ();
                            critical (e.message);
                            show_error_dialog (
                                _("Deleting the task list failed"),
                                _("The task list registry may be unavailable or unable to be written to."),
                                e
                            );
                        }
                    });
                } else {
                    message_dialog.hide_destroy ();
                }
            });
        });
    }

    private void show_error_dialog (string primary_text, string secondary_text, Error e) {
        string error_message = e.message;

        GLib.Idle.add (() => {
            var error_dialog = new Granite.MessageDialog (
                primary_text,
                secondary_text,
                new ThemedIcon ("dialog-error"),
                Gtk.ButtonsType.CLOSE
            );

            error_dialog.show_error_details (error_message);
            error_dialog.run ();
            error_dialog.destroy ();

            return GLib.Source.REMOVE;
        });
    }
}
