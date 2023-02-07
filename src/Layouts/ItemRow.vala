public class Layouts.ItemRow : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    public string project_id { get; set; default = ""; }
    public string section_id { get; set; default = ""; }
    public string parent_id { get; set; default = ""; }

    private Gtk.CheckButton checked_button;
    private Widgets.SourceView content_textview;
    private Gtk.Revealer hide_loading_revealer;

    private Gtk.CheckButton select_checkbutton;
    private Gtk.Revealer select_revealer;

    private Gtk.Label content_label;

    private Gtk.Revealer content_label_revealer;
    private Gtk.Revealer content_entry_revealer;

    private Gtk.Box content_top_box;
    private Gtk.Revealer detail_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.Box handle_grid;
    private Gtk.Popover menu_handle_popover = null;
    
    private Gtk.Popover menu_popover = null;
    private Widgets.ContextMenu.MenuItem more_information_item;
    private Gtk.Button cancel_button;
    private Gtk.Revealer actionbar_revealer;
    private Widgets.LoadingButton hide_loading_button;
    private Widgets.LoadingButton submit_button;
    private Widgets.HyperTextView description_textview;
    private Widgets.ItemLabels item_labels;
    private Widgets.ScheduleButton schedule_button;
    private Widgets.ItemSummary item_summary;
    private Widgets.PriorityButton priority_button;
    private Widgets.LabelButton label_button;
    private Widgets.PinButton pin_button;
    private Widgets.ReminderButton reminder_button;

    private Gtk.Revealer submit_cancel_revealer;
    private Gtk.Button delete_button;
    private Gtk.Button menu_button;
    private Gtk.Revealer delete_button_revealer;
    private Gtk.Revealer menu_button_revealer;
    private Gtk.Button hide_subtask_button;
    private Gtk.Revealer hide_subtask_revealer;
    private Gtk.Box main_grid;
    private Widgets.ContextMenu.MenuItem no_date_item;
    
    private Gtk.DragSource drag_source;
    private Gtk.DropTarget drop_target;

    bool _edit = false;
    public bool edit {
        set {
            _edit = value;
            
            if (value) {
                handle_grid.add_css_class ("card");
                handle_grid.add_css_class ("card-selected");
                handle_grid.add_css_class (is_creating ? "mt-12" : "mt-24");
                main_grid.add_css_class ("mb-12");
                hide_subtask_button.margin_top = 27;

                detail_revealer.reveal_child = true;
                content_label_revealer.reveal_child = false;
                content_entry_revealer.reveal_child = true;
                actionbar_revealer.reveal_child = !item.completed;
                item_summary.reveal_child = false;
                hide_loading_revealer.reveal_child = !is_creating;

                content_textview.grab_focus ();

                if (complete_timeout != 0) {
                    main_grid.get_style_context ().remove_class ("complete-animation");
                    content_label.get_style_context ().remove_class ("dim-label");
                }

                disable_drag_and_drop ();
            } else {
                handle_grid.remove_css_class ("card");
                handle_grid.remove_css_class ("card-selected");
                handle_grid.remove_css_class ("mt-12");
                handle_grid.remove_css_class ("mt-24");
                main_grid.remove_css_class ("mb-12");
                hide_subtask_button.margin_top = 3;

                detail_revealer.reveal_child = false;
                content_label_revealer.reveal_child = true;
                content_entry_revealer.reveal_child = false;
                actionbar_revealer.reveal_child = false;
                item_summary.check_revealer ();
                hide_loading_revealer.reveal_child = false;

                update_request ();
                build_drag_and_drop ();
            }
        }
        get {
            return _edit;
        }
    }

    private bool _is_row_selected = false;
    public bool is_row_selected {
        set {
            _is_row_selected = value;

            if (value) {
                main_grid.add_css_class ("complete-animation");
            } else {
                main_grid.remove_css_class ("complete-animation");
            }
        }

        get {
            return _is_row_selected;
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
            return item.id == "";
        }
    }

    public bool is_loading {
        set {
            if (value) {
                hide_loading_revealer.reveal_child = value;
                hide_loading_button.is_loading = value;
            } else {
                hide_loading_button.is_loading = value;
                hide_loading_revealer.reveal_child = edit;
            }
        }
    }

    public uint destroy_timeout { get; set; default = 0; }
    public uint complete_timeout { get; set; default = 0; }
    public int64 update_id { get; set; default = int64.parse (Util.get_default ().generate_id ()); }
    public bool on_drag = false;

    public signal void item_added ();

    public ItemRow (Objects.Item item) {
        Object (
            item: item,
            focusable: false,
            can_focus: true
        );
    }

    public ItemRow.for_item (Objects.Item _item) {
        var item = new Objects.Item ();
        item.project_id = _item.project_id;
        item.section_id = _item.section_id;

        Object (
            item: item,
            focusable: false,
            can_focus: true
        );
    }

    public ItemRow.for_project (Objects.Project project) {
        var item = new Objects.Item ();
        item.project_id = project.id;

        Object (
            item: item,
            focusable: false,
            can_focus: true
        );
    }

    public ItemRow.for_parent (Objects.Item _item) {
        var item = new Objects.Item ();
        item.project_id = _item.project_id;
        item.section_id = _item.section_id;
        item.parent_id = _item.id;
        
        Object (
            item: item,
            focusable: false,
            can_focus: true
        );
    }

    public ItemRow.for_section (Objects.Section section) {
        var item = new Objects.Item ();
        item.section_id = section.id;
        item.project_id = section.project.id;

        Object (
            item: item,
            focusable: false,
            can_focus: true
        );
    }

    construct {
        add_css_class ("row");

        project_id = item.project_id;
        section_id = item.section_id;
        parent_id = item.parent_id;

        if (is_creating) {
            Planner.event_bus.update_section_sort_func (project_id, section_id, false);
        }

        checked_button = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER
        };

        checked_button.add_css_class ("priority-color");

        content_label = new Gtk.Label (item.content) {
            hexpand = true,
            xalign = 0,
            wrap = true,
            ellipsize = Pango.EllipsizeMode.NONE
        };

        content_label_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            transition_duration = 125,
            reveal_child = true
        };

        content_label_revealer.child = content_label;

        content_textview = new Widgets.SourceView ();
        content_textview.wrap_mode = Gtk.WrapMode.WORD;
        content_textview.buffer.text = item.content;
        content_textview.editable = !item.completed;

        content_textview.remove_css_class ("view");

        content_entry_revealer = new Gtk.Revealer () {
            valign = Gtk.Align.CENTER,
            transition_type = Gtk.RevealerTransitionType.SWING_DOWN,
            transition_duration = 125,
            reveal_child = false
        };

        content_entry_revealer.child = content_textview;

        hide_loading_button = new Widgets.LoadingButton.with_icon ("chevron-down", 19) {
            valign = Gtk.Align.START,
            can_focus = false
        };
        hide_loading_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        hide_loading_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        hide_loading_button.add_css_class ("no-padding");
        
        hide_loading_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            valign = Gtk.Align.START
        };
        hide_loading_revealer.child = hide_loading_button;

        select_checkbutton = new Gtk.CheckButton () {
            valign = Gtk.Align.CENTER,
            margin_end = 6
        };

        select_checkbutton.add_css_class ("circular-check");

        select_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };

        select_revealer.child = select_checkbutton;

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.CENTER,
            margin_start = 6
        };
        content_box.hexpand = true;
        content_box.append (content_label_revealer);
        content_box.append (content_entry_revealer);

        content_top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        content_top_box.append (checked_button);
        content_top_box.append (content_box);
        content_top_box.append (hide_loading_revealer);

        item_summary = new Widgets.ItemSummary (item, this) {
            margin_start = 24
        };

        description_textview = new Widgets.HyperTextView (_("Add a description")) {
            height_request = 64,
            left_margin = 24,
            right_margin = 6,
            top_margin = 3,
            bottom_margin = 12,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true,
            editable = !item.completed
        };

        description_textview.remove_css_class ("view");

        item_labels = new Widgets.ItemLabels (item) {
            margin_start = 31,
            sensitive = !item.completed
        };

        //  project_button = new Widgets.ProjectButton (item) {
        //      sensitive = !item.completed
        //  };

        schedule_button = new Widgets.ScheduleButton ();

        priority_button = new Widgets.PriorityButton ();
        
        label_button = new Widgets.LabelButton (item);

        pin_button = new Widgets.PinButton (item);
        
        reminder_button = new Widgets.ReminderButton (item) {
            visible = !is_creating
        };

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 20,
            margin_top = 6,
            hexpand = true,
            sensitive = !item.completed
        };

        var action_box_right = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            hexpand = true,
            halign = Gtk.Align.END
        };

        action_box_right.append (label_button);
        action_box_right.append (priority_button);
        action_box_right.append (reminder_button);
        action_box_right.append (pin_button);

        action_box.append (schedule_button);
        action_box.append (action_box_right);
        //  action_grid.pack_end (add_button, false, false, 0);

        var details_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        details_grid.append (description_textview);
        details_grid.append (item_labels);
        details_grid.append (action_box);

        detail_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        detail_revealer.child = details_grid;

        handle_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.START
        };

        handle_grid.add_css_class ("transition");
        handle_grid.append (content_top_box);
        handle_grid.append (item_summary);
        handle_grid.append (detail_revealer);

        var chevron_right_image = new Widgets.DynamicIcon ();
        chevron_right_image.size = 19;
        chevron_right_image.update_icon_name ("chevron-right");

        hide_subtask_button = new Gtk.Button () {
            valign = Gtk.Align.START,
            margin_top = 6,
            can_focus = false
        };
        hide_subtask_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        hide_subtask_button.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        hide_subtask_button.add_css_class ("no-padding");
        hide_subtask_button.add_css_class ("hidden-button");
        hide_subtask_button.child = chevron_right_image;

        hide_subtask_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            reveal_child = false
        };

        hide_subtask_revealer.child = hide_subtask_button;

        var itemrow_eventbox_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        // itemrow_eventbox_box.append (hide_subtask_revealer);
        itemrow_eventbox_box.append (handle_grid);
        itemrow_eventbox_box.append (select_revealer);

        submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Add Task"));
        submit_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        submit_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        submit_button.add_css_class ("border-radius-6");
        submit_button.add_css_class ("action-button");

        cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            can_focus = false
        };
        cancel_button.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);
        cancel_button.add_css_class ("border-radius-6");
        cancel_button.add_css_class ("action-button");
        
        var submit_cancel_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3
        };
        submit_cancel_grid.append (cancel_button);
        submit_cancel_grid.append (submit_button);

        submit_cancel_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = is_creating
        };

        submit_cancel_revealer.child = submit_cancel_grid;

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 19;
        menu_image.update_icon_name ("dots-horizontal");
        
        menu_button = new Gtk.Button () {
            can_focus = false
        };

        menu_button.child = menu_image;
        menu_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        
        menu_button_revealer = new Gtk.Revealer () {
            reveal_child = !is_creating
        };

        menu_button_revealer.child = menu_button;

        var trash_image = new Widgets.DynamicIcon ();
        trash_image.size = 19;
        trash_image.update_icon_name ("planner-trash");

        delete_button = new Gtk.Button () {
            can_focus = false
        };

        delete_button.child = trash_image;
        delete_button.get_style_context ().add_class (Granite.STYLE_CLASS_FLAT);

        delete_button_revealer = new Gtk.Revealer () {
            reveal_child = !is_creating
        };

        delete_button_revealer.child = delete_button;

        var project_delete_menu_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            halign = Gtk.Align.END
        };

        // project_delete_menu_box.append (project_button);
        project_delete_menu_box.append (delete_button_revealer);
        project_delete_menu_box.append (menu_button_revealer);

        var actionbar_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6
        };

        actionbar_box.append (submit_cancel_revealer);
        actionbar_box.append (project_delete_menu_box);
        actionbar_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };

        actionbar_revealer.child = actionbar_box;

        //  subitems = new Widgets.SubItems (item);

        main_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        main_grid.add_css_class ("transition");
        // main_grid.append (top_motion_revealer);
        main_grid.append (itemrow_eventbox_box);
        main_grid.append (actionbar_revealer);
        // main_grid.append (subitems);
        // main_grid.append (bottom_motion_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        
        main_revealer.child = main_grid;

        child = main_revealer;
        update_request ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            
            if (is_creating) {
                edit = true;
            }

            if (!item.checked) {                
                build_drag_and_drop ();     
            }

            return GLib.Source.REMOVE;
        });

        connect_signals ();
    }

    private void connect_signals () {
        var handle_gesture_click = new Gtk.GestureClick ();
        handle_grid.add_controller (handle_gesture_click);

        handle_gesture_click.pressed.connect ((n_press, x, y) => {
            if (Planner.event_bus.multi_select_enabled) {
                select_checkbutton.active = !select_checkbutton.active;
                selected_toggled (select_checkbutton.active);             
            } else {
                Planner.event_bus.unselect_all ();
                Timeout.add (Constants.DRAG_TIMEOUT, () => {
                    if (!on_drag) {
                        Planner.event_bus.item_selected (item.id);
                    }

                    return GLib.Source.REMOVE;
                });
            }
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

        var content_controller_key = new Gtk.EventControllerKey ();
        content_textview.add_controller (content_controller_key);

        content_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65293) {
                if (is_creating) {
                    add_item ();
                } else {
                    edit = false;
                }
                
                return Gdk.EVENT_STOP;
            }

            return false;
        });

        content_controller_key.key_released.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                if (is_creating) {
                    hide_destroy ();
                } else {
                    Planner.event_bus.item_selected (null);
                }
            } else {
                if (!is_creating) {
                    update ();
                } else {
                    submit_button.sensitive = Util.get_default ().is_text_valid (content_textview);
                }
            }
        });

        var description_controller_key = new Gtk.EventControllerKey ();
        description_textview.add_controller (description_controller_key);
        
        description_controller_key.key_released.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                if (is_creating) {
                    hide_destroy ();
                } else {
                    Planner.event_bus.item_selected (null);
                }
            } else {
                if (!is_creating) {
                    update ();
                }
            }
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

    //      content_textview.populate_popup.connect ((menu) => {
    //          is_menu_open = true;
    //          menu.hide.connect (() => {
    //              is_menu_open = false;
    //          });
    //      });

        var checked_button_gesture = new Gtk.GestureClick ();
        checked_button_gesture.set_button (1);
        checked_button.add_controller (checked_button_gesture);

        checked_button_gesture.pressed.connect (() => {
            checked_button_gesture.set_state (Gtk.EventSequenceState.CLAIMED);

            if (is_creating == false && is_row_selected == false) {
                checked_button.active = !checked_button.active;
                checked_toggled (checked_button.active);
            }
        });    

        var hide_loading_gesture = new Gtk.GestureClick ();
        hide_loading_gesture.set_button (1);
        hide_loading_button.add_controller (hide_loading_gesture);

        hide_loading_gesture.pressed.connect (() => {
            hide_loading_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            edit = false;
        });

        schedule_button.date_changed.connect ((datetime) => {
            update_due (datetime);
        });

        priority_button.changed.connect ((priority) => {
            if (item.priority != priority) {
                item.priority = priority;

                if (is_creating) {
                    priority_button.update_from_item (item);
                } else {
                    if (item.project.backend_type == BackendType.TODOIST) {
                        item.update_async (Constants.INACTIVE, this);
                    } else {
                        item.update_local ();
                    }
                }
            }
        });

        pin_button.changed.connect (() => {
            update_pinned (!item.pinned);
        });

        item_labels.labels_changed.connect (update_labels);
        label_button.labels_changed.connect (update_labels);

        delete_button.clicked.connect (() => {
            delete_request ();
        });


        Planner.event_bus.checked_toggled.connect ((i) => {
            if (item.id == i.parent_id) {
                item_summary.update_request ();
            }
        });

        Services.Database.get_default ().item_deleted.connect ((i) => {
            if (item.id == i.parent_id) {
                item_summary.update_request ();
            }
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "underline-completed-tasks") {
                update_request ();
            }
        });

        var menu_handle_gesture = new Gtk.GestureClick ();
        menu_handle_gesture.set_button (3);
        handle_grid.add_controller (menu_handle_gesture);

        menu_handle_gesture.pressed.connect ((n_press, x, y) => {
            if (!item.completed) {
                build_handle_context_menu (x, y);
            }
        });

        var menu_gesture = new Gtk.GestureClick ();
        menu_button.add_controller (menu_gesture);

        menu_gesture.pressed.connect ((n_press, x, y) => {
            build_button_context_menu (x, y);
        });

        var multiselect_gesture = new Gtk.GestureClick ();
        multiselect_gesture.set_button (1);
        select_checkbutton.add_controller (multiselect_gesture);

        multiselect_gesture.pressed.connect (() => {
            multiselect_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            select_checkbutton.active = !select_checkbutton.active;
            selected_toggled (select_checkbutton.active);
        });    

        Planner.event_bus.show_multi_select.connect ((active) => {
            select_revealer.reveal_child = active;

            if (!active) {
                select_checkbutton.active = false;
            }
        });
    }

    private void selected_toggled (bool active) {
        if (select_checkbutton.active) {
            Planner.event_bus.select_item (this);
        } else {
            Planner.event_bus.unselect_item (this);
        }
    }

    private void update () {
        if (item.content != content_textview.buffer.text ||
            item.description != description_textview.get_text ()) {
            item.content = content_textview.buffer.text;
            item.description = description_textview.get_text ();

            item.update_async_timeout (update_id, this);      
        }
    }

    private void add_item () {
        if (is_creating && destroy_timeout != 0) {
            Source.remove (destroy_timeout);
        }
        
        if (!Util.get_default ().is_text_valid (content_textview)) {
            hide_destroy ();
            return;
        }

        item.content = content_textview.buffer.text;
        item.description = description_textview.get_text ();

        if (item.project.backend_type == BackendType.TODOIST) {
            submit_button.is_loading = true;
            Services.Todoist.get_default ().add.begin (item, (obj, res) => {
                string? id = Services.Todoist.get_default ().add.end (res);
                if (id != null) {
                    item.id = id;
                    item_added ();
                }
            });
        } else if (item.project.backend_type == BackendType.LOCAL) {
            item.id = Util.get_default ().generate_id ();
            item_added ();
        }
    }

    public void update_inserted_item () {
        update_request ();

        submit_cancel_revealer.reveal_child = false;
        submit_button.is_loading = false;
        
        //  add_button.no_show_all = false;
        //  add_button.show_all ();

        delete_button_revealer.reveal_child = true;
        menu_button_revealer.reveal_child = true;

        reminder_button.visible =  true;

        edit = false;
    }

    public void update_request () {
        if (complete_timeout <= 0) {
            Util.get_default ().set_widget_priority (item.priority, checked_button);
            checked_button.active = item.completed;

            if (item.completed && Planner.settings.get_boolean ("underline-completed-tasks")) {
                content_label.add_css_class ("line-through");
            } else if (item.completed && !Planner.settings.get_boolean ("underline-completed-tasks")) {
                content_label.remove_css_class ("line-through");
            }
        }

        content_label.label = item.content;
        content_label.tooltip_text = item.content;
        content_textview.buffer.text = item.content;
        description_textview.set_text (item.description);
                
        item_summary.update_request ();
        schedule_button.update_from_item (item);
        priority_button.update_from_item (item);
        pin_button.update_request ();
        
        if (!edit) {
            item_summary.check_revealer ();
        }
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
    
    public void update_pinned (bool pinned) {
        item.pinned = pinned;

        if (is_creating) {
            pin_button.update_request ();
        } else {
            item.update_local ();
        }
    }

    private void build_handle_context_menu (double x, double y) {
        if (menu_handle_popover != null) {
            if (item.has_due) {
                no_date_item.show ();
            } else {
                no_date_item.hide ();
            }

            menu_handle_popover.pointing_to = { (int) x, (int) y, 1, 1 };
            menu_handle_popover.popup();
            return;
        }

        var today_item = new Widgets.ContextMenu.MenuItem (_("Today"), "planner-today");
        today_item.secondary_text = new GLib.DateTime.now_local ().format ("%a");

        var tomorrow_item = new Widgets.ContextMenu.MenuItem (_("Tomorrow"), "planner-scheduled");
        tomorrow_item.secondary_text = new GLib.DateTime.now_local ().add_days (1).format ("%a");
        
        no_date_item = new Widgets.ContextMenu.MenuItem (_("No Date"), "planner-close-circle");

        // var labels_item = new Widgets.ContextMenu.MenuItem (_("Labels"), "planner-tag");
        // var reminders_item = new Widgets.ContextMenu.MenuItem (_("Reminders"), "planner-bell");
        var move_item = new Widgets.ContextMenu.MenuItem (_("Move"), "chevron-right");

        var complete_item = new Widgets.ContextMenu.MenuItem (_("Complete"), "planner-check-circle");
        var edit_item = new Widgets.ContextMenu.MenuItem (_("Edit"), "planner-edit");

        var delete_item = new Widgets.ContextMenu.MenuItem (_("Delete task"), "planner-trash");
        delete_item.get_style_context ().add_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (today_item);
        menu_box.append (tomorrow_item);
        if (item.has_due) {
            menu_box.append (no_date_item);
        }
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        // menu_box.append (labels_item);
        // menu_box.append (reminders_item);
        menu_box.append (move_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (complete_item);
        menu_box.append (edit_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (delete_item);

        menu_handle_popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.RIGHT,
            width_request = 225
        };

        menu_handle_popover.set_parent (this);
        menu_handle_popover.pointing_to = { (int) x, (int) y, 1, 1 };

        menu_handle_popover.popup();

        move_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            
            var dialog = new Dialogs.ProjectPicker.ProjectPicker ();
            dialog.project = item.project;
            dialog.show ();

            dialog.changed.connect ((project_id) => {
                move (project_id, item.section_id);
            });
        });

        today_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            update_due (Util.get_default ().get_format_date (new DateTime.now_local ()));
        });

        tomorrow_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            update_due (Util.get_default ().get_format_date (new DateTime.now_local ().add_days (1)));
        });

        no_date_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            update_due (null);
        });

        complete_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
        });

        edit_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            edit = true;
        });

        delete_item.activate_item.connect (() => {
            menu_handle_popover.popdown ();
            delete_request ();
        });
    }

    private void build_button_context_menu (double x, double y) {
        string added_at = _("Added at");
        string updated_at = _("Updated at");
        string added_date = Util.get_default ().get_relative_date_from_date (item.added_datetime);
        string updated_date = "(" + _("Not available") + ")";
        if (item.updated_at != "") {
            updated_date = Util.get_default ().get_relative_date_from_date (item.updated_datetime);
        }

        string added_updated_format = "<b>%s:</b> %s\n<b>%s:</b> %s".printf (added_at, added_date, updated_at, updated_date);

        if (menu_popover != null) {
            more_information_item.title = added_updated_format;
            menu_popover.popup();
            return;
        }

        var copy_clipboard_item = new Widgets.ContextMenu.MenuItem (("Copy to clipboard"), "planner-clipboard");
        var duplicate_item = new Widgets.ContextMenu.MenuItem (("Duplicate"), "planner-copy");
        var move_item = new Widgets.ContextMenu.MenuItem (_("Move"), "chevron-right");
        var repeat_item = new Widgets.ContextMenu.MenuItem (("Repeat…"), "planner-rotate");

        more_information_item = new Widgets.ContextMenu.MenuItem (added_updated_format, null);
        more_information_item.add_css_class ("small-label");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (copy_clipboard_item);
        menu_box.append (duplicate_item);
        menu_box.append (move_item);
        menu_box.append (repeat_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (more_information_item);

        var menu_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
            vhomogeneous = false
        };

        menu_stack.add_named (menu_box, "menu");
        menu_stack.add_named (get_repeat_widget (), "repeat");

        menu_popover = new Gtk.Popover () {
            has_arrow = false,
            child = menu_stack,
            position = Gtk.PositionType.BOTTOM,
            width_request = 225
        };

        menu_popover.set_parent (menu_button);
        menu_popover.popup ();

        copy_clipboard_item.clicked.connect (() => {
            menu_popover.popdown ();
            item.copy_clipboard ();
        });

        duplicate_item.clicked.connect (() => {
            menu_popover.popdown ();
            item.duplicate ();
        });

        move_item.clicked.connect (() => {
            menu_popover.popdown ();
            
            var dialog = new Dialogs.ProjectPicker.ProjectPicker ();
            dialog.project = item.project;
            dialog.show ();

            dialog.changed.connect ((project_id) => {
                move (project_id, item.section_id);
            });
        });

        repeat_item.clicked.connect (() => {
            menu_stack.set_visible_child_name ("repeat");
        });

        menu_popover.closed.connect (() => {
            menu_stack.set_visible_child_name ("menu");
        });
    }

    private Gtk.Widget get_repeat_widget () {
        var none_item = new Widgets.ContextMenu.MenuItem (("None"));
        var daily_item = new Widgets.ContextMenu.MenuItem (("Daily"));
        var weekly_item = new Widgets.ContextMenu.MenuItem (("Weekly"));
        var monthly_item = new Widgets.ContextMenu.MenuItem (("Monthly"));
        var yearly_item = new Widgets.ContextMenu.MenuItem (("Yearly"));
        var custom_item = new Widgets.ContextMenu.MenuItem (("Custom"));
        
        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (daily_item);
        menu_box.append (weekly_item);
        menu_box.append (monthly_item);
        menu_box.append (yearly_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (none_item);
        menu_box.append (custom_item);
        
        daily_item.clicked.connect (() => {
            menu_popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = true;
            duedate.recurrency_type = RecurrencyType.EVERY_DAY;
            duedate.recurrency_interval = 1;
            set_recurrency (duedate);
        });

        weekly_item.clicked.connect (() => {
            menu_popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = true;
            duedate.recurrency_type = RecurrencyType.EVERY_WEEK;
            duedate.recurrency_interval = 1;
            set_recurrency (duedate);
        });

        monthly_item.clicked.connect (() => {
            menu_popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = true;
            duedate.recurrency_type = RecurrencyType.EVERY_MONTH;
            duedate.recurrency_interval = 1;
            set_recurrency (duedate);
        });

        yearly_item.clicked.connect (() => {
            menu_popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = true;
            duedate.recurrency_type = RecurrencyType.EVERY_YEAR;
            duedate.recurrency_interval = 1;
            set_recurrency (duedate);
        });

        none_item.clicked.connect (() => {
            menu_popover.popdown ();

            var duedate = new Objects.DueDate ();
            duedate.is_recurring = false;
            duedate.recurrency_type = RecurrencyType.NONE;
            duedate.recurrency_interval = 0;
            set_recurrency (duedate);
        });

        custom_item.clicked.connect (() => {
            menu_popover.popdown ();

            var dialog = new Dialogs.RepeatConfig ();
            dialog.show ();

            if (item.has_due) {
                dialog.duedate = item.due;
            }

            dialog.changed.connect ((duedate) => {
                set_recurrency (duedate);
            });
        });

        return menu_box;
    }

    public void checked_toggled (bool active, uint? time = null) {
        Planner.event_bus.unselect_all ();
        bool old_checked = item.checked;

        if (active) {
            complete_item (old_checked, time);
        } else {
            if (complete_timeout != 0) {
                GLib.Source.remove (complete_timeout);
                complete_timeout = 0;
                handle_grid.remove_css_class ("complete-animation");
                content_label.remove_css_class ("dim-label");
                content_label.remove_css_class ("line-through");
            } else {
                item.checked = false;
                item.completed_at = "";

                if (item.project.backend_type == BackendType.TODOIST) {
                    checked_button.sensitive = false;
                    is_loading = true;
                    Services.Todoist.get_default ().complete_item.begin (item, (obj, res) => {
                        if (Services.Todoist.get_default ().complete_item.end (res)) {
                            Services.Database.get_default ().checked_toggled (item, old_checked);
                            is_loading = false;
                            checked_button.sensitive = true;
                        }
                    });
                } else {
                    Services.Database.get_default ().checked_toggled (item, old_checked);
                }
            }
        }
    }

    private void complete_item (bool old_checked, uint? time = null) {
        uint timeout = 2500;
        if (Planner.settings.get_enum ("complete-task") == 0) {
            timeout = 0;
        }

        if (time != null) {
            timeout = time;
        }

        if (timeout > 0 && !edit) {
            content_label.add_css_class ("dim-label");
            handle_grid.add_css_class ("complete-animation");
            if (Planner.settings.get_boolean ("underline-completed-tasks")) {
                content_label.add_css_class ("line-through");
            }
        }

        complete_timeout = Timeout.add (timeout, () => {
            complete_timeout = 0;

            if (item.due.is_recurring) {
                update_recurrency ();
            } else {
                item.checked = true;
                item.completed_at = Util.get_default ().get_format_date (
                    new GLib.DateTime.now_local ()).to_string ();
                    
                if (item.project.backend_type == BackendType.TODOIST) {
                    checked_button.sensitive = false;
                    is_loading = true;
                    Services.Todoist.get_default ().complete_item.begin (item, (obj, res) => {
                        if (Services.Todoist.get_default ().complete_item.end (res)) {
                            Services.Database.get_default ().checked_toggled (item, old_checked);
                            is_loading = false;
                            checked_button.sensitive = true;
                        } else {
                            is_loading = false;
                            checked_button.sensitive = true;
                        }
                    });
                } else {
                    Services.Database.get_default ().checked_toggled (item, old_checked);
                }   
            }
            
            return GLib.Source.REMOVE;
        });
    }

    public void update_content (string content = "") {
        content_textview.buffer.text = content;
    }

    public void update_priority (int priority) {
        item.priority = priority;
        
        if (is_creating) {
            priority_button.update_from_item (item);
        } else {
            item.update_async (Constants.INACTIVE, this);
        }
    }

    public void update_due (GLib.DateTime? datetime) {
        item.due.date = datetime == null ? "" : Util.get_default ().get_todoist_datetime_format (datetime);
        print ("Date: %s\n".printf (item.due.date));


        if (item.due.date == "") {
            item.due.reset ();
        }

        if (is_creating) {
            schedule_button.update_from_item (item);
        } else {
            item.update_async (Constants.INACTIVE, this);
        }
    }

    public void set_recurrency (Objects.DueDate duedate) {
        if (item.due.is_recurrency_equal (duedate)) {
            return;
        }

        if (!item.has_due) {
            item.due.date = Util.get_default ().get_todoist_datetime_format (
                Util.get_default ().get_today_format_date ()
            );
        }

        item.due.is_recurring = duedate.is_recurring;
        item.due.recurrency_type = duedate.recurrency_type;
        item.due.recurrency_interval = duedate.recurrency_interval;
        
        if (is_creating) {
            schedule_button.update_from_item (item);
        } else {
            item.update_async (Constants.INACTIVE, this);
        }
    }

    private void update_recurrency () {
        var next_recurrency = Util.get_default ().next_recurrency (item.due.datetime, item.due);
        item.due.date = Util.get_default ().get_todoist_datetime_format (
            next_recurrency
        );

        if (item.project.backend_type == BackendType.TODOIST) {
            checked_button.sensitive = false;
            is_loading = true;
            Services.Todoist.get_default ().update.begin (item, (obj, res) => {
                if (Services.Todoist.get_default ().update.end (res)) {
                    Services.Database.get_default ().update_item (item);
                    is_loading = false;
                    checked_button.sensitive = true;
                    recurrency_update_complete (next_recurrency);
                } else {
                    is_loading = false;
                    checked_button.sensitive = true;
                }
            });
        } else {
            Services.Database.get_default ().update_item (item);
            recurrency_update_complete (next_recurrency);
        }  
    }

    private void recurrency_update_complete (GLib.DateTime next_recurrency) {
        checked_button.active = false;
        complete_timeout = 0;
        handle_grid.remove_css_class ("complete-animation");
        content_label.remove_css_class ("dim-label");
        content_label.remove_css_class ("line-through");

        var title = _("Completed. Next occurrence: %s".printf (Util.get_default ().get_default_date_format_from_date (next_recurrency)));
        var toast = Util.get_default ().create_toast (title, 3);

        Planner.event_bus.send_notification (toast);
    }

    public void update_labels (Gee.HashMap <string, Objects.Label> labels) {
        if (is_creating) {
            item.update_local_labels (labels);
            item_labels.update_labels ();
        } else {
            item.update_labels_async (labels, this);
        }
    }

    public void delete_request (bool undo = true) {
        main_revealer.reveal_child = false;

        if (undo) {
            delete_undo ();
        } else {
            if (item.project.backend_type == BackendType.TODOIST) {
                is_loading = true;
                Services.Todoist.get_default ().delete.begin (item, (obj, res) => {
                    if (Services.Todoist.get_default ().delete.end (res)) {
                        Services.Database.get_default ().delete_item (item);
                    } else {
                        is_loading = false;
                    }
                });
            } else {
                Services.Database.get_default ().delete_item (item);
            }
        }
    }

    private void delete_undo () {
        var toast = new Adw.Toast (_("The task was deleted"));
        toast.button_label = _("Undo");
        toast.priority = Adw.ToastPriority.HIGH;
        toast.timeout = 3;

        Planner.event_bus.send_notification (toast);

        uint delete_timeout = 0;
        delete_timeout = Timeout.add (toast.timeout * 1000, () => {
            if (item.project.backend_type == BackendType.TODOIST) {
                is_loading = true;
                Services.Todoist.get_default ().delete.begin (item, (obj, res) => {
                    if (Services.Todoist.get_default ().delete.end (res)) {
                        Services.Database.get_default ().delete_item (item);
                    } else {
                        is_loading = false;
                    }
                });
            } else {
                Services.Database.get_default ().delete_item (item);
            }
            
            return GLib.Source.REMOVE;
        });

        toast.button_clicked.connect (() => {
            main_revealer.reveal_child = true;
            if (delete_timeout != 0) {
                GLib.Source.remove (delete_timeout);
            }
        });
    }

    public void move (string project_id, string section_id) {
        if (is_creating) {
            item.project_id = project_id;
            item.section_id = section_id;
            // project_button.update_request ();
        } else {
            if (item.project_id != project_id || item.section_id != section_id) {
                if (item.project.backend_type == BackendType.TODOIST) {
                    is_loading = true;

                    string move_id = project_id;
                    string move_type = "project_id";
                    if (section_id != "") {
                        move_type = "section_id";
                        move_id = section_id;
                    }

                    Services.Todoist.get_default ().move_item.begin (item, move_type, move_id, (obj, res) => {
                        if (Services.Todoist.get_default ().move_item.end (res)) {
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
    }

    private void move_item (string project_id, string section_id) {
        string old_project_id = item.project_id;
        string old_section_id = item.section_id;

        item.project_id = project_id;
        item.section_id = section_id;

        Services.Database.get_default ().update_item (item);
        Planner.event_bus.item_moved (item, old_project_id, old_section_id);
    }

    private void build_drag_and_drop () {
        drag_source = new Gtk.DragSource ();
        drag_source.set_actions (Gdk.DragAction.MOVE);
        
        drag_source.prepare.connect ((source, x, y) => {
            return new Gdk.ContentProvider.for_value (this);
        });

        drag_source.drag_begin.connect ((source, drag) => {
            var paintable = new Gtk.WidgetPaintable (handle_grid);
            source.set_icon (paintable, 0, 0);
            drag_begin ();
        });
        
        drag_source.drag_end.connect ((source, drag, delete_data) => {
            drag_end ();
        });

        drag_source.drag_cancel.connect ((source, drag, reason) => {
            drag_end ();
            return false;
        });

        add_controller (drag_source);

        drop_target = new Gtk.DropTarget (typeof (Layouts.ItemRow), Gdk.DragAction.MOVE);
        drop_target.preload = true;

        drop_target.on_drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ItemRow) value;
            var target_widget = this;
            
            Gtk.Allocation alloc;
            target_widget.get_allocation (out alloc);

            picked_widget.drag_end ();
            target_widget.drag_end ();

            if (picked_widget == target_widget || target_widget == null) {
                return false;
            }

            var source_list = (Gtk.ListBox) picked_widget.parent;
            var target_list = (Gtk.ListBox) target_widget.parent;

            source_list.remove (picked_widget);
            
            if (target_widget.get_index () == 0) {
                if (y < (alloc.height / 2)) {
                    target_list.insert (picked_widget, 0);
                } else {
                    target_list.insert (picked_widget, target_widget.get_index () + 1);
                }
            } else {
                target_list.insert (picked_widget, target_widget.get_index () + 1);
            }

            return true;
        });

        add_controller (drop_target);
    }

    private void disable_drag_and_drop () {
        remove_controller (drag_source);
        remove_controller (drop_target);
    }

    public void drag_begin () {
        handle_grid.add_css_class ("card");
        on_drag = true;
        opacity = 0.3;
    }

    public void drag_end () {
        handle_grid.remove_css_class ("card");
        on_drag = false;
        opacity = 1;
    }
}