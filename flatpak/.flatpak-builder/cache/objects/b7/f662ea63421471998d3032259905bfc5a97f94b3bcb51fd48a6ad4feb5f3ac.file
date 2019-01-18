// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2011-2015 Maya Developers (http://launchpad.net/maya)
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
 * Authored by: Jaap Broekhuizen
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class Maya.View.SourceDialog : Gtk.Grid {
    public EventType event_type { get; private set; default=EventType.EDIT;}

    private Gtk.Entry name_entry;
    private Gtk.ColorButton color_button;
    private bool set_as_default = false;
    private Backend current_backend;
    private Gee.Collection<PlacementWidget> backend_widgets;
    private Gtk.Grid main_grid;
    private Gee.HashMap<string, bool> widgets_checked;
    private Gtk.Button create_button;
    private Gtk.ComboBox type_combobox;
    private Gtk.ListStore list_store;
    private E.Source source = null;

    public signal void go_back ();

    public SourceDialog () {
        widgets_checked = new Gee.HashMap<string, bool> (null, null);

        main_grid = new Gtk.Grid ();
        main_grid.set_row_spacing (6);
        main_grid.set_column_spacing (12);

        margin_start = 6;
        margin_end = 6;
        margin_top = 6;
        set_row_spacing (6);
        set_column_spacing (12);
        expand = true;

        // Buttons

        var buttonbox = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        buttonbox.set_layout (Gtk.ButtonBoxStyle.END);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.margin_end = 6;
        create_button = new Gtk.Button.with_label (_("Create"));

        create_button.clicked.connect (save);
        cancel_button.clicked.connect (() => go_back ());

        buttonbox.pack_end (cancel_button);
        buttonbox.pack_end (create_button);

        // Name
        var name_label = new Gtk.Label (_("Name:"));
        ((Gtk.Misc) name_label).xalign = 1.0f;
        name_entry = new Gtk.Entry ();
        name_entry.placeholder_text = _("Calendar Name");
        name_entry.changed.connect (() => {check_can_validate ();});

        // Type Combobox
        list_store = new Gtk.ListStore (2, typeof (string), typeof (Backend));

        type_combobox = new Gtk.ComboBox.with_model (list_store);

        Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
        type_combobox.pack_start (renderer, true);
        type_combobox.add_attribute (renderer, "text", 0);

        type_combobox.changed.connect (() => {
            GLib.Value backend;
            Gtk.TreeIter b_iter;
            type_combobox.get_active_iter (out b_iter);
            list_store.get_value (b_iter, 1, out backend);
            current_backend = ((Backend)backend);
            remove_backend_widgets ();
            backend_widgets = ((Backend)backend).get_new_calendar_widget (source);
            add_backend_widgets ();
        });

        var type_label = new Gtk.Label (_("Type:"));
        ((Gtk.Misc) type_label).xalign = 1.0f;

        Gtk.TreeIter iter;
        var backends_manager = BackendsManager.get_default ();
        foreach (var backend in backends_manager.backends) {
            list_store.append (out iter);
            list_store.set (iter, 0, backend.get_name (), 1, backend);
        }

        if (backends_manager.backends.size <= 1) {
            type_combobox.no_show_all = true;
            type_label.no_show_all = true;
        }

        type_combobox.set_active (0);

        // Color
        var rgba = Gdk.RGBA ();
        rgba.red = 0.13;
        rgba.green = 0.42;
        rgba.blue = 0.70;
        rgba.alpha = 1;
        var color_label = new Gtk.Label (_("Color:"));
        ((Gtk.Misc) color_label).xalign = 1.0f;
        color_button = new Gtk.ColorButton.with_rgba (rgba);
        color_button.use_alpha = false;

        var check_button = new Gtk.CheckButton.with_label (_("Mark as default calendar"));

        check_button.toggled.connect (() => {
            set_as_default = !set_as_default;
        });

        main_grid.attach (type_label,    0, 0, 1, 1);
        main_grid.attach (type_combobox, 1, 0, 1, 1);
        main_grid.attach (name_label,    0, 1, 1, 1);
        main_grid.attach (name_entry,    1, 1, 1, 1);
        main_grid.attach (color_label,   0, 2, 1, 1);
        main_grid.attach (color_button,  1, 2, 1, 1);
        main_grid.attach (check_button,  1, 3, 1, 1);

        attach (main_grid, 0, 0, 2, 1);

        var fake_label = new Gtk.Grid ();
        fake_label.expand = true;
        attach (fake_label, 0, 1, 2, 1);
        attach (buttonbox, 0, 2, 2, 1);

        show_all ();
    }

    public void set_source (E.Source? source = null) {
        this.source = source;
        if (source == null) {
            event_type = EventType.ADD;
            name_entry.text = "";
            type_combobox.sensitive = true;
            create_button.set_label (_("Create Calendar"));
            var rgba = Gdk.RGBA ();
            rgba.red = 0.13;
            rgba.green = 0.42;
            rgba.blue = 0.70;
            rgba.alpha = 1;
            color_button.set_rgba (rgba);
        } else {
            event_type = EventType.EDIT;
            create_button.set_label (_("Save"));
            name_entry.text = source.display_name;
            type_combobox.sensitive = false;
            type_combobox.set_active (0);
            list_store.foreach (tree_foreach);
            var cal = (E.SourceCalendar)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
            var rgba = Gdk.RGBA ();
            rgba.parse (cal.dup_color ());
            color_button.set_rgba (rgba);
        }
    }

    private bool tree_foreach (Gtk.TreeModel model, Gtk.TreePath path, Gtk.TreeIter iter) {
        GLib.Value backend;
        list_store.get_value (iter, 1, out backend);
        var current_backend = ((Backend)backend);
        if (current_backend.get_uid () == source.dup_parent ()) {
            type_combobox.set_active_iter (iter);
            type_combobox.sensitive = true;
            return true;
        }

        return false;
    }

    private void remove_backend_widgets () {
        if (backend_widgets == null)
            return;

        foreach (var widget in backend_widgets) {
            widget.widget.hide ();
            widget.widget.destroy ();
        }

        backend_widgets.clear ();
    }

    private void add_backend_widgets () {
        widgets_checked.clear ();
        foreach (var widget in backend_widgets) {
            main_grid.attach (widget.widget, widget.column, 4 + widget.row, 1, 1);
            if (widget.needed == true && widget.widget is Gtk.Entry) {
                var entry = widget.widget as Gtk.Entry;
                entry.changed.connect (() => {entry_changed (widget);});
                widgets_checked.set (widget.ref_name, ((Gtk.Entry)widget.widget).text != "");
            }
            widget.widget.show ();
        }
        check_can_validate ();
    }

    private void entry_changed (PlacementWidget widget) {
        widgets_checked.unset (widget.ref_name);
        widgets_checked.set (widget.ref_name, ((Gtk.Entry)widget.widget).text.chug ().char_count () > 0);
        check_can_validate ();
    }

    private void check_can_validate () {
        foreach (var valid in widgets_checked.values) {
            if (valid == false) {
                create_button.sensitive = false;
                return;
            }
        }

        if (name_entry.text != "") {
            create_button.sensitive = true;
        }
    }

    public void save () {
        if (event_type == EventType.ADD) {
            current_backend.add_new_calendar (name_entry.text, Util.get_hexa_color (color_button.rgba), set_as_default, backend_widgets);
            go_back ();
        } else {
            current_backend.modify_calendar (name_entry.text, Util.get_hexa_color (color_button.rgba), set_as_default, backend_widgets, source);
            go_back ();
        }
    }
}
