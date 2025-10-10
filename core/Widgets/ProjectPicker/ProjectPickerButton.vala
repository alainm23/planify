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

public class Widgets.ProjectPicker.ProjectPickerButton : Adw.Bin {
    private Objects.Project _project;
    public Objects.Project project {
        set {
            _project = value;
            update_project_request ();
            add_sections (project);
        }

        get {
            return _project;
        }
    }

    private Objects.Section _section;
    public Objects.Section section {
        set {
            _section = value;
            section_label.label = _section.name;
        }
    }

    private Widgets.IconColorProject icon_project;
    private Gtk.Label name_label;
    private Gtk.Label section_label;
    private Gtk.Popover sections_popover;
    private Gtk.Revealer section_box_revealer;
    private Gtk.MenuButton project_button;
    private Widgets.ProjectPicker.ProjectPickerPopover project_picker_popover;
    private Gtk.ListBox sections_listbox;
    private Gtk.Revealer add_section_revealer;
    private Gtk.Label placeholder_message_label;
    private Gtk.Revealer spinner_revealer;

    public signal void project_change (Objects.Project project);
    public signal void section_change (Objects.Section ? section);
    public signal void picker_opened (bool active);

    public Gee.HashMap<string, Widgets.SectionPicker.SectionPickerRow> sections_map = new Gee.HashMap<string, Widgets.SectionPicker.SectionPickerRow> ();
    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    private string PLACEHOLDER_MESSAGE = _("Your list of section will show up here."); // vala-lint=naming-convention
    private string PLACEHOLDER_CREATE_MESSAGE = _("Create '%s'"); // vala-lint=naming-convention

    ~ProjectPickerButton () {
        debug ("Destroying - Widgets.ProjectPicker.ProjectPickerButton\n");
    }

    construct {
        // Project Button
        icon_project = new Widgets.IconColorProject (18);

        name_label = new Gtk.Label (null) {
            valign = Gtk.Align.CENTER,
            ellipsize = Pango.EllipsizeMode.END
        };

        var project_box = new Gtk.Box (HORIZONTAL, 6) {
            valign = CENTER
        };
        project_box.append (icon_project);
        project_box.append (name_label);

        project_picker_popover = new Widgets.ProjectPicker.ProjectPickerPopover ();

        project_button = new Gtk.MenuButton () {
            popover = project_picker_popover,
            child = project_box,
            css_classes = { "flat" }
        };

        // Section Button
        section_label = new Gtk.Label (_("No Section")) {
            valign = Gtk.Align.CENTER,
            ellipsize = Pango.EllipsizeMode.END,
            max_width_chars = 16
        };

        sections_popover = build_sections_popover ();

        var arrow_label = new Gtk.Label ("→");

        var section_button = new Gtk.MenuButton () {
            popover = sections_popover,
            child = section_label,
            css_classes = { "flat" }
        };

        var section_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        section_box.append (arrow_label);
        section_box.append (section_button);

        section_box_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            reveal_child = true,
            child = section_box
        };

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.append (project_button);
        box.append (section_box_revealer);

        child = box;

        signal_map[project_picker_popover.selected.connect ((_project) => {
            project = _project;
            update_project_request ();
            add_sections (_project);
            project_change (_project);

            section_label.label = _("No Section");
            section_change (null);
        })] = project_picker_popover;

        signal_map[project_picker_popover.closed.connect (() => {
            picker_opened (false);
        })] = project_picker_popover;

        signal_map[project_picker_popover.show.connect (() => {
            picker_opened (true);
            if (_project != null) {
                project_picker_popover.set_selected_project (_project);
            }
        })] = project_picker_popover;

        signal_map[sections_popover.closed.connect (() => {
            picker_opened (false);
        })] = sections_popover;

