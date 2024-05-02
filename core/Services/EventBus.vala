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
    private static EventBus? _instance;
    public static EventBus get_default () {
        if (_instance == null) {
            _instance = new EventBus ();
        }

        return _instance;
    }

    // Shortcuts
    public signal void disconnect_typing_accel ();
    public signal void connect_typing_accel ();

    // General
    public signal void theme_changed ();
    public signal void delete_row_project (Objects.Project project);
    public signal void pane_selected (PaneType panel_type, string id);
    public signal void item_selected (string? id);
    public signal void task_selected (string? uid);
    public signal void avatar_downloaded ();
    public signal void view_header (bool view);
    public signal void magic_button_activated (bool activated);
    public signal void project_picker_changed (string id);
    public signal void section_picker_changed (string id);
    public signal void project_parent_changed (Objects.Project project, string old_parent_id, bool collapsed = false);
    public signal void update_inserted_project_map (Gtk.Widget row, string old_parent_id);
    public signal void checked_toggled (Objects.Item item, bool old_checked);
    public signal void favorite_toggled (Objects.Project project);
    public signal void item_moved (Objects.Item item, string old_project_id, string old_section_id, string old_parent_id = "");
    public signal void update_items_position (string project_id, string section_id);
    public signal void update_inserted_item_map (Gtk.Widget row, string old_section_id, string old_parent_id);
    public signal void update_section_sort_func (string project_id, string section_id, bool active);
    public signal void day_changed ();
    public signal void open_labels ();
    public signal void close_labels ();
    public signal void paste_action (string project_id, string content);
    public signal void new_item_deleted (string project_id);
    public signal void update_labels_position ();
    public signal void section_sort_order_changed (string project_id);
    public signal void request_escape ();
    public signal void drag_n_drop_active (string project_id, bool active);

    // Notifications
    public signal void send_notification (Adw.Toast toast);

    // Multi Select
    public bool multi_select_enabled = false;
    public signal void show_multi_select (bool enabled);
    public signal void select_item (Gtk.Widget itemrow);
    public signal void unselect_item (Gtk.Widget itemrow);
    public signal void unselect_all ();
    public bool ctrl_pressed { get; set; default = false; }
    public bool alt_pressed { get; set; default = false; }

    // Magic Button
    public signal void magic_button_visible (bool active);

    // Navigate
    public signal void open_item (Objects.Item item);
    public signal void push_item (Objects.Item item);
    public signal void close_item ();
}
