// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2014-2015 Maya Developers (http://launchpad.net/maya)
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

public class Maya.View.Widgets.CalendarButton : Gtk.ToggleButton {
    public GLib.List<E.Source> sources;
    private E.Source _current_source;
    public E.Source current_source {
        get {
            return _current_source;
        }

        set {
            _current_source = value;
            calendar_grid.source = value;
            tooltip_text = "%s - %s".printf (calendar_grid.label, calendar_grid.location);
        }
    }

    private Gtk.Popover popover;
    private Gtk.ListBox list_box;
    private CalendarGrid calendar_grid;

    public CalendarButton () {
        sources = new GLib.List<E.Source> ();
        var calmodel = Model.CalendarModel.get_default ();
        var registry = calmodel.registry;
        foreach (var src in registry.list_sources (E.SOURCE_EXTENSION_CALENDAR)) {
            if (src.writable == true && src.enabled == true && calmodel.calclient_is_readonly (src) == false) {
                sources.append (src);
            }
        }

        _current_source = registry.default_calendar;

        calendar_grid = new CalendarGrid (current_source);
        calendar_grid.halign = Gtk.Align.START;
        calendar_grid.hexpand = true;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.add (calendar_grid);
        grid.add (new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU));

        add (grid);

        current_source = registry.default_calendar;
        create_popover ();

        toggled.connect (() => {
            if (active) {
                popover.show_all ();
            } else {
                popover.hide ();
            }
        });

        popover.hide.connect (() => {
            active = false;
        });
    }

    private void create_popover () {
        list_box = new Gtk.ListBox ();
        list_box.activate_on_single_click = true;

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled.add (list_box);
        scrolled.margin_top = 6;
        scrolled.margin_bottom = 6;

        popover = new Gtk.Popover (this);
        popover.width_request = 310;
        popover.add (scrolled);

        list_box.add.connect ((widget) => {
            list_box.show_all ();
            int minimum_height;
            int natural_height;

            list_box.get_preferred_height (out minimum_height, out natural_height);
            if (natural_height > 300) {
                scrolled.height_request = 300;
            } else {
                scrolled.height_request = (int) natural_height;
            }
        });

        list_box.set_header_func (header_update_func);

        list_box.set_sort_func ((row1, row2) => {
            var child1 = (CalendarGrid)row1.get_child ();
            var child2 = (CalendarGrid)row2.get_child ();
            var comparison = child1.location.collate (child2.location);
            if (comparison == 0) {
                return child1.label.collate (child2.label);
            } else {
                return comparison;
            }
        });

        list_box.row_activated.connect ((row) => {
            current_source = ((CalendarGrid)row.get_child ()).source;
        });

        foreach (var source in sources) {
            add_source (source);
        }
    }

    private void add_source (E.Source source) {
        var calgrid = new CalendarGrid (source);
        calgrid.margin = 6;
        calgrid.margin_start = 12;

        var row = new Gtk.ListBoxRow ();
        row.add (calgrid);

        list_box.add (row);

        if (source.dup_uid () == current_source.dup_uid ()) {
            list_box.select_row (row);
        }
    }

    private void header_update_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? before) {
        var row_location = ((CalendarGrid)row.get_child ()).location;
        if (before != null) {
            var before_row_location = ((CalendarGrid)before.get_child ()).location;
            if (before_row_location == row_location) {
                row.set_header (null);
                return;
            }
        }

        var header = new SourceItemHeader (row_location);
        header.margin = 6;
        header.margin_bottom = 0;

        row.set_header (header);

        header.show_all ();
        if (before == null) {
            header.margin_top = 0;
        }
    }

    public class CalendarGrid : Gtk.Grid {
        public string label { public get; private set; }
        public string location { public get; private set; }
        private E.Source _source;
        public E.Source source {
            get {
                return _source;
            }

            set {
                _source = value;
                apply_source ();
            }
        }

        private Gtk.Label calendar_name_label;
        private Gtk.Label calendar_color_label;

        public CalendarGrid (E.Source source) {
            column_spacing = 6;

            calendar_color_label = new Gtk.Label ("");
            calendar_color_label.width_request = 6;

            calendar_name_label = new Gtk.Label ("");
            calendar_name_label.xalign = 0;
            calendar_name_label.hexpand = true;
            calendar_name_label.ellipsize = Pango.EllipsizeMode.MIDDLE;

            add (calendar_color_label);
            add (calendar_name_label);

            show_all ();
            _source = source;
            apply_source ();
        }

        private void apply_source () {
            E.SourceCalendar cal = (E.SourceCalendar)_source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            calendar_name_label.label = _source.dup_display_name ();
            label = calendar_name_label.label;
            location = Maya.Util.get_source_location (_source);
            Util.style_calendar_color (calendar_color_label, cal.dup_color (), true);
        }
    }
}
