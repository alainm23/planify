public class Services.Database : GLib.Object {
    private Sqlite.Database db;
    private string db_path;
    private string errormsg;
    private string sql;

    private static Database? _instance;
    public static Database get_default () {
        if (_instance == null) {
            _instance = new Database ();
        }

        return _instance;
    }

    Gee.ArrayList<Objects.Label> _labels = null;
    public Gee.ArrayList<Objects.Label> labels {
        get {
            if (_labels == null) {
                _labels = get_labels_collection ();
            }
            return _labels;
        }
    }

    Gee.ArrayList<Objects.Project> _projects = null;
    public Gee.ArrayList<Objects.Project> projects {
        get {
            if (_projects == null) {
                _projects = get_projects_collection ();
            }
            return _projects;
        }
    }

    Gee.ArrayList<Objects.Section> _sections = null;
    public Gee.ArrayList<Objects.Section> sections {
        get {
            if (_sections == null) {
                _sections = get_sections_collection ();
            }
            return _sections;
        }
    }

    construct {
        db_path = Environment.get_user_data_dir () + "/com.github.alainm23.planner/database.db";
        Sqlite.Database.open (db_path, out db);
    }

    public Gee.ArrayList<Objects.Label> get_labels_collection () {
        Gee.ArrayList<Objects.Label> return_value = new Gee.ArrayList<Objects.Label> ();
        Sqlite.Statement stmt;

        sql = """
            SELECT * FROM Labels;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_label (stmt));
        }
        stmt.reset ();
        return return_value;
    }

    public Objects.Label _fill_label (Sqlite.Statement stmt) {
        Objects.Label return_value = new Objects.Label ();
        return_value.id = stmt.column_int64 (0);
        return_value.name = stmt.column_text (1);
        return_value.color = stmt.column_text (2);
        return_value.item_order = stmt.column_int (3);
        return_value.is_deleted = get_parameter_bool (stmt, 4);
        return_value.is_favorite = get_parameter_bool (stmt, 5);
        return_value.todoist = get_parameter_bool (stmt, 6);
        return return_value;
    }

    public Objects.Label get_label_by_name (string name, bool lowercase = false) {
        Objects.Label? return_value = null;
        lock (_labels) {
            foreach (var label in labels) {
                if (lowercase) {
                    if (label.name.down () == name.down ()) {
                        return_value = label;
                        break;
                    }
                } else {
                    if (label.name == name) {
                        return_value = label;
                        break;
                    }
                }
            }

            return return_value;
        }
    }

    public Objects.Label get_label (int64 id) {
        Objects.Label? return_value = null;
        lock (_labels) {
            foreach (var label in labels) {
                if (label.id == id) {
                    return_value = label;
                    break;
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Project> get_projects_collection () {
        Gee.ArrayList<Objects.Project> return_value = new Gee.ArrayList<Objects.Project> ();

        Sqlite.Statement stmt;
        
        sql = """
            SELECT * FROM Projects ORDER BY child_order;
        """;

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_project (stmt));
        }
        stmt.reset ();
        return return_value;
    }

    public Objects.Project get_project (int64 id) {
        Objects.Project? return_value = null;
        lock (_projects) {
            foreach (var project in projects) {
                if (project.id == id) {
                    return_value = project;
                    break;
                }
            }

            return return_value;
        }
    }

    public Objects.Project _fill_project (Sqlite.Statement stmt) {
        Objects.Project return_value = new Objects.Project ();
        return_value.id = stmt.column_int64 (0);
        return_value.name = stmt.column_text (1);
        return_value.color = stmt.column_text (2);
        return_value.todoist = get_parameter_bool (stmt, 3);
        return_value.inbox_project = get_parameter_bool (stmt, 4);
        return_value.team_inbox = get_parameter_bool (stmt, 5);
        return_value.child_order = stmt.column_int (6);
        return_value.is_deleted = get_parameter_bool (stmt, 7);
        return_value.is_archived = get_parameter_bool (stmt, 8);
        return_value.is_favorite = get_parameter_bool (stmt, 9);
        return_value.shared = get_parameter_bool (stmt, 10);
        return_value.view_style = get_view_style_by_text (stmt, 11);
        return_value.sort_order = stmt.column_int (12);
        return_value.parent_id = stmt.column_int64 (13);
        return_value.collapsed = get_parameter_bool (stmt, 14);
        return_value.icon_style = get_icon_style_by_text (stmt, 15);
        return_value.emoji = stmt.column_text (16);
        return return_value;
    }

    public Objects.Section get_section (int64 id) {
        Objects.Section? return_value = null;
        lock (_sections) {
            foreach (var section in sections) {
                if (section.id == id) {
                    return_value = section;
                    break;
                }
            }

            return return_value;
        }
    }

    public Gee.ArrayList<Objects.Section> get_sections_collection () {
        Gee.ArrayList<Objects.Section> return_value = new Gee.ArrayList<Objects.Section> ();

        Sqlite.Statement stmt;
        sql = "SELECT * FROM Sections;";

        db.prepare_v2 (sql, sql.length, out stmt);

        while (stmt.step () == Sqlite.ROW) {
            return_value.add (_fill_section (stmt));
        }
        stmt.reset ();
        return return_value;
    }

    public Objects.Section _fill_section (Sqlite.Statement stmt) {
        Objects.Section return_value = new Objects.Section ();
        return_value.id = stmt.column_int64 (0);
        return_value.name = stmt.column_text (1);
        return_value.archived_at = stmt.column_text (2);
        return_value.added_at = stmt.column_text (3);
        return_value.project_id = stmt.column_int64 (4);
        return_value.section_order = stmt.column_int (5);
        return_value.collapsed = get_parameter_bool (stmt, 6);
        return_value.is_deleted = get_parameter_bool (stmt, 7);
        return_value.is_archived = get_parameter_bool (stmt, 8);
        return return_value;
    }

    private ProjectViewStyle get_view_style_by_text (Sqlite.Statement stmt, int col) {
        if (stmt.column_text (col) == "board") {
            return ProjectViewStyle.BOARD;
        }

        return ProjectViewStyle.LIST;
    }

    private ProjectIconStyle get_icon_style_by_text (Sqlite.Statement stmt, int col) {
        if (stmt.column_text (col) == "emoji") {
            return ProjectIconStyle.EMOJI;
        }

        return ProjectIconStyle.PROGRESS;
    }
    
    // PARAMENTER REGION
    private void set_parameter_int (Sqlite.Statement? stmt, string par, int val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_int (par_position, val);
    }

    private void set_parameter_int64 (Sqlite.Statement? stmt, string par, int64 val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_int64 (par_position, val);
    }
    private void set_parameter_str (Sqlite.Statement? stmt, string par, string val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_text (par_position, val);
    }

    private void set_parameter_bool (Sqlite.Statement? stmt, string par, bool val) {
        int par_position = stmt.bind_parameter_index (par);
        stmt.bind_int (par_position, val ? Constants.ACTIVE : Constants.INACTIVE);
    }

    private bool get_parameter_bool (Sqlite.Statement stmt, int col) {
        return stmt.column_int (col) == Constants.ACTIVE;
    }
}