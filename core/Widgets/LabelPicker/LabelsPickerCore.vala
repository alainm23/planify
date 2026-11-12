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

public class Widgets.LabelsPickerCore : Adw.Bin {
    public LabelPickerType picker_type { get; construct; }

    private Gtk.SearchEntry search_entry;
    private Gtk.ListBox listbox;
    private Gtk.Label placeholder_message_label;
    private Gtk.Label placeholder_title_label;
    private Gtk.Image placeholder_icon;
    private Gtk.Revealer add_tag_revealer;
    private Gtk.Revealer spinner_revealer;
    private Gtk.Revealer search_entry_revealer;
    private Gtk.ToggleButton filter_button;
    private bool hide_unused;

    private Gee.HashMap<string, Gtk.CheckButton> new_label_color_buttons = new Gee.HashMap<string, Gtk.CheckButton> ();
    private Gee.ArrayList<Gtk.CheckButton> new_label_color_order = new Gee.ArrayList<Gtk.CheckButton> ();
    private Gtk.Revealer new_label_color_revealer;
    private string new_label_color;

    private const double EDGE_SCROLL_ZONE = 24;
    private const double EDGE_SCROLL_MAX_STEP = 6;

    private uint edge_scroll_id = 0;
    private double edge_scroll_step = 0;

    public Gee.ArrayList<Objects.Label> labels {
        set {
            picked.clear ();

            foreach (var entry in labels_widgets_map.entries) {
                entry.value.active = false;
            }

            foreach (Objects.Label label in value) {
                if (labels_widgets_map.has_key (label.id)) {
                    labels_widgets_map[label.id].active = true;
                }
                picked[label.id] = label;
            }
        }
    }

    Objects.Source _source;
    public Objects.Source source {
        set {
            _source = value;
            add_labels (_source);
        }

        get {
            return _source;
        }
    }

    public bool is_loading {
        set {
            spinner_revealer.reveal_child = value;
        }
    }

    public Gee.HashMap<string, Widgets.LabelPicker.LabelRow> labels_widgets_map = new Gee.HashMap<string, Widgets.LabelPicker.LabelRow> ();
    public Gee.HashMap<string, Objects.Label> picked = new Gee.HashMap<string, Objects.Label> ();

    private string PLACEHOLDER_MESSAGE = _("Your list of filters will show up here. Create one by entering the name and pressing the Enter key."); // vala-lint=naming-convention
    private string PLACEHOLDER_CREATE_MESSAGE = _("Create '%s'"); // vala-lint=naming-convention

    public signal void close ();

    private Gee.HashMap<ulong, weak GLib.Object> signals_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public LabelsPickerCore (LabelPickerType picker_type) {
        Object (
            picker_type: picker_type
        );
    }

    ~LabelsPickerCore () {
        debug ("Destroying - Widgets.LabelsPickerCore\n");
    }

    construct {
        if (picker_type == LabelPickerType.FILTER_ONLY) {
            PLACEHOLDER_MESSAGE = _("Your list of filters will show up here.");
        }

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = picker_type == LabelPickerType.FILTER_ONLY ? _("Search") : _("Search or Create"),
            valign = Gtk.Align.CENTER,
            hexpand = true
        };

        hide_unused = Services.Settings.get_default ().settings.get_boolean ("label-picker-hide-unused");

        filter_button = new Gtk.ToggleButton () {
            icon_name = "funnel-outline-symbolic",
            active = hide_unused,
            valign = Gtk.Align.CENTER,
            tooltip_text = _("Hide unused labels"),
            css_classes = { "flat" }
        };

