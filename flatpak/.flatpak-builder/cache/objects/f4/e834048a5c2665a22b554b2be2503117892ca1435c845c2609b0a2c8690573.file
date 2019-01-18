// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2015 Maya Developers (http://launchpad.net/maya)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.SourceSelector : Gtk.Popover {
    private GLib.HashTable<string, SourceItem?> src_map;

    private Gtk.Stack stack;
    private SourceDialog src_dialog = null;

    private Gtk.Grid main_grid;
    private Gtk.ListBox calendar_box;
    private Gtk.ScrolledWindow scroll;

    public SourceSelector () {
        calendar_box = new Gtk.ListBox ();
        calendar_box.selection_mode = Gtk.SelectionMode.NONE;
        calendar_box.margin_start = calendar_box.margin_end = 6;
        calendar_box.set_header_func (header_update_func);
        calendar_box.set_sort_func ((child1, child2) => {
            var comparison = ((SourceItem)child1).location.collate (((SourceItem)child2).location);
            if (comparison == 0)
                return ((SourceItem)child1).label.collate (((SourceItem)child2).label);
            else
                return comparison;
        });

        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        scroll.expand = true;
        scroll.add (calendar_box);

        src_map = new GLib.HashTable<string, SourceItem?>(str_hash, str_equal);

        var add_calendar_button = new Gtk.Button.with_label (_("Add New Calendar…"));
        add_calendar_button.xalign = 0;
        add_calendar_button.clicked.connect (create_source);
        add_calendar_button.get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);

        main_grid = new Gtk.Grid ();
        main_grid.row_spacing = 6;
        main_grid.margin_top = 6;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.add (scroll);
        main_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        main_grid.add (add_calendar_button);

        stack = new Gtk.Stack ();
        stack.add_named (main_grid, "main");
        stack.margin_bottom = 5;

        this.add (stack);
        populate.begin ();
        stack.show_all ();
    }

    public async void populate () {
        try {
            var registry = yield new E.SourceRegistry (null);
            registry.source_removed.connect (source_removed);
            registry.source_disabled.connect (source_disabled);
            registry.source_enabled.connect (add_source_to_view);
            registry.source_added.connect (add_source_to_view);

            // Add sources
            registry.list_sources (E.SOURCE_EXTENSION_CALENDAR).foreach ((source) => {
                add_source_to_view (source);
            });
        } catch (GLib.Error error) {
            critical (error.message);
        }
    }

    private void header_update_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
        var row_location = ((SourceItem)row).location;
        if (before != null) {
            var before_row_location = ((SourceItem)before).location;
            if (before_row_location == row_location) {
                row.set_header (null);
                return;
            }
        }

        var header = new SourceItemHeader (row_location);
        row.set_header (header);
        header.show_all ();
    }

    private void source_removed (E.Source source) {
        var source_item = src_map.get (source.dup_uid ());
        source_item.hide ();
        src_map.remove (source.dup_uid ());
        source_item.destroy ();
    }

    private void source_disabled (E.Source source) {
        var source_item = src_map.get (source.dup_uid ());
        source_item.source_has_changed ();
    }

    private void create_source () {
        if (src_dialog == null) {
            src_dialog = new SourceDialog ();
            src_dialog.go_back.connect (() => {switch_to_main ();});
            stack.add_named (src_dialog, "source");
        }

        src_dialog.set_source (null);
        switch_to_source ();
    }

    private void add_source_to_view (E.Source source) {
        if (source.enabled == false)
            return;

        if (source.dup_uid () in src_map)
            return;

        var source_item = new SourceItem (source);
        source_item.edit_request.connect (edit_source);
        source_item.remove_request.connect (remove_source);

        calendar_box.add (source_item);

        int minimum_height;
        int natural_height;
        calendar_box.show_all ();
        calendar_box.get_preferred_height (out minimum_height, out natural_height);
        if (natural_height > 200) {
            scroll.set_size_request (-1, 200);
        } else {
            scroll.set_size_request (-1, natural_height);
        }

        source_item.destroy.connect (() => {
            calendar_box.show_all ();
            calendar_box.get_preferred_height (out minimum_height, out natural_height);
            if (natural_height > 200) {
                scroll.set_size_request (-1, 200);
            } else {
                scroll.set_size_request (-1, natural_height);
            }
        });

        src_map.set (source.dup_uid (), source_item);
    }

    private void remove_source (E.Source source) {
        Model.CalendarModel.get_default ().trash_calendar (source);
        var source_item = src_map.get (source.dup_uid ());
        source_item.show_calendar_removed ();
    }

    private void edit_source (E.Source source) {
        if (src_dialog == null) {
            src_dialog = new SourceDialog ();
            src_dialog.go_back.connect (() => {switch_to_main ();});
            stack.add_named (src_dialog, "source");
        }

        src_dialog.set_source (source);
        switch_to_source ();
    }

    private void switch_to_main () {
        main_grid.no_show_all = false;
        main_grid.show ();
        stack.set_visible_child_full ("main", Gtk.StackTransitionType.SLIDE_RIGHT);
        src_dialog.hide ();
        src_dialog.no_show_all = true;
    }

    private void switch_to_source () {
        src_dialog.no_show_all = false;
        src_dialog.show ();
        stack.set_visible_child_full ("source", Gtk.StackTransitionType.SLIDE_LEFT);
        main_grid.hide ();
        main_grid.no_show_all = true;
    }
}
