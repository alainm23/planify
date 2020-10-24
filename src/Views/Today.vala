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

public class Views.Today : Gtk.EventBox {
    private Gtk.ListBox event_listbox;
    private Gtk.ListBox listbox;
    private Gtk.ListBox overdue_listbox;
    private Gtk.ListBox completed_listbox;
    private Gtk.Revealer completed_revealer;
    private Gtk.Stack view_stack;
    private Gtk.Revealer overdue_revealer;
    private Gtk.ToggleButton reschedule_button;
    private Gtk.Popover reschedule_popover = null;
    private Gtk.Popover popover = null;
    private Gtk.Menu share_menu = null;
    private Gtk.ToggleButton settings_button;
    private Gtk.ModelButton show_completed_button;
    private Gtk.Switch show_completed_switch;
    private Gtk.Label date_label;
    private Gee.HashMap<string, Widgets.EventRow> event_hashmap;
    private Gee.HashMap <string, Widgets.ItemRow> items_loaded;
    private Gee.HashMap <string, Widgets.ItemRow> overdues_loaded;
    public Gee.HashMap<string, Widgets.ItemRow> items_completed_added;
    
    private Gee.ArrayList<Widgets.ItemRow?> items_list;
    private Gee.ArrayList<Widgets.ItemRow?> overdue_list;

    private uint update_events_idle_source = 0;
    private uint timeout = 0;
    private GLib.DateTime date;

    private const Gtk.TargetEntry[] TARGET_ENTRIES = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    construct {
        items_list = new Gee.ArrayList<Widgets.ItemRow?> ();
        overdue_list = new Gee.ArrayList<Widgets.ItemRow?> ();
        
        items_loaded = new Gee.HashMap <string, Widgets.ItemRow> ();
        overdues_loaded = new Gee.HashMap <string, Widgets.ItemRow> ();
        items_completed_added = new Gee.HashMap<string, Widgets.ItemRow> ();

        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.pixel_size = 16;
        icon_image.icon_name = "help-about-symbolic";
        icon_image.get_style_context ().add_class ("today-icon");

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Today")));
        title_label.get_style_context ().add_class ("title-label");
        title_label.use_markup = true;

        date_label = new Gtk.Label (null);
        date_label.valign = Gtk.Align.CENTER;
        date_label.margin_top = 6;
        date_label.use_markup = true;
        update_today_label ();

        var settings_image = new Gtk.Image ();
        settings_image.gicon = new ThemedIcon ("view-more-symbolic");
        settings_image.pixel_size = 14;

        settings_button = new Gtk.ToggleButton ();
        settings_button.valign = Gtk.Align.CENTER;
        settings_button.can_focus = false;
        settings_button.tooltip_text = _("Menu");
        settings_button.image = settings_image;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_end = 36;
        top_box.margin_start = 42;
        top_box.margin_bottom = 6;
        top_box.margin_top = 6;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 0);
        top_box.pack_start (date_label, false, false, 0);
        top_box.pack_end (settings_button, false, false, 0);

        listbox = new Gtk.ListBox ();
        listbox.margin_start = 30;
        listbox.margin_end = 32;
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;
        listbox.margin_top = 6;

        completed_listbox = new Gtk.ListBox ();
        completed_listbox.margin_start = 30;
        completed_listbox.margin_end = 32;
        completed_listbox.valign = Gtk.Align.START;
        completed_listbox.get_style_context ().add_class ("listbox");
        completed_listbox.activate_on_single_click = true;
        completed_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        completed_listbox.hexpand = true;

        completed_revealer = new Gtk.Revealer ();
        completed_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        completed_revealer.add (completed_listbox);
        completed_revealer.reveal_child = Planner.settings.get_boolean ("show-today-completed");

        var overdue_label = new Gtk.Label (_("Overdue"));
        overdue_label.get_style_context ().add_class ("font-bold");
        overdue_label.halign = Gtk.Align.START;

        overdue_listbox = new Gtk.ListBox ();
        overdue_listbox.margin_start = 30;
        overdue_listbox.margin_end = 32;
        overdue_listbox.get_style_context ().add_class ("listbox");
        overdue_listbox.activate_on_single_click = true;
        overdue_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        overdue_listbox.hexpand = true;

