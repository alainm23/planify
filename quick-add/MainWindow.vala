/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public enum ProjectViewStyle {
    LIST,
    BOARD;

    public string to_string () {
        switch (this) {
            case LIST:
                return "list";

            case BOARD:
                return "board";

            default:
                assert_not_reached();
        }
    }
}

public enum ProjectIconStyle {
    PROGRESS,
    EMOJI;

    public string to_string () {
        switch (this) {
            case PROGRESS:
                return "progress";

            case EMOJI:
                return "emoji";

            default:
                assert_not_reached();
        }
    }
}

public enum BackendType {
    NONE = 0,
    LOCAL = 1,
    TODOIST = 2,
    CALDAV = 3;
}

public class MainWindow : Hdy.Window {
    public Objects.Item item { get; set; }

    private Gtk.CheckButton checked_button;
    private Gtk.Entry content_entry;
    private Widgets.HyperTextView description_textview;
    private Widgets.ItemLabels item_labels;

    private Widgets.ScheduleButton schedule_button;
    private Widgets.PinButton pin_button;
    private Widgets.PriorityButton priority_button;
    private Widgets.LabelButton label_button;

    private Widgets.LoadingButton submit_button;
    private Gtk.Button cancel_button;

    public MainWindow (Gtk.Application application) {
        Object (
            application: application,
            resizable: false,
            skip_taskbar_hint: true,
            window_position: Gtk.WindowPosition.CENTER_ALWAYS,
            width_request: 500
        );
    }

    static construct {
        Hdy.init ();

        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/planner");
    }
    
    construct {
        stick ();
        set_keep_above (true);

        item = new Objects.Item ();

        checked_button = new Gtk.CheckButton () {
            can_focus = false,
            valign = Gtk.Align.CENTER
        };
        checked_button.get_style_context ().add_class ("priority-color");
        QuickAddUtil.set_widget_priority (Constants.INACTIVE, checked_button);

        content_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = _("Task name"),
            margin_top = 1
        };

        content_entry.get_style_context ().remove_class ("view");
        content_entry.get_style_context ().add_class ("content-entry");
        content_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            valign = Gtk.Align.CENTER,
            hexpand = true
        };
        content_box.hexpand = true;
        content_box.pack_start (checked_button, false, false, 0);
        content_box.pack_start (content_entry, false, true, 6);

        description_textview = new Widgets.HyperTextView (_("Description")) {
            height_request = 64,
            left_margin = 22,
            right_margin = 6,
            top_margin = 6,
            bottom_margin = 6,
            wrap_mode = Gtk.WrapMode.WORD_CHAR,
            hexpand = true
        };

        description_textview.get_style_context ().remove_class ("view");

        item_labels = new Widgets.ItemLabels (item) {
            margin_start = 21,
            margin_bottom = 6,
            sensitive = !item.completed
        };

        submit_button = new Widgets.LoadingButton ("LABEL", _("Add Task")) {
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

        var submit_cancel_grid = new Gtk.Grid () {
            column_homogeneous = true,
            column_spacing = 6,
            halign = Gtk.Align.START,
            margin_start = 6,
            margin_bottom = 7
        };
        submit_cancel_grid.add (cancel_button);
        submit_cancel_grid.add (submit_button);

        schedule_button = new Widgets.ScheduleButton (item);
        schedule_button.get_style_context ().add_class ("no-padding");

        pin_button = new Widgets.PinButton (item);
        pin_button.get_style_context ().add_class ("no-padding");
        
        priority_button = new Widgets.PriorityButton (item);
        priority_button.get_style_context ().add_class ("no-padding");

        label_button = new Widgets.LabelButton (item);
        label_button.get_style_context ().add_class ("no-padding");

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 20
        };
        
        action_box.pack_start (schedule_button, false, false, 0);
        action_box.pack_end (pin_button, false, false, 0);
        action_box.pack_end (priority_button, false, false, 0);
        action_box.pack_end (label_button, false, false, 0);

        var quick_add_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            margin = 7
        };

        quick_add_grid.get_style_context ().add_class ("card");

        quick_add_grid.add (content_box);
        quick_add_grid.add (description_textview);
        quick_add_grid.add (item_labels);
        quick_add_grid.add (action_box);
        
        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL
        };

        main_grid.add (quick_add_grid);
        main_grid.add (submit_cancel_grid);
        main_grid.get_style_context ().add_class ("main-view");

        add (main_grid);

        pin_button.changed.connect (() => {
            item.pinned = !item.pinned;
            pin_button.update_request ();
        });

        priority_button.changed.connect ((priority) => {
            if (item.priority != priority) {
                item.priority = priority;
                priority_button.update_request ();
            }
        });

        label_button.labels_changed.connect (labels_changed);

        content_entry.activate.connect (add_item);
        submit_button.clicked.connect (add_item);
        cancel_button.clicked.connect (hide_destroy);
    } 

    private void labels_changed (Gee.HashMap <string, Objects.Label> labels) {
        item.update_local_labels (labels);
        item_labels.update_labels ();
    }

    private void add_item () {        
        if (QuickAddUtil.is_input_valid (content_entry)) {
            submit_button.is_loading = true;

            item.content = content_entry.get_text ();
            item.description = description_textview.get_text ();

            if (item.project.todoist) {
                Services.Todoist.get_default ().add_item.begin (item, (obj, res) => {
                    item.id = Services.Todoist.get_default ().add_item.end (res);
                });
            } else {
                item.id = QuickAddUtil.generate_id ();
            }
        } else {
            hide_destroy ();
        }
    }

    public void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}