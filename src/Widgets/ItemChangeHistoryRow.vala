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

public class Widgets.ItemChangeHistoryRow : Gtk.ListBoxRow {
    public Objects.ObjectEvent object_event { get; construct; }

    private Gtk.Revealer main_revealer;

    public ItemChangeHistoryRow (Objects.ObjectEvent object_event) {
        Object (
            object_event: object_event
        );
    }

    ~ItemChangeHistoryRow () {
        print ("Destroying - Widgets.ItemChangeHistoryRow\n");
    }

    construct {
        add_css_class ("no-selectable");

        var object_event_icon = new Gtk.Image.from_icon_name (object_event.icon_name) {
            pixel_size = 16,
            valign = START
        };


        string _type_string = "";
        if (object_event.object_key == ObjectEventKeyType.CHECKED) {
            _type_string = object_event.object_new_value == "1" ? _("Task completed") : _("Task uncompleted");
        } else if (object_event.object_key == ObjectEventKeyType.PROJECT) {
            _type_string = "%s: %s".printf (
                _("Task moved to project"),
                Services.Store.instance ().get_project (object_event.object_new_value).name
            );
        } else if (object_event.object_key == ObjectEventKeyType.SECTION) {
            string section_name = Services.Store.instance ().get_item (object_event.object_id).project.name;
            if (object_event.object_new_value != "") {
                section_name = Services.Store.instance ().get_section (object_event.object_new_value).name;
            }

            _type_string = "%s: %s".printf (
                _("Task moved to"),
                section_name
            );
        } else {
            _type_string = "%s: %s".printf (object_event.event_type.get_label (), object_event.object_key.get_label ());
        }

        var type_string = new Gtk.Label (_type_string) {
            use_markup = true,
            halign = Gtk.Align.START,
            margin_bottom = 3,
            ellipsize = Pango.EllipsizeMode.END
        };

        var datetime_string = new Gtk.Label (object_event.time) {
            css_classes = { "dimmed", "caption" },
            halign = Gtk.Align.END,
            hexpand = true
        };

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            hexpand = true
        };
        header_box.append (type_string);
        header_box.append (datetime_string);

        var old_value_header = new Gtk.Label (_("Previous") + ": ") {
            css_classes = { "font-bold" }
        };

        var old_value_label = new Gtk.Label (null) {
            css_classes = { "dimmed" },
            selectable = true,
            ellipsize = Pango.EllipsizeMode.END
        };

        var old_value_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            halign = Gtk.Align.START
        };
        old_value_box.append (old_value_header);
        old_value_box.append (old_value_label);

        var old_value_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = old_value_box
        };

        var new_value_header = new Gtk.Label (_("New") + ": ") {
            css_classes = { "font-bold" }
        };

        var new_value_label = new Gtk.Label (null) {
            css_classes = { "dimmed", "caption" },
            selectable = true,
            wrap = true
        };

        var new_value_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            halign = Gtk.Align.START
        };
        // new_value_box.append (new_value_header);
        new_value_box.append (new_value_label);

        var new_value_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = new_value_box
        };

        var detail_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.START
        };

        detail_box.append (header_box);
        // detail_box.append (old_value_revealer);
        detail_box.append (new_value_revealer);

        var content_box = new Gtk.Grid () {
            column_spacing = 9,
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };

        content_box.attach (object_event_icon, 0, 0, 1, 2);
        content_box.attach (detail_box, 1, 1, 1, 1);

        var card = new Adw.Bin () {
            child = content_box,
            css_classes = { "card" },
            margin_top = 3,
            margin_bottom = 3,
            margin_start = 3,
            margin_end = 3
        };

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = card
        };

        child = main_revealer;

        string _old_value_label = "";
        string _new_value_label = "";

        if (object_event.event_type == ObjectEventType.INSERT) {
            _new_value_label = object_event.object_new_value;
        } else if (object_event.event_type == ObjectEventType.UPDATE) {
            if (object_event.object_key == ObjectEventKeyType.DESCRIPTION) {
                _old_value_label = object_event.object_old_value;
                _new_value_label = object_event.object_new_value;
            } else if (object_event.object_key == ObjectEventKeyType.DUE) {
                _old_value_label = Utils.Datetime.get_relative_date_from_date (
                    object_event.get_due_value (object_event.object_old_value).datetime
                );
                _new_value_label = Utils.Datetime.get_relative_date_from_date (
                    object_event.get_due_value (object_event.object_new_value).datetime
                );
            } else if (object_event.object_key == ObjectEventKeyType.PRIORITY) {
                if (object_event.object_old_value != "") {
                    _old_value_label = Util.get_default ().get_priority_title (int.parse (object_event.object_old_value));
                }

                if (object_event.object_new_value != "") {
                    _new_value_label = Util.get_default ().get_priority_title (int.parse (object_event.object_new_value));
                }
            } else if (object_event.object_key == ObjectEventKeyType.LABELS) {
                _old_value_label = object_event.get_labels_value (object_event.object_old_value);
                _new_value_label = object_event.get_labels_value (object_event.object_new_value);
            } else if (object_event.object_key == ObjectEventKeyType.PINNED) {
                _old_value_label = object_event.object_old_value == "1" ? _("Pin: Active") : _("Pin: Inactive");
                _new_value_label = object_event.object_new_value == "1" ? _("Pin: Active") : _("Pin: Inactive");
            }
        }

        if (_old_value_label.length > 0) {
            old_value_revealer.reveal_child = true;
            old_value_label.label = _old_value_label;
        }

        if (_new_value_label.length > 0) {
            new_value_revealer.reveal_child = true;
            new_value_label.label = _new_value_label;
        }

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }
}