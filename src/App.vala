public class Planner : Adw.Application {
	public MainWindow main_window;

	public static Planner _instance = null;
	public static Planner instance {
		get {
			if (_instance == null) {
				_instance = new Planner ();
			}
			return _instance;
		}
	}

	private static bool run_in_background = false;
	private static bool version = false;
	private static bool clear_database = false;
	private static string lang = "";

	private Xdp.Portal? portal = null;

	private const OptionEntry[] PLANNER_OPTIONS = {
		{ "version", 'v', 0, OptionArg.NONE, ref version, "Display version number", null },
		{ "reset", 'r', 0, OptionArg.NONE, ref clear_database, "Reset Planner", null },
		{ "background", 'b', 0, OptionArg.NONE, out run_in_background, "Run the Application in background", null },
		{ "lang", 'l', 0, OptionArg.STRING, ref lang, "Open Planner in a specific language", "LANG" },
		{ null }
	};

	construct {
		application_id = "io.github.alainm23.planify";
		flags |= ApplicationFlags.HANDLES_OPEN;

		Intl.setlocale (LocaleCategory.ALL, "");
		string langpack_dir = Path.build_filename (Constants.INSTALL_PREFIX, "share", "locale");
		Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, langpack_dir);
		Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
		Intl.textdomain (Constants.GETTEXT_PACKAGE);

		add_main_option_entries (PLANNER_OPTIONS);
		create_dir_with_parents ("/io.github.alainm23.planify");
	}

	protected override void activate () {
		if (lang != "") {
			GLib.Environment.set_variable ("LANGUAGE", lang, true);
		}

		if (version) {
			print ("%s\n".printf (Constants.VERSION));
			return;
		}

		if (main_window != null) {
			main_window.show ();
			return;
		}

		main_window = new MainWindow (this);

		Services.Settings.get_default ().settings.bind ("window-height", main_window, "default-height", SettingsBindFlags.DEFAULT);
		Services.Settings.get_default ().settings.bind ("window-width", main_window, "default-width", SettingsBindFlags.DEFAULT);

		if (Services.Settings.get_default ().settings.get_boolean ("window-maximized")) {
			main_window.maximize ();
		}

		if (!run_in_background) {
			main_window.show ();
		}

		Services.Settings.get_default ().settings.bind ("window-maximized", main_window, "maximized", SettingsBindFlags.SET);

		var provider = new Gtk.CssProvider ();
		provider.load_from_resource ("/io/github/alainm23/planify/index.css");
		Gtk.StyleContext.add_provider_for_display (
			Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
			);

		Util.get_default ().update_theme ();

		if (Services.Settings.get_default ().settings.get_string ("version") != Constants.VERSION) {
			Services.Settings.get_default ().settings.set_string ("version", Constants.VERSION);

			var dialog = new Dialogs.WhatsNew ();
			dialog.show ();
		}

		if (clear_database) {
			Util.get_default ().clear_database (_("Are you sure you want to reset all?"),
			                                    _("The process removes all stored information without the possibility of undoing it."));
		}
	}

	public async bool ask_for_background (Xdp.BackgroundFlags flags = Xdp.BackgroundFlags.AUTOSTART) {
		const string[] DAEMON_COMMAND = { "io.github.alainm23.planify", "--background" };
		if (portal == null) {
			portal = new Xdp.Portal ();
		}

		string reason = _(
			"Planify will automatically start when this device turns on " +
			"and run when its window is closed so that it can send to-do notifications."
			);
		var command = new GenericArray<unowned string> (2);
		foreach (unowned var arg in DAEMON_COMMAND) {
			command.add (arg);
		}

		var window = Xdp.parent_new_gtk (active_window);

		try {
			return yield portal.request_background (window, reason, command, flags, null);
		} catch (Error e) {
			print ("Error during portal request: %s".printf (e.message));
			return e is IOError.FAILED;
		}
	}

	public void create_dir_with_parents (string dir) {
		string path = Environment.get_user_data_dir () + dir;
		File tmp = File.new_for_path (path);
		if (tmp.query_file_type (0) != FileType.DIRECTORY) {
			GLib.DirUtils.create_with_parents (path, 0775);
		}
	}

	public static int main (string[] args) {
		Planner app = Planner.instance;
		return app.run (args);
	}
}
