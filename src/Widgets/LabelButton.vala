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

public class Widgets.LabelButton : Gtk.ToggleButton {
    public int64 item_id { get; construct; }
    private int64 temp_id_mapping { get; set; default = 0; }
    public Gee.HashMap <string, Widgets.LabelItem> labels_map { get; set; default = new Gee.HashMap <string, Widgets.LabelItem> (); }

    private Gtk.Image label_icon;
    private Gtk.Image placeholder_image;    
    private Gtk.Label placeholder_label;
    private Gtk.Label subtitle_label;
    private Gtk.Popover popover = null;
    private GLib.Cancellable cancellable = null;
    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox listbox;
    private Gtk.Stack placeholder_stack;

    public signal void closed ();
    public signal void show_popover ();
    public signal void clear ();
    public signal void label_selected (Objects.Label label, bool active);

    public LabelButton (int64 item_id) {
        Object (
            item_id: item_id
        );
    }

    public LabelButton.new_item () {
        Object (
            item_id: 0
        );
    }

    construct {
        tooltip_text = _("Labels");

        get_style_context ().add_class ("flat");
        get_style_context ().add_class ("item-action-button");

        label_icon = new Gtk.Image ();
        label_icon.valign = Gtk.Align.CENTER;
        label_icon.pixel_size = 16;
        check_icon_style ();

        var label = new Gtk.Label (_("labels"));
        label.get_style_context ().add_class ("pane-item");
        label.margin_bottom = 1;
        label.use_markup = true;

        var main_grid = new Gtk.Grid ();
        main_grid.halign = Gtk.Align.CENTER;
        main_grid.valign = Gtk.Align.CENTER;
        main_grid.add (label_icon);

        add (main_grid);

        toggled.connect (() => {
            if (active) {
                if (popover == null) {
                    create_popover ();

                    Planner.database.label_added.connect ((label) => {
                        if (popover != null) {
                            var row = new Widgets.LabelPopoverRow (item_id, label, labels_map);
                            row.label_checked.connect ((label, active) => {
                                label_selected (label, active);
                            });
                            listbox.add (row);
                        }
                    });
                }

                add_all_labels ();
            }
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "appearance") {
                check_icon_style ();
            }
        });
    }

    private void add_all_labels () {
        foreach (Gtk.Widget element in listbox.get_children ()) {
            listbox.remove (element);
        }

        var labels = Planner.database.get_all_labels ();
        if (labels.size > 0) {
            foreach (Objects.Label l in labels) {
                var row = new Widgets.LabelPopoverRow (item_id, l, labels_map);
                row.label_checked.connect ((label, active) => {
                    label_selected (label, active);
                });
                listbox.add (row);
            }

            listbox.show_all ();
        } else {
            placeholder_image.gicon = new ThemedIcon ("tag-symbolic");
            placeholder_label.label = "<b>%s</b>".printf (_("Using Labels"));
            subtitle_label.label = _("Categorize your to-dos with labels, then use them to filter your lists and get focused.");
        }

        popover.show_all ();
        search_entry.grab_focus ();
    }

    private void check_icon_style () {
        if (Planner.settings.get_enum ("appearance") == 0) {
            label_icon.gicon = new ThemedIcon ("pricetag-outline-light");
        } else {
            label_icon.gicon = new ThemedIcon ("pricetag-outline-dark");
        }
    }

    private void create_popover () {
        popover = new Gtk.Popover (this);
        popover.position = Gtk.PositionType.BOTTOM;
        popover.width_request = 260;
        popover.get_style_context ().add_class ("popover-background");
        popover.height_request = 300;

        search_entry = new Gtk.SearchEntry ();
        search_entry.hexpand = true;
        search_entry.placeholder_text = _("Search or Create");
        search_entry.margin = 6;
        search_entry.margin_start = 9;
        search_entry.margin_end = 9;
        search_entry.get_style_context ().add_class ("border-radius-4");
        search_entry.get_style_context ().add_class ("popover-entry");

        var clear_button = new Gtk.Button.with_label (_("Clear"));
        clear_button.get_style_context ().add_class ("flat");
        clear_button.get_style_context ().add_class ("font-weight-600");
        clear_button.get_style_context ().add_class ("label-danger");
        clear_button.get_style_context ().add_class ("no-padding-right");
        clear_button.can_focus = false;

        var done_button = new Gtk.Button.with_label (_("Done"));
        done_button.get_style_context ().add_class ("flat");
        done_button.get_style_context ().add_class ("font-weight-600");
        done_button.get_style_context ().add_class ("no-padding-left");
        done_button.can_focus = false;

        var title_label = new Gtk.Label (_("Labels"));
        title_label.get_style_context ().add_class ("font-bold");

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header_box.margin_top = 3;
        header_box.margin_start = 3;
        header_box.margin_end = 3;
        header_box.pack_start (done_button, false, false, 0);
        header_box.set_center_widget (title_label);
        header_box.pack_end (clear_button, false, false, 0);

        listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.expand = true;
        listbox.set_placeholder (get_alert_placeholder ());

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.margin_bottom = 3;
        listbox_scrolled.expand = true;
        listbox_scrolled.add (listbox);

        var popover_grid = new Gtk.Grid ();
        popover_grid.get_style_context ().add_class ("border-radius-6");
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (header_box);
        popover_grid.add (search_entry);
        popover_grid.add (listbox_scrolled);

        var eventbox = new Gtk.EventBox ();
        eventbox.add (popover_grid);
        popover.add (eventbox);

        popover.closed.connect (() => {
            update_on_leave ();
            temp_id_mapping = 0;
            placeholder_stack.visible_child_name = "image";
            
            if (cancellable != null) {
                cancellable.cancel ();
            }

            this.active = false;
            search_entry.text = "";
            closed ();

            var item = Planner.database.get_item_by_id (item_id);
            if (item.is_todoist == 1 &&
                Planner.settings.get_boolean ("todoist-sync-labels")) {
                Planner.todoist.update_item (item);
            }
        });

        popover.show.connect (() => {
            handle_focus_in ();
            show_popover ();
        });

        done_button.clicked.connect (() => {
            popover.popdown ();
        });

        clear_button.clicked.connect (() => {
            if (item_id == 0) {
                clear ();
                popover.popdown ();
            } else {
                if (Planner.database.clear_item_label (item_id)) {
                    clear ();
                    popover.popdown ();
                }
            }
        });

        eventbox.key_press_event.connect ((event) => {
            var key = Gdk.keyval_name (event.keyval).replace ("KP_", "");

            if (key == "Up" || key == "Down") {
                return false;
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
                var row = ((Widgets.LabelPopoverRow) listbox.get_selected_row ());
                if (item_id == 0) {
                    label_selected (row.label, row.toggled ());
                } else {
                    if (Planner.database.add_item_label (item_id, row.label)) {
                        row.toggled ();
                    }
                }

                return false;
            } else {
                if (!search_entry.has_focus) {
                    search_entry.grab_focus ();
                    search_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
                }

                return false;
            }
        });

        search_entry.changed.connect (() => {
            listbox.foreach ((widget) => {
                widget.destroy ();
            });

            if (search_entry.text.strip () != "") {
                var labels = Planner.database.get_labels_by_search (search_entry.text);

                if (labels.size > 0) {
                    foreach (Objects.Label l in labels) {
                        var row = new Widgets.LabelPopoverRow (item_id, l, labels_map);
                        row.label_checked.connect ((label, active) => {
                            label_selected (label, active);
                        });
                        listbox.add (row);
                    }

                    listbox.show_all ();
                } else {
                    placeholder_image.gicon = new ThemedIcon ("tag-new-symbolic");
                    placeholder_label.label = "<b>%s</b>".printf (_("Label not found"));
                    subtitle_label.label = _("Create '%s'".printf (search_entry.text));
                }
            } else {
                add_all_labels ();
            }
        });

        search_entry.activate.connect (() => {
            if (listbox.get_selected_row () != null) {
                var label = ((Widgets.LabelPopoverRow) listbox.get_selected_row ()).label;
                if (item_id == 0) {
                    label_selected (label, true);
                    popover.popdown ();
                    closed ();
                } else {
                    if (Planner.database.add_item_label (item_id, label)) {
                        popover.popdown ();
                        closed ();
                    }
                }
            } else {
                create_assign ();
            }
        });

        Planner.todoist.label_added_started.connect (() => {
            placeholder_stack.visible_child_name = "spinner";
        });

        Planner.todoist.label_added_completed.connect ((id, label) => {
            if (temp_id_mapping == id) {
                temp_id_mapping = 0;
                placeholder_stack.visible_child_name = "image";

                if (item_id == 0) {
                    label_selected (label, true);
                    popover.popdown ();
                    closed ();
                } else {
                    if (Planner.database.add_item_label (item_id, label)) {
                        popover.popdown ();
                        this.active = false;
                        closed ();
                    }   
                }
            }
        });

        Planner.todoist.label_added_error.connect (() => {
            temp_id_mapping = 0;
            placeholder_stack.visible_child_name = "image";
        });
    }
    
    private bool handle_focus_in () {
        Planner.event_bus.disconnect_typing_accel ();
        return false;
    }

    public bool update_on_leave () {
        Planner.event_bus.connect_typing_accel ();
        return false;
    }

    private void create_assign () {
        var label = new Objects.Label ();
        label.name = search_entry.text.replace (" ", "_");
        label.color = GLib.Random.int_range (30, 49);

        if (Planner.settings.get_boolean ("todoist-sync-labels")) {
            label.is_todoist = 1;
            temp_id_mapping = Planner.utils.generate_id ();
            cancellable = new Cancellable ();
            Planner.todoist.add_label (label, temp_id_mapping, cancellable);
        } else {
            if (Planner.database.insert_label (label)) {
                if (item_id == 0) {
                    label_selected (label, true);
                    popover.popdown ();
                    closed ();
                } else {
                    if (Planner.database.add_item_label (item_id, label)) {
                        popover.popdown ();
                        this.active = false;
                        closed ();
                    }   
                }
            }
        }
    }

    private Gtk.Widget get_alert_placeholder () {
        var submit_spinner = new Gtk.Spinner ();
        submit_spinner.start ();

        placeholder_image = new Gtk.Image ();
        placeholder_image.gicon = new ThemedIcon ("tag-symbolic");
        placeholder_image.pixel_size = 32;
        placeholder_image.halign = Gtk.Align.CENTER;
        placeholder_image.opacity = 0.75;
        placeholder_image.get_style_context ().add_class ("dim-label");

        placeholder_stack = new Gtk.Stack ();
        placeholder_stack.expand = true;
        placeholder_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        placeholder_stack.add_named (placeholder_image, "image");
        placeholder_stack.add_named (submit_spinner, "spinner");

        placeholder_label = new Gtk.Label (null);
        placeholder_label.wrap = true;
        placeholder_label.margin_top = 12;
        placeholder_label.max_width_chars = 27;
        placeholder_label.halign = Gtk.Align.CENTER;
        placeholder_label.justify = Gtk.Justification.CENTER;
        placeholder_label.use_markup = true;
        placeholder_label.get_style_context ().add_class ("dim-label");

        subtitle_label = new Gtk.Label (null);
        subtitle_label.wrap = true;
        subtitle_label.margin_top = 2;
        subtitle_label.max_width_chars = 27;
        subtitle_label.halign = Gtk.Align.CENTER;
        subtitle_label.justify = Gtk.Justification.CENTER;
        subtitle_label.get_style_context ().add_class ("dim-label");

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.margin = 12;
        box.margin_bottom = 24;
        box.valign = Gtk.Align.CENTER;
        box.pack_start (placeholder_stack, false, false, 0);
        box.pack_start (placeholder_label, false, false, 0);
        box.pack_start (subtitle_label, false, false, 0);
        box.show_all ();

        return box;
    }
}

