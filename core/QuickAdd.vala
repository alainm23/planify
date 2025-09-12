/*
 * Copyright © 2023 Alain M. (https://github.com/alainm23/planify)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Alain M. <alainmh23@gmail.com>
 */

public class Layouts.QuickAdd : Adw.Bin {
    public bool is_window_quick_add { get; construct; }
    public Objects.Item item { get; set; }

    private Gtk.Entry content_entry;
    private Widgets.LoadingButton submit_button;
    private Widgets.TextView description_textview;
    private Widgets.ItemLabels item_labels;
    private Widgets.ProjectPicker.ProjectPickerButton project_picker_button;
    private Widgets.ScheduleButton schedule_button;
    private Widgets.PriorityButton priority_button;
    private Widgets.ReminderPicker.ReminderButton reminder_button;
    private Widgets.LabelPicker.LabelButton label_button;
    private Gtk.Image added_image;
    private Gtk.Stack main_stack;
    private Gtk.ToggleButton create_more_button;
    private Gtk.Revealer info_revealer;
    private Gtk.Overlay animation_overlay;
    private Gtk.Fixed animation_container;

    public signal void hide_destroy ();
    public signal void send_interface_id (string id);
    public signal void add_item_db (Objects.Item item, Gee.ArrayList<Objects.Reminder> reminders);
    public signal void error (HttpResponse response);
    public signal void parent_can_close (bool active);

    public bool ctrl_pressed { get; set; default = false; }
    public bool labels_picker_activate_shortcut { get; set; default = false; }
    public bool project_picker_activate_shortcut { get; set; default = false; }
    public bool reminder_picker_activate_shortcut { get; set; default = false; }

    public const string SHORTCUTS_KEY_LABELS = "@";
    public const string SHORTCUTS_KEY_PROJECTS = "#";
    public const string SHORTCUTS_KEY_REMINDERS = "!";

    private Gee.HashMap<string, GLib.Regex> shortcuts_regex_map = new Gee.HashMap<string, GLib.Regex> ();

    public int position { get; set; default = -1; }
    public NewTaskPosition new_task_position { get; set; default = Services.Settings.get_default ().get_new_task_position (); }

    public bool is_loading {
        set {
            submit_button.is_loading = value;
        }
    }

    public QuickAdd (bool is_window_quick_add = false) {
        Object (
            is_window_quick_add: is_window_quick_add
        );
    }

    ~QuickAdd () {
        print ("Destroying Layouts.QuickAdd\n");
    }

    construct {
        item = new Objects.Item ();
        item.project_id = Services.Settings.get_default ().settings.get_string ("local-inbox-project-id");
        item.priority = Util.get_default ().get_default_priority ();

        if (Services.Settings.get_default ().settings.get_boolean ("quick-add-save-last-project")) {
            var project = Services.Store.instance ().get_project (Services.Settings.get_default ().settings.get_string ("quick-add-project-selected"));

            if (project != null) {
                item.project_id = project.id;
            }
        }

        var info_button = new Gtk.MenuButton () {
            popover = build_tip_popover (),
            child = new Gtk.Image.from_icon_name ("dialog-information-symbolic")
        };
        info_button.add_css_class ("flat");

        var headerbar = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (null),
            hexpand = true,
            css_classes = { "flat" }
        };

        headerbar.pack_end (info_button);

