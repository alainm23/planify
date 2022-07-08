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

public class Dialogs.Item : Hdy.Window {
    public Objects.Item item { get; construct; }

    private Widgets.SourceView content_textview;
    private Widgets.ItemLabels item_labels;
    private Gtk.Button priority_button;
    private Gtk.Button status_button;

    public bool is_creating {
        get {
            return item.id == Constants.INACTIVE;
        }
    }

    public Item.new () {
        var item = new Objects.Item ();
        item.id = Constants.INACTIVE;

        Object (
            item: item,
            deletable: true,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            width_request: 525
        );
    }

    public Item (Objects.Item item) {
        Object (
            item: item,
            deletable: true,
            resizable: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            width_request: 525
        );
    }

    construct {
        unowned Gtk.StyleContext main_context = get_style_context ();
        main_context.add_class ("picker");

        transient_for = Planner.instance.main_window;

        var headerbar = new Hdy.HeaderBar () {
            hexpand = true
        };
        headerbar.has_subtitle = false;
        headerbar.show_close_button = true;
        headerbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var menu_image = new Widgets.DynamicIcon ();
        menu_image.size = 19;
        menu_image.update_icon_name ("dots-horizontal");
        
        var menu_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false
        };

        menu_button.add (menu_image);
        menu_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true
        };

        action_box.pack_end (menu_button, false, false, 0);

        headerbar.custom_title = action_box;

        content_textview = new Widgets.SourceView ();
        content_textview.hexpand = true;
        content_textview.height_request = 16;
        content_textview.left_margin = 6;
        content_textview.right_margin = 6;
        content_textview.top_margin = 3;
        content_textview.bottom_margin = 3;
        content_textview.wrap_mode = Gtk.WrapMode.WORD;
        // content_textview.get_style_context ().add_class ("font-bold");

        var content_scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true
        };
        content_scrolled.add (content_textview);

        var textview_content = new Dialogs.Settings.SettingsContent (null);
        textview_content.add_child (content_scrolled);

        /*
        *   Tags
        */

        var tag_image = new Widgets.DynamicIcon ();
        tag_image.size = 16;
        tag_image.update_icon_name ("planner-tag");

        var tag_label = new Gtk.Label (_("Label"));
        // tag_label.get_style_context ().add_class ("font-bold");

        var tag_grid = new Gtk.Grid () {
            column_spacing = 6,
            valign = Gtk.Align.START
        };

        tag_grid.add (tag_image);
        tag_grid.add (tag_label);

        item_labels = new Widgets.ItemLabels (item);

        /*
        *   Priority
        */

        var priority_image = new Widgets.DynamicIcon ();
        priority_image.size = 16;
        priority_image.update_icon_name ("planner-flag");

        var priority_label = new Gtk.Label (_("Priority"));
        // priority_label.get_style_context ().add_class ("font-bold");

        var priority_grid = new Gtk.Grid () {
            column_spacing = 6,
            valign = Gtk.Align.CENTER
        };

        priority_grid.add (priority_image);
        priority_grid.add (priority_label);

        priority_button = new Gtk.Button () {
            halign = Gtk.Align.START,
            can_focus = false
        };
        priority_button.get_style_context ().add_class ("priority-button");
        priority_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        /*
        *   Status
        */

        var status_image = new Widgets.DynamicIcon ();
        status_image.size = 16;
        status_image.update_icon_name ("planner-flag");

        var status_label = new Gtk.Label (_("Status"));
        // status_label.get_style_context ().add_class ("font-bold");

        var status_grid = new Gtk.Grid () {
            column_spacing = 6,
            valign = Gtk.Align.CENTER
        };

        status_grid.add (status_image);
        status_grid.add (status_label);
        
        status_button = new Gtk.Button () {
            halign = Gtk.Align.START,
            can_focus = false
        };
        status_button.get_style_context ().add_class ("priority-button");
        status_button.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);
        Util.get_default ().set_widget_color ("@text_color", status_button);

        var actions_grid = new Gtk.Grid () {
            column_spacing = 24,
            row_spacing = 12,
            margin = 3
        };
        actions_grid.attach (tag_grid, 0, 0, 1, 1);
        actions_grid.attach (item_labels, 1, 0, 1, 1);
        actions_grid.attach (priority_grid, 0, 1, 1, 1);
        actions_grid.attach (priority_button, 1, 1, 1, 1);
        actions_grid.attach (status_grid, 0, 2, 1, 1);
        actions_grid.attach (status_button, 1, 2, 1, 1);

        var actions_content = new Dialogs.Settings.SettingsContent (null);
        actions_content.add_child (actions_grid);

        var content_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            valign = Gtk.Align.START,
            expand = true
        };

        content_grid.add (textview_content);
        content_grid.add (actions_content);

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            expand = true
        };

        main_grid.add (headerbar);
        // main_grid.add (action_box);
        main_grid.add (content_grid);

        add (main_grid);
        update_request ();

        Timeout.add (225, () => {
            content_textview.wrap_mode = Gtk.WrapMode.WORD;
            return GLib.Source.REMOVE;
        });

        priority_button.clicked.connect (open_priority_picker);

        motion_notify_event.connect ((event) => {
            Planner.event_bus.x_root = (int) Math.rint (event.x_root);
            Planner.event_bus.y_root = (int) Math.rint (event.y_root);
            return false;
        });

        item.updated.connect (() => {
            update_request ();
        });

        item_labels.labels_changed.connect (update_labels);
    }

    public void update_request () {
        //  if (complete_timeout <= 0) {
        //      Util.get_default ().set_widget_priority (item.priority, checked_button);
        //      checked_button.active = item.completed;

        //      if (item.completed && Planner.settings.get_boolean ("underline-completed-tasks")) {
        //          content_label.get_style_context ().add_class ("line-through");
        //      } else if (item.completed && !Planner.settings.get_boolean ("underline-completed-tasks")) {
        //          content_label.get_style_context ().remove_class ("line-through");
        //      }
        //  }

        // content_label.label = item.content;
        // content_label.tooltip_text = item.content;
        content_textview.buffer.text = item.content;
        Util.get_default ().set_widget_color (item.priority_color, priority_button);

        priority_button.label = item.priority_text;

        if (item.section_id != Constants.INACTIVE) {
            status_button.label = item.section.name;
        } else {
            status_button.label = _("None");
        }

        item_labels.update_labels ();
        //  description_textview.set_text (item.description);
                
        //  item_summary.update_request ();
        //  schedule_button.update_request (item, null);
        //  priority_button.update_request (item, null);
        //  project_button.update_request ();
        //  pin_button.update_request ();

        //  if (!edit) {
        //      item_summary.check_revealer ();
        //  }
    }

    private void open_priority_picker () {
        var menu = new Dialogs.ContextMenu.Menu ();

        var priority_1_item = new Dialogs.ContextMenu.MenuItem (_("Priority 1: high"), "planner-priority-1");
        var priority_2_item = new Dialogs.ContextMenu.MenuItem (_("Priority 2: medium"), "planner-priority-2");
        var priority_3_item = new Dialogs.ContextMenu.MenuItem (_("Priority 3: low"), "planner-priority-3");
        var priority_4_item = new Dialogs.ContextMenu.MenuItem (_("Priority 4: none"), "planner-flag");

        menu.add_item (priority_1_item);
        menu.add_item (priority_2_item);
        menu.add_item (priority_3_item);
        menu.add_item (priority_4_item);

        menu.popup ();

        priority_1_item.clicked.connect (() => {
            menu.hide_destroy ();
            priority_changed (Constants.PRIORITY_1);
        });

        priority_2_item.clicked.connect (() => {
            menu.hide_destroy ();
            priority_changed (Constants.PRIORITY_2);
        });

        priority_3_item.clicked.connect (() => {
            menu.hide_destroy ();
            priority_changed (Constants.PRIORITY_3);
        });

        priority_4_item.clicked.connect (() => {
            menu.hide_destroy ();
            priority_changed (Constants.PRIORITY_4);
        });
    }
    
    private void priority_changed (int priority) {
        if (item.priority != priority) {
            item.priority = priority;

            if (is_creating) {
                // priority_button.update_request (item, null);
            } else {
                if (item.project.todoist) {
                    item.update_async (Constants.INACTIVE, null);
                } else {
                    item.update_local ();
                }
            }
        }
    }

    public void update_labels (Gee.HashMap <string, Objects.Label> labels) {
        if (is_creating) {
            // item.update_local_labels (labels);
            // item_labels.update_labels ();
        } else {
            item.update_labels_async (labels, null);
        }
    }
}