public class Layouts.ItemBoard : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    private Gtk.CheckButton checked_button; 
    private Gtk.Label content_label;
    private Gtk.Box handle_grid;
    private Gtk.Revealer main_revealer;

    private Widgets.ItemSummary item_summary;

    public uint complete_timeout { get; set; default = 0; }

    public bool is_loading {
        set {
            if (value) {
                // hide_loading_revealer.reveal_child = value;
                // hide_loading_button.is_loading = value;
            } else {
                // hide_loading_button.is_loading = value;
                // hide_loading_revealer.reveal_child = edit;
            }
        }
    }

    private Gtk.DragSource drag_source;
    private Gtk.DropTarget drop_target;

    public ItemBoard (Objects.Item item) {
        Object (
            item: item,
            focusable: false,
            can_focus: true
        );
    }

    public ItemBoard.for_item (Objects.Item _item) {
        var item = new Objects.Item ();
        item.project_id = _item.project_id;
        item.section_id = _item.section_id;

        Object (
            item: item,
            focusable: false,
            can_focus: true
        );
    }

    public ItemBoard.for_project (Objects.Project project) {
        var item = new Objects.Item ();
        item.project_id = project.id;

        Object (
            item: item,
            focusable: false,
            can_focus: true
        );
    }

    public ItemBoard.for_parent (Objects.Item _item) {
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

    public ItemBoard.for_section (Objects.Section section) {
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

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6
        };

        content_box.append (checked_button);
        content_box.append (content_label);

        item_summary = new Widgets.ItemSummary (item, null) {
            margin_start = 24,
            margin_end = 6
        };

        handle_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        handle_grid.append (content_box);
        handle_grid.append (item_summary);
        handle_grid.add_css_class (Granite.STYLE_CLASS_CARD);
        handle_grid.add_css_class ("border-radius-9");

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        
        main_revealer.child = handle_grid;

        child = main_revealer;
        update_request ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;

            if (!item.checked) {                
                build_drag_and_drop ();     
            }

            return GLib.Source.REMOVE;
        });

        var checked_button_gesture = new Gtk.GestureClick ();
        checked_button_gesture.set_button (1);
        checked_button.add_controller (checked_button_gesture);

        checked_button_gesture.pressed.connect (() => {
            checked_button_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
        });  
    }

    public void checked_toggled (bool active, uint? time = null) {
        Services.EventBus.get_default ().unselect_all ();
        bool old_checked = item.checked;

        if (active) {
            complete_item (old_checked, time);
        } else {
            if (complete_timeout != 0) {
                GLib.Source.remove (complete_timeout);
                complete_timeout = 0;
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
        if (Services.Settings.get_default ().settings.get_enum ("complete-task") == 0) {
            timeout = 0;
        }

        if (time != null) {
            timeout = time;
        }

        if (timeout > 0) {
            content_label.add_css_class ("dim-label");
            if (Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")) {
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
        content_label.remove_css_class ("dim-label");
        content_label.remove_css_class ("line-through");

        var title = _("Completed. Next occurrence: %s".printf (Util.get_default ().get_default_date_format_from_date (next_recurrency)));
        var toast = Util.get_default ().create_toast (title, 3);

        Services.EventBus.get_default ().send_notification (toast);
    }

    public void update_request () {
        if (complete_timeout <= 0) {
            Util.get_default ().set_widget_priority (item.priority, checked_button);
            checked_button.active = item.completed;

            if (item.completed && Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")) {
                content_label.add_css_class ("line-through");
            } else if (item.completed && !Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")) {
                content_label.remove_css_class ("line-through");
            }
        }

        content_label.label = item.content;
        content_label.tooltip_text = item.content;
                
        item_summary.update_request ();
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

        drop_target = new Gtk.DropTarget (typeof (Layouts.ItemBoard), Gdk.DragAction.MOVE);
        drop_target.preload = true;

        drop_target.drop.connect ((value, x, y) => {
            var picked_widget = (Layouts.ItemBoard) value;
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

    public void drag_begin () {
        // handle_grid.add_css_class ("card");
        // opacity = 0.3;
    }

    public void drag_end () {
        // handle_grid.remove_css_class ("card");
        // opacity = 1;
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}