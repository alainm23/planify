
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

public class Views.Project : Adw.Bin {
    public Objects.Project project { get; construct; }

    private Layouts.HeaderBar headerbar;
    private Gtk.Revealer project_view_revealer;
    private Adw.Spinner loading_spinner;
    private Adw.ViewStack project_stack;
    private Adw.ToolbarView toolbar_view;
    private Widgets.ContextMenu.MenuItem expand_all_item;
    private Widgets.ContextMenu.MenuCheckPicker priority_filter;
    private Widgets.ContextMenu.MenuPicker due_date_item;
    private Widgets.MultiSelectToolbar multiselect_toolbar;
    private Gtk.Revealer indicator_revealer;
    private Gtk.Popover context_menu;

    public ProjectViewStyle view_style {
        get {
            return project.source_type == SourceType.CALDAV ? ProjectViewStyle.LIST : project.view_style;
        }
    }

    private Gee.HashMap<ulong, weak GLib.Object> signal_map = new Gee.HashMap<ulong, weak GLib.Object> ();

    public Project (Objects.Project project) {
        Object (
            project: project
        );
    }

    ~Project () {
        debug ("Destroying - Views.Project\n");
    }

    construct {
        var menu_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            margin_end = 12,
            popover = build_context_menu_popover (),
            icon_name = "view-more-symbolic",
            css_classes = { "flat" },
            tooltip_text = _ ("Project Actions")
        };

        var indicator_grid = new Gtk.Grid () {
            width_request = 9,
            height_request = 9,
            margin_top = 6,
            margin_end = 6,
            css_classes = { "indicator" }
        };

