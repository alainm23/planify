public class Utils : GLib.Object {
    public void create_dir_with_parents (string dir) {
        string path = Environment.get_home_dir () + dir;
        File tmp = File.new_for_path (path);
        if (tmp.query_file_type (0) != FileType.DIRECTORY) {
            GLib.DirUtils.create_with_parents (path, 0775);
        }
    }

    public int32 generate_id () {
        return GLib.Random.int_range (0, 999999999);
    }
}