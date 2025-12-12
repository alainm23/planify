/*
 * Copyright © 2025 Alain M. (https://github.com/alainm23/planify)
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

public class Dialogs.Preferences.Pages.TaskSetting : Dialogs.Preferences.Pages.BasePage {
    public TaskSetting (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Task Settings")
        );
    }

    ~TaskSetting () {
        debug ("Destroying - Dialogs.Preferences.Pages.TaskSetting\n");
    }

    construct {
        var group = new Adw.PreferencesGroup () {
            title = _("General")
        };

        var complete_tasks_model = new Gtk.StringList (null);
        complete_tasks_model.append (_("Complete Instantly"));
        complete_tasks_model.append (_("Complete with Undo"));

        var complete_tasks_row = new Widgets.ComboWrapRow ();
        complete_tasks_row.title = _("Task Completion");
        complete_tasks_row.subtitle = _("Choose how tasks behave when marked as complete");
        complete_tasks_row.model = complete_tasks_model;
        complete_tasks_row.selected = Services.Settings.get_default ().settings.get_enum ("complete-task");

        group.add (complete_tasks_row);

        var default_priority_model = new Gtk.StringList (null);
        default_priority_model.append (_("Priority 1"));
        default_priority_model.append (_("Priority 2"));
        default_priority_model.append (_("Priority 3"));
        default_priority_model.append (_("None"));

        var default_priority_row = new Adw.ComboRow ();
        default_priority_row.title = _("Default Priority");
        default_priority_row.model = default_priority_model;
        default_priority_row.selected = Services.Settings.get_default ().settings.get_enum ("default-priority");

        group.add (default_priority_row);

        var underline_completed_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = Services.Settings.get_default ().settings.get_boolean ("underline-completed-tasks")
        };

        var underline_completed_row = new Adw.ActionRow ();
        underline_completed_row.title = _("Cross Out Completed Tasks");
        underline_completed_row.set_activatable_widget (underline_completed_switch);
        underline_completed_row.add_suffix (underline_completed_switch);

        group.add (underline_completed_row);

        var tasks_position_model = new Gtk.StringList (null);
        tasks_position_model.append (_("Start"));
        tasks_position_model.append (_("End"));

        var tasks_position_row = new Adw.ComboRow ();
        tasks_position_row.title = _("New Task Position");
        tasks_position_row.model = tasks_position_model;
        tasks_position_row.selected = Services.Settings.get_default ().settings.get_enum ("new-tasks-position");

        group.add (tasks_position_row);

        var show_completed_subtasks = new Adw.SwitchRow ();
        show_completed_subtasks.title = _("Always Show Completed Sub-Tasks");
        show_completed_subtasks.subtitle = _("Keep all completed subtasks visible without collapsing them");
        Services.Settings.get_default ().settings.bind ("always-show-completed-subtasks", show_completed_subtasks,
                                                        "active", GLib.SettingsBindFlags.DEFAULT);

        group.add (show_completed_subtasks);

        var task_complete_tone = new Adw.SwitchRow ();
        task_complete_tone.title = _("Task Complete Tone");
        task_complete_tone.subtitle = _("Play a sound when tasks are completed");
        Services.Settings.get_default ().settings.bind ("task-complete-tone", task_complete_tone, "active",
                                                        GLib.SettingsBindFlags.DEFAULT);

        group.add (task_complete_tone);

        var open_task_sidebar = new Adw.SwitchRow ();
        open_task_sidebar.title = _("Open Tasks in Sidebar View");
        open_task_sidebar.subtitle = _("Always display task details in the sidebar instead of expanding in list view.");
        Services.Settings.get_default ().settings.bind ("open-task-sidebar", open_task_sidebar, "active",
                                                        GLib.SettingsBindFlags.DEFAULT);

        group.add (open_task_sidebar);

        var attention_at_one = new Adw.SwitchRow ();
        attention_at_one.title = _("Single Task Focus Mode");
        attention_at_one.subtitle = _("Allow only one task to be expanded at a time in list view");
        Services.Settings.get_default ().settings.bind ("attention-at-one", attention_at_one, "active",
                                                        GLib.SettingsBindFlags.DEFAULT);
        Services.Settings.get_default ().settings.bind ("open-task-sidebar", attention_at_one, "sensitive",
                                                        GLib.SettingsBindFlags.INVERT_BOOLEAN);

        group.add (attention_at_one);

        var markdown_item = new Adw.SwitchRow ();
        markdown_item.title = _("Enable Markdown Formatting");
        markdown_item.subtitle = _("Toggle Markdown support for tasks on or off");
        Services.Settings.get_default ().settings.bind ("enable-markdown-formatting", markdown_item, "active",
                                                        GLib.SettingsBindFlags.DEFAULT);

        group.add (markdown_item);

        var always_show_sidebar_item = new Adw.SwitchRow ();
        always_show_sidebar_item.title = _("Always Show Details Sidebar");
        always_show_sidebar_item.subtitle = _("Keep the details sidebar always visible for faster task navigation, without repeatedly opening and closing it");
        Services.Settings.get_default ().settings.bind ("always-show-details-sidebar", always_show_sidebar_item,
                                                        "active", GLib.SettingsBindFlags.DEFAULT);

        group.add (always_show_sidebar_item);

        var spell_checking_item = new Adw.SwitchRow ();
        spell_checking_item.title = _("Enable Spell Checking");
        spell_checking_item.subtitle = _("Check spelling in task descriptions and notes");
        Services.Settings.get_default ().settings.bind ("spell-checking-enabled", spell_checking_item,
                                                        "active", GLib.SettingsBindFlags.DEFAULT);

        group.add (spell_checking_item);

        var reminders_group = new Adw.PreferencesGroup () {
            title = _("Reminders")
        };

        var automatic_reminders = new Adw.SwitchRow ();
        automatic_reminders.title = _("Enabled");
        Services.Settings.get_default ().settings.bind ("automatic-reminders-enabled", automatic_reminders, "active",
                                                        GLib.SettingsBindFlags.DEFAULT);

        var reminders_model = new Gtk.StringList (null);
        reminders_model.append (_("At due time"));
        reminders_model.append (_("10 minutes before"));
        reminders_model.append (_("30 minutes before"));
        reminders_model.append (_("45 minutes before"));
        reminders_model.append (_("1 hour before"));
        reminders_model.append (_("2 hours before"));
        reminders_model.append (_("3 hours before"));

        var reminders_comborow = new Widgets.ComboWrapRow ();
        reminders_comborow.title = _("Automatic reminders");
        reminders_comborow.subtitle =
            _("When enabled, a reminder before the task’s due time will be added by default.");
        reminders_comborow.model = reminders_model;
        reminders_comborow.selected = Services.Settings.get_default ().settings.get_enum ("automatic-reminders");
        Services.Settings.get_default ().settings.bind ("automatic-reminders-enabled", reminders_comborow, "sensitive",
                                                        GLib.SettingsBindFlags.DEFAULT);

        reminders_group.add (automatic_reminders);
        reminders_group.add (reminders_comborow);

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_top = 6
        };
        content_box.append (group);
        content_box.append (reminders_group);

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = content_box
        };

        var toolbar_view = new Adw.ToolbarView () {
            content = scrolled_window
        };
        toolbar_view.add_top_bar (new Adw.HeaderBar ());

        child = toolbar_view;

        signal_map[complete_tasks_row.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_enum ("complete-task", complete_tasks_row.selected);
        })] = complete_tasks_row;

        signal_map[default_priority_row.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_enum ("default-priority",
                                                                (int) default_priority_row.selected);
        })] = default_priority_row;

        signal_map[tasks_position_row.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_enum ("new-tasks-position",
                                                                (int) tasks_position_row.selected);
        })] = tasks_position_row;

        signal_map[underline_completed_switch.notify["active"].connect (() => {
            Services.Settings.get_default ().settings.set_boolean ("underline-completed-tasks",
                                                                   underline_completed_switch.active);
        })] = underline_completed_switch;

        signal_map[reminders_comborow.notify["selected"].connect (() => {
            Services.Settings.get_default ().settings.set_enum ("automatic-reminders", reminders_comborow.selected);
        })] = reminders_comborow;

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