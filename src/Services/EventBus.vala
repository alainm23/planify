public class Services.EventBus : Object {
    // Shortcuts
    public signal void disconnect_typing_accel ();
    public signal void connect_typing_accel ();

    // General
    public signal void theme_changed ();
    public signal void delete_row_project (Objects.Project project);
    public signal void pane_selected (PaneType panel_type, string id);
    public signal void item_selected (int64? id);
    public signal void task_selected (string? uid);
    public signal void avatar_downloaded ();
    public signal void view_header (bool view);
    public signal void magic_button_activated (bool activated);
    public signal void project_picker_changed (int64 project_id);
    public signal void project_parent_changed (Objects.Project project, int64 old_parent_id);
    public signal void checked_toggled (Objects.Item item, bool old_checked);
    public signal void favorite_toggled (Objects.Project project);
    public signal void item_moved (Objects.Item item, int64 old_project_id, int64 old_section_id, int64 old_parent_id = Constants.INACTIVE, bool insert = true);
    public signal void update_items_position (int64 project_id, int64 section_id);
    public signal void update_inserted_item_map (Layouts.ItemRow row);
    public signal void update_section_sort_func (int64 project_id, int64 section_id, bool active);
    public signal void day_changed ();
    public signal void open_labels ();
    public signal void close_labels ();
    
    // Notifications
    public signal void send_notification (Adw.Toast toast);

    // Multi Select
    public bool ctrl_pressed = false;
    public bool alt_pressed = false;
    public signal void unselect_all ();
    public signal void ctrl_press ();
    public signal void ctrl_release ();
    public signal void select_item (Layouts.ItemRow itemrow);
    public signal void magic_button_visible (bool active);

    //Mouse position
    public int x_root = 0;
    public int y_root = 0;
}