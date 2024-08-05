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

public class Dialogs.CompletedTasks : Adw.Dialog {
    public Objects.Project project { get; construct; }

    private Adw.NavigationView navigation_view;
    private Gtk.ListBox listbox;
    private Gtk.SearchEntry search_entry;

    public Gee.HashMap <string, Widgets.CompletedTaskRow> items_checked = new Gee.HashMap <string, Widgets.CompletedTaskRow> ();

    public CompletedTasks (Objects.Project project) {
        Object (
            project: project,
            title: _("Completed Tasks"),
            content_width: 450,
            content_height: 500
        );
    }

    ~CompletedTasks () {
        print ("Destroying Dialogs.CompletedTasks\n");
    }

    construct {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search"),
            hexpand = true,
            css_classes = { "border-radius-9" },
			margin_start = 12,
			margin_end = 12
        };

        listbox = new Gtk.ListBox () {
            hexpand = true,
            valign = START,
            css_classes = { "listbox-background", "listbox-separator-6" },
            margin_start = 12,
			margin_end = 12
        };
        
        listbox.set_sort_func (sort_completed_function);
        listbox.set_header_func (header_completed_function);
        listbox.set_filter_func (filter_function);
        listbox.set_placeholder (new Gtk.Label (_("No completed tasks yet.")) {
            css_classes = { "dim-label" },
            margin_top = 48,
            margin_start = 24,
            margin_end = 24,
            wrap = true,
            justify = Gtk.Justification.CENTER
        });

        var listbox_scrolled = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            child = listbox
        };

        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (search_entry);
        content_box.append (listbox_scrolled);

        var content_clamp = new Adw.Clamp () {
			maximum_size = 600,
			margin_bottom = 12
		};

		content_clamp.child = content_box;

		var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = content_clamp;

        var main_page = new Adw.NavigationPage (toolbar_view, _("Completed Tasks"));

        navigation_view = new Adw.NavigationView ();
        navigation_view.add (main_page);

        child = navigation_view;
        add_items ();
        Services.EventBus.get_default ().disconnect_typing_accel ();

        search_entry.search_changed.connect (() => {
            if (search_entry.text == "") {
                clear_items ();
                add_items ();
            }

            listbox.invalidate_filter ();
        });

        Services.EventBus.get_default ().checked_toggled.connect ((item, old_checked) => {
			if (item.project_id != project.id) {
                return;
			}

            if (!old_checked) {
                if (!items_checked.has_key (item.id)) {
                    items_checked [item.id] = new Widgets.CompletedTaskRow (item);
                    listbox.insert (items_checked [item.id], 0);
                }
            } else {
                if (items_checked.has_key (item.id)) {
                    items_checked [item.id].hide_destroy ();
                    items_checked.unset (item.id);
                }
            }
		});

        listbox.row_activated.connect ((row) => {
            Objects.Item item = ((Widgets.CompletedTaskRow) row).item;
            view_item (item);
        });

        closed.connect (() => {
            Services.EventBus.get_default ().connect_typing_accel ();
        });
    }

    private void view_item (Objects.Item item) {
        var headerbar = new Adw.HeaderBar ();
        headerbar.add_css_class ("flat");

        Layouts.ItemRow item_row = new Layouts.ItemRow (item) {
            edit = true,
            margin_end = 16
        };

        item_row.view_mode ();

        var toolbar_view = new Adw.ToolbarView ();
		toolbar_view.add_top_bar (headerbar);
		toolbar_view.content = item_row;

        var item_page = new Adw.NavigationPage (toolbar_view, _("Task Detail"));
        navigation_view.push (item_page);
    }

    private void add_items () {
        foreach (Objects.Item item in project.items_checked) {
            if (!items_checked.has_key (item.id)) {
                items_checked [item.id] = new Widgets.CompletedTaskRow (item);
                listbox.append (items_checked [item.id]);
            }
        }
    }

    private void header_completed_function (Gtk.ListBoxRow lbrow, Gtk.ListBoxRow? lbbefore) {
        var row = (Widgets.CompletedTaskRow) lbrow;
        if (row.item.completed_at == "") {
            return;
        }

        if (lbbefore != null) {
            var before = (Widgets.CompletedTaskRow) lbbefore;
            var comp_before = Utils.Datetime.get_date_from_string (before.item.completed_at);
            if (comp_before.compare (Utils.Datetime.get_date_from_string (row.item.completed_at)) == 0) {
                return;
            }
        }

        row.set_header (
            get_header_box (
                Utils.Datetime.get_relative_date_from_date (
                    Utils.Datetime.get_date_from_string (row.item.completed_at)
                )
            )
        );
    }

    private int sort_completed_function (Gtk.ListBoxRow row1, Gtk.ListBoxRow? row2) {
        var completed_a = Utils.Datetime.get_date_from_string (((Widgets.CompletedTaskRow) row1).item.completed_at);
        var completed_b = Utils.Datetime.get_date_from_string (((Widgets.CompletedTaskRow) row2).item.completed_at);
        return completed_b.compare (completed_a);
    }

    private bool filter_function (Gtk.ListBoxRow row) {
        return ((Widgets.CompletedTaskRow) row).item.content.down ().contains (search_entry.text.down ());
    }

    private Gtk.Widget get_header_box (string title) {
        var header_label = new Gtk.Label (title) {
            css_classes = { "heading" },
            halign = START
        };

        var header_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_start = 6,
            margin_top = 12,
            margin_bottom = 6
        };

        header_box.append (header_label);

        return header_box;
    }

    private void clear_items () {
        foreach (Widgets.CompletedTaskRow item in items_checked.values) {
            item.hide_destroy ();
        }

        items_checked.clear ();
    }
}

