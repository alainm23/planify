/*
 * Copyright © 2026 Alain M. (https://github.com/alainm23/planify)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class Dialogs.Preferences.Pages.Claude : Dialogs.Preferences.Pages.BasePage {
    public Claude (Adw.PreferencesDialog preferences_dialog) {
        Object (
            preferences_dialog: preferences_dialog,
            title: _("Claude AI")
        );
    }

    ~Claude () {
        debug ("Destroying - Dialogs.Preferences.Pages.Claude\n");
    }

    construct {
        // Model data — parallel arrays indexed 0/1/2
        string[] model_labels = {
            _("Haiku 4.5 — fastest"),
            _("Sonnet 4.6 — balanced"),
            _("Opus 4.8 — most capable")
        };
        string[] model_ids = {
            "claude-haiku-4-5-20251001",
            "claude-sonnet-4-6",
            "claude-opus-4-8"
        };

        // Row 1 — API key
        var api_key_row = new Adw.PasswordEntryRow ();
        api_key_row.title = _("API Key");

        string? env_key = GLib.Environment.get_variable ("ANTHROPIC_API_KEY");
        if (env_key != null && env_key.length > 0) {
            api_key_row.text = "";
            api_key_row.placeholder_text = _("Set via ANTHROPIC_API_KEY environment variable");
            api_key_row.sensitive = false;
        } else {
            string? stored_key = Services.AI.Claude.get_default ().resolve_api_key ();
            if (stored_key != null && stored_key.length > 0) {
                api_key_row.text = stored_key;
            }
        }

        // Row 2 — Model selector
        var model_string_list = new Gtk.StringList (null);
        foreach (string label in model_labels) {
            model_string_list.append (label);
        }

        var model_row = new Adw.ComboRow ();
        model_row.title = _("Model");
        model_row.model = model_string_list;

        string current_model = Services.Settings.get_default ().settings.get_string ("claude-model");
        uint selected_index = 1; // default to Sonnet
        for (uint i = 0; i < model_ids.length; i++) {
            if (model_ids[i] == current_model) {
                selected_index = i;
                break;
            }
        }
        model_row.selected = selected_index;

        // Row 3 — Connection status
        var status_badge = new Widgets.ClaudeStatusBadge ();

        var test_button = new Gtk.Button.with_label (_("Test connection")) {
            valign = Gtk.Align.CENTER
        };
        test_button.add_css_class ("flat");

        var suffix_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
            valign = Gtk.Align.CENTER
        };
        suffix_box.append (status_badge);
        suffix_box.append (test_button);

        var connection_row = new Adw.ActionRow ();
        connection_row.title = _("Connection");
        connection_row.activatable = false;
        connection_row.add_suffix (suffix_box);

        // Group
        var api_group = new Adw.PreferencesGroup ();
        api_group.description = _("Task content is sent to Anthropic's API to process your requests.");
        api_group.add (api_key_row);
        api_group.add (model_row);
        api_group.add (connection_row);

        // Layout
        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_top = 6
        };
        content_box.append (api_group);

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };
        scrolled_window.child = content_box;

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (new Adw.HeaderBar ());
        toolbar_view.content = scrolled_window;

        child = toolbar_view;

        // Signals
        signal_map[api_key_row.apply.connect (() => {
            string text = api_key_row.text.strip ();
            try {
                if (text.length > 0) {
                    Services.AI.Claude.get_default ().store_api_key (text);
                } else {
                    Services.AI.Claude.get_default ().clear_api_key ();
                }
            } catch (Error e) {
                Services.LogService.get_default ().info ("Preferences.Claude", "API key error: %s".printf (e.message));
            }
        })] = api_key_row;

        signal_map[model_row.notify["selected"].connect (() => {
            uint idx = model_row.selected;
            if (idx < model_ids.length) {
                Services.Settings.get_default ().settings.set_string ("claude-model", model_ids[idx]);
            }
        })] = model_row;

        signal_map[test_button.clicked.connect (() => {
            test_button.sensitive = false;
            Services.AI.Claude.get_default ().ping.begin ((obj, res) => {
                Services.AI.Claude.get_default ().ping.end (res);
                test_button.sensitive = true;
            });
        })] = test_button;

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
