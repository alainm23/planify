public abstract class Services.CalDAV.Providers.Base {
    // vala-lint=naming-convention
    public virtual string LOGIN_REQUEST { get; set; default = ""; }

    // vala-lint=naming-convention
    public virtual string USER_DATA_REQUEST { get; set; default = ""; }

    public virtual string TASKLIST_REQUEST { get; set; default = ""; }

    public abstract string get_server_url (string server_url, string username, string password);

    public abstract string get_account_url (string server_url, string username);

    public abstract void set_user_data (GXml.DomDocument doc, Objects.Source source);

    public abstract string get_all_taskslist_url (string server_url, string username);

    public abstract Gee.ArrayList<Objects.Project> get_projects_by_doc (GXml.DomDocument doc, Objects.Source source);

    public abstract bool is_vtodo_calendar (GXml.DomElement element);
}
