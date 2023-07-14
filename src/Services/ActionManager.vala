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
    public const string ACTION_ADD_TASK_PASTE = "action_add_task_paste";
    public const string ACTION_OPEN_SEARCH = "action_open_search";
    public const string ACTION_OPEN_LABELS = "action_open_labels";
    public const string ACTION_SYNC_MANUALLY = "action_sync_manually";
    public const string ACTION_NEW_PROJECT = "action_new_project";
    public const string ACTION_NEW_SECTION = "action_new_section";
    public const string ACTION_VIEW_INBOX = "action_view_inbox";
    public const string ACTION_VIEW_TODAY = "action_view_today";
    public const string ACTION_VIEW_SCHEDULED = "action_view_scheduled";
    public const string ACTION_VIEW_PINBOARD = "action_view_pinboard";
    public const string ACTION_VIEW_HOME = "action_view_home";
    public const string ACTION_ESC = "action_esc";
    public const string ACTION_SHOW_HIDE_SIDEBAR = "action_esc";
    
    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();
    public static Gee.MultiMap<string, string> typing_accelerators = new Gee.HashMultiMap<string, string> ();

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_QUIT, action_quit },
        { ACTION_PREFERENCES, action_preferences },
        { ACTION_SHORTCUTS, action_shortcuts },
        { ACTION_ADD_TASK, action_add_task },
        { ACTION_ADD_TASK_PASTE, action_add_task_paste },
        { ACTION_OPEN_SEARCH, action_open_search },
        { ACTION_OPEN_LABELS, action_open_labels },
        { ACTION_SYNC_MANUALLY, action_sync_manually },
        { ACTION_NEW_PROJECT, action_new_project },
        { ACTION_NEW_SECTION, action_new_section },
        { ACTION_VIEW_INBOX, action_view_inbox },
        { ACTION_VIEW_TODAY, action_view_today },
        { ACTION_VIEW_SCHEDULED, action_view_scheduled },
        { ACTION_VIEW_PINBOARD, action_view_pinboard },
        { ACTION_VIEW_HOME, action_view_home },
        { ACTION_ESC, action_esc },
        { ACTION_SHOW_HIDE_SIDEBAR, action_show_hide_sidebar }
    };

    public ActionManager (Planner app, MainWindow window) {
        Object (
            app: app,
            window: window
        );
    }

    static construct {
        action_accelerators.set (ACTION_QUIT, "<Control>q");
        action_accelerators.set (ACTION_PREFERENCES, "<Control>comma");
        action_accelerators.set (ACTION_SHORTCUTS, "F1");
        action_accelerators.set (ACTION_OPEN_SEARCH, "<Control>f");
        action_accelerators.set (ACTION_OPEN_LABELS, "<Control>l");
        action_accelerators.set (ACTION_SYNC_MANUALLY, "<Control>s");
        action_accelerators.set (ACTION_VIEW_INBOX, "<Control>1");
        action_accelerators.set (ACTION_VIEW_TODAY, "<Control>2");
        action_accelerators.set (ACTION_VIEW_SCHEDULED, "<Control>3");
        action_accelerators.set (ACTION_VIEW_PINBOARD, "<Control>4");
        action_accelerators.set (ACTION_ESC, "Escape");

        typing_accelerators.set (ACTION_ADD_TASK, "a");
        typing_accelerators.set (ACTION_ADD_TASK_PASTE, "<Control>v");
        typing_accelerators.set (ACTION_NEW_PROJECT, "p");
        typing_accelerators.set (ACTION_NEW_SECTION, "s");
        typing_accelerators.set (ACTION_VIEW_HOME, "h");
        typing_accelerators.set (ACTION_SHOW_HIDE_SIDEBAR, "m");
    }

    construct {
        actions = new SimpleActionGroup ();
        actions.add_action_entries (ACTION_ENTRIES, this);
        window.insert_action_group ("win", actions);

        foreach (var action in action_accelerators.get_keys ()) {
            app.set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
        }

        enable_typing_accels ();

        Services.EventBus.get_default ().disconnect_typing_accel.connect (disable_typing_accels);
        Services.EventBus.get_default ().connect_typing_accel.connect (enable_typing_accels);
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
        Services.EventBus.get_default ().unselect_all ();

        var dialog = new Dialogs.Preferences.PreferencesWindow ();
        dialog.show ();
    }

    private void action_open_search () {
        Services.EventBus.get_default ().unselect_all ();

        var dialog = new Dialogs.QuickFind.QuickFind ();
        dialog.show ();
    }

    private void action_sync_manually () {
        Services.EventBus.get_default ().unselect_all ();

        if (Services.Todoist.get_default ().is_logged_in ()) {
            Services.Todoist.get_default ().sync_async ();
        }
    }

    private void action_new_project () {
        Services.EventBus.get_default ().unselect_all ();

        // TODO: Update Backend Type instance default by user
        var dialog = new Dialogs.Project.new (BackendType.LOCAL, true);
        dialog.show ();
    }

    private void action_view_inbox () {
        Services.EventBus.get_default ().unselect_all ();
        Services.EventBus.get_default ().pane_selected (PaneType.FILTER, FilterType.INBOX.to_string ());
    }

    private void action_view_today () {
        Services.EventBus.get_default ().unselect_all ();
        Services.EventBus.get_default ().pane_selected (PaneType.FILTER, FilterType.TODAY.to_string ());
    }

    private void action_view_scheduled () {
        Services.EventBus.get_default ().unselect_all ();
        Services.EventBus.get_default ().pane_selected (PaneType.FILTER, FilterType.SCHEDULED.to_string ());
    }

    private void action_view_pinboard () {
        Services.EventBus.get_default ().unselect_all ();
        Services.EventBus.get_default ().pane_selected (PaneType.FILTER, FilterType.FILTER.to_string ());
    }

    private void action_esc () {
        Services.EventBus.get_default ().unselect_all ();
        Services.EventBus.get_default ().item_selected (null);
    }

    private void action_show_hide_sidebar () {
        Services.EventBus.get_default ().unselect_all ();
        window.show_hide_sidebar ();
    }

    private void action_new_section () {
        Services.EventBus.get_default ().unselect_all ();
        window.new_section_action ();
    }

    private void action_add_task () {
        Services.EventBus.get_default ().unselect_all ();
        window.add_task_action ();
    }

    private void action_add_task_paste () {
        Services.EventBus.get_default ().unselect_all ();
        Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();

        clipboard.read_text_async.begin (null, (obj, res) => {
            try {
                string content = clipboard.read_text_async.end (res);
                window.add_task_action (content);
            } catch (GLib.Error error) {
                debug (error.message);
            }
        });
    }

    private void action_shortcuts () {
        Services.EventBus.get_default ().unselect_all ();
        //  var dialog = new Gtk.ShortcutsWindow ();
        //  dialog.show ();
    }

    private void action_view_home () {
        Services.EventBus.get_default ().unselect_all ();
        window.go_homepage ();
    }

    private void action_open_labels () {
        Services.EventBus.get_default ().unselect_all ();
        Services.EventBus.get_default ().open_labels ();
    }
}
