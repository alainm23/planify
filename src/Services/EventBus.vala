public class Services.EventBus : Object {
    public signal void theme_changed (bool dark);
    public signal void delete_row_project (Objects.Project project);
    public signal void pane_selected (PaneType panel_type, string id);
    public signal void item_selected (int64? id);
    public signal void avatar_downloaded ();
    public signal void view_header (bool view);
    public signal void magic_button_activated (bool activated);
    public signal void project_selector_selected (int64 id);
    public signal void project_parent_changed (Objects.Project project, int64 old_parent_id);
    public signal void checked_toggled (Objects.Item item, bool old_checked);
    public signal void favorite_toggled (Objects.Project project);
    public signal void move_item (Objects.Item item, int64 old_project_id, int64 old_section_id);
}
