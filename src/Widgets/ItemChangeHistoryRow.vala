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
        debug ("Destroying - Widgets.ItemChangeHistoryRow\n");
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
            var project = Services.Store.instance ().get_project (object_event.object_new_value);
            _type_string = "%s: %s".printf (
                _("Task moved to project"),
                project != null ? project.name : _("Unknown project")
            );
        } else if (object_event.object_key == ObjectEventKeyType.SECTION) {
            string section_name = Services.Store.instance ().get_item (object_event.object_id)?.project?.name ?? _("Unknown");
            if (object_event.object_new_value != "") {
                var section = Services.Store.instance ().get_section (object_event.object_new_value);
                section_name = section != null ? section.name : _("Unknown section");
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

        var old_value_label = new Gtk.Label (null) {
            css_classes = { "dimmed", "caption" },
            selectable = true,
            ellipsize = Pango.EllipsizeMode.END
        };

        var arrow_label = new Gtk.Label ("→") {
            css_classes = { "dimmed", "caption" }
        };

        var new_value_label = new Gtk.Label (null) {
            css_classes = { "caption" },
            selectable = true,
            ellipsize = Pango.EllipsizeMode.END
        };

        // Option 2 — chips with arrow (short values)
        var chips_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            halign = START
        };
        chips_box.append (old_value_label);
        chips_box.append (arrow_label);
        chips_box.append (new_value_label);

        var chips_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = chips_box
        };

        // Option 3 — expandable (long values)
        var expand_old_label = new Gtk.Label (null) {
            css_classes = { "dimmed", "caption" },
            selectable = true,
            wrap = true,
            xalign = 0,
            lines = 2,
            ellipsize = Pango.EllipsizeMode.END
        };

        var expand_old_label_full = new Gtk.Label (null) {
            css_classes = { "dimmed", "caption" },
            selectable = true,
            wrap = true,
            xalign = 0
        };

        var expand_old_full_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false,
            child = expand_old_label_full
        };

        var expand_new_label = new Gtk.Label (null) {
            css_classes = { "caption" },
            selectable = true,
            wrap = true,
            xalign = 0,
            lines = 2,
            ellipsize = Pango.EllipsizeMode.END,
            margin_top = 6
        };

        var expand_new_label_full = new Gtk.Label (null) {
            css_classes = { "caption" },
            selectable = true,
            wrap = true,
            xalign = 0
        };

        var expand_new_full_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false,
            child = expand_new_label_full
        };

        var see_more_icon = new Gtk.Image.from_icon_name ("down-small-symbolic") {
            pixel_size = 12,
            css_classes = { "see-more-icon-collapsed" }
        };

        var see_more_label = new Gtk.Label (_("See more")) {
            css_classes = { "caption" }
        };

        var see_more_box = new Gtk.Box (HORIZONTAL, 4) {
            halign = CENTER
        };
        see_more_box.append (see_more_label);
        see_more_box.append (see_more_icon);

        var see_more_button = new Gtk.Button () {
            css_classes = { "flat", "dimmed" },
            halign = CENTER,
            hexpand = true,
            child = see_more_box
        };

        var see_more_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false,
            child = see_more_button
        };

        bool _expanded = false;
        see_more_button.clicked.connect (() => {
            _expanded = !_expanded;
            expand_old_label.visible = !_expanded;
            expand_old_full_revealer.reveal_child = _expanded;
            expand_new_label.visible = !_expanded;
            expand_new_full_revealer.reveal_child = _expanded;
            see_more_label.label = _expanded ? _("See less") : _("See more");
            if (_expanded) {
                see_more_icon.remove_css_class ("see-more-icon-collapsed");
                see_more_icon.add_css_class ("see-more-icon-expanded");
            } else {
                see_more_icon.remove_css_class ("see-more-icon-expanded");
                see_more_icon.add_css_class ("see-more-icon-collapsed");
            }
        });

        var expand_old_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false
        };
        var expand_old_box = new Gtk.Box (VERTICAL, 3);
        expand_old_box.append (expand_old_label);
        expand_old_box.append (expand_old_full_revealer);
        expand_old_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        expand_old_revealer.child = expand_old_box;

        var expand_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
        expand_box.append (expand_old_revealer);
        expand_box.append (expand_new_label);
        expand_box.append (expand_new_full_revealer);
        expand_box.append (see_more_revealer);

        var expand_button_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            reveal_child = false,
            child = expand_box
        };

        var detail_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.START
        };

        detail_box.append (header_box);
        detail_box.append (chips_revealer);
        detail_box.append (expand_button_revealer);

        var content_box = new Gtk.Grid () {
            column_spacing = 9,
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12
        };

        content_box.attach (object_event_icon, 0, 0, 1, 2);
        content_box.attach (detail_box, 1, 0, 1, 2);

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
        string _no_value_label = _("None");
        bool use_chips = false;

        if (object_event.event_type == ObjectEventType.INSERT) {
            _new_value_label = object_event.object_new_value;
        } else if (object_event.event_type == ObjectEventType.UPDATE) {
            if (object_event.object_key == ObjectEventKeyType.CONTENT ||
                object_event.object_key == ObjectEventKeyType.DESCRIPTION) {
                _no_value_label = _("Empty");
                _old_value_label = object_event.object_old_value;
                _new_value_label = object_event.object_new_value;
            } else if (object_event.object_key == ObjectEventKeyType.DUE) {
                use_chips = true;
                _no_value_label = _("No date");
                _old_value_label = Utils.Datetime.get_relative_date_from_date (
                    object_event.get_due_value (object_event.object_old_value).datetime
                );
                _new_value_label = Utils.Datetime.get_relative_date_from_date (
                    object_event.get_due_value (object_event.object_new_value).datetime
                );
            } else if (object_event.object_key == ObjectEventKeyType.PRIORITY) {
                use_chips = true;
                _no_value_label = _("No priority");
                if (object_event.object_old_value != "") {
                    _old_value_label = Objects.Filters.Priority.get_default (int.parse (object_event.object_old_value)).title;
                }
                if (object_event.object_new_value != "") {
                    _new_value_label = Objects.Filters.Priority.get_default (int.parse (object_event.object_new_value)).title;
                }
            } else if (object_event.object_key == ObjectEventKeyType.LABELS) {
                _no_value_label = _("No labels");
                _old_value_label = object_event.get_labels_value (object_event.object_old_value);
                _new_value_label = object_event.get_labels_value (object_event.object_new_value);
            } else if (object_event.object_key == ObjectEventKeyType.PINNED) {
                use_chips = true;
                _no_value_label = _("Not pinned");
                _old_value_label = object_event.object_old_value == "1" ? _("Pin: Active") : _("Pin: Inactive");
                _new_value_label = object_event.object_new_value == "1" ? _("Pin: Active") : _("Pin: Inactive");
            } else if (object_event.object_key == ObjectEventKeyType.DEADLINE) {
                use_chips = true;
                _no_value_label = _("No deadline");
                if (object_event.object_old_value != "") {
                    var old_dt = Utils.Datetime.get_date_from_string (object_event.object_old_value);
                    if (old_dt != null) _old_value_label = Utils.Datetime.get_relative_date_from_date (old_dt);
                }
                if (object_event.object_new_value != "") {
                    var new_dt = Utils.Datetime.get_date_from_string (object_event.object_new_value);
                    if (new_dt != null) _new_value_label = Utils.Datetime.get_relative_date_from_date (new_dt);
                }
            } else if (object_event.object_key == ObjectEventKeyType.PARENT) {
                use_chips = true;
                _no_value_label = _("No parent");
                if (object_event.object_old_value != "") {
                    var old_item = Services.Store.instance ().get_item (object_event.object_old_value);
                    _old_value_label = old_item != null ? old_item.content : _("Unknown task");
                }
                if (object_event.object_new_value != "") {
                    var new_item = Services.Store.instance ().get_item (object_event.object_new_value);
                    _new_value_label = new_item != null ? new_item.content : _("Unknown task");
                }
            }
        }

        if (use_chips) {
            old_value_label.label = _old_value_label.length > 0 ? _old_value_label : _no_value_label;
            if (_new_value_label.length > 0) new_value_label.label = _new_value_label;
            chips_revealer.reveal_child = _new_value_label.length > 0;
        } else {
            string old_val = _old_value_label.length > 0 ? _old_value_label : _no_value_label;
            expand_old_label.label = old_val;
            expand_old_label_full.label = old_val;
            expand_old_revealer.reveal_child = true;
            if (_new_value_label.length > 0) {
                expand_new_label.label = _new_value_label;
                expand_new_label_full.label = _new_value_label;
            }
            expand_button_revealer.reveal_child = _new_value_label.length > 0;

            Timeout.add (main_revealer.transition_duration + 100, () => {
                bool old_truncated = expand_old_label.get_layout ().is_ellipsized ();
                bool new_truncated = expand_new_label.get_layout ().is_ellipsized ();
                see_more_revealer.reveal_child = old_truncated || new_truncated;
                return GLib.Source.REMOVE;
            });
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