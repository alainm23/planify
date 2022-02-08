public class Layouts.ItemRow : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    public int64 project_id { get; set; default = Constants.INACTIVE; }
    public int64 section_id { get; set; default = Constants.INACTIVE; }

    private Gtk.CheckButton checked_button;
    private Widgets.Entry content_entry;
    private Gtk.Revealer hide_loading_revealer;
    
    private Gtk.Label content_label;

    private Gtk.Revealer content_label_revealer;
    private Gtk.Revealer content_entry_revealer;

    private Gtk.Box content_top_box;
    private Gtk.Revealer detail_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.Grid handle_grid;
    private Gtk.Revealer top_motion_revealer;
    private Gtk.Revealer bottom_motion_revealer;
    private Gtk.EventBox itemrow_eventbox;
    private Gtk.Button cancel_button;
    private Gtk.Revealer actionbar_revealer;
    public Widgets.ProjectButton project_button;
    private Widgets.LoadingButton hide_loading_button;
    private Widgets.LoadingButton submit_button;
    private Widgets.HyperTextView description_textview;
    private Widgets.ItemLabels item_labels;
    private Widgets.ScheduleButton schedule_button;
    private Widgets.ItemSummary item_summary;
    private Widgets.PriorityButton priority_button;
    private Widgets.LabelButton label_button;
    private Widgets.PinButton pin_button;
    private Gtk.Revealer submit_cancel_revealer;
    private Gtk.Button delete_button;
    private Gtk.Button menu_button;
    private Gtk.Grid main_grid;
    
    bool _edit = false;
    public bool edit {
        set {
            _edit = value;
            
            if (value) {
                handle_grid.get_style_context ().add_class ("card");
                content_entry.get_style_context ().add_class ("font-weight-500");

                detail_revealer.reveal_child = true;
                content_label_revealer.reveal_child = false;
                content_entry_revealer.reveal_child = true;
                actionbar_revealer.reveal_child = true;
                item_summary.reveal_child = false;
                hide_loading_revealer.reveal_child = !is_creating;

                content_entry.grab_focus_without_selecting ();
                if (content_entry.cursor_position < content_entry.text_length) {
                    content_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, (int32) content_entry.text_length, false);
                }

                if (complete_timeout != 0) {
                    main_grid.get_style_context ().remove_class ("complete-animation");
                    content_label.get_style_context ().remove_class ("dim-label");
                }
            } else {
                handle_grid.get_style_context ().remove_class ("card");
                content_entry.get_style_context ().remove_class ("font-weight-500");

                detail_revealer.reveal_child = false;
                content_label_revealer.reveal_child = true;
                content_entry_revealer.reveal_child = false;
                actionbar_revealer.reveal_child = false;
                item_summary.check_revealer ();
                hide_loading_revealer.reveal_child = false;

                update_request ();
            }
        }
        get {
            return _edit;
        }
    }

    public bool reveal {
        set {
            main_revealer.reveal_child = true;
        }

        get {
            return main_revealer.reveal_child;
        }
    }

    public bool is_creating {
        get {
            return item.id == Constants.INACTIVE;
        }
    }

    public bool is_loading {
        set {
            hide_loading_revealer.reveal_child = value;
            hide_loading_button.is_loading = value;
        }
    }

    public uint destroy_timeout { get; set; default = 0; }
    public uint complete_timeout { get; set; default = 0; }
    public int64 update_id { get; set; default = Util.get_default ().generate_id (); }
    public bool is_menu_open { get; set; default = false; }

    public signal void item_added ();

    public ItemRow (Objects.Item item) {
        Object (
            item: item,
            can_focus: false
        );
    }

    public ItemRow.for_item (Objects.Item _item) {
        var item = new Objects.Item ();
        item.project_id = _item.project_id;
        item.section_id = _item.section_id;
        
        Object (
            item: item,
            can_focus: false
        );
    }

    public ItemRow.for_project (Objects.Project project) {
        var item = new Objects.Item ();
        item.project_id = project.id;
        
        Object (
            item: item,
            can_focus: false
        );
    }

    public ItemRow.for_section (Objects.Section section) {
        var item = new Objects.Item ();
        item.section_id = section.id;
        item.project_id = section.project.id;

        Object (
            item: item,
            can_focus: false
        );
    }

    construct {
        get_style_context ().add_class ("row");

        project_id = item.project_id;
        section_id = item.section_id;

        build_content ();

        item_summary = new Widgets.ItemSummary (item, this) {
            margin_start = 21
        };

        description_textview = new Widgets.HyperTextView (_("Description")) {
            height_request = 64,
            left_margin = 22,
            right_margin = 6,
            top_margin = 3,
            bottom_margin = 12,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true,
            editable = !item.completed
        };

        description_textview.get_style_context ().remove_class ("view");

        var description_scrolled = new Gtk.ScrolledWindow (null, null) {
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        description_scrolled.add (description_textview);

        item_labels = new Widgets.ItemLabels (item) {
            margin_start = 21,
            margin_bottom = 6,
            sensitive = !item.completed
        };

        project_button = new Widgets.ProjectButton (item) {
            sensitive = !item.completed
        };
        schedule_button = new Widgets.ScheduleButton (item);
        schedule_button.get_style_context ().add_class ("no-padding");

        priority_button = new Widgets.PriorityButton (item);
        priority_button.get_style_context ().add_class ("no-padding");
        
        label_button = new Widgets.LabelButton (item);
        label_button.get_style_context ().add_class ("no-padding");

        pin_button = new Widgets.PinButton (item);
        pin_button.get_style_context ().add_class ("no-padding");

        var action_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 20,
            margin_top = 6,
            margin_bottom = 6,
            hexpand = true,
            sensitive = !item.completed
        };

        action_grid.pack_start (schedule_button, false, false, 0);
        action_grid.pack_end (pin_button, false, false, 0);
        action_grid.pack_end (priority_button, false, false, 0);
        action_grid.pack_end (label_button, false, false, 0);

        var details_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        details_grid.add (description_scrolled);
        details_grid.add (item_labels);
        details_grid.add (action_grid);

        detail_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        detail_revealer.add (details_grid);

        handle_grid = new Gtk.Grid () {
            margin = 3,
            margin_start = 6,
            orientation = Gtk.Orientation.VERTICAL
        };
        handle_grid.get_style_context ().add_class ("transition");
        handle_grid.add (content_top_box);
        handle_grid.add (item_summary);
        handle_grid.add (detail_revealer);

        itemrow_eventbox = new Gtk.EventBox ();
        itemrow_eventbox.add_events (
            Gdk.EventMask.BUTTON_PRESS_MASK |
            Gdk.EventMask.BUTTON_RELEASE_MASK
        );
        itemrow_eventbox.add (handle_grid);

        var top_motion_grid = new Gtk.Grid () {
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            height_request = 16
        };
        top_motion_grid.get_style_context ().add_class ("grid-motion");

        top_motion_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        top_motion_revealer.add (top_motion_grid);

        var bottom_motion_grid = new Gtk.Grid () {
            margin_start = 6,
            margin_end = 6
        };
        bottom_motion_grid.get_style_context ().add_class ("grid-motion");
        bottom_motion_grid.height_request = 16;

        bottom_motion_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        bottom_motion_revealer.add (bottom_motion_grid);

        submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Add Task")) {
            sensitive = false,
            can_focus = false
        };
        submit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);
        submit_button.get_style_context ().add_class ("border-radius-6");

        cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            can_focus = false
        };
        cancel_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);
        cancel_button.get_style_context ().add_class ("border-radius-6");
        cancel_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        
        var submit_cancel_grid = new Gtk.Grid () {
            column_spacing = 6
        };
        submit_cancel_grid.add (cancel_button);
        submit_cancel_grid.add (submit_button);

        submit_cancel_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            reveal_child = is_creating
        };

        submit_cancel_revealer.add (submit_cancel_grid);

        var menu_image = new Gtk.Image () {
            gicon = new ThemedIcon ("content-loading-symbolic"),
            pixel_size = 16
        };
        
        menu_button = new Gtk.Button () {
            can_focus = false,
            no_show_all = is_creating
        };

        menu_button.add (menu_image);
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var trash_image = new Widgets.DynamicIcon ();
        trash_image.size = 16;
        trash_image.update_icon_name ("planner-trash");

        delete_button = new Gtk.Button () {
            can_focus = false,
            no_show_all = is_creating
        };

        delete_button.add (trash_image);
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var actionbar_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin = 3,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 12
        };

        actionbar_box.pack_start (submit_cancel_revealer, false, false, 0);
        // actionbar_box.pack_end (menu_button, false, false, 0);
        actionbar_box.pack_end (delete_button, false, false, 0);
        actionbar_box.pack_end (project_button, false, false, 0);

        actionbar_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        actionbar_revealer.add (actionbar_box);

        main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.get_style_context ().add_class ("transition");
        main_grid.add (top_motion_revealer);
        main_grid.add (itemrow_eventbox);
        main_grid.add (actionbar_revealer);
        main_grid.add (bottom_motion_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.add (main_grid);

        add (main_revealer);

        update_request ();

        if (!item.checked) {
            Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, Util.get_default ().ITEMROW_TARGET_ENTRIES, Gdk.DragAction.MOVE);
            drag_begin.connect (on_drag_begin);
            drag_data_get.connect (on_drag_data_get);
            drag_end.connect (clear_indicator);

            build_drag_and_drop (false);
        }

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            if (is_creating) {
                edit = true;
            }
            return GLib.Source.REMOVE;
        });

        connect_signals ();
    }

    private void build_content () {
        checked_button = new Gtk.CheckButton () {
            can_focus = false,
            valign = Gtk.Align.CENTER
        };
        checked_button.get_style_context ().add_class ("priority-color");

        content_label = new Gtk.Label (null) {
            hexpand = true,
            xalign = 0,
            wrap = false,
            ellipsize = Pango.EllipsizeMode.END,
            use_markup = true
        };

        content_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.NONE,
            transition_duration = 125,
            reveal_child = true
        };

        content_label_revealer.add (content_label);

        content_entry = new Widgets.Entry () {
            hexpand = true,
            placeholder_text = _("Task name"),
            margin_top = 1,
            editable = !item.completed
        };

        content_entry.get_style_context ().remove_class ("view");
        content_entry.get_style_context ().add_class ("content-entry");
        content_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        
        content_entry_revealer = new Gtk.Revealer () {
            valign = Gtk.Align.START,
            transition_type = Gtk.RevealerTransitionType.NONE,
            transition_duration = 125
        };

        content_entry_revealer.add (content_entry);

        hide_loading_button = new Widgets.LoadingButton (LoadingButtonType.ICON, "chevron-down") {
            valign = Gtk.Align.START,
            can_focus = false
        };
        hide_loading_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hide_loading_button.get_style_context ().add_class ("no-padding");
        hide_loading_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        hide_loading_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            valign = Gtk.Align.START
        };
        hide_loading_revealer.add (hide_loading_button);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.CENTER
        };
        content_box.hexpand = true;
        content_box.add (content_label_revealer);
        content_box.add (content_entry_revealer);

        content_top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        content_top_box.pack_start (checked_button, false, false, 0);
        content_top_box.pack_start (content_box, false, true, 6);
        content_top_box.pack_end (hide_loading_revealer, false, false, 0);
    }

    private void connect_signals () {
        itemrow_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                Timeout.add (Constants.DRAG_TIMEOUT, () => {
                    if (main_revealer.reveal_child) {
                        Planner.event_bus.item_selected (item.id);
                    }
                    return GLib.Source.REMOVE;
                });
            } else if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                activate_menu ();
            }

            return Gdk.EVENT_PROPAGATE;
        });

        Planner.event_bus.item_selected.connect ((id) => {
            if (item.id == id) {
                if (!edit) {
                    edit = true;
                }
            } else {
                if (edit) {
                    edit = false;
                }
            }
        });

        content_entry.key_press_event.connect ((key) => {
            if (Gdk.keyval_name (key.keyval) == "Return") {
                if (is_creating) {
                    add_item ();
                } else {
                    edit = false;
                }
                
                return Gdk.EVENT_STOP;
            }

            return false;
        });

        content_entry.focus_out_event.connect (() => {
            if (is_creating && !is_menu_open) {
                destroy_timeout = Timeout.add (Constants.DESTROY_TIMEOUT, () => {
                    hide_destroy ();
                    return GLib.Source.REMOVE;
                });
            }

            return false;
        });

        content_entry.focus_in_event.connect (() => {
            if (is_creating && destroy_timeout != 0) {
                Source.remove (destroy_timeout);
            }
        
            return false;
        });

        description_textview.focus_in_event.connect (() => {
            if (is_creating && destroy_timeout != 0) {
                Source.remove (destroy_timeout);
            }
        
            return false;
        });

        submit_button.clicked.connect (() => {
            add_item ();
        });

        cancel_button.clicked.connect (() => {
            if (is_creating) {
                Planner.event_bus.item_selected (null);
                hide_destroy ();
            }
        });

        content_entry.populate_popup.connect ((menu) => {
            is_menu_open = true;
            menu.hide.connect (() => {
                is_menu_open = false;
            });
        });

        content_entry.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                Planner.event_bus.item_selected (null);
            } else {
                if (!is_creating) {
                    update ();
                } else {
                    submit_button.sensitive = Util.get_default ().is_input_valid (content_entry);
                }
            }

            return false;
        });

        description_textview.key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                Planner.event_bus.item_selected (null);
            } else {
                if (!is_creating) {
                    update ();
                }
            }

            return false;
        });

        checked_button.button_release_event.connect (() => {
            if (!is_creating) {
                checked_button.active = !checked_button.active;
                checked_toggled (checked_button.active);
            }
            
            return Gdk.EVENT_STOP;
        });

        hide_loading_button.clicked.connect (() => {
            edit = false;
        });

        schedule_button.date_changed.connect ((date) => {
            update_due (date);
        });

        schedule_button.dialog_open.connect ((dialog_open) => {
            is_menu_open = dialog_open;
        });
        
        project_button.dialog_open.connect ((dialog_open) => {
            is_menu_open = dialog_open;
        });

        label_button.dialog_open.connect ((dialog_open) => {
            is_menu_open = dialog_open;
        });

        item_labels.dialog_open.connect ((dialog_open) => {
            is_menu_open = dialog_open;
        });
 
        project_button.changed.connect ((project_id, section_id) => {
            if (is_creating) {
                item.project_id = project_id;
                item.section_id = section_id;
                project_button.update_request ();
            } else {
                if (item.project_id != project_id || item.section_id != section_id) {
                    if (item.project.todoist) {
                        is_loading = true;

                        int64 move_id = project_id;
                        string move_type = "project_id";
                        if (section_id != Constants.INACTIVE) {
                            move_type = "section_id";
                            move_id = section_id;
                        }

                        Planner.todoist.move_item.begin (item, move_type, move_id, (obj, res) => {
                            if (Planner.todoist.move_item.end (res)) {
                                move_item (project_id, section_id);
                                is_loading = false;
                            } else {
                                main_revealer.reveal_child = true;
                            }
                        });
                    } else {
                        move_item (project_id, section_id);
                    }
                }
            }
        });

        priority_button.changed.connect ((priority) => {
            if (item.priority != priority) {
                item.priority = priority;

                if (is_creating) {
                    priority_button.update_request ();
                } else {
                    if (item.project.todoist) {
                        item.update_async (Constants.INACTIVE, hide_loading_button);
                    } else {
                        item.update_local ();
                    }
                }
            }
        });

        pin_button.changed.connect (() => {
            update_pinned (!item.pinned);
        });

        item_labels.labels_changed.connect (labels_changed);
        label_button.labels_changed.connect (labels_changed);

        delete_button.clicked.connect (() => {
            item.delete (this);
        });

        Planner.event_bus.magic_button_activated.connect ((value) => {
            if (!item.checked) {
                build_drag_and_drop (value);
            }
        });

        menu_button.clicked.connect (() => {

        });
    }

    private void labels_changed (Gee.HashMap <string, Objects.Label> labels) {
        if (is_creating) {
            item.update_local_labels (labels);
            item_labels.update_labels ();
        } else {
            item.update_labels_async (labels, hide_loading_button);
        }
    }

    private void move_item (int64 project_id, int64 section_id) {
        int64 old_project_id = item.project_id;
        int64 old_section_id = item.section_id;

        item.project_id = project_id;
        item.section_id = section_id;

        Planner.database.update_item (item);
        Planner.event_bus.item_moved (item, old_project_id, old_section_id);
    }

    private void update () {
        if (item.content != content_entry.get_text () ||
            item.description != description_textview.get_text ()) {
            item.content = content_entry.get_text ();
            item.description = description_textview.get_text ();

            item.update_async_timeout (update_id, hide_loading_button);       
        }
    }

    private void add_item () {
        if (is_creating && destroy_timeout != 0) {
            Source.remove (destroy_timeout);
        }
        
        if (Util.get_default ().is_input_valid (content_entry)) {
            submit_button.is_loading = true;

            item.content = content_entry.get_text ();
            item.description = description_textview.get_text ();

            if (item.project.todoist) {
                Planner.todoist.add.begin (item, (obj, res) => {
                    item.id = Planner.todoist.add.end (res);
                    item_added ();
                });
            } else {
                item.id = Util.get_default ().generate_id ();
                item_added ();
            }
        }
    }

    public void update_inserted_item () {
        update_request ();

        submit_cancel_revealer.reveal_child = false;
        submit_button.is_loading = false;
        
        delete_button.no_show_all = false;
        delete_button.show_all ();

        menu_button.no_show_all = false;
        menu_button.show_all ();

        edit = false;
    }

    public void update_request () {
        if (complete_timeout <= 0) {
            Util.get_default ().set_widget_priority (item.priority, checked_button);
            checked_button.active = item.completed;
            if (item.completed && Planner.settings.get_boolean ("underline-completed-tasks")) {
                content_label.get_style_context ().add_class ("line-through");
            }
        }

        content_label.label = item.content;
        content_label.tooltip_text = item.content;
        content_entry.set_text (item.content);
        description_textview.set_text (item.description);
                
        item_summary.update_request ();
        schedule_button.update_request ();
        priority_button.update_request ();
        pin_button.update_request ();

        if (!edit) {
            item_summary.check_revealer ();
        }
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    /*
        Build D&D
    */

    private void build_drag_and_drop (bool is_magic_button_active) {
        if (is_magic_button_active) {
            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, Util.get_default ().MAGICBUTTON_TARGET_ENTRIES, Gdk.DragAction.MOVE);
            drag_data_received.disconnect (on_drag_item_received); 
            drag_data_received.connect (on_drag_magicbutton_received);
        } else {
            drag_data_received.disconnect (on_drag_magicbutton_received);
            drag_data_received.connect (on_drag_item_received);
            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, Util.get_default ().ITEMROW_TARGET_ENTRIES, Gdk.DragAction.MOVE);
        }

        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = ((Layouts.ItemRow) widget).handle_grid;

        Gtk.Allocation row_alloc;
        row.get_allocation (out row_alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, row_alloc.width, row_alloc.height);
        var cairo_context = new Cairo.Context (surface);

        var style_context = row.get_style_context ();
        style_context.add_class ("drag-begin");
        row.draw_to_cairo_context (cairo_context);
        style_context.remove_class ("drag-begin");

        int drag_icon_x, drag_icon_y;
        widget.translate_coordinates (row, 0, 0, out drag_icon_x, out drag_icon_y);
        surface.set_device_offset (-drag_icon_x, -drag_icon_y);

        Gtk.drag_set_icon_surface (context, surface);
        main_revealer.reveal_child = false;
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Layouts.ItemRow))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("ITEMROW"), 32, data
        );
    }

    private void on_drag_magicbutton_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {

        var target_row = this;
        Gtk.Allocation alloc;
        target_row.get_allocation (out alloc);

        if (target_row == null) {
            return;
        }

        var target_list = (Gtk.ListBox) target_row.parent;
        var position = target_row.get_index () + 1;

        if (target_row.get_index () <= 0) {
            if (y < (alloc.height / 2)) {
                position = 0;
            }
        }

        Layouts.ItemRow row = new Layouts.ItemRow.for_item (item);
        row.item_added.connect (() => {
            Util.get_default ().item_added (row);
        });
        
        target_list.insert (row, position);
        target_list.show_all ();
    }

    private void on_drag_item_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
        var data = ((Gtk.Widget[]) selection_data.get_data ()) [0];
        var source_row = (Layouts.ItemRow) data;
        var target_row = this;
        Gtk.Allocation alloc;
        target_row.get_allocation (out alloc);

        if (source_row == target_row || target_row == null) {
            return;
        }
        
        int64 old_project_id = source_row.item.project_id;
        int64 old_section_id = source_row.item.section_id;

        if (source_row.item.project_id != target_row.item.project_id) {
            source_row.item.project_id = target_row.item.project_id;
        }

        if (source_row.item.section_id != target_row.item.section_id) {
            source_row.item.section_id = target_row.item.section_id;
        }

        if (old_project_id != source_row.item.project_id || old_section_id != source_row.item.section_id) {
            if (source_row.item.project.todoist) {

                int64 move_id = source_row.item.project_id;
                string move_type = "project_id";
                if (source_row.item.section_id != Constants.INACTIVE) {
                    move_type = "section_id";
                    move_id = source_row.item.section_id;
                }
                
                Planner.todoist.move_item.begin (source_row.item, move_type, move_id, (obj, res) => {
                    if (Planner.todoist.move_item.end (res)) {
                        Planner.database.update_item (source_row.item);
                    }
                });
            } else {
                Planner.database.update_item (source_row.item);
            }

            source_row.project_button.update_request ();
        }

        var source_list = (Gtk.ListBox) source_row.parent;
        var target_list = (Gtk.ListBox) target_row.parent;

        source_list.remove (source_row);

        if (target_row.get_index () <= 0) {
            if (y < (alloc.height / 2)) {
                target_list.insert (source_row, 0);
            } else {
                target_list.insert (source_row, target_row.get_index () + 1);
            }
        } else {
            target_list.insert (source_row, target_row.get_index () + 1);
        }

        Planner.event_bus.update_items_position (target_row.project_id, target_row.section_id);
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        Gtk.Allocation alloc;
        itemrow_eventbox.get_allocation (out alloc);
        
        if (get_index () == 0) {
            if (y > (alloc.height / 2)) {
                bottom_motion_revealer.reveal_child = true;
                top_motion_revealer.reveal_child = false;
            } else {
                bottom_motion_revealer.reveal_child = false;
                top_motion_revealer.reveal_child = true;
            }
        } else {
            bottom_motion_revealer.reveal_child = true;
        }

        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        bottom_motion_revealer.reveal_child = false;
        top_motion_revealer.reveal_child = false;
    }

    public void clear_indicator (Gdk.DragContext context) {
        main_revealer.reveal_child = true;
    }

    public void update_pinned (bool pinned) {
        item.pinned = pinned;

        if (is_creating) {
            pin_button.update_request ();
        } else {
            item.update_local ();
        }
    }
    
    public void update_due (GLib.DateTime? date) {
        item.due.date = date == null ? "" : Util.get_default ().get_todoist_datetime_format (date);

        if (is_creating) {
            schedule_button.update_request ();
        } else {
            item.update_async (Constants.INACTIVE, hide_loading_button);
        }
    }

    private void activate_menu () {
        var menu = new Dialogs.ContextMenu.Menu ();

        var schedule_item = new Dialogs.ContextMenu.MenuItem (_("Schedule"), "planner-calendar");
        var complete_item = new Dialogs.ContextMenu.MenuItem (_("Complete"), "planner-check-circle");
        var edit_item = new Dialogs.ContextMenu.MenuItem (_("Edit"), "planner-edit");

        var delete_item = new Dialogs.ContextMenu.MenuItem (_("Delete task"), "planner-trash");
        delete_item.get_style_context ().add_class ("menu-item-danger");

        menu.add_item (schedule_item);
        menu.add_item (complete_item);
        menu.add_item (edit_item);
        menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
        menu.add_item (delete_item);

        menu.show_all ();

        schedule_item.activate_item.connect (() => {
            var datetime_picker = new Dialogs.DateTimePicker.DateTimePicker ();
            datetime_picker.popup ();

            if (item.has_due) {
                datetime_picker.datetime = item.due.datetime;
            }

            datetime_picker.date_changed.connect (() => {
                update_due (datetime_picker.datetime);
            });
        });

        complete_item.activate_item.connect (() => {
            menu.hide_destroy ();
            checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
        });

        edit_item.activate_item.connect (() => {
            menu.hide_destroy ();
            edit = true;
        });

        delete_item.activate_item.connect (() => {
            menu.hide_destroy ();
            item.delete (this);
        });
    }

    private void checked_toggled (bool active) {
        bool old_checked = item.checked;

        if (active) {
            if (!edit) {
                content_label.get_style_context ().add_class ("dim-label");
                main_grid.get_style_context ().add_class ("complete-animation");
                if (Planner.settings.get_boolean ("underline-completed-tasks")) {
                    content_label.get_style_context ().add_class ("line-through");
                }
            }

            complete_timeout = Timeout.add (Constants.COMPLETE_TIMEOUT, () => {
                complete_timeout = 0;

                item.checked = true;
                item.completed_at = Util.get_default ().get_format_date (
                    new GLib.DateTime.now_local ()).to_string ();
    
                Planner.database.checked_toggled (item, old_checked);
    
                return GLib.Source.REMOVE;
            });
        } else {
            if (complete_timeout != 0) {
                GLib.Source.remove (complete_timeout);
                main_grid.get_style_context ().remove_class ("complete-animation");
                content_label.get_style_context ().remove_class ("dim-label");
                content_label.get_style_context ().remove_class ("line-through");
            } else {
                item.checked = false;
                item.completed_at = "";

                Planner.database.checked_toggled (item, old_checked);
            }
        }
    }
}
