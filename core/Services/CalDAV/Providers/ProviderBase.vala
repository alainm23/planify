public class Services.CalDAV.Providers.Base {
    // vala-lint=naming-convention
    public virtual string LOGIN_REQUEST { get; set; default = ""; }

    // vala-lint=naming-convention
    public virtual string USER_DATA_REQUEST { get; set; default = ""; }

    public virtual string TASKLIST_REQUEST { get; set; default = ""; }

    public virtual string get_server_url (string server_url, string username, string password) {
        return "";
    }

    public virtual string get_account_url (string server_url, string username) {
        return "";
    }

    public virtual void set_user_data (GXml.DomDocument doc, Objects.Source source) {

    }

    public virtual string get_all_taskslist_url (string server_url, string username) {
        return "";
    }

    public virtual Gee.ArrayList<Objects.Project> get_projects_by_doc (GXml.DomDocument doc, Objects.Source source) {
        return new Gee.ArrayList<Objects.Project> ();
    }

    public virtual bool is_vtodo_calendar (GXml.DomElement element) {
        return false;
    }
}