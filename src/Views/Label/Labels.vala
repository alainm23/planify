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

public class Views.Labels : Adw.Bin {
    private Gtk.ListBox sources_listbox;
    public Gee.HashMap<string, Views.LabelSourceRow> sources_hashmap = new Gee.HashMap<string, Views.LabelSourceRow> ();

    construct {
        var headerbar = new Layouts.HeaderBar () {
            title = FilterType.LABELS.get_name ()
        };

        var title_icon = new Gtk.Image.from_icon_name (FilterType.LABELS.get_icon ()) {
            pixel_size = 16,
            valign = CENTER,
            halign = CENTER,
            css_classes = { "view-icon" }
        };

        Util.get_default ().set_widget_color (FilterType.LABELS.get_color (), title_icon);
        Services.EventBus.get_default ().theme_changed.connect (() => {
            Util.get_default ().set_widget_color (FilterType.LABELS.get_color (), title_icon);
        });

        var title_label = new Gtk.Label (FilterType.LABELS.get_name ()) {
            css_classes = { "font-bold", "title-2" },
            ellipsize = END,
            halign = START
        };

        var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 15
        };

        title_box.append (title_icon);
        title_box.append (title_label);

        sources_listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = Gtk.Align.START,
            css_classes = { "listbox-background" },
            margin_start = 9
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            hexpand = true,
            vexpand = true,
            margin_start = 12,
            margin_end = 12
        };

        content_box.append (title_box);
        content_box.append (sources_listbox);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 64,
            child = content_box
        };

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = content_clamp
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.content = scrolled_window;

        child = toolbar_view;

        foreach (Objects.Source source in Services.Store.instance ().sources) {
            add_source_row (source);
        }

        Services.Store.instance ().source_deleted.connect ((source) => {
            if (sources_hashmap.has_key (source.id)) {
                sources_hashmap.get (source.id).hide_destroy ();
            }
        });

        Services.Store.instance ().source_added.connect (add_source_row);

        scrolled_window.vadjustment.value_changed.connect (() => {
            headerbar.revealer_title_box (scrolled_window.vadjustment.value >= Constants.HEADERBAR_TITLE_SCROLL_THRESHOLD);            
        });
    }

    private void add_source_row (Objects.Source source) {
        if (!sources_hashmap.has_key (source.id)) {
            sources_hashmap[source.id] = new Views.LabelSourceRow (source);
            sources_listbox.append (sources_hashmap[source.id]);
        }
    }
}