        var overdue_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        overdue_separator.hexpand = true;
        overdue_separator.margin_start = 42;
        overdue_separator.margin_end = 40;

        reschedule_button = new Gtk.ToggleButton.with_label (_("Reschedule"));
        reschedule_button.get_style_context ().add_class ("flat");
        reschedule_button.get_style_context ().add_class ("overdue-label");
        reschedule_button.valign = Gtk.Align.CENTER;
        reschedule_button.can_focus = false;

        var overdue_header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        overdue_header_box.margin_start = 42;
        overdue_header_box.margin_end = 40;
        overdue_header_box.pack_start (overdue_label, false, true, 0);
        overdue_header_box.pack_end (reschedule_button, false, false, 0);

        var overdue_container_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        overdue_container_box.margin_top = 24;
        overdue_container_box.add (overdue_header_box);
        overdue_container_box.add (overdue_separator);
        overdue_container_box.add (overdue_listbox);

        overdue_revealer = new Gtk.Revealer ();
        overdue_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        overdue_revealer.add (overdue_container_box);
        overdue_revealer.reveal_child = true;

        var listbox_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        listbox_box.expand = true;
        listbox_box.add (listbox);
        listbox_box.add (completed_revealer);
        listbox_box.add (overdue_revealer);

        var placeholder_view = new Widgets.Placeholder (
            _("What tasks are on your mind?"),
            _("Tap + to add a task for today."),
            icon_image.icon_name
        );
        placeholder_view.reveal_child = true;

        view_stack = new Gtk.Stack ();
        view_stack.expand = true;
        view_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        view_stack.add_named (listbox_box, "listbox");
        view_stack.add_named (placeholder_view, "placeholder");

        event_listbox = new Gtk.ListBox ();
        event_listbox.margin_top = 6;
        event_listbox.margin_start = 44;
        event_listbox.valign = Gtk.Align.START;
        event_listbox.get_style_context ().add_class ("listbox");
        event_listbox.activate_on_single_click = true;
        event_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        event_listbox.hexpand = true;
        event_listbox.set_sort_func (sort_event_function);

        var event_revealer = new Gtk.Revealer ();
        event_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        event_revealer.add (event_listbox);
        event_revealer.reveal_child = Planner.settings.get_boolean ("calendar-enabled");

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.margin_bottom = 3;
        box.margin_end = 3;
        box.pack_start (event_revealer, false, false, 0);
        // box.pack_start (new_item_revealer, false, false, 0);
        box.pack_start (view_stack, true, true, 0);

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.expand = true;
        box_scrolled.add (box);

        var magic_button = new Widgets.MagicButton ();

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (box_scrolled, false, true, 0);

        var overlay = new Gtk.Overlay ();
        overlay.expand = true;
        overlay.add_overlay (magic_button);
        overlay.add (main_box);

        add (overlay);

        add_all_items ();
        add_completed_items ();
        show_all ();
        build_drag_and_drop ();

        magic_button.clicked.connect (() => {
            add_new_item (Planner.settings.get_int ("new-tasks-top"));
        });
        
        // Check Placeholder view
        Timeout.add (125, () => {
            check_placeholder_view ();
            set_sort_func (Planner.settings.get_int ("today-sort-order"));
            return false;
        });

        Planner.event_bus.day_changed.connect (() => {
            update_today_label ();
            add_all_items ();
            add_completed_items ();
        });

        reschedule_button.toggled.connect (() => {
            if (reschedule_button.active) {
                if (reschedule_popover == null) {
                    create_reschedule_popover ();
                }
            }

            reschedule_popover.popup ();
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

        completed_listbox.row_activated.connect ((r) => {
            var row = ((Widgets.ItemRow) r);

            row.reveal_child = true;
            Planner.event_bus.unselect_all ();
        });

        overdue_listbox.row_activated.connect ((r) => {
            var row = ((Widgets.ItemRow) r);

            if (Planner.event_bus.ctrl_pressed) {
                Planner.event_bus.select_item (row);
            } else {
                row.reveal_child = true;
                Planner.event_bus.unselect_all ();
            }
        });

        listbox.remove.connect ((row) => {
            check_placeholder_view ();
        });

        Planner.database.add_due_item.connect ((item) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
            if (Planner.utils.is_today (datetime)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    add_item (item);
                    check_placeholder_view ();
                }
            } else if (Planner.utils.is_overdue (datetime)) {
                if (overdues_loaded.has_key (item.id.to_string ()) == false) {
                    add_overdue_item (item);
                    check_placeholder_view ();
                }
            }
        });