public class Widgets.CompletedTaskRow : Gtk.ListBoxRow {
    public Objects.Item item { get; construct; }

    private Gtk.CheckButton checked_button;
    private Gtk.Revealer main_revealer;

    public CompletedTaskRow (Objects.Item item) {
        Object (
            item: item
        );
    }

    ~CompletedTaskRow () {
        print ("Destroying Widgets.CompletedTaskRow\n");
    }

    construct {
        add_css_class ("no-selectable");

        checked_button = new Gtk.CheckButton () {
			valign = Gtk.Align.START,
            css_classes = { "priority-color" },
            active = item.checked
		};

		var content_label = new Gtk.Label (item.content) {
			wrap = true,
            hexpand = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
			xalign = 0,
			yalign = 0
		};

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
			margin_top = 3,
			margin_start = 3,
			margin_end = 3
		};

		content_box.append (checked_button);
		content_box.append (content_label);

        var description_label = new Gtk.Label (null) {
			xalign = 0,
			lines = 1,
			ellipsize = Pango.EllipsizeMode.END,
			margin_start = 30,
			margin_end = 6,
			css_classes = { "dim-label", "caption" }
		};

		var description_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
			child = description_label
		};

        description_label.label = Util.get_default ().line_break_to_space (item.description);
		description_label.tooltip_text = item.description.strip ();
		description_revealer.reveal_child = description_label.label.length > 0;

        var section_label = new Gtk.Label (item.has_section ? "● " + item.section.name : null) {
            hexpand = true,
            halign = END,
            css_classes = { "dim-label", "caption" }
        };

        var bottom_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        bottom_box.append (description_revealer);
        bottom_box.append (section_label);

        var handle_grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
            margin_top = 6,
            margin_end = 9,
            margin_bottom = 6,
            margin_start = 6
        };
		handle_grid.append (content_box);
		handle_grid.append (bottom_box);

        var card = new Adw.Bin () {
            child = handle_grid,
            css_classes = { "card", "border-radius-9" }
        };

        main_revealer = new Gtk.Revealer () {
			transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN,
			child = card
		};

		child = main_revealer;

        Timeout.add (main_revealer.transition_duration, () => {
			main_revealer.reveal_child = true;
			return GLib.Source.REMOVE;
		});

        var checked_button_gesture = new Gtk.GestureClick ();
		checked_button.add_controller (checked_button_gesture);
		checked_button_gesture.pressed.connect (() => {
			checked_button_gesture.set_state (Gtk.EventSequenceState.CLAIMED);
			checked_button.active = !checked_button.active;
            checked_toggled (checked_button.active);
		});
    }

    public void hide_destroy () {
		main_revealer.reveal_child = false;
		Timeout.add (main_revealer.transition_duration, () => {
			((Gtk.ListBox) parent).remove (this);
			return GLib.Source.REMOVE;
		});
	}

    public void checked_toggled (bool active, uint? time = null) {
		bool old_checked = item.checked;

        if (!active) {
            item.checked = false;
            item.completed_at = "";
            _complete_item (old_checked);
        }
	}

    private void _complete_item (bool old_checked) {
        if (item.project.source_type == SourceType.LOCAL) {
            Services.Store.instance ().checked_toggled (item, old_checked);
            return;
        }
        
        if (item.project.source_type == SourceType.TODOIST) {
            checked_button.sensitive = false;
            Services.Todoist.get_default ().complete_item.begin (item, (obj, res) => {
                if (Services.Todoist.get_default ().complete_item.end (res).status) {
                    Services.Store.instance ().checked_toggled (item, old_checked);
                    checked_button.sensitive = true;
                }
            });
        } else if (item.project.source_type == SourceType.CALDAV) {
            checked_button.sensitive = false;
            Services.CalDAV.Core.get_default ().complete_item.begin (item, (obj, res) => {
                if (Services.CalDAV.Core.get_default ().complete_item.end (res).status) {
                    Services.Store.instance ().checked_toggled (item, old_checked);
                    checked_button.sensitive = true;
                }
            });
        }
    }
}