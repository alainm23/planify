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
    public Gee.HashMap <string, Views.LabelSourceRow> sources_hashmap = new Gee.HashMap <string, Views.LabelSourceRow> ();


    construct {
        var headerbar = new Layouts.HeaderBar ();
        headerbar.title = _("Labels");

        sources_listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = Gtk.Align.START,
            css_classes = { "listbox-background" }
        };

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            hexpand = true,
            vexpand = true,
            margin_start = 12,
            margin_end = 12
        };

        content.append (sources_listbox);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 1024,
            tightening_threshold = 800,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 64,
            child = content
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
    }

    private void add_source_row (Objects.Source source) {
        if (!sources_hashmap.has_key (source.id)) {
            sources_hashmap[source.id] = new Views.LabelSourceRow (source);
            sources_listbox.append (sources_hashmap[source.id]);
        }
    }
}