        indicator_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            child = indicator_grid,
            halign = END,
            valign = START,
            sensitive = false,
        };

        var view_setting_button = new Gtk.MenuButton () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            popover = build_view_setting_popover (),
            icon_name = "view-sort-descending-rtl-symbolic",
            css_classes = { "flat" },
            tooltip_text = _ ("View Option Menu")
        };

        var view_setting_overlay = new Gtk.Overlay ();
        view_setting_overlay.child = view_setting_button;
        view_setting_overlay.add_overlay (indicator_revealer);

        headerbar = new Layouts.HeaderBar () {
            title = project.is_inbox_project ? _("Inbox") : project.name
        };

        headerbar.pack_end (menu_button);
        headerbar.pack_end (view_setting_overlay);

        project_view_revealer = new Gtk.Revealer () {
            hexpand = true,
            vexpand = true,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE
        };

        loading_spinner = new Adw.Spinner () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            height_request = 64,
            width_request = 64,
        };

        project_stack = new Adw.ViewStack () {
            vexpand = true,
            hexpand = true
        };

        project_stack.add (project_view_revealer);
        project_stack.add (loading_spinner);
        project_stack.visible_child = project_view_revealer;

        var magic_button = new Widgets.MagicButton ();

        var content_overlay = new Gtk.Overlay () {
            hexpand = true,
            vexpand = true
        };

        content_overlay.child = project_stack;

        if (!project.is_deck) {
            content_overlay.add_overlay (magic_button);

            signal_map[magic_button.clicked.connect (() => {
                prepare_new_item ();
            })] = magic_button;
        }

        multiselect_toolbar = new Widgets.MultiSelectToolbar (project);

        toolbar_view = new Adw.ToolbarView () {
            bottom_bar_style = Adw.ToolbarStyle.RAISED_BORDER,
            reveal_bottom_bars = false
        };
        toolbar_view.add_top_bar (headerbar);
        toolbar_view.add_bottom_bar (multiselect_toolbar);
        toolbar_view.content = content_overlay;

        child = toolbar_view;
        update_project_view ();
        check_default_filters ();
        create_context_menu ();

        var right_click = new Gtk.GestureClick () {
            button = Gdk.BUTTON_SECONDARY
        };
        right_click.pressed.connect (on_right_click);
        add_controller (right_click);

        signal_map[project.updated.connect (() => {
            headerbar.title = project.is_inbox_project ? _("Inbox") : project.name;
        })] = project;

        signal_map[multiselect_toolbar.closed.connect (() => {
            project.show_multi_select = false;
        })] = multiselect_toolbar;

        signal_map[project.show_multi_select_change.connect (() => {
            toolbar_view.reveal_bottom_bars = project.show_multi_select;

            if (project.show_multi_select) {
                Services.EventBus.get_default ().multi_select_enabled = true;
                Services.EventBus.get_default ().show_multi_select (true);
                Services.EventBus.get_default ().magic_button_visible (false);
                Services.EventBus.get_default ().disconnect_typing_accel ();
            } else {
                Services.EventBus.get_default ().multi_select_enabled = false;
                Services.EventBus.get_default ().show_multi_select (false);
                Services.EventBus.get_default ().magic_button_visible (true);
                Services.EventBus.get_default ().connect_typing_accel ();
            }
        })] = project;

        signal_map[project.filter_added.connect (() => {
            check_default_filters ();
        })] = project;

        signal_map[project.filter_updated.connect (() => {
            check_default_filters ();
        })] = project;

        signal_map[project.filter_removed.connect ((filter) => {
            priority_filter.unchecked (filter);

            if (filter.filter_type == FilterItemType.DUE_DATE) {
                due_date_item.selected = "0";
            }

            check_default_filters ();
        })] = project;

        signal_map[project.view_style_changed.connect (() => {
            update_project_view ();
            expand_all_item.visible = view_style == ProjectViewStyle.LIST;
        })] = project;

        signal_map[project.handle_scroll_visibility_change.connect ((visible) => {
            headerbar.update_title_box_visibility (visible);
        })] = project;

        signal_map[Services.EventBus.get_default ().escape_pressed.connect (() => {
            if (project.show_multi_select) {
                project.show_multi_select = false;
            }
        })] = Services.EventBus.get_default ();
    }

    private void create_context_menu () {
        var add_task_item = new Widgets.ContextMenu.MenuItem (_("New Task"), "plus-large-symbolic");
        var add_section_item = new Widgets.ContextMenu.MenuItem (_("New Section"), "tab-new-symbolic");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;
        menu_box.append (add_task_item);
        menu_box.append (add_section_item);

        context_menu = new Gtk.Popover () {
            has_arrow = false,
            child = menu_box,
            position = Gtk.PositionType.BOTTOM,
            width_request = 250
        };

        add_task_item.clicked.connect (() => {
            prepare_new_item ();
            context_menu.popdown ();
        });

        add_section_item.clicked.connect (() => {
            prepare_new_section ();
            context_menu.popdown ();
        });
    }

    private void on_right_click (int n_press, double x, double y) {
        Gdk.Rectangle rect = { (int) x, (int) y, 250, 1 };

        context_menu.set_parent (this);
        context_menu.set_pointing_to (rect);
        context_menu.popup ();
    }

    private void check_default_filters () {
        bool defaults = true;

        if (project.sorted_by != SortedByType.MANUAL) {
            defaults = false;
        }

        if (project.sort_order != SortOrderType.ASC) {
            defaults = false;
        }

        if (project.filters.size > 0) {
            defaults = false;
        }

        indicator_revealer.reveal_child = !defaults;
    }

    private void update_project_view () {
        project_stack.visible_child = loading_spinner;
        project_view_revealer.reveal_child = false;

        Timeout.add (project_view_revealer.transition_duration, () => {
            destroy_current_view ();

            if (view_style == ProjectViewStyle.LIST) {
                project_view_revealer.child = new Views.List (project);
            } else if (view_style == ProjectViewStyle.BOARD) {
                headerbar.update_title_box_visibility (false);
                project_view_revealer.child = new Views.Board (project);
            }

            project_stack.visible_child = project_view_revealer;
            project_view_revealer.reveal_child = true;
            return GLib.Source.REMOVE;
        });
    }

    private void destroy_current_view () {
        if (project_view_revealer.child is Views.List) {
            Views.List ? list_view = (Views.List) project_view_revealer.child;
            if (list_view != null) {
                list_view.clean_up ();
            }
        } else if (project_view_revealer.child is Views.Board) {
            Views.Board ? board_view = (Views.Board) project_view_revealer.child;
            if (board_view != null) {
                board_view.clean_up ();
            }
        }

        project_view_revealer.child = null;
    }

    public void prepare_new_item (string content = "") {
        if (project.is_deck) {
            return;
        }

        if (project_view_revealer.child == null) {
            return;
        }

        if (project_view_revealer.child is Views.List) {
            Views.List ? list_view = (Views.List) project_view_revealer.child;
            if (list_view != null) {
                list_view.prepare_new_item (content);
            }
        } else if (project_view_revealer.child is Views.Board) {
            Views.Board ? board_view = (Views.Board) project_view_revealer.child;
            if (board_view != null) {
                board_view.prepare_new_item (content);
            }
        }
    }

    private Gtk.Popover build_context_menu_popover () {
        var edit_item = new Widgets.ContextMenu.MenuItem (_ ("Edit Project"), "edit-symbolic");
        var duplicate_item = new Widgets.ContextMenu.MenuItem (_ ("Duplicate"), "tabs-stack-symbolic");
        var schedule_item = new Widgets.ContextMenu.MenuItem (_ ("When?"), "month-symbolic");
        var add_section_item = new Widgets.ContextMenu.MenuItem (_ ("New Section"), "tab-new-symbolic");
        add_section_item.secondary_text = "S";
        var manage_sections = new Widgets.ContextMenu.MenuItem (_ ("Manage Sections"), "permissions-generic-symbolic");

        var select_item = new Widgets.ContextMenu.MenuItem (_ ("Select"), "list-large-symbolic");
        var paste_item = new Widgets.ContextMenu.MenuItem (_ ("Paste"), "tabs-stack-symbolic");
        expand_all_item = new Widgets.ContextMenu.MenuItem (_ ("Expand All"), "expand-vertically-symbolic") {
            visible = view_style == ProjectViewStyle.LIST
        };
        var archive_item = new Widgets.ContextMenu.MenuItem (_ ("Archive"), "shoe-box-symbolic");
        var delete_item = new Widgets.ContextMenu.MenuItem (_ ("Delete Project"), "user-trash-symbolic");
        delete_item.add_css_class ("menu-item-danger");

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;

        if (!project.is_deck && !project.inbox_project) {
            menu_box.append (edit_item);

            signal_map[edit_item.activate_item.connect (() => {
                var dialog = new Dialogs.Project (project);
                dialog.present (Planify._instance.main_window);
            })] = edit_item;
        }

        if (!project.is_inbox_project) {
            menu_box.append (schedule_item);
            menu_box.append (duplicate_item);
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());

            signal_map[schedule_item.activate_item.connect (() => {
                var dialog = new Dialogs.DatePicker (_ ("When?"));
                dialog.clear = project.due_date != "";

                signal_map[dialog.date_changed.connect (() => {
                    if (dialog.datetime == null) {
                        project.due_date = "";
                    } else {
                        project.due_date = dialog.datetime.to_string ();
                    }

                    project.update_local ();
                })] = dialog;

                dialog.present (Planify._instance.main_window);
            })] = schedule_item;

            signal_map[duplicate_item.clicked.connect (() => {
                Util.get_default ().duplicate_project.begin (project, project.parent_id);
            })] = duplicate_item;
        }

        if (project.source_type == SourceType.LOCAL || project.source_type == SourceType.TODOIST) {
            menu_box.append (add_section_item);
            menu_box.append (manage_sections);

            signal_map[add_section_item.activate_item.connect (() => {
                prepare_new_section ();
            })] = add_section_item;

            signal_map[manage_sections.clicked.connect (() => {
                var dialog = new Dialogs.ManageSectionOrder (project);
                dialog.present (Planify._instance.main_window);
            })] = manage_sections;
        }