        signal_map[sections_popover.show.connect (() => {
            picker_opened (true);
        })] = sections_popover;
    }

    public void update_project_request () {
        name_label.label = project.is_inbox_project ? _("Inbox") : project.name;
        icon_project.project = project;
        icon_project.update_request ();
        section_box_revealer.reveal_child = project.sections.size > 0 && project.source_type != SourceType.CALDAV;
    }

    private Gtk.Popover build_sections_popover () {
        var search_entry = new Gtk.SearchEntry () {
            margin_top = 9,
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9
        };

        sections_listbox = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true,
            css_classes = { "listbox-background" },
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 9
        };

        sections_listbox.set_placeholder (get_section_placeholder ());

        var scrolled_window = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true,
            child = sections_listbox
        };

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (search_entry);
        toolbar_view.content = scrolled_window;

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM,
            child = toolbar_view,
            height_request = 225,
            width_request = 255,
            css_classes = { "popover-contents" }
        };

        signal_map[sections_listbox.row_activated.connect ((row) => {
            sections_popover.popdown ();

            Objects.Section section = ((Widgets.SectionPicker.SectionPickerRow) row).section;

            section_label.label = section.name;
            section_change (section.id == "" ? null : section);
        })] = sections_listbox;

        signal_map[search_entry.search_changed.connect (() => {
            int size = 0;

            sections_listbox.set_filter_func ((row) => {
                Objects.Section section = ((Widgets.SectionPicker.SectionPickerRow) row).section;
                var return_value = search_entry.text.down () in section.name.down ();

                if (return_value) {
                    size++;
                }

                return return_value;
            });

            add_section_revealer.reveal_child = size <= 0;
            placeholder_message_label.label = size <= 0 ? PLACEHOLDER_CREATE_MESSAGE.printf (search_entry.text) : PLACEHOLDER_MESSAGE;
        })] = search_entry;

        var search_entry_ctrl_key = new Gtk.EventControllerKey ();
        search_entry.add_controller (search_entry_ctrl_key);
        signal_map[search_entry_ctrl_key.key_pressed.connect ((keyval, keycode, state) => {
            if (keyval == 65307) {
                popover.popdown ();
            }

            return false;
        })] = search_entry_ctrl_key;

        signal_map[search_entry.activate.connect (() => {
            if (search_entry.text.length <= 0) {
                return;
            }

            add_assign_section (search_entry.text);
        })] = search_entry;

        var listbox_controller_key = new Gtk.EventControllerKey ();
        sections_listbox.add_controller (listbox_controller_key);
        signal_map[listbox_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            var key = Gdk.keyval_name (keyval).replace ("KP_", "");

            if (key == "Up" || key == "Down") {
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
            } else {
                if (!search_entry.has_focus) {
                    search_entry.grab_focus ();
                    if (search_entry.cursor_position < search_entry.text.length) {
                        search_entry.set_position (search_entry.text.length);
                    }
                }
            }

            return false;
        })] = listbox_controller_key;

        return popover;
    }

    private void add_assign_section (string name) {
        var section = new Objects.Section ();
        section.name = name;
        section.project_id = project.id;

        if (section.project.source_type == SourceType.LOCAL) {
            section.id = Util.get_default ().generate_id (section);
            section.project.add_section_if_not_exists (section);
            _add_assign_section (section);
            return;
        }

        if (section.project.source_type == SourceType.TODOIST) {
            spinner_revealer.reveal_child = true;
            Services.Todoist.get_default ().add.begin (section, (obj, res) => {
                spinner_revealer.reveal_child = false;
                HttpResponse response = Services.Todoist.get_default ().add.end (res);

                if (response.status) {
                    section.id = response.data;
                    section.project.add_section_if_not_exists (section);
                    _add_assign_section (section);
                } else {
                    Services.EventBus.get_default ().send_error_toast (response.error_code, response.error);
                }
            });
        }
    }

    private void _add_assign_section (Objects.Section section) {
        section_label.label = section.name;
        section_change (section);

        sections_map[section.id] = new Widgets.SectionPicker.SectionPickerRow (section);
        sections_listbox.append (sections_map[section.id]);

        sections_popover.popdown ();
    }

    private void add_sections (Objects.Project project) {
        foreach (Widgets.SectionPicker.SectionPickerRow row in sections_map.values) {
            sections_listbox.remove (row);
        }

        sections_map.clear ();

        sections_map["no-section"] = new Widgets.SectionPicker.SectionPickerRow.for_no_section ();
        sections_listbox.append (sections_map["no-section"]);
        foreach (Objects.Section section in project.sections) {
            sections_map[section.id] = new Widgets.SectionPicker.SectionPickerRow (section);
            sections_listbox.append (sections_map[section.id]);
        }
    }

    private Gtk.Widget get_section_placeholder () {
        var add_icon = new Gtk.Image.from_icon_name ("tab-new-symbolic") {
            pixel_size = 24,
            margin_bottom = 12
        };

        add_section_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            child = add_icon
        };

        placeholder_message_label = new Gtk.Label (null) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            css_classes = { "dimmed" }
        };

        var spinner = new Adw.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            height_request = 24,
            width_request = 24,
            margin_top = 12,
            css_classes = { "text-color" }
        };

        spinner_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            child = spinner
        };

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            valign = CENTER,
            margin_start = 24,
            margin_end = 24,
            margin_bottom = 24
        };
        box.append (add_section_revealer);
        box.append (placeholder_message_label);
        box.append (spinner_revealer);

        return box;
    }

    public void open_picker () {
        project_button.active = true;
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        if (project_picker_popover != null) {
            project_picker_popover.clean_up ();
        }
    }
}
