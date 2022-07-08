public class Layouts.ItemCard : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    private Gtk.CheckButton checked_button;
    private Gtk.Label content_label;
    private Gtk.Revealer main_revealer;
    private Widgets.ItemSummary item_summary;
    private Gtk.EventBox itemcard_eventbox;

    public ItemCard (Objects.Item item) {
        Object (
            item: item,
            can_focus: false
        );
    }

    construct {
        get_style_context ().add_class ("row");

        checked_button = new Gtk.CheckButton () {
            can_focus = false,
            valign = Gtk.Align.START
        };

        checked_button.get_style_context ().add_class ("priority-color");
        
        content_label = new Gtk.Label (null) {
            hexpand = true,
            xalign = 0,
            wrap = true
        };

        var content_top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            margin_bottom = 3
        };
        content_top_box.pack_start (checked_button, false, false, 0);
        content_top_box.pack_start (content_label, false, true, 6);
        // content_top_box.pack_end (hide_loading_revealer, false, false, 0);

        item_summary = new Widgets.ItemSummary (item) {
            margin_start = 21
        };

        var main_grid = new Gtk.Grid () {
            margin = 3,
            orientation = Gtk.Orientation.VERTICAL
        };
        main_grid.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);

        main_grid.add (content_top_box);
        main_grid.add (item_summary);

        itemcard_eventbox = new Gtk.EventBox ();
        itemcard_eventbox.add_events (
            Gdk.EventMask.BUTTON_PRESS_MASK |
            Gdk.EventMask.BUTTON_RELEASE_MASK
        );
        itemcard_eventbox.add (main_grid);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        
        main_revealer.add (itemcard_eventbox);

        add (main_revealer);
        update_request ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        itemcard_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 1) {
                if (Planner.event_bus.ctrl_pressed) {
                    // Planner.event_bus.select_item (this);
                } else {
                    Planner.event_bus.unselect_all ();

                    Timeout.add (Constants.DRAG_TIMEOUT, () => {
                        if (main_revealer.reveal_child) {
                            open_item ();
                        }
                        return GLib.Source.REMOVE;
                    });
                }
            } else if (evt.type == Gdk.EventType.BUTTON_PRESS && evt.button == 3) {
                activate_menu ();
            }

            return Gdk.EVENT_PROPAGATE;
        });
    }

    public void update_request () {
        // if (complete_timeout <= 0) {
            Util.get_default ().set_widget_priority (item.priority, checked_button);
            checked_button.active = item.completed;

            //  if (item.completed && Planner.settings.get_boolean ("underline-completed-tasks")) {
            //      content_label.get_style_context ().add_class ("line-through");
            //  } else if (item.completed && !Planner.settings.get_boolean ("underline-completed-tasks")) {
            //      content_label.get_style_context ().remove_class ("line-through");
            //  }
        //}

        content_label.label = item.content;
        content_label.tooltip_text = item.content;
        //  content_textview.buffer.text = item.content;
        //  description_textview.set_text (item.description);
                
        item_summary.update_request ();
        item_summary.check_revealer ();
        //  schedule_button.update_request (item, null);
        //  priority_button.update_request (item, null);
        //  project_button.update_request ();
        //  pin_button.update_request ();

        //  if (!edit) {
        //      item_summary.check_revealer ();
        //  }
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }

    private void activate_menu () {
        Planner.event_bus.unselect_all ();

        var menu = new Dialogs.ContextMenu.Menu ();

        var today_item = new Dialogs.ContextMenu.MenuItem (_("Today"), "planner-today");
        today_item.secondary_text = new GLib.DateTime.now_local ().format ("%a");

        var tomorrow_item = new Dialogs.ContextMenu.MenuItem (_("Tomorrow"), "planner-scheduled");
        tomorrow_item.secondary_text = new GLib.DateTime.now_local ().add_days (1).format ("%a");
        
        var no_date_item = new Dialogs.ContextMenu.MenuItem (_("No Date"), "planner-close-circle");

        var labels_item = new Dialogs.ContextMenu.MenuItem (_("Labels"), "planner-tag");
        var reminders_item = new Dialogs.ContextMenu.MenuItem (_("Reminders"), "planner-bell");
        var move_item = new Dialogs.ContextMenu.MenuItem (_("Move"), "chevron-right");

        var complete_item = new Dialogs.ContextMenu.MenuItem (_("Complete"), "planner-check-circle");
        var edit_item = new Dialogs.ContextMenu.MenuItem (_("Edit"), "planner-edit");

        var delete_item = new Dialogs.ContextMenu.MenuItem (_("Delete task"), "planner-trash");
        delete_item.get_style_context ().add_class ("menu-item-danger");

        menu.add_item (today_item);
        menu.add_item (tomorrow_item);
        if (item.has_due) {
            menu.add_item (no_date_item);
        }
        menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
        menu.add_item (labels_item);
        menu.add_item (reminders_item);
        menu.add_item (move_item);
        menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
        menu.add_item (complete_item);
        menu.add_item (edit_item);
        menu.add_item (new Dialogs.ContextMenu.MenuSeparator ());
        menu.add_item (delete_item);

        menu.popup ();

        labels_item.activate_item.connect (() => {
            menu.hide_destroy ();

            var dialog = new Dialogs.LabelPicker.LabelPicker ();
            dialog.item = item;
            
            dialog.labels_changed.connect ((labels) => {
                update_labels (labels);
            });

            dialog.popup ();
        });

        reminders_item.activate_item.connect (() => {
            menu.hide_destroy ();
            var dialog = new Dialogs.ReminderPicker.ReminderPicker (item);
            dialog.popup ();
        });

        move_item.activate_item.connect (() => {
            menu.hide_destroy ();
            
            var picker = new Dialogs.ProjectPicker.ProjectPicker ();
            
            if (item.has_section) {
                picker.section = item.section;
            } else {
                picker.project = item.project;
            }
            
            picker.popup ();

            picker.changed.connect ((project_id, section_id) => {
                move (project_id, section_id);
            });
        });

        today_item.activate_item.connect (() => {
            menu.hide_destroy ();
            update_due (Util.get_default ().get_format_date (new DateTime.now_local ()));
        });

        tomorrow_item.activate_item.connect (() => {
            menu.hide_destroy ();
            update_due (Util.get_default ().get_format_date (new DateTime.now_local ().add_days (1)));
        });

        no_date_item.activate_item.connect (() => {
            menu.hide_destroy ();
            update_due (null);
        });

        complete_item.activate_item.connect (() => {
            menu.hide_destroy ();
            checked_button.active = !checked_button.active;
            // checked_toggled (checked_button.active);
        });

        edit_item.activate_item.connect (() => {
            menu.hide_destroy ();
            // edit = true;
        });

        delete_item.activate_item.connect (() => {
            menu.hide_destroy ();
            delete_request ();
        });
    }

    public void update_due (GLib.DateTime? date) {
        item.due.date = date == null ? "" : Util.get_default ().get_todoist_datetime_format (date);

        // if (is_creating) {
        //     schedule_button.update_request (item, null);
        // } else {
            item.update_async (Constants.INACTIVE, null);
        // }
    }

    public void update_labels (Gee.HashMap <string, Objects.Label> labels) {
        // if (is_creating) {
        //     item.update_local_labels (labels);
        //    item_labels.update_labels ();
        // } else {
            item.update_labels_async (labels, null);
        // }
    }

    public void delete_request () {
        item.delete (null);
    }

    public void open_item () {
        Util.get_default ().open_item_dialog (item);
    }

    public void move (int64 project_id, int64 section_id) {
        //  if (is_creating) {
        //      item.project_id = project_id;
        //      item.section_id = section_id;
        //      project_button.update_request ();
        //  } else {
            if (item.project_id != project_id || item.section_id != section_id) {
                if (item.project.todoist) {
                    // is_loading = true;

                    int64 move_id = project_id;
                    string move_type = "project_id";
                    if (section_id != Constants.INACTIVE) {
                        move_type = "section_id";
                        move_id = section_id;
                    }

                    Planner.todoist.move_item.begin (item, move_type, move_id, (obj, res) => {
                        if (Planner.todoist.move_item.end (res)) {
                            move_item (project_id, section_id);
                            // is_loading = false;
                        } else {
                            main_revealer.reveal_child = true;
                        }
                    });
                } else {
                    move_item (project_id, section_id);
                }
            }
        // }
    }

    private void move_item (int64 project_id, int64 section_id) {
        int64 old_project_id = item.project_id;
        int64 old_section_id = item.section_id;

        item.project_id = project_id;
        item.section_id = section_id;

        Planner.database.update_item (item);
        Planner.event_bus.item_moved (item, old_project_id, old_section_id);
        // project_button.update_request ();
    }
}