public class Services.LogService : Object {
    public enum Level {
        DEBUG,
        INFO,
        WARNING,
        ERROR;

        public string to_string () {
            switch (this) {
                case DEBUG: return "DEBUG";
                case INFO: return "INFO";
                case WARNING: return "WARNING";
                case ERROR: return "ERROR";
                default: return "UNKNOWN";
            }
        }
    }

    private static LogService? _instance;
    public static LogService get_default () {
        if (_instance == null) {
            _instance = new LogService ();
        }
        return _instance;
    }

    private string log_path;
    private FileOutputStream? stream = null;
    private const int MAX_LOG_SIZE = 5 * 1024 * 1024; // 5MB

    construct {
        var dir = Path.build_filename (Environment.get_user_data_dir (), "io.github.alainm23.planify");
        log_path = Path.build_filename (dir, "planify.log");

        try {
            var dir_file = File.new_for_path (dir);
            if (!dir_file.query_exists ()) {
                dir_file.make_directory_with_parents ();
            }

            rotate_if_needed ();

            var file = File.new_for_path (log_path);
            stream = file.append_to (FileCreateFlags.NONE);
        } catch (Error e) {
            warning ("Could not initialize log file: %s", e.message);
        }
    }

    public void log (Level level, string context, string message) {
        var timestamp = new DateTime.now_local ().format ("%Y-%m-%d %H:%M:%S");
        var line = "[%s] [%s] [%s] %s\n".printf (timestamp, level.to_string (), context, message);

        if (Constants.IS_DEVELOPMENT || !Util.get_default ().is_flatpak ()) {
            print ("%s", line);
        } else {
            GLib.debug ("%s", line.chomp ());
        }

        // Write to file
        if (stream != null) {
            try {
                stream.write (line.data);
                stream.flush ();
            } catch (Error e) {
                warning ("Could not write to log: %s", e.message);
            }
        }
    }

    public void debug (string context, string message) {
        log (Level.DEBUG, context, message);
    }

    public void info (string context, string message) {
        log (Level.INFO, context, message);
    }

    public void warn (string context, string message) {
        log (Level.WARNING, context, message);
    }

    public void error (string context, string message) {
        log (Level.ERROR, context, message);
    }

    private void rotate_if_needed () {
        try {
            var file = File.new_for_path (log_path);
            if (!file.query_exists ()) {
                return;
            }

            var info = file.query_info (FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE);
            if (info.get_size () > MAX_LOG_SIZE) {
                var old_path = log_path + ".old";
                var old_file = File.new_for_path (old_path);
                if (old_file.query_exists ()) {
                    old_file.delete ();
                }
                file.move (old_file, FileCopyFlags.OVERWRITE);
            }
        } catch (Error e) {
            warning ("Could not rotate log: %s", e.message);
        }
    }

    public string get_log_path () {
        return log_path;
    }
}