        var search_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };
        search_box.append (search_entry);
        search_box.append (filter_button);

        search_entry_revealer = new Gtk.Revealer () {
            child = search_box,
            reveal_child = true
        };

        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = Gtk.Align.START
        };
        listbox.add_css_class ("listbox-background");
        listbox.set_placeholder (get_placeholder ());
        listbox.set_sort_func ((row1, row2) => {
            Objects.Label item1 = ((Widgets.LabelPicker.LabelRow) row1).label;
            Objects.Label item2 = ((Widgets.LabelPicker.LabelRow) row2).label;
            return item1.item_order - item2.item_order;
        });

        var listbox_grid = new Adw.Bin () {
            margin_start = 9,
            margin_end = 9,
            margin_bottom = 6,
            child = listbox,
            valign = Gtk.Align.START
        };

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            hexpand = true,
            vexpand = true
        };

        listbox_scrolled.child = listbox_grid;

        var toolbar_view = new Adw.ToolbarView ();
        toolbar_view.add_top_bar (search_entry_revealer);
        toolbar_view.content = listbox_scrolled;

        child = toolbar_view;

        var listbox_controller_key = new Gtk.EventControllerKey ();
        listbox.add_controller (listbox_controller_key);
        signals_map[listbox_controller_key.key_pressed.connect ((keyval, keycode, state) => {
            var key = Gdk.keyval_name (keyval).replace ("KP_", "");

            if (key == "Up") {
                var selected_row = listbox.get_selected_row ();
                
                if (selected_row != null) {
                    Gtk.ListBoxRow first_visible_row = null;
                    int index = 0;
                    while (true) {
                        var row = listbox.get_row_at_index (index);
                        if (row == null) break;
                        if (row.get_child_visible ()) {
                            first_visible_row = row;
                            break;
                        }
                        index++;
                    }
                    
                    if (first_visible_row != null && selected_row == first_visible_row) {
                        search_entry.grab_focus ();
                        search_entry.set_position (search_entry.text.length);
                        return true;
                    }
                }
            } else if (key == "Down") {
            } else if (key == "Enter" || key == "Return" || key == "KP_Enter") {
            } else if (key == "BackSpace") {
                if (!search_entry.has_focus && search_entry.text.length > 0) {
                    search_entry.grab_focus ();
                    int pos = search_entry.text.length;
                    search_entry.delete_text (pos - 1, pos);
                    search_entry.set_position (pos - 1);
                    return true;
                }
            } else {
                if (!search_entry.has_focus) {
                    unichar c = Gdk.keyval_to_unicode (keyval);
                    if (c.isprint ()) {
                        search_entry.grab_focus ();
                        int pos = search_entry.text.length;
                        search_entry.insert_text (c.to_string (), -1, ref pos);
                        search_entry.set_position (pos);
                        return true;
                    }
                }
            }

            return false;
        })] = listbox_controller_key;

        signals_map[search_entry.search_changed.connect (() => {
            invalidate_filter ();
        })] = search_entry;

        signals_map[filter_button.toggled.connect (() => {
            hide_unused = filter_button.active;
            Services.Settings.get_default ().settings.set_boolean ("label-picker-hide-unused", hide_unused);
            invalidate_filter ();
        })] = filter_button;

        signals_map[search_entry.activate.connect (() => {
            if (source != null && search_entry.text.length > 0) {
                Objects.Label label = Services.Store.instance ().get_label_by_name (search_entry.text, true, source.id);
                if (label != null) {
                    if (labels_widgets_map.has_key (label.id_string)) {
                        labels_widgets_map[label.id_string].update_checked_toggled ();
                    }
                } else {
                    add_assign_label ();
                }
            }
        })] = search_entry;

        var search_entry_ctrl_key = new Gtk.EventControllerKey ();
        search_entry.add_controller (search_entry_ctrl_key);
        signals_map[search_entry_ctrl_key.key_pressed.connect ((keyval, keycode, state) => {
            var key = Gdk.keyval_name (keyval).replace ("KP_", "");
            
            if (keyval == Gdk.Key.Escape) {
                close ();
            } else if (key == "Down") {
                // While creating a label, Down goes to its colors.
                if (focus_color_strip ()) {
                    return true;
                }

                var first_row = listbox.get_row_at_index (0);
                if (first_row != null) {
                    first_row.grab_focus ();
                }
                return true;
            }

            return false;
        })] = search_entry_ctrl_key;

        signals_map[Services.Store.instance ().label_added.connect ((label) => {
            add_label (label);
        })] = Services.Store.instance ();
    }

    private void add_assign_label () {
        var label = new Objects.Label ();
        label.color = new_label_color;
        label.name = search_entry.text;

        // The next label starts with a new random color again.
        reset_new_label_color ();
        label.source_id = source.id;

        if (source.source_type == SourceType.LOCAL || source.source_type == SourceType.CALDAV) {
            label.id = Util.get_default ().generate_id (label);
            Services.Store.instance ().insert_label (label);
            checked_toggled (label, true);

            search_entry.text = "";
            close ();
        } else if (source.source_type == SourceType.TODOIST) {
            is_loading = true;
            Services.Todoist.get_default ().add.begin (label, (obj, res) => {
                HttpResponse response = Services.Todoist.get_default ().add.end (res);

                if (response.status) {
                    label.id = response.data;
                    Services.Store.instance ().insert_label (label);
                    checked_toggled (label, true);
                }

                close ();
                is_loading = false;
                search_entry.text = "";
            });
        }
    }

    private void add_labels (Objects.Source source) {
        labels_widgets_map.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            listbox.remove (child);
        }

        foreach (Objects.Label label in Services.Store.instance ().get_labels_by_source (source.id)) {
            add_label (label);
        }
    }

    private void add_label (Objects.Label label) {
        labels_widgets_map[label.id] = new Widgets.LabelPicker.LabelRow (label);
        signals_map[labels_widgets_map[label.id].checked_toggled.connect (checked_toggled)] = labels_widgets_map[label.id];
        listbox.append (labels_widgets_map[label.id]);
    }

    private Gtk.Widget get_placeholder () {
        placeholder_icon = new Gtk.Image.from_icon_name ("tag-outline-add-symbolic") {
            pixel_size = 32,
            margin_bottom = 12,
            css_classes = { "dimmed" }
        };

        add_tag_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_UP,
            child = placeholder_icon
        };

        placeholder_title_label = new Gtk.Label (_("No Labels")) {
            css_classes = { "title-4" }
        };

        placeholder_message_label = new Gtk.Label (PLACEHOLDER_MESSAGE) {
            wrap = true,
            justify = Gtk.Justification.CENTER,
            css_classes = { "dimmed", "caption" },
            margin_top = 4
        };

        new_label_color_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
            child = build_color_strip ()
        };

        reset_new_label_color ();

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
            halign = CENTER,
            margin_start = 24,
            margin_end = 24,
            margin_top = 24
        };
        box.append (add_tag_revealer);
        box.append (placeholder_title_label);
        box.append (new_label_color_revealer);
        box.append (placeholder_message_label);
        box.append (spinner_revealer);

        return box;
    }

    private Gtk.Widget build_color_strip () {
        var colors_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
            margin_start = 6,
            margin_end = 6,
            margin_top = 9,
            margin_bottom = 26
        };

        var colors_list = new Gee.ArrayList<Objects.Color> ();
        foreach (var entry in Util.get_default ().get_colors ().entries) {
            if (!entry.key.has_prefix ("#")) {
                colors_list.add (entry.value);
            }
        }

        colors_list.sort ((a, b) => {
            return a.id - b.id;
        });

        Gtk.CheckButton? group = null;
        foreach (Objects.Color color_obj in colors_list) {
            var color_button = new Gtk.CheckButton () {
                valign = Gtk.Align.CENTER,
                tooltip_text = color_obj.name,
                css_classes = { "color-radio", "small" },
                group = group,
                focus_on_click = false
            };

            if (group == null) {
                group = color_button;
            }

            Util.get_default ().set_widget_color (color_obj.hexadecimal, color_button);
            new_label_color_buttons[color_obj.name_code] = color_button;
            new_label_color_order.add (color_button);
            colors_box.append (color_button);

            string name_code = color_obj.name_code;
            signals_map[color_button.toggled.connect (() => {
                if (color_button.active) {
                    new_label_color = name_code;
                }
            })] = color_button;
        }

        var colors_key = new Gtk.EventControllerKey () {
            propagation_phase = Gtk.PropagationPhase.CAPTURE
        };
        colors_box.add_controller (colors_key);
        signals_map[colors_key.key_pressed.connect ((keyval, keycode, state) => {
            int index = focused_color_index ();

            switch (keyval) {
                case Gdk.Key.Left:
                case Gdk.Key.Right:
                    if (index < 0) {
                        return false;
                    }

                    int next = index + (keyval == Gdk.Key.Right ? 1 : -1);
                    if (next >= 0 && next < new_label_color_order.size) {
                        new_label_color_order[next].active = true;
                        new_label_color_order[next].grab_focus ();
                    }
                    return true;

                case Gdk.Key.Return:
                case Gdk.Key.KP_Enter:
                    if (source != null && search_entry.text.length > 0) {
                        add_assign_label ();
                    }
                    return true;

                case Gdk.Key.Up:
                case Gdk.Key.Escape:
                    search_entry.grab_focus ();
                    search_entry.set_position (-1);
                    return true;
            }

            return false;
        })] = colors_key;

        var scrolled = new Gtk.ScrolledWindow () {
            child = colors_box,
            hscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
            vscrollbar_policy = Gtk.PolicyType.NEVER,
            overlay_scrolling = false,
            propagate_natural_height = true,
            width_request = 220,
            tooltip_text = _("Label color")
        };

        setup_edge_autoscroll (scrolled);

        return scrolled;
    }
    
    private void setup_edge_autoscroll (Gtk.ScrolledWindow scrolled) {
        var motion = new Gtk.EventControllerMotion ();
        scrolled.add_controller (motion);

        signals_map[motion.motion.connect ((x, y) => {
            double width = scrolled.get_width ();

            if (x < EDGE_SCROLL_ZONE) {
                edge_scroll_step = -EDGE_SCROLL_MAX_STEP * (1 - x / EDGE_SCROLL_ZONE);
            } else if (x > width - EDGE_SCROLL_ZONE) {
                edge_scroll_step = EDGE_SCROLL_MAX_STEP * (1 - (width - x) / EDGE_SCROLL_ZONE);
            } else {
                edge_scroll_step = 0;
            }

            if (edge_scroll_step != 0 && edge_scroll_id == 0) {
                edge_scroll_id = Timeout.add (16, () => {
                    var adjustment = scrolled.hadjustment;
                    double max_value = adjustment.upper - adjustment.page_size;
                    double value = (adjustment.value + edge_scroll_step).clamp (adjustment.lower, max_value);

                    // Stop at the ends or when the mouse left the edge.
                    if (edge_scroll_step == 0 || value == adjustment.value) {
                        edge_scroll_id = 0;
                        return GLib.Source.REMOVE;
                    }

                    adjustment.value = value;
                    return GLib.Source.CONTINUE;
                });
            }
        })] = motion;

        signals_map[motion.leave.connect (() => {
            stop_edge_autoscroll ();
        })] = motion;
    }

    private void stop_edge_autoscroll () {
        edge_scroll_step = 0;

        if (edge_scroll_id != 0) {
            GLib.Source.remove (edge_scroll_id);
            edge_scroll_id = 0;
        }
    }

    private int focused_color_index () {
        for (int i = 0; i < new_label_color_order.size; i++) {
            if (new_label_color_order[i].has_focus) {
                return i;
            }
        }

        return -1;
    }

    private bool focus_color_strip () {
        if (!new_label_color_revealer.reveal_child) {
            return false;
        }

        if (new_label_color_buttons.has_key (new_label_color)) {
            new_label_color_buttons[new_label_color].grab_focus ();
            return true;
        }

        return false;
    }

    private void reset_new_label_color () {
        new_label_color = Util.get_default ().get_random_color ();

        if (new_label_color_buttons.has_key (new_label_color)) {
            new_label_color_buttons[new_label_color].active = true;
        }
    }

    private void checked_toggled (Objects.Label label, bool active) {
        if (active) {
            if (!picked.has_key (label.id)) {
                picked[label.id] = label;
            }
        } else {
            if (picked.has_key (label.id)) {
                picked.unset (label.id);
            }
        }
    }

    private void invalidate_filter () {
        string search_text = search_entry.text.down ();
        int size = 0;

        listbox.set_filter_func ((row) => {
            var label = ((Widgets.LabelPicker.LabelRow) row).label;

            if (hide_unused && label.label_count <= 0) {
                return false;
            }

            var matches_search = search_text in label.name.down ();
            if (matches_search) {
                size++;
            }

            return matches_search;
        });

        if (picker_type == LabelPickerType.FILTER_AND_CREATE) {
            if (hide_unused && size <= 0 && search_text.length == 0) {
                placeholder_icon.icon_name = "funnel-outline-symbolic";
                add_tag_revealer.reveal_child = true;
                new_label_color_revealer.reveal_child = false;
                placeholder_title_label.label = _("All Hidden");
                placeholder_message_label.label = _("All labels are hidden by the filter. Disable the filter to see them.");
            } else if (size <= 0) {
                placeholder_icon.icon_name = "tag-outline-add-symbolic";
                add_tag_revealer.reveal_child = true;
                // Only offer a color when there is a name to create.
                new_label_color_revealer.reveal_child = search_text.length > 0;
                placeholder_title_label.label = PLACEHOLDER_CREATE_MESSAGE.printf (search_entry.text);
                placeholder_message_label.label = _("Press Enter to create and assign it");
            } else {
                placeholder_title_label.label = _("No Labels");
                placeholder_message_label.label = PLACEHOLDER_MESSAGE;
                add_tag_revealer.reveal_child = false;
                new_label_color_revealer.reveal_child = false;
            }
        }
    }

    public void reset () {
        foreach (var entry in labels_widgets_map.entries) {
            labels_widgets_map[entry.key].active = false;
        }

        labels_widgets_map.clear ();
    }

    public void add_labels_list (Gee.ArrayList<Objects.Label> labels_list) {
        labels_widgets_map.clear ();

        foreach (unowned Gtk.Widget child in Util.get_default ().get_children (listbox)) {
            listbox.remove (child);
        }

        foreach (Objects.Label label in labels_list) {
            add_label (label);
        }
    }

    public void clean_up () {
        listbox.set_sort_func (null);
        listbox.set_filter_func (null);

        foreach (var entry in labels_widgets_map.entries) {
            labels_widgets_map[entry.key].clean_up ();
        }

        foreach (var entry in signals_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signals_map.clear ();
        new_label_color_buttons.clear ();
        new_label_color_order.clear ();
        stop_edge_autoscroll ();
    }
}
