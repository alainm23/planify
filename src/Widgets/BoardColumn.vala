public class Widgets.BoardColumn : Gtk.EventBox {
    public Objects.Section section { get; construct; }
    public Objects.Project project { get; construct; }

    private Gtk.Label name_label;
    private Widgets.Entry name_entry;
    private Gtk.Stack name_stack;
    private Gtk.ListBox listbox;
    private Gtk.ListBox completed_listbox;
    private Gtk.Revealer completed_revealer;
    private Gtk.Menu menu = null;
    private Gtk.Menu projects_menu;
    private bool menu_visible = false;
    private Gtk.Revealer action_revealer;
    private Gtk.Revealer separator_revealer;
    private bool entry_menu_opened = false;
    private Gtk.Revealer motion_revealer;
    private Gtk.EventBox top_eventbox;
    public Gtk.Revealer main_revealer;
    private Gtk.Box main_box;
    private Gtk.Revealer left_motion_revealer;
    private Gtk.Revealer right_motion_revealer;

    public Gee.ArrayList<Widgets.ItemRow?> items_list;
    public Gee.HashMap <string, Widgets.ItemRow> items_uncompleted_added;
    public Gee.HashMap<string, Widgets.ItemRow> items_completed_added;

    private uint timeout = 0;

    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_ENTRIES_MAGIC_BUTTON = {
        {"MAGICBUTTON", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] TARGET_ENTRIES_SECTION = {
        {"SECTIONROW", Gtk.TargetFlags.SAME_APP, 0}
    };


    public BoardColumn (Objects.Section section, Objects.Project project) {
        Object (
            section: section,
            project: project
        );
    }

    public BoardColumn.for_project (Objects.Project project) {
        var section = new Objects.Section ();
        section.id = 0;
        section.project_id = project.id;
        section.name = _("(No Section)");
        section.is_todoist = project.is_todoist;

        Object (
            section: section,
            project: project
        );
    }

    construct {
        halign = Gtk.Align.START;
        items_list = new Gee.ArrayList<Widgets.ItemRow?> ();
        items_completed_added = new Gee.HashMap<string, Widgets.ItemRow> ();
        items_uncompleted_added = new Gee.HashMap <string, Widgets.ItemRow> ();

        var add_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        add_button.can_focus = false;
        add_button.tooltip_text = _("Add Task");
        add_button.get_style_context ().remove_class ("button");
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        add_button.get_style_context ().add_class ("hidden-button");
        add_button.get_style_context ().add_class ("no-padding");
        add_button.get_style_context ().add_class ("add-button-menu");

        var add_revealer = new Gtk.Revealer ();
        add_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        add_revealer.add (add_button);
        add_revealer.reveal_child = false; 

        name_label = new Gtk.Label (null);
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("font-bold");
        name_label.set_ellipsize (Pango.EllipsizeMode.END);
        if (section.id == 0) {
            name_label.label = _("(No Section)");
        } else {
            name_label.label = section.name;
        }

        var name_eventbox = new Gtk.EventBox ();
        name_eventbox.add (name_label);

        name_entry = new Widgets.Entry ();
        name_entry.text = section.name;
        name_entry.hexpand = true;
        name_entry.placeholder_text = _("Section name");
        name_entry.get_style_context ().add_class ("font-bold");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("project-name-entry");
        name_entry.get_style_context ().add_class ("no-padding");

        name_stack = new Gtk.Stack ();
        name_stack.hexpand = true;
        name_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        name_stack.add_named (name_eventbox, "name_label");
        name_stack.add_named (name_entry, "name_entry");

        var settings_image = new Gtk.Image ();
        settings_image.gicon = new ThemedIcon ("view-more-symbolic");
        settings_image.pixel_size = 14;

        var settings_button = new Gtk.Button ();
        settings_button.can_focus = false;
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.tooltip_text = _("Section Menu");
        settings_button.image = settings_image;
        settings_button.get_style_context ().remove_class ("button");
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        settings_button.get_style_context ().add_class ("hidden-button");

        var count_label = new Gtk.Label (null);

        var menu_stack = new Gtk.Stack ();
        menu_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        menu_stack.add_named (settings_button, "button");
        menu_stack.add_named (count_label, "count");

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        // top_box.pack_start (add_revealer, false, false, 0);
        top_box.pack_start (name_stack, false, true, 0);
        top_box.pack_end (menu_stack, false, true, 0);

        var submit_button = new Gtk.Button.with_label (_("Save"));
        submit_button.sensitive = false;
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.get_style_context ().add_class ("planner-button");

        var action_grid = new Gtk.Grid ();
        action_grid.halign = Gtk.Align.START;
        action_grid.column_homogeneous = true;
        action_grid.column_spacing = 6;
        action_grid.margin_start = 12;
        action_grid.margin_top = 6;
        action_grid.add (cancel_button);
        action_grid.add (submit_button);

        action_revealer = new Gtk.Revealer ();
        action_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        action_revealer.add (action_grid);

        top_eventbox = new Gtk.EventBox ();
        top_eventbox.margin_start = 12;
        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        top_eventbox.get_style_context ().add_class ("toogle-box");
        top_eventbox.add (top_box);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 12;
        // separator.margin_top = 6;

        separator_revealer = new Gtk.Revealer ();
        separator_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        separator_revealer.add (separator);
        separator_revealer.reveal_child = true;

        listbox = new Gtk.ListBox ();
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.set_placeholder (get_placeholder ());
        
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);

        completed_listbox = new Gtk.ListBox ();
        completed_listbox.margin_end = 32;
        completed_listbox.valign = Gtk.Align.START;
        completed_listbox.get_style_context ().add_class ("listbox");
        completed_listbox.activate_on_single_click = true;
        completed_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        completed_listbox.hexpand = true;

        completed_revealer = new Gtk.Revealer ();
        completed_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        completed_revealer.add (completed_listbox);
        if (Planner.database.get_project_by_id (section.project_id).show_completed == 1) {
            completed_revealer.reveal_child = true;
        }

        var listbox_box = new Gtk.Grid ();
        listbox_box.orientation = Gtk.Orientation.VERTICAL;
        listbox_box.add (listbox);
        listbox_box.add (completed_revealer);

        var motion_grid = new Gtk.Grid ();
        motion_grid.margin_start = 12;
        motion_grid.margin_end = 32;
        motion_grid.margin_top = 6;
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.expand = true;
        main_scrolled.add (listbox_box);

        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.vexpand = true;
        main_box.width_request = 315;
        main_box.pack_start (top_eventbox, false, false, 0);
        main_box.pack_start (separator_revealer, false, false, 0);
        main_box.pack_start (action_revealer, false, false, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        main_box.pack_start (main_scrolled, true, true, 0);

        var left_motion_grid = new Gtk.Grid ();
        left_motion_grid.get_style_context ().add_class ("grid-motion");
        // left_motion_grid.width_request = 315;
        //  left_motion_grid.margin_start = 12;
        //  left_motion_grid.margin_start = 12;

        left_motion_revealer = new Gtk.Revealer ();
        left_motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        left_motion_revealer.add (left_motion_grid);

        var right_motion_grid = new Gtk.Grid ();
        right_motion_grid.get_style_context ().add_class ("grid-motion");
        //  right_motion_grid.width_request = 315;

        right_motion_revealer = new Gtk.Revealer ();
        right_motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        right_motion_revealer.add (right_motion_grid);

        var grid = new Gtk.Grid ();
        grid.add (left_motion_revealer);
        grid.add (main_box);
        grid.add (right_motion_revealer);
        grid.margin_end = 24;
        //  if (section.id != 0) {
        //      grid.margin_start = 24;
        //  }

        main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        main_revealer.add (grid);
        main_revealer.reveal_child = true;

        add (main_revealer);

        add_all_items ();
        add_completed_items ();
        // build_defaul_drag_and_drop ();

        Timeout.add (125, () => {
            set_sort_func (Planner.database.get_project_by_id (section.project_id).sort_order);
            return GLib.Source.REMOVE;
        });

        Planner.event_bus.magic_button_activated.connect ((project_id, section_id, is_todoist, index) => {
            if (section.project_id == project_id && section.id == section_id &&
                Planner.database.get_project_by_id (section.project_id).is_kanban == 1) {
                add_new_item (index);
            }
        });

        completed_listbox.row_activated.connect ((r) => {
            var row = ((Widgets.ItemRow) r);

            row.reveal_child = true;
            Planner.event_bus.unselect_all ();
        });

        listbox.row_activated.connect ((r) => {
            var row = ((Widgets.ItemRow) r);

            if (Planner.event_bus.ctrl_pressed) {
                Planner.event_bus.select_item (row);
            } else {
                row.reveal_child = true;
                Planner.event_bus.unselect_all ();
            }
        });

        Planner.database.item_added.connect ((item, index) => {
            if (section.id == 0) {
                if (project.id == item.project_id && item.section_id == section.id && item.parent_id == 0) {
                    var row = new Widgets.ItemRow (item);
                    row.destroy.connect (() => {
                        item_row_removed (row);
                    });
    
                    items_uncompleted_added.set (item.id.to_string (), row);
    
                    if (index == -1) {
                        listbox.add (row);
                        items_list.add (row);
                    } else {
                        listbox.insert (row, index);
                        items_list.insert (index, row);
                    }
                    
                    listbox.show_all ();
                    update_item_order ();
                }
            } else {
                if (section.id == item.section_id && item.parent_id == 0) {
                    var row = new Widgets.ItemRow (item);
                    row.destroy.connect (() => {
                        item_row_removed (row);
                    });
    
                    items_uncompleted_added.set (item.id.to_string (), row);
    
                    if (index == -1) {
                        listbox.add (row);
                        items_list.add (row);
                    } else {
                        listbox.insert (row, index);
                        items_list.insert (index, row);
                    }
                    
                    listbox.show_all ();
                    update_item_order ();
                }
            }
        });

        Planner.database.item_uncompleted.connect ((item) => {
            Idle.add (() => {
                if (section.id == 0) {
                    if (project.id == item.project_id) {
                        if (item.section_id == section.id && item.parent_id == 0) {
                            if (items_completed_added.has_key (item.id.to_string ())) {
                                items_completed_added.unset (item.id.to_string ());
                            }
    
                            if (items_uncompleted_added.has_key (item.id.to_string ()) == false) {
                                var row = new Widgets.ItemRow (item);
                                row.destroy.connect (() => {
                                    item_row_removed (row);
                                });
    
                                listbox.add (row);
                                items_uncompleted_added.set (item.id.to_string (), row);
                                items_list.add (row);
    
                                listbox.show_all ();
                            }
                        }
                    }
                } else {
                    if (section.id == item.section_id && item.parent_id == 0) {
                        if (items_completed_added.has_key (item.id.to_string ())) {
                            items_completed_added.get (item.id.to_string ()).hide_destroy ();
                            items_completed_added.unset (item.id.to_string ());
                        }
    
                        if (items_uncompleted_added.has_key (item.id.to_string ()) == false) {
                            var row = new Widgets.ItemRow (item);
                            row.destroy.connect (() => {
                                item_row_removed (row);
                            });
    
                            listbox.add (row);
                            items_uncompleted_added.set (item.id.to_string (), row);
                            items_list.add (row);
    
                            listbox.show_all ();
                        }
                    }
                }

                return false;
            });
        });

        Planner.database.item_completed.connect ((item) => {
            Idle.add (() => {
                if (section.id == 0) {
                    if (project.id == item.project_id && item.section_id == section.id) {
                        if (item.checked == 1 && item.section_id == 0 && item.parent_id == 0) {
                            if (items_uncompleted_added.has_key (item.id.to_string ())) {
                                items_uncompleted_added.get (item.id.to_string ()).destroy ();
                                items_uncompleted_added.unset (item.id.to_string ());
                            }
    
                            if (items_completed_added.has_key (item.id.to_string ()) == false) {
                                var row = new Widgets.ItemRow (item);
    
                                items_completed_added.set (item.id.to_string (), row);
                                completed_listbox.insert (row, 0);
                                completed_listbox.show_all ();
                            }
                        }
                    }
                } else {
                    if (section.id == item.section_id && item.parent_id == 0) {
                        if (items_uncompleted_added.has_key (item.id.to_string ())) {
                            items_uncompleted_added.get (item.id.to_string ()).destroy ();
                            items_uncompleted_added.unset (item.id.to_string ());
                        }
    
                        if (items_completed_added.has_key (item.id.to_string ()) == false) {
                            var row = new Widgets.ItemRow (item);
    
                            items_completed_added.set (item.id.to_string (), row);
                            completed_listbox.insert (row, 0);
                            completed_listbox.show_all ();
                        }
                    }
                }

                return false;
            });
        });

        Planner.event_bus.drag_magic_button_activated.connect ((value) => {
            build_magic_button_drag_and_drop (value);
        });

        Planner.utils.drag_item_activated.connect ((value) => {
            build_item_drag_and_drop (value);
        });

        top_eventbox.enter_notify_event.connect ((event) => {
            // menu_stack.visible_child_name = "button";
            add_revealer.reveal_child = true;
            add_button.get_style_context ().add_class ("animation");

            return true;
        });

        top_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            // menu_stack.visible_child_name = "count";
            add_revealer.reveal_child = false;
            add_button.get_style_context ().remove_class ("animation");

            return true;
        });

        top_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.@2BUTTON_PRESS && evt.button == 1 && section.id != 0) {
                action_revealer.reveal_child = true;
                name_stack.visible_child_name = "name_entry";

                separator_revealer.reveal_child = false;

                name_entry.grab_focus_without_selecting ();
                if (name_entry.cursor_position < name_entry.text_length) {
                    name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) name_entry.text_length, false);
                }

                return true;
            } else if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                activate_menu ();
                return true;
            }

            return false;
        });

        add_button.clicked.connect (() => {
            add_new_item (Planner.settings.get_enum ("new-tasks-position"));
        });

        name_entry.changed.connect (() => {
            if (name_entry.text.strip () != "" && section.name != name_entry.text) {
                submit_button.sensitive = true;
            } else {
                submit_button.sensitive = false;
            }
        });

        name_entry.focus_out_event.connect (() => {
            if (entry_menu_opened == false) {
                save (true);
                separator_revealer.reveal_child = true;
            }
        });

        name_entry.populate_popup.connect ((menu) => {
            entry_menu_opened = true;
            menu.hide.connect (() => {
                entry_menu_opened = false;
            });
        });

        name_entry.activate.connect (() =>{
            save ();
            separator_revealer.reveal_child = true;
        });

        name_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                action_revealer.reveal_child = false;
                name_stack.visible_child_name = "name_label";
                name_entry.text = section.name;

                separator_revealer.reveal_child = true;
            }

            return false;
        });

        submit_button.clicked.connect (() => {
            save ();
            separator_revealer.reveal_child = true;
        });

        cancel_button.clicked.connect (() => {
            action_revealer.reveal_child = false;
            name_stack.visible_child_name = "name_label";
            name_entry.text = section.name;

            separator_revealer.reveal_child = true;
        });

        settings_button.clicked.connect (() => {
            activate_menu ();
        });

        
        Planner.database.section_deleted.connect ((s) => {
            if (section.id == s.id) {
                main_revealer.reveal_child = false;

                Timeout.add (500, () => {
                    destroy ();
                    return GLib.Source.REMOVE;
                });
            }
        });

        Planner.todoist.section_deleted_started.connect ((id) => {
            if (section.id == id) {
                sensitive = false;
            }
        });

        Planner.todoist.section_deleted_error.connect ((id, http_code, error_message) => {
            if (section.id == id) {
                sensitive = true;
            }
        });

        Planner.todoist.section_moved_started.connect ((id) => {
            if (section.id == id) {
                sensitive = false;
            }
        });

        Planner.todoist.section_moved_completed.connect ((id) => {
            if (section.id == id) {
                sensitive = true;
            }
        });

        Planner.todoist.section_moved_error.connect ((id, http_code, error_message) => {
            if (section.id == id) {
                sensitive = true;
            }
        });

        Planner.database.section_updated.connect ((s) => {
            Idle.add (() => {
                if (section.id == s.id) {
                    section.name = s.name;

                    name_entry.text = s.name;
                    name_label.label = s.name;
                }

                return false;
            });
        });

        Planner.database.item_moved.connect ((item, project_id, old_project_id, index) => {
            Idle.add (() => {
                if (section.project_id == old_project_id) {
                    items_list.foreach ((widget) => {
                        var row = (Widgets.ItemRow) widget;

                        if (row.item.id == item.id) {
                            row.destroy ();
                            items_list.remove (row);
                        }
                    });
                }

                if (project.id == project_id && item.section_id == section.id) {
                    item.project_id = project_id;

                    var row = new Widgets.ItemRow (item);
                    row.destroy.connect (() => {
                        item_row_removed (row);
                    });

                    items_uncompleted_added.set (item.id.to_string (), row);
                    if (index == -1) {
                        listbox.add (row);
                        items_list.add (row);
                    } else {
                        listbox.insert (row, index);
                        items_list.insert (index, row);
                    }
                    
                    listbox.show_all ();
                }

                return false;
            });
        });

        Planner.database.item_section_moved.connect ((i, section_id, old_section_id) => {
            Idle.add (() => {
                if (section.id == old_section_id) {
                    items_list.foreach ((widget) => {
                        var row = (Widgets.ItemRow) widget;

                        if (row.item.id == i.id) {
                            row.destroy ();
                            items_list.remove (row);
                        }
                    });
                }

                if (section.id == section_id) {
                    i.section_id = section_id;

                    var row = new Widgets.ItemRow (i);
                    row.destroy.connect (() => {
                        item_row_removed (row);
                    });

                    items_uncompleted_added.set (i.id.to_string (), row);
                    listbox.add (row);
                    items_list.add (row);

                    listbox.show_all ();
                }

                return false;
            });
        });

        Planner.database.section_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (section.id == current_id) {
                    section.id = new_id;
                }

                return false;
            });
        });

        Planner.database.project_id_updated.connect ((current_id, new_id) => {
            Idle.add (() => {
                if (section.project_id == current_id) {
                    section.project_id = new_id;
                }

                return false;
            });
        });

        Planner.database.project_show_completed.connect ((project) => {
            if (project.id == section.project_id) {
                if (project.show_completed == 1) {
                    completed_revealer.reveal_child = true;
                } else {
                    completed_revealer.reveal_child = false;
                }
            }
        });

        Planner.database.on_drag_item_deleted.connect ((row, section_id) => {
            if (row.item.project_id == section.project_id && section_id == section.id) {
                item_row_removed (row);
            }
        });

        Planner.event_bus.sort_items_project.connect ((project_id, order) => {
            if (section.project_id == project_id) {
                set_sort_func (order);
            }
        });

        Planner.event_bus.hide_items_project.connect ((id) => {
            if (section.project_id == id) {
                hide_items ();
            }
        });

        Planner.event_bus.filter_label_activated.connect ((project_id, values) => {
            if (section.project_id == project_id) {
                if (values.size > 0) {
                    foreach (unowned Gtk.Widget child in listbox.get_children ()) {
                        if (child is Widgets.ItemRow) {
                            var item = ((Widgets.ItemRow) child);
                            var returned = false;
                            foreach (var label in values) {
                                if (item.labels_hashmap.has_key (label.id.to_string ())) {
                                    returned = true;
                                }
                            }

                            item.main_revealer.reveal_child = returned;
                        }
                    }
                } else {
                    foreach (unowned Gtk.Widget child in listbox.get_children ()) {
                        ((Widgets.ItemRow) child).main_revealer.reveal_child = true;
                    }
                }
            }
        });
    }

    private void build_magic_button_drag_and_drop (bool value) {
        name_stack.drag_data_received.disconnect (on_drag_item_received);
        name_stack.drag_data_received.disconnect (on_drag_magic_button_received);

        if (value) {
            Gtk.drag_dest_set (name_stack, Gtk.DestDefaults.ALL, TARGET_ENTRIES_MAGIC_BUTTON, Gdk.DragAction.MOVE);
            name_stack.drag_data_received.connect (on_drag_magic_button_received);
            name_stack.drag_motion.connect (on_drag_magicbutton_motion);
            name_stack.drag_leave.connect (on_drag_magicbutton_leave);
        } else {
            // build_defaul_drag_and_drop ();
        }
    }

    private void build_item_drag_and_drop (bool value) {
        name_stack.drag_data_received.disconnect (on_drag_item_received);
        name_stack.drag_data_received.disconnect (on_drag_magic_button_received);

        if (value) {
            Gtk.drag_dest_set (name_stack, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
            name_stack.drag_data_received.connect (on_drag_item_received);
            name_stack.drag_motion.connect (on_drag_magicbutton_motion);
            name_stack.drag_leave.connect (on_drag_magicbutton_leave);
        } else {
            // build_defaul_drag_and_drop ();
        }
    }

    public bool on_drag_magicbutton_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_revealer.reveal_child = true;
        return true;
    }

    public void on_drag_magicbutton_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;
    }
    
    public void hide_items () {
        for (int index = 0; index < items_list.size; index++) {
            items_list [index].hide_item ();
        }
    }

    public void save (bool todoist=true) {
        name_label.label = name_entry.text;
        section.name = name_entry.text;
        // section.note = note_textview.buffer.text;

        action_revealer.reveal_child = false;
        name_stack.visible_child_name = "name_label";

        section.save (todoist);
    }

    private Gtk.Widget get_placeholder () {
        var button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        button.valign = Gtk.Align.START;
        button.always_show_image = true;
        button.can_focus = false;
        button.label = _("Add Task");
        button.get_style_context ().add_class ("flat");
        button.get_style_context ().add_class ("font-bold");
        button.get_style_context ().add_class ("add-button");
        button.get_style_context ().add_class ("background-transparent");
        button.show ();

        var grid = new Gtk.Grid ();
        grid.margin_top = 12;
        grid.margin_bottom = 6;
        grid.margin_start = 4;
        grid.halign = Gtk.Align.START;
        grid.add (button);
        grid.show ();

        button.clicked.connect (() => {
            add_new_item (Planner.settings.get_enum ("new-tasks-position"));
        });

        return grid;
    }

    public void add_all_items () {
        Gee.ArrayList<Objects.Item?> items;
        if (section.id == 0) {
            items = Planner.database.get_all_items_by_project_no_section_no_parent (project.id);
        } else {
            items = Planner.database.get_all_items_by_section_no_parent (section);
        }

        foreach (Objects.Item item in items) {
            var row = new Widgets.ItemRow (item);
            row.destroy.connect (() => {
                item_row_removed (row);
            });

            items_uncompleted_added.set (item.id.to_string (), row);
            listbox.add (row);
            items_list.add (row);
        }

        listbox.show_all ();
    }

    private void add_completed_items () {
        Gee.ArrayList<Objects.Item?> items;
        if (section.id == 0) {
            items = Planner.database.get_all_completed_items_by_project_no_section_no_parent (project.id);
        } else {
            items = Planner.database.get_all_completed_items_by_section_no_parent (section);
        }
        
        foreach (var item in items) {
            var row = new Widgets.ItemRow (item);

            completed_listbox.add (row);
            items_completed_added.set (item.id.to_string (), row);
            completed_listbox.show_all ();
        }
    }

    private void item_row_removed (Widgets.ItemRow row) {
        items_list.remove (row);
        items_uncompleted_added.unset (row.item.id.to_string ());
        items_completed_added.unset (row.item.id.to_string ());
    }

    public void add_new_item (int index=-1) {
        Planner.event_bus.unselect_all ();

        var new_item = new Widgets.NewItem (
            section.project_id,
            section.id,
            section.is_todoist,
            "",
            index,
            listbox
        );
        
        if (index == -1) {
            listbox.add (new_item);
        } else {
            listbox.insert (new_item, index);
        }

        listbox.show_all ();
    }

    private void set_sort_func (int order) {
        listbox.set_sort_func ((row1, row2) => {
            if (row1 is Widgets.ItemRow && row2 is Widgets.ItemRow) {
                var item1 = ((Widgets.ItemRow) row1).item;
                var item2 = ((Widgets.ItemRow) row2).item;

                if (order == 0) {
                    return 0;
                } else if (order == 1) {
                    if (item1.due_date != "" && item2.due_date != "") {
                        var date1 = new GLib.DateTime.from_iso8601 (item1.due_date, new GLib.TimeZone.local ());
                        var date2 = new GLib.DateTime.from_iso8601 (item2.due_date, new GLib.TimeZone.local ());

                        return date1.compare (date2);
                    }

                    if (item1.due_date == "" && item2.due_date != "") {
                        return 1;
                    }

                    return 0;
                } else if (order == 2) {
                    if (item1.priority < item2.priority) {
                        return 1;
                    }
        
                    if (item1.priority < item2.priority) {
                        return -1;
                    }
        
                    return 0;
                } else {
                    return item1.content.collate (item2.content);
                }
            }

            return 0;
        });

        listbox.set_sort_func (null);
    }

    private void update_item_order () {
        if (timeout != 0) {
            Source.remove (timeout);
        }

        timeout = Timeout.add (1000, () => {
            new Thread<void*> ("update_item_order", () => {
                for (int index = 0; index < items_list.size; index++) {
                    Planner.database.update_item_order (items_list [index].item, section.id, index);
                }

                return null;
            });

            return GLib.Source.REMOVE;
        });
    }

    private void activate_menu () {
        Planner.event_bus.unselect_all ();
        
        if (menu == null) {
            build_context_menu (section);
        }

        foreach (var child in projects_menu.get_children ()) {
            child.destroy ();
        }

        Widgets.ImageMenuItem item_menu;
        int is_todoist = Planner.database.get_project_by_id (Planner.settings.get_int64 ("inbox-project")).is_todoist;
        if (section.is_todoist == is_todoist) {
            item_menu = new Widgets.ImageMenuItem (_("Inbox"), "planner-inbox");
            item_menu.activate.connect (() => {
                Planner.database.move_section (section, Planner.settings.get_int64 ("inbox-project"));
                if (section.is_todoist == 1) {
                    Planner.todoist.move_section (section, Planner.settings.get_int64 ("inbox-project"));
                }

                string move_template = _("Section moved to <b>%s</b>");
                Planner.notifications.send_notification (
                    move_template.printf (
                        section.name
                    )
                );
            });

            projects_menu.add (item_menu);
        }

        foreach (var project in Planner.database.get_all_projects ()) {
            if (project.inbox_project == 0 && section.project_id != project.id) {
                if (project.is_todoist == section.is_todoist) {
                    item_menu = new Widgets.ImageMenuItem (project.name, "color-%i".printf (project.color));
                    item_menu.activate.connect (() => {
                        Planner.database.move_section (section, project.id);
                        if (section.is_todoist == 1) {
                            Planner.todoist.move_section (section, project.id);
                        }

                        string move_template = _("Section moved to <b>%s</b>");
                        Planner.notifications.send_notification (
                            move_template.printf (
                                section.name
                            )
                        );
                    });

                    projects_menu.add (item_menu);
                }
            }
        }

        projects_menu.show_all ();
        menu_visible = true;
        menu.popup_at_pointer (null);
    }

    private void build_context_menu (Objects.Section section) {
        menu = new Gtk.Menu ();
        menu.width_request = 200;

        menu.hide.connect (() => {
            menu_visible = false;
        });
        
        var add_menu = new Widgets.ImageMenuItem (_("Add Task"), "list-add-symbolic");
        add_menu.get_style_context ().add_class ("add-button-menu");

        var edit_menu = new Widgets.ImageMenuItem (_("Rename"), "edit-symbolic");
        var note_menu = new Widgets.ImageMenuItem (_("Add Note"), "text-x-generic-symbolic");

        var move_project_menu = new Widgets.ImageMenuItem (_("Move to Project"), "move-project-symbolic");
        projects_menu = new Gtk.Menu ();
        move_project_menu.set_submenu (projects_menu);

        var share_menu = new Widgets.ImageMenuItem (_("Share"), "emblem-shared-symbolic");
        var share_list_menu = new Gtk.Menu ();
        share_menu.set_submenu (share_list_menu);

        //var share_text_menu = new Widgets.ImageMenuItem (_("Text"), "text-x-generic-symbolic");
        var share_markdown_menu = new Widgets.ImageMenuItem (_("Markdown"), "planner-markdown-symbolic");

        //share_list_menu.add (share_text_menu);
        share_list_menu.add (share_markdown_menu);
        share_list_menu.show_all ();

        var delete_menu = new Widgets.ImageMenuItem (_("Delete"), "user-trash-symbolic");
        delete_menu.get_style_context ().add_class ("menu-danger");

        menu.add (add_menu);
        menu.add (new Gtk.SeparatorMenuItem ());
        if (section.id != 0) {
            menu.add (edit_menu);
        }
        menu.add (move_project_menu);
        menu.add (share_menu);
        if (section.id != 0) {
            menu.add (new Gtk.SeparatorMenuItem ());
            menu.add (delete_menu);
        }

        menu.show_all ();

        add_menu.activate.connect (() => {
            add_new_item (Planner.settings.get_enum ("new-tasks-position"));
        });

        note_menu.activate.connect (() => {
            // separator_revealer.reveal_child = false;
            // note_revealer.reveal_child = true;
            // note_textview.grab_focus ();
        });

        edit_menu.activate.connect (() => {
            action_revealer.reveal_child = true;
            name_stack.visible_child_name = "name_entry";

            separator_revealer.reveal_child = false;

            name_entry.grab_focus_without_selecting ();
            if (name_entry.cursor_position < name_entry.text_length) {
                name_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) name_entry.text_length, false);
            }
        });

        delete_menu.activate.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Delete section"),
                _("Are you sure you want to delete <b>%s</b>?".printf (Planner.utils.get_dialog_text (section.name))),
                "user-trash-full",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Delete"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                Planner.database.delete_section (section);
                if (section.is_todoist == 1) {
                    Planner.todoist.delete_section (section);
                }

                Planner.notifications.send_notification (
                    _("Section deleted")
                );
            }

            message_dialog.destroy ();
        });

        share_markdown_menu.activate.connect (() => {
            section.share_markdown ();
        });
    }

    //  private void build_defaul_drag_and_drop () {
    //      name_stack.drag_data_received.disconnect (on_drag_item_received);
    //      name_stack.drag_data_received.disconnect (on_drag_magic_button_received);

    //      if (section.id != 0) {
    //          Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_ENTRIES_SECTION, Gdk.DragAction.MOVE);
    //          drag_begin.connect (on_drag_begin);
    //          drag_data_get.connect (on_drag_data_get);
    //          drag_end.connect (clear_indicator);
    //      }

    //      Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, TARGET_ENTRIES_SECTION, Gdk.DragAction.MOVE);
    //      this.drag_motion.connect (on_drag_motion);
    //      this.drag_leave.connect (on_drag_leave);
    //  }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        Gtk.Allocation alloc;
        main_box.get_allocation (out alloc);
        
        if (section.id != 0) {
            if (x > (alloc.width / 2)) {
                right_motion_revealer.reveal_child = true;
                left_motion_revealer.reveal_child = false;
            } else {
                left_motion_revealer.reveal_child = true;
                right_motion_revealer.reveal_child = false;
            }  
        }

        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        left_motion_revealer.reveal_child = false;
        right_motion_revealer.reveal_child = false;
    }

    //  private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
    //      var row = ((Widgets.BoardColumn) widget).main_box;

    //      Gtk.Allocation alloc;
    //      row.get_allocation (out alloc);

    //      var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
    //      var cr = new Cairo.Context (surface);
    //      cr.set_source_rgba (0, 0, 0, 0.5);
    //      cr.set_line_width (1);

    //      cr.move_to (0, 0);
    //      cr.line_to (alloc.width, 0);
    //      cr.line_to (alloc.width, alloc.height);
    //      cr.line_to (0, alloc.height);
    //      cr.line_to (0, 0);
    //      cr.stroke ();

    //      cr.set_source_rgba (255, 255, 255, 0);
    //      cr.rectangle (0, 0, alloc.width, alloc.height);
    //      cr.fill ();

    //      // row.get_style_context ().add_class ("drag-begin");
    //      row.draw (cr);
    //      // row.get_style_context ().remove_class ("drag-begin");

    //      Gtk.drag_set_icon_surface (context, surface);
    //      main_revealer.reveal_child = false;
    //  }

    //  private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
    //      Gtk.SelectionData selection_data, uint target_type, uint time) {
    //      uchar[] data = new uchar[(sizeof (Widgets.BoardColumn))];
    //      ((Gtk.Widget[])data)[0] = widget;

    //      selection_data.set (
    //          Gdk.Atom.intern_static_string ("SECTIONROW"), 32, data
    //      );
    //  }

    public void clear_indicator (Gdk.DragContext context) {
        main_revealer.reveal_child = true;
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        if (source.item.is_todoist == section.is_todoist) {
            if (source.item.project_id != section.project_id) {
                Planner.database.update_item_project_id (source.item, section.project_id);
            }
            
            if (source.item.section_id != section.id) {
                Planner.database.on_drag_item_deleted (source, source.item.section_id);
                source.item.section_id = section.id;
                if (source.item.is_todoist == 1) {
                    Planner.todoist.move_item_to_section (source.item, section.id);
                } 
    
                string move_template = _("Task moved to <b>%s</b>");
                Planner.notifications.send_notification (
                    move_template.printf (
                        section.name
                    )
                );
            }
    
            source.get_parent ().remove (source);
            items_list.remove (source);
            items_uncompleted_added.set (source.item.id.to_string (), source);
            
            listbox.insert (source, 0);
            items_list.insert (0, source);
    
            listbox.show_all ();
            update_item_order ();
        } else {
            Planner.notifications.send_notification (
                _("Unable to move task")
            );
        }
    }

    private void on_drag_magic_button_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        add_new_item (0);
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ItemRow target;
        Widgets.ItemRow source;
        Gtk.Allocation alloc;

        target = (Widgets.ItemRow) listbox.get_row_at_y (y);
        target.get_allocation (out alloc);

        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        if (target != null) {
            if (source.item.is_todoist == section.is_todoist) {
                if (source.item.project_id != section.project_id) {
                    Planner.database.update_item_project_id (source.item, section.project_id);
                }
    
                if (source.item.section_id != section.id) {
                    Planner.database.on_drag_item_deleted (source, source.item.section_id);
                    source.item.section_id = section.id;
                    if (source.item.is_todoist == 1) {
                        Planner.todoist.move_item_to_section (source.item, section.id);
                    }
    
                    string move_template = _("Task moved to <b>%s</b>");
                    Planner.notifications.send_notification (
                        move_template.printf (
                            section.name
                        )
                    );
                }
    
                source.get_parent ().remove (source);
                items_list.remove (source);
    
                listbox.insert (source, target.get_index () + 1);
                items_list.insert (target.get_index () + 1, source);
    
                listbox.show_all ();
                update_item_order ();
            } else {
                Planner.notifications.send_notification (
                    _("Unable to move task")
                );
            }
        }
    }
}
