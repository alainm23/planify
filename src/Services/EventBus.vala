public class Services.EventBus : Object {
    public signal void prefers_color_scheme_changed (bool is_dark);
    public signal void delete_row_project (Objects.Project project);
    public signal void pane_selected (PaneType panel_type, string id);
    public signal void avatar_downloaded ();
}
