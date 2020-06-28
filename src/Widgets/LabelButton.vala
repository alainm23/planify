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

    private Gtk.Image label_icon;
    private Gtk.Image placeholder_image;    
    private Gtk.Label placeholder_label;
    private Gtk.Label subtitle_label;
    private Gtk.Popover popover = null;
    private Gtk.SearchEntry label_entry;
    private Gtk.ListBox listbox;

    public LabelButton (int64 item_id) {
        Object (
            item_id: item_id
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

        this.toggled.connect (() => {
            if (this.active) {
                if (popover == null) {
                    create_popover ();

                    Planner.database.label_added.connect ((label) => {
                        if (popover != null) {
                            var row = new Widgets.LabelPopoverRow (label);
                            listbox.add (row);
                        }
                    });
                }

                foreach (Gtk.Widget element in listbox.get_children ()) {
                    listbox.remove (element);
                }

                var labels = Planner.database.get_all_labels ();

                if (labels.size > 0) {
                    foreach (Objects.Label l in labels) {
                        var row = new Widgets.LabelPopoverRow (l);
                        listbox.add (row);
                    }

                    listbox.show_all ();
                } else {
                    placeholder_image.gicon = new ThemedIcon ("tag-symbolic");
                    placeholder_label.label = "<b>%s</b>".printf (_("Using Labels"));
                    subtitle_label.label = _("Categorize your to-dos with labels, then use them to filter your lists and get focused.");
                }

                popover.show_all ();
                label_entry.grab_focus ();
            }
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "appearance") {
                check_icon_style ();
            }
        });
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
        popover.get_style_context ().add_class ("popover-background");
        popover.position = Gtk.PositionType.LEFT;
        popover.width_request = 260;
        popover.height_request = 300;

        label_entry = new Gtk.SearchEntry ();
        label_entry.hexpand = true;
        label_entry.placeholder_text = _("Type a label");

        var edit_add_icon = new Gtk.Image ();
        edit_add_icon.valign = Gtk.Align.CENTER;
        edit_add_icon.icon_name = "edit-symbolic";
        edit_add_icon.pixel_size = 16;

        var edit_labels = new Gtk.Button ();
        edit_labels.add (edit_add_icon);
        edit_labels.can_focus = false;
        edit_labels.tooltip_text = _("Edit labels");
        edit_labels.get_style_context ().add_class ("edi-label-button");

        var action_grid = new Gtk.Grid ();
        action_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        action_grid.hexpand = true;
        action_grid.margin = 6;
        action_grid.add (label_entry);
        action_grid.add (edit_labels);

        var action_background = new Gtk.Grid ();
        action_background.get_style_context ().add_class ("background");
        action_background.add (action_grid);

        listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.expand = true;
        listbox.set_placeholder (get_alert_placeholder ());

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.expand = true;
        listbox_scrolled.add (listbox);

        var popover_grid = new Gtk.Grid ();
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.add (action_background);
        popover_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        popover_grid.add (listbox_scrolled);

        var eventbox = new Gtk.EventBox ();
        eventbox.add (popover_grid);
        popover.add (eventbox);

        popover.closed.connect (() => {
            this.active = false;
            label_entry.text = "";
        });

        edit_labels.clicked.connect (() => {
            if (edit_add_icon.icon_name == "edit-symbolic") {
                var dialog = new Dialogs.Preferences.Preferences ("labels");
                dialog.destroy.connect (Gtk.main_quit);
                dialog.show_all ();

                popover.popdown ();
            } else {
                create_assign ();
            }
        });

        eventbox.key_press_event.connect ((event) => {
            var key = Gdk.keyval_name (event.keyval).replace ("KP_", "");

            if (key == "Up" || key == "Down") {
                return false;
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
                var label = ((Widgets.LabelPopoverRow) listbox.get_selected_row ()).label;
                if (Planner.database.add_item_label (item_id, label)) {
                    popover.popdown ();
                }

                return false;
            } else {
                if (!label_entry.has_focus) {
                    label_entry.grab_focus ();
                    label_entry.move_cursor (Gtk.MovementStep.BUFFER_ENDS, 0, false);
                }

                return false;
            }
        });

        listbox.row_activated.connect ((row) => {
            var label = ((Widgets.LabelPopoverRow) row).label;
            if (Planner.database.add_item_label (item_id, label)) {
                popover.popdown ();
            }
        });

        label_entry.changed.connect (() => {
            listbox.foreach ((widget) => {
                widget.destroy ();
            });

            if (label_entry.text.strip () != "") {
                var labels = Planner.database.get_labels_by_search (label_entry.text);

                if (labels.size > 0) {
                    edit_add_icon.icon_name = "edit-symbolic";
                    edit_labels.tooltip_text = _("Edit labels");

                    foreach (Objects.Label l in labels) {
                        var row = new Widgets.LabelPopoverRow (l);
                        listbox.add (row);
                    }

                    listbox.show_all ();
                } else {
                    edit_add_icon.icon_name = "list-add-symbolic";
                    edit_labels.tooltip_text = _("Add label");

                    placeholder_image.gicon = new ThemedIcon ("tag-new-symbolic");
                    placeholder_label.label = "<b>%s</b>".printf (_("Label not found"));
                    subtitle_label.label = _("Create '%s'".printf (label_entry.text));
                }
            } else {
                edit_add_icon.icon_name = "edit-symbolic";
                edit_labels.tooltip_text = _("Edit labels");
                placeholder_image.gicon = new ThemedIcon ("tag-symbolic");
                placeholder_label.label = "<b>%s</b>".printf (_("Using Labels"));
                subtitle_label.label = _("Categorize your to-dos with labels, then use them to filter your lists and get focused.");
            }
        });

        label_entry.activate.connect (() => {
            if (listbox.get_selected_row () != null) {
                var label = ((Widgets.LabelPopoverRow) listbox.get_selected_row ()).label;
                if (Planner.database.add_item_label (item_id, label)) {
                    popover.popdown ();
                }
            } else {
                if (edit_add_icon.icon_name == "list-add-symbolic") {
                    create_assign ();
                }
            }
        });

        label_entry.focus_in_event.connect (handle_focus_in);
        label_entry.focus_out_event.connect (update_on_leave);
    }
    
    private bool handle_focus_in (Gdk.EventFocus event) {
        Planner.event_bus.disconnect_typing_accel ();
        return false;
    }

    public bool update_on_leave () {
        Planner.event_bus.connect_typing_accel ();
        return false;
    }

    private void create_assign () {
        var label = new Objects.Label ();
        label.name = label_entry.text;
        label.color = 47;

        if (Planner.database.insert_label (label)) {
            if (Planner.database.add_item_label (item_id, label)) {
                popover.popdown ();
                this.active = false;
            }
        }
    }

    private Gtk.Widget get_alert_placeholder () {
        placeholder_image = new Gtk.Image ();
        placeholder_image.gicon = new ThemedIcon ("tag-symbolic");
        placeholder_image.pixel_size = 42;
        placeholder_image.halign = Gtk.Align.CENTER;
        placeholder_image.opacity = 0.9;
        placeholder_image.get_style_context ().add_class ("dim-label");

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
        box.pack_start (placeholder_image, false, false, 0);
        box.pack_start (placeholder_label, false, false, 0);
        box.pack_start (subtitle_label, false, false, 0);
        box.show_all ();

        return box;
    }
}

public class Widgets.LabelPopoverRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }

    public LabelPopoverRow (Objects.Label label) {
        Object (
            label: label
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

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.margin = 6;
        box.hexpand = true;
        box.pack_start (label_image, false, false, 0);
        box.pack_start (name_label, false, true, 0);

        var grid = new Gtk.Grid ();
        grid.hexpand = true;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (box);
        grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        add (grid);

        Planner.database.label_updated.connect ((l) => {
            Idle.add (() => {
                if (label.id == l.id) {
                    name_label.label = l.name;
                }

                return false;
            });
        });

        Planner.database.label_deleted.connect ((l) => {
            if (label.id == l.id) {
                destroy ();
            }
        });
    }
}
