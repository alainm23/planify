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

public class Dialogs.Preferences.Pages.QuickAdd : Dialogs.Preferences.Pages.BasePage {
    private Gtk.Stack stack;
    private Layouts.HeaderItem backups_group;

    public QuickAdd (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Quick Add")
        );
    }

    ~QuickAdd () {
        print ("Destroying - Dialogs.Preferences.Pages.QuickAdd\n");
    }

    construct {
        string quick_add_command =
            "flatpak run --command=io.github.alainm23.planify.quick-add %s".printf (Build.APPLICATION_ID);
        if (GLib.Environment.get_variable ("SNAP") != null) {
            quick_add_command = "planify.quick-add";
        }

        var description_label = new Gtk.Label (
            _(
                "Use Quick Add to create to-dos from anywhere on your desktop with just a few keystrokes. You don’t even have to leave the app you’re currently in.")
            // vala-lint=line-length
                                ) {
            justify = Gtk.Justification.FILL,
            use_markup = true,
            wrap = true,
            xalign = 0,
            margin_end = 6,
            margin_start = 6
        };

        var description2_label = new Gtk.Label (
            _("Head to System Settings → Keyboard → Shortcuts → Custom, then add a new shortcut with the following:")             // vala-lint=line-length
                                 ) {
            justify = Gtk.Justification.FILL,
            use_markup = true,
            wrap = true,
            xalign = 0,
            margin_top = 6,
            margin_end = 6,
            margin_start = 6
        };

        var copy_button = new Gtk.Button.from_icon_name ("edit-copy-symbolic") {
            valign = CENTER
        };
        copy_button.add_css_class ("flat");

        var command_entry = new Adw.ActionRow ();
        command_entry.add_suffix (copy_button);
        command_entry.title = quick_add_command;
        command_entry.add_css_class ("caption");
        command_entry.add_css_class ("monospace");
        command_entry.add_css_class ("property");

        var command_group = new Adw.PreferencesGroup () {
            margin_top = 12
        };
        command_group.add (command_entry);

        var settings_group = new Adw.PreferencesGroup ();
        settings_group.title = _("Settings");

        var save_last_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = Services.Settings.get_default ().settings.get_boolean ("quick-add-save-last-project")
        };

        var save_last_row = new Adw.ActionRow ();
        save_last_row.title = _("Save Last Selected Project");
        save_last_row.subtitle = _("If unchecked, the default project selected is Inbox");
        save_last_row.set_activatable_widget (save_last_switch);
        save_last_row.add_suffix (save_last_switch);

        settings_group.add (save_last_row);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            vexpand = true,
            hexpand = true
        };

        content_box.append (description_label);
        content_box.append (description2_label);
        content_box.append (command_group);
        content_box.append (settings_group);

        var content_clamp = new Adw.Clamp () {
            maximum_size = 400,
            margin_start = 24,
            margin_end = 24,
            margin_top = 12
        };

        content_clamp.child = content_box;

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = content_clamp;

        child = toolbar_view;

        signal_map[copy_button.clicked.connect (() => {
            Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();
            clipboard.set_text (quick_add_command);
            popup_toast (_("The command was copied to the clipboard"));
        })] = copy_button;

        signal_map[save_last_switch.notify["active"].connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("quick-add-save-last-project",
                                                                   save_last_switch.active);
        })] = save_last_switch;

        destroy.connect (() => {
            clean_up ();
        });
    }

    public override void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();
    }
}