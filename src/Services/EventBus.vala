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
    public signal void project_parent_changed (Objects.Project project, string old_parent_id);
    public signal void checked_toggled (Objects.Item item, bool old_checked);
    public signal void favorite_toggled (Objects.Project project);
    public signal void item_moved (Objects.Item item, string old_project_id, string old_section_id, string old_parent_id = "", bool insert = true);
    public signal void update_items_position (string project_id, string section_id);
    public signal void update_inserted_item_map (Layouts.ItemRow row);
    public signal void update_section_sort_func (string project_id, string section_id, bool active);
    public signal void day_changed ();
    public signal void open_labels ();
    public signal void close_labels ();
    public signal void inbox_project_changed ();
    public signal void paste_action (string project_id, string content);
    public signal void new_item_deleted (string project_id);

    // Notifications
    public signal void send_notification (Adw.Toast toast);

    // Multi Select
    public bool multi_select_enabled = false;
    public signal void show_multi_select (bool enabled);
    public signal void unselect_all ();
    public signal void select_item (Layouts.ItemRow itemrow);
    public signal void unselect_item (Layouts.ItemRow itemrow);


    public signal void magic_button_visible (bool active);
}