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

public class Services.ActionManager : Object {
    public Planify app { get; construct; }
    public MainWindow window { get; construct; }

    public SimpleActionGroup actions { get; construct; }

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_QUIT_Q = "action_quit_q";
    public const string ACTION_QUIT_W = "action_quit_w";
    public const string ACTION_PREFERENCES = "action_preferences";
    public const string ACTION_SHORTCUTS = "action_shortcuts";
    public const string ACTION_ADD_TASK = "action_add_task";
    public const string ACTION_ADD_TASK_PASTE = "action_add_task_paste";
    public const string ACTION_OPEN_SEARCH = "action_open_search";
    public const string ACTION_SYNC_MANUALLY = "action_sync_manually";
    public const string ACTION_NEW_PROJECT = "action_new_project";
    public const string ACTION_NEW_SECTION = "action_new_section";
    public const string ACTION_VIEW_HOMEPAGE = "action_view_homepage";
    public const string ACTION_VIEW_INBOX = "action_view_inbox";
    public const string ACTION_VIEW_TODAY = "action_view_today";
    public const string ACTION_VIEW_SCHEDULED = "action_view_scheduled";
    public const string ACTION_VIEW_PINBOARD = "action_view_pinboard";
    public const string ACTION_VIEW_LABELS = "action_view_labels";
    public const string ACTION_VIEW_HOME = "action_view_home";
    public const string ACTION_SHOW_HIDE_SIDEBAR = "action_show_hide_sidebar";

    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();
    public static Gee.MultiMap<string, string> typing_accelerators = new Gee.HashMultiMap<string, string> ();

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_QUIT_Q, action_quit },
        { ACTION_QUIT_W, action_quit },
        { ACTION_PREFERENCES, action_preferences },
        { ACTION_SHORTCUTS, action_shortcuts },
        { ACTION_ADD_TASK, action_add_task },
        { ACTION_ADD_TASK_PASTE, action_add_task_paste },
        { ACTION_OPEN_SEARCH, action_open_search },
        { ACTION_SYNC_MANUALLY, action_sync_manually },
        { ACTION_NEW_PROJECT, action_new_project },
        { ACTION_NEW_SECTION, action_new_section },
        { ACTION_VIEW_HOMEPAGE, action_view_homepage },
        { ACTION_VIEW_INBOX, action_view_inbox },
        { ACTION_VIEW_TODAY, action_view_today },
        { ACTION_VIEW_SCHEDULED, action_view_scheduled },
        { ACTION_VIEW_PINBOARD, action_view_pinboard },
        { ACTION_VIEW_LABELS, action_view_labels },
        { ACTION_VIEW_HOME, action_view_home },
        { ACTION_SHOW_HIDE_SIDEBAR, action_show_hide_sidebar }
    };

    public ActionManager (Planify app, MainWindow window) {
        Object (
            app: app,
            window: window
        );
    }

    static construct {
        action_accelerators.set (ACTION_QUIT_Q, "<Control>q");
        action_accelerators.set (ACTION_QUIT_W, "<Control>w");
        action_accelerators.set (ACTION_PREFERENCES, "<Control>comma");
        action_accelerators.set (ACTION_SHORTCUTS, "F1");
        action_accelerators.set (ACTION_OPEN_SEARCH, "<Control>f");
        action_accelerators.set (ACTION_SYNC_MANUALLY, "<Control>s");
        action_accelerators.set (ACTION_VIEW_HOMEPAGE, "<Control>h");
        action_accelerators.set (ACTION_VIEW_INBOX, "<Control>i");
        action_accelerators.set (ACTION_VIEW_TODAY, "<Control>t");
        action_accelerators.set (ACTION_VIEW_SCHEDULED, "<Control>u");
        action_accelerators.set (ACTION_VIEW_LABELS, "<Control>l");
        action_accelerators.set (ACTION_VIEW_PINBOARD, "<Control>p");

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
            var accels_array = action_accelerators[action].to_array ();
            accels_array += null;
            app.set_accels_for_action (ACTION_PREFIX + action, accels_array);
        }

        enable_typing_accels ();

        Services.EventBus.get_default ().disconnect_typing_accel.connect (disable_typing_accels);
        Services.EventBus.get_default ().connect_typing_accel.connect (enable_typing_accels);

        Services.EventBus.get_default ().disconnect_all_accels.connect (disable_all_accel);
        Services.EventBus.get_default ().connect_all_accels.connect (enable_all_accel);
    }

    // Temporarily disable all the accelerators that might interfere with input fields.
    private void disable_typing_accels () {
        foreach (var action in typing_accelerators.get_keys ()) {
            app.set_accels_for_action (ACTION_PREFIX + action, {});
        }
    }

    private void disable_action_accels () {
        foreach (var action in action_accelerators.get_keys ()) {
            app.set_accels_for_action (ACTION_PREFIX + action, {});
        }
    }

    // Enable all the accelerators that might interfere with input fields.
    private void enable_typing_accels () {
        foreach (var action in typing_accelerators.get_keys ()) {
            var accels_array = typing_accelerators[action].to_array ();
            accels_array += null;
            app.set_accels_for_action (ACTION_PREFIX + action, accels_array);
        }
    }

    private void enable_action_accels () {
        foreach (var action in action_accelerators.get_keys ()) {
            var accels_array = action_accelerators[action].to_array ();
            accels_array += null;
            app.set_accels_for_action (ACTION_PREFIX + action, accels_array);
        }
    }

    private void disable_all_accel () {
        disable_typing_accels ();
        disable_action_accels ();
    }

    private void enable_all_accel () {
        enable_typing_accels ();
        enable_action_accels ();
    }

    private void action_quit () {
        window.destroy ();
    }

    private void action_preferences () {
        window.open_preferences_window ();
    }

    private void action_open_search () {
        var dialog = new Dialogs.QuickFind.QuickFind ();
        dialog.present (Planify._instance.main_window);
    }

    private void action_sync_manually () {
        foreach (Objects.Source source in Services.Store.instance ().sources) {
            source.run_server ();
        }
    }

    private void action_new_project () {
        var dialog = new Dialogs.Project.new (SourceType.LOCAL.to_string (), true);
        dialog.present (Planify._instance.main_window);
    }

    private void action_view_homepage () {
        window.go_homepage ();
    }

    private void action_view_inbox () {
        Services.EventBus.get_default ().pane_selected (PaneType.FILTER, Objects.Filters.Inbox.get_default ().view_id);
    }

    private void action_view_today () {
        Services.EventBus.get_default ().pane_selected (PaneType.FILTER, Objects.Filters.Today.get_default ().view_id);
    }

    private void action_view_scheduled () {
        Services.EventBus.get_default ().pane_selected (PaneType.FILTER, Objects.Filters.Scheduled.get_default ().view_id);
    }

    private void action_view_labels () {
        Services.EventBus.get_default ().pane_selected (PaneType.FILTER, Objects.Filters.Labels.get_default ().view_id);
    }

    private void action_view_pinboard () {
        Services.EventBus.get_default ().pane_selected (PaneType.FILTER, Objects.Filters.Pinboard.get_default ().view_id);
    }

    private void action_show_hide_sidebar () {
        window.show_hide_sidebar ();
    }

    private void action_new_section () {
        window.new_section_action ();
    }

    private void action_add_task () {
        window.add_task_action ();
    }

    private void action_add_task_paste () {
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
        window.open_shortcuts_window ();
    }

    private void action_view_home () {
        window.go_homepage ();
    }
}
