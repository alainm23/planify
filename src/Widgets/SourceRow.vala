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

public class Widgets.SourceRow : Gtk.ListBoxRow {
    public Objects.Source source { get; construct; }

    private Widgets.ReorderChild reorder;
    private Gtk.Revealer main_revealer;
    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public SourceRow (Objects.Source source) {
        Object (
            source: source
        );
    }

    ~SourceRow () {
        print ("Destroying - Widgets.SourceRow\n");
    }

    construct {
        add_css_class ("no-selectable");

        var title_label = new Gtk.Label (source.display_name) {
            halign = Gtk.Align.START
        };

        var subtitle_label = new Gtk.Label (source.subheader_text) {
            halign = Gtk.Align.START,
            css_classes = { "caption", "dimmed" }
        };

        var subtitle_revealer = new Gtk.Revealer () {
            child = subtitle_label,
            reveal_child = source.source_type != SourceType.LOCAL
        };

        var title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = Gtk.Align.CENTER
        };
        title_box.append (title_label);
        title_box.append (subtitle_revealer);

        var visible_checkbutton = new Gtk.Switch () {
            active = source.is_visible,
            valign = CENTER
        };


        Gtk.Image ? warning_image = null;
        if (source.source_type == SourceType.CALDAV && source.caldav_data.ignore_ssl) {
            warning_image = new Gtk.Image.from_icon_name ("dialog-warning-symbolic");
            warning_image.set_tooltip_text ("SSL verification is disabled");
        }

        var end_box = new Gtk.Box (HORIZONTAL, 12) {
            hexpand = true,
            halign = END
        };
        if (warning_image != null) {
            end_box.append (warning_image);
        }
        end_box.append (visible_checkbutton);
        end_box.append (new Gtk.Image.from_icon_name ("go-next-symbolic"));

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6,
            height_request = 32
        };

        content_box.append (new Gtk.Image.from_icon_name ("list-drag-handle-symbolic") {
            css_classes = { "dimmed" },
            pixel_size = 12
        });
        content_box.append (title_box);
        content_box.append (end_box);

        var card = new Adw.Bin () {
            child = content_box,
            margin_top = 3,
            margin_bottom = 3,
            margin_start = 3,
            margin_end = 3
        };

        reorder = new Widgets.ReorderChild (card, this);

        main_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = reorder
        };

        child = main_revealer;
        reorder.build_drag_and_drop ();

        Timeout.add (main_revealer.transition_duration, () => {
            main_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });

        signal_map[source.updated.connect (() => {
            title_label.label = source.display_name;
        })] = source;

        signal_map[visible_checkbutton.notify["active"].connect (() => {
            source.is_visible = visible_checkbutton.active;
            source.save ();
        })] = visible_checkbutton;

        signal_map[reorder.on_drop_end.connect ((listbox) => {
            update_views_order (listbox);
        })] = reorder;

        signal_map[main_revealer.notify["child-revealed"].connect (() => {
            reorder.draw_motion_widgets ();
        })] = main_revealer;
    }

    private void update_views_order (Gtk.ListBox listbox) {
        unowned Widgets.SourceRow ? row = null;
        var row_index = 0;

        do {
            row = (Widgets.SourceRow) listbox.get_row_at_index (row_index);

            if (row != null) {
                row.source.child_order = row_index;
                row.source.save ();
            }

            row_index++;
        } while (row != null);

        Services.EventBus.get_default ().update_sources_position ();
    }

    public void hide_destroy () {
        main_revealer.reveal_child = false;
        clean_up ();
        Timeout.add (main_revealer.transition_duration, () => {
            ((Gtk.ListBox) parent).remove (this);
            return GLib.Source.REMOVE;
        });
    }

    public void clean_up () {
        if (reorder != null) {
            reorder.clean_up ();
            reorder = null;
        }

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
        
        main_revealer = null;
    }
}
