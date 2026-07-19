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

public class Views.AI.AssistantPanel : Adw.Bin {
    private Adw.BottomSheet bottom_sheet;

    private Gtk.Button prioritize_button;
    private Gtk.Button schedule_button_widget;
    private Gtk.ListBox preview_list;
    private Gtk.Revealer preview_revealer;
    private Gtk.Button apply_button;
    private Gtk.Button cancel_button;
    private Gtk.Spinner spinner;
    private Gtk.Label status_label;

    private Gee.ArrayList<Services.AI.ScheduleSuggestion?>? pending_suggestions = null;
    private Gee.ArrayList<Objects.Item>? current_items = null;
    private ulong status_handler_id = 0;

    ~AssistantPanel () {
        if (status_handler_id != 0) {
            Services.AI.Claude.get_default ().disconnect (status_handler_id);
        }
        debug ("Destroying Views.AI.AssistantPanel\n");
    }

    construct {
        bottom_sheet = new Adw.BottomSheet () {
            can_open = false,
            show_drag_handle = true
        };

        // Sheet content
        var sheet_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            margin_top = 16, margin_bottom = 24,
            margin_start = 16, margin_end = 16
        };

        // Header
        var title_label = new Gtk.Label (_("Claude Assistant")) {
            css_classes = { "title-4" },
            hexpand = true,
            xalign = 0
        };
        var badge = new Widgets.ClaudeStatusBadge ();
        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
        header_box.append (title_label);
        header_box.append (badge);

        // Not-configured notice
        var notice_label = new Gtk.Label (_("Add your API key in Preferences → Claude AI")) {
            css_classes = { "caption", "dim-label" },
            wrap = true
        };
        var notice_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = notice_label,
            reveal_child = !Services.AI.Claude.get_default ().is_configured ()
        };

        status_handler_id = Services.AI.Claude.get_default ().status_changed.connect (() => {
            bool configured = Services.AI.Claude.get_default ().is_configured ();
            notice_revealer.reveal_child = !configured;
            prioritize_button.sensitive = configured;
            schedule_button_widget.sensitive = configured;
        });

        // Action buttons
        spinner = new Gtk.Spinner ();
        bool configured = Services.AI.Claude.get_default ().is_configured ();

        prioritize_button = new Gtk.Button.with_label (_("Prioritize tasks")) {
            css_classes = { "pill" },
            sensitive = configured,
            hexpand = true
        };
        schedule_button_widget = new Gtk.Button.with_label (_("Schedule undated tasks")) {
            css_classes = { "pill" },
            sensitive = configured,
            hexpand = true
        };

        var actions_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
            homogeneous = true
        };
        actions_box.append (prioritize_button);
        actions_box.append (schedule_button_widget);

        status_label = new Gtk.Label ("") { xalign = 0, wrap = true };

        // Preview list
        preview_list = new Gtk.ListBox () {
            css_classes = { "boxed-list" }
        };
        preview_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = preview_list
        };

        apply_button = new Gtk.Button.with_label (_("Apply")) {
            css_classes = { "suggested-action" }
        };
        cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            css_classes = { "flat" }
        };

        var apply_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
            halign = Gtk.Align.END
        };
        apply_box.append (cancel_button);
        apply_box.append (apply_button);
        var apply_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = apply_box
        };

        sheet_box.append (header_box);
        sheet_box.append (notice_revealer);
        sheet_box.append (actions_box);
        sheet_box.append (spinner);
        sheet_box.append (status_label);
        sheet_box.append (preview_revealer);
        sheet_box.append (apply_revealer);

        var scroll = new Gtk.ScrolledWindow () {
            child = sheet_box,
            hscrollbar_policy = Gtk.PolicyType.NEVER
        };

        bottom_sheet.sheet = scroll;
        child = bottom_sheet;

        // Wire up buttons
        prioritize_button.clicked.connect (() => run_suggestions (false));
        schedule_button_widget.clicked.connect (() => run_suggestions (true));

        cancel_button.clicked.connect (() => {
            pending_suggestions = null;
            preview_revealer.reveal_child = false;
            apply_revealer.reveal_child = false;
            status_label.label = "";
        });

        apply_button.clicked.connect (() => {
            apply_suggestions ();
            preview_revealer.reveal_child = false;
            apply_revealer.reveal_child = false;
            status_label.label = _("Applied!");
        });
    }

    public void open_sheet () {
        bottom_sheet.can_open = true;
        bottom_sheet.open = true;
    }

    public void set_sheet_content (Gtk.Widget content_widget) {
        bottom_sheet.content = content_widget;
    }

    private void run_suggestions (bool schedule_mode) {
        current_items = get_current_items (schedule_mode);
        if (current_items == null || current_items.is_empty) {
            status_label.label = _("No tasks to process.");
            return;
        }

        spinner.spinning = true;
        prioritize_button.sensitive = false;
        schedule_button_widget.sensitive = false;
        status_label.label = _("Asking Claude…");

        var sched = new Services.AI.Scheduler ();
        sched.suggest.begin (current_items, (obj, res) => {
            pending_suggestions = sched.suggest.end (res);
            spinner.spinning = false;
            bool configured = Services.AI.Claude.get_default ().is_configured ();
            prioritize_button.sensitive = configured;
            schedule_button_widget.sensitive = configured;

            if (pending_suggestions == null) {
                status_label.label = _("Claude request failed — try again.");
                return;
            }

            status_label.label = _("Review suggested changes:");
            populate_preview (pending_suggestions);
            preview_revealer.reveal_child = true;
            apply_revealer.reveal_child = true;
        });
    }

    private void populate_preview (Gee.ArrayList<Services.AI.ScheduleSuggestion?> suggestions) {
        while (preview_list.get_first_child () != null)
            preview_list.remove (preview_list.get_first_child ());

        foreach (var s in suggestions) {
            Objects.Item? found_item = Services.Store.instance ().get_item (s.item_id);
            if (found_item == null) continue;

            var row = new Adw.ActionRow () {
                title = found_item.content,
                subtitle = s.reason
            };
            if (s.suggested_due_date != null) {
                row.add_suffix (new Gtk.Label (s.suggested_due_date) {
                    css_classes = { "caption" }, valign = Gtk.Align.CENTER
                });
            }
            preview_list.append (row);
        }
    }

    private void apply_suggestions () {
        if (pending_suggestions == null) return;
        foreach (var s in pending_suggestions) {
            Objects.Item? found_item = Services.Store.instance ().get_item (s.item_id);
            if (found_item == null) continue;
            if (s.suggested_due_date != null) {
                found_item.due.date = s.suggested_due_date;
            }
            found_item.priority = s.suggested_priority;
            found_item.update ();
        }
        pending_suggestions = null;
    }

    private Gee.ArrayList<Objects.Item> get_current_items (bool undated_only) {
        var items = new Gee.ArrayList<Objects.Item> ();
        var today = new GLib.DateTime.now_local ();
        var source_items = undated_only
            ? Services.Store.instance ().get_items_by_scheduled (false)
            : Services.Store.instance ().get_items_by_date (today, false);
        foreach (var it in source_items) {
            items.add (it);
        }
        return items;
    }
}
