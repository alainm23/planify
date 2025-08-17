public abstract class Services.CalDAV.Providers.Base {
    public virtual string TASKLIST_REQUEST { get; set; default = ""; }

    public abstract string get_all_taskslist_url (string server_url, string username);

    public abstract Gee.ArrayList<Objects.Project> get_projects_by_doc (GXml.DomDocument doc, Objects.Source source);

    public abstract bool is_vtodo_calendar (GXml.DomElement element);
}
