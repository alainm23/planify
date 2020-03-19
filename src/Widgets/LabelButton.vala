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

    private Gtk.Popover popover = null;
    private Gtk.Entry label_entry;
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

        var label_icon = new Gtk.Image ();
        label_icon.valign = Gtk.Align.CENTER;
        label_icon.gicon = new ThemedIcon ("tag-new-symbolic");
        label_icon.pixel_size = 16;

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

                foreach (Objects.Label l in Planner.database.get_all_labels ()) {
                    var row = new Widgets.LabelPopoverRow (l);
                    listbox.add (row);
                }

                popover.show_all ();
                label_entry.grab_focus ();
            }
        });
    }

    private void create_popover () {
        popover = new Gtk.Popover (this);
        popover.get_style_context ().add_class ("popover-background");
        popover.position = Gtk.PositionType.LEFT;

        label_entry = new Gtk.SearchEntry ();
        label_entry.hexpand = true;
        label_entry.placeholder_text = _("Type a label");

        listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.expand = true;
        listbox.set_filter_func ((row) => {
            var label = ((Widgets.LabelPopoverRow) row).label;
            return label_entry.text.down () in label.name.down ();
        });

        var listbox_scrolled = new Gtk.ScrolledWindow (null, null);
        listbox_scrolled.expand = true;
        listbox_scrolled.add (listbox);

        var edit_icon = new Gtk.Image ();
        edit_icon.valign = Gtk.Align.CENTER;
        edit_icon.gicon = new ThemedIcon ("edit-symbolic");
        edit_icon.pixel_size = 14;

        var edit_labels = new Gtk.Button ();
        edit_labels.add (edit_icon);
        edit_labels.can_focus = false;
        edit_labels.tooltip_text = _("Edit labels");
        edit_labels.get_style_context ().add_class ("edi-label-button");


        var action_grid = new Gtk.Grid ();
        action_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        action_grid.margin = 6;
        action_grid.hexpand = true;
        action_grid.add (label_entry);
        action_grid.add (edit_labels);

        var action_bar = new Gtk.ActionBar ();
        action_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        action_bar.pack_start (action_grid);

        var popover_grid = new Gtk.Grid ();
        popover_grid.width_request = 235;
        popover_grid.height_request = 250;
        popover_grid.orientation = Gtk.Orientation.VERTICAL;
        popover_grid.margin_top = 3;
        popover_grid.add (listbox_scrolled);
        popover_grid.add (action_bar);

        var eventbox = new Gtk.EventBox ();
        eventbox.add (popover_grid);

        popover.add (eventbox);

        popover.closed.connect (() => {
            this.active = false;
        });

        edit_labels.clicked.connect (() => {
            var dialog = new Dialogs.Preferences.Preferences ("labels");
            dialog.destroy.connect (Gtk.main_quit);
            dialog.show_all ();

            popover.popdown ();
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

            return true;
        });

        listbox.row_activated.connect ((row) => {
            var label = ((Widgets.LabelPopoverRow) row).label;
            if (Planner.database.add_item_label (item_id, label)) {
                popover.popdown ();
            }
        });

        label_entry.changed.connect (() => {
            listbox.invalidate_filter ();
        });

        label_entry.activate.connect (() => {
            if (listbox.get_selected_row () != null) {
                var label = ((Widgets.LabelPopoverRow) listbox.get_selected_row ()).label;
                if (Planner.database.add_item_label (item_id, label)) {
                    popover.popdown ();
                }
            }
        });
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