        Planner.database.remove_due_item.connect ((item) => {
            if (items_loaded.has_key (item.id.to_string ())) {
                items_loaded.get (item.id.to_string ()).hide_destroy ();
                items_loaded.unset (item.id.to_string ());

                check_placeholder_view ();
            } else if (overdues_loaded.has_key (item.id.to_string ())) {
                overdues_loaded.get (item.id.to_string ()).hide_destroy ();
                overdues_loaded.unset (item.id.to_string ());
                
                check_placeholder_view ();
            }
        });

        Planner.database.update_due_item.connect ((item, index) => {
            var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());

            if (Planner.utils.is_today (datetime)) {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    add_item (item, index);
                    check_placeholder_view ();
                }
            } else {
                if (items_loaded.has_key (item.id.to_string ())) {
                    items_loaded.get (item.id.to_string ()).hide_destroy ();
                    items_loaded.unset (item.id.to_string ());
                    check_placeholder_view ();
                }
            }

            if (Planner.utils.is_overdue (datetime)) {
                if (overdues_loaded.has_key (item.id.to_string ()) == false) {
                    add_overdue_item (item);
                    check_placeholder_view ();
                }
            } else {
                if (overdues_loaded.has_key (item.id.to_string ())) {
                    overdues_loaded.get (item.id.to_string ()).hide_destroy ();
                    overdues_loaded.unset (item.id.to_string ());
                    check_placeholder_view ();
                }
            }
        });

        Planner.database.item_added.connect ((item, index) => {
            if (item.due_date != "") {
                var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
                if (Planner.utils.is_today (datetime)) {
                    add_item (item, index);
                    check_placeholder_view ();
                } else if (Planner.utils.is_overdue (datetime)) {
                    var row = new Widgets.ItemRow (item, "today");

                    overdues_loaded.set (item.id.to_string (), row);
                    overdue_list.add (row);

                    overdue_listbox.add (row);
                    overdue_listbox.show_all ();

                    check_placeholder_view ();
                    update_item_order ();
                }
            }
        });

        Planner.event_bus.magic_button_activated.connect ((project_id, section_id, is_todoist, index, view, due_date) => {
            if (view == "today") {
                add_new_item (index);
            }
        });

        Planner.database.item_completed.connect ((item) => {
            Idle.add (() => {
                if (items_loaded.has_key (item.id.to_string ())) {
                    items_loaded.get (item.id.to_string ()).hide_destroy ();
                    items_loaded.unset (item.id.to_string ());
                    check_placeholder_view ();
                }

                if (items_completed_added.has_key (item.id.to_string ()) == false) {
                    var row = new Widgets.ItemRow (item);

                    items_completed_added.set (item.id.to_string (), row);
                    completed_listbox.insert (row, 0);
                    completed_listbox.show_all ();
                }

                return false;
            });
        });

        Planner.database.item_uncompleted.connect ((item) => {
            Idle.add (() => {
                if (items_loaded.has_key (item.id.to_string ()) == false) {
                    var datetime = new GLib.DateTime.from_iso8601 (item.due_date, new GLib.TimeZone.local ());
                    if (Planner.utils.is_today (datetime) || Planner.utils.is_overdue (datetime)) {
                        if (items_loaded.has_key (item.id.to_string ()) == false) {
                            add_item (item);
                            check_placeholder_view ();
                        }
                    }
                }

                return false;
            });
        });
        
        date = new GLib.DateTime.now_local ();
        event_hashmap = new Gee.HashMap<string, Widgets.EventRow> ();
        Planner.calendar_model.month_start = Util.get_start_of_month ();

        Planner.calendar_model.events_added.connect (add_event_model);
        Planner.calendar_model.events_removed.connect (remove_event_model);

        idle_update_events ();

        Planner.settings.changed.connect ((key) => {
            if (key == "calendar-enabled") {
                event_revealer.reveal_child = Planner.settings.get_boolean ("calendar-enabled");
            } else if (key == "today-sort-order") {
                set_sort_func (Planner.settings.get_int ("today-sort-order"));
            } else if (key == "show-today-completed") {
                completed_revealer.reveal_child = Planner.settings.get_boolean ("show-today-completed");
            }
        });

        Planner.utils.add_item_show_queue_view.connect ((row, view) => {
            if (view == "today") {
                // items_opened.add (row);
            }
        });

        Planner.utils.remove_item_show_queue_view.connect ((row, view) => {
            if (view == "today") {
                remove_item_show_queue (row);
            }
        });

        settings_button.toggled.connect (() => {
            Planner.event_bus.unselect_all ();
            
            if (settings_button.active) {
                if (popover == null) {
                    create_popover ();
                }

                popover.show_all ();
            }
        });
    }

    private void update_today_label () {
        date_label.label = new GLib.DateTime.now_local ().format (
            Granite.DateTime.get_default_date_format (false, true, false)
        );
    }

    private void create_popover () {
        popover = new Gtk.Popover (settings_button);
        popover.get_style_context ().add_class ("popover-background");
        popover.position = Gtk.PositionType.BOTTOM;

        // var sort_date_menu = new Widgets.ModelButton (_("Sort by date"), "x-office-calendar-symbolic", "");
        var sort_priority_menu = new Widgets.ModelButton (_("Sort by priority"), "edit-flag-symbolic", "");
        var sort_name_menu = new Widgets.ModelButton (_("Sort by name"), "font-x-generic-symbolic", "");
        var sort_project_menu = new Widgets.ModelButton (_("Sort by project"), "planner-project-symbolic", "");
        var share_item = new Widgets.ModelButton (_("Utilities"), "applications-utilities-symbolic", "", true);

        // Show Complete
        var show_completed_image = new Gtk.Image ();
        show_completed_image.gicon = new ThemedIcon ("emblem-default-symbolic");
        show_completed_image.valign = Gtk.Align.START;
        show_completed_image.pixel_size = 16;

        var show_completed_label = new Gtk.Label (_("Show Completed"));
        show_completed_label.hexpand = true;
        show_completed_label.valign = Gtk.Align.START;
        show_completed_label.xalign = 0;
        show_completed_label.margin_start = 9;

        show_completed_switch = new Gtk.Switch ();
        show_completed_switch.margin_start = 12;
        show_completed_switch.get_style_context ().add_class ("planner-switch");
        show_completed_switch.active = Planner.settings.get_boolean ("show-today-completed");

        var show_completed_grid = new Gtk.Grid ();
        show_completed_grid.add (show_completed_image);
        show_completed_grid.add (show_completed_label);
        show_completed_grid.add (show_completed_switch);

        show_completed_button = new Gtk.ModelButton ();
        show_completed_button.get_style_context ().add_class ("popover-model-button");
        show_completed_button.get_child ().destroy ();
        show_completed_button.add (show_completed_grid);

        var popover_grid = new Gtk.Grid ();
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 3;
        popover_grid.margin_bottom = 3;
        popover_grid.add (sort_project_menu);
        popover_grid.add (sort_priority_menu);
        popover_grid.add (sort_name_menu);
        popover_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        });
        popover_grid.add (share_item);
        popover_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        });
        popover_grid.add (show_completed_button);

        popover.add (popover_grid);

        popover.closed.connect (() => {
            settings_button.active = false;
        });

        sort_project_menu.clicked.connect (() => {
            Planner.settings.set_int ("today-sort-order", 1);
            popover.popdown ();
        });

        sort_priority_menu.clicked.connect (() => {
            Planner.settings.set_int ("today-sort-order", 2);
            popover.popdown ();
        });

        sort_name_menu.clicked.connect (() => {
            Planner.settings.set_int ("today-sort-order", 3);
            popover.popdown ();
        });

        share_item.clicked.connect (() => {
            if (share_menu == null) {
                share_menu = new Gtk.Menu ();

                var share_mail = new Widgets.ImageMenuItem (_("Send by e-mail"), "internet-mail-symbolic");
                var share_markdown_menu = new Widgets.ImageMenuItem (_("Share on Markdown"), "planner-markdown-symbolic");
                var hide_items_menu = new Widgets.ImageMenuItem (_("Hide all tasks details"), "view-restore-symbolic");

                share_menu.add (share_mail);
                share_menu.add (share_markdown_menu);
                share_menu.add (hide_items_menu);
                share_menu.show_all ();

                share_mail.activate.connect (() => {
                    share_today_mail ();
                });
        
                share_markdown_menu.activate.connect (() => {
                    share_markdown ();
                });

                hide_items_menu.activate.connect (() => {
                    hide_items ();
                    popover.popdown ();
                });
            }

            share_menu.popup_at_pointer (null);
        });

        show_completed_button.button_release_event.connect (() => {
            show_completed_switch.activate ();
            Planner.settings.set_boolean ("show-today-completed", !show_completed_switch.active);
            check_placeholder_view ();
            return Gdk.EVENT_STOP;
        });
    }

    public void share_today_mail () {
        string uri = "";
        uri += "mailto:?subject=%s&body=%s".printf (_("Today"), to_markdown ());
        try {
            AppInfo.launch_default_for_uri (uri, null);
        } catch (Error e) {
            warning ("%s\n", e.message);
        }
    }

    public void share_markdown () {
        Gtk.Clipboard.get_default (Planner.instance.main_window.get_display ()).set_text (to_markdown (), -1);
        Planner.notifications.send_notification (
            _("Today was copied to the Clipboard.")
        );
    }

    private string to_markdown () {
        string text = "";
        text += "# %s\n".printf (_("Today"));

        foreach (var item in Planner.database.get_all_today_items ()) {
            text += "- [ ] %s\n".printf (item.content);
        }

        return text;
    }

    private void set_sort_func (int order) {
        listbox.set_sort_func ((row1, row2) => {
            if (row1 is Widgets.ItemRow && row2 is Widgets.ItemRow) {
                var item1 = ((Widgets.ItemRow) row1).item;
                var item2 = ((Widgets.ItemRow) row2).item;

                if (order == 0) {
                    return 0;
                } else if (order == 1) {
                    if (item1.project_id == item2.project_id) {
                        return 1;
                    }

                    if (item1.project_id != item2.project_id) {
                        return -1;
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
            } else {
                return 0;
            }
        });

        listbox.set_sort_func (null);
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect (on_drag_data_received);
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
            source.get_parent ().remove (source);
            items_list.remove (source);

            var due = new GLib.DateTime.from_iso8601 (source.item.due_date, new GLib.TimeZone.local ());
            if (Planner.utils.is_today (due) == false) {
                source.item.due_date = new GLib.DateTime.now_local ().to_string ();

                Planner.database.set_due_item (source.item, false, target.get_index () + 1);
                if (source.item.is_todoist == 1) {
                    Planner.todoist.update_item (source.item);
                }
            } else {
                listbox.insert (source, target.get_index () + 1);
                items_list.insert (target.get_index () + 1, source);

                listbox.show_all ();
            }

            update_item_order ();
        }
    }

    private void update_item_order () {
        Planner.settings.set_int ("today-sort-order", 0);

        if (timeout != 0) {
            Source.remove (timeout);
        }

        timeout = Timeout.add (1000, () => {
            new Thread<void*> ("update_item_order", () => {
                for (int index = 0; index < items_list.size; index++) {
                    Planner.database.update_today_day_order (items_list [index].item, index);
                }

                return null;
            });

            return false;
        });
    }

    public void add_new_item (int index=-1) {
        var new_item = new Widgets.NewItem (
            Planner.settings.get_int64 ("inbox-project"),
            0,
            Planner.database.get_project_by_id (Planner.settings.get_int64 ("inbox-project")).is_todoist,
            Planner.utils.get_format_date (new GLib.DateTime.now_local ()).to_string (),
            index,
            listbox
        );

        if (index == -1) {
            listbox.add (new_item);
        } else {
            listbox.insert (new_item, index);
        }

        listbox.show_all ();
        view_stack.visible_child_name = "listbox";
    }

    private void remove_item_show_queue (Widgets.ItemRow row) {
        // items_opened.remove (row);
    }

    public void hide_last_item () {
        //  if (items_opened.size > 0) {
        //      var last = items_opened [items_opened.size - 1];
        //      remove_item_show_queue (last);
        //      last.hide_item ();

        //      if (items_opened.size > 0) {
        //          var focus = items_opened [items_opened.size - 1];
        //          focus.grab_focus ();
        //          focus.content_entry_focus ();
        //      }
        //  }
    }

    private void add_event_model (E.Source source, Gee.Collection<ECal.Component> events) {
        foreach (var component in events) {
            if (Util.calcomp_is_on_day (component, date)) {
                unowned ICal.Component ical = component.get_icalcomponent ();

                var event_uid = ical.get_uid ();
                if (!event_hashmap.has_key (event_uid)) {
                    event_hashmap[event_uid] = new Widgets.EventRow (date, ical, source);
                    event_listbox.add (event_hashmap[event_uid]);
                }
            }
        }

        event_listbox.show_all ();
    }

    private void idle_update_events () {
        if (update_events_idle_source > 0) {
            GLib.Source.remove (update_events_idle_source);
        }

        update_events_idle_source = GLib.Idle.add (update_events);
    }

    private bool update_events () {
        Planner.calendar_model.source_events.@foreach ((source, component_map) => {
            foreach (var comp in component_map.get_values ()) {
                if (Util.calcomp_is_on_day (comp, date)) {
                    unowned ICal.Component ical = comp.get_icalcomponent ();
                    var event_uid = ical.get_uid ();
                    if (!event_hashmap.has_key (event_uid)) {
                        event_hashmap[event_uid] = new Widgets.EventRow (date, ical, source);
                        event_listbox.add (event_hashmap[event_uid]);
                    }
                }
            }
        });

        event_listbox.show_all ();
        update_events_idle_source = 0;
        return GLib.Source.REMOVE;
    }

    private void remove_event_model (E.Source source, Gee.Collection<ECal.Component> events) {
        foreach (var component in events) {
            unowned ICal.Component ical = component.get_icalcomponent ();
            var event_uid = ical.get_uid ();
            var event_row = event_hashmap[event_uid];
            if (event_row != null) {
                event_row.destroy ();
                event_hashmap.unset (event_uid);
            }
        }
    }

    private void add_item (Objects.Item item, int index=-1) {
        var row = new Widgets.ItemRow (item, "today");

        items_loaded.set (item.id.to_string (), row);
        if (index == -1) {
            items_list.add (row);
            listbox.add (row);
        } else {
            items_list.insert (index, row);
            listbox.insert (row, index);
        }

        listbox.show_all ();
    }

    private void add_overdue_item (Objects.Item item) {
        var row = new Widgets.ItemRow (item, "today");

        overdues_loaded.set (item.id.to_string (), row);
        overdue_list.add (row);

        overdue_listbox.add (row);
        overdue_listbox.show_all ();   
    }

    private void add_all_items () {
        items_loaded.clear ();
        items_list.clear ();
        listbox.foreach ((widget) => {
            widget.destroy ();
        });

        overdues_loaded.clear ();
        overdue_list.clear ();
        overdue_listbox.foreach ((widget) => {
            widget.destroy ();
        });

        foreach (var item in Planner.database.get_all_today_items ()) {
            var row = new Widgets.ItemRow (item, "today");

            items_loaded.set (item.id.to_string (), row);
            items_list.add (row);

            listbox.add (row);
            listbox.show_all ();
        }

        foreach (var item in Planner.database.get_all_overdue_items ()) {
            var row = new Widgets.ItemRow (item, "today");

            overdues_loaded.set (item.id.to_string (), row);
            overdue_list.add (row);

            overdue_listbox.add (row);
            overdue_listbox.show_all ();   
        }

        check_placeholder_view ();
    }

    private void add_completed_items () {
        items_completed_added.clear ();
        completed_listbox.foreach ((widget) => {
            widget.destroy ();
        });

        foreach (var item in Planner.database.get_all_today_completed_items ()) {
            var row = new Widgets.ItemRow (item);

            items_completed_added.set (item.id.to_string (), row);
            
            completed_listbox.add (row);
            completed_listbox.show_all ();
        }
    }

    private int sort_event_function (Gtk.ListBoxRow child1, Gtk.ListBoxRow child2) {
        var e1 = (Widgets.EventRow) child1;
        var e2 = (Widgets.EventRow) child2;

        if (e1.start_time.compare (e2.start_time) != 0) {
            return e1.start_time.compare (e2.start_time);
        }

        // If they have the same date, sort them wholeday first
        if (e1.is_allday) {
            return -1;
        } else if (e2.is_allday) {
            return 1;
        }

        return 0;
    }

    private void check_placeholder_view () {
        var overdue_size = Planner.database.get_all_overdue_items ().size;

        if (Planner.database.get_all_today_items ().size > 0 ||
            overdue_size > 0) {
            view_stack.visible_child_name = "listbox";
        } else {
            view_stack.visible_child_name = "placeholder";
        }

        if (overdue_size > 0) {
            overdue_revealer.reveal_child = true;
        } else {
            overdue_revealer.reveal_child = false;
        }
    }

    private void create_reschedule_popover () {
        reschedule_popover = new Gtk.Popover (reschedule_button);
        reschedule_popover.position = Gtk.PositionType.BOTTOM;
        reschedule_popover.get_style_context ().add_class ("popover-background");

        var popover_grid = new Gtk.Grid ();
        popover_grid.margin_top = 6;
        popover_grid.width_request = 235;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (get_calendar_widget ());
        popover_grid.show_all ();

        reschedule_popover.add (popover_grid);

        reschedule_popover.closed.connect (() => {
            reschedule_button.active = false;
        });
    }

    private Gtk.Widget get_calendar_widget () {
        var today_button = new Widgets.ModelButton (_("Today"), "help-about-symbolic", "");
        today_button.get_style_context ().add_class ("due-menuitem");
        today_button.item_image.pixel_size = 14;
        today_button.color = 0;
        today_button.due_label = true;

        var tomorrow_button = new Widgets.ModelButton (_("Tomorrow"), "x-office-calendar-symbolic", "");
        tomorrow_button.get_style_context ().add_class ("due-menuitem");
        tomorrow_button.item_image.pixel_size = 14;
        tomorrow_button.color = 1;
        tomorrow_button.due_label = true;

        var undated_button = new Widgets.ModelButton (_("Undated"), "window-close-symbolic", "");
        undated_button.get_style_context ().add_class ("due-menuitem");
        undated_button.item_image.pixel_size = 14;
        undated_button.color = 2;
        undated_button.due_label = true;

        var calendar = new Widgets.Calendar.Calendar (true);
        calendar.hexpand = true;

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (today_button);
        grid.add (tomorrow_button);
        grid.add (undated_button);
        grid.add (calendar);
        grid.show_all ();

        today_button.clicked.connect (() => {
            set_due (Planner.utils.get_format_date (new GLib.DateTime.now_local ()).to_string ());
        });

        tomorrow_button.clicked.connect (() => {
            set_due (Planner.utils.get_format_date (new GLib.DateTime.now_local ().add_days (1)).to_string ());
        });

        undated_button.clicked.connect (() => {
            set_due ("");
        });

        calendar.selection_changed.connect ((date) => {
            set_due (Planner.utils.get_format_date (date).to_string ());
        });

        return grid;
    }

    private void set_due (string date) {
        foreach (var item in Planner.database.get_all_overdue_items ()) {
            item.due_date = date;
            Planner.database.set_due_item (item, false);
            if (item.is_todoist == 1) {
                Planner.todoist.update_item (item);
            }
        }
    }

    public void hide_items () {
        for (int index = 0; index < items_list.size; index++) {
            if (items_list [index].reveal_child) {
                items_list [index].hide_item ();
            }
        }

        for (int index = 0; index < overdue_list.size; index++) {
            if (overdue_list [index].reveal_child) {
                overdue_list [index].hide_item ();
            }
        }
    }
}