#if WITH_EVOLUTION
        var calendar_sync_item = new Widgets.ContextMenu.MenuItem (_ ("Calendar Sync"), "month-symbolic") {
            badge = _("New")
        };

        if (!project.is_inbox_project) {
            menu_box.append (calendar_sync_item);
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());

            calendar_sync_item.clicked.connect (() => {
                var dialog = new Dialogs.CalendarSync (project);
                dialog.present (Planify._instance.main_window);
            });
        }
#endif

        menu_box.append (select_item);
        menu_box.append (paste_item);
        menu_box.append (expand_all_item);

        if (!project.is_deck && !project.inbox_project) {
            menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
            menu_box.append (archive_item);
            menu_box.append (delete_item);

            signal_map[archive_item.clicked.connect (() => {
                project.archive_project ((Gtk.Window) Planify.instance.main_window);
            })] = archive_item;

            signal_map[delete_item.clicked.connect (() => {
                project.delete_project ((Gtk.Window) Planify.instance.main_window);
            })] = delete_item;
        }

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM,
            child = menu_box,
            width_request = 250
        };

        signal_map[paste_item.clicked.connect (() => {
            Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();

            clipboard.read_text_async.begin (null, (obj, res) => {
                try {
                    string content = clipboard.read_text_async.end (res);
                    Planify.instance.main_window.add_task_action (content);
                } catch (GLib.Error error) {
                    debug (error.message);
                }
            });
        })] = paste_item;

        signal_map[expand_all_item.clicked.connect (() => {
            if (expand_all_item.icon == "collapse-vertically-symbolic") {
                expand_all_item.title = _ ("Expand All");
                expand_all_item.icon = "expand-vertically-symbolic";
                Services.EventBus.get_default ().expand_all (project.id, false);
            } else {
                expand_all_item.title = _ ("Collapse All");
                expand_all_item.icon = "collapse-vertically-symbolic";
                Services.EventBus.get_default ().expand_all (project.id, true);
            }
        })] = expand_all_item;

        signal_map[select_item.clicked.connect (() => {
            project.show_multi_select = true;
        })] = select_item;

        return popover;
    }

    private Gtk.Popover build_view_setting_popover () {
        var list_toggle = new Adw.Toggle () {
            name = ProjectViewStyle.LIST.to_string (),
            label = _ ("List"),
            icon_name = "list-symbolic"
        };

        var board_toggle = new Adw.Toggle () {
            name = ProjectViewStyle.BOARD.to_string (),
            label = _ ("Board"),
            icon_name = "view-columns-symbolic"
        };

        var view_group = new Adw.ToggleGroup () {
            margin_bottom = 12
        };

        view_group.add (list_toggle);
        view_group.add (board_toggle);
        view_group.active_name = project.view_style.to_string ();

        var sorted_by_item = new Widgets.ContextMenu.MenuPicker (_ ("Sorting"), "vertical-arrows-long-symbolic") {
            selected = project.sorted_by.to_string ()
        };
        sorted_by_item.add_item (_("Custom sort order"), SortedByType.MANUAL.to_string ());
        sorted_by_item.add_item (_("Alphabetically"), SortedByType.NAME.to_string ());
        sorted_by_item.add_item (_("Due Date"), SortedByType.DUE_DATE.to_string ());
        sorted_by_item.add_item (_("Date Added"), SortedByType.ADDED_DATE.to_string ());
        sorted_by_item.add_item (_("Priority"), SortedByType.PRIORITY.to_string ());

        var sort_order_item = new Widgets.ContextMenu.MenuSwitch (_ ("Ascending Order"), "view-sort-ascending-rtl-symbolic") {
            active = project.sort_order == SortOrderType.ASC,
            visible = project.sorted_by != SortedByType.MANUAL
        };

        // Filters
        due_date_item = new Widgets.ContextMenu.MenuPicker (_ ("Duedate"), "month-symbolic") {
            selected = "0"
        };
        due_date_item.add_item (_ ("All (default)"), "0");
        due_date_item.add_item (_ ("Today"), "1");
        due_date_item.add_item (_ ("This Week"), "2");
        due_date_item.add_item (_ ("Next 7 Days"), "3");
        due_date_item.add_item (_ ("This Month"), "4");
        due_date_item.add_item (_ ("Next 30 Days"), "5");
        due_date_item.add_item (_ ("No Date"), "6");

        var priority_items = new Gee.ArrayList<Objects.Filters.FilterItem> ();

        priority_items.add (new Objects.Filters.FilterItem () {
            filter_type = FilterItemType.PRIORITY,
            name = _ ("P1"),
            value = Constants.PRIORITY_1.to_string ()
        });

        priority_items.add (new Objects.Filters.FilterItem () {
            filter_type = FilterItemType.PRIORITY,
            name = _ ("P2"),
            value = Constants.PRIORITY_2.to_string ()
        });

        priority_items.add (new Objects.Filters.FilterItem () {
            filter_type = FilterItemType.PRIORITY,
            name = _ ("P3"),
            value = Constants.PRIORITY_3.to_string ()
        });

        priority_items.add (new Objects.Filters.FilterItem () {
            filter_type = FilterItemType.PRIORITY,
            name = _ ("P4"),
            value = Constants.PRIORITY_4.to_string ()
        });

        priority_filter = new Widgets.ContextMenu.MenuCheckPicker (_ ("Priority"), "flag-outline-thick-symbolic");
        priority_filter.set_items (priority_items);

        var labels_filter = new Widgets.ContextMenu.MenuItem (_ ("Filter by Labels"), "tag-outline-symbolic") {
            arrow = true
        };

        var show_completed_item = new Widgets.ContextMenu.MenuSwitch (_ ("Show Completed"), "check-round-outline-symbolic") {
            tooltip_text = _("Display completed tasks in the list")
        };
        show_completed_item.active = project.show_completed;

        var show_completed_item_button = new Gtk.Button.from_icon_name ("edit-find-symbolic") {
            valign = CENTER,
            tooltip_text = _("Search completed tasks")
        };
        show_completed_item_button.add_css_class ("flat");

        var show_completed_box = new Gtk.Box (HORIZONTAL, 6) {
            valign = CENTER
        };
        show_completed_box.append (show_completed_item);
        show_completed_box.append (show_completed_item_button);

        var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        menu_box.margin_top = menu_box.margin_bottom = 3;

        if (project.source_type == SourceType.LOCAL || project.source_type == SourceType.TODOIST) {
            menu_box.append (view_group);

            signal_map[view_group.notify["active-name"].connect (() => {
                if (view_group.active_name == ProjectViewStyle.LIST.to_string ()) {
                    project.view_style = ProjectViewStyle.LIST;
                } else {
                    project.view_style = ProjectViewStyle.BOARD;
                }

                project.update_local ();
            })] = view_group;
        }

        menu_box.append (new Gtk.Label (_ ("Sort By")) {
            css_classes = { "caption", "font-bold" },
            margin_start = 6,
            margin_bottom = 6,
            halign = Gtk.Align.START
        });
        menu_box.append (sorted_by_item);
        menu_box.append (sort_order_item);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (new Gtk.Label (_ ("Filter By")) {
            css_classes = { "caption", "font-bold" },
            margin_start = 6,
            margin_top = 6,
            margin_bottom = 6,
            halign = Gtk.Align.START
        });
        menu_box.append (due_date_item);
        menu_box.append (priority_filter);
        menu_box.append (labels_filter);
        menu_box.append (new Widgets.ContextMenu.MenuSeparator ());
        menu_box.append (show_completed_box);

        var popover = new Gtk.Popover () {
            has_arrow = false,
            position = Gtk.PositionType.BOTTOM,
            child = menu_box,
            width_request = 250
        };

        signal_map[sorted_by_item.notify["selected"].connect (() => {
            project.sorted_by = SortedByType.parse (sorted_by_item.selected);
            if (project.sorted_by == SortedByType.MANUAL) {
                project.sort_order = SortOrderType.ASC;
            }

            project.update_local ();
            check_default_filters ();
        })] = sorted_by_item;

        signal_map[sort_order_item.activate_item.connect (() => {
            project.sort_order = sort_order_item.active ? SortOrderType.ASC : SortOrderType.DESC;
            project.update_local ();
            check_default_filters ();
        })] = sort_order_item;

        signal_map[show_completed_item.activate_item.connect (() => {
            project.show_completed = !project.show_completed;
            project.update_local ();
            check_default_filters ();
        })] = show_completed_item;

        signal_map[project.show_completed_changed.connect (() => {
            show_completed_item.active = project.show_completed;
        })] = project;

        signal_map[show_completed_item_button.clicked.connect (() => {
            popover.popdown ();

            var dialog = new Dialogs.CompletedTasks (project);
            dialog.present (Planify._instance.main_window);
        })] = show_completed_item_button;

        signal_map[project.sorted_by_changed.connect (() => {
            sorted_by_item.update_selected (project.sorted_by.to_string ());
            sort_order_item.visible = project.sorted_by != SortedByType.MANUAL;

            check_default_filters ();
        })] = project;

        signal_map[project.sort_order_changed.connect (() => {
            sort_order_item.active = project.sort_order == SortOrderType.ASC;
        })] = project;

        signal_map[due_date_item.notify["selected"].connect (() => {
            int selected = int.parse (due_date_item.selected);

            if (selected <= 0) {
                Objects.Filters.FilterItem filter = project.get_filter (FilterItemType.DUE_DATE.to_string ());
                if (filter != null) {
                    project.remove_filter (filter);
                }
            } else {
                Objects.Filters.FilterItem filter = project.get_filter (FilterItemType.DUE_DATE.to_string ());
                bool insert = false;

                if (filter == null) {
                    filter = new Objects.Filters.FilterItem ();
                    filter.filter_type = FilterItemType.DUE_DATE;
                    insert = true;
                }

                if (selected == 1) {
                    filter.name = _ ("Today");
                } else if (selected == 2) {
                    filter.name = _ ("This Week");
                } else if (selected == 3) {
                    filter.name = _ ("Next 7 Days");
                } else if (selected == 4) {
                    filter.name = _ ("This Month");
                } else if (selected == 5) {
                    filter.name = _ ("Next 30 Days");
                } else if (selected == 6) {
                    filter.name = _ ("No Date");
                }

                filter.value = selected.to_string ();

                if (insert) {
                    project.add_filter (filter);
                } else {
                    project.update_filter (filter);
                }
            }
        })] = due_date_item;

        signal_map[priority_filter.filter_change.connect ((filter, active) => {
            if (active) {
                project.add_filter (filter);
            } else {
                project.remove_filter (filter);
            }
        })] = priority_filter;

        signal_map[labels_filter.activate_item.connect (() => {
            Gee.ArrayList<Objects.Label> _labels = new Gee.ArrayList<Objects.Label> ();
            foreach (Objects.Filters.FilterItem filter in project.filters.values) {
                if (filter.filter_type == FilterItemType.LABEL) {
                    _labels.add (Services.Store.instance ().get_label (filter.value));
                }
            }

            var dialog = new Dialogs.LabelPicker ();
            dialog.add_labels (project.source);
            dialog.labels = _labels;
            dialog.present (Planify._instance.main_window);

            dialog.labels_changed.connect ((labels) => {
                foreach (Objects.Label label in labels.values) {
                    var filter = new Objects.Filters.FilterItem ();
                    filter.filter_type = FilterItemType.LABEL;
                    filter.name = label.name;
                    filter.value = label.id;

                    project.add_filter (filter);
                }

                Gee.ArrayList<Objects.Filters.FilterItem> to_remove = new Gee.ArrayList<Objects.Filters.FilterItem> ();
                foreach (Objects.Filters.FilterItem filter in project.filters.values) {
                    if (filter.filter_type == FilterItemType.LABEL) {
                        if (!labels.has_key (filter.value)) {
                            to_remove.add (filter);
                        }
                    }
                }

                foreach (Objects.Filters.FilterItem filter in to_remove) {
                    project.remove_filter (filter);
                }
            });
        })] = labels_filter;

        return popover;
    }

    public void prepare_new_section () {
        if (project.source_type == SourceType.CALDAV) {
            return;
        }

        var dialog = new Dialogs.Section.new (project);
        dialog.present (Planify._instance.main_window);
    }

    public void clean_up () {
        foreach (var entry in signal_map.entries) {
            entry.value.disconnect (entry.key);
        }

        signal_map.clear ();

        destroy_current_view ();
    }

    public override void dispose () {
        clean_up ();
        base.dispose ();
    }
}
