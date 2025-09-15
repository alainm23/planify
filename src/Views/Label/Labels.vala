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
    private Layouts.HeaderBar headerbar;
    private Gtk.ListBox sources_listbox;

    public Gee.HashMap<string, Views.LabelSourceRow> sources_hashmap = new Gee.HashMap<string, Views.LabelSourceRow> ();
    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    ~Labels () {
        print ("Destroying - Views.Labels\n");
    }

    construct {
        headerbar = new Layouts.HeaderBar () {
            title = Objects.Filters.Labels.get_default ().name
        };

        var title_icon = new Gtk.Image.from_icon_name (Objects.Filters.Labels.get_default ().icon_name) {
            pixel_size = 16,
            valign = CENTER,
            halign = CENTER,
            css_classes = { "view-icon" }
        };

        Util.get_default ().set_widget_color (Objects.Filters.Labels.get_default ().theme_color (), title_icon);
        signal_map[Services.EventBus.get_default ().theme_changed.connect (() => {
            Util.get_default ().set_widget_color (Objects.Filters.Labels.get_default ().theme_color (), title_icon);
        })] = Services.EventBus.get_default ();

        var title_label = new Gtk.Label (Objects.Filters.Labels.get_default ().name) {
            css_classes = { "font-bold", "title-2" },
            ellipsize = END,
            halign = START
        };

        var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        title_box.append (title_icon);
        title_box.append (title_label);

        sources_listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = Gtk.Align.START,
            css_classes = { "listbox-background" }
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            hexpand = true,
            vexpand = true,
            margin_start = 24,
            margin_end = 24
        };

        content_box.append (title_box);
        content_box.append (sources_listbox);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 864,
            margin_bottom = 64,
            child = content_box
        };

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = content_clamp
        };

        var magic_button = new Widgets.MagicButton ();

        var content_overlay = new Gtk.Overlay () {
            hexpand = true,
            vexpand = true,
            child = scrolled_window
        };

        content_overlay.add_overlay (magic_button);

        var toolbar_view = new Adw.ToolbarView () {
            content = content_overlay
        };
        toolbar_view.add_top_bar (headerbar);

        child = toolbar_view;

        foreach (Objects.Source source in Services.Store.instance ().sources) {
            add_source_row (source);
        }

        signal_map[Services.Store.instance ().source_deleted.connect ((source) => {
            if (sources_hashmap.has_key (source.id)) {
                sources_hashmap.get (source.id).hide_destroy ();
            }
        })] = Services.Store.instance ();

        signal_map[Services.Store.instance ().source_added.connect (add_source_row)] = Services.Store.instance ();

        signal_map[scrolled_window.vadjustment.value_changed.connect (() => {
            headerbar.revealer_title_box (scrolled_window.vadjustment.value >= Constants.HEADERBAR_TITLE_SCROLL_THRESHOLD);            
        })] = scrolled_window.vadjustment;

        signal_map[magic_button.clicked.connect (() => {
            prepare_new_item ();
        })] = magic_button;
    }

    private void add_source_row (Objects.Source source) {
        if (!sources_hashmap.has_key (source.id)) {
            sources_hashmap[source.id] = new Views.LabelSourceRow (source);
            sources_listbox.append (sources_hashmap[source.id]);
        }
    }

    public void prepare_new_item (string content = "") {
        var dialog = new Dialogs.QuickAdd ();
        dialog.update_content (content);
        dialog.present (Planify._instance.main_window);
    }

    public void clean_up () {
        foreach (var row in Util.get_default ().get_children (sources_listbox)) {
            ((Views.LabelSourceRow) row).clean_up ();   
        }

        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        headerbar.clean_up ();
    }
}