        content_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = _("To-do name"),
            has_frame = false
        };

        var info_icon = new Gtk.Image.from_icon_name ("info-outline-symbolic") {
            css_classes = { "error" },
            tooltip_text = _("This field is required")
        };

        info_revealer = new Gtk.Revealer () {
            child = info_icon,
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            valign = Gtk.Align.CENTER,
            hexpand = true,
            margin_top = 9,
            margin_bottom = 9,
            margin_start = 12,
            margin_end = 12
        };

        content_box.append (content_entry);
        content_box.append (info_revealer);

        description_textview = new Widgets.TextView () {
            left_margin = 14,
            right_margin = 6,
            top_margin = 12,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            event_focus = false,
            accepts_tab = false,
            placeholder_text = _("Add a description…")
        };

        description_textview.remove_css_class ("view");

        var description_scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = NEVER,
            max_content_height = 200,
            propagate_natural_height = false,
            child = description_textview
        };

        item_labels = new Widgets.ItemLabels (item) {
            margin_start = 12,
            top_margin = 12
        };

        schedule_button = new Widgets.ScheduleButton ();
        priority_button = new Widgets.PriorityButton () {
            tooltip_markup = Util.get_default ().markup_accels_tooltip (_("Set The Priority"), { "p1", "p2", "p3", "p4" }),
        };
        priority_button.update_from_item (item);

        label_button = new Widgets.LabelPicker.LabelButton () {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Add Labels"), "@"),
        };
        label_button.source = item.project.source;

        reminder_button = new Widgets.ReminderPicker.ReminderButton (true) {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Add Reminders"), "!"),
        };

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6,
            margin_top = 6
        };

        var action_box_right = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            halign = Gtk.Align.END
        };

        action_box_right.append (label_button);
        action_box_right.append (reminder_button);
        action_box_right.append (priority_button);

        action_box.append (schedule_button);
        action_box.append (action_box_right);

        var quick_add_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
        };
        quick_add_content.add_css_class ("card");
        quick_add_content.add_css_class ("sidebar-card");
        quick_add_content.append (content_box);
        quick_add_content.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        quick_add_content.append (description_scrolled);
        quick_add_content.append (item_labels);
        quick_add_content.append (action_box);

        submit_button = new Widgets.LoadingButton (LoadingButtonType.LABEL, _("Add")) {
            valign = CENTER,
            css_classes = { "suggested-action", "border-radius-6" }
        };

        create_more_button = new Gtk.ToggleButton () {
            css_classes = { "flat", "keep-adding-button" },
            tooltip_text = _("Keep adding"),
            icon_name = "arrow-turn-down-right-symbolic",
            active = Services.Settings.get_default ().settings.get_boolean ("quick-add-create-more")
        };

        var submit_cancel_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            halign = END
        };

        submit_cancel_grid.append (create_more_button);
        submit_cancel_grid.append (submit_button);

        project_picker_button = new Widgets.ProjectPicker.ProjectPickerButton () {
            tooltip_markup = Util.get_default ().markup_accel_tooltip (_("Select a Project"), "#"),
        };
        project_picker_button.project = item.project;

        var footer_content = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };

        footer_content.append (project_picker_button);
        footer_content.append (submit_cancel_grid);

        var main_content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_content.append (headerbar);
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

        added_image = new Gtk.Image.from_icon_name ("check-round-outline-symbolic") {
            pixel_size = 64
        };

        var added_box = new Gtk.Box (VERTICAL, 6);
        added_box.halign = Gtk.Align.CENTER;
        added_box.valign = Gtk.Align.CENTER;
        added_box.append (added_image);

        main_stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.CROSSFADE
        };
        main_stack.add_named (main_content, "main");
        main_stack.add_named (warning_box, "warning");
        main_stack.add_named (added_box, "added");

        animation_container = new Gtk.Fixed () {
            can_target = false
        };
        animation_overlay = new Gtk.Overlay ();

        var window = new Gtk.WindowHandle ();
        animation_overlay.set_child (main_stack);
        animation_overlay.add_overlay (animation_container);
        window.set_child (animation_overlay);

        child = window;

        Timeout.add (225, () => {
            if (Services.Store.instance ().is_database_empty ()) {
                main_stack.visible_child_name = "warning";
            } else {
                main_stack.visible_child_name = "main";
                content_entry.grab_focus ();
            }

            return GLib.Source.REMOVE;
        });

        submit_button.clicked.connect (add_item);

        project_picker_button.project_change.connect ((project) => {
            bool project_change = item.project_id != project.id;
            item.project_id = project.id;
            label_button.source = project.source;

            if (Services.Settings.get_default ().settings.get_boolean ("quick-add-save-last-project")) {
                Services.Settings.get_default ().settings.set_string ("quick-add-project-selected", project.id);
            }
        });

        project_picker_button.section_change.connect ((section) => {
            if (section == null) {
                item.section_id = "";
            } else {
                item.section_id = section.id;
            }
        });

        project_picker_button.picker_opened.connect ((active) => {
            parent_can_close (!active);

            if (!active) {
                Timeout.add (250, () => {
                    if (project_picker_activate_shortcut) {
                        entry_focus ();
                    }

                    project_picker_activate_shortcut = false;
                    return GLib.Source.REMOVE;
                });
            }
        });

        schedule_button.duedate_changed.connect (() => {
            set_duedate (schedule_button.duedate);
        });

        schedule_button.picker_opened.connect ((active) => {
            parent_can_close (!active);
        });

        priority_button.changed.connect ((priority) => {
            set_priority (priority);
        });

        priority_button.picker_opened.connect ((active) => {
            parent_can_close (!active);
        });

        label_button.labels_changed.connect (set_labels);

        label_button.picker_opened.connect ((active) => {
            parent_can_close (!active);

            if (!active) {
                Timeout.add (250, () => {
                    if (labels_picker_activate_shortcut) {
                        entry_focus ();
                    }

                    labels_picker_activate_shortcut = false;
                    return GLib.Source.REMOVE;
                });
            }
        });

        reminder_button.picker_opened.connect ((active) => {
            parent_can_close (!active);

            if (!active) {
                Timeout.add (250, () => {
                    if (reminder_picker_activate_shortcut) {
                        entry_focus ();
                    }

                    reminder_picker_activate_shortcut = false;
                    return GLib.Source.REMOVE;
                });
            }
        });

        var destroy_controller = new Gtk.EventControllerKey ();
        add_controller (destroy_controller);
        destroy_controller.key_released.connect ((keyval, keycode, state) => {
            if (keyval == Gdk.Key.Escape) {
                hide_destroy ();
            }
        });

        content_entry.activate.connect (() => {
            add_item ();
        });

        content_entry.changed.connect (() => {
            info_revealer.reveal_child = false;
            content_entry.remove_css_class ("error");
            handle_priority_shortcut (content_entry.get_text ());
            handle_text_trigger (SHORTCUTS_KEY_LABELS, content_entry.get_text ());
            handle_text_trigger (SHORTCUTS_KEY_PROJECTS, content_entry.get_text ());
            handle_text_trigger (SHORTCUTS_KEY_REMINDERS, content_entry.get_text ());
        });

        var content_controller_key = new Gtk.EventControllerKey ();
        content_entry.add_controller (content_controller_key);
        content_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == Gdk.Key.Return && ctrl_pressed) {
                add_item ();
            }

            return false;
        });

        var description_controller_key = new Gtk.EventControllerKey ();
        description_textview.add_controller (description_controller_key);
        description_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            if (ctrl_pressed && keyval == Gdk.Key.Return) {
                add_item ();
            }

            return false;
        });

        var event_controller_key = new Gtk.EventControllerKey ();
        ((Gtk.Widget) this).add_controller (event_controller_key);
        event_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == Gdk.Key.Control_L || keyval == Gdk.Key.Control_R) {
                ctrl_pressed = true;
                create_more_button.active = ctrl_pressed;
            }

            return false;
        });

        event_controller_key.key_released.connect ((keyval, keycode, state) => {
            if (keyval == Gdk.Key.Control_L || keyval == Gdk.Key.Control_R) {
                ctrl_pressed = false;
                create_more_button.active = ctrl_pressed;
            }
        });

        create_more_button.activate.connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("quick-add-create-more", create_more_button.active);
        });

        var open_label_shortcut = new Gtk.Shortcut (Gtk.ShortcutTrigger.parse_string ("<Control>l"), new Gtk.CallbackAction (() => {
            label_button.open_picker ();
        }));

        var open_reminder_shortcut = new Gtk.Shortcut (Gtk.ShortcutTrigger.parse_string ("<Control>r"), new Gtk.CallbackAction (() => {
            reminder_button.open_picker ();
        }));

        var shortcutController = new Gtk.ShortcutController ();
        shortcutController.add_shortcut (open_label_shortcut);
        shortcutController.add_shortcut (open_reminder_shortcut);

        add_controller (shortcutController);
    }

    private void add_item () {
        info_revealer.reveal_child = false;
        content_entry.remove_css_class ("error");

        if (content_entry.get_text ().length <= 0 && description_textview.get_text ().length <= 0) {
            hide_destroy ();
            return;
        }

        if (content_entry.get_text ().length <= 0) {
            Timeout.add (info_revealer.transition_duration, () => {
                info_revealer.reveal_child = true;
                content_entry.add_css_class ("error");
                return GLib.Source.REMOVE;
            });

            return;
        }

        item.content = content_entry.get_text ();
        item.description = description_textview.get_text ();
        item.child_order = generate_child_order ();

        if (item.project.source_type == SourceType.LOCAL) {
            item.id = Util.get_default ().generate_id ();
            _add_item (item);
            return;
        }

        if (item.project.source_type == SourceType.TODOIST) {
            is_loading = true;
            Services.Todoist.get_default ().add.begin (item, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().add.end (res);
                is_loading = false;

                if (response.status) {
                    item.id = response.data;
                    _add_item (item);
                } else {
                    error (response);
                }
            });

            return;
        }

        if (item.project.source_type == SourceType.CALDAV) {
            is_loading = true;
            item.id = Util.get_default ().generate_id ();
            var caldav_client = Services.CalDAV.Core.get_default ().get_client (item.project.source);
            caldav_client.add_item.begin (item, false, (obj, res) => {
                HttpResponse response = caldav_client.add_item.end (res);
                is_loading = false;

                if (response.status) {
                    _add_item (item);
                } else {
                    error (response);
                }
            });

            return;
        }
    }

    private void _add_item (Objects.Item item) {
        add_item_db (item, reminder_button.reminders ());

        if (item.has_parent) {
            item.parent.collapsed = true;
        }
    }

    public void added_successfully () {
        main_stack.visible_child_name = "added";
        added_image.add_css_class ("fancy-turn-animation");
        bool create_more = create_more_button.active;

        Timeout.add (750, () => {
            if (create_more) {
                main_stack.visible_child_name = "main";
                added_image.remove_css_class ("fancy-turn-animation");

                reset_item ();

                content_entry.text = "";
                description_textview.set_text ("");
                schedule_button.reset ();
                priority_button.reset ();
                label_button.reset ();
                item_labels.reset ();

                content_entry.grab_focus ();
            } else {
                hide_destroy ();
            }

            return GLib.Source.REMOVE;
        });
    }

    private void reset_item () {
        string old_project_id = item.project_id;
        string old_section_id = item.section_id;
        string old_parent_id = item.parent_id;

        item = new Objects.Item ();
        item.project_id = old_project_id;
        item.section_id = old_section_id;
        item.parent_id = old_parent_id;

        label_button.source = item.project.source;
    }

    public void update_content (string content = "") {
        content_entry.set_text (content);
    }

    public void set_due (GLib.DateTime ? datetime) {
        item.due.date = datetime == null ? "" : Utils.Datetime.get_todoist_datetime_format (datetime);

        if (item.due.date == "") {
            item.due.reset ();
        }

        schedule_button.update_from_item (item);
    }

    public void set_duedate (Objects.DueDate duedate) {
        item.due = duedate;

        if (!item.has_due) {
            item.due.reset ();
        }

        schedule_button.update_from_item (item);
    }

    public void set_priority (int priority) {
        if (item.priority == priority) {
            return;
        }

        item.priority = priority;
        priority_button.update_from_item (item);
    }

    public void set_labels (Gee.HashMap<string, Objects.Label> new_labels) {
        bool labels_change = false;
        foreach (var entry in new_labels.entries) {
            if (item.get_label (entry.key) == null) {
                item.add_label_if_not_exists (entry.value);
                labels_change = true;
            }
        }

        foreach (var label in item._get_labels ()) {
            if (!new_labels.has_key (label.id)) {
                item.delete_item_label (label.id);
                labels_change = true;
            }
        }

        if (labels_change && labels_picker_activate_shortcut) {
            remove_entry_char ("@");
        }
    }

    private void remove_entry_char (string value) {
        string current_text = content_entry.get_text ();
        int at_position = content_entry.text.index_of (value);
        if (at_position != -1) {
            string before_at = current_text.substring (0, at_position);
            string after_at = current_text.substring (at_position + 1);

            string updated_text = before_at + after_at;
            content_entry.set_text (updated_text);
            entry_focus ();
        }
    }

    private void entry_focus () {
        content_entry.grab_focus ();
        if (content_entry.cursor_position < content_entry.text.length) {
            content_entry.set_position (content_entry.text.length);
        }
    }

    public void for_project (Objects.Project project) {
        item.project_id = project.id;
        project_picker_button.project = project;
        label_button.source = project.source;
    }

    public void for_section (Objects.Section section) {
        item.section_id = section.id;
        item.project_id = section.project_id;

        project_picker_button.project = section.project;
        project_picker_button.section = section;
        label_button.source = section.project.source;
    }

    public void for_parent (Objects.Item _item) {
        item.project_id = _item.project_id;
        item.section_id = _item.section_id;
        item.parent_id = _item.id;

        project_picker_button.project = _item.project;
        label_button.source = _item.project.source;
        project_picker_button.sensitive = false;
    }

    private void handle_priority_shortcut (string text) {
        GLib.MatchInfo match;

        if (!shortcuts_regex_map.has_key ("priority")) {
            try {
                shortcuts_regex_map["priority"] = new GLib.Regex ("(?:^|\\s)(p[1-4])(?:$|\\s)", RegexCompileFlags.MULTILINE);
            } catch (Error e) {
                critical (e.message);
            }
        }

        if (shortcuts_regex_map["priority"].match (text, 0, out match)) {
            string result = match.fetch (1);

            animate_priority_to_button_single (result);

            string new_text = text.replace (result, "");
            content_entry.text = new_text;
            entry_focus ();
        }
    }

    private void handle_text_trigger (string key, string text) {
        GLib.MatchInfo match;

        if (!shortcuts_regex_map.has_key (key)) {
            try {
                shortcuts_regex_map[key] = new GLib.Regex ("(?:^|\\s)(%s)(?:$|\\s)".printf (key), RegexCompileFlags.MULTILINE);
            } catch (Error e) {
                critical (e.message);
            }
        }

        if (shortcuts_regex_map[key].match (text, 0, out match)) {
            string result = match.fetch (1);

            string new_text = text.replace (result, "");
            content_entry.text = new_text;

            if (key == SHORTCUTS_KEY_LABELS) {
                labels_picker_activate_shortcut = true;
                label_button.open_picker ();
            } else if (key == SHORTCUTS_KEY_PROJECTS) {
                project_picker_activate_shortcut = true;
                project_picker_button.open_picker ();
            } else if (key == SHORTCUTS_KEY_REMINDERS) {
                reminder_picker_activate_shortcut = true;
                reminder_button.open_picker (true);
            }
        }
    }

    private void animate_priority_to_button_single (string priority_text) {
        double entry_x, entry_y;
        double button_x, button_y;

        Graphene.Point entry_point;
        if (!content_entry.compute_point (animation_overlay, Graphene.Point (), out entry_point)) {
            return;
        }
        entry_x = entry_point.x;
        entry_y = entry_point.y;

        Graphene.Point button_point;
        if (!priority_button.compute_point (animation_overlay, Graphene.Point (), out button_point)) {
            return;
        }
        button_x = button_point.x;
        button_y = button_point.y;

        var cursor_x_offset = get_cursor_position_in_entry ();

        var start_x = entry_x + cursor_x_offset;
        var start_y = entry_y + content_entry.get_height () / 2;
        var end_x = button_x + priority_button.get_width () / 2;
        var end_y = button_y + priority_button.get_height () / 2;

        var flying_label = new Gtk.Label (priority_text) {
            css_classes = { "priority-flying-label" }
        };

        var priority = ItemPriority.parse (priority_text);

        animation_container.put (flying_label, (int) start_x, (int) start_y);
        Util.get_default ().set_widget_color (
            priority.get_color (),
            flying_label
        );

        var target = new Adw.CallbackAnimationTarget ((progress) => {
            var current_x = (int) lerp (start_x, end_x, progress);
            var current_y = (int) lerp (start_y, end_y, progress);

            animation_container.move (flying_label, current_x, current_y);

            flying_label.opacity = 1.0 - (progress * 0.3);
        });

        var animation = new Adw.TimedAnimation (
            flying_label,
            0.0,
            1.0,
            600,
            target
        );

        animation.easing = Adw.Easing.EASE_OUT_CUBIC;

        animation.done.connect (() => {
            flying_label.add_css_class ("priority-label-impact");
            animation_container.remove (flying_label);
            priority_button.animation ();
            set_priority (priority);
        });

        animation.play ();
    }

    private double get_cursor_position_in_entry () {
        var text = content_entry.get_text ();
        var cursor_pos = content_entry.get_position ();

        var pango_layout = content_entry.create_pango_layout ("");
        pango_layout.set_text (text.substring (0, cursor_pos), -1);
        pango_layout.set_font_description (content_entry.get_pango_context ().get_font_description ());

        int text_width, text_height;
        pango_layout.get_pixel_size (out text_width, out text_height);

        var style_context = content_entry.get_style_context ();
        var padding = style_context.get_padding ();

        return padding.left + text_width;
    }

    private double get_precise_cursor_position () {
        var text = content_entry.get_text ();
        var cursor_pos = content_entry.get_position ();

        var pango_context = content_entry.get_pango_context ();
        var font_desc = pango_context.get_font_description ();

        var layout = new Pango.Layout (pango_context);
        layout.set_font_description (font_desc);
        layout.set_text (text.substring (0, cursor_pos), -1);

        int width, height;
        layout.get_pixel_size (out width, out height);

        // Agregar el padding interno del Entry
        var style_context = content_entry.get_style_context ();
        var padding = style_context.get_padding ();
        var margin = style_context.get_margin ();

        return margin.left + padding.left + width;
    }

    private double lerp (double start, double end, double progress) {
        return start + (end - start) * progress;
    }

    private Gtk.Popover build_tip_popover () {
        var title_label = new Gtk.Label (_("Keyboard Shortcuts")) {
            halign = START,
            valign = END
        };
        title_label.add_css_class ("font-bold");

        var subtitle_label = new Gtk.Label (_("Speed up task creation with these shortcuts")) {
            halign = START,
            valign = START
        };
        subtitle_label.add_css_class ("dimmed");
        subtitle_label.add_css_class ("caption");

        var title_box = new Gtk.Box (VERTICAL, 3);
        title_box.append (title_label);
        title_box.append (subtitle_label);

        var shortcut_box = new Gtk.Box (VERTICAL, 12) {
            margin_top = 12
        };
        shortcut_box.append (build_shortcut_widget ("p1…p4", "#1e63ec", _("Set priority"), _("p1 = highest, p4 = lowest")));
        shortcut_box.append (build_shortcut_widget ("@", "#16af54", _("Add labels"), _("Opens label selector")));
        shortcut_box.append (build_shortcut_widget ("#", "#9141ac", _("Assign project"), _("Opens project selector")));
        shortcut_box.append (build_shortcut_widget ("!", "#fa1955", _("Set reminder"), _("Opens reminder options")));

        var popover_box = new Gtk.Box (VERTICAL, 0) {
            margin_top = 6,
            margin_start = 6,
            margin_end = 6,
            margin_bottom = 6
        };

        popover_box.append (title_box);
        popover_box.append (shortcut_box);
        popover_box.append (new Widgets.ContextMenu.MenuSeparator () {
            margin_top = 3,
            margin_bottom = 3
        });
        popover_box.append (build_shortcut_widget ("⮑", "#1e63ec", _("Keep adding"), _("Stay open after creating task")));
        popover_box.append (new Widgets.ContextMenu.MenuSeparator () {
            margin_top = 3,
            margin_bottom = 3
        });

        popover_box.append (new Gtk.Label ("<b>%s</b>: %s".printf (_("Tip"), _("Combine shortcuts in the title field for faster creation"))) {
            wrap = true,
            halign = START,
            css_classes = { "dimmed", "caption" },
            use_markup = true
        });

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = BOTTOM,
            child = popover_box
        };

        return popover;
    }

    private Gtk.Widget build_shortcut_widget (string shortcut_key, string color, string title, string subtitle) {
        var shortcut_label = new Gtk.Label (shortcut_key) {
            width_chars = 5,
            valign = CENTER
        };
        shortcut_label.add_css_class ("caption");
        shortcut_label.add_css_class ("shortcut-widget");
        Util.get_default ().set_widget_color (color, shortcut_label);

        var title_label = new Gtk.Label (title) {
            halign = START,
            valign = END
        };
        title_label.add_css_class ("caption");
        title_label.add_css_class ("fw-600");

        var subtitle_label = new Gtk.Label (subtitle) {
            halign = START,
            valign = START
        };
        subtitle_label.add_css_class ("dimmed");
        subtitle_label.add_css_class ("caption");

        var grid = new Gtk.Grid () {
            column_spacing = 12
        };
        grid.attach (shortcut_label, 0, 0, 1, 2);
        grid.attach (title_label, 1, 0, 1, 1);
        grid.attach (subtitle_label, 1, 1, 1, 1);

        return grid;
    }
    
    private int generate_child_order () {
        Objects.BaseObject? base_object = null;

        if (item.parent_id != "") {
            base_object = item;
        } else {
            if (item.section_id != "") {
                base_object = item.section;
            } else {
                base_object = item.project;
            }
        }

        if (base_object == null) {
            return 0;
        }

        Gee.ArrayList<Objects.Item> items = Services.Store.instance ().get_items_by_baseobject (base_object);
        items.sort (set_sort_func);

        if (items.size == 0) {
            return 1000;
        }

        int new_order = 1000;

        if (position == -1) {
            if (new_task_position == NewTaskPosition.START) {
                new_order = items[0].child_order / 2;
            } else {
                new_order = items[items.size - 1].child_order + 1000;
            }
        } else if (position == 0) {
            var first = items[0];
            new_order = first.child_order / 2;

            if (new_order == first.child_order) {
                normalize_orders (items);
                return generate_child_order ();
            }
        } else if (position > 0 && position < items.size) {
            var prev = items[position - 1];
            var next = items[position];
            new_order = (prev.child_order + next.child_order) / 2;

            if (new_order == prev.child_order || new_order == next.child_order) {
                normalize_orders (items);
                return generate_child_order ();
            }
        } else if (position >= items.size) {
            new_order = items[items.size - 1].child_order + 1000;
        }

        return new_order;
    }

    private void normalize_orders (Gee.ArrayList<Objects.Item> items) {
        int spacing = 1000;
        int order = spacing;

        foreach (Objects.Item item in items) {
            item.child_order = order;
            order += spacing;
            item.update_async ();
        }
    }

    private int set_sort_func (Objects.Item item1, Objects.Item item2) {
        return item1.child_order - item2.child_order;
    }
}
