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

public class Layouts.LabelRow : Gtk.ListBoxRow {
    public Objects.Label label { get; construct; }

    private Gtk.Label name_label;
    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.Revealer main_revealer;
    private Gtk.Grid widget_color;

    public LabelRow (Objects.Label label) {
        Object (
            label: label
        );
    }

    construct {        
        add_css_class ("selectable-item");
        add_css_class ("transition");

        widget_color = new Gtk.Grid () {
            valign = Gtk.Align.CENTER,
            height_request = 12,
            width_request = 12
        };

        unowned Gtk.StyleContext widget_color_context = widget_color.get_style_context ();
        widget_color_context.add_class ("label-color");

        name_label = new Gtk.Label (label.name);
        name_label.valign = Gtk.Align.CENTER;
        name_label.ellipsize = Pango.EllipsizeMode.END;

        count_label = new Gtk.Label (label.label_count.to_string ()) {
            hexpand = true,
            halign = Gtk.Align.END,
            margin_end = 3
        };

        count_label.get_style_context ().add_class ("dim-label");
        count_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        count_revealer = new Gtk.Revealer () {
            reveal_child = int.parse (count_label.label) > 0
        };

        count_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        count_revealer.child = count_label;

        var edit_image = new Widgets.DynamicIcon ();
        edit_image.size = 19;
        edit_image.update_icon_name ("planner-edit");

        var edit_button = new Gtk.Button ();
        edit_button.child = edit_image;
        edit_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        edit_button.add_css_class ("no-padding");

        var trash_image = new Widgets.DynamicIcon ();
        trash_image.size = 19;
        trash_image.update_icon_name ("planner-trash");

        var trash_button = new Gtk.Button ();
        trash_button.child = trash_image;
        trash_button.add_css_class (Granite.STYLE_CLASS_FLAT);
        trash_button.add_css_class ("no-padding");

        var buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        buttons_box.append (edit_button);
        buttons_box.append (trash_button);

        var buttons_box_revealer = new Gtk.Revealer ();
        buttons_box_revealer.transition_type = Gtk.RevealerTransitionType.SWING_RIGHT;
        buttons_box_revealer.child = buttons_box;
        
        var labelrow_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_bottom = 3,
            margin_start = 3,
            margin_end = 3
        };

        labelrow_grid.append (widget_color);
        labelrow_grid.append (name_label);
        labelrow_grid.append (count_revealer);
        labelrow_grid.append (buttons_box_revealer);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN
        };
        main_revealer.child = labelrow_grid;

        child = main_revealer;
        update_request ();
        
        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        label.updated.connect (() => {
            update_request ();
        });

        label.deleted.connect (() => {
            hide_destroy ();
        });

        label.label_count_updated.connect (() => {
            count_label.label = label.label_count.to_string ();
            count_revealer.reveal_child = int.parse (count_label.label) > 0;
        });

        var motion_gesture = new Gtk.EventControllerMotion ();
        add_controller (motion_gesture);

        motion_gesture.enter.connect (() => {
            buttons_box_revealer.reveal_child = true;
            count_revealer.reveal_child = false;
        });

        motion_gesture.leave.connect (() => {
            buttons_box_revealer.reveal_child = false;
            count_revealer.reveal_child = int.parse (count_label.label) > 0;
        });

        trash_button.clicked.connect (() => {
            Planner.event_bus.close_labels ();
            
            var dialog = new Adw.MessageDialog ((Gtk.Window) Planner.instance.main_window, 
            _("Delete label"), _("Are you sure you want to delete <b>%s</b>?".printf (Util.get_default ().get_dialog_text (label.short_name))));

            dialog.body_use_markup = true;
            dialog.add_response ("cancel", _("Cancel"));
            dialog.add_response ("delete", _("Delete"));
            dialog.set_response_appearance ("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.show ();

            dialog.response.connect ((response) => {
                if (response == "delete") {
                    if (label.todoist) {
                        //  remove_button.is_loading = true;
                        Services.Todoist.get_default ().delete.begin (label, (obj, res) => {
                            Services.Todoist.get_default ().delete.end (res);
                            Services.Database.get_default ().delete_label (label);
                            // remove_button.is_loading = false;
                            // message_dialog.hide_destroy ();
                        });
                    } else {
                        Services.Database.get_default ().delete_label (label);
                    }
                }
            });
        });

        edit_button.clicked.connect (() => {
            Planner.event_bus.close_labels ();
            var dialog = new Dialogs.Label (label);
            dialog.show ();
        });
    }

    public void update_request () {
        name_label.label = label.name;
        Util.get_default ().set_widget_color (Util.get_default ().get_color (label.color), widget_color);
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}