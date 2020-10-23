/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Dialogs.ShortcutsDialog : Gtk.Dialog {
    public ShortcutsDialog () {
        Object (
            transient_for: Planner.instance.main_window,
            deletable: true,
            resizable: true,
            modal: false,
            title: _("Keyboard Shortcuts")
        );
    }

    construct {
        Planner.event_bus.unselect_all ();
        get_style_context ().add_class ("release-dialog");
        get_style_context ().add_class ("app");
        width_request = 525;
        height_request = 600;

        use_header_bar = 1;
        var header_bar = (Gtk.HeaderBar) get_header_bar ();
        header_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        header_bar.get_style_context ().add_class ("oauth-dialog");
        header_bar.get_style_context ().add_class ("default-decoration");
        
        string keys = Planner.settings.get_string ("quick-add-shortcut");
        uint accelerator_key;
        Gdk.ModifierType accelerator_mods;
        Gtk.accelerator_parse (keys, out accelerator_key, out accelerator_mods);
        var shortcut_hint = Gtk.accelerator_get_label (accelerator_key, accelerator_mods);

        var column = new Gtk.Grid ();
        column.column_spacing = 12;
        column.row_spacing = 6;
        column.hexpand = true;
        column.column_homogeneous = false;

        var create_new_items_header = new Gtk.Label (_("Used anywhere"));
        create_new_items_header.halign = Gtk.Align.START;
        create_new_items_header.get_style_context ().add_class ("font-bold");

        var change_label = new Gtk.Label (_("Change"));
        change_label.halign = Gtk.Align.START;
        change_label.get_style_context ().add_class ("inbox");

        var change_eventbox = new Gtk.EventBox ();
        change_eventbox.add (change_label);

        change_eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS) {
                destroy ();
                
                var dialog = new Dialogs.Preferences.Preferences ("quick-add");
                dialog.destroy.connect (Gtk.main_quit);
                dialog.show_all ();

                return true;
            }

            return false;
        });

        column.attach (create_new_items_header, 1, 0);
        column.attach (new Widgets.ShortcutLabel ({"a"}), 0, 1);
        column.attach (new NameLabel (_("Create a new task")), 1, 1);
        column.attach (new Widgets.ShortcutLabel ({"q"}), 0, 2);
        column.attach (new NameLabel (_("Create a new task at the top of the list")), 1, 2);
        column.attach (new Widgets.ShortcutLabel ({"Ctrl", "v"}), 0, 3);
        column.attach (new NameLabel (_("Paste plain text to create new task")), 1, 3);
        column.attach (new Widgets.ShortcutLabel ({"p"}), 0, 4);
        column.attach (new NameLabel (_("Create a new project")), 1, 4);
        column.attach (new Widgets.ShortcutLabel ({"f"}), 0, 5);
        column.attach (new NameLabel (_("Create a new folder")), 1, 5);
        column.attach (new Widgets.ShortcutLabel ({"s"}), 0, 6);
        column.attach (new NameLabel (_("Create a new section in a project")), 1, 6);
        column.attach (new Widgets.ShortcutLabel ({"d"}), 0, 7);
        column.attach (new NameLabel (_("Sort by date")), 1, 7);
        column.attach (new Widgets.ShortcutLabel ({"r"}), 0, 8);
        column.attach (new NameLabel (_("Sort by priority")), 1, 8);

        column.attach (new Widgets.ShortcutLabel ({"n"}), 0, 9);
        column.attach (new NameLabel (_("Sort by name")), 1, 9);

        column.attach (new Widgets.ShortcutLabel ({"Ctrl", "h"}), 0, 10);
        column.attach (new NameLabel (_("Hide all tasks details")), 1, 10);

        column.attach (new Widgets.ShortcutLabel (shortcut_hint.split ("+")), 0, 11);
        column.attach (new NameLabel (_("Open Quick Add")), 1, 11);
        column.attach (change_eventbox, 1, 12);

        var search_header = new Gtk.Label (_("Search"));
        search_header.halign = Gtk.Align.START;
        search_header.get_style_context ().add_class ("font-bold");
        search_header.margin_top = 12;

        column.attach (search_header, 1, 13);
        column.attach (new Widgets.ShortcutLabel ({"Ctrl", "f"}), 0, 14);
        column.attach (new NameLabel (_("Open Quick Find")), 1, 14);
        column.attach (new Widgets.ShortcutLabel ({"any key"}), 0, 15);
        column.attach (new NameLabel (_("Start typing to begin a search")), 1, 15);
        column.attach (new Widgets.ShortcutLabel ({"p1, p2, p3"}), 0, 16);
        column.attach (new NameLabel (_("Filter by priorities")), 1, 16);
        column.attach (new Widgets.ShortcutLabel ({_("Labels")}), 0, 17);
        column.attach (new NameLabel (_("Quick Find list for all labels")), 1, 17);
        column.attach (new Widgets.ShortcutLabel ({_("Projects")}), 0, 18);
        column.attach (new NameLabel (_("Quick Find list for all projects")), 1, 18);
        column.attach (new Widgets.ShortcutLabel ({_("Completed")}), 0, 19);
        column.attach (new NameLabel (_("Filter by all your completed tasks.")), 1, 19);

        var control_windows_header = new Gtk.Label (_("Control windows"));
        control_windows_header.halign = Gtk.Align.START;
        control_windows_header.get_style_context ().add_class ("font-bold");
        control_windows_header.margin_top = 12;

        column.attach (control_windows_header, 1, 20);
        column.attach (new Widgets.ShortcutLabel ({"Ctrl", "q"}), 0, 21);
        column.attach (new NameLabel (_("Quit")), 1, 21);
        column.attach (new Widgets.ShortcutLabel ({"Ctrl", ","}), 0, 22);
        column.attach (new NameLabel (_("Open preferences")), 1, 22);
        column.attach (new Widgets.ShortcutLabel ({"Ctrl", "w",}), 0, 23);
        column.attach (new NameLabel (_("Open current project new window")), 1, 23);
        column.attach (new Widgets.ShortcutLabel ({"Super", "Alt", "←"}), 0, 24);
        column.attach (new NameLabel (_("Move project window to left workspace")), 1, 24);
        column.attach (new Widgets.ShortcutLabel ({"Super", "Alt", "→"}), 0, 25);
        column.attach (new NameLabel (_("Move project window to right workspace")), 1, 25);
        column.attach (new Widgets.ShortcutLabel ({"f1"}), 0, 26);
        column.attach (new NameLabel (_("Open Keyboard Shortcuts")), 1, 26);

        var navigate_header = new Gtk.Label (_("Navigate"));
        navigate_header.halign = Gtk.Align.START;
        navigate_header.get_style_context ().add_class ("font-bold");
        navigate_header.margin_top = 12;

        column.attach (navigate_header, 1, 27);
        column.attach (new Widgets.ShortcutLabel ({"Ctrl", "1"}), 0, 28);
        column.attach (new NameLabel (_("Open Inbox")), 1, 28);
        column.attach (new Widgets.ShortcutLabel ({"Ctrl", "2"}), 0, 29);
        column.attach (new NameLabel (_("Open Today")), 1, 29);
        column.attach (new Widgets.ShortcutLabel ({"Ctrl", "3"}), 0, 30);
        column.attach (new NameLabel (_("Open Upcoming")), 1, 30);
        column.attach (new Widgets.ShortcutLabel ({"h"}), 0, 31);
        column.attach (new NameLabel (_("Go to start page")), 1, 31);
        
        var grid = new Gtk.Grid ();
        grid.halign = Gtk.Align.CENTER;
        grid.column_spacing = 12;
        grid.margin_bottom = 12;
        grid.hexpand = true;
        grid.attach (column, 0, 0);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled.expand = true;
        scrolled.add (grid);

        var content_area = get_content_area ();
        content_area.border_width = 0;
        content_area.add (scrolled);
    }

    private class NameLabel : Gtk.Label {
        public NameLabel (string label) {
            Object (
                label: label
            );
        }

        construct {
            halign = Gtk.Align.START;
            xalign = 1;
        }
    }
}
