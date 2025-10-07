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

public class Dialogs.ItemChangeHistory : Adw.Dialog {
    public Objects.Item item { get; construct; }

    private Gtk.ListBox listbox;
    private Gtk.Button load_button;
    private int start_week = 0;
    private int end_week = 7;

    private Gee.HashMap<ulong, GLib.Object> signal_map = new Gee.HashMap<ulong, GLib.Object> ();

    public ItemChangeHistory (Objects.Item item) {
        Object (
            item: item,
            title: _("Change History"),
            content_width: 450,
            content_height: 500
        );
    }

    ~ItemChangeHistory () {
        debug ("Destroying - Dialogs.ItemChangeHistory\n");
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        var create_update_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_start = 6,
            margin_end = 6,
            valign = START,
        };
        create_update_box.append (build_card ("plus-large-symbolic", _("Added at"), Utils.Datetime.get_relative_date_from_date (item.added_datetime)));

        string updated_date = "(" + _("Not available") + ")";
        if (item.updated_at != "") {
            updated_date = Utils.Datetime.get_relative_date_from_date (item.updated_datetime);
        }
        create_update_box.append (build_card ("update-symbolic", _("Updated at"), updated_date));

        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = START,
            css_classes = { "listbox-background" }
        };

        listbox.set_header_func (header_completed_function);
        listbox.set_placeholder (new Gtk.Label (_("Your change history will be displayed here once you start making changes.")) {
            css_classes = { "dimmed" },
            margin_top = 24,
            margin_start = 24,
            margin_end = 24,
            wrap = true,
            justify = Gtk.Justification.CENTER
        });

        load_button = new Gtk.Button () {
            css_classes = { "flat" },
            vexpand = true,
            valign = Gtk.Align.END
        };

        var v_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            hexpand = true,
            valign = Gtk.Align.START
        };

        v_box.append (create_update_box);
        v_box.append (listbox);

        var v2_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            hexpand = true,
            vexpand = true,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_top = 12
        };

        v2_box.append (v_box);
        v2_box.append (load_button);

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = v2_box
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.content = listbox_scrolled;

        child = toolbar_view;
        fetch_data ();

        signal_map[load_button.clicked.connect (() => {
            start_week = end_week;
            end_week = end_week + 7;
            fetch_data ();
        })] = load_button;

        closed.connect (() => {
            clean_up ();
        });
    }

    private void fetch_data () {
        foreach (Objects.ObjectEvent object_event in Services.Database.get_default ().get_events_by_item (item.id, start_week, end_week)) {
            listbox.append (new Widgets.ItemChangeHistoryRow (object_event));
        }

        listbox.invalidate_headers ();

        int weeks = (end_week / 7) + 1;
        load_button.label = GLib.ngettext (
            _("Load more history from %d week ago…"),
            _("Load more history from %d weeks ago…"),
            weeks
        ).printf (weeks);
    }

    private void header_completed_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow ? lbbefore) {
        var row = (Widgets.ItemChangeHistoryRow) lbrow;
        if (row.object_event.event_date == "") {
            return;
        }

        if (lbbefore != null) {
            var before = (Widgets.ItemChangeHistoryRow) lbbefore;
            if (before.object_event.date.compare (row.object_event.date) == 0) {
                return;
            }
        }

        row.set_header (get_header_box (Utils.Datetime.get_relative_date_from_date (row.object_event.date)));
    }

    private Gtk.Widget get_header_box (string title) {
        var header_label = new Gtk.Label (title) {
            css_classes = { "heading" },
            halign = START
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_start = 12,
            margin_top = 6,
            margin_bottom = 6
        };

        header_box.append (header_label);

        return header_box;
    }

    private Gtk.Widget build_card (string icon_name, string header, string value) {
        var image = new Gtk.Image.from_icon_name (icon_name);

        var header_label = new Gtk.Label (header) {
            halign = START,
            css_classes = { "title-4", "caption", "font-bold" }
        };

        var value_label = new Gtk.Label (value) {
            xalign = 0,
            use_markup = true,
            halign = START,
            ellipsize = Pango.EllipsizeMode.END,
            css_classes = { "caption" }
        };

        var card_content = new Gtk.Grid () {
            column_spacing = 12,
            vexpand = true,
            hexpand = true,
            margin_start = 12,
            margin_end = 6,
            margin_top = 6,
            margin_bottom = 6,
        };
        card_content.attach (image, 0, 0, 1, 2);
        card_content.attach (header_label, 1, 0, 1, 1);
        card_content.attach (value_label, 1, 1, 1, 1);

        var card = new Adw.Bin () {
            child = card_content,
            css_classes = { "card" }
        };

        return card;
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        listbox.set_header_func (null);
    }
}
