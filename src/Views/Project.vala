public class Views.Project : Gtk.EventBox {
    public Objects.Project project { get; construct; }

    private Gtk.Entry name_entry;
    private Gtk.TextView note_textview;
    private Gtk.Label note_placeholder;

    private Gtk.ListBox listbox;
    private Gtk.ListBox section_listbox;
    private Gtk.Revealer motion_revealer;

    private Gtk.ListBox completed_listbox;
    private Gtk.Revealer completed_revealer;

    private Gtk.Popover popover = null;
    private Gtk.ToggleButton settings_button;

    private int64 temp_id_mapping { get; set; default = 0; }

    private const Gtk.TargetEntry[] targetEntries = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    private const Gtk.TargetEntry[] targetEntriesSection = {
        {"SECTIONROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public Gee.HashMap<string, bool> items_completed_loaded;

    public Project (Objects.Project project) {
        Object (
            project: project
        );
    }

    construct {
        items_completed_loaded = new Gee.HashMap<string, bool> ();

        var grid_color = new Gtk.Grid ();
        grid_color.set_size_request (16, 16);
        grid_color.valign = Gtk.Align.CENTER;
        grid_color.halign = Gtk.Align.CENTER;
        grid_color.get_style_context ().add_class ("project-%s".printf (project.id.to_string ()));

        name_entry = new Gtk.Entry ();
        name_entry.text = project.name;
        name_entry.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        name_entry.get_style_context ().add_class ("font-bold");
        name_entry.get_style_context ().add_class ("flat");
        name_entry.get_style_context ().add_class ("project-name-entry");
        name_entry.hexpand = true;

        var section_image = new Gtk.Image ();
        section_image.gicon = new ThemedIcon ("planner-header-symbolic");
        section_image.pixel_size = 21;

        var section_button = new Gtk.Button ();
        section_button.valign = Gtk.Align.CENTER;
        section_button.valign = Gtk.Align.CENTER;
        section_button.tooltip_text = _("Add section");
        section_button.can_focus = false;
        section_button.get_style_context ().add_class ("flat");
        section_button.add (section_image);

        var section_loading = new Gtk.Spinner ();
        section_loading.valign = Gtk.Align.CENTER;
        section_loading.halign = Gtk.Align.CENTER;
        section_loading.start ();

        var section_stack = new Gtk.Stack ();
        section_stack.margin_start = 6;
        section_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        
        section_stack.add_named (section_button, "section_button");
        section_stack.add_named (section_loading, "section_loading");
        
        var add_person_button = new Gtk.Button.from_icon_name ("contact-new-symbolic", Gtk.IconSize.MENU);
        add_person_button.valign = Gtk.Align.CENTER;
        add_person_button.valign = Gtk.Align.CENTER;
        add_person_button.tooltip_text = _("Invite person");
        add_person_button.can_focus = false;
        add_person_button.margin_start = 6;
        add_person_button.get_style_context ().add_class ("flat");
        //add_person_button.get_style_context ().add_class ("dim-label");

        var comment_button = new Gtk.Button.from_icon_name ("internet-chat-symbolic", Gtk.IconSize.MENU);
        comment_button.valign = Gtk.Align.CENTER;
        comment_button.valign = Gtk.Align.CENTER;
        comment_button.can_focus = false;
        comment_button.tooltip_text = _("Project comments");
        comment_button.margin_start = 6;
        comment_button.get_style_context ().add_class ("flat");
        //comment_button.get_style_context ().add_class ("dim-label");

        var search_button = new Gtk.Button.from_icon_name ("edit-find-symbolic", Gtk.IconSize.MENU);
        search_button.valign = Gtk.Align.CENTER;
        search_button.valign = Gtk.Align.CENTER;
        search_button.can_focus = false;
        search_button.tooltip_text = _("Search task");
        search_button.margin_start = 6;
        search_button.get_style_context ().add_class ("flat");

        settings_button = new Gtk.ToggleButton ();
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.can_focus = false;
        settings_button.tooltip_text = _("Options");
        settings_button.image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.MENU);
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 24;
        top_box.margin_start = 41;

        top_box.pack_start (name_entry, false, true, 0);
        top_box.pack_end (settings_button, false, false, 0);
        //top_box.pack_end (search_button, false, false, 0);

        if (project.is_todoist == 1) {
            //top_box.pack_end (add_person_button, false, false, 0);
            //top_box.pack_end (comment_button, false, false, 0);
        }
        
        top_box.pack_end (section_stack, false, false, 0);
        
        var top_eventbox = new Gtk.EventBox ();
        top_eventbox.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK);
        top_eventbox.hexpand = true;
        top_eventbox.add (top_box);

        note_textview = new Gtk.TextView ();
        note_textview.tooltip_text = _("Add a note");
        note_textview.hexpand = true;
        note_textview.margin_top = 6;
        note_textview.height_request = 24;
        note_textview.wrap_mode = Gtk.WrapMode.WORD;
        note_textview.get_style_context ().add_class ("project-textview");
        note_textview.get_style_context ().add_class ("welcome");
        note_textview.margin_start = 42;

        note_placeholder = new Gtk.Label (_("Add note"));
        note_placeholder.opacity = 0.7;
        note_textview.add (note_placeholder);
        
        note_textview.buffer.text = project.note;

        if (project.note != "") {
            note_placeholder.visible = false;
            note_placeholder.no_show_all = true;
        } else {
            note_placeholder.visible = true;
            note_placeholder.no_show_all = false;
        }

        listbox = new Gtk.ListBox  ();
        listbox.margin_top = 6;
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("welcome");
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 24;
            
        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        motion_revealer.add (motion_grid);

        section_listbox = new Gtk.ListBox  ();
        section_listbox.margin_top = 6;
        section_listbox.valign = Gtk.Align.START;
        section_listbox.get_style_context ().add_class ("welcome");
        section_listbox.get_style_context ().add_class ("listbox");
        section_listbox.activate_on_single_click = true;
        section_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        section_listbox.hexpand = true;

        Gtk.drag_dest_set (section_listbox, Gtk.DestDefaults.ALL, targetEntriesSection, Gdk.DragAction.MOVE);
        section_listbox.drag_data_received.connect (on_drag_section_received);
        
        completed_listbox = new Gtk.ListBox  ();
        completed_listbox.margin_bottom = 32;
        completed_listbox.valign = Gtk.Align.START;
        completed_listbox.get_style_context ().add_class ("welcome");
        completed_listbox.get_style_context ().add_class ("listbox");
        completed_listbox.activate_on_single_click = true;
        completed_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        completed_listbox.hexpand = true;

        var completed_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        completed_box.hexpand = true;
        completed_box.pack_start (get_completed_header (), false, false, 0);
        completed_box.pack_start (completed_listbox, false, false, 0);

        completed_revealer = new Gtk.Revealer ();
        completed_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        completed_revealer.add (completed_box);
        
        var motion_last_grid = new Gtk.Grid ();
        //motion_last_grid.get_style_context ().add_class ("grid-motion");
        motion_last_grid.height_request = 24;

        var infobar = new Widgets.InfoBar ();
        /*
        var infobar = new Gtk.InfoBar ();
        infobar.show_close_button = true;
        infobar.message_type = Gtk.MessageType.QUESTION;
        */

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_eventbox, false, false, 0);
        main_box.pack_start (note_textview, false, true, 0);
        main_box.pack_start (motion_revealer, false, false, 0);
        //main_box.pack_start (infobar, false, false, 0);
        main_box.pack_start (listbox, false, false, 0);
        main_box.pack_start (section_listbox, false, false, 0);
        //main_box.pack_start (motion_last_grid, false, false, 0);
        main_box.pack_start (completed_revealer, false, false, 12);
        
        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.expand = true;
        main_scrolled.add (main_box);

        add (main_scrolled);

        build_drag_and_drop (false);

        add_all_items ();
        add_all_sections ();
        
        show_all ();

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.ItemRow) row);
            item.reveal_child = true;
        });

        settings_button.toggled.connect (() => {
            if (settings_button.active) {
                if (popover == null) {
                    create_popover ();
                }

                popover.show_all ();
            }
        });

        top_eventbox.event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                var edit_dialog = new Dialogs.ProjectSettings (project);
                edit_dialog.destroy.connect (Gtk.main_quit);
                edit_dialog.show_all ();
            }

            return false;
        });

        note_textview.focus_in_event.connect (() => {
            note_placeholder.visible = false;
            note_placeholder.no_show_all = true;

            return false;
        });

        note_textview.focus_out_event.connect (() => {
            if (note_textview.buffer.text == "") {
                note_placeholder.visible = true;
                note_placeholder.no_show_all = false;
            }

            return false;
        });

        note_textview.buffer.changed.connect (() => {
            save (false);
        });

        name_entry.changed.connect (() => {
            save ();
        });

        section_button.clicked.connect (() => {
            var section = new Objects.Section ();
            section.name = _("New Section");
            section.project_id = project.id;
            section.is_todoist = project.is_todoist;

            if (project.is_todoist == 0) {
                Planner.database.insert_section (section);
            } else {
                temp_id_mapping = Planner.utils.generate_id ();
                section.is_todoist = 1;

                Planner.todoist.add_section (section, temp_id_mapping);
            }
        });

        Planner.todoist.section_added_started.connect ((id) => {
            if (temp_id_mapping == id) {
                section_stack.visible_child_name = "section_loading";
            }
        });

        Planner.todoist.section_added_completed.connect ((id) => {
            if (temp_id_mapping == id) {
                section_stack.visible_child_name = "section_button";
                temp_id_mapping = 0;
            }
        });

        Planner.todoist.section_added_error.connect ((id) => {
            if (temp_id_mapping == id) {
                section_stack.visible_child_name = "section_button";
                temp_id_mapping = 0;
                print ("Add Section Error\n");
            }
        });

        Planner.database.project_updated.connect ((p) => {
            if (project != null && p.id == project.id) {
                project = p;

                name_entry.text = p.name;
            }
        });

        Planner.database.section_added.connect ((section) => {
            if (project.id == section.project_id) {
                var row = new Widgets.SectionRow (section);
                section_listbox.add (row);
                section_listbox.show_all ();

                row.set_focus = true;
            }
        });

        Planner.database.item_added.connect ((item) => {
            if (project.id == item.project_id && item.section_id == 0 && item.parent_id == 0) {
                var row = new Widgets.ItemRow (item);
                listbox.add (row);
                listbox.show_all ();
            }
        });

        Planner.database.item_added_with_index.connect ((item, index) => {
            if (project.id == item.project_id && item.section_id == 0) {
                var row = new Widgets.ItemRow (item);
                listbox.insert (row, index);
                listbox.show_all ();
            }
        });
        
        Planner.database.item_completed.connect ((item) => {
            if (project.id == item.project_id) {
                if (item.checked == 1 && item.parent_id == 0) {
                    if (completed_revealer.reveal_child) {
                        if (items_completed_loaded.has_key (item.id.to_string ()) == false) {
                            var row = new Widgets.ItemCompletedRow (item);
                            completed_listbox.add (row);
                            completed_listbox.show_all ();

                            items_completed_loaded.set (item.id.to_string (), true);
                        }
                    }
                } else {
                    if (item.section_id == 0 && item.parent_id == 0) {
                        var row = new Widgets.ItemRow (item);
                        listbox.add (row);
                        listbox.show_all ();
                    }
                }
            }
        });

        Planner.utils.magic_button_activated.connect ((project_id, section_id, is_todoist, last, index) => {
            if (project.id == project_id && section_id == 0) {
                var new_item = new Widgets.NewItem (
                    project_id,
                    section_id, 
                    is_todoist
                );
                
                if (last) {
                    listbox.add (new_item);
                } else {
                    new_item.has_index = true;
                    new_item.index = index;
                    listbox.insert (new_item, index);
                }
                
                listbox.show_all ();
            }
        });

        Planner.database.item_moved.connect ((item, project_id, old_project_id) => {
            Idle.add (() => {
                if (project.id == old_project_id) {
                    listbox.foreach ((widget) => {
                        var row = (Widgets.ItemRow) widget;
                        
                        if (row.item.id == item.id) {
                            row.destroy ();
                        }
                    });
                }

                if (project.id == project_id && item.section_id == 0) {
                    item.project_id = project_id;

                    var row = new Widgets.ItemRow (item);
                    listbox.add (row);
                    listbox.show_all ();
                }
                
                return false;
            });
        });

        Planner.database.section_moved.connect ((section, project_id, old_project_id) => {
            Idle.add (() => {
                if (project.id == old_project_id) {
                    section_listbox.foreach ((widget) => {
                        var row = (Widgets.SectionRow) widget;
                        
                        if (row.section.id == section.id) {
                            row.destroy ();
                        }
                    });
                }

                if (project.id == project_id) {
                    section.project_id = project_id;

                    var row = new Widgets.SectionRow (section);
                    section_listbox.add (row);
                    section_listbox.show_all ();
                }

                return false;
            });
        });
        
        Planner.database.item_section_moved.connect ((i, section_id, old_section_id) => {
            Idle.add (() => {
                if (0 == old_section_id) {
                    listbox.foreach ((widget) => {
                        var row = (Widgets.ItemRow) widget;
                        
                        if (row.item.id == i.id) {
                            row.destroy ();
                        }
                    });
                }

                if (0 == section_id) {
                    i.section_id = 0;

                    var row = new Widgets.ItemRow (i);
                    listbox.add (row);
                    listbox.show_all ();
                }

                return false;
            });
        });
    }

    private void save (bool online=true) {
        if (project != null) {
            project.note = note_textview.buffer.text;
            project.name = name_entry.text;

            if (online) {
                project.save ();
            } else {
                project.save_local ();
            }
        }
    }

    private void add_all_items () {
        foreach (var item in Planner.database.get_all_items_by_project_no_section_no_parent (project.id)) {
            var row = new Widgets.ItemRow (item);
            listbox.add (row);
            listbox.show_all ();
        }
    }

    private void add_completed_items (int64 id) { 
        foreach (var child in completed_listbox.get_children ()) {
            child.destroy ();
        }

        foreach (var item in Planner.database.get_all_completed_items_by_project (project.id)) {
            var row = new Widgets.ItemCompletedRow (item);
            completed_listbox.add (row);
            completed_listbox.show_all ();
        }

        completed_revealer.reveal_child = true;
    }

    private void add_all_sections () {
        foreach (var section in Planner.database.get_all_sections_by_project (project.id)) {
            var row = new Widgets.SectionRow (section);
            section_listbox.add (row);
            section_listbox.show_all ();
        }
    }

    private void build_drag_and_drop (bool is_magic_button_active) {
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);

        Gtk.drag_dest_set (note_textview, Gtk.DestDefaults.ALL, targetEntries, Gdk.DragAction.MOVE);
        note_textview.drag_data_received.connect (on_drag_item_received);
        note_textview.drag_motion.connect (on_drag_motion);
        note_textview.drag_leave.connect (on_drag_leave);
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ItemRow target;
        Widgets.ItemRow source;
        Gtk.Allocation alloc;

        target = (Widgets.ItemRow) listbox.get_row_at_y (y);
        target.get_allocation (out alloc);
        
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        if (target != null) {         
            if (source.item.section_id != 0) {
                source.item.section_id = 0;

                if (source.item.is_todoist == 1) {
                    Planner.todoist.move_item_to_section (source.item, 0);
                }
            }

            source.get_parent ().remove (source); 
            listbox.insert (source, target.get_index () + 1);
            listbox.show_all ();

            update_item_order ();
        }
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        if (source.item.section_id != 0) {
            source.item.section_id = 0;

            if (source.item.is_todoist == 1) {
                Planner.todoist.move_item_to_section (source.item, 0);
            }
        }

        source.get_parent ().remove (source); 
        listbox.insert (source, 0);
        listbox.show_all ();
    
        update_item_order ();
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_revealer.reveal_child = true;
        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;
    }

    private void update_item_order () {
        listbox.foreach ((widget) => {
            var row = (Gtk.ListBoxRow) widget;
            int index = row.get_index ();

            var item = ((Widgets.ItemRow) row).item;
            
            new Thread<void*> ("update_item_order", () => {
                Planner.database.update_item_order (item, 0, index);
                return null;
            });
        });
    }

    private void create_popover () {
        popover = new Gtk.Popover (settings_button);
        popover.position = Gtk.PositionType.BOTTOM;

        //var edit_menu = new Widgets.ModelButton (_("Edit project"), "edit-symbolic", "");
        //var archive_menu = new Widgets.ModelButton (_("Archive project"), "planner-archive-symbolic");

        var delete_menu = new Widgets.ModelButton (_("Delete project"), "user-trash-symbolic");
        var show_menu = new Widgets.ModelButton (_("Show completed task"), "emblem-default-symbolic", "");

        var separator_01 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_01.margin_top = 3;
        separator_01.margin_bottom = 3;

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 200;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 6;
        popover_grid.margin_bottom = 6;
        //popover_grid.add (edit_menu);
        //popover_grid.add (archive_menu);
        popover_grid.add (delete_menu);
        popover_grid.add (separator_01);
        popover_grid.add (show_menu);
  
        popover.add (popover_grid);

        popover.closed.connect (() => {
            settings_button.active = false;
        });

        /*
        edit_menu.clicked.connect (() => {
            if (project != null) {
                var edit_dialog = new Dialogs.ProjectSettings (project);
                edit_dialog.destroy.connect (Gtk.main_quit);
                edit_dialog.show_all ();
            }

            popover.popdown ();
        });
        */

        show_menu.clicked.connect (() => {
            if (completed_revealer.reveal_child) {
                show_menu.text = _("Show completed task");
                completed_revealer.reveal_child = false;
            } else {
                show_menu.text = _("Hide completed task");
                add_completed_items (project.id);
            }

            popover.popdown ();
        });
    }

    private void on_drag_section_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint target_type, uint time) {
        Widgets.SectionRow target;
        Widgets.SectionRow source;
        Gtk.Allocation alloc;

        target = (Widgets.SectionRow) section_listbox.get_row_at_y (y);
        target.get_allocation (out alloc);
        
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.SectionRow) row;
        
        if (target != null) {
            source.get_parent ().remove (source); 

            section_listbox.insert (source, target.get_index ());
            section_listbox.show_all ();

            update_section_order ();         
        }
    }

    private void update_section_order () {
        section_listbox.foreach ((widget) => {
            var row = (Gtk.ListBoxRow) widget;
            int index = row.get_index ();
            
            var section = ((Widgets.SectionRow) row).section;

            new Thread<void*> ("update_section_order", () => {
                Planner.database.update_section_item_order (section.id, index);

                return null;
            });
        });
    }

    private Gtk.Widget get_completed_header () {
        var name_label =  new Gtk.Label ("Task completed");
        name_label.halign = Gtk.Align.START;
        name_label.get_style_context ().add_class ("header-title");
        name_label.valign = Gtk.Align.CENTER;
        name_label.set_ellipsize (Pango.EllipsizeMode.END);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = 3;

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.margin_top = 12;
        main_box.margin_start = 41;
        main_box.margin_bottom = 6;
        main_box.margin_end = 32;
        main_box.hexpand = true;
        main_box.pack_start (name_label, false, false, 0);
        main_box.pack_start (separator, false, false, 0);
        main_box.show_all ();

        return main_box;
    }
}