public class Utils : GLib.Object {
    private const string ALPHA_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    private const string NUMERIC_CHARS = "1234567890";
    
    public void create_dir_with_parents (string dir) {
        string path = Environment.get_home_dir () + dir;
        File tmp = File.new_for_path (path);
        if (tmp.query_file_type (0) != FileType.DIRECTORY) {
            GLib.DirUtils.create_with_parents (path, 0775);
        }
    }

    public int32 generate_id () {
        int32 id = GLib.Random.int_range (0, 999999999);

        while (Application.database.is_project_id_valid (id) == false) {
            id = GLib.Random.int_range (0, 999999999);
        }

        return id;
    }

    public string generate_string () {
        string allowed_characters = ALPHA_CHARS + NUMERIC_CHARS;

        var password_builder = new StringBuilder ();
            for (var i = 0; i < 36; i++) {
                var random_index = Random.int_range (0, allowed_characters.length);
                password_builder.append_c (allowed_characters[random_index]);
            }
        return password_builder.str;
    }

    public string get_color (int key) {
        var colors = new Gee.HashMap<int, string> ();
        
        colors.set (30, "#b8256f");
        colors.set (31, "#db4035");
        colors.set (32, "#ff9933");
        colors.set (33, "#fad000");
        colors.set (34, "#afb83b");
        colors.set (35, "#7ecc49");
        colors.set (36, "#299438");
        colors.set (37, "#6accbc");
        colors.set (38, "#158fad");
        colors.set (39, "#14aaf5");
        colors.set (40, "#96c3eb");
        colors.set (41, "#4073ff");
        colors.set (42, "#884dff");
        colors.set (43, "#af38eb");
        colors.set (44, "#eb96eb");
        colors.set (45, "#e05194");
        colors.set (46, "#ff8d85");
        colors.set (47, "#808080");
        colors.set (48, "#b8b8b8");
        colors.set (49, "#ccac93");

        return colors.get (key);
    }   
}