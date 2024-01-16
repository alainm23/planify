public class Layouts.QuickAdd : Adw.Bin {
    public bool is_window_quick_add { get; construct; }
    public Objects.Item item { get; construct; }

    private Gtk.Entry content_entry;
    private Widgets.LoadingButton submit_button;
    private Widgets.HyperTextView description_textview;
    private Widgets.ItemLabels item_labels;
    private Widgets.ProjectPicker.ProjectPickerButton project_picker_button;
    private Widgets.ScheduleButton schedule_button;
    private Widgets.PinButton pin_button;
    private Widgets.PriorityButton priority_button;
    private Widgets.LabelPicker.LabelButton label_button;
    private Gtk.Label name_label;
    private Gtk.Image added_image;
    private Gtk.Stack main_stack;

    public signal void hide_destroy ();
    public signal void send_interface_id (string id);
    public signal void add_item_db (Objects.Item item);

    public QuickAdd (bool is_window_quick_add = false) {
        var item = new Objects.Item ();
        item.project_id = Services.Settings.get_default ().settings.get_string ("inbox-project-id");
        
        if (Services.Settings.get_default ().get_new_task_position () == NewTaskPosition.TOP) {
            item.child_order = 0;
            item.custom_order = true;
        }

        Object (
            is_window_quick_add: is_window_quick_add,
            item: item
        );
    }

    construct {
        if (is_window_quick_add &&
            Services.Settings.get_default ().settings.get_boolean ("quick-add-save-last-project")) {
            var project = Services.Database.get_default ().get_project (Services.Settings.get_default ().settings.get_string ("quick-add-project-selected"));
            
            if (project != null) {
                item.project_id = project.id;
            }
        }

        content_entry = new Widgets.Entry () {
            hexpand = true,
            placeholder_text = _("To-do name")
        };

        content_entry.add_css_class (Granite.STYLE_CLASS_FLAT);

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_top = 12,
            margin_start = 12,
            margin_end = 12
        };
        
        content_box.append (content_entry);

        description_textview = new Widgets.HyperTextView (_("Add a description…")) {
            height_request = 64,
            left_margin = 14,
            right_margin = 6,
            top_margin = 6,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true
        };

        description_textview.remove_css_class ("view");

        item_labels = new Widgets.ItemLabels (item) {
            margin_start = 12
        };

        schedule_button = new Widgets.ScheduleButton ();
        pin_button = new Widgets.PinButton (item);
        priority_button = new Widgets.PriorityButton ();
        priority_button.update_from_item (item);
        label_button = new Widgets.LabelPicker.LabelButton (item.project.backend_type);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 3,
            margin_top = 6,
            margin_bottom = 3
        };

        var action_box_right = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 3
        };

        action_box_right.append (label_button);
        action_box_right.append (priority_button);
        action_box_right.append (pin_button);

        action_box.append (schedule_button);
        action_box.append (action_box_right);

        var quick_add_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            vexpand = true
        };
        quick_add_content.add_css_class ("card");
        quick_add_content.add_css_class ("sidebar-card");
        quick_add_content.append (content_box);
        quick_add_content.append (description_textview);
        quick_add_content.append (item_labels);
        quick_add_content.append (action_box);
        
        // Alert Box
        var error_icon = new Widgets.DynamicIcon.from_icon_name ("dialog-warning-symbolic");
        var error_label = new Gtk.Label ("Error de casa");

        var error_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            vexpand = true
        };

        error_box.append (error_icon);
        error_box.append (error_label);

        submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Add To-Do")) {
            valign = CENTER,
            css_classes = { Granite.STYLE_CLASS_SUGGESTED_ACTION, "border-radius-6" }
        };

        var cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            valign = CENTER,
            css_classes = { "border-radius-6" }
        };

        name_label = new Gtk.Label (null);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        var submit_cancel_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            homogeneous = true,
            hexpand = true,
            halign = END
        };
        submit_cancel_grid.append (cancel_button);
        submit_cancel_grid.append (submit_button);
        
        project_picker_button = new Widgets.ProjectPicker.ProjectPickerButton ();
        project_picker_button.project = item.project;

        var footer_content = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_bottom = 12,
            margin_start = 14,
            margin_end = 12
        };

        footer_content.append (project_picker_button);
        footer_content.append (submit_cancel_grid);
        
        var main_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.START
        };
        main_content.append (quick_add_content);
        main_content.append (footer_content);

        var warning_image = new Gtk.Image ();
        warning_image.gicon = new ThemedIcon ("dialog-warning");
        warning_image.pixel_size = 32;

        var warning_label = new Gtk.Label (_("I'm sorry, Quick Add can't find any project available, try creating a project from Planify."));
        warning_label.wrap = true;
        warning_label.max_width_chars = 42;
        warning_label.xalign = 0;

        var warning_box = new Gtk.Box (HORIZONTAL, 12) {
            margin_start = 12
        };
        warning_box.halign = Gtk.Align.CENTER;
        warning_box.valign = Gtk.Align.CENTER;
        warning_box.append (warning_image);
        warning_box.append (warning_label);

        main_stack = new Gtk.Stack () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };

        added_image = new Gtk.Image ();
        added_image.gicon = new ThemedIcon ("planner-completed");
        added_image.pixel_size = 64;

        var added_label = new Gtk.Label (_("To-do added"));

        var added_box = new Gtk.Box (VERTICAL, 0);
        added_box.halign = Gtk.Align.CENTER;
        added_box.valign = Gtk.Align.CENTER;
        added_box.append (added_image);
        added_box.append (added_label);

        main_stack.add_named (main_content, "main");
        main_stack.add_named (warning_box, "warning");
        main_stack.add_named (added_box, "added");

        var window = new Gtk.WindowHandle ();
        window.set_child (main_stack);

        child = window;
        
        Timeout.add (225, () => {
            if (Services.Database.get_default ().is_database_empty ()) {
                main_stack.visible_child_name = "warning";
            } else {
                main_stack.visible_child_name = "main";
                content_entry.grab_focus ();
            }

            return GLib.Source.REMOVE;
        });

        content_entry.activate.connect (add_item);
        submit_button.clicked.connect (add_item);
        cancel_button.clicked.connect (() => {
            hide_destroy ();
        });

        project_picker_button.project_change.connect ((project) => {
            item.project_id = project.id;

            if (Services.Settings.get_default ().settings.get_boolean ("quick-add-save-last-project")) {
                Services.Settings.get_default ().settings.set_string ("quick-add-project-selected", project.id);
            }
        });

        project_picker_button.section_change.connect ((section) => {
            item.section_id = section.id;
        });

        schedule_button.date_changed.connect ((datetime) => {
            set_due (datetime);
        });

        pin_button.changed.connect (() => {
            set_pinned (!item.pinned);
        });

        priority_button.changed.connect ((priority) => {
            set_priority (priority);
        });

        // item_labels.labels_changed.connect (set_labels);
        label_button.labels_changed.connect (set_labels);

        var destroy_controller = new Gtk.EventControllerKey ();
        add_controller (destroy_controller);

        destroy_controller.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });

        Services.EventBus.get_default ().item_added_successfully.connect (() => {
            main_stack.visible_child_name = "added";
            added_image.add_css_class ("fancy-turn-animation");

            Timeout.add (750, () => {
                hide_destroy ();
                return GLib.Source.REMOVE;
            });
        });
    }

    private void add_item () {        
        if (content_entry.buffer.text.length <= 0) {
            hide_destroy ();
            return;
        }

        item.content = content_entry.get_text ();
        item.description = description_textview.get_text ();
        
        submit_button.is_loading = true;

        if (item.project.backend_type == BackendType.LOCAL) {
            item.id = Util.get_default ().generate_id ();
            add_item_db (item);
        } else if (item.project.backend_type == BackendType.TODOIST) {
            Services.Todoist.get_default ().add.begin (item, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().add.end (res);
                submit_button.is_loading = false;

                if (response.status) {
                    item.id = response.data;
                    add_item_db (item);
                } else {
                    debug ("%s", response.error);
                }
            });
        } else if (item.project.backend_type == BackendType.CALDAV) {
            item.id = Util.get_default ().generate_id ();
            Services.CalDAV.get_default ().add_task.begin (item, false, (obj, res) => {
                HttpResponse response = Services.CalDAV.get_default ().add_task.end (res);
                submit_button.is_loading = false;

                if (response.status) {
                    add_item_db (item);
                } else {
                    debug ("%s", response.error);
                }
            });
        }
    }

    public void update_content (string content = "") {
        content_entry.set_text (content);
    }

    public void set_due (GLib.DateTime? datetime) {
        item.due.date = datetime == null ? "" : Util.get_default ().get_todoist_datetime_format (datetime);

        if (item.due.date == "") {
            item.due.reset ();
        }

        schedule_button.update_from_item (item);
    }

    public void set_pinned (bool pinned) {
        item.pinned = pinned;
        pin_button.update_request ();
    }

    public void set_priority (int priority) {
        if (item.priority == priority) {
            return;
        }

        item.priority = priority;
        priority_button.update_from_item (item);
    }

    public void set_labels (Gee.HashMap<string, Objects.Label> new_labels) {
        foreach (var entry in new_labels.entries) {
            if (item.get_label (entry.key) == null) {
                item.add_label_if_not_exists (entry.value);
            }
        }
        
        foreach (var label in item._get_labels ()) {
            if (!new_labels.has_key (label.id)) {
                item.delete_item_label (label.id);
            }
        }
    }

    public void for_project (Objects.Project project) {
        item.project_id = project.id;
        project_picker_button.project = project;
    }

    public void for_section (Objects.Section section) {
        item.section_id = section.id;
        item.project_id = section.project.id;

        project_picker_button.project = section.project;
        project_picker_button.section = section;
    }

    public void for_parent (Objects.Item _item) {
        item.project_id = _item.project_id;
        item.section_id = _item.section_id;
        item.parent_id = _item.id;

        project_picker_button.project = _item.project;
    }

    public void set_index (int index) {
        item.child_order = index;
        item.custom_order = true;
    }
}
