/*/
*- Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
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

public class Services.ActionManager : Object {
    public weak Planner app { get; construct; }
    public weak MainWindow window { get; construct; }

    public SimpleActionGroup actions { get; construct; }

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_QUIT = "action_quit";
    public const string ACTION_PREFERENCES = "action_preferences";
    public const string ACTION_SHORTCUTS = "action_shortcuts";
    public const string ACTION_ADD_TASK = "action_add_task";
    public const string ACTION_ADD_TASK_TOP = "action_add_task_top";
    public const string ACTION_ADD_TASK_PASTE = "action_add_task_paste";
    public const string ACTION_OPEN_SEARCH = "action_open_search";
    public const string ACTION_SYNC_MANUALLY = "action_sync_manually";
    public const string ACTION_NEW_PROJECT = "action_new_project";
    public const string ACTION_NEW_SECTION = "action_new_section";
    public const string ACTION_NEW_FOLDER = "action_new_folder";
    public const string ACTION_VIEW_INBOX = "action_view_inbox";
    public const string ACTION_VIEW_TODAY = "action_view_today";
    public const string ACTION_VIEW_UPCOMING = "action_view_upcoming";
    public const string ACTION_ESC = "action_esc";
    
    
    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();
    public static Gee.MultiMap<string, string> typing_accelerators = new Gee.HashMultiMap<string, string> ();

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_QUIT, action_quit },
        { ACTION_PREFERENCES, action_preferences },
        { ACTION_SHORTCUTS, action_shortcuts },
        { ACTION_ADD_TASK, action_add_task },
        { ACTION_ADD_TASK_TOP, action_add_task_top },
        { ACTION_ADD_TASK_PASTE, action_add_task_paste },
        { ACTION_ADD_TASK, action_add_task },
        { ACTION_OPEN_SEARCH, action_open_search },
        { ACTION_SYNC_MANUALLY, action_sync_manually },
        { ACTION_NEW_PROJECT, action_new_project },
        { ACTION_NEW_SECTION, action_new_section },
        { ACTION_NEW_FOLDER, action_new_folder },
        { ACTION_VIEW_INBOX, action_view_inbox },
        { ACTION_VIEW_TODAY, action_view_today },
        { ACTION_VIEW_UPCOMING, action_view_upcoming },
        { ACTION_ESC, action_esc },
    };

    public ActionManager (Planner planner_app, MainWindow window) {
        Object (
            app: planner_app,
            window: window
        );
    }

    static construct {
        action_accelerators.set (ACTION_QUIT, "<Control>q");
        action_accelerators.set (ACTION_PREFERENCES, "<Control>comma");
        action_accelerators.set (ACTION_SHORTCUTS, "F1");
        action_accelerators.set (ACTION_OPEN_SEARCH, "<Control>f");
        action_accelerators.set (ACTION_SYNC_MANUALLY, "<Control>s");
        action_accelerators.set (ACTION_VIEW_INBOX, "<Control>1");
        action_accelerators.set (ACTION_VIEW_TODAY, "<Control>2");
        action_accelerators.set (ACTION_VIEW_UPCOMING, "<Control>3");

        typing_accelerators.set (ACTION_ADD_TASK, "a");
        typing_accelerators.set (ACTION_ADD_TASK_TOP, "q");
        typing_accelerators.set (ACTION_ADD_TASK_PASTE, "<Control>v");
        typing_accelerators.set (ACTION_NEW_PROJECT, "p");
        typing_accelerators.set (ACTION_NEW_SECTION, "s");
        typing_accelerators.set (ACTION_NEW_FOLDER, "f");
        typing_accelerators.set (ACTION_ESC, "Escape");
    }

    construct {
        actions = new SimpleActionGroup ();
        actions.add_action_entries (ACTION_ENTRIES, this);
        window.insert_action_group ("win", actions);

        foreach (var action in action_accelerators.get_keys ()) {
            app.set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
        }

        enable_typing_accels ();

        Planner.event_bus.disconnect_typing_accel.connect (disable_typing_accels);
        Planner.event_bus.connect_typing_accel.connect (enable_typing_accels);
    }

    // Temporarily disable all the accelerators that might interfere with input fields.
    private void disable_typing_accels () {
        foreach (var action in typing_accelerators.get_keys ()) {
            app.set_accels_for_action (ACTION_PREFIX + action, {});
        }
    }

    // Enable all the accelerators that might interfere with input fields.
    private void enable_typing_accels () {
        foreach (var action in typing_accelerators.get_keys ()) {
            app.set_accels_for_action (ACTION_PREFIX + action, typing_accelerators[action].to_array ());
        }
    }

    private void action_quit () {
        window.destroy ();
    }

    private void action_preferences () {
        var dialog = new Dialogs.Preferences.Preferences ();
        dialog.destroy.connect (Gtk.main_quit);
        dialog.show_all ();
    }

    private void action_shortcuts () {
        var dialog = new Dialogs.ShortcutsDialog ();
        dialog.destroy.connect (Gtk.main_quit);
        dialog.show_all ();
    }

    private void action_add_task () {
        window.add_task_action (-1);
    }

    private void action_add_task_top () {
        window.add_task_action (0);
    }

    private void action_open_search () {
        window.show_quick_find ();
    }

    private void action_sync_manually () {
        Planner.todoist.sync ();
    }

    private void action_new_project () {
        window.new_project ();
    }

    private void action_new_folder () {
        var area = new Objects.Area ();
        area.name = _("New area");
        Planner.database.insert_area (area);
    }

    private void action_new_section () {
        window.new_section_action ();
    }

    private void action_view_inbox () {
        window.go_view (0);
    }

    private void action_view_today () {
        window.go_view (1);
    }

    private void action_view_upcoming () {
        window.go_view (2);
    }

    private void action_add_task_paste () {
        Gdk.Display display = Gdk.Display.get_default ();
        Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
        string text = clipboard.wait_for_text ();

        if (text != null && text.strip () != "") {
            window.add_task_clipboard_action (text);
        } else {
            Planner.notifications.send_notification (
                _("Empty clipboard, copy some text and try again")
            );
        }
    }

    private void action_esc () {
        window.hide_item ();
    }
}
