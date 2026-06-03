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

public class Dialogs.ImportDialog : Adw.Dialog {
    private Gtk.Stack stack;
    private Gtk.Button import_button;
    private Gtk.Spinner spinner;
    private Gtk.Label status_label;
    private Gtk.ListBox preview_list;
    private Gtk.Button confirm_button;
    private Gtk.Button back_button;
    private Services.AI.ImportResult? current_result = null;

    public ImportDialog () {
        Object (
            title: _("Import Tasks"),
            content_width: 560,
            content_height: 500
        );
    }

    ~ImportDialog () {
        debug ("Destroying - Dialogs.ImportDialog\n");
    }

    construct {
        stack = new Gtk.Stack () {
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        };

        stack.add_named (build_file_page (), "file");
        stack.add_named (build_preview_page (), "preview");

        var toolbar = new Adw.ToolbarView ();
        toolbar.add_top_bar (new Adw.HeaderBar ());
        toolbar.content = stack;

        child = toolbar;
    }

    private Gtk.Widget build_file_page () {
        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 16) {
            margin_top = 24, margin_bottom = 24,
            margin_start = 24, margin_end = 24,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };

        var icon = new Gtk.Image.from_icon_name ("document-open-symbolic") {
            pixel_size = 64,
            opacity = 0.6
        };

        var label = new Gtk.Label (_("Select a Markdown or JSON file to import")) {
            wrap = true,
            justify = Gtk.Justification.CENTER
        };

        import_button = new Gtk.Button.with_label (_("Choose file…")) {
            css_classes = { "suggested-action", "pill" },
            halign = Gtk.Align.CENTER
        };

        spinner = new Gtk.Spinner ();

        status_label = new Gtk.Label ("") {
            wrap = true,
            justify = Gtk.Justification.CENTER
        };

        import_button.clicked.connect (open_file_chooser);

        vbox.append (icon);
        vbox.append (label);
        vbox.append (import_button);
        vbox.append (spinner);
        vbox.append (status_label);

        return vbox;
    }

    private Gtk.Widget build_preview_page () {
        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 8) {
            margin_top = 16, margin_bottom = 16,
            margin_start = 16, margin_end = 16,
            vexpand = true
        };

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
        back_button = new Gtk.Button.with_label (_("← Back")) {
            css_classes = { "flat" }
        };
        var preview_label = new Gtk.Label (_("Preview import")) {
            css_classes = { "title-4" },
            hexpand = true,
            xalign = 0
        };
        header_box.append (back_button);
        header_box.append (preview_label);

        preview_list = new Gtk.ListBox () {
            css_classes = { "boxed-list" },
            selection_mode = Gtk.SelectionMode.NONE
        };

        var scroll = new Gtk.ScrolledWindow () {
            child = preview_list,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vexpand = true
        };

        confirm_button = new Gtk.Button.with_label (_("Import all")) {
            css_classes = { "suggested-action" },
            halign = Gtk.Align.END
        };

        back_button.clicked.connect (() => {
            stack.visible_child_name = "file";
        });

        confirm_button.clicked.connect (do_import);

        vbox.append (header_box);
        vbox.append (scroll);
        vbox.append (confirm_button);

        return vbox;
    }

    private void open_file_chooser () {
        var dialog = new Gtk.FileDialog () {
            title = _("Open file"),
            modal = true
        };

        var filter = new Gtk.FileFilter ();
        filter.name = "Markdown / JSON";
        filter.add_pattern ("*.md");
        filter.add_pattern ("*.json");

        var filters = new ListStore (typeof (Gtk.FileFilter));
        filters.append (filter);
        dialog.filters = filters;

        dialog.open.begin (null, null, (obj, res) => {
            try {
                var file = dialog.open.end (res);
                process_file (file);
            } catch (Error e) {
                // user cancelled — no action
            }
        });
    }

    private void process_file (GLib.File file) {
        import_button.sensitive = false;
        spinner.spinning = true;
        status_label.label = _("Analysing with Claude…");

        string content;
        try {
            uint8[] data;
            file.load_contents (null, out data, null);
            content = (string) data;
        } catch (Error e) {
            spinner.spinning = false;
            import_button.sensitive = true;
            status_label.label = _("Could not read file: ") + e.message;
            return;
        }

        string mime_hint = file.get_basename ().down ().has_suffix (".json") ? "json" : "md";

        var mapper = new Services.AI.ImportMapper ();
        mapper.map_file.begin (content, mime_hint, (obj, res) => {
            current_result = mapper.map_file.end (res);
            spinner.spinning = false;
            import_button.sensitive = true;

            if (current_result == null || current_result.projects.is_empty) {
                status_label.label = _("Claude couldn't identify any tasks — try a different file.");
                return;
            }

            populate_preview (current_result);
            stack.visible_child_name = "preview";
        });
    }

    private void populate_preview (Services.AI.ImportResult result) {
        while (preview_list.get_first_child () != null) {
            preview_list.remove (preview_list.get_first_child ());
        }

        foreach (var mp in result.projects) {
            var proj_row = new Adw.ActionRow () {
                title = "📁 " + mp.name
            };
            preview_list.append (proj_row);

            foreach (var ms in mp.sections) {
                if (ms.name != "") {
                    var sec_row = new Adw.ActionRow () {
                        title = "  📂 " + ms.name
                    };
                    preview_list.append (sec_row);
                }

                foreach (var mi in ms.items) {
                    string item_text = "    ☐ " + mi.title;
                    if (mi.due_date != null) item_text += " · " + mi.due_date;
                    var item_row = new Adw.ActionRow () {
                        title = item_text
                    };
                    preview_list.append (item_row);
                }
            }
        }

        // Add ambiguity warnings at top
        foreach (var amb in result.ambiguities) {
            var warn_row = new Adw.ActionRow () {
                title = "⚠ " + amb.line,
                subtitle = amb.reason,
                css_classes = { "warning" }
            };
            preview_list.prepend (warn_row);
        }
    }

    private void do_import () {
        if (current_result == null) return;

        foreach (var mp in current_result.projects) {
            var project = new Objects.Project ();
            project.name = mp.name;
            Services.Store.instance ().insert_project (project);

            foreach (var ms in mp.sections) {
                Objects.Section? section = null;
                if (ms.name != "") {
                    section = new Objects.Section ();
                    section.name = ms.name;
                    section.project_id = project.id;
                    Services.Store.instance ().insert_section (section);
                }

                foreach (var mi in ms.items) {
                    var item = new Objects.Item ();
                    item.content = mi.title;
                    item.description = mi.notes;
                    item.project_id = project.id;
                    item.section_id = section != null ? section.id : "";
                    item.priority = mi.priority;
                    if (mi.due_date != null) item.due.date = mi.due_date;
                    Services.Store.instance ().insert_item (item);
                }
            }
        }

        close ();
    }
}
