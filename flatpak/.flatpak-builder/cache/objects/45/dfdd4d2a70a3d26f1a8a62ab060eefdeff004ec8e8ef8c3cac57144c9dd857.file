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

public class Maya.View.Widgets.DynamicSpinner : Gtk.Revealer {
    private Gtk.Popover info_popover;
    private Gtk.Spinner spinner;
    private Gtk.ListBox list_box;
    HashTable<string, Gtk.Widget> children_matcher;
    public DynamicSpinner () {
        transition_type = Gtk.RevealerTransitionType.CROSSFADE;

        children_matcher = new HashTable<string, Gtk.Widget> (str_hash, str_equal);

        spinner = new Gtk.Spinner ();
        var button = new Gtk.Button ();
        button.image = spinner;
        button.clicked.connect (() => {
            info_popover.show_all ();
        });

        list_box = new Gtk.ListBox ();
        list_box.selection_mode = Gtk.SelectionMode.NONE;

        info_popover = new Gtk.Popover (button);
        info_popover.position = Gtk.PositionType.BOTTOM;
        info_popover.add (list_box);

        var calmodel = Model.CalendarModel.get_default ();
        calmodel.connecting.connect ((source, cancellable) => add_source.begin (source, cancellable));
        calmodel.connected.connect ((source) => remove_source.begin (source));

        add (button);

        show_all ();
        spinner.start ();
    }

    public async void add_source (E.Source source, Cancellable cancellable) {
        Idle.add (() => {
            set_reveal_child (true);

            var label = new Gtk.Label (source.get_display_name ());
            var stop_button = new Gtk.Button.from_icon_name ("process-stop", Gtk.IconSize.BUTTON);
            stop_button.clicked.connect (() => {cancellable.cancel ();});

            var grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.column_spacing = 12;
            grid.orientation = Gtk.Orientation.HORIZONTAL;
            grid.add (label);
            grid.add (stop_button);

            lock (children_matcher) {
                children_matcher.insert (source.dup_uid (), grid);
            }
            list_box.add (grid);
            return false;
        });
    }

    public async void remove_source (E.Source source) {
        Idle.add (() => {
            lock (children_matcher) {
                var widget = children_matcher.get (source.dup_uid ());
                children_matcher.remove (source.dup_uid ());
                if (widget != null)
                    widget.destroy ();
                if (children_matcher.size () == 0) {
                    set_reveal_child (false);
                }
            }

            return false;
        });
    }
}
