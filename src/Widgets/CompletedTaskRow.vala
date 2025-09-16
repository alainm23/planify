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

public class Widgets.CompletedTaskRow : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    private Gtk.CheckButton checked_button;
    private Widgets.LoadingButton loading_button;
    private Gtk.Revealer main_revealer;

    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public CompletedTaskRow (Objects.Item item) {
        Object (
            item: item
        );
    }

    ~CompletedTaskRow () {
        debug ("Destroying - Widgets.CompletedTaskRow\n");
    }

    construct {
        add_css_class ("row");
        add_css_class ("no-padding");

        checked_button = new Gtk.CheckButton () {
            valign = Gtk.Align.START,
            css_classes = { "priority-color" },
            active = item.checked
        };

        var content_label = new Gtk.Label (item.content) {
            wrap = true,
            hexpand = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            xalign = 0,
            yalign = 0
        };

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 3,
            margin_start = 3,
            margin_end = 3
        };

        content_box.append (checked_button);
        content_box.append (content_label);

        var description_label = new Gtk.Label (null) {
            xalign = 0,
            lines = 1,
            ellipsize = Pango.EllipsizeMode.END,
            margin_start = 30,
            margin_end = 6,
            css_classes = { "dimmed", "caption" }
        };

        var section_label = new Gtk.Label (item.has_section ? "● " + item.section.name : "● " + _("No Section")) {
            css_classes = { "dimmed", "caption" }
        };

        var subitems_label = new Gtk.Label (null) {
            css_classes = { "dimmed", "caption" }
        };

        var bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 24
        };
        bottom_box.append (section_label);

        if (item.items.size > 0) {
            bottom_box.append (new Gtk.Label ("|") {
                css_classes = { "dimmed", "caption" }
            });

            subitems_label.label = "%s %s".printf (item.items.size < 10 ? "0" + item.items.size.to_string () : item.items.size.to_string (), _("Sub-tasks"));
            bottom_box.append (subitems_label);
        }

        var v_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            hexpand = true
        };

        v_box.append (content_box);
        v_box.append (bottom_box);

        loading_button = new Widgets.LoadingButton.with_icon ("go-next-symbolic", 16) {
            valign = Gtk.Align.CENTER,
            css_classes = { "flat", "dimmed", "no-padding" }
        };

        var h_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_top = 6,
            margin_end = 9,
            margin_bottom = 6,
            margin_start = 6
        };

        h_box.append (v_box);
        h_box.append (loading_button);

        var card = new Adw.Bin () {
            child = h_box,
            css_classes = { "card", "activatable", "border-radius-9" },
            margin_start = 1,
            margin_end = 1,
            margin_top = 1,
            margin_bottom = 1
        };

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = card,
            reveal_child = true
        };

        child = main_revealer;

        var checked_button_gesture = new Gtk.GestureClick ();
        checked_button.add_controller (checked_button_gesture);
        signals_map[checked_button_gesture.pressed.connect (() => {
            checked_button_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
            checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
        })] = checked_button_gesture;

        signals_map[item.loading_change.connect (() => {
            loading_button.is_loading = item.loading;
        })] = item;

        destroy.connect (() => {
            foreach (var entry in signals_map.entries) {
                entry.value.disconnect (entry.key);
            }

            signals_map.clear ();
        });
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }

    public void checked_toggled (bool active, uint ? time = null) {
        bool old_checked = item.checked;

        if (!active) {
            var old_completed_at = item.completed_at;

            item.checked = false;
            item.completed_at = "";
            _complete_item.begin (old_checked, old_completed_at);
        }
    }

    private async void _complete_item (bool old_checked, string old_completed_at) {
        checked_button.sensitive = false;

        HttpResponse response = yield item.complete_item (old_checked);

        if (!response.status) {
            // _complete_item_error (response, old_checked, old_completed_at);
        }
    }

    public void clean_up () {
        foreach (var entry in signals_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signals_map.clear ();
    }
}