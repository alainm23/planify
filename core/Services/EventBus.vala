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

public class Services.EventBus : Object {
    private static EventBus ? _instance;
    public static EventBus get_default () {
        if (_instance == null) {
            _instance = new EventBus ();
        }

        return _instance;
    }

    // Shortcuts
    public signal void disconnect_typing_accel ();
    public signal void connect_typing_accel ();
    public signal void disconnect_all_accels ();
    public signal void connect_all_accels ();
    public signal void escape_pressed ();

    // General
    public signal void theme_changed ();
    public signal void delete_row_project (Objects.Project project);
    public signal void pane_selected (PaneType panel_type, string id);
    public signal void item_selected (string ? id);
    public signal void task_selected (string ? uid);
    public signal void avatar_downloaded ();
    public signal void magic_button_activated (bool activated);
    public signal void project_picker_changed (string id);
    public signal void section_picker_changed (string id);
    public signal void project_parent_changed (Objects.Project project, string old_parent_id, bool collapsed = false);
    public signal void update_inserted_project_map (Gtk.Widget row, string old_parent_id);
    public signal void checked_toggled (Objects.Item item, bool old_checked);
    public signal void favorite_toggled (Objects.Project project);
    public signal void item_moved (Objects.Item item, string old_project_id, string old_section_id, string old_parent_id = "");
    public signal void update_inserted_item_map (Gtk.Widget row, string old_section_id, string old_parent_id);
    public signal void update_section_sort_func (string project_id, string section_id, bool active);
    public signal void day_changed ();
    public signal void section_sort_order_changed (string project_id);
    public signal void drag_n_drop_active (string project_id, bool active);
    public signal void expand_all (string project_id, bool active);
    public signal void projects_drag_begin (string source_id);
    public signal void projects_drag_end (string source_id);
    public signal void drag_items_end (string project_id);
    public signal void update_sources_position ();

    public bool _mobile_mode = Services.Settings.get_default ().settings.get_boolean ("mobile-mode");
    public bool mobile_mode {
        set {
            _mobile_mode = value;
            mobile_mode_change ();
        }

        get {
            return _mobile_mode;
        }
    }

    public signal void mobile_mode_change ();

    // Notifications
    public signal void send_toast (Adw.Toast toast);
    public signal void send_error_toast (int error_code, string error_message);
    public signal void send_task_completed_toast (string project_id);

    // Multi Select
    public bool multi_select_enabled = false;
    public signal void show_multi_select (bool enabled);
    public signal void select_item (Gtk.Widget itemrow);
    public signal void unselect_item (Gtk.Widget itemrow);
    public signal void unselect_all ();

    // Magic Button
    public signal void magic_button_visible (bool active);

    // Navigate
    public signal void open_item (Objects.Item item);
    public signal void push_item (Objects.Item item);
    public signal void close_item ();

    // Item Edit Backdrop
    public signal void close_item_edit ();
    public signal void dim_content (bool active, string focused_item_id = "");    
    public bool item_edit_active = false;

    public void unfocus_item () {
        item_edit_active = false;
        dim_content (false, "");
    }
}
