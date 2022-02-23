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

public class Dialogs.Shortcuts.Shortcuts : Hdy.Window {
    public Shortcuts () {
        Object (
            transient_for: (Gtk.Window) Planner.instance.main_window.get_toplevel (),
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            resizable: false,
            height_request: 475
        );
    }

    construct {
        var headerbar = new Hdy.HeaderBar () {
            has_subtitle = false,
            show_close_button = false,
            hexpand = true
        };
        headerbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        headerbar.get_style_context ().add_class ("default-decoration");

        var done_button = new Gtk.Button.with_label (_("Done")) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            can_focus = false
        };
        done_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        done_button.get_style_context ().add_class ("primary-color");

        var title_label = new Gtk.Label (_("Shortcuts"));
        title_label.get_style_context ().add_class ("h4");

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            margin_start = 3,
            margin_end = 3
        };
        header_box.set_center_widget (title_label);
        // header_box.pack_end (done_button, false, false, 0);

        headerbar.set_custom_title (header_box);

        var anywhere_content = new Dialogs.Settings.SettingsContent (_("Used anywhere"));

        anywhere_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Create a new task"),
                {"a"})
        );
        anywhere_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Paste plain text to create new task"),
                {"Ctrl", "v"})
        );
        anywhere_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Create a new project"),
                {"p"})
        );
        anywhere_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Create a new section in a project"),
                {"s"})
        );

        var search_content = new Dialogs.Settings.SettingsContent (_("Search"));

        search_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Open Quick Find"),
            {"Ctrl", "f"})
        );

        search_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Start typing to begin a search"),
            {"any key"})
        );

        var windows_content = new Dialogs.Settings.SettingsContent (_("Control windows"));

        windows_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Quit"),
            {"Ctrl", "q"})
        );

        windows_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Open preferences"),
            {"Ctrl", ","})
        );

        windows_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Open Keyboard Shortcuts"),
            {"f1"})
        );

        var navigate_content = new Dialogs.Settings.SettingsContent (_("Navigate"));

        navigate_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Open Inbox"),
            {"Ctrl", "1"})
        );

        navigate_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Open Today"),
            {"Ctrl", "2"})
        );

        navigate_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Open Scheduled"),
            {"Ctrl", "3"})
        );

        navigate_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Open Pinboard"),
            {"Ctrl", "4"})
        );

        navigate_content.add_child (
            new Dialogs.Shortcuts.ShortcutLabel (_("Go to start page"),
            {"h"})
        );

        var main_grid = new Gtk.Grid () {
            orientation = Gtk.Orientation.VERTICAL,
            width_request = 300
        };
        main_grid.add (headerbar);
        main_grid.add (anywhere_content);
        main_grid.add (search_content);
        main_grid.add (windows_content);
        main_grid.add (navigate_content);
        
        unowned Gtk.StyleContext main_grid_context = main_grid.get_style_context ();
        main_grid_context.add_class ("picker");

        var stack_scrolled = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };
        stack_scrolled.add (main_grid);

        add (stack_scrolled);

        focus_out_event.connect (() => {
            hide_destroy ();
            return false;
        });

        key_release_event.connect ((key) => {
            if (key.keyval == 65307) {
                hide_destroy ();
            }

            return false;
        });

        done_button.clicked.connect (() => {
            hide_destroy ();
        });
    }

    private void hide_destroy () {
        hide ();

        Timeout.add (500, () => {
            destroy ();
            return GLib.Source.REMOVE;
        });
    }
}