public class Widgets.LabelPopoverRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }
    public int64 item_id { get; construct; }
    public Gee.HashMap <string, Widgets.LabelItem> labels_map { get; construct; }

    private Gtk.CheckButton checked_button;
    public signal void label_checked (Objects.Label label, bool active);

    public LabelPopoverRow (
        int64 item_id, Objects.Label label,
        Gee.HashMap <string, Widgets.LabelItem> labels_map) {
        Object (
            item_id: item_id,
            label: label,
            labels_map: labels_map
        );
    }

    construct {
        get_style_context ().add_class ("label-select-row");

        var label_image = new Gtk.Image.from_icon_name ("tag-symbolic", Gtk.IconSize.MENU);
        label_image.valign = Gtk.Align.CENTER;
        label_image.halign = Gtk.Align.CENTER;
        label_image.can_focus = false;
        label_image.get_style_context ().add_class ("label-%s".printf (label.id.to_string ()));

        var name_label = new Gtk.Label (label.name);
        name_label.get_style_context ().add_class ("font-weight-600");
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;
        name_label.margin_bottom = 1;
        name_label.use_markup = true;

        var source_icon = new Gtk.Image ();
        source_icon.pixel_size = 14;
        source_icon.gicon = new ThemedIcon ("planner-online-symbolic");
        source_icon.tooltip_text = _("Todoist Label");

        checked_button = new Gtk.CheckButton ();
        checked_button.valign = Gtk.Align.CENTER;
        checked_button.get_style_context ().add_class ("check-border");
        checked_button.halign = Gtk.Align.END;
        checked_button.hexpand = true;

        if (item_id == 0) {
            checked_button.active = labels_map.has_key (label.id.to_string ());
        } else {
            checked_button.active = Planner.database.exists_item_label (item_id, label.id) == false;
        }
    
        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.hexpand = true;
        box.pack_start (label_image, false, false, 0);
        box.pack_start (name_label, false, true, 0);
        if (label.is_todoist == 1) {
            box.pack_start (source_icon, false, false, 0);   
        }
        box.pack_end (checked_button, false, true, 0);

        var grid = new Gtk.Grid ();
        grid.hexpand = true;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (box);

        var button = new Gtk.ModelButton ();
        button.get_style_context ().add_class ("menu-button");
        button.get_child ().destroy ();
        button.add (grid);

        add (button);

        button.button_release_event.connect (() => {
            toggled ();      
            return Gdk.EVENT_STOP;
        });

        Planner.database.label_updated.connect ((l) => {
            Idle.add (() => {
                if (label.id == l.id) {
                    name_label.label = l.name;
                }

                return false;
            });
        });

        Planner.database.label_deleted.connect ((id) => {
            if (label.id == id) {
                destroy ();
            }
        });
    }

    public bool toggled () {
        checked_button.active = !checked_button.active;
        if (item_id == 0) {
            label_checked (label, checked_button.active);
        } else {
            if (checked_button.active) {
                Planner.database.add_item_label (item_id, label);
            } else {
                var id = Planner.database.get_item_label (item_id, label.id);
                Planner.database.delete_item_label (id, item_id, label);
            }
        }

        return checked_button.active;
    }
}
